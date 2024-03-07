//
//  BookCell.swift
//  ManhuaReader
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
        label.textAlignment = .left
        return label
    }()
    
    lazy var coverView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "fi-sr-neutral"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var progress: UILabel = {
        let label = UILabel()
        label.text = "[Progress]"
        label.numberOfLines = 5
        label.textColor = .white
        label.textAlignment = .left
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
            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            title.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configureCoverView() {
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.centerXAnchor.constraint(equalTo: centerXAnchor),
            coverView.centerYAnchor.constraint(equalTo: centerYAnchor),
            coverView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6),
            coverView.widthAnchor.constraint(equalTo: coverView.heightAnchor),
        ])
    }
    
    func configureProgress() {
        progress.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progress.centerXAnchor.constraint(equalTo: centerXAnchor),
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

