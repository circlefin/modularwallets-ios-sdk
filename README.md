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
>     // 3. Create modularTransport with chain and client key then create a bundlerClient
>     let modularTransport = toModularTransport(
>       clientKey: CLIENT_KEY,
>       url: clientUrl
>     )
> 
>     let bundlerClient = BundlerClient( 
>       chain: Sepolia,
>       transport: modularTransport
>     )
>  
>     // 4. Create SmartAccount(CircleSmartAccount) and set the WebAuthn account as the owner
>     let smartAccount = try await toCircleSmartAccount(
>       client: bundlerClient,
>       owner: webAuthnAccount
>     )
> 
>     // 5. Send a User Operation to the Bundler. This returns a User Operation hash,
>     // not the on-chain transaction hash.
>     let userOpHash = try await bundlerClient.sendUserOperation(
>       account: smartAccount,
>       calls: [
>         EncodeCallDataArg(
>           to: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
>           value: UnitUtils.parseEtherToWei("1")
>         )
>       ],
>       paymaster: Paymaster.True()
>     )
>
>     // 6. Wait for the User Operation receipt when you need the on-chain transaction hash.
>     let userOperationReceipt = try await bundlerClient.waitForUserOperationReceipt(
>       userOpHash: userOpHash
>     )
>     let transactionHash = userOperationReceipt.receipt.transactionHash
>   } catch {
>     print(error)
>   }
> }
> ```

### Sponsored / gasless User Operations

`paymaster` defaults to `nil` on `sendUserOperation`, `estimateUserOperationGas`, and
`prepareUserOperation`. This is intentional: the SDK keeps gas sponsorship as an
explicit app-level policy instead of choosing a default paymaster for every caller.

For Circle Modular Wallet flows that should be sponsored or gasless, pass a
paymaster explicitly:

```swift
let userOpHash = try await bundlerClient.sendUserOperation(
  account: smartAccount,
  calls: calls,
  paymaster: Paymaster.True()
)
```

If all User Operations in your app should use the same sponsorship policy, wrap
the SDK calls in your app layer so new flows cannot forget the paymaster:

```swift
struct SponsoredUserOperationClient {
  let bundlerClient: BundlerClient
  let paymaster: Paymaster

  func prepareUserOperation(
    account: SmartAccount,
    calls: [EncodeCallDataArg]?,
    partialUserOp: UserOperationV07 = .init(),
    estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
  ) async throws -> UserOperationV07 {
    try await bundlerClient.prepareUserOperation(
      account: account,
      calls: calls,
      partialUserOp: partialUserOp,
      paymaster: paymaster,
      estimateFeesPerGas: estimateFeesPerGas
    )
  }

  func estimateUserOperationGas(
    account: SmartAccount,
    calls: [EncodeCallDataArg],
    estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
  ) async throws -> EstimateUserOperationGasResult {
    try await bundlerClient.estimateUserOperationGas(
      account: account,
      calls: calls,
      paymaster: paymaster,
      estimateFeesPerGas: estimateFeesPerGas
    )
  }

  func sendUserOperation(
    account: SmartAccount,
    calls: [EncodeCallDataArg]?,
    partialUserOp: UserOperationV07 = .init(),
    estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
  ) async throws -> String {
    try await bundlerClient.sendUserOperation(
      account: account,
      calls: calls,
      partialUserOp: partialUserOp,
      paymaster: paymaster,
      estimateFeesPerGas: estimateFeesPerGas
    )
  }
}

let sponsoredClient = SponsoredUserOperationClient(
  bundlerClient: bundlerClient,
  paymaster: Paymaster.True()
)
```

Use `Paymaster.Client(client:paymasterContext:)` instead of `Paymaster.True()`
when sponsorship is served by a separate paymaster transport.
