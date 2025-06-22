//
//  ReaderViewController.swift
//  KanmanReader
//
//  Created by AC on 12/16/23.
//

import UIKit
import TipKit

protocol Reader: UIViewController {
    var urls: [URL] { get set }
    var position: Int { get }
    var currentPage: Page { get set }
    var currentImage: UIImage? { get }
}

class ReaderViewController: UIViewController, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate {    
    var comic: Comic
    
    var tipManager: TipManager?
    
    var preferences = ReaderPreferences()
    
    var dictionaryViewController = DictionaryViewController(text: "")
    var reader: Reader = HReaderViewController()
    var selectionView: Selection?
    var initialLocation: CGPoint?
    
    var prefsViewController: ReaderPrefsViewController = {
        let controller = ReaderPrefsViewController()
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.permittedArrowDirections = .up
        return controller
    }()
    
    var ocrTipView: TipUIView?
    var dictTipView: TipUIView?
    
    lazy var prefsButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderColor = UIColor.accent.cgColor
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
        config.baseForegroundColor = .accent
        button.configuration? = config
        
        button.addTarget(self, action: #selector(didTapBack(_:)), for: .touchUpInside)
        
        return button
    }()
    
    init(urls: [URL], comic: Comic) {
        self.comic = comic
        
        super.init(nibName: nil, bundle: nil)
        
        
        preferences = ReaderPreferences(from: comic.preferences)
        if preferences.scrollDirection == .horizontal {
            reader = HReaderViewController(urls: urls, position: Int(comic.lastPage), parent: self)
        }
        else if preferences.scrollDirection == .vertical {
            reader = VReaderViewController(urls: urls, position: Int(comic.lastPage), parent: self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        title = "\(comic.lastPage + 1) / \(comic.totalPages)"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: prefsButton)
        
        prefsViewController.popoverPresentationController?.delegate = self
        prefsViewController.delegate = self
        
        configureUI()
        addReader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tipManager?.startTasks()
        navigationController?.setToolbarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(updateComic), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if comic.isTutorial || !TipManager.hasStartedTips() {
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
        updateComic()
    }
    
    func addReader() {
        addChild(reader)
        view.addSubview(reader.view)
        configureReader()
        reader.didMove(toParent: self)
        addGestureRecognizers()
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
        let dragGesture = UILongPressGestureRecognizer(target: self, action: #selector(didDrag(_:)))
        dragGesture.delegate = self;
        dragGesture.minimumPressDuration = 0.1
        dragGesture.allowableMovement = 10
        dragGesture.cancelsTouchesInView = true
        reader.view.addGestureRecognizer(dragGesture);
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
    
    @objc func didTapPrefs() {
        prefsViewController.updatePreferences(with: preferences)
        if let pvc = prefsViewController.popoverPresentationController {
            pvc.permittedArrowDirections = [.up]
            pvc.delegate = self
            pvc.sourceRect = prefsButton.frame
            pvc.sourceView = prefsButton
            
            if !isModal(prefsViewController) {
                prefsButton.animateBackgroundFlash()
                self.present(prefsViewController, animated: true)
            }
        }
    }
    
    @objc func didTapBack(_ sender: UIButton) {
        ComicFileManager.clearReading()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func updateComic() {
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






extension ReaderViewController: TipDelegate, ReaderDelegate, ReaderPrefsDelegate {
    func didDisplay(tip: any Tip) {
        switch tip{
        case is OCRTip:
            displayOCRTip(tip)
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
        case is DictionaryTip:
            dictTipView?.removeFromSuperview()
        default:
            return
        }
    }
    
    @objc func didDrag(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let mainView = reader.view;
        var posView = reader.view;
        if reader is HReaderViewController {
            posView = reader.currentPage.zoomableView.imageView;
        }
        
        let location = gestureRecognizer.location(in: posView)
        let start = initialLocation ?? location
        let translation = CGPoint(x: location.x - start.x, y: location.y - start.y)
        let p1 = CGPoint(x: location.x - translation.x,
                            y: location.y - translation.y)
        let p2 = gestureRecognizer.location(in: posView)
        let minX = min(p1.x, p2.x)
        let minY = min(p1.y, p2.y)
        let size = CGSize(width: abs(translation.x), height: abs(translation.y))
        let region = CGRect(origin: CGPoint(x: minX, y: minY), size: size)
        let selectionRect = posView?.convert(region, to: mainView) ?? region

        switch gestureRecognizer.state {
        case .began:
            initialLocation = gestureRecognizer.location(in: posView)
            selectionView = Selection(frame: selectionRect)
            mainView?.addSubview(selectionView!)
        case .changed:
            selectionView?.frame = selectionRect;
        case .ended, .cancelled:
            selectionView?.removeFromSuperview();
            selectionView = nil
            initialLocation = nil
            Task { @MainActor in
                await didFrameRegion(rect: region, in: reader)
            }
        default:
            break
        }
    }
    
    @discardableResult
    func didFrameRegion(rect: CGRect, in reader: Reader) async -> Bool {
        var text = ""
        
        if let hReader = reader as? HReaderViewController,  let image = hReader.currentImage {
            text = await image.requestVision(in: rect)
        }
        else if let vReader = reader as? VReaderViewController {
            guard let image = vReader.tableView.screenshot() else { return false }
            text = await image.requestVision(in: rect)
        }
        
        self.presentDictionary(text: text)
        
        return true
    }
    
    func didFlipPage() {
        title = "\(reader.position + 1) / \(comic.totalPages)"
    }
    
    func changedScroll(to direction: Direction) {
        switch(direction) {
        case .horizontal:
            preferences.scrollDirection = .horizontal
        case .vertical:
            preferences.scrollDirection = .vertical
        }
       
        let lastPosition = reader.position
        removeReader()
        if preferences.scrollDirection == .vertical {
            reader = VReaderViewController(urls: reader.urls, position: lastPosition, parent: self)
        }
        else if preferences.scrollDirection == .horizontal {
            reader = HReaderViewController(urls: reader.urls, position: lastPosition, parent: self)
        }
        addReader()
    }
    
    func toggleScroll(enabled: Bool) {
        if let hReader = reader as? HReaderViewController {
            hReader.dataSource = enabled ? hReader : nil
            hReader.currentPage.zoomableView.scrollView.isScrollEnabled = enabled
        }
        if let vReader = reader as? VReaderViewController {
            vReader.tableView.isScrollEnabled = enabled
            for case let cell as ImageCell in vReader.tableView.visibleCells {
                cell.zoomableView.scrollView.isScrollEnabled = enabled
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
