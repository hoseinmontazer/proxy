#!/bin/bash
#update and upgrade and install pakeage
#apt update && apt upgrade -y


set -e
#set -u
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
CLEAR='\033[0m'

usage() {
	echo -e ${CYAN}
        echo -e "usage: $(basename $0) [option]"
	echo
	echo "server-gost		Create Server side tunnel as gost"
        echo "local-gost		Create local Side  tunnel as gost"
        echo "v2ray			Create v2ray account"
	echo "install-package		isnatll requerment package"
	echo "revoke-conf		revoke account"
        echo "help			show this help"
	echo -e ${CLEAR}
}


install-package() {

	if ! [ -x "$(command -v python3)" ];then
    		apt install python3-pip
    		echo "python3 installation done."
	else
   		echo "Skipping 'python3' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v qr)" ];then
    		pip3 install qrcode
    		echo "installation qrcode done."
	else
   		echo "Skipping 'qrcode' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v supervisorctl)" ];then
    		apt install supervisor -y
    		echo "supervisor installation done."
	else
   		echo "Skipping 'supervisor' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v gost)" ];then
    		# Package does not exist: Do the package installation
    		# downloaf and install gost
    		echo "gost installation started ."
    		curl -fsSL https://github.com/ginuerzh/gost/releases/download/v2.11.4/gost-linux-amd64-2.11.4.gz -o gost.gz  &&  gunzip gost.gz  &
    		PID=$!
    		i=1
    		sp="/-\|"
    		echo -n ' '
    		while [ -d /proc/$PID ]
    		do
      			printf "\b${sp:i++%${#sp}:1}"
    		done
    		chmod +x gost
    		mv gost /usr/bin/
    		#rm gost.gz
    		echo " gost installation done ."
	else
   		echo "Skipping 'gost' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -f /usr/local/bin/v2ray ];then
		bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
                echo "v2ray installation done."
        else
                echo "Skipping 'v2ray' installation: that already exists"
                sleep 2
        fi;

echo "installed all requerment pakage."
}

server-gost() {
unset MSG
while [[ ! "$MSG" =~ ^[yYnN]$ ]]; do read -p  'create gost proxy in server side. you shoud run this command on server side node: [Y/N] :'  MSG ;done 
echo $MSG
if [[  $MSG == "Y" ]] || [[  $MSG == "y" ]] ;then
	#PASS=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
	PORT=`for i in $(seq 1); do echo $(((RANDOM % $((65000 - 2000))) + 2000));done`
	DIR=/var/log/gost
	if [ -d $DIR ];then
		echo "supervisor conf is enable"
	else
		mkdir /var/log/gost
	fi;
	echo "create supervisor conf for server side"
	sleep 1
	read -rep $'enter your account name :\n'   FILENAME
	while [[   -f  /etc/supervisor/conf.d/$FILENAME.conf ]];do
		echo -e "${RED}this account is exist please enter another name${CLEAR}"
		read -rep $'enter your account name: \n'   FILENAME
	done
	if [ $FILENAME  ]; then
			read -rep $'enter your gost Transporters ,  recommend is ssh in server side: \n'   TRANSPORTS
			while [[ ! "$TRANSPORTS" =~  "ssh" ]]; do 
				echo -e "${RED}only ssh avalable please choose this!!!${CLEAR}"
				read -rep $'enter your gost Transporters ,  recommend is ssh in server side: \n'   TRANSPORTS;
		       	done
			read -rep $'please enter pulic key: \n'   PUBKEY
			while [ -z $PUBKEY ];do
				echo -e "${RED}public key con not be empty${CLEAR}"
				read -rep $'please enter pulic key: \n'   PUBKEY
			done	
			sleep 1
			if [ ! -f  /root/auth-gost_keys  ];then
           	     		touch /root/auth-gost_keys
				echo "ssh authorized public keys file created"
        		else
				echo "ssh authorized public keys file is enable"
			fi;
			echo $PUBKEY
			echo $PUBKEY >>  /root/auth-gost_keys
			cat <<-EOF >  /etc/supervisor/conf.d/$FILENAME.conf
			[program:$FILENAME]
			command=gost -L="ssh://:$PORT?ssh_authorized_keys=/root/auth-gost_keys"
			autostart=true
			autorestart=true
			stderr_logfile=/var/log/gost/$FILENAME.err.log
			stdout_logfile=/var/log/gost/$FILENAME.log
			EOF
			sleep 1
			echo -e "${YELLOW}===========start gost===========${CLEAR}"
			supervisorctl reread && supervisorctl update && supervisorctl start all
			echo -e "${YELLOW}===========your config===========${CLEAR}"
			cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
			echo -e "${GREEN}setup finish${CLEAR}"
	else
		echo "not found file name"
	fi;

else
	echo "${GREEN}setup finish${CLEAR}"
fi;


}


