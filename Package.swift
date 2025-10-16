// swift-tools-version:5.9
import PackageDescription
import Foundation
let package = Package(
    name: "ama-ios-sdk",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ama-ios-sdk",
            targets: ["ama-ios-sdk"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SVProgressHUD/SVProgressHUD.git", .upToNextMajor(from: "2.3.1")),
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/web3swift-team/web3swift.git", .upToNextMajor(from: "3.0.0")),
        //.package(url: "https://github.com/keefertaylor/Base58Swift.git", from: "2.1.0"),
        //.package(url: "https://github.com/airsidemobile/JOSESwift.git", from: "3.0.0"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0"),
        //.package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.0.0")),
        .package(url: "https://github.com/L3-iGrant/covid19-global-sdk-iOS", .upToNextMajor(from: "2024.9.1")),
        .package(url: "https://github.com/guoyingtao/Mantis", from: "2.26.0"),
        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages", from: "10.0.1"),
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.2.4"),
        .package(url: "https://github.com/marmelroy/Localize-Swift.git", .upToNextMajor(from: "3.2.0")),
        .package(url: "https://github.com/alexiscn/WXNavigationBar.git", .upToNextMajor(from: "2.3.6")),
        .package(url: "https://github.com/hackiftekhar/IQKeyboardManager.git", from: "8.0.1"),
        .package(url: "https://github.com/yonat/RadioGroup", from: "1.4.9"),
        .package(url: "https://github.com/Marxon13/M13Checkbox.git", from: "3.4.0"),
        .package(url: "https://github.com/decentralised-dataexchange/LibIndy", from: "2025.8.3"),
        .package(url: "https://github.com/decentralised-dataexchange/AEOTPTextField", from: "2025.9.1"),
        .package(url: "https://github.com/farshadjahanmanesh/loady.git", .upToNextMajor(from: "1.0.8")),
        .package(url: "https://github.com/decentralised-dataexchange/libzmq", from: "2025.8.2"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
        .package(url: "https://github.com/decentralised-dataexchange/eudi-wallet-oid4vc-ios", .upToNextMajor(from: "2025.9.3")),
        .package(url: "https://github.com/apple/swift-certificates.git", .upToNextMajor(from: "1.12.0"))
    ],
    targets: [
        .target(
            name: "IndyCWrapper",
            dependencies: [
                "LibIndy"
            ],
            path: "Sources/IndyCWrapper",
            publicHeadersPath: "Indy"
        ),
        .binaryTarget(
            name: "OpenSSL-XM",
            path: "Sources/ama-ios-sdk/Classes/SupportLibraries/OpenSSL-XM.xcframework"
        ),
        .target(
            name: "ama-ios-sdk",
            dependencies: [
                "OpenSSL-XM",
                "SVProgressHUD",
                "Moya",
                "web3swift",
                "Kingfisher",
                "covid19-global-sdk-iOS",
                "Mantis",
                "SwiftMessages",
                "WXNavigationBar",
                "RadioGroup",
                "M13Checkbox",
                "LibIndy",
                "AEOTPTextField",
                .product(name: "eudiWalletOidcIos", package: "eudi-wallet-oid4vc-ios"),
                "IndyCWrapper",
                .product(name: "libzmq", package: "libzmq"),
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "Localize_Swift", package: "Localize-Swift"),
                .product(name: "Loady", package: "loady"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "X509", package: "swift-certificates")
            ]
        )
    ]
)
