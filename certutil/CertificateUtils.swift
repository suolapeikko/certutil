//
//  CertificateUtils.swift
//  certutil
//
//  Created by Antti Tulisalo on 16/05/2019.
//  Copyright © 2019 Antti Tulisalo. All rights reserved.
//

import Foundation

// Generic error class for CertUtil
enum CertUtilError: Error {
    case runtimeError(String)
}

// Adding helper functions to SecIdentity
extension SecIdentity {
     
    /// Return associated certificate object from security identity
    ///     https://developer.apple.com/documentation/security/1401305-secidentitycopycertificate
    /// - returns:
    ///   - SecCertificate?: Security certificate
    ///     https://developer.apple.com/documentation/security/seccertificate
    func getCertificate() -> SecCertificate? {
        
        var certificate: SecCertificate?
        
        let status = SecIdentityCopyCertificate(self, &certificate)
        guard status == errSecSuccess else { return nil }
        
        return certificate
    }

    /// Return associated private key object from security identity
    ///     https://developer.apple.com/documentation/security/1392978-secidentitycopyprivatekey
    /// - returns:
    ///   - SecKey?: Private key
    ///     https://developer.apple.com/documentation/security/seckey
    func getPrivateKey() -> SecKey? {
        
        var privateKey: SecKey?
        let status = SecIdentityCopyPrivateKey(self, &privateKey)
        guard status == errSecSuccess else { return nil }

        return privateKey
    }

    /// Return calculated public key based on the private key
    ///     https://developer.apple.com/documentation/security/1643774-seckeycopypublickey
    /// - returns:
    ///   - SecKey?: Public key
    ///     https://developer.apple.com/documentation/security/seckey
    func getPublicKey(privateKey: SecKey?) -> SecKey? {
        
        guard privateKey != nil else {
            return nil
        }
        
        // If private key does not have associated public key in the Keychain, this will return nil
        guard let publicKey = SecKeyCopyPublicKey(privateKey!) else {
            
            return nil
        }
        
        return publicKey
    }
}

// Adding helper fucntions to SecCertificate
extension SecCertificate {
    
    /// Return certificate's OID values
    /// - parameters:
    ///   - [CFString]: An array of OID keys
    ///     https://developer.apple.com/documentation/security/certificate_key_and_trust_services/certificates/certificate_oids
    /// - returns:
    ///   - [String:Any]: Dictionary containing searched OID values with certificate property keys
    ///     https://developer.apple.com/documentation/security/certificate_key_and_trust_services/certificates/certificate_property_keys
    func getCertificateOIDValues(keys: [CFString]) -> [String:Any]? {
        
        guard let values = SecCertificateCopyValues(self, keys as CFArray, nil) as? [String: Any] else {
            return nil
        }
        
        return values
    }
    
    /// Return certificate's CN
    /// - returns:
    ///     - String: CN value
    func getCN() -> String? {
        
        let key = [kSecOIDCommonName]
        
        guard let value = getCertificateOIDValues(keys: key) else {
            return nil
        }
        
        guard value.count > 0 else {
            return nil
        }
        
        let firstItem = Array(value.values.map{ $0 })
        
        guard let attributes: Dictionary = firstItem[0] as? [String: Any] else {
            return nil
        }
        
        guard let cn: [String] = attributes[kSecPropertyKeyValue as String] as? [String] else {
            return nil
        }
        
        return cn.joined(separator:",CN=")
    }
    
    /// Return certificate's expiration date as a number
    /// - returns:
    ///     - Double: Certificate's expiration date as a number since 2001
    func getExpirationDateAsDouble() -> Double {
        
        let key = [kSecOIDX509V1ValidityNotAfter]
        
        guard let value = getCertificateOIDValues(keys: key) else {
            return 0
        }
        
        guard value.count > 0 else {
            return 0
        }
        
        let firstItem = Array(value.values.map{ $0 })
        
        guard let attributes: Dictionary = firstItem[0] as? [String: Any] else {
            return 0
        }
        
        guard let dateNmbr = attributes[kSecPropertyKeyValue as String] else {
            return 0
        }
        
        let dateStr:String = String(format: "%@", dateNmbr as! CVarArg)
        
        guard let dateAsOf2001 = Double(dateStr) else {
            return 0
        }
        
        return dateAsOf2001
    }
    
