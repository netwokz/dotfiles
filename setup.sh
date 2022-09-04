#!/bin/bash

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# save current working directory
workdir=$PWD

# packages to install
pacman_packages=("thunar" "thunar-volman" "micro" "alacritty" "xmonad" "xmonad-contrib" "polybar" "rofi" "nitrogen" "picom" "lsd" "feh" "bottom" "neofetch" "gvfs" "gvfs-smb" "zsh" "starship" "xpad" "jq")

# aur packages to install
aur_packages=("visual-studio-code-bin" "google-chrome" "snapd" "betterlockscreen" "ly")

# exit on errors
set -e

info() { echo -e "\e[1m--> $@\e[0m"; }
mkcd() { mkdir -p "$1" && cd "$1"; }

# check if not running as root
test "$UID" -gt 0 || { info "don't run this as root!"; exit; }

# ask for user password once, set timestamp. see sudo(8)
info "setting / verifying sudo timestamp"
sudo -v

# make sure we can even build packages
info "we need packages from 'base-devel'"
sudo pacman -S --noconfirm base-devel

function install_yay(){
    # which packages to install from AUR, in this order!
    aurpkgs="yay"
    
    # make and enter build environment
    buildroot="$(mktemp -d /tmp/install-pacaur-XXXXXX)"
    info "switching to temporary directory '$buildroot'"
    mkcd "$buildroot"

    # set link to plaintext PKGBUILDs
    pkgbuild="https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h"
    info "using '$pkgbuild=<package>' for plaintext PKGBUILDs"

    # loop over required packages
    info "looping over all packages in \$aurpkgs: '$aurpkgs'"
    for pkg in $aurpkgs; do

        info "create subdirectory for $pkg"
        mkcd "$buildroot/$pkg"

        info "fetch PKGBUILD for $pkg"
        curl -o PKGBUILD "$pkgbuild=$pkg"

        info "fetch required pgp keys from PKGBUILD"
        gpg --recv-keys $(sed -n "s:^validpgpkeys=('\([0-9A-Fa-fx]\+\)').*$:\1:p" PKGBUILD)

        info "make and install ..."
        makepkg -si --noconfirm

    done

    info "finished. cleaning up .."
    cd "$buildroot/.."
    rm -rf "$buildroot"
}

function pac_remove_pkg(){
    echo "Removing packages..."
    for pkg in ${pacman_packages[@]};do
        if [[ $(command -v $pkg) ]]; then
            echo "$pkg is installed"
            echo "Removing $pkg"
            pacman -R $pkg --noconfirm --noprogressbar
            sleep 2

        else
            echo "$pkg is not installed"
            #pacman -S $pkg --answerclean None --answerdiff None
        fi
    done    
}

function pac_install_pkg(){
    for pkg in ${pacman_packages[@]};do
        if [[ $(command -v $pkg) ]]; then
            echo -e "${GREEN}$pkg is already installed${NOCOLOR}"

        else
            echo -e "${GREEN}Installing $pkg${NOCOLOR}"
            sudo pacman -S $pkg --noconfirm --noprogressbar
        fi
    done
}

function aur_install_pkg(){
    if [[ $(command -v "yay") ]]; then
        echo "Insalling packages..."
        for pkg in ${aur_packages[@]};do
            if [[ $(command -v $pkg) ]]; then
                echo "$pkg is already installed"
            else
                echo -e "${GREEN}Installing $pkg${NOCOLOR}"
                yay -S $pkg --noconfirm --answerclean None --answerdiff None
            fi            
        done
    else
        echo "yay is not installed!"
        sleep 5
    fi
}

function copy_custom_files(){
    mkdir -p ~/Downloads
    sudo mkdir -p /usr/local/share/fonts/ttf
    sudo cp -a $workdir/JetBrains.ttf /usr/local/share/fonts/ttf/
    sudo cp -a $workdir/weathericons.ttf /usr/local/share/fonts/ttf/
    cp -a $workdir/polybar/. ~/.config/polybar/
    cp -a $workdir/betterlockscreen/. ~/.config/betterlockscreen/
    cp -a $workdir/alacritty/. ~/.config/alacritty/
    cp -a $workdir/neofetch/. ~/.config/neofetch/
    cp -a $workdir/xmonad/. ~/.xmonad/
    cp -a $workdir/rofi/. ~/.config/rofi/
    sudo cp -a $workdir/powermenu/powermenu /usr/bin/
    sudo cp -a $workdir/scripts/systemd-timers/. /usr/lib/systemd/system/
    sudo systemctl start updateRepositories.timer
    sudo systemctl enable updateRepositories.timer
    cp -a $workdir/wallpapers/. ~/Downloads/
    xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>p' -s powermenu
    xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>e' -s thunar
    xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>t' -s alacritty
    xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>c' -s google-chrome-stable
    xfconf-query --create --channel xfce4-keyboard-shortcuts --property '/commands/custom/<Super>Return' --type string --set  'rofi -show drun'
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorDisplayPort-2/workspace0/last-image -s $workdir/wallpapers/server_room.jpg
    betterlockscreen -u ~/Downloads/server_room.jpg
    sudo systemctl enable --now snapd.socket
    sudo ln -s /var/lib/snapd/snap /snap
}

function setup_shell(){
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
    touch ~/.histfile
    cp -a $workdir/starship/starship.toml ~/.config/starship.toml
    cp -a $workdir/zsh/zshrc ~/.zshrc
    chsh -s $(which zsh)
}

install_yay
sudo pacman -Sy
pac_install_pkg
aur_install_pkg
copy_custom_files
setup_shell

reboot

function make_install(){
    cd /home/netwokz/
    sudo -u netwokz mkdir -p temp_dir
    cd /home/netwokz/temp_dir/
    sudo -u netwokz git clone https://aur.archlinux.org/google-chrome.git
    cd /home/netwokz/temp_dir/google-chrome/
    sudo -u netwokz makepkg -si
    rm -rf /home/netwokz/temp_dir/
}

#wget -q --tries=10 --timeout=20 --spider http://google.com
#if [[ $? -eq 0 ]]; then
#        echo "Online"
#        sleep 5
#else
#        echo "Offline"
#fi

#make_install
#for pkg in ${aur_packages[@]};do
#    if [[ $(command -v $pkg) ]]; then
#        echo "$pkg is installed"
#
#    else
#        echo "$pkg is not installed"
#        yay -S $pkg --answerclean None --answerdiff None
#    fi
#done

#echo "Checking and installing packages..."

#for str in ${packages[@]};do
#    if [[ $(command -v $str) ]]; then
#        echo "$str is installed"
#    else
#        echo "$str is not installed"
#        yay -S $str --answerclean None --answerdiff None
#    fi
#done

#function remove_pkg(){
#        yay -R "$1"
#}

#remove_pkg "visual-studio-code-bin"


#function is_installed() {
#     if [ -n "$(dpkg -l | awk "/^ii  $1/")" ]; then
#        return 1;
#    fi
#    return 0;
#}

#if is_installed "micro"; then
#    echo "micro installed";
#else
#    echo "micro not installed";
#fi

# Check if package is installed
#if [[ $(command -v ${packages[3]}) ]]; then
#    echo "${packages[3]} is installed"
#else
#    echo "${packages[3]} is not installed"
#    echo "Installing ${packages[3]}..."
#    yay -S visual-studio-code-bin --answerclean None --answerdiff None
#fi
