import UIKit
import Photos
import CoreLocation

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showLocationButton: UIButton!
    @IBOutlet weak var addTextButton: UIButton!
    @IBOutlet weak var textToolbar: UIStackView!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var boldButton: UIButton!
    @IBOutlet weak var italicButton: UIButton!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fontNameButton: UIButton!
    
    // MARK: - Properties
    var selectedImage: UIImage?
    var asset: PHAsset?
    var selectedImageLocation: CLLocation?
    let geocoder = CLGeocoder()
    
    var selectedLabel: UILabel? {
        didSet {
            updateToolbarWithSelectedLabel()
        }
    }
    
    var isTextEditingMode = false {
        didSet {
            textToolbar.isHidden = !isTextEditingMode
            fontNameButton.isHidden = !isTextEditingMode
            if !isTextEditingMode {
                selectedLabel = nil
            }
        }
    }
    
    // Default text properties
    var defaultFontName = "Helvetica"
    var defaultFontSize: CGFloat = 18
    var defaultIsBold = false
    var defaultIsItalic = false
    var defaultTextColor: UIColor = .white
    var defaultTextAlignment: NSTextAlignment = .left
    
    private var textAttributes: [UILabel: TextAttributes] = [:]
    
    private struct TextAttributes {
        var fontName: String
        var fontSize: CGFloat
        var isBold: Bool
        var isItalic: Bool
        var textColor: UIColor
        var alignment: NSTextAlignment
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let asset = asset, let location = asset.location {
            selectedImageLocation = location
        }
    }
    @objc private func deleteSelectedText() {
        guard let labelToDelete = selectedLabel else { return }
        labelToDelete.removeFromSuperview()
        textAttributes.removeValue(forKey: labelToDelete)
        selectedLabel = nil
        isTextEditingMode = false
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }


    private func setupUI() {
        imageView.image = selectedImage
        textToolbar.isHidden = true
        fontNameButton.isHidden = true
        
        addTextButton.addTarget(self, action: #selector(showTextInputAlert), for: .touchUpInside)
        
        fontNameButton.setTitle(defaultFontName, for: .normal)
        fontNameButton.addTarget(self, action: #selector(showFontPicker), for: .touchUpInside)
        
        fontSizeSlider.minimumValue = 8
        fontSizeSlider.maximumValue = 72
        fontSizeSlider.value = Float(defaultFontSize)
    }
    
    // MARK: - Save Functionality
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let imageToSave = captureEditedImage() else {
            showAlert(title: "Hata", message: "Görsel oluşturulamadı")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(title: "Başarılı", message: "Fotoğraf kaydedildi")
                } else {
                    self?.showAlert(title: "Hata", message: error?.localizedDescription ?? "Bilinmeyen hata")
                }
            }
        }
    }
    
    private func captureEditedImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)

        return renderer.image { context in
            imageView.image?.draw(in: imageView.bounds)
            drawRecursiveSubviews(of: self.view)
        }
    }
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputDelete, modifierFlags: [], action: #selector(deleteSelectedText), discoverabilityTitle: "Seçili metni sil")
        ]
    }


    private func drawRecursiveSubviews(of view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel, !label.isHidden {
                drawLabel(label: label)
            } else {
                drawRecursiveSubviews(of: subview)
            }
        }
    }

    private func drawLabel(label: UILabel) {
        guard label.superview != nil, !label.isHidden else { return }
        
        let labelFrame = view.convert(label.frame, to: imageView)
        let attributes = textAttributes[label] ?? TextAttributes(
            fontName: defaultFontName,
            fontSize: defaultFontSize,
            isBold: defaultIsBold,
            isItalic: defaultIsItalic,
            textColor: defaultTextColor,
            alignment: defaultTextAlignment
        )
        
        let font = createFont(
            name: attributes.fontName,
            size: attributes.fontSize,
            isBold: attributes.isBold,
            isItalic: attributes.isItalic
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = attributes.alignment
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: attributes.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        (label.text ?? "").draw(with: labelFrame, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
    }
    
    // MARK: - Text Handling
    @objc func showTextInputAlert() {
        let alert = UIAlertController(title: "Metin Ekle", message: "Metni girin", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Metin" }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ekle", style: .default, handler: { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.addTextLabel(with: text)
        }))
        
        present(alert, animated: true)
    }
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        // Eklenen tüm UILabel’ları kaldır
        for subview in view.subviews {
            if let label = subview as? UILabel {
                label.removeFromSuperview()
            }
        }
    }

    func addTextLabel(with text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = defaultTextColor
        label.textAlignment = defaultTextAlignment
        label.font = createFont(
            name: defaultFontName,
            size: defaultFontSize,
            isBold: defaultIsBold,
            isItalic: defaultIsItalic
        )
        label.sizeToFit()
        label.backgroundColor = .clear
        label.center = view.center
        label.isUserInteractionEnabled = true
        view.addSubview(label)
        
        textAttributes[label] = TextAttributes(
            fontName: defaultFontName,
            fontSize: defaultFontSize,
            isBold: defaultIsBold,
            isItalic: defaultIsItalic,
            textColor: defaultTextColor,
            alignment: defaultTextAlignment
        )
        
        addPanGesture(to: label)
        addTapGestureToLabel(label)
        selectedLabel = label
        isTextEditingMode = true
    }
    
    // MARK: - Font Handling
    private func createFont(name: String, size: CGFloat, isBold: Bool, isItalic: Bool) -> UIFont {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        
        if let font = UIFont(name: name, size: size) {
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
            return UIFont(descriptor: descriptor, size: size)
        }
        return UIFont.systemFont(ofSize: size)
    }
    
    // MARK: - Toolbar Actions
    @IBAction func fontSizeChanged(_ sender: UISlider) {
        guard let label = selectedLabel else { return }
        let newSize = CGFloat(sender.value)
        
        if var attributes = textAttributes[label] {
            attributes.fontSize = newSize
            textAttributes[label] = attributes
            updateLabelFont(label, with: attributes)
        }
    }
    
    @IBAction func boldTapped(_ sender: UIButton) {
        toggleTextAttribute(for: \.isBold, button: sender)
    }
    
    @IBAction func italicTapped(_ sender: UIButton) {
        toggleTextAttribute(for: \.isItalic, button: sender)
    }
    
    @IBAction func colorTapped(_ sender: UIButton) {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    @IBAction func alignmentChanged(_ sender: UISegmentedControl) {
        guard let label = selectedLabel else { return }
        
        let alignment: NSTextAlignment
        switch sender.selectedSegmentIndex {
        case 0: alignment = .left
        case 1: alignment = .center
        case 2: alignment = .right
        default: alignment = .left
        }
        
        if var attributes = textAttributes[label] {
            attributes.alignment = alignment
            textAttributes[label] = attributes
            label.textAlignment = alignment
        }
    }
    
    private func toggleTextAttribute(for keyPath: WritableKeyPath<TextAttributes, Bool>, button: UIButton) {
        guard let label = selectedLabel else { return }
        
        if var attributes = textAttributes[label] {
            attributes[keyPath: keyPath].toggle()
            textAttributes[label] = attributes
            updateLabelFont(label, with: attributes)
            button.tintColor = attributes[keyPath: keyPath] ? .systemBlue : .label
        }
    }
    
    private func updateLabelFont(_ label: UILabel, with attributes: TextAttributes) {
        label.font = createFont(
            name: attributes.fontName,
            size: attributes.fontSize,
            isBold: attributes.isBold,
            isItalic: attributes.isItalic
        )
        label.sizeToFit()
    }
    
    // MARK: - Location Handling
    @IBAction func showLocationTapped(_ sender: UIButton) {
        guard let location = selectedImageLocation else {
            addTextLabel(with: "Konum bilgisi yok")
            return
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.addTextLabel(with: "Konum hatası: \(error.localizedDescription)")
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.addTextLabel(with: "Konum bulunamadı")
                    return
                }

                var locationText = "📍"
                if let city = placemark.locality {
                    locationText += city
                }
                if let country = placemark.country {
                    locationText += locationText.isEmpty ? country : ", \(country)"
                }

                locationText += String(format: "\nEnlem: %.6f\nBoylam: %.6f",
                                       location.coordinate.latitude,
                                       location.coordinate.longitude)

                self.addTextLabel(with: locationText)
            }
        }
    }

    // MARK: - Gestures
    private func addPanGesture(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }
    
    private func addTapGestureToLabel(_ label: UILabel) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        label.addGestureRecognizer(tap)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: self.view)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        gesture.setTranslation(.zero, in: self.view)
    }
    
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedLabel = gesture.view as? UILabel else { return }
        
        if selectedLabel == tappedLabel {
            isTextEditingMode = false
        } else {
            selectedLabel = tappedLabel
            isTextEditingMode = true
        }
    }
    
    // MARK: - Helper Methods
    private func updateToolbarWithSelectedLabel() {
        guard let label = selectedLabel, let attributes = textAttributes[label] else {
            resetToolbarToDefaults()
            return
        }
        
        boldButton.tintColor = attributes.isBold ? .systemBlue : .label
        italicButton.tintColor = attributes.isItalic ? .systemBlue : .label
        fontSizeSlider.value = Float(attributes.fontSize)
        fontNameButton.setTitle(attributes.fontName, for: .normal)
        
        switch attributes.alignment {
        case .left: alignmentSegmentedControl.selectedSegmentIndex = 0
        case .center: alignmentSegmentedControl.selectedSegmentIndex = 1
        case .right: alignmentSegmentedControl.selectedSegmentIndex = 2
        default: alignmentSegmentedControl.selectedSegmentIndex = 0
        }
    }
    
    private func resetToolbarToDefaults() {
        boldButton.tintColor = defaultIsBold ? .systemBlue : .label
        italicButton.tintColor = defaultIsItalic ? .systemBlue : .label
        fontSizeSlider.value = Float(defaultFontSize)
        fontNameButton.setTitle(defaultFontName, for: .normal)
        alignmentSegmentedControl.selectedSegmentIndex = 0
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showFontPicker() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fontPickerVC = storyboard.instantiateViewController(withIdentifier: "FontPickerViewController") as? FontPickerViewController {
            fontPickerVC.delegate = self
            present(fontPickerVC, animated: true, completion: nil)
        } else {
            print("⚠️ FontPickerViewController bulunamadı. Storyboard ID kontrol et.")
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension PhotoDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        updateTextColor(viewController.selectedColor)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        updateTextColor(viewController.selectedColor)
    }
    
    private func updateTextColor(_ color: UIColor) {
        guard let label = selectedLabel else { return }
        
        if var attributes = textAttributes[label] {
            attributes.textColor = color
            textAttributes[label] = attributes
            label.textColor = color
        }
    }
}

// MARK: - FontPickerDelegate
extension PhotoDetailViewController: FontPickerDelegate {
    func fontPicker(_ picker: FontPickerViewController, didSelectFont fontName: String) {
        guard let label = selectedLabel else { return }
        
        if var attributes = textAttributes[label] {
            attributes.fontName = fontName
            textAttributes[label] = attributes
            updateLabelFont(label, with: attributes)
            fontNameButton.setTitle(fontName, for: .normal)
        }
    }
}
