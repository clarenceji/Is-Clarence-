//
//  ViewController.swift
//  Is Clarence?
//
//  Created by Clarence Ji on 6/7/18.
//  Copyright © 2018 Clarence Ji. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet private weak var cameraContainerView: UIView!
    @IBOutlet private var captureButton: UIButton!
    @IBOutlet private var isClarenceLabel: UILabel!
    @IBOutlet private var notClarenceLabel: UILabel!
    
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
            print("[CJ] photoData is nil")
            return
        }
        guard let image = UIImage(data: photoData) else {
            print("[CJ] UIImage is nil")
            return
        }
        
        do {
            print("[CJ] Generating Pixel Buffer")
            let cvPixelBuffer = image.pixelBuffer(width: Int(image.size.width), height: Int(image.size.height))
            let output = try classifier.prediction(image: cvPixelBuffer!)
            print("Class label - \(output.classLabel)")
            self.displayResult(output)

        } catch {
            print(error)
        }
        
    }
    
    private func displayResult(_ result: ClarenceClassifierOutput) {
        func toggleLabels(_ isClarence: Bool) {
            let label: UILabel = isClarence ? isClarenceLabel : notClarenceLabel
            UIView.animate(withDuration: 0.2, animations: {
                label.alpha = 1.0
            }) { (_) in
                UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseIn, animations: {
                    label.alpha = 0.0
                }, completion: nil)
            }
        }
        
        switch result.classLabel {
        case "Clarence":
            toggleLabels(true)
            
        case "Not Clarence":
            toggleLabels(false)
            
            
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
        
//        self.captureSession.beginConfiguration()
//
//        guard let currentInput = captureSession.inputs.first else { return }
//
//        captureSession.removeInput(currentInput
//
//        let newCamera = AVCaptureDevice.init(uniqueID: <#T##String#>)
//        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
//        {
//            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
//        }
//        else
//        {
//            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
//        }
//
//        NSError *err = nil;
//
//        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
//
//        if(!newVideoInput || err)
//        {
//            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
//        }
//        else
//        {
//            [session addInput:newVideoInput];
//        }
//
//        [session commitConfiguration];
        
    }
    
}

