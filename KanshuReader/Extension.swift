//
//  UIViewExtension.swift
//  KanshuReader
//
//  Created by AC on 12/16/23.
//

import UIKit
import SwiftyTesseract
import libtesseract
import Vision

extension UIView {
    func makeCircular() {
        self.layer.cornerRadius = self.bounds.size.width / 2.0
        self.clipsToBounds = true
    }
}

extension UIImage {

    func crop(from scrollView: UIScrollView) -> UIImage {
        let zoom: CGFloat = 1.0 / scrollView.zoomScale
        
        let origX: CGFloat = (scrollView.contentOffset.x) * zoom // 0
        let origY: CGFloat = (scrollView.contentOffset.y) * zoom // 0
        let widthCropper: CGFloat = scrollView.frame.size.width * zoom
        let heightCropper: CGFloat = scrollView.frame.size.height * zoom
        let SIDE_MARGIN: CGFloat = 0
        
        let cropRect = CGRectMake((origX + (SIDE_MARGIN/2)), (origY + (SIDE_MARGIN / 2)), (widthCropper - SIDE_MARGIN), (heightCropper  - SIDE_MARGIN));

        guard let croppedImageRef = cgImage?.cropping(to: cropRect) else { return self }
        let croppedImage = UIImage(cgImage: croppedImageRef, scale: scale, orientation: imageOrientation)

        return croppedImage
    }
    
    func crop(rect: CGRect?) -> UIImage {
        guard let rect = rect else { return self }
        guard let croppedImageRef = cgImage?.cropping(to: rect) else { return self }
        let croppedImage = UIImage(cgImage: croppedImageRef, scale: scale, orientation: imageOrientation)

        return croppedImage
    }
    
    func getZoomedRect(from page: Page) -> CGRect {
        let zoom: CGFloat = 1.0 / page.scrollView.zoomScale
        
        let origX: CGFloat = (page.scrollView.contentOffset.x + page.scrollView.contentInset.left) * zoom // 0
        let origY: CGFloat = (page.scrollView.contentOffset.y + page.scrollView.contentInset.top) * zoom // 0
        let widthCropper: CGFloat = min(page.imageView.image?.size.width ?? page.scrollView.frame.size.width * zoom, page.scrollView.frame.size.width * zoom)
        let heightCropper: CGFloat = min(page.imageView.image?.size.height ?? page.scrollView.frame.size.height * zoom, page.scrollView.frame.size.height * zoom)
        let SIDE_MARGIN: CGFloat = 0
        
        let zoomedRect = CGRect(x: origX + (SIDE_MARGIN/2), y: origY + (SIDE_MARGIN / 2), width: widthCropper - SIDE_MARGIN, height: heightCropper  - SIDE_MARGIN)
        
        return zoomedRect
    }
    
    func getCroppedRect(from scrollView: UIScrollView) -> CGRect {
        let zoom: CGFloat = 1.0 / scrollView.minimumZoomScale
        
        let origX: CGFloat = 0 * zoom // 0
        let origY: CGFloat = 0 * zoom // 0
        let widthCropper: CGFloat = scrollView.frame.size.width * zoom
        let heightCropper: CGFloat = scrollView.frame.size.height * zoom
        let SIDE_MARGIN: CGFloat = 0
        
        return CGRectMake((origX + (SIDE_MARGIN/2)), (origY + (SIDE_MARGIN / 2)), (widthCropper - SIDE_MARGIN), (heightCropper  - SIDE_MARGIN))
    }
    
    func drawPointsOnImage(_ points: [CGPoint], color: UIColor) -> UIImage {
        let imageSize = self.size
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        self.draw(at: CGPoint.zero)
        let ctx = UIGraphicsGetCurrentContext()

        points.forEach { point in
            ctx?.addEllipse(in: CGRect(x: point.x - 1, y: point.y - 1, width: 2, height: 2))
        }
        ctx?.setStrokeColor(color.cgColor)
        ctx?.setLineWidth(2.0)
        ctx?.strokePath()

        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }

