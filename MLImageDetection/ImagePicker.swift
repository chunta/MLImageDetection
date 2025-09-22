//
//  ImagePicker.swift
//  MLImageDetection
//
//  Created by rex on 9/21/25.
//

import UIKit
import PhotosUI
import AVFoundation

/// ImagePickerManager
/// - 支援：
///   - 相機 (UIImagePickerController)
///   - 相簿 (PHPickerViewController)
/// - 使用方式：呼叫 present(from:allowEditing:completion:)
/// - 完成後會回傳 UIImage (主線程)

final class ImagePickerManager: NSObject {
    enum Source {
        case camera
        case photoLibrary
    }

    static let shared = ImagePickerManager()

    private var completion: ((UIImage?) -> Void)?
    private weak var presentingVC: UIViewController?

    private override init() { super.init() }

    // MARK: - Public API

    /// Present image picker
    /// - Parameters:
    ///   - from: UIViewController 用來 present picker
    ///   - source: camera 或 photoLibrary
    ///   - allowEditing: 如果使用 camera（UIImagePickerController）可設定是否允許編輯
    ///   - completion: UIImage? 回調
    func present(from: UIViewController, source: Source, allowEditing: Bool = false, completion: @escaping (UIImage?) -> Void) {
        self.presentationChecksAndPresent(from: from, source: source, allowEditing: allowEditing, completion: completion)
    }

    // MARK: - Internal logic

    private func presentationChecksAndPresent(from: UIViewController, source: Source, allowEditing: Bool, completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        self.presentingVC = from

        switch source {
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                completion(nil)
                return
            }
            checkCameraPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        self.presentCamera(from: from, allowEditing: allowEditing)
                    } else {
                        completion(nil)
                        self.presentSettingsAlert(for: .camera)
                    }
                }
            }

        case .photoLibrary:
            // photo library: use PHPicker (iOS14+)
            checkPhotoLibraryPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        self.presentPhotoPicker(from: from)
                    } else {
                        completion(nil)
                        self.presentSettingsAlert(for: .photoLibrary)
                    }
                }
            }
        }
    }

    // MARK: - Camera

    private func presentCamera(from: UIViewController, allowEditing: Bool) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = allowEditing
        picker.modalPresentationStyle = .fullScreen
        from.present(picker, animated: true)
    }

    // MARK: - Photo Library (PHPicker)

    private func presentPhotoPicker(from: UIViewController) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        from.present(picker, animated: true)
    }

    // MARK: - Permissions

    private func checkCameraPermission(_ handler: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            handler(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                handler(granted)
            }
        case .denied, .restricted:
            handler(false)
        @unknown default:
            handler(false)
        }
    }

    private func checkPhotoLibraryPermission(_ handler: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            handler(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                switch newStatus {
                case .authorized, .limited:
                    handler(true)
                default:
                    handler(false)
                }
            }
        default:
            handler(false)
        }
    }

    // MARK: - Helpers

    private func presentSettingsAlert(for source: Source) {
        guard let vc = presentingVC else { return }
        let title = "Permission Required"
        let message: String
        switch source {
        case .camera:
            message = "請在 設定 > 隱私 > 相機 開啟相機權限"
        case .photoLibrary:
            message = "請在 設定 > 隱私 > 照片 開啟相簿權限"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        })
        vc.present(alert, animated: true)
    }

    private func finish(with image: UIImage?) {
        DispatchQueue.main.async {
            self.completion?(image)
            self.completion = nil
            self.presentingVC = nil
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.finish(with: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let key: UIImagePickerController.InfoKey = picker.allowsEditing ? .editedImage : .originalImage
        var image = info[key] as? UIImage
        // Optional: normalize orientation / resize
        picker.dismiss(animated: true) { [weak self] in
            self?.finish(with: image)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ImagePickerManager: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else {
            finish(with: nil)
            return
        }

        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let img = object as? UIImage {
                    self?.finish(with: img)
                } else {
                    self?.finish(with: nil)
                }
            }
        } else {
            finish(with: nil)
        }
    }
}

/*
 Usage example:

 ImagePickerManager.shared.present(from: self, source: .photoLibrary) { image in
     guard let img = image else { return }
     // use img
 }

 ImagePickerManager.shared.present(from: self, source: .camera, allowEditing: true) { image in
     // use camera image
 }

 Info.plist required keys:
 - NSCameraUsageDescription (for camera)
 - NSPhotoLibraryUsageDescription (for older iOS)
 - NSPhotoLibraryAddUsageDescription (if you save to library)

 Notes:
 - 使用 PHPickerViewController 可避免部分權限複雜性 (iOS 14+)
 - 若需支援多張選取，調整 config.selectionLimit
*/
