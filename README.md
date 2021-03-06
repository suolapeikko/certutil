# certutil
macOS command line tool for deleting expired/duplicate/not used certificates and associated private keys from Keychain. The idea of certutil is to always leave the most recent certificate in Keychain.

If you are running macOS 10.3 (High Sierra) or below, you need to install [Swift 5 Runtime Support for Command Line Tools](https://support.apple.com/kb/DL1998?locale=en_US) to run certutil.

## Usage:
```
$ ./certutil
certutil: Command line utility for listing and cleaning certificates from Keychain (Version 4.1)

   Usage:
   certutil -list <name>           List all certificates with <name> in CN
   certutil -list_exp <name>       List all expired certificates with <name> in CN
   certutil -verify <name>         List and verify all certificates with <name> in CN
   certutil -delete <name>         Delete all certificates except the most recent one with <name> in CN
   certutil -delete_exp <name>     Delete all expired certificates with <name> in CN
   certutil -count <name>          Count all certificates with <name> in CN
   certutil -count_exp <name>      Count all expired certificates with <name> in CN
```

## Options:
The whole idea of the tool is to remove copies of defined certificates and associated private (and possible public) keys that are not used, thus leaving only the latest one to the macOS's Keychain.

`./certutil -list <name>` searches keychain for all certificates which have name variable in their CN. For example, it will match both "Developer ID Application: Antti" and "Developer ID Installer: Antti". The idea of the tool is to not restrict user to do only exact matches.

`./certutil -list_exp <name>` searches keychain for all expired certificates which have name variable in their CN. For example, it will match both "Developer ID Application: Antti" and "Developer ID Installer: Antti". The idea of the tool is to not restrict user to do only exact matches.

`./certutil -verify <name>`is used to verify the selected name variable and show what the tool will actually delete by marking them with `-> Remove` in the list that it prints to the screen. This way you can test the result before deleting anything.

`./certutil -delete <name>` deletes all certificates from Keychain which have name variable in their CN. Be careful with the name attribute. Use at your own risk!

`./certutil -delete_exp <name>` deletes all expired certificates from Keychain which have name variable in their CN. Be careful with the name attribute. Use at your own risk!

`./certutil -count <name>` counts the number of certificates with the given full or substring of CN.

`./certutil -count_exp <name>` counts the number of expired certificates with the given full or substring of CN.

## How to get started:
Download the latest certutil from GitHub:

`curl -OL https://github.com/suolapeikko/certutil/releases/download/4.1/CertUtil-4.1.pkg`

Install certutil to /usr/local/bin:

`sudo installer -package CertUtil-4.1.pkg -target /`

Make a test run with "-verify" command:

`certutil -verify "your_cn_value_here"`

You should make a backup copy of your Keychain before running "-delete" command in case something goes wrong:

`sudo cp -Rpf ~/Library/Keychains ~/Desktop`

## Usage examples:
```
antti@my-mbp ~ % certutil -count "@antti.com"
Total amount of certificates having '@antti.com' in CN: 3

antti@my-mbp ~ % certutil -list "@antti.com"
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17

antti@my-mbp ~ % certutil -verify "@antti.com"
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59 -> Keep
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44 -> Delete
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17 -> Delete

antti@my-mbp ~ % certutil -delete "@antti.com" 
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:59 -> Keeping
CN=antti@antti.com, Expiration: 14. Mar 2021 15:26:44 -> Deleting
CN=antti@antti.com, Expiration: 14. Mar 2021 15:01:17 -> Deleting
```
