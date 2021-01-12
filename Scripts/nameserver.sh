#!/bin/bash

#DECLARACIONS PÚBLIQUES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LOGFILE="nameservers.txt"
LOGFILE_OVERWRITE=true
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# FUNCIONS
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
print_s()
{
	if [ -z "$1" ]; then
		echo "No s'ha pogut obtindre"
	else
		echo $1
	fi
}
usage()
{
	echo "Usage: nameserver.sh <domain> <nameserver>"
	exit 1
}
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#MAIN DE L'SCRIPT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if [[ $(id -u) -ne 0 ]] ; then echo "Si us plau executi amb permisos root" ; exit 1 ; fi

if [[ $# -ne 2 ]] ; then usage; fi

start="$(date '+%Y-%m-%d %H:%M:%S')"

#XIVATO
echo -e "Inici $start"




if [ $LOGFILE_OVERWRITE ]; then
	echo -e "---------------- Data inici: $start ----------------\n" > $LOGFILE
else
	echo -e "---------------- Data inici: $start ----------------\n" >> $LOGFILE
fi


#XIVATO
echo -ne "Trobant correu de l'administrador "
email=`dig @$2 SOA $1 +short | awk '{print $2}' | awk -v domain="$1" '
														{ 
														  split($0, chars, "")
														  split(domain,chars2,"")
														  dots=2
														  
														  for (i=0; i<length(domain); i++)
														  {
														  	if (chars2[i]==".") dots++;
														  }
														  
														  dots2=0
														  for (i=length($0); i>=0; i--)
														  {
														  	if (chars[i]==".") dots2++;
															if (dots2==dots)
															{
																chars[i]="@";
																break;
															}
														  }
														  
														} END{for (i=0; i <= length($0); i++){printf chars[i]} }'`

#XIVATO														
if [[ $? -ne 0 ]]; then  
	echo -ne "ERROR\n"
else
	echo -ne "FET\n"
fi

if [[ ${#email} -eq 0 ]] ; then 
	echo -e "\nAlguna cosa ha anat malament... Les possibles causes són:" 
	echo -e "  1. $1 no és un domini sinó un equip"
	echo -e "  2. El domini no existeix"
	echo -e "  3. No té registre SOA (poc probable en una zona)"
	echo -e "  4. El DNS $2 no pot resoldre\n"
	
	echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"
	exit 1 
fi


#XIVATO
echo -ne "Trobant el servidor màster "
master=`dig @$2 SOA $1 +short 2>/dev/null | awk '{print $1}'`
#XIVATO														
if [[ $? -ne 0 ]]; then  
	echo -ne "ERROR\n"
else
	echo -ne "FET\n"				 
fi

#XIVATO
echo -ne "Trobant els servidors esclaus "
slaves=`dig @$2 NS $1 +short 2>/dev/null | sort |  awk -v master="$master" '{if ($0!=master) print $0;}' | awk -v master="$master" ' {
																																		if (NR>1) print "\t\t\t" $0; 
																																		else print $0;

																																	}'`	# TREU EL SERVIDOR MÀSTER DELS ESCLAUS
#XIVATO														
if [[ $? -ne 0 ]]; then  
	echo -ne "ERROR\n"
else
	echo -ne "FET\n"				 
fi

#XIVATO
echo -ne "Trobant els servidors de correu "
mx=`dig @$2 MX $1 +short 2>/dev/null | sort | awk '{print $2}'`
mx_formatted=`dig @$2 MX $1 +short 2>/dev/null | sort | awk '{
									if (NR>1) print "\t\t\t" $2 " amb prioritat " $1; 
									else print $2 " amb prioritat " $1;
												}'`
#XIVATO														
if [[ $? -ne 0 ]]; then  
	echo -ne "ERROR\n"
else
	echo -ne "FET\n"				 
fi

#XIVATO
echo -ne "Resolent els dominis "
a="$1. --> `dig @$2 A $1 +short 2>/dev/null`\n$master --> `dig @$2 A $master +short 2>/dev/null`\n"

for ip in $esclaus; do
	tmp=`dig @$2 A $ip +short 2>/dev/null`
	a="${a}${ip} --> ${tmp}\n"
done

for ip in $mx; do
	tmp=`dig @$2 A $ip +short 2>/dev/null`
	a="${a}${ip} --> ${tmp}\n"
done

a_formatted=`echo -e $a | awk '{
											if (NR>1) print "\t\t\t" $0; 
											else print $0;
														}'`
#XIVATO														
if [[ $? -ne 0 ]]; then  
	echo -ne "ERROR\n"
else
	echo -ne "FET\n"				 
fi

echo -e "Correu administrador	$email\n" >> $LOGFILE
echo -e "Servidor màster 	$master\n" >> $LOGFILE
echo -e "Servidors esclaus	${slaves:-Dada no trobada}\n" >> $LOGFILE
echo -e "Servidors de correu	${mx_formatted:-Dada no trobada}\n" >> $LOGFILE
echo -e "Registres A		${a_formatted:-No es pot resoldre}\n" >> $LOGFILE


echo -e "Fi $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "\n---------------- Data fi: $(date '+%Y-%m-%d %H:%M:%S') ----------------" >> $LOGFILE

cat $LOGFILE
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
