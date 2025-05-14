//
//  PhotoSelectViewController.swift
//  photoEdit
//
//  Created by Tubanur Türkmen on 9.05.2025.
//


import UIKit
import Photos

class PhotoSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var uploadPhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    
    
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        let asset = info[.phAsset] as? PHAsset
        
        if let detailVC = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController {
            detailVC.selectedImage = image
            detailVC.asset = asset
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
