//
//  ShopDetailMenuView.swift
//  Private
//
//  Created by H on 2023/09/22.
//

import SwiftUI
import Kingfisher

struct ShopDetailMenuView: View {
    
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var reservationStore: ReservationStore
    
    let shopData: Shop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVStack {
                ForEach(shopData.menu, id: \.self) { menu in
                    HStack(spacing: 10) {
                        KFImage(getImageString(url: menu.imageUrl))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)                         
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(menu.name)")
                                .font(.pretendardMedium18)
                            
                            Text("\(menu.price)")
                                .font(.pretendardRegular14)
                        }
                        
                        Spacer()
                    }
                    .padding(10)
                }
            }
        }
    }
    
    func getImageString(url: String) -> URL {
        guard let myUrl = URL(string: url) else {
            return URL(string: "https://e7.pngegg.com/pngimages/595/505/png-clipart-computer-icons-error-closeup-miscellaneous-text.png")!
        }
        return myUrl
    }
}

struct ShopDetailMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ShopDetailMenuView(shopData: ShopStore.shop)
            .environmentObject(ShopStore())
            .environmentObject(ReservationStore())
    }
}
