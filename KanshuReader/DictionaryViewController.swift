//
//  DictionaryViewController.swift
//  KanshuReader
//
//  Created by AC on 12/19/23.
//

import UIKit

class DictionaryViewController: UIViewController, UITextViewDelegate {
    
    var searchLimit = 8
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = .white
        return view
    }()
    
    lazy var ocrTextView: UITextView = {
        let textView = UITextView()
        textView.text = ""
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.textAlignment = .left
        textView.font = Constants.zhFontRegularLarge
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapWords(_:)))
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }()
    
    lazy var dictionaryTextView: UITextView = {
        let textView = UITextView()
        textView.text = ""
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.textAlignment = .left
        textView.font = Constants.zhFontRegularSmall
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
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
        ocrTextView.text = "\n" + text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.accentColor
        view.layoutMargins = UIEdgeInsets(top: 50, left: 5, bottom: 50, right: 5)
        
        DictionaryTip.dictOpened = true
        BoxTip.tipEnabled = false
        
        addSubviews()
        configureUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DictionaryTip.dictOpened = false
    }
    
    func addSubviews() {
        view.addSubview(scrollView)
        view.addSubview(copyButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(ocrTextView)
        contentView.addSubview(dictionaryTextView)
    }
    
    func configureUI() {
        configureScrollView()
        configureContentView()
        configureCopyButton()
        configureOCRTextView()
        configureDictionaryLabel()
    }
    
    func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    func configureContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func configureOCRTextView() {
        ocrTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ocrTextView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            ocrTextView.bottomAnchor.constraint(equalTo: dictionaryTextView.topAnchor),
            ocrTextView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            ocrTextView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
        ocrTextView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        ocrTextView.sizeToFit()
    }
    
    func configureDictionaryLabel() {
        dictionaryTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dictionaryTextView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            dictionaryTextView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            dictionaryTextView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
        dictionaryTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
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
        
        guard let detectedWord = getWordAtPosition(point) else {
            ocrTextView.attributedText = generateAttributedString(with: "2hdaun2unkjsdjakd2", targetString: ocrTextView.text)
            dictionaryTextView.text = ""
            return
        }
        
        var entries: [DictEntry] = []
        for i in 0..<detectedWord.count {
            entries += CoreDataManager.shared.translationFor(chinese: String(detectedWord.prefix(upTo: String.Index(utf16Offset: detectedWord.count - i, in: detectedWord))))
        }
        
        if(entries.count == 0) {
            ocrTextView.attributedText = generateAttributedString(with: "2hdaun2unkjsdjakd2", targetString: ocrTextView.text)
            dictionaryTextView.text = ""
            return
        }
        
        let longestDetectedWord = entries.reduce(entries[0], {
            if($0.traditional?.count ?? 0 > $1.traditional?.count ?? 0) { return $0 }
            else { return $1 }
        })
        let trimmedWord = String(detectedWord.prefix(upTo: String.Index(utf16Offset: longestDetectedWord.traditional?.count ?? 0, in: detectedWord)))
        ocrTextView.attributedText = generateAttributedString(with: trimmedWord, targetString: ocrTextView.text)
        dictionaryTextView.text = generateTranslationString(entries: entries)
        
        DictionaryTip.tipEnabled = false
    }
    
    func generateTranslationString(entries: [DictEntry]) -> String {
        if(entries.count == 0) { return "" }
        var string = "———————————————\n"
        
        for i in 0..<entries.count {
            let entry = entries[i]
            string += entry.traditional!
            if entry.traditional != entry.simplified {
                string += "【" +  entry.simplified! + "】"
            }
            
            string += " - "
            string += PinyinConverter().convert(pinyin: entry.pinyin!)
            string += "\n"
            
            let definitions = entry.definition!.components(separatedBy: "\\")
            for j in 0..<definitions.count {
                string += String(j + 1)
                string += ". " + definitions[j] + "\n"
            }
            if(i < entries.count - 1)
            {
                if(entry.simplified == entries[i + 1].simplified) { string += "————————\n" }
                else { string += "========\n" }
            }
        }
        
        return string
    }
    
    func generateAttributedString(with searchTerm: String, targetString: String) -> NSAttributedString? {
        
        let attributedString = NSMutableAttributedString(string: targetString)
        attributedString.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontRegularLarge as Any, range: NSRange(location: 0, length: targetString.count))
        
        do {
            let regex = try NSRegularExpression(pattern: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current), options: .caseInsensitive)
            let range = NSRange(location: 0, length: targetString.utf16.count)
            for match in regex.matches(in: targetString.folding(options: .diacriticInsensitive, locale: .current), options: .withTransparentBounds, range: range) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontBoldLarge as Any, range: match.range)
                attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: Constants.lightBlueColor as Any, range: match.range)
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
            let pos = ocrTextView.offset(from: ocrTextView.beginningOfDocument, to: textPosition)
            let textAfterPos = ocrTextView.text.suffix(from: String.Index(utf16Offset: pos, in: ocrTextView.text))
            let limitedText = String(textAfterPos.prefix(upTo: String.Index(utf16Offset: min(textAfterPos.count, searchLimit), in: textAfterPos)))
            return limitedText
        }
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: ocrTextView)
        if(ocrTextView.bounds.contains(touchPoint)) { return }
        
        ocrTextView.attributedText = generateAttributedString(with: "2hdaun2unkjsdjakd2", targetString: ocrTextView.text)
        dictionaryTextView.text = ""
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.selectedTextRange != nil {
            textView.delegate = nil
            textView.selectedTextRange = nil
            textView.delegate = self
        }
    }

}
