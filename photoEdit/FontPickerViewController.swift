import UIKit

protocol FontPickerDelegate: AnyObject {
    func fontPicker(_ picker: FontPickerViewController, didSelectFont fontName: String)
}

class FontPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    weak var delegate: FontPickerDelegate? //Font seçimi başka bir ViewController’a bildirilecekse bu kullanılacak
    var currentFontName: String = "Helvetica"
    
    let allFonts = UIFont.familyNames.sorted()//Sistem fontlarının isim listesidir
    var filteredFonts: [String] = []
    var favoriteFonts: [String] = []
    
    var isSearching: Bool {
        return !filteredFonts.isEmpty || !(searchBar.text?.isEmpty ?? true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Font Seç"
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        if let savedFavorites = UserDefaults.standard.array(forKey: "Favori Fontlar") as? [String] {
            favoriteFonts = savedFavorites //Uygulama açıldığında daha önce kaydedilen favori fontlar varsa UserDefaults'tan alınır
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    //Eğer section 0: Favori fontlar gösterilir.
   // section 1: Arama yapılıyorsa filteredFonts, değilse tüm fontlar gösterilir.

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return favoriteFonts.count
        } else {
            return isSearching ? filteredFonts.count : allFonts.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "⭐️ Favori Fontlar" : "Tüm Fontlar"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FontCell", for: indexPath) as? FontTableViewCell else {
            return UITableViewCell()
        }
        
        let fontName = indexPath.section == 0 ? favoriteFonts[indexPath.row] : (isSearching ? filteredFonts[indexPath.row] : allFonts[indexPath.row])
        //Hücrede font adı yazılır ve aynı font ile görselleştirilir
        cell.fontNameLabel.text = fontName
        cell.fontNameLabel.font = UIFont(name: fontName, size: 18)
        
        let isFavorite = favoriteFonts.contains(fontName)
        let starImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        cell.favoriteButton.setImage(starImage, for: .normal)
        cell.favoriteButton.tintColor = isFavorite ? .systemYellow : .gray
        
        cell.favoriteButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.favoriteButton.addTarget(self, action: #selector(toggleFavorite(_:)), for: .touchUpInside)
        
        if let index = allFonts.firstIndex(of: fontName) {
            cell.favoriteButton.tag = index
        }
        
        return cell
    }
    //favorileri yıldızlama 
    @objc func toggleFavorite(_ sender: UIButton) {
        let fontName = allFonts[sender.tag]
        
        if let index = favoriteFonts.firstIndex(of: fontName) {
            favoriteFonts.remove(at: index)
        } else {
            favoriteFonts.insert(fontName, at: 0)
        }
        
        UserDefaults.standard.set(favoriteFonts, forKey: "Favori Fontlar")
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFont = indexPath.section == 0 ? favoriteFonts[indexPath.row] : (isSearching ? filteredFonts[indexPath.row] : allFonts[indexPath.row])
        delegate?.fontPicker(self, didSelectFont: selectedFont)
        dismiss(animated: true, completion: nil)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredFonts = allFonts.filter { $0.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
}
