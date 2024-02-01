//
//  BoardMainViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
struct Post {
    var title: String
    let writer: String
    let timestamp: Int
    var postId: String?
    var imageUrl : String?
    var content : String?

    init(dictionary: [String: Any]) {
        self.title = dictionary["title"] as? String ?? "title 없음"
        self.writer = dictionary["writer"] as? String ?? "익명"
        self.timestamp = dictionary["timestamp"] as? Int ?? 0
        self.postId = dictionary["postId"] as? String
        self.imageUrl = dictionary["imageUrl"] as? String
        self.content = dictionary["content"] as? String
    }
}

import Foundation
import UIKit
import FirebaseDatabase

class BoardMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    var posts = [Post]() {
        didSet {
            // "관리자" 또는 "관장님" 작성자의 게시글을 상단에 배치합니다.
            posts.sort { ($0.writer == "관리자" || $0.writer == "관장님") && !($1.writer == "관리자" || $1.writer == "관장님") }
        }
    }
    let tableView = UITableView()
    let headerLabel = UILabel()
    let separatorView = UIView()
    // '글 작성' 버튼 UI 요소
    let writePostButton = UIButton(type: .system)
    var filteredPosts = [Post]()
    let searchController = UISearchController(searchResultsController: nil)
    let searchButton = UIButton(type: .system)
    var isCustomSearchActive = false
    private var lastViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 화면 상단에 "자유게시판" 라벨과 구분선 추가
        setupHeaderView()
        // '글 작성' 버튼 설정 및 레이아웃 추가
        //setupWritePostButton()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 검색 컨트롤러 설정
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "검색"
        navigationItem.searchController = nil
        navigationController?.navigationBar.isHidden = true
        definesPresentationContext = true
        
        // '검색' 버튼 설정
        searchButton.setTitle("검색", for: .normal)
        searchButton.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
        view.addSubview(searchButton)
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 8),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            searchButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor)
        ])
        
        fetchPosts()
        
    }
    
    

    func setupHeaderView() {
        headerLabel.text = "자유게시판"
        headerLabel.textColor = .black // 텍스트 색상을 변경합니다.
        headerLabel.backgroundColor = .white
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textAlignment = .center
        view.addSubview(headerLabel)
        
        separatorView.backgroundColor = .black
        view.addSubview(separatorView)
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            separatorView.heightAnchor.constraint(equalToConstant: 0.3),
            separatorView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            separatorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        // '글 작성' 버튼 레이아웃 설정
        writePostButton.setTitle("글 작성", for: .normal)
        writePostButton.addTarget(self, action: #selector(didTapWritePostButton), for: .touchUpInside)
        view.addSubview(writePostButton)
        
        writePostButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            writePostButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            writePostButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor)
        ])
    }

    // '글 작성' 버튼 액션
    @objc func didTapWritePostButton() {
        let createPostVC = CreatePostViewController()
        // 네비게이션 컨트롤러가 있다면, 그것을 사용해서 새로운 뷰 컨트롤러를 푸시합니다.
        // 없다면, 모달 형태로 표시합니다.
        if let navigationController = navigationController {
            navigationController.pushViewController(createPostVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: createPostVC) // 모달을 위한 네비게이션 컨트롤러를 추가
            present(navController, animated: true, completion: nil)
        }
    }
    
    @objc func didTapSearchButton() {
        // 검색 옵션을 선택하기 위한 얼럿 컨트롤러를 생성합니다.
        let alertController = UIAlertController(title: "검색 옵션", message: "검색할 항목을 선택하세요.", preferredStyle: .actionSheet)

        // 제목 검색 액션을 정의합니다.
        let titleSearchAction = UIAlertAction(title: "제목으로 검색", style: .default) { [unowned self] _ in
            self.presentSearchAlert(searchType: "제목")
        }

        // 작성자 검색 액션을 정의합니다.
        let writerSearchAction = UIAlertAction(title: "작성자로 검색", style: .default) { [unowned self] _ in
            self.presentSearchAlert(searchType: "작성자")
        }

        // 취소 액션을 정의합니다.
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        // 얼럿 컨트롤러에 액션을 추가합니다.
        alertController.addAction(titleSearchAction)
        alertController.addAction(writerSearchAction)
        alertController.addAction(cancelAction)

        // 얼럿 컨트롤러를 표시합니다.
        present(alertController, animated: true)
    }

    // 검색 얼럿을 표시하는 메소드
    func presentSearchAlert(searchType: String) {
        let searchAlertController = UIAlertController(title: "\(searchType) 검색", message: nil, preferredStyle: .alert)
        
        // 검색 텍스트 필드 추가
        searchAlertController.addTextField { textField in
            textField.placeholder = "\(searchType) 입력"
        }
        
        // 검색 액션을 정의합니다.
        let searchAction = UIAlertAction(title: "검색", style: .default) { [unowned self] _ in
            guard let searchText = searchAlertController.textFields?.first?.text, !searchText.isEmpty else { return }
            print("사용자가 입력한 검색어: '\(searchText)'") // 입력한 검색어 출력
            
            if searchType == "제목" {
                    self.filteredPosts = self.posts.filter { post in
                        post.title.lowercased().contains(searchText.lowercased())
                    }
                } else {
                    self.filteredPosts = self.posts.filter { post in
                        post.writer.lowercased().contains(searchText.lowercased())
                    }
                }
                
                print("필터링된 포스트 목록: \(self.filteredPosts.map { $0.title })") // 필터링된 제목 목록 출력

            
            self.isCustomSearchActive = true
            // 필터링 결과를 콘솔에 출력합니다.
            print("필터링된 포스트 수: \(self.filteredPosts.count)")
            
            // 메인 스레드에서 테이블뷰를 리로드합니다.
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        // 취소 액션을 정의합니다.
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [unowned self] _ in
            // 사용자 정의 검색 활성화 상태를 false로 설정합니다.
            self.isCustomSearchActive = false
            
            // 메인 스레드에서 테이블뷰를 리로드합니다.
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        // 검색 얼럿 컨트롤러에 액션을 추가합니다.
        searchAlertController.addAction(searchAction)
        searchAlertController.addAction(cancelAction)
        
        // 검색 얼럿 컨트롤러를 표시합니다.
        present(searchAlertController, animated: true)
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        // 사용자가 입력한 검색 텍스트를 가져옵니다.
        guard let searchText = searchController.searchBar.text else { return }

        // 검색 텍스트가 비어있지 않은 경우 필터링을 수행합니다.
        if searchText.isEmpty {
            filteredPosts = posts
        } else {
            filteredPosts = posts.filter { post in
                post.title.lowercased().contains(searchText.lowercased()) ||
                post.writer.lowercased().contains(searchText.lowercased())
            }
        }
        print("검색 업데이트 - 검색어: \(searchText)")
        print("검색 업데이트 - 필터링된 포스트 수: \(filteredPosts.count)")

        // 메인 스레드에서 테이블뷰를 리로드합니다.
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func fetchPosts() {
        let ref = Database.database().reference().child("posts")
        ref.queryOrdered(byChild: "timestamp").observe(.value, with: { [weak self] snapshot in
            guard let self = self else { return }
            var adminPosts = [Post]()
            var otherPosts = [Post]()

            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let postDict = child.value as? [String: Any] {
                    let post = Post(dictionary: postDict)
                    if post.writer == "관리자" || post.writer == "관장님" {
                        adminPosts.append(post)
                    } else {
                        otherPosts.append(post)
                    }
                }
            }

            // 관리자 또는 관장님의 글을 최상단에 두고, 나머지 글들은 최신글이 위로 오도록 정렬합니다.
            otherPosts.sort { $0.timestamp > $1.timestamp }
            
            // 두 그룹을 합칩니다.
            self.posts = adminPosts + otherPosts
            print("전체 포스트 수: \(self.posts.count)")
            self.tableView.reloadData()
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    // TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // `isCustomSearchActive` 변수를 사용하여 필터링된 결과를 반환합니다.
        return isCustomSearchActive ? filteredPosts.count : posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // 검색이 활성화되었는지 확인하고, 해당하는 데이터 소스를 사용합니다.
        let post = isCustomSearchActive ? filteredPosts[indexPath.row] : posts[indexPath.row]

        // 데이터 모델에서 가져온 데이터를 셀에 할당합니다.
        let date = Date(timeIntervalSince1970: Double(post.timestamp) / 1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dateString = dateFormatter.string(from: date)

        // 셀에 표시될 텍스트를 설정합니다.
        var titleText = post.title
        if titleText.count > 10 {
            let index = titleText.index(titleText.startIndex, offsetBy: 10)
            titleText = "\(titleText[..<index])..."
        }
        cell.textLabel?.text = "\(titleText) - \(post.writer) - \(dateString)"
        
        // 셀에 할당된 데이터를 로그로 출력하여 확인합니다.
        print("셀에 할당된 데이터: \(cell.textLabel?.text ?? "데이터 없음")")

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailViewController = PostDetailViewController()
        detailViewController.post = posts[indexPath.row] // 선택된 게시글의 데이터를 전달
        navigationController?.pushViewController(detailViewController, animated: true) // 화면 이동
    }
    
}
