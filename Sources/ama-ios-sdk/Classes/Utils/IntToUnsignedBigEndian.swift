//
//  IntToUnsignedBigEndian.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 14/02/22.
//

import Foundation

struct IntToUnsignedBigEndian{
    
    static func pack(value: Int) -> Data {
        var bytes = [UInt8]()
//        let alignment = false
//        let PAD_BYTE = UInt8(0)
//
//        func padAlignment(size: Int) {
//            if alignment {
//                let mask = size - 1
//                while (bytes.count & mask) != 0 {
//                    bytes.append(PAD_BYTE)
//                }
//            }
//        }
//
//        padAlignment(size: 8)
        bytes = value.splitBytesBigEndian(size: 8)
        return Data.init(bytes: bytes, count: bytes.count)
    }
}
