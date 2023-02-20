//
//  SceneDelegate.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit

extension UIWindow {
    func switchRootViewController(_ viewController: UIViewController? = nil,
                                  animated: Bool = true,
                                  duration: TimeInterval = 1,
                                  options: AnimationOptions = .curveEaseInOut,
                                  completion: (() -> Void)? = nil) {
        var destinationViewController: UIViewController!
        destinationViewController = viewController
        if destinationViewController == nil {
            destinationViewController = appState.handleHierarchyOnState()
        }
        guard animated else {
            rootViewController = destinationViewController
            return
        }
        UIView.transition(with: self, duration: duration, options: options, animations: {
//            let oldState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(animated)
            self.rootViewController = destinationViewController
//            UIView.setAnimationsEnabled(oldState)
            UIView.setAnimationsEnabled(animated)
        }, completion: { _ in
            completion?()
        })
    }
}

var appState: ApplicationState = .unauthorized
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        configureApplication()
        
        // MARK: - App become active
        if let user = AuthenticatedUser.retrieve(),
            let data = user.data, data.token != nil {
            appState = .authorized
        }
        
        configureWindow(on: appState)
//        if appState == .authorized {
//            DataInteraction.fetchData { [self] in
//                configureWindow(on: appState)
//            }
//        } else {
//            configureWindow(on: appState)
//        }
    }
    
    func configureWindow(on appState: ApplicationState) {
        self.window?.backgroundColor = .systemBackground
        self.window?.rootViewController = appState.handleHierarchyOnState()
        self.window?.makeKeyAndVisible()
    }
    
    /// Configure default specification for application.
    /// - ex: domain, ip, port,..
    func configureApplication() {
        AuthenticatedUser.store(networkConfig: NetworkConfig(domain: "http://\(configureIp):8080/", ip: configureIp, port: "8080"))
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

