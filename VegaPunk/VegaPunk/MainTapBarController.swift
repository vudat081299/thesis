//
//  MainTapBarController.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit

let imageUrl = "http://192.168.1.24:8080/api/files/63e28ee8c6b2f7c2a220cc04"

struct ViewControllerData {
    let title: String
    let iconNormal: String
    let selectedIcon: String
    let viewController: UINavigationController
    
    
    
    // MARK: - Data.
    static var viewControllerDatas: [ViewControllerData] = {
        let array = [
//            ViewControllerData(title: "Profile", iconNormal: "person", selectedIcon: "person.fill", viewController: UINavigationController(rootViewController: ViewController())),
            ViewControllerData(title: "Chat box", iconNormal: "message", selectedIcon: "message.fill", viewController: UINavigationController(rootViewController: ChatBoxViewController())),
        ]
        var dataList: [ViewControllerData] = []
        array.forEach {
            $0.viewController.topViewController?.title = $0.title
            $0.viewController.tabBarItem.image = UIImage(systemName: $0.iconNormal)
            $0.viewController.tabBarItem.selectedImage = UIImage(systemName: $0.selectedIcon)
//            $0.viewController.navigationBar.prefersLargeTitles = true
            $0.viewController.navigationBar.sizeToFit()
            $0.viewController.navigationItem.largeTitleDisplayMode = .always
            dataList.append($0)
        }
        return dataList
    }()
}

class MainTabBarController: UITabBarController {
    
    // MARK: - Life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ViewControllerData.viewControllerDatas.forEach {
            viewControllers?.append($0.viewController)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - App default configuration
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
}
