//
//  Page.swift
//  KanmanReader
//
//  Created by AC on 8/20/24.
//

import UIKit

protocol PageDelegate: AnyObject {
    @discardableResult func didTapRegion(location: CGPoint) -> Bool
}

class Page: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var position = -1
    weak var delegate: PageDelegate? = nil
    
    var initialImage: UIImage? = nil
    var singleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    var doubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    var url: URL? {
        didSet {
            if let url = url {
                setImage(url)
            }
        }
    }
    
    var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.maximumZoomScale = 4
        return view
    }()
    
    var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        addSubviews()
        configureUI()
        addGestureRecognizers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if initialImage == nil {
            let scale = scrollView.bounds.width / imageView.intrinsicContentSize.width
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
            initialImage = imageView.image
        }
    }
    
    func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    
    func configureUI() {
        configureScrollView()
        configureImageView()
    }
    
    func addGestureRecognizers() {
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.delegate = self
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(singleTapGesture)
    }
    
    func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func configureImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])
    }
    
    func setImage(_ url: URL) {
        guard let image = url.loadImage() else { return }
        
        imageView.image = image
        initialImage = nil
    }
    
    func centerContent() {
        let rectContent = CGRect(x: 0, y: 0, width: (imageView.image?.size.width ?? 0) * scrollView.zoomScale, height: (imageView.image?.size.height ?? 0) * scrollView.zoomScale);

        scrollView.contentSize = rectContent.size;

        let fOffsetWidth = (rectContent.size.width < scrollView.bounds.size.width) ? (scrollView.bounds.size.width - rectContent.size.width)/2 : 0;
        let fOffsetHeight = (rectContent.size.height < scrollView.bounds.size.height) ? (scrollView.bounds.size.height - rectContent.size.height)/2 : 0;

        scrollView.contentInset = UIEdgeInsets(top: fOffsetHeight, left: fOffsetWidth, bottom: fOffsetHeight, right: fOffsetWidth)
    }
    
    @objc func didDoubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        if scrollView.zoomScale >= scrollView.minimumZoomScale * 2 - 0.01 {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let height = scrollView.frame.size.height / (2 * scrollView.minimumZoomScale)
            let width = scrollView.frame.size.width / (2 * scrollView.minimumZoomScale)
            
            let zoomRect = CGRect(origin: CGPoint(x: center.x - (width / 2.0), y: center.y - (height / 2.0)), size: CGSize(width: width, height: height))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    @objc func didSingleTap(_ gestureRecognizer: UIGestureRecognizer) {
        let vision = delegate?.didTapRegion(location: gestureRecognizer.location(in: imageView)) ?? false
        if(vision) { return }
        if scrollView.zoomScale != scrollView.minimumZoomScale { return }
        
        // TO DO: tap sides to page left/right
//        let touchCenterX = gestureRecognizer.location(in: gestureRecognizer.view).x
//        let viewCenterX = gestureRecognizer.view?.bounds.midX ?? 0
//        let margin = (gestureRecognizer.view?.bounds.width ?? 0) / 6
        
//        if(touchCenterX > viewCenterX + margin) { pageDelegate?.pageRight() }
//        if(touchCenterX < viewCenterX - margin) { pageDelegate?.pageLeft() }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        return
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
