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
        picker.delegate = self//Fotoğraf seçildiğinde ya da iptal edildiğinde bu ViewController'ın bilgilendirilmesini sağlar
        picker.sourceType = .photoLibrary //Fotoğraf albümünden seçim yapılacak
        picker.mediaTypes = ["public.image"]
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }//Seçilen resim UIImage tipinde alınır. Alamazsa fonksiyon sonlanır
        let asset = info[.phAsset] as? PHAsset//Seçilen resmin metadata bilgileri PHAsset ile alınır (örneğin konum, tarih, vs.)
        
       // Seçilen resim ve PHAsset nesnesi detay ekranına gönderilir.
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
