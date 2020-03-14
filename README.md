# certutil
macOS command line tool for removing multiple copies of the same certificate from macOS's Keychain.

Usage:
```
$ ./certutil
certutil: Command line utility for listing and cleaning certificates from Keychain

   Usage:
   certutil -list <name>       List all certificates having <name> in CN
   certutil -verify <name>     List and verify all certificates having <name> in CN
   certutil -delete <name>     Delete all certificates except the latest one having <name> in CN
   certutil -count <name>      Count all certificates having <name> in CN
```

Options:
The whole idea of the tool is to remove copies of the certificates that are not used, thus leaving only the latest one to the keychain.

`./certutil -list <name>` searches keychain for all certificates which have name variable in their CN. For example, it will match both "Developer ID Application: Antti" and "Developer ID Installer: Antti". The idea of the tool is to not restrict user to do only exact matches.

`./certutil -verify <name>`is used to verify the selected name variable and show what the tool will actually delete by marking them with `-> Remove` in the list that it prints to the screen. This way you can test the result before deleting anything.

`./certutil -delete <name>` does what is says. Be careful with the name attribute. Use at your own risk!

`./certutil -count <name>` counts the number of certificates with the given full or substring of CN.

Examples:
```
antti@my-mbp ~ % certutil -count "@antti.com"
Total amount of certificates having '@antti.com' in CN: 3

antti@my-mbp ~ % certutil -list "@antti.com"
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17

antti@my-mbp ~ % certutil -verify "@antti.com"
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59 -> Keep
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44 -> Remove
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17 -> Remove

antti@my-mbp ~ % certutil -delete "@antti.com" 
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59 -> Keeping
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44 -> Deleting
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17 -> Deleting
```
