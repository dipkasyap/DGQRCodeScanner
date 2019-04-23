
import UIKit
import AVFoundation

fileprivate extension UIViewController {
    class func loadFromNib<T: UIViewController>() -> T {
        return T(nibName: String(describing: self), bundle: nil)
    }
}

//fileprivate func presentController()-> UIViewController? {
//    if var topController = UIApplication.shared.keyWindow?.rootViewController {
//        while let presentedViewController = topController.presentedViewController {
//            topController = presentedViewController
//        }
//        return topController
//    } else {
//        return nil
//    }
//}


func presentController() -> UIViewController? {
    if let rootController = UIApplication.shared.keyWindow?.rootViewController {
        var currentController: UIViewController! = rootController
        while(currentController.presentedViewController != nil ) {
            currentController = currentController.presentedViewController
        }
        return currentController
    }
    return nil
}




fileprivate func delayFor(_ seconds: Double = 0.3, then: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        then()
    }
}

class DGQRCodeScanner: UIViewController {
    
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    
    
    var captureSession = AVCaptureSession()
    var captureMetadataOutput: AVCaptureMetadataOutput!

    var themeColor = UIColor(red:0.00, green:0.80, blue:0.80, alpha:1.0)
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    
    //MARK:- callbacks
    var onSuccess : ((_ url: String) -> ())?
    var onFailure : (() -> ())?
    
    //MARK:- init
    public class func show()-> DGQRCodeScanner? {
        let viewController: DGQRCodeScanner = DGQRCodeScanner.loadFromNib()
        if let presentController = presentController() {
            presentController.present(viewController, animated:true, completion: nil)
        }
        return viewController
    }
    
    //MARK:- Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.layer.bounds
    }
    
    //MARK:- setup
    private func setup() {
        
        guard  let camera = getCamera(), configureSessionFor(camera) else {
            return
        }
        getVisualFromSession()
        addFrameOnObject()
        
        // Move the message label and top bar to the front
        view.bringSubviewToFront(messageLabel)
        view.bringSubviewToFront(topbar)
        view.bringSubviewToFront(bottomBar)
        
        //color
        topbar.backgroundColor = themeColor.withAlphaComponent(0.4)
        bottomBar.backgroundColor = themeColor.withAlphaComponent(0.4)

    }
    
    //MARK:- Configuration
    private func getCamera()-> AVCaptureDevice? {
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            messageLabel.text = "Can not detect Camera!"
            return nil
        }
        
        return captureDevice
    }
    
    private func configureSessionFor(_ camera: AVCaptureDevice)-> Bool {
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: camera)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            return true
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return false
        }
    }
    
    func getVisualFromSession() {
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        //Start video capture.
        captureSession.startRunning()
    }
    
    private func addFrameOnObject() {
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = themeColor.cgColor // mportGreen
            qrCodeFrameView.layer.borderWidth = 4
            qrCodeFrameView.layer.cornerRadius = 10
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    // MARK: - complition
    private func complition( value: String? = nil) {
        if let value = value {
            if let success = onSuccess {
                success(value)
            }
        } else {
            if let failure = onFailure {
                failure()
            }
        }
    }
    
    //MARK:- action
    @IBAction private  func close() {
        dismiss(animated: true, completion: onFailure)
    }
}

//MARK:- Video outup delegate
extension DGQRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            doWithText(nil)
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if let text = metadataObj.stringValue {
               
                messageLabel.text = nil
                captureMetadataOutput.setMetadataObjectsDelegate(nil, queue: DispatchQueue.main)

                delayFor { [weak self] in
                    self?.doWithText(text)
                    self?.captureSession.stopRunning()
                }
     
            } else {
                doWithText("cannot read the QR")
            }
        }
        
    }
    
    private func doWithText(_ text: String?) {
        if let text = text {
            complition(value: text)
            messageLabel.text = nil
            dismiss(animated: true, completion: nil)
        } else {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            complition()
        }
    }
}
