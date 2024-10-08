//
//  Constants.swift
//  KanmanReader
//
//  Created by AC on 12/19/23.
//

import UIKit
import SwiftUI

struct Constants {
    // APP INFO
    static let APP_VERSION = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    static let BUILD_NUMBER = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    static let IOS_VERSION = UIDevice.current.systemVersion
    static let DEVICE_MODEL = UIDevice.current.name
    
    
    // USERDEFAULTS KEYS
    static let LOADED_SAMPLE_KEY = "loadedSample"
    static let LOADED_SAMPLE = "v1.1.0"
    
    static let LATEST_DICT_UPDATE_KEY = "dictDate"
    static let LATEST_DICT_UPDATE = "2024-08-19"
    
    static let APP_PREFERENCES_KEY = "appPreferences"
    static let HAS_ONBOARDED_KEY = "hasOnboarded"
    static let FINISHED_TIPS_KEY = "finishedTips"
    
    
    // FONTS
    static let smallFont: CGFloat = 15
    static let mediumFont: CGFloat = 20
    static let largeFont: CGFloat = 24
    
    static let zhFontRegularSmall = UIFont(name: "PingFangTC-Regular", size: smallFont)
    static let zhFontRegularMedium = UIFont(name: "PingFangTC-Regular", size: mediumFont)
    static let zhFontRegularLarge = UIFont(name: "PingFangTC-Regular", size: largeFont)
    
    static let zhFontBoldSmall = UIFont(name: "PingFangTC-Semibold", size: smallFont)
    static let zhFontBoldMedium = UIFont(name: "PingFangTC-Semibold", size: mediumFont)
    static let zhFontBoldLarge = UIFont(name: "PingFangTC-Semibold", size: largeFont)
    
    
    // MISC
    static let TUTORIAL_FILENAME = "kanman-tutorial-sample"
}
