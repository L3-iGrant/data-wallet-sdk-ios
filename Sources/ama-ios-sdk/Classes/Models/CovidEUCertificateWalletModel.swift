//
//  CovidEUCertificateWalletModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 18/07/21.
//

import Foundation
import covid19_global_sdk_iOS

struct CovidEUCertificateWalletModel: Codable {
    let type: IDCardAttributes?
    let fullName: IDCardAttributes?
    let DateOfBirth: IDCardAttributes?
    let memberState: IDCardAttributes?
    let country: IDCardAttributes?
    let vaccineManufacturer: IDCardAttributes?
    let vaccineDate: IDCardAttributes?
    let uniqueCertificateIdentifier: IDCardAttributes?
    let vaccinatedDosage: IDCardAttributes?
    let certificateIssuer: IDCardAttributes?
    let QRCodeImage: IDCardAttributes?
    let certificateIdentifier: IDCardAttributes?
    let validUntil: IDCardAttributes?
    
    let name: IDCardAttributes?
    let DOB: IDCardAttributes?
    let state: IDCardAttributes?
    let disease: IDCardAttributes?
    let testType: IDCardAttributes?
    let testName: IDCardAttributes?
    let manufactur: IDCardAttributes?
    let sampleCollectionDate: IDCardAttributes?
    let result: IDCardAttributes?
    let center: IDCardAttributes?

    static func initFromCovidCertModel(model: ValidationResult, QRCode: String?) -> CovidEUCertificateWalletModel {
        
        let beneficiaryName = (model.greenpass?.person.givenName?.uppercased() ?? "") + " " + (model.greenpass?.person.familyName?.uppercased() ?? "")
        let ageValue = model.greenpass?.dateOfBirth ?? ""
        let vaccination = model.greenpass?.vaccinations?.last
        let dateOfDoseValue = vaccination?.vaccinationDate
        let vaccineManufacturerValue = VaccineManufacturer(rawValue: vaccination?.marketingAuthorizationHolder ?? "")?.humanReadable() ?? vaccination?.marketingAuthorizationHolder
        let vaccinatedDosageValue = "\(vaccination?.doseNumber ?? 0) of \(vaccination?.totalDoses ?? 0)"
        let country =  IDCardAttributes.init(name: "country", value: model.metaInformation?.issuer)
        let type = IDCardAttributes.init(name: "type", value: IDCardType.CovidCert_EU.rawValue)
        let fullName = IDCardAttributes.init(name: "Covid EU Beneficiary Name", value:beneficiaryName)
        let DateOfBirth = IDCardAttributes.init(name: "Covid EU Date Of Birth", value:ageValue)
        let memberState = IDCardAttributes.init(name: "Covid EU Member State", value:vaccination?.country)
        let vaccineManufacturer = IDCardAttributes.init(name: "Covid EU Vaccine Manufacturer", value:vaccineManufacturerValue)
        let vaccineDate = IDCardAttributes.init(name: "Covid EU Vaccine Date", value:dateOfDoseValue)
        let uniqueCertificateIdentifier = IDCardAttributes.init(name: "Covid EU Unique Certificate Identifier", value: vaccination?.certificateIdentifier)
        let vaccinationDosage = IDCardAttributes.init(name: "Covid EU Vaccination Dosage", value: vaccinatedDosageValue)
        let certificateIssuer = IDCardAttributes.init(name: "Covid EU Certificate Issuer", value: vaccination?.certificateIssuer ?? "")
        let QRCodeImage = IDCardAttributes.init(type: .image, name: "QRCode", value: QRCode)
        let validUntil = IDCardAttributes.init(name: "Certificate Valid Until", value: String(model.metaInformation?.expirationTime?.split(separator: "T").first ?? "NA"))

        let tests = model.greenpass?.tests?.last
        let certificateIdentifier = IDCardAttributes.init(name: "Covid EU Vaccination Dosage", value: tests?.certificateIdentifier ?? "")

        return CovidEUCertificateWalletModel(type: type, fullName: fullName, DateOfBirth: DateOfBirth, memberState: memberState, country: country, vaccineManufacturer: vaccineManufacturer, vaccineDate: vaccineDate, uniqueCertificateIdentifier: uniqueCertificateIdentifier, vaccinatedDosage: vaccinationDosage, certificateIssuer: certificateIssuer, QRCodeImage: QRCodeImage, certificateIdentifier: certificateIdentifier, validUntil: validUntil, name: nil, DOB: nil, state: nil, disease: nil, testType: nil, testName: nil, manufactur: nil, sampleCollectionDate: nil, result: nil, center: nil)
    }

