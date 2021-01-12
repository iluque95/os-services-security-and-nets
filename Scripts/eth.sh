#!/bin/bash

#DECLARACIONS PÚBLIQUES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LOGFILE="info_eth.txt"
LOGFILE_OVERWRITE=true
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# FUNCIONS
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
getHumanUsers()
{
	users=""
	for user in `cut -d: -f1,3 /etc/passwd | egrep ':[0]{1}|:[0-9]{4}$' | cut -d: -f1 | cut -d: -f1 | paste -s -d ','`; do
		users="$users $user"
	done
	echo $users;
}

getSystemUsers()
{
	users=""
	for user in `cut -d: -f1,3 /etc/passwd | egrep -v ':[0]{1}|:[0-9]{4}$' | cut -d: -f1 | paste -s -d ','`; do
		users="$users $user"
	done
	echo $users;
}
getConnectedUsers()
{
	echo -e "`who -s | awk '{
			 	if (NR>1) print "\t\t\t" $0; 
				else print $0;
							}'`";
}
getLink()
{
	if [ $1 == "UP" ]; then
		echo "Activa"
	elif [ $1 == "UNKNOWN" ]; then
		echo "Desconegut"
	else
		echo "Desactivada"
	fi
}
getState()
{
	if [ ! -z "$1" ]; then
		echo "Activa"
	else
		echo "Desactivada"
	fi
}
getLocalhostName()
{
	hostname=`cat /etc/hosts | grep $1 | awk '{print $2}' | cut -d '.' -f1`

	echo $(print_s $hostname)
}
getLocalDNS()
{
	local_dns=`cat /etc/networks | grep $1 | awk '{print $1}'`
	
	echo $(print_s $local_dns)
}
getIfaceName()
{
	if [ ! -z "$2" ]; then
		echo "$1 ($2)"
	else
		echo "$1 (No configurada)"
	fi
}
getPublicIP() # Useless
{
	for ip in `dig ipecho.net +short`; do
		`ip route del $ip`
		`ip route add $ip via $1 dev $2`
	done
	
	echo "`wget -qO- https://ipecho.net/plain ; echo`"
}
delWebpageRoutes() # Useless
{
	for ip in `dig ipecho.net +short`; do
		`ip route del $ip`
	done
}
enableIface()
{	
	`ip link set $1 up`
}
print_s()
{
	if [ -z "$1" ]; then
		echo "No s'ha pogut obtindre"
	else
		echo $1
	fi
}
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#MAIN DE L'SCRIPT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if [[ $(id -u) -ne 0 ]] ; then echo "Si us plau executi amb permisos root" ; exit 1 ; fi

start="$(date '+%Y-%m-%d %H:%M:%S')"

#XIVATO
echo -e "Inici $start"


gateway=`ip r | grep default | awk '{print $3}'`

if [ ! -z "$gateway" ]; then

	publicIP=`wget -t 10 -qO- https://ipecho.net/plain ; echo`
	
	if [ -z "$publicIP" ]; then
		gateway="No hi ha ruta per defecte"
		externIP="No es pot sortir a inet"
	else
		publicIPname=`dig -x $publicIP +short 2>/dev/null`
		externIP="$publicIP ($publicIPname)"
	fi
	
else
	gateway="No hi ha ruta per defecte"
	externIP="No es pot sortir a inet"
fi

dns=`cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | awk '{
																		if (NR>1) print "\t\t\t" $0; 
																		else print $0;
																		}'`
#XIVATO
echo -ne "Comprovant usuaris del sistema... "

if [ $LOGFILE_OVERWRITE ]; then
	echo -e "---------------- Data inici: $start ----------------\n" > $LOGFILE
else
	echo -e "---------------- Data inici: $start ----------------\n" >> $LOGFILE
fi

echo -e "Usuaris del sistema " >> $LOGFILE
echo -e "-------------------\n " >> $LOGFILE
echo -e "Usuaris humans:		$(getHumanUsers)" >> $LOGFILE
echo -e "Usuaris connectats:	$(getConnectedUsers)\n" >> $LOGFILE
#echo -e "Usuaris de sistema: 	$(getSystemUsers)\n" >> $LOGFILE

#XIVATO
echo -ne "FET\n"

#XIVATO
echo -ne "Comprovant configuració de l'equip... "

echo -e "Configuració de l'equip " >> $LOGFILE
echo -e "-----------------------\n " >> $LOGFILE
echo -e "Direcció del router: 	$gateway" >> $LOGFILE
echo -e "Direcció externa: 	$externIP" >> $LOGFILE
echo -e "Direccions dels DNS: 	$dns\n" >> $LOGFILE

#XIVATO
echo -ne "FET\n"

echo -e "Informació de les interfícies" >> $LOGFILE
echo -e "-----------------------------\n" >> $LOGFILE


