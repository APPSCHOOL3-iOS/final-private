//
//  MainHomeView.swift
//  Private
//
//  Created by 변상우 on 2023/09/21.
//

import SwiftUI
import NMapsMap

struct MainHomeView: View {
    @ObservedObject var coordinator: Coordinator = Coordinator.shared
    @ObservedObject var locationSearchStore = LocationSearchStore.shared
    
    @Binding var root: Bool
    @Binding var selection: Int
    @Binding var showLocation: Bool
    @Binding var searchResult: SearchResult
    
    @State var selectedNumber: Int = 0
    @State private var tapped: Bool = true
    @State private var isShowSearch: Bool = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                HStack {
                    Button {
                        selectedNumber = 0
                    } label: {
                        Image(systemName: "map")
                        Text("지도")
                    }
                    .foregroundColor(selectedNumber == 0 ? .primary : .subGrayColor)
                    .padding(.bottom, 10)
                    .modifier(BottomBorder(showBorder: selectedNumber == 0))
                    
                    Button {
                        selectedNumber = 1
                    } label: {
                        Image(systemName: "text.justify")
                        Text("피드")
                    }
                    .foregroundColor(selectedNumber == 1 ? .primary : .subGrayColor)
                    .padding(.bottom, 10)
                    .modifier(BottomBorder(showBorder: selectedNumber == 1))
                    
                    Spacer()
                    
                    Button {
                        isShowSearch.toggle()
                        print("검색 버튼 클릭")
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    NavigationLink {
                        ChatRoomListView()
                    } label: {
                        Image(systemName: "paperplane")
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.horizontal, 10)
            .font(.pretendardMedium20)
            .foregroundColor(.primary)
            
            .sheet(isPresented: $isShowSearch) {
                MapSearchView(showLocation: $showLocation, searchResult: $searchResult, coord: $coordinator.coord, selection: $selection)
            }
            if selectedNumber == 0 {
                MapMainView()
            } else if selectedNumber == 1 {
                FeedMainView()
            }
        }
    }
}

struct MainHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainHomeView(root: .constant(true), selection: .constant(1), showLocation: .constant(true), searchResult: .constant(SearchResult(title: "", category: "", address: "", roadAddress: "", mapx: "", mapy: "")))
            .environmentObject(FeedStore())
    }
}
