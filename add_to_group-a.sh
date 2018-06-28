#! /bin/sh
# 
# Add a list of servers to a group in AD. 
# Create a file with the contents being a list of  the servers you wish to add to the group
# Name the file/list with the name of the AD group
# FILENAME=ADGROUPNAME
# Contents = server names
# Usage: add_to_group-a.sh <FILENAME>

# check for the groupname arg and see if it's valid

if [ $# -ne 1 ]
 then echo "one argument for groupname required"
 exit 1
fi
GNAME=$1
LIST=$1
NGROUPS=`/opt/pbis/bin/adtool -a search-group --name $GNAME |grep Total |awk '{print $3}' -`
if [ $NGROUPS -eq 0 ]
 then echo "$1 may not be a proper AD group"
 exit 1
fi

# Add the serves in the list to the named group

for host in `cat $LIST`
do
echo $host
/opt/pbis/bin/adtool -a add-to-group --to-group=$1 --user=$host\$
done