        UIGraphicsEndImageContext()
        return drawnImage
    }

    func drawRectsOnImage(_ rects: [CGRect], color: UIColor) -> UIImage {
        let imageSize = self.size
        let scale: CGFloat = 0.0

        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        let ctx = UIGraphicsGetCurrentContext()

        ctx?.addRects(rects)
        ctx?.setStrokeColor(color.cgColor)
        ctx?.setLineWidth(2.0)
        ctx?.strokePath()

        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }

        UIGraphicsEndImageContext()

        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        self.draw(at: CGPoint.zero)
        drawnImage.draw(at: CGPoint.zero)

        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }

        UIGraphicsEndImageContext()

        return finalImage
    }
    
    func imageWith(size: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        
        return image.withRenderingMode(renderingMode)
    }
    
    func noiseReducted() -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        
        let ciContext = CIContext()
        
        guard let colorControls = CIFilter(name: "CIColorControls") else { return self }
        colorControls.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        colorControls.setDefaults()
        colorControls.setValue(1.1, forKey: "inputContrast")
        guard let output1 = colorControls.outputImage else { return self }
        
        guard let exposure = CIFilter(name: "CIExposureAdjust") else { return self }
        exposure.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        exposure.setValue(output1, forKey: kCIInputImageKey)
        exposure.setDefaults()
        exposure.setValue(0.7, forKey: "inputEV")
        guard let output2 = exposure.outputImage else { return UIImage() }

        guard let cgImage2 = ciContext.createCGImage(output2, from: output2.extent) else { return self }
        return UIImage(cgImage: cgImage2, scale: scale, orientation: imageOrientation)
    }
}

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(NSCoder.string(for: self))
    }
    
    func normalizeBoundingBox(for image: UIImage) -> CGRect
    {
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let renormalized = VNImageRectForNormalizedRect(self, Int(imageRect.width), Int(imageRect.height))

        return CGRect(
            origin: CGPoint(
                x: renormalized.origin.x,
                y: imageRect.maxY - renormalized.origin.y - renormalized.size.height
            ),
            size: renormalized.size
        )
    }
    
    func unnormalizeBoundingBox(for image: UIImage) -> CGRect
    {
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
//        let unnormalized = VNNormalizedRectForImageRect(self, Int(imageRect.size.width), Int(imageRect.size.height))
//        min(scrollView.zoomView?.image?.size.width ?? scrollView.frame.size.width * zoom, scrollView.frame.size.width * zoom)
        let unnormalized = VNNormalizedRectForImageRect(self, Int(imageRect.size.width), Int(imageRect.size.height))
        

        let normalized = CGRect(
            origin: CGPoint(
                x: unnormalized.origin.x,
                y: 1 - unnormalized.origin.y - unnormalized.size.height
            ),
            size: unnormalized.size
        )
        return normalized.inNormalBounds()
    }
    
    func unnormalizeBoundingBox(for rect: CGRect?) -> CGRect
    {
        guard let rect = rect else { return self }
//        let unnormalized = VNNormalizedRectForImageRect(self, Int(imageRect.size.width), Int(imageRect.size.height))
//        min(scrollView.zoomView?.image?.size.width ?? scrollView.frame.size.width * zoom, scrollView.frame.size.width * zoom)
        let unnormalized = VNNormalizedRectForImageRect(self, Int(rect.size.width), Int(rect.size.height))
        

        let normalized = CGRect(
            origin: CGPoint(
                x: unnormalized.origin.x,
                y: 1 - unnormalized.origin.y - unnormalized.size.height
            ),
            size: unnormalized.size
        )
        return normalized.inNormalBounds()
    }
    
    func inNormalBounds() -> CGRect
    {
        let x = max(0, self.minX)
        let y = max(0, self.minY)
        return CGRect(x: x, y: y, width: min(self.width, 1 - x), height: min(self.height, 1 - y))
    }
}

public typealias PageSegmentationMode = TessPageSegMode
public extension TessPageSegMode {
  static let osdOnly = PSM_OSD_ONLY
  static let autoOsd = PSM_AUTO_OSD
  static let autoOnly = PSM_AUTO_ONLY
  static let auto = PSM_AUTO
  static let singleColumn = PSM_SINGLE_COLUMN
  static let singleBlockVerticalText = PSM_SINGLE_BLOCK_VERT_TEXT
  static let singleBlock = PSM_SINGLE_BLOCK
  static let singleLine = PSM_SINGLE_LINE
  static let singleWord = PSM_SINGLE_WORD
  static let circleWord = PSM_CIRCLE_WORD
  static let singleCharacter = PSM_SINGLE_CHAR
  static let sparseText = PSM_SPARSE_TEXT
  static let sparseTextOsd = PSM_SPARSE_TEXT_OSD
  static let count = PSM_COUNT
}

extension Tesseract {
  var pageSegMode: TessPageSegMode {
    get {
      perform { tessPointer in
        TessBaseAPIGetPageSegMode(tessPointer)
      }
    }
    set {
      perform { tessPointer in
        TessBaseAPISetPageSegMode(tessPointer, newValue)
      }
    }
  }
}

extension NSLayoutConstraint
{
    func withPriority(_ priority: Float) -> NSLayoutConstraint
    {
        self.priority = UILayoutPriority(priority)
        return self
    }
}
