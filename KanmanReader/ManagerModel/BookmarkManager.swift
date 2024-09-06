//
//  BookmarkManager.swift
//  KanmanReader
//
//  Created by AC on 8/23/24.
//

import Foundation
import UIKit

struct BookmarkManager {
    static let LINK_CHECKING = true // make false when using dummy databases for simulator screenshots
    
    @discardableResult
    static func createComic(from url: URL, name: String? = nil, openInPlace: Bool = true) -> Comic? {
        let comics = CoreDataManager.shared.fetchComics()
        
        var comic = comics?.first(where: { $0.url == url })
        
        if comic == nil {
            let name = name ?? getFileName(for: url)
            guard let uuid = createBookmark(url: url, openInPlace: openInPlace) else { return nil }
            guard let (cover, images) = getImages(for: url, openInPlace: openInPlace) else { return nil }
            if(images.count == 0 ) { return nil }
            
            comic = CoreDataManager.shared.createComic(name: name, totalPages: images.count, cover: cover, url: url, uuid: uuid)
        } else {
            CoreDataManager.shared.updateComic(comic: comic)
        }
        
        return comic
    }
    
    @discardableResult
    static func createTutorial() -> Comic? {
        guard let sampleUrl = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return nil }
        
        var comic = CoreDataManager.shared.fetchTutorial()
        
        if comic == nil {
            let name = "Tutorial"
            guard let (cover, images) = getImages(for: sampleUrl) else { return nil }
            comic = CoreDataManager.shared.createComic(name: name, totalPages: images.count, cover: cover, url: sampleUrl, prefs: ReaderPreferences(scroll: .horizontal), uuid: "Tutorial")
        } else {
            comic?.url = sampleUrl
            CoreDataManager.shared.updateComic(comic: comic)
        }
        
        return comic
    }
    
    static func relinkTutorial() {
        guard let sampleUrl = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return }
        
        let comic = CoreDataManager.shared.fetchTutorial()
        comic?.url = sampleUrl
        CoreDataManager.shared.updateComic(comic: comic)
    }
    
    static func getImages(for url: URL, openInPlace: Bool = true) -> (data: Data, images: [UIImage])? {
        if(!openInPlace || url.isTutorial) { return Unzipper.extractImages(for: url) }
        
        guard url.startAccessingSecurityScopedResource() else { return nil }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return Unzipper.extractImages(for: url)
    }
    
    static func readBookmarks() -> [URL] {
        let fm = FileManager.default
        let files = try? fm.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        let urls: [URL] = files?.compactMap {file in
            if(file.lastPathComponent == "Inbox") { return nil}
            do {
                let bookmarkData = try Data(contentsOf: file)
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                
                guard !isStale && LINK_CHECKING else {
                    deleteComic(url: url)
                    return nil
                }
                
                return url
            }
            catch {
                if(LINK_CHECKING) {
                    deleteComic(url: file)
                }
                print("Failed to read bookmark: \(error.localizedDescription)")
                return nil
            }
        }  ?? []
        
        return urls
    }
    
    static func retrieveComics() -> [Comic] {
        let comics = CoreDataManager.shared.fetchComics()
        
        if(LINK_CHECKING) {
            let urls = readBookmarks()
            
            let matchedComics: [Comic] = comics?.compactMap { comic in
                if comic.isTutorial { return comic }
                guard let _ = urls.first(where: { comic.url == $0 } ) else { return nil}
                return comic
            } ?? []
            
            comics?.forEach { comic in
                if(!matchedComics.contains(comic)) {
                    deleteComic(comic: comic)
                }
            }
            
            return matchedComics.sorted(by: { $0.lastOpened ?? Date(timeIntervalSince1970: 0) > $1.lastOpened ?? Date(timeIntervalSince1970: 0) })
        }
        
        return comics ?? []
    }
    
    static func createBookmark(url: URL, openInPlace: Bool = true) -> String? {
        if(!openInPlace) { return writeBookmark(url: url) }
        
        guard url.startAccessingSecurityScopedResource() else { return nil }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return writeBookmark(url: url)
    }
    
    static func writeBookmark(url: URL) -> String? {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = generateUUID(for: url)
            try bookmarkData.write(to: getAppSandboxDirectory().appendingPathComponent(uuid))
            return uuid
        }
        catch {
            print("Error creating the bookmark: \(error)")
            return nil
        }
    }
    
    static func deleteComic(url: URL?) {
        guard let comic = CoreDataManager.shared.fetchComic(url: url) else { return }
        deleteComic(comic: comic)
    }
    
    static func deleteComic(comic: Comic) {
        deleteBookmark(uuid: comic.uuid)
        CoreDataManager.shared.deleteComic(comic: comic)
    }
    
    static func deleteBookmark(uuid: String?) {
        guard let uuid = uuid else { return }
        
        let fm = FileManager.default
        do {
            let bookmarkURL = getAppSandboxDirectory().appendingPathComponent(uuid)
            if(fm.fileExists(atPath: bookmarkURL.path))
            {
                try fm.removeItem(at: bookmarkURL) // WARNING: this WILL delete files
            }
        } catch {
            print("Failed to delete bookmark: \(error)")
        }
    }
    
    static private func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func deleteBookmarks() {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        let fm = FileManager.default
        
        files?.forEach { file in
            if(file.lastPathComponent == "Inbox") { return }
            do {
                try fm.removeItem(at: file)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
    }
    
    static func generateUUID(for url: URL) -> String {
        let uuid = UUID().uuidString
        return uuid
    }
    
    static func getFileName(for url: URL?) -> String {
        guard let url = url else { return "" }
        return (url.lastPathComponent as NSString).deletingPathExtension
    }
}

extension Comic {
    var isTutorial: Bool {
        uuid == "Tutorial"
    }
}

extension URL {
    var isTutorial: Bool {
        lastPathComponent.contains(Constants.TUTORIAL_FILENAME)
    }
}
