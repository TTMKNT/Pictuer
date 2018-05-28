//
//  ViewController.swift
//  camera
//
//  Created by keisuke on 2018/05/03.
//  Copyright © 2018年 keisuke. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController{

    // プレビュー用のビューとOutlet接続しておく
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var shutterButton: UIButton!
    
    var toggle:Bool = true
    
    // インスタンスの作成
    var session = AVCaptureSession()
    var photoOutputObj = AVCapturePhotoOutput()
    // 通知センターを作る
    let notification = NotificationCenter.default
    // プライバシーと入出力のステータス
    var authStatus:AuthorizedStatus = .authorized
    var inOutStatus:InputOutputStatus = .ready
    //シェアするイメージ
    var shareImage:UIImage?
    // 認証のステータス
    enum AuthorizedStatus {
        case authorized
        case notAuthorized
        case failed
    }
    // 入出力のステータス
    enum InputOutputStatus {
        case ready
        case notReady
        case failed
    }
    
    // ビューが表示された直後に実行
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // セッション実行中ならば中断する
        guard !session.isRunning else {
            return
        }
        // カメラのプライバシー認証確認
        cameraAuth()
        // 入出力の設定
        setupInputOutput()
        // カメラの準備ができているかどうか
        if (authStatus == .authorized)&&(inOutStatus == .ready){
            // プレビューレイヤの設定
            setPreviewLayer()
            // セッション開始
            session.startRunning()
            shutterButton.isEnabled = true
        } else {
            // アラートを出す
            showAlert(appName: "カメラ")
        }
        // デバイスが回転したときに通知するイベントハンドラを設定する
        notification.addObserver(self,
                                 selector: #selector(self.changedDeviceOrientation(_:)),
                                 name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // シャッターボタンで実行する
    @IBAction func takephoto(_ sender: Any) {
        if (authStatus == .authorized)&&(inOutStatus == .ready){
            let captureSetting = AVCapturePhotoSettings()
            captureSetting.flashMode = .auto
            captureSetting.isAutoStillImageStabilizationEnabled = true
            captureSetting.isHighResolutionPhotoEnabled = false
            // キャプチャのイメージ処理はデリゲートに任せる
           photoOutputObj.capturePhoto(with: captureSetting, delegate: self)
        } else {
            // カメラの利用を許可しなかったにも関わらずボタンをタップした（初回起動時のみ）
            showAlert(appName: "カメラ")
        }
    }
    
    //シェアボタンで実行する
    @IBAction func shareAction(_ sender: Any) {
        guard let shareImage = shareImage else {
            return
        }
        //共有する内容
        let activities = [shareImage] as [Any]
        let activityVC = UIActivityViewController(activityItems: activities, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    // カメラのプライバシー認証確認
    func cameraAuth(){
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .notDetermined:
            // 初回起動時
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler: { [unowned self] authorized in
                                            print("初回", authorized.description)
                                            if authorized {
                                                self.authStatus = .authorized
                                            } else {
                                                self.authStatus = .notAuthorized
                                            }})
        case .restricted, .denied:
            authStatus = .notAuthorized
        case .authorized:
            authStatus = .authorized
        }
    }
    
    // 入出力の設定
    func setupInputOutput(){
        //解像度の指定
        session.sessionPreset = AVCaptureSession.Preset.photo
        // 入力の設定
        do {
            //デバイスの取得
           let device = AVCaptureDevice.default(
                AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                for: AVMediaType.video, // ビデオ入力
                position: AVCaptureDevice.Position.back) // カメラの設定
            
            // 入力元
            let input = try AVCaptureDeviceInput(device: device!)
            if session.canAddInput(input){
                session.addInput(input)
            } else {
                print("セッションに入力を追加できなかった")
                return
            }
        } catch  let error as NSError {
            print("カメラがない \(error)")
            return
        }
        
        // 出力の設定
        if session.canAddOutput(photoOutputObj) {
            session.addOutput(photoOutputObj)
        } else {
            print("セッションに出力を追加できなかった")
            return
        }
    }
    
    // プレビューレイヤの設定
    func setPreviewLayer(){
        // プレビューレイヤを作る
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        // previewViewに追加する
        previewView.layer.addSublayer(previewLayer)
    }
    
    @IBAction func changedevice(_ sender: Any) {
        if(toggle){
            ledFlash(flg: true)
            toggle = false
            
        }
        else{
            ledFlash(flg: false)
            toggle = true
        }
    }
    
    func ledFlash(flg: Bool){
        
        let avDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        if avDevice.hasTorch {
            do {
                // torch device lock on
                try avDevice.lockForConfiguration()
                
                if (flg){
                    // flash LED ON
                    avDevice.torchMode = AVCaptureDevice.TorchMode.on
                } else {
                    // flash LED OFF
                    avDevice.torchMode = AVCaptureDevice.TorchMode.off
                }
                
                // torch device unlock
                avDevice.unlockForConfiguration()
                
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    // デバイスの向きが変わったときに呼び出すメソッド
    @objc func changedDeviceOrientation(_ notification :Notification) {
        // photoOutputObj.connectionの回転向きをデバイスと合わせる
        if let photoOutputConnection = self.photoOutputObj.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
    }
    
    
    // プライバシー認証のアラートを表示する
    func showAlert(appName:String){
        let aTitle = appName + "のプライバシー認証"
        let aMessage = "設定＞プライバシー＞" + appName + "で利用を許可してください。"
        let alert = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        // OKボタン（何も実行しない）
        alert.addAction(
            UIAlertAction(title: "OK",style: .default,handler: nil)
        )
        // 設定を開くボタン
        alert.addAction(
            UIAlertAction(
                title: "設定を開く",style: .default,
                handler:  { action in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            })
        )
        // アラートを表示する
        self.present(alert, animated: false, completion:nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

