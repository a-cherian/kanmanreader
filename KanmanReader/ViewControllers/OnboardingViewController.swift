//
//  OnboardingViewController.swift
//  KanmanReader
//
//  Created by AC on 8/30/24.
//

import UIKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let pages: [UIViewController] = [OnboardingPageViewController(title: "Welcome to Kanman Reader!\n欢迎来到看漫阅读器！",
                                                                  imageName: "Onboard_1",
                                                                  text: "Import manhua in CBZ/CBR/ZIP/RAR formats"),
                                     OnboardingPageViewController(title: "Seamlessly read manhua",
                                                                  imageName: "Onboard_2",
                                                                  text: "Scan and extract Chinese text at any time"),
                                     OnboardingPageViewController(title: "Expand your knowledge",
                                                                  imageName: "Onboard_3",
                                                                  text: "Look up English definitions for unfamiliar Chinese words with one tap"),
                                     SampleTipViewController()]
    
    lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        
        control.addTarget(self, action: #selector(didTapPageControl(_:)), for: .valueChanged)
        control.currentPageIndicatorTintColor = .black
        control.pageIndicatorTintColor = .systemGray2
        control.numberOfPages = pages.count
        control.currentPage = 0
        
        return control
    }()
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        
        button.setTitle("Skip", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        
        button.addTarget(self, action: #selector(didSkip(_:)), for: .touchUpInside)
        
        return button
    }()
    
    required init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setViewControllers([pages[0]], direction: .forward, animated: true)
        self.dataSource = self
        self.delegate = self
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(pageControl)
        view.addSubview(skipButton)
    }
    
    func configureUI() {
        configurePageControl()
        configureSkipButton()
    }
    
    func configurePageControl() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.widthAnchor.constraint(equalTo: view.widthAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    func configureSkipButton() {
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 10),
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            skipButton.widthAnchor.constraint(equalToConstant: 50),
            skipButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func didTapPageControl(_ sender: UIPageControl) {
        setViewControllers([pages[sender.currentPage]], direction: .forward, animated: true, completion: nil)
    }
    
    @objc func didSkip(_ sender: UIPageControl) {
        dismiss(animated: true)
    }
    
    func shouldPresentSample() -> Bool {
        return (pages[pages.count - 1] as? SampleTipViewController)?.shouldPresentSample ?? false
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = pages.firstIndex(of: viewController) ?? 0

        if(currentIndex - 1 >= 0) {
            return pages[currentIndex - 1]
        }
        else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        if(currentIndex + 1 < pages.count) {
            return pages[currentIndex + 1]
        }
        else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard let viewControllers = pageViewController.viewControllers else { return }
        guard let currentIndex = pages.firstIndex(of: viewControllers[0]) else { return }
        
        for view in view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.bounces = currentIndex != 0 && currentIndex < pages.count - 1
            }
        }
        
        pageControl.currentPage = currentIndex
    }
}





class OnboardingPageViewController: UIViewController {
    lazy var titleView: UILabel = {
        let label = UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize * 1.25)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        
        return view
    }()
    
    lazy var labelView: UILabel = {
        let label = UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        return label
    }()
    
    init(title: String = "", imageName: String = "", text: String = "") {
        super.init(nibName: nil, bundle: nil)
        
        titleView.text = title
        labelView.text = text
        if(UIDevice.current.userInterfaceIdiom == .pad) {
            setImage(UIImage(named: "iPad_" + imageName))
        }
        else {
            setImage(UIImage(named: "iPhone_" + imageName))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(titleView)
        view.addSubview(imageView)
        view.addSubview(labelView)
    }
    
    func configureUI() {
        configureTitleView()
        configureImageView()
        configureLabelView()
    }
    
    func configureTitleView() {
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20),
            titleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleView.heightAnchor.constraint(equalToConstant: 100),
            titleView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100)
        ])
    }
    
    func configureImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 10),
//            imageView.bottomAnchor.constraint(equalTo: labelView.topAnchor, constant: 50),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            imageView.heightAnchor.constraint(greaterThanOrEqualTo: imageView.widthAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -25)
        ])
    }
    
    func configureLabelView() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            labelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            labelView.heightAnchor.constraint(equalToConstant: 100),
            labelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            labelView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100)
        ])
    }
    
    func setImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        imageView.image = image;
        let aspectRatio = image.size.height / image.size.width
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio)
        ])
    }
}





class SampleTipViewController: UIViewController {
    var shouldPresentSample = false
    
    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var titleView: UILabel = {
        let label = UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize * 1.25)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.text = "Check out a sample file to try it out for yourself!"
        
        return label
    }()
    
    lazy var buttonView: UIButton = {
        let button = UIButton()
        
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderColor = UIColor.accent.cgColor
        button.layer.borderWidth = 2
        button.setTitle("Go to tutorial", for: .normal)
        
        button.addTarget(self, action: #selector(didTapSample), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(containerView)
        containerView.addSubview(titleView)
        containerView.addSubview(buttonView)
    }
    
    func configureUI() {
        configureContainerView()
        configureTitleView()
        configureButtonView()
    }
    
    func configureTitleView() {
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleView.heightAnchor.constraint(equalToConstant: 100),
            titleView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -100)
        ])
    }
    
    func configureButtonView() {
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buttonView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonView.heightAnchor.constraint(equalToConstant: 50),
            buttonView.widthAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    func configureContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 175),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }
    
    @objc func didTapSample() {
        shouldPresentSample = true
        dismiss(animated: true)
    }
}
