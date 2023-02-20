//
//  UUID.swift
//  VegaPunk
//
//  Created by Dat Vu on 06/02/2023.
//

import Foundation


// MARK: - Hash to 16bit
extension UUID {
    var fourBitHash: Int {
        self.uuidString.fourBitHash
    }
}
