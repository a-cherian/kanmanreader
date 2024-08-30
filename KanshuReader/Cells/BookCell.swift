//
//  BookCell.swift
//  KanshuReader
//
//  Created by AC on 12/23/23.
//

import UIKit

protocol BookCellDelegate: AnyObject {
    func didTapBook(position: Int)
}

class BookCell: UICollectionViewCell {
    
    weak var delegate: BookCellDelegate?
    static let identifier = "book"
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.text = "[Title]"
        label.textColor = .white
        label.textAlignment = .center
        label.font = label.font.withSize(15)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        
        return label
    }()
    
    lazy var coverView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "fi-sr-neutral"))
        imageView.tintColor = .white
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var progress: UILabel = {
        let label = UILabel()
        label.text = "[Pages]"
        label.textColor = .white
        label.textAlignment = .center
        label.font = label.font.withSize(15)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = Constants.accentColor.cgColor
        contentView.layer.borderWidth = 3
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)
        
        addSubviews()
        configureUI(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        contentView.addSubview(title)
        contentView.addSubview(coverView)
        contentView.addSubview(progress)
    }
    
    func configureUI(frame: CGRect) {
        configureTitle()
        configureCoverView()
        configureProgress()
    }
    
    func configureTitle() {
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            title.bottomAnchor.constraint(equalTo: coverView.topAnchor, constant: -15),
            title.heightAnchor.constraint(lessThanOrEqualToConstant: 40)
        ])
    }
    
    func configureCoverView() {
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.centerXAnchor.constraint(equalTo: centerXAnchor),
            coverView.bottomAnchor.constraint(equalTo: progress.topAnchor, constant: -10),
            coverView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -30)
        ])
    }
    
    func configureProgress() {
        progress.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            progress.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setIcons(icons: [UIImage]) {
        coverView.image = icons[0]
    }
    
    @objc func didTap() {
        delegate?.didTapBook(position: tag)
    }
}

