//
//  ConcurrencyInteraction.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/02/2023.
//

import Foundation

class ConcurrencyInteraction {
    static func leave(_ dispatchGroup: DispatchGroup) {
        DispatchQueue.main.async {
            dispatchGroup.leave()
        }
    }
    static func mainQueueAsync(_ task: (() -> ())? = nil) {
        DispatchQueue.main.async {
            if let task = task { task() }
        }
    }
}
