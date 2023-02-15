//
//  FileManager.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 26/05/2021.
//

import Foundation
import UIKit

extension FileManager {
    
    /// - The parameter filename doesn't need enter .png extension.
    static func loadImageFromFileWithPNGEx(_ fileName: String) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(fileName).png")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data.init(contentsOf: fileURL)
                return UIImage(data: data)
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func confirmFileExists(atPath: URL, isDirectory: ObjCBool = false)  {
        do {
            var isDirectory = isDirectory
            if !FileManager.default.fileExists(atPath: atPath.absoluteString, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: atPath, withIntermediateDirectories: true, attributes: nil)
            }
        }
        catch {
            print("FileManager fail when createDirectory - \(error)")
        }
    }
}
