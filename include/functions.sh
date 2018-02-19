#!/usr/bin/env bash

###############################################################################################
#####                                                                                    ######
#####                          Funkcje do monitoringu                                    ######
#####                                                                                    ######
#####                                                                                    ######
###############################################################################################




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
	    if [ "$1" = "snmp" ]
	        then
	        $1="net-snmp-utils"
	        fi

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



function check_running_process_count {
    res=`ps -ax | grep $2 | grep -v 'grep' | wc -l | xargs`
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
	    fi
    if [ -n "$(command -v md5sum)" ]
	    then
	    crc_md5=`echo -n $crc | md5sum | cut -d" " -f1`
	    fi
    if [ -n "$(command -v md5sha1sum)" ]
	    then
	    crc_md5=`echo -n $crc | md5sha1sum | cut -d" " -f1`
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
        loggrep $1
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


function check_uptime_hour {

    if [ -f /proc/uptime ]
        then
        sec=`cat /proc/uptime | cut -d' ' -f1 | cut -d"." -f1 | xargs`
        else
        sec=`sysctl -n kern.boottime | cut -c14-18 | xargs`
        fi

    hour=$(( $sec / 3600 ))
    save_result $1 $hour
    }


function check_uptime_days {

    if [ -f /proc/uptime ]
        then
        sec=`cat /proc/uptime | cut -d' ' -f1 | cut -d"." -f1 | xargs`
    else
        sec=`sysctl -n kern.boottime | cut -c14-18 | xargs`
        fi

    days=$(( $sec / 86400 ))
    save_result $1 $days
    }


function check_lan_interface_tx {

    interface=$2
    tx2=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
    f_tx="$HOME/.monitoring/check_tx"
    if [ ! -d $HOME/.monitoring ]
        then
        mkdir $HOME/.monitoring
        echo $rx2 > $f_rx
        echo $tx2 > $f_tx
        fi

    tx1=`cat $f_tx`

    tx_bps=$((tx2 - tx1))
    tx_kbps=$((tx_bps / 1024))

    echo $tx2 > $f_tx

    save_result $1 $tx_kbps
    }


function check_lan_interface_rx {

    interface=$2

    rx2=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")
    f_rx="$HOME/.monitoring/check_rx"

    if [ ! -d $HOME/.monitoring ]
        then
        mkdir $HOME/.monitoring
        echo $rx2 > $f_rx
        echo $tx2 > $f_tx
        fi

    rx1=`cat $f_rx`

    rx_bps=$((rx2 - rx1))
    rx_kbps=$((rx_bps / 1024))

    echo $rx2 > $f_rx

    save_result $1 $rx_kbps
    }





function check_snmp_oid {
    
    res=`snmpget -v 1 -c public $2 $3 | rev | cut -d':' -f1 | rev | xargs`
    
    save_result $1 $res
    }
    


function check_snmp_oid_increase {

    if [ "$4" != "" ]; then divide=$4; else divide='1'; fi 

    v_act=`snmpget -v 1 -c public $2 $3 | rev | cut -d':' -f1 | rev | xargs`

    f_prev="$HOME/.monitoring/$3"

    if [ ! -d $HOME/.monitoring ]
        then
        mkdir $HOME/.monitoring
        echo $v_act > $f_prev
        fi

    v_prev=`cat $f_prev`

    res=$(($v_act - $v_prev))
    res_div=$((rx_bps / $divide))

    echo $v_act > $f_prev

    save_result $1 $res_div
    }
    
    
    