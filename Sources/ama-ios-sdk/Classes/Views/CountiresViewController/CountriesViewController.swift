//
//  CountriesViewController.swift
//  CountryCode
//
//  Created by Created by WeblineIndia  on 01/07/20.
//  Copyright © 2020 WeblineIndia . All rights reserved.
//

import UIKit
import Foundation
import CoreData
import M13Checkbox

/// Class to select countries
 final class CountriesViewController: AriesBaseViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    public var unfilteredCountries: [[Country]]! { didSet { filteredCountries = unfilteredCountries } }
    public var filteredCountries: [[Country]]!
    public var majorCountryLocaleIdentifiers: [String] = []
    public var delegate: CountriesViewControllerDelegate?
    public var allowMultipleSelection: Bool = true
    public var selectedCountries: [Country] = [Country]() {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled = self.selectedCountries.count > 0
        }
    }

    var renderForWelcome: Bool = false {
        didSet {
            if renderForWelcome {
                viewToHide.forEach( { $0.isHidden = true } )
            }
        }
    }
    @IBOutlet var viewToHide: [UIView]!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    /// Calculate the nav bar height if present


    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var searchCancelButton: UIButton!
    private var searchString: String = ""
    @IBOutlet weak var searchBgView: UIView!

// viewDidLoad specify the design of country picker when it is loaded
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Regions".localizedForSDK()

        self.baseView.layer.cornerRadius = 10
        self.baseView.layer.masksToBounds = true
        searchBgView.layer.cornerRadius = 8
        searchBar.removeBg()
        /// Configure tableVieew
        tableView.keyboardDismissMode   = .onDrag
        /// Add delegates
        searchBar.delegate      = self
        tableView.dataSource    = self
        tableView.delegate      = self
        self.searchBar.placeholder = "Search".localizedForSDK()
        /// Setup controller
        setupCountries()
    }

    // MARK: - UISearchBarDelegate
//Serach bar method to search countries
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchString = searchText
        searchForText(searchText)
        tableView.reloadData()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchCancelButton.isEnabled = true
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchCancelButton.isEnabled = false
    }
    @IBAction func searchBarCancelButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.searchCancelButton.isEnabled = false
        self.searchBar.text = ""
        searchForText(searchBar.text ?? "")
    }

    fileprivate func searchForText(_ text: String) {
        if text.isEmpty {
            filteredCountries = unfilteredCountries
        } else {
            let allCountries: [Country] = Countries.countries.filter { $0.regionLabel?.lowercased().range(of: text.lowercased()) != nil }
            filteredCountries = partionedArray(allCountries, usingSelector: #selector(getter: NSFetchedResultsSectionInfo.name))
            filteredCountries.insert([], at: 0) //Empty section for our favorites
        }
        tableView.reloadData()
    }

    // MARK: Viewing Countries
    fileprivate func setupCountries() {

        unfilteredCountries = partionedArray(Countries.countries.filter({ co in
            !selectedCountries.contains(co)
        }), usingSelector: #selector(getter: NSFetchedResultsSectionInfo.name))
//        unfilteredCountries.insert(Countries.countriesFromCountryCodes(majorCountryLocaleIdentifiers), at: 0)
        unfilteredCountries.insert(selectedCountries, at: 0)

        unfilteredCountries.insert([Country(disabled: false, regionID: "ALL", regionLabel: "International", parent: [])], at: 0)

        searchForText(searchBar.text ?? "")

        /// If some countries are selected, scroll to the first
//        if let selectedCountry = selectedCountries.first {
//            for (index, countries) in unfilteredCountries.enumerated() {
//                if let countryIndex = countries.firstIndex(of: selectedCountry) {
//                    let indexPath = IndexPath(row: countryIndex, section: index)
//                    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
//                    break
//                }
//            }
//        }
    }

    //  UItableViewDelegate,UItableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return filteredCountries.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCountries[section].count
    }


    public  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        /// Obtain a cell
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else {
                return UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "Cell")
            }
            cell.contentView.backgroundColor = UIColor(named:"contactListingColor")
            return cell
        }()

        /// Configure cell
        let country                 = filteredCountries[indexPath.section][indexPath.row]
        cell.textLabel?.text        = country.regionLabel ?? ""
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
//        cell.textLabel?.textColor = .darkGray

        cell.detailTextLabel?.text  = ""
        let button = M13Checkbox.init(frame: CGRect.init(x: 0, y: 0, width: 20, height: 20))
        button.boxType = .square
        button.stateChangeAnimation = .fill
        button.tintColor = (country.disabled ?? false) ? .lightGray : .black
        button.secondaryTintColor = (country.disabled ?? false) ? .lightText : .black
        cell.accessoryView = button
        (selectedCountries.firstIndex(of: country) != nil) ? button.setCheckState(.checked, animated: false) : button.setCheckState(.unchecked, animated: false)
        cell.contentView.backgroundColor = UIColor(named:"contactListingColor")
        cell.textLabel?.isEnabled = !(country.disabled ?? false)
        button.isEnabled = !(country.disabled ?? false)
        button.isUserInteractionEnabled = false
        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets.zero

        if indexPath.section == 0 {
            (selectedCountries.isEmpty) ? button.setCheckState(.checked, animated: false) : button.setCheckState(.unchecked, animated: false)

        }
        //To remove last cell seperator
        if (tableView.numberOfSections - 1) == indexPath.section {
            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width , bottom: 0, right: 0)
            }
        }
        return cell
    }

