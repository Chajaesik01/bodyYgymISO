//
//  ChatRoomViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit
import FirebaseDatabase
import Kingfisher
import FirebaseAuth
import FirebaseStorage



struct Message {
    let sender: String
    let content: String
    let timestamp: Int64
    let type: String
    let isCurrentUser: Bool
}

struct Report {
    let reportId: String
    let author: String
    let postTitle: String
    let reportReason: String
}

class ImageViewController: UIViewController {
    let imageView = UIImageView()

    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChatRoomViewController: UIViewController {
    var chatRoom: ChatRoom!
    var ref: DatabaseReference!
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    var chatViewController: ChatViewController!
    //var messageId: String? // 메시지 ID를 저장하는 프로퍼티를 추가합니다.
    var currentUserNickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경색을 설정합니다.
        self.view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        //댓글 입력창 키도브 문제와 탭 관련 코드
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        view.addGestureRecognizer(tapGesture)
        
        // 키보드가 나타날 때
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        // 키보드가 사라질 때
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // 삭제 버튼 생성
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteButtonTapped))

        // 신고 버튼 생성
        let reportButton = UIBarButtonItem(title: "Report", style: .plain, target: self, action: #selector(reportButtonTapped))

        navigationItem.rightBarButtonItems = [deleteButton, reportButton] // 두 개 이상의 버튼을 추가할 때

        let inputFieldHeight: CGFloat = 50

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Firebase 데이터베이스 참조를 가져옵니다.
        let db = Database.database().reference()

        // 특정 ChatRoom을 가져옵니다.
        db.child("Chats").child(chatRoom.id).observeSingleEvent(of: .value) { (snapshot) in
            // Snapshot의 value를 딕셔너리로 변환합니다.
            guard let value = snapshot.value as? [String: Any] else {
                print("ChatRoom 데이터를 가져오는 데 실패했습니다.")
                return
            }

            // 딕셔너리에서 필요한 정보를 추출하여 ChatRoom 인스턴스를 생성합니다.
            self.chatRoom = ChatRoom(
                id: self.chatRoom.id,
                author: value["author"] as? String ?? "",
                name: value["name"] as? String ?? "",
                password: value["password"] as? String ?? "",
                timestamp: value["timestamp"] as? Double ?? 0.0
            )

            // navigationItem.title 설정
            if let chatRoomName = self.chatRoom?.name {
                self.navigationItem.title = chatRoomName
            }

            // 이제 ChatRoom 인스턴스를 가지고 있으므로, ChatViewController를 생성할 수 있습니다.
            self.chatViewController = ChatViewController(chatRoom: self.chatRoom, nibName: nil, bundle: nil)

            // ChatViewController를 생성하고, ChatRoomViewController에 추가합니다.
            self.addChild(self.chatViewController)
            self.view.addSubview(self.chatViewController.view)
            self.chatViewController.didMove(toParent: self)
                
            // ChatViewController의 뷰의 제약 조건을 설정합니다.
            self.chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.chatViewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                self.chatViewController.view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                self.chatViewController.view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                self.chatViewController.view.heightAnchor.constraint(equalToConstant: 50),

                // scrollView의 바닥 제약 조건을 chatViewController.view의 상단으로 설정합니다.
                self.scrollView.bottomAnchor.constraint(equalTo: self.chatViewController.view.topAnchor)
            ])

            // 이제 ChatViewController가 준비되었으므로, 메시지를 불러옵니다.
            self.loadMessages()
        }
    }
    
    
    @objc func tapOutside() {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let messageView = gesture.view as? ChatMessageView else { return }
            // 채팅을 보낸 사용자인지 확인
            if messageView.senderLabel.text == self.currentUserNickname {
                let alert = UIAlertController(title: nil, message: "메시지를 삭제하시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "예", style: .default, handler: { _ in
                    // 메시지 삭제 코드
                    let ref = Database.database().reference().child("Chats").child(self.chatRoom.id).child(messageView.messageId ?? "")
                    ref.removeValue()
                }))
                alert.addAction(UIAlertAction(title: "아니오", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func loadMessages() {
            ref = Database.database().reference()

            ref.child("Chats").child(chatRoom.id).observe(.childAdded, with: { [weak self] (snapshot) in
                if let chatData = snapshot.value as? [String: Any] {
                    let id = snapshot.key // 메시지 ID를 가져옵니다.
                    let sender = chatData["sender"] as? String ?? ""
                    let content = chatData["content"] as? String ?? ""
                    let timestamp = chatData["timestamp"] as? Int64 ?? 0
                    let type = chatData["type"] as? String ?? ""

                    // ChatMessageView 인스턴스 생성 및 설정
                    let messageView = ChatMessageView()
                    messageView.messageId = id // 메시지 ID를 저장합니다.
                    // '길게 누르기' 제스처를 추가합니다.
                    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self!.handleLongPress(_:)))
                    messageView.addGestureRecognizer(longPress)
                    // ...

                    self?.addChatMessageView(sender: sender, content: content, timestamp: timestamp, type: type)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }



    func getCurrentUserNickname(completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        let db = Database.database().reference()
        db.child("Users").child(uid).child("nickname").observeSingleEvent(of: .value) { (snapshot) in
            guard let nickname = snapshot.value as? String else {
                print("Error: Could not retrieve nickname.")
                completion(nil)
                return
            }
            completion(nickname)
        }
    }
    
    func addChatMessageView(sender: String, content: String, timestamp: Int64, type: String) {
        getCurrentUserNickname { [weak self] (currentUserNickname) in
            guard let self = self, let currentUserNickname = currentUserNickname else { return }
            let isCurrentUser = (sender == currentUserNickname)

            // Message 모델을 만듭니다.
            let message = Message(sender: sender, content: content, timestamp: timestamp, type: type, isCurrentUser: isCurrentUser)

            // 새로운 ChatMessageView를 생성하고 설정합니다.
            let chatMessageView = ChatMessageView()
            chatMessageView.updateWithChatData(message: message)

            // UIStackView에 ChatMessageView를 추가합니다.
            self.stackView.addArrangedSubview(chatMessageView)
        }
    }
    // 스크롤뷰를 맨 아래로 이동시키는 메소드입니다.
    func scrollToBottom(animated: Bool = true) {
        if scrollView.contentSize.height > scrollView.frame.height {
            let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.frame.height)
            scrollView.setContentOffset(bottomOffset, animated: animated)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToBottom(animated: false)
    }
    
    // 삭제 버튼이 눌렸을 때 호출될 메소드
    @objc func deleteButtonTapped() {
        print("Delete button tapped.")
        
        // 현재 사용자의 닉네임을 가져옵니다.
        getCurrentUserNickname { [weak self] currentNickname in
            guard let currentNickname = currentNickname else {
                print("Could not retrieve current user nickname.")
                return
            }
            
            // 현재 채팅방의 개설자 닉네임과 현재 사용자의 닉네임을 비교합니다.
            if self?.chatRoom.author == currentNickname || self?.chatRoom.author == "관장님" || self?.chatRoom.author == "관리자" {
                // 닉네임이 같다면 알림창을 띄웁니다.
                let alertController = UIAlertController(title: "채팅방 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)
                
                // '예' 버튼을 추가합니다.
                let yesAction = UIAlertAction(title: "예", style: .default) { _ in
                    // '예' 버튼을 누르면 채팅방을 삭제합니다.
                    if let chatRoom = self?.chatRoom {
                        self?.deleteChatRoom(chatRoom: chatRoom)
                    }
                    // 채팅방 목록 화면으로 돌아갑니다.
                    self?.navigationController?.popViewController(animated: true)
                }
                alertController.addAction(yesAction)
                
                // '아니오' 버튼을 추가합니다.
                let noAction = UIAlertAction(title: "아니오", style: .cancel, handler: nil)
                alertController.addAction(noAction)
                
                // 알림창을 띄웁니다.
                self?.present(alertController, animated: true, completion: nil)
            } else {
                // 닉네임이 다르다면 아무런 동작을 수행하지 않습니다.
                print("You are not the author of this chat room.")
            }
        }
    }

    func deleteChatRoom(chatRoom: ChatRoom) {
        print("Deleting chat room...")
        
        // 현재 채팅방의 ID를 가진 레퍼런스를 가져옵니다.
        let db = Database.database().reference()
        let chatRoomRef = db.child("Chats").child(chatRoom.id)
        
        // 해당 레퍼런스를 삭제합니다.
        chatRoomRef.removeValue { (error, _) in
            if let error = error {
                // 에러가 발생한 경우 에러 메시지를 출력합니다.
                print("Failed to delete chat room: \(error.localizedDescription)")
            } else {
                // 성공적으로 삭제한 경우 메시지를 출력합니다.
                print("Chat room successfully deleted.")
            }
        }
    }
    
    @objc func reportButtonTapped() {
        // 신고 버튼이 눌렸을 때의 동작을 작성합니다.
        let alertController = UIAlertController(title: "신고", message: "이 채팅방을 신고하시겠습니까?", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "신고 사유를 입력해주세요..."
        }
        
        let reportAction = UIAlertAction(title: "신고", style: .destructive) { _ in
            // 신고 로직을 작성합니다.
            if let reportReason = alertController.textFields?.first?.text {
                // Firebase에 신고 정보를 저장합니다.
                let reportRef = Database.database().reference().child("report")
                let reportId = reportRef.childByAutoId().key ?? ""
                
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd/HH:mm"
                let reportTime = dateFormatter.string(from: date) // 현재 시간을 'yyyy-MM-dd/HH:mm' 형식의 문자열로 변환합니다.
                
                let reportData = ["reportId": reportId,
                                  "reportReason": reportReason,
                                  "author": self.chatRoom?.author ?? "",
                                  "postTitle": self.chatRoom?.name ?? "",
                                  "reportTime": reportTime] // 신고 시간을 추가합니다.
                reportRef.child(reportId).setValue(reportData)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
}


class ChatMessageView: UIView {
    let senderLabel: UILabel
    let contentLabel: UILabel
    let timestampLabel: UILabel
    let chatImageView: UIImageView
    var chatImageViewLeadingConstraint: NSLayoutConstraint?
    var chatImageViewTrailingConstraint: NSLayoutConstraint?
    var chatImageViewHeightConstraint: NSLayoutConstraint?
    var messageId: String?


    override init(frame: CGRect) {
        senderLabel = UILabel()
        contentLabel = UILabel()
        timestampLabel = UILabel()
        chatImageView = UIImageView()
        chatImageView.contentMode = .scaleAspectFit // 이미지의 원본 비율을 유지

        super.init(frame: frame)

        addSubview(senderLabel)
        addSubview(contentLabel)
        addSubview(timestampLabel)
        addSubview(chatImageView)

        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        chatImageView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false

        contentLabel.numberOfLines = 0
        
        
        chatImageViewLeadingConstraint = chatImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        chatImageViewTrailingConstraint = chatImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        chatImageViewLeadingConstraint?.isActive = false
        chatImageViewTrailingConstraint?.isActive = false
        
        chatImageViewHeightConstraint = chatImageView.heightAnchor.constraint(equalToConstant: 100)
        chatImageViewHeightConstraint?.isActive = false
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        chatImageView.addGestureRecognizer(tapGestureRecognizer)
        chatImageView.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            senderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            senderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            contentLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 5),
            contentLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            timestampLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 5),
            timestampLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            timestampLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            
            // 이미지 뷰의 너비를 100으로 설정
            chatImageView.widthAnchor.constraint(equalToConstant: 100),

            // 이미지 뷰의 위치를 조정
            chatImageView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 5),
            timestampLabel.topAnchor.constraint(equalTo: chatImageView.bottomAnchor, constant: 5),
            
            // 이미지 뷰의 좌우 위치를 조정하는 제약 조건
            chatImageViewLeadingConstraint!,
            chatImageViewTrailingConstraint!
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func imageTapped() {
        guard let image = chatImageView.image else { return }
        let imageVC = ImageViewController(image: image)
        // 현재 뷰 컨트롤러를 가져오는 코드는 앱의 구조에 따라 다를 수 있습니다.
        if let viewController = self.findViewController() {
            viewController.present(imageVC, animated: true, completion: nil)
        }
    }

    override var intrinsicContentSize: CGSize {
        let contentSize = contentLabel.sizeThatFits(CGSize(width: contentLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let senderSize = senderLabel.sizeThatFits(CGSize(width: senderLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let timestampSize = timestampLabel.sizeThatFits(CGSize(width: timestampLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let chatImageSize = chatImageView.image != nil ? CGSize(width: 100, height: 100) : CGSize.zero // 크기를 고정한 값으로 변경

        let height = contentSize.height + senderSize.height + timestampSize.height + chatImageSize.height + 20 // 패딩과 간격의 합계
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    func updateWithChatData(message: Message) {
        senderLabel.text = message.sender
        senderLabel.textColor = .black

        if message.type == "text" {
            contentLabel.text = message.content
            chatImageView.isHidden = true
            chatImageViewHeightConstraint?.constant = 0
        } else if message.type == "image", let url = URL(string: message.content) {
            contentLabel.text = ""
            chatImageView.isHidden = false
            chatImageViewHeightConstraint?.constant = 100
            chatImageViewHeightConstraint?.isActive = true
                chatImageView.kf.setImage(with: url) {
                    result in
                    switch result {
                    case .success(_):
                        self.invalidateIntrinsicContentSize() // 이미지 로드 후 intrinsic content size 업데이트
                    case .failure(let error):
                        print("Error: \(error)") // 이미지 로드 실패 시 에러 출력
                    }
                }
        } else {
            chatImageView.isHidden = true
            chatImageViewHeightConstraint?.constant = 0
        }

            if chatImageView.isHidden {
                self.invalidateIntrinsicContentSize() // 이미지 숨김 후 intrinsic content size 업데이트
            }

        let date = Date(timeIntervalSince1970: TimeInterval(message.timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd/HH:mm"
        let dateString = dateFormatter.string(from: date)
        timestampLabel.text = dateString
        timestampLabel.textColor = .black

        if message.isCurrentUser {
            senderLabel.textAlignment = .right
            contentLabel.textAlignment = .right
            timestampLabel.textAlignment = .right
            chatImageViewLeadingConstraint?.isActive = false
            chatImageViewTrailingConstraint?.isActive = true
        } else {
            senderLabel.textAlignment = .left
            contentLabel.textAlignment = .left
            timestampLabel.textAlignment = .left
            chatImageViewLeadingConstraint?.isActive = true
            chatImageViewTrailingConstraint?.isActive = false
        }

        self.invalidateIntrinsicContentSize()
    }
}

class ChatViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let messageInputField: UITextField
    let sendButton: UIButton
    let attachImageButton: UIButton
    let imagePicker: UIImagePickerController
    var chatRoom: ChatRoom! // 이 부분은 수정하지 않습니다.

    // chatRoom을 매개변수로 받는 생성자를 추가합니다.
    init(chatRoom: ChatRoom, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.chatRoom = chatRoom // 여기에서 chatRoom을 설정합니다.
        

        messageInputField = UITextField()
        sendButton = UIButton()
        attachImageButton = UIButton()
        imagePicker = UIImagePickerController()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        //self.chatRoom = chatRoom

        messageInputField.placeholder = "메시지를 입력하세요"
        sendButton.setTitle("전송", for: .normal)
        attachImageButton.setTitle("이미지 첨부", for: .normal)
        
        messageInputField.backgroundColor = .white // 배경색을 흰색으로 설정
        messageInputField.textColor = .black // 텍스트 색상을 검정색으로 설정

        sendButton.backgroundColor = .white // 배경색을 파란색으로 설정
        sendButton.setTitleColor(.black, for: .normal) // 텍스트 색상을 흰색으로 설정

        attachImageButton.backgroundColor = .white // 배경색을 파란색으로 설정
        attachImageButton.setTitleColor(.black, for: .normal) // 텍스트 색상을 흰색으로 설정


        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        attachImageButton.addTarget(self, action: #selector(attachImage), for: .touchUpInside)

        imagePicker.delegate = self

        // 뷰에 추가
        view.addSubview(messageInputField)
        view.addSubview(sendButton)
        view.addSubview(attachImageButton)

        // AutoLayout 설정
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        attachImageButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageInputField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            messageInputField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),

            sendButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            sendButton.trailingAnchor.constraint(equalTo: attachImageButton.leadingAnchor, constant: -10),
            sendButton.widthAnchor.constraint(equalToConstant: 60),

            attachImageButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            attachImageButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            attachImageButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ChatViewController viewDidLoad")

        // 뷰의 배경색을 흰색으로 설정
        view.backgroundColor = .white

        // chatRoom의 값 확인 및 navigationItem.title 설정
        if let chatRoomName = self.chatRoom?.name {
            navigationItem.title = chatRoomName
            print("ChatViewController chatRoom.name: \(chatRoomName)")

            // chatRoomName을 화면 상단, Back 버튼의 오른쪽에 출력
            let rightBarButtonItem = UIBarButtonItem(title: chatRoomName, style: .plain, target: self, action: nil)
            navigationItem.rightBarButtonItem = rightBarButtonItem
        } else {
            print("ChatViewController chatRoom이 설정되지 않았습니다.")
        }

        // chatRoom의 값 확인
        if let chatRoomId = self.chatRoom?.id {
            print("ChatViewController chatRoom.id: \(chatRoomId)")
        } else {
            print("ChatViewController chatRoom이 설정되지 않았습니다.")
        }
        
    }
    @objc func sendMessage() {
        guard let messageContent = messageInputField.text, !messageContent.isEmpty else {
            print("메시지가 비어있습니다.")
            return
        }

        // chatRoom과 chatRoom.id의 값 확인
        if let chatRoomId = self.chatRoom?.id {
            print("chatRoom.id: \(chatRoomId)")
        } else {
            print("chatRoom이 설정되지 않았습니다.")
            return
        }

        // 현재 로그인한 사용자의 닉네임을 가져옵니다.
        getCurrentUserNickname { (nickname) in
            guard let senderNickname = nickname else {
                print("사용자 닉네임을 가져오는 데 실패했습니다.")
                return
            }
            print("senderNickname: \(senderNickname)") // 이 위치로 print 문을 이동

            // 메시지 데이터를 만듭니다.
            let messageData = [
                "sender": senderNickname,
                "content": messageContent,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000), // 현재 시간을 밀리초로 변환
                "type": "text"
            ] as [String : Any]

            // 메시지를 Firebase 데이터베이스에 저장합니다.
            let db = Database.database().reference()
            db.child("Chats").child(self.chatRoom.id).childByAutoId().setValue(messageData) { (error, ref) in
                if let error = error {
                    print("데이터베이스에 메시지를 저장하는 데 실패했습니다: \(error.localizedDescription)")
                } else {
                    print("메시지를 성공적으로 저장했습니다.")
                    self.messageInputField.text = "" // 메시지 전송 후 텍스트 필드를 비웁니다.
                }
            }
        }
    }

        @objc func attachImage() {
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        getCurrentUserNickname { (nickname) in
            if let nickname = nickname {
                self.handleImageSelected(info: info, nickname: nickname)
            } else {
                print("Error: Could not retrieve the current user's nickname.")
            }
        }
    }

    func handleImageSelected(info: [UIImagePickerController.InfoKey : Any], nickname: String) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let storageRef = Storage.storage().reference().child("image/\(UUID().uuidString).jpg")
            if let uploadData = pickedImage.jpegData(compressionQuality: 0.5) {
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    if error != nil {
                        print("Failed to upload image:", error!)
                        return
                    }
                    
                    print("Successfully uploaded image.")
                    
                    storageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            print("Failed to get download url:", error!)
                            return
                        }
                        
                        print("Successfully got download URL.")
                        
                        // 채팅방 ID에 대한 참조를 얻은 후, 해당 위치에서 새로운 메시지 ID를 생성
                        let ref = Database.database().reference().child("Chats").child(self.chatRoom.id).childByAutoId()
                        let messageData: [String: Any] = [
                            "content": downloadURL.absoluteString,
                            "mine": true,
                            "sender": nickname,
                            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                            "type": "image",
                            "id": ref.key ?? "", // 생성된 메시지 ID를 사용합니다.
                            // 필요한 항목을 추가하거나 제거해주세요.
                            // "author": "Test_new",
                            // "name": "open_chat",
                            // "password": "",
                        ]
                        
                        ref.updateChildValues(messageData) { (error, ref) in
                            if error != nil {
                                print("Failed to save message data:", error!)
                                return
                            }
                            
                            print("Successfully saved message data.")
                        }
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }

        func getCurrentUserNickname(completion: @escaping (String?) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(nil)
                return
            }

            let db = Database.database().reference()
            db.child("Users").child(uid).child("nickname").observeSingleEvent(of: .value) { (snapshot) in
                guard let nickname = snapshot.value as? String else {
                    print("Error: Could not retrieve nickname.")
                    completion(nil)
                    return
                }
                completion(nickname)
            }
        }
    }

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
