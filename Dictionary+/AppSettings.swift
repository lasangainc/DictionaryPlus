import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var enableSuggestions: Bool {
        didSet { UserDefaults.standard.set(enableSuggestions, forKey: Keys.enableSuggestions) }
    }

    @Published var enabledDictionaries: Set<String> {
        didSet {
            let array = Array(enabledDictionaries)
            UserDefaults.standard.set(array, forKey: Keys.enabledDictionaries)
        }
    }

    private struct Keys {
        static let enableSuggestions = "settings.enableSuggestions"
        static let enabledDictionaries = "settings.enabledDictionaries"
    }

    private init() {
        let savedEnableSuggestions = UserDefaults.standard.object(forKey: Keys.enableSuggestions) as? Bool
        self.enableSuggestions = savedEnableSuggestions ?? true

        if let saved = UserDefaults.standard.array(forKey: Keys.enabledDictionaries) as? [String] {
            self.enabledDictionaries = Set(saved)
        } else {
            // Default: enable common dictionaries
            self.enabledDictionaries = Set(DictionaryItem.defaultEnabled.map { $0.rawValue })
            let array = Array(enabledDictionaries)
            UserDefaults.standard.set(array, forKey: Keys.enabledDictionaries)
        }
    }
}


