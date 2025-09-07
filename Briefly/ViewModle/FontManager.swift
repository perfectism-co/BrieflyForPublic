//
//  FontManager.swift
//  Briefly
//
//  
//

import SwiftUI


class FontManager: ObservableObject {
    @Published var useSystemFont: Bool {
        didSet {
            // 每次切換字體時存到 UserDefaults
            UserDefaults.standard.set(useSystemFont, forKey: "useSystemFont")
        }
    }
    @Published var customFontFamily: String = "SourceHanSerif"
    
    init() {
        // 從 UserDefaults 讀取設定，預設為 true (系統字體)
        self.useSystemFont = UserDefaults.standard.bool(forKey: "useSystemFont")
    }

    /// 切換字體
    func toggleFont() {
        useSystemFont.toggle()
    }

    /// 目前字體名稱（顯示用）
    var currentFontName: String {
        useSystemFont ? "系統字體 (SF Pro)" : "宋體"
    }
}


// MARK: - 自訂 ViewModifier
struct CustomFontModifier: ViewModifier {
    @EnvironmentObject var fontManager: FontManager
    
    let style: String
    var weight: Font.Weight
    var size: CGFloat
    
    func body(content: Content) -> some View {
        if fontManager.useSystemFont {
            // 系統字體
            switch style {
            case "body":
                content
                    .font(.system(size: size, weight: weight))
                    .lineSpacing(2)
            case "subheadline":
                content
                    .font(.subheadline)
            case "light":
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(.secondary)
            default:
                content
                    .font(.system(size: size, weight: weight))
            }
        } else {
            // 自訂字體
            switch style {
            case "light":
                content
                    .font(.custom("\(fontManager.customFontFamily)-ExtraLight", size: size))
            case "subheadline":
                content
                    .font(.custom("\(fontManager.customFontFamily)-SemiBold", size: size))
                    .kerning(1)
            case "headline":
                content
                    .font(.custom("\(fontManager.customFontFamily)-Bold", size: size))
                    .kerning(1.2)
            case "body":
                content
                    .font(.custom("\(fontManager.customFontFamily)-SemiBold", size: size))
                    .kerning(1)
                    .lineSpacing(4)
            default:
                content
                    .font(.custom("\(fontManager.customFontFamily)-SemiBold", size: size))
            }
        }
    }
}

// MARK: - Text 擴充語法糖
extension View {
    func fontManager(style: String, weight: Font.Weight, size: CGFloat) -> some View {
        self.modifier(CustomFontModifier(style: style, weight: weight, size: size))
    }
}
