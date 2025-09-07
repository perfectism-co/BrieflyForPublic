//
//  NewsPaperViewModel.swift
//  Briefly
//
//
//

import Foundation
import SwiftSoup


@MainActor
class NewsPaperViewModel: ObservableObject {
    @Published var news: NewsPaper? = nil
    @Published var isLoading = false
    
    func fetchNews(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // 1️⃣ 抓取 HTML
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return }

            // 2️⃣ 用 SwiftSoup 解析
            let doc: Document = try SwiftSoup.parse(html)

            // 標題
            let title = try doc.select("h1.article-content__title").text()
            
            // 來源時間
            let timeParagraphs = try doc.select("div.article-content__subinfo > section.authors")
            let timeString = try timeParagraphs.array().map { try $0.text() }.joined(separator: " ")

            // 圖片
            let imageURL = try doc.select("figure.article-content__cover img, figure.article-content__image img").attr("src")

            // 精準抓文章內文
            // 只抓 div.article-content__paragraph 下的 <p>
            let contentParagraphs = try doc.select("div.article-content__paragraph > section.article-content__editor p")

            // 過濾：排除父層是 <div> 的 <p>
            let validParagraphs = contentParagraphs.filter { p in
               if let parent = p.parent() {
                   return parent.tagName() != "div"
               }
               return true
            }

            // 轉成文字陣列
            let content = try validParagraphs
                .map { try $0.text() }
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")

            // ✅ 回傳 NewsPaper
            self.news = NewsPaper(title: title, time: timeString, imageURL: imageURL, content: content)

        } catch {
            print("錯誤：\(error)")
        }
    }
}




struct NewsPaper {
    let title: String
    let time: String
    let imageURL: String
    let content: String
}
