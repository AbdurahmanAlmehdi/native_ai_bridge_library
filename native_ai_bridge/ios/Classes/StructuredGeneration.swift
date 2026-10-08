import Flutter
import ImageIO
import UIKit

#if canImport(FoundationModels)
    import FoundationModels
#endif

extension NativeAiBridgePlugin {

    func capabilities() -> [String: Any] {
        var info: [String: Any] = [
            "available": false,
            "vision": false,
            "supportsCurrentLocale": false,
            "supportedLanguages": [String](),
        ]
        if let error = checkAvailability() {
            info["code"] = error.code
            info["reason"] = error.message
            return info
        }
        guard #available(iOS 26.0, *) else { return info }

        let model = SystemLanguageModel.default
        info["available"] = true
        info["reason"] = "Available"
        info["supportsCurrentLocale"] = model.supportedLanguages.contains(
            Locale.current.language)
        info["supportedLanguages"] = model.supportedLanguages.map { $0.maximalIdentifier }
        #if compiler(>=6.4)
            if #available(iOS 27.0, *) {
                info["supportsCurrentLocale"] = model.supportsLocale()
                info["vision"] = model.capabilities.contains(.vision)
            }
        #endif
        return info
    }

    @available(iOS 26.0, *)
    func generateStructured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let promptText = args["prompt"] as? String,
            let schemaMap = args["schema"] as? [String: Any]
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS", message: "prompt and schema are required",
                    details: nil))
            return
        }
        let images = (args["images"] as? [FlutterStandardTypedData])?.map(\.data) ?? []
        let instructions = args["instructions"] as? String
        let schemaName = args["schemaName"] as? String ?? "Response"
        let options = options(from: args) ?? GenerationOptions()

        Task {
            let output: Any
            do {
                let root = try DynamicSchemaBuilder.build(schemaMap, name: schemaName)
                let schema = try GenerationSchema(root: root, dependencies: [])
                let session =
                    instructions.map { LanguageModelSession(instructions: $0) }
                    ?? LanguageModelSession()
                let content: GeneratedContent
                if images.isEmpty {
                    content = try await session.respond(
                        to: promptText, schema: schema, options: options
                    ).content
                } else {
                    content = try await respondWithImages(
                        session: session, prompt: promptText, images: images, schema: schema,
                        options: options)
                }
                output = content.jsonString
            } catch {
                output = flutterError(for: error)
            }
            await MainActor.run { result(output) }
        }
    }

    @available(iOS 26.0, *)
    private func respondWithImages(
        session: LanguageModelSession, prompt: String, images: [Data],
        schema: GenerationSchema, options: GenerationOptions
    ) async throws -> GeneratedContent {
        #if compiler(>=6.4)
            if #available(iOS 27.0, *) {
                guard SystemLanguageModel.default.capabilities.contains(.vision) else {
                    throw BridgeError(
                        code: "VISION_UNSUPPORTED",
                        message: "The on-device model cannot read images on this device.")
                }
                let attachments = try images.map { data -> Attachment<ImageAttachmentContent> in
                    guard let image = UIImage(data: data), let cgImage = image.cgImage else {
                        throw BridgeError(
                            code: "INVALID_IMAGE", message: "Image bytes could not be decoded.")
                    }
                    return Attachment(cgImage, orientation: image.imageOrientation.cgOrientation)
                }
                return try await session.respond(
                    to: Prompt {
                        attachments
                        prompt
                    },
                    schema: schema,
                    options: options
                ).content
            }
        #endif
        throw BridgeError(
            code: "VISION_UNSUPPORTED", message: "Image input requires iOS 27.0 or later.")
    }
}

@available(iOS 26.0, *)
enum DynamicSchemaBuilder {
    static func build(_ node: [String: Any], name: String) throws -> DynamicGenerationSchema {
        let description = node["description"] as? String

        if let choices = node["enum"] as? [String] {
            return DynamicGenerationSchema(name: name, description: description, anyOf: choices)
        }

        switch node["type"] as? String {
        case "object":
            let properties = node["properties"] as? [String: Any] ?? [:]
            let required = Set(node["required"] as? [String] ?? [])
            let order = node["propertyOrder"] as? [String] ?? properties.keys.sorted()
            let built = try order.compactMap { key -> DynamicGenerationSchema.Property? in
                guard let child = properties[key] as? [String: Any] else { return nil }
                return DynamicGenerationSchema.Property(
                    name: key,
                    description: child["description"] as? String,
                    schema: try build(child, name: "\(name)_\(key)"),
                    isOptional: !required.contains(key))
            }
            return DynamicGenerationSchema(name: name, description: description, properties: built)
        case "array":
            guard let items = node["items"] as? [String: Any] else {
                throw BridgeError(code: "INVALID_SCHEMA", message: "Array schema \(name) has no items.")
            }
            return DynamicGenerationSchema(
                arrayOf: try build(items, name: "\(name)_item"),
                minimumElements: node["minItems"] as? Int,
                maximumElements: node["maxItems"] as? Int)
        case "string":
            return DynamicGenerationSchema(type: String.self)
        case "number":
            return DynamicGenerationSchema(type: Double.self)
        case "integer":
            return DynamicGenerationSchema(type: Int.self)
        case "boolean":
            return DynamicGenerationSchema(type: Bool.self)
        default:
            throw BridgeError(
                code: "INVALID_SCHEMA",
                message: "Unsupported schema type \(node["type"] ?? "nil") at \(name).")
        }
    }
}

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    extension LanguageModelSession.GenerationError {
        var flutterCode: String {
            switch self {
            case .exceededContextWindowSize: "CONTEXT_WINDOW_EXCEEDED"
            case .assetsUnavailable: "MODEL_NOT_READY"
            case .guardrailViolation: "GUARDRAIL_VIOLATION"
            case .unsupportedLanguageOrLocale: "UNSUPPORTED_LANGUAGE"
            case .rateLimited: "RATE_LIMITED"
            default: "GENERATION_ERROR"
            }
        }
    }

    #if compiler(>=6.4)
        @available(iOS 27.0, *)
        extension LanguageModelError {
            var flutterCode: String {
                switch self {
                case .contextSizeExceeded: "CONTEXT_WINDOW_EXCEEDED"
                case .rateLimited: "RATE_LIMITED"
                case .guardrailViolation: "GUARDRAIL_VIOLATION"
                case .unsupportedLanguageOrLocale: "UNSUPPORTED_LANGUAGE"
                case .unsupportedCapability: "UNSUPPORTED_CAPABILITY"
                case .timeout: "TIMEOUT_ERROR"
                default: "GENERATION_ERROR"
                }
            }
        }
    #endif
#endif

extension UIImage.Orientation {
    var cgOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