local-gost() {
read -rep $'create server gost in cliet side server  "you shoud run this command in cliet side for forward trafic to server side server "  : y or n:\n' -i y  MSG
if [ $MSG == 'y' ];then
        #echo $MSG
        PASS=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
        PORT=`for i in $(seq 1); do echo $(((RANDOM % $((65000 - 2000))) + 2000));done`
        DIR=/var/log/gost
        if [ -d $DIR ];then
                echo "supervisor conf is enable"
        else
                mkdir /var/log/gost
        fi;
        echo "create supervisor conf for client side"
        sleep 1
        read -rep $'enter your account name: \n'   FILENAME
        if [ $FILENAME  ]; then
		if [ ! -f  /etc/supervisor/conf.d/$FILENAME.conf  ]; then
			echo "=================== type of listeners available ==================="
			printf "1) ss+ohttp (this is shadowsocks with simple obfs plugin ) \n2) http (http proxy) \n3) socks ( socks proxy) \n"
			echo "=================== choose one of the option ==================="
                	read -rep $'enter your gost listner type : \n'   LISTENER		
			echo "hi listener"
			if [ $LISTENER == 'ss+ohttp' ] || [ $MODE == 1 ];then
				echo "hi ohttp"
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
				if [[ ${FORWARDER} ]];then
                                        echo $FORWARDER
					cat <<-EOF > /etc/supervisor/conf.d/$FILENAME.conf
					[program:$FILENAME]
					command=gost -L=ss+ohttp://chacha20-ietf-poly1305:$PASS@:$PORT?~bypass=*.ir,*.ir/*,google.com,google.com/*,*.google.com,*.google.com/* -F="$FORWARDER"
					autostart=true
					autorestart=true
					stderr_logfile=/var/log/gost/$FILENAME.err.log
					stdout_logfile=/var/log/gost/$FILENAME.log
					EOF
                                        sleep 1
                                        echo "===========start gost==========="
                                        supervisorctl reread && supervisorctl update && supervisorctl start all
                                        echo "===========your config==========="
                                        cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
                                        echo "finish"
                                        PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`	
				else
					echo "not available forwarder"
					local-gost
				fi
			elif [ $LISTENER == 'http' ] || [ $MODE == 2 ];then
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
	                        if [[ ${FORWARDER} ]];then
                                        echo $FORWARDER
					cat <<-EOF >  /etc/supervisor/conf.d/$FILENAME.conf
					[program:$FILENAME]
					command=gost -L=http://$FILENAME:$PASS@:$PORT?~bypass=*.ir,*.ir/*,google.com,google.com/*,*.google.com,*.google.com/* -F="$FORWARDER"
					autostart=true
					autorestart=true
					stderr_logfile=/var/log/gost/$FILENAME.err.log
					stdout_logfile=/var/log/gost/$FILENAME.log
					EOF
                                        sleep 1
                                        echo "===========start gost==========="
                                        supervisorctl reread && supervisorctl update && supervisorctl start all
                                        echo "===========your config==========="
                                        cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
                                        echo "finish"
                                        PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`					
                	        else
                        	        echo "not available forwarder"
					local-gost
	                        fi

			elif [ $LISTENER == 'socks' ] || [ $MODE == 3 ];then
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
                	        if [[ ${FORWARDER} ]];then
                                        echo $FORWARDER
					cat <<-EOF > /etc/supervisor/conf.d/$FILENAME.conf
					[program:$FILENAME]
					command=gost -L=socks5://$FILENAME:$PASS@:$PORT?~bypass=*.ir,*.ir/*,google.com,google.com/*,*.google.com,*.google.com/* -F="$FORWARDER"
					autostart=true
					autorestart=true
					stderr_logfile=/var/log/gost/$FILENAME.err.log
					stdout_logfile=/var/log/gost/$FILENAME.log
					EOF
                                        sleep 1
                                        echo "===========start gost==========="
                                        supervisorctl reread && supervisorctl update && supervisorctl start all
                                        echo "===========your config==========="
                                        cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
                                        echo "finish"
                                        PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`					
        	                else
                	                echo "not available forwarder"
					local-gost
	                        fi

			else
				echo "not support listener"
				local-gost
			fi
		else
			echo "this account is avalebale" 
			local-gost
		fi
	else
		echo "can not find listener"
		local-gost
	fi;
else
        echo -e  "$GREEN setup finish $CLEAR"
fi;

}

v2ray() {
install-package
while [[ ! "$MSG" =~ ^[yYnN]$ ]]; do read -rep $'Create v2ray account (vmess)"  : y or n:\n' -i y  MSG; done
if [ $MSG == 'y' ];then
	PASS=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
	INPORT=`for i in $(seq 1); do echo $(((RANDOM % $((65000 - 2000))) + 2000));done`
	UUID=`/usr/local/bin/v2ray uuid`
	VDIR=/usr/local/etc/v2ray/
        read -rep $'enter your account name :\n'   FILENAME
        while [[   -f  /etc/supervisor/conf.d/$FILENAME.conf ]];do
                echo -e "${RED}this account is exist please enter another name${CLEAR}"
                read -rep $'enter your account name: \n'   FILENAME
        done

	echo  -e "${YELLOW}=================== choose one of the option ===================${CLEAR}"
	printf "${YELLOW}1) direct (single node) \n2) bridge (two server)${CLEAR} \n"
	read -rep $'enter your v2ray mode :\n'   MODE
	while [ ! "$MODE" == bridge ] && [ ! "$MODE" == direct ] && [ ! "$MODE" == 1 ] && [ ! "$MODE" == 2 ] ;do
		echo "asssas$MODE"
		echo -e "${RED}\"$MODE\" not avalable, please chosse correct item${CLEAR}"
		printf "${YELLOW}1) direct (single node) \n2) bridge (two server)${CLEAR} \n"
        	read -rep $'enter your v2ray mode : \n'   MODE;
	done

	#bridge mode
	if [ "$MODE" == 'bridge' ] || [ "$MODE" == '2' ];then

		echo  -e "${YELLOW}=================== choose protocol ===================${CLEAR}"
		echo -e "${RED}only suport vmess now!!! vless will be added soon${CLEAR}"
		printf "${YELLOW}1) vmess \n2) vless ${CLEAR}\n"
		read -rep $'enter protocol : \n'   POROTOCOL
		while [ ! "$POROTOCOL" == vmess ] && [ ! "$POROTOCOL" == 1 ];do
			echo -e "${RED}\"$POROTOCOL\" not avalable, please chosse correct item${CLEAR}"
			echo -e "${RED}only suport vmess now!!! vless will be added soon${CLEAR}"
			printf "${YELLOW}1) vmess \n2) vless ${CLEAR}\n"
			read -rep $'enter protocol : \n'   POROTOCOL
		done
                if [ $POROTOCOL == 1 ];then
                        POROTOCOL=vmess
                elif [ $POROTOCOL == 2 ];then
                        POROTOCOL=vless
                else
                        echo -e "$RED can not find valid protocl $CLEAR"
                        v2ray
                fi
		echo -e "${YELLOW}=================== choose outnound network ===================${CLEAR}"
		printf "${YELLOW}1) ws \n2) http ${CLEAR}\n"
		read -rep $'enter outbound network : \n'   NET
		while [ ! "$NET" == ws ] && [ ! "$NET" == 1 ] && [ ! "$NET" == http ] && [ ! "$NET" == 2 ];do
			echo -e "${RED}\"$NET\" not avalable, please chosse correct item${CLEAR}"
			printf "${YELLOW}1) ws \n2) http ${CLEAR}\n"
        	        read -rep $'enter outbound network : \n'   NET
		done
                if [ $NET == 1 ];then
                        NET=ws
                elif [ $NET == 2 ];then
                        NET=http
                else
                        echo -e "$RED can not find valid network $CLEAR"
                        v2ray   
                fi
		echo -e  "${YELLOW}=================== enter outbound Ip  ===================${CLEAR}"
		read -rep $'enter outbound IP  : \n'   IP
		while [[ ! $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];do
			echo -e "${RED}can not find valid ip${CLEAR}"
			read -rep $'enter outbound IP  : \n'   IP
		done

		echo -e  "${YELLOW}=================== enter outbound Port  ===================${CLEAR}"
                read -rep $'enter outbound Port : \n'   OUTPORT
                while [[ ! "$OUTPORT" =~ ^[0-9]+$  ]];do
                        echo -e "${RED}can not find valid PORT${CLEAR}"
                        read -rep $'enter outbound Port  : \n'   OUTPORT
                done

                echo  -e "${YELLOW}=================== enter outbound protocol ===================${CLEAR}"
                printf "${YELLOW}1) socks \n2) http ${CLEAR}\n"
                read -rep $'enter protocol : \n'   OUTPOROTOCOL
                while [ ! "$OUTPOROTOCOL" == socks ] && [ ! "$OUTPOROTOCOL" == 1 ] && [ ! "$OUTPOROTOCOL" == http ] && [ ! "$OUTPOROTOCOL" == 2 ];do
                        echo -e "${RED}\"$POROTOCOL\" not avalable, please chosse correct item${CLEAR}"
                        printf "${YELLOW}1) socks \n2) http ${CLEAR}\n"
                        read -rep $'enter outbound protocol : \n'  OUTPOROTOCOL
                done
                if [ $OUTPOROTOCOL == 1 ];then
                        OUTPOROTOCOL=socks
                elif [ $OUTPOROTOCOL == 2 ];then
                        OUTPOROTOCOL=http
                else
                        echo -e "$RED can not find valid outbound protocol $CLEAR"
                        v2ray   
                fi
                echo  -e "${YELLOW}=================== enter outbound username ===================${CLEAR}"
                read -rep $'enter protocol username : \n'   USERNAME
                while [ ! "$USERNAME" ];do
                        echo -e "${RED}\"$USERNAME\" not avalable, please enter correct Username${CLEAR}"
			read -rep $'enter protocol username : \n'   USERNAME
                done

                echo  -e "${YELLOW}=================== enter outbound password ===================${CLEAR}"
                read -rep $'enter outbound protocol password : \n'   PASSWORD
                while [ ! "$PASSWORD" ];do
                        echo -e "${RED}\"$PASSWORD\" not avalable, please enter correct Username${CLEAR}"
                        read -rep $'enter outbound protocol password : \n'   PASSWORD
                done
		if [ ! -f  $VDIR$FILENAME.json ];then
			cat <<-EOF  > $VDIR$FILENAME.json
				{
    					"log": {
        					"loglevel": "warning"
    					},
	    				"routing": {
						"domainStrategy": "AsIs",
						"rules": [
						{
                						"type": "field",
                						"ip": [
                    							"geoip:private"
                						],
	                					"outboundTag": "direct"
        	    					}
        					]
    					},
    					"inbounds": [
	        				{
        	    					"listen": "0.0.0.0",
            						"port": $INPORT,
            						"protocol": "$POROTOCOL",
            						"settings": {
                						"clients": [
                    							{
                        							"id": "$UUID"
                    							}
	                					]
        	    					},
            						"streamSettings": {
                						"network": "$NET",
                						"security": "none"
            						}
        					}
	    				],
    					"outbounds": [
        					{
            						"protocol": "http",
            						"settings": {
                						"servers": [
                    							{
                        							"address": "$IP",
                        							"port": $OUTPORT,
                        							"users": [
                            								{
	                                							"user": "$USERNAME",
        	                        							"pass": "$PASSWORD"
                	            							}
                        							]

        	            						}
                						]
            						},
            						"tag": "proxy"
        					},
	        				{
        	    					"protocol": "freedom",
            						"tag": "direct"
        					}
    					]
				}
			EOF
		else
			cat $VDIR$FILENAME.json
			echo -e  "${RED}this v2ray conf is aviable, pleasee revoke that !!!${CLEAR}"
			exit
		fi
		cat $VDIR$FILENAME.json
		if [ $VDIR$FILENAME.json ];then
			if [ ! -f  /etc/supervisor/conf.d/$FILENAME.conf  ]; then
				cat <<- EOF > /etc/supervisor/conf.d/$FILENAME.conf
				[program:$FILENAME]
				command=/usr/local/bin/v2ray run -c $VDIR$FILENAME.json
				autostart=true
				autorestart=true
				stderr_logfile=/var/log/gost/$FILENAME.err.log
				stdout_logfile=/var/log/gost/$FILENAME.log
				EOF
                                sleep 1
                                echo "===========start gost==========="
                                supervisorctl reread && supervisorctl update && supervisorctl start all
                                echo "===========your config==========="
                                cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
                                echo "finish"
                                PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`
			fi
		fi
	elif [ "$MODE" == 'direct' ] || [ "$MODE" == '1' ];then

                echo  -e "${YELLOW}=================== choose protocol ===================${CLEAR}"
		echo -e "${RED}only suport vmess now!!! vless will be added soon${CLEAR}"
                printf "${YELLOW}1) vmess \n2) vless ${CLEAR}\n"
                read -rep $'enter protocol : \n'   POROTOCOL
                while [ ! "$POROTOCOL" == vmess ] && [ ! "$POROTOCOL" == 1 ]  ;do
                        echo -e "${RED}\"$POROTOCOL\" not avalable, please chosse correct item${CLEAR}"
			echo -e "${RED}only suport vmess now!!! vless will be added soon${CLEAR}"
                        printf "${YELLOW}1) vmess \n2) vless ${CLEAR}\n"
                        read -rep $'enter protocol : \n'   POROTOCOL
                done
		if [ $POROTOCOL == 1 ];then
			POROTOCOL=vmess
		elif [ $POROTOCOL == 2 ];then
			POROTOCOL=vless
		else
			echo -e "$RED can not find valid protocl $CLEAR"
			v2ray
		fi
                echo -e "${YELLOW}=================== choose outnound network ===================${CLEAR}"
                printf "${YELLOW}1) ws \n2) http ${CLEAR}\n"
                read -rep $'enter outbound network : \n'   NET
                while [ ! "$NET" == ws ] && [ ! "$NET" == 1 ] && [ ! "$NET" == http ] && [ ! "$NET" == 2 ];do
                        echo -e "${RED}\"$NET\" not avalable, please chosse correct item${CLEAR}"
                        printf "${YELLOW}1) ws \n2) http ${CLEAR}\n"
                        read -rep $'enter outbound network : \n'   NET
                done
		if [ $NET == 1 ];then
			NET=ws
                elif [ $NET == 2 ];then
                        NET=http
                else
                        echo -e "$RED can not find valid network $CLEAR"
			v2ray
                fi
                if [ ! -f  $VDIR$FILENAME.json ];then
			cat <<-EOF  > $VDIR$FILENAME.json
                                {
                                        "log": {
                                                "loglevel": "warning"
                                        },
                                        "routing": {
                                                "domainStrategy": "AsIs",
                                                "rules": [
                                                {
                                                                "type": "field",
                                                                "ip": [
                                                                        "geoip:private"
                                                                ],
                                                                "outboundTag": "direct"
                                                        }
                                                ]
                                        },
                                        "inbounds": [
                                                {
                                                        "listen": "0.0.0.0",
                                                        "port": $INPORT,
                                                        "protocol": "$POROTOCOL",
                                                        "settings": {
                                                                "clients": [
                                                                        {
                                                                                "id": "$UUID"
                                                                        }
                                                                ]
                                                        },
                                                        "streamSettings": {
                                                                "network": "$NET",
                                                                "security": "none"
                                                        }
                                                }
                                        ],
                                        "outbounds": [
                                                {
                                                        "protocol": "freedom",
                                                        "tag": "direct"
                                                }
                                        ]
                                }
			EOF
                else
                        cat $VDIR$FILENAME.json
                        echo -e  "${RED}this v2ray conf is aviable, pleasee revoke that !!!${CLEAR}"
                        exit
                fi
                cat $VDIR$FILENAME.json
                if [ $VDIR$FILENAME.json ];then
                        if [ ! -f  /etc/supervisor/conf.d/$FILENAME.conf  ]; then
				cat <<- EOF > /etc/supervisor/conf.d/$FILENAME.conf
				[program:$FILENAME]
				command=/usr/local/bin/v2ray run -c $VDIR$FILENAME.json
				autostart=true
				autorestart=true
				stderr_logfile=/var/log/gost/$FILENAME.err.log
				stdout_logfile=/var/log/gost/$FILENAME.log
				EOF
                                sleep 1
                                echo "===========start gost==========="
                                supervisorctl reread && supervisorctl update && supervisorctl start all
                                echo "===========your config==========="
                                cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
                                echo "finish"
                                PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`
                        fi
                fi
	else
		echo "are you sure choose correct v2ray mode !!!"
	fi
else
	echo -e "${GREEN}setup finished ${CLEAR}"
fi

}

revoke-conf() {
read -rep $'delete exist Account"  : y or n:\n' -i n  MSG
if [ $MSG == 'y' ];then
	echo -e "${YELLOW}=================== available account ===================${CLEAR}"
	echo -e ${BLUE}
	ls -1 /etc/supervisor/conf.d/  | sed -e 's/\.conf$//'
	echo -e ${CLEAR}
	read -rep $'please select an account :  \n'   CONF
	# check account avilability ####TO DO
	echo -e "${RED}===== your choice is =====${CLEAR}"
	echo $CONF
	echo -e "${RED}=========================="
	read -rep $'are you sure to delete this account ?"  : y or n:\n' -i n  DELETE
	echo -e ${CLEAR}
	if [ $DELETE == 'y' ];then
		rm -f /etc/supervisor/conf.d/$CONF.conf
		rm -f /usr/local/etc/v2ray/$CONF.json
		echo -e "${YELLOW}=========== restart supervisor ===========${CLEAR}"
               	supervisorctl reread && supervisorctl update && supervisorctl stop all &&  supervisorctl start all
		echo -e "${RED}your account is deleted.${CLEAR}"
	else
	        echo -e "${RED}revoke is finished${CLEAR}"
		usage

	fi;

else
	echo -e  "${GREEN}revoke is finish${CLEAR}"
fi;
}



if [ $# -eq 0 ]
then
usage
exit 1
fi

    case $1 in
        "install-package")
            install-package
            ;;
        "server-gost")
        server-gost
            ;;
        "local-gost")
        local-gost
            ;;
        "revoke-conf")
        revoke-conf
            ;;
        "v2ray")
        v2ray
            ;;
        "help")
            usage
            break
            ;;
        *) echo "invalid option";;
    esac
