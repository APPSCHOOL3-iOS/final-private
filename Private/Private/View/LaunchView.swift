//
//  LaunchView.swift
//  Private
//
//  Created by 변상우 on 2023/09/18.
//

import SwiftUI

struct LaunchView: View {
    
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    
    @State private var isActive = false
    @State private var isloading = true
    
    var body: some View {
        if isActive {
            if authStore.currentUser != nil {
                 MainTabView()
             } else {
                 MainLoginView()
             }
        } else {
            if isloading {
                VStack {
                    Text("Private")
                        .font(.pretendardBold28)
                        .foregroundStyle(.foreground)
                }
                .onAppear {
                    if let email = authStore.currentUser?.email {
                        userStore.fetchMyInfo(userEmail: email, completion: { result in
                            if result {
                                self.isActive = true
                            }
                        })
                        userStore.fetchCurrentUser(userEmail: email)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isloading.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
