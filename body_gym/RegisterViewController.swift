//
//  RegisterViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
    class RegisterViewController: UIViewController {
        let titleLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "회원가입"
            label.textColor = .black
            label.font = UIFont.boldSystemFont(ofSize: 24)
            return label
        }()
        
        let idTextField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.placeholder = "이메일 형식으로 입력해주세요"
            return textField
        }()
        
        let passwordTextField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.placeholder = "6자리 이상 입력해주세요"
            textField.isSecureTextEntry = true
            return textField
        }()
        
        let passwordConfirmTextField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.placeholder = "비밀번호를 다시 입력해주세요"
            textField.isSecureTextEntry = true
            return textField
        }()
        
        let nicknameTextField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.placeholder = "입력 후 중복확인을 해주세요"
            return textField
        }()
        
        let checkButton: UIButton = {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("중복확인", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            return button
        }()
        
        let agreeCheckbox: UIButton = {
            let button = UIButton(type: .custom) // type을 .custom으로 변경
            button.translatesAutoresizingMaskIntoConstraints = false

            // 버튼의 타이틀을 설정합니다.
            button.setTitle("약관 및 개인정보보호 동의하기", for: .normal)
            button.setTitle("동의함", for: .selected)
            button.setTitleColor(.blue, for: .normal) // 텍스트 색상을 설정합니다.
            // 버튼 타이틀의 폰트를 설정할 수도 있습니다.
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            return button
        }()
        
        let confirmButton: UIButton = {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("확인", for: .normal)
            button.setTitleColor(.black, for: .normal)
            return button
        }()
        
        let cancelButton: UIButton = {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("취소", for: .normal)
            button.setTitleColor(.black, for: .normal)
            return button
        }()
        
        
        // 아이디 라벨을 생성합니다.
        let idLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "아이디"
            return label
        }()
        
        // 비밀번호 라벨을 생성합니다.
        let passwordLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "비밀번호"
            return label
        }()
        
        // 비밀번호 확인 라벨을 생성합니다.
        let passwordConfirmLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "비밀번호 확인"
            return label
        }()
        
        // 닉네임 라벨을 생성합니다.
        let nicknameLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "닉네임"
            return label
        }()
        
        var isNicknameVerified: Bool = false
        var isAgreeToTerms: Bool = false
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = .white // 배경색 설정
            
            // 뷰에 라벨과 텍스트 필드를 추가합니다.
            view.addSubview(titleLabel)
            view.addSubview(idLabel)
            view.addSubview(idTextField)
            view.addSubview(passwordLabel)
            view.addSubview(passwordTextField)
            view.addSubview(passwordConfirmLabel)
            view.addSubview(passwordConfirmTextField)
            view.addSubview(nicknameLabel)
            view.addSubview(nicknameTextField)
            view.addSubview(checkButton)
            view.addSubview(agreeCheckbox) // 누락된 부분 추가
            view.addSubview(confirmButton) // 누락된 부분 추가
            view.addSubview(cancelButton) // 누락된 부분 추가
            
            // 화면의 다른 곳을 탭하면 키보드를 숨깁니다.
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
            
            //nickname check
            checkButton.addTarget(self, action: #selector(checkNickname), for: .touchUpInside)
            
            // 확인 버튼 액션 추가
            confirmButton.addTarget(self,action:#selector(didTapConfirmButton), for: .touchUpInside)
            
            // 취소 버튼 액션 추가
            cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
            
            // 제약 조건 설정
            setupConstraints()
            
            //체크박스 액션 추가
            agreeCheckbox.addTarget(self, action: #selector(didTapAgreeCheckbox), for: .touchUpInside)
                
        }
        func setupConstraints() {
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
                titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                // 아이디 라벨 제약 조건 (각 라벨과 텍스트 필드 사이의 간격을 20으로 조정)
                idLabel.bottomAnchor.constraint(equalTo: idTextField.topAnchor, constant: -20),
                idLabel.leadingAnchor.constraint(equalTo: idTextField.leadingAnchor),
                idLabel.trailingAnchor.constraint(equalTo: idTextField.trailingAnchor),

                // 아이디 텍스트 필드 제약 조건 (titleLabel과의 간격을 60으로 유지)
                idTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
                idTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                idTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

                // 비밀번호 라벨 제약 조건 (라벨과 텍스트 필드 사이의 간격을 20으로 조정)
                passwordLabel.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -20),
                passwordLabel.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
                passwordLabel.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

                // 비밀번호 텍스트 필드 제약 조건 (idTextField와의 간격을 30으로 조정)
                passwordTextField.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 40),
                passwordTextField.leadingAnchor.constraint(equalTo: idTextField.leadingAnchor),
                passwordTextField.trailingAnchor.constraint(equalTo: idTextField.trailingAnchor),

                // 비밀번호 확인 라벨 제약 조건 (라벨과 텍스트 필드 사이의 간격을 20으로 조정)
                passwordConfirmLabel.bottomAnchor.constraint(equalTo: passwordConfirmTextField.topAnchor, constant: -20),
                passwordConfirmLabel.leadingAnchor.constraint(equalTo: passwordConfirmTextField.leadingAnchor),
                passwordConfirmLabel.trailingAnchor.constraint(equalTo: passwordConfirmTextField.trailingAnchor),

                // 비밀번호 확인 텍스트 필드 제약 조건 (passwordTextField와의 간격을 30으로 조정)
                passwordConfirmTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 40),
                passwordConfirmTextField.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
                passwordConfirmTextField.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

                // 닉네임 라벨 제약 조건 (라벨과 텍스트 필드 사이의 간격을 20으로 조정)
                nicknameLabel.bottomAnchor.constraint(equalTo: nicknameTextField.topAnchor, constant: -20),
                nicknameLabel.leadingAnchor.constraint(equalTo: nicknameTextField.leadingAnchor),
                nicknameLabel.trailingAnchor.constraint(equalTo: nicknameTextField.trailingAnchor),

                // 닉네임 텍스트 필드 제약 조건 (passwordConfirmTextField와의 간격을 30으로 조정)
                nicknameTextField.topAnchor.constraint(equalTo: passwordConfirmTextField.bottomAnchor, constant: 40),
                nicknameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),


                // 중복확인 버튼 제약 조건, 닉네임 라벨의 오른쪽에 위치하도록 설정
                checkButton.centerYAnchor.constraint(equalTo: nicknameLabel.centerYAnchor),
                checkButton.leadingAnchor.constraint(equalTo: nicknameLabel.trailingAnchor, constant: 8),
                checkButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

                // 약관 동의 체크박스 제약 조건
                agreeCheckbox.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 40),
                agreeCheckbox.centerXAnchor.constraint(equalTo: view.centerXAnchor),

                // '확인' 버튼 제약 조건, 두 버튼의 너비가 동일하다고 가정하고 중간 지점을 조정
                confirmButton.topAnchor.constraint(equalTo: agreeCheckbox.bottomAnchor, constant: 40),
                confirmButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10), // 화면 중앙에서 왼쪽으로 조금 이동

                // '취소' 버튼 제약 조건 수정, '확인' 버튼의 바로 오른쪽에 위치하도록 설정
                cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10), // 화면 중앙에서 오른쪽으로 조금 이동
                cancelButton.centerYAnchor.constraint(equalTo: confirmButton.centerYAnchor),
                cancelButton.topAnchor.constraint(equalTo: confirmButton.topAnchor) // '확인' 버튼과 상단을 맞춤
            ])
        }
        
        @objc func toggleAgreeCheckbox(_ sender: UIButton) {
            sender.isSelected.toggle() // 버튼의 선택 상태를 토글합니다.
            isAgreeToTerms = sender.isSelected // 동의 여부를 업데이트합니다.
        }
            
        
        @objc func didTapConfirmButton() {
            // 입력 값을 가져옵니다.
            guard let email = idTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty,
                  let nickname = nicknameTextField.text, !nickname.isEmpty else { // 닉네임 빈 값 체크 추가
                print("이메일, 비밀번호, 닉네임을 모두 입력해주세요.")
                return
            }

            // 이메일 형식이 맞는지 확인합니다.
            if !isValidEmail(email) {
                print("올바른 이메일 형식이 아닙니다.")
                return
            }

            // 비밀번호가 6자리 이상인지 확인합니다.
            if password.count < 6 {
                print("비밀번호는 6자리 이상이어야 합니다.")
                return
            }

            // 약관에 동의했는지 확인합니다.
            guard isAgreeToTerms else {
                print("약관 및 개인정보보호에 동의해주세요.")
                return
            }
            
            // 닉네임 중복확인을 했는지 확인합니다.
            guard isNicknameVerified else {
                print("닉네임 중복확인을 해주세요.")
                return
            }

            // 사용자가 입력한 비밀번호를 출력합니다.
            print("입력된 비밀번호: \(password)")

            // Firebase Authentication에 사용자를 등록합니다.
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                guard let user = authResult?.user, error == nil else {
                    print("사용자 등록에 실패했습니다: \(error!.localizedDescription)")
                    return
                }
                // 등록 성공 시 처리할 내용을 여기에 작성합니다.
                // 등록 성공 시 Firebase Realtime Database에 사용자 정보 저장
                let ref = Database.database().reference()
                ref.child("Users").child(user.uid).setValue(["nickname": nickname])
                print("사용자 등록에 성공했습니다: \(user.email ?? "")")
            }
            // ViewController를 닫습니다.
            self.dismiss(animated: true, completion: nil)
        }
        
        
        // 이메일 형식을 검증하는 함수입니다.
        func isValidEmail(_ email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: email)
        }
        
        @objc func didTapAgreeCheckbox(_ sender: UIButton) {
            // 약관 내용을 사용자에게 보여주는 로직
            let alertController = UIAlertController(title: "약관 및 개인정보 보호 동의", message: "바디와이짐은 이용자의 개인정보를 중요하게 생각하며, 이용자의 개인정보 보호를 위해 최선을 다하고 있습니다. 서비스 제공을 위해 필요한 최소한의 개인정보만을 수집하고 있습니다.\n" +
                "\n" +
                "수집하는 개인정보의 항목은 다음과 같습니다.\n" +
                "1. 이메일\n" +
                "2. 이름 또는 닉네임\n" +
                "\n" +
                "수집된 정보는 다음과 같은 목적으로만 사용됩니다.\n" +
                "1. 회원 관리\n" +
                "2. 기타 새로운 서비스 정보 제공\n" +
                "\n" +
                "개인 정보의 보유 기간은 서비스 이용 종료 시까지 입니다.\n" +
                "\n" +
                "바디와이짐은 이용자의 사전 동의 없이는 이용자의 개인 정보를 공개하지 않습니다. 이용자는 개인정보 수집 및 이용에 대한 동의를 거부할 권리가 있으며, 동의 거부 시 바디와이짐의 서비스 제공에 제한을 받을 수 있습니다.\n" +
                "\n" +
                "아래 '동의' 버튼을 누르시면 위와 같이 개인정보 수집 및 이용에 동의하는 것으로 간주됩니다.", preferredStyle: .alert)
            
            // 동의 액션
            let agreeAction = UIAlertAction(title: "동의", style: .default) { _ in
                // 사용자가 동의했을 때 체크박스 상태 변경
                sender.isSelected = true
                // 사용자가 동의했으므로 isAgreeToTerms를 true로 설정
                self.isAgreeToTerms = true
            }

            // 동의하지 않음 액션
            let disagreeAction = UIAlertAction(title: "동의하지 않음", style: .cancel) { _ in
                // 사용자가 동의하지 않았을 때 체크박스 상태 변경
                sender.isSelected = false
                // 사용자가 동의하지 않았으므로 isAgreeToTerms를 false로 설정
                self.isAgreeToTerms = false
            }
            
            // 알림창에 액션 추가
            alertController.addAction(agreeAction)
            alertController.addAction(disagreeAction)
            
            // 알림창 표시
            present(alertController, animated: true)
        }
  
        @objc func didTapCancelButton() {
            // '취소' 버튼을 눌렀을 때 현재 뷰 컨트롤러를 닫습니다.
            self.dismiss(animated: true, completion: nil)
        }

        @objc func didTapCheckbox(sender: UIButton) {
            sender.isSelected.toggle()
        }
        
        @objc func dismissKeyboard() {
            view.endEditing(true)
        }

        @objc func checkNickname() {
            // 닉네임 텍스트 필드로부터 값을 가져옵니다.
            guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
                print("닉네임을 입력해주세요.")
                return
            }
            
            // 사용자가 입력한 닉네임을 출력합니다.
            print("입력된 닉네임: \(nickname)")

            let dbRef = Database.database().reference()
            dbRef.child("Users").observeSingleEvent(of: .value) { (snapshot) in
                var isNicknameTaken = false
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String: Any]
                    let nickNameDB = dict["nickname"] as? String
                    if nickname == nickNameDB {
                        isNicknameTaken = true
                        break
                    }
                }
                if isNicknameTaken {
                    print("닉네임이 이미 사용 중입니다.")
                } else {
                    // 닉네임이 중복되지 않으므로 사용 가능함을 알립니다.
                    self.isNicknameVerified = true
                    self.nicknameTextField.isEnabled = false // 닉네임 텍스트 필드를 비활성화합니다.
                    print("사용 가능한 닉네임입니다.")
                }
            }
        }
    }

        
