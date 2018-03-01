#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH

source include/global_functions.sh


function clear_screen {
  clear
  echo "##########################################################################################################################"
  echo "#                                                                                                                        #"
  echo "#                                                                                                                        #"
  echo "#  Skrypt skanujący sieć / urzędzenie                                                                                    #"
  echo "#  Parametry uruchamiania:                                                                                               #"
  echo "#    ./scanner.sh --scan-all [--update]       #skanuje całą sieć                                                         #"
  echo "#    ./scanner.sh [--update] IP_ADDR          #skanuje pojedynczy adres IP                                               #"
  echo "#    ./scanner.sh --mac [--update] MAC_ADDR   #wyswietla dane adresu MAC                                                 #"
  echo "#    ./scanner.sh --show-ip-details IP_ADDR   #wyswietla dane adresu IP (dane zachowane ze skanowania)                   #"
  echo "#                                                                                                                        #"
  echo "#    --update #aktualizuje dane w systemie sky-desk.eu                                                                   #"
  echo "#                                                                                                                        #"
  echo "#   include/config.scanner <--- Plik konfiguracyjny skanera                                                              #"
  echo "#                                                                                                                        #"
  echo "#  Postępuj zgodnie z instrukcjami wyświetlanymi na ekranie                                                              #"
  echo "#  W razie problemów skontaktuj się z pomocą techniczną lub skorzystaj                                                   #"
  echo "#  pomocy on-line pod adresem:                                                                                           #"
  echo "#    https://sky-desk.eu/help                                                                                            #"
  echo "#                                                                                                                        #"
  echo "##########################################################################################################################"
  echo ""
  echo ""
}


clear_screen

if [ "$EUID" -ne 0 ]
  then
  echo "=========================================="
  echo "=                                        ="
  echo "= Musisz uruchomić mnie jako root !!!    ="
  echo "=                                        ="
  echo "=========================================="
  echo ""
  if [ -f scanner.flag ]
    then
    rm scanner.flag
    fi
  exit
fi


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
> $SCRIPTPATH/.data/log.txt
> $SCRIPTPATH/.data/debug.txt
echo "# temporary scan settings" > $SCRIPTPATH/include/temporary.settings



if [ "$1" == "--unlock" ]
    then
        if [ -f "scanner.flag" ]
        then
        rm -rf scanner.flag
        fi
    echo "==================================="
    echo "=                                 ="
    echo "= Skaner odblokowany              ="
    echo "=                                 ="
    echo "==================================="
    echo ""
    exit
    fi


# sprawdzanie czy jest juz uruchomiona jedna instancja
if [ -f "scanner.flag" ]
then
  echo "==================================="
  echo " Ten proces jest już uruchomiony"
  echo " Jeśli uważasz inaczej to usuń flagę"
  echo " scanner.flag"
  echo " Albo uruchom z parametrem:"
  echo " ./scanner.sh --unlock"
  echo "==================================="
  echo ""
  exit
fi

> scanner.flag



# wyswietlanie danych podjedynczego adresu IP
# dane pobierane z wczesniejszego skanowania
if [ "$1" == "--show-ip-details" ]
    then
    get_details_from_nmap "$SCRIPTPATH/.data/IP/$2.nmap"
    rm scanner.flag
    exit 1
    fi



if [ ! -f $SCRIPTPATH/include/config ]
    then
    echo "-------------------------------------"
    echo "-             INFO"
    echo "- Bez pliku 'include/config' nie będzie można zaktualizować"
    echo "- danych w systemie Sky-Desk"
    echo "- Uruchom najpierw ./setup.sh i skonfiguruj parametry"
    echo "-"
    echo "-------------------------------------"
    fi



if [ "$1" == "--scan-all" ]
	then
    echo "Skanowanie calej sieci"
    # scan_network
    if [ "$2" == "--update" ]
      then
        echo "" > $SCRIPTPATH/include/temporary.settings
        echo "temp_key=$key" >> $SCRIPTPATH/include/temporary.settings
        echo "temp_update='true'" >> $SCRIPTPATH/include/temporary.settings
        echo ""
        echo "Aktualizuje sky-desk.eu"
        for plik in `ls $SCRIPTPATH/.data/IP/*.nmap`
            do
            get_details_from_nmap $plik
            done
      fi
  fi




  if [ "$1" == "--mac" ]
  	then
      debug "Skanowanie po adresie MAC"
      if [ "$2" == "--update" ]
        then
          mac=`fix_mac $3`
          debug "Poprawiony MAC=$mac"
          ip=`get_ip_from_mac $mac`
          debug "Mam adres IP=$ip i będę aktualizował bazę po MAC"
          echo "temp_key='MAC'" >> $SCRIPTPATH/include/temporary.settings
          echo "temp_update='true'" >> $SCRIPTPATH/include/temporary.settings
          echo "Aktualizuje sky-desk.eu"
        else
          mac=`fix_mac $2`
          ip=`get_ip_from_mac $mac`
          debug "Mam adres IP=$ip i będę aktualizował bazę po MAC"
          debug "Poprawiony MAC=$mac"

        fi
        get_details_from_ip $ip
    fi




if [ "$1" != "--scan-all" ] && [ "$1" != "--mac" ] && [ "$1" != "" ]
  then
    if [ "$1" == "--update" ]
      then
        debug "Będę aktualizował bazę po adresie IP=$2"
        echo "temp_key='IP'" >> $SCRIPTPATH/include/temporary.settings
        echo "temp_update='true'" >> $SCRIPTPATH/include/temporary.settings
        echo "Skanowanie jednego IP i aktualizacja w sky-desk.eu"
        get_details_from_ip $2
      else
        debug "Skanowanie jednego adresu IP: $1"
        echo "temp_key='IP'" >> $SCRIPTPATH/include/temporary.settings
        echo "Skanowanie jednego adresu IP: $1"
        get_details_from_ip $1
      fi
  fi


echo ""
echo ""

rm $SCRIPTPATH/include/temporary.settings
rm scanner.flag
