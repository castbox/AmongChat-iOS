//
//  DatePickerView.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class DatePickerView: UIPickerView {
        
        enum DatePickerComponent : Int {
            case month, day, year
        }
        
        var minYear = 1900
        var maxYear = 2020
        var rowHeight : CGFloat = 42
        
        var date: Date {
            let month = months[selectedRow(inComponent: DatePickerComponent.month.rawValue) % months.count]
            let year = years[selectedRow(inComponent: DatePickerComponent.year.rawValue) % years.count]
            let day = days[selectedRow(inComponent: DatePickerComponent.day.rawValue) % days.count]
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM:yyyy:dddd"
            let date = formatter.date(from: "\(month):\(year):\(day)")
            return date!
        }
        
        var selectedDate: String {
            
            let month = selectedRow(inComponent: DatePickerComponent.month.rawValue) % months.count + 1
            let year = years[selectedRow(inComponent: DatePickerComponent.year.rawValue) % years.count]
            let day = days[selectedRow(inComponent: DatePickerComponent.day.rawValue) % days.count]
            
            return "\(year)/\(month)/\(day)"
        }
        
        private var yearFont = R.font.nunitoExtraBold(size: 20)
        private let bigRowCount = 1000
        private let componentsCount = 3
        private let formatter = DateFormatter()
        private var rowLabel : UILabel {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: componentWidth, height: rowHeight))
            label.textAlignment = .center
            label.backgroundColor = UIColor.clear
            return label
        }
        
        private var months = ["January", "February", "March", "April",
                              "May", "June", "July","August", "September",
                              "October", "November", "December", ]
        
        private var years : Array<String> {
            let years = [Int](minYear...maxYear)
            return years.map({ "\($0)"})
        }
        
        private var days:[String] {
            let day = [Int](1...31)
            return day.map({"\($0)"})
        }
        
        private var currentDay = Date()
        
        private var currentMonthName: String {
            formatter.locale = Locale.init(identifier: "en_US")
            formatter.dateFormat = "MMMM"
            let dateString = formatter.string(from: currentDay)
            return NSLocalizedString(dateString, comment: "")
        }
        
        private var currentYearName: String {
            formatter.locale = Locale.init(identifier: "en_US")
            formatter.dateFormat = "yyyy"
            return formatter.string(from: currentDay)
        }
        
        private var currentDayName: String {
            formatter.locale = Locale.init(identifier: "en_US")
            formatter.dateFormat = "dd"
            return formatter.string(from: currentDay)
        }
        
        private var bigRowMonthCount: Int {
            return months.count * bigRowCount
        }
        
        private var bigRowDayCount: Int {
            return days.count * bigRowCount
        }
        
        private var bigRowYearCount : Int {
            return years.count * bigRowCount
        }
        
        private var componentWidth: CGFloat {
            return self.bounds.size.width / CGFloat(componentsCount)
        }
        
        private var todayIndexPath: IndexPath {
            var row = 0
            var section = 0
            let currentMonthName = self.currentMonthName
            let currentYearName = self.currentYearName
            
            for month in months {
                if month == currentMonthName {
                    row = months.firstIndex(of: month)!
                    row += bigRowMonthCount / 2
                    break;
                }
            }
            
            for year in years {
                if year == currentYearName {
                    section = years.firstIndex(of: year)!
                    section += bigRowYearCount / 2
                    break;
                }
            }
            return IndexPath(row: row, section: section)
        }
        
        private var currentDayRow: Int {
            var row = 0
            for day in days {
                if day == currentDayName {
                    row = days.firstIndex(of: day)!
                    row += bigRowDayCount / 2
                    break;
                }
            }
            return row
        }
        
        //MARK: - Override
        override init(frame: CGRect) {
            super.init(frame: frame)
            loadDefaultsParameters()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            loadDefaultsParameters()
        }
        
        override func awakeFromNib(){
            super.awakeFromNib()
            loadDefaultsParameters()
        }
        
        //MARK: - Public
        func selectToday() {
            selectRow(todayIndexPath.row, inComponent: DatePickerComponent.month.rawValue, animated: false)
            selectRow(todayIndexPath.section, inComponent: DatePickerComponent.year.rawValue, animated: false)
            selectRow(currentDayRow, inComponent: DatePickerComponent.day.rawValue, animated: false)
        }
        
        func selectBirthday(_ text: String) {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "yyyy/MM/dd"
            currentDay = formatter.date(from: text) ?? Date()
            selectToday()
        }
                
        private func loadDefaultsParameters() {
            delegate = self
            dataSource = self
        }
    }
}
extension Social.DatePickerView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return componentWidth
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label : UILabel
        if view is UILabel {
            label = view as! UILabel
        } else {
            label = rowLabel
        }
        
        label.font = yearFont
        label.textColor = .white
        label.text = titleForRow(row, component: component)
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return rowHeight
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return componentsCount
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == DatePickerComponent.month.rawValue {
            return bigRowMonthCount
        } else if component == DatePickerComponent.day.rawValue {
            return bigRowDayCount
        }
        return bigRowYearCount
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let month = (selectedRow(inComponent: DatePickerComponent.month.rawValue) + 1) % 12
        let day = selectedRow(inComponent: DatePickerComponent.day.rawValue) % 31
        let year = years[selectedRow(inComponent: DatePickerComponent.year.rawValue) % years.count].int ?? 2020
        
        if year % 4 == 0 {
            if month == 2 {
                if day == 29 || day == 30 {
                    let gap = day - 28
                    let daySelectedRow = selectedRow(inComponent: DatePickerComponent.day.rawValue)
                    selectRow(daySelectedRow - gap, inComponent: DatePickerComponent.day.rawValue, animated: true)
                }
            }
        } else {
            if month == 2 {
                if day == 28 || day == 29 || day == 30 {
                    let gap = day - 27
                    let daySelectedRow = selectedRow(inComponent: DatePickerComponent.day.rawValue)
                    selectRow(daySelectedRow - gap, inComponent: DatePickerComponent.day.rawValue, animated: true)
                }
            }
        }
    }
    
    private func titleForRow(_ row : Int, component : Int) -> String {
        if component == DatePickerComponent.month.rawValue {
            return months[row % months.count]
        } else if component == DatePickerComponent.day.rawValue {
            return days[row % days.count]
        }
        return years[row % years.count]
    }
}
