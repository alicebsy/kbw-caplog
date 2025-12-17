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
                print("❌ OCR 에러로 인한 실패: \(ocrError.localizedDescription)")
                completion(.failure(.ocrFailed(ocrError.localizedDescription)))
                return
            }
            
            if ocrText.isEmpty {
                print("❌ OCR 텍스트가 비어있음")
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
        
        guard let apiKey = Bundle.main.infoDictionary?["GPT_API_KEY"] as? String else {
            print("❌ GPT_API_KEY가 Info.plist에 없습니다.")
            completion(.failure(.gptFailed("GPT API Key가 없습니다.")))
            return
        }
        
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
                print("❌ Card 파싱 실패")
                completion(.failure(.cardCreationFailed("GPT 응답 파싱 실패")))
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
        
        [공통 스키마]
        {
          "category_main": "",   // Info | Contents | Social | Log | Music | Art | Unknown
          "category_sub": "",    // 아래 리스트에서 정확히 선택
          "title": "",           // 카드 제목 (짧고 핵심, 최대 50자)
          "summary": "",         // 1~2문장 요약 (최대 150자)
          "fields": {}           // 카테고리별 상세 (최대 4~5개)
        }
        
        [category_sub 소분류 목록 - 반드시 이 중에서 선택]
        Info: 맛집, 카페, 공부, 공고, 취업, 필기, 뉴스, 문화생활, 운동/건강, 기타, 쿠폰
        Contents: 글, 짤
        Social: 채팅, 사진
        Log: 기록, 활동
        Music: 음악
        Art: 미술
        Unknown: 기타
        
        [카테고리별 필드 정의(최대 4~5개)]
        1) Info (정보)
           - 맛집/카페: place_name, address(optional), menu_or_keyword(optional), valid_until(optional), benefit(optional)
           - 공부/공고/취업/필기: topic, organization(optional), deadline(optional), notes(optional)
           - 쿠폰: brand, benefit, valid_until(optional), conditions(optional)
        
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
        - 제목: 가장 중요한 정보 1줄 (예: "이마트24 5천원권", "목화반점 맛집")
        - 요약: 사용자가 한눈에 이해할 수 있는 1~2문장 (예: "이마트24에서 사용할 수 있는 5천원 모바일금액권입니다.")
        
        [입력 정보]
        
        **OCR 텍스트:**
        \"\"\"
        \(safe)
        \"\"\"
        
        **Google Vision 이미지 분석 (객체/개념 탐지):**
        \(labelsInfo)
        
        [출력 예시]
        {
          "category_main": "Info",
          "category_sub": "쿠폰",
          "title": "이마트24 5천원권",
          "summary": "이마트24에서 사용할 수 있는 5천원 모바일금액권입니다.",
          "fields": {
            "brand": "이마트24",
            "benefit": "5천원권",
            "valid_until": "2025-11-20",
            "conditions": "모바일 금액권"
          }
        }
        
        주의: 위의 필드(brand, benefit 등)에서 태그가 자동으로 추출됩니다.
        """
    }
    
    /// GPT 결과를 Card 객체로 변환 (새 스키마)
    private func parseGPTResultToCard(
        gptResult: String,
        extractedText: String,
        visionLabels: [VisionLabel],
        image: UIImage
    ) -> Card? {
        print("🔍 GPT 원본 응답:")
        print(gptResult)
        print(String(repeating: "=", count: 50))
        
        // JSON 이외 문자가 섞였을 때 방어용
        let cleanedJSON = stripFences(gptResult)
        
        print("🧹 정제된 JSON:")
        print(cleanedJSON)
        print(String(repeating: "=", count: 50))
        
        // JSON 파싱
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("❌ JSON 파싱 실패")
            print("원본 길이: \(gptResult.count)")
            print("정제 후 길이: \(cleanedJSON.count)")
            return nil
        }
        
        print("✅ JSON 파싱 성공")
        print("JSON 키: \(json.keys)")
        
        // 필드 추출 (새 스키마)
        guard let categoryMain = json["category_main"] as? String,
              let title = json["title"] as? String else {
            print("❌ 필수 필드 누락")
            print("category_main: \(json["category_main"] as? String ?? "nil")")
            print("title: \(json["title"] as? String ?? "nil")")
            return nil
        }
        
        print("✅ 필수 필드 확인 완료")
        print("category_main: \(categoryMain)")
        print("title: \(title)")
        
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
    
    /// JSON 이외 문자가 섞였을 때 방어용
    private func stripFences(_ s: String) -> String {
        s.replacingOccurrences(of: "```json", with: "")
         .replacingOccurrences(of: "```", with: "")
         .trimmingCharacters(in: .whitespacesAndNewlines)
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
