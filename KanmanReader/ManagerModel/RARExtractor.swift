//
//  RARExtractor.swift
//  KanmanReader
//
//  Created by AC on 9/13/24.
//

import Unrar
import UIKit

struct RARExtractor: Extractor {
    var url: URL
    var archive: Archive
    var entries: [Entry]
    
    init(url: URL) throws {
        self.url = url
        
        archive = try Archive(fileURL: url)
        
        // sort by filename
        entries = try archive.entries().sorted(by: { $0.fileName.compare($1.fileName, options: .numeric) == .orderedAscending })
        
        // filter out directory & extraneous files
        entries = entries.filter { entry in
            return !entry.directory && shouldKeepFile(fileName: entry.fileName)
        }
        
        if(entries.count == 0) { throw ExtractError.noValidFiles }
    }
    
    func extractInfo() throws -> (cover: Data, totalPages: Int) {
        var cover: Data = Data([])
        
        do {
            _ = try archive.extract(entries[0]) { data, prog in cover.append(data) }
        } catch {
            print("Failed to extract image: \(error.localizedDescription)")
            throw error
        }
        
        return (cover, entries.count)
    }
    
    func extractImages() throws -> [UIImage] {
        var images: [UIImage] = []
        
        for i in 0..<entries.count {
            let entry = entries[i]
            
            var extractedData: Data = Data([])
            
            do {
                _ = try archive.extract(entry) { data, prog in extractedData.append(data) }
                if let image = UIImage(data: extractedData) {
                    images.append(image)
                }
            } catch {
                print("Failed to extract image: \(error.localizedDescription)")
                throw error
            }
        }
        
        return images
    }
    
    func extractData() throws -> [Data] {
        var data: [Data] = []
        
        for i in 0..<entries.count {
            let entry = entries[i]
            
            do {
                try data.append(archive.extract(entry))
            } catch {
                print("Failed to extract image: \(error.localizedDescription)")
                throw error
            }
        }
        
        return data
    }
}
