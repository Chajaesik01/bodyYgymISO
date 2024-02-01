//
//  CreatPostViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import SDWebImage


class UITextViewWithPlaceholder: UITextView {

    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.isHidden = false // isHidden 속성을 false로 변경
        return label
    }()

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            placeholderLabel.sizeToFit()
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: UITextView.textDidChangeNotification, object: nil)

        placeholderLabel.font = self.font
        placeholderLabel.numberOfLines = 0
        self.addSubview(placeholderLabel)
        self.sendSubviewToBack(placeholderLabel)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([
            NSLayoutConstraint(item: placeholderLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 5),
            NSLayoutConstraint(item: placeholderLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -5),
            NSLayoutConstraint(item: placeholderLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 8),
        ])

        // 텍스트 컨테이너 인셋 설정
        textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
    }

    @objc func textChanged(notification: NSNotification) {
        placeholderLabel.isHidden = !self.text.isEmpty
    }
}



class CreatePostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 이미지 피커 컨트롤러
    let imagePickerController = UIImagePickerController()
    
    // 게시글 내용, 이미지 URL, 제목, 작성자를 입력받는 텍스트 필드
    //var contentTextField: UITextField!
    var imageUrlTextField: UITextField!
    var titleTextField: UITextField!
    var writerTextField: UITextField!
    
    
    // 게시 버튼 UI 요소
    let postButton = UIButton(type: .system)
    
    // 취소 버튼 UI 요소
    let cancelButton = UIButton(type: .system)
    // 이미지 추가 버튼 UI 요소
    let addImageButton = UIButton(type: .system)
    
    var contentTextField: UITextViewWithPlaceholder!
    
    var imageUrl = ""
    
    
    
    // 게시 버튼이 눌렸을 때 호출되는 메소드
    @objc func didTapPostButton() {
        // 텍스트 필드에서 입력받은 내용을 가져옵니다.
        guard let content = contentTextField.text, !content.isEmpty,
              let title = titleTextField.text, !title.isEmpty else {
            // 오류 처리: 필수 필드가 비어 있는 경우
            // 적절한 사용자 피드백을 제공해야 합니다.
            // imageUrl이 비어 있으면 공백 문자열을 사용합니다.
            imageUrl = imageUrlTextField.text ?? ""
            return
        }
        
        //let imageUrl = ""
        // 현재 로그인한 사용자의 UID를 가져옵니다.
        guard let currentUserUid = Auth.auth().currentUser?.uid else {
            // 오류 처리: 사용자가 로그인하지 않았을 경우
            return
        }
        
        // Users 노드에서 현재 사용자의 닉네임을 가져옵니다.
        let usersRef = Database.database().reference().child("Users").child(currentUserUid)
        usersRef.observeSingleEvent(of: .value, with: { snapshot in
            // 닉네임을 가져오거나 기본값을 사용합니다.
            let nickname = (snapshot.value as? [String: Any])?["nickname"] as? String ?? "익명"
            
            // 파이어베이스에 저장하기 위한 참조와 타임스탬프를 생성합니다.
            let postRef = Database.database().reference().child("posts").childByAutoId()
            let timestamp = Int(Date().timeIntervalSince1970 * 1000) // 밀리세컨드 단위로 변환
            let postObject = [
                "content": content,
                "imageUrl": self.imageUrl,
                "postId": postRef.key, // childByAutoId()에서 생성된 고유 ID를 사용
                "title": title,
                "writer": nickname, // 닉네임을 작성자로 설정합니다.
                "timestamp": timestamp
            ] as [String: Any]
            
            // 게시글 객체를 파이어베이스 데이터베이스에 저장합니다.
            postRef.setValue(postObject) { [weak self] error, ref in
                if let error = error {
                    // 오류 처리: 게시글 저장 실패
                    print("Error posting: \(error.localizedDescription)")
                    // 사용자에게 오류 메시지를 표시합니다.
                } else {
                    // 성공 처리: 게시글 저장 성공
                    self?.dismiss(animated: true, completion: nil)  // 이 부분을 이동하였습니다.
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }) { error in
            // 오류 처리: 사용자 정보 가져오기 실패
        }
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    // 이미지 추가 버튼이 눌렸을 때 호출되는 메소드
    @objc func didTapAddImageButton() {
        // 이미지 피커 표시
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true)
    }
    
    // 취소 버튼이 눌렸을 때 호출되는 메소드
    @objc func didTapCancelButton() {
        // 현재 뷰 컨트롤러를 닫고 이전 화면으로 돌아갑니다.
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 이미지 피커 델리게이트 설정
        imagePickerController.delegate = self
        
        // 레이아웃 설정을 위한 UI 설정 메소드 호출
        setupUI()
        
        // '게시' 버튼 액션 설정
        postButton.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
        
        // '취소' 버튼 액션 설정
        cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        
        // '이미지 추가' 버튼 액션 설정
        addImageButton.addTarget(self, action: #selector(didTapAddImageButton), for: .touchUpInside)
        
        
        imagePickerController.delegate = self
        self.view.addSubview(imageUrlTextField)
    }
    
    func setupUI() {
        // UI 요소들의 배경색을 흰색으로 설정합니다.
        view.backgroundColor = .white
        
        imageUrlTextField = UITextField()
        
        
        // '글 작성하기' 라벨 설정
        let titleLabel = UILabel()
        titleLabel.text = "글 작성하기"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        view.addSubview(titleLabel)
        
        // 구분선 설정
        let separatorView = UIView()
        separatorView.backgroundColor = .black
        view.addSubview(separatorView)
        
        
        
        // 텍스트 필드 초기화 및 설정
        titleTextField = UITextField()
        titleTextField.placeholder = "제목"
        titleTextField.borderStyle = .roundedRect
        view.addSubview(titleTextField)
        
        // 본문 텍스트 필드 초기화
        contentTextField = UITextViewWithPlaceholder()
        
        // 본문 텍스트 필드 설정
        contentTextField.placeholder = "게시글 작성 시 다음 사항을 준수해주세요:\n1. 욕설 및 비방글은 금지입니다.\n2. 타인의 사생활을 존중해주세요.\n3. 부적절한 내용의 게시글은 삭제됩니다."
        contentTextField.textColor = .black // 텍스트 색상을 검은색으로 설정
        contentTextField.isEditable = true // 텍스트 뷰를 편집 가능하게 설정
        
        // 테두리 스타일 설정
        contentTextField.layer.cornerRadius = 5
        contentTextField.layer.borderColor = UIColor.gray.cgColor
        contentTextField.layer.borderWidth = 1
        
        // 뷰에 추가
        view.addSubview(contentTextField)
        
        // 버튼들을 뷰에 추가합니다.
        view.addSubview(addImageButton)
        view.addSubview(postButton)
        view.addSubview(cancelButton)
        
        // 버튼들의 오토레이아웃 설정
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        contentTextField.translatesAutoresizingMaskIntoConstraints = false
        postButton.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            // '글 작성하기' 라벨 레이아웃
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 구분선 레이아웃
            separatorView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // 제목 텍스트필드 레이아웃
            titleTextField.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 본문 텍스트필드 레이아웃
            contentTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            contentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentTextField.heightAnchor.constraint(equalToConstant: 120), // 본문 필드의 높이를 지정합니다.
            
            // '이미지 추가' 버튼 레이아웃
            addImageButton.topAnchor.constraint(equalTo: contentTextField.bottomAnchor, constant: 20),
            addImageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addImageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addImageButton.heightAnchor.constraint(equalToConstant: 50), // 버튼의 높이를 지정합니다.
            
            // '게시' 버튼 레이아웃
            postButton.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 20),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            postButton.heightAnchor.constraint(equalToConstant: 50), // 버튼의 높이를 지정합니다.
            
            // '취소' 버튼 레이아웃
            cancelButton.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50), // 버튼의 높이를 지정합니다.
        ])
        
        // 버튼 타이틀 설정
        postButton.setTitle("게시", for: .normal)
        addImageButton.setTitle("이미지 추가", for: .normal)
        cancelButton.setTitle("취소", for: .normal)
        
        // 버튼 기본 색상 설정
        postButton.setTitleColor(.blue, for: .normal)
        addImageButton.setTitleColor(.blue, for: .normal)
        cancelButton.setTitleColor(.blue, for: .normal)
    }
    
    // 이미지 피커 컨트롤러에서 이미지를 선택했을 때 호출되는 메소드
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        print("imagePickerCOntroller function has been called")
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // 이미지 데이터를 JPEG 형식으로 변환 (압축률 0.8)
            
            if let imageData = pickedImage.jpegData(compressionQuality: 0.8) {
                print("Image data has been created successfully. : \(imageData)")
                
                // Firebase Storage에 업로드할 경로 설정
                let storagePath = "image/\(UUID().uuidString)"
                let storageRef = Storage.storage().reference().child("image/\(UUID().uuidString)")
                print("Storage Path: \(storagePath)")
                print("Storage Ref: \(storageRef)")
                
                // 이미지 데이터 업로드
                storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    if let error = error{
                        print("Failed to upload image : \(error.localizedDescription)")
                    }
                    else if let metadata = metadata{
                        print("image upload Successfully : \(metadata.path ?? "")")
                    }
                    
                    // 이미지 URL 가져오기
                    storageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            // URL 가져오기 실패 처리
                            print("Failed to get download URL")
                            return
                        }

                        // 이미지 URL을 textField에 설정
                        if let imageUrlTextField = self.imageUrlTextField {
                            imageUrlTextField.text = downloadURL.absoluteString
                            self.imageUrl = downloadURL.absoluteString // imageUrl 업데이트
                        } else {
                            print("imageUrlTextField이 nil입니다.")
                        }
                    }
                }
                dismiss(animated: true, completion: nil)
            }
            
            // 이미지 피커 컨트롤러에서 취소했을 때 호출되는 메소드
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                dismiss(animated: true, completion: nil)
            }
            
            func setupButtons() {
                // 버튼들을 뷰에 추가합니다.
                view.addSubview(postButton)
                view.addSubview(addImageButton)
                view.addSubview(cancelButton)
                
                postButton.setTitle("게시", for: .normal)
                addImageButton.setTitle("이미지 추가", for: .normal)
                cancelButton.setTitle("취소", for: .normal)
                
                // 버튼 기본 색상 설정
                postButton.setTitleColor(.blue, for: .normal)
                addImageButton.setTitleColor(.blue, for: .normal)
                cancelButton.setTitleColor(.blue, for: .normal)
                
                // postButton 오토레이아웃 설정
                NSLayoutConstraint.activate([
                    postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    postButton.topAnchor.constraint(equalTo: contentTextField.bottomAnchor, constant: 20),
                    postButton.widthAnchor.constraint(equalToConstant: 100),
                    postButton.heightAnchor.constraint(equalToConstant: 50)
                ])
            }
        }
    }
}
