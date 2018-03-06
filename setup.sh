#!/usr/bin/env bash

###############################################################################################
#####                                                                                    ######
#####                          Funkcje do monitoringu                                    ######
#####                                                                                    ######
#####                                                                                    ######
#####        Uruchom "./setup.sh"                                                        ######
#####                "./setup.sh --update" - aktualizacja, nie wymaga potwierdzenia      ######
#####                ".setup.sh --help"    - wyświetlenie pomocy                         ######
#####                ".setup.sh --config"  - uruchomienie konfiguratora                  ######
#####                                                                                    ######
###############################################################################################

#### Instalacja:
#### wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh


########### wymagane pakiety ##############
##
##	curl
##	md5sum
##  md5
##  md5sha1sum
##	free
##	python
##	snmp
##	nc
###


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH


function clear_screen {
      clear
      echo "######################################################################################################"
      echo "#                                                                                                    #"
      echo "#                                                                                                    #"
      echo "#  Instalator monitoringu                                                                            #"
      echo "#  ./setup.sh --help      # wyświetlenie pomocy                                                      #"
      echo "#  ./setup.sh --config    # uruchomienie konfiguratora                                               #"
      echo "#                                                                                                    #"
      echo "#  Postępuj zgodnie z instrukcjami wyświetlanymi na ekranie                                          #"
      echo "#  W razie problemów skontaktuj się z pomocą techniczną lub skorzystaj                               #"
      echo "#  pomocy on-line pod adresem:                                                                       #"
      echo "#                                                                                                    #"
      echo "#    https://sky-desk.eu/help                                                                        #"
      echo "#  lub:                                                                                              #"
      echo "#    https://sky-desk.eu/help?topic=13-konfiguracja-monitorowania-serwera                            #"
      echo "#                                                                                                    #"
      echo "######################################################################################################"
      echo "";echo "";

}

function check_needed_packages {

      check_package "curl"
      check_package "md5sum"
      check_package "python"
      #check_package "snmp"
      check_package "nmap"
      # check_package "free" -- paczka przeniesiona do miejsca instalacji

}


#################################################################################################
# instalacja skryptow
# zmiana nazwy z monitoring.sh na functions.sh
# instalacja przykladowych skryptow
# tworzenie katalogow

my_name=`echo $0 | rev | cut -d'/' -f1 | rev`

update='no'



if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "?" ]
      then
      cat README.md
      exit 1
      fi


if [ "$1" = "--update" ]
      then
      update='yes'
      force='yes'
      fi


