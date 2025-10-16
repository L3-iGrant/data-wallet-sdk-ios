//
//  CovidIndiaCertificateModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 18/07/21.
//

import Foundation
import covid19_global_sdk_iOS


struct CovidIndiaCertificateWalletModel: Codable {
    let type: IDCardAttributes?
    let fullName: IDCardAttributes?
    let age: IDCardAttributes?
    let gender: IDCardAttributes?
    let idVerified: IDCardAttributes?
    let idNumber: IDCardAttributes?
    let uniqueHealthId: IDCardAttributes?
    let beneficiaryRefId: IDCardAttributes?
    let vaccineName: IDCardAttributes?
    let dateOfDose: IDCardAttributes?
    let vaccinatedBy: IDCardAttributes?
    let vaccinatedAt: IDCardAttributes?
    let vaccinationDosage: IDCardAttributes?
    let QRCodeImage: IDCardAttributes?
    
    static func initFromCovidCertModel(model: CovidIndiaCertificateModel, QRCode: String?) -> CovidIndiaCertificateWalletModel{
        let beneficiaryName = model.credentialSubject?.name
        let ageValue = model.credentialSubject?.age ?? UIApplicationUtils.shared.calcAge(birthday: model.credentialSubject?.dob ?? "")
        let genderValue = model.credentialSubject?.gender ?? model.credentialSubject?.sex
        let id = model.credentialSubject?.id?.split(separator: ":")
        var idVerifiedValue: String?
        var idNumberValue: String?
        if (id?.count ?? 0) > 2{
            idVerifiedValue = "\(id?[1] ?? "")"
            idNumberValue = "\(id?[2] ?? "")"
        } else {
            idVerifiedValue = "NA"
            idNumberValue = "NA"
        }
        let uniqueHealthIDValue = model.credentialSubject?.uhid ?? ""
        let beneficiaryReferenceIDValue = model.credentialSubject?.refID ?? ""
        let vaccine = model.evidence?.last
        let vaccinationNameValue = vaccine?.vaccine ?? ""
        let dateOfDoseValue = vaccine?.date
        let vaccinatedByValue = vaccine?.verifier?.name ?? ""
        let vaccinationAtValue = vaccine?.facility?.name ?? ""
        let vaccinatedDosageValue = "\(vaccine?.dose ?? 0) of \(vaccine?.totalDoses ?? 0)"
        var typeValue = IDCardType.CovidCert_IND.rawValue
        if model.issuer == "PHL DOH"{
            typeValue = IDCardType.CovidCert_PHL.rawValue
        }
        
        let type = IDCardAttributes.init(name: "type", value: typeValue)
        let fullName = IDCardAttributes.init(name: "Covid IN Beneficiary Name", value:beneficiaryName)
        let age = IDCardAttributes.init(name: "Covid IN Age", value:ageValue)
        let gender = IDCardAttributes.init(name: "Covid IN Gender", value:genderValue)
        let idVerified = IDCardAttributes.init(name: "Covid IN ID Verified", value:idVerifiedValue)
        let uniqueHealthId = IDCardAttributes.init(name: "Covid IN Unique Health ID", value:uniqueHealthIDValue)
        let beneficiaryRefId = IDCardAttributes.init(name: "Covid IN Beneficiary Reference ID", value:beneficiaryReferenceIDValue)
        let vaccineName = IDCardAttributes.init(name: "Covid IN Vaccine Name", value:vaccinationNameValue)
        let dateOfDose = IDCardAttributes.init(name: "Covid IN Date of Dose", value: dateOfDoseValue)
        let vaccinatedBy = IDCardAttributes.init(name: "Covid IN Vaccinated By", value:vaccinatedByValue)
        let vaccinatedAt = IDCardAttributes.init(name: "Covid IN Vaccinated At", value:vaccinationAtValue)
        let vaccinationDosage = IDCardAttributes.init(name: "Covid IN Vaccination Dosage", value: vaccinatedDosageValue)
        let idNumber = IDCardAttributes.init(name: "Covid IN ID Number", value:idNumberValue)
        let QRCodeImage = IDCardAttributes.init(type: .image, name: "QRCode", value: QRCode)
        return CovidIndiaCertificateWalletModel.init(type: type, fullName: fullName, age: age, gender: gender, idVerified: idVerified, idNumber: idNumber, uniqueHealthId: uniqueHealthId, beneficiaryRefId: beneficiaryRefId, vaccineName: vaccineName, dateOfDose: dateOfDose, vaccinatedBy: vaccinatedBy, vaccinatedAt: vaccinatedAt, vaccinationDosage: vaccinationDosage, QRCodeImage: QRCodeImage)
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case fullName = "Covid IN Beneficiary Name"
        case age = "Covid IN Age"
        case gender = "Covid IN Gender"
        case idVerified = "Covid IN ID Verified"
        case idNumber = "Covid IN ID Number"
        case uniqueHealthId = "Covid IN Unique Health ID"
        case beneficiaryRefId = "Covid IN Beneficiary Reference ID"
        case vaccineName = "Covid IN Vaccine Name"
        case dateOfDose = "Covid IN Date of Dose"
        case vaccinatedBy = "Covid IN Vaccinated By"
        case vaccinatedAt = "Covid IN Vaccinated At"
        case vaccinationDosage = "Covid IN Vaccination Dosage"
        case QRCodeImage = "QRCode"
    }
}

struct CovidCertificateSearchRecordModel: Codable {
    var totalCount: Int?
    var records: [CustomWalletRecordCertModel]?
}

struct CovidCertificate_CustomWalletRecordCertModel: Codable {
    var type: String?
    var id: String?
    var value: CustomWalletRecordCertModel?
}
