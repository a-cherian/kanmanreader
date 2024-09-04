//
//  CoreDataManager.swift
//  KanshuReader
//
//  Created by AC on 12/15/23.
//

import CoreData

struct CoreDataManager {
    
    static let shared = CoreDataManager()
     
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "KanshuReader")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    @discardableResult
    func createComic(name: String, lastPage: Int = 0, totalPages: Int, cover: Data, url: URL, lastOpened: Date = Date(), prefs: ReaderPreferences = ReaderPreferences(), uuid: String? = "") -> Comic? {
        let context = persistentContainer.viewContext
        
        let comic = NSEntityDescription.insertNewObject(forEntityName: "Comic", into: context) as! Comic
        
        comic.name = name
        comic.lastPage = Int64(lastPage)
        comic.totalPages = Int64(totalPages)
        comic.cover = cover
        comic.url = url
        comic.lastOpened = lastOpened
        comic.preferences = prefs.string
        comic.uuid = uuid
        
        do {
            try context.save()
            return comic
        } catch let createError {
            print("Failed to create: \(createError)")
        }
        
        return nil
    }
    
    func fetchComic(name: String) -> Comic? {
        let predicate = NSPredicate(format: "name == %@", argumentArray: [name])
        return fetchComic(predicate: predicate)
    }
    
    func fetchComic(url: URL?) -> Comic? {
        guard let url = url else { return nil }
        let predicate = NSPredicate(format: "url == %@", argumentArray: [url])
        return fetchComic(predicate: predicate)
    }
    
    func fetchComic(predicate: NSPredicate) -> Comic? {
        let context = persistentContainer.viewContext
        
        let request = Comic.fetchRequest()
        request.predicate = predicate
        
        do {
            let results = try context.fetch(request)
            return results.first
        }
        catch {
            debugPrint("Failed to fetch: \(error)")
        }
        
        return nil
    }
    
    func fetchComics() -> [Comic]? {
        let context = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<Comic>(entityName: "Comic")
        
        do {
            let comics = try context.fetch(fetchRequest)
            return comics
        } catch let fetchError {
            print("Failed to fetch: \(fetchError)")
        }
        
        return nil
    }
    
    func fetchTutorial() -> Comic? {
        
        let context = persistentContainer.viewContext
        
        let request = Comic.fetchRequest()
        request.predicate = NSPredicate(format: "url CONTAINS %@", argumentArray: [Constants.TUTORIAL_FILENAME])
        
        do {
            let results = try context.fetch(request)
            return results.first
        }
        catch {
            debugPrint(error)
        }
        
        return nil
    }
    
    func updateComic(comic: Comic?) {
        guard let _ = comic else { return }
        let context = persistentContainer.viewContext
        
        do {
            try context.save()
        } catch let createError {
            print("Failed to update: \(createError)")
        }
    }
    
    func deleteComic(comic: Comic) {
        let context = persistentContainer.viewContext
        context.delete(comic)
        
        do {
            try context.save()
        } catch let saveError {
            print("Failed to update: \(saveError)")
        }
    }
    
    func deleteComic(for url: URL) {
        let context = persistentContainer.viewContext
        
        let request = Comic.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", argumentArray: [url])
        
        do {
            let results = try context.fetch(request)
            
            results.forEach { comic in
                deleteComic(comic: comic)
            }
            
            try context.save()
        }
        catch {
            debugPrint("Failed to delete: \(error)")
        }
    }
    
    func deleteAllComics() {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Comic")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch let saveError {
            print("Failed to update: \(saveError)")
        }
    }
    
    @discardableResult
    func createEntry(traditional: String, simplified: String, pinyin: String, definition: String) -> DictEntry? {
        let context = persistentContainer.newBackgroundContext()
        
        let entry = NSEntityDescription.insertNewObject(forEntityName: "DictEntry", into: context) as! DictEntry
        
        entry.traditional = traditional
        entry.simplified = simplified
        entry.pinyin = pinyin
        entry.definition = definition
        
        do {
            try context.save()
            return entry
        } catch let createError {
            print("Failed to create: \(createError)")
        }
        
        return nil
    }
    
    @discardableResult
    func createDict(dictData: [[String]]) async -> Bool {
        // Create a private context
        let context = persistentContainer.newBackgroundContext()
        
        do {
            let _ = try await context.perform {
                var i = 0
                let batchRequest = NSBatchInsertRequest(entityName: "DictEntry", dictionaryHandler: { dict in
                    if i < dictData.count {
                        // Create data. The current Item has only one property, timestamp, of type Date.
                        let entry = ["traditional": dictData[i][0], "simplified": dictData[i][1], "pinyin": dictData[i][2], "definition": dictData[i][3]]
                        dict.setDictionary(entry)
                        i += 1
                        return false
                    }
                    return true
                })
                batchRequest.resultType = .statusOnly
                let result = try context.execute(batchRequest) as! NSBatchInsertResult
                return result.result as! Bool
            }
        }
        catch let createError {
            print("Failed to create: \(createError)")
        }
        return false
    }
    
    func deleteDict() {
        let context = persistentContainer.newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DictEntry")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch let saveError {
            print("Failed to update: \(saveError)")
        }
    }
    
    func fetchDict() -> [DictEntry]? {
        let context = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<DictEntry>(entityName: "DictEntry")
        
        do {
            let dict = try context.fetch(fetchRequest)
            return dict
        } catch let fetchError {
            print("Failed to fetch: \(fetchError)")
        }
        
        return nil
    }
    
    func translationFor(chinese: String) -> [DictEntry] {
        let predicate = NSPredicate(format: "(simplified == %@) OR (traditional == %@)", argumentArray: [chinese, chinese])
        
        return fetchEntryFor(predicate: predicate)
    }
    
    func translationFor(traditional: String) -> [DictEntry] {
        let predicate = NSPredicate(format: "traditional == %@", argumentArray: [traditional])
        
        return fetchEntryFor(predicate: predicate)
    }
    
    func translationFor(simplified: String) -> [DictEntry] {
        let predicate = NSPredicate(format: "simplified == %@", argumentArray: [simplified])
        
        return fetchEntryFor(predicate: predicate)
    }
    
    func fetchEntryFor(predicate: NSPredicate) -> [DictEntry] {
        let context = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<DictEntry>(entityName: "DictEntry")
        fetchRequest.predicate = predicate
        
        do {
            let entries = try context.fetch(fetchRequest)
            return entries
        } catch let fetchError {
            print("Failed to fetch: \(fetchError)")
        }
        return []
    }
}
