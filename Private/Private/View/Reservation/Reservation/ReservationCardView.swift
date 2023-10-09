//
//  ReservationCardView.swift
//  Private
//
//  Created by 박성훈 on 10/3/23.
//

import SwiftUI

struct ReservationCardView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @State private var isShowDeleteAlert: Bool = false
    
    let reservation: Reservation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // ~ 예약시간 이용 전
            // 예약 시간 ~ 2시간까지 이용 중
            // 이용시간 2시간 후 이용 완료로 바꾸기
            
            HStack {
                Text(reservationStore.isFinishedReservation(date: reservation.date, time: reservation.time))
                    .font(.pretendardMedium20)
                
                Spacer()
                Menu {
                    Button {
                        print(#fileID, #function, #line, "- 가게보기")
                    } label: {
                        Text("가게보기")
                    }
                    
                    Button {
                        print(#fileID, #function, #line, "- 예약 상세내역 보기")
                    } label: {
                        Text("예약상세")
                    }
                    
                    Button(role: .destructive) {
                        print(#fileID, #function, #line, "- 예약내역 삭제")
                        reservationStore.deleteMyReservation(reservation: reservation)
                    } label: {
                        Text("예약내역 삭제")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(20)  // 버튼 터치 영역을 넓히기 위함
                }
                .foregroundColor(Color.secondary)
            }
            
            ReservationCardCell(title: "예약 날짜", content: dateToFullString(date: reservation.date))
            ReservationCardCell(title: "예약 시간", content: "\(reservation.time)시")
            ReservationCardCell(title: "예약 인원", content: "\(reservation.numberOfPeople)명")
            ReservationCardCell(title: "총 비용", content: "\(reservation.totalPrice)원")
            
            
            Button {
                print(#fileID, #function, #line, "- 예약 변경하기 ")
            } label: {
                Text("예약 변경")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color("AccentColor"))
            .cornerRadius(12)
            
            Button {
                print(#fileID, #function, #line, "- 예약 취소하기 ")
                isShowDeleteAlert.toggle()
            } label: {
                Text("예약 취소")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color("AccentColor"))
            .cornerRadius(12)
        }
        .padding()
        .background(Color("SubGrayColor"))
        .cornerRadius(12)
        .alert("예약 취소", isPresented: $isShowDeleteAlert) {
            Button(role: .destructive) {
                reservationStore.removeReservation(reservation: reservation)
            } label: {
                Text("취소하기")
            }
            
            Button(role: .cancel) {
                
            } label: {
                Text("돌아가기")
            }
            .foregroundStyle(Color.red)
        }
    }
    
    func dateToFullString(date: Date) -> String {
        let formatter = DateFormatter()
        //        formatter.locale = Locale(identifier: Locale.current.identifier)
        formatter.locale = Locale(identifier: "ko_KR")
        //        formatter.timeZone = TimeZone(identifier: TimeZone.current.identifier)
        formatter.timeZone = TimeZone(abbreviation: "KST")
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct ReservationCardView_Previews: PreviewProvider {
    static var previews: some View {
        ReservationCardView(reservation: ReservationStore.tempReservation)
            .environmentObject(ReservationStore())
    }
}

struct ReservationCardCell: View {
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(title)")
                .font(Font.pretendardMedium18)
            
            Spacer()
            
            Text("\(content)")
                .font(Font.pretendardMedium16)
        }
    }
}
