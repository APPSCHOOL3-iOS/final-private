
//
//  FeedUpdateView.swift
//  Private
//
//  Created by 변상우 on 2023/09/21.
//

import SwiftUI
import NMapsMap
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseCore
import Combine
import Kingfisher

struct FeedUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var userStore: UserStore
    @State var newFeed : MyFeed = MyFeed()
    @StateObject private var locationSearchStore = LocationSearchStore.shared
    @StateObject private var postStore: PostStore = PostStore()
    @ObservedObject var postCoordinator: PostCoordinator = PostCoordinator.shared
    @Binding var root: Bool
    @Binding var selection: Int
    @Binding var isFeedUpdateViewPresented: Bool
    @Binding var searchResult: SearchResult
    @State private var currentSearchResult: SearchResult

    @State private var text: String = ""
    @State private var textPlaceHolder: String = ""
    @State private var lat: String = ""
    @State private var lng: String = ""
    @State private var newMarkerlat: String = ""
    @State private var newMarkerlng: String = ""
    @State private var writer: String = ""
    @State private var images: [String] = []
    @State private var createdAt: Double = Date().timeIntervalSince1970
    @State private var visitedShop: String = ""
    @State private var feedId: String = ""
    @State private var myselectedCategory: [String] = []
    @State private var clickLocation: Bool = false
    @State private var isImagePickerPresented: Bool = false
    @State private var ImageViewPresented: Bool = true
    @State private var showLocation: Bool = false
    @State private var isshowAlert = false
    @State private var categoryAlert: Bool = false
    @State private var isSearchedLocation: Bool = false
    @State private var registrationAlert: Bool = false
    @State private var selectedImage: [UIImage]? = []
    @FocusState private var isTextMasterFocused: Bool
    @State private var selectedCategories: Set<MyCategory> = []
    @State private var selectedToggle: [Bool] = Array(repeating: false, count: MyCategory.allCases.count)
    
    @State var feed: MyFeed
    private let minLine: Int = 10
    private let maxLine: Int = 12
    private let fontSize: Double = 18
    private let maxSelectedCategories = 3
    let userDataStore: UserStore = UserStore()
    var db = Firestore.firestore()
    var storage = Storage.storage()
    let filteredCategories = Category.filteredCases
    
    init(root: Binding<Bool>, selection: Binding<Int>, isFeedUpdateViewPresented: Binding<Bool>, searchResult: Binding<SearchResult>, feed: MyFeed) {
        self._root = root
        self._selection = selection
        self._isFeedUpdateViewPresented = isFeedUpdateViewPresented
        self._searchResult = searchResult
        self._textPlaceHolder = State(initialValue: feed.contents)
        self._images = State(initialValue: feed.images)
        let firstCategory = getValue(from: feed.category, at: 0)
        let secondCategory = getValue(from: feed.category, at: 1)
        let thirdCategory = getValue(from: feed.category, at: 2)

        let combinedCategory = "\(firstCategory), \(secondCategory), \(thirdCategory)"

        self._currentSearchResult = State(initialValue: SearchResult(title: feed.title, category: combinedCategory, address: feed.address, roadAddress: feed.roadAddress, mapx: feed.mapx, mapy: feed.mapy))

        self._feed = State(initialValue: feed)
        let selectedCategories = Set(feed.category)
        self._selectedToggle = State(initialValue: MyCategory.allCases.map { selectedCategories.contains($0.categoryName) })
        
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        ZStack {
                            if userStore.user.profileImageURL.isEmpty {
                                Circle()
                                    .frame(width: .screenWidth*0.15)
                                Image(systemName: "person")
                                    .resizable()
                                    .frame(width: .screenWidth*0.15, height: .screenWidth*0.15)
                                    .foregroundColor(Color.darkGraySubColor)
                                    .clipShape(Circle())
                            } else {
                                KFImage(URL(string: userStore.user.profileImageURL))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: .screenWidth*0.15, height: .screenWidth*0.15)
                                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                            }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(userStore.user.name)
                            Text("@\(userStore.user.nickname)")
                        }
                    }
                    .padding(.vertical, 10)
                    //MARK: 내용
                    TextMaster(text: $text, isFocused: $isTextMasterFocused, maxLine: minLine, fontSize: fontSize, placeholder: textPlaceHolder)
                        .padding(.trailing, 10)
                    //MARK: 장소
                    VStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feed.title)
                                .font(.pretendardRegular14)
                                .foregroundStyle(Color.subGrayColor)
                            Text(feed.address)
                                .font(.pretendardRegular12)
                                .foregroundStyle(Color.subGrayColor)
                        }
                        Button {
                            showLocation = true
                        } label: {
                            Label("장소", systemImage: "location")
                                .font(.pretendardMedium16)
                                .foregroundStyle(Color.privateColor)
                        }
                        .sheet(isPresented: $showLocation) {
                            LocationSearchView(showLocation: $showLocation, searchResult: $searchResult, isSearchedLocation: $isSearchedLocation)
                                .presentationDetents([.fraction(0.75), .large])
                        }
                        .sheet(isPresented: $isSearchedLocation) {
                            LocationView(searchResult: $searchResult, registrationAlert: $registrationAlert, newMarkerlat: $newMarkerlat, newMarkerlng: $newMarkerlng, isSearchedLocation: $isSearchedLocation)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            if searchResult.title.isEmpty && postCoordinator.newMarkerTitle.isEmpty {
                                Text("장소를 선택해주세요")
                                    .font(.pretendardRegular12)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 5)
                            } else {
                                Button {
                                    if !postCoordinator.newMarkerTitle.isEmpty {
                                        clickLocation.toggle()
                                        postCoordinator.newLocalmoveCameraPosition()

                                        postCoordinator.makeSearchLocationMarker()
                                    } else {
                                        lat = locationSearchStore.formatCoordinates(searchResult.mapy, 2) ?? ""
                                        lng = locationSearchStore.formatCoordinates(searchResult.mapx, 3) ?? ""
                                        
                                        postCoordinator.coord = NMGLatLng(lat: Double(lat) ?? 0, lng: Double(lng) ?? 0)
                                        postCoordinator.newMarkerTitle = searchResult.title
                                        print("위도값: \(postCoordinator.coord.lat), 경도값: \(postCoordinator.coord.lng)")
                                        print("지정장소 클릭")
                                        clickLocation.toggle()
                                        postCoordinator.moveCameraPosition()
                                        postCoordinator.makeSearchLocationMarker()
                                    }
                                } label: {
                                    Text("\(searchResult.title)".replacingOccurrences(of: "</b>", with: "").replacingOccurrences(of: "<b>", with: ""))
                                        .font(.pretendardRegular12)
                                }
                                .sheet(isPresented: $clickLocation) {
                                    LocationDetailView(searchResult: $searchResult)
                                        .presentationDetents([.height(.screenHeight * 0.6), .large])
                                }
                                if (!searchResult.address.isEmpty) {
                                    Text(searchResult.address)
                                        .font(.pretendardRegular10)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        Button {
                            searchResult.title = ""
                            searchResult.address = ""
                            searchResult.roadAddress = ""
                            postCoordinator.newMarkerTitle = ""
                        } label: {
                            Label("", systemImage: "xmark")
                                .font(.pretendardMedium16)
                                .foregroundStyle(Color.privateColor)
                        }
                        //                            if !postCoordinator.newMarkerTitle.isEmpty {
                        //                                Text("신규장소: \(postCoordinator.newMarkerTitle)")
                        //                            }
                    }
                    Divider()
                        .padding(.vertical, 10)
                    
                    
                    //MARK: 사진
                    
                    HStack {
                        Label("사진", systemImage: "camera")
                            .font(.pretendardMedium16)
                            .foregroundStyle(Color.privateColor)
                        Spacer()
                        Button {
                            isImagePickerPresented.toggle()
                        } label: {
                            Label("", systemImage: "plus")
                                .font(.pretendardMedium16)
                                .foregroundStyle(Color.privateColor)
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePickerView(selectedImages: $selectedImage)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white)
                                .transition(.move(edge: .leading))
                        }
                    }
                    
                    ScrollView(.horizontal) {
                        HStack(alignment: .center) {
                            if let images = selectedImage, !images.isEmpty {
                                ForEach(images, id: \.self) { image in
                                    ZStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 150)
                                            .clipShape(Rectangle())
                                        Button {
                                            if let index = selectedImage?.firstIndex(of: image) {
                                                selectedImage?.remove(at: index)
                                            }
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .frame(width: .screenWidth*0.06)
                                                Image(systemName: "x.circle")
                                                    .font(.pretendardMedium20)
                                                    .foregroundColor(Color.white)
                                                    .padding(8)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    }
                                }
                            } else {
                                Text("최소 1장의 사진이 필요합니다!")
                                    .font(.pretendardRegular12)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .onAppear {
                        for imageUrl in feed.images {
                            KingfisherManager.shared.retrieveImage(with: URL(string: imageUrl)!) { result in
                                switch result {
                                case .success(let value):
                                    selectedImage?.append(value.image)
                                case .failure(let error):
                                    print("Error loading image: \(error)")
                                }
                            }
                        }
                    }
                    Divider()
                        .padding(.vertical, 10)
                    
                    //MARK: 카테고리
                    
                    HStack {
                        Text("카테고리")
                            .font(.pretendardMedium20)
                            .foregroundStyle(Color.privateColor)
                        Text("(최대 3개)")
                            .font(.pretendardRegular12)
                            .foregroundColor(.secondary)
                        //Text()
                    }
                    LazyVGrid(columns: createGridColumns(), spacing: 20) {
                        ForEach (filteredCategories.indices, id: \.self) { index in
                            VStack {
                                if selectedToggle[index] {
                                    Text(MyCategory.allCases[index].categoryName)
                                        .font(.pretendardMedium16)
                                        .foregroundColor(.primary)
                                        .frame(width: 70, height: 30)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 4)
                                        .background(Color.privateColor)
                                        .cornerRadius(7)
                                } else {
                                    Text(MyCategory.allCases[index].categoryName)
                                        .font(.pretendardMedium16)
                                        .foregroundColor(.white)
                                        .background(Color.black)
                                        .frame(width: 70, height: 30)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 4)
                                        .cornerRadius(7)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(Color.darkGrayColor, lineWidth: 1.5)
                                        )
                                }
                            }
                            .onTapGesture {
                                toggleCategorySelection(at: index)
                                print("선택한 카테고리: \(myselectedCategory), 선택 된 Index토글: \(selectedToggle)")
                            }
                        }
                    }
                    .padding(.trailing, 8)
                    //MARK: 업로드
                    Text("수정 완료")
                        .font(.pretendardBold18)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundColor(text == "" || selectedImage == [] || myselectedCategory == [] || (searchResult.title == "" && postCoordinator.newMarkerTitle == "") ? .white : .black)
                        .background(text == "" || selectedImage == [] || myselectedCategory == [] || (searchResult.title == "" && postCoordinator.newMarkerTitle == "") ? Color.darkGrayColor : Color.privateColor)
                        .cornerRadius(7)
                        .padding(EdgeInsets(top: 25, leading: 0, bottom: 0, trailing: 13))
                        .onTapGesture {
                            isshowAlert = true
                            
                            print("신규마커최종위치: \(newMarkerlat), \(newMarkerlng)")
                            //
                        }
                        .disabled(text == "" || selectedImage == [] || myselectedCategory == [] || (searchResult.title == "" && postCoordinator.newMarkerTitle == ""))
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isFeedUpdateViewPresented = false
                        selection = 1
                        print("뷰 닫기")
                    } label: {
                        Text("취소")
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .alert(isPresented: $isshowAlert) {
                let firstButton = Alert.Button.cancel(Text("취소")) {
                    print("취소 버튼 클릭")
                }
                let secondButton = Alert.Button.default(Text("완료")) {
                    print("registrationAlert 마지막상태: \(registrationAlert)")
                    self.feedStore.updatedToast = true
                    // 업데이트 피드가 있으면
                    //MARK: 이부분 주석..
                    //                    if postCoordinator.newMarkerTitle.isEmpty {
                    //                        creatFeed()
                    //                    } else {
                    //                        creatMarkerFeed()
                    //                    }
                    //MARK: 업데이트 피드 함수를
                    let newFeed = MyFeed(id: feed.id, writerNickname: feed.writerNickname, writerName: feed.writerName, writerProfileImage: feed.writerProfileImage, images: images, contents: text, createdAt: feed.createdAt, title: searchResult.title, category: myselectedCategory, address: searchResult.address, roadAddress: searchResult.roadAddress, mapx: searchResult.mapx, mapy: searchResult.mapy)
     
                    updateFeed(inputFeed: newFeed, feedId: feed.id)
                    searchResult.title = ""
                    searchResult.address = ""
                    searchResult.roadAddress = ""
                    postCoordinator.newMarkerTitle = ""
                    
                    registrationAlert = false
                    
                    isFeedUpdateViewPresented = false
                    selection = 1
                    print("완료 버튼 클릭")
                    print("registrationAlert 마지막상태: \(registrationAlert)")
                }
                return Alert(title: Text("피드 수정"),
                             message: Text("수정을 완료하시겠습니까?"),
                             primaryButton: firstButton, secondaryButton: secondButton)
            }
            .padding(.leading, 12)
            .navigationTitle("피드 수정")
            .navigationBarTitleDisplayMode(.inline)
        } // navigationStack
        .alert(isPresented: $categoryAlert) {
            Alert(
                title: Text("선택 초과"),
                message: Text("최대 3개까지 선택 가능합니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    } // body
    func toggleCategorySelection(at index: Int) {
        selectedToggle[index].toggle()
        let categoryName = MyCategory.allCases[index].categoryName
        
        if selectedToggle[index] {
            if myselectedCategory.count < maxSelectedCategories {
                myselectedCategory.append(categoryName)
            } else {
                categoryAlert = true
                myselectedCategory = []
                selectedToggle = Array(repeating: false, count: MyCategory.allCases.count)
            }
        } else if let selectedIndex = myselectedCategory.firstIndex(of: categoryName) {
            myselectedCategory.remove(at: selectedIndex)
        }
    }
    func createGridColumns() -> [GridItem] {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
        return columns
    }
    
    func modifyUpdateFeed(with selectedImages: [String]) -> [String] {
        return selectedImages
    }
    func updateFeed(inputFeed: MyFeed, feedId: String) {
        print("Function: \(#function) started")
        var feedCopy = inputFeed
        
        if let selectedImages = selectedImage {
            var imageUrls: [String] = []
            let group = DispatchGroup()
            
            for image in selectedImages {
                guard let imageData = image.jpegData(compressionQuality: 0.2) else { continue }
                
                let storageRef = storage.reference().child(UUID().uuidString)
                
                group.enter()
                storageRef.putData(imageData) { _, error in
                    if let error = error {
                        print("Error uploading image: \(error)")
                        group.leave()
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        guard let imageUrl = url?.absoluteString else {
                            group.leave()
                            return
                        }
                        imageUrls.append(imageUrl)
                        group.leave()  
                    }
                }
            }

            group.notify(queue: .main) {
                let updatedImages = self.modifyUpdateFeed(with: imageUrls)
                feedCopy.images = updatedImages
                
                            Firestore.firestore().collection("Feed").document(feedId).updateData([

                                "writerNickname": userStore.user.nickname,
                                "writerName": userStore.user.id,
                                "writerProfileImage": userStore.user.profileImageURL,
                                "images": feedCopy.images,
                                "contents": inputFeed.contents,
                                "createdAt": inputFeed.createdAt,
                                "title": inputFeed.title,
                                "category": inputFeed.category,
                                "address": inputFeed.address,
                                "roadAddress": inputFeed.roadAddress,
                                "mapx": inputFeed.mapx,
                                "mapy": inputFeed.mapy
                            ]) { error in
                                if let error = error {
                                    print("Error updating feed: \(error.localizedDescription)")
                                } else {
                                    print("Feed updated successfully")
                                    feedStore.fetchFeeds()
                                    
                                }
                            }
                        }
                    }
                }
            }
func getValue(from array: [String], at index: Int) -> String {
    return index < array.count ? array[index] : ""
}

