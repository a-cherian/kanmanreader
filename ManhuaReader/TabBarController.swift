//
//  TabBarController.swift
//  ManhuaReader
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
        // web view
        let calendar = CalendarViewController()
        calendar.tabBarItem.image = UIImage(systemName: "calendar")
        calendar.tabBarItem.title = "Calendar"
        let calendarNav = UINavigationController(rootViewController: calendar)
        
        // documents
        let entryList = EntryListViewController()
        entryList.tabBarItem.image = UIImage(systemName: "line.3.horizontal")
        entryList.tabBarItem.title = "Entry List"
        let entryListNav = UINavigationController(rootViewController: entryList)
        
        // reader
        let documents = DocumentSelectionViewController()
        documents.tabBarItem.image = UIImage(systemName: "books.vertical.fill")
        documents.tabBarItem.title = "Documents"
        let documentsNav = UINavigationController(rootViewController: documents)
        
        // vocabulary
        let stats = StatsViewController()
        stats.tabBarItem.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        stats.tabBarItem.title = "Statistics"
        let statsNav = UINavigationController(rootViewController: stats)
        
        // settings
        let settings = SettingsViewController()
        settings.tabBarItem.image = UIImage(systemName: "gearshape.fill")
        settings.tabBarItem.title = "Settings"
        let settingsNav = UINavigationController(rootViewController: settings)
        
        tabBar.tintColor = Constants.accentColor
        tabBar.backgroundColor = .black
        
        setViewControllers([documentsNav], animated: true)
    }

}
