//
//  Page.swift
//  KanmanReader
//
//  Created by AC on 8/20/24.
//

import UIKit

class Page: UIViewController {
    var zoomableView = ZoomableImageView()
    var position = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(zoomableView)
        zoomableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            zoomableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            zoomableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        let bottomConstraint = zoomableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true
    }
}
