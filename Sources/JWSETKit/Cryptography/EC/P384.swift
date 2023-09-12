//
//  P384.swift
//
//
//  Created by Amir Abbas Mousavian on 9/9/23.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

extension P384.Signing.PublicKey: CryptoECPublicKey {
    static var curve: JSONWebKeyCurve { .p384 }
}

extension P384.Signing.PublicKey: JSONWebValidatingKey {
    public init(storage: JSONWebValueStorage) {
        self = P384.Signing.PrivateKey().publicKey
        self.storage = storage
    }
    
    public func validate<S, D>(_ signature: S, for data: D, using _: JSONWebAlgorithm) throws where S: DataProtocol, D: DataProtocol {
        let signature = try P384.Signing.ECDSASignature(rawRepresentation: signature)
        var digest = SHA384()
        digest.update(data: data)
        if !isValidSignature(signature, for: digest.finalize()) {
            throw CryptoKitError.authenticationFailure
        }
    }
}

extension P384.Signing.PrivateKey: CryptoECPrivateKey {
    typealias PublicKey = P384.Signing.PublicKey
}

extension P384.Signing.PrivateKey: JSONWebSigningKey {
    public init(storage: JSONWebValueStorage) {
        self.init()
        self.storage = storage
    }
    
    public func sign<D>(_ data: D, using _: JSONWebAlgorithm) throws -> Data where D: DataProtocol {
        var digest = SHA384()
        digest.update(data: data)
        return try signature(for: digest.finalize()).rawRepresentation
    }
    
    public func validate<S, D>(_ signature: S, for data: D, using algorithm: JSONWebAlgorithm) throws where S: DataProtocol, D: DataProtocol {
        try publicKey.validate(signature, for: data, using: algorithm)
    }
}