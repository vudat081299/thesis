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


// MARK: -
extension String {
    func transformToArrayUInt8() -> [UInt8] {
        var result: Array<UInt8> = []
        let utf8 = Array<UInt8>(self.utf8)
        let skip0x = self.hasPrefix("0x") ? 2 : 0
        for idx in stride(from: utf8.startIndex.advanced(by: skip0x), to: utf8.endIndex, by: utf8.startIndex.advanced(by: 2)) {
            let byteHex = "\(UnicodeScalar(utf8[idx]))\(UnicodeScalar(utf8[idx.advanced(by: 1)]))" // Crash when exceed, check this!
            if let byte = UInt8(byteHex, radix: 16) {
                result.append(byte)
            }
        }
        return result
    }
    func transformToArrayUInt8ByTrimmingIV() -> [UInt8] {
        let trimedIVCipherText = self[self.index(self.startIndex, offsetBy: 32)..<self.endIndex]
        return String(trimedIVCipherText).transformToArrayUInt8()
    }
    func ivFromFullCipherText() -> String {
        return String(self[self.startIndex..<self.index(self.startIndex, offsetBy: 32)])
    }
    func cipherTextFromFullCipherText() -> String {
        let trimedIVCipherText = self[self.index(self.startIndex, offsetBy: 32)..<self.endIndex]
        return String(trimedIVCipherText)
    }
}
