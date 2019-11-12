Defense-MN-Install
System requirements

The VPS you plan to install your masternode on needs to have at least 1GB of RAM and 10GB of free disk space. We do not recommend using servers who do not meet those criteria, and your masternode will not be stable. We also recommend you do not use elastic cloud services like AWS or Google Cloud for your masternode - to use your node with such a service would require some networking knowledge and manual configuration.
Funding your Masternode

    First, we will do the initial collateral TX and send exactly 50000 DFNX to one of our addresses. To keep things sorted in case we setup more masternodes we will label the addresses we use.

        Open your DFNX wallet and switch to the "Receive" tab.

        Click into the label field and create a label, I will use MN1

        Now click on "Request payment"

        The generated address will now be labelled as MN1 If you want to setup more masternodes just repeat the steps so you end up with several addresses for the total number of nodes you wish to setup. Example: For 10 nodes you will need 10 addresses, label them all.

        Once all addresses are created send 50000 DFNX each to them. Ensure that you send exactly 50000 DFNX and do it in a single transaction. You can double check where the coins are coming from by checking it via coin control usually, that's not an issue.

    As soon as all 2.5K transactions are done, we will wait for 6 confirmations. You can check this in your wallet or use the explorer. It should take around 6 minutes if all transaction have 6 confirmations

Installation & Setting up your Server

Generate your Masternode Private Key

In your wallet, open Tools -> Debug console and run the following command to get your masternode key:

masternode genkey

Please note: If you plan to set up more than one masternode, you need to create a key with the above command for each one.

Run this command to get your output information:

masternode outputs

Copy both the key and output information to a text file.

In your wallet, open Tools -> Open Masternode Configuration File and fill in the input:

masternodename ipaddress:16425 genkey collateralTxID outputID

An example would be

mn1 127.0.0.2:6942 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

masternodename is a name you choose, ipaddress is the public IP of your VPS, masternodeprivatekey is the output from masternode genkey, and collateralTxID & outputID come from masternode outputs. Please note that masternodename must not contain any spaces, and should not contain any special characters.

Restart and unlock your wallet.

SSH (Putty on Windows, Terminal.app on macOS) to your VPS, login as root (Please note: It's normal that you don't see your password after typing or pasting it) and run the following command:

wget https://github.com/defense-org/masternode-autoinstall/releases/download/v1.0/masternode-autoinstall.sh && bash masternode-autoinstall.sh

When the script asks, confirm your VPS IP Address and paste your masternode key (You can copy your key and paste into the VPS if connected with Putty by right clicking)

The installer will then present you with a few options.