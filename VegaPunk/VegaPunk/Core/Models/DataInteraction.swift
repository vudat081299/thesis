//
//  DataInteraction.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/02/2023.
//

import Foundation

class DataInteraction {
    /// Fetch data and perform task after all fetching tasks is finished executing.
    static func fetchData(_ completion: (() -> ())? = nil) {
        let dispatchGroup = DispatchGroup()
        /// Leave dispatchGroup.
        func leave(_ dispatchGroup: DispatchGroup) {
            DispatchQueue.main.async {
                dispatchGroup.leave()
            }
        }
        
        // Request APIs
        dispatchGroup.enter() // <--
        RequestEngine.getAllUsers ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
//        dispatchGroup.enter() // <--
//        RequestEngine.getAllMappings ({
//            leave(dispatchGroup)
//        }, onSuccess: nil)
        
        dispatchGroup.enter() // <--
        RequestEngine.getAllMappingPivots ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
        dispatchGroup.enter() // <--
        RequestEngine.getMyChatBoxes ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
        // Call handler when all tasks is finished
        dispatchGroup.notify(queue: .main) {
            ConcurrencyInteraction.mainQueueAsync(completion)
        }
    }
    
    static func newUserFetch(_ completion: (() -> ())? = nil) {
        let dispatchGroup = DispatchGroup()
        /// Leave dispatchGroup.
        func leave(_ dispatchGroup: DispatchGroup) {
            DispatchQueue.main.async {
                dispatchGroup.leave()
            }
        }
        
        // Request APIs
        dispatchGroup.enter() // <--
        RequestEngine.getAllUsers ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
//        dispatchGroup.enter() // <--
//        RequestEngine.getAllMappings ({
//            leave(dispatchGroup)
//        }, onSuccess: nil)
        
        // Call handler when all tasks is finished
        dispatchGroup.notify(queue: .main) {
            ConcurrencyInteraction.mainQueueAsync(completion)
        }
    }
    
    static func newChatBoxFetch(_ completion: (() -> ())? = nil) {
        let dispatchGroup = DispatchGroup()
        /// Leave dispatchGroup.
        func leave(_ dispatchGroup: DispatchGroup) {
            DispatchQueue.main.async {
                dispatchGroup.leave()
            }
        }
        
        // Request APIs
        dispatchGroup.enter() // <--
        RequestEngine.getAllMappingPivots ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
        dispatchGroup.enter() // <--
        RequestEngine.getMyChatBoxes ({
            leave(dispatchGroup)
        }, onSuccess: nil)
        
        // Call handler when all tasks is finished
        dispatchGroup.notify(queue: .main) {
            ConcurrencyInteraction.mainQueueAsync(completion)
        }
    }
}