    /// Convert Double value (since 2001 / NSDate) to a String
    /// - returns:
    ///     - Date: String
    func getDateFromDoubleSince2001(since2001: Double) -> String {

        let date = NSDate(timeIntervalSinceReferenceDate: since2001) as Date
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "d. MMM yyyy HH:mm:ss"

        return dateFormatter.string(from: date)
    }
}

// Helper data container
struct IdentityContainer {
    
    var certificate: SecCertificate
    var privateKey: SecKey?
    var publicKey: SecKey?
    var cn: String
    var dateAsString: String
    var dateAsMillisecondsSinceJan2001: Double
    
    init(certificate: SecCertificate, privateKey: SecKey?, publicKey: SecKey?, cn: String, dateAsString: String, dateAsMillisecondsSinceJan2001: Double) {
        
        self.certificate = certificate
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.cn = cn
        self.dateAsString = dateAsString
        self.dateAsMillisecondsSinceJan2001 = dateAsMillisecondsSinceJan2001
    }
}

// Main functionality
struct CertificateUtils {

    /// Validate identities to more easily handled ValidateIdentity array
    /// - parameters:
    ///   - SecIdentity: An array of security identities
    /// - returns:
    ///   - [IdentityContainer]: An array of identities
    func validateIdentities(identities: [SecIdentity]) -> [IdentityContainer] {

        let noDuplicateIdentities = Array(Set(identities))

        var processedIdentities: [IdentityContainer] = []
        
        for identity in noDuplicateIdentities {
            
            let certificate = identity.getCertificate()!
            let privateKey = identity.getPrivateKey()
            let publicKey = identity.getPublicKey(privateKey: privateKey)
            let cn = certificate.getCN()
            let dateAsDouble = certificate.getExpirationDateAsDouble()
            let dateAsString = certificate.getDateFromDoubleSince2001(since2001: dateAsDouble)
            
            if(cn != nil && dateAsDouble != 0) {
                let processedIdentity = IdentityContainer(certificate: certificate, privateKey: privateKey, publicKey: publicKey, cn: cn!, dateAsString: dateAsString, dateAsMillisecondsSinceJan2001: dateAsDouble)
                    processedIdentities.append(processedIdentity)
            }
        }
        
        return processedIdentities
    }
    
    /// Find security identities from Keychain based on the subject name of the certificate
    /// - parameters:
    ///   - String: Either partial or whole subject name of the certificate
    /// - returns:
    ///   - [IdentityContainer]: An array of validated identities
    func findIdentitiesFromKeychain(subjectContains: String) -> [IdentityContainer] {
        
        let searchQuery: [String: Any] =  [
            kSecClass as String : kSecClassIdentity,
            kSecMatchSubjectContains as String : subjectContains,
            kSecMatchLimit as String : kSecMatchLimitAll,
            kSecReturnRef as String: kCFBooleanTrue as Any
        ]
        
        var data: AnyObject?
        
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &data)
        
