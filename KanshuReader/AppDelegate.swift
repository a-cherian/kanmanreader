//
//  AppDelegate.swift
//  KanshuReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadDictionary()
        }
        
        self.loadSample()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "KanshuReader")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func loadDictionary() {
        let userDefaults = UserDefaults.standard
        
        let currentDictVersion = userDefaults.string(forKey: Constants.LATEST_DICT_UPDATE_KEY)
        
        if(currentDictVersion != Constants.LATEST_DICT_UPDATE) {
            print("Updating dictionary...")
            let dictFileName = "cedict_ts_" + Constants.LATEST_DICT_UPDATE
            guard let urlPath = Bundle.main.url(forResource: dictFileName, withExtension: "txt") else { return }
            var dictLines: [String] = []
            
            do {
                let dictText = try String(contentsOf: urlPath, encoding: String.Encoding.utf8)
                dictLines = dictText.components(separatedBy: "\r\n")
            }
            catch {
                return
            }
            
            CoreDataManager.shared.deleteDict()
            print("Deleting previous dictionary...")
            
            var dict: [[String]] = []

            for entry in dictLines {
                if(entry.hasPrefix("#")) { continue }
                
                let splitted = entry.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
                
                let english = splitted[1...].joined(separator: "\\")
                
                let hanzi_and_pinyin = splitted[0].split(separator: "[")
                
                let hanzi = hanzi_and_pinyin[0].split(separator: " ")
                let traditional = String(hanzi[0])
                let simplified = String(hanzi[1])
                
                let pinyin_text = String(hanzi_and_pinyin[1]).trimmingCharacters(in: CharacterSet(charactersIn: "] "))
                
                dict.append([traditional, simplified, pinyin_text, english])
            }
            
            Task {
                await CoreDataManager.shared.createDict(dictData: dict)
                userDefaults.setValue(Constants.LATEST_DICT_UPDATE, forKey: Constants.LATEST_DICT_UPDATE_KEY)
                print("Dictionary updated...")
            }
        }
    }
    
    func loadSample() {
        let userDefaults = UserDefaults.standard
        
        let loadedSample = userDefaults.string(forKey: Constants.LOADED_SAMPLE_KEY)
        
        if(loadedSample != Constants.LOADED_SAMPLE) {
            BookmarkManager.shared.createTutorial()
            userDefaults.setValue(Constants.LOADED_SAMPLE, forKey: Constants.LOADED_SAMPLE_KEY)
        }
        else {
            BookmarkManager.shared.relinkTutorial()
        }
    }

}

