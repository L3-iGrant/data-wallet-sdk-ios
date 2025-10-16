//
//  CertificateIssueModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 27/11/20.
//

import Foundation

struct CertificateIssueModel: Codable {
    let type, id: String?
    let thread: IssueCertificateThread?
    let credentialPreview: IssueCertificateCredentialPreview?
    let offersAttach: [IssueCertificateOffersAttach]?
    let comment: String?
    let dataAgreement: DataAgreementContext?
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
        case credentialPreview = "credential_preview"
        case offersAttach = "offers~attach"
        case comment
        case dataAgreement = "~data-agreement-context"
    }
}

// MARK: - CredentialPreview
struct IssueCertificateCredentialPreview: Codable {
    let type: String?
    let attributes: [IssueCertificateAttribute]?
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case attributes
    }
}

// MARK: - Attribute
class IssueCertificateAttribute: Codable {
    let name, value: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        name = try? container.decodeIfPresent(String.self, forKey: .name)
//        value = CodableUtils.decodeAsString(container: container, codingKey: .value)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//            try container.encodeIfPresent(self.name, forKey: .name)
//            try container.encodeIfPresent(self.value, forKey: .value)
//    }
}

// MARK: - OffersAttach
struct IssueCertificateOffersAttach: Codable {
    let id, mimeType: String?
    let data: IssueCertificateDataClass?
    
    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case mimeType = "mime-type"
        case data
    }
}

// MARK: - DataClass
struct IssueCertificateDataClass: Codable {
    let base64: String?
}

// MARK: - Thread
struct IssueCertificateThread: Codable {
    let thid: String?
}

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dataAgreementContext = try? newJSONDecoder().decode(DataAgreementContext.self, from: jsonData)

enum DataAgreementValidations: String,Codable {
    case not_validate
    case valid
    case invalid
}

// MARK: - DataAgreementContext
class DataAgreementContext: NSObject, Codable, NSCopying {
    
    var message: DataAgreementMessage?
    let messageType: String?
    var validated: DataAgreementValidations?
    var receipt: ReceiptModel?
    
    enum CodingKeys: String, CodingKey {
        case message
        case messageType = "message_type"
        case validated
        case receipt
    }
    
    init(message: DataAgreementMessage?, messageType: String?, validated: DataAgreementValidations? = nil,receipt: ReceiptModel? = nil){
        self.message = message
        self.messageType = messageType
        self.validated = validated
        self.receipt = receipt
    }
    
    override func copy() -> Any {
        guard let asCopying = ((self as AnyObject) as? NSCopying) else {
            fatalError("This class doesn't implement NSCopying")
        }
        return asCopying.copy(with: nil)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return DataAgreementContext.init(message: self.message, messageType: self.messageType, validated: self.validated)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try? container.decodeIfPresent(DataAgreementMessage.self, forKey: .message)
        messageType = try? container.decodeIfPresent(String.self, forKey: .messageType)
        validated = try? container.decodeIfPresent(DataAgreementValidations.self, forKey: .validated)
        receipt = try? container.decodeIfPresent(ReceiptModel.self, forKey: .receipt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(self.message, forKey: .message)
            try container.encodeIfPresent(self.messageType, forKey: .messageType)
            try container.encodeIfPresent(self.validated, forKey: .validated)
            try container.encodeIfPresent(self.receipt, forKey: .receipt)
    }
}

// MARK: - Message
struct DataAgreementMessage: Codable {
    var body: Body?
    let id, from, to, createdTime: String?
    let type: String?
    
    
    enum CodingKeys: String, CodingKey {
        case body
        case id = "@id"
        case type = "@type"
        case from, to
        case createdTime = "created_time"
    }
}

// MARK: - Body
struct Body: Codable {
    var proof: Proof?
    var proofChain: [Proof]?
    let purpose: String?
    let dataControllerURL: String?
    let dataSubjectDid, id: String?
    var event: [Event]?
    let templateVersion: String?
    let dataControllerName: String?
    let personalData: [PersonalDatum]?
    let templateID, purposeDescription, lawfulBasis, methodOfUse: String?
    let dataPolicy: DataPolicy?
    let version: String?
    let context: [String]?
    let dpia: Dpia?
    let language: String?
    let type: [String]?
    var isNewKey: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case proof, purpose
        case dataControllerURL = "dataControllerUrl"
        case old_dataControllerURL = "data_controller_url"
        case dataSubjectDid
        case old_dataSubjectDid = "data_subject_did"
        case id = "@id"
        case old_id = "id"
        case templateVersion
        case old_templateVersion = "template_version"
        case dataControllerName
        case old_dataControllerName = "data_controller_name"
        case personalData
        case old_personalData = "personal_data"
        case templateID = "templateId"
        case old_templateID = "template_id"
        case purposeDescription
        case old_purposeDescription = "purpose_description"
        case lawfulBasis
        case old_lawfulBasis = "lawful_basis"
        case methodOfUse
        case old_methodOfUse = "method_of_use"
        case dataPolicy
        case old_dataPolicy = "data_policy"
        case version
        case context = "@context"
        case proofChain
        case dpia
        case type = "@type"
        case language
        case event
    }
    
