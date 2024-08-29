//
//  HReaderViewController.swift
//  KanshuReader
//
//  Created by AC on 8/25/24.
//

import UIKit
import TipKit

protocol HReaderDelegate: AnyObject {
    func didFlipPage()
}

class HReaderViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, Reader {
    
    weak var rDelegate: HReaderDelegate?
    
    var pages: [UIImage] = []
    var position: Int {
        currentPage.position
    }
    var currentImage: UIImage { return pages[position] }
    var currentPage: Page = Page()
    var pendingPage: Page = Page()
    
    required init(images: [UIImage] = [], position: Int = 0, parent: ReaderViewController? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        
        if(images.count == 0) { return }
        
        self.pages = images
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
    
    func createPage(position: Int) -> Page {
        let newPage = Page()
        newPage.setImage(pages[position])
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
        if(position + 1 < pages.count)
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
