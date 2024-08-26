//
//  VReaderViewController.swift
//  KanshuReader
//
//  Created by AC on 8/25/24.
//

import UIKit

class VReaderViewController: UIViewController, Reader {
    var pages: [UIImage] = []
    var position: Int = 0
    var currentImage: UIImage { return pages[position] }
    var currentPage: Page = Page()
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        
        table.backgroundColor = .red
        
        return table
    }()
    
    required init(images: [UIImage] = [], position: Int = 0) {
        super.init(nibName: nil, bundle: nil)
        
        self.pages = images
        self.position = position
        self.currentPage = createPage(position: position)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
        ])
    }
    
    func createPage(position: Int) -> Page {
        let newPage = Page()
        newPage.setImage(pages[position])
        newPage.position = position
        newPage.delegate = self.presentingViewController as? ReaderViewController
        
        return newPage
    }
}