    init(proof: Proof? = nil, proofChain: [Proof]? = nil, purpose: String?, dataControllerURL: String?, dataSubjectDid: String?, id: String?, event: [Event]? = nil, templateVersion: String?, dataControllerName: String?, personalData: [PersonalDatum]?, templateID: String?, purposeDescription: String?, lawfulBasis: String?, methodOfUse: String?, dataPolicy: DataPolicy?, version: String?, context: [String]?, dpia: Dpia?, language: String?, type: [String]?) {
        self.proof = proof
        self.proofChain = proofChain
        self.purpose = purpose
        self.dataControllerURL = dataControllerURL
        self.dataSubjectDid = dataSubjectDid
        self.id = id
        self.event = event
        self.templateVersion = templateVersion
        self.dataControllerName = dataControllerName
        self.personalData = personalData
        self.templateID = templateID
        self.purposeDescription = purposeDescription
        self.lawfulBasis = lawfulBasis
        self.methodOfUse = methodOfUse
        self.dataPolicy = dataPolicy
        self.version = version
        self.context = context
        self.dpia = dpia
        self.language = language
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        proof = try? container.decodeIfPresent(Proof.self, forKey: .proof)
        proofChain = try? container.decodeIfPresent([Proof].self, forKey: .proofChain)
        purpose = try? container.decodeIfPresent(String.self, forKey: .purpose)
        event = try? container.decodeIfPresent([Event].self, forKey: .event)
        dpia = try? container.decodeIfPresent(Dpia.self, forKey: .dpia)
        language = try? container.decodeIfPresent(String.self, forKey: .language)
        type = try? container.decodeIfPresent([String].self, forKey: .type)
        context = try? container.decodeIfPresent([String].self, forKey: .context)

        //different types
        templateVersion = try? (container.decodeIfPresent(String.self, forKey: .templateVersion) ?? container.decodeIfPresent(Int.self, forKey: .old_templateVersion)?.toString)
        version = try? (container.decodeIfPresent(String.self, forKey: .version) ?? container.decodeIfPresent(Int.self, forKey: .version)?.toString)

        if container.contains(.dataControllerURL) {
            self.isNewKey = true
        }
        //with old keys
        id = try? (container.decodeIfPresent(String.self, forKey: .id) ?? container.decodeIfPresent(String.self, forKey: .old_id))

        dataControllerURL = try? (container.decodeIfPresent(String.self, forKey: .dataControllerURL) ?? container.decodeIfPresent(String.self, forKey: .old_dataControllerURL))
        dataSubjectDid = try? (container.decodeIfPresent(String.self, forKey: .dataSubjectDid) ?? container.decodeIfPresent(String.self, forKey: .old_dataSubjectDid))
        dataControllerName = try? (container.decodeIfPresent(String.self, forKey: .dataControllerName) ?? container.decodeIfPresent(String.self, forKey: .old_dataControllerName))
        personalData = try? (container.decodeIfPresent([PersonalDatum].self, forKey: .personalData) ?? container.decodeIfPresent([PersonalDatum].self, forKey: .old_personalData))
        templateID = try? (container.decodeIfPresent(String.self, forKey: .templateID) ?? container.decodeIfPresent(String.self, forKey: .old_templateID))
        purposeDescription = try? (container.decodeIfPresent(String.self, forKey: .purposeDescription) ?? container.decodeIfPresent(String.self, forKey: .old_purposeDescription))
        lawfulBasis = try? (container.decodeIfPresent(String.self, forKey: .lawfulBasis) ?? container.decodeIfPresent(String.self, forKey: .old_lawfulBasis))
        methodOfUse = try? (container.decodeIfPresent(String.self, forKey: .methodOfUse) ?? container.decodeIfPresent(String.self, forKey: .old_methodOfUse))
        dataPolicy = try? (container.decodeIfPresent(DataPolicy.self, forKey: .dataPolicy) ?? container.decodeIfPresent(DataPolicy.self, forKey: .old_dataPolicy))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.proof, forKey: .proof)
        try container.encodeIfPresent(self.proofChain, forKey: .proofChain)
        try container.encodeIfPresent(self.purpose, forKey: .purpose)
        try container.encodeIfPresent(self.event, forKey: .event)
        try container.encodeIfPresent(self.dpia, forKey: .dpia)
        try container.encodeIfPresent(self.language, forKey: .language)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.context, forKey: .context)
        
        if isNewKey {
            try container.encodeIfPresent(self.version, forKey: .version)
            try container.encodeIfPresent(self.templateVersion, forKey: .templateVersion)
            try container.encodeIfPresent(self.dataControllerURL, forKey: .dataControllerURL)
            try container.encodeIfPresent(self.dataSubjectDid, forKey: .dataSubjectDid)
            try container.encodeIfPresent(self.dataControllerName, forKey: .dataControllerName)
            try container.encodeIfPresent(self.personalData, forKey: .personalData)
            try container.encodeIfPresent(self.templateID, forKey: .templateID)
            try container.encodeIfPresent(self.purposeDescription, forKey: .purposeDescription)
            try container.encodeIfPresent(self.lawfulBasis, forKey: .lawfulBasis)
            try container.encodeIfPresent(self.methodOfUse, forKey: .methodOfUse)
            try container.encodeIfPresent(self.dataPolicy, forKey: .dataPolicy)
            try container.encodeIfPresent(self.id, forKey: .id)
        } else {
            if let intValue = Int(self.templateVersion ?? "") {
                try container.encodeIfPresent(intValue, forKey: .old_templateVersion)
            }
            if let intValue = Int(self.version ?? "") {
                try container.encodeIfPresent(intValue, forKey: .version)
            }
            try container.encodeIfPresent(self.dataControllerURL, forKey: .old_dataControllerURL)
            
            try container.encodeIfPresent(self.dataSubjectDid, forKey: .old_dataSubjectDid)
            try container.encodeIfPresent(self.id, forKey: .old_id)
            
            try container.encodeIfPresent(self.dataControllerName, forKey: .old_dataControllerName)
            
            try container.encodeIfPresent(self.personalData, forKey: .old_personalData)
            
            try container.encodeIfPresent(self.templateID, forKey: .old_templateID)
            
            try container.encodeIfPresent(self.purposeDescription, forKey: .old_purposeDescription)
            
            try container.encodeIfPresent(self.lawfulBasis, forKey: .old_lawfulBasis)
            
            try container.encodeIfPresent(self.methodOfUse, forKey: .old_methodOfUse)
            
            try container.encodeIfPresent(self.dataPolicy, forKey: .old_dataPolicy)
        }
        
        
    }
}

