//
//  ImageCell.swift
//  KanmanReader
//
//  Created by AC on 8/26/24.
//

import UIKit

class ImageCell: UITableViewCell {
    
    static let identifier = "page"
    
    var position = -1
    weak var delegate: PageDelegate? = nil
    var url: URL? {
        didSet {
            if let url = url, let image = url.loadImage() {
                setImage(image)
            }
        }
    }
    
    weak var singleTapGesture: UITapGestureRecognizer?
    
    weak var aspectConstraint: NSLayoutConstraint? = nil
    
    var pageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        addSubviews()
        configureUI()
        addGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        url = nil
    }
    
    func addSubviews() {
        contentView.addSubview(pageView)
    }
    
    func configureUI() {
        configurePageView()
        
    }
    
    func addGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.delegate = self
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        pageView.addGestureRecognizer(singleTapGesture)
    }
    
    func configurePageView() {
        pageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).withPriority(999),
            pageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func setImage(_ image: UIImage) {
        pageView.image = image;
        let aspectRatio = image.size.height / image.size.width
        aspectConstraint?.isActive = false
        aspectConstraint = pageView.heightAnchor.constraint(equalTo: pageView.widthAnchor, multiplier: aspectRatio)
        guard let aspectConstraint = aspectConstraint else { return }
        NSLayoutConstraint.activate([aspectConstraint])
    }
    
    @objc func didSingleTap(_ gestureRecognizer: UIGestureRecognizer) {
        let vision = delegate?.didTapRegion(location: gestureRecognizer.location(in: pageView)) ?? false
        if(vision) { return }
    }
}
