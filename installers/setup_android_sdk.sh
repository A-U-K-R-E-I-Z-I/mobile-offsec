#!/usr/bin/env bash

# Copyright (C) 2020 BizarreNULL <jonas.uliana@passwd.com.br>

# Project:     mobile-offsec
# Repository:  https://github.com/BizarreNULL/mobile-offsec
# License:     WTFPL
# Description: My personal repo to automate some stuffs for pentesting

export BASE_DIR="$HOME/.android/cmdline-tools/latests"

function usage() {
    echo "> Mobile Application Penetration Testing"
    echo "> github.com/BizarreNULL/mobile-offsec"
    echo
    echo "Automatic Android SDK installation (and uninstallation)."
    echo "Eg.: $0 <OPTION>"
    echo
    echo -e "\\t-c --check            - Check if Android Tools is present."
    echo -e "\\t-i --install          - Setup Android SDK."
    echo -e "\\t-u --uninstall        - Uninstall Android Studio and Android SDK."
    echo -e "\\t-h --hrlp             - Show this help and exit."
    echo
}

function check_requirements() {
    echo "[+] Checking requirements..."
    
    if [ -z "$HOME" ]; then
        echo "[!] HOME Environment variable is empty"
        exit 111
    fi
    
    if [ ! $(which curl) ]; then
        echo "[!] curl not found"
        exit 111
    fi
    
    if [ ! $(which unzip) ]; then
        echo "[!] unzip not found"
        exit 111
    fi
    
    if [ ! $(which java) ]; then
        echo "[!] Java SDK not fount"
        echo "    Prefered version is OpenJDK 1.8.0_242"
        echo "    On Ubuntu-based run apt install openjdk-8-jdk"
        exit 111
    fi
    
    if [ ! -w $BASE_DIR ]; then
        mkdir -p $BASE_DIR
    fi
}

function check_installation() {
    echo "[+] Checking installation..."
    
    if [ ! -z "$ANDROID_SDK" ]; then
        echo "[!] Environment variable ANDROID_SDK ($ANDROID_SDK) is not empty"
        echo "    Maybe a active Android SDK installation?"
        
        exit 111
    fi
    
    if [ ! -z "$ANDROID_HOME" ]; then
        echo "[!] Environment variable ANDROID_HOME ($ANDROID_HOME) is not empty"
        echo "    Maybe a active Android SDK installation?"
        
        exit 111
    fi
    
    if [ -e $BASE_DIR/source.properties ]; then
        echo "[+] Found installation under $BASE_DIR"
        echo "    If you wanna reinstall, remove with --uninstall option"
        
        exit 111
    fi
    
    check_requirements
}

function uninstall() {
    if [ ! -e $BASE_DIR/source.properties ]; then
        echo "[!] Installation not found on default directory ($BASE_DIR)"
        
        exit 111
    fi
    
    rm -rf $BASE_DIR
    echo "[+] Installation removed"
}

function install() {
    check_installation
    
    case "$OSTYPE" in
        linux*) os_type="NIX" ;;
        darwin*) os_type="MAC" ;;
        *) os_type="UNKNOWN" ;;
    esac
    
    ANDROID_ARCHIVE="commandlinetools.zip"
    if [[ "$OSTYPE" =~ "linux" ]]; then
        ANDROID_URL="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip"
        elif [[ "$OSTYPE" =~ "darwin" ]]; then
        ANDROID_URL="https://dl.google.com/android/repository/commandlinetools-mac-6200805_latest.zip"
    else
        echo "[!] Unsupported OS detected!"
        exit 111
    fi
    
    echo "[+] Downloading Android SDK..."
    curl "$ANDROID_URL" -o $BASE_DIR/$ANDROID_ARCHIVE -s > /dev/null ||
    (
        fatal "[!] Download failed"
        rm $BASE_DIR/$ANDROID_ARCHIVE
        exit 111
    ) &&
    echo "[+] Download successful"
    
    echo "[+] Uncompressing Android SDK... $BASE_DIR/$ANDROID_ARCHIVE"
    (cd $BASE_DIR && unzip "$BASE_DIR/$ANDROID_ARCHIVE" > /dev/null 2>&1)
    mv $BASE_DIR/tools/* $BASE_DIR/
    rm -rf "$BASE_DIR/tools"
    rm $BASE_DIR/$ANDROID_ARCHIVE
    
    echo "[+] Exporting ANDROID_HOME to current session..."
    export ANDROID_HOME=$BASE_DIR
    
    echo "[+] Accepting Android SDK licenses..."
    yes | $BASE_DIR/bin/sdkmanager --licenses > /dev/null 2>&1
    
    echo "[+] Installing Android SDK things..."
    $BASE_DIR/bin/sdkmanager "platform-tools" "platforms;android-25" "platforms;android-29"
    
    echo
    echo -e "[+] Now, \\033[1myou need to export this variables to your environment\\033[0m:"
    echo -e "\\t\\033[1mexport ANDROID_HOME=$BASE_DIR\\033[0m"
    echo -e "\\t\\033[1mexport PATH=$BASE_DIR/bin:\$PATH\\033[0m"
    echo -e "\\t\\033[1mexport PATH=$HOME/.android/platform-tools:\$PATH\\033[0m"
}

if [ -z "$1" ]; then
    usage
    echo
    echo "[!] Empty command line arguments"
    exit 111
fi

while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    case $PARAM in
        -h | --help)
            usage
            exit
        ;;
        -c | --check)
            check_installation
        ;;
        -i | --install)
            install "$@"
        ;;
        -u | --uninstall)
            uninstall
        ;;
        *)
            echo "[!] Unknown parameter ($PARAM)!"
            echo "try --help."
            exit 111
        ;;
    esac
    shift
done