// MARK: - DataPolicy
struct DataPolicy: Codable {
    
    let industrySector, jurisdiction: String?
    let policyURL: String?
    let storageLocation: String?
    let dataRetentionPeriod: Int?
    let geographicRestriction: String?
    let thirdPartyDataSharing: Bool?
    var isNewKey: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case policyURL = "policyUrl"
        case jurisdiction, industrySector, dataRetentionPeriod, geographicRestriction, storageLocation, thirdPartyDataSharing
        case old_industrySector = "industry_sector"
        case old_policyURL = "policy_URL"
        case old_geographicRestriction = "geographic_restriction"
        case old_storageLocation = "storage_location"
        case old_dataRetentionPeriod = "data_retention_period"
    }
    
    init(industrySector: String? = nil, jurisdiction: String? = nil, policyURL: String? = nil, storageLocation: String? = nil, dataRetentionPeriod: Int? = nil, geographicRestriction: String? = nil, thirdPartyDataSharing: Bool? = nil) {
        self.industrySector = industrySector
        self.jurisdiction = jurisdiction
        self.policyURL = policyURL
        self.storageLocation = storageLocation
        self.dataRetentionPeriod = dataRetentionPeriod
        self.geographicRestriction = geographicRestriction
        self.thirdPartyDataSharing = thirdPartyDataSharing
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.industrySector) {
            self.isNewKey = true
        }
        jurisdiction = try? container.decode(String.self, forKey: .jurisdiction)
        industrySector = try? (container.decodeIfPresent(String.self, forKey: .industrySector) ?? container.decodeIfPresent(String.self, forKey: .old_industrySector))
        dataRetentionPeriod = try? (container.decodeIfPresent(Int.self, forKey: .dataRetentionPeriod) ?? container.decodeIfPresent(Int.self, forKey: .old_dataRetentionPeriod))
        policyURL = try? (container.decodeIfPresent(String.self, forKey: .policyURL) ?? container.decodeIfPresent(String.self, forKey: .old_policyURL))
        geographicRestriction = try? (container.decodeIfPresent(String.self, forKey: .geographicRestriction) ?? container.decodeIfPresent(String.self, forKey: .old_geographicRestriction))
        thirdPartyDataSharing = try? container.decodeIfPresent(Bool.self, forKey: .thirdPartyDataSharing)
        storageLocation = try? (container.decodeIfPresent(String.self, forKey: .storageLocation) ?? container.decodeIfPresent(String.self, forKey: .old_storageLocation))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.jurisdiction, forKey: .jurisdiction)
        try container.encodeIfPresent(self.thirdPartyDataSharing, forKey: .thirdPartyDataSharing)
        if isNewKey {
            try container.encodeIfPresent(self.industrySector, forKey: .industrySector)
            try container.encodeIfPresent(self.dataRetentionPeriod, forKey: .dataRetentionPeriod)
            try container.encodeIfPresent(self.policyURL, forKey: .policyURL)
            try container.encodeIfPresent(self.geographicRestriction, forKey: .geographicRestriction)
            try container.encodeIfPresent(self.storageLocation, forKey: .storageLocation)
        } else {
            try container.encodeIfPresent(self.industrySector, forKey: .old_industrySector)
            
            try container.encodeIfPresent(self.dataRetentionPeriod, forKey: .old_dataRetentionPeriod)
            
            try container.encodeIfPresent(self.policyURL, forKey: .old_policyURL)
            
            try container.encodeIfPresent(self.geographicRestriction, forKey: .old_geographicRestriction)
            
            
            try container.encodeIfPresent(self.storageLocation, forKey: .old_storageLocation)
        }
    }
}

