//
//  TrustServiceProviersViewModel.swift
//  dataWallet
//
//  Created by iGrant on 11/06/25.
//

import Foundation
import eudiWalletOidcIos

class TrustServiceProviersViewModel {
    
    var data: TrustServiceProvider?
    var credential: String?
    
    var sectionItems = [[IDCardAttributes]]()
    
    
    func loadData(model: TrustServiceProvider) {
        sectionItems.append(firstSection(data: model))
        sectionItems.append(secondSection(data: model))
        sectionItems.append(thirdSection(data: model))
    }
    
    func firstSection(data: TrustServiceProvider) -> [IDCardAttributes] {
        let address = data.tspAddress?.postalAddresses?.first
        let email = data.tspAddress?.electronicAddresses?.uri?.split(separator: ":")
        let emailString = email?.last.map { String($0) } ?? ""
        
        var parts: [String] = []
        if let name = address?.streetAddress , !name.isEmpty {
            parts.append(name)
        }

        if let name = address?.locality , !name.isEmpty {
            parts.append(name)
        }
        if let name = address?.postalCode , !name.isEmpty {
            parts.append(name)
        }

        if let name = address?.countryName, !name.isEmpty {
            parts.append(name)
        }

        let addressString = parts.joined(separator: ", ").trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        
        let array = [
            IDCardAttributes(name: "Address".localized(), value: addressString),
            IDCardAttributes(name: "Email".localized(), value: emailString)
        ]
        return array.createAndFindNumberOfLines()
    }
    
    func secondSection(data: TrustServiceProvider) -> [IDCardAttributes] {
        var section2Attributes: [IDCardAttributes] = []
        
        if let serviceStatus = data.tspServices.first?.serviceStatus {
            section2Attributes.append(IDCardAttributes(name: "Service Status", value: serviceStatus, schemeID: ""))
        }
        if let serviceTypeIdentifier = data.tspServices.first?.serviceTypeIdentifier {
            section2Attributes.append(IDCardAttributes(name: "Service Type", value: serviceTypeIdentifier, schemeID: ""))
        }
        
        return section2Attributes.createAndFindNumberOfLines()
    }
    
    func thirdSection(data: TrustServiceProvider) -> [IDCardAttributes] {
        var section3Attributes: [IDCardAttributes] = []
        var x5cData: String?
        let credentialCount = credential?.split(separator: ".")
        
        if credentialCount?.count == 1 {
            guard let issuerAuthData = MDocVpTokenBuilder().getIssuerAuth(credential: credential ?? "") else { return []}
            x5cData = TrustMechanismManager().extractX5cFromIssuerAuth1(issuerAuth: issuerAuthData)?.first
        } else {
            x5cData = TrustMechanismManager().extractX5cFromCredential(data: credential)?.first
        }
        let certData = parseX509Certificate(base64String: x5cData ?? "")
        var x5cSKIValue: String?
        if let x509SKI = data.tspServices.first?.serviceDigitalIdentities?.last?.x509SKI {
            x5cSKIValue = x509SKI
        } else if let kid = data.tspServices.first?.serviceDigitalIdentities?.last?.KID {
            x5cSKIValue = kid
        } else if let did = data.tspServices.first?.serviceDigitalIdentities?.last?.DID {
            x5cSKIValue = did
        } else if data.tspServices.first?.serviceDigitalIdentities?.last?.x509SKI == nil {
            let ski = X509SkiGeneratorHelper.generateSKI(from: x5cData ?? "")
            x5cSKIValue = ski
        }
        section3Attributes.append(IDCardAttributes(name: "Subject Key Identifier", value: x5cSKIValue, schemeID: ""))
        if let subject = certData?.subject {
            section3Attributes.append(IDCardAttributes(name: "Subject", value: subject, schemeID: ""))
        }
        if let issuer = certData?.issuer {
            section3Attributes.append(IDCardAttributes(name: "Issuer", value: issuer, schemeID: ""))
        }
        if let serialNumber = certData?.serialNumber {
            section3Attributes.append(IDCardAttributes(name: "Serial Number", value: serialNumber, schemeID: ""))
        }
        if let validFrom = certData?.validFrom {
            section3Attributes.append(IDCardAttributes(name: "Valid From", value: validFrom, schemeID: ""))
        }
        if let validTo = certData?.validTo {
            section3Attributes.append(IDCardAttributes(name:  "Valid To", value: validTo, schemeID: ""))
        }
        if let authorityKeyIdentifier = certData?.authorityKeyIdentifier {
            section3Attributes.append(IDCardAttributes(name: "Authority Key Identifier", value: authorityKeyIdentifier, schemeID: ""))
        }
        if let sha256Fingerprint = certData?.sha256Fingerprint{
            section3Attributes.append(IDCardAttributes(name: "SHA-256 Fingerprint", value: sha256Fingerprint, schemeID: ""))
        }
        return section3Attributes.createAndFindNumberOfLines()
    }
    
}
