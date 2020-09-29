#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${DIR}/config.sh

function logger()
{
#       echo "$@"
        echo $(date)"$@" >> ${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log

}

#Start the script function
function start_script()
{
        logger
        logger "##############################################################################"
        logger " | Starting Delete Connection Script"
        logger "##############################################################################"
        logger

}


#Exit function
function exit_script()
{
        #logger "##############################################################################"
        logger " | Ending Delete Connection Script"
        logger "##############################################################################"
        logger
        exit
}



#check if necessary directories are present
function check_dir_creation()
{
        if [ ! -d ${LOG_DIR} ]
        then
                mkdir -p ${LOG_DIR}
                logger " | Created Script Log Directory : "${LOG_DIR}
        fi

        if [ ! -d ${EMS_SCRIPTS_REPO} ]
        then
                
                mkdir -p ${EMS_SCRIPTS_REPO}
                logger " | Created EMS Script Repo : "${EMS_SCRIPTS_REPO}
        fi

        if [ ! -d ${CONNECTION_REPO} ]
        then
                mkdir -p ${CONNECTION_REPO}
                logger " | Created EMS Connections Repo : "${CONNECTION_REPO}
        fi
        
        if [ ! -d ${TEMP_DIR} ]
        then
                mkdir -p ${TEMP_DIR}
                logger " | Created Temp Directory : "${TEMP_DIR}
        fi
        
        if [ ! -d ${CONFIG_DIR} ]
        then
                mkdir -p ${CONFIG_DIR}
                logger " | Created Config Directory : "${CONFIG_DIR}
        fi

}


#check if necessary scripts are present
function check_scripts()
{

        if [ ! -f ${EMS_SERVER_INFO} ]
        then
                
                echo "info" > ${EMS_SERVER_INFO}
                logger " | Created server info script : "${EMS_SERVER_INFO}
        fi
	
	
	if [ ! -f ${EMS_CONNECTIONS_INFO} ]
        then
                
                echo "show connections full" > ${EMS_CONNECTIONS_INFO}
                logger " | Created server info script : "${EMS_CONNECTIONS_INFO}
        fi
}


#check if necessary configs are present
function check_configs()
{

        if [ ! -f ${CONFIG_FILE} ]
        then
                logger " | Missing config file : "${CONFIG_FILE}
                exit_script
        fi

}


#is_active $TIBEMSADMIN $URL $USER $PWD $SCRIPT
function is_active()
{
        TIBEMSADMIN=${1}
        #EMS=${2}
        EMS1=`echo ${2} | awk -F"," '{print $1}'`
        EMS2=`echo ${2} | awk -F"," '{print $2}'`
                
        USER=${3}
        PWD=${4}
        SCRIPT=${5}
        
        logger " | Checking active server between "${EMS1}" and "${EMS2}
        
        EMS1_STATE=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
        EMS2_STATE=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
        

        #If connection or any other error connecting to EMS
        if [ ${EMS1_STATE} = 'active' ]
        then
        #If ems is active
                EMS1_NAME=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep "Server:" | awk '{print $2}' | sed "s/\ //g"`
                echo ${EMS1}"|"${EMS1_NAME}
                
        elif [ ${EMS2_STATE} = 'active' ]
        then
                EMS2_NAME=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep "Server:" | awk '{print $2}' | sed "s/\ //g"`
                echo ${EMS2}"|"${EMS2_NAME}
                
        else
        #EMS state is neither error or active
                echo ${ERROR_STATE}
        fi

}

#run_ems_script $TIBEMSADMIN $ACTIVEURL $USER $PWD $SCRIPT
function run_ems_script()
{
        TIBEMSADMIN=${1}
        EMS=${2}
        USER=${3}
        PWD=${4}
        SCRIPT=${5}
        
        ${TIBEMSADMIN} -server ${EMS} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | sed '1,10d'

}


#connectionStatus
function connectionStatus(){
        #echo "Count Username Destination"
	logger " | Taking connection snapshot for "$1
        echo "show connections full" | $1 -server $2 -user $3 -password $4 | sed '1,10d' | grep -v "SASB Pre Dlv" | awk '{print $4"|"$7"|"$8"|"$9}' 
        logger " | Connection Snapshot Complete!"
}



function main()
{
        cat ${CONFIG_FILE} | grep ${ENV} | while read line
        do
                ####################################################################
                # ENV|EMSURL|USERNAME|HOSTPREFIX
                # ENV|EMSURL|USERNAME|HOSTPREFIX
		# TXPROD|ssl://f-tibems001lp:14100,ssl://f-tibems002lp:14100|apijavaota|10.20.30
                ####################################################################
                URL=`echo ${line} | awk -F"|" '{print $2}'`

                #active_ems $TIBEMSADMIN $URL $USER $PWD $SCRIPT returns URL|EMSNAME
                URL_AND_NAME=`active_ems ${TIBEMSADMIN} ${URL} ${USER} ${PWD} ${EMS_SERVER_INFO}`
                ACTIVE_EMS=`echo ${URL_AND_NAME} | awk -F"|" '{print $1}'`
                ACTIVE_EMS_NAME=`echo ${URL_AND_NAME} | awk -F"|" '{print $2}'`

		#check if ACTIVE EMS errored out
		if [ ! -z ${ACTIVE_EMS} || ! -z ${ACTIVE_EMS_NAME} ||  ${ACTIVE_EMS} = 'ERROR-ACTIVE-STATE' || ${ACTIVE_EMS_NAME} = 'ERROR-ACTIVE-STATE' ]
		then
			logger " | Error while processing line : "${line}
			logger " | ACTIVE_EMS or ACTIVE_EMS_NAME check failed"
			continue
		fi
                
                #Use url to find connections for username and hostprefix and use the name to name all temp files and scripts
                USERNAME=`echo ${line} | awk -F"|" '{print $3}'`
                HOSTPREFIX=`echo ${line} | awk -F"|" '{print $4}'`
                
		#Get All connections and save it in file using below script
		#run_ems_script $TIBEMSADMIN $ACTIVEURL $USER $PWD $SCRIPT
		#Keep all temporary connections files 
		#TEMP_DIR=${SCRIPT_HOME}/temp
		#TEMP_CONN_SNAP_FILE_SUFFIX="_connection_snap.txt"
		#${TEMP_DIR}/${ACTIVE_EMS_NAME}${TEMP_CONN_SNAP_FILE_SUFFIX}


		CONNECTION_FILE = ${TEMP_DIR}/${ACTIVE_EMS_NAME}${TEMP_CONN_SNAP_FILE_SUFFIX}
		run_ems_script $TIBEMSADMIN $ACTIVEURL $USER $PWD $SCRIPT | grep -v "SASB Pre Dlv" | awk '{print $4"|"$7"|"$8"|"$9}' > ${CONNECTION_FILE}
		logger " | Created connection file : "${CONNECTION_FILE}
		                
                # From connections filter the connection ids and build delete script of connection ids
		# Keeps all EMS Scripts
		# EMS_SCRIPTS_REPO=${SCRIPT_HOME}/scripts/
		# EMS_SERVER_INFO=${EMS_SCRIPTS_REPO}/server_info.sh
		# Template for EMS specific script
		# EMS_CONN_DEL_SCRIPT_TEMPLATE="_del_user_connections.sh"

		CONNECTION_SCRIPT = ${EMS_SCRIPTS_REPO}/${ACTIVE_EMS_NAME}${EMS_CONN_DEL_SCRIPT_TEMPLATE}
		cat ${CONNECTION_FILE} | grep ${USERNAME} | grep ${HOSTPREFIX} | awk -F"|" '{print $1}' > ${CONNECTION_SCRIPT}
		logger " | Created delete conenction script : "${CONNECTION_SCRIPT}
		logger " | This will delete "$(wc - l ${CONNECTION_SCRIPT})" connections"
		sed -i "s/^/delete connection /g" ${CONNECTION_SCRIPT}
               
               # Execute the delete connections script

        done
}
