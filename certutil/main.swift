//
//  main.swift
//  certutil
//
//  Created by Antti Tulisalo on 16/05/2019.
//  Copyright © 2019 Antti Tulisalo. All rights reserved.
//

import Foundation

let args = CommandLine.arguments
let argCount = CommandLine.arguments.count
var errorFlag = true
let certificateUtils = CertificateUtils()

if(argCount == 3) {
    
    switch(args[1]) {
        
    case "-list":
        
        let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))

        for certificate in certificates {
            let cn = certificate.getCN() ?? "Unknown"
            let dateStr = certificate.getDateFromDoubleSince2001(since2001: certificate.getExpirationDateAsDouble())
            print("CN=\(cn), Expiration: \(dateStr)")
        }
        
        errorFlag = false

        case "-list_exp":
            
            let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))
            
            let expiredCertificates = certificateUtils.listExpiredCertificates(certificates: certificates)

            for certificate in expiredCertificates {
                let cn = certificate.getCN() ?? "Unknown"
                let dateStr = certificate.getDateFromDoubleSince2001(since2001: certificate.getExpirationDateAsDouble())
                print("CN=\(cn), Expiration: \(dateStr)")
            }
            
            errorFlag = false

    case "-verify":
        
        var index = 0
        let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))
        
        for certificate in certificates {
            let cn = certificate.getCN() ?? "Unknown"
            let date = certificate.getDateFromDoubleSince2001(since2001: certificate.getExpirationDateAsDouble())
            
            if(index > 0) {
                print("CN=\(cn), Expiration: \(date.description) -> Delete")
            }
            else {
                print("CN=\(cn), Expiration: \(date.description) -> Keep")
            }
            index += 1
        }
        
        errorFlag = false
        
    case "-delete":

        var index = 0
        let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))

        for certificate in certificates {
            let cn = certificate.getCN() ?? "Unknown"
            let date = certificate.getDateFromDoubleSince2001(since2001: certificate.getExpirationDateAsDouble())
            
            if(index > 0) {
                print("CN=\(cn), Expiration: \(date.description) -> Deleting")
            }
            else {
                print("CN=\(cn), Expiration: \(date.description) -> Keeping")
            }
            index += 1
        }

        certificateUtils.deleteOldestCertificates(certificates: certificates)
        
        
        errorFlag = false

        case "-delete_exp":

            let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))
            let expiredCertificates = certificateUtils.listExpiredCertificates(certificates: certificates)

            for certificate in expiredCertificates {
                let cn = certificate.getCN() ?? "Unknown"
                let date = certificate.getDateFromDoubleSince2001(since2001: certificate.getExpirationDateAsDouble())
                print("CN=\(cn), Expiration: \(date.description) -> Deleting")
            }

            certificateUtils.deleteOldestCertificates(certificates: certificates)
            
            
            errorFlag = false

    case "-count":
        
        print("Total amount of certificates having '\(args[2])' in CN: \(certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]).count)")

        errorFlag = false

    case "-count_exp":
        
        let certificates = certificateUtils.findCertificatesFromKeychain(subjectContains: args[2])
        
        print("Total amount of expired certificates having '\(args[2])' in CN: \(certificateUtils.listExpiredCertificates(certificates: certificates).count)")

        errorFlag = false

    default:
        errorFlag = true
    }
}

if(errorFlag) {
    print("certutil: Command line utility for listing and cleaning certificates from Keychain (Version 3.0)\n")
    print("   Usage:")
    print("   certutil -list <name>           List all certificates with <name> in CN")
    print("   certutil -list_exp <name>       List all expired certificates with <name> in CN")
    print("   certutil -verify <name>         List and verify all certificates with <name> in CN")
    print("   certutil -delete <name>         Delete all certificates except the most recent one with <name> in CN")
    print("   certutil -delete_exp <name>     Delete all expired certificates with <name> in CN")
    print("   certutil -count <name>          Count all certificates with <name> in CN")
    print("   certutil -count_exp <name>      Count all expired certificates with <name> in CN")
    exit(EXIT_FAILURE)
}
