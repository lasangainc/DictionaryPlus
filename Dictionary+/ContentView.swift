//
//  ContentView.swift
//  Dictionary+
//
//  Created by Benji on 2025-08-11.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var selectedDictionary: DictionaryItem? = .allCases.first
    @State private var isLoading: Bool = false
    @State private var fetchedWord: String = ""
    @State private var fetchedDefinition: String = ""
    @State private var fetchErrorMessage: String?

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDictionary: $selectedDictionary)
        } detail: {
            DetailView(
                searchText: $searchText,
                isLoading: isLoading,
                fetchedWord: fetchedWord,
                fetchedDefinition: fetchedDefinition,
                errorMessage: fetchErrorMessage,
                onSubmit: performSearch
            )
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Models

enum DictionaryItem: String, CaseIterable, Identifiable {
    case englishThesaurus = "English Thesaurus"
    case swedish = "Swedish"
    case swedishEnglish = "Swedish – English"
    case english = "English"
    case french = "French"

    var id: String { rawValue }

    var apiLanguageCode: String {
        switch self {
        case .english, .englishThesaurus: return "en"
        case .swedish: return "sv"
        case .swedishEnglish: return "en" // API supports language code, not bilingual
        case .french: return "fr"
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedDictionary: DictionaryItem?

    var body: some View {
        List(selection: $selectedDictionary) {
            Section("Dictionaries") {
                ForEach(DictionaryItem.allCases) { item in
                    Label(item.rawValue, systemImage: "character.book.closed.fill")
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Detail

struct DetailView: View {
    @Binding var searchText: String
    var isLoading: Bool
    var fetchedWord: String
    var fetchedDefinition: String
    var errorMessage: String?
    var onSubmit: () -> Void

    var body: some View {
        ZStack {
            Color.clear
            VStack(spacing: 16) {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 420)
                    .onSubmit(onSubmit)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                } else if !fetchedWord.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(fetchedWord)
                                .font(.largeTitle).bold()
                            Spacer()
                        }
                        Text(fetchedDefinition)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 24)
                } else {
                    Text("Type to search…")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

// MARK: - Networking

extension ContentView {
    func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isLoading = true
        fetchErrorMessage = nil
        fetchedWord = ""
        fetchedDefinition = ""

        Task { @MainActor in
            do {
                let lang = selectedDictionary?.apiLanguageCode ?? "en"
                let entry = try await DictionaryAPI.fetchEntry(for: query, languageCode: lang)
                fetchedWord = entry.word
                fetchedDefinition = entry.primaryDefinition ?? ""
                isLoading = false
            } catch {
                fetchErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}
