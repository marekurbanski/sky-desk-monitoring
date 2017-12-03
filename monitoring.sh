#!/usr/bin/env bash

###############################################################################################
#####                                                                                    ######
#####                          Funkcje do monitoringu                                    ######
#####                                                                                    ######
#####                              wersja: 5.1                                           ######
#####                                                                                    ######
#####        Uruchom "./functions.sh --update" aby pobrać aktualną wersję                ######
#####                "./functions.sh --force-update" - nie wymaga potwierdzenia          ######
#####                "./functions.sh --install"      - uruchamia instalatora             ######
#####                                                                                    ######
###############################################################################################

#### Instalacja:
#### wget --no-check-certificate https://sky-desk.eu/download/monitoring.sh


########### wymagane pakiety ##############
##
##	curl
##	md5sum
##	free
###


####################################### settings ##############################################
#
# -- sprawdzanie % wielkosci miejsca na dysku
# check_hdd_size {service_id} {partition}
#
# -- sprawdzanie czy port jest otwarty
# check_port_open {service_id} {port_no} {ok_value=2} {error_value=0} {host=localhost}
#
# -- zapytanie do PgSQL
# check_pgsql_query {service_id} {login} {password} {database} {query}
#
# -- zajętość pamięci
# check_memory_usage {service_id}
#
# -- obciazenie sumaryczne procesorow
# check_cpu_load {service_id}
#
# -- obciazenie mysql
# check_mysql_processcount {service_id} {username} {password}
#
# -- wysylanie zawartosci pliku (trim do jednej linii) jako wynik
# file_content {service_id} "{file_path_name}"
#
# -- sprawdzanie pinga
# check_ping {service_id} {hostname=localhost} {ping_count=2}
#
# -- sprawdzanie ilu jest zalogowanych userow
# check_logged_users {service_id}
#
# -- 
# loggrep {service_id} {plik ze sciezka} {fraza do zyszukania}
#


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
    else
	crc_md5=`echo -n $crc | md5sum | cut -d" " -f1`
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

install_now='0'

if [ "$my_name" = "monitoring.sh" ]
    then
    install_now='1'
    fi

if [ "$1" = "--install" ]
    then
    install_now='1'
    fi

if [ "$install_now" = "1" ]
    then
    clear
    
    check_package "curl"
    
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
        
        
    while [ "$server" = "" ]
	do
	echo ""
	echo "------------------------------- Pytanie ----------------------------------------- "
	echo "#   Podaj adres URL servera Sky-Desk, [ https://XYZ.sky-desk.eu ], np:"
	echo "#   np: 'https://kowalski.sky-desk.eu/index.php' lub 'kowalski.sky-desk.eu'"
	echo ""
	read -p "URL = " server
	done
    server=`basename $(dirname "$server")`
    server="https://$server"
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
	echo "#!/usr/bin/env bash" > check.sh
	echo "user_id='$userID'" >> check.sh
	echo "api_key='$companyAPI'" >> check.sh
	echo 'source $(dirname $0)/functions.sh' >> check.sh
	
	
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
	    echo "------------------------------- Pytanie ----------------------------------------- "
	    read -p "Czy chcesz dodać monitoring zajętości partycji '$dd' ? [t/N]" -n 1 -r
	    echo ""
	    echo ""
	    if [[ $REPLY =~ ^[Tt]$ ]]
		then
		sID=$(get_data_from_server $userID $companyAPI "get_set_monitor^$assetID^0^90^HDD [% usage] $dd")
		echo "check_hdd_size $sID '$dd'" >> check.sh
		fi
	    done
	    
	# sprawdzanie pamieci ram    
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


	# sprawdzanie CPU
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


	# sprawdzanie zalogowanych uzytkownikow
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


	# sprawdzanie MySQLa
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


	# sprawdzanie otwartych portów 
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
	    sudo echo "1 1 * * * root $SCRIPTPATH/functions.sh --force-update" >> /etc/crontab
	    sudo echo ""  >> /etc/crontab
	    sudo echo "##### KONIEC MONITORINGU #####"  >> /etc/crontab

	else
	    echo ""  >> /etc/crontab
	    echo ""  >> /etc/crontab
	    echo "##### MONITORING #####"  >> /etc/crontab
	    echo ""  >> /etc/crontab
	    echo "*/5 * * * * root $SCRIPTPATH/check.sh" >> /etc/crontab
	    echo "1 1 * * * root $SCRIPTPATH/functions.sh --force-update" >> /etc/crontab
	    echo ""  >> /etc/crontab
	    echo "##### KONIEC MONITORINGU #####"  >> /etc/crontab
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
    echo "  './functions.sh --install' - uruchamia proces instalacji / konfiguracji"
    echo "  './functions.sh --update'  - uruchamia proces aktualizacji interaktywnej"
    echo "  './functions.sh --force-update - uruchamia automatyczną aktualizację"
    echo ""
    echo ""
    if [ -f "monitoring.sh" ]
	then
	mv monitoring.sh functions.sh
	fi
    
    exit 1    
    fi




