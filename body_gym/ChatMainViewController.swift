//
//  ChatMainViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth


struct ChatRoom {
    let id: String
    let author: String
    let name: String
    let password: String
    let timestamp: Double // 채팅방이 생성된 시간의 타임스탬프
}

class ChatRoomNavigator {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func navigateToChatRoom(_ chatRoom: ChatRoom) {
        let chatRoomViewController = ChatRoomViewController()
        chatRoomViewController.chatRoom = chatRoom
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
}




class ChatMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var originalChatRooms: [ChatRoom] = []
    var chatRooms: [ChatRoom] = []
    var tableView: UITableView!
    var chatRoomNavigator: ChatRoomNavigator?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 테이블 뷰 생성 및 셀 등록
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatRoomCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never // 이 줄 추가
        view.addSubview(tableView)

        let topBar = UIView()
        topBar.backgroundColor = .white
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        let titleLabel = UILabel()
        titleLabel.text = "채팅방"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(titleLabel)

        let searchButton = UIButton()
        searchButton.setTitle("검색", for: .normal)
        searchButton.setTitleColor(.black, for: .normal) // 글씨색을 검은색으로 설정
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(searchButton)
        
        let refreshButton = UIButton()
        refreshButton.setTitle("새로고침", for: .normal)
        refreshButton.setTitleColor(.black, for: .normal) // 글씨색을 검은색으로 설정
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(refreshButton)
        refreshButton.isHidden = true

        let addButton = UIButton()
        addButton.setTitle("추가", for: .normal)
        addButton.setTitleColor(.black, for: .normal) // 글씨색을 검은색으로 설정
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(addButton)
        
