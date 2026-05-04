import Foundation
import os.log

/// Internal logger for the SDK. Only outputs when `enableLogging` is `true`.
struct Logger: Sendable {

    private let enabled: Bool
    private static let subsystem = "com.aicoach.sdk"
    private static let category = "AICoachSDK"
    private static let consolePrefix = "[AICoachSDK]"

    #if DEBUG
    private static let allowsVerbosePayloadLogging = true
    #else
    private static let allowsVerbosePayloadLogging = false
    #endif

    init(enabled: Bool) {
        self.enabled = enabled
    }

    func log(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        write(message(), isError: false)
    }

    func error(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        write(message(), isError: true)
    }

    func logPayload(_ label: String, data: Data) {
        guard enabled, Self.allowsVerbosePayloadLogging else { return }
        write("\(label): \(redactedSummary(for: data))", isError: false)
    }

    private func write(_ message: String, isError: Bool) {
        let logger = os.Logger(subsystem: Self.subsystem, category: Self.category)
        if isError {
            logger.error("\(message, privacy: .private(mask: .hash))")
        } else {
            logger.debug("\(message, privacy: .private(mask: .hash))")
        }

        #if DEBUG
        if isError {
            print("\(Self.consolePrefix) ⚠️ \(message)")
        } else {
            print("\(Self.consolePrefix) \(message)")
        }
        #endif
    }

    private func redactedSummary(for data: Data) -> String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return "<redacted \(data.count) bytes>"
        }

        return summarize(jsonObject)
    }

    private func summarize(_ value: Any) -> String {
        switch value {
        case let dictionary as [String: Any]:
            let fields = dictionary.keys.sorted().map { "\($0)=<redacted>" }.joined(separator: ", ")
            return "{\(fields)}"
        case let array as [Any]:
            return "[\(array.count) redacted item(s)]"
        case _ as String:
            return "<redacted string>"
        case _ as NSNumber:
            return "<redacted number>"
        case _ as NSNull:
            return "null"
        default:
            return "<redacted value>"
        }
    }
}
