//
//  AboutViewController.swift
//  KanshuReader
//
//  Created by AC on 9/4/24.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var tableView: SizingTableView = {
        let table = SizingTableView()
        
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        table.layer.cornerRadius = 10
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = .white
        
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkAccentColor
        view.layoutMargins = UIEdgeInsets(top: 50, left: 5, bottom: 50, right: 5)
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(tableView)
    }
    
    func configureUI() {
        configureTableView()
    }
    
    func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    func getAppInfo() -> NSMutableAttributedString {
        let headerText = NSMutableAttributedString(string: "")

        let appName = NSMutableAttributedString(string: "Kanshu Reader\n")
        appName.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontBoldLarge as Any, range: NSRange(location: 0, length: appName.length))
        
        let version = NSAttributedString(string: "v" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""))
        let copyright = NSAttributedString(string: "\n© 2024 Akash Cherian")

        headerText.append(appName)
        headerText.append(version)
        headerText.append(copyright)

        return headerText
    }
    
    func getCredits() -> NSMutableAttributedString {
        let creditText = NSMutableAttributedString(string: "")

        let appName = NSMutableAttributedString(string: "Acknowledgements\n\n")
        appName.addAttribute(NSAttributedString.Key.font, value: Constants.zhFontBoldSmall as Any, range: NSRange(location: 0, length: appName.length))
        let ccceDict = NSAttributedString(string: "CC-CEDICT Dictionary from mdbg.net, distributed under a Creative Commons license, see http://creativecommons.org/licenses/by-sa/4.0/ for details.")

        creditText.append(appName)
        creditText.append(ccceDict)

        return creditText
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .white
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textColor = .black
        
        if(indexPath.item == 0) {
            cell.textLabel?.attributedText = getAppInfo()
            cell.textLabel?.textAlignment = .center
        }
        if(indexPath.item == 1) {
            cell.textLabel?.attributedText = getCredits()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0) { return 2 }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
