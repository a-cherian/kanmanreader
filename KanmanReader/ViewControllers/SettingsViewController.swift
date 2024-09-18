//
//  SettingsViewController.swift
//  KanmanReader
//
//  Created by AC on 9/17/24.
//

import UIKit

class SettingsViewController: UITableViewController {
    let NAME_POS = 0
    let VIEW_POS = 0
    
    let headers = ["Library", "Dictionary Definitions", "Info"]
    var settings: [[(name: String,
                     view: UIView?,
                     action: (() -> ())?)]] = [[("Display chapter numbers", nil, nil)],
                                               [("Display both scripts", nil, nil), ("Display traditional first", nil, nil)],
                                               [("About", nil, nil), ("Tutorial", nil, nil)]]
    let appPreferences = AppPreferences(from: nil)
    
    let chapterNumberButton = {
        let sw = UISwitch()
        sw.onTintColor = .accent
        sw.addTarget(self, action: #selector(toggleChapterNumber(_:)), for: .valueChanged)
        return sw
    }()
    
    let bothScriptsButton = {
        let sw = UISwitch()
        sw.onTintColor = .accent
        sw.addTarget(self, action: #selector(toggleBothScripts(_:)), for: .valueChanged)
        return sw
    }()
    
    let traditionalButton = {
        let sw = UISwitch()
        sw.onTintColor = .accent
        sw.addTarget(self, action: #selector(toggleTraditional(_:)), for: .valueChanged)
        return sw
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        setTraditionalOptionText()
        configureAccessoryViews()
        configureActions()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        hidesBottomBarWhenPushed = false
    }
    
    
    func configureAccessoryViews() {
        settings[0][0].view = chapterNumberButton
        settings[1][0].view = bothScriptsButton
        settings[1][1].view = traditionalButton
        
        chapterNumberButton.isOn = appPreferences.displayChapterNumbers
        bothScriptsButton.isOn = appPreferences.displayBothScripts
        traditionalButton.isOn = appPreferences.prioritizeTraditional
    }
    
    func configureActions() {
        settings[2][0].action = openAbout
        settings[2][1].action = openTutorial
    }
    
    func setTraditionalOptionText() {
        settings[1][1].name = appPreferences.displayBothScripts ? "Display traditional first" : "Display traditional"
        tableView.reloadData()
    }
    
    @objc func toggleChapterNumber(_ sender: UISwitch) {
        appPreferences.displayChapterNumbers = sender.isOn
        savePreferences()
    }
    
    @objc func toggleBothScripts(_ sender: UISwitch) {
        appPreferences.displayBothScripts = sender.isOn
        setTraditionalOptionText()
        savePreferences()
    }
    
    @objc func toggleTraditional(_ sender: UISwitch) {
        appPreferences.prioritizeTraditional = sender.isOn
        savePreferences()
    }
    
    func openAbout() {
        let aboutViewController = AboutViewController()
        if let presentationController = aboutViewController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersEdgeAttachedInCompactHeight = true
            presentationController.prefersGrabberVisible = true
            presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        self.present(aboutViewController, animated: true)
    }
    
    func openTutorial() {
        guard let tutorial = ComicFileManager.createTutorial() else { return }
        if let url = tutorial.url {
            tutorial.lastOpened = Date()
            CoreDataManager.shared.updateComic(comic: tutorial)
            if let images = try? ComicFileManager.getImages(for: url) {
                self.navigationController?.pushViewController(ReaderViewController(images: images, comic: tutorial), animated: true)
                return
            }
        }
        else {
            let alert = UIAlertController(
                title: "Could not open tutorial",
                message: "Contact support if the problem persists.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                    // cancel action
                }))
            present(alert, animated: true, completion: nil)
        }
    }

    func savePreferences() {
        UserDefaults.standard.setValue(appPreferences.string, forKey: Constants.APP_PREFERENCES_KEY)
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override public func tableView(_ tableView: UITableView,
                                   numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection
                                section: Int) -> String? {
       return headers[section]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .black
        header.tintColor = .clear
        
        let view = UIView()
        view.backgroundColor = .white
        
        header.backgroundView = view
    }

    override public func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.section][indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .none
        
        cell.textLabel?.text = setting.name
        cell.accessoryView = setting.view
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        settings[indexPath.section][indexPath.row].action?()
    }
}
