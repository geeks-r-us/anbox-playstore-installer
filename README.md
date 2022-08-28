# anbox-playstore-installer
Install script that automates installation of googles playstore in anbox (an LX container based environment to run Android apps on Linux https://anbox.io/ )

A detailed description of the installation steps can be found under: 
~~https://geeks-r-us.de/2017/08/26/android-apps-auf-dem-linux-desktop/~~
https://geeks-r-us.de/2018/09/04/anbox-update-overlay/

Tested with Anbox Snap 186 on Ubuntu 20.04 and 20.10 and Debian 11

COMMANDS:
 --clean    remove downloads and temporary files
 --layout   installs specific keyboard layout options are: da_DK de_CH de_DE en_GB en_UK en_US es_ES es_US fr_BE fr_CH fr_FR it_IT nl_NL pt_BR pt_PT ru_RU

## Installation

**Ubuntu**

```bash
sudo apt install lzip
wget -O -  https://raw.githubusercontent.com/geeks-r-us/anbox-playstore-installer/master/install-playstore.sh | bash
```

## Support
If you find this software useful please support me with a cup of [coffee](https://ko-fi.com/geeks_r_us) or start [sponsoring](https://github.com/sponsors/geeks-r-us) my work
