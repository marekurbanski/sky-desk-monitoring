#!/bin/sh

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
    tx2=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
    if [ -f "$HOME/.monitoring/${interface}_tx" ]
        then
        f_tx="$HOME/.monitoring/${interface}_tx"
    else
        f_tx="$HOME/.monitoring/${interface}_tx"
        echo "0" > $f_tx
        fi


    if [ ! -d $HOME/.monitoring ]
        then
        mkdir $HOME/.monitoring
        echo $tx2 > $f_tx
        fi

    if [ ! -f "$HOME/.monitoring/${interface}_time_tx" ]
        then
        echo "0" > $HOME/.monitoring/${interface}_time_tx
        fi

    act_time=`date +%s`
    prev_time=`cat $HOME/.monitoring/${interface}_time_tx`
    time_diff=$(($act_time - $prev_time))
    echo $act_time > $HOME/.monitoring/${interface}_time_tx

    tx1=`cat $f_tx`

    tx_bps=$((tx2 - tx1))
    tx_kbps=$((tx_bps / 1024 * 8 / $time_diff))

    echo $tx2 > $f_tx

    save_result $1 $tx_kbps
    }


check_lan_interface_rx()
    {

    interface=$2



    rx2=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")

    if [ -f "$HOME/.monitoring/${interface}_rx" ]
        then
        f_rx="$HOME/.monitoring/${interface}_rx"
    else
        f_rx="$HOME/.monitoring/${interface}_rx"
        echo "0" > $f_rx
        fi

    if [ ! -d $HOME/.monitoring ]
        then
        mkdir $HOME/.monitoring
        echo $rx2 > $f_rx
        fi

    if [ ! -f "$HOME/.monitoring/${interface}_time_rx" ]
        then
        echo "0" > $HOME/.monitoring/${interface}_time_rx
        fi

    act_time=`date +%s`
    prev_time=`cat $HOME/.monitoring/${interface}_time_rx`
    time_diff=$(($act_time - $prev_time))
    echo $act_time > $HOME/.monitoring/${interface}_time_rx

    rx1=`cat $f_rx`

    rx_bps=$((rx2 - rx1))
    rx_kbps=$((rx_bps / 1024 * 8 / $time_diff))

    echo $rx2 > $f_rx

    save_result $1 $rx_kbps
    }





url='https://sky-desk.eu'
user_id='XXX'
api_key='XXX'


check_memory_usage 129
check_cpu_load 130
check_ping 131 'wp.pl'
check_lan_interface_tx 132 'eth0'
check_lan_interface_rx 133 'eth0'
check_lan_interface_tx_dropped 134

check_lan_interface_tx 145 'p0_1'
check_lan_interface_tx 146 'bat0'
check_lan_interface_tx 147 'bat0.1'
check_lan_interface_tx 148 'bat0.2'
check_lan_interface_tx 149 'bat0.3'
check_lan_interface_tx 150 'bat0.989'
check_lan_interface_tx 151 'br-lan1'
check_lan_interface_tx 152 'br-lan1.100'
check_lan_interface_tx 153 'br-lan2'
check_lan_interface_tx 154 'br-meship'
check_lan_interface_tx 155 'br-ssid1'
check_lan_interface_tx 156 'eth1'
check_lan_interface_tx 157 'ifb_uds'
check_lan_interface_tx 158 'mesh0'
check_lan_interface_tx 159 'mon0'


check_lan_interface_rx 160 'p0_1'
check_lan_interface_rx 161 'bat0'
check_lan_interface_rx 162 'bat0.1'
check_lan_interface_rx 163 'bat0.2'
check_lan_interface_rx 164 'bat0.3'
check_lan_interface_rx 165 'bat0.989'
check_lan_interface_rx 166 'br-lan1'
check_lan_interface_rx 167 'br-lan1.100'
check_lan_interface_rx 168 'br-lan2'
check_lan_interface_rx 169 'br-meship'
check_lan_interface_rx 170 'br-ssid1'
check_lan_interface_rx 171 'eth1'
check_lan_interface_rx 172 'ifb_uds'
check_lan_interface_rx 173 'mesh0'
check_lan_interface_rx 174 'mon0'

