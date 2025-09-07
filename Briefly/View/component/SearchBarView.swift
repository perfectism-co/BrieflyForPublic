//
//  SearchBarView.swift
//  Briefly
//
//
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "關鍵字搜索新聞"
    var backgroundColor: Color = .itemBackground
    // 新增一個 onSubmitAction 參數，預設空動作
    var onSubmitAction: () -> Void = {}

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search) 
                .onSubmit {
                    print("使用者按下了 Enter！輸入文字：\(text)")
                    onSubmitAction()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(backgroundColor)
        .cornerRadius(10)        
    }
}

#Preview {
    SearchBarView(text: .constant("123"))
}
