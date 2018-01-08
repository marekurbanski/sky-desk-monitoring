Welcome to the sky-desk-monitoring wiki!<br>
<br>
This is a tool for monitoring lan devices.<br>
This new version is done by splitted files to configure and monitoring.<br>
It can add new monitoring scripts to existing ones.<br>
All data will be imported to [https://sky-desk.eu](https://sky-desk.eu) - there is a view to monitor sources and activity<br>
<br>
<br>
If you have your own instance of Sky-Desk you can download installer executing this:<br>
<br>
wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh<br>
<br>
Predefined function list that can be used to monitoring<br>
<br>
<br>
-- sprawdzanie % wielkosci miejsca na dysku<br>
check_hdd_size {service_id} {partition}<br>
<br>
-- sprawdzanie czy port jest otwarty<br>
check_port_open {service_id} {port_no} {ok_value=2} {error_value=0} {host=localhost}<br>
<br>
-- zapytanie do PgSQL<br>
check_pgsql_query {service_id} {login} {password} {database} {query}<br>
<br>
-- zajętość pamięci<br>
check_memory_usage {service_id}<br>
<br>
-- obciazenie sumaryczne procesorow<br>
check_cpu_load {service_id}<br>
<br>
-- obciazenie mysql<br>
check_mysql_processcount {service_id} {username} {password}<br>
<br>
-- wysylanie zawartosci pliku (trim do jednej linii) jako wynik<br>
file_content {service_id} "{file_path_name}"<br>
<br>
-- sprawdzanie pinga<br>
check_ping {service_id} {hostname=localhost} {ping_count=2}<br>
<br>
-- sprawdzanie ilu jest zalogowanych userow<br>
check_logged_users {service_id}<br>
<br>
-- <br>
loggrep {service_id} {plik ze sciezka} {fraza do zyszukania}<br>
<br>