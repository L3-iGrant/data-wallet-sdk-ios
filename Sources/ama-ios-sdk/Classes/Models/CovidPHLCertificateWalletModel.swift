//
//  CovidPHLCertificateWalletModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 07/01/22.
//

import Foundation
import covid19_global_sdk_iOS


struct CovidPHLCertificateWalletModel: Codable {
    let type: IDCardAttributes?
    let fullName: IDCardAttributes?
    let dob: IDCardAttributes?
    let gender: IDCardAttributes?
    let beneficiaryRefId: IDCardAttributes?
    let certificateId: IDCardAttributes?
    let vaccineName: IDCardAttributes?
    let vaccinationManufacturer: IDCardAttributes?
    let batchNumber: IDCardAttributes?
    let dateOfDose: IDCardAttributes?
    let vaccinatedAt: IDCardAttributes?
    let vaccinationDosage: IDCardAttributes?
    let QRCodeImage: IDCardAttributes?
    
    static func initFromCovidCertModel(model: CovidIndiaCertificateModel, QRCode: String?) -> CovidPHLCertificateWalletModel{
        let beneficiaryName = model.credentialSubject?.name
        let ageValue = model.credentialSubject?.age ?? model.credentialSubject?.dob ?? ""
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
        let certificateIdValue = vaccine?.certificateID ?? ""
        let manufacturerValue = vaccine?.manufacturer ?? ""
        let batchNumberValue = vaccine?.batch ?? ""
        
        let type = IDCardAttributes.init(name: "type", value: typeValue)
        let fullName = IDCardAttributes.init(name: "Covid PH Beneficiary Name", value:beneficiaryName)
        let dob = IDCardAttributes.init(name: "Covid PH Date of Birth", value:ageValue)
        let gender = IDCardAttributes.init(name: "Covid PH Gender", value:genderValue)
        let beneficiaryRefId = IDCardAttributes.init(name: "Covid PH Beneficiary Reference ID", value:beneficiaryReferenceIDValue)
        let certificateId = IDCardAttributes.init(name: "Covid PH Vaccination Certificate ID", value:certificateIdValue)
        let batchNumber = IDCardAttributes.init(name: "Covid PH Vaccine Batch Number", value:batchNumberValue)
        let vaccineName = IDCardAttributes.init(name: "Covid PH Vaccine Name", value:vaccinationNameValue)
        let vaccinationManufacturer = IDCardAttributes.init(name: "Covid PH Vaccine Manufacturer", value:manufacturerValue)
        let dateOfDose = IDCardAttributes.init(name: "Covid PH Date of Dose", value: dateOfDoseValue)
        let vaccinatedAt = IDCardAttributes.init(name: "Covid PH Vaccinated At", value:vaccinationAtValue)
        let vaccinationDosage = IDCardAttributes.init(name: "Covid PH Vaccination Dosage", value: vaccinatedDosageValue)
        let QRCodeImage = IDCardAttributes.init(type: .image, name: "QRCode", value: QRCode)
        return CovidPHLCertificateWalletModel.init(type: type, fullName: fullName, dob: dob, gender: gender, beneficiaryRefId: beneficiaryRefId, certificateId: certificateId, vaccineName: vaccineName, vaccinationManufacturer: vaccinationManufacturer, batchNumber: batchNumber, dateOfDose: dateOfDose, vaccinatedAt: vaccinatedAt, vaccinationDosage: vaccinationDosage, QRCodeImage: QRCodeImage)
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case fullName = "Covid PH Beneficiary Name"
        case dob = "Covid PH Date of Birth"
        case gender = "Covid PH Gender"
        case beneficiaryRefId = "Covid PH Beneficiary Reference ID"
        case certificateId = "Covid PH Vaccination Certificate ID"
        case vaccineName = "Covid PH Vaccine Name"
        case vaccinationManufacturer = "Covid PH Vaccine Manufacturer"
        case batchNumber = "Covid PH Vaccine Batch Number"
        case dateOfDose = "Covid PH Date of Dose"
        case vaccinatedAt = "Covid PH Vaccinated At"
        case vaccinationDosage = "Covid PH Vaccination Dosage"
        case QRCodeImage = "QRCode"
    }
}

