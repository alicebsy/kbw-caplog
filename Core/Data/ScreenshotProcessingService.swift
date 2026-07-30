import Foundation
import UIKit
import Vision

/// Apple Vision OCR/이미지 분류 -> 개인정보 마스킹 -> GPT -> ProcessingResult 파이프라인
class ScreenshotProcessingService {
    
    // MARK: - Services
    private let imageClassifier = OnDeviceImageClassifier()
    
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
        
        // Step 1: 외부 전송 없이 Apple Vision OCR + 이미지 분류를 병렬 처리
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
    
    /// Apple Vision OCR + 온디바이스 이미지 분류 병렬 처리
    private func processWithVisionKit(
        image: UIImage,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("📸 Step 1: Apple Vision 온디바이스 분석 시작")
        
        guard let cgImage = image.cgImage else {
            print("❌ CGImage 변환 실패")
            completion(.failure(.ocrFailed("이미지 변환 실패")))
            return
        }
        
        // 병렬 처리를 위한 DispatchGroup
        let group = DispatchGroup()
        var ocrText = ""
        var ocrTextLines: [String] = []
        var imageLabels: [ImageLabel] = []
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
                
                ocrText = ocrTextLines.joined(separator: "\n")
                
                // OCR 원문은 개인정보가 포함될 수 있으므로 로그에 출력하지 않는다.
                print("✅ VisionKit OCR 완료")
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
        
        // 2️⃣ Apple Vision 온디바이스 이미지 분류
        group.enter()
        print("🎯 온디바이스 이미지 분류 시작...")
        imageClassifier.classify(from: image) { result in
            defer { group.leave() }
            
            switch result {
            case .success(let labels):
                imageLabels = labels
                print("✅ 온디바이스 이미지 분류 완료: \(labels.count)개")
                
            case .failure(let error):
                print("⚠️ 온디바이스 이미지 분류 실패 (OCR로 계속): \(error.localizedDescription)")
            }
        }
        
        // 3️⃣ 모든 작업 완료 후 GPT 분류
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            print("⏳ 모든 병렬 작업 완료, 다음 단계 진행 중...")
            
            // OCR은 필수, 이미지 분류 레이블은 선택
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
            
            // Step 2: 개인정보를 가린 OCR 텍스트 + 기기 내 레이블만 GPT에 전달
            self.classifyWithGPT(
                ocrText: ocrText,
                ocrTextLines: ocrTextLines,
                imageLabels: imageLabels,
                originalImage: image,
                completion: completion
            )
        }
    }
    
    /// GPT-4로 분류 및 정보 추출
    private func classifyWithGPT(
        ocrText: String,
        ocrTextLines: [String],
        imageLabels: [ImageLabel],
        originalImage: UIImage,
        completion: @escaping (Result<ProcessingResult, ProcessingError>) -> Void
    ) {
        print("🤖 Step 2: GPT-4 분류 시작")
        
        let redactedText = OCRPrivacyRedactor.redact(ocrText)
        let prompt = makeGPTPrompt(from: redactedText, imageLabels: imageLabels)
        
        classifyTextWithGPT_stable(prompt: prompt) { [weak self] gptResult, usage in
            guard let self = self else { return }
            
            // AI 응답에는 카드 내용이 포함되므로 원문을 로그에 남기지 않는다.
            print("🤖 GPT-4 분류 응답 수신")
            print("📊 Token 사용량: \(usage)")
            
            // Step 3: Card 생성
            let parsedCard = self.parseGPTResultToCard(
                gptResult: gptResult,
                imageLabels: imageLabels
            )
            let card = parsedCard ?? self.makeOCRFallbackCard(
                ocrText: redactedText,
                ocrTextLines: redactedText.components(separatedBy: .newlines),
                imageLabels: imageLabels
            )
            if parsedCard == nil {
                print("[Caplog 스크린샷] ⚠️ AI 분류 실패 → OCR 기본 카드로 계속 진행")
            }
            
            // Step 4: ProcessingResult 생성
            let processingResult = ProcessingResult(
                card: card,
                ocrText: ocrTextLines,
                imageLabels: imageLabels,
                preprocessedImage: originalImage,
                apiUsage: usage
            )
            
            print("✅ ProcessingResult 생성 완료")
            print("   - OCR 라인: \(ocrTextLines.count)")
            print("   - 온디바이스 레이블: \(imageLabels.count)")
            
            // 카드 저장은 ScreenshotIndexer/ScreenshotMonitor의 CardManager에서 한 번만 수행한다.
            completion(.success(processingResult))
        }
    }

    /// 외부 AI를 사용할 수 없을 때도 OCR 결과를 잃지 않고 기본 카드로 보존한다.
    private func makeOCRFallbackCard(
        ocrText: String,
        ocrTextLines: [String],
        imageLabels _: [ImageLabel]
    ) -> Card {
        let normalizedLines = ocrTextLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let firstLine = normalizedLines.first(where: { !isTimeOnlyTitle($0) })
            ?? "내용을 확인해주세요"
        let title = String(firstLine.prefix(50))
        let normalizedText = ocrText
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let summary = String(normalizedText.prefix(150))
        let cardId = UUID()
        let imageName = cardId.uuidString

        return Card(
            id: cardId,
            title: title,
            summary: summary,
            category: .etc,
            subcategory: "기타",
            tags: ["자동 생성"],
            fields: ["분류 상태": "내용 확인 필요"],
            thumbnailURL: imageName,
            screenshotURLs: [imageName]
        )
    }

    private func isTimeOnlyTitle(_ text: String) -> Bool {
        let pattern = #"^\s*(?:(?:[01]?\d|2[0-3]):[0-5]\d)(?:\s*(?:AM|PM|오전|오후))?\s*$"#
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    /// GPT 프롬프트 생성 (Caplog 전용 - JSON only)
    private func makeGPTPrompt(from text: String, imageLabels: [ImageLabel]) -> String {
        // 만에 하나 OCR 텍스트에 """ 가 들어있을 경우 프롬프트가 깨지지 않도록 이스케이프
        let safe = text.replacingOccurrences(of: "\"\"\"", with: #"\"\"\""#)
        
        // Apple Vision 온디바이스 분류 레이블 포맷팅
        let labelsInfo: String
        if imageLabels.isEmpty {
            labelsInfo = "없음"
        } else {
            labelsInfo = imageLabels
                .map { "\($0.description) (\($0.confidencePercentage))" }
                .joined(separator: ", ")
        }
        
        return """
        당신은 개인정보가 가려진 OCR 텍스트와 기기 내 Apple Vision 이미지 분류 정보를 종합하여 핵심 정보를 구조화된 JSON으로 변환하는 역할을 합니다.
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
        2. Apple Vision 온디바이스 레이블: 신뢰도 50% 이상인 객체/개념
        3. 중복 제거: 같은 태그가 여러 번 나오면 하나만 사용
        
        예시:
        - fields에서 "place_name": "이마트24" → #이마트24 태그 추가
        - fields에서 "menu_or_keyword": "떡볶이, 튀김" → #떡볶이 #튀김 태그 추가
        - Vision에서 "신용카드 (95.3%)" → #신용카드 태그 추가
        
        [제목과 요약 생성 규칙]
        - 제목: 가장 중요한 정보 1줄. 가게/브랜드 이름이 있으면 반드시 포함 (예: "이마트24 5천원권", "목화반점 맛집", "스타벅스 아메리카노 1+1")
        - 상태 표시줄의 시간(예: "4:24", "5:13 PM")만으로 제목을 만들지 마세요.
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
        
        **Apple Vision 온디바이스 이미지 분석 (객체/개념 분류):**
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
        imageLabels: [ImageLabel]
    ) -> Card? {
        let debug = "[Caplog GPT 디버그]"
        print("\(debug) 1단계: GPT 원본 응답 수신, 길이=\(gptResult.count)")
        
        if gptResult.hasPrefix("❌") {
            print("\(debug) 실패: GPT가 에러 문자열 반환 → \(gptResult.prefix(80))")
            return nil
        }
        
        var cleanedJSON = stripFences(gptResult)
        if cleanedJSON.hasPrefix("\u{FEFF}") { cleanedJSON = String(cleanedJSON.dropFirst()) }
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        print("\(debug) 2단계: stripFences 후 길이=\(cleanedJSON.count)")
        
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
            print("\(debug) 실패: JSON 파싱 불가")
            return nil
        }
        
        print("\(debug) 4단계: JSON 키 목록: \(json.keys.sorted().joined(separator: ", "))")
        
        let catMain = json["category_main"]
        let titleVal = json["title"]
        guard let categoryMain = catMain as? String,
              let title = titleVal as? String, !title.isEmpty else {
            print("\(debug) 실패: category_main 또는 title 필드 누락")
            return nil
        }
        
        print("\(debug) 5단계: 필수 필드 확인 완료. category_main=\(categoryMain)")
        
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
        
        // 온디바이스 이미지 분류 레이블은 핵심 필드 키워드 뒤에 보조로 추가합니다.
        // 일반적인 이미지 레이블이 카드의 중요한 키워드를 밀어내지 않도록 신뢰도와 개수를 제한합니다.
        let highConfidenceLabels = imageLabels
            .filter { $0.confidence >= 0.7 }
            .map { $0.description }
        tags.append(contentsOf: highConfidenceLabels)

        let normalizedTags = normalizedKeywords(from: tags, limit: 5)
        
        let cardId = UUID()
        let imageName = cardId.uuidString
        
        return Card(
            id: cardId,
            title: title,
            summary: summary,
            category: category,
            subcategory: subcategory,
            tags: normalizedTags,
            fields: fields,
            thumbnailURL: imageName,
            screenshotURLs: [imageName]
        )
    }

    /// 키워드는 추출 우선순서를 유지하면서 중복·공백·불필요한 해시 기호를 정리합니다.
    private func normalizedKeywords(from candidates: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for candidate in candidates {
            let keyword = candidate
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            guard !keyword.isEmpty else { continue }

            let comparisonKey = keyword.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            guard seen.insert(comparisonKey).inserted else { continue }

            result.append(keyword)
            if result.count == limit { break }
        }

        return result
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
