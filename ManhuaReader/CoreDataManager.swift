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
}
