#!/bin/bash

# create user t_user "testing" password=""
# grant admin t_user view-server, view-connection, change-connection
# 

#Package Name
MAINDIR=

#Base directory
SCRIPTHOME=/opt/scripts
LOGSHOME=/opt/script_logs/

#Keeps all the logs
LOGDIR=${LOGSHOME}/logs/
LOGDATE=$(date +"%Y%m%d")
LOGFILEPREFIX="ta_del_connections_"

#Keeps all the connections snapshots
CONNECTIONREPO=${SCRIPTHOME}/connections/

#Keeps all EMS Scripts
EMSSCRIPTSREPO=${SCRIPTHOME}/scripts/
EMSSERVERINFO=${EMSSCRIPTSREPO}/server_info.sh

#Template for EMS specific script
EMSCONNECTIONTEMPLATE="_show_connections.sh"
EMSDELTECONNECTIONTEMPLATE="_del_user_connections.sh"

#Keep all temporary connections files 
TEMPDIR=${SCRIPTHOME}/temp

#Snapshots file
TEMPCONNECTIONSNAP="_connection_snap.txt"
TEMPSERVERINFOSNAP="_server_info_snap.txt"

#Keep the config from where to delete connections 
CONFIGDIR=${SCRIPTHOME}/config
CONFIGFILE=${CONFIGDIR}/ems_config.txt
####################################################################
# ENV|EMSURL|USERNAME|HOSTPREFIX
# ENV|EMSURL|USERNAME|HOSTPREFIX
####################################################################



#
EMSURLS=
EMSHOME=/tibco/ems/8.3/bin/
TIBEMSADMIN=${EMSHOME}/tibemsadmin
USER=
PASSWORDFILE=
ENV=

function logger()
{
#       echo "$@"
        echo $(date)"$@" >> ${LOGDIR}/${LOGFILEPREFIX}${LOGDATE}.log

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
        if [ ! -d ${LOGDIR} ]
        then
                mkdir -p ${LOGDIR}
                logger " | Created Script Log Directory : "${LOGDIR}
        fi

        if [ ! -d ${EMSSCRIPTSREPO} ]
        then
                
                mkdir -p ${EMSSCRIPTSREPO}
                logger " | Created EMS Script Repo : "${EMSSCRIPTSREPO}
        fi

        if [ ! -d ${CONNECTIONREPO} ]
        then
                mkdir -p ${CONNECTIONREPO}
                logger " | Created EMS Connections Repo : "${CONNECTIONREPO}
        fi
        
        if [ ! -d ${TEMPDIR} ]
        then
                mkdir -p ${TEMPDIR}
                logger " | Created Temp Directory : "${TEMPDIR}
        fi
        
        if [ ! -d ${CONFIGDIR} ]
        then
                mkdir -p ${CONFIGDIR}
                logger " | Created Config Directory : "${CONFIGDIR}
        fi

}


#check if necessary scripts are present
function check_scripts()
{

        if [ ! -f ${EMSSERVERINFO} ]
        then
                
                echo "show info" > ${EMSSERVERINFO}
                logger " | Created server info script : "${EMSSERVERINFO}
        fi

}


#check if necessary configs are present
function check_configs()
{

        if [ ! -f ${CONFIGFILE} ]
        then
                logger " | Missing config file : "${CONFIGFILE}
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
        
        EMSSTATE1=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
        EMSSTATE2=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
        

        #If connection or any other error connecting to EMS
        if [ ${EMSSTATE1} = 'active' ]
        then
        #If ems is active
                EMS1NAME=`${TIBEMSADMIN} -server ${EMS1} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep "Server:" | awk '{print $2}' | sed "s/\ //g"`
                echo ${EMS1}"|"${EMS1NAME}
                
        elif [ ${EMSSTATE2} = 'active' ]
        then
                EMS2NAME=`${TIBEMSADMIN} -server ${EMS2} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep "Server:" | awk '{print $2}' | sed "s/\ //g"`
                echo ${EMS2}"|"${EMS2NAME}
                
        else
        #EMS state is neither error or active
                echo "ERROR-ACTIVE-STATE|ERROR-ACTIVE-STATE"
        fi

}

#find_aota_connections $TIBEMSADMIN $ACTIVEURL $USER $PWD $SCRIPT
function run_ems_script()
{
        TIBEMSADMIN=${1}
        EMS=${2}
        USER=${3}
        PWD=${4}
        SCRIPT=${5}
        
        ${TIBEMSADMIN} -server ${EMS} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore

}



function connectionStatus(){
        #echo "Count Username Destination"

        echo "show connections full" | $1 -server $2 -user $3 -password $4 | sed '1,10d' | grep -v "SASB Pre Dlv" | awk '{print $7" "$8" "$9}' | grep -v ${2} | sort -n | uniq -c
        echo "Connection Snapshot Complete!"
}



function main()
{
        cat ${CONFIGFILE} | grep ${ENV} | while read line
        do
                ####################################################################
                # ENV|EMSURL|USERNAME|HOSTPREFIX
                # ENV|EMSURL|USERNAME|HOSTPREFIX
                ####################################################################
                URL=`echo ${line} | awk -F"|" '{print $2}'`
                USERNAME=`echo ${line} | awk -F"|" '{print $3}'`
                HOSTPREFIX=`echo ${line} | awk -F"|" '{print $4}'`
                
                #active_ems $TIBEMSADMIN $URL $USER $PWD $SCRIPT returns URL|EMSNAME
                URL_AND_NAME=`active_ems ${TIBEMSADMIN} ${URL} ${USER} ${PWD} ${EMSSERVERINFO}`
                
                #Use url to find connections for username and hostprefix and use the name to name all temp files and scripts
                
               # From connections filter the connection ids and build delete script of connection ids
               
               # Execute the delete connections script

        done
}
