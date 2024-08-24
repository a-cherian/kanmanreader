//
//  Tips.swift
//  ManhuaReader
//
//  Created by AC on 8/22/24.
//

import Foundation
import TipKit

struct OCRTip: Tip {
    @Parameter static var tipEnabled: Bool = true
    
    var title: Text {
        Text("Click to search for text")
    }
    
    var message: Text? {
        Text("Identify regions of Chinese text on the page")
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
        Text("Convert the boxed regions into text that can be copied or searched.")
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
        Text("Look up unfamiliar words")
    }
    
    var message: Text? {
        Text("Tap on any word to pull up a definition for the word.")
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
    }
}

