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
        echo "$@" >> ${LOGDIR}/${LOGFILEPREFIX}${LOGDATE}.log

}


function check_dir_creation()
{
        if [ ! -d ${LOGDIR} ]
        then
                mkdir -p ${LOGDIR}
                logger "Created Script Log Directory : "${LOGDIR}
        fi

        if [ ! -d ${EMSSCRIPTSREPO} ]
        then
                
                mkdir -p ${EMSSCRIPTSREPO}
                logger "Created EMS Script Repo : "${EMSSCRIPTSREPO}
        fi

        if [ ! -d ${CONNECTIONREPO} ]
        then
                mkdir -p ${CONNECTIONREPO}
                logger "Created EMS Connections Repo : "${CONNECTIONREPO}
        fi


}



#is_active $TIBEMSADMIN $URL $USER $PWD $SCRIPT
function is_active()
{
        TIBEMSADMIN=${1}
        EMS=${2}
        USER=${3}
        PWD=${4}
        SCRIPT=${5}
        
        EMSSTATE=`${TIBEMSADMIN} -server ${EMS} -user ${USER} -password ${PWD} -script ${SCRIPT} -ignore | grep State | awk '{print $2}'`
 

        #If connection or any other error connecting to EMS
        if [ ! -z ${EMSSTATE} ]
        then
                echo "ERROR-ACTIVE-STATE"
        elif [ ${EMS1STATE} = 'active' ]
        then
        #If ems is active
                echo ${EMSSTATE}
        else
        #EMS state is neither error or active
                echo "FT"                
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

       EMS1=`echo ${url} | awk -F"," '{print $1}'`
        EMS2=`echo ${url} | awk -F"," '{print $2}'`
