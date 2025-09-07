//
//  NewspaperView.swift
//  Briefly
//
//
//

import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct CollectionView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var newsVM: NewsViewModel
    @EnvironmentObject var fontManager: FontManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
 
    @State private var searchText = ""
    @State private var enterSearch: Bool = false
    @State private var previousSearchTerm = ""
    @State private var isHeaderHidden: Bool = false
    

    var filteredNews: [NewsItem] {
        // 1. Core Data 的關鍵字 (OR)
        let savedKeywords = items
            .compactMap { $0.term }
            .flatMap { $0.lowercased().split(separator: " ").map { String($0) } }

        // 2. searchText 的關鍵字 (AND)
        let searchKeywords = searchText
            .lowercased()
            .split(separator: " ")
            .map { String($0) }

        // 3. 沒有任何關鍵字 → 回傳空陣列
        guard !savedKeywords.isEmpty || !searchKeywords.isEmpty else {
            return []
        }

        // 4. 先用 items 過濾 (OR)
        let afterItemsFilter = savedKeywords.isEmpty
            ? newsVM.newsItems
            : newsVM.newsItems.filter { newsItem in
                let title = newsItem.title.lowercased()
                let summary = newsItem.summary.lowercased()
                return savedKeywords.contains { keyword in
                    title.contains(keyword) || summary.contains(keyword)
                }
            }

        // 5. 再用 searchText 過濾 (AND)
        let finalFiltered = searchKeywords.isEmpty
            ? afterItemsFilter
            : afterItemsFilter.filter { newsItem in
                let title = newsItem.title.lowercased()
                let summary = newsItem.summary.lowercased()
                return searchKeywords.contains { keyword in
                    title.contains(keyword) || summary.contains(keyword)
                }
            }

        return finalFiltered
    }

    
    var body: some View {
        NavigationView {
            ZStack{
                Color(.listSystemBackground).ignoresSafeArea()
                
                if filteredNews == [] {
                    Text("尚未有新聞").foregroundStyle(.secondary)
                }else {
                    ScrollView(showsIndicators: false) {
                        HStack {}.frame(height: 40)
                        VStack(spacing: 0) {
                            ForEach(filteredNews) { item in
                                NavigationLink(destination: WebViewContainer(urlString: item.link)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.title)
                                            .multilineTextAlignment(.leading)
                                            .fontManager(style: "headline", weight: .semibold, size: 18)
                                        Text(item.summary)
                                            .fontManager(style: "subheadline", weight: .regular, size: 14)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        if let imageURL = item.imageURL, let imageUrl = URL(string: imageURL) {
                                            WebImage(url: imageUrl) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(height: 150)
                                            .clipped()
                                            .cornerRadius(8)
                                        }
                                        if let date = item.pubDate {
                                            Text(date, style: .date)
                                                .fontManager(style: "light", weight: .regular, size: 11)
                                        }
                                        Rectangle().frame(height: 1).foregroundColor(Color(.systemGray5))
                                    }
                                }
                            }
                            .padding(.horizontal).padding(.vertical, 8)
                            .background(Color(.systemBackground))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .simultaneousGesture(
                        DragGesture().onChanged { value in
                            if value.translation.height > 0 {
                                withAnimation {
                                    isHeaderHidden = false
                                }
                            } else {
                                withAnimation {
                                    isHeaderHidden = true
                                }
                            }
                        }
                    )
                    
                    if !isHeaderHidden {
                        VStack{
                            SearchBarView(text: $searchText, placeholder: "搜索", backgroundColor: Color(.listSystemItem)){
                                if !searchText.isEmpty {
                                    enterSearch = true
                                    previousSearchTerm = searchText
                                }
                            }
                            .padding(.horizontal).padding(.bottom, 8)
                            .background(Color(.listSystemBackground))
                        Spacer()
                        }
                    }
                }
            }
            .navigationBarTitle("我的訂閱", displayMode: .inline)
        }
        .onAppear {
            Task {
                await newsVM.fetchRSS()
            }
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                enterSearch = false
            }
        }
    }
}

#Preview {
    CollectionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(RSSFetcher())
        .environmentObject(FontManager())
        .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
}




