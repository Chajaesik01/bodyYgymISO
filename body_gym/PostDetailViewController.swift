//
//  PostDetailViewController.swift
//  bodyYgym
//
//  Created by 차재식 on 2024/01/21.
//  Copyright © 2024 차재식. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import SDWebImage

struct Comment {
    var author: String?
    let text: String
    let timestamp: Int
    let userId: String
    let id: String

    init(dictionary: [String: Any]) {
        self.author = dictionary["author"] as? String ?? "익명"
        self.text = dictionary["text"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Int ?? 0
        self.userId = dictionary["userId"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
    }
}

class PostDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var post: Post?
    var postRef: DatabaseReference!
    var comments: [Comment] = []
    var commentsTableView: UITableView!
    var commentTextField: UITextField!
    let imageView = UIImageView() // 클래스의 속성으로 추가
    let sendButton = UIButton()
    let titleLabel = UILabel()
    let contentTextView = UITextView()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        postRef = Database.database().reference().child("posts").child(post?.postId ?? "")

        postRef.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let post = Post(dictionary: dictionary)
                self.setupUI(with: post)
            }
        }, withCancel: nil)
        
    
        sendButton.setTitle("저장", for: .normal)
        sendButton.setTitleColor(.black, for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.backgroundColor = .lightGray
        view.addSubview(sendButton)
        
        
        // 댓글 테이블 뷰 설정
            commentsTableView = UITableView()
            commentsTableView.delegate = self
            commentsTableView.dataSource = self
            commentsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CommentCell")
            commentsTableView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(commentsTableView)

            // 댓글 입력 필드 설정
            commentTextField = UITextField()
            commentTextField.placeholder = "댓글을 입력하세요..."
            commentTextField.delegate = self
            commentTextField.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(commentTextField)

            // 뒤로가기 버튼 추가
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "뒤로가기", style: .plain, target: self, action: #selector(goBack))
        
        // 로그인한 사용자의 이름을 가져옵니다.
        fetchLoggedInUserName { [weak self] (username) in
            guard let self = self else { return }
            
            print("Logged in user name: \(username ?? "nil")")  // 로그인한 사용자의 이름을 출력합니다.
            print("Post writer: \(self.post?.writer ?? "nil")")  // 게시글 작성자의 이름을 출력합니다.
            
            if self.post?.writer == username || username == "관장님" || username == "관리자" {
                let editButton = UIBarButtonItem(title: "수정", style: .plain, target: self, action: #selector(self.editButtonTapped))
                self.navigationItem.rightBarButtonItem = editButton

                let deleteButton = UIBarButtonItem(title: "삭제", style: .plain, target: self, action: #selector(self.deleteButtonTapped))
                self.navigationItem.leftBarButtonItem = deleteButton
            }
        }
        
        let commentsRef = Database.database().reference().child("comments").child(post?.postId ?? "")
        commentsRef.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            if var dictionary = snapshot.value as? [String: AnyObject] {
                dictionary["id"] = snapshot.key as AnyObject // 여기서 "id"를 추가합니다.
                var comment = Comment(dictionary: dictionary) // comment를 var로 선언합니다.
                
                // userId에 해당하는 사용자의 닉네임을 가져옵니다.
                self.fetchUserName(with: comment.userId) { (username) in
                    comment.author = username // 닉네임을 author 프로퍼티에 저장합니다.
                    print(comment.author)
                    self.comments.append(comment)
                    DispatchQueue.main.async {
                        self.commentsTableView.reloadData()
                    }
                }
            }
        }, withCancel: nil)
        commentsTableView.dataSource = self
        //fetchComments()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        // '전송' 버튼의 제약 조건 설정

    }

    func setupUI(with post: Post) {
        
        // 게시글 내용을 표시하는 TextView를 생성하고 설정합니다.
        contentTextView.text = post.content
        contentTextView.font = UIFont.systemFont(ofSize: 20)
        contentTextView.isEditable = false
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        
        
        // 선을 생성합니다.
        let separatorLine = UIView()
        separatorLine.backgroundColor = .black
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
            
        let text = post.title
        if text.count > 10 {
            let index = text.index(text.startIndex, offsetBy: 8)
            titleLabel.text = String(text[..<index]) + "..."
        } else {
            titleLabel.text = text
        }
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let writerAndDateLabel = UILabel()
        writerAndDateLabel.font = UIFont.systemFont(ofSize: 16)
        writerAndDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timestampInt = post.timestamp ?? 0
        let timestamp = Double(timestampInt)
        let date = Date(timeIntervalSince1970: timestamp / 1000) // Firebase timestamp는 밀리초 단위이므로 1000으로 나눕니다.

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm" // 원하는 날짜 형식으로 설정합니다.
        let dateString = dateFormatter.string(from: date)

        writerAndDateLabel.text = "\(post.writer ?? "") (\(dateString))"
        

        
        let editButton = UIButton()
        editButton.setTitle("수정", for: .normal)
        editButton.setTitleColor(.blue, for: .normal)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)

        let deleteButton = UIButton()
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        let reportButton = UIButton()
        reportButton.setTitle("신고", for: .normal)
        reportButton.setTitleColor(.red, for: .normal)
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        reportButton.addTarget(self, action: #selector(reportButtonTapped), for: .touchUpInside)
        
        
        imageView.sd_setImage(with: URL(string: post.imageUrl ?? ""), completed: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageViewTapped)))

        // 댓글 공간을 위한 placeholder
        let commentsPlaceholder = UIView()
        commentsPlaceholder.backgroundColor = .lightGray
        commentsPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        // commentsPlaceholder 뷰에 댓글 테이블 뷰와 댓글 입력 필드를 추가합니다.
        commentsPlaceholder.addSubview(commentsTableView)
        commentsPlaceholder.addSubview(commentTextField)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        writerAndDateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        commentsPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
    
    
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "뒤로가기", style: .plain, target: self, action: #selector(goBack))

        view.addSubview(titleLabel)
        view.addSubview(writerAndDateLabel)
        view.addSubview(contentTextView) // 여기에 추가
        view.addSubview(imageView)
        view.addSubview(commentsPlaceholder)
        view.addSubview(separatorLine)
        view.addSubview(commentsTableView)
        view.addSubview(editButton)
        view.addSubview(deleteButton)
        view.addSubview(reportButton)
        commentsPlaceholder.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.heightAnchor.constraint(equalToConstant: 30), // 예시입니다. 적절한 값으로 조절해주세요.
           
            
            separatorLine.topAnchor.constraint(equalTo: writerAndDateLabel.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            writerAndDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            writerAndDateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            writerAndDateLabel.heightAnchor.constraint(equalToConstant: 30), // 예시입니다. 적절한 값으로 조절해주세요.

            editButton.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            editButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            editButton.widthAnchor.constraint(equalToConstant: 60),
            editButton.heightAnchor.constraint(equalToConstant: 30),

            deleteButton.topAnchor.constraint(equalTo: editButton.topAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 5),
            deleteButton.widthAnchor.constraint(equalToConstant: 60),
            deleteButton.heightAnchor.constraint(equalToConstant: 30),

            reportButton.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            reportButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 5),
            reportButton.widthAnchor.constraint(equalToConstant: 60),
            reportButton.heightAnchor.constraint(equalToConstant: 30),
            
            
            
            contentTextView.topAnchor.constraint(equalTo: writerAndDateLabel.bottomAnchor, constant: 20),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentTextView.heightAnchor.constraint(equalToConstant: 150), // 높이 제약 조건을 변경합니다.
            
            imageView.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 20), // 여기를 변경합니다.
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            

            // commentsPlaceholder의 제약 조건을 설정합니다.
            commentsPlaceholder.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            commentsPlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentsPlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentsPlaceholder.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            
            commentTextField.leadingAnchor.constraint(equalTo: commentsPlaceholder.leadingAnchor),
            commentTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            commentTextField.bottomAnchor.constraint(equalTo: commentsPlaceholder.bottomAnchor),
            commentTextField.heightAnchor.constraint(equalToConstant: 50),
            

            // commentsTableView의 top 제약 조건을 commentsPlaceholder.topAnchor로 변경합니다.
            commentsTableView.topAnchor.constraint(equalTo: commentsPlaceholder.topAnchor),
            commentsTableView.leadingAnchor.constraint(equalTo: commentsPlaceholder.leadingAnchor),
            commentsTableView.trailingAnchor.constraint(equalTo: commentsPlaceholder.trailingAnchor),
            commentsTableView.bottomAnchor.constraint(equalTo: commentTextField.topAnchor), // 이 부분을 추가

            commentTextField.leadingAnchor.constraint(equalTo: commentsPlaceholder.leadingAnchor),
            commentTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            commentTextField.bottomAnchor.constraint(equalTo: commentsPlaceholder.bottomAnchor),
            commentTextField.heightAnchor.constraint(equalToConstant: 50),
            sendButton.trailingAnchor.constraint(equalTo: commentsPlaceholder.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: commentTextField.bottomAnchor), // 추가된 부분
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            sendButton.heightAnchor.constraint(equalTo: commentTextField.heightAnchor),
        ])
    }
    
    func fetchComments() {
        guard let postId = self.post?.postId else { return } // post는 현재 게시물을 나타내는 변수입니다.
        print("Failed to get postId")

        let commentsRef = Database.database().reference().child("comments").child(postId)
        print("Fetching comments from: comments/\(postId)")
        commentsRef.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            
            let comment = Comment(dictionary: dictionary)
            self.comments.append(comment)
            
            // 댓글 데이터를 콘솔에 출력합니다.
            print("Fetched comment: \(comment.text)")
            
            // UI 업데이트는 메인 스레드에서 실행해야 합니다.
            DispatchQueue.main.async {
                self.commentsTableView.reloadData()
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let commentText = textField.text, !commentText.isEmpty else {
            // 댓글 텍스트가 비어있으면 아무것도 하지 않습니다.
            return true
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return true
        }

        // userId에 해당하는 사용자의 닉네임을 가져옵니다.
        self.fetchUserName(with: userId) { [weak self] (username) in
            guard let self = self else { return }
            
            let commentsRef = Database.database().reference().child("comments").child(self.post?.postId ?? "")
            let newCommentRef = commentsRef.childByAutoId()
            let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Firebase timestamp는 밀리초 단위입니다.
            let commentId = newCommentRef.key ?? "" // 여기에서 댓글의 ID를 가져옵니다.

            // 'author' 필드에 닉네임을 추가하고, 'id' 필드에 댓글의 ID를 추가합니다.
            let values: [String: Any] = ["text": commentText, "userId": userId, "timestamp": timestamp, "author": username ?? "", "id": commentId]
            
            newCommentRef.updateChildValues(values) { [weak self] (error, ref) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to save comment:", error)
                    return
                }

                // 댓글을 저장한 후에는 텍스트 필드를 비웁니다.
                DispatchQueue.main.async {
                    textField.text = ""
                }

                // 댓글을 comments 배열에 추가하고, commentsTableView를 리로드합니다.
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let dictionary = snapshot.value as? [String: Any] else { return }
                    let comment = Comment(dictionary: dictionary)
                    self.comments.append(comment)
                    
                    DispatchQueue.main.async {
                        self.commentsTableView.reloadData()
                    }
                })
            }
        }

        return true
    }

    // MARK: - UITableView Delegate & DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func fetchUserName(with userId: String, completion: @escaping (String?) -> Void) {
        let usersRef = Database.database().reference().child("Users").child(userId)
        usersRef.observeSingleEvent(of: .value) { (snapshot) in
            let value = snapshot.value as? [String: Any]
            let username = value?["nickname"] as? String // 닉네임 키가 "nickname"이라고 가정했습니다.
            completion(username)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let comment = comments[indexPath.row]
        
        // 로그인한 사용자의 이름을 가져옵니다.
        fetchLoggedInUserName { [weak self] (username) in
            guard let self = self else { return }
            
            if comment.author == username {
                // 삭제 대화 상자를 표시합니다.
                let alertController = UIAlertController(title: "댓글 삭제", message: "이 댓글을 삭제하시겠습니까?", preferredStyle: .alert) // 이 부분이 빠져있었습니다.
                let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
                    // 댓글을 삭제합니다.
                    let postId = self.post?.postId ?? ""
                    let commentId = comment.id // 이 부분을 수정합니다.
                    print("Post ID: \(postId)") // Post ID 확인
                    print("Comment ID: \(commentId)") // Comment ID 확인
                    let commentsRef = Database.database().reference().child("comments").child(postId)
                    commentsRef.child(commentId).removeValue { error, _ in
                        if let error = error {
                            print("Failed to remove comment: \(error)")
                        } else {
                            print("Comment successfully removed!")
                            // 댓글을 배열에서 제거합니다.
                            self.comments = self.comments.filter { $0.id != commentId }
                            
                            // 테이블 뷰를 다시 로드합니다.
                            DispatchQueue.main.async {
                                tableView.reloadData()
                            }
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "취소", style: .cancel)
                
                alertController.addAction(deleteAction)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true) // 이 부분을 수정합니다.
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        let comment = comments[indexPath.row]
        cell.textLabel?.text = "\(comment.author ?? "익명"): \(comment.text)"
        return cell
    }
    
    func fetchLoggedInUserName(completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        Database.database().reference().child("Users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let username = dictionary["nickname"] as? String
                completion(username)
            }
        }, withCancel: nil)
    }
    
    
    @objc func sendButtonTapped() {
        guard let commentText = commentTextField.text, !commentText.isEmpty else {
            // 댓글 텍스트가 비어있으면 아무것도 하지 않습니다.
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }

        // userId에 해당하는 사용자의 닉네임을 가져옵니다.
        self.fetchUserName(with: userId) { [weak self] (username) in
            guard let self = self else { return }
            
            let commentsRef = Database.database().reference().child("comments").child(self.post?.postId ?? "")
            let newCommentRef = commentsRef.childByAutoId()
            let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Firebase timestamp는 밀리초 단위입니다.
            let commentId = newCommentRef.key ?? "" // 여기에서 댓글의 ID를 가져옵니다.

            // 'author' 필드에 닉네임을 추가하고, 'id' 필드에 댓글의 ID를 추가합니다.
            let values: [String: Any] = ["text": commentText, "userId": userId, "timestamp": timestamp, "author": username ?? "", "id": commentId]
            
            newCommentRef.updateChildValues(values) { [weak self] (error, ref) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to save comment:", error)
                    return
                }

                // 댓글을 저장한 후에는 텍스트 필드를 비웁니다.
                DispatchQueue.main.async {
                    self.commentTextField.text = ""
                }

                // 댓글을 comments 배열에 추가하고, commentsTableView를 리로드합니다.
                let comment = Comment(dictionary: values)
                self.comments.append(comment)
                
                DispatchQueue.main.async {
                    self.commentsTableView.reloadData()
                }
            }
        }
    }
    
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func imageViewTapped() {
        let imageViewController = UIViewController()
        imageViewController.view.backgroundColor = .black

        let imageView = UIImageView()
        imageView.frame = imageViewController.view.frame
        imageView.contentMode = .scaleAspectFit
        imageView.image = self.imageView.image // self.imageView는 클릭한 이미지뷰를 의미합니다.
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage)))

        imageViewController.view.addSubview(imageView)
        self.present(imageViewController, animated: true)
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
        self.dismiss(animated: true)
    }
    
    @objc func editButtonTapped() {
            fetchLoggedInUserName { [weak self] (username) in
                guard let self = self, let post = self.post, post.writer == username || username == "관장님" || username == "관리자"else { return }

                // 로그인한 사용자가 게시글 작성자인 경우 게시글 수정 로직을 수행합니다.
                let alertController = UIAlertController(title: "게시글 수정", message: "제목과 내용을 수정해주세요.", preferredStyle: .alert)

                alertController.addTextField { (textField) in
                    textField.text = post.title
                }
                alertController.addTextField { (textField) in
                    textField.text = post.content
                }

                alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))

                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] (_) in
                    guard let self = self else { return }
                    let title = alertController.textFields?[0].text ?? ""
                    let content = alertController.textFields?[1].text ?? ""

                    let postRef = Database.database().reference().child("posts").child(self.post?.postId ?? "")
                    let updatedPost = ["title": title, "content": content]
                    postRef.updateChildValues(updatedPost)

                    var updatedPostModel = self.post
                    updatedPostModel?.title = title
                    updatedPostModel?.content = content
                    self.post = updatedPostModel

                    // UI 요소를 업데이트합니다.
                    let text = self.post?.title ?? ""
                    if text.count > 8 {
                        let index = text.index(text.startIndex, offsetBy: 10)
                        self.titleLabel.text = String(text[..<index]) + "..."
                    } else {
                        self.titleLabel.text = text
                    }
                }))

                self.present(alertController, animated: true, completion: nil)
            }
        }

        @objc func deleteButtonTapped() {
            fetchLoggedInUserName { [weak self] (username) in
                guard let self = self, let post = self.post, post.writer == username || username == "관장님" || username == "관리자" else { return }

                // 로그인한 사용자가 게시글 작성자인 경우 게시글 삭제 로직을 수행합니다.
                let alertController = UIAlertController(title: "게시글 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)

                alertController.addAction(UIAlertAction(title: "예", style: .default, handler: { (_) in
                    let postRef = Database.database().reference().child("posts").child(post.postId ?? "")
                    postRef.removeValue()
                    
                    self.navigationController?.popViewController(animated: true)
                }))

                alertController.addAction(UIAlertAction(title: "아니오", style: .cancel, handler: nil))

                self.present(alertController, animated: true, completion: nil)
            }
        }
    
    @objc func reportButtonTapped() {
        // 신고 버튼이 눌렸을 때의 동작을 작성합니다.
        let alertController = UIAlertController(title: "신고", message: "이 게시글을 신고하시겠습니까?", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "신고 사유를 입력해주세요..."
        }
        
        let reportAction = UIAlertAction(title: "신고", style: .destructive) { _ in
            // 신고 로직을 작성합니다.
            if let reportReason = alertController.textFields?.first?.text {
                // reportReason에 신고 사유가 저장됩니다.
                // Firebase에 신고 정보를 저장합니다.
                let reportRef = Database.database().reference().child("report")
                let reportId = reportRef.childByAutoId().key ?? ""
                
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd/HH:mm"
                let reportTime = dateFormatter.string(from: date) // 현재 시간을 'yyyy-MM-dd/HH:mm' 형식의 문자열로 변환합니다.
                
                let reportData = ["reportId": reportId,
                                  "reportReason": reportReason,
                                  "author": self.post?.writer ?? "",
                                  "postTitle": self.post?.title ?? "",
                                  "postContent": self.post?.content ?? "",
                                  "reportTime": reportTime] // 신고 시간을 추가합니다.
                reportRef.child(reportId).setValue(reportData)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
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
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
