//
//  ComicFileManager.swift
//  KanmanReader
//
//  Created by AC on 8/23/24.
//

import Foundation
import UIKit

enum BookmarkError: Error {
    case notSecurityScoped
    case failedWrite
}

struct ComicFileManager {
    static let LINK_CHECKING = true // make false when using dummy databases for simulator screenshots
    
    @discardableResult
    static func createComics(for urls: [URL]) async -> Int {
        let comics = CoreDataManager.shared.fetchComics()
        let comicData: [[AnyHashable : Any]] = urls.sorted(by: { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending })
            .compactMap { url in
                if comics?.first(where: { $0.url == url }) != nil { return nil }
                    
                let name = getFileName(for: url)
                guard let uuid = try? createBookmark(url: url) else { return nil }
                guard let (cover, totalPages) = try? getInfo(for: url) else { return nil }
                if(totalPages == 0 ) { return nil }
                
                return ["name": name, "lastPage": 0, "totalPages": totalPages, "cover": cover, "lastOpened": Date(), "preferences": ReaderPreferences().string, "uuid": uuid]
            }

        return await CoreDataManager.shared.createComics(comicData: comicData)
    }
    
    @discardableResult
    static func createComic(from url: URL, name: String? = nil, openInPlace: Bool = true) -> Comic? {
        let comics = CoreDataManager.shared.fetchComics()
        
        do {
            var comic = comics?.first(where: { $0.url == url })
            
            if comic == nil {
                let name = name ?? getFileName(for: url)
                let uuid = try createBookmark(url: url, openInPlace: openInPlace)
                let (cover, totalPages) = try getInfo(for: url, openInPlace: openInPlace)
                if(totalPages == 0 ) { return nil }
                
                comic = CoreDataManager.shared.createComic(name: name, totalPages: totalPages, cover: cover, uuid: uuid)
            }
            
            return comic
        }
        catch {
            print("Couldn't create comic for \(url): \(error)")
            
            let alert = UIAlertController(
                title: "Manhua import failed",
                message: "Manhua was unable to be imported. Try again, or contact support if the problem persists.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                // cancel action
            }))
            alert.show()
            
            return nil
        }
    }
    
    @discardableResult
    static func createTutorial() -> Comic? {
        guard let sampleURL = Bundle.main.url(forResource: Constants.TUTORIAL_FILENAME, withExtension: "zip") else { return nil }
        let comics = CoreDataManager.shared.fetchComics()
        
        do {
            var comic = comics?.first(where: { $0.url == sampleURL })
            
            if comic == nil {
                let name = "Tutorial"
                let (cover, totalPages) = try getInfo(for: sampleURL, openInPlace: false)
                let uuid = try createBookmark(url: sampleURL, openInPlace: false)
                comic = CoreDataManager.shared.createComic(name: name, totalPages: totalPages, cover: cover, prefs: ReaderPreferences(scroll: .horizontal), uuid: uuid)
            }
            
            return comic
        }
        catch {
            print("Couldn't create comic for \(sampleURL): \(error)")
            return nil
        }
    }
    
    static func getInfo(for url: URL, openInPlace: Bool = true) throws -> (cover: Data, totalPages: Int) {
        if(!openInPlace) { return try Unpacker(for: url).extractInfo() }
        
        guard url.startAccessingSecurityScopedResource() else { throw BookmarkError.notSecurityScoped }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return try Unpacker(for: url).extractInfo()
    }
    
    static func getImages(for url: URL, openInPlace: Bool = true) throws -> [UIImage]? {
        if(!openInPlace) { return try Unpacker(for: url).extractImages() }
        
        guard url.startAccessingSecurityScopedResource() else { throw BookmarkError.notSecurityScoped }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return try Unpacker(for: url).extractImages()
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
    
    static func createBookmark(url: URL, openInPlace: Bool = true) throws -> String {
        if(!openInPlace) { return try writeBookmark(url: url) }
        
        guard url.startAccessingSecurityScopedResource() else { throw BookmarkError.notSecurityScoped }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        return try writeBookmark(url: url)
    }
    
    static func writeBookmark(url: URL) throws -> String {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = generateUUID(for: url)
            try bookmarkData.write(to: getBookmarkDirectory().appendingPathComponent(uuid))
            return uuid
        }
        catch {
            print("Error creating the bookmark: \(error)")
            throw BookmarkError.failedWrite
        }
    }
    
    static func deleteComic(comic: Comic) {
        if let url = comic.url,
           let manhuaDirectoryFiles = try? FileManager.default.contentsOfDirectory(at:  getManhuaDirectory(), includingPropertiesForKeys: nil),
           manhuaDirectoryFiles.contains(url) {
            deleteFile(url: url)
        }
        
        deleteBookmark(uuid: comic.uuid)
        CoreDataManager.shared.deleteComic(comic: comic)
        
    }
    
    static func deleteTutorial() {
        if let tutorial = CoreDataManager.shared.fetchTutorial() {
            deleteComic(comic: tutorial)
        }
    }
    
    static func deleteBookmark(uuid: String?) {
        guard let uuid = uuid else { return }
        
        deleteFile(url: getBookmarkDirectory().appendingPathComponent(uuid))
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
    
    static func getInboxDirectory() -> URL {
        return getCreateDirectory(name: "Inbox")
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
        
        files?.forEach { file in
            deleteFile(url: file)
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
    
    static func loadInbox() {
        let files = (try? FileManager.default.contentsOfDirectory(at: getInboxDirectory(), includingPropertiesForKeys: nil)) ?? []
        
        for file in files {
            guard let url = ComicFileManager.moveToBooks(url: file) else { continue }
            ComicFileManager.createComic(from: url, openInPlace: false)
            
        }
        
        clearDirectory(name: "Inbox")
    }
    
    static func clearTrash() {
        clearDirectory(name: ".Trash")
    }
    
    static func deleteFile(url: URL) {
        let fm = FileManager.default
        do {
            if(fm.fileExists(atPath: url.path))
            {
                try fm.removeItem(at: url) // WARNING: this WILL delete files
            }
        } catch {
            print("Failed to delete URL \(url): \(error)")
        }
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
                ComicFileManager.deleteBookmark(uuid: self.uuid)
                self.uuid = try ComicFileManager.createBookmark(url: url)
                CoreDataManager.shared.updateComic(comic: self)
                return url
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
