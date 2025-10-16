//
//  CertificateWithDataTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 22/01/21.
//

import UIKit

final class CertificateWithDataTableViewCell: UITableViewCell,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var certAttributeTableView: AGTableView!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var headerStackView: UIStackView!
    
    var certData: [IDCardAttributes] = [] {
        didSet {
            certAttributeTableView.reloadInMain()
        }
    }
    var showValues = true
    var blurValues = true
    var valueTextAlignment: NSTextAlignment?
    
    var bgColor: UIColor? {
        didSet {
            certAttributeTableView.reloadInMain()
        }
    }
    
    var labelColor: UIColor? {
        didSet {
            certAttributeTableView.reloadInMain()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        certAttributeTableView.delegate = self
        certAttributeTableView.dataSource = self
        baseView.layer.cornerRadius = 10
        certAttributeTableView.estimatedRowHeight = 60
        certAttributeTableView.rowHeight = UITableView.automaticDimension;
        certAttributeTableView.register(UINib(nibName: "ExchangeDataPreviewTableViewCell", bundle: Constants.bundle), forCellReuseIdentifier: "ExchangeDataPreviewTableViewCell")
        certAttributeTableView.register(UINib(nibName: "ExchangeDataImagePreviewTableViewCell", bundle: Constants.bundle), forCellReuseIdentifier: "ExchangeDataImagePreviewTableViewCell")
        certAttributeTableView.register(UINib(nibName: "DataAgreementTableViewCell", bundle: Constants.bundle), forCellReuseIdentifier: "DataAgreementTableViewCell")
        certAttributeTableView.register(cellType: CovidValuesRowTableViewCell.self)
        certAttributeTableView.separatorStyle = .none
        addButton?.imageView?.contentMode = .scaleAspectFit
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        UIView.performWithoutAnimation {
            self.superTableView?.beginUpdates()
            self.layoutIfNeeded()
            self.superTableView?.endUpdates()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.contentView.layoutIfNeeded()
        self.contentView.updateConstraints()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attribute = certData[safe: indexPath.row]
        if attribute?.type == CertAttributesTypes.image {
            let cell:ExchangeDataImagePreviewTableViewCell? = tableView.dequeueReusableCell(withIdentifier: "ExchangeDataImagePreviewTableViewCell") as? ExchangeDataImagePreviewTableViewCell
            cell?.attrName.text = (attribute?.name ?? "").uppercaseFirstWords
            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                cell?.seperator.isHidden = true
            }else{
                cell?.seperator.isHidden = false
            }
            cell?.attrImage.layer.cornerRadius = 8
            cell?.attrImage.contentMode = .scaleAspectFit
            if let cellBG = bgColor {
                cell?.backgroundColor = cellBG
            }
            cell?.setBlur(value: blurValues)
            if let image = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: attribute?.value ?? "") {
                cell?.attrImage.image =  image
            } else {
                cell?.attrImage.image =  "placeholder".getImage()
            }
            cell?.selectionStyle = .none
            return cell ?? ExchangeDataPreviewTableViewCell()
        } else {
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            if let data = certData[safe: indexPath.row] {
                cell.setData(model: data, blurStatus: blurValues)
                cell.renderUI(index: indexPath.row, tot: certData.count)
            }
            cell.removePadding()
            cell.arrangeStackForDataAgreement()
            cell.layoutIfNeeded()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let attribute = certData[safe: indexPath.row]
        if attribute?.type == CertAttributesTypes.image {
            return 130
        }
        return UITableView.automaticDimension
    }
}