        if status == errSecSuccess, let retrievedData = data as! NSArray? {
            
            let identities: [SecIdentity] = retrievedData.compactMap({ ($0 as! SecIdentity) })
            
            return validateIdentities(identities: identities)
        }
        else {
            return []
        }
    }
    
    /// Sort array of processed identities in descending order based on expiration dates
    /// - parameters:
    ///   - [SecIdentity]: An array of SecIdentity objects
    /// - returns:
    ///   - [IdentityContainer]: A sorted array of identity objects in descending order
    func sortIdentitiesDescendingExpirationDate(identities: [IdentityContainer]) -> [IdentityContainer] {
        
        let sorted = identities.sorted(by: {
            $0.dateAsMillisecondsSinceJan2001 > $1.dateAsMillisecondsSinceJan2001
        })

        return sorted
    }
    
    /// Leave the identity with the most recent expiration date but delete the rest
    /// - parameters:
    ///   - [IdentityContainer]: An array of processed identity objects
    func deleteOldestIdentities(identities: [IdentityContainer]) {
        
        var mutableIdentities = identities
        
        // If we have more than 1 identity, we need to delete something
        if(mutableIdentities.count > 1) {
            
            // Remove the first item from the sorted array, as it is the one with the latest expiration date
            mutableIdentities.removeFirst()
            
            for identity in mutableIdentities {
                
                // SecCertificate item
                let deleteCertificateQuery: [String: Any] =  [
                    kSecClass as String : kSecClassCertificate,
                    kSecMatchLimit as String : kSecMatchLimitOne,
                    kSecValueRef as String: identity.certificate
                ]
                SecItemDelete(deleteCertificateQuery as CFDictionary)

                // SecKey item (private key)
                if(identity.privateKey != nil) {
                    let deletePrivateKeyQuery: [String: Any] =  [
                        kSecClass as String : kSecClassKey,
                        kSecMatchLimit as String : kSecMatchLimitOne,
                        kSecValueRef as String: identity.privateKey!
                    ]
                    SecItemDelete(deletePrivateKeyQuery as CFDictionary)
                }

                // SecKey item (public key)
                if(identity.publicKey != nil) {
                    let deletePublicKeyQuery: [String: Any] =  [
                        kSecClass as String : kSecClassKey,
                        kSecMatchLimit as String : kSecMatchLimitOne,
                        kSecValueRef as String: identity.publicKey!
                    ]
                    SecItemDelete(deletePublicKeyQuery as CFDictionary)
                }
            }
        }
    }

    /// Delete all expired identities
    /// - parameters:
    ///   - [IdentityContainer]: An array of expired identity objects
    func deleteExpiredIdentities(identities: [IdentityContainer]) {
        
        let mutableIdentities = identities
        
        for identity in mutableIdentities {
            
            // SecCertificate item
            let deleteCertificateQuery: [String: Any] =  [
                kSecClass as String : kSecClassCertificate,
                kSecMatchLimit as String : kSecMatchLimitOne,
                kSecValueRef as String: identity.certificate
            ]
            SecItemDelete(deleteCertificateQuery as CFDictionary)

            // SecKey item (private key)
            if(identity.privateKey != nil) {
                let deletePrivateKeyQuery: [String: Any] =  [
                    kSecClass as String : kSecClassKey,
                    kSecMatchLimit as String : kSecMatchLimitOne,
                    kSecValueRef as String: identity.privateKey!
                ]
                SecItemDelete(deletePrivateKeyQuery as CFDictionary)
            }

            // SecKey item (public key)
            if(identity.publicKey != nil) {
                let deletePublicKeyQuery: [String: Any] =  [
                    kSecClass as String : kSecClassKey,
                    kSecMatchLimit as String : kSecMatchLimitOne,
                    kSecValueRef as String: identity.publicKey!
                ]
                SecItemDelete(deletePublicKeyQuery as CFDictionary)
            }
        }
    }

    /// List all expired identities
    /// - parameters:
    ///   - [IdentityContainer]: An array of identity objects
    func listExpiredIdentities(identities: [IdentityContainer]) -> [IdentityContainer] {
        
        var expiredIdentities: [IdentityContainer] = []
        let currentDate = Date()
        var expirationDate: Date
        
        for identity in identities {
            
            expirationDate = NSDate(timeIntervalSinceReferenceDate: identity.dateAsMillisecondsSinceJan2001) as Date
            
            // If the certificate has expired, add it to an array
            if(currentDate > expirationDate) {
                expiredIdentities.append(identity)
            }
        }
        
        return expiredIdentities
    }
}
