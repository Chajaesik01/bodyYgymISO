//
//  CalendarMainViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth


import Foundation
import UIKit
import FSCalendar  // 달력을 표시하기 위해 FSCalendar 라이브러리를 사용합니다.
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage

class ImageDetailViewController: UIViewController {
    var image: UIImage?
    var imageURL: String? // 이미지 URL을 저장할 프로퍼티 추가
    var memoID: String? // 메모 ID를 저장할 프로퍼티 추가
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // 삭제하기 버튼 추가
        let deleteButton = UIButton()
        deleteButton.setTitle("삭제하기", for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .lightGray
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: deleteButton.topAnchor), // 이미지 뷰의 하단을 삭제하기 버튼의 상단에 연결
            
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 50) // 삭제하기 버튼의 높이 설정
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func didTapBackground() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapDeleteButton() {
        print("Delete button was tapped.")
        // imageURL과 memoID 값 확인
        print("imageURL: \(imageURL ?? "nil")")
        print("memoID: \(memoID ?? "nil")")

        guard let url = imageURL, let memoID = memoID else {
            print("URL or memoID is nil.")
            return
        }

        // Firebase Storage에서 해당 URL의 이미지 삭제
        let storageRef = Storage.storage().reference(forURL: url)
        print("Deleting image from Storage...")
        storageRef.delete { error in
            if let error = error {
                print("Failed to delete image from Storage: \(error)")
            } else {
                print("Successfully deleted image from Storage.")
            }
        }

        // Firebase Database에서 imageURLs 배열에서 해당 URL 삭제
        let userID = Auth.auth().currentUser?.uid ?? ""
        let memoRef = Database.database().reference().child("Memos/\(memoID)/\(userID)")
        memoRef.observeSingleEvent(of: .value) { snapshot in
            print(snapshot.value)
        }
        print("Deleting imageURL from Database...")
        memoRef.observeSingleEvent(of: .value) { snapshot in
            if var memo = snapshot.value as? [String: Any],
               var imageURLs = memo["imageURLs"] as? [String] {
                if let index = imageURLs.firstIndex(of: url) {
                    imageURLs.remove(at: index)
                    memo["imageURLs"] = imageURLs
                    print("Setting new imageURLs in Database...")
                    memoRef.setValue(memo) { error, _ in
                        if let error = error {
                            print("Failed to delete imageURL from Database: \(error)")
                        } else {
                            print("Successfully deleted imageURL from Database.")
                            // 이미지 삭제 작업이 완료되었음을 알리는 노티피케이션 보내기
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImageDeleted"), object: nil)
                        }
                    }
                } else {
                    print("Could not find imageURL in Database.")
                }
            } else {
                print("Could not get memo from Database.")
            }
        }

        // 이전 화면으로 돌아가기
        dismiss(animated: true, completion: nil)
    }
}
class CalendarMainViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let calendar = FSCalendar()
    let memoContentTextView = UITextView()
    let scrollView = UIScrollView()
    let feedbackContentTextView = UITextView() // 클래스 변수로 변경
    var selectedDate: Date?
    var shareCheckBox: UIButton!
    var datesWithMemos = Set<String>()
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"  // 여기를 수정해주세요.
        return formatter
    }()
    var imagesPerDate: [String: [UIImage]] = [:]
    // 그림을 표시할 UIImageView를 생성합니다.
    let imageView1 = UIImageView()
    let imageView2 = UIImageView()
    let imageView3 = UIImageView()
    
    var currentSelectedDate: String?  // 클래스의 프로퍼티로 추가합니다

    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경색을 흰색으로 설정합니다.
        view.backgroundColor = .white
        // 캘린더에서 선택한 날짜를 저장합니다.
        // '식단운동일지' 레이블을 생성하고 설정합니다.
        let titleLabel = UILabel()
        titleLabel.text = "식단운동일지"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // '메모 추가' 버튼을 생성하고 설정합니다.
        let addButton = UIButton(type: .system)
        addButton.setTitle("메모 추가", for: .normal)
        addButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        // 수정 버튼을 생성하고 설정합니다.
        let editButton = UIButton(type: .system)
        editButton.setTitle("이미지 추가", for: .normal)
        editButton.addTarget(self, action: #selector(didTapEditButton), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)
        
        // '삭제' 버튼을 생성하고 설정합니다.
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)
        

        // 검은색 줄을 생성하고 설정합니다.
        let lineView = UIView()
        lineView.backgroundColor = .black
        lineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineView)

        // 달력을 설정하고 추가합니다.
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)
    
        

        // UIButton 인스턴스를 생성하고 설정합니다.
        shareCheckBox = UIButton(type: .custom)
        shareCheckBox.setTitle("☐", for: .normal)  // 체크가 안 되었을 때의 텍스트
        shareCheckBox.setTitle("☑", for: .selected)  // 체크가 되었을 때의 텍스트
        shareCheckBox.setTitleColor(.black, for: .normal)
        shareCheckBox.setTitleColor(.black, for: .selected)
        shareCheckBox.translatesAutoresizingMaskIntoConstraints = false
        shareCheckBox.addTarget(self, action: #selector(didTapCheckBox(_:)), for: .touchUpInside)  // 버튼이 눌렸을 때의 동작을 설정합니다.
        view.addSubview(shareCheckBox)

        let shareLabel = UILabel()
        shareLabel.text = "관장님과 메모 공유"
        shareLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareLabel)

        // '작성한 메모'와 그 내용을 묶을 뷰를 생성합니다.
        let memoView = UIView()
        memoView.translatesAutoresizingMaskIntoConstraints = false

        let memoLabel = UILabel()
        memoLabel.text = "작성한 메모  "
        memoLabel.translatesAutoresizingMaskIntoConstraints = false
        memoView.addSubview(memoLabel)

        // 메모 내용을 표시할 UITextView를 생성하고 설정합니다.
        memoContentTextView.text = ""
        memoContentTextView.isEditable = false  // 편집 불가능하도록 설정합니다.
        memoContentTextView.translatesAutoresizingMaskIntoConstraints = false
        memoView.addSubview(memoContentTextView)

        // '관장님 피드백'과 그 내용을 묶을 뷰를 생성합니다.
        let feedbackView = UIView()
        feedbackView.translatesAutoresizingMaskIntoConstraints = false

        let feedbackLabel = UILabel()
        feedbackLabel.text = "관장님 피드백 "
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackView.addSubview(feedbackLabel)

        // 피드백 내용을 표시할 UITextView를 생성하고 설정합니다.
        feedbackContentTextView.text = ""
        feedbackContentTextView.isEditable = false  // 편집 불가능하도록 설정합니다.
        feedbackContentTextView.translatesAutoresizingMaskIntoConstraints = false
        feedbackView.addSubview(feedbackContentTextView)

        // UIScrollView를 설정하고 추가합니다.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // memoView와 feedbackView를 UIScrollView에 추가합니다.
        scrollView.addSubview(memoView)
        scrollView.addSubview(feedbackView)

        // UITextView의 높이를 내용에 따라 조절하도록 설정합니다.
        memoContentTextView.isScrollEnabled = false
        feedbackContentTextView.isScrollEnabled = false
        
        // UIImageView를 설정합니다.
        imageView1.translatesAutoresizingMaskIntoConstraints = false
        imageView2.translatesAutoresizingMaskIntoConstraints = false
        imageView3.translatesAutoresizingMaskIntoConstraints = false

        // UIImageView를 숨깁니다.
        //imageView1.isHidden = true
        //imageView2.isHidden = true
        //imageView3.isHidden = true
        
        // imageView1에 대한 탭 제스처 인식기를 추가합니다.
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
        imageView1.isUserInteractionEnabled = true
        imageView1.addGestureRecognizer(tapGestureRecognizer1)

        // imageView2에 대한 탭 제스처 인식기를 추가합니다.
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
        imageView2.isUserInteractionEnabled = true
        imageView2.addGestureRecognizer(tapGestureRecognizer2)

        // imageView3에 대한 탭 제스처 인식기를 추가합니다.
        let tapGestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
        imageView3.isUserInteractionEnabled = true
        imageView3.addGestureRecognizer(tapGestureRecognizer3)
        

        // UIImageView를 뷰에 추가합니다.
        view.addSubview(imageView1)
        view.addSubview(imageView2)
        view.addSubview(imageView3)
        
        // AutoLayout 설정
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),

            editButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),

            // '삭제' 버튼의 제약을 수정합니다.
            deleteButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            lineView.heightAnchor.constraint(equalToConstant: 1),

            calendar.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 16),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendar.heightAnchor.constraint(equalToConstant: 200),
            
            // imageView1의 제약
            imageView1.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 16),
            imageView1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView1.widthAnchor.constraint(equalToConstant: 100),
            imageView1.heightAnchor.constraint(equalToConstant: 100),

            // imageView2의 제약
            imageView2.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 16),
            imageView2.leadingAnchor.constraint(equalTo: imageView1.trailingAnchor, constant: 16),
            imageView2.widthAnchor.constraint(equalToConstant: 100),
            imageView2.heightAnchor.constraint(equalToConstant: 100),

            // imageView3의 제약
            imageView3.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 16),
            imageView3.leadingAnchor.constraint(equalTo: imageView2.trailingAnchor, constant: 16),
            imageView3.widthAnchor.constraint(equalToConstant: 100),
            imageView3.heightAnchor.constraint(equalToConstant: 100),

            // 체크박스와 라벨의 위치를 이미지 뷰 아래로 변경합니다.
            shareCheckBox.topAnchor.constraint(equalTo: imageView1.bottomAnchor, constant: 16),
            shareCheckBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            shareLabel.centerYAnchor.constraint(equalTo: shareCheckBox.centerYAnchor),
            shareLabel.leadingAnchor.constraint(equalTo: shareCheckBox.trailingAnchor, constant: 8),
            // UIScrollView의 제약을 추가합니다.
            // UIScrollView의 제약을 추가합니다.
                       scrollView.topAnchor.constraint(equalTo: shareLabel.bottomAnchor, constant: 16),
                       scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                       scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                       scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

                       // memoView와 feedbackView의 제약을 수정합니다.
                       memoView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                       memoView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                       memoView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                       memoLabel.topAnchor.constraint(equalTo: memoView.topAnchor),
                       memoLabel.leadingAnchor.constraint(equalTo: memoView.leadingAnchor),

                       memoContentTextView.topAnchor.constraint(equalTo: memoLabel.bottomAnchor, constant: 8),
                       memoContentTextView.leadingAnchor.constraint(equalTo: memoView.leadingAnchor),
                       memoContentTextView.trailingAnchor.constraint(equalTo: memoView.trailingAnchor),
                       memoContentTextView.bottomAnchor.constraint(equalTo: memoView.bottomAnchor),

                       feedbackView.topAnchor.constraint(equalTo: memoView.bottomAnchor, constant: 16),
                       feedbackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                       feedbackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                       feedbackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),  // 스크롤 뷰의 컨텐츠 크기를 설정합니다.

                       feedbackLabel.topAnchor.constraint(equalTo: feedbackView.topAnchor),
                       feedbackLabel.leadingAnchor.constraint(equalTo: feedbackView.leadingAnchor),

                       feedbackContentTextView.topAnchor.constraint(equalTo: feedbackLabel.bottomAnchor, constant: 8),
                       feedbackContentTextView.leadingAnchor.constraint(equalTo: feedbackView.leadingAnchor),
                       feedbackContentTextView.trailingAnchor.constraint(equalTo: feedbackView.trailingAnchor),
                       feedbackContentTextView.bottomAnchor.constraint(equalTo: feedbackView.bottomAnchor),
        ])
        
        let ref = Database.database().reference().child("Memos")
        ref.observe(.value) { [weak self] snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    // 메모의 날짜를 datesWithMemos에 추가합니다.
                    let date = childSnapshot.key
                    self?.datesWithMemos.insert(date)
                }
            }
        }
        calendar.delegate = self
        calendar.dataSource = self
        
        updateDatesWithMemos()
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // UITextView의 높이를 내용에 따라 조절합니다.
        memoContentTextView.invalidateIntrinsicContentSize()
        feedbackContentTextView.invalidateIntrinsicContentSize()
    }
    
    @objc func didTapImageView(_ sender: UITapGestureRecognizer) {
        if let imageView = sender.view as? UIImageView, let image = imageView.image {
            let imageDetailViewController = ImageDetailViewController()
            imageDetailViewController.image = image

            // imageURL과 memoID 값을 설정합니다.
            imageDetailViewController.imageURL = imageView.sd_imageURL?.absoluteString
            imageDetailViewController.memoID = currentSelectedDate

            present(imageDetailViewController, animated: true, completion: nil)
        }
    }
    
    @objc func didTapCheckBox(_ sender: UIButton) {
        sender.isSelected.toggle()

        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let dateString = currentSelectedDate else {
            print("No date selected.")
            return
        }
        let isChecked = sender.isSelected

        let ref = Database.database().reference()
        ref.child("Memos/\(dateString)/\(userId)/shared").setValue(isChecked)
    }

    
    @objc func didTapEditButton() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func didTapAddButton() {
        let alertController = UIAlertController(title: "메모 추가", message: "추가할 메모를 작성해주세요.", preferredStyle: .alert)
        alertController.addTextField()

        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            if let memo = alertController.textFields?.first?.text {
                print("Confirm button tapped with memo: \(memo)")
                self?.memoContentTextView.text = memo

                guard let userId = Auth.auth().currentUser?.uid else { return }
                var date: Date
                if let selectedDateString = self?.currentSelectedDate {
                    if let selectedDate = self?.dateFormatter.date(from: selectedDateString) {
                        date = selectedDate
                    } else {
                        print("날짜 형식이 잘못되었습니다. yyyy-MM-dd 형식이어야 합니다.")
                        date = Date()
                    }
                } else {
                    date = Date()
                }

                let dateString = self?.dateFormatter.string(from: date) ?? ""  // 여기를 수정해주세요.
                let isChecked = self?.shareCheckBox.isSelected ?? false
                let ref = Database.database().reference()
                ref.child("Users/\(userId)/nickname").observeSingleEvent(of: .value) { (snapshot) in
                    guard let userName = snapshot.value as? String else { return }
                    let memoData = ["memo": memo, "userName": userName, "comment": "", "shared": isChecked, "imageURLs": ""] as [String: Any]
                    ref.child("Memos/\(dateString)/\(userId)").setValue(memoData)
                }
            }
        }
        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }
    
    @objc func didTapDeleteButton() {
        guard let dateString = currentSelectedDate else {
            print("No date selected.")
            return
        }

        // 삭제 확인 알림을 띄웁니다.
        let alert = UIAlertController(title: "메모 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: .default) { _ in
            // '예'를 선택한 경우, 선택한 날짜의 메모를 삭제합니다.
            let ref = Database.database().reference().child("Memos").child(dateString).child(Auth.auth().currentUser?.uid ?? "").child("memo")
            ref.removeValue { [weak self] error, _ in
                if let error = error {
                    print("Failed to delete memo: \(error)")
                } else {
                    print("Memo deleted.")
                    self?.memoContentTextView.text = ""
                    self?.datesWithMemos.remove(dateString)
                    self?.calendar.reloadData()
                }
            }
        })
        alert.addAction(UIAlertAction(title: "아니오", style: .cancel))
        present(alert, animated: true)
    }

    func addImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage, let user = Auth.auth().currentUser {
            let userId = user.uid
            if let date = currentSelectedDate, let imageData = image.jpegData(compressionQuality: 0.8) {
                let storageRef = Storage.storage().reference().child("Images").child("\(date)/\(UUID().uuidString)")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let ref = Database.database().reference().child("Memos").child(date).child(userId)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if var dict = snapshot.value as? [String: Any] {
                        var imageURLs = dict["imageURLs"] as? [String] ?? []
                        
                        if imageURLs.count < 3 {
                            storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                                if let error = error {
                                    print("Error uploading image: \(error)")
                                } else {
                                    print("이미지 업로드 성공")
                                    storageRef.downloadURL { (url, error) in
                                        if let error = error {
                                            print("Error getting download URL: \(error)")
                                        } else if let url = url {
                                            print("이미지 URL 가져오기 성공: \(url)")
                                            imageURLs.append(url.absoluteString)
                                            dict["imageURLs"] = imageURLs
                                            ref.setValue(dict)
                                            print("이미지 URL 저장 완료: \(url.absoluteString)")
                                        }
                                    }
                                }
                            }
                        } else {
                            print("이미 3개의 이미지가 저장되어 있습니다.")
                        }
                    }
                })
            } else {
                print("날짜를 선택해주세요.")
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func updateDatesWithMemos() {
        guard let uuid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        print("Logged in user's UUID: \(uuid)") // 로그인한 사용자의 UUID를 출력합니다.

        let ref = Database.database().reference().child("Memos")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            self?.datesWithMemos.removeAll() // 먼저 기존의 메모 날짜들을 모두 제거합니다.
            for child in snapshot.children { // 각 날짜에 대해서
                if let childSnapshot = child as? DataSnapshot {
                    for userSnapshot in childSnapshot.children {
                        if let userSnapshot = userSnapshot as? DataSnapshot {
                            print("UUID found in data: \(userSnapshot.key)") // 데이터에서 찾은 UUID를 출력합니다.
                            if userSnapshot.key == uuid {
                                self?.datesWithMemos.insert(childSnapshot.key)
                                print("Memo found on date: \(childSnapshot.key)") // 메모가 있는 날짜를 출력합니다.
                                break
                            }
                        }
                    }
                }
            }
            self?.calendar.reloadData() // 캘린더를 다시 로드하여 메모가 있는 날짜를 강조 표시합니다.
        }
    }
}


