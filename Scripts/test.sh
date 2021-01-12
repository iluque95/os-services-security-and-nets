#!/bin/bash

line="MIWIFI_2G_JKR2;AP;Unknown;10;2.457GHz;8C:15:C7:90:5C:3C;-80;54;Not associated;No attempts;"

max_chars_essid=14
max_chars_vendor=7

linia=`echo $line | awk -v essid=$max_chars_essid -v vendor=$max_chars_vendor 'END{

                                split ($0, av1, ";");

                                for(i in av1){values++};

                                out="";

                                for (i=1; i<values; ++i) {
                                    
                                    out=sprintf("%s%s",out,av1[i]) 

                                    if (i==1) for (j=0; j<(essid-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ")	# FORMATA ESSID
                                    if (i==2) for (j=0; j<(3-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA TYPE
                                    if (i==3) for (j=0; j<(vendor-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 	# FORMATA VENDOR
                                    if (i==4) for (j=0; j<(2-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA CHANNEL
                                    if (i==5) for (j=0; j<(8-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA FREQUENCY
                                    if (i==6) out=sprintf("%s%s",out," ") 												# FORMATA MAC
                                    if (i==7) for (j=0; j<(4-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA SIGNAL
                                    if (i==8) for (j=0; j<(3-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA BANDWITH
                                    if (i==9) for (j=0; j<(14-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ASSOCIATION
                                    if (i==10) for (j=0; j<(11-length(av1[i])+1); ++j) out=sprintf("%s%s",out," ") 		# FORMATA ATTEMPT

                                }

                                print out;

                            }'`
#echo "Formatted-line; $linia"

test="58:BD:A3:E3:FC:4C, 2019-06-13 16:27:40, 2019-06-13 16:27:40, -80,        2, (not associated) ,Orange-0B36"

awk -F "," '{for (i=1; i<NF; ++i) print i " " $i}' <<< $test

awk -F "," 'BEGIN {essid = " Unknown"} {if (length($14)>1) essid=$14 } END{print essid}' <<< $test | cut -c2-

#awk -F "," '{print $9}' | tr -d " "

cipher=`echo $test | awk -F "," '{if (substr($6,0,17)==" (not associated)") print 1; else print 0;}'`

echo $cipher

aps="MOVISTAR_FBE1;AP;Comtrend Corporation;F8:8E:85:FF:FB:E2;11;2.462GHz;-79;54;WEP;Not associated;No attempts;\nMiFibra-DCF6;AP;Unknown;94:6A:B0:99:DC:F8;1;2.412GHz;-77;54;WPA2;Not associated;No attempts;\nMIWIFI_2G_JKR2;AP;Unknown;8C:15:C7:90:5C:3C;10;2.457GHz;-78;54;WPA2;Not associated;No attempts;\nOrange-A3CD;AP;Arcadyan Technology Corporation;88:03:55:D6:A3:CF;11;2.462GHz;-78;54;WPA2;Not associated;No attempts;\nOjoberque;AP;Unknown;4C:1B:86:AC:5E:15;1;2.412GHz;-74;54;WPA2;Not associated;No attempts;\nvodafone9232;AP;Unknown;3C:98:72:2E:92:33;1;2.412GHz;-75;54;WPA2;Not associated;No attempts;\n.:RouteR:.;AP;Unknown;E2:41:36:3A:9E:88;11;2.462GHz;-70;54;WPA2;Not associated;No attempts;\nDIRECT-A3-BRAVIA;AP;Unknown;8E:57:9B:0D:EC:37;11;2.462GHz;-71;54;WPA2;Not associated;No attempts;\nSWV 733 A2 2.4G;AP;Winstars Technology Ltd;80:3F:5D:B3:B2:67;11;2.462GHz;-20;54;WPA2;Not associated;No attempts;\n"

mac="1B:86:AC:5E:15"

essid=`echo -e $aps | grep $mac | awk -F ";" '{print $1}'`

echo "ESSID $essid"

nr=2

essid=`echo -e $aps | awk -F ";" -v line=$nr '{if (NR==line) print $1}'`

echo "ESSID $essid"

oldIFS=$IFS

IFS=""

for block in `lshw -C network | sed -n "/network/,/network/p"`; do
    echo "YEEEEP $block"
done

IFS=$oldIFS

echo $1
