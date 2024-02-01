//
//  MainTabBarController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let vc1 = HomeMainViewController()
        let vc2 = BoardMainViewController()
        let vc3 = ChatMainViewController()
        let vc4 = CalendarMainViewController()
        let vc5 = SettingMainViewController()

        let nav1 = UINavigationController(rootViewController: vc1)
        let nav2 = UINavigationController(rootViewController: vc2)
        let nav3 = UINavigationController(rootViewController: vc3)
        let nav4 = UINavigationController(rootViewController: vc4)
        let nav5 = UINavigationController(rootViewController: vc5)

        let imageSize: CGFloat = 20
        
        nav1.tabBarItem = UITabBarItem(title: "홈", image: UIImage(named: "home.png")?.resizeImage(size: CGSize(width: imageSize, height: imageSize)), tag: 0)
        nav2.tabBarItem = UITabBarItem(title: "게시판", image: UIImage(named: "board.png")?.resizeImage(size: CGSize(width: imageSize, height: imageSize)), tag: 1)
        nav3.tabBarItem = UITabBarItem(title: "채팅방", image: UIImage(named: "chat.png")?.resizeImage(size: CGSize(width: imageSize, height: imageSize)), tag: 2)
        nav4.tabBarItem = UITabBarItem(title: "식단일지", image: UIImage(named: "calendar.png")?.resizeImage(size: CGSize(width: imageSize, height: imageSize)), tag: 3)
        nav5.tabBarItem = UITabBarItem(title: "설정", image: UIImage(named: "setting.png")?.resizeImage(size: CGSize(width: imageSize, height: imageSize)), tag: 4)


        self.viewControllers = [nav1, nav2, nav3, nav4, nav5]

        self.delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let navController = viewController as? UINavigationController {
            if let boardViewController = navController.viewControllers.first as? BoardMainViewController {
                boardViewController.isCustomSearchActive = false
                boardViewController.filteredPosts = boardViewController.posts
                boardViewController.tableView.reloadData()
            } else if let chatViewController = navController.viewControllers.first as? ChatMainViewController {
                print("resetFilter() will be called")
                chatViewController.resetFilter()
            }
        }
    }
}

extension UIImage {
    func resizeImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
