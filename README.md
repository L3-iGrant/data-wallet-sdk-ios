# AMA iOS SDK

The `ama_ios_sdk` is an iOS SDK that provides functionality related to a data wallet. It allows developers to interact with a data wallet, configure it, and perform various operations such as displaying notifications, accessing wallet home, sharing data history, managing connections, scanning wallet content, and more. This SDK simplifies the integration of data wallet features into iOS applications.

## Installation

To install the `ama_ios_sdk` in your iOS project, follow these steps:

1. Open your project in Xcode.
2. Navigate to your project's root directory.
3. Open the `Podfile` and add the following line:

   ```ruby
   pod 'ama-ios-sdk'
   ```
4. Add below sources to podfile
   
   ```ruby
   source 'https://github.com/CocoaPods/Specs.git'
   source 'https://github.com/hyperledger/indy-sdk.git'
   source 'https://github.com/L3-iGrant/covid19-global-sdk-iOS-specs.git'
   source 'https://github.com/portto/secp256k1.swift'
   ```
5. Run the following command in Terminal:

   ```bash
   pod install
   ```

6. Once the installation is complete, you can import the SDK into your code using the following import statement:

   ```swift
   import ama_ios_sdk
   ```

## Functions

### `configureWallet`

Configures the data wallet.

```swift
let delegate = // Set your delegate conforming to AriesMobileAgentDelegate
AriesMobileAgent.shared.configureWallet(delegate: delegate) { success in
    if let success = success, success {
        // Wallet configuration successful
    } else {
        // Wallet configuration failed
    }
}
```

This function initializes and configures the data wallet. It takes a completion block as a parameter, which is called when the wallet configuration is completed. The `success` parameter indicates whether the wallet configuration was successful.

### `showDataWalletNotificationViewController`

Displays the data wallet notifications view controller.

```swift
AriesMobileAgent.shared.showDataWalletNotificationViewController()
```

This function presents the notifications view controller of the data wallet. This view controller provides a user interface for managing wallet notifications, such as receiving and viewing notifications related to data sharing or wallet updates.

### `showDataWalletHomeViewController`

Displays the data wallet home view controller.

```swift
AriesMobileAgent.shared.showDataWalletHomeViewController(showBackButton: true)
```

This function presents the home view controller of the data wallet. The wallet home provides a user interface for managing wallet contents, accessing shared data, and performing wallet-related operations.

### `showDataWalletShareDataHistoryViewController`

Displays the data wallet share data history view controller.

```swift
AriesMobileAgent.shared.showDataWalletShareDataHistoryViewController()
```

This function presents the share data history view controller of the data wallet. The share data history view displays a log of all the shared data, allowing the user to view the details of each shared item and manage data sharing permissions.

### `showDataWalletConnectionsViewController`

Displays the data wallet connections view controller.

```swift
AriesMobileAgent.shared.showDataWalletConnectionsViewController()
```

This function presents the connections view controller of the data wallet. The connections view displays the list of established connections, allowing the user to manage their connections, view connection details, and perform connection-related actions.

### `showDataWalletScannerViewController`

Displays the data wallet scanner view controller.

```swift
AriesMobileAgent.shared.showDataWalletScannerViewController()
```

This function presents the scanner view controller of the data wallet. The scanner view allows the user to scan and interact with QR codes containing wallet-related information or perform wallet-specific actions.

### `showDataAgreementScreen`

Displays the data agreement screen based on the provided data agreement ID, API key, and organization ID.

```swift
AriesMobileAgent.shared.showDataAgreementScreen(dataAgreementID: "agreement_id", apiKey: "api_key", orgId: "organization_id")
```

This function presents the data agreement screen of the data wallet. It allows the user to view and accept data sharing agreements by providing the data agreement ID, API key, and organization ID.

### `queryCredentials`

Query credentials based on the credential definition ID and schema ID.

