//
//  ContentView.swift
//  Dictionary+
//
//  Created by Benji on 2025-08-11.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - View utility

extension View {
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var selectedDictionary: DictionaryItem? = .allCases.first
    @State private var isLoading: Bool = false
    @State private var entry: DictionaryAPI.Entry?
    @State private var fetchErrorMessage: String?
    @State private var showToolbarSearch: Bool = false
    @State private var showResult: Bool = false
    @State private var showDescription: Bool = false
    @State private var suggestions: [String] = []
    @State private var suggestionTask: Task<Void, Never>? = nil
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDictionary: $selectedDictionary)
        } detail: {
            DetailView(
                searchText: $searchText,
                isLoading: isLoading,
                entry: entry,
                errorMessage: fetchErrorMessage,
                showToolbarSearch: showToolbarSearch,
                showResult: showResult,
                showDescription: showDescription,
                suggestions: suggestions,
                onSubmit: { performSearch() }
            )
        }
        .applyIf(showToolbarSearch) { view in
            view
                .searchable(text: $searchText, placement: .toolbar, prompt: "Search")
                .searchSuggestions {
                    ForEach(suggestions.prefix(10), id: \.self) { suggestion in
                        Text(suggestion).searchCompletion(suggestion)
                    }
                }
                .onSubmit(of: .search) { performSearch(fromToolbar: true) }
        }
        .onChange(of: searchText) { newValue in
            // Debounced suggestions for both main and toolbar search
            suggestionTask?.cancel()
            suggestions.removeAll()
            let trimmed = newValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard trimmed.count >= 2 else { return }
            suggestionTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                let results: [String]
                if settings.enableSuggestions {
                    results = (try? await SuggestionAPI.fetchSuggestions(prefix: trimmed, limit: 10)) ?? []
                } else {
                    results = []
                }
                if !Task.isCancelled {
                    suggestions = results
                }
            }
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
    case german = "German"
    case spanish = "Spanish"
    case italian = "Italian"
    case portuguese = "Portuguese"
    case dutch = "Dutch"

    var id: String { rawValue }

    var apiLanguageCode: String {
        switch self {
        case .english, .englishThesaurus: return "en"
        case .swedish: return "sv"
        case .swedishEnglish: return "en" // API supports language code, not bilingual
        case .french: return "fr"
        case .german: return "de"
        case .spanish: return "es"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .dutch: return "nl"
        }
    }

    static var defaultEnabled: [DictionaryItem] {
        [.english, .englishThesaurus, .swedish, .french]
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedDictionary: DictionaryItem?
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        List(selection: $selectedDictionary) {
            Section("Dictionaries") {
                ForEach(DictionaryItem.allCases.filter { settings.enabledDictionaries.contains($0.rawValue) }) { item in
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
    var entry: DictionaryAPI.Entry?
    var errorMessage: String?
    var showToolbarSearch: Bool
    var showResult: Bool
    var showDescription: Bool
    var suggestions: [String]
    var onSubmit: () -> Void

    // Rotating title for empty state
    @State private var rotatingIndex: Int = 0
    @State private var rotateTask: Task<Void, Never>? = nil
    private let rotatingTitles: [String] = ["Dictionary", "Synonyms", "Translations", "Pronunciation", "Origins"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Top-left result area
            if showResult {
                ResultView(entry: entry, showDescription: showDescription)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .transition(.asymmetric(insertion: .offset(y: 24).combined(with: .opacity), removal: .opacity))
            }

            // Centered overlay for search/loading/error when toolbar search not yet shown
            if !showToolbarSearch {
                VStack(spacing: 8) {
                    ZStack {
                        Text(rotatingTitles[rotatingIndex])
                            .font(.largeTitle).bold()
                            .foregroundStyle(.primary)
                            .id(rotatingIndex)
                            .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 0) {
                        TextField("Search", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: 420)
                            .onSubmit(onSubmit)
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(suggestions.prefix(8), id: \.self) { suggestion in
                                    Button(action: {
                                        searchText = suggestion
                                        onSubmit()
                                    }) {
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundStyle(.secondary)
                                            Text(suggestion)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    Divider().opacity(0.2)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.quaternary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(.tertiary, lineWidth: 1)
                            )
                            .frame(maxWidth: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(.top, 4)
                        }
                    }

                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.secondary)
                    } else {
                        Text("Type to search…").foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    startTitleRotation()
                }
                .onDisappear {
                    stopTitleRotation()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

private extension DetailView {
    func startTitleRotation() {
        rotateTask?.cancel()
        rotatingIndex = 0
        rotateTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.easeInOut(duration: 0.35)) {
                    rotatingIndex = (rotatingIndex + 1) % rotatingTitles.count
                }
            }
        }
    }

    func stopTitleRotation() {
        rotateTask?.cancel()
        rotateTask = nil
    }
}

// MARK: - Networking

extension ContentView {
    func performSearch(fromToolbar: Bool = false) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isLoading = true
        fetchErrorMessage = nil
        entry = nil
        showResult = false
        showToolbarSearch = true
        showDescription = false

        Task { @MainActor in
            do {
                let lang = selectedDictionary?.apiLanguageCode ?? "en"
                let entry = try await DictionaryAPI.fetchEntry(for: query, languageCode: lang)
                self.entry = entry
                isLoading = false
                withAnimation(.interpolatingSpring(stiffness: 160, damping: 16)) {
                    showResult = true
                }
                // Stagger: reveal description slightly after the title
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 16)) {
                        showDescription = true
                    }
                }
                #if os(macOS)
                if fromToolbar {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
                #endif
            } catch {
                fetchErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Result View

struct ResultView: View {
    let entry: DictionaryAPI.Entry?
    let showDescription: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let entry {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(entry.word)
                        .font(.largeTitle).bold()
                    if let phon = entry.phonetic, !phon.isEmpty {
                        Text(phon)
                            .foregroundStyle(.secondary)
                    }
                }

                if let meanings = entry.meanings, !meanings.isEmpty, showDescription {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(meanings.indices, id: \.self) { index in
                                MeaningCardView(meaning: meanings[index])
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.trailing, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .transition(.asymmetric(insertion: .offset(y: 10).combined(with: .opacity), removal: .opacity))
                }
            }
        }
    }
}

struct MeaningView: View {
    let meaning: DictionaryAPI.Meaning

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pos = meaning.partOfSpeech, !pos.isEmpty {
                Text(pos.capitalized)
                    .font(.headline)
            }
            if !meaning.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(meaning.definitions.indices, id: \.self) { i in
                        DefinitionRow(definition: meaning.definitions[i])
                    }
                }
            }
        }
    }
}

struct DefinitionRow: View {
    let definition: DictionaryAPI.Definition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(definition.definition)
            if let example = definition.example, !example.isEmpty {
                Text(example)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Card style container for meanings

struct MeaningCardView: View {
    let meaning: DictionaryAPI.Meaning

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MeaningView(meaning: meaning)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.tertiary, lineWidth: 1)
        )
    }
}
