//
//  HolidayManager.swift
//  Private
//
//  Created by 박성훈 on 10/17/23.
//

import Foundation

class HolidayManager: ObservableObject {
    @Published var publicHolidays: [[String: Any]] = []
    
    let networkManager = NetworkManager.shared
    
    private let thisYear: Int = Calendar.current.component(.year, from: Date())
    private let nextYear: Int = Calendar.current.component(.year, from: Date()) + 1

    
    init() {
        self.fetchData(year: thisYear)
        self.fetchData(year: nextYear)
    }
    
    private func fetchData(year: Int) {
        networkManager.fetchHoliday(year: year) { result in
            switch result {
            case .success(let holidayDatas):
                
                DispatchQueue.main.async {
                    self.publicHolidays.append(contentsOf: holidayDatas.map { $0.toDictionary() })
                }

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
