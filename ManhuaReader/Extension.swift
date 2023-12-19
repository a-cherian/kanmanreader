//
//  UIViewExtension.swift
//  ManhuaReader
//
//  Created by AC on 12/16/23.
//

import UIKit

extension UIView {
    func makeCircular() {
        self.layer.cornerRadius = self.bounds.size.width / 2.0
        self.clipsToBounds = true
    }
}

extension UIImage {

    func crop(from scrollView: UIScrollView) -> UIImage {
        let zoom: CGFloat = 1.0 / scrollView.zoomScale
        
        var origX: CGFloat = (scrollView.contentOffset.x) * zoom // 0
        var origY: CGFloat = (scrollView.contentOffset.y) * zoom // 0
        var widthCropper: CGFloat = scrollView.frame.size.width * zoom
        var heightCropper: CGFloat = scrollView.frame.size.height * zoom
        let SIDE_MARGIN: CGFloat = 0
        
        let cropRect = CGRectMake((origX + (SIDE_MARGIN/2)), (origY + (SIDE_MARGIN / 2)), (widthCropper - SIDE_MARGIN), (heightCropper  - SIDE_MARGIN));

        guard let croppedImageRef = cgImage?.cropping(to: cropRect) else { return self }
        let croppedImage = UIImage(cgImage: croppedImageRef, scale: scale, orientation: imageOrientation)

        return croppedImage
    }

}
