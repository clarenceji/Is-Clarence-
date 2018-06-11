//
//  CJViewController.swift
//  Is Clarence?
//
//  Created by Clarence Ji on 6/7/18.
//  Copyright © 2018 Clarence Ji. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet private weak var cameraContainerView: UIView!
    @IBOutlet private var captureButton: UIButton!
    @IBOutlet private var isClarenceLabel: UILabel!
    @IBOutlet private var notClarenceLabel: UILabel!
    
    // UI & Strings
    private let isClarenceString = "✅ Is Clarence"
    private let notClarenceString = "❌ Not Clarence"
    
    // Camera
    private let captureSession = AVCaptureSession()
    private var camera: AVCaptureDevice?
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    // ML Model
    private let classifier = ClarenceClassifier()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.captureButton.layer.cornerRadius = 8
        self.cameraContainerView.layer.cornerRadius = 20
        initCam()
        
        isClarenceLabel.alpha = 0
        notClarenceLabel.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraContainerView.bounds
    }
    
    /// Initialize Camera
    private func initCam() {
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDualCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera], mediaType: AVMediaType.video, position: .unspecified).devices
        
        for device in devices {
            
            if device.position == .back && device.deviceType == AVCaptureDevice.DeviceType.builtInWideAngleCamera {
                
                self.camera = device
                
                do {
                    
                    var finalFormat: AVCaptureDevice.Format? = nil
                    var is60FPS = false
                    for vFormat in device.formats {
                        var ranges = (vFormat as AnyObject).videoSupportedFrameRateRanges as [AVFrameRateRange]
                        let frameRates = ranges[0]
                        if frameRates.maxFrameRate == 60 {
                            finalFormat = vFormat as AVCaptureDevice.Format
                            is60FPS = true
                        }
                    }
                    
                    if finalFormat == nil {
                        
                        for vFormat in device.formats {
                            var ranges = (vFormat as AnyObject).videoSupportedFrameRateRanges as [AVFrameRateRange]
                            let frameRates = ranges[0]
                            if frameRates.maxFrameRate == 30 {
                                finalFormat = vFormat as AVCaptureDevice.Format
                            }
                        }
                        
                    }
                    
                    let input = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(input) {
                        
                        captureSession.addInput(input)
                        
                        try device.lockForConfiguration()
                        device.activeFormat = finalFormat!
                        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: is60FPS ? 60 : 30)
                        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: is60FPS ? 60 : 30)
                        device.unlockForConfiguration()
                        
                        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                        
                        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                        
                        // Output
                        photoOutput.isHighResolutionCaptureEnabled = true
                        
                        if captureSession.canAddOutput(self.photoOutput) {
                            self.captureSession.sessionPreset = .photo
                            captureSession.addOutput(self.photoOutput)
                        }
                        
                        self.captureSession.commitConfiguration()
                        
                        cameraContainerView.layer.addSublayer(previewLayer)
                        
                    }
                    
                } catch{
                    print("exception!")
                }
                
            }
            
        }
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let photoData = photo.fileDataRepresentation() else {
            print("[CJ] /!\\ photoData is nil")
            return
        }
        guard let image = UIImage(data: photoData) else {
            print("[CJ] /!\\ UIImage is nil")
            return
        }
        
        do {
            
            guard let croppedImage = image.cropped(boundingBox: CGRect(x: image.size.width / 2, y: image.size.height / 2, width: 299, height: 299)) else {
                print("[CJ] /!\\ Unable to crop image")
                return
            }
            
            print("[CJ] Generating Pixel Buffer")
            let cvPixelBuffer = croppedImage.pixelBuffer(width: 299, height: 299)
            let output = try classifier.prediction(image: cvPixelBuffer!)
            print("Class label - \(output.classLabel)")
            self.displayResult(output)

        } catch {
            print(error)
        }
        
    }
    
    private func displayResult(_ result: ClarenceClassifierOutput) {
        func toggleLabels(_ isClarence: Bool, _ confidence: String) {
            DispatchQueue.main.async {
                self.isClarenceLabel.alpha = 0
                self.isClarenceLabel.textColor = isClarence ? #colorLiteral(red: 0.4235294118, green: 0.8078431373, blue: 0.4039215686, alpha: 1) : #colorLiteral(red: 0.8919706941, green: 0.3084927201, blue: 0.3301423192, alpha: 1)
                let labelString = (isClarence ? self.isClarenceString : self.notClarenceString) + confidence
                self.isClarenceLabel.text = labelString
                UIView.animate(withDuration: 0.2, animations: {
                    self.isClarenceLabel.alpha = 1.0
                }) { (_) in
                    UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseIn, animations: {
                        self.isClarenceLabel.alpha = 0.0
                    }, completion: nil)
                }
            }
        }
        
        let classLabelProb = 100 * (result.classLabelProbs[result.classLabel] ?? 0)
        let confidence = " (\(round(100 * classLabelProb) / 100)%)"
        
        
        switch result.classLabel {
        case "Clarence":
            toggleLabels(true, confidence)
            
        case "Not Clarence":
            toggleLabels(false, confidence)
            
            
        default:
            break
        }
        
    }

    @IBAction private func captureButtonTapped(_ sender: Any) {
        
        var photoSettings: AVCapturePhotoSettings!
        if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format:
                [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        
        photoSettings.isAutoStillImageStabilizationEnabled =
            self.photoOutput.isStillImageStabilizationSupported
        
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private var isBackCamera = true
    @IBAction func switchCameraButtonTapped(_ sender: Any) {
    }
    
}

