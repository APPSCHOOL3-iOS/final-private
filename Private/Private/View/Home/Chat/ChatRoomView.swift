//
//  ChatRoomView.swift
//  Private
//
//  Created by 변상우 on 2023/09/25.
//

import SwiftUI
import Kingfisher

struct ChatRoomView: View {
    
    @EnvironmentObject var chatRoomStore: ChatRoomStore
    @EnvironmentObject var userStore: UserStore
    
    @State private var message: String = ""
    
    var chatRoom: ChatRoom
    
    var body: some View {
        //        ScrollView {
        ZStack{
            VStack{
                List(chatRoomStore.messageList, id: \.self) { message in
                    if (message.sender == userStore.user.nickname) {
                        Text(message.content)
                            .padding(10)
                            .padding(.horizontal, 5)
                            .background(Color.privateColor)
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .listRowSeparator(.hidden)
                    } else {
                        Text(message.content)
                            .padding(10)
                            .padding(.horizontal, 5)
                            .background(Color.lightGrayColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowSeparator(.hidden)
                    }
                }
                
                .listStyle(.plain)
            }
            //    }
            if chatRoomStore.isShowingChatLoading {
                ProgressView()
            }
        }
        
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if (userStore.user.nickname == chatRoom.firstUserNickname) {
                    HStack {
                        KFImage(URL(string: chatRoom.secondUserProfileImage))
                            .placeholder {
                                Image("userDefault")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                                    .cornerRadius(50)
                            }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .cornerRadius(50)
                        VStack(alignment: .leading) {
                            Text("\(chatRoom.secondUserNickname)")
                                .font(.pretendardSemiBold14)
                        }
                        .padding(.leading, 5)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image("userDefault")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .cornerRadius(50)
                        VStack(alignment: .leading) {
                            Text("\(chatRoom.firstUserNickname)")
                                .font(.pretendardSemiBold14)
                        }
                        .padding(.leading, 5)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .backButtonArrow()
        
        .onAppear {
            //            chatRoomStore.checkFetchMessage(myNickName: userStore.user.nickname, otherUserNickname: userStore.user.nickname == chatRoom.firstUserNickname ? chatRoom.secondUserNickname : chatRoom.firstUserNickname)
            chatRoomStore.fetchMessage(myNickName: userStore.user.nickname, otherUserNickname: userStore.user.nickname == chatRoom.firstUserNickname ? chatRoom.secondUserNickname : chatRoom.firstUserNickname)
            print("\(chatRoomStore.messageList)")
            print("\(userStore.user)")
            print("\(chatRoom)")
        }
        .onDisappear {
            chatRoomStore.stopFetchMessage()
        }
        SendMessageTextField(text: $message, placeholder: "메시지를 입력하세요") {
            print("chatRoom-sendMessage\(chatRoom)")
            if message != "" {
                chatRoomStore.sendMessage(myNickName: userStore.user.nickname, otherUserNickname: userStore.user.nickname == chatRoom.firstUserNickname ? chatRoom.secondUserNickname : chatRoom.firstUserNickname, message: Message(sender: userStore.user.nickname, content: message, timestamp: Date().timeIntervalSince1970))
                message = ""
            }
        }
    }
}

//struct ChatRoomView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatRoomView(chatRoom: ChatRoomStore.chatRoom)
//    }
//}
