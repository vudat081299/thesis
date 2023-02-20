//
//  String.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 19/05/2021.
//

import Foundation
import UIKit

extension String {
//    func toDate() -> Date {
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
//        dateFormatter.calendar = Calendar(identifier: .gregorian)
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ" // 2022-12-28 17:09:15 +0000
//        guard let date = dateFormatter.date(from: self) else {
//            return Date()
//        }
//        return date
//    }
    
    /// Convert from date String to shortTime String.
    func transformToShortTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        guard let date = dateFormatter.date(from: self)
        else {
            return ""
        }
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        return dateFormatter.string(from: date)
    }
    
    func getImageWithThisURL() -> UIImage? {
        print("Get image with url string: \(self)")
        do {
            return UIImage(data: try Data(contentsOf: URL(string: self)!))
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    
    
    // MARK: - Remake
    func toDate() -> Date {
        guard let epochTime = Int(self) else { return Date() }
        return Date(timeIntervalSince1970: TimeInterval(epochTime > 10_000_000_000 ? epochTime / 1_000 : epochTime))
    }
}


// MARK: - Storing UserDefaults Keys or Storing file paths
extension String {
    // Keys
//    static let KeyAuthenticatedUser = "KEY_AUTHENTICATED_USER"
    
    // File paths
}


// MARK: - Hash to 16bit
extension String {
    var fourBitHash: Int {
        self.utf8.reduce(0) { $0 + Int($1) } % 16
    }
}

extension String {
    /// Capitalize first character of string.
    var Capitalized: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
}
