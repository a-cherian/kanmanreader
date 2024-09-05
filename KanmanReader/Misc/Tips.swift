//
//  Tips.swift
//  KanmanReader
//
//  Created by AC on 8/22/24.
//

import Foundation
import TipKit

struct OCRTip: Tip {
    @Parameter static var tipEnabled: Bool = true
    
    var title: Text {
        Text("Hold down to search for text")
    }
    
    var message: Text? {
        Text("Long press the page to identify regions of Chinese text")
    }
    
    var image: Image? {
        Image(systemName: "rectangle.and.text.magnifyingglass")    }
    
    var rules: [Rule] {
        #Rule(Self.$tipEnabled) { $0 == true }
    }
}

struct BoxTip: Tip {
    @Parameter static var tipEnabled: Bool = true
    @Parameter static var boxesGenerated: Bool = false
    
    var title: Text {
        Text("Tap red boxes")
    }
    
    var message: Text? {
        Text("Convert the boxed regions into text that can be copied or searched")
    }
    
    var image: Image? {
        Image(systemName: "list.dash.header.rectangle")
    }
    
    var rules: [Rule] {
        #Rule(Self.$boxesGenerated) { $0 == true }
        #Rule(Self.$tipEnabled) { $0 == true }
    }
}

struct DictionaryTip: Tip {
    @Parameter static var tipEnabled: Bool = true
    @Parameter static var dictOpened: Bool = false
    
    var title: Text {
        Text("Tap on unfamiliar words")
    }
    
    var message: Text? {
        Text("Pull up a definition for Chinese words by tapping on them")
    }
    
    var image: Image? {
        Image(systemName: "character.book.closed.fill.zh")
    }
    
    var rules: [Rule] {
        #Rule(Self.$tipEnabled) { $0 == true }
        #Rule(Self.$dictOpened) { $0 == true }
    }
}

struct CustomTipViewStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                configuration.image
                configuration.title
                    .fontWeight(.bold)
            }
 
            configuration.message?
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(.secondary)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

struct BorderTipViewStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                configuration.image
                configuration.title
                    .fontWeight(.bold)
            }
 
            configuration.message?
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(.secondary)
        }
        .padding()
        .preferredColorScheme(.dark)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Constants.suiDarkAccentColor, lineWidth: 3)
        )

    }
}

extension TipUIPopoverViewController {
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let borderColor = Constants.darkAccentColor.cgColor
        let fillColor = UIColor.clear.cgColor
        let lineWidth = 6.0
        
        let isBorderLayer = view.superview?.superview?.layer.sublayers?.map { subl in
            guard let sublayer = subl as? CAShapeLayer else { return false }
            
            if(sublayer.lineWidth != lineWidth) { return false }
            if(sublayer.fillColor != fillColor) { return false }
            if(sublayer.strokeColor != borderColor) { return false }
            
            
            return true
        }
        
        let hasBorderLayer = isBorderLayer?.contains(true) ?? false
        
        if(!hasBorderLayer) {
            guard let shapeLayer = view.superview?.superview?.mask?.layer as? CAShapeLayer else { return }
            let borderLayer = CAShapeLayer()
            
            borderLayer.path = shapeLayer.path
            borderLayer.lineWidth = lineWidth
            borderLayer.strokeColor = borderColor
            borderLayer.fillColor = fillColor
            borderLayer.frame = shapeLayer.bounds
            view.superview?.superview?.layer.addSublayer(borderLayer)
        }
    }
}
