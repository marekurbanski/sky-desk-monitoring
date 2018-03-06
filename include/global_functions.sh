#!/usr/bin/env bash

if [ ! -d "$SCRIPTPATH/.data" ]
    then
    mkdir $SCRIPTPATH/.data
    mkdir $SCRIPTPATH/.data/IP
    chmod -R 777 $SCRIPTPATH/.data
    fi

echo '' > $SCRIPTPATH/.data/log.txt


function debug {

    echo $1 >> $SCRIPTPATH/.data/debug.txt

    }

function fix_mac {

    fixed_mac=""
    for i in {1..6}
        do
        part=`echo $1 | cut -d':' -f $i`
        if [ ${#part} == 1 ]
        then
            fixed_mac="${fixed_mac}0${part}:"
        else
        fixed_mac="$fixed_mac$part:"
        fi
        done

    echo $fixed_mac | rev | cut -d':' -f2-10 | rev | awk '{print toupper($0)}'
    }




function get_data_from_server {

    if [ ! -f ${TMPDIR}sky_desk_server ] && [ ! -f $SCRIPTPATH/include/config ]
        then
        echo "-------------------------------------"
        echo "-             INFO"
        echo "- Bez pliku 'include/config' nie będzie można zaktualizować"
        echo "- danych w systemie Sky-Desk"
        echo "- Uruchom najpierw ./setup.sh i skonfiguruj parametry"
        echo "-"
        echo "-------------------------------------"
        exit
        fi

    sid='config'
    user_id=$1
    data=`date +%Y-%m-%d`
    crc="$1$3$2$sid$data"
    #crc_md5=`echo -n $crc | md5sum | cut -d" " -f1`
    if [ -n "$(command -v md5)" ]
	    then
	    crc_md5=`echo -n $crc | md5 | cut -d" " -f1`
	    fi

    if [ -n "$(command -v md5sum)" ]
        then
	    crc_md5=`echo -n $crc | md5sum | cut -d" " -f1`
	    fi

    if [ -n "$(command -v md5sha1sum)" ]
        then
	    crc_md5=`echo -n $crc | md5sha1sum | cut -d" " -f1`
	    fi

    value=$3
    value=$(python -c "import urllib, sys; print urllib.quote(sys.argv[1])"  "$value")
    if [ -f ${SCRIPTPATH}sky_desk_server ]
        then
        url=`cat ${TMPDIR}sky_desk_server`
        fi

    if [ "$url" = "" ] && [ -f ${SCRIPTPATH}sky_desk_server ]
        then
        url=`cat ${SCRIPTPATH}sky_desk_server`
        fi


    if [ -f ${SCRIPTPATH}/include/config.scanner ]
        then
        source ${SCRIPTPATH}/include/config.scanner
        fi

    if [ "$url" = "" ]
        then
        url='https://sky-desk.eu'
        fi

    url2=`echo $url | sed 's~http[s]*://~~g'`
    r=`curl -s -k "https://$url2/api/?act=monitoring&user_id=$user_id&sid=$sid&crc=$crc_md5&value=$value&url=$url&default_item_group=$default_item_group"`
    # echo "-->$r<--"
    rr=`echo $r | xargs`

    tmp=`echo $rr | cut -d' ' -f1 | xargs`
    if [ "$tmp" == "!!!" ]
        then
        rr=""
        fi

    echo "$rr"
    }


function check_package {

    # res=`dpkg -l $1 | grep $1 | wc -l`
    # if [ $res == '1' ]
    echo ""
    echo "------------------------------- check --------------------------------"
    echo "|                                                                     |"
    echo "|        Sprawdzam czy jest zainstalowana paczka $1"
    echo "|                                                                     |"
    echo "----------------------------------------------------------------------"
    echo ""
    if [ -n "$(command -v $1)" ]
    then
        #true
        echo "OK - Paczka '$1' jest już zainstalowana"
        return 0
    else
        #false
        echo "Nie znalazłem paczki '$1' - będę ją instalował"
	if [ -n "$(command -v apt-get)" ]
	    then
	    if [ "$1" = "nc" ]
	        then
	        $1="netcat"
	    fi

	    if [ -n "$(command -v sudo)" ]
		then
		    echo "Używam apt-get. Podaj hasło roota..."
		    sudo apt-get update
		    sudo apt-get install $1
		else
		    apt-get update
		    apt-get install $1
		fi
	    fi

	if [ -n "$(command -v yum)" ]
	    then
	    if [ -n "$(command -v sudo)" ]
		then
		echo "Używam yum. Podaj hasło roota..."
	        sudo yum install $1
		else
		yum install $1
		fi
	    fi


	if [ -n "$(command -v brew)" ]
	    then
	    if [ "$1" = "md5" ]
	        then
	        $1="md5sha1sum"
	        fi
	    if [ "$1" = "md5sum" ]
	        then
	        $1="md5sha1sum"
	        fi

	    brew install $1
	    fi

        return 1
    fi
    }


function ProgressBar {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done

    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    printf "\rPostęp : [${_fill// /#}${_empty// /-}] ${_progress}%%"
    }


function refresh_arp {
  debug 'Jestem w refresh_arp()'
  for ip in `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
    do
    debug "Znaleziony adres IP=$ip"
    range=`echo $ip | cut -d'.' -f1-3`
    for i in $(seq 1 1 255)
      do
        ProgressBar $i 255
        addr="$range.${i}"
        debug "Pinguję adres $addr"
        ping -c3 -t2 -W 500 $addr 2>&1 >> $SCRIPTPATH/.data/log.txt
      done
      echo ""
    done

}


# funkcja aktuaizuje dane + pyta
function update_data_in_database {
    key=$1
    key_value=$2
    variable=$3
    value=$4
    descr=$5
    server_result='OK'

    if [ ! -f $SCRIPTPATH/include/config ]
        then
        echo "-------------------------------------"
        echo "-             INFO"
        echo "- Bez pliku 'include/config' nie będzie można zaktualizować"
        echo "- danych w systemie Sky-Desk"
        echo "- Uruchom najpierw ./setup.sh i skonfiguruj parametry"
        echo "-"
        echo "-------------------------------------"
        exit
        fi


    source $SCRIPTPATH/include/config

    # nie aktualizujemy pustych danych
    if [ "$value" != "" ] || [ "$variable" != "" ]
        then

        if [ "$ineractive" == "true" ]
            then
            echo "------------------------------- Pytanie ----------------------------------------- "
            read -p "Czy zaktualizować '$descr' => '$value' ? [t/N]" -n 1 -r
            echo ""
            echo ""
            if [[ $REPLY =~ ^[Tt]$ ]]
                then
                server_result=$(get_data_from_server $user_id $api_key "update_data^$key^$key_value^$variable^$value^$default_item_group")
                fi
          else
            server_result=$(get_data_from_server $user_id $api_key "update_data^$key^$key_value^$variable^$value^$default_item_group")
            fi

        fi

    if [ "$server_result" != "OK" ]
        then
        echo "!!!!!!!!!!! Błąd podczas aktualizacji danych !!!!!!!!!!!!!!"
        echo "$server_result"
        fi
    }


# pobiera dane szczegółowe z zebranych danych z nmap
function get_details_from_nmap {

  if [ -f $1 ]
    then
      system=`cat $1 | grep "Running:" | cut -d":" -f2 | head -n1 | xargs`
      osdetails=`cat $1 | grep "OS details:" | cut -d":" -f2 | head -n1 | xargs`
      mac=`cat $1 | grep "MAC Address:" | cut -d":" -f2-10 | head -n1 | xargs | cut -d" " -f1`
      type=`cat $1 | grep "Device type:" | cut -d":" -f2 | head -n1 | xargs`
      info=`cat $1 | grep "Service Info:" | cut -d":" -f2-100 | head -n1 | xargs`
      name=`cat $1 | grep -i netbios | cut -d":" -f3 | cut -d',' -f1 | grep -v open | head -n1 | xargs`
      if [ "$name" == "" ]
        then
        name=`cat $1 | grep -i netbios | cut -d":" -f3 | cut -d',' -f1 | grep -v open | head -n2 | xargs`
        fi

      if [ "$mac" == "" ]
        then
          plik=`echo $1 | rev | cut -d"." -f2-100 | rev `
          mac=`cat $plik.mac | xargs`
        fi
      ip=`echo $1 | rev | cut -d'.' -f2-5 | cut -d '/' -f1 | rev`
      echo "Name = $name"
      echo "IP = $ip"
      echo "System = $system"
      echo "OS details = $osdetails"
      echo "MAC = $mac"
      echo "Type = $type"
      echo "Info = $info"
      echo "Porty"
      cat $1 | grep "/tcp" | grep -v "Discovered"


      source $SCRIPTPATH/include/temporary.settings
      source $SCRIPTPATH/include/config

      if [ "$temp_update" == "true" ]
        then
        debug "Zaczynam aktualizacje danych w systemie $host_name"


        if [ "$temp_key" == "MAC" ]
            then
            key_value=$mac
            debug "Kluczem jest MAC=$mac"
            assetID=$(get_data_from_server $user_id $api_key "check_mac^$mac")
            if [ "$assetID" == "" ]
                then
                assetID=$(get_data_from_server $user_id $api_key "add_host^$host_name^$mac^$ip^$system^$desc^$default_item_group")
                assetID=$(get_data_from_server $user_id $api_key "check_mac^$mac")
                echo "Nie znalazłem tego urządzenia po MAC ($mac), więc je dodałem pod ID = $assetID"
                debug "Nie znalazłem tego urządzenia po MAC ($mac), więc je dodałem pod ID = $assetID"
                else
                echo "Znalazłem takie urządzenie w systemie po adresie MAC (ID=$assetID) :) "
                debug "Znalazłem takie urządzenie w systemie po adresie MAC (ID=$assetID) :) "
                fi
            fi


        if [ "$temp_key" == "IP" ]
            then
            key_value=$ip
            debug "Kluczem jest IP=$ip"
            assetID=$(get_data_from_server $user_id $api_key "check_ip^$ip")
            if [ "$assetID" == "" ]
                then
                assetID=$(get_data_from_server $user_id $api_key "add_host^$host_name^$mac^$ip^$system^$desc^$default_item_group")
                assetID=$(get_data_from_server $user_id $api_key "check_mac^$mac")
                echo "Nie znalazłem tego urządzenia po IP ($ip), więc je dodałem pod ID = $assetID"
                debug "Nie znalazłem tego urządzenia po IP ($ip), więc je dodałem pod ID = $assetID"
                else
                echo "Znalazłem takie urządzenie w systemie po adresie IP (ID=$assetID) :) "
                debug "Znalazłem takie urządzenie w systemie po adresie IP (ID=$assetID) :) "
                fi
            fi

        if [ "$assetID" != "" ]
            then
            debug "Aktualizacja wlasciwa po $temp_key"

            vendor=$(get_data_from_server $user_id $api_key "check_vendor^$mac")

            # update_data_in_database key key_value variable value descr
            update_data_in_database $temp_key "$key_value" 'title' "$name" 'Nazwa urzadzenia'
            update_data_in_database $temp_key "$key_value" 'ip_address' "$ip" 'Adres IP'
            update_data_in_database $temp_key "$key_value" 'mac_address' "$mac" 'Adres MAC'
            update_data_in_database $temp_key "$key_value" 'vendor' "$vendor" 'Producent'
            update_data_in_database $temp_key "$key_value" 'system_type' "$system" 'System'
            update_data_in_database $temp_key "$key_value" 'description' "$info" 'Opis'
            update_data_in_database $temp_key "$key_value" 'location' "$location" 'Lokalizacja'

            else
            echo "Wystapil blad - nie potrafie wyszukac sprzetu ani go dodac :((("
            rm scanner.flag
            exit
            fi

        fi

      echo ""
      echo ""

    else
    echo "#####################################################################"
    echo "#"
    echo "# Nie mam żadnych danych, uruchom skanowanie pojedynczej maszyny"
    echo "# lub skanowanie całej sieci."
    echo "#"
    echo "#####################################################################"
    fi

}


# pobiera dane nmap z adresu IP
# i zapisuje do katalogu IP
function get_data_from_ip {
  scan='TRUE'

  if [ -f "$SCRIPTPATH/.data/IP/$1.nmap" ]
    then
    if [[ $(find "$SCRIPTPATH/.data/IP/$1.nmap" -mtime +1 -print) ]]
        then
        scan='TRUE'
        else
        scan='FALSE'
        fi
    fi

  if [ "$scan" == "TRUE" ]
      then
      i=$2
      max=$3
      ProgressBar $i $max
      echo "nmap1" >> $SCRIPTPATH/.data/log.txt
      debug "nmap1"
      nmap -O $1 > $SCRIPTPATH/.data/IP/$1.nmap
      let i=$i+1
      ProgressBar $i $max
      echo "nmap2" >> $SCRIPTPATH/.data/log.txt
      debug "nmap2"
      nmap -sL $1 >> $SCRIPTPATH/.data/IP/$1.nmap
      let i=$i+1
      ProgressBar $i $max
      echo "nmap3" >> $SCRIPTPATH/.data/log.txt
      debug "nmap3"
      nmap -T4 -A -v $1 >> $SCRIPTPATH/.data/IP/$1.nmap
      let i=$i+1
      ProgressBar $i $max
      echo "nmap4" >> $SCRIPTPATH/.data/log.txt
      debug "nmap4"
      nmap -O -v -A -sV --version-intensity 5 $1 >> $SCRIPTPATH/.data/IP/$1.nmap
    else
      let i=$2+2
      max=$3
      ProgressBar $i $max
      ProgressBar 5 5
      fi
}



function get_details_from_ip {
  debug 'Jestem w get_details_from_ip()'
  debug "Uruchamiam get_data_from_ip $1 1 4"
  get_data_from_ip $1 1 5
  ProgressBar 5 5
  echo "";echo "";
  debug 'Uruchamiam get_details_from_nmap()'
  get_details_from_nmap "$SCRIPTPATH/.data/IP/$1.nmap"
  mac=`arp $1 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
  fix_mac $mac > $SCRIPTPATH/.data/IP/$1.mac
  debug 'Wychodze z get_details_from_ip'
  echo ""
  echo ""
}


# sprawdzanie czy instanie katalog .data
# jesli nie to musze go utworzyć do tymczasowych zmiennych
if [ ! -d "$SCRIPTPATH/.data" ]
    then
    mkdir $SCRIPTPATH/.data
    mkdir $SCRIPTPATH/.data/IP
    chmod 777 $SCRIPTPATH/.data
    fi


# sprawdzanie czy jest juz plik konfiguracyjny
# jesli nie to go tworze
if [ ! -f "$SCRIPTPATH/include/config.scanner" ]
    then
    if [ -f "$SCRIPTPATH/include/config" ]
        then
        source $SCRIPTPATH/include/config
        fi
    clear_screen
    echo "#!/bin/bash" > $SCRIPTPATH/include/config.scanner
    echo "##################################################" >> $SCRIPTPATH/include/config.scanner
    echo "#                                                #" >> $SCRIPTPATH/include/config.scanner
    echo "# Config file for scanner                        #" >> $SCRIPTPATH/include/config.scanner
    echo "#                                                #" >> $SCRIPTPATH/include/config.scanner
    echo "##################################################" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "# Zmienna globalna - ustawia czy scanner jest aktywny czy nie" >> $SCRIPTPATH/include/config.scanner
    echo "enabled=true" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "# Grupa urządzeń w Sky-Desk do której będą przypisane nowe urządzenia" >> $SCRIPTPATH/include/config.scanner
    echo "default_item_group=$default_item_group_id" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "# Lokalizacja sprzetu" >> $SCRIPTPATH/include/config.scanner
    echo "location='Serwerownia'" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "# Po ustawieni zmiennej na true, scanner za każdym razem zapyta się czy zaktualizować poszczególne dane w systemie Sky-Desk" >> $SCRIPTPATH/include/config.scanner
    echo "ineractive=true" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "# [scan-all]" >> $SCRIPTPATH/include/config.scanner
    echo "# Aktualizuj dane porówbując adres MAC / IP" >> $SCRIPTPATH/include/config.scanner
    echo "key='MAC'" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner
    echo "" >> $SCRIPTPATH/include/config.scanner


    for ip in `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
    	do
    	echo "Moj adres IP = $ip"
    	range=`echo $ip | cut -d'.' -f1-3`
    	addr="$range.255"
    	range="range=$range.*"
    	echo "Zakres IP = $range"
    	ping -c 10 -b $addr
      echo "Utworzyłem plik konfiguracyjny"
      echo "Sprawdź czy są poprawne parametry i uruchom ponownie $0"
      echo ""
      echo "koniec..."
      echo ""
    	done
    chmod 777 $SCRIPTPATH/include/config.scanner
    chmod 777 $0
fi

# ladawoanie configa
source $SCRIPTPATH/include/config.scanner
# sprawdzanie czy w konfigu nie jest pypadkiem wylaczona akacja
if [ "$enabled" != "true" ]
  then
    echo "==================================="
    echo " Wyłączony w config.scanner"
    echo " enabled=false -> enabled=true"
    echo "==================================="
    echo ""

    exit 1
  fi



function get_ip_from_mac {

  rm -rf $SCRIPTPATH/.data/ip_mac.txt
  debug 'Skanuje tablice ARP do mac.tmp'
  arp -a | grep -v 'incomplete' > $SCRIPTPATH/.data/mac.tmp
  debug "Skanowanie zakończone, będę tworzył plik ip_mac.txt"
  while IFS='' read -r line || [[ -n "$line" ]]
	    do
  	    ip=`echo $line | cut -d"(" -f2 | cut -d")" -f1`
	    mac_tmp=`echo $line | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
	    mac=`fix_mac $mac_tmp`
	    echo "${ip},${mac}" >> $SCRIPTPATH/.data/ip_mac.txt
	    done < "$SCRIPTPATH/.data/mac.tmp"
  mac=`fix_mac $1`
  debug "Plik ip_mac.txt utworzony, sprawdzę czy istenieje IP dla MAC=$mac"
  ip=`cat $SCRIPTPATH/.data/ip_mac.txt | grep $mac | cut -d',' -f1 | xargs`
  if [ "$ip" == "" ]
    then
      debug 'Nie znalazłem żadnego IP, będę odświeżał tablicę ARP: refresh_arp()'
      refresh_arp
      debug "Tablica ARP odświeżona, sprawdzam jeszcze raz czy istnieje MAC=$mac"
      ip=`arp -a | tr '[:upper:]' '[:lower:]' | grep $mac | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | xargs`
      debug "Znalazłem IP=$ip"
      echo $ip
  else
    debug "Znalazłem IP=$ip :)))"
    echo $ip
    fi
}


function valid_ip()
  {
      local  ip=$1
      local  stat=1

      if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
          OIFS=$IFS
          IFS='.'
          ip=($ip)
          IFS=$OIFS
          [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
              && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
          stat=$?
      fi
      return $stat
  }



function scan_network {

  rm -rf $SCRIPTPATH/.data/ip_mac.txt
  echo "Proces 1 z 2"
  refresh_arp
  arp -a | grep -v 'incomplete' > $SCRIPTPATH/.data/ip_lista.txt

	if [ -d "$SCRIPTPATH/.data/IP" ]
	    then
	    rm -rf $SCRIPTPATH/.data/IP/*
	    fi


  echo "Proces 2 z 2"
  max=`cat $SCRIPTPATH/.data/ip_lista.txt | wc -l | xargs`
  let i=0
  let max=$max*4
  while IFS='' read -r line || [[ -n "$line" ]]
	    do
	    ip=`echo $line | cut -d"(" -f2 | cut -d")" -f1`
	    mac_tmp=`echo $line | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
	    mac=`fix_mac $mac_tmp`
	    echo "${ip},${mac}" >> $SCRIPTPATH/.data/ip_mac.txt

      if [ ! -d "$SCRIPTPATH/.data" ]
        then
          mkdir $SCRIPTPATH/.data
          mkdir $SCRIPTPATH/.data/IP
        fi

      let i=$i+1
      echo "get_data_from_ip $ip $i $max" >> $SCRIPTPATH/.data/log.txt
	    get_data_from_ip $ip $i $max
	    echo $mac > $SCRIPTPATH/.data/IP/$ip.mac
      done < "$SCRIPTPATH/.data/ip_lista.txt"



      for p in `ls .data/IP/*.nmap`
          do
          echo "get_details_from_nmap $p" >> $SCRIPTPATH/.data/log.txt
          get_details_from_nmap $p 2>&1 >> $SCRIPTPATH/.data/log.txt
          done

  rm -rf ip_lista.txt
  }

# rm -rf tmp
