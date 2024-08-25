//
//  TipManager.swift
//  KanshuReader
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
    var boxTip = BoxTip()
    var dictTip = DictionaryTip()
    
    var ocrTipTask: Task<Void, Never>?
    var boxTipTask: Task<Void, Never>?
    var dictTipTask: Task<Void, Never>?
    
    lazy var boxTipView: TipUIView = {
        let view = TipUIView(boxTip)
        view.viewStyle = CustomTipViewStyle()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var dictTipView: TipUIView = {
        let view = TipUIView(dictTip)
        view.viewStyle = CustomTipViewStyle()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init() {
        try? Tips.resetDatastore()
        try? Tips.configure()
        OCRTip.tipEnabled = true
        BoxTip.tipEnabled = true
        BoxTip.boxesGenerated = false
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
        
        boxTipTask = boxTipTask ?? Task { @MainActor in
            for await shouldDisplay in boxTip.shouldDisplayUpdates {
                if shouldDisplay { delegate?.didDisplay(tip: boxTip) }
                else { delegate?.didDismiss(tip: boxTip) }
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
        BoxTip.tipEnabled = false
        DictionaryTip.tipEnabled = false
    }
}
