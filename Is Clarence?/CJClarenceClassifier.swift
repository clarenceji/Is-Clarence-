//
//  ClarenceClassifier.swift
//  Is Clarence?
//
//  Created by Clarence Ji on 6/8/18.
//  Copyright © 2018 Clarence Ji. All rights reserved.
//

import UIKit
import CoreML

class CJClarenceClassifier: NSObject {

    static let shared: CJClarenceClassifier = {
        return CJClarenceClassifier()
    }()
    
    override init() {
        super.init()
        
        let model = MLModel()
        
        
    }

}
