<pre>
Witamy w skrypcie monitorującym sieć.
To narzędzie pozwala na monitorowanie urządzeń w sieci.
Może być uruchamiane jako własny, zdefiniowany skrypt lub można używać predefiniowanych
zestawów komend.

Oprócz monitoringu, możliwe jest także skanowanie sieci i dodawanie/aktualizacja tych urządzeń
w systemie Sky-Desk.

Podstawowe skrypty:
--------------------

./setup.sh
# Główny instalator sktyptów
# Do ściagnięcia z:
# wget --no-check-certificate https://sky-desk.eu/download/monitoring/setup.sh
# lub
# https://github.com/marekurbanski/sky-desk-monitoring
# Należy nadać mu uprawnienia uruchamiania
# chmod 777 check.sh
# i następnie do uruchomić (najlepiej jako root, wtedy będzie mógł doinstalować ew. brakujące paczki)
# ./check.sh
# Możliwe parametry uruchamiania:
# ./setup.sh --update # aktualizacja wszystkich skryptow
# ./setup.sh --help   # wyświetlenie pliku pomocy (tego pliku)

./check.sh
# skrypt tworzony automatycznie, to on będzie odpowiedzialny za monitorowanie hostów i usług

include/config
# konfiguracja monitorowania, podstawowe parametry poniżej:
# user_id='XXX'
# api_key='YYY'
# url='https://ZZZ.sky-desk.eu'
# server='https://ZZZ.sky-desk.eu'
# companyID='OOO'

./scanner.sh
# Skrypt skanujący sieć i updatujący dane w systemie Sky-Desk
# Parametry uruchamiania:
# ./scanner.sh --scan_all [--update]       # skanuje całą sieć
# ./scanner.sh [--update] IP_ADDR          # skanuje pojedynczy adres IP
# ./scanner.sh --mac [--update] MAC_ADDR   # skanuje jeden adres MAC
# Dodanie parametru '--update' powoduje zaktualizowanie danych w systemie
# Dane ktore będą updateowane są konfigurowane w pliku 'include/config.scanner'
# [IP_ADDR] - adres IP
# [MAC] - adres MAC

include/config.scaner
# Plik ten tworzony jest na początku automatycznie
# To w nim konfigururjemy co ma się automatycznie updateować w Sky-Desk a co nie

examples
# Katalog w którym są przykładowe skrypty sprawdzające odbiegające od standartowych
# konfiguracji linuxowych
# Np: dla AccessPointów OpenMesh standardowa konfiguracja nie zadzała więc
# przygotowana jest przykładowa paczka, działająca pod OpenMesh

------------------------------------------------------------------------------------------------
-- Poniżej lista komend predefiniowanych służących do monitorowania
------------------------------------------------------------------------------------------------

# sprawdzanie % wielkosci miejsca na dysku
check_hdd_size {service_id} {partition}

# sprawdzanie czy port jest otwarty<br>
check_port_open {service_id} {port_no} {ok_value=2} {error_value=0} {host=localhost}

# zapytanie do PgSQL
check_pgsql_query {service_id} {login} {password} {database} {query}

# zajętość pamięci
check_memory_usage {service_id}

# obciazenie sumaryczne procesorow
check_cpu_load {service_id}

# obciazenie mysql
check_mysql_processcount {service_id} {username} {password}

# wysylanie zawartosci pliku (trim do jednej linii) jako wynik
file_content {service_id} "{file_path_name}"

# sprawdzanie pinga
check_ping {service_id} {hostname=localhost} {ping_count=2}

# sprawdzanie ilu jest zalogowanych userow
check_logged_users {service_id}

# wyszukiwanie liczby wystąpień zadanej frazy w pliku
loggrep {service_id} {plik ze sciezka} {fraza do zyszukania}

# sprawdzanie czasu działania systemu po restarcie w godzinach
check_uptime_hour {service_id}

# sprawdzanie czasu działania systemu po restarcie w dniach
check_uptime_days {service_id}

# sprawdzanie liczby kb odebranych RX przez zadany interfejs, np. "eth0"
check_lan_interface_rx {service_id} {interface}

# sprawdzanie liczby kb wyslanych TX przez zadany interfejs, np. "eth0"
check_lan_interface_tx {service_id} {interface}

# sprawdzanie licznby uruchomionych procesow
check_running_process_count {service_id} {process_name}

</pre>
