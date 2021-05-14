//
//  DateExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 12/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

//let weekStrings = [R.string.localizable.monday(), R.string.localizable.tuesday(), R.string.localizable.wednesday(), R.string.localizable.thursday(), R.string.localizable.friday(), R.string.localizable.saturday(), R.string.localizable.sunday()]

extension Date {
    func timeFormattedForConversationList(referenceDate now: Date = Date()) -> String {
let date = self
    //  let secondsFromDate = now.secondsFrom(date)
    //  if secondsFromDate < 60 {
    //    return secondsFormatter()
    //  }
    //
    //  let minutesFromDate = now.minutesFrom(date)
    //  if minutesFromDate < 60 {
    //    return minutesFormatter(minutesFromDate)
    //  }

      let hoursFromDate = now.hoursFrom(date)
      if hoursFromDate < 24 {
        //显示时间
        return date.string(withFormat: "HH:mm")
      }
      let daysFromDate = now.daysFrom(date)
        guard daysFromDate > 7 else {
            return date.dayName()
        }
        return date.dateString(ofStyle: .medium)

    //  switch daysFromDate {
    //  case 1:
    //    return yesterdayFormatter()
    //  case 2...6:
    //    return daysFormatter(daysFromDate)
    //  default:
    //    break
    //  }

    //  let weeksFromDate = now.weeksFrom(date)
    //  let monthsFromDate = now.monthsFrom(date)
    //  switch monthsFromDate {
    //  case 0:
    //    return weeksFormatter(weeksFromDate)
    //  case 1...11:
    //    return monthsFormatter(monthsFromDate)
    //  default:
    //    break
    //  }
    //
    //  let yearsFromDate = now.yearsFrom(date)
    //  return yearsFormatter(yearsFromDate)
    }

    func timeFormattedForConversation(referenceDate now: Date = Date()) -> String {
        let date = self
    //  let secondsFromDate = now.secondsFrom(date)
    //  if secondsFromDate < 60 {
    //    return secondsFormatter()
    //  }
    //
    //  let minutesFromDate = now.minutesFrom(date)
    //  if minutesFromDate < 5 {
    //    return date.string(withFormat: "dd/MM/yyyy HH:mm")
    //  }

      let hoursFromDate = now.hoursFrom(date)
      if hoursFromDate < 24 {
        //显示时间
        return date.string(withFormat: date.string(withFormat: "dd/MM/yyyy HH:mm"))
      }
      let daysFromDate = now.daysFrom(date)
        guard daysFromDate > 7 else {
    //        return weekStrings[date.weekday]
            return date.dayName() + " " + date.string(withFormat: "HH:mm")
        }
        return date.string(withFormat: date.string(withFormat: "dd/MM/yyyy HH:mm"))

    //  switch daysFromDate {
    //  case 1:
    //    return yesterdayFormatter()
    //  case 2...6:
    //    return daysFormatter(daysFromDate)
    //  default:
    //    break
    //  }

    //  let weeksFromDate = now.weeksFrom(date)
    //  let monthsFromDate = now.monthsFrom(date)
    //  switch monthsFromDate {
    //  case 0:
    //    return weeksFormatter(weeksFromDate)
    //  case 1...11:
    //    return monthsFormatter(monthsFromDate)
    //  default:
    //    break
    //  }
    //
    //  let yearsFromDate = now.yearsFrom(date)
    //  return yearsFormatter(yearsFromDate)
    }

    // MARK: Formatter functions
    func classicFormatterAgo(_ quantity: Int, _ unit: String) -> String {
      var formattedString = "\(quantity) \(unit)"
      if quantity > 1 {
        formattedString += "s"
      }
      formattedString += " ago"
      return formattedString
    }

    func secondsFormatter() -> String {
      return "Just now"
    }

    func minutesFormatter(minutes: Int) -> String {
      return classicFormatterAgo(minutes, "minute")
    }

    func hoursFormatter(hours: Int) -> String {
      return classicFormatterAgo(hours, "hour")
    }

    func yesterdayFormatter() -> String {
      return "Yesterday"
    }

    func daysFormatter(days: Int) -> String {
      return classicFormatterAgo(days, "day")
    }

    func weeksFormatter(weeks: Int) -> String {
      return classicFormatterAgo(weeks, "week")
    }

    func monthsFormatter(months: Int) -> String {
      return classicFormatterAgo(months, "month")
    }

    func yearsFormatter(years: Int) -> String {
      return classicFormatterAgo(years, "year")
    }
    
  func yearsFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
  }
  func monthsFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
  }
  func weeksFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.weekday], from: date, to: self).weekday ?? 0
  }
  func daysFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
  }
  func hoursFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
  }
  func minutesFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
  }
  func secondsFrom(_ date: Date) -> Int {
    return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
  }
}
