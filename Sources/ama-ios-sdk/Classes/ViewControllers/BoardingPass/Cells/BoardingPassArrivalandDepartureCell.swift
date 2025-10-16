//
//  BoardingPassArrivalandDepartureCell.swift
//  dataWallet
//
//  Created by iGrant on 06/08/25.
//

import Foundation
import UIKit

final class BoardingPassArrivalandDepartureCell: UITableViewCell {
    
    @IBOutlet weak var departureDateLabel: UILabel!
    
    @IBOutlet weak var departureTimeLabel: UILabel!
    
    @IBOutlet weak var emptyLabel: UILabel!
    
    @IBOutlet weak var imageLogo: UIImageView!
    
    @IBOutlet weak var destinationLabel: UILabel!
    
    @IBOutlet weak var arrivalDateLabel: UILabel!
    
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!
    
    
    func updateCell(arrivalDate: String?, arrivalTime: String?, imageData: String?, departureDate: String?, departureTime: String?, destination: String?) {
        
        if let arrivalDate = arrivalDate {
            arrivalDateLabel.text = "Date: \(arrivalDate)"
        }
        
        if let arrivalTime = arrivalTime {
            arrivalTimeLabel.text = "Time: \(arrivalTime)"
        }
        
        if let departureDate = departureDate {
            departureDateLabel.text = "Date: \(departureDate)"
           // departureDateLabel.text = departureDate
        }
        
        if let departureTime = departureTime {
            //departureTimeLabel.text = departureTime
            departureTimeLabel.text = "Time: \(departureTime)"
        }
        
        if let destination = destination {
            destinationLabel.text = destination.uppercased()
            emptyLabel.text = destination
        }
        
        if let imageData = imageData {
            ImageUtils.shared.setRemoteImage(for: imageLogo, imageUrl: imageData, orgName: "")
        }
        
    }
    
    func renderForCredebtialBranding(clr: UIColor) {
        arrivalDateLabel.textColor = clr
        departureDateLabel.textColor = clr
        destinationLabel.textColor = clr
        departureTimeLabel.textColor = clr
        arrivalTimeLabel.textColor = clr
        imageLogo.tintColor = clr
    }
    
    
}
