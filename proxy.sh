#!/bin/bash
#update and upgrade and install pakeage
#apt update && apt upgrade -y


set -e
set -u

usage() { 
        echo "usage: $(basename $0) [option]"
	echo "option=server-gost: Create Server side tunnel as gost"
        echo "option=local-gost: Create local Side  tunnel as gost"
        echo "option=v2ray: Create v2ray account"
	echo "option=install-package: isnatll requerment package"
	echo "option=revoke-conf: revoke supervisor conf"
        echo "option=help: show this help"
}


install-package() {

	if ! [ -x "$(command -v supervisorctl)" ];then
		apt install supervisor -y
    		echo "done install supervisor ."
	else
   		echo "Skipping 'supervisor' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v python3)" ];then
    		apt install python3-pip
    		echo "done install python3 ."
	else
   		echo "Skipping 'python3' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v qr)" ];then
    		pip3 install qrcode
    		echo "done install qrcode ."
	else
   		echo "Skipping 'qrcode' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v supervisorctl)" ];then
    		apt install supervisor -y
    		echo "done install supervisor ."
	else
   		echo "Skipping 'supervisor' installation: that already exists"
   		sleep 2
	fi;

	if ! [ -x "$(command -v gost)" ];then
    		# Package does not exist: Do the package installation
    		# downloaf and install gost
    		echo "start install gost ."
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
    		echo "done install gost ."
	else
   		echo "Skipping 'gost' installation: that already exists"
   		sleep 2
	fi;
	echo "installed all requerment pakage."
}

server-gost() {
read -rep $'create server gost "you shoud run this command on server side node"  : y or n:\n' -i y  MSG
if [ $MSG == 'y' ];then
	#echo $MSG
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
	read -rep $'enter your account name: \n'   FILENAME
	if [ $FILENAME  ]; then
		if [ ! -f  /etc/supervisor/conf.d/$FILENAME.conf  ]; then
			read -rep $'enter your gost Transports ,  recommend is ssh in server side: \n'   TRANSPORTS
        		if [ $TRANSPORTS  ];then
                		echo $TRANSPORTS
				if [ $TRANSPORTS == 'ssh' ];then
					read -rep $'please enter pulic key: \n'   PUBKEY
					echo $PUBKEY
					sleep 3
					if [[ ${PUBKEY} ]];then
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
						sleep 2
						echo "===========start gost==========="
						supervisorctl reread && supervisorctl update && supervisorctl start all
						echo "===========your config==========="
						cat /etc/supervisor/conf.d/$FILENAME.conf | grep command
						echo "finish"
						PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`
					else
					        echo "not found your public key"
					fi; 
				fi;
                	else
                        	echo  "not found Transports"
                	fi;
        	else
			echo "this account is exist please enter another name"
		fi;
	else
		echo "not found file name"
	fi;

else
	echo "setup finish"
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
			printf "ss+ohttp (this is shadowsocks with simple obfs plugin ) \nhttp (http proxy) \nsocks ( socks proxy) \n"
			echo "=================== choose one pf the option ==================="
                	read -rep $'enter your gost listner type : \n'   LISTENER		
			echo "hi listener"
			if [ $LISTENER == 'ss+ohttp' ];then
				echo "hi ohttp"
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
				if [[ ${FORWARDER} ]];then
					echo "hi forwarder"
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
				fi
			elif [ $LISTENER == 'http' ];then
				echo "hi http"
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
	                        if [[ ${FORWARDER} ]];then
        	                        echo "hi forwarder"
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
	                        fi

			elif [ $LISTENER == 'socks' ];then
				echo "hi socks"
				read -rep $'please enter forwarder: \n'  FORWARDER
				sleep 1
                	        if [[ ${FORWARDER} ]];then
	                                echo "hi forwarder"
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
	                        fi

			else
				echo "not support listener"
			fi
		else
			echo "this account is avalebale" 
		fi
	else
		echo "can not find listener"
	fi;
else
        echo "setup finish"
fi;

}

revoke-conf() {
read -rep $'delete exist conf in supervisor"  : y or n:\n' -i n  MSG
if [ $MSG == 'y' ];then
	echo "=================== available account ==================="
	ls -1 /etc/supervisor/conf.d/  | sed -e 's/\.conf$//'
	read -rep $'please select an account :  \n'   CONF
	echo "===== your choice is ====="
	echo $CONF
	echo "==================="
	read -rep $'are you sure to delete this account ?"  : y or n:\n' -i n  DELETE
	if [ $DELETE == 'y' ];then
		rm -f /etc/supervisor/conf.d/$CONF.conf
		echo "=========== restart supervisor ==========="
               	supervisorctl reread && supervisorctl update && supervisorctl stop all &&  supervisorctl start all
		echo "your account is deleted."
	else
	        echo "revoke is finish"

	fi;

else
	echo "revoke is finish"
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
