import Foundation

enum DictionaryAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case emptyResults

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .requestFailed: return "Request failed."
        case .emptyResults: return "No results found."
        }
    }
}

struct DictionaryAPI {
    struct Entry: Decodable {
        let word: String
        let meanings: [Meaning]?
    }

    struct Meaning: Decodable {
        let partOfSpeech: String?
        let definitions: [Definition]
    }

    struct Definition: Decodable {
        let definition: String
    }

    static func fetchEntry(for word: String, languageCode: String = "en") async throws -> Entry {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/\(languageCode)/\(encodedWord)") else {
            throw DictionaryAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw DictionaryAPIError.requestFailed
        }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 404 {
                throw DictionaryAPIError.emptyResults
            }
            throw DictionaryAPIError.requestFailed
        }

        let decoder = JSONDecoder()
        let entries = try decoder.decode([Entry].self, from: data)
        guard let first = entries.first else {
            throw DictionaryAPIError.emptyResults
        }
        return first
    }
}

extension DictionaryAPI.Entry {
    var primaryDefinition: String? {
        for meaning in meanings ?? [] {
            if let text = meaning.definitions.first?.definition, !text.isEmpty {
                return text
            }
        }
        return nil
    }
}


