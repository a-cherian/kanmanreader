//
//  Unpacker.swift
//  KanmanReader
//
//  Created by AC on 8/29/24.
//

import UIKit
import ZIPFoundation
import Unrar

enum ExtractError: Error {
    case noValidFiles
    case failedExtract
    case unsupportedFileType
}


protocol Extractor {
    var url: URL { get set }
    
    init(url: URL) throws
    func extractInfo() throws -> (cover: Data, totalPages: Int)
    func extractImages() throws -> [UIImage]
    func extractData() throws -> [Data]
}

class Unpacker {
    var extractor: Extractor
    
    init(for url: URL) throws {
        let pathExtension = url.pathExtension
        
        do {
            if ["zip", "cbz"].contains(pathExtension) {
                extractor = try ZIPExtractor(url: url)
            }
            else if ["rar", "cbr"].contains(pathExtension) {
                extractor = try RARExtractor(url: url)
            }
            else {
                throw ExtractError.unsupportedFileType
            }
        }
        catch {
            print("Failed to create extractor for \(url): \(error).")
            throw error
        }
    }
    
    func extractInfo() throws -> (cover: Data, totalPages: Int) {
        do {
            return try extractor.extractInfo()
        }
        catch {
            print("Failed to extract info for \(extractor.url): \(error).")
            throw error
        }
    }
    
    func extractImages() throws -> [UIImage] {
        do {
            return try extractor.extractImages()
        }
        catch {
            print("Failed to extract info for \(extractor.url): \(error).")
            throw ExtractError.failedExtract
        }
    }
    
    func extractData() throws -> [Data] {
        do {
            return try extractor.extractData()
        }
        catch {
            print("Failed to extract info for \(extractor.url): \(error).")
            throw ExtractError.failedExtract
        }
    }
}

func shouldKeepFile(fileName: String) -> Bool {
    let imageSuffixes = [".jpg", ".jpeg", ".png", ".webp", ".tiff", ".heic", ".bmp"]

    let isMacFile = fileName.hasPrefix("__MACOSX")
    
    let url = URL(fileURLWithPath: fileName)
    let isImageFile = imageSuffixes.contains { $0.contains(url.pathExtension.lowercased()) }
    
    return isImageFile && !isMacFile
}
