//
//  ReaderPrefsViewController.swift
//  KanshuReader
//
//  Created by AC on 8/27/24.
//

import UIKit

protocol ReaderPrefsDelegate: AnyObject {
    func changedScroll(to direction: Direction)
    func changedText(to direction: Direction)
}

class ReaderPrefsViewController: UIViewController {
    
    weak var delegate: ReaderPrefsDelegate?

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillProportionally
        view.axis = .vertical
        view.spacing = 5
        return view
    }()
    
    lazy var scrollDirControl: UISegmentedControl = {
        let horizontalTapped = UIAction(title: "Horizontal", handler: { _ in self.delegate?.changedScroll(to: .horizontal) })
        let verticalTapped = UIAction(title: "Vertical", handler: { _ in self.delegate?.changedScroll(to: .vertical) })
        
        let view = UISegmentedControl(frame: .zero, actions: [horizontalTapped, verticalTapped])
        view.selectedSegmentIndex = 0
        
        return view
    }()
    
    lazy var textDirControl: UISegmentedControl = {
        let horizontalTapped = UIAction(title: "Horizontal", handler: { _ in self.delegate?.changedText(to: .horizontal) })
        let verticalTapped = UIAction(title: "Vertical", handler: { _ in self.delegate?.changedText(to: .vertical) })
        
        let view = UISegmentedControl(frame: .zero, actions: [horizontalTapped, verticalTapped])
        view.selectedSegmentIndex = 0
        
        return view
    }()
    
    init(prefs: [String]? = nil) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        view.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        addSubviews()
        configureUI()
        
        stackView.layoutIfNeeded()
        preferredContentSize = CGSize(width: 300, height: stackView.frame.size.height + 20)
    }
    
    func addSubviews() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(ToggleView(text: "Reader Scroll Direction", view: scrollDirControl))
//        stackView.addArrangedSubview(ToggleView(text: "Text Scanning Direction", view: textDirControl))
    }
    
    func configureUI() {
        configureStackView()
    }
    
    func configureStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
}

class ToggleView: UIView {
    
    lazy var labelView: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var accessoryView: UIView = UIView()
    
    init(text: String, view: UIView) {
        super.init(frame: CGRectZero)

        labelView.text = text
        accessoryView = view
        
        addSubviews()
        configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        addSubview(labelView)
        addSubview(accessoryView)
    }
    
    func configureUI() {
        configureView()
        configureLabelView()
        configureAccessoryView()
    }
    
    func configureLabelView() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelView.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    func configureAccessoryView() {
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
        NSLayoutConstraint.activate([
            accessoryView.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 5),
            accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor),
            accessoryView.leadingAnchor.constraint(equalTo: leadingAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configureView() {
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
