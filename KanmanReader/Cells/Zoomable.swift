//
//  ZoomableImageView.swift
//  KanmanReader
//
//  Created by AC on 6/12/25.
//

import UIKit

class ZoomableImageView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var initialImage: UIImage? = nil
    private var doubleTapGesture: UITapGestureRecognizer!
    weak var aspectConstraint: NSLayoutConstraint? = nil
    
    let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.maximumZoomScale = 4
        view.minimumZoomScale = 1
        return view
    }()
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])
        
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if initialImage == nil {
            let scale = bounds.width / imageView.intrinsicContentSize.width
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
            initialImage = imageView.image
        }
    }
    
//    func setImage(_ image: UIImage) {
    func setImage(_ url: URL, setAspect: Bool = true) {
        guard let image = url.loadImage() else { return }
        imageView.image = image
        initialImage = nil
        
        if setAspect {
            let aspectRatio = image.size.height / image.size.width
            aspectConstraint?.isActive = false
            aspectConstraint = heightAnchor.constraint(equalTo: widthAnchor, multiplier: aspectRatio)
            aspectConstraint?.priority = .required
            guard let aspectConstraint = aspectConstraint else { return }
            NSLayoutConstraint.activate([aspectConstraint])
        }
        
        DispatchQueue.main.async {
            self.updateZoomScale()
        }
    }
    
    private func updateZoomScale() {
        guard let image = imageView.image else { return }

        let imageSize = image.size
        let viewSize = bounds.size

        guard viewSize.width > 0 && viewSize.height > 0 else { return }

        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = minScale
    }


    @objc func didDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale >= scrollView.minimumZoomScale * 2 - 0.01 {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let center = gestureRecognizer.location(in: imageView)
            let height = scrollView.frame.size.height / (2 * scrollView.minimumZoomScale)
            let width = scrollView.frame.size.width / (2 * scrollView.minimumZoomScale)
            let zoomRect = CGRect(origin: CGPoint(x: center.x - width/2, y: center.y - height/2), size: CGSize(width: width, height: height))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }

    func centerContent() {
        guard let imageSize = imageView.image?.size else { return }
        let contentWidth = imageSize.width * scrollView.zoomScale
        let contentHeight = imageSize.height * scrollView.zoomScale
        let offsetX = max((scrollView.bounds.width - contentWidth) / 2, 0)
        let offsetY = max((scrollView.bounds.height - contentHeight) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }
}
