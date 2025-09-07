//
//  HomeView.swift
//  Briefly
//


import SwiftUI
import CoreData
import UIKit
import UserNotifications
import SDWebImageSwiftUI

struct HomeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var newsVM: NewsViewModel
    @EnvironmentObject var fontManager: FontManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var searchTerm = ""
    @State private var isMenuCollapsed: Bool = true // tab 水平 or 垂直顯示
    @Binding var cellIsSelected: Bool
    @State private var enterSearch: Bool = false
    @State private var previousSearchTerm = ""
    @State private var selectedTerm: String? = nil
    @State private var isShowLoading: Bool = false
    @State private var isHeaderHidden: Bool = false
    @State private var direction: String = "None"

    var filteredNews: [NewsItem] {
        // 把 selectedTerm 拆關鍵字（如果為 nil 就給空陣列）
        let selectedKeywords = selectedTerm?
            .lowercased()
            .split(separator: " ")
            .map { String($0) } ?? []

        // 把 searchTerm 拆關鍵字（至少會有字串，所以不用 optional）
        let searchKeywords = searchTerm
            .lowercased()
            .split(separator: " ")
            .map { String($0) }

        // 合併兩者
        let keywords = selectedKeywords + searchKeywords
            
        // 如果沒有輸入關鍵字，回傳全部
        if keywords.isEmpty {
            return newsVM.newsItems
        } else {
            return newsVM.newsItems.filter { newsItem in
                // 過濾新聞：同時包含所有關鍵字
                keywords.allSatisfy { keyword in
                    newsItem.title.lowercased().contains(keyword) ||
                    newsItem.summary.lowercased().contains(keyword)
                }
            }
        }
    }

    
    var body: some View {
        NavigationView{
            ZStack(alignment: .top){
                Color.mainBackground
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
// MARK: - SearchBar
                    if !isHeaderHidden {
                        SearchBarView(text: $searchTerm) {
                            if !searchTerm.isEmpty {
                                enterSearch = true
                                previousSearchTerm = searchTerm
                            }
                        }
                        .padding(.bottom, 16)
                    }
// MARK: - Cell Menu
                    if !enterSearch && !isHeaderHidden && items.contains(where: { $0.term != nil }) {
                        ZStack(alignment: .topTrailing){
                            // 垂直 Scroll 模式
                            if !isMenuCollapsed  {
                                ScrollView(.vertical, showsIndicators: false) {
                                    HStack{}.frame(height: 30)
                                    VStack(spacing: 24) {
                                        ForEach(items) { item in
                                            if let term = item.term {
                                                CategoryCellView(title: term, selectedTerm: $selectedTerm)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                // 水平 Scroll 模式
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(items) { item in
                                            if let term = item.term {
                                                CategoryCellView(title: term, selectedTerm: $selectedTerm)
                                            }
                                        }
                                    }
                                }
                            }
// MARK: - toggleCollapseButton
                            if items.count > 4 {
                                Image(systemName: isMenuCollapsed ? "increase.indent" : "decrease.indent")
                                    .padding(8)
                                    .background(Color.mainBackground)
                                    .onTapGesture {
                                        isMenuCollapsed.toggle()
                                    }
                            }
                        }
                    }
                
// MARK: - search result bar--> add this subscription
                    if enterSearch{
                        HStack(alignment: .center, spacing: 16){
                            Text("# \(searchTerm)")
                            SubscribeButton(myTerm: $searchTerm)
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
// MARK: - content
                    if isMenuCollapsed{
                        ScrollView(.vertical, showsIndicators: false) {
                            HStack{}.frame(height: 8)
                            content()
                        }
                        .padding(.top, 8)
                        .simultaneousGesture(
                            DragGesture().onChanged { value in
                                if value.translation.height > 0 {
                                    direction = "⬇️ 向下滑"
                                    withAnimation {
                                        isHeaderHidden = false
                                    }
                                } else {
                                    direction = "⬆️ 向上滑"
                                    withAnimation {
                                        isHeaderHidden = true
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("新聞關鍵字", displayMode: .inline)
            .onChange(of: searchTerm) { newValue in
                if newValue.isEmpty {
                    enterSearch = false
                }
            }            
            // 🟢 監控 items 變化，若 selectedTerm 被刪除，自動清除
            .onChange(of: items.map { $0.term }) { newTerms in
                if let selected = selectedTerm {
                    if !newTerms.contains(selected) {
                        selectedTerm = nil
                    }
                }
            }
            //手機通知
            .onAppear {
                requestNotificationPermission()
                Task {
                    await newsVM.fetchRSS()
                }
            }
            .onChange(of: newsVM.newsItems) { newItems in
                checkForMatchingTerms(in: newItems)
            }
        }
    }
    private func checkForMatchingTerms(in newsItems: [NewsItem]) {
            let terms = items.compactMap { $0.term?.lowercased() }
            for newsItem in newsItems {
                for term in terms {
                    if newsItem.title.lowercased().contains(term) || newsItem.summary.lowercased().contains(term) {
                        sendNotification(for: newsItem.title)
                        break
                    }
                }
            }
        }
        
    private func sendNotification(for title: String) {
        let content = UNMutableNotificationContent()
        content.title = "有新新聞！"
        content.body = "符合您的訂閱：\(title)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知發送失敗：\(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知權限請求失敗：\(error.localizedDescription)")
            } else if granted {
                print("通知權限已授權")
            } else {
                print("通知權限被拒絕")
            }
        }
    }
    
    private func content() -> some View {
        LazyVStack{
            ForEach(filteredNews) { item in
                NavigationLink(destination: WebViewContainer(urlString: item.link)){
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .fontManager(style: "headline", weight: .semibold, size: 19)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                        Text(item.summary)
                            .fontManager(style: "subheadline", weight: .regular, size: 14)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
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
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.2))
                            .padding(.vertical, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}



// MARK: - SubscribeButton
struct SubscribeButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var myTerm: String
    @State private var isSubscribed: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isSubscribed ? "minus.circle" : "plus.circle")
                .padding(.vertical, 6)
            Text(isSubscribed ? "取消訂閱" : "訂閱此標籤")
        }
        .foregroundColor(isSubscribed ? .red : .blue)
        .onAppear(perform: checkIfSubscribed)
        .onChange(of: myTerm) { _ in
            checkIfSubscribed()
        }
        .onTapGesture {
            if isSubscribed {
                deleteItem()
            } else {
                addItem()
            }
        }
    }
    
    private func checkIfSubscribed() {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "term == %@", myTerm)
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try viewContext.fetch(fetchRequest)
            isSubscribed = !result.isEmpty
        } catch {
            print("查詢失敗: \(error)")
            isSubscribed = false
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.term = myTerm
            do {
                try viewContext.save()
                isSubscribed = true
            } catch {
                let nsError = error as NSError
                print("新增失敗: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItem() {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "term == %@", myTerm)
        
        do {
            let result = try viewContext.fetch(fetchRequest)
            result.forEach { viewContext.delete($0) }
            try viewContext.save()
            isSubscribed = false
        } catch {
            let nsError = error as NSError
            print("刪除失敗: \(nsError), \(nsError.userInfo)")
        }
    }
    
}



#Preview {
    HomeView(cellIsSelected: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(RSSFetcher())
        .environmentObject(FontManager())
        .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
}



