//
//  WalletHomeTitle.swift
//  dataWallet
//
//  Created by sreelekh N on 02/11/21.
//

import UIKit
protocol WalletHomeTitleDelegate: AnyObject {
    func searchStarted(value: String)
    func addCardTapped()
    func filterAction(filterOn: Int)
    func closeButtonAction()
    func filterButtonAction()
}

extension WalletHomeTitleDelegate {
    func filterAction(filterOn: Int) {}
    func addCardTapped() {}
    func filterButtonAction() {}
}

final class WalletHomeTitle: UIView, UITextFieldDelegate {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var newBtn: UIButton!
    @IBOutlet weak var cvHeight: NSLayoutConstraint!
    @IBOutlet weak var inBetweenHeight: NSLayoutConstraint!
    @IBOutlet weak var infoHeight: NSLayoutConstraint!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var plusgapBottom: NSLayoutConstraint!
    @IBOutlet weak var searchField: BindingTextField! {
        didSet {
            searchField.bind(completion: { [weak self] str in
                self?.pageDelegate?.searchStarted(value: str)
            })
        }
    }
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(cellType: FiltercardsCollectionViewCell.self)
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var filterButton: UIButton!
    
    @IBOutlet weak var filterImageView: UIImageView!
    
    var selectedIndex = 0
    weak var pageDelegate: WalletHomeTitleDelegate?
    
    @IBAction func newAction(_ sender: Any) {
        pageDelegate?.addCardTapped()
    }
    
    enum WalletViewType {
        case home
        case connection
        case organisationSearch
        case thirdParty
    }
    
    var viewMode: ViewMode = .FullScreen
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(type: WalletViewType = .home) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
        renderView(type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(userText: UITextField!) -> Bool {
        searchField.resignFirstResponder()
        return true
    }
    
    public func renderView(type: WalletViewType = .home) {
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            lbl.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        }
        closeButton.isHidden = AriesMobileAgent.shared.getViewMode() != .BottomSheet
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet && type == .connection {
            filterButton.isHidden = false
            filterImageView.isHidden = false
        } else {
            filterButton.isHidden = true
            filterImageView.isHidden = true
        }
//        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
//            if type == .home {
//                cvHeight.constant = 0
//                inBetweenHeight.constant = 0
//                collectionView.isHidden = true
//                newBtn.isHidden = false
//            }
//        } else {
            switch type {
            case .connection:
                cvHeight.constant = 0
                inBetweenHeight.constant = 0
                collectionView.isHidden = true
                newBtn.isHidden = false
            case .organisationSearch:
                cvHeight.constant = 0
                inBetweenHeight.constant = 0
                collectionView.isHidden = true
                newBtn.isHidden = true
            case .thirdParty:
                cvHeight.constant = 0
                inBetweenHeight.constant = 0
                infoHeight.constant = 0
                plusgapBottom.constant = 0
                collectionView.isHidden = true
                newBtn.isHidden = true
                searchField.placeholder = "Search organisations...".localize
            default:
                cvHeight.constant = 75
                inBetweenHeight.constant = 10
                collectionView.isHidden = false
                newBtn.isHidden = false
            }
//        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        pageDelegate?.closeButtonAction()
    }
    
    @IBAction func filterAction(_ sender: Any) {
        pageDelegate?.filterButtonAction()
    }
    
    
}