        let separator = UIView()
        separator.backgroundColor = .black // 실선의 색상을 검은색으로 설정
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)
        
        // ChatRoomNavigator 인스턴스 초기화
        chatRoomNavigator = ChatRoomNavigator(navigationController: self.navigationController)
    
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 50),

            separator.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.3), // 실선의 높이를 1로 설정

            tableView.topAnchor.constraint(equalTo: topBar.bottomAnchor), // separator.bottomAnchor를 topBar.bottomAnchor로 변경
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            searchButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 10),
            searchButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            refreshButton.leadingAnchor.constraint(equalTo: searchButton.trailingAnchor, constant: 10),
            refreshButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            addButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -10),
            addButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
        ])
        fetchChatRooms()
    }
    
    // 새로고침 버튼이 눌렸을 때 호출될 메소드
    @objc func refreshButtonTapped() {
        fetchChatRooms()
    }
    
    func fetchChatRooms() {
        let ref = Database.database().reference()
        ref.child("Chats").observe(.value, with: { [weak self] snapshot in
            guard let self = self, let chatRoomsDict = snapshot.value as? [String: [String: Any]] else { return }

            var allChatRooms: [ChatRoom] = []

            // 모든 채팅방을 가져옵니다.
            for (id, data) in chatRoomsDict {
                guard let author = data["author"] as? String,
                      let name = data["name"] as? String,
                      let password = data["password"] as? String,
                      let timestamp = data["timestamp"] as? Double else { continue }

                let chatRoom = ChatRoom(id: id, author: author, name: name, password: password, timestamp: timestamp)
                allChatRooms.append(chatRoom)
            }

            // 타임스탬프를 기준으로 내림차순 정렬합니다.
            self.originalChatRooms = allChatRooms.sorted(by: { $0.timestamp > $1.timestamp })

            // chatRooms 배열에는 공개방만 저장합니다.
            self.chatRooms = self.originalChatRooms.filter { $0.password.isEmpty }

            // 메인 스레드에서 화면을 업데이트합니다.
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { error in
            print(error.localizedDescription)
        }
    }

    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomCell", for: indexPath)
        let chatRoom = chatRooms[indexPath.row]

        // DateFormatter 인스턴스 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // 원하는 날짜 형식 설정
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // 타임스탬프가TC 기준일 경우 설정

        // timestamp를 Date 객체로 변환
        let date = Date(timeIntervalSince1970: chatRoom.timestamp / 1000) // 밀리초 단위이므로 1000으로 나눔

        // Date 객체를 원하는 문자열 형식으로 변환
        let dateString = dateFormatter.string(from: date)

        // 셀의 텍스트에 채팅방의 제목, 작성자 이름, 그리고 날짜를 포함시킵니다.
        cell.textLabel?.text = "\(chatRoom.name) - \(chatRoom.author) - \(dateString)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatRoom = chatRooms[indexPath.row]
        // 비밀번호가 있는 경우 비밀번호 입력을 요구합니다.
        if !chatRoom.password.isEmpty {
            // 비밀번호 입력을 위한 AlertController 생성
            let passwordAlert = UIAlertController(title: "비밀번호 입력", message: "이 채팅방에 입장하려면 비밀번호를 입력해야 합니다.", preferredStyle: .alert)
            passwordAlert.addTextField { textField in
                textField.placeholder = "비밀번호"
                textField.isSecureTextEntry = true // 비밀번호를 안전하게 입력받기 위해
            }
            let enterAction = UIAlertAction(title: "입장", style: .default) { [weak self, weak passwordAlert] _ in
                guard let textField = passwordAlert?.textFields?.first, let inputPassword = textField.text else { return }
                if inputPassword == chatRoom.password {
                    // 비밀번호가 일치하면 채팅방으로 이동
                    self?.chatRoomNavigator?.navigateToChatRoom(chatRoom)
                    
                } else {
                    // 비밀번호가 일치하지 않으면 경고 메시지 표시
                    self?.showPasswordError()
                }
            }
            passwordAlert.addAction(enterAction)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            passwordAlert.addAction(cancelAction)
            
            // AlertController를 표시합니다.
            present(passwordAlert, animated: true, completion: nil)
        } else {
            // 비밀번호가 없는 경우 바로 채팅방으로 이동
            chatRoomNavigator?.navigateToChatRoom(chatRoom)
        }
    }

    func showPasswordError() {
        let errorAlert = UIAlertController(title: "오류", message: "비밀번호가 일치하지 않습니다.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        errorAlert.addAction(okAction)
        present(errorAlert, animated: true, completion: nil)
    }

    /*
    func navigateToChatRoom(_ chatRoom: ChatRoom) {
        // 채팅방으로 이동하는 코드를 여기에 작성합니다.
        // 예: 해당 채팅방의 ViewController를 push 하거나 present 합니다.
    }
 */
    @objc func searchButtonTapped() {
        let alertController = UIAlertController(title: "검색", message: "제목 또는 작성자를 선택하고 검색어를 입력하세요.", preferredStyle: .alert)

        // 제목 또는 작성자를 선택하는 액션 추가
        let titleAction = UIAlertAction(title: "제목", style: .default) { [weak self] _ in
            self?.search(by: .title)
        }
        alertController.addAction(titleAction)

        let authorAction = UIAlertAction(title: "작성자", style: .default) { [weak self] _ in
            self?.search(by: .author)
        }
        alertController.addAction(authorAction)

        // 취소 액션 추가
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    enum SearchType {
        case title
        case author
    }

    func search(by type: SearchType) {
        let alertController = UIAlertController(title: "검색어 입력", message: nil, preferredStyle: .alert)
        alertController.addTextField()

        let searchAction = UIAlertAction(title: "검색", style: .default) { [weak self, weak alertController] _ in
            guard let keyword = alertController?.textFields?.first?.text else { return }
            self?.filterChatRooms(by: type, keyword: keyword)
        }
        alertController.addAction(searchAction)

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    
    func filterChatRooms(by type: SearchType, keyword: String) {
        switch type {
        case .title:
            chatRooms = originalChatRooms.filter { $0.name.contains(keyword) }
        case .author:
            chatRooms = originalChatRooms.filter { $0.author.contains(keyword) }
        }
        tableView.reloadData()
    }

    func resetFilter() {
        // originalChatRooms 배열에서 password가 빈 문자열인 방만 필터링하여 chatRooms 배열에 할당합니다.
        chatRooms = originalChatRooms.filter { $0.password.isEmpty }

        // tableView가 nil인지 확인합니다.
        if tableView != nil {
            tableView.reloadData()
        }
    }

    @objc func addButtonTapped() {
        let roomTypeAlert = UIAlertController(title: "방 유형 선택", message: "생성할 채팅방 유형을 선택해주세요.", preferredStyle: .actionSheet)

        let publicRoomAction = UIAlertAction(title: "공개방", style: .default) { [weak self] _ in
            self?.presentCreateRoomAlert(isSecret: false)
        }

        let secretRoomAction = UIAlertAction(title: "비밀방", style: .default) { [weak self] _ in
            self?.presentCreateRoomAlert(isSecret: true)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        roomTypeAlert.addAction(publicRoomAction)
        roomTypeAlert.addAction(secretRoomAction)
        roomTypeAlert.addAction(cancelAction)

        present(roomTypeAlert, animated: true, completion: nil)
    }
    
    func presentCreateRoomAlert(isSecret: Bool) {
        let alert = UIAlertController(title: "새 채팅방 생성", message: "방 이름을 입력해주세요.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "방 이름"
        }

        if isSecret {
            alert.addTextField { textField in
                textField.placeholder = "비밀번호"
                textField.isSecureTextEntry = true
            }
        }

        let createAction = UIAlertAction(title: "생성", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text,
                  let password = isSecret ? alert.textFields?.last?.text : "",
                  let self = self else { return }

            // 사용자 닉네임 가져오기
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let usersRef = Database.database().reference().child("Users").child(uid)
            
            usersRef.observeSingleEvent(of: .value, with: { snapshot in
                let nickname = snapshot.childSnapshot(forPath: "nickname").value as? String ?? "익명"

                let ref = Database.database().reference().child("Chats")
                let chatRoomId = ref.childByAutoId().key ?? UUID().uuidString
                // 채팅방 정보에 타임스탬프를 추가
                let chatRoomInfo: [String: Any] = [
                    "id": chatRoomId,
                    "author": nickname,
                    "name": name,
                    "password": password,
                    "timestamp": ServerValue.timestamp() // 서버 타임스탬프 추가
                ]

                ref.child(chatRoomId).setValue(chatRoomInfo) { error, _ in
                    if let error = error {
                        print("데이터베이스 저장 에러: \(error.localizedDescription)")
                    } else {
                        print("새로운 채팅방이 성공적으로 생성되었습니다.")
                        // 채팅방 목록을 다시 가져오거나, UI를 업데이트하는 로직을 추가할 수 있습니다.
                    }
                }
            }) { error in
                print("닉네임 가져오기 에러: \(error.localizedDescription)")
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alert.addAction(createAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
}
