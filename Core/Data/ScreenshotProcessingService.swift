import Foundation
import UIKit
import Vision

/// VisionKit OCR -> Google Vision API (레이블) -> GPT-4 -> ProcessingResult 생성 통합 파이프라인
class ScreenshotProcessingService {
    
    // MARK: - Services
    private let googleVision = GoogleVisionService()
    private let cardService = CardService()
    
    // MARK: - Processing Pipeline
    
    /// 스크린샷 처리 파이프라인 (ProcessingResult 반환 - Card + 원본 데이터)
    /// - Parameters:
    ///   - image: 처리할 이미지
    ///   - completion: (ProcessingResult, 에러) 콜백
    func processScreenshot(
        image: UIImage,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("🚀 스크린샷 처리 파이프라인 시작")
        
        // Step 1: VisionKit OCR + Google Vision 레이블 병렬 처리
        processWithVisionKit(image: image, completion: completion)
    }
    
    /// async/await 버전
    func processScreenshot(image: UIImage) async throws -> ProcessingResult {
        try await withCheckedThrowingContinuation { continuation in
            processScreenshot(image: image) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Private Processing Methods
    
    /// VisionKit OCR + Google Vision 레이블 병렬 처리
    private func processWithVisionKit(
        image: UIImage,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("📸 Step 1: VisionKit으로 OCR + Google Vision 레이블 탐지 시작")
        
        guard let cgImage = image.cgImage else {
            print("❌ CGImage 변환 실패")
            completion(.failure(.ocrFailed("이미지 변환 실패")))
            return
        }
        
        // 병렬 처리를 위한 DispatchGroup
        let group = DispatchGroup()
        var ocrText = ""
        var ocrTextLines: [String] = []
        var visionLabels: [VisionLabel] = []
        var ocrError: Error?
        
        // 1️⃣ VisionKit OCR
        group.enter()
        print("📝 VisionKit OCR 요청 시작...")
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest { request, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ VisionKit 에러: \(error.localizedDescription)")
                    ocrError = error
                    return
                }
                
                print("📝 VisionKit 요청 처리 중...")
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ VisionKit 결과 없음 (observations nil)")
                    ocrError = ProcessingError.ocrFailed("텍스트를 찾을 수 없습니다.")
                    return
                }
                
                print("📝 인식된 라인 수: \(observations.count)")
                
                ocrTextLines = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                
                print("📝 추출된 텍스트 라인 수: \(ocrTextLines.count)")
                ocrTextLines.enumerated().forEach { idx, text in
                    print("  [\(idx)] \(text.prefix(50))")
                }
                
                ocrText = ocrTextLines.joined(separator: "\n")
                
                print("✅ VisionKit OCR 완료: \(ocrText.prefix(100))...")
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                print("📝 VisionKit handler.perform 실행...")
                try handler.perform([request])
                print("📝 VisionKit handler.perform 완료")
            } catch {
                print("❌ VisionKit 실행 에러: \(error.localizedDescription)")
                ocrError = error
                group.leave()
            }
        }
        
        // 2️⃣ Google Vision 레이블 탐지
        group.enter()
        print("🎯 Google Vision LABEL_DETECTION 요청 시작...")
        googleVision.detectLabels(from: image) { result in
            defer { group.leave() }
            
            switch result {
            case .success(let labels):
                visionLabels = labels
                print("✅ Google Vision 레이블 탐지 완료: \(labels.count)개")
                labels.forEach { label in
                    print("  - \(label.description): \(label.confidencePercentage)")
                }
                
            case .failure(let error):
                print("⚠️ Google Vision 레이블 탐지 실패 (진행 계속): \(error.localizedDescription)")
            }
        }
        
        // 3️⃣ 모든 작업 완료 후 GPT 분류
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            print("⏳ 모든 병렬 작업 완료, 다음 단계 진행 중...")
            
