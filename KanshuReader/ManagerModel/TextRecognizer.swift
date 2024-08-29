//
//  TextRecognizer.swift
//  KanshuReader
//
//  Created by AC on 8/24/24.
//

import UIKit
import Vision
import SwiftyTesseract

protocol TextRecognizerDelegate: AnyObject {
    func didPerformVision(image: UIImage)
}

class TextRecognizer {
    weak var delegate: TextRecognizerDelegate?
    
    let tesseract = Tesseract(language: .custom("chi_tra_vert"))
    
    var detectedText: [(String?, CGRect)] = []
    var unprocessedImage: UIImage? = nil
    var clusters: [[CGRect]] = []
    var textRegions: [CGRect] = []
    
    func requestInitialVision(for image: UIImage, with frame: CGRect? = nil) {
        guard let cgImage = image.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else { return }
            
            self.detectedText = self.getBoxes(observations: observations, image: image, rect: frame)
            self.clusters = self.getBoxClusters(boxes: self.detectedText.map { $0.1 })
            self.textRegions = self.clusters.map { self.joinBoxes(cluster: $0) }
            
            self.unprocessedImage = image
            
            if(self.textRegions.count > 0) {
                OCRTip.tipEnabled = false
                BoxTip.boxesGenerated = true
            }
            
            self.delegate?.didPerformVision(image: image.drawRectsOnImage(self.textRegions, color: .red))
        }
        
        if let frame = frame {
            request.regionOfInterest = frame.unnormalizeBoundingBox(for: image)
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant", "en-US"]

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    func requestFinalVision(for location: CGPoint, textDirection: Direction) -> String? {
        guard let regionIndex = textRegions.firstIndex(where: { $0.contains(location) }) else { return nil }
        let region = textRegions[regionIndex]
        
        var text: String? = ""
        
        if textDirection == .vertical {
            text = requestVerticalVision(image: unprocessedImage, cluster: clusters[regionIndex])
        }
        else if textDirection == .horizontal {
            text = requestHorizontalVision(on: unprocessedImage, region: region)
        }
        
        return text
    }
    
    func requestHorizontalVision(on image: UIImage?, region: CGRect) -> String {
        guard let unwrapped = image else { return "" }
        guard let cgImage = unwrapped.cgImage else { return "" }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var result = ""

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else { return }
            let text = observations.compactMap({ $0.topCandidates(1).first?.string}).joined(separator: "")
            
            result = text
        }
        
        request.regionOfInterest = region.unnormalizeBoundingBox(for: unwrapped)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
        
        return result
    }
    
    func requestVerticalVision(image: UIImage?, cluster: [CGRect]) -> String {
        guard let image = image else { return "" }
        
        let boxes = getVerticalBoxes(cluster: cluster, original: detectedText)
        
        var results = [String](repeating: "", count: boxes.count)
        for i in 0..<boxes.count {
            let box = boxes[i]
            let column = image.crop(rect: box).noiseReducted()
            let result = tesseract.performOCR(on: column)
            do {
                results[i] = try result.get().replacingOccurrences(of: "\n", with: "")
            } catch {
                print("Error retrieving the value: \(error)")
            }
        }
        
        return results.joined()
    }
    
    func getRegion(for location: CGPoint) -> CGRect? {
        guard let regionIndex = textRegions.firstIndex(where: { $0.contains(location) }) else { return nil }
        return textRegions[regionIndex]
    }
    
    func getBoxes(observations: [VNRecognizedTextObservation], image: UIImage, rect: CGRect?) -> [(String?, CGRect)] {
        var requestImage = image
        if rect != nil { requestImage = image.crop(rect: rect) }
        let boundingRects: [(String?, CGRect)] = observations.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return ("", .zero) }

            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)

            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero

            // Convert the rectangle from normalized coordinates to image coordinates.
            let normalizedToZoom = boundingBox.normalizeBoundingBox(for: requestImage)
            let normalized = CGRect(x: normalizedToZoom.minX + (rect?.minX ?? 0), y: normalizedToZoom.minY + (rect?.minY ?? 0), width: normalizedToZoom.width, height: normalizedToZoom.height)
            return (candidate.string, normalized)
        }
        return boundingRects
    }
    
    func getBoxClusters(boxes: [CGRect]) -> [[CGRect]] {
        var processing = boxes
        
        var clusters: [[CGRect]] = []
        
        while(processing.count > 0) {
            var cluster: [CGRect] = []
            cluster.append(processing[0])
            
            var clusterUnprocessed = cluster
            while(clusterUnprocessed.count > 0) {
                let curr = clusterUnprocessed[0]
                cluster.append(curr)
                clusterUnprocessed.removeAll(where: { $0 == curr })
                
                let thresholdArea = CGRect(x: curr.minX - curr.height, y: curr.minY - curr.height / 2, width: curr.width + curr.height * 2, height: curr.height * 2)

                var clusterSet = Set(clusterUnprocessed)
                clusterSet.formUnion(Set(processing.filter { $0.intersects(thresholdArea) }))
                clusterSet = clusterSet.subtracting(Set(cluster))
                clusterUnprocessed = Array(clusterSet)
            }
            clusters.append(cluster)
            processing = Array(Set(processing).subtracting(cluster))
        }
        
        return clusters
    }
    
    func getVerticalBoxes(cluster: [CGRect], original: [(String?, CGRect)]) -> [CGRect] {
        var joined = cluster[0]
        var longest: (String, CGRect) = ("", cluster[0])
        
        cluster.forEach { box in
            let sameRow = Set(cluster.filter({ $0 != box && abs($0.origin.y - box.origin.y) < box.height / 5 }))
            var rowBox = box
            var rowString = detectedText.first(where: { $0.1 == box })?.0 ?? ""
            sameRow.forEach { item in
                rowBox = rowBox.union(item)
                rowString += detectedText.first(where: { $0.1 == item })?.0 ?? ""
            }
            if(rowString.count > longest.0.count) { longest = (rowString, rowBox) }
            joined = joined.union(box)
        }
        
        var verticalCluster: [CGRect] = []
        
        let columnNum = CGFloat(longest.0.count)
        let columnSize = joined.width / columnNum
        for i in 0..<longest.0.count {
            var columnBox = CGRect(x: joined.minX + CGFloat(i) * columnSize, y: joined.minY, width: columnSize, height: joined.height)
            columnBox = columnBox.insetBy(dx: -(joined.width / columnNum) / 5, dy: -(joined.width / columnNum) / 5)
            verticalCluster.insert(columnBox, at: 0)
        }
        
        return verticalCluster
    }
    
    func joinBoxes(cluster: [CGRect]) -> CGRect {
        if cluster.count == 0 { return .zero }
        var joined = cluster[0]
        cluster.forEach { box in
            joined = joined.union(box)
        }
        return joined
    }
}
