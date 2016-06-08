#!/bin/bash
#######################################################################################################
########################################### ALPHA_DOG 1.0 #############################################
######################################### ARP TABLE PROTECTOR ######################################### 
###############$$$$$$$$ Author: Yago M. Laignie®  #####  All rights reserved 2016 #####################
#######################################################################################################

RANGE=$1 	# TARGET NETWORK RANGE IPs
PORT=$2 	# TARGET PORT
PROTOCOL=$3 	# LOWERCASE !
COM=$4		# COMMUNITY

# CHECK LOCAL IPs
NUM_LOCAL_IPs=$(snmpwalk -v1 -c $COM localhost .1.3.6.1.2.1.4.20.1.1 | wc -l)

if (($NUM_LOCAL_IPs < 2));then
	echo "IP Lan local não definido, saindo..."
	exit
fi

ROWS_THIS_TABLE=$(snmpwalk -v1 -c $COM localhost .1.3.6.1.2.1.3.1.1.2.2.1 | wc -l)

if (($ROWS_THIS_TABLE < 3));then
	echo 'É necessário popular a tabela ARP deste host...'
	echo 'Digite a faixa de ips (range) da rede para gerar a tabela:'
	read RANGE_TABLE
	if [ $RANGE_TABLE != '' ]; then
		# Scan to populate this host arp table
		nmap -sS -O -P0 -p $PORT -v $RANGE_TABLE
	fi

fi

# Get real open $PORT IPs:
#FIND_IPs=$(nmap -sS -O -P0 -p $PORT -v $RANGE | grep -E open[[:space:]]port[[:space:]]$PORT/$PROTOCOL | cut -d' ' -f6)

# Play TEST with local IPs:
FIND_IPs=('localhost 127.0.0.1')

LAN_IP=$(snmpgetnext -v1 -c $COM localhost .1.3.6.1.2.1.4.20.1.1.127.0.0.1 | awk {'print $4'})

# Determine length of IPs string by words
ROWS=$(echo $FIND_IPs | wc -w)
# Arp Tables save directory
mkdir -p arp_tables

# Walk on Find IPs getting and saving its arp tables, then compares it with original services.conf MAC Addressesice 
for i in $(seq $ROWS); do 
	THIS_IP=$(echo $FIND_IPs | cut -d' ' -f$i)
	./arp_walker.sh $THIS_IP $COM
	echo ""
	echo -e "\033[4mHOST: $THIS_IP\033[0m"

	grep -v '#' services.conf | while read -r ROW ; do
		CONFIG_NAME=$(echo $ROW | cut -d',' -f1)
		CONFIG_IP=$(echo $ROW | cut -d',' -f2)
		CONFIG_MAC=$(echo $ROW | cut -d',' -f3)
		NS_CONFIG_MAC=$(echo $ROW | cut -d',' -f3 | tr -d '[[:space:]]')

		i=1	# Counter to indicate header lines number of arp_table for each IP
		while read ROW; do
			if (($i > 2)); then # Scape header lines
				ARP_IP=$(echo $ROW | cut -d'-' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//') # Explode and remove spaces.	
				ARP_MAC=$(echo $ROW | cut -d'-' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
				NS_MAC=$(echo $ARP_MAC | tr -d '[[:space:]]')
				FW_MAC=$(echo $ARP_MAC | tr '[[:space:]]' ':')

				if [ $CONFIG_IP == $ARP_IP ]; then
					if [ $NS_CONFIG_MAC != $NS_MAC ]; then
						echo -e "\033[01;31mService $CONFIG_NAME: IP:$ARP_IP -> MAC: $ARP_MAC\033[0m"
						echo -e "\033[01;31mALERT DANGER! MAC Address doesn't match with original $CONFIG_NAME MAC Address !\033[0m"
						echo -e "\033[1;34mBlocking divergent MAC Adress of $CONFIG_NAME service...\033[0m"
						iptables -A FORWARD -m mac --mac-source $FW_MAC -j DROP
						echo -e "\033[1;34mReconfiguring $CONFIG_NAME service with original MAC Address: $CONFIG_MAC...\033[0m"
						snmpset -v 2c -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1.$ARP_IP x $CONFIG_MAC
						echo -e "\033[1;34mSending Alert...!\033[0m"
						while read ROW; do
							MAIL=$ROW
							echo "Alert danger found in host: $LAN_IP for service $CONFIG_NAME: IP: $ARP_IP -> MAC: $ARP_MAC - MAC Address doesn't match with original $CONFIG_NAME MAC Address ($CONFIG_MAC)" | mail -s "Alpha Dog Alert-Danger!" $MAIL
						done < mail.conf

					else
						echo -e "\033[1;32mService $CONFIG_NAME: IP: $ARP_IP -> MAC: $ARP_MAC\033[0m"
					fi
				fi
			fi
			i=$((i+1))
		done < $THIS_IP.arp_table
	done
	mv $THIS_IP.arp_table arp_tables
done

exit
