#!/bin/bash
# ensure to apply the proper configuration
/opt/files/config.sh
chown -R bonita:bonita /opt/*
# launch tomcat
sudo -u bonita /opt/bonita/${BONITA_ARCHIVE_DIR}/bin/catalina.sh run
