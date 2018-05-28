//
//  ExtensionViewController.swift
//  avCapturePhoto
//

//

import Photos

// デリゲート部分を拡張する
extension ViewController:AVCapturePhotoCaptureDelegate {
    
    // 映像をキャプチャする
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // 写真のプライバシー認証をチェックする
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .denied {
            showAlert(appName: "写真")
            return
        }
        
        // Dataを取り出す
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        // Dataから写真イメージを作る
        if let stillImage = UIImage(data: photoData) {
            // アルバムに追加する
            UIImageWriteToSavedPhotosAlbum(stillImage, self, nil, nil)
            //シェアするイメージに代入する
            shareImage = stillImage
        }
    }
}
