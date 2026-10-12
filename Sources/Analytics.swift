import Foundation

enum AnalyticsEventName: String, Codable {
    case appOpen = "app_open"
    case styleSelected = "style_selected"
    case characterSelected = "character_selected"
    case basicVariantSelected = "basic_variant_selected"
}

final class AnonymousAnalytics {
    static let shared = AnonymousAnalytics()

    private enum DefaultsKey {
        static let consent = "analytics.consent"
        static let installationID = "analytics.installation.id"
    }

    private struct EventPayload: Encodable {
        let id: UUID
        let installID: UUID
        let eventName: String
        let appVersion: String
        let style: String?
        let selection: String?
        let platform: String

        enum CodingKeys: String, CodingKey {
            case id
            case installID = "install_id"
            case eventName = "event_name"
            case appVersion = "app_version"
            case style
            case selection
            case platform
        }
    }

    private let defaults = UserDefaults.standard
    private let session = URLSession(configuration: .ephemeral)
    private let endpoint: URL?
    private let publishableKey: String

    let isSuppressed: Bool

    private init() {
        let arguments = CommandLine.arguments
        isSuppressed = arguments.contains("--export-previews")

        let baseURL = (Bundle.main.object(forInfoDictionaryKey: "OACSupabaseURL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        publishableKey = (Bundle.main.object(forInfoDictionaryKey: "OACSupabasePublishableKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let url = URL(string: baseURL), !baseURL.isEmpty {
            endpoint = url
                .appendingPathComponent("rest")
                .appendingPathComponent("v1")
                .appendingPathComponent("analytics_events")
        } else {
            endpoint = nil
        }
    }

    var isConfigured: Bool {
        endpoint != nil && publishableKey.hasPrefix("sb_publishable_")
    }

    var consent: Bool? {
        guard defaults.object(forKey: DefaultsKey.consent) != nil else { return nil }
        return defaults.bool(forKey: DefaultsKey.consent)
    }

    func setConsent(_ enabled: Bool) {
        defaults.set(enabled, forKey: DefaultsKey.consent)
    }

    func track(
        _ event: AnalyticsEventName,
        style: String? = nil,
        selection: String? = nil
    ) {
        guard !isSuppressed, consent == true, isConfigured, let endpoint else { return }

        let payload = EventPayload(
            id: UUID(),
            installID: installationID,
            eventName: event.rawValue,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            style: style,
            selection: selection,
            platform: "macos"
        )

        guard let body = try? JSONEncoder().encode(payload) else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")

        session.dataTask(with: request).resume()
    }

    private var installationID: UUID {
        if let stored = defaults.string(forKey: DefaultsKey.installationID),
           let value = UUID(uuidString: stored) {
            return value
        }

        let value = UUID()
        defaults.set(value.uuidString, forKey: DefaultsKey.installationID)
        return value
    }
}
