#!/usr/bin/env bash

# Copyright (C) 2020 BizarreNULL <jonas.uliana@passwd.com.br>

# Project:     mobile-offsec
# Repository:  https://github.com/BizarreNULL/mobile-offsec
# License:     WTFPL
# Description: Install frida-server on a shit way on remote

FRIDA_LAST_RELEASE_URL="https://github.com/frida/frida/releases/download/12.8.1/frida-server-12.8.1-android-x86.xz"
ARCH=`adb shell getprop ro.product.cpu.abi`
FRIDA_PID=`adb shell pgrep frida`

echo "[+] Checking current device architecture..."

if [ $ARCH != "x86" ]
then
   echo "[!] Invalid device architecture!"
   echo "[!] This script target only x86 devices."

   exit -1
fi

echo "[+] Downloading Frida Server..."
wget $FRIDA_LAST_RELEASE_URL -O /tmp/frida.xz >/dev/null 2>&1
unxz /tmp/frida.xz

if [ ! -z "$FRIDA_PID" ] 
then
   echo "[+] Killing any Frida Server instances on Android device..."
   adb shell "su 0 kill $FRIDA_PID"
fi

echo "[+] Pushing binaries to remote..."
adb push /tmp/frida /data/local/tmp
echo "[+] Granting execute privileges..."
adb shell "su 0 chmod 077 /data/local/tmp/frida"
echo "[+] Starting Frida Server as root user..."
'adb shell "su 0 ./data/local/tmp/frida"'&