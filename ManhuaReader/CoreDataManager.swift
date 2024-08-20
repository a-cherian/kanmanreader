//
//  CoreDataManager.swift
//  ManhuaReader
//
//  Created by AC on 12/15/23.
//

import CoreData

struct CoreDataManager {
    
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ManhuaReader")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    @discardableResult
    func createBook(name: String, lastPage: Int, totalPages: Int, cover: Data, url: URL, lastOpened: Date) -> Book? {
        let context = persistentContainer.viewContext
        
        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: context) as! Book
        
        book.name = name
        book.lastPage = Int64(lastPage)
        book.totalPages = Int64(totalPages)
        book.cover = cover
        book.url = url
        book.lastOpened = lastOpened
        
        do {
            try context.save()
            return book
        } catch let createError {
            print("Failed to create: \(createError)")
        }
        
        return nil
    }
    
    func fetchBooks() -> [Book]? {
        let context = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        
        do {
            let books = try context.fetch(fetchRequest)
            return books
        } catch let fetchError {
            print("Failed to fetch: \(fetchError)")
        }
        
        return nil
    }
    
    func updateBook(book: Book?) {
        guard let book = book else { return }
        let context = persistentContainer.viewContext
        
        do {
            try context.save()
        } catch let createError {
            print("Failed to update: \(createError)")
        }
    }
    
    func deleteBook(book: Book) {
        let context = persistentContainer.viewContext
        context.delete(book)
        
        do {
            try context.save()
        } catch let saveError {
            print("Failed to update: \(saveError)")
        }
    }
    
    func deleteBook(for url: URL) {
        let context = persistentContainer.viewContext
        
        let request = Book.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", argumentArray: [url])
        
        do {
            let results = try context.fetch(request)
            
            results.forEach { book in
                deleteBook(book: book)
            }
            
            try context.save()
        }
        catch {
            debugPrint(error)
        }
    }
    
    func deleteAllBooks() {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Book")
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
    
    func createDict(dictData: [[String]]) async -> Bool {
        // Create a private context
        let context = persistentContainer.newBackgroundContext()
        
        do {
            let res = try await context.perform {
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
    
//    func fetchEntryObjects(forPredicate: NSPredicate) -> [TranslationEntry] {
//        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
//        fetchRequest.predicate = forPredicate
//        
//        do {
//            let results = try DataController.sharedInstance.getContext().fetch(fetchRequest)
//            
//            return results
//        }
//        catch {
//            debugPrint(error)
//            return []
//        }
//    }
//    public func translationsFor(simplifiedChinese: String) -> [Translation] {
//        let simplifiedPredicate = NSPredicate(format: "simplified == %@", argumentArray: [simplifiedChinese])
//        
//        return self.translationsFor(entryPredicate: simplifiedPredicate)
//    }
//    
//    public func translationsFor(chinese: String) -> [Translation] {
//        let chinesePredicate = NSPredicate(format: "(simplified == %@) OR (traditional == %@)", argumentArray: [chinese, chinese])
//        
//        return self.translationsFor(entryPredicate: chinesePredicate)
//    }
//    
//    public func translationsContaining(simplifiedChinese: String) -> [Translation] {
//        let simplifiedPredicate = NSPredicate(format: "simplified CONTAINS %@", argumentArray: [simplifiedChinese])
//        
//        return self.translationsFor(entryPredicate: simplifiedPredicate)
//    }
//    
//    public func translationsFor(traditionalChinese: String) -> [Translation] {
//        let traditionalPredicate = NSPredicate(format: "traditional == %@", argumentArray: [traditionalChinese])
//        
//        return self.translationsFor(entryPredicate: traditionalPredicate)
//    }
//    
//    public func translationsContaining(traditionalChinese: String) -> [Translation] {
//        let traditionalPredicate = NSPredicate(format: "traditional CONTAINS %@", argumentArray: [traditionalChinese])
//        
//        return self.translationsFor(entryPredicate: traditionalPredicate)
//    }
}
