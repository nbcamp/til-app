import Foundation

struct Keyword: Codable {
    let keyword: String
    let tags: [String]
}

struct Blog: Codable {
    let id: Int
    let name: String
    let url: String
    let rss: String
    let main: Bool
    let keywords: [Keyword]
    let lastPublishedAt: Date?
    let createdAt: Date
}

struct CreateBlogInput: Codable {
    let name: String
    let url: String
    let rss: String
    let keywords: [KeywordInput]
}

struct UpdateBlogInput: Codable {
    let name: String?
    let keywords: [KeywordInput]?
}

struct KeywordInput: Codable, Equatable {
    var keyword: String
    var tags: [String]

    init(keyword: String, tags: [String]) {
        self.keyword = keyword
        self.tags = tags
    }

    init(from keyword: Keyword) {
        self.keyword = keyword.keyword
        self.tags = keyword.tags
    }
    
    static func == (lhs: KeywordInput, rhs: KeywordInput) -> Bool {
        return lhs.keyword == rhs.keyword && lhs.tags == rhs.tags
    }
}
