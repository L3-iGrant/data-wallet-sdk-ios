//
//  WalletContainer.swift
//  dataWallet
//
//  Created by sreelekh N on 03/11/21.
//

import Foundation
import UIKit

class WalletContainer: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var walletView: WalletView!
    
    weak var pageDelegate: WalletHomeViewControllerDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadStackView() {
        let view = UIView()
        view.backgroundColor = .yellow
        walletView.walletHeader = nil
        walletView.useHeaderDistanceForStackedCards = true
        walletView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func loadStackContent(content: [SearchItems_CustomWalletRecordCertModel]) {
        let operationQueue = OperationQueue()
        let op1 = BlockOperation {
            DispatchQueue.main.async {
                let subViews = self.walletView.scrollView.subviews
                subViews.forEach({ $0.removeFromSuperview() })
            }
        }
        let op2 = BlockOperation {
            DispatchQueue.main.async {
                self.walletView.presentedCardView = nil
                self.walletView.insertedCardViews.removeAll()
            }
        }
        let op3 = BlockOperation {
            DispatchQueue.main.async {
                self.walletView.calculateLayoutValues()
            }
        }
        let op4 = BlockOperation {
            DispatchQueue.main.async {
                var coloredCardViews = [CardTileView]()
                for index in 0..<content.count {
                    let cardView = CardTileView()
                    cardView.index = index
                    if let data = content[safe: index] {
                        cardView.certificates = data
                    }
                    cardView.cardAction = { [weak self] action in
                        self?.pageDelegate?.cardTapped(card: action)
                    }
                    //cardView.contentView.backgroundColor = (index % 2 == 0) ? .appColor(.cardOddColor) : .white
                    
                    if let bgColor = content[index].value?.backgroundColor{
                        cardView.contentView.backgroundColor = UIColor(hex:bgColor)
                        cardView.whiteShadeView.backgroundColor =  UIColor(hex: bgColor)
                    } else {
                        cardView.contentView.backgroundColor = (index % 2 == 0) ? .appColor(.cardOddColor) : .white
                    }
                    if let textColor = content[index].value?.textColor {
                        cardView.certName.textColor =  UIColor(hex: textColor)
                        cardView.locationName.textColor = UIColor(hex: textColor)
                        cardView.orgName.textColor = UIColor(hex: textColor)
                    }
                    
                    coloredCardViews.append(cardView)
                }
                self.walletView.reload(cardViews: coloredCardViews)
            }
        }
        op2.addDependency(op1)
        op3.addDependency(op2)
        op4.addDependency(op3)
        operationQueue.addOperations([op1, op2, op3, op4], waitUntilFinished: true)
        
        walletView.didPresentCardViewBlock = { _ in
            
        }
    }
    
    func addCard() {
        walletView.insert(cardView: CardTileView(), animated: true, presented: true)
    }
}
