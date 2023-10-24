//
//  ChatRoomStore.swift
//  Private
//
//  Created by 변상우 on 2023/09/22.
//

import Foundation
import FirebaseFirestore

final class ChatRoomStore: ObservableObject {
    @Published var chatRoomList: [ChatRoom] = [ChatRoom(firstUserNickname: "ii", firstUserProfileImage: "", secondUserNickname: "boogie", secondUserProfileImage: "")]
    @Published var messageList: [Message] = []
    @Published var isShowingChatLoading : Bool = false
    @Published var chatRoomMessageToast : Bool = false
    
    let userCollection = Firestore.firestore().collection("User")
    let chatRoomCollection = Firestore.firestore().collection("ChatRoom")
    
    private var timer: Timer?
    private var timeInterval: Double = 0.1
    private var listenerObject: ListenerRegistration?
    
    //@MainActor 검토
    func subscribeToChatRoomChanges (user: User) {
        print("email")
        print(user.email)
        print("count")
        print(chatRoomList.count)
        print("user.nickname")
        print(user.nickname)
        
        let userCollection = Firestore.firestore().collection("ChatRoom")
        
        listenerObject = userCollection
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error getting chat room documents: \(error)")
                    return
                }
                
                guard let querySnapshot = querySnapshot else {
                    print("No chat room documents found for the given nickname")
                    return
                }
                
                var chatRooms: [ChatRoom] = []
                
