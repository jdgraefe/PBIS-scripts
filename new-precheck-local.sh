#! /bin/sh

OSMAJOR=`(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)|cut -c1)`
SERVER=`hostname`
LINE="###############################"
SECTION="#################################################################"
CUSTOMPROFILE="/etc/profile.d/custom_profile.sh"
SPACER=" "
RED='\033[0;31m'
NC='\033[0;37m'

#
echo $SECTION
echo $SECTION
echo "##  Running PBIS Pre-Migration on host $SERVER"
echo $SECTION
echo $SECTION
echo -n "OS Version: ";  cat /etc/redhat-release
#
echo $SPACER
echo $SPACER
#
f_check_sudoers ()
{
echo "Checking groups in sudoers files" 
grep ^% "/etc/sudoers.d/"*"" |awk '{print $1}'|sort -u >/tmp/sudoersgroups
for i in `cat /tmp/sudoersgroups`
do 
echo "SUDO GROUP: $i"
done
echo $SPACER
echo $SPACER
}

#
#
# Check the profile for BT account access
#for i in `cat rg35`; do ssh $i pbrun pbtest; done
echo "Checking the custom profile for BT account access"
if [ -f $CUSTOMPROFILE ]
 then grep pz $CUSTOMPROFILE
else echo "custom_profile.sh not found"
fi
#
echo $SPACER
echo $SPACER
# Check for oracle groups / users
echo "Checking for local oracle users and groups"
 grep dba /etc/group; grep oracle /etc/passwd
#
echo $SPACER
echo $SPACER
#
#
#PBIS install needs bc binary - checking for i here
echo "Checking if "bc" rpm installed"
 rpm -qa bc
#
echo $SPACER
echo $SPACER

f_check_puppet()
{
echo "Checking for Puppet installation and version"
puppet -V >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "PUPPET: May not be Installed"
else
    PUPVER=`puppet -V |cut -c1`
	if [ $PUPVER -eq 3 ]; then
	 PUPCONF=/etc/puppet/puppet.conf
	elif [ $PUPVER -eq 4 ]; then
	 PUPCONF=/etc/puppetlabs/puppet/puppet.conf
	fi
	echo "PUPPET: Version: $PUPVER"
	echo "PUPPET: status: `grep noop $PUPCONF`"
fi
echo $SPACER
echo $SPACER

}

# Checking for local service accounts
# Checks for processes or crontabs owned by a service account then checks if it is local or not
echo "Checking for non-local service accounts"
f_check_procs()
{
echo "Checking for processes running from non-local service accounts"
for P in `ls -l /proc |awk '{print $3}' -`
do 
	if [ $P != root ]
	 then grep -q $P /etc/passwd
	  if [ $? -ne 0 ]
	   then echo "PROC: $P"
	   ((COUNT++))
#echo $COUNT
	  fi
	fi
done #|sort -u
# For debug
 #echo "COUNT= $COUNT"
if [ $COUNT -eq  0 ]; then echo "PROC: NONE"
   fi
echo $SPACER
echo $SPACER
}

# Check last logins of service accounts where possible
f_check_last_sc()
{
echo "Checking for Service Accounts recently logged in"
last |grep ^pz |awk '{print $1}'  |sort -u
echo ""
echo "Checking for ssh publickey connections from Service Accounts"
echo -n "PUBLICKEY:"; grep -e pz -e nz /var/log/secure |grep publickey
echo $SPACER
echo $SPACER
}
# add check of home dirs
# Find non-prod nz accounts
# echo "Checking /home for Potential Non-prod Accounts"

f_check_home_n()
{
echo "Checking for home directories from non-local non-prod service accounts"
touch /tmp/nzaccts
ls -d /home/nz* >/tmp/nzaccts 2>/dev/null
for NP in `cat /tmp/nzaccts`
do
  grep -q `basename $NP` /etc/passwd
	if [ $? -ne 0 ]
	 then echo HOME: `basename $NP`
	fi
done |sort -u

echo $SPACER
echo $SPACER
}

f_check_home_p()
{
# Find prod pz accounts
#echo "Checking /home for Potential Prod Accounts"
echo "Checking for home directories from non-local PROD service accounts"
touch /tmp/pzaccts
ls -d /home/pz* >/tmp/pzaccts 2>/dev/null
for P in `cat /tmp/pzaccts`
do
  grep -q `basename $P` /etc/passwd
	if [ $? -ne 0 ]
	 then echo HOME: `basename $P`
	fi
done |sort -u
echo $SPACER
echo $SPACER
}

f_check_cron_allow()
{
# Check accounts that might be using cron
echo "Non Local accounts listed in cron.allow"
CRONALLOW=0
cat /dev/null > /tmp/cronaccts
if [ -f /etc/cron.allow ]
 then cat /etc/cron.allow |grep -v ^\# >>/tmp/cronaccts 
fi
for C in `cat /tmp/cronaccts`
do
  grep -q $C /etc/passwd
   if [ $? -ne 0 ]
    then echo CRONALLOW: `basename $C`
    ((CRONALLOW++))
   fi
done 
if [ $CRONALLOW -eq  0 ]; then echo "CRONALLOW: NONE"
   fi
echo $SPACER
echo $SPACER
}

f_check_cron()
{
# Check accounts that might be using cron
echo "Non Local accounts that own crontab files"
cat /dev/null > /tmp/cronfileaccts
CRONFILES=0
 ls /var/spool/cron >/tmp/cronfileaccts
 for C in `cat /tmp/cronfileaccts`
do
  grep -q $C /etc/passwd
   if [ $? -ne 0 ]
    then echo  CRONTAB: `basename $C`
    ((CRONFILES++))
   fi
done 
if [ $CRONFILES -eq  0 ]; then echo "CRONTAB: NONE"
fi
echo $SPACER
echo $SPACER
}

# will check ports for AD connections prior to PBIS Migration
f_check_ports()
{
PORTFAIL=0
PORTLIST="53 88 389 445 464 3268"

if [ $OSMAJOR = 6 ] || [ $OSMAJOR = 5 ]; then 
  NCCMD="nc -w 3 -z -v"
else
  NCCMD="ncat -c date -v"
fi

for i in $(nslookup ad.<domain>.com | grep Address | grep -v \# | cut -d" " -f2); do 
  for j in ${PORTLIST}; do
    $NCCMD $i $j > /dev/null 2>&1
    if [ $? -ne 0 ]; then ((PORTFAIL++))
      #echo "SUCCESS: Connection to $i port $j is working!"
    else
      #echo "FAILED:  Connection to $i port $j failed!"
	:
    fi
  done
done

if [ $PORTFAIL -ne 0 ]; then echo -e "${RED} Port Checks Failed ${NC}"
 else echo "No Port Connection Failures Detected"
fi

echo $SPACER
echo $SPACER

}


f_check_ports
f_check_cron
# Next group checks service accounts that might be in use
echo "Checking for non-local service accounts"
#f_check_cron_allow
f_check_procs
f_check_home_n
f_check_home_p
f_check_puppet
f_check_last_sc

echo $SECTION
echo " End of Pre-Migration Checks for host $SERVER"
echo $SPACER
echo $SPACER
echo $SPACER