            // OCR은 필수, 레이블은 선택
            if let ocrError = ocrError {
                print("[Caplog 스크린샷] ❌ 카드 생성 불가: OCR 에러 - \(ocrError.localizedDescription)")
                completion(.failure(.ocrFailed(ocrError.localizedDescription)))
                return
            }
            
            if ocrText.isEmpty {
                print("[Caplog 스크린샷] ❌ 카드 생성 불가: OCR 텍스트 없음")
                completion(.failure(.ocrFailed("텍스트를 찾을 수 없습니다.")))
                return
            }
            
            print("✅ OCR 텍스트 유효함 (\(ocrTextLines.count) 라인)")
            
            // Step 2: GPT-4 분류 (OCR 텍스트 + 레이블 정보 함께 전달)
            self.classifyWithGPT(
                ocrText: ocrText,
                ocrTextLines: ocrTextLines,
                visionLabels: visionLabels,
                originalImage: image,
                completion: completion
            )
        }
    }
    
    /// GPT-4로 분류 및 정보 추출
    private func classifyWithGPT(
        ocrText: String,
        ocrTextLines: [String],
        visionLabels: [VisionLabel],
        originalImage: UIImage,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("🤖 Step 2: GPT-4 분류 시작")
        
        guard let raw = Bundle.main.infoDictionary?["GPT_API_KEY"] as? String, !raw.isEmpty else {
            print("❌ GPT_API_KEY가 Info.plist에 없거나 비어 있습니다. caplog/Info.plist에 OpenAI API 키를 넣어주세요.")
            completion(.failure(.gptFailed("GPT API Key가 없습니다. Info.plist의 GPT_API_KEY를 설정하세요.")))
            return
        }
        let apiKey = raw
        
        let prompt = makeGPTPrompt(from: ocrText, visionLabels: visionLabels)
        
        classifyTextWithGPT_stable(prompt: prompt, apiKey: apiKey) { [weak self] gptResult, usage in
            guard let self = self else { return }
            
            print("✅ GPT-4 분류 완료: \(gptResult.prefix(100))...")
            print("📊 Token 사용량: \(usage)")
            
            // Step 3: Card 생성
            guard let card = self.parseGPTResultToCard(
                gptResult: gptResult,
                extractedText: ocrText,
                visionLabels: visionLabels,
                image: originalImage
            ) else {
                // GPT가 에러 문자열(❌ API 에러, ❌ 빈 응답 등)을 반환한 경우 원인을 그대로 전달
                if gptResult.hasPrefix("❌") {
                    print("[Caplog 스크린샷] ❌ 카드 생성 불가: GPT 에러 - \(gptResult.prefix(120))")
                    completion(.failure(.gptFailed(gptResult)))
                } else {
                    print("[Caplog 스크린샷] ❌ 카드 생성 불가: GPT 응답 파싱 실패 (JSON/필드 문제)")
                    completion(.failure(.cardCreationFailed("GPT 응답 파싱 실패")))
                }
                return
            }
            
            // Step 4: ProcessingResult 생성
            let processingResult = ProcessingResult(
                card: card,
                ocrText: ocrTextLines,
                googleVisionLabels: visionLabels,
                preprocessedImage: originalImage,
                apiUsage: usage
            )
            
            print("✅ ProcessingResult 생성 완료")
            print("   - Card: \(card.title)")
            print("   - OCR 라인: \(ocrTextLines.count)")
            print("   - Vision 레이블: \(visionLabels.count)")
            
            // Step 5: 서버에 저장 (optional)
            self.saveCardToServer(processingResult, completion: completion)
        }
    }
    
    /// GPT 프롬프트 생성 (Caplog 전용 - JSON only)
    private func makeGPTPrompt(from text: String, visionLabels: [VisionLabel]) -> String {
        // 만에 하나 OCR 텍스트에 """ 가 들어있을 경우 프롬프트가 깨지지 않도록 이스케이프
        let safe = text.replacingOccurrences(of: "\"\"\"", with: #"\"\"\""#)
        
        // Google Vision 레이블 포맷팅
        let labelsInfo: String
        if visionLabels.isEmpty {
            labelsInfo = "없음"
        } else {
            labelsInfo = visionLabels
                .map { "\($0.description) (\($0.confidencePercentage))" }
                .joined(separator: ", ")
        }
        
        return """
        당신은 OCR로 추출된 스크린샷 텍스트와 Google Vision이 탐지한 이미지 정보를 종합하여 분류하고, 핵심 정보를 구조화된 JSON으로 변환하는 역할을 합니다.
        다음 지침을 반드시 지키세요.
        
        [출력 규칙]
        - JSON만 출력하세요. 설명/문장/마크다운/코드펜스(``` 등) 절대 금지.
        - 값이 없으면 빈 문자열("")로 남기세요.
        - 모든 값은 문자열로 주세요. (숫자/날짜도 문자열)
        - 날짜는 가능하면 YYYY-MM-DD 형식으로 통일하세요.
        - 카테고리 분류가 확실치 않으면 category_main은 "Unknown", category_sub은 ""로 두세요.
        
        [기타 사용 최소화 - 반드시 준수]
        - "기타"는 정말 어떤 소분류에도 넣기 어려울 때만 사용하세요. 웬만하면 아래 유사 매핑으로 가장 가까운 소분류를 선택하세요.
        - 할인/쿠폰/기프티콘/금액권/이벤트권/상품권 → 쿠폰
        - 식당/음식/맛집/배달/메뉴/리뷰 → 맛집
        - 커피/카페/음료/브런치/디저트 매장 → 카페
        - 채용/모집/공고/지원기한/인재 → 공고 또는 취업
        - 뉴스/기사/정보글 → 뉴스
        - 공부/시험/수업/과제 → 공부
        - 전시/영화/공연/문화행사 → 문화생활
        - 운동/헬스/건강/다이어트 → 운동/건강
        - 메모/필기/노트/요약 → 필기
        - 기록/로그/데이터/활동이력 → 기록 또는 활동
        - 음악/노래/앨범/플레이리스트 → 음악
        - 미술/전시/작품/갤러리 → 미술
        - 채팅/대화/메신저/채널 → 채팅
        - 사진/이미지/갤러리 → 사진
        - 글/짤/밈/문구 → 글 또는 짤
        - 장소/가게/매장 정보가 있으면 → 맛집 또는 카페 우선 고려
        
        [공통 스키마]
        {
          "category_main": "",   // Info | Contents | Social | Log | Music | Art | Unknown
          "category_sub": "",    // 아래 리스트에서 정확히 선택
          "title": "",           // 카드 제목 (짧고 핵심, 최대 50자)
          "summary": "",         // 1~2문장 요약 (최대 150자)
          "fields": {}           // 카테고리별 상세 (최대 4~5개)
        }
        
        [category_sub 소분류 목록 - 반드시 이 중에서 선택, 기타는 최후 수단만]
        Info: 맛집, 카페, 공부, 공고, 취업, 필기, 뉴스, 문화생활, 운동/건강, 쿠폰, 기타(정말 불가 시에만)
        Contents: 글, 짤
        Social: 채팅, 사진
        Log: 기록, 활동
        Music: 음악
        Art: 미술
        Unknown: 기타(대분류부터 불명확할 때만)
        
        [카테고리별 필드 정의(최대 4~5개)]
        1) Info (정보)
           - 맛집/카페: place_name(필수: 가게·매장·브랜드 이름이 보이면 반드시 추출), address(optional), menu_or_keyword(optional), valid_until(optional), benefit(optional)
           - 공부/공고/취업/필기: topic, organization(optional), deadline(마감일 있으면 반드시 YYYY-MM-DD 또는 yyyy.MM.dd.), notes(optional)
           - 쿠폰: brand(필수: 브랜드·가맹점명이 보이면 반드시 추출), benefit, valid_until(만료일 있으면 반드시 추출, 형식 YYYY-MM-DD 또는 yyyy.MM.dd.), conditions(optional)
        
        2) Contents (밈/짤/글)
           - content_text, tone(optional), topic(optional), share_intent(optional)
        
        3) Social (채팅/사진)
           - sender(optional), participants(optional), date(optional), content(optional)
        
        4) Log (기록/활동)
           - activity, date(optional), location(optional), notes(optional)
        
        5) Music
           - title, artist(optional), genre(optional), date(optional)
           
        6) Art
           - title, artist(optional), location(optional), date(optional)
        
        [태그 생성 규칙]
        태그는 자동으로 다음에서 추출됩니다:
        1. fields에서: place_name, brand, menu_or_keyword 등 주요 키워드
        2. Google Vision 레이블: 신뢰도 50% 이상인 객체/개념
        3. 중복 제거: 같은 태그가 여러 번 나오면 하나만 사용
        
        예시:
        - fields에서 "place_name": "이마트24" → #이마트24 태그 추가
        - fields에서 "menu_or_keyword": "떡볶이, 튀김" → #떡볶이 #튀김 태그 추가
        - Vision에서 "신용카드 (95.3%)" → #신용카드 태그 추가
        
        [제목과 요약 생성 규칙]
        - 제목: 가장 중요한 정보 1줄. 가게/브랜드 이름이 있으면 반드시 포함 (예: "이마트24 5천원권", "목화반점 맛집", "스타벅스 아메리카노 1+1")
        - 요약: 사용자가 한눈에 이해할 수 있는 1~2문장 (예: "이마트24에서 사용할 수 있는 5천원 모바일금액권입니다.")
        
        [날짜·마감일 추출 규칙]
        - 쿠폰: 유효기간·사용기한·만료일이 보이면 valid_until에 반드시 넣기. 형식: 2025-12-31 또는 2025. 12. 31.
        - 공고/취업: 마감일·접수마감·지원기한이 보이면 deadline에 반드시 넣기. 형식 동일.
        - 숫자만 보이면 (예: 12.31, 2025.12.31) 연도를 추정해 완성하세요.
        
        [가게·브랜드 이름 추출 규칙]
        - 맛집/카페: 상호명, 매장 이름, 프랜차이즈명이 OCR/Vision에 있으면 place_name에 반드시 넣기. (예: "목화반점", "스타벅스 강남점", "메가커피")
        - 쿠폰: 기프티콘 브랜드, 가맹점명이 보이면 brand에 반드시 넣기. (예: "이마트24", "GS25", "스타벅스")
        
        [입력 정보]
        
        **OCR 텍스트:**
        \"\"\"
        \(safe)
        \"\"\"
        
        **Google Vision 이미지 분석 (객체/개념 탐지):**
        \(labelsInfo)
        
        [출력 예시 - 쿠폰]
        { "category_main": "Info", "category_sub": "쿠폰", "title": "이마트24 5천원권", "summary": "이마트24에서 사용할 수 있는 5천원 모바일금액권입니다.", "fields": { "brand": "이마트24", "benefit": "5천원권", "valid_until": "2025-11-20", "conditions": "모바일 금액권" } }
        [출력 예시 - 맛집]
        { "category_main": "Info", "category_sub": "맛집", "title": "목화반점 강남점", "summary": "강남역 인근 중식당 목화반점입니다.", "fields": { "place_name": "목화반점", "address": "서울 강남구", "menu_or_keyword": "짜장면, 짬뽕" } }
        [출력 예시 - 공고]
        { "category_main": "Info", "category_sub": "공고", "title": "OO회사 개발자 채용", "summary": "OO회사 백엔드 개발자 모집 공고입니다.", "fields": { "topic": "백엔드 개발자 채용", "organization": "OO회사", "deadline": "2025-12-15", "notes": "경력 3년 이상" } }
        
        주의: place_name, brand, valid_until, deadline은 보이면 반드시 채우고, 위 필드에서 태그가 자동 추출됩니다.
        """
    }
    
    /// GPT 결과를 Card 객체로 변환 (새 스키마)
    private func parseGPTResultToCard(
        gptResult: String,
        extractedText: String,
        visionLabels: [VisionLabel],
        image: UIImage
    ) -> Card? {
        let debug = "[Caplog GPT 디버그]"
        print("\(debug) 1단계: GPT 원본 응답 수신, 길이=\(gptResult.count), 앞 200자: \(String(gptResult.prefix(200)))")
        
        if gptResult.hasPrefix("❌") {
            print("\(debug) 실패: GPT가 에러 문자열 반환 → \(gptResult.prefix(80))")
            return nil
        }
        
        var cleanedJSON = stripFences(gptResult)
        if cleanedJSON.hasPrefix("\u{FEFF}") { cleanedJSON = String(cleanedJSON.dropFirst()) }
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        print("\(debug) 2단계: stripFences 후 길이=\(cleanedJSON.count), 앞 150자: \(String(cleanedJSON.prefix(150)))")
        
        var json: [String: Any]?
        if let data = cleanedJSON.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = parsed
            print("\(debug) 3단계: JSON 파싱 성공 (직렬)")
        } else if let span = extractFirstJSONObject(cleanedJSON),
                  let data = span.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = parsed
            print("\(debug) 3단계: JSON 파싱 성공 ({ } 구간 추출 후)")
        }
        guard let json = json else {
            print("\(debug) 실패: JSON 파싱 불가. 원본 앞 300자: \(String(gptResult.prefix(300)))")
            return nil
        }
        
        print("\(debug) 4단계: JSON 키 목록: \(json.keys.sorted().joined(separator: ", "))")
        
        let catMain = json["category_main"]
        let titleVal = json["title"]
        guard let categoryMain = catMain as? String,
              let title = titleVal as? String, !title.isEmpty else {
            print("\(debug) 실패: 필수 필드 누락. category_main 타입=\(type(of: catMain)), 값=\(String(describing: catMain)); title 타입=\(type(of: titleVal)), 값=\(String(describing: titleVal))")
            return nil
        }
        
        print("\(debug) 5단계: 필수 필드 확인 완료. category_main=\(categoryMain), title=\(title)")
        
        // category_main -> FolderCategory 매핑
        let category = mapCategoryMain(categoryMain)
        
        // category_sub 추출
        let categorySub = json["category_sub"] as? String ?? ""
        let subcategory = mapSubcategory(categorySub, category: category)
        
        let summary = json["summary"] as? String ?? ""
        let fieldsDict = json["fields"] as? [String: Any] ?? [:]
        
        // fields를 [String: String]으로 변환
        var fields: [String: String] = [:]
        for (key, value) in fieldsDict {
            if let stringValue = value as? String {
                fields[key] = stringValue
            } else {
                fields[key] = "\(value)"
            }
        }
        // 마감일 통일: valid_until / deadline → 만료일 (홈·카드 상세에서 공통 사용)
        if fields["만료일"] == nil || fields["만료일"]?.isEmpty == true {
            if let v = fields["valid_until"], !v.isEmpty { fields["만료일"] = v }
            else if let d = fields["deadline"], !d.isEmpty { fields["만료일"] = d }
        }
        
        // 태그 생성 (fields에서 추출)
        var tags: [String] = []
        if let placeName = fields["place_name"], !placeName.isEmpty {
            tags.append(placeName)
        }
        if let brand = fields["brand"], !brand.isEmpty {
            tags.append(brand)
        }
        if let menuOrKeyword = fields["menu_or_keyword"], !menuOrKeyword.isEmpty {
            let keywords = menuOrKeyword.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            tags.append(contentsOf: keywords)
        }
        
        // Google Vision 레이블 태그 추가 (신뢰도 높은 것만)
        let highConfidenceLabels = visionLabels
            .filter { $0.confidence > 0.5 }
            .map { $0.description }
        tags.append(contentsOf: highConfidenceLabels)
        
        // 이미지 저장 (실제로는 서버에 업로드하거나 로컬 저장)
        let imageName = UUID().uuidString
        // TODO: 실제 이미지 저장 로직 구현
        
        return Card(
            title: title,
            summary: summary,
            category: category,
            subcategory: subcategory,
            tags: Array(Set(tags)), // 중복 제거
            fields: fields,
            thumbnailURL: imageName,
            screenshotURLs: [imageName]
        )
    }
    
    /// JSON 이외 문자가 섞였을 때 방어용 (```json / ```JSON / ``` 제거)
    private func stripFences(_ s: String) -> String {
        s.replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
         .replacingOccurrences(of: "```", with: "")
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 첫 번째 { 부터 마지막 } 까지 문자열 추출
    private func extractFirstJSONObject(_ s: String) -> String? {
        guard let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}"), start < end else { return nil }
        return String(s[start...end])
    }
    
    /// category_main 문자열 -> FolderCategory 매핑
    private func mapCategoryMain(_ categoryMain: String) -> FolderCategory {
        switch categoryMain.lowercased() {
        case "info": return .info
        case "contents": return .contents
        case "social": return .social
        case "log": return .log
        case "music/art", "musicart": return .musicArt
        case "unknown", "etc", "etc.": return .etc
        default: return .etc
        }
    }
    
    /// category_sub 문자열 -> 적절한 subcategory 매핑
    private func mapSubcategory(_ categorySub: String, category: FolderCategory) -> String {
        // 빈 문자열이면 기본값 반환
        if categorySub.isEmpty {
            return category.subcategories.first?.name ?? "기타"
        }
        
        // 정확히 일치하는 것이 있으면 반환
        if category.subcategories.contains(where: { $0.name == categorySub }) {
            return categorySub
        }
        
        // 부분 일치 시도
        let lowerSub = categorySub.lowercased()
        if let matched = category.subcategories.first(where: { $0.name.lowercased().contains(lowerSub) || lowerSub.contains($0.name.lowercased()) }) {
            return matched.name
        }
        
        // 매핑 실패 시 GPT가 준 값 그대로 사용
        return categorySub
    }
    
    /// 서버에 카드 저장
    private func saveCardToServer(
        _ processingResult: ProcessingResult,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("💾 Step 4: 서버에 카드 저장 시작")
        
        Task {
            do {
                let savedCard = try await cardService.createCard(processingResult.card)
                print("✅ 카드 저장 완료: \(savedCard.title)")
                
                // 저장된 Card로 ProcessingResult 업데이트
                let updatedResult = ProcessingResult(
                    card: savedCard,
                    ocrText: processingResult.ocrText,
                    googleVisionLabels: processingResult.googleVisionLabels,
                    preprocessedImage: processingResult.preprocessedImage,
                    apiUsage: processingResult.apiUsage
                )
                completion(.success(updatedResult))
            } catch {
                print("⚠️ 서버 저장 실패 (Mock 모드): \(error.localizedDescription)")
                // Mock 모드에서는 원본 ProcessingResult 반환
                completion(.success(processingResult))
            }
        }
    }
}

// MARK: - Error Types
enum ProcessingError: LocalizedError {
    case ocrFailed(String)
    case gptFailed(String)
    case cardCreationFailed(String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed(let message):
            return "OCR 실패: \(message)"
        case .gptFailed(let message):
            return "GPT 분류 실패: \(message)"
        case .cardCreationFailed(let message):
            return "카드 생성 실패: \(message)"
        case .notImplemented(let message):
            return "미구현: \(message)"
        }
    }
}
