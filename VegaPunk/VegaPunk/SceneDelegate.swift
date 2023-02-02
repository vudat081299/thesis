//
//  SceneDelegate.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        
        // MARK: - App become active
        var appState: ApplicationState
        appState = .unauthorized
        if let authUser = AuthenticatedUser.retrieve(), authUser.token != nil {
            appState = .authorized
        } else {
            appState = .unauthorized
        }
        fetchData {
            self.window?.rootViewController = appState.handleHierarchyOnState()
            self.window?.makeKeyAndVisible()
        } onFailure: {
            appState = .unauthorized
            self.window?.rootViewController = appState.handleHierarchyOnState()
            self.window?.makeKeyAndVisible()
        }
        
    }
    
    /// Leave dispatchGroup.
    func leave(_ dispatchGroup: DispatchGroup) {
        DispatchQueue.main.async {
            dispatchGroup.leave()
        }
    }
    /// Fetch data and perform task after all fetching tasks is finished executing.
    func fetchData(_ onSuccess: @escaping () -> (), onFailure: @escaping () -> ()) {
        var countSuccessTask = 0
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        RequestEngine.getAllUsers {
            self.leave(dispatchGroup)
        } onSuccess: {
            countSuccessTask += 1
        }
        dispatchGroup.enter()
        RequestEngine.getAllMappings {
            self.leave(dispatchGroup)
        } onSuccess: {
            countSuccessTask += 1
        }
        dispatchGroup.enter()
        RequestEngine.getAllMappingPivots {
            self.leave(dispatchGroup)
        } onSuccess: {
            countSuccessTask += 1
        }
        dispatchGroup.enter()
        RequestEngine.getMyChatBoxes {
            self.leave(dispatchGroup)
        } onSuccess: {
//            countSuccessTask += 1
        }
        
        dispatchGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                if (countSuccessTask == 3) {
                    onSuccess()
                } else {
                    onFailure()
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

