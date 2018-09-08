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
# chmod 755 /etc/init.d/firewall.sh
# ou
# chmod +x /etc/init.d/firewall.sh
###############################################################################

firewall_start() {
	echo "********************************************"
	echo "*  CARREGANDO CONFIGURAÇÃO DO FIREWALL     *"
	echo "********************************************"

}
firewall_stop() {
	echo "********************************************"
	echo "*           DESLIGANDO FIREWALL            *"
	echo "********************************************"
}
firewall_restart() {
   firewall_start
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
