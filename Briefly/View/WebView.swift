

import SwiftUI
import WebKit
import SDWebImageSwiftUI

struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 將 urlString 轉成 URL
        guard let url = URL(string: urlString) else { return }
        
        // 避免重複加載同一個網址
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

struct WebViewContainer: View {
    
    @StateObject private var newsPaperVM = NewsPaperViewModel()
    @EnvironmentObject var fontManager: FontManager
    
    let urlString: String
    
    @State private var isShareSheetShowing = false
    @State private var isScaleSheetShowing = false
    @State private var isPaperMode: Bool = UserDefaults.standard.bool(forKey: "isPaperMode")
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var titleFontSize: Double = 28.0
    @State private var timeFontSize: Double = 14.0
    @State private var contentFontSize: Double = 17.0
    @State private var scale: Double = 1.0
    
    var body: some View {
        ZStack{
            WebView(urlString: urlString)
            
            if settings.isPaperMode{
                ZStack{
                    Color.mainBackground.ignoresSafeArea(edges: .all)
                    
                    if let news = newsPaperVM.news {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(news.title)
                                    .fontManager(style: "headline", weight: .semibold, size: 28 * scale)
                                
                                Text(news.time)
                                    .fontManager(style: "light", weight: .light, size: 14 * scale)
                                
                                if let url = URL(string: news.imageURL) {
                                    WebImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                
                                Text(news.content)
                                    .fontManager(style: "body", weight: .regular, size: 17 * scale)
                            }
                            .padding()
                        }
                    } else if newsPaperVM.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("無法取得新聞")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if isScaleSheetShowing {
                        VStack {
                            VStack {
                                Text("縮放比例：\(String(format: "%.1f", scale))x")
                                    .font(.caption)
                                Slider(value: $scale, in: 0.5...2.0, step: 0.1)
                            }
                            .padding()
                            .background(Color.white.shadow(color: .black.opacity(0.2), radius: 4, y: 8))
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 40) {
                    if settings.isPaperMode{
                        Button{
                            isScaleSheetShowing.toggle()
                        }label: {
                            Image(systemName: "textformat.size")
                                .font(.system(size: isScaleSheetShowing ? 8 : 18))
                                .frame(width: isScaleSheetShowing ? 24 : 32, height: isScaleSheetShowing ? 24 : 32)
                                .foregroundColor(isScaleSheetShowing ? .white : .primary)
                                .background(isScaleSheetShowing ? Color.primary : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                    
                    Button{
                        settings.isPaperMode.toggle()
                    }label: {
                        Image(systemName: settings.isPaperMode ? "list.bullet.rectangle.portrait.fill" : "list.bullet.rectangle.portrait")
                    }
                    
                    Button{
                        isShareSheetShowing = true
                    }label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $isShareSheetShowing) {
            ShareSheet(activityItems: [urlString])
        }
        .task {
            await newsPaperVM.fetchNews(from: urlString)
        }
    }
}

// 封裝 UIKit 的 UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 不需要更新
    }
}

#Preview {
    NavigationView{
        WebViewContainer(urlString: "https://udn.com/news/story/7314/8979375")
            .environmentObject(FontManager())
    }
}

