//
// Copyright (c) 2025, Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AuthenticationServices

class WebAuthnHandler: NSObject, @unchecked Sendable {

    static let shared = WebAuthnHandler()

    private var authenticationAnchor: ASPresentationAnchor?
    private var isPerformingModalReqest = false
    private var continuation: CheckedContinuation<PublicKeyCredential, Error>?
    private var webAuthnMode: WebAuthnMode = .register

    // In fact, this function returns the RegistrationCredential type
    func signUpWith(
        anchor: ASPresentationAnchor? = nil,
        option: PublicKeyCredentialCreationOptions
    ) async throws -> PublicKeyCredential {
        guard isPerformingModalReqest == false else {
            throw BaseError(shortMessage: "WebAuthn request is authorizing. Please wait until the current authentication is finished and try again.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.authenticationAnchor = anchor

            let rpId = option.relyingParty.id
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)

            // Fetch the challenge from the server. The challenge needs to be unique for each request.
            // The userID is the identifier for the user's account.
            let challenge = Data(option.challenge.decodedBytes ?? [])
            let userID = option.user.id
            let userName = option.user.name

            let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge, name: userName, userID: userID)
            registrationRequest.displayName = option.user.displayName

            let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )

            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
            isPerformingModalReqest = true

            self.continuation = continuation
            self.webAuthnMode = .register
        }
    }

    // In fact, this function returns the AuthenticationCredential type
    func signInWith(
        anchor: ASPresentationAnchor? = nil,
        option: PublicKeyCredentialRequestOptions
    ) async throws -> PublicKeyCredential  {
        guard isPerformingModalReqest == false else {
            throw BaseError(shortMessage: "WebAuthn request is authorizing. Please wait until the current authentication is finished and try again.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.authenticationAnchor = anchor

            let rpId = option.relyingParty.id
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)

            // Fetch the challenge from the server. The challenge needs to be unique for each request.
            let challenge = Data(option.challenge.decodedBytes ?? [])

            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)

            if let allowCredentials = option.allowCredentials, !allowCredentials.isEmpty {
                let credentialDescriptors = allowCredentials.map {
                    let credentialID = URLEncodedBase64($0.id).decodedBytes
                    return ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: Data(credentialID ?? []))
                }
                assertionRequest.allowedCredentials = credentialDescriptors
            }

            if let userVerification = option.userVerification {
                assertionRequest.userVerificationPreference = .init(userVerification.rawValue)
            }

            // Also allow the user to use a saved password, if they have one.
            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordCredentialProvider.createRequest()

            // Pass in any mix of supported sign-in request types.
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self

            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
            // passkey from a nearby device.
            authController.performRequests()
            isPerformingModalReqest = true

            self.continuation = continuation
            self.webAuthnMode = .login
        }
    }
}

extension WebAuthnHandler: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        switch authorization.credential {
        case let asCredentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            logger.webAuthn.info("A new passkey was registered: \(asCredentialRegistration)")

            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            let attestationObjectData = asCredentialRegistration.rawAttestationObject
            let clientDataJSON = asCredentialRegistration.rawClientDataJSON
            var attachment: AuthenticatorAttachment = .platform
            if #available(iOS 16.6, *) {
                switch asCredentialRegistration.attachment {
                case .platform:
                    attachment = .platform
                case .crossPlatform:
                    attachment = .crossPlatform
                @unknown default:
                    attachment = .platform
                }
            }

            let credential = RegistrationCredential(
                id: asCredentialRegistration.credentialID.base64URLEncodedString().asString(),
                type: CredentialType.publicKey,
                authenticatorAttachment: attachment,
                rawID: asCredentialRegistration.credentialID.base64URLEncodedString(),
                response: AuthenticatorAttestationResponse(
                    rawClientDataJSON: clientDataJSON.bytes,
                    rawAttestationObject: attestationObjectData?.bytes ?? []
                )
            )
            logger.webAuthn.debug("RegistrationCredential:")
            logger.webAuthn.debug("\(String(describing: credential))")

            continuation?.resume(returning: credential)
            continuation = nil

        case let asCredentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            logger.webAuthn.log("A passkey was used to sign in: \(asCredentialAssertion)")

            // Verify the below signature and clientDataJSON with your service for the given userID.
            let signature = asCredentialAssertion.signature
            let clientDataJSON = asCredentialAssertion.rawClientDataJSON
            let authenticatorData = asCredentialAssertion.rawAuthenticatorData
            var attachment: AuthenticatorAttachment = .platform
            if #available(iOS 16.6, *) {
                switch asCredentialAssertion.attachment {
                case .platform:
                    attachment = .platform
                case .crossPlatform:
                    attachment = .crossPlatform
                @unknown default:
                    attachment = .platform
                }
            }

            let credential = AuthenticationCredential(
                id: asCredentialAssertion.credentialID.base64URLEncodedString().asString(),
                type: CredentialType.publicKey,
                authenticatorAttachment: attachment,
                rawID: asCredentialAssertion.credentialID.base64URLEncodedString(),
                response: AuthenticatorAssertionResponse(
                    clientDataJSON: clientDataJSON.bytes.base64URLEncodedString(),
                    authenticatorData: (authenticatorData ?? .init() ).bytes.base64URLEncodedString(),
                    signature: (signature ?? .init()).bytes.base64URLEncodedString(),
                    userHandle: asCredentialAssertion.userID.base64URLEncodedString()
                )
            )
            logger.webAuthn.debug("AuthenticationCredential:")
            logger.webAuthn.debug("\(String(describing: credential))")

            continuation?.resume(returning: credential)
            continuation = nil
            
        default:
            logger.webAuthn.notice("Received unknown authorization type.")

            let error: WebAuthnCredentialError
            switch webAuthnMode {
            case .register:
                error = .registerUnknownAuthType
            case .login:
                error = .requestUnknownAuthType
            }
            continuation?.resume(throwing: error)
            continuation = nil
        }

        isPerformingModalReqest = false
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authorizationError = error as? ASAuthorizationError {
            if authorizationError.code == .canceled {
                // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
                // This is a good time to show a traditional login form, or ask the user to create an account.
                logger.webAuthn.notice("Request canceled.")
            } else {
                // Another ASAuthorization error.
                // Note: The userInfo dictionary contains useful information.
                logger.webAuthn.error("Error: \((error as NSError).userInfo)")
            }
        } else {
            isPerformingModalReqest = false
            logger.webAuthn.error("Unexpected authorization error: \(error.localizedDescription)")
        }

        let shortErrorMessage: String
        switch webAuthnMode {
        case .register:
            shortErrorMessage = "WebAuthnCredential registration failed"
        case .login:
            shortErrorMessage = "WebAuthnCredential request failed"
        }

        let err = BaseError(shortMessage: shortErrorMessage,
                            args: .init(cause: error, name: String(describing: error)))
        continuation?.resume(throwing: err)
        continuation = nil

        isPerformingModalReqest = false
    }
}

extension WebAuthnHandler: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor ?? ASPresentationAnchor()
    }
}
