import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            DictionariesSettingsView()
                .tabItem { Label("Dictionaries", systemImage: "book") }
        }
        .padding(20)
        .frame(width: 520, height: 380)
    }
}

private struct GeneralSettingsView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Toggle("Enable search suggestions", isOn: $settings.enableSuggestions)
        }
    }
}

private struct DictionariesSettingsView: View {
    @StateObject private var settings = AppSettings.shared

    private let all = DictionaryItem.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enabled dictionaries")
                .font(.headline)
            List {
                ForEach(all) { item in
                    HStack {
                        Label(item.rawValue, systemImage: "character.book.closed.fill")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.enabledDictionaries.contains(item.rawValue) },
                            set: { isOn in
                                if isOn { settings.enabledDictionaries.insert(item.rawValue) }
                                else { settings.enabledDictionaries.remove(item.rawValue) }
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }
        }
    }
}


