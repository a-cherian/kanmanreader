//
//  HReaderViewController.swift
//  KanmanReader
//
//  Created by AC on 8/25/24.
//

import UIKit
import TipKit

protocol ReaderDelegate: AnyObject {
    func didFlipPage()
}

class HReaderViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, Reader {
    
    weak var rDelegate: ReaderDelegate?
    
    var urls: [URL] = []
    var position: Int {
        max(min(currentPage.position, urls.count - 1), 0)
    }
    var currentImage: UIImage? { return urls[position].loadImage() }
    var currentPage: Page = Page()
    var pendingPage: Page = Page()
    
    required init(urls: [URL] = [], position: Int = 0, parent: ReaderViewController? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        
        if(urls.count == 0) { return }
        
        self.urls = urls
        self.currentPage = createPage(position: position)
        self.currentPage.delegate = parent
        self.rDelegate = parent
        
        setViewControllers([currentPage], direction: .forward, animated: true)
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.currentPage = createPage(position: position)
        rDelegate?.didFlipPage()
        setViewControllers([currentPage], direction: .forward, animated: false)
        view.setNeedsLayout()
    }
    
    func createPage(position: Int) -> Page {
        let newPage = Page()
        newPage.url = urls[position]
        newPage.position = position
        newPage.delegate = parent as? ReaderViewController
        
        return newPage
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if(position - 1 >= 0) {
            let previousPage = createPage(position: position - 1)
            return previousPage
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if(position + 1 < urls.count)
        {
            let nextPage = createPage(position: position + 1)
            return nextPage
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingPage = pendingViewControllers[0] as! Page
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if(completed) {
            let previousPage = previousViewControllers[0] as? Page
            previousPage?.imageView.image = previousPage?.initialImage
            currentPage = pendingPage
            rDelegate?.didFlipPage()
        }
    }
}
