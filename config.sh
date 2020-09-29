#!/bin/bash

# https://unix.stackexchange.com/questions/216910/bash-command-to-source-a-file-in-a-different-directory
# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself

# create user t_user "testing" password=""
# grant admin t_user view-server, view-connection, change-connection
# 

#Package Name
MAINDIR=

#Base directory
SCRIPT_HOME=/opt/scripts
LOGS_HOME=/opt/script_logs/

#Keeps all the logs
LOG_DIR=${LOGS_HOME}/logs/
LOG_DATE=$(date +"%Y%m%d")
LOG_FILE_PREFIX="ta_del_connections_"

#Keeps all the connections snapshots
CONNECTION_REPO=${SCRIPT_HOME}/connections/

#Keeps all EMS Scripts
EMS_SCRIPTS_REPO=${SCRIPT_HOME}/scripts/
EMS_SERVER_INFO=${EMS_SCRIPTS_REPO}/server_info.sh

#Template for EMS specific script
EMS_CONN_SCRIPT_TEMPLATE="_show_connections.sh"
EMS_CONN_DEL_SCRIPT_TEMPLATE="_del_user_connections.sh"

#Keep all temporary connections files 
TEMP_DIR=${SCRIPT_HOME}/temp

#Snapshots file
TEMP_CONN_SNAP_FILE_SUFFIX="_connection_snap.txt"
TEMP_SERVER_SNAP_FILE_SUFFIX="_server_info_snap.txt"

#Keep the config from where to delete connections 
CONFIG_DIR=${SCRIPT_HOME}/config
CONFIG_FILE=${CONFIG_DIR}/ems_config.txt
####################################################################
# ENV|EMSURL|USERNAME|HOSTPREFIX
# ENV|EMSURL|USERNAME|HOSTPREFIX
####################################################################

#Error string which script will return when ems is not active
ERROR_STATE="ERROR-ACTIVE-STATE|ERROR-ACTIVE-STATE"

#
EMS_URLS=
EMS_HOME=/tibco/ems/8.3/bin/
TIBEMSADMIN=${EMS_HOME}/tibemsadmin
USER=
PASSWORD_FILE=
ENV=
