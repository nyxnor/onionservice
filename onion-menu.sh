#!/bin/bash

# This file is part of onion-cli, an easy to use Tor hidden services manager.
#
# Copyright (C) 2021 nyxnor
# Contact: nyxnor@protonmail.com
# Github:  https://github.com/nyxnor
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it is useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# DESCRIPTION
# This file lets you manage your authorized clients for hidden services
# It is a CLI for the onion-service.sh with everything integrated in this menu
#
# SYNTAX
# bash menu-onion-main

###########################
######## FUNCTIONS ########

## include lib
. onion.lib


prepare_derived_menu(){
  i=0
  INSTRUCTIONS="Use spacebar to select"
  HEIGHT=19
  WIDTH=50
  CHOICE_HEIGHT=$((${CHOICE_HEIGHT}-2))
}


service_menu(){
  prepare_derived_menu

  for SERVICE in $(sudo -u ${DATA_DIR_OWNER} ls -A ${DATA_DIR_HS}/); do
    ((i++))
    SERVICE_ARRAY+=(${i} "${SERVICE}" OFF)
  done

  CHOICE_SERVICE=$(whiptail --separate-output \
    --checklist "${INSTRUCTIONS}" \
    ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
    "${SERVICE_ARRAY[@]}" \
    3>&1 1>&2 2>&3)

  #CHOICE_SERVICE=$(dialog --title "${TITLE}" \
  #           --checklist "${INSTRUCTIONS}" \
  #           ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
  #           "${SERVICE_ARRAY[@]}" 2>&1 >/dev/tty)

  if [ ! -z "${CHOICE_SERVICE}" ]; then
    SERVICE_NAME_LIST=""
    while [ ${i} -gt 0 ]; do
      check=0; check=$(echo "${CHOICE_SERVICE}" | grep -c "${i}")
      k=$((i * 3 -2))
      if [ ${check} -eq 1 ]; then
        SERVICE=("${SERVICE_ARRAY[$k]}")
        SERVICE_NAME_LIST="${SERVICE_NAME_LIST},${SERVICE}"
      fi
      ((i--))
    done
      SERVICE_NAME_LIST=$(echo ${SERVICE_NAME_LIST} | sed 's/^,//g')
  fi
}


AUTH_SERVER_menu(){
  prepare_derived_menu

for SERVICE in $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/); do
  ## only include services that has at least one .auth
  if [ $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/${SERVICE}/authorized_clients/ | wc -l) -gt 0 ]; then
    ((i++))
    SERVICE_ARRAY+=(${i} "${SERVICE}" OFF)
    AUTH_NAME_LIST=$(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/${SERVICE}/authorized_clients/ | cut -d '.' -f1)
    AUTH_RAW_ARRAY+=("${AUTH_NAME_LIST}")
  fi
