//
//  RecieptCredentialModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/01/23.
//

import Foundation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let recieptCredentialModel = try? JSONDecoder().decode(RecieptCredentialModel.self, from: jsonData)

import Foundation

// MARK: - RecieptCredentialModel
class ReceiptCredentialModel: Codable {
    let context: String?
    let type, customizationID, profileID, iD: String?
    let issueDate, invoiceTypeCode, documentCurrencyCode, buyerReference: String?
    let accountingSupplierParty: AccountingSupplierParty?
    let accountingCustomerParty: AccountingCustomerParty?
    let paymentMeans: PaymentMeans?
    let paymentTerms: PaymentTerms?
    let taxTotal: TaxTotal?
    let legalMonetaryTotal: LegalMonetaryTotal?
    let invoiceLine: [InvoiceLine]?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case customizationID, profileID, iD, issueDate, invoiceTypeCode, documentCurrencyCode, buyerReference, accountingSupplierParty, accountingCustomerParty, paymentMeans, paymentTerms, taxTotal, legalMonetaryTotal, invoiceLine
    }

    //value    String?    "urn:fdc:nsgb:2023:ereceipt:01:1.0"    some
    fileprivate static func checkReceiptModel(_ attr: [SearchCertificateAttribute]?) -> ReceiptCredentialModel? {
        var receipt = ""
        var context = ""
        for e in attr ?? [] {
            if e.name?.lowercased() == "receipt" {
                receipt = e.value ?? ""
            }
            if e.name?.lowercased() == "context" {
                context = e.value ?? ""
            }
        }
        if let dict = UIApplicationUtils.shared.convertToDictionary(text: receipt), context == "urn:fdc:nsgb:2023:ereceipt:01:1.0"{
            let model = ReceiptCredentialModel.decode(withDictionary: dict as [String : Any]) as? ReceiptCredentialModel
            return model
        } else {
            return nil
        }
    }
    
    class func isReceiptCredentialModel(certModel: SearchItems_CustomWalletRecordCertModel) -> ReceiptCredentialModel? {
        let attr = certModel.value?.certInfo?.value?.credentialProposalDict?.credentialProposal?.attributes
        return checkReceiptModel(attr)
    }
    
    class func isReceiptCredentialModel(certModel: SearchCertificateRecord) -> ReceiptCredentialModel? {
        let attr = certModel.value?.credentialProposalDict?.credentialProposal?.attributes
        return checkReceiptModel(attr)
    }
    
    class func isReceiptCredentialModel(searchedAttr: [SearchedAttribute]) -> ReceiptCredentialModel? {
        let attr = searchedAttr.map { e in
            SearchCertificateAttribute.init(name: e.value?.name, value: e.value?.value)
        }
        return checkReceiptModel(attr)
    }
    
    class func isReceiptCredentialModel(attributes: [IDCardAttributes]) -> ReceiptCredentialModel? {
        let attr = attributes.map { e in
            SearchCertificateAttribute.init(name: e.name, value: e.value)
        }
        return checkReceiptModel(attr)
    }
    
    init(context: String?, type: String?, customizationID: String?, profileID: String?, iD: String?, issueDate: String?, invoiceTypeCode: String?, documentCurrencyCode: String?, buyerReference: String?, accountingSupplierParty: AccountingSupplierParty?, accountingCustomerParty: AccountingCustomerParty?, paymentMeans: PaymentMeans?, paymentTerms: PaymentTerms?, taxTotal: TaxTotal?, legalMonetaryTotal: LegalMonetaryTotal?, invoiceLine: [InvoiceLine]?) {
        self.context = context
        self.type = type
        self.customizationID = customizationID
        self.profileID = profileID
        self.iD = iD
        self.issueDate = issueDate
        self.invoiceTypeCode = invoiceTypeCode
        self.documentCurrencyCode = documentCurrencyCode
        self.buyerReference = buyerReference
        self.accountingSupplierParty = accountingSupplierParty
        self.accountingCustomerParty = accountingCustomerParty
        self.paymentMeans = paymentMeans
        self.paymentTerms = paymentTerms
        self.taxTotal = taxTotal
        self.legalMonetaryTotal = legalMonetaryTotal
        self.invoiceLine = invoiceLine
    }
}

// MARK: - AccountingCustomerParty
class AccountingCustomerParty: Codable {
    let party: AccountingCustomerPartyParty?

    init(party: AccountingCustomerPartyParty?) {
        self.party = party
    }
}

// MARK: - AccountingCustomerPartyParty
class AccountingCustomerPartyParty: Codable {
    let endpointID: String?
    let partyName: PartyName?
    let postaladdress: PurplePostaladdress?

    init(endpointID: String?, partyName: PartyName?, postaladdress: PurplePostaladdress?) {
        self.endpointID = endpointID
        self.partyName = partyName
        self.postaladdress = postaladdress
    }
}

// MARK: - PartyName
class PartyName: Codable {
    let name: String?

    init(name: String?) {
        self.name = name
    }
}

// MARK: - PurplePostaladdress
class PurplePostaladdress: Codable {
    let streetName, cityName, postalZone: String?
    let country: PartyName?

    init(streetName: String?, cityName: String?, postalZone: String?, country: PartyName?) {
        self.streetName = streetName
        self.cityName = cityName
        self.postalZone = postalZone
        self.country = country
    }
}

// MARK: - AccountingSupplierParty
class AccountingSupplierParty: Codable {
    let party: AccountingSupplierPartyParty?

    init(party: AccountingSupplierPartyParty?) {
        self.party = party
    }
}

// MARK: - AccountingSupplierPartyParty
class AccountingSupplierPartyParty: Codable {
    let endpointID: String?
    let partyIdentification: PartyIdentification?
    let partyName: PartyName?
    let postaladdress: FluffyPostaladdress?
    let partyTaxScheme: PartyTaxScheme?
    let partyLegalEntity: PartyLegalEntity?

