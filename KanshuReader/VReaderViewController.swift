//
//  VReaderViewController.swift
//  KanshuReader
//
//  Created by AC on 8/25/24.
//

import UIKit

class VReaderViewController: UIViewController, Reader, UITableViewDataSource, UITableViewDelegate {
    
    var pages: [UIImage] = []
    var startPosition: Int = 0
    var position: Int {
        let cell = tableView.visibleCells.first as! ImageCell
        return cell.position
    }
    var currentImage: UIImage { return pages[position] }
    var currentPage: Page = Page()
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        
        table.backgroundColor = .red
        table.register(ImageCell.self, forCellReuseIdentifier: ImageCell.identifier)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 500
        table.separatorStyle = .none
//        table.rowHeight = 500
        
        return table
    }()
    
    required init(images: [UIImage] = [], position: Int = 0) {
        super.init(nibName: nil, bundle: nil)
        
        self.pages = images
//        self.position = position
        tableView.scrollToRow(at: IndexPath(row: position, section: 0), at: .top, animated: false)
        tableView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
        configureUI()
        tableView.reloadData()
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        cell.delegate = parent as? ReaderViewController
        cell.position = indexPath.item
        if(cell.initialImage) { cell.setImage(pages[indexPath.item]) }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pages.count
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
}
