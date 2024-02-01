//
//  SettingMainViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import FirebaseAuth
import UIKit


class SettingMainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경색을 흰색으로 설정합니다.
        view.backgroundColor = .white

        // 로그아웃 버튼을 생성합니다.
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        view.addSubview(logoutButton)

        // 계정 삭제 버튼을 생성합니다.
        let deleteAccountButton = UIButton(type: .system)
        deleteAccountButton.setTitle("계정 삭제", for: .normal)
        deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false
        deleteAccountButton.addTarget(self, action: #selector(didTapDeleteAccountButton), for: .touchUpInside)
        view.addSubview(deleteAccountButton)

        // AutoLayout을 이용하여 버튼을 화면 중앙에 위치하게 합니다.
        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),  // 로그아웃 버튼 위치를 조정합니다.

            deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteAccountButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30)  // 계정 삭제 버튼 위치를 조정합니다.
        ])
    }

    @objc func didTapLogoutButton() {
        // 로그아웃 버튼이 눌렸을 때 ViewController로 돌아갑니다.
        let viewController = ViewController()
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    @objc func didTapDeleteAccountButton() {
        // 계정 삭제 확인 알림을 띄웁니다.
        let alert = UIAlertController(title: "계정 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: .default) { _ in
            // '예'를 선택한 경우, 현재 사용자의 계정을 삭제합니다.
            Auth.auth().currentUser?.delete { error in
                if let error = error {
                    // 계정 삭제에 실패한 경우 에러 메시지를 출력합니다.
                    print("Failed to delete account: \(error)")
                } else {
                    // 계정 삭제에 성공한 경우 ViewController로 돌아갑니다.
                    print("Account deleted.")
                    
                    // 사용자 계정 정보를 UserDefault에서 제거합니다.
                    UserDefaults.standard.removeObject(forKey: "SavedId")
                    UserDefaults.standard.removeObject(forKey: "SavedPassword")
                    
                    // ViewController로 이동합니다.
                    let viewController = ViewController()
                    UIApplication.shared.windows.first?.rootViewController = viewController
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                }
            }
        })
        alert.addAction(UIAlertAction(title: "아니오", style: .cancel))
        present(alert, animated: true)
    }
}
