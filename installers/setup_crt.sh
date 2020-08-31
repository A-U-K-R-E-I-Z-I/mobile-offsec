#!/usr/bin/env bash

# Copyright (C) 2020 BizarreNULL <jonas.uliana@passwd.com.br>

# Project:     mobile-offsec
# Repository:  https://github.com/BizarreNULL/mobile-offsec
# License:     WTFPL
# Description: Install .CRT certs on remote

function usage()
{
    echo "Setup a certificate (.CRT format only) on remote."
    echo "Note: ONLY works on API 29, API 25 and API 24."
    echo "Usage: $0 --serial=emnulator-5554 -c=certificate.crt"
    echo
    echo -e "\\t-h --help        - Show this message, and exit."
    echo -e "\\t-s --serial      - Android serial port to connect."
    echo -e "\\t-c --certificate - Certificate path."
    echo -e "\\t-g --genymotion  - Install certificate on Genymotion VM instead of AVD."
    echo -e "\\t-a --api         - API level (default is 29)."
    echo
}

API_LEVEL="29"
IS_NOT_AVD="0"

while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    case $PARAM in
        -h | --help)
            usage
            exit
        ;;
        -a | --api)
            API_LEVEL=$VALUE
        ;;
        -g | --genymotion)
        IS_NOT_AVD="1"
        ;;
        -c | --certificate)
            CERTIFICATE_PATH=$VALUE
        ;;
        -s | --serial)
            SERIAL_PORT=$VALUE
        ;;
        *)
            echo "[!] Unknown parameter ($PARAM)!"
            echo "[+] Try --help"
            echo
            exit 111
        ;;
    esac
    shift
done

if [ -z "$SERIAL_PORT" ]
then
    echo "[!] Serial port can't be empty!"
    echo "[+] Try --help"
    echo
    exit 111
fi

if [ -z "$CERTIFICATE_PATH" ]
then
    echo "[!] Certificate PATH can't be empty!"
    echo "[+] Try --help"
    echo
    exit 111
fi

echo "[+] Checking requirements..."

if [ ! "$(which adb)" ]; then
    echo "[!] adb not found"
    echo
    exit 111
fi

if [ ! "$(which openssl)" ]; then
    echo "[!] openssl not found"
    echo
    exit 111
fi

echo "[+] Checking choose API level ($API_LEVEL)..."

if [ "$API_LEVEL" != "$(adb shell getprop ro.build.version.sdk)" ]; then
    echo "[!] Invalid remote device API level!"
    echo "[!] Script aims API-$API_LEVEL, but remote are running API-$(adb shell getprop ro.build.version.sdk)"
    echo
    exit 111
fi

if [ "$(adb shell getprop ro.build.version.sdk)" == "24" ]; then
    FILENAME=$(openssl x509 -in "$CERTIFICATE_PATH" -hash -noout)
    FILENAME=$FILENAME".0"

    echo "[+] Generated certificate filename is $FILENAME"
    echo "[+] Creating certificate file..."

    openssl x509 -in "$CERTIFICATE_PATH" >> "$FILENAME"
    openssl x509 -in "$CERTIFICATE_PATH"  -text -fingerprint -noout >> "$FILENAME"

    echo "[+] Making /system writable..."

    if [ "$IS_NOT_AVD" == "1" ]; then
        adb -s "$SERIAL_PORT" shell "su 0 mount -o rw,remount /system"
    else
        adb -s "$SERIAL_PORT" shell "su 0 mount -o rw,remount /dev/block/vda /system"
    fi

    echo "[+] Pushing certificate to /sdcard/$FILENAME"
    adb -s "$SERIAL_PORT" push "$FILENAME" /sdcard
    echo "[+] Moving certificate ($FILENAME) to /system/etc/security/cacerts..."
    adb -s "$SERIAL_PORT" shell "su 0 mv /sdcard/$FILENAME /system/etc/security/cacerts"
    echo "[+] Granting certificate permissions..."
    adb -s "$SERIAL_PORT" shell "su 0 chmod 644 /system/etc/security/cacerts/$FILENAME"
    echo "[+] Reverting /system to read-only..."

    if [ "$IS_NOT_AVD" == "1" ]; then
        adb -s "$SERIAL_PORT" shell "su 0 mount -o ro,remount /system"
    else
        adb -s "$SERIAL_PORT" shell "su 0 mount -o ro,remount /dev/block/vda /system"
    fi

    echo "[+] Removing local generated certificate..."
    rm "$FILENAME"



elif [ "$(adb shell getprop ro.build.version.sdk)" == "29" ] || [ "$(adb shell getprop ro.build.version.sdk)" == "25" ];then
    FILENAME=$(openssl x509 -in "$CERTIFICATE_PATH" -hash -noout)
    FILENAME=$FILENAME".0"

    echo "[+] Generated certificate filename is $FILENAME"
    echo "[+] Creating certificate file..."

    openssl x509 -in "$CERTIFICATE_PATH" >> "$FILENAME"
    openssl x509 -in "$CERTIFICATE_PATH"  -text -fingerprint -noout >> "$FILENAME"

    echo "[+] Stoping current ADB server instance..."
    adb kill-server
    adb wait-for-device

    echo "[+] Starting ADB server as root..."
    adb root
    adb disable-verity
    echo "[+] Rebooting device..."
    adb reboot

    adb wait-for-device
    adb root

    adb remount

    echo "[+] Remounting partitions... "
    adb remount

    echo "[+] Pushing certificate to /sdcard/$FILENAME"
    adb -s "$SERIAL_PORT" push "$FILENAME" /sdcard
    echo "[+] Moving certificate ($FILENAME) to /system/etc/security/cacerts..."
    adb -s "$SERIAL_PORT" shell "su 0 mv /sdcard/$FILENAME /system/etc/security/cacerts"
    echo "[+] Granting certificate permissions..."
    adb -s "$SERIAL_PORT" shell "su 0 chmod 644 /system/etc/security/cacerts/$FILENAME"
    echo "[+] Removing local generated certificate..."
    rm "$FILENAME"

else
    echo "[!] Invalid remote device API level!"
    echo "[!] Script aims API-24, API-25 and API-29, but remote are running API-$(adb shell getprop ro.build.version.sdk)"
    echo
    exit 111
fi

echo
echo "[+] Certificate installed as system trusted credential"
echo "[+] Check if you able to see the new certificate listed in 'Settings > Security > Trusted Cert > Systems'"
echo