// MARK: - Event
struct Event: Codable {
    let state, did, id, timeStamp: String?
    
    enum CodingKeys: String, CodingKey {
        case state, did, id
        case timeStamp = "time_stamp"
    }
}

// MARK: - PersonalDatum
struct PersonalDatum: Codable {
    
    let attributeID, attributeName: String?
    let attributeSensitive: Bool?
    let attributeDescription, attributeCategory: String?
    let restrictions: [[String:String]]?
    var isNewKey: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case attributeID = "attributeId"
        case attributeName, attributeSensitive, attributeDescription
        case restrictions, attributeCategory
        case old_attributeSensitive = "attribute_sensitive"
        case old_attributeCategory = "attribute_category"
        case old_attributeID = "attribute_id"
        case old_attributeName = "attribute_name"
        case old_attributeDescription = "attribute_description"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.attributeID) {
            self.isNewKey = true
        }
        attributeID = try? (container.decodeIfPresent(String.self, forKey: .attributeID) ?? container.decodeIfPresent(String.self, forKey: .old_attributeID))
        attributeName = try? (container.decodeIfPresent(String.self, forKey: .attributeName) ?? container.decodeIfPresent(String.self, forKey: .old_attributeName))
        attributeSensitive = try? (container.decodeIfPresent(Bool.self, forKey: .attributeSensitive) ?? container.decodeIfPresent(Bool.self, forKey: .old_attributeSensitive))
        attributeDescription = try? (container.decodeIfPresent(String.self, forKey: .attributeDescription) ?? container.decodeIfPresent(String.self, forKey: .old_attributeDescription))
        restrictions = try? container.decodeIfPresent([[String:String]].self, forKey: .restrictions)
        attributeCategory = try? (container.decodeIfPresent(String.self, forKey: .attributeCategory) ?? container.decodeIfPresent(String.self, forKey: .old_attributeCategory))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !isNewKey {
            try container.encodeIfPresent(self.attributeID, forKey: .old_attributeID)
            
            try container.encodeIfPresent(self.attributeName, forKey: .old_attributeName)
            
            try container.encodeIfPresent(self.attributeSensitive, forKey: .old_attributeSensitive)
            
            try container.encodeIfPresent(self.attributeDescription, forKey: .old_attributeDescription)
            try container.encodeIfPresent(self.restrictions, forKey: .restrictions)
            
            try container.encodeIfPresent(self.attributeCategory, forKey: .old_attributeCategory)
        } else {
            try container.encodeIfPresent(self.attributeID, forKey: .attributeID)
            try container.encodeIfPresent(self.attributeName, forKey: .attributeName)
            try container.encodeIfPresent(self.attributeSensitive, forKey: .attributeSensitive)
            try container.encodeIfPresent(self.attributeDescription, forKey: .attributeDescription)
            try container.encodeIfPresent(self.attributeCategory, forKey: .attributeCategory)
            try container.encodeIfPresent(self.restrictions, forKey: .restrictions)
        }
        
        
    }
}


