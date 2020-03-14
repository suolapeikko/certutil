//
//  CertificateUtils.swift
//  certutil
//
//  Created by Antti Tulisalo on 16/05/2019.
//  Copyright © 2019 Antti Tulisalo. All rights reserved.
//

import Foundation

enum CertificateCheckError: Error {
    case message(String)
}

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
    func getExpirationDate() -> Double {
        
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
    
    /// Convert Double value (since 2001 / NSDate) to a Date
    /// - returns:
    ///     - Date: Date
    func getDateFromIntSince2001(since2001: Double) -> String {
        
        let date = NSDate(timeIntervalSinceReferenceDate: since2001) as Date
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "d. MMM yyyy HH:mm:ss"

        return dateFormatter.string(from: date)
    }
}

struct CertificateUtils {
    
    /// Find certificates from Keychain based on the subject name of the certificate
    /// - parameters:
    ///   - String: Either partial or whole subject name of the certificate
    /// - returns:
    ///   - [SecCertificate]: An array of certificates
    func findCertificatesFromKeychain(subjectContains: String) -> [SecCertificate] {
        
        let searchQuery: [String: Any] =  [
            kSecClass as String : kSecClassCertificate,
            kSecMatchSubjectContains as String : subjectContains,
            kSecMatchLimit as String : kSecMatchLimitAll,
            kSecReturnRef as String: kCFBooleanTrue as Any
        ]
        
        var data: AnyObject?
        
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &data)
        
        if status == errSecSuccess, let retrievedData = data as! NSArray? {
            
            let swiftArr: [SecCertificate] = retrievedData.compactMap({ ($0 as! SecCertificate) })
            
            return swiftArr
        }
        else {
            return []
        }
    }
    
    /// Sort array of SecCertificates in descending order based of expiration dates
    /// - parameters:
    ///   - [SecCertificate]: An array of SecCertificate objects
    /// - returns:
    ///   - [SecCertificate]: A sorted array of SecCertificate objects in descending order
    func sortCertificatesDescendingExpirationDate(certificates: [SecCertificate]) -> [SecCertificate] {
        
        let sorted = certificates.sorted(by: { $0.getExpirationDate() > $1.getExpirationDate()})
        
        return sorted
    }
    
    /// Leave the certificate with the latest expiration date but delete the rest
    /// - parameters:
    ///   - [SecCertificate]: An array of SecCertificate objects
    func deleteOldestCertificates(certificates: [SecCertificate]) {
        
        var sortedCertificates = certificates
        
        // If we have more than 1 certificate, we need to delete something
        if(sortedCertificates.count > 1) {
            
            // Remove the first item from the sorted array, as it is the one with the latest expiration date
            sortedCertificates.removeFirst()
            
            for certificate in sortedCertificates {
                
                let deleteQuery: [String: Any] =  [
                    kSecClass as String : kSecClassCertificate,
                    kSecMatchLimit as String : kSecMatchLimitOne,
                    kSecValueRef as String: certificate
                ]
                SecItemDelete(deleteQuery as CFDictionary)
            }
        }
    }
}
