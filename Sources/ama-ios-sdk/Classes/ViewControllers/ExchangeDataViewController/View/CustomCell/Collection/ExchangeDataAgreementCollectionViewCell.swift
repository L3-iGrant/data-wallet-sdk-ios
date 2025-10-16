//
//  ExchangeDataAgreementCollectionViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 24/09/21.
//

import UIKit

class ExchangeDataAgreementCollectionViewCell: UICollectionViewCell {
    let dataAgreementHeaderHeight: CGFloat = 50
    var dataAgreement: DataAgreementModel?
    @IBOutlet weak var tableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.register(UINib(nibName: "DataAgreementTableViewCell", bundle: Constants.bundle), forCellReuseIdentifier: "DataAgreementTableViewCell")
        // Initialization code
    }
}

extension ExchangeDataAgreementCollectionViewCell: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataAgreementHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let header = UILabel.init(frame: CGRect.init(x: 18, y: 0, width: tableView.frame.width - 30, height: dataAgreementHeaderHeight))
            header.text = "Data Agreement Policy".localizedForSDK()
            header.textColor = UIColor.gray
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width - 30, height: dataAgreementHeaderHeight))
            headerView.addSubview(header)
            return headerView
        } else {
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell:DataAgreementTableViewCell? = tableView.dequeueReusableCell(withIdentifier: "DataAgreementTableViewCell") as? DataAgreementTableViewCell
            switch indexPath.row {
                case 0:
                    cell?.name.text = "Lawful basis of processing".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.lawfulBasisOfProcessing
                    cell?.borderConfigForTop()
                case 1:
                    cell?.name.text = "Policy URL".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.policyURL
                    cell?.borderConfigForMiddle()
                case 2:
                    cell?.name.text = "Jurisdiction".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.jurisdiction
                    cell?.borderConfigForMiddle()
                case 3:
                    cell?.name.text = "Third party disclosure".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.disclosure
                    cell?.borderConfigForMiddle()
                case 4:
                    cell?.name.text = "Industry scope".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.industryScope
                    cell?.borderConfigForMiddle()
                case 5:
                    cell?.name.text = "Geographic restriction".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.restriction
                    cell?.borderConfigForMiddle()
                case 6:
                    cell?.name.text = "Is shared to 3pps?".localizedForSDK()
                    cell?.value.text = dataAgreement?.purposeDetails?.purpose?.shared3Pp ?? false ? "True".localizedForSDK() : "False".localizedForSDK()
                    cell?.borderConfigForBottom()
                default:
                    cell?.name.text = "".localizedForSDK()
                    cell?.value.text = ""
            }
            return cell ?? UITableViewCell()
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
//    {
//        let cornerRadius = 5
//        var corners: UIRectCorner = []
//
//        if indexPath.row == 0
//        {
//            corners.update(with: .topLeft)
//            corners.update(with: .topRight)
//        }
//
//        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
//        {
//            corners.update(with: .bottomLeft)
//            corners.update(with: .bottomRight)
//        }
//
//        let maskLayer = CAShapeLayer()
//        maskLayer.path = UIBezierPath(roundedRect: cell.bounds,
//                                      byRoundingCorners: corners,
//                                      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
//        cell.layer.mask = maskLayer
//    }
}