// MARK: - Proof
struct Proof: Codable {
    let created, proofPurpose, id, verificationMethod: String?
    var proofValue, type: String?
    var jws: String?
    var context: String?
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case created
        case proofPurpose
        case id
        case verificationMethod
        case proofValue
        case type
        case jws
    }
    
    init(created: String?, proofPurpose: String?, id: String?, verificationMethod: String?, proofValue: String?, type: String?) {
        self.created = created
        self.proofPurpose = proofPurpose
        self.id = id
        self.verificationMethod = verificationMethod
        self.proofValue = proofValue
        self.type = type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decodeIfPresent(String.self, forKey: .context)
        created = try container.decodeIfPresent(String.self, forKey: .created)
        proofPurpose = try container.decodeIfPresent(String.self, forKey: .proofPurpose)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        verificationMethod = try container.decodeIfPresent(String.self, forKey: .verificationMethod)
        proofValue = try container.decodeIfPresent(String.self, forKey: .proofValue)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        jws = try container.decodeIfPresent(String.self, forKey: .jws)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.context, forKey: .context)
        try container.encodeIfPresent(self.created, forKey: .created)
        try container.encodeIfPresent(self.proofPurpose, forKey: .proofPurpose)
        try container.encodeIfPresent(self.id, forKey: .id)
        try container.encodeIfPresent(self.verificationMethod, forKey: .verificationMethod)
        try container.encodeIfPresent(self.proofValue, forKey: .proofValue)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.jws, forKey: .jws)
    }
}

struct Dpia: Codable {
    internal init(dpiaDate: String? = nil, dpiaSummaryURL: String? = nil) {
        self.dpiaDate = dpiaDate
        self.dpiaSummaryURL = dpiaSummaryURL
    }
    
    let dpiaDate: String?
    let dpiaSummaryURL: String?
    var isNewKey: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case dpiaDate
        case dpiaSummaryURL = "dpiaSummaryUrl"
        case old_dpiaDate = "dpia_date"
        case old_dpiaSummaryURL = "dpia_summary_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.dpiaDate) {
            self.isNewKey = true
        }
        dpiaDate = try? (container.decodeIfPresent(String.self, forKey: .dpiaDate) ?? container.decodeIfPresent(String.self, forKey: .old_dpiaDate))
        dpiaSummaryURL = try? (container.decodeIfPresent(String.self, forKey: .dpiaSummaryURL) ?? container.decodeIfPresent(String.self, forKey: .old_dpiaSummaryURL))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if isNewKey {
            try container.encodeIfPresent(self.dpiaDate, forKey: .dpiaDate)
            try container.encodeIfPresent(self.dpiaSummaryURL, forKey: .dpiaSummaryURL)
        } else {
            try container.encodeIfPresent(self.dpiaDate, forKey: .old_dpiaDate)
            try container.encodeIfPresent(self.dpiaSummaryURL, forKey: .old_dpiaSummaryURL)
        }
    }
}
