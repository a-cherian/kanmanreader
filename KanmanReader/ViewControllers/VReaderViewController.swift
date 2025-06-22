//
//  VReaderViewController.swift
//  KanmanReader
//
//  Created by AC on 8/25/24.
//

import UIKit

class VReaderViewController: UIViewController, Reader, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: ReaderDelegate?
    
    var urls: [URL] = []
    var startPosition: Int = 0
    var position: Int {
        guard tableView.window != nil else { return 0 }
        
        let cell = tableView.visibleCells.first as? ImageCell
        
        if let visibleRows = tableView.indexPathsForVisibleRows, visibleRows.contains(where: { $0.item == urls.count - 1 }) {
            return urls.count - 1
        }
        
        return max(min(cell?.position ?? 0, urls.count - 1), 0)
    }
    var currentImage: UIImage? { return urls[position].loadImage() }
    var currentPage: Page = Page()
    var selectionView: Selection?
    var initialLocation: CGPoint?
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        
        table.register(ImageCell.self, forCellReuseIdentifier: ImageCell.identifier)
        table.dataSource = self
        table.delegate = self
//        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 500
        table.separatorStyle = .none
        table.separatorColor = .clear
        table.bounces = false
        
        return table
    }()
    
//    lazy var visionView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.isUserInteractionEnabled = true
//        return imageView
//    }()
    
    
    required init(urls: [URL] = [], position: Int = 0, parent: ReaderViewController? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.delegate = parent
        self.urls = urls
        
        tableView.scrollToRow(at: IndexPath(row: position, section: 0), at: .top, animated: false)
        tableView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(view: tableView)
    }
    
    func add(view addView: UIView) {
        view.addSubview(addView)
        configure(view: addView)
    }
    
    func configure(view configureView: UIView) {
        configureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            configureView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            configureView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            configureView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            configureView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
        ])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        
        cell.position = indexPath.item
//        cell.url = urls[cell.position]
        
        cell.zoomableView.setImage(urls[cell.position])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.didFlipPage()
    }
}
