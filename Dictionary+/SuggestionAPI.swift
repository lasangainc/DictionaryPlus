import Foundation

struct SuggestionAPI {
    struct Suggestion: Decodable {
        let word: String
    }

    static func fetchSuggestions(prefix: String, limit: Int = 10) async throws -> [String] {
        let encoded = prefix.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prefix
        guard let url = URL(string: "https://api.datamuse.com/sug?s=\(encoded)&max=\(limit)") else {
            return []
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return []
        }
        let suggestions = try? JSONDecoder().decode([Suggestion].self, from: data)
        return suggestions?.map { $0.word } ?? []
    }
}


