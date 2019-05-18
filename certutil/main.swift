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
        
        let certificates = certificateUtils.findCertificatesFromKeychain(subjectContains: args[2])
        
        for certificate in certificates {
            let cn = certificate.getCN() ?? "Unknown"
            let date = certificate.getDateFromIntSince2001(since2001: certificate.getExpirationDate())
            
            print("CN=\(cn), Expiration: \(date.description)")
        }
        
        errorFlag = false
        
    case "-verify":
        
        var index = 0
        let certificates = certificateUtils.sortCertificatesDescendingExpirationDate(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))
        
        for certificate in certificates {
            let cn = certificate.getCN() ?? "Unknown"
            let date = certificate.getDateFromIntSince2001(since2001: certificate.getExpirationDate())
            
            if(index > 0) {
                print("CN=\(cn), Expiration: \(date.description) -> Remove")
            }
            else {
                print("CN=\(cn), Expiration: \(date.description)")
            }
            index += 1
        }
        
        errorFlag = false
        
    case "-delete":
        
        certificateUtils.deleteOldestCertificates(certificates: certificateUtils.findCertificatesFromKeychain(subjectContains: args[2]))
        
        errorFlag = false
        
    default:
        errorFlag = true
    }
}

if(errorFlag) {
    print("certutil: Command line utility for listing and cleaning certificates from Keychain\n");
    print("   Usage:");
    print("   certutil -list <name>       List all certificates having <name> in CN");
    print("   certutil -verify <name>     List and verify all certificates having <name> in CN");
    print("   certutil -delete <name>     Delete all certificates except the latest one having <name> in CN");
    exit(EXIT_FAILURE)
}
