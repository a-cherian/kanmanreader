//
//  SceneDelegate.swift
//  KanmanReader
//
//  Created by AC on 12/15/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let URLContexts = connectionOptions.urlContexts
        if let urlContext = URLContexts.first {
            ComicFileManager.createComic(from: urlContext.url, openInPlace: urlContext.options.openInPlace)
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        configureNavbarAppearance()
        configureToolbarAppearance()

        window.rootViewController = TabBarController()
        
        self.window = window
        window.makeKeyAndVisible()
        window.overrideUserInterfaceStyle = .dark
        window.tintColor = .accent
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        importFile: if let urlContext = URLContexts.first {
            var url = urlContext.url
            if(!urlContext.options.openInPlace) {
                guard let movedURL = ComicFileManager.moveToBooks(url: urlContext.url) else { break importFile }
                url = movedURL
            }
            
            if let comic = ComicFileManager.createComic(from: url, openInPlace: urlContext.options.openInPlace),
               let tabBarController = self.window?.rootViewController as? UITabBarController,
               let navController = tabBarController.selectedViewController as? UINavigationController {
                navController.openReader(with: comic, openInPlace: urlContext.options.openInPlace)
            }
        }
        ComicFileManager.loadInbox()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

