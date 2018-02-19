#!/bin/sh

#################################################
#
# Example script for checkning Open Mesh AP
# 
# First are functions
# At the bottom are function exexuted
# and all settings
#
#################################################

run_shell()
    {
    res=`eval $2`
    save_result $1 $res
    }

save_result()
    {

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
    curl -k "$url/api/?act=monitoring&user_id=$user_id&value=$value&sid=$sid&crc=hvkhvjhvkjvhjvljhv;khv;cfxhfdxhdxesrdkglj;kjbl"
    }



check_memory_usage()
{
    res=`free | grep -e Mem -e Pami | awk '{print $3/$2 * 100.0}'`
    save_result $1 $res
    }


check_cpu_load()
    {
    av=`cat /proc/loadavg | cut -d' ' -f1`
    pc=`cat /proc/cpuinfo | grep processor | wc -l`
    res=$(awk "BEGIN {printf \"%.2f\",${av}/${pc}}")
    save_result $1 $res
    }



check_ping()
    {

    if [ "$3" != "" ]; then c=$3; else c='2'; fi
    if [ "$2" != "" ]; then h=$2; else h='localhost'; fi

    res=`ping -c $c $h | grep time | grep from | wc -l`

    save_result $1 $res
    }


check_lan_interface_tx_dropped()
    {

    interface=$2
    tx2=`batctl statistics | grep tx_dropped | grep -v mgmt | grep -v frag | cut -d" " -f2`
    f_tx="/tmp/check_tx_dropped"

    tx1=`cat $f_tx`

    tx_bps=$((tx2 - tx1))
    tx_kbps=$((tx_bps / 1024))

    echo $tx2 > $f_tx

    save_result $1 $tx_kbps
    }


check_lan_interface_tx()
    {

    interface=$2
    tx2=`batctl statistics | grep tx_bytes | grep -v mgmt | grep -v frag | cut -d" " -f2`
    f_tx="/tmp/check_tx"

    tx1=`cat $f_tx`

    tx_bps=$((tx2 - tx1))
    tx_kbps=$((tx_bps / 1024))

    echo $tx2 > $f_tx

    save_result $1 $tx_kbps
    }



check_lan_interface_rx()
    {

    interface=$2
    rx2=`batctl statistics | grep rx_bytes | grep -v mgmt | grep -v frag | cut -d" " -f2`
    f_rx="/tmp/check_rx"

    rx1=`cat $f_rx`

    rx_bps=$((rx2 - rx1))
    rx_kbps=$((rx_bps / 1024))

    echo $rx2 > $f_rx

    save_result $1 $rx_kbps
    }




#################################################
#
# Settings, obligatory to connect to serwer
#

url='https://[##SUBDOMAIN##]sky-desk.eu'
user_id='[##USER_ID##]'
api_key='[##API_KEY##]'


#################################################
#
#  Functions to run (update params)
#
check_memory_usage [#CHECK_ID#]
check_cpu_load [#CHECK_ID#]
check_ping [#CHECK_ID#] 'google.com'
check_lan_interface_tx [#CHECK_ID#]
check_lan_interface_rx [#CHECK_ID#]
check_lan_interface_tx_dropped [#CHECK_ID#]

