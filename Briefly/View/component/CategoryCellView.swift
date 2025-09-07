//
//  CategoryCellView.swift
//  Briefly
//
//  
//

import SwiftUI

struct CategoryCellView: View {
    var title: String = ""
    @Binding var selectedTerm: String?

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(isSelected ? .bold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.itemBackground)
            .foregroundColor(isSelected ? Color.buttonTextSelected : Color.accentColor)
            .cornerRadius(100)
            .onTapGesture {
                if isSelected {
                    selectedTerm = nil
                } else {
                    selectedTerm = title
                }
            }
    }

    private var isSelected: Bool {
        // 檢查目前這個 cell 的 title 是否等於目前選取的標籤
        selectedTerm == title
    }
}

#Preview {
    PreviewWrapperCategoryCellView()
}

struct PreviewWrapperCategoryCellView: View {
    @State private var selected: String? = nil  

    var body: some View {
        ZStack {
            Color.mainBackground
            CategoryCellView(title: "Example", selectedTerm: $selected)
        }
    }
}
