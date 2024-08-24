//
//  TabBarController.swift
//  KanshuReader
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
        documents.tabBarItem.title = "Books"
        let documentsNav = UINavigationController(rootViewController: documents)
        
        // vocabulary
//        let stats = StatsViewController()
//        stats.tabBarItem.image = UIImage(systemName: "doc.plaintext")
//        stats.tabBarItem.title = "Saved"
//        let statsNav = UINavigationController(rootViewController: stats)
        
        // settings
//        let settings = SettingsViewController()
//        settings.tabBarItem.image = UIImage(systemName: "gearshape.fill")
//        settings.tabBarItem.title = "Settings"
//        let settingsNav = UINavigationController(rootViewController: settings)
        
        tabBar.tintColor = Constants.accentColor
        tabBar.backgroundColor = .black
        
        setViewControllers([documentsNav], animated: true)
    }

}
