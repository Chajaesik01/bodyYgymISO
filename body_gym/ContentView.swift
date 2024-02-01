//
//  ContentView.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import SwiftUI
import UIKit
import FirebaseAuth

        class ViewController: UIViewController {
            let idTextField = UITextField()
            let passwordTextField = UITextField()
            override func viewDidLoad() {
                super.viewDidLoad()
                
                // 배경색을 흰색으로 설정합니다.
                view.backgroundColor = .white
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

                view.addGestureRecognizer(tap)

                // UserDefault에서 저장된 아이디와 비밀번호 불러오기
                if let savedId = UserDefaults.standard.string(forKey: "SavedId"),
                   let savedPassword = UserDefaults.standard.string(forKey: "SavedPassword") {
                    idTextField.text = savedId
                    passwordTextField.text = savedPassword
                }

                // 이미지뷰 설정
                let imageView = UIImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.image = UIImage(named: "bodygym")
                view.addSubview(imageView)

                // 아이디 입력 필드 설정
                idTextField.translatesAutoresizingMaskIntoConstraints = false
                idTextField.placeholder = "아이디"
                idTextField.textColor = .black  // 글씨 색상을 검은색으로 설정
                view.addSubview(idTextField)

                // 비밀번호 입력 필드 설정
                passwordTextField.translatesAutoresizingMaskIntoConstraints = false
                passwordTextField.placeholder = "비밀번호"
                passwordTextField.isSecureTextEntry = true
                passwordTextField.textColor = .black  // 글씨 색상을 검은색으로 설정
                view.addSubview(passwordTextField)

                // 로그인 버튼 설정
                let loginButton = UIButton()
                loginButton.translatesAutoresizingMaskIntoConstraints = false
                loginButton.setTitle("로그인", for: .normal)
                loginButton.setTitleColor(.black, for: .normal)
                loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
                view.addSubview(loginButton)

                // 회원가입 버튼 설정
                let registerButton = UIButton()
                registerButton.translatesAutoresizingMaskIntoConstraints = false
                registerButton.setTitle("회원가입", for: .normal)
                registerButton.setTitleColor(.black, for: .normal)
                registerButton.addTarget(self, action: #selector(didTapRegisterButton), for: .touchUpInside)
                view.addSubview(registerButton)
                    
                // AutoLayout 설정
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
                    imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

                    idTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50),
                    idTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
                    idTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),

                    passwordTextField.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 11),
                    passwordTextField.leadingAnchor.constraint(equalTo: idTextField.leadingAnchor),
                    passwordTextField.trailingAnchor.constraint(equalTo: idTextField.trailingAnchor),

                    loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 70),
                    loginButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),  // 뷰 가운데를 기준으로 왼쪽에 위치
                    loginButton.widthAnchor.constraint(equalToConstant: 100),  // 버튼 너비 설정

                    registerButton.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),  // 로그인 버튼과 동일한 수준에 위치
                    registerButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),  // 뷰 가운데를 기준으로 오른쪽에 위치
                    registerButton.widthAnchor.constraint(equalToConstant: 100),  // 버튼 너비 설정
                ])
            }
                @objc func didTapRegisterButton() {
                let registerViewController = RegisterViewController()
                self.present(registerViewController, animated: true, completion: nil)
            }
            
            @objc func dismissKeyboard() {
                view.endEditing(true)
            }
            
            @objc func didTapLoginButton() {
                   guard let id = idTextField.text, !id.isEmpty,
                         let password = passwordTextField.text, !password.isEmpty else {
                       print("아이디와 비밀번호를 입력해주세요.")
                       return
                   }

                   Auth.auth().signIn(withEmail: id, password: password) { (authResult, error) in
                       guard authResult != nil, error == nil else {
                           print("로그인에 실패했습니다: \(error!.localizedDescription)")
                           return
                       }

                       // 로그인 성공하면 아이디와 비밀번호를 UserDefault에 저장
                       UserDefaults.standard.set(id, forKey: "SavedId")
                       UserDefaults.standard.set(password, forKey: "SavedPassword")

                       // 로그인 성공, home_mainViewController로 이동
                    let mainTabBarController = MainTabBarController()
                    UIApplication.shared.windows.first?.rootViewController = mainTabBarController
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                       let homeMainViewController = HomeMainViewController()
                       self.present(homeMainViewController, animated: true, completion: nil)
                   }
               }
            
}

