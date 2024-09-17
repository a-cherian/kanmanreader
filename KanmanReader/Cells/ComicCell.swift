//
//  ComicCell.swift
//  KanmanReader
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
    var chapterNumber: CGFloat? = nil {
        didSet {
            if let chapterNumber = chapterNumber {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                chapterLabel.text = formatter.string(for: chapterNumber)
                chapterLabel.isHidden = false
            }
            else {
                chapterLabel.text = ""
                chapterLabel.isHidden = true
            }
        }
    }
    
    override var isSelected: Bool{
      didSet {
          if(isSelected) {
              selectView.image = UIImage(systemName: "checkmark.circle.fill")
          }
          else {
              selectView.image = UIImage(systemName: "circle")
          }
      }
    }
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.text = "[Title]"
        label.textColor = .white
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
        imageView.layer.cornerRadius = 5
        
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
    
    lazy var selectView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "circle")
        imageView.tintColor =  Constants.accentColor
        imageView.backgroundColor = .black 
        imageView.layer.cornerRadius = 35 / 2
        return imageView
    }()
    
    lazy var finishedView: UILabel = {
        let label = UILabel()
        
        label.backgroundColor = .black.withAlphaComponent(0.5)
        label.textColor = .white
        label.layer.cornerRadius = 5
        
        label.clipsToBounds = true
        label.textAlignment = .center
        label.font = Constants.zhFontBoldSmall
        label.text = "Finished"
        
        return label
    }()
    
    lazy var chapterLabel: UILabel = {
        let label = UILabel()
        
        label.backgroundColor = .black
        label.textColor = Constants.accentColor
        label.layer.cornerRadius = 5
        
        label.clipsToBounds = true
        label.textAlignment = .center
        label.font = Constants.zhFontBoldSmall
        label.text = ""
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 5
        
        
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
        contentView.addSubview(selectView)
        contentView.addSubview(chapterLabel)
    }
    
    func configureUI(frame: CGRect) {
        configureCoverView()
        configureTitle()
        configureProgress()
        configureSelectView()
        configureChapterLabel()
    }
    
    func configureCoverView() {
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: topAnchor),
            coverView.centerXAnchor.constraint(equalTo: centerXAnchor),
            coverView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor)
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
            progress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progress.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configureSelectView() {
        selectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectView.topAnchor.constraint(equalTo: coverView.topAnchor, constant: 10),
            selectView.trailingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: -10),
            selectView.heightAnchor.constraint(equalToConstant: 35),
            selectView.widthAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    func configureChapterLabel() {
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chapterLabel.topAnchor.constraint(equalTo: coverView.topAnchor),
            chapterLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            chapterLabel.heightAnchor.constraint(equalToConstant: 35),
            chapterLabel.widthAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    func setIcons(icons: [UIImage]) {
        coverView.image = icons[0]
    }
    
    @objc func didTap() {
        delegate?.didTapComic(position: tag)
    }
}