extension CalendarMainViewController {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d"
        let selectedDateString = dateFormatter.string(from: date)
        
        // 현재 선택된 날짜를 저장합니다.
        currentSelectedDate = selectedDateString
        
        // 새로운 날짜를 선택할 때마다 이미지 뷰를 초기화합니다.
        imageView1.image = nil
        //imageView1.isHidden = true
        imageView2.image = nil
        //imageView2.isHidden = true
        imageView3.image = nil
        //imageView3.isHidden = true
        // 디버깅 메시지를 출력합니다.
        print("날짜를 선택했습니다: \(selectedDateString)")
    
        let ref = Database.database().reference().child("Memos").child(selectedDateString)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let userId = Auth.auth().currentUser?.uid,
                   childSnapshot.key == userId,
                   let memoData = childSnapshot.value as? [String: Any],
                   let memo = memoData["memo"] as? String {
                    print("Memo data for user \(userId): \(memo)")  // 가져온 메모를 출력합니다.
                    self?.memoContentTextView.text = memo

                    // 추가: 피드백을 가져와서 출력합니다.
                    if let comment = memoData["comment"] as? String {
                        self?.feedbackContentTextView.text = comment
                    }

                    // 수정: imageURLs를 가져옵니다.
                    if let imageURLs = memoData["imageURLs"] as? [String] {
                        // imageView1에 첫 번째 이미지를 설정합니다.
                        if imageURLs.indices.contains(0), let url = URL(string: imageURLs[0]) {
                            self?.imageView1.sd_setImage(with: url, completed: nil)
                            self?.imageView1.isHidden = false
                        }

                        // imageView2에 두 번째 이미지를 설정합니다.
                        if imageURLs.indices.contains(1), let url = URL(string: imageURLs[1]) {
                            self?.imageView2.sd_setImage(with: url, completed: nil)
                            self?.imageView2.isHidden = false
                        }

                        // imageView3에 세 번째 이미지를 설정합니다.
                        if imageURLs.indices.contains(2), let url = URL(string: imageURLs[2]) {
                            self?.imageView3.sd_setImage(with: url, completed: nil)
                            self?.imageView3.isHidden = false
                        }
                    }
                    
                    return
                }
            }
            if let userId = Auth.auth().currentUser?.uid {
                print("No memo for user \(userId) on this date.")  // 이 날짜에 해당 사용자의 메모가 없는 경우 메시지를 출력합니다.
            }
            
            self?.memoContentTextView.text = "해당 날짜에는 메모가 존재하지 않습니다."
            self?.feedbackContentTextView.text = ""  // 피드백 필드를 비웁니다.
        }
    }
}
extension CalendarMainViewController: FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let dateString = dateFormatter.string(from: date)
        return datesWithMemos.contains(dateString) ? UIColor.red : nil
    }
}
