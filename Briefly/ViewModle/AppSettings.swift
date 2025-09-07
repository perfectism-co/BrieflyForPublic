//
//  AppSettings.swift
//  Briefly
//
//
//  UserDefaults

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // 使用 @Published 讓 SwiftUI 監控變化
    @Published var isPaperMode: Bool {
        didSet {
            // 同步存 UserDefaults
            UserDefaults.standard.set(isPaperMode, forKey: "isPaperMode")
        }
    }
    
    private init() {
        // 啟動時讀取 UserDefaults
        self.isPaperMode = UserDefaults.standard.bool(forKey: "isPaperMode")
    }
}