    init(endpointID: String?, partyIdentification: PartyIdentification?, partyName: PartyName?, postaladdress: FluffyPostaladdress?, partyTaxScheme: PartyTaxScheme?, partyLegalEntity: PartyLegalEntity?) {
        self.endpointID = endpointID
        self.partyIdentification = partyIdentification
        self.partyName = partyName
        self.postaladdress = postaladdress
        self.partyTaxScheme = partyTaxScheme
        self.partyLegalEntity = partyLegalEntity
    }
}

// MARK: - PartyIdentification
class PartyIdentification: Codable {
    let iD: String?

    init(iD: String?) {
        self.iD = iD
    }
}

// MARK: - PartyLegalEntity
class PartyLegalEntity: Codable {
    let registrationName, companyID: String?

    init(registrationName: String?, companyID: String?) {
        self.registrationName = registrationName
        self.companyID = companyID
    }
}

// MARK: - PartyTaxScheme
class PartyTaxScheme: Codable {
    let companyID: String?
    let taxScheme: PartyIdentification?

    init(companyID: String?, taxScheme: PartyIdentification?) {
        self.companyID = companyID
        self.taxScheme = taxScheme
    }
}

// MARK: - FluffyPostaladdress
class FluffyPostaladdress: Codable {
    let streetName, cityName, postalZone: String?
    let country: PostalCountry?

    init(streetName: String?, cityName: String?, postalZone: String?, country: PostalCountry?) {
        self.streetName = streetName
        self.cityName = cityName
        self.postalZone = postalZone
        self.country = country
    }
}

// MARK: - Country
class PostalCountry: Codable {
    let name, identificationCode: String?

    init(name: String?, identificationCode: String?) {
        self.name = name
        self.identificationCode = identificationCode
    }
}

// MARK: - InvoiceLine
class InvoiceLine: Codable {
    let iD, invoicedQuantity: String?
    let lineExtensionAmount: Double?
    let item: Item?
    let price: Price?

    init(iD: String?, invoicedQuantity: String?, lineExtensionAmount: Double?, item: Item?, price: Price?) {
        self.iD = iD
        self.invoicedQuantity = invoicedQuantity
        self.lineExtensionAmount = lineExtensionAmount
        self.item = item
        self.price = price
    }
}

// MARK: - Item
class Item: Codable {
    let name: String?
    let classifiedTaxCategory: TaxCategory?

    init(name: String?, classifiedTaxCategory: TaxCategory?) {
        self.name = name
        self.classifiedTaxCategory = classifiedTaxCategory
    }
}

// MARK: - TaxCategory
class TaxCategory: Codable {
    let iD: String?
    let percent: Int?
    let taxScheme: PartyIdentification?

    init(iD: String?, percent: Int?, taxScheme: PartyIdentification?) {
        self.iD = iD
        self.percent = percent
        self.taxScheme = taxScheme
    }
}

// MARK: - Price
class Price: Codable {
    let priceAmount: Double?

    init(priceAmount: Double?) {
        self.priceAmount = priceAmount
    }
}

// MARK: - LegalMonetaryTotal
class LegalMonetaryTotal: Codable {
    let lineExtensionAmount, taxExclusiveAmount, taxInclusiveAmount, chargeTotalAmount: Double?
    let prepaidAmount: Double?
    let payableAmount: Int?

    init(lineExtensionAmount: Double?, taxExclusiveAmount: Double?, taxInclusiveAmount: Double?, chargeTotalAmount: Double?, prepaidAmount: Double?, payableAmount: Int?) {
        self.lineExtensionAmount = lineExtensionAmount
        self.taxExclusiveAmount = taxExclusiveAmount
        self.taxInclusiveAmount = taxInclusiveAmount
        self.chargeTotalAmount = chargeTotalAmount
        self.prepaidAmount = prepaidAmount
        self.payableAmount = payableAmount
    }
}

// MARK: - PaymentMeans
class PaymentMeans: Codable {
    let paymentMeansCode, paymentID: String?
    let payeeFinancialAccount: PayeeFinancialAccount?

    init(paymentMeansCode: String?, paymentID: String?, payeeFinancialAccount: PayeeFinancialAccount?) {
        self.paymentMeansCode = paymentMeansCode
        self.paymentID = paymentID
        self.payeeFinancialAccount = payeeFinancialAccount
    }
}

// MARK: - PayeeFinancialAccount
class PayeeFinancialAccount: Codable {
    let iD, name: String?
    let financialInstitutionBranch: PartyIdentification?

    init(iD: String?, name: String?, financialInstitutionBranch: PartyIdentification?) {
        self.iD = iD
        self.name = name
        self.financialInstitutionBranch = financialInstitutionBranch
    }
}

// MARK: - PaymentTerms
class PaymentTerms: Codable {
    let note: String?

    init(note: String?) {
        self.note = note
    }
}

// MARK: - TaxTotal
class TaxTotal: Codable {
    let taxAmount: Int?
    let taxSubtotal: TaxSubtotal?

    init(taxAmount: Int?, taxSubtotal: TaxSubtotal?) {
        self.taxAmount = taxAmount
        self.taxSubtotal = taxSubtotal
    }
}

// MARK: - TaxSubtotal
class TaxSubtotal: Codable {
    let taxableAmount: Double?
    let taxAmount: Int?
    let taxCategory: TaxCategory?

    init(taxableAmount: Double?, taxAmount: Int?, taxCategory: TaxCategory?) {
        self.taxableAmount = taxableAmount
        self.taxAmount = taxAmount
        self.taxCategory = taxCategory
    }
}
