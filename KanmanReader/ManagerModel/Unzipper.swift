//
//  Unzipper.swift
//  KanmanReader
//
//  Created by AC on 8/29/24.
//

import UIKit
import ZIPFoundation
import Unrar

struct Unzipper {
    static let imageSuffixes = [".jpg", ".jpeg", ".png", ".webp", ".tiff", ".heic", ".bmp"]
    
    static func extractImages(for url: URL) -> (data: Data, images: [UIImage])? {
        let pathExtension = url.pathExtension
        
        if ["zip", "cbz"].contains(pathExtension) {
            return extractZip(for: url)
        }
        else if ["rar", "cbr"].contains(pathExtension) {
            return extractRar(for: url)
        }
        
        return nil
    }
    
    static func extractZip(for url: URL) -> (data: Data, images: [UIImage])? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            
            var images: [UIImage] = []
            
            // sort by filename
            var entries = archive.sorted(by: { ($0.path).compare($1.path) == .orderedAscending })
            
            // filter out directory & extraneous files
            entries = entries.filter { entry in
                return entry.type == .file && shouldKeepFile(fileName: entry.path)
            }
            
            var cover: Data = Data([])
            
            for i in 0..<entries.count {
                let entry = entries[i]
                
                var extractedData: Data = Data([])
                
                do {
                    _ = try archive.extract(entry) { extractedData.append($0) }
                    if let image = UIImage(data: extractedData) {
                        images.append(image)
                    }
                    if(i == 0) { cover = extractedData }
                } catch {
                    print("Failed to extract image: \(error.localizedDescription)")
                }
            }
            
            return (cover, images)
        }
        catch let extractError {
            print("Unable to extract the file: \(extractError).")
            return nil
        }
    }
    
    static func extractRar(for url: URL) -> (data: Data, images: [UIImage])? {
        do {
            let archive = try Archive(fileURL: url)
            
            var images: [UIImage] = []
            
            // sort by filename
            var entries = try archive.entries().sorted(by: { $0.fileName.compare($1.fileName) == .orderedAscending })
            
            
            // filter out directory & extraneous files
            entries = entries.filter { entry in
                return !entry.directory && shouldKeepFile(fileName: entry.fileName)
            }
            
            var cover: Data = Data([])
            
            for i in 0..<entries.count {
                let entry = entries[i]
                
                var extractedData: Data = Data([])
                
                do {
                    _ = try archive.extract(entry) { data, prog in extractedData.append(data) }
                    if let image = UIImage(data: extractedData) {
                        images.append(image)
                    }
                    if(i == 0) { cover = extractedData }
                } catch {
                    print("Failed to extract image: \(error.localizedDescription)")
                }
            }
            
            return (cover, images)
        }
        catch let extractError {
            print("Unable to extract the file: \(extractError).")
            return nil
        }
    }
    
    static func shouldKeepFile(fileName: String) -> Bool {
        let isMacFile = fileName.hasPrefix("__MACOSX")

        var isImageFile = false
        imageSuffixes.forEach { imageSuffix in
            let pathExt = URL(fileURLWithPath: fileName).pathExtension.lowercased()
            isImageFile = isImageFile || imageSuffix.contains(pathExt)
        }
        
        return isImageFile && !isMacFile
    }
}
