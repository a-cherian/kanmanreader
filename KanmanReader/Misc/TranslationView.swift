//
//  TranslationModelDownloader.swift
//  KanmanReader
//
//  Created by AC on 6/12/25.
//

import SwiftUI
import Translation

class TranslationCoordinator: ObservableObject {
    @Published var showsTranslation: Bool = false
    @Published var textToTranslate: String = ""
}

struct TranslationView: View {
    @ObservedObject var coordinator: TranslationCoordinator
    
    var body: some View {
        Color.clear
            .translationPresentation(isPresented: $coordinator.showsTranslation, text: coordinator.textToTranslate)
    }
}
