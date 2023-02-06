//
//  ApplicationState.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/02/2023.
//

import UIKit

enum ApplicationState {
    case authorized, unauthorized
    
    /// Handle `instantiateViewController` on app state
    func handleHierarchyOnState() -> UIViewController {
        switch self {
        case .unauthorized:
            let storyboard = UIStoryboard(name: "UserAccess", bundle: nil)
            return storyboard.instantiateViewController(identifier: "SignInNavigation")
        case .authorized:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(identifier: "MainTapBarController")
        }
    }
}
