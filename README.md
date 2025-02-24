# modularwallets-ios-sdk

This is **CircleModularWalletsSDK** repo in iOS.

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding CircleModularWalletsCore as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/circlefin/modularwallets-ios-sdk.git", .upToNextMajor(from: "1.0.0"))
]
```

Normally you'll want to depend on the `CircleModularWalletsCore` target:

```swift
.product(name: "CircleModularWalletsCore", package: "CircleModularWalletsCore")
```

## Example

### Users can create smart accounts and send UserOps with passkeys with sample code

> ```swift
> import CircleModularWalletsCore
> 
> let CLIENT_KEY = "xxxxxxx:xxxxx"
> 
> Task {
>   do {
>     // 1. SDK calls RP to create/login a user
> 
>     // Create a PasskeyTransport with client key
>     let transport = toPasskeyTransport(clientKey: CLIENT_KEY)
> 
>     let credential = try await toWebAuthnCredential(
>       transport: transport,
>       userName: "MyExampleName", // userName
>       mode: WebAuthnMode.register // or WebAuthnMode.login
>     )
>       
>     // 2. Create a WebAuthn owner account from the credential.
>     let webAuthnAccount = toWebAuthnAccount(
>       credential
>     )
> 
>     // 3. Create modularTrasport with chain and client key then create a bundlerClient
>     let modularTrasport = toModularTransport( 
>       clientKey: CLIENT_KEY,
>       url: clientUrl
>     )
> 
>     let bundlerClient = BundlerClient( 
>       chain: Sepolia,
>       transport: modularTrasport
>     )
>  
>     // 4. Create SmartAccout(CircleSmartAccount) and set the WebAuthn account as the owner
>     let smartAccount = try await toCircleSmartAccount(
>       client: bundlerClient,
>       owner: webAuthnAccount
>     )
> 
>     // 5. Send an User Operation to the Bundler. For the example below, we will send 1 ETH to a random address.
>     let hash = bundlerClient.sendUserOperation(
>       account: account,
>       calls: [
>         EncodeCallDataArg(
>           to: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
>           value: UnitUtils.parseEtherToWei("1")
>         )
>       ]
>     )
>   } catch {
>     print(error)
>   }
> }
> ```
