#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source ${DIR}/config_var.sh

function logger()
{
       #echo "$@"
        echo $(date +"%b-%d-%Y %H:%M:%S")"$@" >> ${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log

}

#Start the script function
function start_script()
{
        logger " | "
        logger " | ##############################################################################"
        logger " | Starting Script : "${BASH_SOURCE[0]}
        logger " | ##############################################################################"
        logger " | "

}


#Exit function
function exit_script()
{
        #logger "| ##############################################################################"
        logger " | Ending Script : "${BASH_SOURCE[0]}
        logger " | ##############################################################################"
        logger " | "
        exit
}



#check if necessary directories are present
function check_dir_creation()
{
        if [ ! -d ${LOG_DIR} ]
        then
                mkdir -p ${LOG_DIR}
                touch ${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log
                logger " | "
                logger " | Created Script Log Directory : "${LOG_DIR}
                logger " | Created Script Log File : "${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log

        fi

        if [ ! -f ${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log ]
        then
                touch ${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log
                logger " | "
                logger " | Created Script Log File : "${LOG_DIR}/${LOG_FILE_PREFIX}${LOG_DATE}.log

        fi


        if [ ! -d ${EMS_SCRIPTS_REPO} ]
        then

                mkdir -p ${EMS_SCRIPTS_REPO}
                logger " | Created EMS Script Repo : "${EMS_SCRIPTS_REPO}
        fi

        #if [ ! -d ${CONNECTION_REPO} ]
        #then
        #        mkdir -p ${CONNECTION_REPO}
        #        logger " | Created EMS Connections Repo : "${CONNECTION_REPO}
        #fi

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
                logger " | Created server info script : "`basename ${EMS_SERVER_INFO}`
        fi


        if [ ! -f ${EMS_CONNECTIONS_INFO} ]
        then

                echo "show connections full" > ${EMS_CONNECTIONS_INFO}
                logger " | Created server info script : "`basename ${EMS_CONNECTIONS_INFO}`
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
        logger " | EMS Config File Check : [ COMPLETE ]"

}


#is_active $TIBEMSADMIN $URL $USER $PASSWORD_FILE $SCRIPT
function active_ems()
{
        TIBEMSADMIN=${1}
        #EMS=${2}
        EMS1=`echo ${2} | awk -F"," '{print $1}'`
        EMS2=`echo ${2} | awk -F"," '{print $2}'`

        USER=${3}
        PASSWORD_FILE=${4}
        SCRIPT=${5}

        logger " | Checking Active EMS From FT Pair "${EMS1}" and "${EMS2}
        #logger "************************"
        #logger ${TIBEMSADMIN} -server ${EMS1} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore
        #logger "**************"
        #${TIBEMSADMIN} -server ${EMS1} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore
        EMS1_STATE=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
        EMS2_STATE=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`

        #logger ${EMS1_STATE}
        #logger ${EMS2_STATE}
        #If connection or any other error connecting to EMS
        if [ ${EMS1_STATE} = 'active' ]
        then
        #If ems is active
                EMS1_NAME=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore | grep "Server:" | grep "version"| awk '{print $2}'| sed "s/\ //g"`
                logger " | "
                logger " | Active EMS Name : "${EMS1_NAME}
                logger " | Active EMS Url : "${EMS1}
                echo ${EMS1}"|"${EMS1_NAME}

        elif [ ${EMS2_STATE} = 'active' ]
        then
                EMS2_NAME=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore | grep "Server:" | grep "version"| awk '{print $2}' | sed "s/\ //g"`
                logger " | "
                logger " | Active EMS Name : "${EMS2_NAME}
                logger " | Active EMS Url : "${EMS2}
                echo ${EMS2}"|"${EMS2_NAME}

        else
        #EMS state is neither error or active
                logger " | "
                logger " | Error while connecting to EMSes"
                logger " | Error EMS Name : "${ERROR_STATE}
                logger " | Error EMS Url : "${EMS1}","${EMS2}
                echo ${ERROR_STATE}
        fi
        logger " | Active EMS Check : [ COMPLETE ]"
        logger " | "

}

#run_ems_script $TIBEMSADMIN $ACTIVEURL $USER $PASSWORD_FILE $SCRIPT
function run_ems_script()
{
        TIBEMSADMIN=${1}
        EMS=${2}
        USER=${3}
        PASSWORD_FILE=${4}
        SCRIPT=${5}
        FILETOSTOR=${6}
        logger " | "
        logger " | Running "`basename ${SCRIPT}`" On "${EMS}


        #${TIBEMSADMIN} -server ${EMS} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore | sed '1,10d'
        ${TIBEMSADMIN} -server ${EMS} -user ${USER} -pwdfile ${PASSWORD_FILE} -script ${SCRIPT} -ignore
        logger " | "`basename ${SCRIPT}`" : [ COMPLETE ]"
        logger " | "

}



function main()
{
        cat ${CONFIG_FILE} | grep ${ENV} | while read line
        do
                ####################################################################
                # ENV|EMSURL|USERNAME|HOSTPREFIX
                # ENV|EMSURL|USERNAME|HOSTPREFIX
                ####################################################################
                URL=`echo ${line} | awk -F"|" '{print $2}'`

                #active_ems $TIBEMSADMIN $URL $USER $PASSWORD_FILE $SCRIPT returns URL|EMSNAME

                URL_AND_NAME=`active_ems ${TIBEMSADMIN} ${URL} ${USER} ${PASSWORD_FILE} ${EMS_SERVER_INFO}`
                ACTIVE_EMS=`echo ${URL_AND_NAME} | awk -F"|" '{print $1}'`
                ACTIVE_EMS_NAME=`echo ${URL_AND_NAME} | awk -F"|" '{print $2}'`
                #logger " | Checking ====> "${ACTIVE_EMS}" "${ACTIVE_EMS_NAME}
                #check if ACTIVE EMS errored out
                if [[  -z ${ACTIVE_EMS}  ||  -z ${ACTIVE_EMS_NAME}  ||  ${ACTIVE_EMS} = 'ERROR-ACTIVE-STATE' ||  ${ACTIVE_EMS_NAME} = 'ERROR-ACTIVE-STATE' ]]
                then
                        logger " | "
                        logger " | Error While Processing Line : "${line}
                        logger " | ACTIVE_EMS or ACTIVE_EMS_NAME Check Failed"
                        logger " | Moving To Next Line In EMS Config"
                        logger " | "
                        continue
                fi

                #Use url to find connections for username and hostprefix and use the name to name all temp files and scripts
                USERNAME=`echo ${line} | awk -F"|" '{print $3}'`
                HOSTPREFIX=`echo ${line} | awk -F"|" '{print $4}'`

                #Get All connections and save it in file using below script
                #run_ems_script $TIBEMSADMIN $ACTIVEURL $USER $PASSWORD_FILE $SCRIPT
                #Keep all temporary connections files
                #TEMP_DIR=${SCRIPT_HOME}/temp
                #TEMP_CONN_SNAP_FILE_SUFFIX="_connection_snap.txt"
                #${TEMP_DIR}/${ACTIVE_EMS_NAME}${TEMP_CONN_SNAP_FILE_SUFFIX}


                CONNECTION_FILE=${TEMP_DIR}/${ACTIVE_EMS_NAME}${TEMP_CONN_SNAP_FILE_SUFFIX}

                #Run connection script
                logger " | "
                #logger " | Running connection snapshot on:"${ACTIVE_EMS}

                run_ems_script ${TIBEMSADMIN} ${ACTIVE_EMS} ${USER} ${PASSWORD_FILE} ${EMS_CONNECTIONS_INFO} | grep -v "SASB Pre Dlv" | awk '{print $4"|"$7"|"$8"|"$9}' > ${CONNECTION_FILE}
                logger " | "${CONNECTION_FILE}" : [ CREATED ]"
                logger " | "

                # From connections filter the connection ids and build delete script of connection ids
                # Keeps all EMS Scripts
                # EMS_SCRIPTS_REPO=${SCRIPT_HOME}/scripts/
                # EMS_SERVER_INFO=${EMS_SCRIPTS_REPO}/server_info.sh
                # Template for EMS specific script
                # EMS_CONN_DEL_SCRIPT_TEMPLATE="_del_user_connections.sh"

                #CONNECTION_SCRIPT=${EMS_SCRIPTS_REPO}/${ACTIVE_EMS_NAME}${EMS_CONN_DEL_SCRIPT_TEMPLATE}
                CONNECTION_SCRIPT=${EMS_SCRIPTS_REPO}/${ACTIVE_EMS_NAME}"_"${USERNAME}"_"${HOSTPREFIX}"_"${EMS_CONN_DEL_SCRIPT_TEMPLATE}
                logger " | "
                logger " | Following Connections Will Be Deleted:"
                conn_count=0

                #Inform user on connections to be deleted connections
                cat ${CONNECTION_FILE} | grep ${USERNAME} | grep ${HOSTPREFIX} | while read connection
                do
                        ((conn_count++))
                        logger " |  |->["${conn_count}"] "${connection}
                        #echo " |--->["${conn_count}"] "${connection}
                done

                cat ${CONNECTION_FILE} | grep ${USERNAME} | grep ${HOSTPREFIX} | awk -F"|" '{print $1}' > ${CONNECTION_SCRIPT}
                #logger " | "
                #logger " | Created delete connenction script : "`basename ${CONNECTION_SCRIPT}`
                #logger " | "$(wc -l ${CONNECTION_SCRIPT} | awk '{print $1}')" connections will be deleted"
                sed -i "s/^/delete connection /g" ${CONNECTION_SCRIPT}
                logger " | "
                logger " | "${CONNECTION_SCRIPT}" : [ CREATED ]"
               # Execute the delete connections script
                logger " | "
                logger " | Deleting "${USERNAME}" connections"
               # cat ${CONNECTION_SCRIPT}
                logger " | Connection deletion : [ COMPLETE ]"
        done
}

#main
check_dir_creation
logger " | "

start_script

check_configs
logger " | "

check_scripts
logger " | "

main
logger " | "

exit_script
