
# Copyright (c) 2018-2019 The GOSSIP developers
# Copyright (c) 2018-2019 The Defense developers

CONFIG_FILE='defense.conf'
CONFIGFOLDER='/root/.defense'
COIN_DAEMON='defensed'
COIN_CLI='defense-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/defense-org/defense-core/releases/download/v1.0/defense_ubuntu.tar.gz'
COIN_ZIP='defense_ubuntu.tar.gz'
COIN_NAME='defense-core'
COIN_PORT='16425'

NODEIP=$(curl -s4 icanhazip.com)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function start_setup() {
  echo -e "${RED}"
  echo -e ""
  echo -e ""
  echo -e "${NC}"
  echo -e "${GREEN}Welcome to the Defense masternode installation${NC}"
  echo -e ""
  echo -e "${RED}Do you want to install or update your Defense masternode?${NC}"
  echo -e ""
  PS3='Please enter your choice: '
  echo -e ""
  options=("Install" "Update" "Exit")
  select opt in "${options[@]}"
  do
      case $opt in
          "Install")
              break
              ;;
          "Update")
              update_node
              ;;
          "Exit")
              exit 0
              ;;
          *) echo "Invalid option $REPLY";;
      esac
  done
}
 
function delete_old_installation() {
  echo -e "Searching and removing old ${RED}$COIN_NAME files and configurations${NC}"
  systemctl stop $COIN_NAME.service >/dev/null 2>&1
  killall -9 defensed >/dev/null 2>&1
  ufw delete allow 13370/tcp >/dev/null 2>&1
  rm -rf /root/defense* >/dev/null 2>&1
  rm -rf /root/.defense* >/dev/null 2>&1
  rm -rf /usr/local/bin/defense* >/dev/null 2>&1
  rm -rf /etc/systemd/system/defense-core.service >/dev/null 2>&1
  echo -e "${GREEN}done...${NC}";
  clear
}

function download_node() {
  echo -e "Download ${RED}$COIN_NAME${NC}"
  cd /root/ >/dev/null 2>&1
  wget -c $COIN_TGZ #&& wget -c https://bitbucket.org/GOSSIPCOIN/gossip-mn-autosetup/raw/master/goss-control.sh >/dev/null 2>&1
  chmod +x defense-control.sh >/dev/null 2>&1
  tar -xvf $COIN_ZIP >/dev/null 2>&1
  cd /root/defense-1.0.1.0-l33t/ >/dev/null 2>&1
  chmod +x $COIN_DAEMON $COIN_CLI >/dev/null 2>&1
  cp $COIN_CLI $COIN_PATH >/dev/null 2>&1
  mv $COIN_DAEMON $COIN_PATH >/dev/null 2>&1
  cd lib/ && cp *.* /usr/lib/x86_64-linux-gnu/
  cd /root/ >/dev/null 2>&1
  rm -rf defense-* >/dev/null 2>&1
  echo -e "${GREEN}done...${NC}";
  clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/defense-core.service
[Unit]
Description=defense-core service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=45s
TimeoutStartSec=10s
StartLimitInterval=60s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload >/dev/null 2>&1
  sleep 4 >/dev/null 2>&1
  systemctl start $COIN_NAME.service >/dev/null 2>&1
  systemctl enable $COIN_NAME.service >/dev/null 2>&1
  sleep 2 >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "-----------------------------------------------------------------------------------------------------------------"
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands:"
    echo -e "Start: systemctl start $COIN_NAME"
    echo -e "Status: systemctl status $COIN_NAME"
    echo -e "Logfile: less /var/log/syslog"
    echo -e "-----------------------------------------------------------------------------------------------------------------"
    exit 1
  fi
}

function create_key() {
  echo -e "Enter your ${RED}Masternode Private Key${NC} and press Enter:"
  read -e COINKEY
clear
}

function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=DFNX_usEr`shuf -i 1000000000000-100000000000000 -n 1`
  RPCPASS=DFNX_pAss`shuf -i 2000000000000-200000000000000 -n 1`
  clear

cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASS
rpcallowip=127.0.0.1
logintimestamps=1
maxconnections=224
listen=1
server=1
daemon=0
staking=0
externalip=$NODEIP:$COIN_PORT
masternode=1
masternodeprivkey=$COINKEY
EOF
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
EOF
}

function enable_firewall() {
  echo -e "----------------------"
  echo -e "Setting up firewall"
  echo -e "----------------------"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp comment "Limit SSH" >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  ufw logging on >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
  echo -e "${GREEN}done...${NC}";
clear
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]; then
    echo -e "-----------------------------------------------------------------------------------------------"
    echo -e "${RED}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
    for ip in "${NODE_IPS[@]}"
      do
      echo ${INDEX} $ip
      echo -e "-----------------------------------------------------------------------------------------------"  
      let INDEX=${INDEX}+1
      done
    read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
      else
      NODEIP=${NODE_IPS[0]}
  fi
}

function checks() {

  if [[ $EUID -ne 0 ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "${RED}$0 must be run as root.${NC}"
    echo -e "------------------------------------------------------------------"
    exit 1
  fi
}

function prepare_system() {
  echo -e "-----------------------------------------------------------------------"
  echo -e "Prepare the system to install the ${GREEN}DFNX${NC} masternode..."
  echo -e "Installing tools and tune your swap..."
  echo -e "Please be patient and wait a moment..."
  echo -e "-----------------------------------------------------------------------"
  sysctl vm.swappiness=10 >/dev/null 2>&1
  echo -e  "vm.swappiness=10" >> /etc/sysctl.conf >/dev/null 2>&1
  sysctl vm.vfs_cache_pressure=50 >/dev/null 2>&1
  echo -e "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf >/dev/null 2>&1
  sysctl -p >/dev/null 2>&1
  apt-get update >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
  apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" wget ufw fail2ban nano htop >/dev/null 2>&1
  export LC_ALL="en_US.UTF-8" >/dev/null 2>&1
  export LC_CTYPE="en_US.UTF-8" >/dev/null 2>&1
  locale-gen --purge >/dev/null 2>&1
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  if [ "$?" -gt "0" ];
    then
      echo -e "----------------------------------------------------------------------------------------------------------------------------------"
      echo -e "${RED}Not all required packages were installed properly.${NC} Try to install them manually by running the following commands:"
      echo -e "apt-get update && apt -y install wget ufw fail2ban nano htop"
      echo -e "----------------------------------------------------------------------------------------------------------------------------------"
    exit 1
  fi
  clear
}

function wallet_active() {
  systemctl start $COIN_NAME.service >/dev/null 2>&1
  sleep 2
  if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
    echo -e "--------------------------------------------"
    echo -e "${GREEN}$COIN_NAME daemon is up and running!${NC}"
    echo -e "--------------------------------------------"
  else
    echo -e "-----------------------------------------------------------------------------------------"
    echo -e "${RED}$COIN_NAME daemon is not running!${NC} Try to start manually: systemctl start $COIN_NAME"
    echo -e "-----------------------------------------------------------------------------------------"
    exit 1
  fi
}

function check_connections() {
  echo -e "-----------------------------------------------------------------------"
  echo -e "Waiting at least ${RED}4 connections${NC} to sync the blockchain..."
  echo -e "-----------------------------------------------------------------------"
  connectioncount=$(/usr/local/bin/defense-cli getconnectioncount)
    while [ $connectioncount -lt "3" ]; do
    connectioncount=$(/usr/local/bin/defense-cli getconnectioncount)
    echo -e "We have only $connectioncount connections to other nodes..."
    echo -e "I will try to find other nodes in the network..."
    sleep 5
      if [[ "$connectioncount" -gt "3" ]]; then
        break
      fi
    done
  echo -e "We have more than ${GREEN}3${NC} network connections, let's go."
  clear
}

function sync_node() {
  echo -e "-----------------------------------------------------------------------"
  echo -e "Defense blockchain synchronization in progress..."
  echo -e "-----------------------------------------------------------------------"
  DFNXblocks=$(curl -s http://chain.DFNX.io/api/getblockcount)
  walletblocks=$(/usr/local/bin/defense-cli getblockcount)
  echo "Blockcount on your node: $walletblocks"
  echo "Blockcount on the Defense blockchain: $DFNXblocks"
  echo -n ' '
    while [ "$walletblocks" -lt "$DFNXblocks" ]; do
      walletblocks=$(/usr/local/bin/defense-cli getblockcount)
      echo -e "$walletblocks from $DFNXblocks synced..."
      sleep 3
    if [[ "$walletblocks" == "$DFNXblocks" ]]; then
      break
    fi
  done
  echo -e "${GREEN}Your node is in sync!${NC}"
  clear
}

function important_information() {
  rm /root/DFNX-mn-autosetup.sh >/dev/null 2>&1
  echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo -e "${GREEN}This installation was successfull! Good job!${NC}"
  echo -e "${BLUE}Your DFNX Masternode is up and running, you have enough connections and the blockchain is synced.${NC}"
  echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo -e "MASTERNODE PRIVATEKEY is: $COINKEY"
  echo -e "Your IP and Port: $NODEIP:$COIN_PORT"
  echo -e "Masternode configuration: $CONFIGFOLDER/$CONFIG_FILE"
  echo -e "Start manually: sudo ./DFNX-control.sh -a"
  echo -e "Stop manually: sudo ./DFNX-control.sh -b"
  echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo -e "${GREEN}Now you can start your Masternode from your QT wallet${NC}"
  echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo -e "${RED} After the start from the QT wallet do a double check here to see if your node is started!${NC}"
  echo -e "${RED}sudo ./DFNX-control.sh -f${NC}"
  echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

function update_clean() {
  echo -e "Stopping and removing the ${RED}$COIN_NAME daemon${NC}. Be patient a moment..."
  systemctl stop $COIN_NAME.service
  sleep 10
  killall -9 DFNXd
  rm /usr/local/bin/$COIN_CLI 
  rm /usr/local/bin/$COIN_DAEMON 
  echo -e "${GREEN}done...${NC}";
  clear
}

function tune_memory() {
  echo -e "We will tune your swap memory..."
  echo -e  "vm.swappiness=10" >> /etc/sysctl.conf
  sysctl vm.vfs_cache_pressure=50 
  echo -e "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
  sysctl -p 
  clear
}

function update_daemon() {
  echo -e "Download and update ${RED}$COIN_NAME${NC}"
  cd /root >/dev/null 2>&1
  wget -c $COIN_TGZ >/dev/null 2>&1
  tar -xvf $COIN_ZIP >/dev/null 2>&1
  cd /root/defense-1.0.1.0-l33t-linux/ >/dev/null 2>&1
  chmod +x $COIN_DAEMON $COIN_CLI  >/dev/null 2>&1
  cp $COIN_CLI $COIN_PATH  >/dev/null 2>&1
  mv $COIN_CLI $COIN_DAEMON $COIN_PATH >/dev/null 2>&1
  cd -  >/dev/null 2>&1
  rm -R defense-1.0.1.0-l33t* >/dev/null 2>&1
  systemctl start $COIN_NAME.service >/dev/null 2>&1
  rm -r DFNX-mn-autosetup.sh >/dev/null 2>&1
  clear
  echo -e "----------------------------------"
  echo -e "${GREEN}Update successfull!${NC}";
}

function update_node() {
  clear
  update_clean
  tune_memory
  update_daemon
  wallet_active
  exit 0
}

function setup_node() {
  #get_ip
  create_key
  create_config
  #update_config
  configure_systemd
  enable_firewall
  wallet_active
  check_connections
  sync_node
  important_information
}

##### Main #####
clear
checks
start_setup
delete_old_installation
prepare_system
download_node
setup_node

    © 2019 GitHub, Inc.
    Terms
    Privacy
    Security
    Status
    Help

    Contact GitHub
    Pricing
    API
    Training
    Blog
    About

