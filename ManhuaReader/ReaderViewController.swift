//
//  ReaderViewController.swift
//  ManhuaReader
//
//  Created by AC on 12/16/23.
//

import UIKit
import Vision

class ReaderViewController: UIViewController, ImageScrollViewDelegate {
    
    
    private var dataSource: [UIImage] = [UIImage(systemName: "calendar") ?? UIImage(), UIImage(systemName: "plus.diamond") ?? UIImage(), UIImage(systemName: "calendar") ?? UIImage()]
    var position = 0
    
    var ocrEnabled = false {
        didSet {
            if(ocrEnabled) { ocrButton.backgroundColor = .systemMint }
            else { ocrButton.backgroundColor = .white }
        }
    }
    var selectStart = CGPoint(x: 0, y: 0)
    var selectRect: CGRect? = nil
    
    lazy var reader: ImageScrollView = {
        let view = ImageScrollView()
        view.imageScrollViewDelegate = self
        return view
    }()
    
//    lazy var ocrButton: UIButton = {
//        let button = UIButton()
//        
//        button.setImage(UIImage(systemName: "rectangle.and.text.magnifyingglass"), for: .normal)
//        button.backgroundColor = .white
//        button.tintColor = .black
//        
//        button.addTarget(self, action: #selector(didTapOCR), for: .touchUpInside)
//        
//        return button
//    }()
    
    lazy var ocrButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        
        button.setImage(UIImage(systemName: "rectangle.and.text.magnifyingglass"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .black
        
        button.addTarget(self, action: #selector(didTapOCR), for: .touchUpInside)
        
        return button
    }()
    
    lazy var backButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 35))
        
        button.setImage(UIImage(systemName: "arrow.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.tintColor = .white
        
        button.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        return button
    }()
        
    @objc func backAction(_ sender: UIButton) {
       self.navigationController?.popViewController(animated: true)
    }
    
    init(images: [UIImage] = []) {
        self.dataSource = images
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: ocrButton)
        
        addSubviews()
        configureUI()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ocrButton.makeCircular()
    }
    
    func addSubviews() {
        view.addSubview(reader)
        view.addSubview(ocrButton)
    }
    
    func configureUI() {
        configureReader()
    }
    
    func configureReader() {
        reader.setup()
        let image = dataSource[position]
        reader.display(image: image)
        reader.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            reader.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            reader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func pageLeft() {
        if(position + 1 < dataSource.count)
        {
            position += 1
            let image = dataSource[position]
            reader.display(image: image)
        }
    }
    
    func pageRight() {
        if(position - 1 >= 0) {
            position -= 1
            let image = dataSource[position]
            reader.display(image: image)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Stop scrollView sliding:
//        targetContentOffset.pointee = scrollView.contentOffset
        let width = reader.contentSize.width - reader.bounds.width
        let height = reader.contentSize.height + reader.bounds.height
        let contentOffsetBounds = CGRect(x: 0, y: -reader.bounds.height / 2, width: width, height: height)
        let inBounds = contentOffsetBounds.contains(reader.contentOffset)
        if(inBounds) { return }
        
        // calculate conditions:
        let swipeVelocityThreshold: CGFloat = 3
        
        if(velocity.x > swipeVelocityThreshold)
        {
            pageRight()
        }
        if(velocity.x < -swipeVelocityThreshold) {
            pageLeft()
        }

    }
    
    func imageScrollViewDidChangeOrientation(imageScrollView: ImageScrollView) {
        
    }
    
    @objc func didTapOCR() {
        reader.isScrollEnabled = !reader.isScrollEnabled
        ocrEnabled = !ocrEnabled
        
        let zoomedImage = dataSource[position].crop(from: reader)
        guard let cgImage = zoomedImage.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else { return }
            
            let text = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: ", ")
            
            self.getBoxes(observations: observations, image: zoomedImage)

            self.presentDictionary(text: text)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant"]

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
        print("OCR")
    }
    
    func presentDictionary(text: String) {
        let dictionaryViewController = DictionaryViewController(text: text)
        if let presentationController = dictionaryViewController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
        }
        
        self.present(dictionaryViewController, animated: true)
    }
    
    func getBoxes(observations: [VNRecognizedTextObservation], image: UIImage) {
        let boundingRects: [CGRect] = observations.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return .zero }

            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)

            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero

            // Convert the rectangle from normalized coordinates to image coordinates.
            return VNImageRectForNormalizedRect(boundingBox, Int(image.size.width), Int(image.size.height))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(!ocrEnabled) { return }
        
        guard let touch = touches.first else { return }
        selectStart = touch.location(in: reader)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(!ocrEnabled) { return }
//        guard let touch = touches.first else { return }
//        let selectEnd = touch.location(in: reader)
//        let selectWidth = abs(selectStart.x - selectEnd.x)
//        let selectHeight = abs(selectStart.y - selectEnd.y)
//        let upperRight = CGPoint(x: min(selectStart.x, selectEnd.x), y: min(selectStart.y, selectEnd.y))
//            selection.transform = CGAffineTransformIdentity
//            selection.transform = CGAffineTransformTranslate(selection.transform, upperRight.x, upperRight.y)
//            if selectWidth != 0 && selectHeight != 0 { selection.setBorder(width: selectWidth, height: selectHeight) }
    }
}
