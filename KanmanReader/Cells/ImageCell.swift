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
    let zoomableView = ZoomableImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(zoomableView)
        zoomableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        let bottomConstraint = zoomableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
