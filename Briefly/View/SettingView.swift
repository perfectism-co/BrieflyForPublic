//
//  SettingView.swift
//  Briefly
//
//  
//

import SwiftUI

struct SettingView: View {
    
    @EnvironmentObject var fontManager: FontManager
    @State private var isOn = false
    
    var body: some View {
        NavigationView{
            List{
                Section(header: Text("新聞字體")){
                    VStack(alignment: .leading) {
                        HStack {
                            Text("切換字體").font(.subheadline)
                            Spacer()
                            Toggle(isOn: $isOn){}.scaleEffect(0.85)
                                .onChange(of: isOn) { _ in
                                    fontManager.toggleFont()
                                }
                        }
                        
                        Text("當前新聞顯示：\(fontManager.currentFontName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 20)  {
                            Text("新聞 Light")
                                .fontManager(style: "light", weight: .light, size: 14)
                                .frame(height: 40)
                            
                            Text("新聞 Regular")
                                .fontManager(style: "", weight: .regular, size: 17)
                                .frame(height: 40)

                            Text("新聞 Bold")
                                .fontManager(style: "headline", weight: .semibold, size: 28)
                                .frame(height: 40)
                        }
                        .padding(50)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.05))
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
        }
    }
}

#Preview {
     SettingView().environmentObject(FontManager())
}
