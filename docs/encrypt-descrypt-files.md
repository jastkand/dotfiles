The original article:
https://dev.to/efe/how-to-use-gnupg-for-encrypting-files-on-macos-2kke

```
brew install gnupg
gpg --version

gpg -c --armor --cipher-algo AES256 --no-symkey-cache --output test.asc test.txt

gpg --decrypt --no-symkey-cache --output test1.txt test.asc
```
