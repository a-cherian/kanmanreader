//
//  ZIPExtractor.swift
//  KanmanReader
//
//  Created by AC on 9/13/24.
//

import ZIPFoundation
import UIKit

struct ZIPExtractor: Extractor {
    var url: URL
    var archive: Archive
    var entries: [Entry]
    
    init(url: URL) throws {
        self.url = url
       
        archive = try Archive(url: url, accessMode: .read)
        
        // sort by filename
        entries = archive.sorted(by: { ($0.path).compare($1.path) == .orderedAscending })
        
        // filter out directory & extraneous files
        entries = entries.filter { entry in
            return entry.type == .file && shouldKeepFile(fileName: entry.path)
        }
    }
    
    func extractInfo() throws -> (cover: Data, totalPages: Int) {
        var cover: Data = Data([])
        
        do {
            _ = try archive.extract(entries[0]) { cover.append($0) }
        } catch {
            print("Failed to extract image: \(error.localizedDescription)")
        }
        
        return (cover, entries.count)
    }
    
    func extractImages() throws -> [UIImage] {
        var images: [UIImage] = []
        
        for i in 0..<entries.count {
            let entry = entries[i]
            
            var extractedData: Data = Data([])
            
            do {
                _ = try archive.extract(entry) { extractedData.append($0) }
                if let image = UIImage(data: extractedData) {
                    images.append(image)
                }
            } catch {
                print("Failed to extract image: \(error.localizedDescription)")
            }
        }
        
        return images
    }
    
    func extractData() throws -> [Data] {
        var data: [Data] = []
        
        for i in 0..<entries.count {
            let entry = entries[i]
            
            
            var extractedData: Data = Data([])
            
            do {
                _ = try archive.extract(entry) { extractedData.append($0) }
                data.append(extractedData)
            } catch {
                print("Failed to extract image: \(error.localizedDescription)")
                throw error
            }
        }
        
        return data
    }
}
