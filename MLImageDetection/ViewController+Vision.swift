//
//  ViewController+Vision.swift
//  MLImageDetection
//
//  Created by rex on 9/22/25.
//

import UIKit
import Vision

extension ViewController {
    var detectionRequest: VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest{ (request, error) in
            if let error = error {
                print(error)
                return
            } else {
                guard let observations = request.results as? [VNRectangleObservation] else { return }
                self.visualizeObservations(observations)
            }
                
        }
        request.quadratureTolerance = 45.0
        return request
    }
    
    func performVisionRequest(image: UIImage)
    {
        guard let cgImage = image.cgImage else { return }
        let imageRequestHandler
        = VNImageRequestHandler(cgImage: cgImage,
                                orientation: image.cgOrientation,
                                options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            let requests = [self.detectionRequest]
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("failed to perform image request: \(error)")
            }
        }
    }
    
    private func visualizeObservations(_ observations: [VNDetectedObjectObservation]) {
        DispatchQueue.main.async {
            guard let image = self.imageView.image else {
                print("Failed to retrieve image!")
                return
            }
            
            // 1. Transforms
            let imageSize = image.size
            // Transform the observation bounding rect from Quartz 2D coordinate system to UIKit coordinates
            // flip vertically and translate back after flipping
            var transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -imageSize.height)
            // Scale the normalized bounding box based on the image dimensions
            transform = transform.scaledBy(x: imageSize.width, y: imageSize.height)
            
            // 2. Rendering
            UIGraphicsBeginImageContextWithOptions(imageSize, true, 0.0)
            let context = UIGraphicsGetCurrentContext()
            
            // Draw the image in the current graphics context within the boundaries of the provided rectangle
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            
            // saves the current graphics state before we change line, stroke color and fill color properties
            context?.saveGState()
            
            // set line properties
            context?.setLineWidth(8.0)
            context?.setLineJoin(CGLineJoin.round)
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.3)
            
            observations.forEach({ observation in
                // transform the observation's bounding rectangle to the UIKit coordinate system and scale it based on the image dimensions
                let observationBounds = observation.boundingBox.applying(transform)
                // add the rectangular path
                context?.addRect(observationBounds)
            })
            
            // draw the paths
            context?.drawPath(using: CGPathDrawingMode.fillStroke)
            
            // restores the current graphics state
            context?.restoreGState()
            // get the final image
            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            // replace image drawn in ImageView
            self.imageView.image = drawnImage
        }
    }
}
