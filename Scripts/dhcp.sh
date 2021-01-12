#!/bin/bash

#DECLARACIONS PÚBLIQUES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LOGFILE="dhcp.log"
LOGFILE_OVERWRITE=true
TMP_FILE="dhcp_tmp_file.log"
USAGE="Usage: dhcp.sh <interface name>"
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# FUNCIONS
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enableIface()
{	
	`ip link set $1 up`
}
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#MAIN DE L'SCRIPT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if [ $# -ne 1 ]; then echo $USAGE; exit 1; fi

if [[ $(id -u) -ne 0 ]] ; then echo "Si us plau executi amb permisos root" ; exit 1 ; fi

start="$(date '+%Y-%m-%d %H:%M:%S')"

#XIVATO
echo -e "Inici $start"

if [ $LOGFILE_OVERWRITE ]; then
	echo -e "---------------- Data inici: $start ----------------\n" > $LOGFILE
else
	echo -e "---------------- Data inici: $start ----------------\n" >> $LOGFILE
fi

#XIVATO
echo -ne "Comprovant interficie $1..."

ip addr show $1 > /dev/null 2>&1

if (( $? )); then 
{ 
	#XIVATO
	echo -ne "NO TROBADA\n"
	exit 1
} fi;

#XIVATO
echo -ne "FET\n"

active=`ip addr show $1 | grep "<" | cut -d "<" -f2 | cut -d ">" -f1 | grep "UP"`

if [ -z "$active" ]; then
	echo -ne "La interfície es troba baixada. Aixencant... "
	$(enableIface $1)
	echo -ne "FET\n"
fi


echo -ne "Enviant broadcast a la xarxa i recullint dades... "


# Llança el dhcpdump en background i seguidament llança l'nmap que aquest envia DHCPDISCOVER en broadcast.
{ dhcpdump -i $1 > $TMP_FILE;   } &
																#XIVATO
{ nmap --script broadcast-dhcp-discover -e $1 > /dev/null 2>&1; echo -ne "FET\n";   } &
# Quan acaba l'nmap, mata el procès en background de l'dhcpdump
wait -n > /dev/null 2>&1
pkill -P $$ $! 2>/dev/null

# No fem cas al header, per això,  el primer cop ens ho saltem.
# Considerem un block quan s'obre i es tanca amb la ristra de guions
first_time=true
block=""

while read -r line; do

	if [ $first_time != true ]; then
		block="${block}$line\n"
	fi


	if [ "$line" == "---------------------------------------------------------------------------" ]; then
		
		if [ $first_time == false ]; then
		
			server_ip=`echo -e $block | awk '/Server identifier/{print $7}'`
			mac_address=`echo -e $block | awk '/IP:/{print $3}' | tr -d "()"`
			offered_ip=`echo -e $block | awk '/YIADDR:/{print $2}'`
			lease_time=`echo -e $block | awk '/IP address leasetime/{print $8 " " $9}'`

			echo -e "	DHCP SERVER: $server_ip" >> $LOGFILE
			echo -e "	ADR. FÍSICA: $mac_address" >> $LOGFILE
			echo -e "------------------------------------------------" >> $LOGFILE
			echo -e " IP oferida			$offered_ip" >> $LOGFILE
			echo -e " Temps prèstec			$lease_time" >> $LOGFILE
			echo -e "------------------------------------------------" >> $LOGFILE

			block=""
		fi
		
		first_time=false
	fi
	
done < "$TMP_FILE"

# Si existeix el fitxer temporal, esborrem
if [ -f $TMP_FILE ]; then
	rm $TMP_FILE 
fi


echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "\n---------------- Data fi: $(date '+%Y-%m-%d %H:%M:%S') ----------------" >> $LOGFILE

cat $LOGFILE
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



