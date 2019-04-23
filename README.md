# DGQRCodeScanner

## usage 

1. Clone or download the sample project.
2. Drag and drop Scanner folder on your project.
3. Implement Code as following  
```
let scanner = QRScannerController.show()
 scanner?.onSuccess = { [weak self] result in
            self?.messageLabel.text = "Result from Scan is \n \(result)"
        }
