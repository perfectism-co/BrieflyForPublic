//
//  RSSFetcher.swift
//  Briefly
//
//

import Foundation
import FeedKit
import SwiftSoup

@MainActor
class RSSFetcher: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// 使用 async/await 抓取並解析 RSS
    func fetchRSS() async {
        isLoading = true
        defer { isLoading = false } // 確保結束時關閉 loading
        errorMessage = nil

        guard let feedURL = URL(string: "https://udn.com/rssfeed/news/2/6638") else {
            errorMessage = "無效的 RSS 連結"
            return
        }

        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 10 // 避免卡太久

        do {
            // 用 async 抓資料
            let (data, _) = try await URLSession.shared.data(for: request)

            // FeedKit 還是同步 API，所以直接 parse
            let parser = FeedParser(data: data)
            let result = parser.parse()

            switch result {
            case .success(let feed):
                if let rssFeed = feed.rssFeed {
                    let items = rssFeed.items?.compactMap { item -> NewsItem? in
                        // 🚫 排除 UDN VIP 文章
                        if let link = item.link, link.contains("vip.udn.com/vip/story/") {
                            return nil
                        }
                        let imageURL = self.extractImageURLWithSwiftSoup(from: item.description ?? "")
                        return NewsItem(
                            title: item.title ?? "無標題",
                            summary: item.description?.htmlToPlainText ?? "",
                            imageURL: imageURL,
                            pubDate: item.pubDate,
                            link: item.link ?? ""
                        )
                    } ?? []
                    
                    // ✅ 比對新舊第一筆，如果一樣就不更新
                    if let newFirst = items.first,
                       let oldFirst = newsItems.first,
                       newFirst.link == oldFirst.link {
                        print("⚡️ RSS 無新資料，不更新 UI")
                    } else {
                        self.newsItems = items
                    }
                } else {
                    errorMessage = "無法解析 RSS feed"
                }

            case .failure(let error):
                errorMessage = "RSS 解析失敗：\(error.localizedDescription)"
            }
        } catch {
            errorMessage = "下載失敗：\(error.localizedDescription)"
        }
    }

    /// 從 HTML 描述中提取第一張圖片 URL
    private func extractImageURLWithSwiftSoup(from html: String) -> String? {
        do {
            let doc = try SwiftSoup.parse(html)
            if let img = try doc.select("img").first() {
                return try img.attr("src")
            }
        } catch {
            print("SwiftSoup 解析錯誤: \(error)")
        }
        return nil
    }
}


extension String {
    /// 將 HTML 轉成緊密純文字（完全沒有多餘空格或換行）
    var htmlToPlainText: String {
        do {
            // 解析 HTML
            let doc = try SwiftSoup.parse(self)

            // 抓出所有文字，連成一行
            let text = try doc.text()

            // 去掉所有空白與換行
            return text
                .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        } catch {
            print("⚠️ HTML 轉換失敗：\(error.localizedDescription)")
            return self
        }
    }
}


