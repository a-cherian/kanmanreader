//
//  WordView.swift
//  KanmanReader
//
//  Created by AC on 9/3/24.
//

import UIKit

class WordView: UIView {
    var word: DictEntry
    
    lazy var textView: UITextView = {
        let view = UITextView()
        
        view.text = getEntryString()
        
        view.backgroundColor = .white
        view.textColor = .black
        view.layer.cornerRadius = 10
        view.layer.borderColor = Constants.darkAccentColor.cgColor
        view.layer.borderWidth = 3
        
        view.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.textAlignment = .left
        view.font = Constants.zhFontRegularSmall
        
        view.isEditable = false
        view.isUserInteractionEnabled = false
        view.isScrollEnabled = false
        
        return view
    }()
    
    init(word: DictEntry) {
        self.word = word
        
        super.init(frame: CGRect.zero)
        
        addSubviews()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        addSubview(textView)
    }
    
    func configureUI() {
        configureTextView()
    }
    
    func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        textView.setContentCompressionResistancePriority(.required, for: NSLayoutConstraint.Axis.vertical)
    }
    
    func getEntryString() -> String {
        
        let prioritizeTraditional = UserDefaults.standard.bool(forKey: Constants.PRIORITIZE_TRADITIONAL_KEY)
        let displaySecondary = UserDefaults.standard.bool(forKey: Constants.DISPLAY_SECONDARY_KEY)
        
        var string = ""
        
        var hanziPrimary = word.simplified!
        var hanziSecondary = word.simplified!
        
        if(prioritizeTraditional) { hanziPrimary = word.traditional! }
        else { hanziSecondary = word.traditional! }
        
        string += hanziPrimary
        if hanziPrimary != hanziSecondary && displaySecondary {
            string += "【" +  hanziSecondary + "】"
        }
        
        string += " - "
        string += PinyinConverter().convert(pinyin: word.pinyin!)
        string += "\n"
        
        let definitions = word.definition!.components(separatedBy: "\\")
        for j in 0..<definitions.count {
            string += String(j + 1)
            string += ". " + definitions[j] + "\n"
        }
        string = String(string.prefix(string.count - 1))
        
        return string
    }
}
