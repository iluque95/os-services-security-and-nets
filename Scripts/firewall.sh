#!/bin/bash
# DECLARACIONS PÚBLIQUES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FILE="/var/log/messages"
OUTPUT="fw_warnings.txt"
OW_FILE=true
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# MAIN DE L'SCRIPT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Variables per emmagatzemar les dades recollides
SSH=""
ICMP=""
DNS=""
OTHERS=""

if [[ $(id -u) -ne 0 ]] ; then echo "Si us plau executi amb permisos root" ; exit 1 ; fi

start="$(date '+%Y-%m-%d %H:%M:%S')"

#XIVATO
echo -e "Inici $start"

#XIVATO
echo -ne "Llegin el log... "

# Recorre totes i cada una de les linies registrades per el loggin
while read -r line; do

	date=""
	iface_in=""
	iface_out=""
	src_ip=""
	dst_ip=""
	src_port=0
	dst_port=0
	proto=""
	type=0

	dst_port=`echo -e $line | tr ' ' '\n' | grep "^DPT=" | cut -d "=" -f2 | awk 'END{if(length($0)==0) $0="Dada no proporcionada\n"; print $0}'`
	date=`echo -e $line| awk '{print $1 " " $2 " " $3}'`
	iface_in=`echo -e $line | tr ' ' '\n' | grep "^IN=" | cut -d "=" -f2 | awk 'END{if(length($0)==0) $0="Dada no proporcionada\n"; print $0}'`
	iface_out=`echo -e $line | tr ' ' '\n' | grep "^OUT=" | cut -d "=" -f2 | awk 'END{if(length($0)==0) $0="Dada no proporcionada\n"; print $0}'`
	src_ip=`echo -e $line | tr ' ' '\n' | grep "^SRC=" | cut -d "=" -f2`
	dst_ip=`echo -e $line | tr ' ' '\n' | grep "^DST=" | cut -d "=" -f2`
	proto=`echo -e $line | tr ' ' '\n' | grep "^PROTO=" | cut -d "=" -f2`
	src_port=`echo -e $line | tr ' ' '\n' | grep "^SPT=" | cut -d "=" -f2 | awk 'END{if(length($0)==0) $0="Dada no proporcionada\n"; print $0}'`
	type=`echo -e $line | tr ' ' '\n' | grep "^TYPE=" | cut -d "=" -f2`
	
	if [[ "$proto" == "ICMP" && $type -eq 8 ]]; then
		ICMP="${ICMP}"
		ICMP="${ICMP}------------ $date -------------\n"
		ICMP="${ICMP}Interfície entrada:\t\t$iface_in\n"
		ICMP="${ICMP}Interfície sortida:\t\t$iface_out\n"
		ICMP="${ICMP}@ origen:\t\t\t$src_ip\n"
		ICMP="${ICMP}@ destí:\t\t\t$dst_ip\n"
		ICMP="${ICMP}Protocol:\t\t\t$proto\n"
		ICMP="${ICMP}Port origen:\t\t\t$src_port\n"
		ICMP="${ICMP}Port destí:\t\t\t$dst_port\n"
		ICMP="${ICMP}-------------------------------------\n"
	else
		if [ $dst_port == 22 ]; then
			dst_ip=`echo $dst_ip | cut -d " " -f2`
			proto=`echo $proto | cut -d " " -f2`
			SSH="${SSH}"
			SSH="${SSH}------------ $date -------------\n"
			SSH="${SSH}Interfície entrada:\t\t$iface_in\n"
			SSH="${SSH}Interfície sortida:\t\t$iface_out\n"
			SSH="${SSH}@ origen:\t\t\t$src_ip\n"
			SSH="${SSH}@ destí:\t\t\t$dst_ip\n"
			SSH="${SSH}Protocol:\t\t\t$proto\n"
			SSH="${SSH}Port origen:\t\t\t$src_port\n"
			SSH="${SSH}Port destí:\t\t\t$dst_port\n"
			SSH="${SSH}-------------------------------------\n"
		elif [ $dst_port == 53 ]; then
			DNS="${DNS}"
			DNS="${DNS}------------ $date -------------\n"
			DNS="${DNS}Interfície entrada:\t\t$iface_in\n"
			DNS="${DNS}Interfície sortida:\t\t$iface_out\n"
			DNS="${DNS}@ origen:\t\t\t$src_ip\n"
			DNS="${DNS}@ destí:\t\t\t$dst_ip\n"
			DNS="${DNS}Protocol:\t\t\t$proto\n"
			DNS="${DNS}Port origen:\t\t\t$src_port\n"
			DNS="${DNS}Port destí:\t\t\t$dst_port\n"
			DNS="${DNS}-------------------------------------\n"
		elif [ $dst_port -lt 1024 ]; then
			OTHERS="${OTHERS}"
			OTHERS="${OTHERS}------------ $date -------------\n"
			OTHERS="${OTHERS}Interfície entrada:\t\t$iface_in\n"
			OTHERS="${OTHERS}Interfície sortida:\t\t$iface_out\n"
			OTHERS="${OTHERS}@ origen:\t\t\t$src_ip\n"
			OTHERS="${OTHERS}@ destí:\t\t\t$dst_ip\n"
			OTHERS="${OTHERS}Protocol:\t\t\t$proto\n"
			OTHERS="${OTHERS}Port origen:\t\t\t$src_port\n"
			OTHERS="${OTHERS}Port destí:\t\t\t$dst_port\n"
			OTHERS="${OTHERS}------------------------------------------\n"
		fi
	fi
	
done < <(tail -n51 $FILE | grep "IPTables-Dropped:")

#XIVATO
echo -ne "FET\n"

SSH=`echo $SSH | awk 'END{if(length($0)==0) $0="No s ha trobat cap atac al port 22.\n"; print $0}'`
ICMP=`echo $ICMP | awk 'END{if(length($0)==0) $0="No s ha trobat cap atac del tipus ICMP.\n"; print $0}'`
DNS=`echo $DNS | awk 'END{if(length($0)==0) $0="No s ha trobat cap atac al port 53.\n"; print $0}'`
OTHERS=`echo $OTHERS | awk 'END{if(length($0)==0) $0="No s ha trobat cap atac als ports 1:1023.\n"; print $0}'`

if [ $OW_FILE == true ]; then 

	echo -e "\n---------------- Data inici: $start ----------------" > $OUTPUT
else
	echo -e "\n---------------- Data inici: $start ----------------" >> $OUTPUT
fi

echo -e "Possibles atacs SSH\n\n $SSH" >> $OUTPUT	
echo -e "Possibles atacs ICMP\n\n $ICMP" >> $OUTPUT
echo -e "Possibles atacs DNS\n\n $DNS" >> $OUTPUT
echo -e "Possibles atacs a ports ben coneguts\n\n $OTHERS" >> $OUTPUT

echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "\n---------------- Data fi: $(date '+%Y-%m-%d %H:%M:%S') ----------------" >> $OUTPUT

cat $OUTPUT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%