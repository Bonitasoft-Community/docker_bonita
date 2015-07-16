#!/bin/bash
# ensure to set the proper owner of data volume
if [ `stat -c %U /opt/bonita/` != 'bonita' ]
then
	chown -R bonita:bonita /opt/bonita/
fi
# ensure to apply the proper configuration
if [ ! -f /opt/${BONITA_VERSION}-configured ]
then
	sudo -u bonita --preserve-env /opt/files/config.sh && touch /opt/${BONITA_VERSION}-configured || exit 1
fi
# launch tomcat
exec sudo -u bonita /opt/bonita/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-7.0.55/bin/catalina.sh run