if [ "$1" = "--update" ]
    then
    update='yes'
    force='no'
    fi



if [ "$1" = "--force-update" ]
    then
    update='yes'
    force='yes'
    fi



if [ "$update" = "yes" ]
    then

    check_package "curl"
    check_package "md5sum"
    check_package "free"
    
    wget --no-check-certificate https://sky-desk.eu/download/_functions.new
    vnew=`head -n 15 _functions.new | grep '####' | grep : | cut -d':' -f2 | cut -d'#' -f1 | xargs`
    vold=`head -n 15 functions.sh | grep '####' | grep : | cut -d':' -f2 | cut -d'#' -f1 | xargs`

    if [ $vnew == $vold ]
	then
	echo ""
	echo ""
	echo " Posiadasz aktualną wersję pliku funkcji :)"
	echo ""
	echo ""
	echo ""
	rm _functions.new
	exit
	fi
    echo ""
    echo "================================================================================"
    echo ""
    echo "Jest nowa aktualizacja pliku ( z wersji $vold do wersji $vnew )"
    echo ""
    
    if [ $force = "no" ]
	then
	read -p "Czy nadpisać aktualny plik ? (aktualna wersja zostanie zarchiwizowana) [t/N]" -n 1 -r
	echo ""
        if [[ $REPLY =~ ^[Tt]$ ]]
	    then
	    force='yes'
	    fi
	fi

    if [ $force = "yes" ]
	then
	if [ ! -d "archive" ]
	    then
	    mkdir archive
	    fi
        data=`date +%Y-%m-%d`
	cp functions.sh archive/functions_$data.sh
	cat _functions.new > functions.sh
	echo ""
	echo "Gotowe... :)"
	echo ""
	fi
    rm _functions.new
    exit
    else
    echo ""
    echo "#######################################################################################"
    echo "##                                                                                   ##"
    echo "##        Aby pobrać nową wersję funkcji uruchom:                                    ##"
    echo "##        ./functions.sh --update                                                    ##"
    echo "##        ./functions.sh --force-update                                              ##"
    echo "##                                                                                   ##"
    echo "##        Nowa instalacja:                                                           ##"
    echo "##        wget --no-check-certificate https://sky-desk.eu/download/monitoring.sh     ##"
    echo "##                                                                                   ##"
    echo "##        Konfiguracja:                                                              ##"
    echo "##        ./functions.sh --install                                                   ##"
    echo "##                                                                                   ##"
    echo "##                                                                                   ##"
    echo "#######################################################################################"
    echo ""
    echo ""
    fi

function tcp_transfer {
    INTERVAL="$2"
    IF=$3

    while true
    do
        R1=`cat /sys/class/net/$3/statistics/rx_bytes`
        T1=`cat /sys/class/net/$3/statistics/tx_bytes`
        sleep $INTERVAL
        R2=`cat /sys/class/net/$3/statistics/rx_bytes`
        T2=`cat /sys/class/net/$3/statistics/tx_bytes`
        TBPS=`expr $T2 - $T1`
        RBPS=`expr $R2 - $R1`
        TKBPS=`expr $TBPS / 1024`
        RKBPS=`expr $RBPS / 1024`
        echo "TX $1: $TKBPS kB/s RX $1: $RKBPS kB/s"
    done 

    }


