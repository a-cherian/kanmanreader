//
//  ReaderViewController.swift
//  KanmanReader
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

class ReaderViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    var comic: Comic
    
    var tipManager: TipManager?
    var textRecognizer = TextRecognizer()
    var ocrEnabled = false
    var zoomedRect: CGRect? = nil
    
    var preferences = ReaderPreferences()
    
    var dictionaryViewController = DictionaryViewController(text: "")
    var reader: Reader = HReaderViewController()
    
    var prefsViewController: ReaderPrefsViewController = {
        let controller = ReaderPrefsViewController()
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.permittedArrowDirections = .up
        return controller
    }()
    
    var ocrTipView: TipUIView?
    var boxTipView: TipUIView?
    var dictTipView: TipUIView?
    
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
    
    lazy var ocrView: UIView = {
        let view = UIView()
        
        view.addSubview(prefsButton)
        view.addSubview(UIView())
        
        return view
    }()
    
    lazy var backButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 35))
        
        button.setImage(UIImage(systemName: "arrow.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.baseForegroundColor = Constants.accentColor
        button.configuration? = config
        
        button.addTarget(self, action: #selector(didTapBack(_:)), for: .touchUpInside)
        
        return button
    }()
    
    init(images: [UIImage] = [], comic: Comic) {
        self.comic = comic
        
        super.init(nibName: nil, bundle: nil)
        
        
        preferences = ReaderPreferences(from: comic.preferences)
        if preferences.scrollDirection == .horizontal {
            reader = HReaderViewController(images: images, position: Int(comic.lastPage), parent: self)
        }
        else if preferences.scrollDirection == .vertical {
            reader = VReaderViewController(images: images, position: Int(comic.lastPage), parent: self)
        }
        
        textRecognizer.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: prefsButton)
        
        prefsViewController.popoverPresentationController?.delegate = self
        prefsViewController.delegate = self
        
        configureUI()
        addReader()
        addGestureRecognizers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tipManager?.startTasks()
        NotificationCenter.default.addObserver(self, selector: #selector(closeComic), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(comic.isTutorial || !TipManager.hasStartedTips()) {
            tipManager = TipManager()
            tipManager?.delegate = self
        }
        else {
            TipManager.disableTips()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        closeComic()
    }
    
    func addReader() {
        addChild(reader)
        view.addSubview(reader.view)
        configureReader()
        reader.didMove(toParent: self)
    }
    
    func removeReader() {
        reader.willMove(toParent: nil)
        reader.view.removeFromSuperview()
        reader.removeFromParent()
    }
    
    func configureUI() {
        configurePrefsButton()
    }
    
    func configureReader() {
        reader.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reader.view.topAnchor.constraint(equalTo: view.topAnchor),
            reader.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            reader.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reader.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func configurePrefsButton() {
        prefsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            prefsButton.topAnchor.constraint(equalTo: ocrView.topAnchor),
            prefsButton.bottomAnchor.constraint(equalTo: ocrView.bottomAnchor),
            prefsButton.trailingAnchor.constraint(equalTo: ocrView.trailingAnchor),
            prefsButton.heightAnchor.constraint(equalToConstant: 35),
            prefsButton.widthAnchor.constraint(equalTo: prefsButton.heightAnchor)
        ])
    }
    
    func addGestureRecognizers() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didTapOCR(_:)))
        longPressGesture.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPressGesture)
    }
    
    func displayOCRTip(_ tip: any Tip) {
        prefsButton.isUserInteractionEnabled = false
        ocrTipView = TipUIView(tip)
        if let ocrTipView = ocrTipView {
            ocrTipView.viewStyle = BorderTipViewStyle()
            ocrTipView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(ocrTipView)
            view.addConstraints([
                ocrTipView.topAnchor.constraint(equalTo: view.centerYAnchor),
                ocrTipView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ocrTipView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                ocrTipView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
    }
    
    func displayBoxTip(_ tip: any Tip) {
        boxTipView = TipUIView(tip)
        if let boxTipView = boxTipView {
            boxTipView.viewStyle = BorderTipViewStyle()
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
            dictTipView.viewStyle = BorderTipViewStyle()
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
            presentationController.prefersEdgeAttachedInCompactHeight = true
            presentationController.prefersGrabberVisible = true
            presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        self.present(dictionaryViewController, animated: true)
    }
    
    @objc func didTapOCR(_ sender: UILongPressGestureRecognizer) {
        if let hReader = reader as? HReaderViewController {
            let image = hReader.currentImage
            zoomedRect = image.getZoomedRect(from: reader.currentPage)
            textRecognizer.requestInitialVision(for: image, with: zoomedRect)
            hReader.currentPage.didSingleTap(sender)
        }
        else if let vReader = reader as? VReaderViewController {
            guard let image = vReader.tableView.screenshot() else { return }
            textRecognizer.requestInitialVision(for: image)
            vReader.didSingleTap(sender)
        }
    }
    
    @objc func didTapPrefs() {
        prefsViewController.updatePreferences(with: preferences)
        if let pvc = prefsViewController.popoverPresentationController {
            pvc.permittedArrowDirections = [.up]
            pvc.delegate = self
            pvc.sourceRect = prefsButton.frame
            pvc.sourceView = prefsButton
            
            if(!isModal(prefsViewController)) {
                prefsButton.animateBackgroundFlash()
                self.present(prefsViewController, animated: true)
            }
        }
    }
    
    @objc func didTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func closeComic() {
        comic.lastPage = Int64(reader.position)
        comic.lastOpened = Date()
        comic.preferences = preferences.string
        CoreDataManager.shared.updateComic(comic: comic)
    }
    
    func isModal(_ vc: UIViewController) -> Bool {
        return vc.presentingViewController?.presentedViewController == vc
            || (vc.navigationController != nil && vc.navigationController?.presentingViewController?.presentedViewController == vc.navigationController)
            || vc.tabBarController?.presentingViewController is UITabBarController
    }
}






extension ReaderViewController: PageDelegate, TipDelegate, TextRecognizerDelegate, HReaderDelegate, ReaderPrefsDelegate {
    func didPerformVision(image: UIImage) {
        if let hReader = reader as? HReaderViewController {
            hReader.currentPage.imageView.image = image
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
            ocrTipView?.removeFromSuperview()
            prefsButton.isUserInteractionEnabled = true
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
        guard let text = textRecognizer.requestFinalVision(for: location, textDirection: preferences.textDirection) else { return false }

        self.presentDictionary(text: text)
        
        return true
    }
    
    func didFlipPage() {
        textRecognizer = TextRecognizer()
        textRecognizer.delegate = self
    }
    
    func changedScroll(to direction: Direction) {
        switch(direction) {
        case .horizontal:
            preferences.scrollDirection = .horizontal
        case .vertical:
            preferences.scrollDirection = .vertical
        }
        
        removeReader()
        if preferences.scrollDirection == .vertical {
            reader = VReaderViewController(images: reader.pages, position: reader.position, parent: self)
        }
        else if preferences.scrollDirection == .horizontal {
            reader = HReaderViewController(images: reader.pages, position: reader.position, parent: self)
        }
        addReader()
        
        textRecognizer = TextRecognizer()
        textRecognizer.delegate = self
    }
    
    func changedText(to direction: Direction) {
        switch(direction) {
        case .horizontal:
            preferences.textDirection = .horizontal
        case .vertical:
            preferences.textDirection = .vertical
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
