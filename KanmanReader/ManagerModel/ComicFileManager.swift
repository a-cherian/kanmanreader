//
//  ComicFileManager.swift
//  KanmanReader
//
//  Created by AC on 8/23/24.
//

import Foundation
import UIKit

struct ComicFileManager {
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
            
            comic = CoreDataManager.shared.createComic(name: name, totalPages: images.count, cover: cover, uuid: uuid)
        }
        
        return comic
    }
    
    @discardableResult
    static func createTutorial() -> Comic? {
        guard let sampleUrl = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return nil }
        
        var comic = CoreDataManager.shared.fetchTutorial()
        
        if comic == nil {
            let name = "Tutorial"
            guard let (cover, images) = getImages(for: sampleUrl, openInPlace: false) else { return nil }
            guard let uuid = createBookmark(url: sampleUrl, openInPlace: false) else { return nil }
            comic = CoreDataManager.shared.createComic(name: name, totalPages: images.count, cover: cover, prefs: ReaderPreferences(scroll: .horizontal), uuid: uuid)
        }
        
        return comic
    }
    
    static func getImages(for url: URL, openInPlace: Bool = true) -> (data: Data, images: [UIImage])? {
        if(!openInPlace) { return Unzipper.extractImages(for: url) }
        
        guard url.startAccessingSecurityScopedResource() else { return nil }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return Unzipper.extractImages(for: url)
    }
    
    static func retrieveComics() -> [Comic] {
        var comics = CoreDataManager.shared.fetchComics()
        
        if(LINK_CHECKING) {
            comics = comics?.compactMap { comic in
                if comic.url == nil {
                    ComicFileManager.deleteComic(comic: comic)
                    return nil
                }
                else {
                    return comic
                }
            }
        }
        
        return comics?.sorted(by: { $0.lastOpened ?? Date(timeIntervalSince1970: 0) > $1.lastOpened ?? Date(timeIntervalSince1970: 0) }) ?? []
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
            try bookmarkData.write(to: getBookmarkDirectory().appendingPathComponent(uuid))
            return uuid
        }
        catch {
            print("Error creating the bookmark: \(error)")
            return nil
        }
    }
    
    static func deleteComic(comic: Comic) {
        deleteBookmark(uuid: comic.uuid)
        CoreDataManager.shared.deleteComic(comic: comic)
    }
    
    static func deleteBookmark(uuid: String?) {
        guard let uuid = uuid else { return }
        
        let fm = FileManager.default
        do {
            
            let bookmarkURL = getBookmarkDirectory().appendingPathComponent(uuid)
            if(fm.fileExists(atPath: bookmarkURL.path))
            {
                try fm.removeItem(at: bookmarkURL) // WARNING: this WILL delete files
            }
        } catch {
            print("Failed to delete bookmark: \(error)")
        }
    }
    
    static func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func getBookmarkDirectory() -> URL {
        return getCreateDirectory(name: ".Bookmarks")
    }
    
    static func getManhuaDirectory() -> URL {
        return getCreateDirectory(name: "Manhua")
    }
    
    static func getCreateDirectory(name: String) -> URL {
        let directory = getAppSandboxDirectory().appendingPathComponent(name)
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(atPath: directory.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Failed to create \(name) directory: \(error)")
                return getAppSandboxDirectory()
            }
        }
        
        return directory
    }
    
    static func deleteBookmarks() {
        let files = try? FileManager.default.contentsOfDirectory(at:  getBookmarkDirectory(), includingPropertiesForKeys: nil)
        let fm = FileManager.default
        
        files?.forEach { file in
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
    
    static func loadManhuaDirectory() {
        let files = try? FileManager.default.contentsOfDirectory(at: getManhuaDirectory(), includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            createComic(from: file, openInPlace: false)
        }
    }
    
    static func moveToBooks(url: URL) -> URL? {
        let fm = FileManager.default
        
        do {
            let newURL = getManhuaDirectory().appendingPathComponent(url.lastPathComponent)
            if(!fm.fileExists(atPath: newURL.path))
            {
                try fm.moveItem(at: url, to: getManhuaDirectory().appendingPathComponent(url.lastPathComponent))
                return newURL
            }
            else { return nil }
        } catch {
            print("Failed to move file: \(error)")
            return nil
        }
    }
    
    static func clearDirectory(name: String) {
        let files = try? FileManager.default.contentsOfDirectory(at: getAppSandboxDirectory().appendingPathComponent(name), includingPropertiesForKeys: nil)
        let fm = FileManager.default
        
        files?.forEach { file in
            do {
                try fm.removeItem(at: file)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
    }
    
    static func clearInbox() {
        clearDirectory(name: "Inbox")
    }
    
    static func clearTrash() {
        clearDirectory(name: ".Trash")
    }
}

extension Comic {
    var isTutorial: Bool {
        url?.lastPathComponent.contains(Constants.TUTORIAL_FILENAME) ?? false
    }
    
    var url: URL? {
        guard let uuid = uuid else { return nil }
        
        let file = ComicFileManager.getBookmarkDirectory().appendingPathComponent(uuid)
        
        do {
            let bookmarkData = try Data(contentsOf: file)
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            
            guard !isStale else {
                return nil
            }
            
            return url
        }
        catch {
            print("Failed to read bookmark: \(error.localizedDescription)")
            return nil
        }
    }
}

extension URL {
    var isTutorial: Bool {
        lastPathComponent.contains(Constants.TUTORIAL_FILENAME)
    }
}
