
import UIKit

class QRCodeViewController: UIViewController {

    @IBOutlet var messageLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func show(_ sender: UIButton) {
        let scanner =   QRScannerController.show()
        scanner?.onSuccess = { [weak self] result in
            self?.messageLabel.text = "Result from Scan is \n \(result)"
        }
    }
}
