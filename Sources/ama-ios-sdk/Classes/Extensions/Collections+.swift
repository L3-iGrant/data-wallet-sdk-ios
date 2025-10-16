//
//  Collections+.swift
//  dataWallet
//
//  Created by sreelekh N on 16/09/22.
//

import Foundation
extension Sequence {
    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        return Dictionary.init(grouping: self, by: key)
    }
}
