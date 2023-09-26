//
//  ReservationView.swift
//  Private
//
//  Created by 변상우 on 2023/09/21.
//

import SwiftUI

struct ReservationView: View {
    
    @ObservedObject var shopStore: ShopStore
    @EnvironmentObject var reservationStore: ReservationStore
    
    @State private var date = Date()  // 현재 날짜와 시간을 가져옴

    // 나중에 실제 데이터 가져오면 이거 없애고 ObservedObject로 해결하면 될듯
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Int = -1  // 시간
    @State private var number = 1  // 예약 인원

    @State private var showingDate: Bool = false    // 예약 일시 선택
    @State private var showingNumbers: Bool = false // 예약 인원 선택
    @State private var isSelectedTime: Bool = false
    @State private var isShwoingConfirmView: Bool = false
    
    private let step = 1  // 인원선택 stepper의 step
    private let range = 1...6  // stepper 인원제한
    
    
    /// Double 타입의 날짜를 String으로 변형.
    /// 만약, 예약 날짜가 오늘이면 오늘(요일) 형태로 바꿔줌
    var reservationDate: String {
        let reservationDate: Date = selectedDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")  // 요일을 한국어로 얻기 위해 로케일 설정
        
        if Calendar.current.isDateInToday(reservationDate) {
            // 예약 날짜가 오늘일 경우
            dateFormatter.dateFormat = "오늘(E)" // 요일을 표시하는 형식으로 설정
        } else {
            dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        }
        
        let dateString = dateFormatter.string(from: reservationDate)
        return dateString
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                    .opacity(0)
                
                // 메뉴마다 이렇게 있을 수 없음.. 식당에서는 예약 아이템을 어떻게 둬야할지
                ItemInfoView(shopStore: shopStore, reservationStore: reservationStore)
                    .padding(.bottom, 20)
                
                Text("예약 일시")
                    .font(Font.pretendardBold24)
                
                // 버튼의 범위를 HStack 전체로 할지 고민
                HStack {
                    Image(systemName: "calendar")
                    HStack {
                        Text(reservationDate)
                        Text(" / ")
                        Text(isSelectedTime ? "오후 \(selectedTime)시": "시간") // 오전 /오후 수정
                    }
                    Spacer()
                    
                    Button {
                        showingDate.toggle()
                    } label: {
                        Image(systemName: showingDate ? "chevron.up.circle": "chevron.down.circle")
                    }
                }
                .font(Font.pretendardMedium18)
                .padding()
                .background(Color("SubGrayColor"))
                .padding(.bottom)
                
                if showingDate {
                    DateTimePickerView(reservationStore: reservationStore, date: $date, selectedDate: $selectedDate, selectedTime: $selectedTime, isSelectedTime: $isSelectedTime)
                }
                
                Text("인원")
                    .font(Font.pretendardBold24)
                
                HStack {
                    Image(systemName: "person")
                    Text(isSelectedTime ? String(number) + "명" : "인원 선택")
                    Spacer()
                    Button {
                        showingNumbers.toggle()
                    } label: {
                        Image(systemName: showingNumbers ? "chevron.up.circle": "chevron.down.circle")
                    }
                    .disabled(!isSelectedTime)
                }
                .font(Font.pretendardMedium18)
                .padding()
                .background(Color("SubGrayColor"))
                .padding(.bottom, 20)
                
                // 뷰 따로 빼야함
                // 가게 예약 가능인원 정보를 받을지 말지 정해야함
                if showingNumbers {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("1~6명 까지 선택 가능합니다.")
                            .font(Font.pretendardRegular16)
                    }
                    
                    Divider()
                    
//                    Text("방문하시는 인원을 선택하세요")
                    Stepper(value: $number, in: range, step: step) {
                        Text("\(number)")
                    }
                    .padding(10)
                }
                
                VStack(alignment: .leading) {
                    Divider()
                        .opacity(0)
                    HStack {
                        Image(systemName: "info.circle")
                        Text("알립니다")
                    }
                    .font(Font.pretendardBold18)
                    .foregroundColor(Color("AccentColor"))
                    .padding(.bottom, 6)
                    
                    // BreakTime에 대한 Data 없음
                    Text("Break Time")
                    Text("월~금: 15:00 ~ 17:00")
                    Text("토~일: 15:00 ~ 17:00")
                    Text("당일 예약은 예약을 받지 않습니다.\n예약시간은 10분 경과시, 자동 취소됩니다.\n양해부탁드립니다.")
                }
                .padding()
                .background(Color("SubGrayColor"))
                .cornerRadius(12)
                .padding(.bottom, 30)
                
                Button {
                    // 예약하기 뷰로 넘어가기

                    reservationStore.reservationList[0].date = self.selectedDate
                    reservationStore.reservationList[0].time = self.selectedTime
                    reservationStore.reservationList[0].numberOfPeople = number
                    
                    isShwoingConfirmView.toggle()
                    
                } label: {
                    Text("예약하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .tint(.black)
                .background(Color("AccentColor"))
                .cornerRadius(12)
                .disabled(!isSelectedTime)
                .sheet(isPresented: $isShwoingConfirmView) {
                    ReservationConfirmView(reservationDate: reservationDate)
                }
                
            }// VStack
            
        }// ScrollView
        .padding()
        
    }
}

struct ReservationView_Previews: PreviewProvider {
    static var previews: some View {
        ReservationView(shopStore: ShopStore())
    }
}
