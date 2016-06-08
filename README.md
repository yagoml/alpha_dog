# Alph@_d0g v1.0 B3T@ _\|/_
Alpha Dog S.I.5


IMPORTANT!

Requisites to send mail alert:

Open the /etc/postfix/main.cf and add the following lines to the end of the file:
	myhostname = hostname.example.com
	relayhost = [smtp.gmail.com]:587
	smtp_use_tls = yes
	smtp_sasl_auth_enable = yes
	smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
	smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt
	smtp_sasl_security_options = noanonymous
	smtp_sasl_tls_security_options = noanonymous

The Gmail credentials must now be added for authentication. Create a /etc/postfix/sasl_passwd file and add following line:
	[smtp.gmail.com]:587 username:password
	
	
Requisites to fix MAC ADDRESS of service:

Requires rw permissions (rwcommunity) of snmp (/etc/snmp/snmpd.conf)