done

    if [ ${#SERVICE_ARRAY[@]} -eq 0 ]; then
      TEXT_NO_CLIENT="No service has client authorization."
      whiptail --msgbox "${TEXT_NO_CLIENT}" 10 50
    else

        CHOICE_SERVICE=$(whiptail --separate-output \
          --checklist "${INSTRUCTIONS}" \
          ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
          "${SERVICE_ARRAY[@]}" \
          3>&1 1>&2 2>&3)

        # CHOICE_SERVICE=$(dialog --title "${TITLE}" \
        #           --checklist "${INSTRUCTIONS}" \
        #           ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
        #           "${SERVICE_ARRAY[@]}" 2>&1 >/dev/tty)
    fi

    if [ ! -z "${CHOICE_SERVICE}" ]; then

        AUTH_CLEAN_LIST=$(echo ${AUTH_RAW_ARRAY[@]} | tr ' ' '\n' | cut -d '.' -f1  | sort | uniq -c | tr -s ' ' | tr '\n' ' ' | tr -s ' ' | sed 's/^ //g')
        AUTH_CLEAN_ARRAY+=(${AUTH_CLEAN_LIST})
        COUNT_AUTH_CLEAN_ARRAY=${#AUTH_CLEAN_ARRAY[@]}

        z=0
        j=$((${COUNT_AUTH_CLEAN_ARRAY}/2))
        while [ ${j} -gt 0 ]; do
            q=$((j * 2 -2 ))
            n=$((j * 2 -1 ))
            AUTH_QUANTITY=("${AUTH_CLEAN_ARRAY[$q]}")
            AUTH_NAME=("${AUTH_CLEAN_ARRAY[$n]}")
            if [ ${i} == ${AUTH_QUANTITY} ]; then
              ((z++))
              AUTH_FINAL_ARRAY+=(${z} "${AUTH_NAME}" OFF)
            fi
            ((j--))
        done

        if [ ${#AUTH_FINAL_ARRAY[@]} -eq 0 ]; then
          TEXT_NO_CLIENT="No client exist for desired service or no clients intersection with chosen services."
          whiptail --msgbox "${TEXT_NO_CLIENT}" 10 50
        else

          CHOICE_CLIENT=$(whiptail --separate-output \
            --checklist "${INSTRUCTIONS}" \
            ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
            "${AUTH_FINAL_ARRAY[@]}" \
            3>&1 1>&2 2>&3)

          # CHOICE_CLIENT=$(dialog --title "${TITLE}" \
          #           --checklist "${INSTRUCTIONS}" \
          #           ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
          #           "${AUTH_FINAL_ARRAY[@]}" 2>&1 >/dev/tty)

        if [ ! -z "${CHOICE_CLIENT}" ]; then
          SERVICE_NAME_LIST=""
          while [ ${i} -gt 0 ]; do
            check=0; check=$(echo "${CHOICE_SERVICE}" | grep -c "${i}")
            k=$((i * 3 -2))
            if [ ${check} -eq 1 ]; then
              SERVICE=("${SERVICE_ARRAY[$k]}")
              SERVICE_NAME_LIST="${SERVICE_NAME_LIST},${SERVICE}"
            fi
            ((i--))
          done
          SERVICE_NAME_LIST=$(echo ${SERVICE_NAME_LIST} | sed 's/^,//g')

          CLIENT_NAME_LIST=""
          while [ ${z} -gt 0 ]; do
              check=0; check=$(echo "${CHOICE_CLIENT}" | grep -c "${z}")
              k=$((z * 3 -2))
              if [ ${check} -eq 1 ]; then
                CLIENT=("${AUTH_FINAL_ARRAY[$k]}")
                CLIENT_NAME_LIST="${CLIENT_NAME_LIST},${CLIENT}"
              fi
              ((z--))
          done
          CLIENT_NAME_LIST=$(echo ${CLIENT_NAME_LIST} | sed 's/^,//g')
        fi
      fi
    fi
}


AUTH_CLIENT_menu(){
  prepare_derived_menu

  for ONION_AUTH in $(sudo -u ${DATA_DIR_OWNER} ls -A ${CLIENT_ONION_AUTH_DIR}/ | cut -d '.' -f1); do
  ((i++))
  ONION_AUTH_ARRAY+=(${i} "${ONION_AUTH}" OFF)
  done

  if [ ${#ONION_AUTH_ARRAY[@]} -eq 0 ]; then
    TEXT_NO_CLIENT="The folder ${CLIENT_ONION_AUTH_DIR} is empty."
    whiptail --msgbox "${TEXT_NO_CLIENT}" 10 50
  else
    CHOICE_ONION_AUTH=$(whiptail --separate-output \
      --checklist "${INSTRUCTIONS}" \
      ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
      "${ONION_AUTH_ARRAY[@]}" \
      3>&1 1>&2 2>&3)

    # CHOICE_ONION_AUTH=$(dialog --title "${TITLE}" \
    #           --checklist "${INSTRUCTIONS}" \
    #           ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
    #           "${ONION_AUTH_ARRAY[@]}" 2>&1 >/dev/tty)

    if [ ! -z "${CHOICE_ONION_AUTH}" ]; then
      ONION_AUTH_NAME_LIST=""
      while [ ${i} -gt 0 ]; do
        check=0; check=$(echo "${CHOICE_ONION_AUTH}" | grep -c "${i}")
        k=$((i * 3 -2))
        if [ ${check} -eq 1 ]; then
          ONION_AUTH=("${ONION_AUTH_ARRAY[$k]}")
          ONION_AUTH_NAME_LIST="${ONION_AUTH_NAME_LIST},${ONION_AUTH}"
        fi
        ((i--))
      done
      ONION_AUTH_NAME_LIST=$(echo ${ONION_AUTH_NAME_LIST} | sed 's/^,//g')
    fi
  fi
}


md_menu(){
  i=0
  for MD in $(ls text/*.md); do
    ((i++))
    MD_PATH=${MD%*/}
    MD_NAME=$(echo "${MD_PATH##*/}" | cut -f1 -d '.')
    MD_ARRAY+=("${MD_NAME}" " ")
  done

  TITLE="Markdown guides"
  MENU="select one guide"
  CHOICE_MD=$(whiptail --title "${TITLE}" --menu "${MENU}" 18 40 10 "${MD_ARRAY[@]}" 3>&1 1>&2 2>&3)

  if [ ! -z "${CHOICE_MD}" ]; then
    pandoc "text/${CHOICE_MD}.md" | lynx -stdin
  fi
}

###########################


TITLE="Onion Services Main Menu"
HEIGHT=20
WIDTH=80
CHOICE_HEIGHT=10
MENU="Manage your onion services"

if [ -z "$(sudo -u ${DATA_DIR_OWNER} ls -A ${DATA_DIR_HS}/)" ]; then
  CHOICE_MAIN=$(whiptail --menu "${MENU}" --title "${TITLE}" ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
    "MAN" "Manual pages for the onion-cli" \
    "GUIDES" "Markdown guides by Tor Project Organization and Riseup" \
    "CREATE" "Create and host a hidden service" \
    "IMPORT" "Import your hidden service data directory" \
    "AUTH_CLIENT" "Manage your client key of someonelse's service" \
    3>&1 1>&2 2>&3)
else
  CHOICE_MAIN=$(whiptail --menu "${MENU}" --title "${TITLE}" ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
    "MAN" "Manual pages for the onion-cli" \
    "GUIDES" "Markdown guides by Tor Project Organization and Riseup" \
    "CREATE" "Host a hidden service" \
    "DELETE" "Delete chosen onion service" \
    "RENEW" "Renew onion service address" \
    "AUTH_SERVER" "Add or Remove client authorization from your service" \
    "AUTH_CLIENT" "Manage your client key of someonelse's service" \
    "CREDENTIALS" "See credentials (onion address, authorized clients)" \
    "IMPORT" "Import your hidden service data from another machine" \
    "EXPORT" "Export your hidden service data to another machine" \
    3>&1 1>&2 2>&3)
fi


if [ ! -z "${CHOICE_MAIN}" ]; then

  case ${CHOICE_MAIN} in

    MAN)
      man ./text/onion-cli.man
    ;;

    GUIDES)
      md_menu
    ;;

    DELETE)
      service_menu
      if [ ! -z ${SERVICE_NAME_LIST} ]; then
        bash onion-service.sh off ${SERVICE_NAME_LIST}
      fi
    ;;

    RENEW)
      service_menu
      if [ ! -z ${SERVICE_NAME_LIST} ]; then
        bash onion-service.sh renew ${SERVICE_NAME_LIST}
      fi
    ;;

    CREDENTIALS)
      service_menu
      if [ ! -z ${SERVICE_NAME_LIST} ]; then
        bash onion-service.sh credentials ${SERVICE_NAME_LIST}
      fi
    ;;

    IMPORT)
      bash onion-service.sh backup import
    ;;

    EXPORT)
      bash onion-service.sh backup export
    ;;

    CREATE)

      TITLE_CREATE="Onion Services Creation Menu"
      MENU_CREATE="Choose socket type:"

      SOCKET_CHOICE=$(whiptail --menu "${MENU_CREATE}" --title "${TITLE_CREATE}" 18 100 10 \
        "UNIX" "unix:path (unix:/var/run/tor-website.sock)" \
        "TCP" "addr:port (127.0.0.1:22, 192.168.2.10:3000, localhost:80)" \
        3>&1 1>&2 2>&3)

      if [ ! -z "${SOCKET_CHOICE}" ]; then

        SERVICE_MSG="Name your service (one string, no space. Eg: torbox.ch)"
        VIRTPORT_MSG="Listening on the 1st virtual port number:"
        VIRTPORT2_MSG="Listening on the 2st virtual port number:"
        TARGET_MSG="OPTIONAL -> Redirect incoming traffic to 1st target addr:port"
        TARGET2_MSG="OPTIONAL -> Redirect incoming traffic to 2nd target addr:port2"

        if [ "${SOCKET_CHOICE}" == "UNIX" ]; then
          # Required
          SERVICE_NAME=$(whiptail --inputbox "${SERVICE_MSG}" 10 50 3>&1 1>&2 2>&3)
          if [ ! -z ${SERVICE_NAME} ]; then
            VIRTPORT=$(whiptail --inputbox "${VIRTPORT_MSG}" 10 50 3>&1 1>&2 2>&3)
            if [ ! -z ${VIRTPORT} ]; then
              ## Optional
              VIRTPORT2=$(whiptail --inputbox "${VIRTPORT2_MSG}" 10 50 3>&1 1>&2 2>&3)
              bash onion-service.sh on unix ${SERVICE_NAME} ${VIRTPORT} ${VIRTPORT2}
            fi
          fi

        elif [ "${SOCKET_CHOICE}" == "TCP" ]; then
          # Required
          SERVICE_NAME=$(whiptail --inputbox "${SERVICE_MSG}" 10 50 3>&1 1>&2 2>&3)
          if [ ! -z ${SERVICE_NAME} ]; then
            VIRTPORT=$(whiptail --inputbox "${VIRTPORT_MSG}" 10 50 3>&1 1>&2 2>&3)
            if [ ! -z ${VIRTPORT} ]; then
              TARGET=$(whiptail --inputbox "${TARGET_MSG}" 10 50 3>&1 1>&2 2>&3)
              if [ ! -z ${TARGET} ]; then
                # Optional
                VIRTPORT2=$(whiptail --inputbox "${VIRTPORT2_MSG}" 10 50 3>&1 1>&2 2>&3)
                if [ ! -z ${VIRTPORT2} ]; then
                  TARGET2=$(whiptail --inputbox "${TARGET2_MSG}" 10 50 3>&1 1>&2 2>&3)
                fi
              fi
              bash onion-service.sh on tcp ${SERVICE_NAME} ${VIRTPORT} ${TARGET} ${VIRTPORT2} ${TARGET2}
            fi
          fi
        fi
      fi
    ;;

    AUTH_SERVER)
      TITLE="Client Authorization"
      MENU="Would you like to add or remove authorization from a client?"
      AUTH_TYPE=$(whiptail --menu "${MENU}" --title "${TITLE}" 12 50 2 \
        "ADD" "Authorize a client" \
        "DEL" "Remove authorization from a client" \
        3>&1 1>&2 2>&3)

      if [ "${AUTH_TYPE}" == "ADD" ]; then
        service_menu
        if [ ! -z ${SERVICE_NAME_LIST} ]; then
          AUTH_STATUS="on"
          DESCRIPTION="Client(s) name(s) delimited by space or/and comma (alice, bob)"
          CLIENT_NAME_LIST=("$(whiptail --inputbox "${DESCRIPTION}" 10 50 3>&1 1>&2 2>&3)")
          ## separate spaced words by comma and delete sequential commas and spaces
          CLIENT_NAME_LIST=$(cut -f1- -d ' ' --output-delimiter=',' <<< ${CLIENT_NAME_LIST})
          CLIENT_NAME_LIST=$(echo ${CLIENT_NAME_LIST} | tr -d ' ' | tr -s ',' ',')
        fi
      elif [ "${AUTH_TYPE}" == "DEL" ]; then
        AUTH_STATUS="off"
        AUTH_SERVER_menu
      fi

      if [ ! -z ${CLIENT_NAME_LIST} ]; then
        bash onion-service.sh auth server ${AUTH_STATUS} ${SERVICE_NAME_LIST} ${CLIENT_NAME_LIST}
      fi
    ;;

    AUTH_CLIENT)
      TITLE="Client Authorization"
      MENU="Would you like to add or remove authorization from a client?"
      AUTH_TYPE=$(whiptail --menu "${MENU}" --title "${TITLE}" 15 70 2 \
        "ADD" "Authorize yourself to service" \
        "DEL" "Remove your client authorization from a service" \
        3>&1 1>&2 2>&3)

      if [ "${AUTH_TYPE}" == "ADD" ]; then
        DESCRIPTION="Insert file name without '.auth_private'. Recommendation is to refer to the authenticated service."
        AUTH_FILE_NAME=("$(whiptail --inputbox "${DESCRIPTION}" 15 70 3>&1 1>&2 2>&3)")
        AUTH_FILE_NAME=$(echo ${AUTH_FILE_NAME} | tr -d ' ')
        if [ ! -z ${AUTH_FILE_NAME} ]; then
          DESCRIPTION="Insert private key as instructed by the service operator.\nFormat: <onion-addr-without-.onion-part>:descriptor:x25519:<private-key>"
          AUTH_PRIV_KEY=("$(whiptail --inputbox "${DESCRIPTION}" 15 70 3>&1 1>&2 2>&3)")
          AUTH_PRIV_KEY=$(echo ${AUTH_PRIV_KEY} | tr -d ' ')
          if [ ! -z ${AUTH_PRIV_KEY} ]; then
            bash onion-service.sh auth client on ${AUTH_FILE_NAME} ${AUTH_PRIV_KEY}
          fi
        fi
      elif [ "${AUTH_TYPE}" == "DEL" ]; then
        AUTH_CLIENT_menu
        if [ ! -z ${ONION_AUTH_NAME_LIST} ]; then
          bash onion-service.sh auth client off ${ONION_AUTH_NAME_LIST}
        fi
      fi
    ;;

    *)
      exit 0

  esac

fi

# if [ $? -eq 0 ]; then
#     exit 0
# fi

# bash ${0}