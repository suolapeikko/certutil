# certutil
macOS command line tool for removing multiple copies of the same certificate from macOS's Keyhchain.

Usage:
```
$ ./certutil
certutil: Command line utility for listing and cleaning certificates from Keychain

   Usage:
   certutil -list <name>       List all certificates having <name> in CN
   certutil -verify <name>     List and verify all certificates having <name> in CN
   certutil -delete <name>     Delete all certificates except the latest one having <name> in CN
```

Examples:
