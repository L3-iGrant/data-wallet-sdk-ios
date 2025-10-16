//
//  AriesPackMessageTemplates.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 18/02/22.
//

import Foundation

struct AriesPackMessageTemplates {
    
    static func requestCredential(didCom: String, credReq: String, threadId: String) -> [String: Any] {
        return [
            "@type": "\(didCom);spec/issue-credential/1.0/request-credential",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "~thread": [
                "thid": threadId
            ],
            "requests~attach": [
                [
                    "@id": "libindy-cred-request-0",
                    "mime-type": "application/json",
                    "data": [
                        "base64": credReq.encodeBase64()
                    ]
                ]
            ]
        ]
    }
    
    static func requestCredentialWithDataAgreement(didCom: String, credReq: String, threadId: String, dataAgreementContext: [String: Any]) -> [String: Any] {
        return [
            "@type": "\(didCom);spec/issue-credential/1.0/request-credential",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "~thread": [
                "thid": threadId
            ],
            "requests~attach": [
                [
                    "@id": "libindy-cred-request-0",
                    "mime-type": "application/json",
                    "data": [
                        "base64": credReq.encodeBase64()
                    ]
                ]
            ],
            "~data-agreement-context": dataAgreementContext
        ]
    }
    
    static func getDataAgreementFromQRID(QR_ID: String,fromDid: String, toDid: String,isThirdPartyShareSupported: Bool) -> [String: Any]{
        if !isThirdPartyShareSupported {
            return [
                    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreement-qr-code/1.0/initiate",
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                    "to": RegistryHelper.shared.convertDidSovToDidMyData(didSov: toDid),
                    "created_time": Date().epochTime,
                    "from": RegistryHelper.shared.convertDidSovToDidMyData(didSov: fromDid),
                    "body": [
                        "qr_id": QR_ID
                    ],
                    "~transport": [
                        "return_route": "all"
                    ]
                ]
        }
        return [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreement-qr-code/1.0/initiate",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "body": [
                    "qr_id": QR_ID
                ],
                "~transport": [
                    "return_route": "all"
                ]
            ]
    }
    
    static func presentationDataExchange(presentation: PRPresentation?, didCom: String, threadId: String) -> [String:Any]{
        let modelDict = presentation.dictionary ?? [String:Any]()
        let base64 = modelDict.toString()?.encodeBase64()
        return [
            "@type": "\(didCom);spec/present-proof/1.0/presentation",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "~thread": [
                "thid": threadId
            ],
            "presentations~attach": [
                [
                    "@id": "libindy-presentation-0",
                    "mime-type" : "application/json",
                    "data" : ["base64" : base64]
                ]
            ],
            "comment": "auto-presented for proof request nonce=1234567890"
        ]
    }
    
    static func  presentationDataExchangeWithDataAgreement(presentation: PRPresentation?, didCom: String, threadId: String, dataAgreementContext: [String: Any]) -> [String: Any] {
        let modelDict = presentation.dictionary ?? [String:Any]()
        let base64 = modelDict.toString()?.encodeBase64()
        return [
            "@type": "\(didCom);spec/present-proof/1.0/presentation",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "~thread": [
                "thid": threadId
            ],
            "presentations~attach": [
                [
                    "@id": "libindy-presentation-0",
                    "mime-type" : "application/json",
                    "data" : ["base64" : base64]
                ]
            ],
            "~data-agreement-context": dataAgreementContext,
            "comment": "auto-presented for proof request nonce=1234567890"
        ]
    }
    
    static func queryDataControllerProtocol() -> [String: Any]{
        return [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/discover-features/1.0/query",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "query": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-controller/*",
            "comment": "Querying features available.",
            "~transport": [
                "return_route": "all"
            ]
        ]
    }
    
    static func queryThirdPartySharingProtocol() -> [String: Any]{
        return [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/discover-features/1.0/query",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "query": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/third-party-data-sharing/*",
            "comment": "Querying features available.",
            "~transport": [
                "return_route": "all"
            ]
        ]
    }
    
    static func getDataControllerOrgDetail(from_myDataDid: String, to_myDataDid: String, isThirdPartyShareSupported: Bool) -> [String: Any] {
        if !isThirdPartyShareSupported {
            return [
                    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-controller/1.0/details",
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                    "from": from_myDataDid,
                    "created_time": Date().epochTime,
                    "to": to_myDataDid,
                    "~transport": [
                        "return_route": "all"
                    ]
                ]
        }
        return [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-controller/1.0/details",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "~transport": [
                    "return_route": "all"
                ]
            ]
    }
    
    static func informDuplicateConnection_new(myVerKey: String,recipientKey: String, theirDid: String,isThirdPartyShareSupported: Bool) -> [String: Any]{
        if !isThirdPartyShareSupported {
            return [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/exists", // before -- igrantio-operator/1.0/org-multiple-connections",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "from": RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey),
                "to": RegistryHelper.shared.convertDidSovToDidMyData(didSov: recipientKey),
                "created_time": "\(Int(Date().timeIntervalSince1970))",
                "body" : [
                    "theirdid": theirDid ?? "",
                    ]
                ]
        }
        return [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/exists", // before -- igrantio-operator/1.0/org-multiple-connections",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "body" : [
                "theirdid": theirDid ?? "",
                ]
            ]
        
    }
    
    static func readAllTemplate(myDid: String,theirDid: String, isThirdPartyShareSupported: Bool)  -> [String: Any]{ //grantio-operator/1.0/list-data-certificate-types
        if !isThirdPartyShareSupported {
            return [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreements/1.0/read-all-template",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "from": RegistryHelper.shared.convertDidSovToDidMyData(didSov: myDid),
                "created_time": "\(Int(Date().timeIntervalSince1970))",
                "to":  RegistryHelper.shared.convertDidSovToDidMyData(didSov: theirDid),
               "~transport": [
                    "return_route": "all"
                ]
            ]
        }
        return [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreements/1.0/read-all-template",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
           "~transport": [
                "return_route": "all"
            ]
        ]
        
        
    }
    
}
