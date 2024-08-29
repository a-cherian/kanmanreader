//
//  BookManager.swift
//  KanshuReader
//
//  Created by AC on 8/23/24.
//

import Foundation
import UIKit

struct BookmarkManager {
    static let LINK_CHECKING = true // make false when using dummy databases for simulator screenshots
    
    @discardableResult
    static func createBook(from url: URL, name: String? = nil) -> Book? {
        let books = CoreDataManager.shared.fetchBooks()
        
        var book = books?.first(where: { $0.url == url })
        
        if book == nil {
            createBookmark(url: url)
            let name = name ?? getFileName(for: url)
            guard let (cover, images) = getImages(for: url) else { return nil }
            book = CoreDataManager.shared.createBook(name: name, totalPages: images.count, cover: cover, url: url)
        } else {
            CoreDataManager.shared.updateBook(book: book)
        }
        
        return book
    }
    
    static func createTutorial() {
        guard let sampleUrl = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return }
        
        var book = CoreDataManager.shared.fetchTutorial()
        
        if book == nil {
            let name = "Sample Tutorial"
            guard let (cover, images) = getImages(for: sampleUrl) else { return }
            book = CoreDataManager.shared.createBook(name: name, totalPages: images.count, cover: cover, url: sampleUrl)
        } else {
            book?.url = sampleUrl
            CoreDataManager.shared.updateBook(book: book)
        }
    }
    
    static func relinkTutorial() {
        guard let sampleUrl = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return }
        
        let book = CoreDataManager.shared.fetchTutorial()
        book?.url = sampleUrl
        CoreDataManager.shared.updateBook(book: book)
    }
    
    static func getImages(for url: URL, isApp: Bool = false) -> (data: Data, images: [UIImage])? {
        guard url.startAccessingSecurityScopedResource() else {
            return Unzipper.extractImages(for: url)
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return Unzipper.extractImages(for: url)
    }
    
    static func readBookmarks() -> [URL] {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        let urls: [URL] = files?.compactMap {file in
            do {
                let bookmarkData = try Data(contentsOf: file)
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                
                guard !isStale && LINK_CHECKING else {
                    if(!url.isTutorial) { deleteBook(for: url) }
                    return nil
                }
                
                return url
            }
            catch {
                if(LINK_CHECKING) {
                    deleteBook(for: file)
                }
                print(error.localizedDescription)
                return nil
            }
        }  ?? []
        
        return urls
    }
    
    static func retrieveBooks() -> [Book] {
        let books = CoreDataManager.shared.fetchBooks()
        
        if(LINK_CHECKING) {
            let urls = readBookmarks()
            
            let matchedBooks: [Book] = books?.compactMap { book in
                if book.isTutorial { return book }
                guard let _ = urls.first(where: { book.url == $0 } ) else { return nil}
                return book
            } ?? []
            
            books?.forEach { book in
                if(!matchedBooks.contains(book)) {
                    deleteBook(for: book.url)
                }
            }
            
            return matchedBooks.sorted(by: { $0.lastOpened ?? Date(timeIntervalSince1970: 0) > $1.lastOpened ?? Date(timeIntervalSince1970: 0) })
        }
        
        return books ?? []
    }
    
    static func createBookmark(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            writeBookmark(url: url)
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        writeBookmark(url: url)
    }
    
    static func writeBookmark(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = generateUUID(for: url)
            try bookmarkData.write(to: getAppSandboxDirectory().appendingPathComponent(uuid))
        }
        catch {
            print("Error creating the bookmark")
        }
    }
    
    static func deleteBook(for url: URL?) {
        guard let file = url else { return }
        deleteBookmark(url: file)
        CoreDataManager.shared.deleteBook(for: file)
    }
    
    static func deleteBookmark(url: URL) {
        let fm = FileManager.default
        do {
            let bookmarkURL = getAppSandboxDirectory().appendingPathComponent(generateUUID(for: url))
            if(fm.fileExists(atPath: bookmarkURL.path))
            {
                try fm.removeItem(at: bookmarkURL) // WARNING: this WILL delete files
            }
        } catch {
            print(error)
        }
    }
    
    static private func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func deleteBookmarks() {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        let fm = FileManager.default

        
        files?.forEach { file in
            do {
                try fm.removeItem(at: file)
            } catch {
                print(error)
            }
        }
    }
    
    static func generateUUID(for url: URL) -> String {
        var uuid = url.absoluteString.replacing("/", with: "")
        uuid = uuid.replacing(":", with: "")
        return uuid
    }
    
    static func getFileName(for url: URL?) -> String {
        guard let url = url else { return "" }
        return (url.lastPathComponent as NSString).deletingPathExtension
    }
}

extension Book {
    var isTutorial: Bool {
        url?.lastPathComponent.hasPrefix(Constants.TUTORIAL_FILENAME) ?? false
    }
}

extension URL {
    var isTutorial: Bool {
        lastPathComponent.contains(Constants.TUTORIAL_FILENAME)
    }
}