```swift
async {
    if let credentials = await AriesMobileAgent.shared.queryCredentials(credDefId: "cred_def_id", schemaId: "schema_id") {
        // Process the queried credentials
    }
}
```

This function asynchronously queries the credentials stored in the data wallet based on the provided credential definition ID and schema ID. The queried credentials are returned as an optional array for further processing.

### `changeSDKLanguage`

Change the SDK language to the specified language code.

```swift
AriesMobileAgent.shared.changeSDKLanguage(languageCode: "en") // Change the SDK language to English
```

This function allows you to change the language used by the SDK. Provide the language code (e.g., "en" for English) to switch the SDK's localization to the desired language.

### Delegate

The SDK provides a delegate, `AriesMobileAgentDelegate`, to receive notifications and events from the SDK. Implement the delegate methods in your class to handle these events.

```swift
class MyViewController: UIViewController, AriesMobileAgentDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        AriesMobileAgent.shared.delegate = self
    }
    
    // Delegate method to receive notifications
    func notificationReceived(message: String) {
        // Handle the received notification
    }
}
```

By implementing the `AriesMobileAgentDelegate` protocol in your class and assigning it as the delegate of `AriesMobileAgent.shared`, you can receive notifications and events triggered by the SDK, such as notifications received from the data wallet.

### Delete Wallet

Deletes the wallet.

```swift
 AriesMobileAgent.shared.deleteWallet(completion: { success in
     if success ?? false {
         debugPrint("Wallet deleted successfully")
     }
 })
```

## Additional Notes

- Make sure to import the `ama_ios_sdk` module at the beginning of the file where you want to use the SDK functions.
- The SDK provides an instance of the `AriesMobileAgent` class named `shared`, which is used to access the various functions.
- The SDK functions should be called after the wallet is configured using the `configureWallet` function.
- The SDK requires appropriate permissions and access to user data to function correctly. Make sure to handle permissions and user data securely and according to relevant privacy guidelines.

That's it! You have now learned about the functions provided by the AMA iOS SDK. Here are some additional notes and best practices to keep in mind when using the SDK:

- Ensure that you have obtained the necessary permissions from the user before accessing and manipulating their wallet data. Respect user privacy and follow relevant data protection regulations.
- It's a good practice to handle errors and edge cases when using the SDK functions. Check for success/failure callbacks and handle any potential errors gracefully.
- The SDK functions are asynchronous, meaning they might not execute immediately. Make sure to consider this when designing your application's flow and user interface.
- Familiarize yourself with the SDK's documentation and guidelines provided by the SDK's developers. It will help you understand the available options, customization, and best practices.
- Stay up to date with the SDK updates and releases. Check for any new versions, bug fixes, or feature enhancements that might be relevant to your application.
- Consider implementing appropriate security measures when integrating the SDK. Protect sensitive user data and ensure secure communication between your app and the wallet.
- Test the integration thoroughly in various scenarios and edge cases to ensure the functionality works as expected and provides a smooth user experience.
- Provide appropriate error handling and user feedback when encountering issues with the SDK functions. Clear error messages and instructions can assist users in troubleshooting problems.
- Consider adding analytics or monitoring capabilities to track the usage and performance of the SDK

 in your application. This can help identify any issues and optimize the integration.

## Troubleshoot

- Multiple commands produce Assets.car: Add `install! "'cocoapods', :disable_input_output_paths => true"` on top of your Podfile.

  ```ruby
  # Podfile
  platform :ios, '10.3'
  install! 'cocoapods', :disable_input_output_paths => true
  ```

  Note that this SDK doesn't support the simulator, so it is recommended to exclude the `arm64` architecture in the build settings of your project.

By leveraging the capabilities of the AMA iOS SDK, you can empower your iOS application with data wallet functionalities, such as configuring the wallet, managing notifications, accessing wallet home, viewing and managing data sharing history, managing connections, and scanning wallet content.
