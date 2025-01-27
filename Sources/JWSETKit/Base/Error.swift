//
//  Error.swift
//
//
//  Created by Amir Abbas Mousavian on 9/7/23.
//

import Foundation

/// General settings and configurations.
enum JSONWebKit {
    /// Localization used for key lookups and translating errors.
    @ReadWriteLocked
    public static var locale: Locale = .autoupdatingCurrent
}

/// Errors occurred during key creation or usage.
///
/// - Note: Localization of `errorDescription` can be changes by setting `jsonWebKeyLocale`.
public enum JSONWebKeyError: LocalizedError, Sendable {
    /// Given algorithm is unsupported in the framework.
    case unknownAlgorithm
    
    /// Key type is not defined.
    ///
    /// Supported key types are `"EC"`, `"RSA"`, `"oct"`.
    case unknownKeyType
    
    /// Decipherment of given cipher-text has failed.
    case decryptionFailed
    
    /// Key not found.
    case keyNotFound
    
    /// Operation is not allowed with given class/struct or key.
    case operationNotAllowed
    
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .unknownAlgorithm:
            return .init(localizingKey: "errorUnknownAlgorithm")
        case .unknownKeyType:
            return .init(localizingKey: "errorUnknownKeyType")
        case .decryptionFailed:
            return .init(localizingKey: "errorDecryptionFailed")
        case .keyNotFound:
            return .init(localizingKey: "errorKeyNotFound")
        case .operationNotAllowed:
            return .init(localizingKey: "errorOperationNotAllowed")
        }
    }
}

/// Validation errors including expired token.
///
/// - Note: Localization of `errorDescription` can be changes by setting `jsonWebKeyLocale`.
public enum JSONWebValidationError: LocalizedError, Sendable {
    /// Current date is after `"exp"` claim in token.
    case tokenExpired(expiry: Date)
    
    /// Current date is before `"nbf"` claim in token.
    case tokenInvalidBefore(notBefore: Date)
    
    /// Given audience is not enlisted in `"aud"` claim in token.
    case audienceNotIntended(String)
    
    /// A required field is missing.
    case missingRequiredField(key: String)
    
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = JSONWebKit.locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        switch self {
        case .tokenExpired(let date):
            return .init(localizingKey: "errorExpiredToken", dateFormatter.string(from: date))
        case .tokenInvalidBefore(let date):
            return .init(localizingKey: "errorNotBeforeToken", dateFormatter.string(from: date))
        case .audienceNotIntended(let audience):
            return .init(localizingKey: "errorInvalidAudience", audience)
        case .missingRequiredField(let key):
            return .init(localizingKey: "errorMissingField", key)
        }
    }
}
