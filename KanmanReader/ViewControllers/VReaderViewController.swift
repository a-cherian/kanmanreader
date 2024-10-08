//
//  VReaderViewController.swift
//  KanmanReader
//
//  Created by AC on 8/25/24.
//

import UIKit

class VReaderViewController: UIViewController, Reader, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: PageDelegate?
    weak var rDelegate: ReaderDelegate?
    
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
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        
        table.register(ImageCell.self, forCellReuseIdentifier: ImageCell.identifier)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 500
        table.separatorStyle = .none
        table.separatorColor = .clear
        table.bounces = false
        
        return table
    }()
    
    lazy var visionView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    required init(urls: [URL] = [], position: Int = 0, parent: ReaderViewController? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.delegate = parent
        self.rDelegate = parent
        self.urls = urls

        addGestureRecognizers()
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        stopVisionMode()
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
    
    func addGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        visionView.addGestureRecognizer(singleTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        visionView.addGestureRecognizer(panGesture)
    }
    
    func startVisionMode(image: UIImage) {
        tableView.removeFromSuperview()
        visionView.image = image
        add(view: visionView)
    }
    
    func stopVisionMode() {
        visionView.removeFromSuperview()
        add(view: tableView)
    }
    
    @objc func didSingleTap(_ gestureRecognizer: UIGestureRecognizer) {
        delegate?.didTapRegion(location: gestureRecognizer.location(in: visionView))
    }
    
    @objc func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if(gestureRecognizer.state == .changed) {
            stopVisionMode()
            
            let translation = gestureRecognizer.translation(in: visionView)
            let velocity = gestureRecognizer.velocity(in: visionView)
            let scaleFactor: CGFloat = 0.0075
            let scaledVelocity = abs(velocity.y) * scaleFactor
            
            let minBounded = max(self.tableView.contentOffset.y - translation.y * scaledVelocity, 0)
            let boundedOffsetY = min(minBounded, self.tableView.contentSize.height - self.tableView.frame.size.height)
            let newOffset = CGPoint(x: self.tableView.contentOffset.x, y: boundedOffsetY)
            
            let row = self.tableView.indexPathForRow(at: newOffset)
            
            if let firstCell = tableView.visibleCells.first, row == self.tableView.indexPath(for: firstCell) {
                self.tableView.setContentOffset(newOffset, animated: false)
            }
            else if let row = row {
                self.tableView.scrollToRow(at: row, at: .top, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        
        cell.delegate = parent as? ReaderViewController
        cell.position = indexPath.item
        cell.url = urls[cell.position]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        rDelegate?.didFlipPage()
    }
}
