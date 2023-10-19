//
//  ShopInfoCardView.swift
//  Private
//
//  Created by 주진형 on 2023/09/26.
//

import SwiftUI
import Kingfisher

struct ShopInfoCardView: View {
    @EnvironmentObject var userStore: UserStore
    let mySavedPlaceList: [MyFeed]
    var body: some View {
        ForEach(mySavedPlaceList, id:\.self) {place in
            HStack {
                KFImage(URL(string:place.images[0])) .placeholder {
                    Image(systemName: "photo")
                }
                .resizable()
                .frame(width: 80,height: 80)
                .cornerRadius(10)
                .padding(.leading,20)
                VStack(alignment: .leading) {
                    Text(place.title)
                        .font(.pretendardBold18)
                        .foregroundColor(.primary)
                        .padding(.bottom, 2)
                    VStack(alignment: .leading) {
                        HStack {
                            Label(
                                title: { Text(place.category[0])
                                        .font(.pretendardRegular14)
                                        .foregroundColor(.primary)
                                },
                                icon: { Image(systemName: "fork.knife") }
                            )
                            Text("|")
                                .font(.pretendardRegular14)
                                .foregroundColor(.primary)
                            Label(
                                title: { Text("0") // 가게 좋아요 수 필요
                                        .font(.pretendardRegular14)
                                        .foregroundColor(.primary)
                                },
                                icon: { Image(systemName: "heart.fill") }
                            )
                            .font(.pretendardRegular14)
                            Text("|")
                                .font(.pretendardRegular14)
                                .foregroundColor(.primary)
                            Label(
                                title: { Text("0") // 가게 북마크 수 필요
                                        .font(.pretendardRegular14)
                                        .foregroundColor(.primary)
                                },
                                icon: { Image(systemName: "bookmark.fill") }
                            )
                            .font(.pretendardRegular14)
                        }
                        Label(
                            title: { Text(place.roadAddress)
                                    .font(.pretendardRegular14)
                                    .foregroundColor(.primary)
                            },
                            icon: { Image(systemName: "mappin") }
                        )
                    }
                    .padding(.top,2)
                }
                .padding(.leading,5)
                Spacer()
                Button {
                    userStore.deletePlace(place)
                    userStore.user.bookmark.removeAll { $0 == "\(place.images[0].suffix(32))" }
                    userStore.updateUser(user: userStore.user)
                } label: {
                    Image(systemName: "pin.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(.trailing,20)
                }
            }
            Divider()
                .background(Color.primary)
                .frame(width: .screenWidth * 0.9)
        }
    }
}

struct ShopInfoCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShopInfoCardView(mySavedPlaceList: [MyFeed()]).environmentObject(UserStore())
    }
}
