<pre>
Welcome to the sky-desk-monitoring wiki!

This is a tool for monitoring lan devices.
This new version is done by splitted files to configure and monitoring.
It can add new monitoring scripts to existing ones.
All data will be imported to https://sky-desk.eu - there is a view to monitor sources and activity


If you have your own instance of Sky-Desk you can download installer executing this:

wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh

Predefined function list that can be used to monitoring

-- sprawdzanie % wielkosci miejsca na dysku
    check_hdd_size {service_id} {partition}

-- sprawdzanie czy port jest otwarty<br>
    check_port_open {service_id} {port_no} {ok_value=2} {error_value=0} {host=localhost}

-- zapytanie do PgSQL
    check_pgsql_query {service_id} {login} {password} {database} {query}

-- zajętość pamięci
    check_memory_usage {service_id}

-- obciazenie sumaryczne procesorow
    check_cpu_load {service_id}

-- obciazenie mysql
    check_mysql_processcount {service_id} {username} {password}

-- wysylanie zawartosci pliku (trim do jednej linii) jako wynik
    file_content {service_id} "{file_path_name}"

-- sprawdzanie pinga
    check_ping {service_id} {hostname=localhost} {ping_count=2}

-- sprawdzanie ilu jest zalogowanych userow
   check_logged_users {service_id}

-- wyszukiwanie liczby wystąpień zadanej frazy w pliku
    loggrep {service_id} {plik ze sciezka} {fraza do zyszukania}

-- sprawdzanie czasu działania systemu po restarcie w godzinach
    check_uptime_hour {service_id}

-- sprawdzanie czasu działania systemu po restarcie w dniach
    check_uptime_days {service_id}

-- sprawdzanie liczby kb odebranych RX przez zadany interfejs, np. "eth0"
    check_lan_interface_rx {service_id} {interface}

-- sprawdzanie liczby kb wyslanych TX przez zadany interfejs, np. "eth0"
    check_lan_interface_tx {service_id} {interface}

-- sprawdzanie licznby uruchomionych procesow
    check_running_process_count {service_id} {process_name}

</pre>