                for document in querySnapshot.documents {
                    
                    let documentID = document.documentID
                    
                    let nicknames = documentID.split(separator: ",")
                    
                    if let nickname1 = nicknames.first, let nickname2 = nicknames.last {
                        if (nickname1 == user.nickname || nickname2 == user.nickname) {
                            let documentData = document.data()
                            if let chatRoomData = documentData as? [String: Any],
                               let firstUserNickname = chatRoomData["firstUserNickname"] as? String,
                               let firstUserProfileImage = chatRoomData["firstUserProfileImage"] as? String,
                               let secondUserNickname = chatRoomData["secondUserNickname"] as? String,
                               let secondUserProfileImage = chatRoomData["secondUserProfileImage"] as? String {
                                let chatRoom = ChatRoom(firstUserNickname: firstUserNickname, firstUserProfileImage: firstUserProfileImage, secondUserNickname: secondUserNickname, secondUserProfileImage: secondUserProfileImage)
                                chatRooms.append(chatRoom)
                                
                            }
                        }
                    }
                }
                print("chatRooms::\(chatRooms)")
                DispatchQueue.main.async {
                    self?.chatRoomList = chatRooms
                    print("chatRoomList::\(self?.chatRoomList)")
                }
            }
    }
    
    func removeListener() {
           listenerObject?.remove()
       }
    
    func addChatRoomToUser(user: User, chatRoom: ChatRoom) {
        let userCollection = Firestore.firestore().collection("ChatRoom")
        
        if (user.nickname == chatRoom.firstUserNickname) {
            let subCollection = userCollection.document("\(user.nickname),\(chatRoom.secondUserNickname)")
            
            var chatRoomData: [String: Any] = [:]
            
            chatRoomData["firstUserNickname"] = chatRoom.firstUserNickname
            chatRoomData["firstUserProfileImage"] = user.profileImageURL
            chatRoomData["secondUserNickname"] = chatRoom.secondUserNickname
            chatRoomData["secondUserProfileImage"] = chatRoom.secondUserProfileImage
            
            subCollection.setData(chatRoomData) { error in
                if let error = error {
                    print("Error adding chatRoom: \(error.localizedDescription)")
                } else {
                    print("Reservation added to Firestore")
                }
            }
        } else {
            // Create Message subcollection
            let subCollection = userCollection.document("\(user.nickname),\(chatRoom.firstUserNickname)")
            
            var chatRoomData: [String: Any] = [:]
            
            chatRoomData["firstUserNickname"] = chatRoom.firstUserNickname
            chatRoomData["firstUserProfileImage"] = chatRoom.firstUserProfileImage
            chatRoomData["secondUserNickname"] = chatRoom.secondUserNickname
            chatRoomData["secondUserProfileImage"] = user.profileImageURL
           
            subCollection.setData(chatRoomData) { error in
                if let error = error {
                    print("Error adding chatRoom: \(error.localizedDescription)")
                } else {
                    print("Reservation added to Firestore")
                }
            }
        }
    }
    
    func removeChatRoom(myNickName: String, otherUserNickname: String){
        
        let subCollection1 = chatRoomCollection.document("\(myNickName),\(otherUserNickname)")
        let subCollection2 = chatRoomCollection.document("\(otherUserNickname),\(myNickName)")
        
        let subCollectionMessage1 = subCollection1.collection("Message")
        let subCollectionMessage2 = subCollection2.collection("Message")
        
        // 문서 삭제
        subCollection1.collection("Message").getDocuments { (snapshot, error) in
            if let error = error {
                print("메시지 컬렉션 가져오기 오류: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("메시지 컬렉션 없음")
                return
            }
            
            for document in documents {
                document.reference.delete()
            }
            
            // 채팅방 문서 삭제
            subCollection1.delete { error in
                if let error = error {
                    print("채팅방 문서 삭제 오류: \(error.localizedDescription)")
                } else {
                    print("채팅방 문서 삭제 성공")
                }
            }
            
            
        }
        
        subCollection2.collection("Message").getDocuments { (snapshot, error) in
            if let error = error {
                print("메시지 컬렉션 가져오기 오류: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("메시지 컬렉션 없음")
                return
            }
            
            for document in documents {
                document.reference.delete()
            }
            
            // 채팅방 문서 삭제
            subCollection2.delete { error in
                if let error = error {
                    print("채팅방 문서 삭제 오류: \(error.localizedDescription)")
                } else {
                    print("채팅방 문서 삭제 성공")
                }
            }
        }
    }
    
    func fetchMessage(myNickName: String, otherUserNickname: String){
        var tempChatMessageListLocal:[Message] = []
        self.isShowingChatLoading = true
        
        timer = Timer.scheduledTimer(withTimeInterval:  0.5, repeats: true) { timer in
            print("=======fetchMessage=========")
            let userCollection = Firestore.firestore().collection("ChatRoom")
            let subCollection1 = userCollection.document("\(myNickName),\(otherUserNickname)")
            let messageCollection1 = subCollection1.collection("Message")
            
            let subCollection2 = userCollection.document("\(otherUserNickname),\(myNickName)")
            let messageCollection2 = subCollection2.collection("Message")
            
            userCollection
                .getDocuments { (querySnapshot, error) in
                    
                    if let error = error {
                        print("Error getting chat room documents: \(error)")
                        return
                    }
                    
                    guard let querySnapshot = querySnapshot else {
                        print("No chat room documents found for the given nickname")
                        return
                    }
                    print("=======for=========")
                    
                    for document in querySnapshot.documents {
                        let documentID = document.documentID
                        if documentID == "\(myNickName),\(otherUserNickname)" {
                            print("documentID: \(myNickName),\(otherUserNickname)")
                            messageCollection1.order(by: "timestamp", descending: false).getDocuments { (querySnapshot, error) in
                                if let error = error {
                                    print("Error getting chat room documents: \(error)")
                                    return
                                }
                                guard let querySnapshot = querySnapshot else {
                                    print("No chat room documents found for the given nickname")
                                    return
                                }
                                for document in querySnapshot.documents {
                                    let documentData = document.data()
                                    print("documentData: \(documentData)")
                                    if let messageData = documentData as? [String: Any],
                                       let sender = messageData["sender"] as? String,
                                       let content = messageData["content"] as? String,
                                       let timestamp = messageData["timestamp"] as? Double {
                                        let message = Message(sender: sender, content: content, timestamp: timestamp)
                                        tempChatMessageListLocal.append(message)
                                    }
                                }
                            }
                        } else if documentID == "\(otherUserNickname),\(myNickName)" {
                            print("documentID: \(otherUserNickname),\(myNickName)")
                            messageCollection2.order(by: "timestamp", descending: false).getDocuments { (querySnapshot, error) in
                                if let error = error {
                                    print("Error getting chat room documents: \(error)")
                                    return
                                }
                                guard let querySnapshot = querySnapshot else {
                                    print("No chat room documents found for the given nickname")
                                    return
                                }
                                
                                for document in querySnapshot.documents {
                                    let documentData = document.data()
                                    if let messageData = documentData as? [String: Any],
                                       let sender = messageData["sender"] as? String,
                                       let content = messageData["content"] as? String,
                                       let timestamp = messageData["timestamp"] as? Double
                                    {
                                        let message = Message(sender: sender, content: content, timestamp: timestamp)
                                        tempChatMessageListLocal.append(message)
                                    }
                                }
                            }
                        }
                    }
                }
            DispatchQueue.main.async {
                if self.messageList != tempChatMessageListLocal {
                    self.messageList = tempChatMessageListLocal
                    tempChatMessageListLocal=[]
                    self.isShowingChatLoading = false
                }
                tempChatMessageListLocal=[]
            }
        }
    }
    
    func stopFetchMessage() {
        messageList = []
        timer?.invalidate()
        timer = nil
    }
    
    func sendMessage(myNickName: String, otherUserNickname: String, message: Message) {
        print("myNickName:\(myNickName) /n otherUserNickname:\(otherUserNickname) /n message:\(message)")
        let userCollection = Firestore.firestore().collection("ChatRoom")
        let subCollection1 = userCollection.document("\(myNickName),\(otherUserNickname)")
        let messageCollection1 = subCollection1.collection("Message")
        
        let subCollection2 = userCollection.document("\(otherUserNickname),\(myNickName)")
        let messageCollection2 = subCollection2.collection("Message")
        
        var tempMessageList = messageList
        tempMessageList.append(message)
        
        var messagesData: [String: Any] = [:]
        
        for message in tempMessageList {
            if let messageDict = messageToDictionary(message) {
                print("messageDict:\(messageDict)")
                messagesData = messageDict
            } else {
                print("Invalid message data")
                return
            }
        }
        userCollection
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting chat room documents: \(error)")
                    return
                }
                
                guard let querySnapshot = querySnapshot else {
                    print("No chat room documents found for the given nickname")
                    return
                }
                
                for document in querySnapshot.documents {
                    let documentID = document.documentID
                    if documentID == "\(myNickName),\(otherUserNickname)" {
                        messageCollection1.addDocument(data: messagesData) { error in
                            if let error = error {
                                print("Error adding chatRoom: \(error.localizedDescription)")
                            } else {
                                print("Reservation added to Firestore")
                            }
                        }
                    } else if documentID == "\(otherUserNickname),\(myNickName)" {
                        messageCollection2.addDocument(data: messagesData) { error in
                            if let error = error {
                                print("Error adding chatRoom: \(error.localizedDescription)")
                            } else {
                                print("Reservation added to Firestore")
                            }
                        }
                    }
                }
            }
        DispatchQueue.main.async {
            self.chatRoomMessageToast = true
        }
    }
    
    // Message 객체를 딕셔너리로 변환하는 함수
    func messageToDictionary(_ message: Message) -> [String: Any]? {
        return [
            "sender": message.sender,
            "content": message.content,
            "timestamp": message.timestamp,
        ]
    }
    
    func findChatRoom(user:User, firstNickname: String, firstUserProfileImage: String, secondNickname: String, secondUserProfileImage: String) -> ChatRoom? {
        for chatRoom in self.chatRoomList {
            if (chatRoom.firstUserNickname == firstNickname && chatRoom.secondUserNickname == secondNickname) ||
                (chatRoom.firstUserNickname == secondNickname && chatRoom.secondUserNickname == firstNickname) {
                return chatRoom
            }
        }
        
        //chatRoom이 없는 경우 생성
        print("::make new chatRoom")
        let newChatRoom = ChatRoom(firstUserNickname: firstNickname, firstUserProfileImage: firstUserProfileImage, secondUserNickname: secondNickname, secondUserProfileImage: secondUserProfileImage)
        
        addChatRoomToUser(user: user, chatRoom: newChatRoom)
        print("::chatRoomList is empty.")
        return newChatRoom
    }
    
    init() {
        print("ChatRoomStore reset.")
    }
}