if [ "$update" = "yes" ]
      then

      if [ -f "${TMPDIR}sky_desk_server" ]
            then
            mv ${TMPDIR}sky_desk_server $SCRIPTPATH/include/sky_desk_server
            sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
            fi

      if [ -f sky_desk_server ]
            then
            mv sky_desk_server include/
            sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
            fi

      if [ -f "${TMPDIR}sky_desk_server" ]
            then
            sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
            fi

        sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server


      vold=`cat version.txt | xargs`
      rm -rf version.txt
      wget --no-check-certificate https://sky-desk.eu/download/monitoring/version.txt
      vnew=`cat version.txt | xargs`

      clear_screen
      if [ "$vnew" = "$vold" ]
            then
            echo ""
            echo ""
            echo " Posiadasz aktualną wersję :)"
            echo ""
            echo ""
            echo ""
            exit
            fi
      echo ""
      echo "================================================================================"
      echo ""
      echo "Jest nowa aktualizacja ( z wersji $vold do wersji $vnew )"
      echo ""

      if [ ! -d "archive" ]
          	    then
          	    mkdir archive
          	    fi
      data=`date +%Y-%m-%d`

      if [ ! -d "include" ]
                then
                mkdir include
                fi


      if [ -f "include/functions.sh" ]
              then
              mv include/functions.sh archive/functions_$data
              mv include/global_functions.sh archive/global_functions_$data
              fi

      rm -rf setup.sh
      rm -rf include/functions.sh
      rm -rf scanner.sh
      rm -rf include/global_functions.sh

      wget --no-check-certificate https://sky-desk.eu/download/monitoring/include/functions.sh
      wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh
      wget --no-check-certificate https://sky-desk.eu/download/monitoring/scanner.sh
      wget --no-check-certificate https://sky-desk.eu/download/monitoring/include/global_functions.sh

      if [ -f README.md ]
        then
        rm -rf README.md
        fi
      wget --no-check-certificate https://sky-desk.eu/download/monitoring/README.md

      chmod 777 setup.sh
      chmod 777 scanner.sh
      mv functions.sh include/functions.sh
      mv global_functions.sh include/global_functions.sh

      rm -rf functions.sh*
      rm -rf global_functions.sh*

      clear_screen
      echo "Gotowe... :)"
      echo ""

      host_name=`echo $HOSTNAME`
      ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
      mac=`ifconfig | grep "$ip" -B 3 -A 3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`

      source $SCRIPTPATH/include/config

      if [ "$default_item_group_id" == "" ]
            then
            host_name=`echo $HOSTNAME`
            ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
            mac=`ifconfig | grep "$ip" -B 3 -A 3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`

            default_item_group=$(get_data_from_server $user_id $api_key "check_default_asset_group^$mac")
            if [ "$default_item_group" == "" ]
                then
                clear_screen
                echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
                echo ""
                echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
                echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
                read -p "Podaj grupę lub wciśnij ENTER aby anulowac [ np: 1 ] = " default_item_group
                echo ""
              else
                clear_screen
                echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
                echo ""
                echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
                echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
                echo "Automatycznie dopasowałem grupę ===> $default_item_group <=== - potwierdź jej poprawnosc"
                read -p "Wpisz grupę $default_item_group lub wciśnij ENTER aby anulowac [ $default_item_group ] = " default_item_group
                echo ""

                fi
            fi

        if [ "$default_item_group" != "" ]
            then
            echo "default_item_group_id='$default_item_group'" >> include/config
            fi


      echo ""
      exit
      fi



source $SCRIPTPATH/include/functions.sh

install_now='0'
if [ ! -d "include" ] || [ ! -f "include/config" ] || [ ! -f "check.sh" ] || [ "$1" == "--config" ]
        then
        install_now='1'
        fi

sky_desk_server_path=${TMPDIR}sky_desk_server

if [ -f "${TMPDIR}sky_desk_server" ]
    then
    mv ${TMPDIR}sky_desk_server $SCRIPTPATH/include/sky_desk_server
    sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
    fi

if [ -f sky_desk_server ]
    then
    mv sky_desk_server include/
    sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
    fi

if [ -f "${TMPDIR}sky_desk_server" ]
    then
    sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server
    fi

sky_desk_server_path=$SCRIPTPATH/include/sky_desk_server

