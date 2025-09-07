//
//  SwiftUIView.swift
//  Briefly
//
//  
//

import SwiftUI


#Preview {
    NavigationView {
        ScrollDetectView()
    }
}

// 1) PreferenceKey：用來傳遞捲動位移
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 2) 放在 ScrollView 內容最上方的「零高度偵測器」
struct TopOffsetReader: View {
    let spaceName: String
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: ScrollOffsetKey.self,
                            value: proxy.frame(in: .named(spaceName)).minY)
        }
        .frame(height: 0) // 很重要：固定 0 高，作為錨點
    }
}

struct ScrollDetectView: View {
    @State private var lastOffset: CGFloat = 0
    @State private var directionText: String = "None"

    private let spaceName = "newsScroll"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TopOffsetReader(spaceName: spaceName)  // ⭐️ 量測「內容頂端」相對位置
                ForEach(0..<50) { i in
                    NavigationLink(destination: DragDetectView()) {
                        VStack {
                            Text("Row \(i)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .buttonStyle(.plain) // 避免多餘高亮造成誤會
                    .background(Color(.secondarySystemBackground))
                }
            }
            
        }
        .coordinateSpace(name: spaceName) // ⭐️ 一定要設定對應的座標空間
        .onPreferenceChange(ScrollOffsetKey.self) { newOffset in
            // newOffset 變小(更負) = 內容往上移動 = 使用者「向上滑」
            let delta = newOffset - lastOffset
            // 避免微抖動，設一個很小的門檻
            guard abs(delta) > 0.5 else { return }

            directionText = delta < 0 ? "⬆️ 向上滑" : "⬇️ 向下滑"
            lastOffset = newOffset
        }
        .overlay(alignment: .top) {
           Text("方向：\(directionText)")
               .padding(8)
               .background(.black.opacity(0.6))
               .foregroundColor(.white)
               .clipShape(RoundedRectangle(cornerRadius: 8))
               .padding()
       }
    }
}

struct DragDetectView: View {
    @State private var direction: String = "None"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<50) { i in
                    NavigationLink(destination: DragDetectView()) {
                        Text("Row \(i)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        // ✅ 改用 simultaneousGesture，不會吃掉 ScrollView 的捲動
        .simultaneousGesture(
            DragGesture().onChanged { value in
                if value.translation.height > 0 {
                    direction = "⬇️ 向下滑"
                } else {
                    direction = "⬆️ 向上滑"
                }
            }
        )
        .overlay(
            Text("方向：\(direction)")
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10),
            alignment: .top
        )
    }
}
