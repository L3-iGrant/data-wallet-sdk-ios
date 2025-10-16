//
//  TableView.Extension.swift
//  
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit
extension UITableView {
    static func getTableview(_ style: Style = .grouped) -> UITableView {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        return tableView
    }

    func update() {
        self.beginUpdates()
        self.endUpdates()
    }

    func reloadInMain() {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    func reloadSection(section: Int) {
        DispatchQueue.main.async {
            self.reloadSections(IndexSet(integer: section), with: .none)
        }
    }

    func addSections(startIndex: Int, endIndex: Int) {
        guard startIndex  == self.numberOfSections  else {
            return
        }
        self.beginUpdates()
        self.insertSections(IndexSet(startIndex..<endIndex), with: .fade)
        self.endUpdates()
    }

    func reloadCell(section: Int, row: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: row, section: section)
            self.reloadRows(at: [indexPath], with: .none)
        }
    }

    func addRows(section: Int, startIndex: Int, endIndex: Int) {
        DispatchQueue.main.async {
            let indexPaths = (startIndex ..< endIndex).map { IndexPath(row: $0, section: section) }
            self.performBatchUpdates({
                self.insertRows(at: indexPaths, with: .automatic)
            }, completion: nil)
        }
    }

    func addRow(section: Int, at row: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: row, section: section)
            self.insertRows(at: [indexPath], with: .automatic)
        }
    }

    func hasRowAtIndexPath(section: Int, row: Int) -> Bool {
        let indexPath = IndexPath(row: row, section: section)
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }

    func reloadRow(_ section: Int, _ row: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: row, section: section)
            if let visibleIndexPaths = self.indexPathsForVisibleRows?.firstIndex(of: indexPath) {
                if visibleIndexPaths != NSNotFound {
                    self.reloadRows(at: [indexPath], with: .fade)
                }
            }
        }
    }

    func deleteRow(section: Int, row: Int) {
        let indexPath = IndexPath(row: row, section: section)
        DispatchQueue.main.async {
            self.performBatchUpdates({
                self.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
        }
    }

    func deleteSection(section: Int) {
        DispatchQueue.main.async {
            self.performBatchUpdates({
                self.deleteSections(IndexSet(integer: section), with: .automatic)
            }, completion: nil)
        }
    }

    func hasRow(at indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }

    func hasSection(at indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections
    }

    func scrollToTop(animated: Bool) {
        let indexPath = IndexPath(row: 0, section: 0)
        if self.hasRow(at: indexPath) {
            self.scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }

    func isCellVisible(section: Int, row: Int) {
        DispatchQueue.main.async {
            guard let indexes = self.indexPathsForVisibleRows else {
                return self.reloadInMain()
            }
            if indexes.contains(where: { $0.section == section && $0.row == row }) {
                self.addRow(section: 0, at: 0)
            } else {
                self.reloadInMain()
            }
        }
    }
}
