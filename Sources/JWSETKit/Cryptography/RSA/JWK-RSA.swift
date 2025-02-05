//
//  JWK-RSA.swift
//
//
//  Created by Amir Abbas Mousavian on 9/7/23.
//

import Foundation
import SwiftASN1
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
#if canImport(CommonCrypto)
import CommonCrypto
#else
#endif
#if canImport(_CryptoExtras)
import _CryptoExtras
#endif
#if canImport(CryptoSwift)
import CryptoSwift
#endif

/// JSON Web Key (JWK) container for RSA public keys.
public struct JSONWebRSAPublicKey: MutableJSONWebKey, JSONWebValidatingKey, JSONWebEncryptingKey, Sendable {
    public var storage: JSONWebValueStorage
    
    public init(storage: JSONWebValueStorage) {
        self.storage = storage
    }
    
    public init(derRepresentation: Data) throws {
#if canImport(CommonCrypto)
        self.storage = try SecKey(derRepresentation: derRepresentation, keyType: .rsa).storage
#elseif canImport(_CryptoExtras)
        self.storage = try _RSA.Signing.PublicKey(derRepresentation: derRepresentation).storage
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoExtras is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
    
    public static func create(storage: JSONWebValueStorage) throws -> JSONWebRSAPublicKey {
        .init(storage: storage)
    }
    
    public func verifySignature<S, D>(_ signature: S, for data: D, using algorithm: JSONWebSignatureAlgorithm) throws where S: DataProtocol, D: DataProtocol {
#if canImport(CommonCrypto)
        return try SecKey.create(storage: storage).verifySignature(signature, for: data, using: algorithm)
#elseif canImport(_CryptoExtras)
        return try _RSA.Signing.PublicKey.create(storage: storage).verifySignature(signature, for: data, using: algorithm)
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoExtras is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
    
    public func encrypt<D, JWA>(_ data: D, using algorithm: JWA) throws -> Data where D: DataProtocol, JWA: JSONWebAlgorithm {
#if canImport(CommonCrypto)
        return try SecKey.create(storage: storage).encrypt(data, using: algorithm)
#elseif canImport(CryptoSwift) && canImport(_CryptoExtras)
        let key = try _RSA.Encryption.PublicKey.create(storage: storage)
        if algorithm == .rsaEncryptionPKCS1 {
            let rsaKey = try RSA(rawRepresentation: key.pkcs1DERRepresentation)
            return try .init(rsaKey.encrypt([UInt8](data), variant: .pksc1v15))
        } else {
            return try key.encrypt(data, using: algorithm)
        }
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoSwift is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
}

/// JWK container for RSA private keys.
public struct JSONWebRSAPrivateKey: MutableJSONWebKey, JSONWebSigningKey, JSONWebDecryptingKey, Sendable {
    public var storage: JSONWebValueStorage
    
    public var publicKey: JSONWebRSAPublicKey {
        var result = JSONWebRSAPublicKey(storage: storage)
        result.privateExponent = nil
        result.firstPrimeFactor = nil
        result.secondPrimeFactor = nil
        result.firstFactorCRTExponent = nil
        result.secondFactorCRTExponent = nil
        result.firstCRTCoefficient = nil
        return result
    }
    
    public init(algorithm _: any JSONWebAlgorithm) throws {
        self.storage = try _RSA.Signing.PrivateKey(keySize: .bits2048).storage
    }
    
    public init(storage: JSONWebValueStorage) {
        self.storage = storage
    }
    
    public init(derRepresentation: Data) throws {
#if canImport(CommonCrypto)
        self.storage = try SecKey(derRepresentation: derRepresentation, keyType: .rsa).storage
#elseif canImport(_CryptoExtras)
        self.storage = try _RSA.Signing.PrivateKey(derRepresentation: derRepresentation).storage
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoExtras is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
    
    public static func create(storage: JSONWebValueStorage) throws -> JSONWebRSAPrivateKey {
        .init(storage: storage)
    }
    
    public func signature<D>(_ data: D, using algorithm: JSONWebSignatureAlgorithm) throws -> Data where D: DataProtocol {
#if canImport(CommonCrypto)
        return try SecKey.create(storage: storage).signature(data, using: algorithm)
#elseif canImport(_CryptoExtras)
        return try _RSA.Signing.PrivateKey.create(storage: storage).signature(data, using: algorithm)
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoExtras is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
    
    public func decrypt<D, JWA>(_ data: D, using algorithm: JWA) throws -> Data where D: DataProtocol, JWA: JSONWebAlgorithm {
#if canImport(CommonCrypto)
        return try SecKey.create(storage: storage).decrypt(data, using: algorithm)
#elseif canImport(CryptoSwift) && canImport(_CryptoExtras)
        let key = try _RSA.Encryption.PrivateKey.create(storage: storage)
        if algorithm == .rsaEncryptionPKCS1 {
            let rsaKey = try RSA(rawRepresentation: key.derRepresentation)
            return try .init(rsaKey.decrypt([UInt8](data), variant: .pksc1v15))
        } else {
            return try key.decrypt(data, using: algorithm)
        }
#else
        // This should never happen as CommonCrypto is available on Darwin platforms
        // and CryptoSwift is used on non-Darwin platform.
        fatalError("Unimplemented")
#endif
    }
}

enum RSAHelper {
    static func rsaComponents(_ data: Data) throws -> [Data] {
        let der = try DER.parse([UInt8](data))
        guard let nodes = der.content.sequence else {
            throw CryptoKitASN1Error.unexpectedFieldType
        }
        guard nodes.count >= 2 else {
            throw CryptoKitASN1Error.invalidASN1Object
        }
        return try nodes.compactMap {
            guard let data = $0.content.primitive else {
                throw CryptoKitASN1Error.unexpectedFieldType
            }
            return data
        }
    }
    
    static func pkcs1Representation(_ key: AnyJSONWebKey) throws -> Data {
        guard let modulus = key.modulus, let publicExponent = key.exponent else {
            throw CryptoKitError.incorrectKeySize
        }
        let components: [Data]
        if let privateExponent = key.privateExponent,
           let prime1 = key.firstPrimeFactor,
           let prime2 = key.secondPrimeFactor,
           let exponent1 = key.firstFactorCRTExponent,
           let exponent2 = key.secondFactorCRTExponent,
           let coefficient = key.firstCRTCoefficient
        {
            components = [
                Data([0x00]),
                modulus, publicExponent,
                privateExponent, prime1, prime2,
                exponent1, exponent2, coefficient,
            ]
        } else {
            components = [modulus, publicExponent]
        }
        var result = DER.Serializer()
        try result.appendIntegers(components)
        return Data(result.serializedBytes)
    }
    
    static func rsaWebKey(data: Data) throws -> any JSONWebKey {
        let components = try rsaComponents(data)
        var key = AnyJSONWebKey()
        switch components.count {
        case 2:
            key.keyType = .rsa
            key.modulus = components[0]
            key.exponent = components[1]
            return JSONWebRSAPublicKey(storage: key.storage)
        case 9:
            key.keyType = .rsa
            key.modulus = components[1]
            key.exponent = components[2]
            key.privateExponent = components[3]
            key.firstPrimeFactor = components[4]
            key.secondPrimeFactor = components[5]
            key.firstFactorCRTExponent = components[6]
            key.secondFactorCRTExponent = components[7]
            key.firstCRTCoefficient = components[8]
            return JSONWebRSAPrivateKey(storage: key.storage)
        default:
            throw JSONWebKeyError.unknownKeyType
        }
    }
}
