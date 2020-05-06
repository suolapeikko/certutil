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
        
        let identities = certificateUtils.sortIdentitiesDescendingExpirationDate(identities: certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]))

        for identity in identities {
            
            print("CN=\(identity.cn), Expiration: \(identity.dateAsString)")
        }
        
        errorFlag = false

    case "-list_exp":
            
            let identities = certificateUtils.sortIdentitiesDescendingExpirationDate(identities: certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]))

            let expiredIdentities = certificateUtils.listExpiredIdentities(identities: identities)

            for identity in expiredIdentities {
                let cn = identity.cn
                let dateStr = identity.dateAsString
                print("CN=\(cn), Expiration: \(dateStr)")
            }
            
            errorFlag = false

    case "-verify":
        
        var index = 0
        let identities = certificateUtils.sortIdentitiesDescendingExpirationDate(identities: certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]))

        for identity in identities {
            let cn = identity.cn
            let date = identity.dateAsString
            
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
        let identities = certificateUtils.sortIdentitiesDescendingExpirationDate(identities: certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]))

        for identity in identities {
            let cn = identity.cn
            let date = identity.dateAsString
            
            if(index > 0) {
                print("CN=\(cn), Expiration: \(date.description) -> Deleting")
            }
            else {
                print("CN=\(cn), Expiration: \(date.description) -> Keeping")
            }
            index += 1
        }

        certificateUtils.deleteOldestIdentities(identities: identities)
        
        
        errorFlag = false

        
    case "-delete_exp":

        let identities = certificateUtils.sortIdentitiesDescendingExpirationDate(identities: certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]))

        let expiredIdentities = certificateUtils.listExpiredIdentities(identities: identities)

        for identity in expiredIdentities {
            let cn = identity.cn
            let date = identity.dateAsString
            print("CN=\(cn), Expiration: \(date.description) -> Deleting")
        }

        certificateUtils.deleteExpiredIdentities(identities: expiredIdentities)
        
        
        errorFlag = false

    case "-count":
        
        print("Total amount of certificates having '\(args[2])' in CN: \(certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2]).count)")

        errorFlag = false

    case "-count_exp":
        
        let identities = certificateUtils.findIdentitiesFromKeychain(subjectContains: args[2])
        
        print("Total amount of expired certificates having '\(args[2])' in CN: \(certificateUtils.listExpiredIdentities(identities: identities).count)")

        errorFlag = false

    default:
        errorFlag = true
    }
}

if(errorFlag) {
    print("certutil: Command line utility for listing and cleaning certificates from Keychain (Version 4.1)\n")
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
