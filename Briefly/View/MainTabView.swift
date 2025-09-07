//
//  MainTabView.swift
//  Briefly
//
//
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            HomeView(cellIsSelected: .constant(false)).tabItem { Label("新聞", systemImage: "doc.append")}
            CollectionView().tabItem { Label("我的訂閱", systemImage: "bookmark")}
            NoticeView().tabItem { Label("通知", systemImage: "bell")}
            SettingView().tabItem { Label("設定", systemImage: "gearshape.fill")}
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(RSSFetcher())
        .environmentObject(FontManager())
        .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
}
