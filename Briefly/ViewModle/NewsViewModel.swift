//
//  NewsViewModel.swift
//  Briefly
//
//  
//

import Foundation
import CoreData
import Combine

@MainActor
class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []

    private let repository: NewsRepository
    private let fetcher: RSSFetcher

    init(context: NSManagedObjectContext) {
        self.repository = NewsRepository(context: context)
        self.fetcher = RSSFetcher()
        
        // 當 RSSFetcher 的 newsItems 改變時，存進 Core Data
        self.fetcher.$newsItems
            .sink { [weak self] newItems in
                guard let self = self else { return }
                for item in newItems {
                    self.repository.saveNewsItem(item)
                }
                self.newsItems = self.repository.fetchAllNews()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func fetchRSS() async {
        await fetcher.fetchRSS()
        
        // 將抓到的新新聞存進 Core Data（自動避免重複）
        for item in fetcher.newsItems {
            repository.saveNewsItem(item)
        }

        // 更新 ViewModel 的 newsItems
        newsItems = repository.fetchAllNews()

        // 刪掉超過一個月的新聞
        repository.deleteOldNews()
    }
    
}