#Obtenim les ifaces cablejades
for iface in `ls /sys/class/net`; do

	if [ -d "/sys/class/net/$iface/wireless" ]; then continue; fi;

	active=`ip addr show $iface | grep "<" | cut -d "<" -f2 | cut -d ">" -f1 | grep "UP"`
	
	if [ -z "$active" ]; then
		echo -ne "La interfície $iface es troba baixada. Aixencant... "
		$(enableIface $iface)
		echo -ne "FET\n"
	fi
	
	#XIVATO
	echo -ne "Recollint informació de l'interfície $iface... "
	
	state=`ip addr show $iface | awk '/state/ {print $9}'`
	
	configuredBy=`cat /etc/network/interfaces | grep "^iface $iface" | awk '{print $4}'`
	mac=`ip addr show $iface | grep "link/" | awk '{print $2}'`
	ip=`ip addre show $iface | grep "inet" | grep -v "inet6" | awk '{print $2}' | cut -d "/" -f1`
	
	echo -e "Nom de la interfície: 	$(getIfaceName $iface $configuredBy)" >> $LOGFILE
	echo -e "Estat: 			$(getLink $state)" >> $LOGFILE
	echo -e "Adreça MAC: 		$mac" >> $LOGFILE

	# Si està connectada i a més té ip, es mostra l'informació d'aquesta.
	if ([ "$state" == "UP" ] || [ "$iface" == "lo" ]) && [ ! -z "$ip" ]; then
	
		for address in $ip; do

			cidr=`ip addr show $iface | grep $address | awk '{print $2}' | cut -d "/" -f2`
			netmask_hex=$(( 0xffffffff ^ ((1 << (32-$cidr)) -1) ))
			netmask=$(( (netmask_hex>>24) & 0xff )).$(( (netmask_hex>>16) & 0xff )).$(( (netmask_hex>>8) & 0xff )).$(( netmask_hex & 0xff ))
			broadcast=`ip addr show $iface | grep "brd\>" | awk 'NR==2 {print $4}'`

			IFS=. read -r i1 i2 i3 i4 <<< $address
			IFS=. read -r m1 m2 m3 m4 <<< $netmask
			network=`printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"`

			remote_machine_name=" "
			remote_network_name=" "
			
			# Comprova amb tots els servidors de noms en /etc/resolv.conf com es reconeix la màquina
			for dns_ip in $dns; do
				remote_machine_name=`dig @$dns_ip -x $address +short`
				
				# Comprova si ha hagut un error amb la comanda
				if (( $? )); then 
				{ 
					remote_machine_name=""
					continue; 
				} fi;
				
				if [ ! -z "$remote_machine_name" ]; then 
					break 
				fi
			done

			# Comprova amb tots els servidors de noms en /etc/resolv.conf com es reconeix la xarxa
			for dns_ip in $dns; do
				remote_network_name=`dig @$dns_ip -x $network +short`
				
				# Comprova si ha hagut un error amb la comanda
				if (( $? )); then 
				{ 
					remote_network_name=""
					continue; 
				} fi;
				
				if [ ! -z "$remote_network_name" ]; then 
					break 
				fi
			done

			#echo -e "Direcció IP pública: 		$(getPublicIP $ip $iface)" >> $LOGFILE
			echo -e "Direcció IP privada: 	$address" >> $LOGFILE
			echo -e "Màscara de l'equip: 	$netmask (/$cidr)" >> $LOGFILE
			echo -e "Direcció broadcast: 	$(print_s $broadcast)" >> $LOGFILE
			echo -e "Direcció de xarxa: 	$network" >> $LOGFILE
			echo -e "Nom local equip: 	$(getLocalhostName $address)" >> $LOGFILE
			echo -e "Nom local xarxa: 	$(getLocalDNS $network)" >> $LOGFILE
			echo -e "Nom DNS de l'equip: 	$(print_s $remote_machine_name)" >> $LOGFILE
			echo -e "Nom DNS de la xarxa: 	$(print_s $remote_network_name)" >> $LOGFILE
		done
		
		mtu=`ip addr show $iface | grep "mtu" | awk '{print $5}'`
		
		echo -e "MTU: 			$mtu\n" >> $LOGFILE
	else
		echo -e "" >> $LOGFILE
		
		# Iface activa, però, sense IP. Potser el DHCP no està responent o bé la conf. estàtica està malament.
		if [[ -z "$ip" &&  "$state" == "UP" ]]; then
			errors="${errors}Possibles problemes amb la configuració de la interfície $iface amb configuració $configuredBy\n"
		fi
	fi
	
	#XIVATO
	echo -ne "FET\n"
	
done

if [ ! -z "$errors" ]; then
	echo -e "ERRORS" >> $LOGFILE
	echo -e "------\n" >> $LOGFILE

	echo -e "$errors" >> $LOGFILE
fi

echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "\n---------------- Data fi: $(date '+%Y-%m-%d %H:%M:%S') ----------------" >> $LOGFILE

cat $LOGFILE
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%