//    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//
//        let countries = filteredCountries[section]
//        if countries.isEmpty {
//            return nil
//        }
//        if section == 0 {
//            return ""
//        }
//        return UILocalizedIndexedCollation.current().sectionTitles[section - 1]
//
//    }
//section are prepared as per localization of countries
//    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
//        return searchString != "" ? nil : UILocalizedIndexedCollation.current().sectionTitles
//    }

//    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
//        return UILocalizedIndexedCollation.current().section(forSectionIndexTitle: index + 1)
//    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let country = filteredCountries[indexPath.section][indexPath.row]
        if (country.disabled ?? false){
            return
        }
        if (indexPath.section == 0){
            if let cell = tableView.cellForRow(at: indexPath) {
            let button = cell.accessoryView as! M13Checkbox
                if button.checkState == .checked {
//                    button.checkState = .unchecked
//                    delegate?.countriesViewController(self, didSelectCountries: selectedCountries)
                }else{
                    selectedCountries.removeAll()
                    button.checkState = .checked
                    delegate?.countriesViewController(self, didSelectCountries: selectedCountries)
                }
            }
            setupCountries()
            return
        }
        if allowMultipleSelection {
            if let cell = tableView.cellForRow(at: indexPath) {
                let button = cell.accessoryView as! M13Checkbox
                if button.checkState == .checked {
                    button.checkState = .unchecked
                    let co = filteredCountries[indexPath.section][indexPath.row]
                    selectedCountries = selectedCountries.filter({
                        $0.regionID != co.regionID
                    })

                    /// Comunicate to delegate
                    delegate?.countriesViewController(self, didUnselectCountry: co)
                    delegate?.countriesViewController(self, didSelectCountries: selectedCountries)
                } else {

                    delegate?.countriesViewController(self, didSelectCountry: filteredCountries[indexPath.section][indexPath.row])
                    selectedCountries.append(filteredCountries[indexPath.section][indexPath.row])
                    delegate?.countriesViewController(self, didSelectCountries: selectedCountries)
                    button.checkState = .checked
                }
            }
        } else {
            /// Comunicate to delegate
            delegate?.countriesViewController(self, didSelectCountry: filteredCountries[indexPath.section][indexPath.row])
            self.dismiss(animated: true) { () -> Void in }
        }
        setupCountries()
    }

    /// Function to present a selector in a UIViewContoller claass
    ///
    /// - Parameter to: UIViewController current visibile
    public class func show(countriesViewController coVar: CountriesViewController, toVar: UIViewController) {
        let navController  = UINavigationController(rootViewController: coVar)
        toVar.present(navController, animated: true) { () -> Void in }
    }

}

/// Return partionated array
///
/// - Parameters:
///   - array: source array
///   - selector: selector
/// - Returns: Partionaed array
private func partionedArray<T: AnyObject>(_ array: [T], usingSelector selector: Selector) -> [[T]] {

    let collation = UILocalizedIndexedCollation.current()
    let numberOfSectionTitles = collation.sectionTitles.count
    var unsortedSections: [[T]] = Array(repeating: [], count: numberOfSectionTitles)

    for object in array {
        let sectionIndex = collation.section(for: object, collationStringSelector: selector)
        unsortedSections[sectionIndex].append(object)
    }

    var sortedSections: [[T]] = []

    for section in unsortedSections {
        let sortedSection = collation.sortedArray(from: section, collationStringSelector: selector) as! [T]
        sortedSections.append(sortedSection)
    }

    return sortedSections

}
