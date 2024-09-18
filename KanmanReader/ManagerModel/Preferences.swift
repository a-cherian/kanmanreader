//
//  Preferences.swift
//  KanmanReader
//
//  Created by AC on 8/28/24.
//

import Foundation

class ReaderPreferences {
    let SCROLL_DIR_POS = 0
    let TEXT_DIR_POS = 1
    
    var scrollDirection: Direction = .vertical
    var textDirection: Direction = .horizontal
    
    var string: String { ReaderPreferences.generateString(scrollDir: scrollDirection, textDir: textDirection) }
    
    init(scroll: Direction = .vertical, text: Direction = .horizontal) {
        scrollDirection = scroll
        textDirection = text
    }
    
    init(from string: String?) {
        let prefsString = string ?? ReaderPreferences.generateString()
        
        let prefs = prefsString.split(separator: ":")
        let prefsOptions: [[String]] = prefs.map { $0.split(separator: "_").map({ String($0) }) }
        
        scrollDirection = Direction(with: prefsOptions[SCROLL_DIR_POS][1])
        textDirection = Direction(with: prefsOptions[TEXT_DIR_POS][1])
    }
    
    static func generateString(scrollDir: Direction = .vertical, textDir: Direction = .vertical) -> String {
        let scrollDirStr = "scrollDirection_" + scrollDir.rawValue
        let textDirStr = "textDirection_" + textDir.rawValue
        
        let prefs = [scrollDirStr, textDirStr]
        
        return prefs.joined(separator: ":")
    }
}



class AppPreferences {
    let CHAPTER_NUMBER_POS = 0
    let BOTH_SCRIPTS_POS = 1
    let TRADITIONAL_POS = 2
   
    var displayChapterNumbers = true
    var displayBothScripts = true
    var prioritizeTraditional = false
    
    var string: String { AppPreferences.generateString(chapterNumbers: displayChapterNumbers, bothScripts: displayBothScripts, traditional: prioritizeTraditional) }
    
    init(chapterNumbers: Bool = false, bothScripts: Bool = true, traditional: Bool = false) {
        displayChapterNumbers = chapterNumbers
        displayBothScripts = bothScripts
        prioritizeTraditional = traditional
    }
    
    init(from string: String?) {
        let prefsString = string ?? UserDefaults.standard.string(forKey: Constants.APP_PREFERENCES_KEY) ?? AppPreferences.generateString()
        
        let prefs = prefsString.split(separator: ":")
        let prefsOptions: [[String]] = prefs.map { $0.split(separator: "_").map({ String($0) }) }
        
        displayChapterNumbers = Bool(prefsOptions[CHAPTER_NUMBER_POS][1]) ?? displayChapterNumbers
        displayBothScripts = Bool(prefsOptions[BOTH_SCRIPTS_POS][1]) ?? displayBothScripts
        prioritizeTraditional = Bool(prefsOptions[TRADITIONAL_POS][1]) ?? prioritizeTraditional
    }
    
    init(fromStored: Bool) {
    }
    
    static func generateString(chapterNumbers: Bool = false, bothScripts: Bool = true, traditional: Bool = false) -> String {
        let chapterNumbersStr = "chapterNumbers_" + String(chapterNumbers)
        let bothScriptsStr = "bothScripts_" + String(bothScripts)
        let traditionalStr = "traditional_" + String(traditional)
        
        let prefs = [chapterNumbersStr, bothScriptsStr, traditionalStr]
        
        return prefs.joined(separator: ":")
    }
}
