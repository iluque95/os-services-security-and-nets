#!/bin/bash

#DECLARACIONS PÚBLIQUES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LOGFILE="wifi_output.log"
LOGFILE_OVERWRITE=true
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# FUNCIONS
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
getLink()
{
	if [ $1 == "UP" ]; then
		echo "Amb paràmetres"
	elif [ $1 == "UNKNOWN" ]; then
		echo "Desconegut"
	else
		echo "Sense paràmetres"
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
enableIface()
{	
	# Renombrem a igestio *NO*
	#`ip link set $1 name igestio`
	`ip link set $1 up`
}
print_s()
{
	if [ -z "$1" ]; then
		echo "No s'ha pogut obtindre"
	else
		echo -e $1
	fi
}
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#MAIN DE L'SCRIPT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if [[ $(id -u) -ne 0 ]] ; then echo "Si us plau executi amb permisos root" ; exit 1 ; fi

channel_param=$1

start="$(date '+%Y-%m-%d %H:%M:%S')"

#XIVATO
echo -e "Inici $start"


if [ $LOGFILE_OVERWRITE ]; then
	echo -e "---------------- Data inici: $start ----------------\n" > $LOGFILE
else
	echo -e "---------------- Data inici: $start ----------------\n" >> $LOGFILE
fi

#Obtenim les ifaces que siguin wifi
for iface in `ls /sys/class/net`; do

	if [ ! -d "/sys/class/net/$iface/wireless" ]; then continue; fi;

	active=`ip addr show $iface | grep "<" | cut -d "<" -f2 | cut -d ">" -f1 | grep "UP"`
	
	if [ -z "$active" ]; then
		echo -ne "La interfície $iface es troba baixada. Aixencant... "
		$(enableIface $iface)
		echo -ne "OK\n"
	fi

	mac=`ip -o link | grep $iface | awk '{print substr($17,0,14)}'`

	# Informació del driver (NO VÀLID PER A TOTES LES IFACES)
	#driver=`ethtool -i $iface | grep driver`
	#description=`modinfo $driver | grep "description:" | cut -d ":" -f2 | cut -c5-`
	#firmware=`modinfo $driver | awk '/firmware:/ {print $2}'`
	#version=`modinfo $driver | awk '/^version:/ {print $2}'`

	driver=`lshw -C network | grep $mac -C 5 | grep driver | awk -F " " '{print $3}' | cut -d"=" -f2`
	firmware=`lshw -C network | grep $mac -C 5 | grep driver | awk -F " " '{print $4}' | cut -d"=" -f2`
	version=`lshw -C network | grep $mac -C 5 | grep driver | awk -F " " '{print $5}' | cut -d"=" -f2`

	bands=`iwlist $iface frequency | grep "Channel 40\>"| awk 'BEGIN{bands="2.4GHz"}{ if(length($0)>0) bands=sprintf("%s %s",bands,"& 5GHz")} END {print bands}'`
	mode=`iwconfig $iface | awk -F " " '/Mode:/{print $1}' | cut -d ":" -f2`
	transmission=`iwconfig $iface | grep "Tx-Power" | awk -F "=" '{print $2}'`
	
	#XIVATO
	echo -ne "Posant interfície en mode monitor $iface... "

	if [ `ip addr show $iface | grep -c "ieee802.11"` -eq 0 ]; then

		airmon-ng start $iface > /dev/null
				
	fi

	monitor=`ip -o link | grep $mac | awk '{print $2}' | cut -d ":" -f1 | tail -1`

	if [ ! -z "$monitor" ]; then
		#XIVATO
		echo -ne "OK\n"

		#XIVATO
		echo -ne "Comprovant xarxes Wi-Fi operatives (escanejant amb $monitor)... "

		if [ ! -z $channel_param ]; then
			airodump-ng $monitor -W --write output.csv --output-format csv -c $channel_param > /dev/null 2>&1 & sleep 15
		else
			airodump-ng $monitor -W --write output.csv --output-format csv > /dev/null 2>&1 & sleep 15
		fi
		
		#XIVATO
		echo -ne "OK\n"

		essid=""
		type=""
		vendor=""
		channel=""
		frequency=""
		mac=""
		signal=""
		bandwith=""
		association=""
		attempt=""
		cipher=""

		max_chars_essid=0
		max_chars_vendor=0

		aps=""

		# Llegeix APS
		while read -r line; do
			tmp=`echo $line | awk -F "," 'BEGIN {essid = " Unknown"} {if (length($14)>1) essid=$14 } END{print essid}' | cut -c2-`
			
			if [ ${#tmp} -gt $max_chars_essid ]; then max_chars_essid=${#tmp}; fi

			essid="${essid}$tmp;"
			
			type="${type}AP;"

			tmp=`echo $line | awk -F "," '{print $1}' | tr -d ":"`
			tmp=`echo $tmp | awk '{print substr($0,0,6)}'`
			tmp=`cat mac-list.txt | grep $tmp | awk 'BEGIN {vendor = " Unknown"} {if (length($0)>0) vendor=""; for (i=2; i<=NF; ++i) {vendor=vendor" "$i} } END{print vendor}' | cut -c2-`
			
			if [ ${#tmp} -gt $max_chars_vendor ]; then max_chars_vendor=${#tmp}; fi

			vendor="${vendor}$tmp;"

			tmp=`echo $line | awk '{print $6}' | tr -d ",:"`

			channel="${channel}$tmp;"

			if [ ${#tmp} -eq 1 ]; then tmp="0${tmp}"; fi

			tmp=`cat frequency_list.txt | grep "Channel ${tmp}\>" | awk '{print $4$5}'`

			frequency="${frequency}$tmp;"

			tmp=`echo $line | awk -F "," '{print $1}'`

			mac="${mac}$tmp;"

			tmp=`echo $line | awk -F "," '{print $9}' | tr -d " "`

			signal="${signal}$tmp;"

			tmp=`echo $line | awk -F "," '{print $5}' | tr -d " "`

			bandwith="${bandwith}${tmp};"

			association="${association}Not associated;"
			
			attempt="${attempt}No attempts;"

			cipher=`echo $line | awk -F "," '{print $6}' | awk '{print $1}'`
			cipher="${cipher};"

			aps="${aps}${essid}${type}${vendor}${mac}${channel}${frequency}${signal}${bandwith}${cipher}${association}${attempt}\n"

			#echo -e "$line"

			essid=""
			type=""
			vendor=""
			channel=""
			frequency=""
			mac=""
			signal=""
			bandwith=""
			association=""
			attempt=""
			cipher=""

		done < <(cat output.csv-01.csv | sed -n "/BSSID, First time seen/,/Station MAC/p" | head -n -2 | tail -n +2)

		cli=""

		# Llegeix CLI
		while read -r line; do

			#nr=`echo $line | awk -F "," '{print $5}' | tr -d " "`
			associated=`echo $line | awk -F "," '{if (substr($6,0,17)==" (not associated)") print 0; else print 1;}'`
			if [ $associated -ne 0 ]; then APmac=`echo $line | awk -F "," '{print $6}'`; fi
			
			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac| awk -F ";" '{print $1}'`; else tmp="Unknown"; fi

			if [ ${#tmp} -eq 0 ]; then tmp="Unknown"; fi

			essid="${essid}${tmp};" 	# ESSID del AP al que està connectat
			
			type="${type}CLI;"

			tmp=`echo $line | awk -F "," '{print $1}' | tr -d ":"`
			tmp=`echo $tmp | awk '{print substr($0,0,6)}'`
			tmp=`cat mac-list.txt | grep $tmp | awk 'BEGIN {vendor = " Unknown"} {if (length($0)>0) vendor=""; for (i=2; i<=NF; ++i) {vendor=vendor" "$i} } END{print vendor}' | cut -c2-`
			
			if [ ${#tmp} -gt $max_chars_vendor ]; then max_chars_vendor=${#tmp}; fi

			vendor="${vendor}${tmp};"

			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac | awk -F ";" '{print $5}'`; else tmp="--"; fi

			channel="${channel}${tmp};"

			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac | awk -F ";" '{print $6}'`; else tmp="--"; fi

			frequency="${frequency}$tmp;"

			tmp=`echo $line | awk -F "," '{print $1}'`

			mac="${mac}${tmp};"

			tmp=`echo $line | awk -F "," '{print $4}' | tr -d " "`

			signal="${signal}${tmp};"

			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac | awk -F ";" '{print $8}'`; else tmp="--"; fi

			bandwith="${bandwith}${tmp};"

			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac | awk -F ";" '{print $4}'`; else tmp="Not associated"; fi

			association="${association}${tmp};" 	# MAC del AP al que està connectat

			if [ $associated -ne 0 ]; then tmp=`echo $line | awk -F "," '{for (i=6; i<NF; ++i) gsub(/ /, "", $i); print $i;}' | tr -d "()" | cut -c2-`; fi

			if [ ${#tmp} -eq 0 ]; then tmp="No attempts"; fi

			attempt="${attempt}${tmp};"

			if [ $associated -ne 0 ]; then tmp=`echo -e $aps | grep $APmac | awk -F ";" '{if(substr($9,0,14)=="not associated") print "No attempts"; else print $9;}'`; else tmp="--"; fi

			cipher="${cipher}${tmp};"

			cli="${cli}${essid}${type}${vendor}${mac}${channel}${frequency}${signal}${bandwith}${cipher}${association}${attempt}\n"

			essid=""
			type=""
			vendor=""
			channel=""
			frequency=""
			mac=""
			signal=""
			bandwith=""
			association=""
			attempt=""
			cipher=""

		done < <(cat output.csv-01.csv | sed -n "/Station MAC/,//p" | tail -n +2 | head -n -1)

		# PRINTA CAPÇALERA FORMATEJADA

		for (( c=1; c<=(($max_chars_essid+$max_chars_vendor+90+$max_chars_essid)); c++ )); do echo -n "-" >> $LOGFILE; done; echo >> $LOGFILE
		echo -n "IFACE: $iface, MONITOR: $monitor. DRIVER: $driver, FIRMWARE: $firmware, VERSION: $version. BANDS: $bands, MODE: $mode, TX-POWER: $transmission" >> $LOGFILE; echo >> $LOGFILE
		for (( c=1; c<=(($max_chars_essid+$max_chars_vendor+90+$max_chars_essid)); c++ )); do echo -n "-" >> $LOGFILE; done; echo >> $LOGFILE

		echo -n "ESSID" >> $LOGFILE; for (( c=1; c<=(($max_chars_essid-5)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "TYPE " >> $LOGFILE;
		echo -n "VENDOR" >> $LOGFILE; for (( c=1; c<=(($max_chars_vendor-6)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "MAC" >> $LOGFILE; for (( c=1; c<=15; c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "CHANNEL " >> $LOGFILE;
		echo -n "FREQUENCY " >> $LOGFILE;
		echo -n "SIGNAL " >> $LOGFILE;
		echo -n "BANDWITH " >> $LOGFILE;
		echo -n "CIPHER " >> $LOGFILE;
		echo -n "ASSOCIATION" >> $LOGFILE; for (( c=1; c<=((6)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "ATTEMPT" >> $LOGFILE; for (( c=1; c<=7; c++ )); do echo -n " " >> $LOGFILE; done ; echo >> $LOGFILE

		echo -n "-----" >> $LOGFILE; for (( c=1; c<=(($max_chars_essid-5)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "---- " >> $LOGFILE;
		echo -n "------" >> $LOGFILE; for (( c=1; c<=(($max_chars_vendor-6)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "---" >> $LOGFILE; for (( c=1; c<=15; c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "------- " >> $LOGFILE;
		echo -n "--------- " >> $LOGFILE;
		echo -n "------ " >> $LOGFILE;
		echo -n "-------- " >> $LOGFILE;
		echo -n "------ " >> $LOGFILE;
		echo -n "-----------" >> $LOGFILE; for (( c=1; c<=((6)+1); c++ )); do echo -n " " >> $LOGFILE; done
		echo -n "-------" >> $LOGFILE; for (( c=1; c<=7; c++ )); do echo -n " " >> $LOGFILE; done ; echo >> $LOGFILE

		# FORMATA APS
		while read -r line; do


			linia=`echo $line | awk -v essid=$max_chars_essid -v vendor=$max_chars_vendor '{
			
											split ($0, av1, ";");

											for(i in av1){values++};

											out="";

											for (i=1; i<values; ++i) {
												
												out=sprintf("%s%s",out,av1[i]) 

												if (i==1) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ")	# FORMATA ESSID
												if (i==2) for (j=0; j<(4-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA TYPE
												if (i==3) for (j=0; j<(vendor-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA VENDOR
												if (i==4) out=sprintf("%s%s",out," ") 												# FORMATA MAC
												if (i==5) for (j=0; j<(7-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CHANNEL
												if (i==6) for (j=0; j<(9-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA FREQUENCY
												if (i==7) for (j=0; j<(6-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA SIGNAL
												if (i==8) for (j=0; j<(8-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA BANDWITH
												if (i==9) for (j=0; j<(6-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CIPHER
												if (i==10) for (j=0; j<(17-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA ASSOCIATION
												if (i==11) for (j=0; j<(11-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ATTEMPT

											}

											print out;

										}'`
			echo "$linia" >> $LOGFILE
		done < <(echo -e "$aps" | head -n -1)

		# FORMATA CLI
		while read -r line; do

			linia=`echo $line | awk -v essid=$max_chars_essid -v vendor=$max_chars_vendor '{
			
											split ($0, av1, ";");

											for(i in av1){values++};

											out="";

											for (i=1; i<values; ++i) {
												
												out=sprintf("%s%s",out,av1[i]) 

												if (i==1) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ")	# FORMATA ESSID
												if (i==2) for (j=0; j<(4-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA TYPE
												if (i==3) for (j=0; j<(vendor-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA VENDOR
												if (i==4) out=sprintf("%s%s",out," ") 												# FORMATA MAC
												if (i==5) for (j=0; j<(7-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CHANNEL
												if (i==6) for (j=0; j<(9-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA FREQUENCY
												if (i==7) for (j=0; j<(6-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA SIGNAL
												if (i==8) for (j=0; j<(8-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA BANDWITH
												if (i==9) for (j=0; j<(6-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CIPHER
												if (i==10) for (j=0; j<(17-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA ASSOCIATION
												if (i==11) for (j=0; j<(11-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ATTEMPT

											}

											print out;

										}'`
			echo "$linia" >> $LOGFILE
		done < <(echo -e "$cli" | head -n -1)

		for (( c=1; c<=(($max_chars_essid+$max_chars_vendor+90+$max_chars_essid)); c++ )); do echo -n "-" >> $LOGFILE; done; echo >> $LOGFILE
		
		rm output.csv-01.csv

		#XIVATO
		echo -ne "Aturant interfície en mode monitor $monitor... "

		airmon-ng stop $monitor > /dev/null

		#XIVATO
		echo -ne "OK\n"
	
	else
		#XIVATO
		echo -ne "ERROR\n"
	fi
	
done

# Mata tots els processo airodump-ng

killall airodump-ng > /dev/null 2>&1

echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "\n---------------- Data fi: $(date '+%Y-%m-%d %H:%M:%S') ----------------" >> $LOGFILE

cat $LOGFILE
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%