function check_pgsql_query {
    export PGPASSWORD=$3
    value=`psql -h localhost -U $2 -d $4 -c "$5" | head -n 3 | tail -n 1 | xargs`
    save_result $1 $value
    }

function check_ping {

    if [ "$3" != "" ]; then c=$3; else c='2'; fi
    if [ "$2" != "" ]; then h=$2; else h='localhost'; fi

    res=`ping -c $c $h | grep time | grep from | wc -l`

    save_result $1 $res
    }

function check_port_open {
    let i=0
    if [ "$3" != "" ]; then ok_value=$3; else ok_value='2'; fi
    if [ "$4" != "" ]; then error_value=$4; else error_value='0'; fi;
    if [ "$5" != "" ]; then host_name=$5; else host_name='localhost'; fi
    port=$2

    value=$ok_value
    while ! nc -z $host_name $port; do
	sleep 1
	let i=i+1
        if [ $i > 10 ]
	    then
    	    value=$error_value
    	    break
        fi
    done
    save_result $1 $value
    }

function run_shell {
    res=`eval $2`
    save_result $1 $res
    }

function file_content {
    res=`cat $2 | xargs`
    save_result $1 $res
    }

function check_hdd_size {
    res=`df -h $2 | tail -n1 | rev | cut -d"%" -f2 | cut -d" " -f1 | rev`
    save_result $1 $res
    }

function check_cpu_load {
    av=`cat /proc/loadavg | cut -d' ' -f1`
    pc=`cat /proc/cpuinfo | grep processor | wc -l`
    res=$(awk "BEGIN {printf \"%.2f\",${av}/${pc}}")
    save_result $1 $res
    }


function check_memory_usage {
    res=`free | grep -e Mem -e Pami | awk '{print $3/$2 * 100.0}'`
    save_result $1 $res
    }


function check_mysql_processcount {
    res=`mysql -u $2 -p$3 -e 'select * from information_schema.processlist where state <> ""' | wc -l`
    save_result $1 $res
    }


function check_mysql_slowprocesscount {
    res=`mysql -u $2 -p$3 -e 'select * from information_schema.processlist where state <> "" and time > 1' | wc -l`
    save_result $1 $res
    }


function save_result {
    value=$2
    sid=$1
    data=`date +%Y-%m-%d`
    crc="$user_id$value$api_key$sid$data"
    if [ -n "$(command -v md5)" ]
	then
	crc_md5=`echo -n $crc | md5 | cut -d" " -f1`
    else
	crc_md5=`echo -n $crc | md5sum | cut -d" " -f1`
	fi
    echo "Wynik = $value"
    url=`cat ${TMPDIR}sky_desk_server`
    if [ "$url" = "" ]
	then
	url='https://sky-desk.eu'
	fi

    curl -k "$url/api/?act=monitoring&user_id=$user_id&value=$value&sid=$sid&crc=$crc_md5"
    }


function loggrep {

    filename=$2
    filename_temp=$(basename "$filename")
    temp_dir="$HOME/.logtail2"
    counter_file="$temp_dir/tail_$filename_temp.last"
    temp_filename="$temp_dir/$filename_temp.tmp"

    if [ ! -d "$temp_dir" ]
        then
        mkdir $temp_dir
        fi

    if [ ! -f "$counter_file" ]
        then
        last='0'
    else
        last=`cat $counter_file | xargs`
        fi


    act=`awk '1' $1 | wc -l`

    if [ $((act-last)) -lt 0 ]
        then
        #Previously there were more lines, so it must be a new file
        rm -rf $counter_file
        loggrep $1 $2 $3
        exit 1
        fi

    last2=$(($last + 1))
    tail -n +$last2 $filename > $temp_filename
    n=`awk '1' $temp_filename | wc -l`
    nn=$(($n + $last))
    echo $nn > $counter_file
    res=`cat $temp_filename | grep "$3" | wc -l | xargs`

    save_result $1 $res
    }


function check_logged_users {
    
    lu=`w | wc -l | xargs`
    count=$(($lu-2))
    
    save_result $1 $count
    }