    static func getEUTestSaverModel(savedModel: [IDCardAttributes]) -> CovidEUCertificateWalletModel {

        let type = IDCardAttributes.init(name: "type", value: IDCardType.digitalTestCertificateEU.rawValue)
        let certificateIssuer = IDCardAttributes.init(name: "EU Certificate Issuer", value: savedModel[safe: 13]?.value ?? "")
        let name = IDCardAttributes.init(name: "EU Beneficiary Name", value: savedModel[safe: 0]?.value ?? "")
        let dob = IDCardAttributes.init(name: "EU Date Of Birth", value: savedModel[safe: 1]?.value ?? "")
        let state = IDCardAttributes.init(name: "EU Member State", value: savedModel[safe: 2]?.value ?? "")
        let certificateIdentifier = IDCardAttributes.init(name: "EU Unique Certificate Identifier", value: savedModel[safe: 3]?.value ?? "")
        let disease = IDCardAttributes.init(name: "EU Disease", value: savedModel[safe: 4]?.value ?? "")
        let testType = IDCardAttributes.init(name: "EU Type of Tests", value: savedModel[safe: 5]?.value ?? "")
        let testName = IDCardAttributes.init(name: "EU Test Name", value: savedModel[safe: 6]?.value ?? "")
        let manufactur = IDCardAttributes.init(name: "EU Test Device Identifier", value: savedModel[safe: 7]?.value ?? "")
        let sampleCollectionDate = IDCardAttributes.init(name: "EU Sample Collection Date", value: savedModel[safe: 8]?.value ?? "")
        let result = IDCardAttributes.init(name: "EU Test Result", value: savedModel[safe: 10]?.value ?? "")
        let center = IDCardAttributes.init(name: "EU Test Center", value: savedModel[safe: 11]?.value ?? "")
        let qrCode = IDCardAttributes.init(name: "QRCode", value: savedModel[safe: 12]?.value ?? "")
        let validUntil = IDCardAttributes.init(name: "Certificate Valid Until", value: savedModel[safe: 9]?.value ?? "")

        let model = CovidEUCertificateWalletModel(
            type: type,
            fullName: nil,
            DateOfBirth: nil,
            memberState: nil,
            country: nil,
            vaccineManufacturer: nil,
            vaccineDate: nil,
            uniqueCertificateIdentifier: nil,
            vaccinatedDosage: nil,
            certificateIssuer: certificateIssuer,
            QRCodeImage: qrCode,
            certificateIdentifier: certificateIdentifier,
            validUntil: validUntil,
            name: name,
            DOB: dob,
            state: state,
            disease: disease,
            testType: testType,
            testName: testName,
            manufactur: manufactur,
            sampleCollectionDate: sampleCollectionDate,
            result: result,
            center: center
        )
        return model
    }

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case country = "country"
        case fullName = "Covid EU Beneficiary Name"
        case DateOfBirth = "Covid EU Date Of Birth"
        case memberState = "Covid EU Member State"
        case vaccineManufacturer = "Covid EU Vaccine Manufacturer"
        case vaccineDate = "Covid EU Vaccine Date"
        case uniqueCertificateIdentifier = "Covid EU Unique Certificate Identifier"
        case vaccinatedDosage = "Covid EU Vaccination Dosage"
        case certificateIssuer = "Covid EU Certificate Issuer"
        case QRCodeImage = "QRCode"
        case validUntil = "Certificate Valid Until"
        
        //EU Test
        case certificateIdentifier = "EU Unique Certificate Identifier"
        case name = "EU Beneficiary Name"
        case DOB = "EU Date Of Birth"
        case state = "EU Member State"
        case disease = "EU Disease"
        case testType =  "EU Type of Tests"
        case testName = "EU Test Name"
        case manufactur = "EU Test Device Identifier"
        case sampleCollectionDate = "EU Sample Collection Date"
        case result = "EU Test Result"
        case center = "EU Test Center"
    }
}
