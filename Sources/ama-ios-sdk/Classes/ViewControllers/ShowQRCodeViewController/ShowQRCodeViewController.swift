//
//  ShowQRCodeViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 20/07/21.
//

import UIKit

final class ShowQRCodeViewController: UIViewController {

    override var wx_navigationBarBackgroundColor: UIColor? {
        return UIColor.clear
    }
    
    @IBOutlet weak var QRCodeImageView: UIImageView!
    var QRCodeImage: UIImage?
    @IBOutlet weak var baseView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QRCodeImageView.image = QRCodeImage
        // Do any additional setup after loading the view.
        baseView.layer.cornerRadius = 25
    }
    

    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
