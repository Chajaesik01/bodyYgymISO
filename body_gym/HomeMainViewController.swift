//
//  HomeMainViewController.swift
//  body_gym
//
//  Created by 차재식 on 1/26/24.
//

import UIKit
import AVFoundation
import FirebaseStorage


class HomeMainViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 상단의 ImageView를 생성하고 설정을 합니다.
        let qrImageView = UIImageView(image: UIImage(named: "ic_qr_code_scanner_24"))
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrImageView)
        
        // QR 코드 이미지에 탭 제스처를 추가합니다.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(startScanning))
        qrImageView.isUserInteractionEnabled = true
        qrImageView.addGestureRecognizer(tapGestureRecognizer)
        
        // QR 코드 스캔 세션을 초기화합니다.
        captureSession = AVCaptureSession()
        
        // '기구사용법' 버튼을 생성하고 설정을 합니다.
        let guideButton = UIButton()
        guideButton.setTitle("기구사용법", for: .normal)
        guideButton.setTitleColor(.black, for: .normal)
        guideButton.addTarget(self, action: #selector(openGuide), for: .touchUpInside)
        guideButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideButton)
        
        // 가운데 ImageView를 생성하고 설정을 합니다.
        let centerImageView = UIImageView()
        centerImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerImageView)
        
        // Firebase Storage에서 이미지를 가져옵니다.
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("images/mainlogo.png")
        
        // 이미지를 다운로드하여 centerImageView에 설정합니다.
        imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("이미지 다운로드에 실패했습니다: \(error.localizedDescription)")
            } else if let data = data {
                centerImageView.image = UIImage(data: data)
            }
        }
        
        // AutoLayout 설정
        NSLayoutConstraint.activate([
            qrImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            qrImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            qrImageView.heightAnchor.constraint(equalTo: guideButton.heightAnchor),
            qrImageView.widthAnchor.constraint(equalTo: guideButton.heightAnchor),
            
            guideButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            guideButton.trailingAnchor.constraint(equalTo: qrImageView.leadingAnchor, constant: -8),
            
            centerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    @objc func startScanning() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined: // 사용자가 아직 카메라에 대한 권한을 설정하지 않았을 때
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                }
            }
        case .restricted, .denied: // 사용자가 카메라에 접근하는 것을 거부했을 때
            self.showCameraAccessAlert()
        case .authorized: // 사용자가 이미 카메라 접근을 허용했을 때
            self.setupCaptureSession()
        @unknown default:
            fatalError("카메라 접근 권한에 대한 새로운 케이스가 추가되었습니다.")
        }
    }
func setupCaptureSession() {
    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
        print("카메라를 사용할 수 없습니다.")
        return
    }
    
    let videoInput: AVCaptureDeviceInput
    
    do {
        videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
        print("카메라를 사용할 수 없습니다.")
        return
    }
    
    if captureSession.canAddInput(videoInput) {
        captureSession.addInput(videoInput)
    } else {
        print("QR 코드 스캔을 시작할 수 없습니다.")
        return
    }
    
    let metadataOutput = AVCaptureMetadataOutput()
    
    if captureSession.canAddOutput(metadataOutput) {
        captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    } else {
        print("QR 코드 스캔을 시작할 수 없습니다.")
        return
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.layer.bounds
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)
    
    captureSession.startRunning()
}


    
    func showCameraAccessAlert() {
        let alertController = UIAlertController(title: "카메라 접근 권한이 필요합니다", message: "QR 코드를 스캔하기 위해서는 카메라 접근 권한이 필요합니다. 허용하지 않으면 QR 코드 스캔 기능을 사용할 수 없습니다 설정 메뉴에서 권한을 허용해주세요.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // '기구사용법' 버튼을 탭했을 때 호출되는 메소드입니다.
    @objc func openGuide() {
        if let url = URL(string: "https://m.blog.naver.com/body_y_gym_gogang?tab=1") {
            UIApplication.shared.open(url)
        }
    }
}



// 광고 뷰를 생성하고 설정을 합니다.
/*
let adView = GADBannerView(adSize: kGADAdSizeBanner)
adView.adUnitID = "ca-app-pub-3940256099942544/6300978111"
adView.rootViewController = self
adView.translatesAutoresizingMaskIntoConstraints = false
layout.addArrangedSubview(adView)
*/
