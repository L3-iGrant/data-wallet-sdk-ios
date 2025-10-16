//
//  SettingsPageViewController+Confirm.swift
//  dataWallet
//
//  Created by sreelekh N on 06/09/22.
//

import Foundation
extension SettingsPageViewController: CountriesViewControllerDelegate {
    
    func getSelectedCountries() {
        if let countriesString =  UserDefaults.standard.value(forKey: Constants.add_card_selected_countries) as? String, !countriesString.isEmpty{
            let countries = countriesString.split(separator: ",")
            let countriesModel = Countries.countries
            self.viewModel.selectedCountriesArray.removeAll()
            for county in countries {
                if let selectedItem = countriesModel.first(where: { item in
                    (item.regionID ?? "") == county
                }){
                    self.viewModel.selectedCountriesArray.append(selectedItem)
                }
            }
        } else {
            self.viewModel.selectedCountriesArray.removeAll()
        }
    }
    
    func countriesViewController(_ countriesViewController: CountriesViewController, didSelectCountries countries: [Country]) {
        var arrayOfIds: [String] = []
        countries.forEach { co in
            arrayOfIds.append(co.regionID ?? "")
            arrayOfIds.append(contentsOf: co.parent ?? [])
        }
        let idsSet = Set(arrayOfIds)
        UserDefaults.standard.setValue(idsSet.joined(separator: ","), forKey: Constants.add_card_selected_countries)
        getSelectedCountries()
    }
    
    func countriesViewControllerDidCancel(_ countriesViewController: CountriesViewController) {}
    
    func countriesViewController(_ countriesViewController: CountriesViewController, didSelectCountry country: Country) {}
    
    func countriesViewController(_ countriesViewController: CountriesViewController, didUnselectCountry country: Country) {}
}
