//
//  NewsItem.swift
//  Briefly
//
//  Created by macmini on 2025/5/23.
//

import Foundation
import CoreData

struct NewsItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let summary: String
    let imageURL: String?
    let pubDate: Date?
    let link: String

    // 初始化時如果沒有傳 id，會自動生成
    init(id: UUID = UUID(),
         title: String,
         summary: String,
         imageURL: String? = nil,
         pubDate: Date?,
         link: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.imageURL = imageURL
        self.pubDate = pubDate
        self.link = link
    }

    // 對比 id
    static func ==(lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.id == rhs.id
    }
}



extension NewsEntity {
    func toNewsItem() -> NewsItem {
        NewsItem(
            id: id ?? UUID(),
            title: title ?? "",
            summary: summary ?? "",
            imageURL: imageURL,
            pubDate: pubDate,
            link: link ?? ""
        )
    }
}

extension NewsItem {
    func toEntity(context: NSManagedObjectContext) -> NewsEntity {
        let entity = NewsEntity(context: context)
        entity.id = id
        entity.title = title
        entity.summary = summary
        entity.imageURL = imageURL
        entity.pubDate = pubDate
        entity.link = link
        return entity
    }
}
