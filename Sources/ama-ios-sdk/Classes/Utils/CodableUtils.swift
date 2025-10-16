////
////  CodableUtils.swift
////  dataWallet
////
////  Created by MOHAMED REBIN K on 20/01/23.
////
//
//import Foundation
//
//struct CodableUtils {
//    static func decodeAsString<K: CodingKey>(container: KeyedDecodingContainer<K>, codingKey: K) -> String? {
//        let stringValue = try? container.decodeIfPresent(String.self, forKey: codingKey)
//        let dict = try? container.decodeIfPresent([String: Any].self, forKey: codingKey)
//        let array = try? container.decodeIfPresent([Any].self, forKey: codingKey) ?? []
//        var arrayString: [String] = []
//        array?.forEach { e in
//            if let dictionary = e as? [String: Any], let value = dictionary.toString() {
//                arrayString.append(value)
//            } else if let string = e as? String {
//                arrayString.append(string)
//            }
//        }
//        return stringValue ?? dict?.toString() ?? arrayString.joined(separator: ",")
//    }
//
//    static func decodeAsStringMap<K: CodingKey>(container: KeyedDecodingContainer<K>, codingKey: K) -> [String: String] {
//        let dict = try? container.decodeIfPresent([String: Any].self, forKey: codingKey)
//        var convertedDict: [String: String] = [:]
//        if let keys = dict?.keys{
//            for item in keys {
//                if let string = dict?[item] as? String {
//                    convertedDict[item] = string
//                } else if let dict = dict?[item] as? [String: Any] {
//                    convertedDict[item] = dict.toString()
//                } else if let array = dict?[item] as? [Any] {
//                    var arrayString: [String] = []
//                    array.forEach { e in
//                        if let dictionary = e as? [String: Any], let value = dictionary.toString() {
//                            arrayString.append(value)
//                        } else if let string = e as? String {
//                            arrayString.append(string)
//                        }
//                    }
//                    convertedDict[item] = arrayString.joined(separator: ",")
//                }
//            }
//        }
//
//        return convertedDict ?? [:]
//    }
//}
//
//
