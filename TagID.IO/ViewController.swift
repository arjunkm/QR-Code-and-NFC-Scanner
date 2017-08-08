//
//  ViewController.swift
//  TagID.IO
//
//  Created by Arjun Koppal Manjunatha on 7/12/17.
//  Copyright © 2017 Arjun Koppal Manjunath. All rights reserved.
//

import UIKit
import AVFoundation
import SafariServices

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, SFSafariViewControllerDelegate
{

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView:UIView!
    

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var topNavbar: UINavigationBar!
    @IBOutlet weak var scanCodeLabel: UILabel!
    @IBOutlet weak var darkOverlay: UIImageView!
    @IBOutlet weak var whiteBorder: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    
    @IBAction func aboutUs(_ sender: UIButton) {
        aboutUs()
    }
    
    
    @IBAction func help(_ sender: Any) {
        
        let urlString = URL(string: "https://www.tagid.io/smart-connects-app-help.html")
        let vc = SFSafariViewController(url: urlString! as URL, entersReaderIfAvailable: false)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        
    }
    
    
    func aboutUs()
    {
        let urlString = URL(string: "https://www.tagid.io")
        let vc = SFSafariViewController(url: urlString! as URL, entersReaderIfAvailable: false)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func flashlight(_ sender: UIButton)
    {
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), device.hasTorch
        {
            do
            {
                try device.lockForConfiguration()
                if(device.torchMode == .on)
                {
                    device.torchMode = .off
                }
                else
                {
                    device.torchMode = .on
                }
                device.unlockForConfiguration()
            }
            catch
            {
                print("Error!")
            }
        }

    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType:AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do
        {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }
            
        catch
        {  return  }
        
        if(captureSession.canAddInput(videoInput))
        {
            captureSession.addInput(videoInput)
        }
        else
        {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if(captureSession.canAddOutput(metadataOutput))
        {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
        }
        else
        {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer)
        view.bringSubview(toFront: darkOverlay);
        view.bringSubview(toFront: toolbar)
        view.bringSubview(toFront: topNavbar)
        view.bringSubview(toFront: logo)
        view.bringSubview(toFront: scanCodeLabel)
        view.bringSubview(toFront: whiteBorder)
        view.bringSubview(toFront: helpButton)
        
        captureSession.startRunning();
    }
    
    func toggleOff()
    {
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), device.hasTorch
        {
            do
            {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            catch
            {
                print("Error!")
            }
        }
    }
    
    func failed()
    {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false)
        {
            captureSession.startRunning();
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true)
        {
            captureSession.stopRunning();
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
    {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first
        {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
            
            found(code: readableObject.stringValue)
            toggleOff()
            captureSession.startRunning()
            
        }
        
        // dismiss(animated: true)
    }
    
    
    func found(code: String)
    {
        var enteredURL = code
        //let url = NSURL(string: enteredURL)
        //let uurl = URL(string: code)
        if(verifyUrl(urlString: code) == true)
        {
            let url = NSURL(string: enteredURL)
            var components = URLComponents(url: url! as URL, resolvingAgainstBaseURL: false)
            var domainName = components?.host;
            let compare = "www.tagid.io"
            let compare1 = "tagid.io"
        
            if domainName == compare || domainName == compare1
            {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                let vc = SFSafariViewController(url: url! as URL, entersReaderIfAvailable: false)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            }
            else
            {
                unsupportedQRCode()
            }
        }
        else
        {
            unsupportedQRCode()
        }
    }
    
    
    func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url  = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    func unsupportedQRCode()
    {
        let ac = UIAlertController(title: "Scan only TagID QR Codes", message: "You are trying to scan a code that is not supported by TagID.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession.startRunning()
    }
    
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    {
        dismiss(animated: true)
    }
    
    
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return .portrait
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
}



