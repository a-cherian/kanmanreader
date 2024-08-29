//
//  ReaderPreferences.swift
//  KanshuReader
//
//  Created by AC on 8/28/24.
//

import Foundation

class ReaderPreferences {
    static let SCROLL_DIR_POS = 0
    static let TEXT_DIR_POS = 1
    
    var scrollDirection: Direction = .horizontal
    var textDirection: Direction = .horizontal
    
    var string: String { ReaderPreferences.generateString(scrollDir: scrollDirection, textDir: textDirection) }
    
    init(scroll: Direction = .horizontal, text: Direction = .horizontal) {
        scrollDirection = scroll
        textDirection = text
    }
    
    init(from string: String?) {
        let prefsString = string ?? ReaderPreferences.generateString()
        
        let prefs = prefsString.split(separator: ":")
        let prefsOptions: [[String]] = prefs.map { $0.split(separator: "_").map({ String($0) }) }
        
        scrollDirection = Direction(with: prefsOptions[ReaderPreferences.SCROLL_DIR_POS][1])
        textDirection = Direction(with: prefsOptions[ReaderPreferences.TEXT_DIR_POS][1])
    }
    
    static func generateString(scrollDir: Direction = .horizontal, textDir: Direction = .vertical) -> String {
        let scrollDirStr = "scrollDirection_" + scrollDir.rawValue
        let textDirStr = "textDirection_" + textDir.rawValue
        
        let prefs = [scrollDirStr, textDirStr]
        
        return prefs.joined(separator: ":")
    }
}
