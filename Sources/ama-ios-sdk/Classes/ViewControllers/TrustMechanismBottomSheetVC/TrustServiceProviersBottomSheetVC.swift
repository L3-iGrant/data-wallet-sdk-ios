//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 21/08/25.
//

import Foundation
import eudiWalletOidcIos
import CoreLocation
import UIKit

class TrustServiceProviersBottomSheetVC: UIViewController {
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var parentViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var locatiom: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    @IBOutlet weak var dimmedView: UIView!
    
    var trustListItem: TrustServiceProvider?
    let viewModel = TrustServiceProviersViewModel()
    var clearAlpha: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        titleLabel.text = "general_trusted_service_provider".localizedForSDK()
        if let data = viewModel.data {
            companyName.text = data.tspName
            locatiom.text = data.tspAddress?.postalAddresses?.first?.locality
            setFlagFromCityName(data.tspAddress?.postalAddresses?.first?.countryName ?? "", to: countryFlagImageView)
            viewModel.loadData(model: data)
        }
        if clearAlpha {
            dimmedView.backgroundColor = .clear
        } else {
            dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        parentViewHeight.constant = sheetHeight
    }
    
    //let vv = XMLParser(data: <#T##Data#>)
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: CertificateWithDataTableViewCell.self)
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
    }
    
    let geocoder = CLGeocoder()

    func setFlagFromCityName(_ city: String, to imageView: UIImageView) {
        geocoder.geocodeAddressString(city) { placemarks, error in
            guard
                error == nil,
                let placemark = placemarks?.first,
                let country = placemark.country
            else {
                print("Failed to get country for city: \(city)")
                imageView.image = nil // or set a default image
                return
            }

            self.setFlagEmojiImage(for: country, to: imageView)
        }
    }
    
    func getFlagEmoji(for countryName: String) -> String? {
        let locale = Locale(identifier: "en_US")
        
        for code in Locale.isoRegionCodes {
            if let name = locale.localizedString(forRegionCode: code), name.lowercased() == countryName.lowercased() {
                var flag = ""
                for scalar in code.uppercased().unicodeScalars {
                    if let scalarValue = UnicodeScalar(127397 + scalar.value) {
                        flag.unicodeScalars.append(scalarValue)
                    }
                }
                return flag
            }
        }
        
        return nil
    }
    
    func setFlagEmojiImage(for countryName: String, to imageView: UIImageView, fontSize: CGFloat = 40) {
        guard let flagEmoji = getFlagEmoji(for: countryName) else {
            imageView.image = nil
            return
        }

        let label = UILabel()
        label.text = flagEmoji
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.sizeToFit()

        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        imageView.image = image
    }
    
    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
}

extension TrustServiceProviersBottomSheetVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sectionItems.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sectionItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        if let data = self.viewModel.sectionItems[safe: indexPath.section]?[indexPath.row] {
            if isValidURL(data.value ?? "") {
                cell.mainLbl.text = data.name
                cell.blurView.accessibilityLabel = data.value
                cell.tapGesture = UITapGestureRecognizer()
                cell.tapGesture.addTarget(self, action: #selector(handleLabelTap(_:)))
                cell.blurView.addGestureRecognizer(cell.tapGesture)
                let attributedString = NSMutableAttributedString(string: data.value ?? "")
                attributedString.addAttribute(.link, value: attributedString, range: NSRange(location: 0, length: attributedString.length))
                cell.disableCheckBox()
                cell.blurView.blurLbl.attributedText = attributedString
                cell.blurView.blurLabelVerification.isHidden = true
                cell.disableCheckBox()
                cell.blurView.blurLbl.isUserInteractionEnabled = true
            } else {
                cell.setPassportData(model: data, blurStatus: true)
            }
            cell.disableCheckBox()
            cell.renderUI(index: indexPath.row, tot: self.viewModel.sectionItems[indexPath.section].count)
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else {
            let view = GeneralTitleView()
            view.btnNeed = false
            if section == 1 {
                view.value = "SERVICE INFORMATION".localized()
            } else if section == 2 {
                view.value = "SERVICE DIGITAL IDENTITY".localized()
            }
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        } else if section == 1 || section == 2 {
            return 40
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    @objc func handleLabelTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, let label = view.accessibilityLabel,
                  let url = URL(string: label) else {
                return
            }
        UIApplication.shared.open(url)
    }
    
    
}

