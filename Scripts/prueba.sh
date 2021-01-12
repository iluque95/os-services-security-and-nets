#!/bin/bash

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

    bandwith="${bandwith}$tmp;"

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

done < <(cat output.csv-02.csv | sed -n "/BSSID, First time seen/,/Station MAC/p" | head -n -2 | tail -n +2)

cli=""

# Llegeix CLI
while read -r line; do

    nr=`echo $line | awk -F "," '{print $5}' | tr -d " "`
    associated=`echo $line | awk -F "," '{if (substr($6,0,17)==" (not associated)") print 0; else print 1;}'` 

    tmp="Unknown"
    
    if [ ${#tmp} -gt $max_chars_essid ]; then max_chars_essid=${#tmp}; fi

    essid="${essid}${tmp};"	# Station (CLIENT)
    
    type="${type}CLI;"

    tmp=`echo $line | awk -F "," '{print $1}' | tr -d ":"`
    tmp=`echo $tmp | awk '{print substr($0,0,6)}'`
    tmp=`cat mac-list.txt | grep $tmp | awk 'BEGIN {vendor = " Unknown"} {if (length($0)>0) vendor=""; for (i=2; i<=NF; ++i) {vendor=vendor" "$i} } END{print vendor}' | cut -c2-`
    
    if [ ${#tmp} -gt $max_chars_vendor ]; then max_chars_vendor=${#tmp}; fi

    vendor="${vendor}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $5}'`; else tmp="--"; fi

    channel="${channel}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $6}'`; else tmp="--"; fi

    frequency="${frequency}$tmp;"

    tmp=`echo $line | awk -F "," '{print $1}'`

    mac="${mac}${tmp};"

    tmp=`echo $line | awk -F "," '{print $4}' | tr -d " "`

    signal="${signal}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $8}'`; else tmp="--"; fi

    bandwith="${bandwith}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $1}'`; else tmp="Not associated"; fi

    association="${association}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk '{attempt=""; for (i=6; i<=NF; ++i) {attempt=attempt", "$i} } END{print attempt}'`; else tmp="No attempt"; fi
    
    tmp=`echo $line | awk -F "," '{print $6}' | tr -d "()" | cut -c2-`

    attempt="${attempt}${tmp};"

    if [ $associated -ne 0 ]; then tmp=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $9}'`; else tmp="--"; fi

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

done < <(cat output.csv-02.csv | sed -n "/Station MAC/,//p" | tail -n +2 | head -n -1)


echo -n "ESSID"; for (( c=1; c<=(($max_chars_essid-5)+1); c++ )); do echo -n " "; done
echo -n "TYPE ";
echo -n "VENDOR"; for (( c=1; c<=(($max_chars_vendor-6)+1); c++ )); do echo -n " "; done
echo -n "MAC"; for (( c=1; c<=15; c++ )); do echo -n " "; done
echo -n "CHANNEL ";
echo -n "FREQUENCY ";
echo -n "SIGNAL ";
echo -n "BANDWITH ";
echo -n "CIPHER ";
echo -n "ASSOCIATION"; for (( c=1; c<=(($max_chars_essid-11)+1); c++ )); do echo -n " "; done
echo -n "ATTEMPT"; for (( c=1; c<=7; c++ )); do echo -n " "; done ; echo

echo -n "-----"; for (( c=1; c<=(($max_chars_essid-5)+1); c++ )); do echo -n " "; done
echo -n "---- ";
echo -n "------"; for (( c=1; c<=(($max_chars_vendor-6)+1); c++ )); do echo -n " "; done
echo -n "---"; for (( c=1; c<=15; c++ )); do echo -n " "; done
echo -n "------- ";
echo -n "--------- ";
echo -n "------ ";
echo -n "-------- ";
echo -n "------ ";
echo -n "-----------"; for (( c=1; c<=(($max_chars_essid-11)+1); c++ )); do echo -n " "; done
echo -n "-------"; for (( c=1; c<=7; c++ )); do echo -n " "; done ; echo

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
                                        if (i==10) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA ASSOCIATION
                                        if (i==11) for (j=0; j<(11-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ATTEMPT

                                    }

                                    print out;

                                }'`
    echo "$linia"
done < <(echo -e "$aps" )

# FORMATA CLI
while read -r line; do

    linia=`echo $line | awk -v essid=$max_chars_essid -v vendor=$max_chars_vendor '{
    
                                    split ($0, av1, ";");

                                    for(i in av1){values++};

                                    out="";

                                    for (i=1; i<values; ++i) {
                                        
                                        out=sprintf("%s%s",out,av1[i]) 

                                        if (i==1) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ")	# FORMATA ESSID
                                        if (i==2) for (j=0; j<(3-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA TYPE
                                        if (i==3) for (j=0; j<(vendor-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA VENDOR
                                        if (i==4) out=sprintf("%s%s",out," ") 												# FORMATA MAC
                                        if (i==5) for (j=0; j<(2-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CHANNEL
                                        if (i==6) for (j=0; j<(8-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA FREQUENCY
                                        if (i==7) for (j=0; j<(4-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA SIGNAL
                                        if (i==8) for (j=0; j<(3-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA BANDWITH
                                        if (i==9) for (j=0; j<(4-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CIPHER
                                        if (i==10) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA ASSOCIATION
                                        if (i==11) for (j=0; j<(11-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ATTEMPT

                                    }

                                    print out;

                                }'`
    echo "$linia"
done < <(echo -e "$cli")

