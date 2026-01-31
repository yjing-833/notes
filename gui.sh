#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)
username=$(getent passwd $(whoami) | cut -d ':' -f1)

check_root(){
    if [ "$(id -u)" -ne 0 ]; then
        echo -ne " ${R}Run this program as root!\n\n"${W}
        exit 1
    fi
}

banner() {
    clear
    echo -e "${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___"
    echo -e "${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \\" 
    echo -e "${G}    |__| |__] |__| | \\|  |  |__|    |  | |__| |__/"
    echo -e "${G}     A modded GUI version of Ubuntu\n"
}

package() {
    banner
    echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
    apt-get update -y

    packs=(sudo gnupg2 curl nano git xz-utils xfce4 xfce4-goodies xfce4-terminal librsvg2-common inetutils-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https)
    for pkg in "${packs[@]}"; do
        dpkg -s "$pkg" &>/dev/null || {
            echo -e "\n${R} [${W}-${R}]${G} Installing package: ${Y}$pkg${W}"
            apt-get install "$pkg" -y --no-install-recommends
        }
    done

    apt-get upgrade -y
    apt-get clean
}

install_apt() {
    for apt in "$@"; do
        command -v $apt &>/dev/null && echo "${Y}${apt} is already Installed!${W}" || {
            echo -e "${G}Installing ${Y}${apt}${W}"
            apt install -y ${apt}
        }
    done
}

install_vscode() {
    command -v code &>/dev/null && echo "${Y}VSCode is already Installed!${W}" || {
        echo -e "${G}Installing ${Y}VSCode${W}"
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
        apt update -y
        apt install code -y
        echo -e "${C} Visual Studio Code Installed Successfully\n${W}"
    }
}

install_sublime() {
    command -v subl &>/dev/null && echo "${Y}Sublime is already Installed!${W}" || {
        apt install gnupg2 software-properties-common -y
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublime.gpg > /dev/null
        apt update -y
        apt install sublime-text -y
        echo -e "${C} Sublime Text Editor Installed Successfully\n${W}"
    }
}

config() {
    banner
    echo -e "${R} [${W}-${R}]${C} Configuring System...\n"${W}
    
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
    yes | apt upgrade
    yes | apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin
    mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfceverticals-old.png
    temp_folder=$(mktemp -d -p "$HOME")
    { banner; sleep 1; cd $temp_folder; }

    echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n"${W}
    downloader "fonts.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/fonts.tar.gz"
    downloader "icons.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/icons.tar.gz"
    downloader "wallpaper.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/wallpaper.tar.gz"
    downloader "gtk-themes.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/gtk-themes.tar.gz"
    downloader "ubuntu-settings.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/ubuntu-settings.tar.gz"

    echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n"${W}
    tar -xvzf fonts.tar.gz -C "/usr/local/share/fonts/"
    tar -xvzf icons.tar.gz -C "/usr/share/icons/"
    tar -xvzf wallpaper.tar.gz -C "/usr/share/backgrounds/xfce/"
    tar -xvzf gtk-themes.tar.gz -C "/usr/share/themes/"
    tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/"
    rm -fr $temp_folder

    echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n"${W}
    fc-cache -fv

    echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n"${W}
    apt update
    yes | apt upgrade
    apt clean
    yes | apt autoremove
}

# ----------------------------

check_root
package
install_vscode
install_sublime
config
