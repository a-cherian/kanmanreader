//
//  ReaderViewController.swift
//  KanshuReader
//
//  Created by AC on 12/16/23.
//

import UIKit
import TipKit

class ReaderViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PageDelegate, TipDelegate, TextRecognizerDelegate {
    var pages: [UIImage] = []
    var vertReader = VertReaderViewController(position: 0)
    var currentPage: Page = Page()
    var pendingPage: Page = Page()
    var position = 0
    var book: Book
    
    var tipManager: TipManager?
    var textRecognizer = TextRecognizer()
    var ocrEnabled = false
    var zoomedRect: CGRect? = nil
    var detectVertical = false
    var scrollVertical = false
    
    var dictionaryViewController = DictionaryViewController(text: "")
//
    var boxTipView: TipUIView?
    var dictTipView: TipUIView?
    
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
        self.position = Int(book.lastPage)
        self.book = book
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        
        textRecognizer.delegate = self
        
        pages = images
        currentPage = createPage(position: position)
        setViewControllers([currentPage], direction: .forward, animated: true)
        self.dataSource = self
        self.delegate = self
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
    
    func createPage(position: Int) -> Page {
        let newPage = Page()
        newPage.setImage(pages[position])
        newPage.position = position
        newPage.delegate = self
        
        return newPage
    }
    
    @objc func didTapOCR() {
        ocrEnabled = true
        
        let image = pages[position]
        zoomedRect = image.getZoomedRect(from: currentPage)
        textRecognizer.requestInitialVision(for: image, with: zoomedRect)
    }
    
    @objc func didTapPrefs() {
        // present popup
        
        detectVertical = !detectVertical
        scrollVertical = !scrollVertical
        
        if(scrollVertical) {
            vertReader = VertReaderViewController(position: position)
            setViewControllers([vertReader], direction: .forward, animated: false)
            self.delegate = nil
            self.dataSource = nil
        }
        else {
            currentPage = createPage(position: vertReader.position)
            setViewControllers([currentPage], direction: .forward, animated: false)
            self.delegate = self
            self.dataSource = self
        }
        
        print("prefs")
    }
    
    @objc func didTapOCRSwitch(_ sender: UISwitch ) {
        detectVertical = sender.isOn
    }
    
    @objc func didTapBack(_ sender: UIButton) {
        book.lastPage = Int64(position)
        book.lastOpened = Date()
        CoreDataManager.shared.updateBook(book: book)
        self.navigationController?.popViewController(animated: true)
    }
    
    func didPerformVision(image: UIImage) {
        currentPage.imageView.image = image
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
    
    func didTapRegion(location: CGPoint) -> Bool {
        guard let zoomedRect = zoomedRect else { return false }
        if !(zoomedRect.contains(location)) { return false }
        
        guard let text = textRecognizer.requestFinalVision(for: location, vertical: detectVertical) else { return false }

        self.presentDictionary(text: text)
        
        return true
    }
}





extension ReaderViewController {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if(position - 1 >= 0) {
            let previousPage = createPage(position: position - 1)
            return previousPage
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if(position + 1 < pages.count)
        {
            let nextPage = createPage(position: position + 1)
            return nextPage
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingPage = pendingViewControllers[0] as! Page
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if(completed) {
            currentPage = pendingPage
            position = currentPage.position
        }
    }
}