if [ "$install_now" == "1" ]
        then
        clear_screen
        echo "########################################################################### "
        echo "#                                                                "
        echo "#  Instalacja skryptu monitoringu                                "
        echo "#                                                                "
        echo "########################################################################### "


        check_needed_packages

        # tworznie katalogu z archiwami
        if [ ! -d "archive" ]
                then
                mkdir archive
                fi

        if [ ! -d "include" ]
                then
                mkdir include
                fi


        if [ ! -f "include/functions.sh" ]
                then
              	wget --no-check-certificate https://sky-desk.eu/download/monitoring/include/functions.sh
                wget --no-check-certificate https://sky-desk.eu/download/monitoring/scanner.sh
                wget --no-check-certificate https://sky-desk.eu/download/monitoring/include/global_functions.sh

                if [ -f README.md ]
                    then
                    rm -rf README.md
                    fi
                 wget --no-check-certificate https://sky-desk.eu/download/monitoring/README.md


              	cat functions.sh > include/functions.sh
                cat global_functions.sh > include/global_functions.sh

              	rm -rf functions.sh
                rm -rf global_functions.sh
              	chmod 777 include/functions.sh
                chmod 777 include/global_functions.sh
                chmod 777 scanner.sh

                source $SCRIPTPATH/include/functions.sh
                fi



        if [ -f "include/config" ]
                then
                clear_screen
                echo "Znalazłem poprzedni plik konfiguracyjny, więc go użyję :)"
                source include/config

                server=$server
                url=$url
                companyID=$companyID
                userID=$user_id
                companyAPI=$api_key

                echo "Poprzednie userID = $userID"
                echo "Poprzednie companyAPI = $companyAPI"
                echo "Poprzedni server = $server"
                echo "Poprzedni url = $url"
                echo "Poprzedni user_id = $userID"
                else

            	    if [ -f "check.sh" ]
                        	then
                        	echo "Sprawdzam poprzedni plik check.sh"
                        	userID=`cat check.sh | grep user_id | cut -d "'" -f2`
                        	companyAPI=`cat check.sh | grep api_key | cut -d "'" -f2`

                        	echo "Poprzednie userID = $userID"
                        	echo "Poprzednie companyAPI = $companyAPI"

                        	if [ -f "$sky_desk_server_path" ]
                            	    then
                            	    url=`cat $sky_desk_server_path`
                            	    server=$url
                            	    fi
                        	fi
            	   fi

      while [ "$server" = "" ]
            	do
              clear_screen
            	echo "------------------------------- Pytanie ----------------------------------------- "
            	echo "#  Podaj adres URL servera Sky-Desk z przedrostkiem https lub bez:"
            	echo "#  https://xyz.sky-desk.eu "
            	echo "#  xyz.sky-desk.eu "
            	echo "#   np:  'https://kowalski.sky-desk.eu'"
            	echo "#   lub: 'kowalski.sky-desk.eu'"
            	echo ""
            	read -p "URL = " server
            	done
      echo $server > $sky_desk_server_path
      url=`cat $sky_desk_server_path`
      echo "Ustawiony serwer = $url"

      while [ "$companyID" = "" ]
            	do
            	clear_screen
            	echo "------------------------------- Pytanie ----------------------------------------- "
            	echo "Podaj numer ID firmy z systemu Sky-Desk"
            	echo "Jeśli monitoring ma dotyczyć Twojej firmy lub nie masz dodanych żadnych innych wprowadź '1'"
            	echo ""
            	read -p "Comapny ID = " companyID
            	done

      while [ "$userID" = "" ]
            	do
            	clear_screen
            	echo "------------------------------- Pytanie ----------------------------------------- "
            	echo "Podaj numer ID użytkownika"
            	echo "ID to znajdziesz w Panelu Sterowania, klikając w swojego użytkownika, zazwyczaj dla Administratora powinna ta wartość być równa '1'"
            	echo ""
            	read -p "User ID = " userID
            	done


      while [ "$companyAPI" = "" ]
            	do
            	clear_screen
            	echo "------------------------------- Pytanie ----------------------------------------- "
            	echo "Podaj klucz API użytkownika"
            	echo "Klucz ten znajdziesz w Panelu Sterowania, klikając w swojego użytkownika (nie będzie on widoczny podczas wpisywania, możesz go wkleić)"
            	echo ""
            	read -s -p "Klucz API = " companyAPI
            	done




      # sprawdzanie poprawnosci danych
      r=$(get_data_from_server $userID $companyAPI 'check_credentials^')
      if [ "$r" != "OK" ]
              then
              clear_screen
              echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              echo "!!"
              echo "!!              BŁĄD W AUTORYZACJI"
              echo "!!"
              echo "!!        Sprawdź czy podałeś prawiłowe dane"
              echo "!!"
              echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              exit 1
              fi

      if [ "$r" = "OK" ]
    	then

        if [ "$default_item_group_id" == "" ]
            then
            host_name=`echo $HOSTNAME`
            ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
            mac=`ifconfig | grep "$ip" -B 3 -A 3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`

            default_item_group=$(get_data_from_server $user_id $api_key "check_default_asset_group^$mac")
            if [ "$default_item_group" == "" ]
                then
                clear_screen
                echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
                echo ""
                echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
                echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
                read -p "Podaj grupę lub wciśnij ENTER aby anulowac [ np: 1 ] = " default_item_group
                echo ""
              else
                clear_screen
                echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
                echo ""
                echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
                echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
                echo "Automatycznie dopasowałem grupę ===> $default_item_group <=== - potwierdź jej poprawnosc"
                read -p "Wpisz grupę $default_item_group lub wciśnij ENTER aby anulowac [ $default_item_group ] = " default_item_group
                echo ""

                fi
            fi

    	# poprawne dane - robie plik
    	echo "#!/usr/bin/env bash" > include/config
    	echo "user_id='$userID'" >> include/config
    	echo "api_key='$companyAPI'" >> include/config
    	echo "url='$url'" >> include/config
    	echo "server='$server'" >> include/config
    	echo "companyID='$companyID'" >> include/config
        if [ "$default_item_group" != "" ]
            then
            echo "default_item_group_id='$default_item_group'" >> include/config
            fi




      data=`date +"%Y-%m-%d %H:%M:%S"`
      echo "#!/usr/bin/env bash" > _check.sh
      echo 'source $(dirname $0)/include/config' >> _check.sh
      echo 'source $(dirname $0)/include/functions.sh' >> _check.sh
      echo '' >> _check.sh
      echo 'SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"' >> _check.sh
      echo 'cd $SCRIPTPATH' >> _check.sh
      echo '' >> _check.sh
      clear_screen
      echo '####################################################' >> _check.sh
      echo '## poniżej skrypty monitorujące                   ##' >> _check.sh
      echo "## ostatnia aktualizacja: $data     ##" >> _check.sh
      echo '##                                                ##' >> _check.sh
      echo '## UWAGA, wszyskie testy bez słowa "check"        ##' >> _check.sh
      echo '##        w nazwie będą usunięte !!!!             ##' >> _check.sh
      echo '##                                                ##' >> _check.sh
      echo '####################################################' >> _check.sh
      echo '' >> _check.sh

      if [ -f "check.sh" ]
              then
              echo "" >> _check.sh
              cat check.sh | grep check >> _check.sh
              fi

    	# pobieranie parametrow urzadzania
    	# i sprawdzanie czy nie ma go w bazie juz przypadkiem
    	host_name=`echo $HOSTNAME`
    	ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
    	mac=`ifconfig | grep "$ip" -B 3 -A 3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
    	desc=`uname -a`
    	system=`uname -s`


        assetID=$(get_data_from_server $userID $companyAPI "check_mac^$mac")

    	if [ "$assetID" != "" ]
        	    then
        	    clear_screen
        	    echo "------------------------------- Pytanie ----------------------------------------- "
        	    echo "Znalazłem takie urządzenie (ID=$assetID) w bazie $server"
        	    echo "Czy chcesz usunąć wszystkie aktualne wpisy sprawdzające parametry dla tego urządzenia ???????"
        	    echo ""
        	    read -p "Usunąć wszystkie wpisy dla tego urządzenia: '$mac' ? [t/N]" -n 1 -r
        	    echo ""
        	    if [[ $REPLY =~ ^[Tt]$ ]]
            		    then
            		    wynik=$(get_data_from_server $userID $companyAPI "delete_subitems^$mac^$assetID")
            		    fi
        	    fi

    	while [ "$assetID" = "" ]
        	    do
        	    clear_screen
        	    echo "------------------------------- Pytanie ----------------------------------------- "
        	    echo "Nie znalazłem w bazie urządzenia z tym adresem MAC: $mac"
        	    echo "Podaj ID urządzenia do którego chcesz przypisać monitoring"
        	    echo "ID to znajdziesz otwierając ikonę 'Zasoby sprzętowe' a następnie 'Pokaż zasoby' przy wybranej kategorii"
        	    echo "albo:"
        	    echo "Jeśli chcesz dodać automatycznie dany sprzęt (jego nazwę, IP, MAC itp, wpisz cyfrę '0')"
        	    echo ""
        	    read -p "ID urządzenia = " assetID
        	    done

    	if [ "$assetID" = "0" ]
        	    then
        	    assetID=$(get_data_from_server $userID $companyAPI "add_host^$host_name^$mac^$ip^$system^$desc")
        	    assetID=$(get_data_from_server $userID $companyAPI "check_mac^$mac")
        	    clear_screen
        	    echo "------------------------------- Info -------------------------------------------- "
        	    echo "Dodałem nowe urządzenie do bazy"
        	    echo "Jest ono teraz dostępne jako $host_name pod numerem ID=$assetID"
        	    fi


        echo ""
        echo ""
        # sprawdzanie dyskow
        for d in `df -h | grep -v Filesystem | rev | cut -d'%' -f1 | rev | grep '/'`
                do
                dd=`echo $d | xargs`
                ret=`cat check.sh | grep 'check_hdd_size' | grep "'$dd'" | wc -l | xargs`
                if [ "$ret" = "0" ]
                        then
                        clear_screen
                        echo "------------------------------- Pytanie ----------------------------------------- "
                        read -p "Czy chcesz dodać monitoring zajętości partycji '$dd' ? [t/N]" -n 1 -r
                        echo ""
                        echo ""
                        if [[ $REPLY =~ ^[Tt]$ ]]
                                then
                                sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^90^HDD [% usage] $dd")
                                echo "check_hdd_size $sID '$dd'" >> _check.sh
                                fi
                        fi
                done

    	  # sprawdzanie pamieci ram
        ret=`cat check.sh | grep 'check_memory_usage' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring pamięci RAM ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        check_package "free"
                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^95^Memory usage")
                        echo "check_memory_usage $sID" >> _check.sh
                        fi
                fi

    	  # sprawdzanie CPU
        ret=`cat check.sh | grep 'check_cpu_load' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring obciążenia procesora ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^3^CPU Load")
                        echo "check_cpu_load $sID" >> _check.sh
                        fi
                fi

    	  # sprawdzanie zalogowanych uzytkownikow
        ret=`cat check.sh | grep 'check_logged_users' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring zalogowanych użytkowników ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^0^Logged users")
                        echo "check_logged_users $sID" >> _check.sh
                        fi
                fi

    	  # sprawdzanie MySQLa
        ret=`cat check.sh | grep 'check_mysql_processcount' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring obciążenia bazy MySQL ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        read -p "Podaj użytkownika do MySQLa [ np: root ] = " mysqlUser
                        read -s -p "Podaj hasło $mysqlUser do MySQLa = " mysqlPass
                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^20^MySQL - process count")
                        echo "check_mysql_processcount $sID $mysqlUser $mysqlPass" >> _check.sh

                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^20^MySQL - long process count > 1 min")
                        echo "check_mysql_processcount $sID $mysqlUser $mysqlPass" >> _check.sh
                        fi
                fi


    	  # sprawdzanie uptime w dniach
        ret=`cat check.sh | grep 'check_uptime_days' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring uptime ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        read -p "Podaj minimalną liczbę dni [ np: 7 ] = " min_days
                        read -p "Podaj maksymalną liczbę dni [ np: 365 ] = " max_days
                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^$min_days^$max_days^Uptime [dni]")
                        echo "check_uptime_days $sID" >> _check.sh
                        fi
                fi


    	  # sprawdzanie transferu sieciowego
        ret=`cat check.sh | grep 'check_lan_interface_tx' | wc -l | xargs`
        if [ "$ret" = "0" ]
                then
                clear_screen
                echo "------------------------------- Pytanie ----------------------------------------- "
                echo ""
                read -p "Czy chcesz dodać monitoring transferu sieciowego TX/RX ? [t/N]" -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Tt]$ ]]
                        then
                        for i in `ip link show | grep 'state' | cut -d':' -f 2 | grep -v 'lo'`
                                do
                                interface=`echo $i | xargs`
                                read -p "Dodać interfejs '$interface' ? [t/N]" -n 1 -r
                                echo ""
                                if [[ $REPLY =~ ^[Tt]$ ]]
                                        then
                                        echo "Dostępne interfejsy sieciowe:"
                                        ip link show | grep 'state' | cut -d':' -f 2 | grep -v 'lo'

                                        read -p "Podaj minimalne wysycenie pobierania [kbitów/s] dla $interface w kb [ np: 0 ] = " min_rx
                                        read -p "Podaj maksymalne wysycenie pobierania [kbitów/s] dla $interface w kb [ np: 1024 ] = " max_rx
                                        read -p "Podaj minimalne wysycenie wysyłania [kbitów/s] dla $interface w kb [ np: 0 ] = " min_tx
                                        read -p "Podaj maksymalne wysycenie wysyłania [kbitów/s] dla $interface w kb [ np: 1024 ] = " max_tx

                                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^$min_tx^$max_tx^$interface TX [kBitów/s]")
                                        echo "check_lan_interface_tx $sID '$interface'" >> _check.sh
                                        sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^$min_rx^$max_rx^$interface RX [kBitów/s]")
                                        echo "check_lan_interface_rx $sID '$interface'" >> _check.sh
                                        fi
                                 done
                        fi
                fi


       # sprawdzanie ilosci uruchomionych procesow w pamieci
       ret=`cat check.sh | grep 'check_running_process_count' | wc -l | xargs`
       clear_screen
        if [ "$ret" != "0" ]
                then
                echo "INFO: Lista poniższych procesów jest już monitorowana:"
                cat check.sh | grep 'check_running_process_count' | grep -v '#'
                fi

    	echo ""
    	echo "------------------------------- Pytanie ----------------------------------------- "
    	echo ""
    	read -p "Czy chcesz dodać sprawdzanie liczby otwartych procesów ? [t/N]" -n 1 -r
    	echo ""
    	if [[ $REPLY =~ ^[Tt]$ ]]
        	    then
        	    while [ "$processName" != "0" ]
        		        do
                		clear_screen
                		echo "------------------------------- Pytanie ----------------------------------------- "
                		echo ""
                		echo "Podaj nazwę procesu którego liczbę uruchomień chcesz monitorować [ jeśli nie chcesz dodawać więcej portów wpisz '0' lub naciśnij ENTER bez wpisywania niczego ]"
                		read -p "Nazwa procesu = " processName
                		if [ "$processName" = "" ]
                    		    then
                    		    processName="0"
                    		    fi
                		if [ "$processName" != "0" ]
                    		    then
                    		    clear_screen
                    		    echo "------------------------------- Pytanie ----------------------------------------- "
                    		    echo ""
                    		    read -p "Podaj minimalną liczbę wystąpień danego procesu = " min_count
                    		    read -p "Podaj maksymalną liczbę wystąpień danego procesu = " max_count

                    			  sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^$min_count^$max_count^Uruchomionych: $processName")
                    		    echo "check_running_process_count $sID '$processName'" >> _check.sh
                    		    fi
                		done
        	    fi
    	fi


    	# sprawdzanie otwartych portów
      clear_screen
      ret=`cat check.sh | grep 'check_port_open' | wc -l | xargs`
      if [ "$ret" != "0" ]
                then
                echo "INFO: Poniższe porty są już monitorowane:"
                cat check.sh | grep 'check_port_open' | grep -v '#'
                fi

    	echo ""
    	echo "------------------------------- Pytanie ----------------------------------------- "
    	echo ""
    	read -p "Czy chcesz dodać sprawdzanie otwartych portów (mogą być też inne adresy IP) ? [t/N]" -n 1 -r
    	echo ""
    	if [[ $REPLY =~ ^[Tt]$ ]]
    	    then
    	    while [ "$portNo" != "0" ]
            		do
            	  clear_screen
            		echo "------------------------------- Pytanie ----------------------------------------- "
            		echo ""
            		echo "Podaj numer portu [ jeśli nie chcesz dodawać więcej portów wpisz '0' lub naciśnij ENTER bez wpisywania niczego ]"
            		read -p "Numer portu = " portNo
            		if [ "$portNo" = "" ]
                		    then
                		    portNo="0"
                		    fi
            		if [ "$portNo" != "0" ]
                		    then
                		    echo ""
                		    echo "------------------------------- Pytanie ----------------------------------------- "
                		    echo ""
                		    echo "Podaj nazwę hosta albo adres IP [ Jeśli chcesz sprawdzać tego hosta wpisz 'localhost' albo kliknij ENTER pozostawiając pusty wpis ]"
                		    read -p "Nazwa hosta = " portHost
                		    if [ "$portHost" = "" ]
                        			then
                        			portHost="localhost"
                        			fi
                		    echo ""
                		    echo "------------------------------- Pytanie ----------------------------------------- "
                		    echo ""
                		    echo "Podaj opis portu [ np. 'FTP', jeśli nie ustawisz opisu będzie np: 'Port 21' ]"
                		    read -p "Opis portu = " portDesc
                		    if [ "$portDesc" = "" ]
                        			then
                        			sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^1^2^Port $portNo")
                      		    else
                        			sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^1^2^$portDesc")
                        			fi
            		         echo "check_port_open $sID $portNo 2 0 $portHost" >> _check.sh
            		         fi
            		done
    	    fi
    	fi


      ret=`cat /etc/crontab | grep 'check.sh' | grep -v '#' | wc -l | xargs`
      if [ "$ret" = "0" ]
              then
              clear_screen
              echo "------------------------------- Pytanie ----------------------------------------- "
              echo ""
              read -p "Czy chcesz dodać skrypt do crona ? [t/N]" -n 1 -r
              echo ""
              if [[ $REPLY =~ ^[Tt]$ ]]
                    then
                    #wget --no-check-certificate https://sky-desk.eu/download/demo_check.sh
                    #mv demo_check.sh check.sh
                    chmod 777 check.sh
                    echo "Będzie potrzeba podania hasła roota"

                    if [ -n "$(command -v sudo)" ]
                            then
                            sudo echo ""  >> /etc/crontab
                            sudo echo ""  >> /etc/crontab
                            sudo echo "##### MONITORING #####"  >> /etc/crontab
                            sudo echo ""  >> /etc/crontab
                            sudo echo "*/5 * * * * root $SCRIPTPATH/check.sh" >> /etc/crontab
                            sudo echo "1 1 * * * root $SCRIPTPATH/setup.sh --update" >> /etc/crontab
                            sudo echo ""  >> /etc/crontab
                            sudo echo "##### KONIEC MONITORINGU #####"  >> /etc/crontab
                          else
                            echo ""  >> /etc/crontab
                            echo ""  >> /etc/crontab
                            echo "##### MONITORING #####"  >> /etc/crontab
                            echo ""  >> /etc/crontab
                            echo "*/5 * * * * root $SCRIPTPATH/check.sh" >> /etc/crontab
                            echo "1 1 * * * root $SCRIPTPATH/setup.sh --update" >> /etc/crontab
                            echo ""  >> /etc/crontab
                            echo "##### KONIEC MONITORINGU #####"  >> /etc/crontab
                            fi
                    fi
          fi

      #echo ""
      #echo ""
      #echo "#####################################################################"
      #echo "Sprawdzanie pakietów niezbędnych do działania monitoringu"
      #check_needed_packages


    source $SCRIPTPATH/include/config
    ## sprawdzanie default_item_group ##
    if [ "$default_item_group_id" == "" ]
        then
        host_name=`echo $HOSTNAME`
        ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
        mac=`ifconfig | grep "$ip" -B 3 -A 3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`

        default_item_group=$(get_data_from_server $user_id $api_key "check_default_asset_group^$mac")
        if [ "$default_item_group" == "" ]
            then
            clear_screen
            echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
            echo ""
            echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
            echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
            read -p "Podaj grupę lub wciśnij ENTER aby anulowac [ np: 1 ] = " default_item_group
            echo ""
          else
            clear_screen
            echo "------------------------------- Pytanie dodatkowe ----------------------------------------- "
            echo ""
            echo "Podaj grupę urządzeń z systemu Sky-Desk. Nie jest ona niezbędna ale jej brak może powodować problem"
            echo "z identyfikacją sprzętu w przypdaku zdublowanych adresów MAC (mało prawdopodobne ale zawsze)"
            echo "Automatycznie dopasowałem grupę ===> $default_item_group <=== - potwierdź jej poprawnosc"
            read -p "Wpisz grupę $default_item_group lub wciśnij ENTER aby anulowac [ $default_item_group ] = " default_item_group
            echo ""

            fi
        fi
   if [ "$default_item_group" != "" ]
        then
        echo "default_item_group_id='$default_item_group'" >> include/config
        fi




      clear_screen
      echo "------------------------------- Info    ----------------------------------------- "
      echo ""
      echo "Wygląda OK. Jeśli chcesz to przeedytuj skrypt 'check.sh' na własne potrzeby..."
      echo "Poniżej lista opcji uruchamiania:"
      echo ""
      echo ""

      if [ -f _check.sh ]
        then
        mv _check.sh check.sh
        fi

       if [ -f check.sh ]
        then
          chmod 777 check.sh
          ./check.sh
        fi

      exit 1
      fi
