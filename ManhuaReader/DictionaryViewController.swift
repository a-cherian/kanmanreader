//
//  DictionaryViewController.swift
//  ManhuaReader
//
//  Created by AC on 12/19/23.
//

import UIKit

class DictionaryViewController: UIViewController {
    
    lazy var ocrTextView: UITextView = {
        let textView = UITextView()
        textView.text = "我今天晚上吃了晚飯"
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.textAlignment = .left
        textView.font = Constants.zhFontRegular
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
//        textView.tokenizer = nil
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapWords(_:)))
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }()
    
    lazy var dictionaryLabel: UITextView = {
        let textView = UITextView()
        textView.text = "\n今天: today"
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.textAlignment = .left
        textView.font = Constants.zhFontRegular
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
//        textView.refreshControl?.contentVerticalAlignment
        return textView
    }()
    
    lazy var copyButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "list.clipboard.fill"), for: .normal)
        button.tintColor = .black
        button.showsTouchWhenHighlighted = true

        button.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)
        
        return button
    }()
    
    init(text: String) {
        super.init(nibName: nil, bundle: nil)
        ocrTextView.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layoutMargins = UIEdgeInsets(top: 50, left: 5, bottom: 50, right: 5)
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(ocrTextView)
        view.addSubview(dictionaryLabel)
        view.addSubview(copyButton)
    }
    
    func configureUI() {
        configureOCRTextView()
        configureDictionaryLabel()
        configureCopyButton()
    }
    
    func configureOCRTextView() {
        ocrTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ocrTextView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            ocrTextView.bottomAnchor.constraint(equalTo: dictionaryLabel.topAnchor),
            ocrTextView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            ocrTextView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
        ocrTextView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        ocrTextView.sizeToFit()
    }
    
    func configureDictionaryLabel() {
        dictionaryLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dictionaryLabel.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            dictionaryLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            dictionaryLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
        dictionaryLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
    
    func configureCopyButton() {
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            copyButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            copyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            copyButton.heightAnchor.constraint(equalToConstant: 45),
            copyButton.widthAnchor.constraint(equalTo: copyButton.heightAnchor)
        ])
    }
    
    @objc func didTapCopy() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = ocrTextView.text
    }
    
    @objc func didTapWords(_ tapGesture: UITapGestureRecognizer) {
        let point = tapGesture.location(in: ocrTextView)
          if let detectedWord = getWordAtPosition(point)
          {
              ocrTextView.attributedText = generateAttributedString(with: detectedWord, targetString: ocrTextView.text)
          }
    }
    
    func generateAttributedString(with searchTerm: String, targetString: String) -> NSAttributedString? {

        let attributedString = NSMutableAttributedString(string: targetString)
        attributedString.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontRegular, range: NSRange(location: 0, length: targetString.count))
    
        do {
            let regex = try NSRegularExpression(pattern: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current), options: .caseInsensitive)
            let range = NSRange(location: 0, length: targetString.utf16.count)
            for match in regex.matches(in: targetString.folding(options: .diacriticInsensitive, locale: .current), options: .withTransparentBounds, range: range) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontBold, range: match.range)
                attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: Constants.lightBlueColor, range: match.range)
            }
            return attributedString
        } catch {
            NSLog("Error creating regular expresion: \(error)")
            return nil
        }
    }
    
    private final func getWordAtPosition(_ point: CGPoint) -> String?{
        if let textPosition = ocrTextView.closestPosition(to: point)
        {
            if let range = ocrTextView.tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: UITextDirection(rawValue: 1))
            {
                return ocrTextView.text(in: range)
            }
        }
        return nil
    }
}
