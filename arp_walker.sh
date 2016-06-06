#!/bin/bash
#######################################################################################################
##################################### ARP_WALK 1.2 ####################################################
############### Author: Yago M. Laignie®  #####  All rights reserved 2016 #############################
### The code shows the router arp table, locally or remotely, using SNMP queries on ifRoute-mib .21 ###
#######################################################################################################

# Parameters
IP=$1
COM=$2

# CENTOS (need change in 'for' too)
THIS_IP=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.1 | cut -d'.' -f8-11 | awk {'print $1'})
MAC=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.1 | cut -d':' -f4)
IF_NUM=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.1 | awk {'print $4'})
IF_NAME=$(snmpget -v1 -c $COM $IP .1.3.6.1.2.1.2.2.1.2.$IF_NUM | awk {'print $4'})

# DEBIAN
#THIS_IP=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.1 | cut -d'.' -f13-16 | awk {'print $1'})
#MAC=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.1 | cut -d' ' -f4-9)
#IF_NUM=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.1 | awk {'print $4'})
#IF_NAME=$(snmpget -v1 -c $COM $IP .1.3.6.1.2.1.2.2.1.2.2 | cut -d'"' -f2)

echo -e "     IP      -        MAC        -       INTERFACE" > $IP.arp_table
echo -e "\n$THIS_IP - $MAC - $IF_NAME" >> $IP.arp_table

ROWS=$(snmpwalk -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1 | wc -l)
ROWS=$(expr $ROWS - 1)

for i in $(seq $ROWS);
	do
		#NEXT_IP=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1.$THIS_IP | cut -d'.' -f13-16 | awk {'print $1'})
		#NEXT_MAC=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1.$THIS_IP | cut -d' ' -f4-9)
		#NEXT_IF_NUM=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.1.2.1.$THIS_IP | awk {'print $4'})
		#NEXT_IF_NAME=$(snmpget -v1 -c $COM $IP .1.3.6.1.2.1.2.2.1.2.$IF_NUM | cut -d'"' -f2)

		NEXT_IP=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1.$THIS_IP | cut -d'.' -f8-11 | awk {'print $1'})
		NEXT_MAC=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.2.2.1.$THIS_IP | cut -d':' -f4)
		NEXT_IF_NUM=$(snmpgetnext -v1 -c $COM $IP .1.3.6.1.2.1.3.1.1.1.2.1.$THIS_IP | awk {'print $4'})
		NEXT_IF_NAME=$(snmpget -v1 -c $COM $IP .1.3.6.1.2.1.2.2.1.2.$NEXT_IF_NUM | awk {'print $4'})
		
		echo -e "$NEXT_IP - $NEXT_MAC - $NEXT_IF_NAME" >> $IP.arp_table
		THIS_IP=$NEXT_IP
		IF_NUM=$NEXT_IF_NUM
	done 
exit
