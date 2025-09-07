//
//  BrieflyApp.swift
//  Briefly
//
// 
//

import SwiftUI
import CoreData

@main
struct BrieflyApp: App {
    
    // Core Data
    let persistenceController = PersistenceController.shared

    // StateObjects
    @StateObject var fetcher = RSSFetcher()
    @StateObject var fontManager = FontManager()
    @StateObject private var newsVM: NewsViewModel

    // App init
    init() {
        let context = persistenceController.container.viewContext
        _newsVM = StateObject(wrappedValue: NewsViewModel(context: context))
    }
    
    var body: some Scene {
        WindowGroup {
            
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(fetcher)
                .environmentObject(fontManager)
                .environmentObject(newsVM)
        }
    }
}
