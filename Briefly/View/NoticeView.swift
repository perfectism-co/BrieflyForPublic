//  TestView.swift
//  Briefly
//
//

import SwiftUI
import CoreData
import UserNotifications

struct NoticeView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var insertTerm: String = ""
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack{
                List {
                    ForEach(items) { item in
                        HStack {
                            Text(item.term ?? "")
                                .font(.system(size: 16))
                            Spacer()
                            ItemToggle(item: item)
                        }
                        .frame(height: 38)
                    }
                    .onDelete(perform: deleteItems)
                }
                .offset(y: 60)
               
// Header
               
                VStack {
                    HStack(spacing: 28) {
                        Text("訂閱通知")
                            .font(.headline)
                        Spacer()
                        
                        Button{
                            showAlert.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }

                        EditButton()
                    }
                    .padding(.horizontal,24).padding(.top, 4)
                    
                    Text("手機最新新聞通知，請務必開啟App通知權限")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24).padding(.horizontal, 24).padding(.bottom, 8)
                        .background(Color(.listSystemBackground))
                    Spacer()
                }
            }
            .background(Color(.listSystemBackground))
            .alert("新增訂閱標籤", isPresented: $showAlert) {
                TextField("輸入標籤名稱", text: $insertTerm)
                Button("新增"){
                    addItem()
                    insertTerm = "" // 新增後清空
                }
                Button("取消", role: .cancel) {
                    insertTerm = "" // 取消後清空
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.term = insertTerm
            newItem.noticeEnabled = false // 新增時預設通知為關閉

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ItemToggle: View {
    @ObservedObject var item: Item
    @State private var noticeToggleIsOn: Bool = true
    
    var body: some View {
        Toggle("", isOn: $noticeToggleIsOn)
            .scaleEffect(0.85)
            .frame(width: 44, alignment: .trailing)
            .onAppear {
                noticeToggleIsOn = item.noticeEnabled
            }
            .onChange(of: noticeToggleIsOn) { newValue in
                item.noticeEnabled = newValue
                try? item.managedObjectContext?.save()
                if newValue {
                    requestNotificationPermission()
                }
            }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知權限授權成功")
            } else if let error = error {
                print("通知權限授權失敗: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NoticeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


