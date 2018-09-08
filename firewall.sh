#!/bin/bash
###############################################################################
# Nome: firewall.sh
# Local: /etc/init.d/
# Autor: Adilson Bortoloso
# Criação: 08/09/2018
# Modificação: 08/09/2018
# Função: Arquivo de configuração do firewall IpTables
# Utilização: firewall.sh start|stop|restart
#	sudo sh /etc/init.d/firewall.sh start
#	sudo sh /etc/init.d/firewall.sh stop
#	sudo sh /etc/init.d/firewall.sh restart
#
# Marcar como executável
# sudo chmod 755 /etc/init.d/firewall.sh
# ou
# sudo chmod +x /etc/init.d/firewall.sh
#
# Colocar como inicialização automática
# sudo update-rc.d firewall.sh defaults
#
# Tirar da inicialização automática
# sudo update-rc.d firewall.sh remove
###############################################################################

firewall_start() {
	echo "Habilitando Firewall"
	#######################################################################
	# CARREGANDO CONFIGURAÇÃO DO FIREWALL
	#######################################################################

	# Carregando os modulos do iptables
	/sbin/modprobe ip_tables
	/sbin/modprobe ip_conntrack
	/sbin/modprobe iptable_filter
	/sbin/modprobe iptable_mangle
	/sbin/modprobe iptable_nat
	/sbin/modprobe ipt_LOG
	/sbin/modprobe ipt_limit
	/sbin/modprobe ipt_state
	/sbin/modprobe ipt_REDIRECT
	/sbin/modprobe ipt_owner
	/sbin/modprobe ipt_REJECT
	/sbin/modprobe ipt_MASQUERADE
	/sbin/modprobe ip_conntrack_ftp
	/sbin/modprobe ip_nat_ftp

	# Limpar regras
	iptables -X
	iptables -Z
	iptables -F INPUT
	iptables -F OUTPUT
	iptables -F FORWARD
	iptables -F -t nat
	iptables -F -t mangle

	# Definindo a política default das cadeias
	iptables -t filter -P INPUT DROP
	iptables -t filter -P OUTPUT ACCEPT
	iptables -t filter -P FORWARD DROP
	iptables -t nat -P PREROUTING ACCEPT
	iptables -t nat -P OUTPUT ACCEPT
	iptables -t nat -P POSTROUTING ACCEPT
	iptables -t mangle -P PREROUTING ACCEPT
	iptables -t mangle -P OUTPUT ACCEPT

	# Manter conexões já estabelecidas para nao parar
	# iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	# iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	# iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	# Aceita todo o trafego vindo do loopback e indo pro loopback
	iptables -t filter -A INPUT -i lo -j ACCEPT

	#######################################################################
	# PROTEÇÕES
	#######################################################################

	# Desabilitando o tráfego IP
	echo "0" > /proc/sys/net/ipv4/ip_forward

	# Configurando a proteção anti-spoofing
	for spoofing in /proc/sys/net/ipv4/conf/*/rp_filter; do
	        echo "1" > $spoofing
	done

	# Impedindo que um atacante possa maliciosamente alterar alguma rota
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects

	# Impedindo que o atacante determine o "caminho" que seu
	# pacote vai percorrer (roteadores) até seu destino.
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route

	# Proteção contra responses bogus
	echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses

	# Proteção contra ataques de syn flood (inicio da conexão TCP).
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies

	# Protege contra os "Ping of Death"
	iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 20/m -j ACCEPT
	iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 20/m -j ACCEPT

	# Protege contra port scanners avançados (Ex.: nmap)
	iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 20/m -j ACCEPT

	# Bloqueando tracertroute
	iptables -A INPUT -p udp -s 0/0 -i eth0 --dport 33435:33525 -j REJECT

	# Protecoes contra ataques
	iptables -A INPUT -m state --state INVALID -j REJECT

	#######################################################################
	# TABELA INPUT
	#######################################################################

	# Liberando porta 22 (ssh)
	iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT

	# Liberando porta 80 (http)
	iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT

	# Liberando porta 8080 (http) - Oracle Apex
	iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT

	# Liberando porta 3128 (Squid)
	# iptables -A FORWARD -i eth0 -p tcp --dport 3128 -j ACCEPT

	# Sockets validos
	iptables -A INPUT -m state --state ESTABLISHED,RELATED,NEW -j ACCEPT

	#######################################################################
	# TABELA FORWARD
	#######################################################################

	# Libera computador das regras do firewall
	# iptables -A FORWARD -s 10.0.0.150 -p tcp  -j ACCEPT
	# iptables -A FORWARD -s 10.0.0.150 -p udp  -j ACCEPT

	# Ativar o mascaramento (nat).
	iptables -t nat -F POSTROUTING
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

	# Liberando porta 53 (DNS)
	iptables -A FORWARD -i eth0 -p tcp --dport 53 -j ACCEPT
	iptables -A FORWARD -i eth0 -p udp --dport 53 -j ACCEPT

	# Liberando Porta 25 (smtp)
	iptables -A FORWARD -i eth0 -p tcp --dport 25 -j ACCEPT

	# Liberando Porta 110 (pop-3)
	iptables -A FORWARD -i eth0 -p tcp --dport 110 -j ACCEPT

	# Liberando Porta 21 (ftp)
	iptables -A FORWARD -i eth0 -p tcp --dport 21 -j ACCEPT

	# Sockets válidos
	iptables -A FORWARD -m state --state ESTABLISHED,RELATED,NEW -j ACCEPT

	#######################################################################
	# TABELA NAT
	#######################################################################

	# Mascaramento de rede para acesso externo #
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

	#Bloqueia todo o resto
	#iptables -A INPUT -p tcp -j LOG --log-level 6 --log-prefix "FIREWALL: GERAL "
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p tcp -j DROP
	iptables -A INPUT -p udp -j DROP

	echo "1" > /proc/sys/net/ipv4/ip_forward
	echo "Firewall habilitado"
}
firewall_stop() {
	echo "Desabilitando Firewall"
	#######################################################################
	# DESLIGANDO FIREWALL
	#######################################################################

	# Limpa as regras
	iptables -X
	iptables -Z
	iptables -F INPUT
	iptables -F OUTPUT
	iptables -F FORWARD
	iptables -F -t nat
	iptables -F -t mangle

	# Definindo a política default das cadeias
	iptables -t filter -P INPUT ACCEPT
	iptables -t filter -P OUTPUT ACCEPT
	iptables -t filter -P FORWARD ACCEPT
	iptables -t nat -P PREROUTING ACCEPT
	iptables -t nat -P OUTPUT ACCEPT
	iptables -t nat -P POSTROUTING ACCEPT
	iptables -t mangle -P PREROUTING ACCEPT
	iptables -t mangle -P OUTPUT ACCEPT

	# Manter conexões já estabelecidas para nao parar
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	# Aceita todo o trafego vindo do loopback e indo pro loopback
	iptables -t filter -A INPUT -i lo -j ACCEPT

	# Mascaramento de rede para acesso externo #
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	echo "Firewall desabilitado"
}
firewall_restart() {
	echo "Reiniciando Firewall"
	firewall_stop
	sleep 3
	firewall_start
	echo "Firewall reiniciado"
}

case "$1" in
'start')
  firewall_start
  ;;
'stop')
  firewall_stop
  ;;
'restart')
  firewall_restart
  ;;
*)
  firewall_start
esac
