//
//  ReaderViewController.swift
//  KanshuReader
//
//  Created by AC on 12/16/23.
//

import UIKit
import TipKit

protocol Reader: UIViewController {
    var pages: [UIImage] { get set }
    var position: Int { get }
    var currentPage: Page { get set }
    var currentImage: UIImage { get }
}

class ReaderViewController: UIViewController, PageDelegate, TipDelegate, TextRecognizerDelegate, HReaderDelegate {
    
    var book: Book
    
    var tipManager: TipManager?
    var textRecognizer = TextRecognizer()
    var ocrEnabled = false
    var zoomedRect: CGRect? = nil
    var detectVertical = false
    var scrollVertical = false {
        didSet {
            removeReader()
            if(scrollVertical) {
                reader = VReaderViewController(images: reader.pages, position: reader.position, parent: self)
            }
            else { reader = HReaderViewController(images: reader.pages, position: reader.position, parent: self) }
            addReader()
            
            textRecognizer = TextRecognizer()
            textRecognizer.delegate = self
        }
    }
    
    var dictionaryViewController = DictionaryViewController(text: "")

    var boxTipView: TipUIView?
    var dictTipView: TipUIView?
    
    var reader: Reader = HReaderViewController()
    
    lazy var ocrButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "rectangle.and.text.magnifyingglass"), for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderColor = Constants.accentColor.cgColor
        button.layer.borderWidth = 2
        
        button.addTarget(self, action: #selector(didTapOCR), for: .touchUpInside)
        
        return button
    }()
    
    lazy var prefsButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderColor = Constants.accentColor.cgColor
        button.layer.borderWidth = 2
        
        button.addTarget(self, action: #selector(didTapPrefs), for: .touchUpInside)
        
        return button
    }()
    
    lazy var ocrSwitch: UISwitch = {
        let button = UISwitch()
        
        button.tintColor = Constants.accentColor
        button.onTintColor = Constants.accentColor
        
        button.addTarget(self, action: #selector(didTapOCRSwitch(_:)), for: .valueChanged)

        return button
    }()
    
    lazy var ocrView: UIView = {
        let view = UIView()
        
        view.addSubview(ocrButton)
        view.addSubview(prefsButton)
        
        return view
    }()
    
    lazy var backButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 35))
        
        button.setImage(UIImage(systemName: "arrow.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.tintColor = .white
        
        button.addTarget(self, action: #selector(didTapBack(_:)), for: .touchUpInside)
        
        return button
    }()
    
    init(images: [UIImage] = [], book: Book) {
        self.book = book
        
        super.init(nibName: nil, bundle: nil)
        
        textRecognizer.delegate = self
        
        reader = HReaderViewController(images: images, position: Int(book.lastPage), parent: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: ocrView)
        
        configureUI()
        addReader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(book.name == "Sample Tutorial") {
            tipManager = TipManager()
            tipManager?.delegate = self
        }
        else {
            TipManager.disableTips()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tipManager?.startTasks()
    }
    
    func addReader() {
        addChild(reader)
        view.addSubview(reader.view)
        reader.didMove(toParent: self)
    }
    
    func removeReader() {
        reader.willMove(toParent: nil)
        reader.view.removeFromSuperview()
        reader.removeFromParent()
    }
    
    func configureUI() {
        configureOCRButton()
        configurePrefsButton()
    }
    
    func configureOCRButton() {
        ocrButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ocrButton.topAnchor.constraint(equalTo: ocrView.topAnchor),
            ocrButton.bottomAnchor.constraint(equalTo: ocrView.bottomAnchor),
            ocrButton.trailingAnchor.constraint(equalTo: ocrView.trailingAnchor),
            ocrButton.heightAnchor.constraint(equalToConstant: 35),
            ocrButton.widthAnchor.constraint(equalTo: ocrButton.heightAnchor),
        ])
    }
    
    func configurePrefsButton() {
        prefsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            prefsButton.topAnchor.constraint(equalTo: ocrView.topAnchor),
            prefsButton.bottomAnchor.constraint(equalTo: ocrView.bottomAnchor),
            prefsButton.leadingAnchor.constraint(equalTo: ocrView.leadingAnchor),
            prefsButton.trailingAnchor.constraint(equalTo: ocrButton.leadingAnchor, constant: -20),
            prefsButton.heightAnchor.constraint(equalToConstant: 35),
            prefsButton.widthAnchor.constraint(equalTo: prefsButton.heightAnchor)
        ])
    }
    
    func displayOCRTip(_ tip: any Tip) {
        let controller = TipUIPopoverViewController(tip, sourceItem: ocrButton)
        controller.viewStyle = CustomTipViewStyle()
        controller.popoverPresentationController?.passthroughViews = [ocrButton]
        present(controller, animated: true)
    }
    
    func displayBoxTip(_ tip: any Tip) {
        boxTipView = TipUIView(tip)
        if let boxTipView = boxTipView {
            boxTipView.viewStyle = CustomTipViewStyle()
            boxTipView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(boxTipView)
            view.addConstraints([
                boxTipView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                boxTipView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                boxTipView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
    }
    
    func displayDictTip(_ tip: any Tip) {
        dictTipView = TipUIView(tip)
        if let dictTipView = dictTipView {
            dictTipView.viewStyle = CustomTipViewStyle()
            dictTipView.translatesAutoresizingMaskIntoConstraints = false
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let currentWindow = windowScene.windows.first(where: { $0.isKeyWindow })
            {
                currentWindow.addSubview(dictTipView)
                currentWindow.addConstraints([
                    dictTipView.topAnchor.constraint(equalTo: currentWindow.topAnchor),
                    dictTipView.bottomAnchor.constraint(equalTo: currentWindow.centerYAnchor),
                    dictTipView.leadingAnchor.constraint(equalTo: currentWindow.leadingAnchor, constant: 20),
                    dictTipView.trailingAnchor.constraint(equalTo: currentWindow.trailingAnchor, constant: -20)
                ])
            }
        }
    }
    
    func presentDictionary(text: String) {
        dictionaryViewController = DictionaryViewController(text: text)
        if let presentationController = dictionaryViewController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
            presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        self.present(dictionaryViewController, animated: true)
    }
    
    @objc func didTapOCR() {
        if let hReader = reader as? HReaderViewController {
            let image = hReader.currentImage
            zoomedRect = image.getZoomedRect(from: reader.currentPage)
            textRecognizer.requestInitialVision(for: image, with: zoomedRect)
        }
        else if let vReader = reader as? VReaderViewController {
            guard let image = vReader.tableView.screenshot() else { return }
            textRecognizer.requestInitialVision(for: image)
        }
    }
    
    @objc func didTapPrefs() {
        // present popup
        
//        detectVertical = !detectVertical
        scrollVertical = !scrollVertical
    }
    
    @objc func didTapOCRSwitch(_ sender: UISwitch ) {
        detectVertical = sender.isOn
    }
    
    @objc func didTapBack(_ sender: UIButton) {
        book.lastPage = Int64(reader.position)
        book.lastOpened = Date()
        CoreDataManager.shared.updateBook(book: book)
        self.navigationController?.popViewController(animated: true)
    }
    
    func didPerformVision(image: UIImage) {
        if let hReader = reader as? HReaderViewController {
            reader.currentPage.imageView.image = image
        }
        else if let vReader = reader as? VReaderViewController {
            vReader.startVisionMode(image: image)
        }
    }
    
    func didDisplay(tip: any Tip) {
        switch tip{
        case is OCRTip:
            displayOCRTip(tip)
        case is BoxTip:
            displayBoxTip(tip)
        case is DictionaryTip:
            displayDictTip(tip)
        default:
            return
        }
    }
    
    func didDismiss(tip: any Tip) {
        switch tip{
        case is OCRTip:
            if presentedViewController is TipUIPopoverViewController {
                dismiss(animated: true)
            }
        case is BoxTip:
            boxTipView?.removeFromSuperview()
        case is DictionaryTip:
            dictTipView?.removeFromSuperview()
        default:
            return
        }
    }
    
    @discardableResult
    func didTapRegion(location: CGPoint) -> Bool {
        guard let text = textRecognizer.requestFinalVision(for: location, vertical: detectVertical) else { return false }

        self.presentDictionary(text: text)
        
        return true
    }
    
    func didFlipPage() {
        textRecognizer = TextRecognizer()
        textRecognizer.delegate = self
    }
}
