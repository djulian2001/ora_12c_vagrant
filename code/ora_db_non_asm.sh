#! /bin/sh

# update the OS the packages
sudo yum -y update
sudo yum -y clean all

# The purpose of this shell script is to install an oracle 12c database with the following:
#	- non-ASM (no grid)
#	- single dedicated database instance
#	- net listener service
# The steps will be as follows:
#	setup hostname
#	install package dependency
#	configure users and groups
#	setup directory structures

echo "STEP :  Oracle 12c dependency installation"
declare -a ORA_DEPENDENCY_LIST=(
	"binutils.x86_64" "compat-libcap1.x86_64" "gcc.x86_64" "gcc-c++.x86_64"
	"glibc.i686" "glibc.x86_64" "glibc-devel.i686" "glibc-devel.x86_64" "ksh"
	"compat-libstdc++-33" "libaio.i686" "libaio.x86_64" "libaio-devel.i686"
	"libaio-devel.x86_64" "libgcc.i686" "libgcc.x86_64" "libstdc++.i686"
	"libstdc++.x86_64" "libstdc++-devel.i686" "libstdc++-devel.x86_64"
	"libXi.i686" "libXi.x86_64" "libXtst.i686" "libXtst.x86_64"
	"make.x86_64" "sysstat.x86_64" "zip" "unzip"
)
for ORA_DEPENDENCY in "${ORA_DEPENDENCY_LIST[@]}"
do
	sudo yum -y install $ORA_DEPENDENCY
done

sudo yum -y clean all


echo "STEP :  host setup for oracle 12c use"
sudo hostnamectl --static set-hostname ora12c-vagrant.biodesign.asu.edu
# disable firewall services.
sudo service firewalld stop
sudo systemctl disable firewalld
###  READ UP On this firewalld stuff...
cat /vagrant/code/configs/ora_sysctl.conf | sudo tee -a /etc/sysctl.conf 1> /dev/null
sudo sysctl -p 1> /dev/null
cat /vagrant/code/configs/ora_limits.conf | sudo tee -a /etc/security/limits.conf  1> /dev/null


echo "STEP :  Users and Groups Configuration"
sudo groupadd oinstall
sudo groupadd dba
sudo useradd -g oinstall -G dba oracle
echo "oracle:ora12c" | sudo chpasswd


echo "STEP :  Pre-Install Oracle setup"
sudo mkdir /stage
sudo unzip /vagrant/ora_installs/linuxamd64_12102_database_1of2.zip -d /stage/
sudo unzip /vagrant/ora_installs/linuxamd64_12102_database_2of2.zip -d /stage/
sudo chown -R oracle:oinstall /stage/

# software files
sudo mkdir -p /u01/app/oraInventory
sudo mkdir -p /u01/app/oracle/product/12.1.0/db_1
sudo chown -R oracle:oinstall /u01
sudo chmod -R 775 /u01
sudo chmod g+s /u01
# database files
sudo mkdir -p /oracle/db1/controlfile
sudo mkdir -p /oracle/db1/data
sudo mkdir -p /oracle/db1/recoveryarea
sudo chown oracle:oinstall -R /oracle/


echo "STEP :  Set Oracle Enviornment Variables"
cat /vagrant/code/configs/ora_bash_profile.conf | sudo -i -u oracle tee -a .bash_profile 1> /dev/null


echo "STEP :  Oracle Database Install - response file silent mode"
sudo -i -u oracle /stage/database/runInstaller -silent -responseFile /vagrant/code/configs/ora_software_only.rsp -showProgress -ignorePrereq | while read l ; do echo "$l" ; done
# http://dbaora.com/install-oracle-in-silent-mode-12c-release-1-12-1/
# /stage/database/runInstaller --help
sudo /u01/app/oraInventory/orainstRoot.sh
sudo /u01/app/oracle/product/12.1.0/db_1/root.sh


echo "STEP :  Oracle Listener Install - response file silent mode"
# netca -silent -responsefile /home/oracle/netca.rsp

echo "STEP :  Wha_Wha_What!"
echo "STEP :  Wha_Wha_What!"
