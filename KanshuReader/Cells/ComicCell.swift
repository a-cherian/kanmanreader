//
//  ComicCell.swift
//  KanshuReader
//
//  Created by AC on 12/23/23.
//

import UIKit

protocol ComicCellDelegate: AnyObject {
    func didTapComic(position: Int)
}

class ComicCell: UICollectionViewCell {
    
    weak var delegate: ComicCellDelegate?
    static let identifier = "comic"
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.text = "[Title]"
        label.textColor = .black
        label.textAlignment = .center
        label.font = label.font.withSize(15)
        label.lineBreakMode = .byTruncatingMiddle
        
        return label
    }()
    
    lazy var coverView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "fi-sr-neutral"))
        
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        imageView.layer.borderWidth = 3
        
        return imageView
    }()
    
    lazy var progress: UILabel = {
        let label = UILabel()
        label.text = "[Pages]"
        label.textColor = .black
        label.textAlignment = .center
        label.font = label.font.withSize(15)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)
        
        addSubviews()
        configureUI(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        contentView.addSubview(coverView)
        contentView.addSubview(title)
        contentView.addSubview(progress)
    }
    
    func configureUI(frame: CGRect) {
        configureCoverView()
        configureTitle()
        configureProgress()
    }
    
    func configureCoverView() {
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            coverView.centerXAnchor.constraint(equalTo: centerXAnchor),
            coverView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -30)
        ])
    }
    
    func configureTitle() {
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            title.heightAnchor.constraint(lessThanOrEqualToConstant: 40)
        ])
    }
    
    func configureProgress() {
        progress.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progress.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progress.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setIcons(icons: [UIImage]) {
        coverView.image = icons[0]
    }
    
    @objc func didTap() {
        delegate?.didTapComic(position: tag)
    }
}

