//
//  ReservationView.swift
//  Private
//
//  Created by 변상우 on 2023/09/21.
//

import SwiftUI

struct ReservationView: View {
    @EnvironmentObject var shopStore: ShopStore
    @EnvironmentObject var reservationStore: ReservationStore
    @EnvironmentObject var holidayManager: HolidayManager
    @EnvironmentObject var calendarData: CalendarData
    
    @State private var showingDate: Bool = false    // 예약 일시 선택
    @State private var showingNumbers: Bool = false // 예약 인원 선택
    @State private var isSelectedTime: Bool = false
    @State private var isShwoingConfirmView: Bool = false
    
    @State private var temporaryReservation: Reservation = Reservation(shopId: "", reservedUserId: "유저정보 없음", date: Date(), time: 23, totalPrice: 30000)
    @State private var reservedTime: String = ""
    @State private var reservedHour: Int = 0
    
    @Binding var isReservationPresented: Bool
    
    private let step = 1  // 인원선택 stepper의 step
    private let range = 1...6  // stepper 인원제한
    
    let shopData: Shop
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(shopData.name)
                    .font(.pretendardBold24)
                    .padding(.bottom)
                
                VStack(alignment: .leading) {
                    Divider()
                        .opacity(0)
                    
                    Text("예약 일시")
                        .font(.pretendardBold18)
                    
                    HStack {
                        Image(systemName: "calendar")
                        HStack {
                            // 이 때 호출하면 언제 메소드는 언제 호출되는거야?
                            Text(reservationStore.getReservationDate(reservationDate: calendarData.selectedDate))
                            Text(" / ")
                            Text(isSelectedTime ? self.reservedTime + " \(self.reservedHour)시" : "시간")
                        }
                        Spacer()
                        
                        Button {
                            showingDate.toggle()
                        } label: {
                            Image(systemName: showingDate ? "chevron.up.circle": "chevron.down.circle")
                        }
                    }
                    .font(.pretendardMedium18)
                    .padding()
                    .background(Color("SubGrayColor"))
                    .cornerRadius(12)
                    .padding(.bottom)
                    
                    if showingDate {
                        DateTimePickerView(temporaryReservation: $temporaryReservation, isSelectedTime: $isSelectedTime, shopData: shopData)
                            .onChange(of: temporaryReservation.time) { newValue in
                                self.reservedTime = reservationStore.conversionReservedTime(time: newValue).0
                                self.reservedHour = reservationStore.conversionReservedTime(time: newValue).1
                            }
                    }
                    
                    Text("인원")
                        .font(.pretendardBold18)
                    
                    HStack {
                        Image(systemName: "person")
                        Text(isSelectedTime ? String(temporaryReservation.numberOfPeople) + "명" : "인원 선택")
                        Spacer()
                        Button {
                            showingNumbers.toggle()
                        } label: {
                            Image(systemName: showingNumbers ? "chevron.up.circle": "chevron.down.circle")
                        }
                        .disabled(!isSelectedTime)
                    }
                    .font(.pretendardMedium18)
                    .padding()
                    .background(Color.subGrayColor)
                    .cornerRadius(12)
                    .padding(.bottom, 20)
                    
                    // 가게 예약 가능인원 정보를 받을지 말지 정해야함
                    if showingNumbers {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("1~6명 까지 선택 가능합니다.")
                                .font(.pretendardRegular16)
                        }
                        
                        Divider()
                        
                        Stepper(value: $temporaryReservation.numberOfPeople, in: range, step: step) {
                            Text("\(temporaryReservation.numberOfPeople)")
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
                        .font(.pretendardBold18)
                        .foregroundColor(Color("AccentColor"))
                        .padding(.bottom, 6)
                        
                        Text("Break Time")
                            .font(Font.pretendardMedium18)
                        
                        VStack(alignment: .leading) {
                            ForEach(calendarData.sortedWeekdays, id: \.self) { day in
                                if let hours = shopData.breakTimeHours[day] {
                                    HStack {
                                        Text("\(day)")
                                        
                                        Spacer()
                                        
                                        if shopData.regularHoliday.contains(where: { holidayString in
                                            return holidayString == day
                                        }) {
                                            Text("정기 휴무")
                                        } else {
                                            ShopDetailHourTextView(startHour: hours.startHour, startMinute: hours.startMinute, endHour: hours.endHour, endMinute: hours.endMinute)
                                        }
                                    }
                                    .font(Font.pretendardRegular16)
                                    .padding(.bottom, 1)
                                }
                            }
                            if shopData.breakTimeHours.isEmpty {
                                Text("브레이크 타임이 없습니다.")
                            }
                        }
                        .padding(10)
                        
                        Text("당일 예약은 예약시간 1시간 전까지 가능합니다.")
                            .padding(.bottom, 1)
                        Text("예약시간은 10분 경과시, 자동 취소됩니다.\n양해부탁드립니다.")
                    }
                    .padding()
                    .background(Color.subGrayColor)
                    .cornerRadius(12)
                    .padding(.bottom, 30)
                    
                    HStack {
                        ReservationButton(text: "다음단계") {
                            temporaryReservation.date = calendarData.selectedDate
                            isShwoingConfirmView.toggle()
                        }
                        .foregroundStyle(isSelectedTime ? .primary : Color.gray)
                        .disabled(!isSelectedTime)
                    }
                    .navigationDestination(isPresented: $isShwoingConfirmView) {
                        ReservationDetailView(isShwoingConfirmView: $isShwoingConfirmView, isReservationPresented: $isReservationPresented, reservationData: $temporaryReservation, shopData: shopData)
                    }
                }// VStack
            }// ScrollView
            .padding()
            .onAppear {
                self.temporaryReservation.shopId = self.shopData.id
            }
        }
    }
}

struct ReservationView_Previews: PreviewProvider {
    static var previews: some View {
        ReservationView(isReservationPresented: .constant(true), shopData: ShopStore.shop)
            .environmentObject(ShopStore())
            .environmentObject(ReservationStore())
            .environmentObject(HolidayManager())
            .environmentObject(CalendarData())
    }
}
