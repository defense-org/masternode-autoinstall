
clear
# declare STRING variable
STRING1="Make sure you double check before hitting enter! Only one shot at these!"
STRING2="If you found this helpful, please donate to DFNX Donation: "
STRING3="DknNiMwphRRAdSnb6Dcg8qFagBjCxN2oHa"
STRING4="Updating system and installing required packages."
STRING5="Switching to Aptitude"
STRING6="Some optional installs"
STRING7="Starting your masternode"
STRING8="Now, you need to finally start your masternode in the following order:"
STRING9="Go to your windows wallet and from the Control wallet debug console please enter"
STRING10="startmasternode alias false <mymnalias>"
STRING11="where <mymnalias> is the name of your masternode alias (without brackets)"
STRING12="once completed please return to VPS and press the space bar"
STRING13=""

#print variable on a screen
echo $STRING1 

    read -e -p "Server IP Address : " ip
    read -e -p "Masternode Private Key (e.g. 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg # THE KEY YOU GENERATED EARLIER) : " key
    read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
    read -e -p "Install UFW and configure ports? [Y/n] : " UFW

    clear
 echo $STRING2
 echo $STRING13
 echo $STRING3 
 echo $STRING13
 echo $STRING4    
    sleep 10    

# update package and upgrade Ubuntu
    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    sudo apt-get install wget nano htop -y
    sudo apt install git -y
    sudo apt-get install build-essential libtool bsdmainutils autotools-dev autoconf pkg-config -y 
    sudo apt-get install libssl-dev libgmp-dev libevent-dev libboost-all-dev -y
    sudo apt-get install software-properties-common -y
    sudo add-apt-repository ppa:bitcoin/bitcoin -y
    sudo apt-get install libssl1.0-dev -y
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
    sudo apt-get install libminiupnpc-dev -y
    sudo apt-get install libzmq3-dev -y
    sudo apt-get install libboost-chrono1.65.1 libboost1.65-dev -y
    clear
echo $STRING5
    sudo apt-get -y install aptitude

#Generating Random Passwords
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

echo $STRING6
    if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
    cd ~
    sudo aptitude -y install fail2ban
    sudo service fail2ban restart 
    fi
    if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
    sudo apt-get install ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 16425/tcp
    sudo ufw enable -y
    fi

#Install defense Daemon
    wget https://github.com/defense-org/defense-core/releases/download/v1.0/defense_ubuntu.tar.gz
    sudo tar -xzvf defense_ubuntu.tar.gz
    sudo rm defense-1.2.0-x86_64-linux-gnu.tar.gz
    defensed -daemon
    clear
    
#Setting up coin
    clear
echo $STRING2
echo $STRING13
echo $STRING3
echo $STRING13
echo $STRING4
sleep 10

#Create defense.conf
echo '
rpcuser='$password'
rpcpassword='$password2'
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip='$ip'
bind='$ip':16425
masternodeaddr='$ip'
masternodeprivkey='$key'
masternode=1
' | sudo -E tee ~/.defense/defense.conf >/dev/null 2>&1
    sudo chmod 0600 ~/.defense/defense.conf

#Starting coin
    (crontab -l 2>/dev/null; echo '@reboot sleep 30 && defensed -daemon -shrinkdebugfile') | crontab
    (crontab -l 2>/dev/null; echo '@reboot sleep 60 && defense-cli startmasternode local false') | crontab
    defensed -daemon

    clear
echo $STRING2
echo $STRING13
echo $STRING3
echo $STRING13
echo $STRING4
    sleep 10
echo $STRING7
echo $STRING13
echo $STRING8 
echo $STRING13
echo $STRING9 
echo $STRING13
echo $STRING10
echo $STRING13
echo $STRING11
echo $STRING13
echo $STRING12
    sleep 120
    
    read -p "Press any key to continue... " -n1 -s
    defense-cli startmasternode local false
    defense-cli masternode status