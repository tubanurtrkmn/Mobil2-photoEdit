//
//  FontTableViewCell.swift
//  photoEdit
//
//  Created by Tubanur Türkmen on 9.05.2025.
//

//Bir tablo görünümünde (UITableView) her bir hücrede yazı tipi ismi (fontNameLabel) ve yanında bir "favorilere ekle" butonu (favoriteButton) göstermek
import UIKit

class FontTableViewCell: UITableViewCell {
    @IBOutlet weak var fontNameLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
}
