//
//  CJExtensions.swift
//  Is Clarence?
//
//  Created by Clarence Ji on 6/11/18.
//  Copyright © 2018 Clarence Ji. All rights reserved.
//

import UIKit

extension UIImage {
    func cropped(boundingBox: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: boundingBox) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
