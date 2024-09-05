//
//  Enums.swift
//  KanmanReader
//
//  Created by AC on 8/27/24.
//

import Foundation

enum Direction: String {
    case horizontal
    case vertical
    
    init(with rawValue: String) {
        self = Direction(rawValue: rawValue) ?? .vertical
    }
}
