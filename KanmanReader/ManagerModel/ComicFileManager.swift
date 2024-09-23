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
    static func createComic(from url: URL, name: String? = nil, openInPlace: Bool = true, alerts: Bool = true) -> Comic? {
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
            
            if(alerts) {
                let alert = UIAlertController(
                    title: "Manhua import failed",
                    message: "Manhua was unable to be imported. Make sure that the file is a ZIP/RAR/CBR/CBZ that contains image files in the main folder. Contact support if the problem persists.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { _ in
                        // cancel action
                    }))
                alert.show()
            }
            
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
        return try accessGuardedResource(url, with: { try Unpacker(for: url).extractInfo() }, openInPlace: openInPlace) as? (cover: Data, totalPages: Int) ?? (Data(), 0)
    }
    
    static func getImages(for url: URL, openInPlace: Bool = true) throws -> [UIImage]? {
        return try accessGuardedResource(url, with: { try Unpacker(for: url).extractImages() }, openInPlace: openInPlace) as? [UIImage]
    }
    
    static func getData(for url: URL, openInPlace: Bool = true) throws -> [Data]? {
        return try accessGuardedResource(url, with: { try Unpacker(for: url).extractData() }, openInPlace: openInPlace) as? [Data]
    }
    
    static func writeToDirectory(directory: URL, data: Data, position: Int) -> URL? {
        let targetURL = directory.appending(path: "\(position)")
        
        do {
            try data.write(to: targetURL)
            return targetURL
        } catch let error {
            print("Error writing image: \(error)")
            return nil
        }
    }
    
    static func getPages(for url: URL, openInPlace: Bool = true) async -> [URL]? {
        do {
            guard let imageData = try getData(for: url, openInPlace: true) else { return nil}
            guard let readingDir = getReadingDirectory() else { return nil }
            
            var urls: [URL] = []
            for (index, data) in imageData.enumerated() {
                if let url = writeToDirectory(directory: readingDir, data: data, position: index) {
                    urls.append(url)
                }
            }
            
            if urls.compactMap({$0}).count == 0 { return nil }
            
            return urls
        }
        catch {
            print("Failed to get pages: \(error)")
            return nil
        }
    }
    
    static func getCovers(for data: [Data?]) -> [URL?] {
        var urls: [URL?] = []
        guard let coverDirectory = getCoverDirectory() else { return [] }
        
        for (index, datum) in data.enumerated() {
            if let datum = datum {
                urls.append(writeToDirectory(directory: coverDirectory, data: datum, position: index))
            }
            else {
                urls.append(nil)
            }
        }
        
        return urls
    }
    
    static func accessGuardedResource(_ url: URL, with function: () throws -> (Any), openInPlace: Bool = true) throws -> Any {
        if(!openInPlace) { return try function() }
        
        guard url.startAccessingSecurityScopedResource() else { throw BookmarkError.notSecurityScoped }
        defer { url.stopAccessingSecurityScopedResource() }
        
        return try function()
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
    
    private static func writeBookmark(url: URL) throws -> String {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = generateUUID(for: url)
            guard let bookmarkURL = getBookmarkDirectory()?.appendingPathComponent(uuid) else { throw BookmarkError.failedWrite }
            try bookmarkData.write(to: bookmarkURL)
            return uuid
        }
        catch {
            print("Error creating the bookmark: \(error)")
            throw BookmarkError.failedWrite
        }
    }
    
    static func deleteComic(comic: Comic) {
        if let url = comic.url,
           let manhuaDir = getManhuaDirectory(),
           let manhuaDirFiles = try? FileManager.default.contentsOfDirectory(at: manhuaDir, includingPropertiesForKeys: nil),
           manhuaDirFiles.contains(url) {
            deleteFile(url: url)
            clearTrash()
        }
        
        deleteFile(url: comic.bookmarkURL)
        CoreDataManager.shared.deleteComic(comic: comic)
        
    }
    
    static func deleteTutorial() {
        if let tutorial = CoreDataManager.shared.fetchTutorial() {
            deleteComic(comic: tutorial)
        }
    }
    
    static func deleteBookmark(uuid: String?) {
        guard let uuid = uuid, uuid.count > 0, let bookmarkURL = getBookmarkDirectory()?.appendingPathComponent(uuid) else { return }
        
        deleteFile(url: bookmarkURL)
    }
    
    static func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func getBookmarkDirectory() -> URL? {
        return getCreateDirectory(name: ".Bookmarks")
    }
    
    static func getManhuaDirectory() -> URL? {
        return getCreateDirectory(name: "Manhua")
    }
    
    static func getInboxDirectory() -> URL? {
        return getAppSandboxDirectory().appendingPathComponent("Inbox")
    }
    
    static func getReadingDirectory() -> URL? {
        return getCreateDirectory(baseDirectory: FileManager.default.temporaryDirectory, name: "reading")
    }
    
    private static func getCoverDirectory() -> URL? {
        return getCreateDirectory(baseDirectory: FileManager.default.temporaryDirectory, name: "covers")
    }
    
    private static func getCreateDirectory(baseDirectory: URL = getAppSandboxDirectory(), name: String) -> URL? {
        let directory = baseDirectory.appendingPathComponent(name)
        
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory.path) {
            do {
                try fm.createDirectory(atPath: directory.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Failed to create \(name) directory: \(error)")
                return nil
            }
        }
        
        return directory
    }
    
    static func deleteBookmarks() {
        guard let bookmarkDir = getBookmarkDirectory() else { return }
        let files = try? FileManager.default.contentsOfDirectory(at:  bookmarkDir, includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            deleteFile(url: file)
        }
    }
    
    private static func generateUUID(for url: URL) -> String {
        let uuid = UUID().uuidString
        return uuid
    }
    
    private static func getFileName(for url: URL?) -> String {
        guard let url = url else { return "" }
        return (url.lastPathComponent as NSString).deletingPathExtension
    }
    
    static func loadManhuaDirectory() {
        guard let manhuaDir = getManhuaDirectory() else { return }
        let files = try? FileManager.default.contentsOfDirectory(at: manhuaDir, includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            createComic(from: file, openInPlace: false, alerts: false)
        }
    }
    
    static func moveToBooks(url: URL) -> URL? {
        let fm = FileManager.default
        
        do {
            guard let newURL = getManhuaDirectory()?.appendingPathComponent(url.lastPathComponent) else { return nil }
            if(!fm.fileExists(atPath: newURL.path))
            {
                try fm.moveItem(at: url, to: newURL)
                return newURL
            }
            else { return nil }
        } catch {
            print("Failed to move file: \(error)")
            return nil
        }
    }
    
    private static func clearDirectory(name: String) {
        let fm = FileManager.default
        let files = try? FileManager.default.contentsOfDirectory(at: getAppSandboxDirectory().appendingPathComponent(name), includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            do {
                try fm.removeItem(at: file)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
    }
    
    static func clearReading() {
        let fm = FileManager.default
        let readingDir = fm.temporaryDirectory.appending(path: "reading")
        deleteFile(url: readingDir)
    }
    
    static func loadInbox() {
        guard let inboxDir = getInboxDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: inboxDir, includingPropertiesForKeys: nil)) ?? []
        
        for file in files {
            guard let url = ComicFileManager.moveToBooks(url: file) else { continue }
            ComicFileManager.createComic(from: url, openInPlace: false)
        }
        
        clearDirectory(name: "Inbox")
    }
    
    static func clearTrash() {
        clearDirectory(name: ".Trash")
    }
    
    private static func deleteFile(url: URL?) {
        guard let url = url else { return }
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
