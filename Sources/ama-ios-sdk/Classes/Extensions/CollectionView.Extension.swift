//
//  CollectionView.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 01/11/21.
//

import Foundation
import UIKit

extension UICollectionView {

    static func getCV(layOut: UICollectionViewFlowLayout = UICollectionViewFlowLayout()) -> UICollectionView {
        let viewLayout = layOut
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        collectionView.backgroundColor = UIColor.clear
        viewLayout.minimumInteritemSpacing = 0
        viewLayout.minimumLineSpacing = 0
        viewLayout.estimatedItemSize = .zero
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }

    var visibleCurrentCellIndexPath: IndexPath? {
        for cell in self.visibleCells {
            let indexPath = self.indexPath(for: cell)
            return indexPath
        }

        return nil
    }

    func reloadWithAnimation() {
        UIView.transition(with: self,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { self.reloadData() })
    }

    func addSections(startIndex: Int, endIndex: Int, topView: UIViewController, currentView: UIViewController) {
        if topView == currentView {
            DispatchQueue.main.async {
                self.performBatchUpdates({ [weak self] in
                    self?.insertSections(IndexSet(startIndex..<endIndex))
                }, completion: nil)
            }
        }
    }

    func addSections(startIndex: Int, endIndex: Int) {
        guard startIndex == self.numberOfSections else {
            return
        }
        DispatchQueue.main.async {
            self.performBatchUpdates({
                self.insertSections(IndexSet(startIndex..<endIndex))
            }, completion: nil)
        }
    }

    func addRows(startIndex: Int, endIndex: Int, section: Int) {
        let insertIndexPaths = Array(startIndex..<endIndex).map { IndexPath(item: $0, section: section) }
        DispatchQueue.main.async {
            self.performBatchUpdates({
                for indexPath in insertIndexPaths {
                    if self.isValid(indexPath: indexPath) {
                        self.insertItems(at: [indexPath])
                    }
                }
            }, completion: nil)
        }
    }

    func deleteSection(section: Int) {
        self.deleteSections(IndexSet(integer: section))
    }

    func deleteRow(section: Int, row: Int) {
        let indexPath = IndexPath(row: row, section: section)
        DispatchQueue.main.async {
            self.performBatchUpdates({
                if self.isValid(indexPath: indexPath) {
                    self.deleteItems(at: [indexPath])
                }
            }, completion: nil)
        }
    }

    func reloadInMain() {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    func disReloadWithoutAnimation() {
        UIView.performWithoutAnimation {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }

    func reloadSection(_ index: Int) {
        UIView.performWithoutAnimation {
            self.performBatchUpdates({
                let indexSet = IndexSet(integer: index)
                self.reloadSections(indexSet)
            }, completion: nil)
        }
    }

    func reloadRow(_ row: Int, _ section: Int? = 0) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: row, section: section ?? 0)
            if self.isValid(indexPath: indexPath) {
                self.reloadItems(at: [indexPath])
            }
        }
    }

    func isValid(indexPath: IndexPath) -> Bool {
        guard indexPath.section < numberOfSections,
              indexPath.row < numberOfItems(inSection: indexPath.section)
        else { return false }
        return true
    }

    func top() {
        self.setContentOffset(.zero, animated: false)
    }

    func scrollToLast() {
        guard numberOfSections > 0 else {
            return
        }

        let lastSection = numberOfSections - 1

        guard numberOfItems(inSection: lastSection) > 0 else {
            return
        }

        let lastItemIndexPath = IndexPath(item: numberOfItems(inSection: lastSection) - 1,
                                          section: lastSection)
        scrollToItem(at: lastItemIndexPath, at: .bottom, animated: true)
    }

    func scrollToItem(section: Int, row: Int, position: UICollectionView.ScrollPosition = .top, animated: Bool = true) {
        self.scrollToItem(at: IndexPath(row: row, section: section),
                          at: position,
                          animated: animated)
    }
}
