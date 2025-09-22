//
//  ViewController.swift
//  MLImageDetection
//
//  Created by rex on 9/21/25.
//

import UIKit

class ViewController: UIViewController {

    private var imagePicker: ImagePickerManager?
    public var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let button = UIButton(type: .system)
        button.setTitle("Pick Image", for: .normal)
        button.addTarget(self, action: #selector(openPicker), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        
        // 建立 UIImageView
        imageView = UIImageView()
        imageView.layer.borderWidth = 1
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 550),
            imageView.heightAnchor.constraint(equalToConstant: 650),

            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20)
        ])
        
    }

    @objc private func openPicker() {
        ImagePickerManager.shared.present(from: self, source: .photoLibrary) { image in
            guard let img = image else { return }
            //
            self.imageView.image = img
            self.performVisionRequest(image: img)
        }

    }
}
