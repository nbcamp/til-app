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
    let primary: Bool
    let keywords: [Keyword]
    let lastPublishedAt: Date
    let createdAt: Date
}

struct CreateBlogInput: Codable {
    let name: String
    let url: String
    let rss: String
    let keywords: [Keyword]
}

struct UpdateBlogInput: Codable {
    let name: String?
    let primary: Bool?
    let keywords: [Keyword]?
}
