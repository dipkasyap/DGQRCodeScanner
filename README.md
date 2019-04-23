# DGQRCodeScanner

## usage 

1. Clone or download the sample project.
2. Drag and drop Scanner folder on your project.
3. Implement Code as following  
```
let scanner = DGQRCodeScanner.show()
 scanner?.onSuccess = { [weak self] result in
            self?.messageLabel.text = "Result from Scan is \n \(result)"
        }
```
## Important 
DO NOT forget to provide access messege on plist.
just go to info.plist file , do right click -> open as -> source code and add following line below <dict> 
```
    <key>NSCameraUsageDescription</key>
    <string>We need to access your camera for scanning QR code</string>
    
