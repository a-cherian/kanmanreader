//
//  TabBarController.swift
//  KanmanReader
//
//  Created by AC on 12/15/23.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabs()
        self.selectedIndex = 2
    }
    
    private func configureTabs() {
        
        // reader
        let documents = DocumentSelectionViewController()
        documents.tabBarItem.image = UIImage(systemName: "books.vertical.fill")
        documents.tabBarItem.title = "Library"
        let documentsNav = UINavigationController(rootViewController: documents)
        documentsNav.hidesBottomBarWhenPushed = true
        
        // vocabulary
//        let vocab = VocabViewController()
//        vocab.tabBarItem.image = UIImage(systemName: "doc.plaintext")
//        vocab.tabBarItem.title = "Saved"
//        let vocabNav = UINavigationController(rootViewController: vocab)
        
        // settings
        let settings = SettingsViewController()
        settings.tabBarItem.image = UIImage(systemName: "gearshape.fill")
        settings.tabBarItem.title = "Settings"
        let settingsNav = UINavigationController(rootViewController: settings)
        settingsNav.hidesBottomBarWhenPushed = true
        
        tabBar.backgroundColor = .black
        
        setViewControllers([documentsNav, settingsNav], animated: true)
    }
}
