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


#is_active $TIBEMSADMIN $URL $USER $PWD
function is_active()
{
        EMS1=`echo ${url} | awk -F"," '{print $1}'`
        EMS2=`echo ${url} | awk -F"," '{print $2}'`


        EMS1STATE=`echo "i" | ${ADMINTOOL} -server ${EMS1} -user ${USER} -password ${PWD} | grep State | awk '{print $2}'`
        EMS2STATE=`echo "i" | ${ADMINTOOL} -server ${EMS2} -user ${USER} -password ${PWD} | grep State | awk '{print $2}'`

        EMSTOUSE=${EMS2}

        if [ ${EMS1STATE} = 'active' ]
        then
                EMSTOUSE=${EMS1}
        elif [ ${EMS2STATE} = 'active' ]
        then
                EMSTOUSE=${EMS2}
        else
                echo "None of the EMS active for : "${url}
                continue
        fi

}

#find_aota_connections $TIBEMSADMIN $ACTIVEURL $USER $PWD
function find_aota_connections()
{

}



function connectionStatus(){
        #echo "Count Username Destination"

        echo "show connections full" | $1 -server $2 -user $3 -password $4 | sed '1,10d' | grep -v "SASB Pre Dlv" | awk '{print $7" "$8" "$9}' | grep -v ${2} | sort -n | uniq -c
        echo "Connection Snapshot Complete!"
}
