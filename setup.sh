#!/usr/bin/env bash

###############################################################################################
#####                                                                                    ######
#####                          Funkcje do monitoringu                                    ######
#####                                                                                    ######
#####                                                                                    ######
#####        Uruchom "./setup.sh"                                                        ######
#####                "./setup.sh --update" - aktualizacja, nie wymaga potwierdzenia      ######
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
###


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH

# ### """

function get_data_from_server {

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
    url=`cat ${TMPDIR}sky_desk_server`
    if [ "$url" = "" ]
	then
	url='https://sky-desk.eu'
	fi
    r=`curl -s -k "$url/api/?act=monitoring&user_id=$user_id&sid=$sid&crc=$crc_md5&value=$value&url=$url"`
    # echo "-->$r<--"
    rr=`echo $r | xargs`
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



#################################################################################################
# instalacja skryptow
# zmiana nazwy z monitoring.sh na functions.sh
# instalacja przykladowych skryptow
# tworzenie katalogow

my_name=`echo $0 | rev | cut -d'/' -f1 | rev`

update='no'


if [ "$1" = "--update" ]
    then
    update='yes'
    force='yes'
    fi


if [ "$update" = "yes" ]
    then
    check_package "curl"
    check_package "md5sum"
    check_package "free"

    vold=`cat version.txt | xargs`
    rm -rf version.txt
    wget --no-check-certificate https://sky-desk.eu/download/monitoring/version.txt
    vnew=`cat version.txt | xargs`

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
        fi

    rm -rf setup.sh
    wget --no-check-certificate https://sky-desk.eu/download/monitoring/include/functions.sh
    wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh

    chmod 777 setup.sh
	cat functions.sh > include/functions.sh
    rm -rf functions.sh

	echo ""
	echo "Gotowe... :)"
	echo ""
	exit
	fi






install_now='1'


if [ "$install_now" = "1" ]
    then
    clear

    echo "########################################################################### "
    echo "#                                                                "
    echo "#  Instalacja skryptu monitoringu                                "
    echo "#                                                                "
    echo "########################################################################### "
    
    # tworznie katalogu z archiwami
    if [ ! -d "archive" ]
        then
        mkdir archive
        fi

    if [ ! -d "include" ]
        then
        mkdir include
        fi

    if [ -f "include/config" ]
        then
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

            if [ -f "cat ${TMPDIR}sky_desk_server" ]
                then
                url=`cat ${TMPDIR}sky_desk_server`
                server=$url
                fi
            fi
        fi

    while [ "$server" = "" ]
	do
	echo ""
	echo "------------------------------- Pytanie ----------------------------------------- "
	echo "#   Podaj adres URL servera Sky-Desk z przedrostkiem HTTPS, [ https://XYZ.sky-desk.eu ], np:"
	echo "#   np: 'https://kowalski.sky-desk.eu/index.php'"
	echo ""
	read -p "URL = " server
	done
    echo $server > ${TMPDIR}sky_desk_server
    url=`cat ${TMPDIR}sky_desk_server`
    echo "Ustawiony serwer = $url"
    
    while [ "$companyID" = "" ]
	do
	echo ""
	echo "------------------------------- Pytanie ----------------------------------------- "
	echo "Podaj numer ID firmy z systemu Sky-Desk"
	echo "Jeśli monitoring ma dotyczyć Twojej firmy lub nie masz dodanych żadnych innych wprowadź '1'"
	echo ""
	read -p "Comapny ID = " companyID
	done

    while [ "$userID" = "" ]
	do
	echo ""
	echo "------------------------------- Pytanie ----------------------------------------- "
	echo "Podaj numer ID użytkownika"
	echo "ID to znajdziesz w Panelu Sterowania, klikając w swojego użytkownika, zazwyczaj dla Administratora powinna ta wartość być równa '1'"
	echo ""
	read -p "User ID = " userID
	done


    while [ "$companyAPI" = "" ]
	do
	echo ""
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
        echo ""
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
	# poprawne dane - robie plik
	echo "#!/usr/bin/env bash" > include/config
	echo "user_id='$userID'" >> include/config
	echo "api_key='$companyAPI'" >> include/config
	echo "url='$url'" >> include/config
	echo "server='$server'" >> include/config
	echo "companyID='$companyID'" >> include/config

    #ret=`cat check.sh | grep 'include/config' | wc -l | xargs`
    #if [ "$ret" = "0" ]
        #then
        data=`date +"%Y-%m-%d %H:%M:%S"`
        echo "#!/usr/bin/env bash" > _check.sh
	    echo 'source $(dirname $0)/include/config' >> _check.sh
        echo 'source $(dirname $0)/include/functions.sh' >> _check.sh
        echo '' >> _check.sh
        echo 'SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"' >> _check.sh
        echo 'cd $SCRIPTPATH' >> _check.sh
        echo '' >> _check.sh
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
            rm -rf check.sh
            mv _check.sh check.sh
            fi
	 #fi

	
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
	    echo ""
	    echo "------------------------------- Pytanie ----------------------------------------- "
	    echo "Znalazłem takie urządzenie w bazie $server"
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
	    echo ""
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
	    echo ""
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
            echo "------------------------------- Pytanie ----------------------------------------- "
            read -p "Czy chcesz dodać monitoring zajętości partycji '$dd' ? [t/N]" -n 1 -r
            echo ""
            echo ""
            if [[ $REPLY =~ ^[Tt]$ ]]
                then
                sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^90^HDD [% usage] $dd")
                echo "check_hdd_size $sID '$dd'" >> check.sh
                fi
            fi
        done
	    
	# sprawdzanie pamieci ram
    ret=`cat check.sh | grep 'check_memory_usage' | wc -l | xargs`
    if [ "$ret" = "0" ]
        then
        echo ""
        echo "------------------------------- Pytanie ----------------------------------------- "
        echo ""
        read -p "Czy chcesz dodać monitoring pamięci RAM ? [t/N]" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Tt]$ ]]
            then
            sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^95^Memory usage")
            echo "check_memory_usage $sID" >> check.sh
            fi
        fi

	# sprawdzanie CPU
    ret=`cat check.sh | grep 'check_cpu_load' | wc -l | xargs`
    if [ "$ret" = "0" ]
        then
        echo ""
        echo "------------------------------- Pytanie ----------------------------------------- "
        echo ""
        read -p "Czy chcesz dodać monitoring obciążenia procesora ? [t/N]" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Tt]$ ]]
            then
            sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^3^CPU Load")
            echo "check_cpu_load $sID" >> check.sh
            fi
        fi

	# sprawdzanie zalogowanych uzytkownikow
    ret=`cat check.sh | grep 'check_logged_users' | wc -l | xargs`
    if [ "$ret" = "0" ]
        then
        echo ""
        echo "------------------------------- Pytanie ----------------------------------------- "
        echo ""
        read -p "Czy chcesz dodać monitoring zalogowanych użytkowników ? [t/N]" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Tt]$ ]]
            then
            sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^0^Logged users")
            echo "check_logged_users $sID" >> check.sh
            fi
        fi

	# sprawdzanie MySQLa
    ret=`cat check.sh | grep 'check_mysql_processcount' | wc -l | xargs`
    if [ "$ret" = "0" ]
        then
        echo ""
        echo "------------------------------- Pytanie ----------------------------------------- "
        echo ""
        read -p "Czy chcesz dodać monitoring obciążenia bazy MySQL ? [t/N]" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Tt]$ ]]
            then
            read -p "Podaj użytkownika do MySQLa [ np: root ] = " mysqlUser
            read -s -p "Podaj hasło $mysqlUser do MySQLa = " mysqlPass
            sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^20^MySQL - process count")
            echo "check_mysql_processcount $sID $mysqlUser $mysqlPass" >> check.sh

            sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^20^MySQL - long process count > 1 min")
            echo "check_mysql_processcount $sID $mysqlUser $mysqlPass" >> check.sh
            fi
        fi


	# sprawdzanie otwartych portów
    ret=`cat check.sh | grep 'check_mysql_processcount' | wc -l | xargs`
    if [ "$ret" != "0" ]
        then
        echo "INFO: Poniższe porty są już monitorowane:"
        cat check.sh | grep 'check_port_open' | grep -v '#'
        fi

	echo ""
	echo "------------------------------- Pytanie ----------------------------------------- "
	echo ""
	read -p "Czy chcesz dodać sprawdzanie otwartych portów (dla różnych IP) ? [t/N]" -n 1 -r
	echo ""
	if [[ $REPLY =~ ^[Tt]$ ]]
	    then
	    while [ "$portNo" != "0" ]
		do
		echo ""
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
		    echo "check_port_open $sID $portNo 2 0 $portHost" >> check.sh
		    fi
		done
	    fi


	    
	fi


    ret=`cat /etc/crontab | grep 'check.sh' | grep -v '#' | wc -l | xargs`
    if [ "$ret" = "0" ]
        then
        echo ""
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


    echo ""
    echo ""
    echo "#####################################################################"
    echo "Sprawdzanie pakietów niezbędnych do działania monitoringu"
    check_package "curl"
    check_package "md5sum"
    check_package "free"

    echo ""
    echo "------------------------------- Info    ----------------------------------------- "
    echo ""
    echo "Wygląda OK. Jeśli chcesz to przeedytuj skrypt 'check.sh' na własne potrzeby..."
    echo "Poniżej lista opcji uruchamiania:"
    echo ""
    echo ""

    
    exit 1    
    fi




