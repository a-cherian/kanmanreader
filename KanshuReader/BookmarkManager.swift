//
//  BookManager.swift
//  KanshuReader
//
//  Created by AC on 8/23/24.
//

import Foundation
import UIKit
import ZIPFoundation

struct BookmarkManager {
    
    static let shared = BookmarkManager()
    static let LINK_CHECKING = true // make false when using dummy databases for simulator screenshots
    
    func createBook(from url: URL, name: String? = nil) -> Book? {
        let books = CoreDataManager.shared.fetchBooks()
        let (cover, images) = getImages(for: url)
        
        var book = books?.first(where: { $0.url == url })
        if book == nil {
            createBookmark(url: url)
            let name = name ?? (url.lastPathComponent as NSString).deletingPathExtension
            book = CoreDataManager.shared.createBook(name: name, lastPage: 0, totalPages: images.count, cover: cover, url: url, lastOpened: Date())
        } else {
            book?.lastOpened = Date()
            CoreDataManager.shared.updateBook(book: book)
        }
        
        return book
    }
    
    func getImages(for url: URL, isApp: Bool = false) -> (data: Data, images: [UIImage]) {
        guard url.startAccessingSecurityScopedResource() else {
            return extractImages(for: url)
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return extractImages(for: url)
    }
    
    func extractImages(for url: URL) -> (data: Data, images: [UIImage]) {
        guard let archive = Archive(url: url, accessMode: .read) else { return (Data(), []) }
        
        var images: [UIImage] = []
        
        let sorted = archive.sorted(by: { ($0.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date).compare(($1.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date)) == .orderedAscending })
        
        var cover: Data = Data([])
        
        for i in 0..<sorted.count {
            let entry = sorted[i]
            
            var extractedData: Data = Data([])
            
            do {
                _ = try archive.extract(entry) { extractedData.append($0) }
                if let image = UIImage(data: extractedData) {
                    images.append(image)
                }
                if(i == 0) { cover = extractedData }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return (cover, images)
    }
    
    func readBookmarks() -> [URL] {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        let urls: [URL] = files?.compactMap {file in
            do {
                var bookmarkData = try Data(contentsOf: file)
                var isStale = false
                var url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                
                guard !isStale && BookmarkManager.LINK_CHECKING else {
                    bookmarkData = try url.bookmarkData()
                    url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                    deleteFile(url: file)
                    CoreDataManager.shared.deleteBook(for: file)
                    return url
                }
                
                return url
            }
            catch {
                if(!BookmarkManager.LINK_CHECKING) {
                    deleteFile(url: file)
                    CoreDataManager.shared.deleteBook(for: file)
                }
                print(error.localizedDescription)
                return nil
            }
        }  ?? []
        
        return urls
    }
    
    func deleteBookmarks() {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            deleteFile(url: file)
        }
    }
    
    func retrieveBooks() -> [Book] {
        let books = CoreDataManager.shared.fetchBooks()
        
        if(BookmarkManager.LINK_CHECKING) {
            let urls = readBookmarks()
            
            let matchedBooks = urls.compactMap { url in
                books?.first(where: { $0.url == url } )
            }
            
            books?.forEach { book in
                if(!matchedBooks.contains(book)) { CoreDataManager.shared.deleteBook(book: book) }
            }
            
            return matchedBooks.sorted(by: { $0.lastOpened ?? Date(timeIntervalSince1970: 0) > $1.lastOpened ?? Date(timeIntervalSince1970: 0) })
        }
        
        return books ?? []
    }
    
    func createBookmark(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            writeBookmark(url: url)
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        writeBookmark(url: url)
    }
    
    func writeBookmark(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = UUID().uuidString
            try bookmarkData.write(to: getAppSandboxDirectory().appendingPathComponent(uuid))
        }
        catch {
            print("Error creating the bookmark")
        }
    }
    
    func deleteFile(url: URL) {
        let fm = FileManager.default
        do {
            try fm.removeItem(at: url)
        } catch {
            print(error)
        }
    }
    
    private func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
