//
//  Constants.swift
//  KanshuReader
//
//  Created by AC on 12/19/23.
//

import UIKit
import SwiftUI

struct Constants {
    // USERDEFAULTS KEYS
    static let LOADED_SAMPLE_KEY = "loadedSample"
    static let LOADED_SAMPLE = "v1.0"
    
    static let LATEST_DICT_UPDATE_KEY = "dictDate"
    static let LATEST_DICT_UPDATE = "2024-08-19"
    
    static let HAS_ONBOARDED_KEY = "hasOnboarded"
    static let STARTED_TIPS_KEY = "startedTips"
    static let PRIORITIZE_TRADITIONAL_KEY = "prioritizeTraditional"
    static let DISPLAY_SECONDARY_KEY = "displaySecondary"
    
    
    // COLORS
    static let accentColor = UIColor(red: 166 / 255.0, green: 221 / 255.0, blue: 171 / 255.0, alpha: 1.0)
    static let darkAccentColor = UIColor(red: 120 / 255.0, green: 148 / 255.0, blue: 134 / 255.0, alpha: 1.0)
    static let suiDarkAccentColor = Color(red: 120 / 255.0, green: 148 / 255.0, blue: 134 / 255.0)
    static let lightBlueColor = UIColor(red: 139 / 255.0, green: 232 / 255.0, blue: 223 / 255.0, alpha: 1.0)
    
    
    // FONTS
    static let largeFont: CGFloat = 24
    static let smallFont: CGFloat = 20
    static let zhFontRegularSmall = UIFont(name: "PingFangTC-Regular", size: smallFont)
    static let zhFontRegularLarge = UIFont(name: "PingFangTC-Regular", size: largeFont)
    static let zhFontBoldLarge = UIFont(name: "PingFangTC-Semibold", size: largeFont)
    
    
    // MISC
    static let TUTORIAL_FILENAME = "kanshu-tutorial-sample"
}
