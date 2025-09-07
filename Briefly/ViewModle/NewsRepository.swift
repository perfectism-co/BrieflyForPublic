//
//  NewsRepository.swift
//  Briefly
//
//  
//

import Foundation
import CoreData

class NewsRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // 儲存新聞 (自動判斷是否超過一個月，並避免重複存)
    func saveNewsItem(_ item: NewsItem) {
        // 1. 過濾掉超過一個月的新聞
        if let pubDate = item.pubDate {
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            if pubDate < oneMonthAgo {
                return
            }
        }

        // 2. 檢查 Core Data 是否已有相同 link 的新聞
        let fetchRequest: NSFetchRequest<NewsEntity> = NewsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "link == %@", item.link)

        if let existing = try? context.fetch(fetchRequest), !existing.isEmpty {
            return // 已存在 → 不存
        }

        // 3. 不存在才存
        _ = item.toEntity(context: context)

        do {
            try context.save()
        } catch {
            print("❌ CoreData save error: \(error)")
        }
    }


    // 刪除舊新聞 (超過一個月)
    func deleteOldNews() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NewsEntity.fetchRequest()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        fetchRequest.predicate = NSPredicate(format: "pubDate < %@", oneMonthAgo as NSDate)

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("❌ CoreData delete error: \(error)")
        }
    }

    // 讀取所有新聞
    func fetchAllNews() -> [NewsItem] {
        let request: NSFetchRequest<NewsEntity> = NewsEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toNewsItem() }
        } catch {
            print("❌ CoreData fetch error: \(error)")
            return []
        }
    }
}
