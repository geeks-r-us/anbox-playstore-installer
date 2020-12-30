# anbox-playstore-installer
Install script that automates installation of googles playstore in anbox (an LX container based environment to run Android apps on Linux https://www.anbox.io/ )

A detailed description of the installation steps can be found under: 
~~https://geeks-r-us.de/2017/08/26/android-apps-auf-dem-linux-desktop/~~
https://geeks-r-us.de/2018/09/04/anbox-update-overlay/

Tested with Anbox Snap 186 on Ubuntu 20.04 and 20.10

COMMANDS:
 --clean    remove downloads and temporary files

If you find this piece of software useful and or want to support it's development think of buying me a coffee https://www.buymeacoffee.com/YdV7B1rex

## Installation

**Ubuntu**

```bash
sudo apt install lzip
wget -O -  https://raw.githubusercontent.com/geeks-r-us/anbox-playstore-installer/master/install-playstore.sh | bash
```
