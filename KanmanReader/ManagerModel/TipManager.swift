//
//  TipManager.swift
//  KanmanReader
//
//  Created by AC on 8/24/24.
//

import TipKit

protocol TipDelegate: AnyObject {
    func didDisplay(tip: any Tip)
    func didDismiss(tip: any Tip)
}

class TipManager {
    
    weak var delegate: TipDelegate?
    
    var ocrTip = OCRTip()
    var dictTip = DictionaryTip()
    
    var ocrTipTask: Task<Void, Never>?
    var dictTipTask: Task<Void, Never>?
    
    init() {
        try? Tips.resetDatastore()
        try? Tips.configure()
        OCRTip.tipEnabled = true
        DictionaryTip.tipEnabled = true
        DictionaryTip.dictOpened = false
    }
    
    func startTasks() {
        ocrTipTask = ocrTipTask ?? Task { @MainActor in
            for await shouldDisplay in ocrTip.shouldDisplayUpdates {
                if shouldDisplay { delegate?.didDisplay(tip: ocrTip) }
                else { delegate?.didDismiss(tip: ocrTip) }
            }
        }
        
        dictTipTask = dictTipTask ?? Task { @MainActor in
            for await shouldDisplay in dictTip.shouldDisplayUpdates {
                if shouldDisplay { delegate?.didDisplay(tip: dictTip) }
                else { delegate?.didDismiss(tip: dictTip) }
            }
        }
    }
    
    static func disableTips() {
        OCRTip.tipEnabled = false
        DictionaryTip.tipEnabled = false
    }
    
    static func hasStartedTips() -> Bool {
        return UserDefaults.standard.bool(forKey: Constants.FINISHED_TIPS_KEY)
    }
}
