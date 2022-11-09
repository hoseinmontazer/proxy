#!/bin/bash
#update and upgrade and install pakeage
apt update && apt upgrade -y
apt install supervisor -y
apt install python3-pip
pip install qrcode
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

read -rep $'create shadowsocks server : y or n:\n' -i y  MSG
if [ $MSG == 'y' ];then
	echo $MSG
	PASS=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
	PORT=`for i in $(seq 1); do echo $(((RANDOM % $((65000 - 2000))) + 2000));done`
	DIR=/var/log/gost
	if [ -d $DIR ];then
		echo "supervisor conf is enable"
	else	
		mkdir /var/log/gost
	fi;
	echo "create supervisor conf"
	sleep 2
	read -rep $'enter your account name: \n'   FILENAME
	if [ $FILENAME  ]; then
		if [ ! -f  /etc/supervisor/conf.d/$FILENAME.conf  ]; then
			read -rep $'enter your gost forwarder: \n'   FORWARDER
        		if [ $FORWARDER  ];then
                		echo $FORWARDER
				cat <<-EOF >  /etc/supervisor/conf.d/$FILENAME.conf
				[program:$FILENAME]
				command=gost -L=ss+ohttp://chacha20-ietf-poly1305:$PASS@:$PORT?~bypass=*.ir,*.ir/*,google.com,google.com/*,*.google.com,*.google.com/* -F="$FORWARDER"
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
				echo "===========your public key==========="
				cat  /root/.ssh/id_rsa.pub
				echo "finish"
				PUBIP=`dig @resolver4.opendns.com myip.opendns.com +short`
				echo -n "ss://"`echo -n chacha20-ietf-poly1305:$PASS@$PUBIP:$PORT | base64` | qr
                	else
                        	echo  "not found forwarder"
                	fi;
        	else
			echo "this account is exist please try again"
		fi;
	else
		echo "not found file name"
	fi;
	
else
	echo "setup finish"
fi;
