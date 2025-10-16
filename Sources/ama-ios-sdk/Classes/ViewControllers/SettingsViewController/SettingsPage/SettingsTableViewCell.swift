//
//  SettingsTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 06/09/22.
//

import UIKit
enum SettingsRenderFor {
    case toggle
    case arrow
}

final class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var toggle: UISwitch!
    @IBOutlet weak var arrowImg: UIImageView!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var mainView: UIView!
    
    var toggleTapped: (() -> Void)?
    
    enum RenderedFor {
        case thirdParty
        case settings
    }
    var renderedFor: RenderedFor = .settings
    
    @IBAction func toggleAction(_ sender: Any) {
        switch renderedFor {
        case .settings:
            toggleTapped?()
        case .thirdParty:
            toggleTapped?()
        }
    }
    
    func setData(data: SettingsRow, indexPath: IndexPath) {
        lbl.text = data.label.localize
        switch data.renderFor {
        case .arrow:
            toggle.isHidden = true
            arrowImg.isHidden = false
        case .toggle:
            toggle.isHidden = false
            arrowImg.isHidden = true
        }
        switch indexPath.section {
        case 0:
            if UserDefaults.standard.value(forKey: Constants.userDefault_language) == nil {
                if (LanguageListViewController.language.map({ model in
                    model.code
                }).contains(Locale.current.languageCode ?? "en")) {
                    let index = LanguageListViewController.language.map({ model in
                        model.code
                    }).firstIndex(of: Locale.current.languageCode ?? "en") ?? 0
                    lbl.text = LanguageListViewController.language[index].name
                } else {
                    lbl.text = LanguageListViewController.language.first?.name
                }
            } else {
                if let index = UserDefaults.standard.value(forKey: Constants.userDefault_language) as? Int {
                    lbl.text = LanguageListViewController.language[index].name
                }
            }
        case 1:
            let manager = CoreDataManager()
            if UserDefaults.standard.value(forKey: Constants.userDefault_ledger) == nil {
                UserDefaults.standard.setValue(0, forKey: Constants.userDefault_ledger)
                lbl.text = LedgerListViewController.ledgers.first?.str
            } else {
                lbl.text = manager.getCurrentGenesis()?.str
            }
        case 2:
            switch indexPath.row {
            case 0:
                toggle.isOn = !(UserDefaults.standard.bool(forKey: "isSecurityDisabled"))
                toggle.isUserInteractionEnabled = true
            case 1:
                toggle.isOn = Constants.autoBackupEnabled
                toggle.isUserInteractionEnabled = true
            default: break
            }
        default:
            break
        }
    }
    
    func renderUI(total: Int, now: Int, section: Int) {
        switch section {
        case 0, 1:
            bottomLine.isHidden = true
            mainView.maskedCornerRadius = 7
        default:
            if now == 0 {
                mainView.topMaskedCornerRadius = 7
                bottomLine.isHidden = false
            } else if now == (total - 1) {
                mainView.bottomMaskedCornerRadius = 7
                bottomLine.isHidden = true
            } else {
                mainView.IBcornerRadius = 0
                bottomLine.isHidden = false
            }
        }
    }
    
    func setThirdPartyData(data: [ThirdPartyDus]?, row: Int) {
        guard let model = data?[row] else { return }
        renderedFor = .thirdParty
        arrowImg.isHidden = true
        lbl.text = model.controllerDetails?.organisationName ?? ""
        imgView.isHidden = false
        imgView.loadFromUrl(model.controllerDetails?.logoImageURL ?? "")
        let switchState = model.ddaInstancePermissionState == .allow ? true : false
        toggle.setOn(switchState, animated: true)
        if row == 0 && data?.count == 1 {
            bottomLine.isHidden = true
            mainView.maskedCornerRadius = 7
        } else if row == 0 {
            mainView.topMaskedCornerRadius = 7
            bottomLine.isHidden = false
        } else if row == (data?.count ?? 0) - 1 {
            mainView.bottomMaskedCornerRadius = 7
            bottomLine.isHidden = true
        } else {
            mainView.IBcornerRadius = 0
            bottomLine.isHidden = false
        }
    }
}
