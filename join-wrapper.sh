#!/bin/sh
# Editor Settings: expandtabs and use 4 spaces for indentation
# ex: set softtabstop=4 tabstop=8 expandtab shiftwidth=4:

# Professional Services Script to perform installs/upgrades of PBIS client and associated account migrations.
#
# (c) 2008-2016 BeyondTrust Software
# Some portions (c) 2008 Steven Kaplan, IBM
#
# Revision List now at bottom of script.
# For usage, run this script with only the "--help" flag
#
#
# Darwin installs - no darwin features supported at all.
script_version="6.6.0"

#########################################################
# STANDARD INSTALL OPTIONS                              #
# SHOULD BE REVIEWED/MODIFIED BY CUSTOMERS              #
#########################################################
LIKEWISE_PRODUCT_NAME="pbis-enterprise"	#Normally will not change
LW_VERSION="8.5"
QFENUMBER="3"
BUILDNUMBER="289"
TESTUSER="pzunix1"	#This needs to be set to a valid PBIS user for lookup.  Account will lock with bad password attempts when using SSHTEST or LSA_AUTH_TEST
DEFAULT_JOIN_CMD="join"
DEFAULT_JOIN_OPTS="--disable hostname --notimesync"  #DO NOT INCLUDE "--ou" here anymore. It's automatically added if the JOIN_OU parameter is not "NONE"
HOMEDIR=/home
DOMAIN_TRUST_LIST=""
REQUIRE_MEMBERSHIP_GROUP=""
REQUIRE_MEMBERSHIP_GROUP_PREFIX=""
REQUIRE_MEMBERSHIP_GROUP_DOMAIN=""
REQUIRE_MEMBERSHIP_VALIDATE=
CACHE_TIME="4h"

#PATH OPTIONS
INSTALL_DIR="."
NFSPATH="srv1:/home/share/"
MOUNTPOINT="/pbis/install"
SETEXTRACTYES="1"
EXTRACTPREFIXDIR="/tmp/pbis"
OUTFILE_DIR="/var/log/pbislogs"
BACKUP_DIR_ROOT="/root/.pbis-backup"
OUTFILE_NAME=`hostname`-pbis-install-results.out
HOMEDIR_EXCEPTION_REPORT=$INSTALL_DIR/logs/homedirs.log

#AUDITING OPTIONS
COLLECTOR_SERVER=""
COLLECTOR_SPN=""
ALLOWDREADGROUP=""

#ADMIN_USER OPTIONS
ADMIN_USER="pbis" 
ADMIN_GECOS="PBIS service account"
ADMIN_USER_PASSWORD="PBISE123!"
ADMIN_GID=9999
ADMIN_UID=909090901
ADMIN_SHELL="/bin/bash"
ADMIN_USER_GROUPS="wheel admin sysadmin sudo"

#########################################################
# ADVANCED/UNCOMMON INSTALL OPTIONS                     #
# MAY BE MODIFIED BY CUSTOMERS                          #
#########################################################
NSS_MODULES_TO_REMOVE="ldap"	#"nis winbind ldap sss"
PAM_MODULES_TO_REMOVE="faillock ldap"	#"ldap krb5 winbind faillock"
DELETE_PAM_LINES=
JOIN_SLEEP=120
REPLICATION_SLEEP=120
NUMBER_OF_DOMAINS=2  # Equal to or less than the number reported in get-status
HOMEDIR_MOVE_ACTION="link"  # "link" or "move".  "move" is the historical operation
DEPLOY_DIR="$INSTALL_DIR/deploy"
DEL_USER_LIST="$DEPLOY_DIR/delete_user.txt"
SKIP_USER_LIST="$DEPLOY_DIR/skip_user.txt"
SKIP_GROUP_LIST="$DEPLOY_DIR/skip_group.txt"
ALIAS_GROUP_FILE="$DEPLOY_DIR/alias_group.txt"
ALIAS_USER_FILE="$DEPLOY_DIR/alias_user.txt"
BOX2NIS_FILE="$DEPLOY_DIR/box2nisname.txt"
EXCLUDE_FILE="$DEPLOY_DIR/excludefile.txt"
SERVER_ACCESS_GROUPS_FILE="$DEPLOY_DIR/server-access-groups.txt"
passwdmap="$BACKUP_DIR_ROOT/usermap.txt"
groupmap="$BACKUP_DIR_ROOT/groupmap.txt"
passwdorg="$BACKUP_DIR_ROOT/userorg.txt"
grouporg="$BACKUP_DIR_ROOT/grouporg.txt"
wbusers="$BACKUP_DIR_ROOT/passwd.wb"    ;#original passwd
wbgroups="$BACKUP_DIR_ROOT/group.wb"    ;#original group
NAWK_GOOD_ENOUGH=0    #nawk is not good enough, we need /usr/xpg4/bin/awk on Solaris
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/contrib/bin
PERL="/usr/bin/perl"
customer_pre_install_script=$DEPLOY_DIR/customer_pre_install.sh
customer_pre_join_script=$DEPLOY_DIR/customer_pre_join.sh
customer_post_join_script=$DEPLOY_DIR/customer_post_join.sh
customer_post_wrapper_script=$DEPLOY_DIR/customer_post_wrapper.sh

#########################################################
# DEFAULT FLAGS FOR MODULE EXECUTION                    #
# WILL BE SET BY BEYONDTRUST FOR CUSTOMER CONFIGURATION #
# CAN BE MODIFIED BELOW OR                              #
# OVER-RIDDEN VIA COMMAND LINE OPTIONS                  #
#########################################################
DEFAULT_DO_LOG=1
DEFAULT_DO_DEBUG=
DEFAULT_DO_PASSWDBACKUP=1
DEFAULT_DO_BACKUP=1
DEFAULT_DO_NFS_MOUNT=
DEFAULT_DO_RUN_CUSTOMER_SCRIPTS=1
DEFAULT_DO_CUSTOM_PRE_INSTALL=
DEFAULT_DO_ALT_PROVIDER_REMOVE=1
DEFAULT_DO_SELINUX_DISABLE=
DEFAULT_DO_NSCD_DISABLE=1
DEFAULT_DO_LEAVE=
DEFAULT_DO_UNINSTALL=
DEFAULT_DO_REMOVE_NIS=
DEFAULT_DO_DISABLE_YPBIND=
DEFAULT_DO_REMOVE_NSS=1
DEFAULT_DO_REMOVE_PAM=1
DEFAULT_DO_ADMIN_USER=
DEFAULT_DO_INSTALL=1                    # Always keep this enabled to do installs (even if repo)
DEFAULT_DO_REPO_INSTALL=                # Enable this to attempt repo installs over sfx
DEFAULT_DO_ALLOW_SPARSE_INSTALL=1
DEFAULT_DO_AUDITING=
DEFAULT_DO_ENABLE_LOCAL_PROVIDER=1      #1 enables it for AIX, 2 enables for all
DEFAULT_DO_ASSUME_DEFAULT_DOMAIN=
DEFAULT_DO_CUSTOM_PRE_JOIN=
DEFAULT_DO_SKEL_CHANGE=
DEFAULT_DO_REQUIRE_MEMBERSHIP_OF=1
DEFAULT_DO_EDIT_CACHE=
DEFAULT_DO_EDIT_NSSWITCH_NETGROUP=
DEFAULT_DO_LSA_AUTH_TEST=1
DEFAULT_DO_SSH_TEST=
DEFAULT_DO_HOME_DIR_PROCESS=
DEFAULT_DO_USERDEL=1
DEFAULT_DO_USERDEL_FILE=1
DEFAULT_DO_GROUPDEL_FILE=1
DEFAULT_DO_GROUP_CLEANUP=
DEFAULT_DO_REMOVE_PRIVATE_GROUPS=
DEFAULT_DO_UPDATE_DNS=
DEFAULT_DO_CUSTOM_POST_JOIN=
DEFAULT_DO_PURGE_ACCOUNT_DATA=
DEFAULT_DO_SKIP_LOCAL_UID_CONFLICTS=1
DEFAULT_DO_CHOWN=1
DEFAULT_DO_REMOVE_REPO=
DEFAULT_DO_PRESERVE_ON_SUCCESS=1 # When enabled, preserve the scripts and "pbis-input-paramaters".  Otherwise they are deleted upon successful script exit. Use "" on NFS locations, "1" if puppet is delivering
DEFAULT_DO_CREATE_DEPLOY=
DRYRUN=0
#########################################################
# CUSTOMERS SHOULD NOT MODIFY ANYTHING AFTER THIS LINE  #
# WITHOUT GUIDANCE FROM BEYONDTRUST SERVICES!!!!!!!!!!  #
#########################################################
# END USER VARIABLES

# START CUSTOM/DEBUG CODE
	#if [ -f $passwdmap ]; then
        #    rm $passwdmap
        #fi
        #if [ -f $groupmap ]; then
        #    rm $groupmap
        #fi
# END CUSTOM/DEBUG CODE

#
# Pass defaults into the real options used in the script
#
DO_LOG=$DEFAULT_DO_LOG
DO_DEBUG=$DEFAULT_DO_DEBUG
DO_PASSWDBACKUP=$DEFAULT_DO_PASSWDBACKUP # Covers /etc/passwd, /etc/group, /etc/shadow
DO_BACKUP=$DEFAULT_DO_BACKUP  # Pre-backup nsswitch.conf, sshd_config, krb5.conf, etc.
DO_NFS_MOUNT=$DEFAULT_DO_NFS_MOUNT
DO_RUN_CUSTOMER_SCRIPTS=$DEFAULT_DO_RUN_CUSTOMER_SCRIPTS
DO_CUSTOM_PRE_INSTALL=$DEFAULT_DO_CUSTOM_PRE_INSTALL
DO_ALT_PROVIDER_REMOVE=$DEFAULT_DO_ALT_PROVIDER_REMOVE
DO_SELINUX_DISABLE=$DEFAULT_DO_SELINUX_DISABLE
DO_NSCD_DISABLE=$DEFAULT_DO_NSCD_DISABLE
DO_LEAVE=$DEFAULT_DO_LEAVE
DO_UNINSTALL=$DEFAULT_DO_UNINSTALL
DO_LEAVE=$DEFAULT_DO_LEAVE
DO_UNINSTALL=$DEFAULT_DO_UNINSTALL
DO_REMOVE_NIS=$DEFAULT_DO_REMOVE_NIS
DO_DISABLE_YPBIND=$DEFAULT_DO_DISABLE_YPBIND
DO_REMOVE_NSS=$DEFAULT_DO_REMOVE_NSS
DO_REMOVE_PAM=$DEFAULT_DO_REMOVE_PAM
DO_ADMIN_USER=$DEFAULT_DO_ADMIN_USER
DO_REPO_INSTALL=$DEFAULT_DO_REPO_INSTALL
DO_INSTALL=$DEFAULT_DO_INSTALL
DO_ALLOW_SPARSE_INSTALL=$DEFAULT_DO_ALLOW_SPARSE_INSTALL
DO_AUDITING=$DEFAULT_DO_AUDITING
DO_ENABLE_LOCAL_PROVIDER=$DEFAULT_DO_ENABLE_LOCAL_PROVIDER
DO_ASSUME_DEFAULT_DOMAIN=$DEFAULT_DO_ASSUME_DEFAULT_DOMAIN
DO_CUSTOM_PRE_JOIN=$DEFAULT_DO_CUSTOM_PRE_JOIN
JOIN_CMD=$DEFAULT_JOIN_CMD
JOIN_OPTS=$DEFAULT_JOIN_OPTS
DO_SKEL_CHANGE=$DEFAULT_DO_SKEL_CHANGE
DO_REQUIRE_MEMBERSHIP_OF=$DEFAULT_DO_REQUIRE_MEMBERSHIP_OF
DO_EDIT_CACHE=$DEFAULT_DO_EDIT_CACHE
DO_EDIT_NSSWITCH_NETGROUP=$DEFAULT_DO_EDIT_NSSWITCH_NETGROUP
DO_LSA_AUTH_TEST=$DEFAULT_DO_LSA_AUTH_TEST
DO_SSH_TEST=$DEFAULT_DO_SSH_TEST
DO_HOME_DIR_PROCESS=$DEFAULT_DO_HOME_DIR_PROCESS
DO_USERDEL=$DEFAULT_DO_USERDEL
DO_USERDEL_FILE=$DEFAULT_DO_USERDEL_FILE
DO_GROUP_CLEANUP=$DEFAULT_DO_GROUP_CLEANUP
DO_REMOVE_PRIVATE_GROUPS=$DEFAULT_DO_REMOVE_PRIVATE_GROUPS
DO_UPDATE_DNS=$DEFAULT_DO_UPDATE_DNS
DO_CUSTOM_POST_JOIN=$DEFAULT_DO_CUSTOM_POST_JOIN
DO_PURGE_ACCOUNT_DATA=$DEFAULT_DO_PURGE_ACCOUNT_DATA
DO_SKIP_LOCAL_UID_CONFLICTS=$DEFAULT_DO_SKIP_LOCAL_UID_CONFLICTS
DO_CHOWN=$DEFAULT_DO_CHOWN
DO_REMOVE_REPO=$DEFAULT_DO_REMOVE_REPO
DO_PRESERVE_ON_SUCCESS=$DEFAULT_DO_PRESERVE_ON_SUCCESS
DO_CREATE_DEPLOY=$DEFAULT_DO_CREATE_DEPLOY
TODAY=`date '+%y%m%d%H%M'`

#
# Supporting functions setup
#
# This block included from: ././helper-functions.sh.

# Editor Settings: expandtabs and use 4 spaces for indentation
# ex: set softtabstop=4 tabstop=8 expandtab shiftwidth=4:

TODAY=`date '+%y%m%d%H%M'`
ECHO="echo" # Update in get-ostype.sh to specify different version of echo
AWK="awk" # Update in get-ostype.sh to specify different version of awk
TRUE="/bin/true"

# Because you never know what you're going to get...
unalias cp >/dev/null 2>&1
unalias mv >/dev/null 2>&1
unalias rmdir >/dev/null 2>&1


#
# Error usage:
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# error `ERR_OPTIONS`
# exit_with_error `ERR_LDAP`
# 
# or:
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_with_status
# 
# or
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_status
#
# or
# 
# error `ERR_OPTIONS`
# error `ERR_ACCESS`
# exit_if_error
# --- more code
#
ERR_UNKNOWN ()      { echo 1; }
ERR_OPTIONS ()      { echo 2; }
ERR_OS_INFO ()      { echo 2; }
ERR_ACCESS  ()      { echo 4; }
ERR_FILE_ACCESS ()  { echo 4; }
ERR_SYSTEM_CALL ()  { echo 8; }
ERR_DATA_INPUT  ()  { echo 16; }
ERR_LDAP        ()  { echo 32; }
ERR_NETWORK ()      { echo 64; }
ERR_CHOWN   ()      { echo 256; }
ERR_STAT    ()      { echo 512; }
ERR_MAP     ()      { echo 1024; }

gRetVal=0

error()
{
    A=$gRetVal
    B=$1
    SaveA=0  #Neccessary?  only if "error 0"
    # allows "error 0" to *unset* the error status
    while [ $B -ne 0 ] ; do
        SaveA=$A
        A=`expr \$A \/ 2`
        B=`expr \$B \/ 2`
    done
    A=`expr \$A \* 2`
    if [ $SaveA -eq $A ] ; then
        gRetVal=`expr \$gRetVal \+ $1`
    fi
    return $gRetVal
}
exit_with_error()
{
    if ( [ -n "$progressmessage" ] ) && ( [ -n "$DO_INSTALL" ] || [ -n "$DO_REPO_INSTALL" ] ); then
	printf "%b" "$progressmessage"
    fi
    error $1
    exit_status $gRetVal
}
exit_if_error()
{
    if [ $gRetVal -ne 0 ]; then
        exit_status $gRetVal
    fi
}
exit_status()
{
    if [ $gRetVal -eq 0 ]; then
        cleanup_and_exit $gRetVal "Y"
        # most scripts aren't the wrapper, so they don't need this
        #$(dirname $0)/deploy/restore-full.sh $BACKUP_INSTANCE --restore-passwd
    else
        cleanup_and_exit $gRetVal "N"
    fi
}

cleanup_and_exit () 
{
    if [ -n "${DO_PRESERVE_ON_SUCCESS}" ]; then
        DELETESCRIPT="N"
    else
        DELETESCRIPT=$2
    fi

    if [ -z "$DELETESCRIPT" ]; then
        DELETESCRIPT='N'
    fi

    LOCALSCRIPT=`basename $0`

    if [ "${DELETESCRIPT}" = "Y" ] && [ -f "$0" ]; then
        $ECHO "Removing script..."
        /bin/rm -f "$0"
    fi
    if [ "${DELETESCRIPT}" = "Y" ] && [ -f "`dirname $0`/pbis-input-parameters" ]; then
        $ECHO "Removing input parameters"
        /bin/rm -f "`dirname $0`/pbis-input-parameters"
    fi
    if [ "${DELETESCRIPT}" = "Y" ] && [ -d "`dirname $0`/deploy" ]; then
        $ECHO "Removing deploy directory"
        /bin/rm -rf "`dirname $0`/deploy"
    fi

    exit $gRetVal
}

clearcomments ()
{
    if [ -r "$1" ]; then
        $SED -e '/^[[:space:]]*[#;\/]/d' -e '/^[[:space:]]*$/d' $1
    else
        echo $1 | $SED -e '/^[[:space:]]*[#;\/]/d' -e '/^[[:space:]]*$/d'
    fi  
}


#####################################################################
# Floating point math GPLv2 from Mitch Frazier at Linux Journal
# http://www.linuxjournal.com/content/floating-point-math-bash
float_scale=2

#####################################################################
# Evaluate a floating point number expression.
float_eval()
{
    if [ -x "`which bc`" ]; then

        unset stat
        unset result
        stat=0
        result=0.0
        if [ $# -gt 0 ]; then
            result=`$ECHO "scale=$float_scale; $*" | bc 2>/dev/null`
            stat=$?
            if [ $stat -eq 0 ] &&  [ -z "$result" ]; then stat=1; fi
        fi
        $ECHO $result
        return $stat
        unset stat
        unset result
    else
        $ECHO "ERROR: no 'bc' program, can't do floating point math"
        #TODO add in replacements with awk to do tens
        exit_with_error `ERR_OS_INFO`
    fi

}

#####################################################################
# Evaluate a floating point number conditional expression.
# float_cond returns "1" for true!!!!
float_cond()
{
    if [ -x "`which bc`" ]; then
        unset cond
        cond=0
        if [ $# -gt 0 ]; then
            cond=`$ECHO "$*" | bc  2>/dev/null`
            if [ -z "$cond" ]; then cond=0; fi
            if [ "$cond" != 0 ] && [ "$cond" != 1 ]; then cond=0; fi
        fi
        unset stat
        if [ $cond -eq 0 ]; then
            stat=1
        else
            stat=0
        fi
        $ECHO $cond
        return $cond
        unset stat
        unset cond
    else
        $ECHO "ERROR: no 'bc' program, can't do floating point math"
        #TODO add in replacements with awk to do tens
        exit_with_error `ERR_OS_INFO`
    fi

}

get_on_off()
{
    if [ -z "$1" ]; then
        $ECHO "off"
    else
        $ECHO "on"
    fi
}
psection()
{
    pblank
    $ECHO "#####################################################"
    $ECHO "$@"
    $ECHO "#####################################################"
}

pline()
{
    $ECHO "-----------------------------------------------------"
}

pblank()
{
    $ECHO ""
}

# prints the result of adding two numbers
add()
{
    expr $1 + $2
}

cp_verbose()
{
    OPTIONS=""
    while $ECHO "$1" | egrep '^-' >/dev/null && [ "$1" != "-" ]; do
        OPTIONS="$OPTIONS $1"
        shift 1
    done
    $ECHO "WRAPPER INFO: Copying from $1 to $2"
    cp $OPTIONS "$@"
}

print_ini_value()
{
    # prints a value from an ini file section.  
    # Example here will print "b" if called:
    # print_ini_value "[fghi]" "key1" file
    # [abcde]
    # key1=a
    # [fghi]
    # key1=b
    section=$1
    value=$2
    file=$3
    $AWK -v section="$1" -v k="$2" '$0==section{ f=1; next }; /\[/{ f=0; next }; f && $1==k{ print $NF };' "$3"
}

edit_ini_value()
{
    # reprints a an ini file with value in section changed
    # similar to above, but prints everything, changing the
    # single value.
    # DOES NOT SUPPORT VALUES WITH SPACES!!!
    section=$1
    value=$2
    newval=$3
    file=$4
    test1=`print_ini_value $section $value $file`
    if [ -z "$test1" ]; then
        # that section has no value, and we have to *add* it
        $AWK -v section="$section"  '$0==section{  print $0; print "'$value' = '$newval'"; next }; {print $0;} ' "$file"
    else 
        $AWK -v section="$section" -v k="$value" '$0==section{ f=1; print $0; next }; /\[/{ f=0; print $0; next }; f && $1==k{ $NF="'$newval'"; print $0; next; }; { print $0 }' "$file"
    fi
}

lc()
{
    tr "$@" [A-Z] [a-z]
}

lcworks()
{
    echo "$@" | tr [A-Z] [a-z]
}

dolog()
{
    $ECHO "$@" | $GREP -q "ERROR:"
    ISERR=$?
    if [ $ISERR -eq 0 ]; then
    $ECHO "$@" >&2
    fi
    if [ -f "$LOGFILE" -a "x$DO_LOG" = "x1" ]; then
        $ECHO "$@" >> $LOGFILE
    fi
    if [ "x$DO_PRINT" = "x1" -a $ISERR -ne 0 ]; then
        $ECHO "$@"
    fi
}

# returns the opposite exit code of a program. This is a platform independant
# version of the ! operator
not()
{
    "$@" && return 1
    return 0
}

# exits the program if the command fails (like the assert function in C)
or_abort()
{
    "$@" && return 0
    $ECHO "ERROR: running '$*' failed with exit code $?"
    error `ERR_UNKNOWN`
}

# escape a string so that it can be used in a sed expression (with / as the
# deliminator charactor )
sed_escape()
{
    $ECHO "$1" | sed -e 's/\([][^$\/]\)/\\\1/g'
}

sed_expr_build()
{
    sedfile=$1
    shift 1
    #$ECHO "adding '$@' to $sedfile"
    #$ECHO `sed_escape $@` >> $sedfile
    $ECHO $@ >> $sedfile
}

sed_inline_run()
{
    sedfile=$1
    editfile=$2
    backupfile=${editfile}.sedtempout
    $SED -f $sedfile $editfile > $backupfile
    if [ $? -ne 0 ]; then
        error `ERR_FILE_ACCESS`
    fi
    cp $backupfile $editfile
    rm $backupfile
}
uc()
{
    tr "$@" [a-z] [A-Z]
}

servicehandler()
{
    #if you "enable" a service with this servicehandler(), you will need to send a "start" separately.
    #servicehandler "enable" "winbind"
    #servicehandler "start" "winbind"
    # this allows "enable" to explicitly mean one thing wherever possible.
    command=$1
    daemonname=$2
    # SSH is "secsh" on HPUX.
    # nscd is "name-service-cache" on Solaris, but ONLY 10 and 11, so we handle that later.
    if [ "$OStype" = "hpux" ]; then
        if [ "$daemonname" = "sshd" ]; then
            daemonname="secsh"
        fi
        if [ "$daemonname" = "ssh" ]; then
            daemonname="secsh"
        fi
    fi
    case $servicetype in
        systemctl)
            /bin/systemctl $command $daemonname
            ;;
        upstart)
            if [ "x$command" = "xenable" ]; then
                if [ -f "/etc/init/$daemonname.override" ]; then
                    mv "/etc/init/$daemonname.override" "/etc/init/$daemonname.override.bak.$TODAY"
                else
                    awesomeprint "WRAPPER INFO: No override file to remove for $daemonname"
                fi
            elif [ "x$command" = "xdisable" ]; then
                grep manual "/etc/init/$daemonname.override" 2>/dev/null
                result=$?
                if [ "$result" -ne 0 ]; then
                    echo "manual" >> "/etc/init/$daemonname.override"
                fi
            else
                /sbin/$command $daemonname
            fi
            ;;
        service)
            if [ "x$command" = "xenable" ]; then
                /sbin/chkconfig $daemonname on
            elif [ "x$command" = "xdisable" ]; then
                /sbin/chkconfig $daemonname off
            else
                /sbin/service $daemonname $command
            fi
            ;;
        svcadm)
            # Solaris sometimes has VERY different names for things. Handle them nicely here when we know them.
            if [ "x$daemonname" = "xnscd" ]; then
                daemonname="name-service-cache"
            fi
            case $command in
                restart)
                    # restarting this way clears maintenance mode, in case we're scripting a fix around that.
                    # means we don't need to send separate "svcadm clear $daemonname"
                    /usr/sbin/svcadm disable -ts $daemonname
                    /usr/sbin/svcadm enable -s  $daemonname
                    ;;
                start)
                    /usr/sbin/svcadm enable -t $daemonname
                    ;;
                stop)
                    /usr/sbin/svcadm disable -t $daemonname
                    ;;
                reload)
                    /usr/sbin/svcadm refresh $daemonname
                    ;;
                *)
                    # allows enable/disable to work normally
                    /usr/sbin/svcadm $command $daemonname
                    ;;
            esac
            ;;
        launchctl)
            launchctl $command com.likewisesoftware.$daemonname
            launchctl $command com.beyondtrust.$daemonname
            launchctl $command com.apple.$daemonname
            ;;
        startsrc)
            errorcode=0
            if [ "x$command" = "xrestart" ]; then
                stopsrc -s $daemonname
                startsrc -s $daemonname
                errorcode=$?
            fi
            if [ "x$command" = "xdisable" ]; then
                awessomeprint "WRAPPER INFO: No disable for AIX 7"
            fi
            if [ "x$command" = "xenable" ]; then
                awessomeprint "WRAPPER INFO: No enable for AIX 7"
            fi
            if [ "x$command" = "stop" ]; then
                stopsrc -s $daemonname
                errorcode=$?
            fi
            if [ "x$command" = "start" ]; then
                startsrc -s $daemonname
                errorcode=$?
            fi
            # some daemons like lwsmd are not in stopsrc or startsrc, so error trap those and
            # retry via initrc
            if [ "x$errorcode" = "x1" ]; then
                $initpath/$daemonname $command
            fi
            ;;
        *)
            if [ "x$command" = "xenable" ]; then
                awesomeprint "WRAPPER INFO: No enable for init V"
            elif [ "x$command" = "xdisable" ]; then
                awesomeprint "WRAPPER INFO: No disable for init V"
            else
                $initpath/$daemonname $command
            fi
            ;;
    esac
}

awesomeprint()
# Since we default to setting the equivalent of "echo -e" this function ensures that printed test is never escaped.
# Without we can/will have problems printing names like DOMAIN\rauch,DOMAIN\newuser,DOMAIN\testgroup because of the \r\n\t escape sequences
# TODO - We should probably get rid of echo entirely and use this as a standard method of printing.
# However, since the previous method relied on "-e" escapes, we need to be careful moving this over
# TODO Eventually move the logging function and differnt error levels into here, similar to LwDeploy.pm.  in like 2031
{
        printf "%s\n" "$1"
}

# Moved get-ostype.sh below due to logging issues

usage()
{
    $ECHO "usage: `basename $0` [options] 'OU' Domain AD-User {AD-Password}"
    $ECHO ""
    $ECHO "  Options to enable/disable modules:"
    $ECHO ""
    $ECHO "    --log                  - Do logging : `get_on_off $DO_LOG` (default is `get_on_off $DEFAULT_DO_LOG`)"
    $ECHO "    --debug                - Debug logging on Join and lwiauthd.conf : `get_on_off $DO_DEBUG` (default is `get_on_off $DEFAULT_DO_DEBUG`)"
    $ECHO "    --preservescripts      - Preserve script and pbis-input-parameters on successful run : `get_on_off $DO_PRESERVE_ON_SUCCESS` (default is `get_on_off $DEFAULT_DO_PRESERVE_ON_SUCCESS`)"
    $ECHO "    --createdeploy         - Create the deploy folder and files and then exit : `get_on_off $DO_EXIT_NO_DEPLOY` (default is `get_on_off $DEFAULT_DO_CREATE_DEPLOY`)"
    $ECHO "    --passwdbackup         - Back up passwd, group, and shadow : `get_on_off $DO_PASSWDBACKUP` (default is `get_on_off $DEFAULT_DO_PASSWDBACKUP`)"
    $ECHO "    --backup               - Back up config files to $BACKUP_DIR : `get_on_off $DO_BACKUP` (default is `get_on_off $DEFAULT_DO_BACKUP`)"
    $ECHO "    --nfs                  - mount NFS mount point : `get_on_off $DO_NFS_MOUNT` (default is `get_on_off $DEFAULT_DO_NFS_MOUNT`) "
    $ECHO "    --custom_pre_install   - run custom code section prior to install : `get_on_off $DO_CUSTOM_PRE_INSTALL` (default is `get_on_off $DEFAULT_DO_CUSTOM_PRE_INSTALL`)"
    $ECHO "    --alt_provider_remove  - remove alternate authentication providers (VAS/Centrify/Winbind): `get_on_off $DO_ALT_PROVIDER_REMOVE` (default is `get_on_off $DEFAULT_DO_ALT_PROVIDER_REMOVE`)"
    $ECHO "    --selinux              - set selinux to permissive : `get_on_off $DO_SELINUX_DISABLE` (default is `get_on_off $DEFAULT_DO_SELINUX_DISABLE`)"
    $ECHO "    --nscd                 - disable passwd and group entries in nscd : `get_on_off $DO_NSCD_DISABLE` (default is `get_on_off $DEFAULT_DO_NSCD_DISABLE`)"
    $ECHO "    --leave_first          - leave domain (before upgrade from a previous version) : `get_on_off $DO_LEAVE` (default is `get_on_off $DEFAULT_DO_LEAVE`)"
    $ECHO "    --uninstall            - uninstall currently installed version : `get_on_off $DO_UNINSTALL` (default is `get_on_off $DEFAULT_DO_UNINSTALL`)"
    $ECHO "    --remove_nis           - Remove 'nis' and 'compat' lines from nsswitch : `get_on_off $DO_REMOVE_NIS` (default is `get_on_off $DEFAULT_DO_REMOVE_NIS`)"
    $ECHO "    --disable_ypbind       - Disable 'ypbind' service after removing 'nis' settings per previous line. Requires --remove-nis : `get_on_off $DO_DISABLE_YPBIND` (default is `get_on_off $DEFAULT_DO_DISABLE_YPBIND`)"
    $ECHO "    --remove_nss           - Remove '$NSS_MODULES_TO_REMOVE' lines from NSS: `get_on_off $DO_REMOVE_NSS` (default is `get_on_off $DEFAULT_DO_REMOVE_NSS`)"
    $ECHO "    --remove_pam           - Remove '$PAM_MODULES_TO_REMOVE' lines from PAM: `get_on_off $DO_REMOVE_PAM` (default is `get_on_off $DEFAULT_DO_REMOVE_PAM`)"
    $ECHO "    --add_user             - create local backup admin user and group : `get_on_off $DO_ADMIN_USER` (default is `get_on_off $DEFAULT_DO_ADMIN_USER`)"
    $ECHO "    --repo                 - Install binaries from repo : `get_on_off $DO_REPO_INSTALL` (default is `get_on_off $DEFAULT_DO_REPO_INSTALL`) "
    $ECHO "    --install              - Install binaries : `get_on_off $DO_INSTALL` (default is `get_on_off $DEFAULT_DO_INSTALL`) "
    $ECHO "    --allow_sparse         - Allow install on sparse root zones : `get_on_off $DO_ALLOW_SPARSE_INSTALL` (default is `get_on_off $DEFAULT_DO_ALLOW_SPARSE_INSTALL`) "
    $ECHO "    --audit                - turn on auditing settings : `get_on_off $DO_AUDITING` (default is `get_on_off $DEFAULT_DO_AUDITING`)"
    $ECHO "    --local_provider       - turn on local provider : `get_on_off $DO_ENABLE_LOCAL_PROVIDER` (default is `get_on_off $DEFAULT_DO_ENABLE_LOCAL_PROVIDER`)"
    $ECHO "    --assumedefaultdomain  - enables auto prepend of domain to login : `get_on_off $DO_ASSUME_DEFAULT_DOMAIN` (default is `get_on_off $DEFAULT_DO_ASSUME_DEFAULT_DOMAIN`)"
    $ECHO "    --custom_pre_join      - run custom code section prior to join : `get_on_off $DO_CUSTOM_PRE_JOIN` (default is `get_on_off $DEFAULT_DO_CUSTOM_PRE_JOIN`)"
    $ECHO "    --skel_change          - remove lines from /etc/skel/.bash_profile : `get_on_off $DO_SKEL_CHANGE` (default is `get_on_off $DEFAULT_DO_SKEL_CHANGE`)"
    $ECHO "    --require_membership   - add 'require_membership_of' requirement : `get_on_off $DO_REQUIRE_MEMBERSHIP_OF` (default is `get_on_off $DEFAULT_DO_REQUIRE_MEMBERSHIP_OF`)"
    $ECHO "    --cache                - edit default cache times : `get_on_off $DO_EDIT_CACHE` (default is `get_on_off $DEFAULT_DO_EDIT_CACHE`)"
    $ECHO "    --netgroup             - make lsass netgroup aware : `get_on_off $DO_EDIT_NSSWITCH_NETGROUP` (default is `get_on_off $DEFAULT_DO_EDIT_NSSWITCH_NETGROUP`)"
    $ECHO "    --lsa_auth_test        - attempt lsa authenticate-user to localhost as $TESTUSER with bad password : `get_on_off $DO_LSA_AUTH_TEST` (default is `get_on_off $DEFAULT_DO_LSA_AUTH_TEST`)"
    $ECHO "    --sshtest              - attempt ssh to localhost as $TESTUSER with bad password : `get_on_off $DO_SSH_TEST` (default is `get_on_off $DEFAULT_DO_SSH_TEST`, requires autopasswd)"
    $ECHO "    --home_process         - process and change files in home directories : `get_on_off $DO_HOME_DIR_PROCESS` (default is `get_on_off $DEFAULT_DO_HOME_DIR_PROCESS`)"
    $ECHO "    --userdel              - delete local versions of AD users : `get_on_off $DO_USERDEL` (default is `get_on_off $DEFAULT_DO_USERDEL`)"
    $ECHO "    --userdelfile          - delete local versions of user from file : `get_on_off $DO_USERDEL_FILE` (default is `get_on_off $DEFAULT_DO_USERDEL_FILE`)"
    $ECHO "    --group_cleanup        - cleans up local groups during migrate : `get_on_off $DO_GROUP_CLEANUP` (default is `get_on_off $DEFAULT_DO_GROUP_CLEANUP`)"
    $ECHO "    --remove_private       - removes private groups fro migrated users : `get_on_off $DO_REMOVE_PRIVATE_GROUPS` (default is `get_on_off $DEFAULT_DO_REMOVE_PRIVATE_GROUPS`)"
    $ECHO "    --update_dns           - update DNS entry : `get_on_off $DO_UPDATE_DNS` (default is `get_on_off $DEFAULT_DO_UPDATE_DNS`)"
    $ECHO "    --custom_post_join     - run custom code section post-join : `get_on_off $DO_CUSTOM_POST_JOIN` (default is `get_on_off $DEFAULT_DO_CUSTOM_POST_JOIN`)"
    $ECHO "    --purge_account_data   - purges account data from prior runs (use with caution): `get_on_off $DO_PURGE_ACCOUNT_DATA` (default is `get_on_off $DEFAULT_DO_PURGE_ACCOUNT_DATA`)"
    $ECHO "    --skip_uid_conflicts   - populate skip file with local uid conflicts: `get_on_off $DO_SKIP_LOCAL_UID_CONFLICTS` (default is `get_on_off $DEFAULT_DO_SKIP_LOCAL_UID_CONFLICTS`)"
    $ECHO "    --chown                - run the actual chown-all-files script: `get_on_off $DO_CHOWN` (default is `get_on_off $DEFAULT_DO_CHOWN`)"
    $ECHO "    --remove_repo          - remove the $PBIS_REPO_FILE after completion: `get_on_off $DO_REMOVE_REPO` (default is `get_on_off $DEFAULT_DO_REMOVE_REPO`)"
    $ECHO ""
    $ECHO "    To disable a check, prefix option with 'no_' (eg. --no_home_process)"
    $ECHO ""
    $ECHO "  Other options:"
    $ECHO ""
    $ECHO "    --no_log   - Do not create a log file (default is to"
    $ECHO "                 log to $OUTFILE_DIR)"
    $ECHO ""
    $ECHO "  Script Version: $script_version"
}

#
# Determine and set options passed from commandline
#
# WARNING!
# If you change the passthrough settings for --log and --no_log
# you'll create an infinite loop and overload memory on the host
#

PASS_OPTIONS=
while $TRUE; do
    case "$1" in
        --help)
            usage
            exit_with_error `ERR_OPTIONS`
            ;;
        -h)
            usage
            exit_with_error `ERR_OPTIONS`
            ;;
        -?)
            usage
            exit_with_error `ERR_OPTIONS`
            ;;
        --log)
            DO_LOG=1
            # Do not pass through
            ;;
        --no_log)
            DO_LOG=
            # Do not pass through
            ;;
        --debug)
            DO_DEBUG=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_debug)
            DO_DEBUG=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --preservescripts)
            DO_PRESERVE_ON_SUCCESS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_preservescripts)
            DO_PRESERVE_ON_SUCCESS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --createdeploy)
            DO_CREATE_DEPLOY=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_createdeploy)
            DO_CREATE_DEPLOY=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --passwdbackup)
            DO_PASSWDBACKUP=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_passwdbackup)
            DO_PASSWDBACKUP=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --backup)
            DO_BACKUP=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_backup)
            DO_BACKUP=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --nfs)
            DO_NFS_MOUNT=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_nfs)
            DO_NFS_MOUNT=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --custom_pre_install)
            DO_CUSTOM_PRE_INSTALL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_custom_pre_install)
            DO_CUSTOM_PRE_INSTALL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --alt_provider_remove)
            DO_ALT_PROVIDER_REMOVE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_alt_provider_remove)
            DO_ALT_PROVIDER_REMOVE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --selinux)
            DO_SELINUX_DISABLE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_selinux)
            DO_SELINUX_DISABLE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --nscd)
            DO_NSCD_DISABLE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_nscd)
            DO_NSCD_DISABLE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --leave_first)
            DO_LEAVE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_leave_first)
            DO_LEAVE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --uninstall)
            DO_UNINSTALL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_uninstall)
            DO_UNINSTALL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --remove_nis)
            DO_REMOVE_NIS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_remove_nis)
            DO_REMOVE_NIS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --disable_ypbind)
            DO_DISABLE_YPBIND=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_disable_ypbind)
            DO_DISABLE_YPBIND=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --remove_pam)
            DO_REMOVE_PAM=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_remove_pam)
            DO_REMOVE_PAM=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --remove_nss)
            DO_REMOVE_NSS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_remove_nss)
            DO_REMOVE_nss=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --add_user)
            DO_ADMIN_USER=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_add_user)
            DO_ADMIN_USER=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --install)
            DO_INSTALL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_install)
            DO_INSTALL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --repo)
            DO_REPO_INSTALL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_repo)
            DO_REPO_INSTALL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --allow_sparse)
            DO_ALLOW_SPARSE_INSTALL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_allow_sparse)
            DO_ALLOW_SPARSE_INSTALL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --audit)
            DO_AUDITING=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_audit)
            DO_AUDITING=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --local_provider)
            DO_ENABLE_LOCAL_PROVIDER=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_local_provider)
            DO_ENABLE_LOCAL_PROVIDER=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --assumedefaultdomain)
            DO_ASSUME_DEFAULT_DOMAIN=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_assumedefaultdomain)
            DO_ASSUME_DEFAULT_DOMAIN=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --custom_pre_join)
            DO_CUSTOM_PRE_JOIN=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_custom_pre_join)
            DO_CUSTOM_PRE_JOIN=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --skel_change)
            DO_SKEL_CHANGE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_skel_change)
            DO_SKEL_CHANGE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --require_membership)
            DO_REQUIRE_MEMBERSHIP_OF=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_require_membership)
            DO_REQUIRE_MEMBERSHIP_OF=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --cache)
            DO_EDIT_CACHE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_cache)
            DO_EDIT_CACHE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --netgroup)
            DO_EDIT_NSSWITCH_NETGROUP=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no-netgroup)
            DO_EDIT_NSSWITCH_NETGROUP=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --lsa_auth_test)
            DO_LSA_AUTH_TEST=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_lsa_auth_test)
            DO_LSA_AUTH_TEST=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --sshtest)
            DO_SSH_TEST=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_sshtest)
            DO_SSH_TEST=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --home_process)
            DO_HOME_DIR_PROCESS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_home_process)
            DO_HOME_DIR_PROCESS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --userdel)
            DO_USERDEL=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_userdel)
            DO_USERDEL=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --userdelfile)
            DO_USERDEL_FILE=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_userdelfile)
            DO_USERDEL_FILE=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --group_cleanup)
            DO_GROUP_CLEANUP=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_group_cleanup)
            DO_GROUP_CLEANUP=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --remove_private)
            DO_REMOVE_PRIVATE_GROUPS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_remove_private)
            DO_REMOVE_PRIVATE_GROUPS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --update_dns)
            DO_UPDATE_DNS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_update_dns)
            DO_UPDATE_DNS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --custom_post_join)
            DO_CUSTOM_POST_JOIN=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_custom_post_join)
            DO_CUSTOM_POST_JOIN=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --purge_account_data)
            DO_PURGE_ACCOUNT_DATA=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_purge_account_data)
            DO_PURGE_ACCOUNT_DATA=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
	--skip_uid_conflicts)
            DO_SKIP_LOCAL_UID_CONFLICTS=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_skip_uid_conflicts)
            DO_SKIP_LOCAL_UID_CONFLICTS=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
	--chown)
            DO_CHOWN=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_chown)
            DO_CHOWN=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --remove_repo)
            DO_REMOVE_REPO=1
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --no_remove_repo)
            DO_REMOVE_REPO=
            PASS_OPTIONS="$PASS_OPTIONS $1"
            ;;
        --*)
            $ECHO "Unsupported option: $1"
            exit_with_error `ERR_OPTIONS`
            ;;
        *)
            break
            ;;
    esac
    shift 1
done

# Check that all required commands have been passed and error out
# appropriately if not.
#
# 2012-06-04 gmangiantini - add ability to accept options from file instead of command line
# This is placed here to allow still passing options on the command line in addition to
# stuff in the parameters file.

if [ -f `dirname $0`/pbis-input-parameters ]; then
    . `dirname $0`/pbis-input-parameters
fi
if [ -f /root/pbis-input-parameters ]; then
    . /root/pbis-input-parameters
fi
if [ -z "$JOIN_OU" ]; then
    JOIN_OU="$1"
    if [ -z "$JOIN_OU" ]; then
        $ECHO "WRAPPER ERROR: No OU passed to join!"
        usage
        exit_with_error `ERR_OPTIONS`
    fi
    shift 1
fi
if [ -z "$JOIN_DOMAIN" ]; then
    JOIN_DOMAIN="$1"
    if [ -z "$JOIN_DOMAIN" ]; then
        $ECHO "WRAPPER ERROR: No Domain passed to join!"
        usage
        exit_with_error `ERR_OPTIONS`
    fi
    shift 1
fi
if [ -z "$JOIN_USER" ]; then
    JOIN_USER="$1"
    if [ -z "$JOIN_USER" ]; then
        $ECHO "WRAPPER ERROR: No join user passed to join!"
        usage
        exit_with_error `ERR_OPTIONS`
    fi
    shift 1
fi
if [ -z "$JOIN_PASS" ]; then
    JOIN_PASS="$1"
    if [ -n "$JOIN_PASS" ]; then
        # required on Solaris, if you're doing joins without an-command password
        shift 1
    fi
fi # gmangiantini - end of change


if [ -n "$1" ]; then
    $ECHO "WRAPPER ERROR: Too many arguments.  Did not expect '$1'."
    usage
    exit_with_error `ERR_OPTIONS`
fi

if [ -z "$JOIN_OU" ]; then
    $ECHO "WRAPPER ERROR: Too few arguments.  Need an OU to join."
    usage
    exit_with_error `ERR_OPTIONS`
elif [ -z "$JOIN_DOMAIN" ]; then
    $ECHO "WRAPPER ERROR: Too few arguments.  Need a domain to join with."
    usage
    exit_with_error `ERR_OPTIONS`
elif [ -z "$JOIN_USER" ]; then
    $ECHO "WRAPPER ERROR: Too few arguments.  Need a user to join with."
    usage
    exit_with_error `ERR_OPTIONS`
elif [ -z "$JOIN_PASS" ]; then
    if [ -z "$PASSWORD" ]; then
        $ECHO "WRAPPER WARNING: Too few arguments.  Need a password to join and PASSWORD is not set"
        $ECHO "WRAPPER WARNING: You will be prompted for your password at join time."
        #	    usage
        #        exit 1
    fi
fi

mkdir -p $OUTFILE_DIR
OUTFILE_PATH=$OUTFILE_DIR/$OUTFILE_NAME

if [ -n "$DO_LOG" ]; then
    rm -f $OUTFILE_PATH
    case "$-" in
        *x*)
            $ECHO "WRAPPER INFO: -x is set, continuing in forked process"
            sh_opt="-x "
            ;;
        *)
            sh_opt=""
            ;;
    esac

    touch $OUTFILE_PATH
    tail -f $OUTFILE_PATH &
    tailpid=$!

    # add to support gmangiantini 2012-06-04 change for input params file
    if [ -f `dirname $0`/pbis-input-parameters ];
    then
        sh $sh_opt $0 --preservescripts --no_log $PASS_OPTIONS >> $OUTFILE_PATH 2>&1
        error $?
    else
        sh $sh_opt $0 --preservescripts --no_log $PASS_OPTIONS "$JOIN_OU" "$JOIN_DOMAIN" "$JOIN_USER" "$JOIN_PASS" >> $OUTFILE_PATH 2>&1
        error $?
    fi
    # end support for gmangiantini change

    pline
    $ECHO "WRAPPER INFO: The output of this program has been captured in $OUTFILE_PATH"
    sleep 1
    kill $tailpid
    if [ "$?" -ne "0" ]; then
        error `ERR_SYSTEM_CALL`
    fi
    pline
    exit_status $gRetVal
fi

# Calculate the backup directory
# The backup directory is n the form <root>/backup-<date>-<instance>
# e.g. /root/.pbis-backup/backup-081203-1
#
# The instance number is used to distinguish two installs that occurred on the
# same day. The following code searches for an instance number which has not
# been used yet.
i=1
while $TRUE; do
    TEST_PATH="$BACKUP_DIR_ROOT/backup-$TODAY-$i"
    if [ ! -d "$TEST_PATH" ]; then
        BACKUP_DIR=$TEST_PATH
        BACKUP_INSTANCE="$TODAY-$i"
        break
    fi
    i=`add $i 1`
done

if [ -n "$LD_LIBRARY_PATH" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_LIBRARY_PATH is set as $LD_LIBRARY_PATH"
    DO_FIX_LD_LIBRARY_PATH=1
fi
if [ -n "$LD_LIBRARY_PATH_64" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_LIBRARY_PATH_64 is set as $LD_LIBRARY_PATH_64"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$LD_LIBRARY_PATH_32" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_LIBRARY_PATH_32 is set as $LD_LIBRARY_PATH_32"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$LD_PRELOAD" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_PRELOAD is set as $LD_PRELOAD"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$LD_PRELOAD_32" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_PRELOAD_32 is set as $LD_PRELOAD_32"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$LD_PRELOAD_64" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LD_PRELOAD_64 is set as $LD_PRELOAD_64"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$LIBPATH" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: LIBPATH is set as $LIBPATH"
    DO_FIX_LD_LIBRARY_PATH=1
fi

if [ -n "$SHLIB_PATH" ]; then
    pblank
    pline
    pblank
    $ECHO "WRAPPER WARNING: SHLIB_PATH is set as $SHLIB_PATH"
    DO_FIX_LD_LIBRARY_PATH=1
fi
if [ "$DO_FIX_LD_LIBRARY_PATH" = "1" ]; then
    LD_LIBRARY_PATH=""
    export LD_LIBRARY_PATH
    LD_LIBRARY_PATH_32=""
    export LD_LIBRARY_PATH_32
    LD_LIBRARY_PATH_64=""
    export LD_LIBRARY_PATH_64
    LD_PRELOAD=""
    export LD_PRELOAD
    LD_PRELOAD_32=""
    export LD_PRELOAD_32
    LD_PRELOAD_64=""
    export LD_PRELOAD_64
    LIBPATH=""
    export LIBPATH
    SHLIB_PATH=""
    export SHLIB_PATH
    sleep 2
    $ECHO "WRAPPER WARNING: DO_FIX_LD_LIBRARY_PATH will be enabled to clear this up"
fi

# Finally start logging output to screen
psection "MODULE START: OS DETECTION"
# This block included from: ././get-ostype.sh.
# Check system type and set some flags
$ECHO "WRAPPER INFO: Determining OS type..."
OStype=""
kernel=`uname -s`
case "$kernel" in
    Linux)
        if type rpm >/dev/null 2>&1 ; then
            OStype=linux-rpm
        fi
        if type apt-cache >/dev/null 2>&1; then
            OStype=linux-deb
        fi
        ;;
    HP-UX)
        OStype=hpux
        ;;
    SunOS)
        OStype=solaris
        ;;
    AIX)
        OStype=aix
        ;;
    FreeBSD)
        OStype=freebsd
        ;;
    Darwin)
        OStype=darwin
        ;;
    *)
        $ECHO "WRAPPER ERROR: Unknown kernel: $kernel"
        exit_with_error `ERR_OPTIONS`
        ;;
esac
if [ -z "$OStype" ]; then
    $ECHO "WRAPPER ERROR: Unknown OS type (kernel = $kernel )"
    exit_with_error `ERR_OPTIONS`
fi

host=`hostname`
kernel=`uname -s`
unameall=`uname -a`
#
# Set some flags for each type of OS
# So that we can refer back
# This will grow for a long time
#

TRUE="/bin/true"
AWK="awk"
GREP="grep"
SED="sed"
read="read"
#
#Set Echo command for RHEL and CENTOS
#
if [ $OStype = "linux-rpm" ]; then
    ECHO="echo -e"
    if [ -x "/usr/bin/systemctl" ]; then
        # RHEL 7 using systemd, so we need a space at the end of the variable. BEWARE HERE BE DEMONS
        initpath="/usr/bin/systemctl "
        servicetype="systemctl"
    elif [ -x "/sbin/restart" ]; then
        servicetype="upstart"
        initpath="/etc/init.d/"
    elif [ -x "/sbin/service" ]; then
        servicetype="service"
        initpath="/etc/init.d/"
    else
        initpath="/etc/init.d/"
        servicetype="initv"
    fi
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.d"
    platform=`uname -i`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
    PBIS_REPO_FILE="/etc/yum.repos.d/pbis.repo"
elif [ $OStype = "linux-deb" ]; then
    initpath="/etc/init.d/"
    if [ -x "/usr/bin/systemctl" ]; then
        # Debian Wheezy and Ubuntu 16+ using systemd, so we need a space at the end of the variable. BEWARE HERE BE DEMONS
        initpath="/usr/bin/systemctl "
        servicetype="systemctl"
    elif [ -x "/sbin/restart" ]; then
        servicetype="upstart"
        initpath="/etc/init.d/"
    elif [ -x "/sbin/service" ]; then
        servicetype="service"
        initpath="/etc/init.d/"
    else
        initpath="/etc/init.d/"
        servicetype="initv"
    fi
    RCDIR="/etc"
    PAM_PATH="/etc/pam.d"
    platform=`uname -i`
    if [ "$platform" = "unknown" ]; then
        platform=`uname -m`
    fi
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
    PBIS_REPO_FILE="/etc/apt/sources.list.d/pbis.list"
elif [ $OStype = "freebsd" ]; then
    TRUE="/usr/bin/true"
    ECHO="echo -e"
    initpath="/etc/rc.d/"
    servicetype="initv"
    RCDIR=""
    PAM_PATH="/etc/pam.d"
    platform=`uname -m`
    if [ "$platform" = "amd64" ]; then
        platform="x86_64"
    fi
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
elif [ $OStype = "solaris" ]; then
    AWK="nawk"
    if [ -x /usr/bin/read ]; then
        read="/usr/bin/read"
    fi
    if [ -x /usr/xpg4/bin/awk ]; then
        AWK=/usr/xpg4/bin/awk
    fi
    if [ -x /usr/xpg4/bin/grep ]; then
        GREP=/usr/xpg4/bin/grep
    fi
    if [ -x /usr/xpg4/bin/sed ]; then
        SED=/usr/xpg4/bin/sed
    fi
    initpath="/etc/init.d/"
    if [ -x /usr/sbin/svcadm ]; then
        servicetype="svcadm"
    else
        servicetype="initv"
    fi
    RCDIR="/etc/init.d"
    PAM_PATH="/etc/pam.conf"
    platform=`uname -p`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/adm"
    #If Solaris 10, identify if it is a sparse root zone.
    #This has a bearing on upgrades and installs.  sdendin
    if [ -x /usr/sbin/zoneadm ]; then
        if [ `pkgcond is_sparse_root_nonglobal_zone;echo $?` -eq 0 ]; then
            ZONEtype="sparse"
            ZONEOPTS=""
        elif [ `pkgcond is_whole_root_nonglobal_zone;echo $?` -eq 0 ]; then
            ZONEtype="whole"
            ZONEOPTS="-- --current-zone"
        elif [ `pkgcond is_global_zone;echo $?` -eq 0 ]; then
            # We only do "--current-zone" install on child zones currently
            # because the wrapper can't clean up $LD_LIBRARY_PATH
            # properly in child zones yet
            #TODO make wrapper clear LD_LIBRRAY_PATH in child zones if requested
            ZONEtype="global"
            ZONEOPTS="-- --current-zone"
        fi
    else
        ZONEtype=""
        ZONEOPTS=""
    fi
elif [ $OStype = "aix" ]; then
    initpath="/etc/rc.d/init.d/"
    servicetype="startsrc"
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.conf"
    platform=`uname -p`
    df_cmd="df -k"
    nsfile="netsvc.conf"
    LOGPATH="/var/adm"
elif [ $OStype = "hpux" ]; then
    initpath="/sbin/init.d/"
    servicetype="initv"
    RCDIR="/etc/rc.d"
    PAM_PATH="/etc/pam.d"
    platform=`getconf _SC_CPU_VERSION`
    # From /usr/include/unistd.h
    case "$platform" in
        524)
            platform=mc68020
            ;;
        525)
            platform=mc68030
            ;;
        525)
            platform=mc68040
            ;;
        523)
            platform=hppa10
            ;;
        528)
            platform=hppa11
            ;;
        529)
            platform=hppa12
            ;;
        532)
            platform=hppa20
            ;;
        768)
            platform=ia64
            ;;
    esac
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/adm"
elif [ $OStype = "darwin" ]; then
    TRUE="/usr/bin/true"
    PAM_PATH="/etc/pam.d"
    initpath="/etc/init.d/"
    servicetype="launchctl"
    RCDIR="/etc/rc.d"
    platform=`uname -m`
    df_cmd="df -kl"
    nsfile="nsswitch.conf"
    LOGPATH="/var/log"
fi
if [ "$NAWK_GOOD_ENOUGH" = "0" ] && [ "$AWK" = "nawk" ]; then
    $ECHO "WRAPPER ERROR: nawk isn't good enough for this script, install a better awk."
    exit_with_error `ERR_OS_INFO`
fi

# Used in several later functions, since AIX uses /etc/krb5/krb5.conf instead
krb5path=/etc/krb5.conf
if [ -L $krb5path ]; then
    krb5path=`file /etc/krb5.conf | $AWK -F: '{ print $1 }'`
fi

#
# Set different path to Likewise tools bin folder
# for Linux it's /usr and others are /opt
#

if [ -z "$LW_VERSION" ]; then
    if [ -f /opt/pbis/data/VERSION ]; then
        LW_VERSION=`$AWK -F= '/VERSION/ { print $2 }' /opt/pbis/data/VERSION |$AWK -F. ' {print $1 "." $2 }'`
    else
        LW_VERSION=`$AWK -F= '/VERSION/ { print $2 }' /opt/likewise/data/VERSION |$AWK -F. ' {print $1 "." $2 }'`
    fi
fi
if [ -z "$LW_VERSION" ]; then
    $ECHO "WRAPPER ERROR: Still have no LW_VERSION variable set, this needs to be hard-coded, or PBIS needs to be installed!"
    exit_with_error `ERR_OPTIONS`
fi
VERSTEST=`float_cond "if ( $LW_VERSION > 6.2 ) 1"`
if [ $LW_VERSION = "4.1" ]; then
    if [ $OStype = "linux-rpm" ]; then
        LWPath="/usr/centeris/bin"
    elif [ $OStype = "linux-deb" ]; then
        LWPath="/usr/centeris/bin"
    else
        LWPath="/opt/centeris/bin"
    fi
elif [ $VERSTEST -eq 1 ] ; then
    LWPath="/opt/pbis/bin"
elif [ `float_cond "if ( $LW_VERSION > 4.1 ) 1"` -eq 1 ] ; then
    LWPath="/opt/likewise/bin"
else
    $ECHO "WRAPPER ERROR: Unknown version $LW_VERSION!"
    exit_with_error `ERR_OPTIONS`
fi
if  [ $VERSTEST -ne 1 ] ; then
    FINDUSERBYNAME=$LWPath/lw-find-user-by-name
    FINDGROUPBYNAME=$LWPath/lw-find-group-by-name
    FINDUSERBYID=$LWPath/lw-find-user-by-id
    FINDGROUPBYID=$LWPath/lw-find-group-by-id
    FINDOBJECTS=$LWPath/lw-find-objects
    ENUMSERS=$LWPath/lw-enum-users
    ENUMGROUPS=$LWPath/lw-enum-groups
    GETSTATUS=$LWPath/lw-get-status
    LWSM=$LWPath/lwsm
    CONFIG=$LWPath/lwconfig
    REGSHELL=$LWPath/lwregshell
    INITBASE=$LWPath/init-base.sh
    GETLOGLEVEL=$LWPath/lw-get-log-level
    SETLOGLEVEL=$LWPath/lw-set-log-level
    GETDCNAME=$LWPath/lw-get-dc-name
    GETCURRENTDOMAIN=$LWPath/lw-get-current-domain
    EVENTLOGCLI=$LWPath/lw-eventlog-cli
    ADDGROUP=$LWPath/lw-add-group
    MODGROUP=$LWPath/lw-mod-group
    UPDATEDNS=$LWPath/lw-update-dns
else
    FINDUSERBYNAME=$LWPath/find-user-by-name
    FINDGROUPBYNAME=$LWPath/find-group-by-name
    FINDUSERBYID=$LWPath/find-user-by-id
    FINDGROUPBYID=$LWPath/find-group-by-id
    FINDOBJECTS=$LWPath/find-objects
    ENUMSERS=$LWPath/enum-users
    ENUMGROUPS=$LWPath/enum-groups
    GETSTATUS=$LWPath/get-status
    LWSM=$LWPath/lwsm
    CONFIG=$LWPath/config
    REGSHELL=$LWPath/regshell
    INITBASE=$LWPath/../libexec/init-base.sh
    GETLOGLEVEL="$LWPath/lwsm get-log"
    SETLOGLEVEL="$LWPath/lwsm set-log-level"
    GETDCNAME=$LWPath/get-dc-name
    GETCURRENTDOMAIN="$LWPath/lsa ad-get-machine account"
    EVENTLOGCLI=$LWPath/eventlog-cli
    ADDGROUP=$LWPath/add-group
    MODGROUP=$LWPath/mod-group
    ADTOOL=$LWPath/adtool
    AUTHUSER="$LWPath/lsa authenticate-user"
    UPDATEDNS=$LWPath/update-dns
fi

$ECHO "WRAPPER INFO: Hostname: $host"
$ECHO "WRAPPER INFO: Uname All: $unameall"
$ECHO "WRAPPER INFO: OS: $OStype"
$ECHO "WRAPPER INFO: Platform: $platform"
$ECHO "WRAPPER INFO: Kernel: $kernel"
$ECHO "WRAPPER INFO: Likewise/PBIS: $LW_VERSION"
#produc-functions needs path definitions found in get-ostype
# This block included from: ././product-functions.sh.
# product-functions.sh
# contains functions to be called throughout various modules
# Editor Settings: expandtabs and use 4 spaces for indentation
# ex: set softtabstop=4 tabstop=8 expandtab shiftwidth=4:

set_log_level(){
    VERSTEST=`float_cond "if ($LW_VERSION > 6.0 ) 1"`
    if [ $VERSTEST -eq 1 ]; then
        $ECHO "WRAPPER INFO: Changing log level to debug for current instance of services."
        $CONFIG PamLogLevel $1
        $LWSM set-log-level lsass - $1
        $LWSM set-log-level lwio - $1
        $LWSM set-log-level netlogon - $1
    else
        $ECHO "WRAPPER WARNING: Can't change log level for detected PBIS version"
    fi
}

check_lwsm_status(){
    status=1
    while [ $status -ne 0 ]; do
        $ECHO "WRAPPER INFO: Waiting for PBIS service manager (lwsm)..."
        $LWSM list > /dev/null 2>&1
        status=$?
        if [ ! -x $LWSM ]; then
            #this check avoids an infinite loop if the software is removed between install and this check
            $ECHO "WRAPPER ERROR: $LWSM is not executable, something is horribly wrong!"
            $ECHO "WRAPPER ERROR: Exiting immediately."
            exit_with_error `ERR_ACCESS`
            status=0
        fi
        sleep 5
    done
}

check_domainjoin_status(){
    domainjoin_query_domain=`$LWPath/domainjoin-cli query | $GREP "Domain =" | $AWK '{print $3}'`
    if [ "x$domainjoin_query_domain" != "x" ]; then
        $ECHO "WRAPPER INFO: System joined to domain: $domainjoin_query_domain..  Checking LSASS status..."
        check_lsass_provider_status "lsa-activedirectory-provider" "reset"
        return 0	
    else
        $ECHO "WRAPPER WARNING: System is not joined to any domain."
        return 1
    fi
}

restart_lsass(){
    $ECHO "WRAPPER INFO: Restarting LSASS..."
    $LWSM restart lsass
    check_lwsm_status
    if [ -n "$DO_DEBUG" ]; then
        set_log_level debug
    fi
}
 
restart_lwsmd(){
    $ECHO "WRAPPER INFO: Restarting PBIS (lwsmd)..."
    servicehandler "restart" "lwsmd"
    if [ "$?" -ne "0" ]; then
        $ECHO "WRAPPER ERROR - lwsmd doesn't exist, install probably failed!"
        exit_with_error `ERR_SYSTEM_CALL`
    fi

    check_lwsm_status

    check_domainjoin_status

    if [ -n "$DO_DEBUG" ]; then
        set_log_level debug
    fi
}

ad_provider_online=0
local_provider_online=0
check_lsass_provider_status(){
    if [ "x$1" = "xlsa-activedirectory-provider" ]; then
        provider_online=$ad_provider_online
        provider_text="Active Directory Provider"
    elif [ "x$1" = "xlsa-local-provider" ]; then
        provider_online=$local_provider_online
        provider_text="Local LSASS Provider"
    else
        $ECHO "WRAPPER DEBUG: check_lsass_provider_status called with invalid argument"
        return 1
    fi

    $ECHO "WRAPPER INFO: Waiting for $provider_text to come online..."

    stop_watch=0

    while [ $stop_watch -lt $JOIN_SLEEP ] && [ "x$provider_online" != "x1" ]; do
        $GETSTATUS 2>/dev/null | $SED -n -e "/$1/,/Status:/ p" | $GREP -q "Online"
        if [ $? -ne 0 ]; then
            stop_watch=`expr $stop_watch + 1`
            sleep 1
        else
            if [ $1 = "lsa-activedirectory-provider" ]; then
                ad_provider_online=1
                provider_online=1
            elif [ $1 = "lsa-local-provider" ]; then
                local_provider_online=1
                provider_online=1
            fi
        fi
    done

    if [ $provider_online -eq 1 ]; then
        $ECHO "WRAPPER INFO: $provider_text Online."
    else
        $ECHO "WRAPPER ERROR: $provider_text not able to come online."
        exit_with_error `ERR_ACCESS`
        return 1
    fi

    if [ "x$2" = "xreset" ]; then
        if [ "x$1" = "xlsa-activedirectory-provider" ]; then
            ad_provider_online=0
        elif [ "x$1" = "xlsa-local-provider" ]; then
            local_provider_online=0
        fi
    fi
}

all_domains_online=0
check_offline_domains(){
    $ECHO "WRAPPER INFO: Checking for any offline domains..."

    stop_watch=0

    while [ $stop_watch -lt $JOIN_SLEEP ] && [ "x$all_domains_online" != "x1" ]; do
        $GETSTATUS 2>/dev/null | $GREP -q "\- Offline"
        if [ $? -ne 0 ]; then
            stop_watch=`expr $stop_watch + 5`
            sleep 5
        else
            all_domains_online=1
        fi
    done

    if [ $all_domains_online -eq 1 ]; then
        $ECHO "WRAPPER INFO: All domains online."
    else
        $ECHO "WRAPPER ERROR: One or more offline domains detected."
        exit_with_error `ERR_ACCESS`
        return 1
    fi
}

enable_local_provider(){
    if [ $local_provider_online -eq 1 ]; then
        return 0
    fi

    $REGSHELL list_values [HKEY_THIS_MACHINE\\Services\\lsass\\Parameters\\Providers] | $GREP -q "REG_MULTI_SZ\[1\] \"Local\""
    if [ $? -ne 0 ]; then
        $ECHO "WRAPPER INFO: Enabling the PBIS Local LSASS Provider."
        $REGSHELL  set_value [HKEY_THIS_MACHINE\\Services\\lsass\\Parameters\\Providers] "LoadOrder" "ActiveDirectory" "Local"
    fi

    $GETSTATUS | $GREP -q "lsa-local-provider"
    if [ $? -ne 0 ]; then
        $ECHO "WRAPPER INFO: Restarting LSASS to initialize the PBIS Local LSASS Provider."
        $LWSM restart lsass
    fi

    check_lsass_provider_status "lsa-local-provider"
}

# Custom code required to fix up system prior to install 
if [ -n "$DO_CUSTOM_PRE_INSTALL" ]; then
    psection "MODULE START: CUSTOM PRE-INSTALL"
# This block included from: ././custom-pre-install.sh.

    # START CUSTOM PRE INSTALL COMMANDS HERE
    if [ "$OStype" = "aix" ]; then
        chsec -f /etc/security/user -s default -a "loginretries=5"
        if [ "$?" -ne 0 ]; then
            $ECHO "WARNING: Could not change logon retries to 5"
        fi  
    fi 
    # END CUSTOM PRE INSTALL COMMANDS 
fi

# Customer "drop-in" files.  Code to run prior to install.
if [ -n "$DO_RUN_CUSTOMER_SCRIPTS" ]; then
    psection "MODULE START: CUSTOMER PRE-INSTALL SCRIPTS"
    # $customer_pre_install_script did not exist on build host, expecting customer to provide it.
    if [ -f $customer_pre_install_script ]; then
        . $customer_pre_install_script
    else
        $ECHO "WRAPPER WARNING: $customer_pre_install_script wasn't found, and it was supposed to be included!"
    fi
fi

# Pre-install check
psection "MODULE START: PRE INSTALL CHECK"
# This block included from: ././pre-install-check.sh.

$ECHO "WRAPPER INFO: Checking OS Configuration ($OStype)..."
case $OStype in
    aix)
        $ECHO "WRAPPER INFO: OS PASS"
        ;;
    hp-ux)
        $ECHO "WRAPPER INFO: OS PASS"
        ;;
    linux-rpm)
        $ECHO "WRAPPER INFO: OS PASS"
        ;;
    linux-deb)
        $ECHO "WRAPPER INFO: OS PASS"
        ;;
    solaris)
        if [ "$ZONEtype" = "sparse" ]; then
            # check that at least there are files available for the join to work
            if [ ! -f /usr/lib/nss_lsass.so.1 ]; then
                if [ ! -f /usr/lib/nss_lsass.so ]; then
                    $ECHO "WRAPPER ERROR: Sparse Root Zone installs require several files in /usr/lib!"
                    $ECHO "WRAPPER ERROR: Please follow the sparse root child zone install guide."
                    exit_with_error `ERR_OS_INFO`
                fi
            fi
            if [ ! "$DO_ALLOW_SPARSE_INSTALL" = "1" ]; then
                if [ "$DO_INSTALL" = "1" ]; then
                    $ECHO "WRAPPER ERROR: Not allowed to install on sparse Root Child Zones!!!"
                    exit_with_error `ERR_OS_INFO`
                fi
            fi
        fi
        ;;
    *)
        $ECHO "WRAPPER INFO: OS PASS"
        ;;
esac

# Check Keytab lock
if [ -f /etc/krb5.keytab ] ; then
    $ECHO "WRAPPER INFO: Checking if any processes have the krb5.keytab file open (e.g. apache)."

    if [ -x "`which fuser 2>/dev/null`" ]; then
        KRB5_LOCK=`fuser /etc/krb5.keytab 2>/dev/null | $AWK '{print $1}'`
        if [ "z$KRB5_LOCK" = "z" ]; then
                KRB5_LOCK=0
        fi
    elif [ -x "`which lsof 2>null`" ]; then
        KRB5_LOCK=`lsof /etc/krb5.keytab`
    else
        $ECHO "WRAPPER WARNING: no lsof/fuser binary found on system, unable to check keytab lock!"
        $ECHO "WRAPPER WARNING: if anything has the keytab locked, the join will hang!"
        sleep 10
    fi
    if [ "$KRB5_LOCK" != "0" ]; then
        $ECHO "WRAPPER ERROR: A process is currently using /etc/krb5.keytab. You must kill the offending process and then re-run this script."
        $ECHO "WRAPPER ERROR: Installation and Join FAILED"
        pblank
        exit_with_error `ERR_FILE_ACCESS`
    else
        $ECHO "WRAPPER INFO: Keytab PASS"
    fi
else
    $ECHO "WRAPPER INFO: SKIPPED (/etc/krb5.keytab not found)"
fi

# Do an initial check that we can resolve the domain
$ECHO "WRAPPER INFO: Checking SRV records for $JOIN_DOMAIN..."
dig=`command -v dig`
if [ $? -eq 0 ]; then
    dig_answers=`$dig SRV "_ldap._tcp.dc._msdcs.$JOIN_DOMAIN" | grep -i "ANSWER SECTION"`
    if [ $? -eq 0 ]; then
        $ECHO "WRAPPER INFO: Detected SRV records for $JOIN_DOMAIN."
    else
        $ECHO "WRAPPER ERROR: Unable to detect SRV records for $JOIN_DOMAIN."
        exit_with_error `ERR_NETWORK`
    fi
else
    $ECHO "WRAPPER WARNING: dig not found.  Unable to pre-validate SRV records for $JOIN_DOMAIN."
fi

$ECHO "WRAPPER INFO: Checking/Setting permissions on /etc/$nsfile"
chmod 644 /etc/$nsfile

if [ -x "$FINDUSERBYNAME" ]; then
    $ECHO "WRAPPER INFO: Likewise/PBIS installed."
    restart_lwsmd
    pbis_installed=1
else
    if [ "x$DO_INSTALL" = "x" -a "x$DO_REPO_INSTALL" = "x" ]; then
        $ECHO "WRAPPER ERROR: PBIS not found and DO_INSTALL/DO_REPO_INSTALL is disabled. Can't proceed."
        exit_with_error `ERR_OS_INFO`
    fi
    pbis_installed=0
fi

exit_if_error

# Mount any NFS paths required prior to install
# checks for existance of NFS mount target
# and creates it if required.

if [ -n "$DO_NFS_MOUNT" ]; then
    psection "MODULE START: NFS MOUNT"
# This block included from: ././nfsmount.sh.
if [ -x /sbin/mount.nfs ]; then
    $ECHO "WRAPPER INFO: Check for NFS mounter succeeded, continuing."
else
    if [ "$OStype" = "linux-deb" ]; then
        pblank
        $ECHO "WRAPPER WARNING: nfs-client is not installed, installing it now..."
        apt-get -q -y install nfs-commonan
    elif [ "$OStype" = "linux-rpm" ]; then
        pblank
        $ECHO "WRAPPER WARNING: nfs client is not installed, installing it now..."
        yum -t -y install nfs-utils
    fi
fi

if [ -d $MOUNTPOINT ]; then
    $ECHO "WRAPPER INFO: Check for NFS mount point succeeded, continuing."
else
    $ECHO "WRAPPER WARNING, $MOUNTPOINT did not exist, creating!"
    mkdir -p $MOUNTPOINT
fi

mounterror=0
case $OStype in
    aix)
        nfso -o nfs_use_reserved_ports=1
        mount $NFSPATH $MOUNTPOINT
        mounterror=$?
        ;;
    solaris|hpux)
        mount -F nfs -o rw,async $NFSPATH $MOUNTPOINT
        mounterror=$?
        ;;
    *)
        mount -t nfs -o rw,async $NFSPATH $MOUNTPOINT
        mounterror=$?
        ;;
esac

#TODO - Add checks for mount already existing.  Workaround - use unique mount.  Also, add umount to all exit statuses so we don't need manual umoun
if [ $mounterror -ne 0 ]; then
    $ECHO "WRAPPER ERROR: Mounting $NFSPATH failed with error $?"
    $ECHO "WRAPPER ERROR: Exiting install, please mount as root manually with the following command:"
    $ECHO "mount -t nfs -o rw,async $NFSPATH $MOUNTPOINT"
    $ECHO "Run this script with the '--no_nfs' option after manual mount succeeds."
    exit_with_error `ERR_FILE_ACCESS`
fi
fi


#
# Backup is on by default - back up files we're touching
# to a separate backup directory for easy discovery and review
# at a later date
# or to restore if required
#
if [ -n "$DO_BACKUP" ]; then
    psection "MODULE START: BACKUP"
# This block included from: ././backup.sh.
if [ -n "$DO_BACKUP" ]; then
    $ECHO "WRAPPER INFO: Backing up files to $BACKUP_DIR..."
    # backups for all OSes
    if not mkdir -p $BACKUP_DIR; then
        echo "WRAPPER ERROR: unable to create the backup directory at $BACKUP_DIR. The installation will now terminate"
        exit_with_error `ERR_ACCESS`
    fi
    if [ "$DO_PASSWDBACKUP" = "1" ]; then
        for filename in passwd group shadow master.passwd spwd.db pwd.db rc.conf privgroup ; do
            if [ -f /etc/$filename ]; then
                cp -p  /etc/$filename $BACKUP_DIR/$filename
            fi
        done
        if [ "$OStype" = "aix" ]; then
            cp -P /etc/security/passwd $BACKUP_DIR/sec_passwd
            cp -P /etc/security/group $BACKUP_DIR/sec_group
        fi
    fi
    for filename in krb5.conf krb.conf krb5.keytab nscd.conf nodename hosts hostname ; do
        if [ -f /etc/$filename ]; then
            cp -p  /etc/$filename $BACKUP_DIR/$filename
        fi
    done
    nowdir=`pwd`
    cd /etc
    for filename in host* ; do
        cp -p $filename $BACKUP_DIR/$filename
    done
    cd $nowdir
    if [ -f /etc/$nsfile ]; then
        cp -p /etc/$nsfile $BACKUP_DIR/$nsfile
    fi
    if [ -f /etc/issue ]; then
        cp -p /etc/issue $BACKUP_DIR
    fi
    if [ -f /etc/security/access.conf ]; then
        cp -p /etc/security/access.conf $BACKUP_DIR
    fi
    for filename in ncsd selinux authconfig; do 
        if [ -f /etc/sysconfig/$filename ]; then
            cp -p /etc/sysconfig/$filename $BACKUP_DIR/${filename}_sysconfig
        fi
    done
    for filename in nscd crond; do
        if [ -f /etc/init.d/$filename ]; then
            cp -p /etc/init.d/$filename $BACKUP_DIR/${filename}_init
        fi
    done
    #convoluted backup of sshd_config based on where it is.
    # file name must be "$BACKUP_DIR/sshd_config-path-split-by-dash
    # so that restore can restore to the right location
    if [ -f /etc/ssh/sshd_config ]; then
        cp -p /etc/ssh/sshd_config $BACKUP_DIR/sshd_config-ssh
    fi
    if [ -f /etc/sssd/sssd.conf ]; then
        cp -p /etc/sssd/sssd.conf $BACKUP_DIR/sssd.conf-sssd-etc
    fi
    if [ -f /opt/ssh/etc/sshd_config ]; then
        cp -p /opt/ssh/etc/sshd_config $BACKUP_DIR/sshd_config-opt-ssh-etc
    fi
    if [ -f /usr/local/ssh/sshd_config ]; then
        cp -p /usr/local/ssh/sshd_config $BACKUP_DIR/sshd_config-usr-local-ssh
    fi
    if [ -f /services/ssh/etc/sshd_config ]; then
        cp -p /services/ssh/etc/sshd_config $BACKUP_DIR/sshd_config-services-ssh-etc
    fi
    if [ -f /opt/SUNSFW/ssh/sshd_config ]; then
        cp -p /opt/SUNSFW/ssh/sshd_config $BACKUP_DIR/sshd_config-opt-SUNSFW-ssh
    fi
    if [ -f /usr/share/pam-configs/ldap ]; then
        cp -p /usr/share/pam-configs/ldap $BACKUP_DIR/ldap-pam-configs-share-usr
    fi
    if [ -f /usr/share/pam-configs/kerberos ]; then
        cp -p /usr/share/pam-configs/kerberos $BACKUP_DIR/kerberos-pam-configs-share-usr
    fi
    if [ -f /usr/share/pam-configs/krb5 ]; then
        cp -p /usr/share/pam-configs/krb5 $BACKUP_DIR/krb5-pam-configs-share-usr
    fi
    if [ -f /usr/share/pam-configs/sss ]; then
        cp -p /usr/share/pam-configs/sss $BACKUP_DIR/sss-pam-configs-share-usr
    fi

    # added per customer request 20090727
    if [ -d /etc/profile.d ]; then
        or_abort tar -cf "$BACKUP_DIR"/profile.tar /etc/profile.d/* > /dev/null 2>&1
        gzip "$BACKUP_DIR"/profile.tar
    fi
    if [ -d /etc/opt/quest/vas ]; then
        cp -r -p /etc/opt/quest/vas "$BACKUP_DIR"/
    fi
    if [ -d /etc/centrifydc ]; then
        cp -r -p /etc/centrifydc "$BACKUP_DIR"/
    fi
    PAM_FILE="/etc/pam.conf"
    if [ -f "$PAM_FILE" ]; then
        or_abort tar -cf "$BACKUP_DIR"/pam.tar $PAM_FILE >/dev/null 2>&1
    fi
    if [ -d "$PAM_PATH" ]; then
        or_abort tar -cf "$BACKUP_DIR"/pam.tar "$PAM_PATH" >/dev/null 2>&1
    fi
    if [ -d "/tcb/files/auth" ]; then
        #HPUX Trusted Mode auth files
        or_abort tar -cf "$BACKUP_DIR"/tcb-auth.tar /tcb/files/auth > /dev/null 2>&1
        gzip "$BACKUP_DIR/tcp-auth.tar"
    fi
    # done with backup
    gzip "$BACKUP_DIR/pam.tar"
    usage > $BACKUP_DIR/options-list.txt
    $ECHO "WRAPPER INFO: Backup completed."
fi

fi

#TODO - Right now, template files only get created if no deploy directory exists at all.
# If we care, we should check for all required files and then run create-deploy-files to check/create each one.
if [ ! -d "$DEPLOY_DIR" ]; then
    $ECHO "WRAPPER ERROR: Can't find the $DEPLOY_DIR directory - are you running this with correct paths?"
    if [ -n "$DO_CREATE_DEPLOY" ]; then
# This block included from: ././create-deploy-files.sh.


if [ ! -d deploy ]; then
        $ECHO "WRAPPER WARNING: Creating deploy subdirectory"
        mkdir deploy
	deploy_created=1
fi

if [ ! -f $DEL_USER_LIST ]; then
	$ECHO "WRAPPER WARNING: Creating $DEL_USER_LIST"
	touch $DEL_USER_LIST
	cat > $DEL_USER_LIST <<-EOF
	# This file is used to delete any user from 
	# the local /etc/passwd database.
	# Each user specified in this file will be deleted.
	# This file is generally utilized to delete one-off users 
	# who should no longer exist on local systems.
	# Specify one user per line.
	# e.g.:
	# jsmith
EOF
	deploy_created=1
fi

if [ ! -f $SKIP_USER_LIST ]; then
        $ECHO "WRAPPER WARNING: Creating $SKIP_USER_LIST"
        touch $SKIP_USER_LIST
	cat > $SKIP_USER_LIST <<-EOF
	# This file is used to skip users whose account exist in both
	# the local /etc/passwd database and in PBIS.
	# Each user specified in this file will be skipped when performing
	# migration operations (delete/chown).
	# Skipped users will also be added to the PBIS user-ignore file.
	# Specify one user per line.
	# e.g.:
	# jsmith
EOF
	deploy_created=1
fi

if [ ! -f $SKIP_GROUP_LIST ]; then
        $ECHO "WRAPPER WARNING: Creating $SKIP_GROUP_LIST"
        touch $SKIP_GROUP_LIST
        cat > $SKIP_GROUP_LIST <<-EOF
	# This file is used to skip groups whose account exist in both
	# the local /etc/group database and in PBIS.
	# Each group specified in this file will be skipped when performing
	# migration operations (delete/chown).
	# Specify one group per line.
	# e.g.:
	# unix-dev-admins
EOF
	deploy_created=1
fi

if [ ! -f $ALIAS_USER_FILE ]; then
        $ECHO "WRAPPER WARNING: Creating $ALIAS_USER_FILE"
        touch $ALIAS_USER_FILE
        cat > $ALIAS_USER_FILE <<-EOF
	# This file is used to map users whose account names differ in
	# the local /etc/passwd database and in PBIS.
	# Each name pair specified in this file will be mapped.
	# Specify one tab separated pair per line.
	# e.g.:
	# john	jsmith
EOF
	deploy_created=1
fi

if [ ! -f $ALIAS_GROUP_FILE ]; then
        $ECHO "WRAPPER WARNING: Creating $ALIAS_GROUP_FILE"
        touch $ALIAS_GROUP_FILE
        cat > $ALIAS_GROUP_FILE <<-EOF
	# This file is used to map groups whose account names differ in
	# the local /etc/group database and in PBIS.
	# Each name pair specified in this file will be mapped.
	# Specify one tab separated pair per line.
	# e.g.:
	# developers unix-devs
EOF
	deploy_created=1
fi

if [ ! -f $BOX2NIS_FILE ]; then
        $ECHO "WRAPPER WARNING: Creating $BOX2NIS_FILE"
        touch $BOX2NIS_FILE
	deploy_created=1
fi

if [ ! -f $EXCLUDE_FILE ]; then
        $ECHO "WRAPPER WARNING: Creating $EXCLUDE_FILE"
        touch $EXCLUDE_FILE
	cat > $EXCLUDE_FILE <<-EOF
	# This file is used to exclude paths from the chown-all-files.pl script.
	# Each path listed will not be traversed for chown operations.
	# Specify one path per line, regex expressions allowed.
	lost\+found
	^/proc$
	^/dev$
	^/sys$
	^/kernel$
	^/vol$
	^/devices$
	^/boot$
EOF
	deploy_created=1
fi

if [ ! -f $SERVER_ACCESS_GROUPS_FILE ]; then
        $ECHO "WRAPPER WARNING: Creating $SERVER_ACCESS_GROUPS_FILE"
        touch $SERVER_ACCESS_GROUPS_FILE
        cat > $SERVER_ACCESS_GROUPS_FILE <<-EOF
	# This file is used to configure RequireMembershipOf for access control.
	# To process this wrapper ensure the following options are set in the main script:
	# DO_REQUIRE_MEMBERSHIP_OF=1
	# SERVER_ACCESS_GROUPS_FILE=(this file)
	# Specify one user/group per line in the format:
	#
	# hostname domain\accountname
	#
	# where 'hostname' is equal to the hostname (echo `hostname`) of the system 
	# to which this entry should be imported.
	# To import to all systems use 'ALL'
	#
	# where 'domain\accountname' is equal to the NT style domain\account of the 
	# user or group to be imported.  IF domain is excluded it will be set to the 
	# value of REQUIRE_MEMBERSHIP_GROUP_DOMAIN.  If neither value is supplied, 
	# the domain which this system is joined to will be used.
	# 
	# EXAMPLES:
	# centos65-01 SPPTECH\jsmith
	# centos65-02 SPPTECH\rjones
	# centos65-02 ROOT\lmichaels
	# centos65-02 mwilliams
	# ALL SPPTECH\developers
	$ ALL unix-admins
EOF
	deploy_created=1
fi

if [ -n "$deploy_created" ]; then
	$ECHO "WRAPPER WARNING:  Created deploy folder and/or supporting files."
	$ECHO "WRAPPER WARNING:  Will now exit to allow customization of files."
	exit_with_error `ERR_OPTIONS`
fi
    else
	    $ECHO "WRAPPER INFO: Run with --createdeploy to create a base staging folder to customize."
	    exit_with_error `ERR_OPTIONS`
    fi
fi

# Detect alternate authenticaiton products for removal later.
# Will always detect, as it is quick and gives info - but won't necessarily remove.
psection "MODULE START: DETECTING ALTERNATE AUTHENTICATION PROVIDERS"
# This block included from: ././alt-provider-detection.sh.


#Detect Centrify
adinfo=`command -v adinfo`
if [ $? -eq 0 ]; then
    $ECHO "WRAPPER INFO: Detected Centrify."
    ALT_PROVIDER_NAMES_INSTALLED="CENTRIFY"
    adinfo
    if [ $? -eq 0 ]; then
        ALT_PROVIDER_NAMES_ONLINE="CENTRIFY"
        $ECHO "WRAPPER INFO: Reloading Centrify cache..."
        adflush -f
        adreload
    else
        $ECHO "WRAPPER WARNING: Can't confirm Centrify status."
    fi
fi


#Detect VAS
if [ -x "/opt/quest/bin/vastool" ]; then
    $ECHO "WRAPPER INFO: Detected VAS."
    ALT_PROVIDER_NAMES_INSTALLED="${ALT_PROVIDER_NAMES_INSTALLED} VAS"
    vasstatus=`/opt/quest/bin/vastool info domain`
    if [ $? -eq 0 ]; then
        ALT_PROVIDER_NAMES_ONLINE="${ALT_PROVIDER_NAMES_ONLINE} VAS"
        $ECHO "WRAPPER INFO: Reloading VAS Cache..."
        /opt/quest/bin/vastool flush
    else
        $ECHO "WRAPPER WARNING: Can't confirm VAS status."
    fi
fi

#Detect WINBIND
wbinfo=`command -v wbinfo`
if [ $? -eq 0 ]; then
    $ECHO "WRAPPER INFO: Detected Winbind."
    ALT_PROVIDER_NAMES_INSTALLED="${ALT_PROVIDER_NAMES_INSTALLED} WINBIND"
    $wbinfo -p > /dev/null
    if [ $? -eq 0 ]; then
        ALT_PROVIDER_NAMES_ONLINE="${ALT_PROVIDER_NAMES_ONLINE} WINBIND"
    else
        $ECHO "WRAPPER INFO: Can't confirm Winbind status."
    fi
fi

#detect SSSD AD Join
# Realm is the "correct" way to join AD with sssd, but sssd doesn't have to join AD
# https://fedorahosted.org/sssd/wiki/Configuring_sssd_with_ad_server
# so we have to do several detection methods in series
# 
# We start by seeing if sssd is configured to be used and running, since those are
# inexpensive tests
sssdns=`$GREP -E -c '^passwd:.*sss' /etc/$nsfile`
realm=`command -v realm`
if [ $? -eq 0 ]; then
    $ECHO "WRAPPER INFO: Detected sssd 'realm' command."
    ALT_PROVIDER_NAMES_INSTALLED="${ALT_PROVIDER_NAMES_INSTALLED} SSSD"
    realmcount=`$realm list |wc -l`
    if [ $realmcount -gt 0 ]; then
        ALT_PROVIDER_NAMES_ONLINE="${ALT_PROVIDER_NAMES_ONLINE} SSSD"
        SSSDJOINDOM=`awk '/^[[:space:]]*domains/ { print $NF }' /etc/sssd/sssd.conf`
    else
        $ECHO "WRAPPER INFO: Can't confirm realmd status."
    fi
elif [ $sssdns -gt 0 ]; then
    ALT_PROVIDER_NAMES_INSTALLED="${ALT_PROVIDER_NAMES_INSTALLED} SSSD"
    #sssd configured in /etc/nsswitch.conf, but not realmd
    # but it might not be in actual use
    sssdcount=`ps -ef | $GREP -E -c '[s]ssd'`
    SSSDJOINDOM=`awk '/^[[:space:]]*domains/ { print $NF }' /etc/sssd/sssd.conf`
    if [ $sssdcount -gt 0 ]; then
        if [ "z${SSSDJOINDOM}" != "z" ]; then
            # sssd.conf is configured for some domains.  But how?
            sssdidprovider=`print_ini_value "[domains/$SSSDJOINDOM]" id_provider /etc/sssd/sssd.conf`
            ALT_PROVIDER_NAMES_ONLINE="${ALT_PROVIDER_NAMES_ONLINE} SSSD"
            $ECHO "WRAPPER INFO: Decteded sssd [domains/$SSSDJOINDOM] section."
        else
            $ECHO "WRAPPER WARNING: sssd is configured in /etc/$nsfile and it's running,  but there are no join domains. This system has a misconfiguration, but install will continue."
        fi
    else
        $ECHO "WRAPPER WARNING: sssd is configured in /etc/$nsfile, but it is not running. There is a misconfiguration, but install will continue and remove sssd."
    fi
fi


if [ "z$ALT_PROVIDER_NAMES_INSTALLED" != "z" ]; then
    $ECHO "WRAPPER INFO: Alternate Authentication Providers installed: ${ALT_PROVIDER_NAMES_INSTALLED}"
fi
if [ "z$ALT_PROVIDER_NAMES_ONLINE" != "z" ]; then
    $ECHO "WRAPPER INFO: Alternate Authentication Providers online: ${ALT_PROVIDER_NAMES_ONLINE}"
fi

# Pre-install data gathering
# TODO DCW shouldn't these be in an "if $USERDEL=1" ? - RCA
psection "MODULE START: GATHERING PRE-INSTALL ACCOUNT DATA"
# This block included from: ././readaccounts.sh.

# Purge old account data if enabled
if [ -n "$DO_PURGE_ACCOUNT_DATA" ]; then
    $ECHO "WRAPPER INFO: Purging prior account data from $BACKUP_DIR_ROOT..."
    rm -f $passwdmap $groupmap $passwdorg $grouporg $wbusers $wbgroups
fi

# If passwd and group files don't exist then ensure NssEnumeration is enabled
if ( [ $pbis_installed -eq 1 ] ) && ( [ ! -f "$passwdorg" ] || [ ! -f "$grouporg" ] ); then
    check_domainjoin_status
    if [ $? -eq 0 ]; then
        $ECHO "WRAPPER INFO: Validating NSSEnumerationEnabled is True..."
        $CONFIG --show NssEnumerationEnabled | $GREP -q true
        if [ $? -ne 0 ]; then 
            $ECHO "WRAPPER WARNING: NssEnumerationEnabled is false, need it to be true for migration to work, setting it thus..."
            NSSSETON=1
            $CONFIG NssEnumerationEnabled true
        fi
        $CONFIG --show NssEnumerationEnabled | $GREP -q true
        if [ $? -ne 0 ]; then 
            $ECHO "WRAPPER WARNING: NssEnumerationEnabled is still false, likely from GPO, fixing in Policy tree, this will take 10-15 seconds."
            $REGSHELL delete_value '[HKEY_THIS_MACHINE\Policy\services\lsass\Parameters\providers\ActiveDirectory]' "NssEnumerationEnabled"
            $CONFIG NssEnumerationEnabled true
            sleep 10;
        fi
        $CONFIG --show NssEnumerationEnabled | $GREP -q true
        if [ $? -ne 0 ]; then 
            $ECHO "WRAPPER ERROR: NssEnumerationEnabled is still false- exiting so this can be fixed!"
            exit_with_error `ERR_OPTIONS`
        fi

        $ECHO "WRAPPER INFO: Clearing Cache..."
        clear_cache=`$LWPath\ad-cache --delete-all > /dev/null 2>&1`
        if [ $? = 0 ]; then
            $ECHO "WRAPPER INFO: Cached successfully cleared."
        elif [ $? = 185 ]; then
            $ECHO "WRAPPER WARNING: Could not clear cache due to offline domains."
        else
            $ECHO "WRAPPER WARNING: Could not clear cache due to unknown error."
        fi

        #restart_lsass  # 2016-10-15 Ben had this restarting, but that reloads GPO, which he's specifically trying to get around. So don't restart.
        check_lsass_provider_status "lsa-activedirectory-provider" "reset"
    fi
fi

$ECHO $ALT_PROVIDER_NAMES_ONLINE | $GREP -q "SSSD"
result=$?
if [ "x$result" = "x0" ]; then
    $ECHO "WRAPPER INFO: gathering account information from sssd..."
    $AWK '/^\[.*main\// { print }' /etc/sssd/sssd.conf | while read domain;
do
    cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.$TODAY
    edit_ini_value "$domain" "enumerate" "True" /etc/sssd/sssd.conf.$TODAY > /etc/sssd/sssd.conf
done
servicehandler "restart" "sssd"
awesomeprint "WRAPPER INFO: sssd takes a long time to start for enumeation, we must wait $JOIN_SLEEP seconds to ensure enumeration works..."
sleep $JOIN_SLEEP
fi

if [ ! -f "$passwdorg" ]; then
    $ECHO "WRAPPER INFO: Gathering current user accounts..."
    ${PERL} -e 'while (1) { ($na,$pa,$ui,$gi,$qu,$co,$ge,$di,$sh,$ex) = getpwent(); exit if ($na=~/^$/); print join(":",$na,x,$ui,$gi,$ge,$di,$sh)."\n";}' > $passwdorg
else
    $ECHO "WRAPPER WARNING: $passwdorg already exists.  Skipping user account gathering."
fi

if [ ! -f "$grouporg" ]; then
    $ECHO "WRAPPER INFO: Gathering current group accounts..."
    ${PERL} -e 'while (1) {$line= join(":", getgrent())."\n"; exit if ($line=~/^$/); print $line;}' > $grouporg
else
    $ECHO "WRAPPER WARNING: $grouporg already exists.  Skipping group account gathering."
fi

if [ "x$NSSSETON" = "x1" ]; then 
    $CONFIG NssEnumerationEnabled false
fi

#TODO Ensure enumeration is enabled for other Alternate Proivders, or explicitly query their accounts
$ECHO $ALT_PROVIDER_NAMES_ONLINE | $GREP -q "WINBIND" 
result1=$?
$AWK '/^[^#;]*(passwd|group):.*winbind/' /etc/$nsfile > /dev/null
result2=$?
result=`add $result1 $result2`

if [ "x$result" = "x0" ]; then
    $ECHO "WRAPPER INFO: Gathering account information from winbind..."
    if [ ! -f "$wbusers" ]; then
        $ECHO "WRAPPER INFO: Gathering current winbind user accounts..."
        $wbinfo -u | $SED 's/[\]/||/g' > $wbusers
        while read USER;do
            $ECHO "$USER" | $GREP -q "||"
            if [ $? -eq 0 ]; then
                USER=`awesomeprint "$USER" | $SED -e 's/||/\\\\/g'`
            fi
            ${PERL} -e '($na,$pa,$ui,$gu,$qu,$co,$ge,$di,$sh,$ex) = getpwnam($ARGV[0]); print join(":", $na,"x",$ui,$gi,$ge,$di,$sh), "\n";' "$USER" >> $passwdorg
        done <$wbusers
    else
        $ECHO "WRAPPER WARNING: $wbusers already exists.  Skipping winbind user account gathering."
    fi

    if [ ! -f "$wbgroups" ]; then
        $ECHO "WRAPPER INFO: Gathering current winbind group accounts..."
        $wbinfo -g | $SED 's/[\]/||/g' > $wbgroups
        while read GROUP; do
            $ECHO "$GROUP" | $GREP -q "||"
            if [ $? -eq 0 ]; then
                GROUP=`awesomeprint "$GROUP" | $SED -e 's/||/\\\\/g'`
            fi
            ${PERL} -e '($gr,$pa,$gi,$mem) = getgrnam($ARGV[0]); $mem=~s/ /,/g; print join(":",$gr,$pa,$gi,$mem ), "\n"' "$GROUP" >> $grouporg
        done <$wbgroups
    else
        $ECHO "WRAPPER WARNING: $wbgroups already exists.  Skipping winbind group account gathering."
    fi
fi

$ECHO $ALT_PROVIDER_NAMES_ONLINE | $GREP -q "SSSD"
result=$?

if [ "x$result" = "x0" ]; then
    cp_verbose $BACKUP_DIR/sssd.conf-sssd-etc /etc/sssd/sssd.conf
    servicehandler "sssd" "restart"
    awesomeprint "WRAPPER INFO: sssd reset back to original state."
fi

######
# Setup Context, used by aliasing.
#
_DOMAINNAME=`domainname`
_HOSTNAME=`hostname`
_NISDOMAIN=
if [ -f $BOX2NIS_FILE ]; then
    greperror=0
	_LINE=`$GREP "^$_HOSTNAME[[:space:]]" $BOX2NIS_FILE`
	greperror=$?
	if [ $greperror -ne 0 ]; then
	    _LINE=`$GREP "^@$_DOMAINNAME[[:space:]]" $BOX2NIS_FILE`
	    greperror=$?
	fi
	if [ $greperror -ne 0 ]; then
	    $ECHO "WRAPPER INFO: No entry found in $BOX2NIS_FILE"
	else
	    set $_LINE
	    _NISDOMAIN=$2
	fi
fi
#######
localexception()
{
    username=$1

    if [ -d /etc/pbis ]; then
        ROOTDIR="/etc/pbis"
    elif [ -d /etc/likewise ]; then
        ROOTDIR="/etc/likewise"
    else
        echo "WRAPPER ERROR: PBIS isn't installed, can't continue!"
        exit_with_error `ERR_OS_INFO`
    fi

    if [ ! -w ${ROOTDIR}/user-ignore ]; then
        echo "WRAPPER ERROR: ${ROOTDIR}/user-ignore isn't writable, exiting!"
        exit_with_error `ERR_FILE_ACCESS`
    fi
    $GREP -q $username ${ROOTDIR}/user-ignore

    if [ $? -ne 0 ]; then
        $GREP -q ${username}: /etc/passwd
        if [ $? -eq 0 ]; then
            # this is a local user defined in /etc/passwd.
            if [ "x$DRYRUN" = "x1" ]; then
                $ECHO "WRAPPER INFO: DRYRUN: echo $username >> ${ROOTDIR}/user-ignore"
            else
                echo $username >> ${ROOTDIR}/user-ignore
            fi
        else
            $ECHO "WRAPPER INFO: User $username is a Local Exception, but NOT defined in /etc/passwd!!!!"
            $ECHO "WRAPPER INFO: not adding $username to /etc/pbis/user-ignore, will cause different behavior across hosts."
        fi
    fi
}

translate()
{
    unset _RESULT
    unset _NAME
    unset _ALIASFILE
    if [ "$1" = "passwd" ]; then
        _ALIASFILE=$ALIAS_USER_FILE
    else
        _ALIASFILE=$ALIAS_GROUP_FILE
    fi
    _NAME="$2"
    _RESULT="$_NAME"

    if [ -f $_ALIASFILE ]; then
	    for _element in "$_NAME@$_HOSTNAME" "$_NAME@$_NISDOMAIN" "$_NAME"; do
	        _match=`$AWK 'BEGIN{ FS="\t" }; $1~/^'"$_element"'$/ { print $2 }' $_ALIASFILE`
	        #_match=`$GREP "^$_element\t" $_ALIASFILE`
	        if [ -n "$_match" ]; then
	            _RESULT="$_match"
	            break
	        fi
	    done
    fi
    echo "$_RESULT"
    unset _RESULT
    unset _NAME
    unset _ALIASFILE
}

movehome()
{
    OLD_HOME=$1
    NEW_HOME=$2
    OLD_USERNAME=$3
    $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: Comparing home directory from $OLD_HOME to $NEW_HOME"
    if [ -r "$OLD_HOME" ]; then
        $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: $OLD_HOME exists, checking for symlink..."
        if [ -h "$OLD_HOME" ]; then
            $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: old home directory $OLD_HOME is a symbolic link, ignoring."
        else
            $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: $OLD_HOME is not a symlink, checking if equal to $NEW_HOME..."
            if [ "$NEW_HOME" = "$OLD_HOME" ]; then
                $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: New home $NEW_HOME is the same as old home $OLD_HOME, skipping move operation."
            elif [ -z "$OLD_HOME" ]; then
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: $OLD_USERNAME has an empty old home, skipping home move!"
            elif [ "$OLD_HOME" = "/home" ]; then
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: User migrated to AD - their home is $OLD_HOME - this folder won't be moved"
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping home move!"
            elif [ "$OLD_HOME" = "/export/home" ]; then
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: User was migrated to AD - their home is $OLD_HOME - this folder won't be moved"
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping home move!"
            elif [ `$ECHO "$NEW_HOME" | $GREP -E -c "^$OLD_HOME"` -gt 0 ]; then
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: User has a home: $OLD_HOME that's a subcomponent of $NEW_HOME."
                $ECHO "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping home move!"
            else
                $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: $OLD_HOME is ok, checking if $NEW_HOME exists..."
                if [ -r "$NEW_HOME" ]; then
                    $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: New home directory $NEW_HOME already exists"
                    rmdir_command=`command -v rmdir`
                    if [ "x$DRYRUN" = "x1" ]; then
                        $ECHO "DRYRUN: find $NEW_HOME -name 'oldhome-'`hostname`'*' -depth -type d -exec $rmdir_command {} 2>/dev/null \;"
                    else
                        find $NEW_HOME -name 'oldhome-'`hostname`'*' -depth -type d -exec $rmdir_command {} 2>/dev/null \;
                    fi
                    NEW_HOME="$NEW_HOME/oldhome-`hostname`-$OLD_USERNAME"
                    if [ -r "$NEW_HOME" ]; then
                        $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: New home directory $NEW_HOME already exists"
                        i=1
                        while $TRUE; do
                            TEST_PATH="$NEW_HOME-$i"
                            if [ ! -r "$TEST_PATH" ]; then
                                NEW_HOME=$TEST_PATH
                                break
                            fi
                            i=`add $i 1`
                        done
                    fi
                    $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: Using $NEW_HOME as destination path"
                fi
                #Added for OFI since all solaris were automounted
                if [ -f /etc/auto_home ] && [ `$GREP -c ":/" /etc/auto_home` -gt 0 ]; then
                    $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: Not moving $OLD_HOME - Detected AutoFS entries for auto_home!"
                elif [ -f /etc/auto.home ] && [ `$GREP -c ":/" /etc/auto.home` -gt 0 ]; then
                    $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: Not moving $OLD_HOME - Detected AutoFS entries for auto.home!"
                elif [ `mount | $GREP -w "/home" | $GREP -c ":/"` -gt 0 ]; then
                    $ECHO "WRAPPER WARNING: passwd: $OLD_USERNAME: Not moving $OLD_HOME - Detected NFS mount for /home!"
                else
                    if [ "$HOMEDIR_MOVE_ACTION" = "move" ]; then
                        if [ "x$DRYRUN" = "x1" ]; then
                            $ECHO "WRAPPER INFO: DRYRUN: mv $OLD_HOME $NEW_HOME"
                            $ECHO "WRAPPER INFO: DRYRUN: ln -s $NEW_HOME $OLD_HOME"
                        else
                            mv $OLD_HOME $NEW_HOME
                            ln -s $NEW_HOME $OLD_HOME
                        fi
                    else
                        if [ "x$DRYRUN" = "x1" ]; then
                            $ECHO "WRAPPER INFO: DRYRUN: ln -s $OLD_HOME $NEW_HOME"
                        else
                            ln -s $OLD_HOME $NEW_HOME
                        fi
                    fi
                fi
            fi
        fi
    fi
    $ECHO "WRAPPER INFO: passwd: $OLD_USERNAME: Movehome complete."
}


# usage for aliasing:
#
# _PARAM=unixstaff
# _RESULT=`translate "group" "$_PARAM"`
# echo "$_PARAM is now $_RESULT"
# _PARAM=cuylerj
# _RESULT=`translate "passwd" "$_PARAM"`
# echo "$_PARAM is now $_RESULT"
#

# Generate skip users file for local users which conflict with Alternate Provider identities
if [ -n "$DO_SKIP_LOCAL_UID_CONFLICTS" ] && [ -n "$ALT_PROVIDER_NAMES_ONLINE" ]; then
    psection "MODDULE START: CHECKING FOR LOCAL UID CONFLICTS WITH EXISTING AUTHENTICATION PROVIDERS."
# This block included from: ././skip-local-uid-conflicts.sh.

checkforuser(){
        $ECHO "WRAPPER WARNING: local user $USERNAME conflicts with $1 user $ALT_PROVIDER_USERNAME on uid number $UIDNUMBER."
        if [ "$ALT_PROVIDER_USERNAME" != "$USERNAME" ]; then
                $ECHO "WRAPPER WARNING: Username mismatch ($ALT_PROVIDER_USERNAME != $USERNAME)."
                while read line; do
                        $GREP -q "^$2$"
                done <$SKIP_USER_LIST
                if [ $? -ne 0 ]; then
                        $ECHO "WRAPPER WARNING: Adding $ALT_PROVIDER_USERNAME to $SKIP_USER_LIST."
                        $ECHO $ALT_PROVIDER_USERNAME >> $SKIP_USER_LIST
                else
                        $ECHO "WRAPPER WARNING: $ALT_PROVIDER_USERNAME already listed in $SKIP_USER_LIST."
                fi
        fi
}

while read userentry; do
        USERNAME=`echo $userentry | $AWK -F: '{print $1}'`
        UIDNUMBER=`echo $userentry | $AWK -F: '{print $3}'`

        $ECHO "WRAPPER INFO: Checking for conflicts on local user $USERNAME with uid number $UIDNUMBER ..."
        for alt_provider_name in $ALT_PROVIDER_NAMES_ONLINE; do
                if [ $alt_provider_name = "CENTRIFY" ]; then
                        ALT_PROVIDER_UIDNUMBER_LOOKUP=`adquery user -fu | $GREP :$UIDNUMBER$`
                        if [ $? -eq 0 ]; then
                                ALT_PROVIDER_USERNAME=`echo $ALT_PROVIDER_UIDNUMBER_LOOKUP | $AWK -F: '{print $1}'`
                                checkforuser Centrify $ALT_PROVIDER_USERNAME
                        fi
                fi
                if [ $alt_provider_name = "VAS" ]; then
                        ALT_PROVIDER_UIDNUMBER_LOOKUP=`/opt/quest/bin/vastool list -fo users | grep :VAS:$UIDNUMBER:`
                        if [ $? -eq 0 ]; then
                                ALT_PROVIDER_USERNAME=`echo $ALT_PROVIDER_UIDNUMBER_LOOKUP | $AWK -F: '{print $1}'`
                                checkforuser VAS $ALT_PROVIDER_USERNAME
                        fi
                fi
                if [ $alt_provider_name = "WINBIND" ]; then
                        ALT_PROVIDER_UIDNUMBER_LOOKUP=`wbinfo --uid-info=$UIDNUMBER 2>/dev/null`
                        if [ $? -eq 0 ]; then
                                ALT_PROVIDER_USERNAME=`echo $ALT_PROVIDER_UIDNUMBER_LOOKUP | $AWK -F: '{print $1}'`
                                checkforuser winbind $ALT_PROVIDER_USERNAME
                        fi
                fi
        done
done </etc/passwd

fi

# Unjoin/remove/shutdown Alternate Providers
if [ -n "$DO_ALT_PROVIDER_REMOVE" ] && [ -n "$ALT_PROVIDER_NAMES_ONLINE" ]; then
    psection "MODDULE START: REMOVING ALTERNATE AUTHENTICATION PROVIDERS."
# This block included from: ././alt-provider-remove.sh.


for alt_provider_name in $ALT_PROVIDER_NAMES_ONLINE; do
    if [ $alt_provider_name = "CENTRIFY" ]; then
        $ECHO "WRAPPER INFO: Removing Centrify from domain..."
        adleave -f
        if [ $? -ne 0 ]; then
            $ECHO "WRAPPER WARNING: Unable to unjoin from domain"
        fi
    fi
    if [ $alt_provider_name = "VAS" ]; then
        $ECHO "WRAPPER INFO: Removing VAS from domain..."
        /opt/quest/bin/vastool unjoin -fl
        if [ $? -ne 0 ]; then
            $ECHO "WRAPPER WARNING: Unable to unjoin from domain"
        fi
    fi

    if [ $alt_provider_name = "WINBIND" ]; then
        $ECHO "WRAPPER INFO: Adding winbind to list for NSS and PAM removal..."
        $ECHO $NSS_MODULES_TO_REMOVE | $GREP -q winbind
        if [ $? -ne 0 ]; then
            NSS_MODULES_TO_REMOVE="$NSS_MODULES_TO_REMOVE  winbind"
            DO_REMOVE_NSS=1
        fi
        $ECHO $PAM_MODULES_TO_REMOVE | $GREP -q winbind
        if [ $? -ne 0 ]; then
            PAM_MODULES_TO_REMOVE="$PAM_MODULES_TO_REMOVE winbind"
            DO_REMOVE_PAM=1
        fi
    fi
    if [ "$alt_provider_name" = "SSSD" ]; then
        $ECHO "WRAPPER INFO: Adding sssd to list for NSS and PAM removal..."
        $ECHO $NSS_MODULES_TO_REMOVE | $GREP -q sss
        if [ $? -ne 0 ]; then
            NSS_MODULES_TO_REMOVE="$NSS_MODULES_TO_REMOVE sss"
            DO_REMOVE_NSS=1
        fi
        $ECHO $PAM_MODULES_TO_REMOVE | $GREP -q sss
        if [ $? -ne 0 ]; then
            PAM_MODULES_TO_REMOVE="$PAM_MODULES_TO_REMOVE sss"
            DO_REMOVE_PAM=1
        fi
        authconfigbin=`command -v authconfig`
        if [ $? -eq 0 ]; then
            $ECHO "WRAPPER INFO: Removing krb5 and sssd from PAM and NSS with authconfig."
            $authconfigbin --disablekrb5 --disablesssd --disablesssdauth --disableldap --disablenis --enableforcelegacy --disableipav2 --updateall
        else
            $ECHO "WRAPPER WARNING: No authconfig binary found, continuing with krb5 removal using old method."
        fi
    fi
done

# workaround for 47014 - domainjoin doesn't support includedir, needs to be applied *after* authconfig for REALMD removal
$GREP -q -E '^[^[:space:]]includedir' $krb5path
if [ "$?" = "0" ]; then
    $ECHO "Found includedir directive in $krb5path - removing till 8.6.x fixes issue 47014."
    cp -p $krb5path $krb5path.$TODAY
    $AWK '/^[^[:space:]]includedir/ { print "#" $0 " # Removed by LW Install '$TODAY'"}; !/^[^#]*includedir/ { print }' $krb5path.$TODAY > $krb5path
    $ECHO "Commented the following lines from $krb5path:"
    $GREP -E "^#includedir" $krb5path
fi
fi

# Leave first if enabled
if [ -n "$DO_LEAVE" ]; then
    psection "MODULE START: DOMAIN LEAVE"
# This block included from: ././leave-domain.sh.
#If upgrading, remove the system from the domain first
        $ECHO "WRAPPER INFO: Leaving the current domain..."
        if [ -x "$LWPath/domainjoin-cli" ]; then
            RESULT=`$LWPath/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "$LWPath/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            pblank
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP} 
        elif [ -x "/usr/bin/domainjoin-cli" ]; then
            # Since PBIS 6.5 doesn't have "/usr/bin/domainjoin-cli" we have to check 2 places for it
            RESULT=`/usr/bin/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERRROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "/usr/bin/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP}
	else
            $ECHO "WRAPPER INFO: Likewise/PBIS not installed, therefore not leaving domain"
        fi
fi

# Uninstall if enabled
if [ -n "$DO_UNINSTALL" ]; then
    psection "MODULE START: UNINSTALL (UPGRADE)"
    CHECK_PASS_OPTIONS=`$ECHO $PASS_OPTIONS | $GREP -i '\--no_install'`
    if [ $? -eq 0 ]; then
	$ECHO "WRAPPER INFO: Bypassing both DO_INSTALL and DO_UNINSTALL from command line options."
	DO_INSTALL=
    else
# This block included from: ././force-uninstall.sh.
#If upgrading, remove the system from the domain first
    PACKAGE_BASE=$INSTALL_DIR
    LIKEWISEVER="${LW_VERSION}.${QFENUMBER}.${BUILDNUMBER}"
    $ECHO "WRAPPER INFO: Checking for current install..."
    if [ -r "/usr/bin/domainjoin-cli" ]; then
        $ECHO "WRAPPER INFO: Uninstall requested.  Removing existing packages..."
        if [ -d /usr/centeris ]; then
# This block included from: ././leave-domain.sh.
#If upgrading, remove the system from the domain first
        $ECHO "WRAPPER INFO: Leaving the current domain..."
        if [ -x "$LWPath/domainjoin-cli" ]; then
            RESULT=`$LWPath/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "$LWPath/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            pblank
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP} 
        elif [ -x "/usr/bin/domainjoin-cli" ]; then
            # Since PBIS 6.5 doesn't have "/usr/bin/domainjoin-cli" we have to check 2 places for it
            RESULT=`/usr/bin/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERRROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "/usr/bin/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP}
	else
            $ECHO "WRAPPER INFO: Likewise/PBIS not installed, therefore not leaving domain"
        fi
            pkguninstallerror=0
            if [ "$OStype" = "linux-rpm" ]; then
                rpm -qva |grep centeris |xargs rpm -e
                pkguninstallerror=$?
            else
                dpkg -l centeris* | $AWK '/ii/ { print $2 }' | xargs dpkg -r
                pkguninstallerror=$?
            fi
            if [ $pkguninstallerror -ne 0 ]; then
                $ECHO "WRAPPER WARNING: Could not uninstall centeris packages"
                $ECHO "WRAPPER WARNING: This is ok if LW4 wasn't already installed"
            fi
        fi
        if [ -d /opt/centeris ]; then
# This block included from: ././leave-domain.sh.
#If upgrading, remove the system from the domain first
        $ECHO "WRAPPER INFO: Leaving the current domain..."
        if [ -x "$LWPath/domainjoin-cli" ]; then
            RESULT=`$LWPath/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "$LWPath/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            pblank
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP} 
        elif [ -x "/usr/bin/domainjoin-cli" ]; then
            # Since PBIS 6.5 doesn't have "/usr/bin/domainjoin-cli" we have to check 2 places for it
            RESULT=`/usr/bin/domainjoin-cli leave 2>&1|grep -i success`
            if [ -z "$RESULT" ]; then
                $ECHO "WRAPPER ERRROR: Domain leave failed!"
                $ECHO "WRAPPER ERROR: Please try this command as root by hand:"
                $ECHO "/usr/bin/domainjoin-cli leave"
                exit_with_error `ERR_SYSTEM_CALL`
            fi
            $ECHO "WRAPPER INFO: Domain leave successful."
            $ECHO "WRAPPER INFO: Sleeping ${REPLICATION_SLEEP} seconds to allow object changes to replicate."
            sleep ${REPLICATION_SLEEP}
	else
            $ECHO "WRAPPER INFO: Likewise/PBIS not installed, therefore not leaving domain"
        fi
            if [ "$OStype" = "aix" ]; then
                installp -g -u centeris
                if [ $? -ne 0 ]; then
                    $ECHO "WRAPPER WARNING: Could not uninstall centeris packages"
                    $ECHO "WRAPPER WARNING: This is ok if LW4 wasn't already installed"
                fi
            elif [ "$OStype" = "solaris" ]; then
                pkginfo | grep likewise | xargs pkgrm
                if [ $? -ne 0 ]; then
                    $ECHO "WRAPPER WARNING: Could not uninstall centeris packages!"
                    $ECHO "WRAPPER WARNING: This is ok if LW4 wasn't already installed"
                fi
            else
                #TODO: Write uninstall of hpux 4.1
                $ECHO "#TODO: Write uninstall of hpux 4.1"
            fi
        fi
        INSTALL_COMMAND="purge"
        $ECHO "WRAPPER INFO: Running Installer with $INSTALL_COMMAND"
# This block included from: ./installer.sh.
    $ECHO "WRAPPER INFO: Install command is $INSTALL_COMMAND"
    $ECHO "WRAPPER INFO: PACKAGE_BASE is: $PACKAGE_BASE"
    $ECHO "WRAPPER INFO: LIKEWISEVER is: $LIKEWISEVER"

    if [ -z "${INSTALL_COMMAND}" ]; then
        $ECHO "WRAPPER ERROR: This file was imported badly!  There is no installer command!!!"
        exit_with_error `ERR_OPTIONS`
    fi

    if [ -d ${PACKAGE_BASE} ]; then
        cd ${PACKAGE_BASE}
        if [ "$?" -ne "0" ]; then
            $ECHO "WRAPPER ERROR: Unable to cd into ${PACKAGE_BASE}"
            exit_with_error `ERR_FILE_ACCESS`
        fi

        # Here comes the logic to set variables based on what arch & OS we're using
        ARCH=$platform
        PKGOS=$OStype
        case $OStype in
            aix)
                PKGTYPE="lpp"
                ;;
            solaris)
                PKGTYPE="pkg"
                if [ "${platform}" = "i386" ]; then
                    ARCH="x86"
                fi
                if [ "${platform}" = "sparc" ]; then
                    ARCH="sparcv9"
                fi
                ;;
            hpux)
                PKGTYPE="depot"
                ARCH=${platform}
                ;;
            linux-rpm)
                PKGTYPE="rpm"
                PKGOS="linux"
                # doing a [[ ]] statement on debian's dash will not work; old schooling it
                for archtype in i386 i486 i586 i686 athlon;
                do
                    if [ "${platform}" = "${archtype}" ]; then
                        ARCH="x86"
                    fi
                done
                # amd built kernels can return various strings to uname; our 64-bit rpm has worked but we should be mindful
                for archtype in x86_64 amd64;
                do
                    if [ "${platform}" = "${archtype}" ]; then
                        ARCH="x64"
                        platform="x86_64"
                    fi
                done
                if [ "${ARCH}" = "x86" ]; then
                    GLIBCVERSION=`rpm -q glibc --queryformat %{VERSION}`
                    if [ "${GLIBCVERSION}" = "[0-2]\.[0-2]" ]; then
                        ARCH="oldlibc-i386"
                    fi
                fi
                ;;
            linux-deb)
                PKGTYPE="deb"
                PKGOS="linux"
                # doing a [[ ]] statement on debian's dash will not work; old schooling it
                for archtype in i386 i486 i586 i686 athlon;
                do
                    if [ "${ARCH}" = "${archtype}" ]; then
                        ARCH="x86"
                    fi
                done
                # amd built kernels can return various strings to uname; our 64-bit rpm has worked for both but we should be mindful
                for archtype in x86_64;
                do
                    if [ "${ARCH}" = "${archtype}" ]; then
                        #ARCH="amd64"
			# package is named x64 not amd64
                        ARCH="x64"
                    fi
                done
                ;;
            freebsd)
                PKGTYPE="freebsd"
                if [ "${ARCH}" = "amd64" ]; then
                    $ECHO "WRAPPER ERROR: ${ARCH} is not currently supported"
                    exit_with_error `ERR_OS_INFO`
                    # we are translating "amd64" to "x86_64" in get-ostype.sh, well before this code runs, so this should never be hit.
                fi
                ;;
            darwin)
                # Do detection for Snow Leopard 64 bit compiled kernels (yes they will probaly using x86_64 for 64 bit machines)
                OSREL="`uname -r`"
                if [ ${OSREL%%.*} -ge 8 ] && [ ${OSREL%%.*} -le 9 ]; then
                    if [ "${ARCH}" = "x86_64" ]; then
                        $ECHO "WRAPPER ERROR: ${ARCH} is not currently supported"
                        exit_with_error `ERR_OS_INFO`
                    fi
                else
                    $ECHO "WRAPPER ERROR: Your version of Darwin (${OSREL}) is not supported."
                    exit_with_error `ERR_OS_INFO`
                fi
                ;;
            *)
                $ECHO "WRAPPER ERROR: Unknown OS. Full uname output: `uname -a`"
                exit_with_error `ERR_OS_INFO`
                ;;
        esac

        $ECHO "WRAPPER INFO: OS Detected: ${OStype}"
        $ECHO "WRAPPER INFO: Architecture Detected: ${ARCH}"
        if [ "$PKGOS" = "linux" ]; then
            LIKEWISERELNAME="${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}.${PKGOS}.${platform}.${PKGTYPE}.sh"
        else
            LIKEWISERELNAME="${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}.${PKGOS}.${ARCH}.${PKGTYPE}.sh"
        fi
        $ECHO "WRAPPER INFO: Testing $PACKAGE_BASE/$LIKEWISERELNAME"
        # Apple is "special", it does things 'different'. Because of the catch all above, the catch all below
        # will only work on all OSes that have had proper variables designed but aren't OS X (aka Darwin).
        if [ ! -f "$PACKAGE_BASE/$LIKEWISERELNAME" ]; then
            VERSTEST=`float_cond "if ( $LW_VERSION < 6.2 ) 1 "`
            if  [ $VERSTEST -eq 1 ] ; then
                if [ "$OStype" = "freebsd" ]; then
                    BSD_MAJOR=`uname -r | $AWK -F. '{ print $1 }'`
                    PACKAGE_SUB="agents/${PKGOS}${BSD_MAJOR}.${PKGOS}/sfx/lwise"
                else
                    PACKAGE_SUB="agents/${PKGOS}/${ARCH}/sfx/lwise"
                    $ECHO "WRAPPER INFO: BASE is now ${PACKAGE_BASE}/${PACKAGE_SUB} for less than 6.2"
                fi
            else
                if [ "$OStype" = "freebsd" ]; then
                    BSD_MAJOR=`uname -r | $AWK -F. '{ print $1 }'`
                    PACKAGE_SUB="agents/${PKGOS}${BSD_MAJOR}/${PKGOS}/${ARCH}/sfx"
                else
                    if [ "$OStype" = "solaris" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${platform}/sfx"
                    elif [ "$OStype" = "linux-rpm" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${PKGTYPE}.${ARCH}/sfx"
                    elif [ "$OStype" = "linux-deb" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${PKGTYPE}.${ARCH}/sfx"
                    else
                        PACKAGE_SUB="agents/${PKGOS}.${ARCH}/sfx/"

                    fi
                    $ECHO "WRAPPER INFO: BASE is now ${PACKAGE_BASE}/${PACKAGE_SUB} for greater than 6.2"
                fi
            fi
        else
            PACKAGE_SUB=""
            $ECHO "WRAPPER INFO: BASE is still ${PACKAGE_BASE}"
        fi

        if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
            case $OStype in
                darwin)
                    $ECHO "WRAPPER ERROR: This script cannot install from $OStype"
                    $ECHO "WRAPPER ERROR: Exiting."
                    exit_with_error `ERR_OS_INFO`
                    ;;
#               LWISE 5.0-LWISE-5.2 naming convention, retired in 6.0
#                solaris)
#                    if [ "$ARCH" = "sparc" ]; then
#                        LIKEWISERELNAME="l${BUILDNUMBER}sus.sh"
#                    elif [ "$ARCH" = "i386" ]; then
#                        LIKEWISERELNAME="l${BUILDNUMBER}sui.sh"
#                    fi
#                    ;;
                freebsd)
                    if [ "$BSD_MAJOR" = "8" ]; then
                        LIKEWISERELNAME="pbis-enterprise-${LIKEWISEVER}-${PKGOS}${BSD_MAJOR}-${ARCH}.sh"
                    fi
                    # All other freebsd package names are correct (last checked 5.3.7798)
                    ;;
            esac
        fi
        if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
            if [ -n "$DO_WGET" ]; then
                cd $PACKAGE_BASE
                wget --no-check-certificate $WGET_BASE/${LIKEWISERELNAME}
                if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
                    pblank
                    pblank
                    $ECHO "WRAPPER ERROR: Can't find installer at $PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME  !!!"
                    $ECHO "WRAPPER INFO:  Can try DO_REPO_INSTALL instead if no local agent binaries available."
                    pblank
                    exit_with_error `ERR_ACCESS`
                fi
            fi
        fi
        if [ ! "$OS" = "Darwin" ]; then
            $ECHO "WRAPPER INFO: Preparing the ${INSTALL_COMMAND} of the following package: ${LIKEWISERELNAME}"

            if [ "$SETEXTRACTYES" = "1" ]; then
                EXTRACTDIR="${EXTRACTPREFIXDIR}/${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}-${PKGOS}-${ARCH}-${PKGTYPE}"
                $ECHO "WRAPPER INFO: Extracting contents of ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} to ${EXTRACTDIR}"
            fi

            if [ -f ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} ]; then
                if [ ! -x ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} ]; then
                    chmod +x ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME}
                    if [ "$?" -ne "0" ]; then
                        $ECHO "WRAPPER ERROR: Installer was found but the file is not executable; furthermore trying to set the execution bit failed"
                        exit_with_error `ERR_FILE_ACCESS`
                    fi
                fi
                if [ "$SETEXTRACTYES" = "1" ]; then
                    $ECHO "WRAPPER INFO: Starting $INSTALL_COMMAND - this may take several minutes..."
                    ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                    installresult=$?
                    if [ "$INSTALL_COMMAND" = "purge" ]; then
                        if [ $OStype = "solaris" ]; then
                            $ECHO "WRAPPER INFO: Running 2 additional purge commands, to clean up some Solaris child zone issues."
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            installresult=$?
                        fi
                    fi
                    if [ "$installresult" -ne "0" ]; then
                        $ECHO "WRAPPER ERROR: Installation did *NOT* exit cleanly. If running an old version of Likewise, set DO_UPGRADE=1 (--upgrade):"
                        $ECHO "WRAPPER ERROR: To install manually run:"
                        $ECHO "${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS ${INSTALL_COMMAND}"
                        rm -rf ${EXTRACTDIR}
                        exit_with_error `ERR_SYSTEM_CALL`
                    else
                        rm -rf ${EXTRACTDIR}
                    fi
                else
                    $ECHO "WRAPPER INFO: Starting $INSTALL_COMMAND - this may take several minutes..."
                    ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS install 2>&1
                    installresult=$?
                    if [ "$INSTALL_COMMAND" = "purge" ]; then
                        if [ $OStype = "solaris" ]; then
                            $ECHO "WRAPPER INFO: Running 2 additional purge commands, to clean up some Solaris child zone issues."
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            installresult=$?
                        fi
                    fi
                    if [ "$installresult" -ne "0" ];  then
                        $ECHO "WRAPPER ERROR: Installation did *NOT* exit cleanly. If running an old version of Likewise, set DO_UPGRADE=1 (--upgrade):"
                        $ECHO "WRAPPER ERROR: To install manually run:"
                        $ECHO "${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND"
                        rm -rf ${EXTRACTDIR}
                        exit_with_error `ERR_SYSTEM_CALL`
                    else
                        rm -rf ${EXTRACTDIR}
                    fi
                fi
            else
                $ECHO "WRAPPER ERROR: Unable to locate installer, please verify that the path is correct and/or that the file is present"
                exit_with_error `ERR_FILE_ACCESS`
            fi
        fi
        $ECHO ""
        $ECHO "WRAPPER INFO: SUCCESSFULLY COMPLETED $INSTALL_COMMAND"
    else
        $ECHO "WRAPPER ERROR: Directory not found, please verify that ${PACKAGE_BASE} exists"
        exit_with_error `ERR_FILE_ACCESS`
    fi

    else
        $ECHO "WRAPPER INFO: Likewise 5.0 or higher not installed"
    fi
	if [ -z "$DO_INSTALL" ]; then
		$ECHO "WRAPPER INFO: DO_UNINSTALL enabled, enabling DO_INSTALL option"
		DO_INSTALL=1
	fi
   fi
fi

# Install PBIS
if [ -n "$DO_INSTALL" ]; then

    if [ -n "$DO_REPO_INSTALL" ]; then
        psection "MODULE START: INSTALL (REPO)"
# This block included from: ././lw8.0-install-repo.sh.
# These values are derived from variables in other parts of the script and/or are not needed for configuration. Please do not touch.
$ECHO "WRAPPER INFO: Installing Product: ${LIKEWISE_PRODUCT_NAME}"
reposuccess=0

LIKEWISEVER="${LW_VERSION}.${QFENUMBER}.${BUILDNUMBER}"
pblank
REPOCMD=""
configure_pbis_yum_repo ()
{
    YUMVERS=`/usr/bin/yum list available pbis-enterprise --showduplicates| $AWK '/'${LW_VERSION}'.'${QFENUMBER}'-'${BUILDNUMBER}'/ { print $2 }'`
    if [ "x${YUMVERS}" = "x${LW_VERSION}.${QFENUMBER}-${BUILDNUMBER}" ]; then
        $ECHO "WRAPPER INFO: PBIS Version ${LW_VERSION}.${QFENUMBER}-${BUILDNUMBER} is already available. Skipping repo file."
        return
    fi

    # Set up PBIS yum repo
    $ECHO "WRAPPER INFO: Configuring PBIS yum repo..."
    if [ -d /etc/yum.repos.d ]; then
        if [ -r "${PBIS_REPO_FILE}" ]; then
            /bin/rm -f "${PBIS_REPO_FILE}"
        fi
    elif [ -r /etc/yum.conf ]; then
        if [ ! `$GREP -r -qs '^[[:space:]]*\[(likewise|pbis)\]' /etc/yum.conf` ]; then
            FILE=/etc/yum.conf
            $ECHO "" >> "${PBIS_REPO_FILE}"
        fi
    fi
    if [ -n "${PBIS_REPO_FILE}" ]; then
        /bin/cat >> "${PBIS_REPO_FILE}" <<-EOF
[pbis]
name=PBIS Enterprise
baseurl=http://repo.pbis.beyondtrust.com/yum/pbise/\$basearch/
gpgkey=http://repo.pbis.beyondtrust.com/yum/RPM-GPG-KEY-pbis
enabled=1
enablegroups=0
gpgcheck=1
EOF
    fi
    REPOCMD="yum install -y pbis-enterprise"
}
install_pbis_rpms ()
{
    # Do a full yum clean first (we may have mucked with repos)
    $ECHO "WRAPPER INFO: Performing a 'yum clean all'..."
    /usr/bin/yum clean all >/dev/null

    # Install PBIS software
    $ECHO "WRAPEPR INFO: Installing/Updating PBIS RPMs..."

    /usr/bin/yum -y install pbis-enterprise-${LW_VERSION}.${QFENUMBER} &>/dev/null

    rpm -qva |$GREP pbis-enterprise-${LW_VERSION}.${QFENUMBER}

    if [ $? -eq 0 ]; then
        reposuccess=1
    else
        if [ -n "$DO_INSTALL" ]; then
            $ECHO "WRAPPER WARNING: REPO install failed, RPMs not found in 'rpm -qva | $GREP pbis-enterprise-${LW_VERSION}.${QFENUMBER}'"
            $ECHO "WRAPPER WARNING: will try SFX install instead."
        else
            $ECHO "WRAPPER ERROR: FAILED - RPMs not found in 'rpm -qva | $GREP pbis-enterprise-${LW_VERSION}.${QFENUMBER}'"
            $ECHO "WRAPPER ERROR: Failed to install or update required RPMs.  Aborting."
            exit_with_error `ERR_SYSTEM_CALL`
        fi
    fi
}
configure_pbis_apt_repo ()
{
    if [ "x`apt-cache show pbis-enterprise | $AWK '/Version:/ { print $2; exit}' `" = "x${LW_VERSION}.${QFENUMBER}.${BUILDNUMBER}" ]; then
        $ECHO "WRAPPER INFO: PBIS Version ${LW_VERSION}.${QFENUMBER}.${BUILDNUMBER} is available already, skipping repo file."
        return
    fi
    $ECHO "WRAPPER INFO: Setting up PBIS apt repo..."
    if [ -d /etc/apt/sources.repo.d/ ]; then
        if [ -r "${PBIS_REPO_FILE}" ]; then
            /bin/rm -f "${PBIS_REPO_FILE}"
        fi
    fi
    if [ -n "${PBIS_REPO_FILE}" ]; then
        /bin/cat >> "${PBIS_REPO_FILE}" <<-EOF
deb http://repo.pbis.beyondtrust.com/apt pbise non-free
EOF
    fi
    REPOCMD="apt-get -y install pbis-enterprise"
}
install_pbis_debs ()
{
    # Do a full apt-get update first (we may have mucked with repos)
    $ECHO "WRAPPER INFO: Adding PBIS Key..."
    wget -O - http://repo.pbis.beyondtrust.com/yum/RPM-GPG-KEY-pbis|apt-key add -
    $ECHO "WRAPPER INFO: Running apt-get update..."
    /usr/bin/apt-get update >/dev/null
    $ECHO "WRAPPER INFO: apt-get update complete..."


    # Install PBIS software
    $ECHO "WRAPPER INFO: Installing/Updating PBIS Debs..."
    #/usr/bin/apt-get install -y pbis-enterprise-${LW_VERSION}.${QFENUMBER}
    /usr/bin/apt-get install -y pbis-enterprise

    dpkg --get-selections |$GREP 'pbis-enterprise[[:space:]]*install'
    if [ $? -eq 0 ]; then
        reposuccess=1
    else
        $ECHO "WRAPPER ERROR: FAILED"
        $ECHO "WRAPPER ERROR: Failed to install or update required DEBs. Aborting."
        exit_with_error `ERR_SYSTEM_CALL`
    fi
}
configure_pbis_sol_repo()
{
    $ECHO "WRAPPER ERROR: NOT IMPLEMENTED"
    #TODO implement
    exit_with_error `ERR_OS_INFO`
}
case $OStype in
    linux-rpm)
        configure_pbis_yum_repo
        install_pbis_rpms
        ;;
    linux-deb)
        configure_pbis_apt_repo
        install_pbis_debs
        ;;
    #solaris)
    #    configure_pbis_sol_repo
    #    ;;
    *)
        $ECHO "WRAPPER WARNING: No Repo for this OS, using install.sh instead"
        ;;
esac
        if [ "x$reposuccess" != "x1" ]; then
            $ECHO "Repo install was not successful, trying alternate SFX installer."
        fi
    fi

    if [ "x$reposuccess" != "x1" ]; then
        psection "MODULE START: INSTALL (SFX)"
# This block included from: ././install-switch.sh.
if [ -n "$DO_INSTALL" ]; then
    PACKAGE_BASE=$INSTALL_DIR
    PACKAGE_SUB="."
    BUILDNUMBER="${QFENUMBER}.${BUILDNUMBER}"
    LIKEWISEVER="${LW_VERSION}.${BUILDNUMBER}"
    INSTALL_COMMAND="install"
# This block included from: ././installer.sh.
    $ECHO "WRAPPER INFO: Install command is $INSTALL_COMMAND"
    $ECHO "WRAPPER INFO: PACKAGE_BASE is: $PACKAGE_BASE"
    $ECHO "WRAPPER INFO: LIKEWISEVER is: $LIKEWISEVER"

    if [ -z "${INSTALL_COMMAND}" ]; then
        $ECHO "WRAPPER ERROR: This file was imported badly!  There is no installer command!!!"
        exit_with_error `ERR_OPTIONS`
    fi

    if [ -d ${PACKAGE_BASE} ]; then
        cd ${PACKAGE_BASE}
        if [ "$?" -ne "0" ]; then
            $ECHO "WRAPPER ERROR: Unable to cd into ${PACKAGE_BASE}"
            exit_with_error `ERR_FILE_ACCESS`
        fi

        # Here comes the logic to set variables based on what arch & OS we're using
        ARCH=$platform
        PKGOS=$OStype
        case $OStype in
            aix)
                PKGTYPE="lpp"
                ;;
            solaris)
                PKGTYPE="pkg"
                if [ "${platform}" = "i386" ]; then
                    ARCH="x86"
                fi
                if [ "${platform}" = "sparc" ]; then
                    ARCH="sparcv9"
                fi
                ;;
            hpux)
                PKGTYPE="depot"
                ARCH=${platform}
                ;;
            linux-rpm)
                PKGTYPE="rpm"
                PKGOS="linux"
                # doing a [[ ]] statement on debian's dash will not work; old schooling it
                for archtype in i386 i486 i586 i686 athlon;
                do
                    if [ "${platform}" = "${archtype}" ]; then
                        ARCH="x86"
                    fi
                done
                # amd built kernels can return various strings to uname; our 64-bit rpm has worked but we should be mindful
                for archtype in x86_64 amd64;
                do
                    if [ "${platform}" = "${archtype}" ]; then
                        ARCH="x64"
                        platform="x86_64"
                    fi
                done
                if [ "${ARCH}" = "x86" ]; then
                    GLIBCVERSION=`rpm -q glibc --queryformat %{VERSION}`
                    if [ "${GLIBCVERSION}" = "[0-2]\.[0-2]" ]; then
                        ARCH="oldlibc-i386"
                    fi
                fi
                ;;
            linux-deb)
                PKGTYPE="deb"
                PKGOS="linux"
                # doing a [[ ]] statement on debian's dash will not work; old schooling it
                for archtype in i386 i486 i586 i686 athlon;
                do
                    if [ "${ARCH}" = "${archtype}" ]; then
                        ARCH="x86"
                    fi
                done
                # amd built kernels can return various strings to uname; our 64-bit rpm has worked for both but we should be mindful
                for archtype in x86_64;
                do
                    if [ "${ARCH}" = "${archtype}" ]; then
                        #ARCH="amd64"
			# package is named x64 not amd64
                        ARCH="x64"
                    fi
                done
                ;;
            freebsd)
                PKGTYPE="freebsd"
                if [ "${ARCH}" = "amd64" ]; then
                    $ECHO "WRAPPER ERROR: ${ARCH} is not currently supported"
                    exit_with_error `ERR_OS_INFO`
                    # we are translating "amd64" to "x86_64" in get-ostype.sh, well before this code runs, so this should never be hit.
                fi
                ;;
            darwin)
                # Do detection for Snow Leopard 64 bit compiled kernels (yes they will probaly using x86_64 for 64 bit machines)
                OSREL="`uname -r`"
                if [ ${OSREL%%.*} -ge 8 ] && [ ${OSREL%%.*} -le 9 ]; then
                    if [ "${ARCH}" = "x86_64" ]; then
                        $ECHO "WRAPPER ERROR: ${ARCH} is not currently supported"
                        exit_with_error `ERR_OS_INFO`
                    fi
                else
                    $ECHO "WRAPPER ERROR: Your version of Darwin (${OSREL}) is not supported."
                    exit_with_error `ERR_OS_INFO`
                fi
                ;;
            *)
                $ECHO "WRAPPER ERROR: Unknown OS. Full uname output: `uname -a`"
                exit_with_error `ERR_OS_INFO`
                ;;
        esac

        $ECHO "WRAPPER INFO: OS Detected: ${OStype}"
        $ECHO "WRAPPER INFO: Architecture Detected: ${ARCH}"
        if [ "$PKGOS" = "linux" ]; then
            LIKEWISERELNAME="${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}.${PKGOS}.${platform}.${PKGTYPE}.sh"
        else
            LIKEWISERELNAME="${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}.${PKGOS}.${ARCH}.${PKGTYPE}.sh"
        fi
        $ECHO "WRAPPER INFO: Testing $PACKAGE_BASE/$LIKEWISERELNAME"
        # Apple is "special", it does things 'different'. Because of the catch all above, the catch all below
        # will only work on all OSes that have had proper variables designed but aren't OS X (aka Darwin).
        if [ ! -f "$PACKAGE_BASE/$LIKEWISERELNAME" ]; then
            VERSTEST=`float_cond "if ( $LW_VERSION < 6.2 ) 1 "`
            if  [ $VERSTEST -eq 1 ] ; then
                if [ "$OStype" = "freebsd" ]; then
                    BSD_MAJOR=`uname -r | $AWK -F. '{ print $1 }'`
                    PACKAGE_SUB="agents/${PKGOS}${BSD_MAJOR}.${PKGOS}/sfx/lwise"
                else
                    PACKAGE_SUB="agents/${PKGOS}/${ARCH}/sfx/lwise"
                    $ECHO "WRAPPER INFO: BASE is now ${PACKAGE_BASE}/${PACKAGE_SUB} for less than 6.2"
                fi
            else
                if [ "$OStype" = "freebsd" ]; then
                    BSD_MAJOR=`uname -r | $AWK -F. '{ print $1 }'`
                    PACKAGE_SUB="agents/${PKGOS}${BSD_MAJOR}/${PKGOS}/${ARCH}/sfx"
                else
                    if [ "$OStype" = "solaris" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${platform}/sfx"
                    elif [ "$OStype" = "linux-rpm" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${PKGTYPE}.${ARCH}/sfx"
                    elif [ "$OStype" = "linux-deb" ]; then
                        PACKAGE_SUB="agents/${PKGOS}.${PKGTYPE}.${ARCH}/sfx"
                    else
                        PACKAGE_SUB="agents/${PKGOS}.${ARCH}/sfx/"

                    fi
                    $ECHO "WRAPPER INFO: BASE is now ${PACKAGE_BASE}/${PACKAGE_SUB} for greater than 6.2"
                fi
            fi
        else
            PACKAGE_SUB=""
            $ECHO "WRAPPER INFO: BASE is still ${PACKAGE_BASE}"
        fi

        if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
            case $OStype in
                darwin)
                    $ECHO "WRAPPER ERROR: This script cannot install from $OStype"
                    $ECHO "WRAPPER ERROR: Exiting."
                    exit_with_error `ERR_OS_INFO`
                    ;;
#               LWISE 5.0-LWISE-5.2 naming convention, retired in 6.0
#                solaris)
#                    if [ "$ARCH" = "sparc" ]; then
#                        LIKEWISERELNAME="l${BUILDNUMBER}sus.sh"
#                    elif [ "$ARCH" = "i386" ]; then
#                        LIKEWISERELNAME="l${BUILDNUMBER}sui.sh"
#                    fi
#                    ;;
                freebsd)
                    if [ "$BSD_MAJOR" = "8" ]; then
                        LIKEWISERELNAME="pbis-enterprise-${LIKEWISEVER}-${PKGOS}${BSD_MAJOR}-${ARCH}.sh"
                    fi
                    # All other freebsd package names are correct (last checked 5.3.7798)
                    ;;
            esac
        fi
        if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
            if [ -n "$DO_WGET" ]; then
                cd $PACKAGE_BASE
                wget --no-check-certificate $WGET_BASE/${LIKEWISERELNAME}
                if [ ! -f "$PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME" ]; then
                    pblank
                    pblank
                    $ECHO "WRAPPER ERROR: Can't find installer at $PACKAGE_BASE/$PACKAGE_SUB/$LIKEWISERELNAME  !!!"
                    $ECHO "WRAPPER INFO:  Can try DO_REPO_INSTALL instead if no local agent binaries available."
                    pblank
                    exit_with_error `ERR_ACCESS`
                fi
            fi
        fi
        if [ ! "$OS" = "Darwin" ]; then
            $ECHO "WRAPPER INFO: Preparing the ${INSTALL_COMMAND} of the following package: ${LIKEWISERELNAME}"

            if [ "$SETEXTRACTYES" = "1" ]; then
                EXTRACTDIR="${EXTRACTPREFIXDIR}/${LIKEWISE_PRODUCT_NAME}-${LIKEWISEVER}-${PKGOS}-${ARCH}-${PKGTYPE}"
                $ECHO "WRAPPER INFO: Extracting contents of ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} to ${EXTRACTDIR}"
            fi

            if [ -f ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} ]; then
                if [ ! -x ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} ]; then
                    chmod +x ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME}
                    if [ "$?" -ne "0" ]; then
                        $ECHO "WRAPPER ERROR: Installer was found but the file is not executable; furthermore trying to set the execution bit failed"
                        exit_with_error `ERR_FILE_ACCESS`
                    fi
                fi
                if [ "$SETEXTRACTYES" = "1" ]; then
                    $ECHO "WRAPPER INFO: Starting $INSTALL_COMMAND - this may take several minutes..."
                    ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                    installresult=$?
                    if [ "$INSTALL_COMMAND" = "purge" ]; then
                        if [ $OStype = "solaris" ]; then
                            $ECHO "WRAPPER INFO: Running 2 additional purge commands, to clean up some Solaris child zone issues."
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            installresult=$?
                        fi
                    fi
                    if [ "$installresult" -ne "0" ]; then
                        $ECHO "WRAPPER ERROR: Installation did *NOT* exit cleanly. If running an old version of Likewise, set DO_UPGRADE=1 (--upgrade):"
                        $ECHO "WRAPPER ERROR: To install manually run:"
                        $ECHO "${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} --target ${EXTRACTDIR} $ZONEOPTS ${INSTALL_COMMAND}"
                        rm -rf ${EXTRACTDIR}
                        exit_with_error `ERR_SYSTEM_CALL`
                    else
                        rm -rf ${EXTRACTDIR}
                    fi
                else
                    $ECHO "WRAPPER INFO: Starting $INSTALL_COMMAND - this may take several minutes..."
                    ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS install 2>&1
                    installresult=$?
                    if [ "$INSTALL_COMMAND" = "purge" ]; then
                        if [ $OStype = "solaris" ]; then
                            $ECHO "WRAPPER INFO: Running 2 additional purge commands, to clean up some Solaris child zone issues."
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            ${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND 2>&1
                            installresult=$?
                        fi
                    fi
                    if [ "$installresult" -ne "0" ];  then
                        $ECHO "WRAPPER ERROR: Installation did *NOT* exit cleanly. If running an old version of Likewise, set DO_UPGRADE=1 (--upgrade):"
                        $ECHO "WRAPPER ERROR: To install manually run:"
                        $ECHO "${PACKAGE_BASE}/${PACKAGE_SUB}/${LIKEWISERELNAME} $ZONEOPTS $INSTALL_COMMAND"
                        rm -rf ${EXTRACTDIR}
                        exit_with_error `ERR_SYSTEM_CALL`
                    else
                        rm -rf ${EXTRACTDIR}
                    fi
                fi
            else
                $ECHO "WRAPPER ERROR: Unable to locate installer, please verify that the path is correct and/or that the file is present"
                exit_with_error `ERR_FILE_ACCESS`
            fi
        fi
        $ECHO ""
        $ECHO "WRAPPER INFO: SUCCESSFULLY COMPLETED $INSTALL_COMMAND"
    else
        $ECHO "WRAPPER ERROR: Directory not found, please verify that ${PACKAGE_BASE} exists"
        exit_with_error `ERR_FILE_ACCESS`
    fi
fi
    fi
fi

progressmessage="WRAPPER ERROR: The script has NOT run to completion.\n"
progressmessage=$progressmessage"WRAPPER INFO: The --no_install switch will prevent (re)installs on future runs.\n"

# Disable SE linux
if [ -n "$DO_SELINUX_DISABLE" ]; then
    psection "MODULE START: SELINUX DISABLE"
# This block included from: ././selinux-disable.sh.
if [ -n "$DO_SELINUX_DISABLE" ]; then
	$ECHO "WRAPPER INFO: Attempting to disable SELinux (set to Permissive)"
	if [ "$OStype" = "linux-rpm" ]; then
		/usr/sbin/setenforce 0
		RESULT=`/usr/sbin/getenforce |grep "Enforcing"`
		if [ -n "$RESULT" ]; then
			$ECHO "WRAPPER ERROR: setenforce 0 on  SELinux failed!"
			$ECHO "WRAPPER ERROR: SELinux status is still $RESULT"
			$ECHO "WRAPPER ERROR: Please disable SELinux manually and rerun the install."
			$ECHO "WRAPPER ERROR: Install failed."
			exit_with_error `ERR_FILE_ACCESS`
		fi
		if [ -s /etc/sysconfig/selinux ]; then
			cp /etc/sysconfig/selinux $BACKUP_DIR/selinux
			sed -e 's/SELINUX=enforcing/SELINUX=permissive/i' $BACKUP_DIR/selinux >/etc/sysconfig/selinux
			RESULT=`egrep "^SELINUX" /etc/sysconfig/selinux |grep 'enforcing'`
			if [ -n "$RESULT" ]; then
				$ECHO "ERROR: Disabling SELinux in sysconfig failed!"
				egrep "^SELINUX" /etc/sysconfig/selinux
				$ECHO "Please disable SELinux before continuing with install!"
				$ECHO "Install failed"
				exit_with_error `ERR_FILE_ACCESS`
			fi
		fi
		$ECHO "WRAPPER INFO: PASS"
	else
		$ECHO "WRAPPER INFO: SKIPPING (not linux)"
	fi
fi
fi

# Disable nscd caching for passwd and group
if [ -n "$DO_NSCD_DISABLE" ]; then
    psection "MODULE START: NSCD DISABLE"
# This block included from: ././nscd-disable.sh.
nscdfile="/etc/nscd.conf"
if [ -n "$DO_NSCD_DISABLE" ]; then
    $ECHO "WRAPPER INFO: Checking to see if $nscdfile exists"
    if [ -f $nscdfile ]; then
        $ECHO "disabling passwd and group cache from $nscdfile, creating backup"
        cp -p $nscdfile $nscdfile.$TODAY
        $SED -e '/enable-cache.*[pg]/d' $nscdfile.$TODAY > $nscdfile.$TODAY.1
        $GREP -q 'enable-cache' $nscdfile.$TODAY.1
        if [ "$?" = 1 ]; then
            $ECHO "stripping"
            $AWK 'BEGIN {found = 0} found == 0  {if (NF == 0 || /#/) {print} else {print "#\tenable-cache\t\thosts\t\tyes"; print; found=1} next} found==1 {print; next}' $nscdfile.$TODAY.1 > $nscdfile.$TODAY.2
        else
            cp -p $nscdfile.$TODAY.1 $nscdfile.$TODAY.2
        fi
        $AWK '{ if ( $0 ~ /enable-cache/ ) { print; print "\tenable-cache\t\tpasswd\t\tno"; print "\tenable-cache\t\tgroup\t\tno"} else { print } }' $nscdfile.$TODAY.2 > $nscdfile
    else
	$ECHO "WRAPPER INFO: $nscdfile not found"
    fi
    NSCDPID=`ps -elf |$AWK '/[n]scd/ { print $4 }'`
    if [ "$NSCDPID" = "" ]; then
        NSCDPID=`ps -elf |$AWK '/[n]ame-service-/ { print $4 }'`
    fi
    if [ -n "$NSCDPID" ]; then
        # nscd is running
        servicehandler "stop" "nscd"
        servicehandler "start" "nscd"
    fi
fi
fi

# Remove "nis" or "compat" lines from nsswitch prior to doing
# the join, so that lwidentity isn't trying to return the same,
# cleaner, information as NIS
if [ -n "$DO_REMOVE_NIS" ]; then
    psection "MODULE START: REMOVE NIS (NSS)"
# This block included from: ././nss-nis.sh.
if [ -n "$DO_REMOVE_NIS" ]; then
    $ECHO "Checking to see if nis is used in $nsfile"
    $GREP -q -i nis /etc/$nsfile
    if [ "$?" = "0" ];
    then
        $ECHO "removing NIS lines from /etc/$nsfile, creating backup"
        $ECHO "creating backup at /etc/$nsfile.$TODAY.nis"
        cp -p /etc/$nsfile /etc/$nsfile.$TODAY.nis
        sed -e '/^passwd:/ s/compat/files/' -e '/^passwd:/ s/nisplus//' -e '/^passwd:/ s/nis \[.*=.*\]//' -e '/^passwd:/ s/nis//' -e '/^group:/ s/compat/files/' -e '/^group:/ s/nisplus//' -e '/^group:/ s/nis \[.*=.*\]//' -e '/^group:/ s/nis//' -e '/^shadow:/ s/compat/files/' -e '/^shadow:/ s/nisplus//' -e '/^shadow:/ s/nis \[.*=.*\]//' -e '/^shadow:/ s/nis//' /etc/$nsfile.$TODAY.nis | tee /etc/$nsfile

        $ECHO "Completed NIS processing of $nsfile:"
        grep -i nis /etc/$nsfile
        if [ "$DO_DISABLE_YPBIND" = "1" ]; then
            servicehandler "disable" "ypbind"
            servicehandler "stop" "ypbind"
            if [ "$OStype" = "solaris" ]; then
                servicehandler "disable" "svc:/network/nis/client:default"
            elif [ "$OStype" = "freebsd" ]; then
                cp -p /etc/rc.conf /etc/rc.conf.$TODAY
                sed -e 's/^nis_client_enable/#nis_client_enable/' -e 's/^nis_ypset_enable/#nis_ypset_enable/' /etc/rc.conf.$TODAY |tee /etc/rc.conf
                cp -p /etc/$nsfile /etc/$nsfile.$TODAY.compat
                sed -e 's/^passwd_compat:/#passwd_compat:/' -e 's/^group_compat:/#group_compat:/' -e 's/^services_compat:/#services_compat:/' /etc/$nsfile.$TODAY.compat | tee /etc/$nsfile
            fi
        else
            $ECHO "not disabling NIS client"
        fi

    else
        $ECHO "nis reference not being used in $nsfile"
    fi
    $GREP -q -i passwd_compat /etc/$nsfile
    compatcheck=$?
    $GREP -q -i group_compat /etc/$nsfile
    if [ "$?" = "0" ]; then
        compatcheck=0
    fi
    if [ "$compatcheck" = "0" ]; then
        cp -p /etc/$nsfile /etc/$nsfile.$TODAY.compat
        $SED -e 's/^passwd_compat:/#passwd_compat:/' -e 's/^group_compat:/#group_compat:/' -e 's/^services_compat:/#services_compat:/' /etc/$nsfile.$TODAY.compat | tee /etc/$nsfile
        $ECHO "WRAPPER INFO: Removing passwd_compat and group_compat from /etc/$nsfile"
    fi

fi
fi

# Remove "winbind" lines from nsswitch prior to doing
# the join, so that lwidentity isn't trying to return the same,
# cleaner, information as winbind
if [ -n "$DO_REMOVE_NSS" ]; then
    psection "MODULE START: REMOVE NSS MODULES."
    for nss_module_name in $NSS_MODULES_TO_REMOVE; do
        #safely handle the case where there are no modules, but the option is enabled
        if [ -n "$nss_module_name" ]; then
            pline "MODULE START: REMOVE $nss_module_name"
# This block included from: ././nss-generic-remove.sh.

nss_module_name=`lcworks ${nss_module_name}`
$ECHO "WRAPPER INFO: Checking to see if $nss_module_name is used in /etc/$nsfile"
result=`$GREP -i $nss_module_name /etc/$nsfile`
if [ "$?" = "0" ];
then
    $ECHO "WRAPPER INFO: Found $nss_module_name in the following lines of /etc/$nsfile:"
    $ECHO "$result"
    #$ECHO "WRAPPER INFO: creating backup at /etc/$nsfile.$TODAY.$nss_module_name"
    cp -p /etc/$nsfile /etc/$nsfile.$TODAY.$nss_module_name
    $SED -e '/^passwd:/ s/'$nss_module_name' \[.*=.*\]//' -e '/^passwd:/ s/'$nss_module_name'//' -e '/^group:/ s/'$nss_module_name' \[.*=.*\]//' -e '/^group:/ s/'$nss_module_name'//' -e '/^shadow:/ s/'$nss_module_name' \[.*=.*\]//' -e '/^shadow:/ s/'$nss_module_name'//' /etc/$nsfile.$TODAY.$nss_module_name > /etc/$nsfile
    #$GREP -i $nss_module_name /etc/$nsfile
    result=`$AWK '/^[^#;]*(passwd|group|shadow):.*'$nss_module_name'/' /etc/$nsfile`
    if [ -n "$result" ]; then
        $ECHO "WRAPPER WARNING: $nss_module_name still detected in /etc/$nsfile:"
	$ECHO "$result"
    fi
else
    $ECHO "WRAPPER INFO: $nss_module_name reference not being used in $nsfile"
fi
rm -f /etc/$nsfile.$TODAY.$nss_module_name

# Remove from authconfig files to create less issues if authconfig is run.
if [ -f $BACKUP_DIR/authconfig_sysconfig ]; then
	case "$nss_module_name" in
		ldap)
		if [ $? -eq 0 ]; then
			$ECHO "WRAPPER INFO: Updating authconfig to remove LDAP for account information..."
			cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$nss_module_name
			$SED -e 's/^USELDAP=yes/USELDAP=no/gI' /etc/sysconfig/authconfig.$TODAY.$nss_module_name > /etc/sysconfig/authconfig
			rm -f /etc/sysconfig/authconfig.$TODAY.$nss_module_name
		fi
		;;
                sss)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove SSSD for account information..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$nss_module_name
                        $SED -e 's/^USESSSD=yes/USESSSD=no/gI' /etc/sysconfig/authconfig.$TODAY.$nss_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$nss_module_name
                fi
		;;
                winbind)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove WINBIND for account information..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$nss_module_name
                        $SED -e 's/^USEWINBIND=yes/USEWINBIND=no/gI' /etc/sysconfig/authconfig.$TODAY.$nss_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$nss_module_name
                fi
		;;
	esac
fi
        fi
    done
fi

# Remove entries from PAM that conflict with PBIS like Winbind, LDAP, KRB5, etc.
if [ "$DO_REMOVE_PAM" = "1" ]; then
    psection "MODULE START: REMOVE PAM MODULES."
    for pam_module_name in $PAM_MODULES_TO_REMOVE; do
        # Safely handle the case where there are no modules, but the option is enabled
        if [ -n "$pam_module_name" ]; then
            pline "MODULE START: REMOVE $pam_module_name"
# This block included from: ././pam-generic-remove.sh.

pam_module_name=`lcworks ${pam_module_name}`
$ECHO "WRAPPER INFO: Checking to see if ${pam_module_name} is used in $PAM_PATH"

if [ -f $PAM_PATH ]; then
    $GREP -q -E '^[^#].*pam_'${pam_module_name} $PAM_PATH
    if [ "$?" = "0" ]; then
        #$ECHO "WRAPPER INFO: Removing ${pam_module_name} lines from $PAM_PATH, creating backup at $PAM_PATH.$TODAY.${pam_module_name}"
        $ECHO "WRAPPER INFO: Found ${pam_module_name} in $PAM_PATH"
        cp -p $PAM_PATH $PAM_PATH.$TODAY.${pam_module_name}
	if [ -z "$DELETE_PAM_LINES" ]; then
		$AWK '/^[^#].*pam_'${pam_module_name}'/ { print "#" $0 " # Removed by LW Install '$TODAY'"}; !/pam_'${pam_module_name}'/ {print}' $PAM_PATH.$TODAY.${pam_module_name}> $PAM_PATH
		$ECHO "WRAPPER INFO: Commented the following lines from $pamfile:"
		$GREP -E  "^#.*pam_${pam_module_name}" $PAM_PATH
	else
		# Don't remark PAM lines, just remove them
		$ECHO "WRAPPER INFO: Deleting the following lines from $pamfile:"
                $AWK '/^[^#].*pam_'${pam_module_name}'.so/ { print }' $pamfile.$TODAY.${pam_module_name}
		$AWK '/^[^#].*pam_'${pam_module_name}'/ { next }; !/pam_'${pam_module_name}'/ {print}' $PAM_PATH.$TODAY.${pam_module_name}> $PAM_PATH
	fi
	if [ "$?" = "1" ]; then
	    pblank
	    pblank
	    $ECHO "WRAPPER ERROR: Failed modifying $PAM_PATH - please check this system and re-attempt the join."
	    pblank
	    cat $PAM_PATH
	    exit_with_error `ERR_SYSTEM_CALL`
	fi

        # clean up so that domainjoin-cli doesn't process the backup file, since there's one in $BACKUP_DIR
        rm $PAM_PATH.$TODAY.${pam_module_name}
    fi
elif [ -f /usr/share/pam-configs/${pam_module_name} ]; then
    $ECHO "WRAPPER INFO: Running pam-auth-update to remove ${pam_module_name}..."
    #/usr/sbin/pam-auth-update --remove ${pam_module_name} --package
    #remove ${pam_module_name} config from pam-configs - assume it's already been backed up by backup.sh
    rm /usr/share/pam-configs/${pam_module_name}
    /usr/sbin/pam-auth-update --package --force
    sleep 1
    /usr/sbin/pam-auth-update --package
    if [ $? -ne 0 ]; then
        $ECHO "WRAPPER ERROR Running pam-auth-udpate!  Please check the above output, and try again!!"
        exit_with_error `ERR_SYSTEM_CALL`
    fi
    $GREP -E '^[^#].*pam_'${pam_module_name}'' /etc/pam.d/common-auth
    if [ "$?" = "0" ]; then
        $ECHO "WRAPPER ERROR removing ${pam_module_name} from PAM with pam-auth-update - check the config and try again"
        exit_with_error `ERR_SYSTEM_CALL`
    fi
elif [ -d $PAM_PATH ]; then
    for pamfile in `ls $PAM_PATH/* |egrep -v "(.${pam_module_name}|.orig|.bak)"`; do
        $GREP -q -E '^[^#].*pam_'${pam_module_name} $pamfile
        if [ "$?" = "0" ]; then
            #$ECHO "WRAPPER INFO: Removing ${pam_module_name} lines from $pamfile, creating backup at $pamfile.$TODAY.${pam_module_name}"
            $ECHO "WRAPPER INFO: Found ${pam_module_name} in ${pamfile}"
            cp -p $pamfile $pamfile.$TODAY.${pam_module_name}
	    if [ -z "$DELETE_PAM_LINES" ]; then
		    $AWK '/^[^#].*pam_'${pam_module_name}'.so/ { print "#" $0 " # Removed by LW Install '$TODAY'"}; !/pam_'${pam_module_name}'/ {print}' $pamfile.$TODAY.${pam_module_name}> $pamfile
		    $ECHO "WRAPPER INFO: Commented the following lines from $pamfile:"
		    $GREP -E "^#.*pam_${pam_module_name}.so" $pamfile
            else
		# Don't remark PAM lines, just remove them
		$ECHO "WRAPPER INFO: Deleting the following lines from $pamfile:"
		$AWK '/^[^#].*pam_'${pam_module_name}'.so/ { print }' $pamfile.$TODAY.${pam_module_name}
		$AWK '/^[^#].*pam_'${pam_module_name}'.so/ { next }; !/pam_'${pam_module_name}'/ {print}' $pamfile.$TODAY.${pam_module_name}> $pamfile
	    fi
	    if [ "$?" = "1" ]; then
		pblank
		pblank
		$ECHO "WRAPPER ERROR: Failed modifying $pamfile - please check this system and re-attempt the join."
		pblank
		cat $pamfile
		exit_with_error `ERR_SYSTEM_CALL`
	    fi

        rm $pamfile.$TODAY.${pam_module_name}
        fi
    done    
fi

# Remove from authconfig files to create less issues if authconfig is run.
if [ -f $BACKUP_DIR/authconfig_sysconfig ]; then
        case "$pam_module_name" in
                krb5)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove KERBEROS for authentication..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $SED -e 's/^USEKERBEROS=yes/USEKERBEROS=no/gI' /etc/sysconfig/authconfig.$TODAY.$pam_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                fi
                ;;
                ldap)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove LDAP for authentication..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $SED -e 's/^USELDAPAUTH=yes/USELDAPAUTH=no/gI' /etc/sysconfig/authconfig.$TODAY.$pam_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                fi
                ;;
                sss)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove SSSD for authentication..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $SED -e 's/^USESSSDAUTH=yes/USESSSDAUTH=no/gI' /etc/sysconfig/authconfig.$TODAY.$pam_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $ECHO "WRAPPER INFO: Updating authconfig to remove IPAv2 for authentication..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $SED -e 's/^USEIPAV2=yes/USEIPAV2=no/gI' /etc/sysconfig/authconfig.$TODAY.$pam_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                fi 
                ;;
                winbind)
                if [ $? -eq 0 ]; then
                        $ECHO "WRAPPER INFO: Updating authconfig to remove WINBIND for authentication..."
                        cp -p /etc/sysconfig/authconfig /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                        $SED -e 's/^USEWINBINDAUTH=yes/USEWINBINDAUTH=no/gI' /etc/sysconfig/authconfig.$TODAY.$pam_module_name > /etc/sysconfig/authconfig
                        rm -f /etc/sysconfig/authconfig.$TODAY.$pam_module_name
                fi
                ;;
        esac
fi

        fi
    done
fi

# Add sshd privledge separation user to local passwd database
# in case it existed in NIS, but not locally.
# This has to be done after NIS removal process
# but before rejoining AD, because the join
# SIGHUPs or reloads sshd, and you can't add the user if NIS
# reports it still exists
if [ -n "$DO_ADMIN_USER" ]; then
    psection "MODULE START: ADD ADMIN USER"
# This block included from: ././add-user.sh.
# Add a user to local passwd database
# in case it existed in NIS, but not locally.
# This has to be done after NIS removal process
# but before rejoining AD, because the join
# SIGHUPs or reloads sshd, and you can't add the user if NIS
# reports it still exists

addusertogroup() {
    group=$1
    usermoderror=0
    case $OStype in 
        solaris)
            usermod -G $group $name
            usermoderror=$?
            ;;
        aix)
            usergroups=`groups $name | $SED -e 's/^[^ ]* : //' -e 's/ /,/g'`
            chuser groups="$usergroups,$group" $name
            usermoderror=$?
            ;;
        *) 
            usermod -G $group -a $name
            usermoderror=$?
            ;;
    esac
    return $usermoderror
}
i=0
NEW_UID=$ADMIN_UID
for name in $ADMIN_USER; do
    $ECHO "WRAPPER INFO: Attempting to add local sshd user $name..."
    RESULT=`$GREP "^$name:" /etc/passwd`
    if [ -z "${RESULT}" ]; then
        RESULT=`$GREP ":$ADMIN_GID:" /etc/group`
        if [ -z "${RESULT}" ]; then
            case $OStype in
                aix)
                    mkgroup id=$ADMIN_GID $name
                    groupadderror=$?
                    ;;
                *)
                    groupadd -g $ADMIN_GID $name
                    groupadderror=$?
                    ;;
            esac
            # create private group for user, since it's not an existing group
        fi
        #                    $ECHO "NOT FOUND $RESULT"
        #                    RESULT=`groupadd -g $ADMIN_GID $ADMIN_USER`
        #                    $ECHO "GROUP ADD $RESULT"
        NEW_UID=`add $NEW_UID $i`
        case $OStype in
            solaris)
                RESULT=`useradd -c "$name $ADMIN_GECOS" -g $ADMIN_GID -u $NEW_UID -d $HOMEDIR/$name -s $ADMIN_SHELL $name`
                useradderror=$?
                ;;
            aix)
                RESULT=`mkuser gecos="$name $ADMIN_GECOS" id=$NEW_UID login=true pgrp=$ADMIN_GID shell="$ADMIN_SHELL" home="$HOMEDIR/$name" $name`
                useradderror=$?
                ;;
            *)
                RESULT=`useradd -c "$name $ADMIN_GECOS" -g $ADMIN_GID -u $NEW_UID -d $HOMEDIR/$name -s $ADMIN_SHELL $name`
                useradderror=$?
                ;;
        esac

        if [ $useradderror -eq 0 ]; then
            if [ -x $INSTALL_DIR/autopasswd-$OStype-$platform ]; then
                $ECHO "WRAPPER INFO: Setting password with autopasswd..."
                $INSTALL_DIR/autopasswd-$OStype-$platform -n $ADMIN_USER_PASSWORD -c $ADMIN_USER_PASSWORD -- passwd $name
            elif [ -x "`which chpasswd`" ]; then
                $ECHO "WRAPPER INFO: Setting password with chpasswd..."
                $ECHO $name:$ADMIN_USER_PASSWORD | chpasswd
            else
                $ECHO "WRAPPER WARNING: Can't set password on this OS"
                $ECHO "WRAPPER WARNING: Obtain $INSTALL_DIR/autopasswd-$OStype-$platform"
            fi
        else
            $ECHO "WRAPPER ERROR: Could not add admin user!"
            $ECHO "$RESULT"
        fi
    else
        $ECHO "WRAPPER INFO: $name was found locally on the system, no changes made"
        useradderror=0
    fi

    if [ $useradderror -eq 0 ]; then
        addedtogroup=0
        for group in $ADMIN_USER_GROUPS; do
            addusertogroup $group
            addtogrouperror=$?
            if [ $addtogrouperror -eq 0 ]; then
                $ECHO "WRAPPER INFO: User $name added to group $group"
                addedtogroup=1
            fi
        done

        if [ $addedtogroup -ne 1 ]; then
            $ECHO "WRAPPER WARNING: Could not add $name to any of the following groups: $ADMIN_USER_GROUPS"
        fi
    else
        $ECHO "WRAPPER ERROR: Unable to add user $name to system!"
        $ECHO "$RESULT"
    fi

    i=`add $i  1`
done

fi


# TODO: local user processing PRIOR TO JOIN

# Enable workarounds for broken LD_LIBRARY_PATH variants.
# Will enable automatically if required, after warning
# Of problems
if [ "$DO_FIX_LD_LIBRARY_PATH" = "1" ]; then
    psection "MODULE START: FIX LIBRARY PATHS"
# This block included from: ././fix-ld-library-path.sh.
if [ "$DO_FIX_LD_LIBRARY_PATH" = "1" ]; then
    VERSTEST=`float_cond "if ( $LW_VERSION < 6.2 ) 1 "`
    if  [ $VERSTEST -eq 1 ] ; then

        $GREP LD_LIBRARY_PATH $INITBASE
        if [ "$?" = 1 ]; then
            cp $INITBASE $INITBASE.$TODAY
            $AWK '/export PATH/  { print $0; print "LD_LIBRARY_PATH=\"\""; print "export LD_LIBRARY_PATH"; print "LD_LIBRARY_PATH_32=\"\""; print "export LD_LIBRARY_PATH_32"; print "LD_PRELOAD=\"\""; print "export LD_PRELOAD"; print "LIBPATH=\"\""; print "export LIBPATH";print "SHLIB_PATH=\"\""; print "export SHLIB_PATH" } !/export LD_LIBRARY_PATH/ { print $0 }' $INITBASE.$TODAY > $INITBASE
        fi
        if [ "$OStype" = "solaris" ]; then
            if [ -x /usr/sbin/svcadm ]; then
                $ECHO "WRAPPER INFO: Solaris 10 detected, ensuring svcs environment is clean."
                svccfg -s lwsmd setenv -s -m start LD_LIBRARY_PATH \" \"
                svccfg -s lwsmd setenv -s -m start LD_LIBRARY_PATH_32 \" \"
                svccfg -s lwsmd setenv -s -m start LD_PRELOAD \" \"
                svccfg -s lwsmd setenv -s -m start SHLIB_PATH \" \"
                svcadm refresh lwsmd
                restart_lwsmd
            fi
        fi

        $ECHO "WRAPPER INFO: Fixed LD_LIBRARY_PATH in $INITBASE"
        $ECHO "WRAPPER WARNING: This is a workaround"
        $ECHO "WRAPPER ERROR: LD_LIBRARY_PATH is set system-wide, this needs to be fixed"
    fi
fi

if [ "$OStype" = "solaris" ]; then
    if [ -x "`which svccfg`" ]; then
        if [ `psrinfo | wc -l` -gt 8 ]; then
            #required in all versions up to 6.5.732+ / 7.0.1.900+
            LW_GLOBAL_TASK_THREADS=8
            export LW_GLOBAL_TASK_THREADS

#            svccfg -s lwsmd setprop start/environment=astring:'("LD_PRELOAD_32=/usr/lib/extendedFILE.so.1" "LD_LIBRARY_PATH=\"\"" "LW_GLOBAL_TASK_THREADS=8")'

            svcadm refresh lwsmd
            restart_lwsmd
        fi
    fi
fi
fi

# Change loglevel to debug or warning
psection "MODULE START: SET LOG LEVEL"
if [ -n "$DO_DEBUG" ]; then
    LOGLEVEL="--loglevel verbose"
    set_log_level debug
else
    LOGLEVEL="--loglevel warning"
fi
$ECHO "WRAPPER INFO: Log level set to '$LOGLEVEL' for join operation"

# Configure additonal wrapper options in registry
psection "MODULE START: STANDARD CONFIG SETTINGS"

if [ -n "$DO_ASSUME_DEFAULT_DOMAIN" ]; then
    DO_RESTART=1
    $ECHO "WRAPPER INFO: Setting AssumeDefaultDomain enabled."
    #$CONFIG AssumeDefaultDomain true
    #Using reg commands until config is fixed for offline errors
    $REGSHELL  set_value [HKEY_THIS_MACHINE\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "AssumeDefaultDomain" 1
fi

if [ -n "$DO_EDIT_CACHE" ]; then
    DO_RESTART=1
    $ECHO "WRAPPER INFO: Setting CacheEntryExpiry to $CACHE_TIME"
    $CONFIG CacheEntryExpiry $CACHE_TIME
fi

if [ -n "$DOMAIN_TRUST_LIST" ]; then
    DO_RESTART=1
    $ECHO "WRAPPER INFO: Setting DomainManager to include only the following domains: ${DOMAIN_TRUST_LIST}"
    $CONFIG DomainManagerIgnoreAllTrusts true
    $CONFIG DomainManagerIncludeTrustsList ${DOMAIN_TRUST_LIST}
fi

if [ -z "$HOMEDIR" ]; then
    $ECHO "WARNING: Can't set HomeDirPrefix to be a null value!"
elif [ -d "$HOMEDIR" ]; then
    DO_RESTART=1
    #Using reg commands until config is fixed for offline errors
    #$CONFIG HomeDirPrefix "$HOMEDIR"
    $REGSHELL  set_value [HKEY_THIS_MACHINE\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "HomeDirPrefix" "$HOMEDIR"
else
    $ECHO "WARNING: Cant set HomeDirPrefix to $HOMEDIR because it's not a valid path!"
fi

# enable auditing settings
if [ "$DO_AUDITING" = "1" ]; then
    DO_RESTART=1
    psection "MODULE START: DO AUDITING"
# This block included from: ././lw6.0-audit-enable.sh.
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent\\Parameters]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters]
$REGSHELL add_key [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters]
$REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\lsass\\Parameters\\Providers\\ActiveDirectory] "EnableEventlog" REG_DWORD 0x00000001
$REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\gpagent\\Parameters] "EnableEventlog" REG_DWORD 0x00000001
$REGSHELL add_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableUserPolicies" REG_DWORD 0x00000000
#$REGSHELL set_value [HKEY_THIS_MACHINE\\Services\\gpagent\\Parameters] "EnableUserPolicies" REG_DWORD 0x00000000  #Add will fail if it doesn't exist.  TODO: check and fix, so we don't spit errors
$REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "MaxDiskUsage" REG_DWORD 0x0493e000
$REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "MaxEventLifespan" REG_DWORD 0x0000005a
$REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventlog\\Parameters] "RemoveEventsAsNeeded" REG_DWORD 0x00000001
if [ -n "$COLLECTOR_SERVER" ]; then
    $REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters] "Collector" REG_SZ "$COLLECTOR_SERVER"
fi
if [ -n "$COLLECTOR_SPN" ]; then
    $REGSHELL add_value [HKEY_THIS_MACHINE\\Policy\\Services\\eventfwd\\Parameters] "CollectorPrincipal" REG_SZ "$COLLECTOR_SPN"
fi
if [ -n "$ALLOWEDREADGROUP" ]; then
    $CONFIG AllowReadTo "$ALLOWEDREADGROUP"
fi

#TODO need to check for appropriate .conf file for other syslogs
if [ -f /etc/syslog.conf ]; then
	$GREP -i "syslog-reaper" /etc/syslog.conf
	if [ "$?" -eq "1" ]; then
		#// Add these to the syslog.conf
		$ECHO '*.err			/var/lib/likewise/syslog-reaper/error' >> /etc/syslog.conf
		$ECHO '*.warning			/var/lib/likewise/syslog-reaper/warning' >> /etc/syslog.conf
		$ECHO '*.debug			/var/lib/likewise/syslog-reaper/information' >> /etc/syslog.conf
	fi
else
	$ECHO "WRAPPER WARNING: /etc/syslog.conf wasn't located"
fi


$REGSHELL set_value [HKEY_THIS_MACHINE\\Services\\eventlog] "Autostart" 0x00000001
$REGSHELL set_value [HKEY_THIS_MACHINE\\Services\\eventfwd] "Autostart" 0x00000001
$REGSHELL set_value [HKEY_THIS_MACHINE\\Services\\reapsysl] "Autostart" 0x00000001

$LWSM refresh lsass
$LWSM start eventlog
$LWSM refresh eventlog
$LWSM start eventfwd
$LWSM start reapsysl
fi

#enable local provider
if [ "x$DO_ENABLE_LOCAL_PROVIDER" = "x1" ]; then
	if [ "$OStype" = "aix" ]; then
		psecttion  "MODULE START: LOCAL PROVIDER"
		enable_local_provider
	fi
elif [ "x$DO_ENABLE_LOCAL_PROVIDER" = "x2" ]; then
	psection "MODULE START: LOCAL PROVIDER"
	enable_local_provider
fi

# Run custom code prior to join.
# Ideal for any custom config/registry settings 
if [ "$DO_CUSTOM_PRE_JOIN" = "1" ]; then
    DO_RESTART=1
    psection "MODULE START: DO CUSTOM PRE JOIN"
# This block included from: ././custom-pre-join.sh.
# START CUSTOM CONFIG STATEMENTS HERE

# REFRESH APPROPRIATE SERVICES IF NECESSARY 
#$LWSM refresh lsass
#$LWSM refresh eventlog
# END CUSTOM CONFIG STATEMENTS HERE 
fi

# Customer "drop-in" files.  Code to run prior to join.
if [ -n "$DO_RUN_CUSTOMER_SCRIPTS" ]; then
    psection "MODULE START: CUSTOMER PRE-JOIN SCRIPTS"
    # $customer_pre_join_script did not exist on build host, expecting customer to provide it.
    if [ -f $customer_pre_join_script ]; then
        . $customer_pre_join_script
    else
        $ECHO "WRAPPER WARNING: $customer_pre_join_script wasn't found, and it was supposed to be included!"
    fi
fi

# Restart lsass if going to do any custom settings
if [ "$DO_RESTART" = "1" ]; then
    DO_RESTART=
    psection "MODULE START: RESTART PBIS (lsass)"
    restart_lsass
fi

# Do the actual join.
# site-precache script needs to source the join script

psection "MODULE START: DOMAIN JOIN"
# Set a  randomized sleep, so that multiple systems joining at once don't fail due to AD logon problems. (krb5 replay attack detection?)
$PERL -e '$x=int(rand(5)); print "WRAPPER INFO: Sleeping for $x seconds for randomization."; sleep $x;'
# This block included from: ././lw5.0-join.sh.
# Workaround as of 3928, doing a reinstall of the software causes dcerpcd to hang ssh sessions. Kyle determined that this is a fair workaround
VERSTEST=`float_cond "if ( $LW_VERSION > 5.5 ) 1"`
if [ $VERSTEST -eq 1 ] ; then
    $ECHO ""
else
    servicehandler "restart" "dcerpcd" > /dev/null
fi

# Do the join itself
LASTJOINCOMMAND=""
printpasswordtext() {
    if [ -z "$JOIN_PASS" -a -z "$PASSWORD" ]; then
        pline
        pline
        $ECHO "No password was passed to the wrapper at runtime."
        $ECHO "Enter your AD join password below and press Enter."
        $ECHO "Please note, no characters will be echoed to the screen"
        $ECHO "and the script may appear to hang."
        $ECHO "Be patient, the script will resume as normal once the domain join routine completes."
        $ECHO "This may take several minutes in large environments."
        pblank
        $ECHO "PASSWORD:"
        pblank
    fi
}
fncjoin() {
    
    if [ -z "$JOIN_PASS" ]; then
        JOIN_PASS_TEXT=""
    else
        JOIN_PASS_TEXT="*PASSWORD MASKED*"
    fi
    
$ECHO "WRAPPER INFO: Joining domain now with command:\n"
    if $ECHO ${JOIN_OU} | $GREP -i -q "^none$" ; then
        $ECHO "domainjoin-cli --logfile $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log $LOGLEVEL $JOIN_CMD $JOIN_OPTS $JOIN_DOMAIN \"$JOIN_USER\" $JOIN_PASS_TEXT\n"
        LASTJOINCOMMAND="domainjoin-cli $JOIN_CMD $JOIN_OPTS $JOIN_DOMAIN \"$JOIN_USER\" $JOIN_PASS_TEXT"
        printpasswordtext
        RESULT=`domainjoin-cli --logfile $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log $LOGLEVEL $JOIN_CMD $JOIN_OPTS $JOIN_DOMAIN "$JOIN_USER" $JOIN_PASS 2>&1`
        JOINERR=$?
    else
        $ECHO "     domainjoin-cli --logfile $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log $LOGLEVEL $JOIN_CMD $JOIN_OPTS --ou \"$JOIN_OU\" $JOIN_DOMAIN \"$JOIN_USER\" $JOIN_PASS_TEXT"
        LASTJOINCOMMAND="domainjoin-cli $JOIN_CMD $JOIN_OPTS --ou \"$JOIN_OU\" $JOIN_DOMAIN \"$JOIN_USER\" $JOIN_PASS_TEXT"
        printpasswordtext
        RESULT=`domainjoin-cli --logfile $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log $LOGLEVEL $JOIN_CMD $JOIN_OPTS --ou "$JOIN_OU" $JOIN_DOMAIN "$JOIN_USER" $JOIN_PASS 2>&1`
        JOINERR=$?
    fi
    $ECHO $RESULT
    $ECHO "$RESULT" | $GREP -q SUCCESS
    RESULTERR=$?
    if [ $RESULTERR != "0" ]; then
        if [ $JOINERR = "0" ]; then
            # bugfix for domainjoin-cli always exiting with 0 status code
            JOINERR=1
        fi
    fi
}


jointries=0
JOINERR=1
while [ $jointries -lt 3 ] && [ $JOINERR -ne 0 ]; do
	if [ $jointries -gt 0 ]; then
		pblank
		$ECHO "WRAPPER WARNING:  Join failed, please try again"
        # we failed the join, unset the PASSWORD variable, so end-user can type it interactively
        PASSWORD=""
	fi
	fncjoin
	pblank
	jointries=`expr $jointries + 1`
    if [ -n "$JOIN_PASS" ]; then
        jointries=3
    fi
done

if [ $JOINERR -ne 0 ]; then
    $ECHO "WRAPPER ERROR: Could not join domain."
    $ECHO "WRAPPER ERROR: Please check log in $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log for details"
    $ECHO "WRAPPER ERROR: Recieved domainjoin-cli exit status $JOINERR"
    cat $OUTFILE_DIR/$JOIN_CMD-$TODAY-$host.log
    exit_with_error `ERR_NETWORK`
else
    $ECHO "WRAPPER INFO: Join successful."
    # Echo domain join status after successful join.
    $ECHO "WRAPPER INFO: Join Status:"
    pblank
    $LWPath/domainjoin-cli query
    pblank
    computer_name=`$LWPath/lsa ad-get-machine account | $GREP "SAM Account Name:" | $AWK '{print $4}' | tr [:lower:] [:upper:] | $SED s'/.$//'`
    host_name=`hostname | $AWK -F. '{ print $1 }' | tr [:lower:] [:upper:]`
    if [ "$computer_name" != "$host_name" ]; then
        $ECHO "WRAPPER WARNING:  Hostname does not match sAMAccountName.  Most likely hashed value was used (hostname is duplicate or > 15 characters?)."
	sleep 5
    fi
    $ECHO $LASTJOINCOMMAND > /etc/pbis/lastjoin
    $ECHO "WRAPPER INFO: Join command saved to '/etc/pbis/lastjoin'"
fi

# Assorted tests to confirm successful join
psection "MODULE START: POST JOIN TEST"
# This block included from: ././lw5.0-post-join-test.sh.

#Force a gporefresh and wait for processing to complete
rm -f /tmp/gpagent.log
$LWSM set-log-target gpagent - file /tmp/gpagent.log
$LWSM set-log-level gpagent - INFO
$LWPath/gporefresh > /dev/null

stop_watch=0
gpo_refresh_step_delay=5

$ECHO "WRAPPER INFO: Waiting for GPO processing to complete..."
while [ $stop_watch -lt 300 ] && [ "x$policy_complete" != "x1" ]; do
        $GREP -q "Completed refreshing computer group policies" /tmp/gpagent.log
        if [ $? -ne 0 ]; then
                $ECHO "WRAPPER INFO: Waiting ($stop_watch)..."
                stop_watch=`expr $stop_watch + $gpo_refresh_step_delay`
                sleep $gpo_refresh_step_delay
        else
                policy_complete=1
        fi
done

if [ "x$policy_complete" = "x1" ]; then
        $ECHO "WRAPPER INFO: GPO processing complete."
else
        $ECHO "WRAPPER WARNING: GPO processing timed out."
fi

$LWSM set-log-level gpagent - WARNING
$LWSM set-log-target gpagent - syslog

restart_lsass
check_lsass_provider_status "lsa-activedirectory-provider" "reset"

if [ $? -ne 0 ]; then
    $ECHO "WRAPPER ERROR: LSASS not running. Assuming join failed.  Check $JOIN_LOG"
    $ECHO "WRAPPER ERROR: Aborting"
    exit_with_error `ERR_LDAP`
fi

#
# Begin Testing after install has completed
# This lets us give better info back to the customer
# who are doing mass-script changes.
#


#
# DNS test to get a DC
# We shouldn't have been able to join if this fails, but just a double check.
#
check_domainjoin_status
if [ $? -ne 0 ]; then
    exit_with_error `ERR_LDAP`
fi

# Checks that lsass is online AND has the proper number of domains listed
domains=`$GETSTATUS | $GREP "Trusted Domains" | $AWK 'BEGIN{ FS = ": " };{ print $2+0 }'`
$ECHO "WRAPPER INFO: Detected $domains domain(s) from lsass"
if [ -z "$NUMBER_OF_DOMAINS" ]; then
	NUMBER_OF_DOMAINS=1
fi
if [ $NUMBER_OF_DOMAINS -gt $domains ]; then
        $ECHO "WRAPPER ERROR: $domains domain(s) is less than $NUMBER_OF_DOMAINS domain(s) specified!"
        $ECHO "WRAPPER ERROR: Aborting"
        exit 1
fi

#
# Check for any offline domains - eventually
# check_offline_domains

#
# Check that the test user can be found by lsassd
#
testuser_output=`$FINDUSERBYNAME $TESTUSER 2>&1`
testuser=`echo "$testuser_output" | grep "No such user"`
if [ -z "$testuser" ]; then
    $ECHO "WRAPPER INFO: Found $TESTUSER in AD, join successful!"
else
    $ECHO "WRAPPER WARNING: Unable to find user $TESTUSER, sleeping and retrying, may be trust enumeration delay."
    sleep $JOIN_SLEEP
    testuser_output=`$FINDUSERBYNAME $TESTUSER 2>&1`
    testuser=`echo "$testuser_output" | grep "No such user"`
    if [ -z "$testuser" ]; then
        $ECHO "WRAPPER INFO: Found $TESTUSER in AD, join successful!"
    else
        $ECHO "WRAPPER ERROR: Unable to find user $TESTUSER:"
        $ECHO "$testuser_output"
        $ECHO "WRAPPER ERROR: Join failed! Check log in $JOIN_LOG for more details"
        exit_with_error `ERR_LDAP`
    fi
fi


#
# Check  that the test user can authenticate through lsa
#

if [ "$DO_LSA_AUTH_TEST" = "1" ]; then
	LSA_AUTH_TEST=`$AUTHUSER --user $TESTUSER --password Gr33bleM33ble!`
	$ECHO $LSA_AUTH_TEST | $GREP -q -E PASSWORD_MISMATCH\|ACCOUNT_DISABLED
	if [ $? -eq 0 ]; then
	    $ECHO "WRAPPER INFO: Validated $TESTUSER via LSA: $LSA_AUTH_TEST"
	else
	    $ECHO "WRAPPER ERROR: Could not validate $TESTUSER via LSA: $LSA_AUTH_TEST"
	    exit_with_error `ERR_LDAP`
	fi 
fi

#
# Check  that the test user can authenticate through ssh (verifies PAM)
#

if [ "$DO_SSH_TEST" = "1" ]; then
    get_sshd_failure_count()
    {
        USERNAME="$1"
        # Return the number of login failure events for the given username where the account is disabled or the password is bad.
        $EVENTLOGCLI -s 'User = "'"$USERNAME"'"'' AND ( EventSourceID = 1250 OR EventSourceID = 1207 OR EventSourceID = 8)' 127.0.0.1  | grep ssh | wc -l
    }

    $CONFIG EnableEventlog true

    OLD_FAILURE_COUNT=`get_sshd_failure_count $TESTUSER`
    autopass="autopasswd-$OStype-$platform"
    autopassoptions=""
    if [ "$OStype" = "linux-rpm" ]; then
        autopass="autopasswd-linux-$platform"
    elif [ "$OStype" = "linux-deb" ]; then
        autopass="autopasswd-linux-$platform"
        autopassoptions="-i"
    fi
    if [ -x "$INSTALL_DIR/$autopass" ]; then
        $INSTALL_DIR/$autopass $autopassoptions -P badpassword -- ssh $TESTUSER@localhost "exit"
        NEW_FAILURE_COUNT=`get_sshd_failure_count $TESTUSER`
        if [ $NEW_FAILURE_COUNT -le $OLD_FAILURE_COUNT ]; then
            $ECHO "WRAPPER ERROR: Ssh failure event for $TESTUSER did not show up in eventlog."
            $ECHO "WRAPPER ERROR: Old failure count: $OLD_FAILURE_COUNT. New failure count: $NEW_FAILURE_COUNT"
            exit_with_error `ERR_LDAP`
        fi
    else
        $ECHO "WARNING: No $autopass file found in $INSTALL_DIR"
        $ECHO "WARNING: Could not complete ssh logon test"
        error `ERR_OPTIONS`
    fi

fi

# Run custom code post-join
if [ -n "$DO_CUSTOM_POST_JOIN" ]; then
    psection "MODULE START: CUSTOM POST-JOIN"
# This block included from: ././custom-post-join.sh.
# START CUSTOM POST JOIN STATEMENTS HERE 

# END CUSTOM POST JOIN STATEMENTS HERE 
fi

# Customer "drop-in" files.  Code to run post join.
if [ -n "$DO_RUN_CUSTOMER_SCRIPTS" ]; then
    psection "MODULE START: CUSTOMER POST-JOIN SCRIPTS"
    # $customer_post_join_script did not exist on build host, expecting customer to provide it.
    if [ -f $customer_post_join_script ]; then
        . $customer_post_join_script
    else
        $ECHO "WRAPPER WARNING: $customer_post_join_script wasn't found, and it was supposed to be included!"
    fi
fi

# Do DNS update if requested
if [ -n "$DO_UPDATE_DNS" ]; then
        psection "MODULE START: UPDATE DNS"
        $UPDATEDNS --show
        if [ $? = 0 ]; then
                $ECHO "WRAPPER INFO: DNS updated successfully"
        else
                $ECHO "WRAPPER WARNING: Error updating DNS"
        fi
fi

# process /etc/skel files
if [ -n "$DO_SKEL_CHANGE" ]; then
    psection "MODULE START: SKEL FILE CHANGE"
# This block included from: ././skel-change.sh.
# Some customers have custom "chage" or similar commands in their /etc/skel/.bash_profile
# This allows us to clean those commands up, so that new users don't run
# commands meant for local-only accounts.
# This is cleaned up on a per-user basis with DO_HOME_DIR_PROCESS
if [ -n "$DO_SKEL_CHANGE" ]; then
        pblank
        $ECHO "Editing lines in /etc/skel to remove references to local accounts"
        if [ -n "$DO_BACKUP" ]; then
                cp -p /etc/skel/.bash_profile $BACKUP_DIR/bash_profile.$TODAY
        fi
        sed -i -e "/MYID/d" /etc/skel/.bash_profile
        sed -i -e "/ACHANGE/d" /etc/skel/.bash_profile
        sed -i -e "/AEXP/d" /etc/skel/.bash_profile
        sed -i -e "/^echo \"Your Password Information:\"$/d" /etc/skel/.bash_profile
        sed -i -e "/\$CHANGE/d" /etc/skel/.bash_profile
        sed -i -e "/\$EXP/d" /etc/skel/.bash_profile
        sed -i -e "/^echo \"\"$/d" /etc/skel/.bash_profile
        sed -i -e "/^# User Passwd Change Information:$/d" /etc/skel/.bash_profile
        $ECHO "/etc/skel processing completed."
        pblank
        pline
fi

fi

# Some customers want to control "require_membership_of" on a per-server
# basis, rather than in Group Policy.  So far (8/22/08) all those groups
# had names based on the server name.
if [ -n "$DO_REQUIRE_MEMBERSHIP_OF" ]; then
    psection "MODULE START: ACCESS CONTROL"
# This block included from: ././require-membership-of.sh.
# Some customers want to control "require_membership_of" on a per-server
# basis, rather than in Group Policy. for migrations from NIS, we can use Netgroups migrated into AD
# for VAS, the groups already exist, so we just need to doublecheck and translate
# Lastly, we support file-based input as well
GROUPLISTFILE=$OUTFILE_DIR/require-membership-grouplist.$$
touch $GROUPLISTFILE
GROUPLISTTEMP=$OUTFILE_DIR/require-membership-grouptemp.$$
touch $GROUPLISTTEMP
pblank
GROUPLIST=""

# Get current domain
if [ -z "$REQUIRE_MEMBERSHIP_GROUP_DOMAIN" ]; then
    REQUIRE_MEMBERSHIP_GROUP_DOMAIN=`$GETSTATUS | $AWK '/Netbios name/ { print $NF; exit; }'`
fi

# Read in REQUIRE_MEMBERSHIP_GROUP users
rm $GROUPLISTTEMP > /dev/null 2>&1
$ECHO "WRAPPER INFO: Checking wrapper REQUIRE_MEMBERSHIP_GROUP..."
if [ -n "$REQUIRE_MEMBERSHIP_GROUP" ]; then
    awesomeprint "$REQUIRE_MEMBERSHIP_GROUP" | $SED -n 1'p' | tr ',' '\n' | $SED -e 's/[\/&]/||/g' > $GROUPLISTTEMP
    cat $GROUPLISTTEMP | while read group; do
	    # This sets a value of HOST to the shortname of this system and prepands any prefix specified
	    if [ "$group" = "HOSTNAME" ]; then
		group=`hostname | $AWK -F"." '{print $1}'`
	    fi
	    # If this is non-empty, we're using a hardset REQUIRE_MEMBERSHIP_GROUP value
	    $ECHO "$group" |$GREP -q '||'
	    if [ $? -ne 0 ]; then
		group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||${group}"
	    fi
	    $ECHO "${group}" >> $GROUPLISTFILE
	    awesomeprint "WRAPPER INFO: Staging REQUIRE_MEMBERSHIP_GROUP entry to access list: ${group}" | $SED -e 's/||/\\/g'
    done
fi

# Read in VAS users
rm $GROUPLISTTEMP > /dev/null 2>&1
$ECHO "WRAPPER INFO: Checking VAS users.allow..."
if [ -r /etc/opt/quest/vas/users.allow ]; then
    vasusersallow="/etc/opt/quest/vas/users.allow"
elif [ -r ${BACKUP_DIR}/vas/users.allow ]; then
    vasusersallow="${BACKUP_DIR}/vas/users.allow"
fi

if [ -r "$vasusersallow" ]; then
    cat $vasusersallow | $SED -e 's/[\/&]/||/g' > $GROUPLISTTEMP
    cat $GROUPLISTTEMP | while read group; do
	$ECHO "$group" | $GREP -q "@"
	if [ $? -eq 0 ]; then
		accountname=`$ECHO "$group" | awk -F@ '{print $1}'`
		accountfqdn=`$ECHO "$group" | awk -F@ '{print $2}'`
		accountnetbios=`/opt/pbis/bin/get-dc-name $accounfqdn | grep -i netbiosdomainname`
		if [ $? -eq 0 ]; then
			accountnetbios=`$ECHO $accountnetbios | awk -F= '{print $2}' | $SED 's/ //'`
			group="$accountnetbios||$accountname"
		else
			group="$accountname"
		fi
	fi
	if [ -n "$group" ]; then
		$ECHO "$group" |$GREP -q '||'
		if [ $? -ne 0 ]; then
			group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||${group}"
		fi
	fi
	$ECHO "${group}" >> $GROUPLISTFILE
	awesomeprint "WRAPPER INFO: Staging VAS users.allow entry to access list: ${group}" | $SED -e 's/||/\\/g'
     done
fi

# Read in access.conf users
rm $GROUPLISTTEMP > /dev/null 2>&1
$ECHO "WRAPPER INFO: Checking access.conf..."
if [ -r /etc/security/access.conf ]; then
    accessoutput=`clearcomments /etc/security/access.conf`
    if [ -n "$accessoutput" ]; then
        clearcomments /etc/security/access.conf | $AWK -F: '$1~/^[ ]*\+/ { sub(/:[ \t]+/, ":"); print $2 }' >$GROUPLISTTEMP
        while read group ; do
            if [ "$group" = "ALL" ]; then
    		    group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||Domain^users"
            else
    		    group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||${REQUIRE_MEMBERSHIP_GROUP_PREFIX}${group}"
            fi
	    	$ECHO "${group}" >> $GROUPLISTFILE
		    awesomeprint "WRAPPER INFO: Staging access.conf entry to access list: ${group}" | $SED -e 's/||/\\/g'
        done <$GROUPLISTTEMP
    fi
fi

# Read in NIS netgroups from passwd
rm $GROUPLISTTEMP > /dev/null 2>&1
$ECHO "WRAPPER INFO: Checking NIS Netgroups..."
netgrouplist=`$AWK -F: '$1~/^\+/' /etc/passwd`
if [ -n "$netgrouplist" ]; then
    # We have netgroup inclusions in the passwd file
    MAYBELIST=`$AWK -F: '$1~/^\+/ { sub(/^+/, ""); print $1 }' /etc/passwd`
    for group in $MAYBELIST; do
        netgroupcount=`$ECHO $GROUP | $GREP -c '@'`
        if [ -z "$netgroupcount" ]; then
            netgroupcount=0
        fi
        if [ $netgroupcount -gt 0 ]; then
            #found a netgroup, remove the @, since that won't translate to AD
            group=`$ECHO $group | $AWK '{ sub(/@/, ""); print }'`
        fi
	group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||${REQUIRE_MEMBERSHIP_GROUP_PREFIX}${GROUP}"
	$ECHO "${group}" >> $GROUPLISTFILE
	awesomeprint "WRAPPER INFO: Staging NIS Netgroup entry to access list: ${group}" | $SED -e 's/||/\\/g'
    done
fi

# Read in server-access-groups.txt
rm $GROUPLISTTEMP > /dev/null 2>&1
$ECHO "WRAPPER INFO: Checking for server-access-groups.txt file..."
if [ -n "$SERVER_ACCESS_GROUPS_FILE" ]; then
    if [ -f "$SERVER_ACCESS_GROUPS_FILE" ]; then
	$ECHO "WRAPPER INFO: Analyzing $SERVER_ACCESS_GROUPS_FILE..."
        # replace domain separator '\' from SERVER_ACCESS_GROUPS_FILE with '||' to deal with lack of "read -r" on Solaris systems
        $AWK '$1~/^('`hostname`'|ALL)$/ { $1=""; print $0; }' $SERVER_ACCESS_GROUPS_FILE | $SED -e 's/[\/&]/||/g' > $GROUPLISTTEMP
        #$GREP -v '^#' < $GROUPLISTTEMP | while read group; do
        clearcomments $GROUPLISTTEMP | while read group; do
		$ECHO "$group" |$GREP -q '||'
		if [ $? -ne 0 ]; then
			group="${REQUIRE_MEMBERSHIP_GROUP_DOMAIN}||${group}"
		fi
		$ECHO "${group}" >> $GROUPLISTFILE
		awesomeprint "WRAPPER INFO: Staging $SERVER_ACCESS_GROUPS_FILE entry to access list: ${group}" | $SED -e 's/||/\\/g'
        done 
    fi
fi

#Validate objects can be queried
rm $GROUPLISTTEMP > /dev/null 2>&1
grouplist_count=`wc -l "$GROUPLISTFILE" | $AWK '{ print $1 }'`
if [ $grouplist_count -gt 0 ]; then
	cat $GROUPLISTFILE | while read group; do
		if [ -n "$REQUIRE_MEMBERSHIP_VALIDATE" ]; then
			grouplookup=`awesomeprint "$group" | $SED -e 's/||/\\\\/g'`
			$FINDOBJECTS --by-nt4 "$grouplookup" > /dev/null
			if [ $? -eq 0 ]; then
				$ECHO "${group}" >> $GROUPLISTTEMP
				awesomeprint "WRAPPER INFO: ${group} found in AD will continue adding to access contol lists." | $SED -e 's/||/\\/g'
			else
				awesomeprint "WRAPPER WARNING: ${group} not found in AD will not be added to access contol lists." | $SED -e 's/||/\\/g'
			fi
		else
			$ECHO "${group}" >> $GROUPLISTTEMP
			awesomeprint "WRAPPER INFO: ${group} skipping validation will continue adding to access contol lists." | $SED -e 's/||/\\/g'
		fi
	done
fi

#Final translate of temp file to main list
if [ -r $GROUPLISTTEMP ]; then
	cat $GROUPLISTTEMP | $SED -e 's/||/\\/g' > $GROUPLISTFILE
else
	rm $GROUPLISTFILE > /dev/null 2>&1
fi

#Add all objects that validated
if [ -r $GROUPLISTFILE ]; then
    GROUPLIST=`cat "$GROUPLISTFILE"| $SED -e 's/^/"/g' -e 's/$/"/g' |$AWK '{ printf "%s ",  $0  }'`
    grouplist_count=`wc -l "$GROUPLISTFILE" | $AWK '{ print $1 }'`
    $ECHO "WRAPPER INFO: Setting 'RequireMembershipOf' via config to include the following $grouplist_count account(s):"
    cat $GROUPLISTFILE
    GROUPLIST=`cat "$GROUPLISTFILE"| $SED -e 's/^/"/g' -e 's/$/"/g' |$AWK '{ printf "%s ",  $0  }'`
    awesomeprint "$GROUPLIST" | xargs $CONFIG RequireMembershipOf
    if [ $? -eq 0 ]; then
    	$ECHO "WRAPPER INFO: $CONFIG --show RequireMembershipOf"
	$CONFIG --show RequireMembershipOf
	configlist_count=`$CONFIG --show RequireMembershipOf | wc -l | $AWK '{ print $1 }'`
	configlist_count=`expr $configlist_count - 3`
	if [ $grouplist_count = $configlist_count ]; then
		$ECHO "WRAPPER INFO: RequireMembershipOf completed successfully. All $configlist_count of $grouplist_count groups listed are configured."
        if [ -r /etc/security/access.conf ]; then
            chattr -i /etc/security/access.conf  #some customers have this set immutable. ha!
            cp /dev/null /etc/security/access.conf
        fi
	else
		$ECHO "WRAPPER WARNING: RequireMembershipOf did not complete successfully. Only $configlist_count of $grouplist_count groups listed are configured."
        if [ -r /etc/security/access.conf ]; then
            chattr -i /etc/security/access.conf  #some customers have this set immutable. ha!
            cp /dev/null /etc/security/access.conf
        fi
	fi
    else
	$ECHO "WRAPPER WARNING: RequireMembershipOf did not complete successfully, leaving access.conf in place."
    fi
else
    # No file found to get groups from...
    $ECHO "WRAPPER WARNING: Empty access control list, not setting up RequireMembershipOf"
fi
rm $GROUPLISTFILE > /dev/null 2>&1
rm $GROUPLISTTEMP > /dev/null 2>&1
fi

## Turn on netgroup support in $nsfile
if [ -n "$DO_EDIT_NSSWITCH_NETGROUP" ]; then
    psection "MODULE START: CONFIGURE NETGROUP SUPPORT"
    $ECHO "Editing $nsfile to include netgroup support"
# This block included from: ././lw5.0-netgroup.sh.
# Some customers want to control "require_membership_of" on a per-server
# basis, rather than in Group Policy.  So far (8/22/08) all those groups
# had names based on the server name.
if [ -n "$DO_EDIT_NSSWITCH_NETGROUP" ]; then
	$GREP netgroup /etc/$nsfile | $GREP -q lsass
	if [ $? -ne 0 ]; then
		ossupported=""
		for ositerator in Linux SunOS; do
			if [ "$kernel" = "$ositerator" ]; then
					ossupported="1"
			fi
		done
		if [ -n "$ossupported" ]; then
				$ECHO "WRAPPER INFO: Modifying $nsfile to include netgroup support via lsassd"
				cp -p /etc/$nsfile /etc/$nsfile.netgroup.$TODAY
				$AWK '/netgroup:/{ print $0,"lsass" }; !/netgroup:/{print}' /etc/$nsfile.netgroup.$TODAY > /etc/$nsfile
				RESULT="`grep 'netgroup:' /etc/$nsfile`"
				$ECHO "WRAPPER INFO: RESULT: $RESULT"
			else
				$ECHO "OS $kernel not supported"
		fi
	else
		$ECHO "WRAPPER INFO: Netgroups already configured for lsass"
	fi
fi

fi

# Similar to the DO_SKEL_CHANGE command up earlier in the script.
# This removes the local "chage" and similar commands from
# individual users' home .bash_profile
# For the logic behind both modules, view the sourced file.
if [ -n "$DO_HOME_DIR_PROCESS" ]; then
    psection "MODULE START: DO HOME_DIR_PROCESS"
# This block included from: ././bash_profile.sh.
#######################################################################
#
# HOW TO DETERMINE ALL LOCAL USERS WHO HAVE BEEN MIGRATED TO AD
#
# (Architecture by Michael Lampi, implementation by Rob Auch)
#
# Once the join has been completed, users may exist in both /etc/passwd
# and in AD (returned by lwidentity).  In these cases, we'd like to
# remove the local version of the account, so that only one password
# will work for the user.  Or we want to do processing of accounts in
# AD that used to be local to the server.
#
# If a user is a local user who has been migrated to AD, they will by
# definition be a user with a home directory, otherwise they wouldn't
# be able to log into the server.  Accounts like sshd and apache are
# left local, because they are local service accounts.  Therefore,
# we can loop through all home directories to determine users who
# log into the server.
#
# From the home directories, we can determine ownership by UID, and
# compare the UID of a directory with the home directory of the same
# UID in AD.  If both match, and are a valid path on the server,
# then the user used to be local, and now has been migrated to AD.
#
# This is accomplished in shell code by first listing the directories
# in /home (or /export/home, based on the variable at the top of this
# script) (ls -dn $HOMEDIR).  We then use $AWK to parse out the UID
# which owns each directory (|$AWK '{ print $3 }').  That UID is then
# passed to lwiinfo to look up the information for that user in AD
# (lwiinfo --uid-info $uid).  The home directory for that user is
# checked to make sure it's valid (-d $directory), and we then
# pull out the username and sid that we matched initially to the uid
# ($username=`lwiinfo --uid-info $uid |$AWK -F: '{print $1}'` and
# lwiinfo -s $username).  Verifying that the sID for that user gives
# ($username=`lwiinfo --uid-info $uid |$AWK -F: '{print $1}'` and
# lwiinfo -s $username).  Verifying that the sID for that user gives
# the same UID as we originally found in ls -dn completes the circle
# and we can now attempt our work against the account name.
#
# USERDEL is slightly more paranoid than HOME_DIR_PROCESS
#
#######################################################################

#
# Similar to the DO_SKEL_CHANGE command up earlier in the script.
# This removes the local "chage" and similar commands from
# individual users' home .bash_profile
# See the bottom of this section (between here and the next one)
# For the logic behind both modules.
#
if [ -n "$DO_HOME_DIR_PROCESS" ]; then
        pblank
        $ECHO "Beginning processing of home directories..."
        for uid in `ls -dGn $HOMEDIR/* |$AWK '{ print $3 }'`; do
                directory=`$LWPath/lwiinfo --uid-info $uid 2>&1 |$AWK -F: '{ print $6 }'`
                if [ -n `$LWPath/lwiinfo --uid-info $uid |grep Could` ]; then
                        $ECHO "user $uid is not in AD"
                elif [ -d "$directory" ]; then
                        if [ -n "$DO_BACKUP" ]; then
                                cp -p $directory/.bash_profile $BACKUP_DIR/$uid.bash_profile.$TODAY
                        fi
                        sed -i -e "/MYID/d" $directory/.bash_profile
                        sed -i -e "/ACHANGE/d" $directory/.bash_profile
                        sed -i -e "/AEXP/d" $directory/.bash_profile
                        sed -i -e "/^echo \"Your Password Information:\"$/d" $directory/.bash_profile
                        sed -i -e "/\$CHANGE/d" $directory/.bash_profile
                        sed -i -e "/\$EXP/d" $directory/.bash_profile
#                       sed -i -e "/^echo \"\"$/d" $directory/.bash_profile
                        sed -i -e "/^# User Passwd Change Information:$/d" $directory/.bash_profile
                else
                        $ECHO "Could not access $directory to find a .bash_profile"
                fi
        done
        $ECHO "Finishing processing of home directories."
        pblank
        pline
fi

fi

# Do removal of local accounts which have been migrated into AD
# See the sourced file for explanation of logic to determine "local"
# or "AD" accounts.
if [ -n "$DO_USERDEL" ]; then
    psection "MODULE START: REMOVE/UPDATE LOCAL ACCOUNTS"
# This block included from: ././userdel.sh.

# This block included from: ././createmap.sh.
if [ -n "$passwdmap" ]; then
    if [ -f "$passwdmap" ]; then
        $ECHO "WRAPPER INFO: Appending to existing $passwdmap"
    else
        $ECHO "oldid	newid	oldname	newname" > $passwdmap
    fi
fi
if [ -n "$groupmap" ]; then
    if [ -f "$groupmap" ]; then
        $ECHO "WAPPER INFO: Appending to existing $groupmap"
    else
        $ECHO "oldid	newid	oldname	newname" > $groupmap
    fi
fi

grp=$OUTFILE_DIR/group.$$							;# backup group file
pswd=$OUTFILE_DIR/passwd.$$							;# backup group file
cp_verbose /etc/group $grp
SED_SCRIPT_FILE=$OUTFILE_DIR/group-sed-script.$$	;# for fixup of group file


add_group_to_local_provider()
{
    if [ $local_provider_online -eq 0 ]; then
        enable_local_provider
    fi

    NEW_GROUPNAME=$1

    $ADDGROUP --gid $oldgid "$NEW_GROUPNAME" > /dev/null 2>&1
    return_code=$?

    if [ $return_code -eq 0 ]; then
        awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Added to LSASS Local Provider with GID:$oldgid."
    else
        if [ $return_code -eq 99 ]; then
            awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Already exists in LSASS Local Provider"
            return_code=0
        elif [ $return_code -eq 210 ]; then
            awesomeprint "WRAPPER WARNING: group: $NEW_GROUPNAME: GID of $oldgid too low for LSASS Local Provider (<1000)."
            error `ERR_CHOWN`
        else
            awesomeprint "WRAPPER WARNING: group: $NEW_GROUPNAME: Cannot be created in LSASS Local Provider (unknown error)."
            error `ERR_CHOWN`
        fi
    fi
    return $return_code
}

add_users_to_local_provider()
{
    if [ $local_provider_online -eq 0 ]; then
        enable_local_provider
    fi

    MEMBER=$1
    NEW_GROUPNAME=$2
    awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Adding $MEMBER (AD) to group in LSASS Local Provider..."
    $MODGROUP --add-members $MEMBER "$NEW_GROUPNAME" > /dev/null 2>&1
    return_code=$?
    if [ $return_code -eq 0 ]; then
        awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Migrated user $MEMBER (AD) to LSASS Local Provider group."
    elif [ $return_code -eq 35 ]; then
        awesomeprint "WRAPPER WARNING: group: $NEW_GROUPNAME: Can't add user $MEMBER to group (not an lsass user?)."
    elif [ $return_code -eq 76 ]; then
        awesomeprint "WRAPPER WARNING: group: $NEW_GROUPNAME: Can't add user $MEMBER to group (group exists in another account source?)."
    fi
    return $return_code
}

delete_local_group()
{
    NEW_GROUPNAME=$1
    $GREP -q "^$NEW_GROUPNAME:" $grp
    if [ $? -ne 0 ]; then
        return 0
        #Group not found locally, nothing to do
    fi
    awesomeprint "WRAPPER INFO: Deleting local group $NEW_GROUPNAME from /etc/group."
    if [ "x$DRYRUN" = "x1" ]; then
        awesomeprint "WRAPPER INFO: DRYRUN: $GREP -v "^$NEW_GROUPNAME:" $grp > ${grp}.tmp"
        awesomeprint "WRAPPER INFO: DRYRUN: cp ${grp}.tmp $grp"
    else
        $GREP -v "^$NEW_GROUPNAME:" $grp > ${grp}.tmp
        cp ${grp}.tmp $grp
        rm ${grp}.tmp
    fi
}

$ECHO "\nWRAPPER INFO: BEGIN USER ACCOUNT MIGRATION..."
if [ -n "$passwdmap" ]; then
    passwd_accounts=$OUTFILE_DIR/passwd_accounts.$$
    $AWK -F: '{print $1}' $passwdorg | $SED  -e 's/[\]/\\\\/g' > $passwd_accounts
    while read OLD_USERNAME; do
        NEW_USERNAME=`translate "passwd" "$OLD_USERNAME"`
        $FINDOBJECTS --user --by-name --provider lsa-activedirectory-provider "$NEW_USERNAME" | $GREP -q "Enabled: yes"

        if [ $? -eq 0 ]; then
            awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Translates to $NEW_USERNAME (AD)"
            if [ -f "$SKIP_USER_LIST" ]; then
                SKIP=`$GREP -c "^$OLD_USERNAME$" $SKIP_USER_LIST`
                if [ ${SKIP} -gt 0 ]; then
                    awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Listed in $SKIP_USER_LIST. Will not perform chown or delete operations."
                    localexception "$OLD_USERNAME"
                    #error `ERR_CHOWN`
                    continue
                fi
            else
                awesomeprint "WRAPPER VERBOSE: Expected to find a skip user list at $SKIP_USER_LIST."
            fi
            if [ "$OLD_USERNAME" = "root" ]; then
                awesomeprint "WRAPPER WARNING: passwd: $OLD_USERNAME: Migrated to AD, this should NOT have happened. Will not perform chown or delete operations."
                localexception "$OLD_USERNAME"
                continue
            fi
            # checking Home directories
            OLD_HOME=`$AWK -F: '/^'"$OLD_USERNAME"':/ { print $6; exit; }' $passwdorg | $SED -e 's/\/$//'`  #the sed command removes trailing "/" characters, to avoid  some move and test problems
            NEW_HOME=`$FINDUSERBYNAME "$NEW_USERNAME" | $SED -n 's/Home dir: *\(.*\)/\1/p' | $SED -e 's/\/$//'`  #the sed command removes trailing "/" characters to avoid some move and test problems
            if [ `$ECHO $OLD_HOME | $GREP -c "/var/"` -ne 0 ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ `$ECHO $OLD_HOME | $GREP -c "/root"` -ne 0 ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ -z "$OLD_HOME" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home was '/' - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ "$OLD_HOME" = "/usr" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ "$OLD_HOME" = "/tmp" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ "$OLD_HOME" = "/usr/local" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ "$OLD_HOME" = "/bin" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Migrated to AD - their home is $OLD_HOME - this shouldn't have happened."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Skipping user migration."
                error `ERR_CHOWN`
                localexception "$OLD_USERNAME"
                continue
            fi
            if [ -z "$NEW_HOME" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Cannot find new account $NEW_USERNAME's home directory in AD - something is very wrong."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: Check this user after install is complete."
                error `ERR_CHOWN`
            else
                movehome "$OLD_HOME" "$NEW_HOME" "$OLD_USERNAME"
            fi

            newuid=`$FINDUSERBYNAME "$NEW_USERNAME" | $AWK '/Uid/ { print $2 }'`
            olduid=`$AWK -F: '/^'"$OLD_USERNAME"':/ { print $3; exit }' $passwdorg`

            if [ -z "$newuid" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: UID for $NEW_USERNAME couldn't be found via find-user-by-name."
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: A data error exists in AD."
                continue
            fi
            if [ -z "$olduid" ]; then
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNAME: UID for $OLD_USERNAME couldn't be found in $passwdorg!"
                awesomeprint "WRAPPER ERROR: passwd: $OLD_USERNMAE: A data error exists in the original source."
                continue
            fi
            if [ -d `dirname ${HOMEDIR_EXCEPTION_REPORT}` ]; then
                if [ ! -f $HOMEDIR_EXCEPTION_REPORT ]; then
                    $ECHO "Hostname, Old_name, Old_UID, Old_Home, New_Name, New_UID, New_Home" > $HOMEDIR_EXCEPTION_REPORT
                fi
                $ECHO "$host, $OLD_USERNAME, $olduid, $OLD_HOME, $NEW_USERNAME, $newuid, $NEW_HOME" >> $HOMEDIR_EXCEPTION_REPORT
            fi
            if [ $newuid -ne $olduid ]; then
                awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: $NEW_USERNAME added to passwd map for chown operations. Old:$olduid;New:$newuid"
                $ECHO "$olduid	$newuid	$OLD_USERNAME	$NEW_USERNAME" >> $passwdmap
            fi
            # delete the user
            usernamecounts=`$GREP -c "^$OLD_USERNAME:" /etc/passwd`
            errcode=$?
            if [ $usernamecounts -gt 0 ]; then
                awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Removing from /etc/passwd"
                if [ "x$DRYRUN" = "x1" ]; then
                    # fake the returncode from userdel as success
                    errcode=0
                else
                    userdel "$OLD_USERNAME" > /dev/null 2>&1
                    errcode=$?
                fi

                flag_private_group_for_removal=0
                if [ "x$REMOVE_PRIVATE_GROUPS" = "x1" ]; then
                    private_group=`$GREP "^$OLD_USERNAME:" $grp`
                    if [ $? -eq 0 ]; then
                        private_group_members=`$ECHO $private_group | $AWK -F: '{print $4}'`
                        if [ -z "$private_group_members" ] || [ "$private_group_members" = "$OLD_USERNAME" ]; then
                            flag_private_group_for_removal=1
                        fi
                    fi
                fi                            

                if [ $errcode -eq 0 ]; then
                    if [ "$flag_private_group_for_removal" = 1 ]; then
                        awesomeprint "WRAPPER DEBUG: passwd: $OLD_USERNAME: Removing private group from /etc/group"
                        delete_local_group $OLD_USERNAME
                        $GREP -v "^$OLD_USERNAME:" $grouporg > ${grouporg}.tmp
                        cp ${grouporg}.tmp $grouporg
                        rm ${grouporg}.tmp
                    fi
                else
                    awesomeprint "WRAPPER WARNING: passwd: $OLD_USERNAME: Failed to delete user (user logged in?)"
                    awesomeprint "WRAPPER WARNING: passwd: $OLD_USERNAME: User data can be manually cleaned up with the following commands:"
                    if [ "$OStype" != "solaris" ]; then
                        awesomeprint "    sed -i -e '/^"$OLD_USERNAME":/d' /etc/passwd;"
                        awesomeprint "    sed -i -e '/^"$OLD_USERNAME":/d' /etc/shadow;"
                        if [ $flag_private_group_for_removal = 1 ]; then
                            awesomeprint "    sed -i -e '/^"$OLD_USERNAME":/d' /etc/group;"
                        fi
                    else
                        awesomeprint "    sed -e '/^"$OLD_USERNAME":/d' /etc/passwd > /tmp/passwd.sed; cp /tmp/passwd.sed /etc/passwd;"
                        awesomeprint "    sed -e '/^"$OLD_USERNAME":/d' /etc/shadow > /tmp/shadow.sed; cp /tmp/shadow.sed /etc/shadow;"
                        if [ $flag_private_group_for_removal = 1 ]; then
                            awesomeprint "    sed -i -e '/^"$OLD_USERNAME":/d' /etc/group > /tmp/group.sed; cp /tmp/group.sed /etc/group;"
                        fi
                    fi                    
                    error `ERR_CHOWN`
                    continue
                fi
            fi
            # Update group membership to reflect AD username
            # TODO: (limitation) We're not handling the case where NEW_USERNAME is already a member
            if [ ! "$OLD_USERNAME" = "$NEW_USERNAME" ]; then
                sed_expr_build $SED_SCRIPT_FILE 's/\([:,]\)'${OLD_USERNAME}',/\\1'${NEW_USERNAME}',/'
                sed_expr_build $SED_SCRIPT_FILE 's/\([:,]\)'${OLD_USERNAME}'$/\\1'${NEW_USERNAME}'/'
                if [ -f "$SED_SCRIPT_FILE" ]; then
                    lines=`cat $SED_SCRIPT_FILE | wc -l`
                    if [ $lines -gt 0 ]; then
                        awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Group membership will update to $NEW_USERNAME."
                        #$ECHO "Running sed script file $SED_SCRIPT_FILE."
                        if [ "x$DRYRUN" = "x1" ]; then
                            awesomeprint "WRAPPER INFO: DRYRUN: sed_inline_run $SED_SCRIPT_FILE $grp"
                        else
                            sed_inline_run $SED_SCRIPT_FILE $grp
                        fi
                    else
                        awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: No group membership updates needed to $NEW_USERNAME."
                    fi
                else
                    awesomeprint "WRAPPER WARNING: passwd: $OLD_USERNAME: $SED_SCRIPT_FILE does not exist."
                fi
            fi
            # Add migrated user as a secondary member to their primary group
            # This ensures that all users remain in their primary group even if user's gid changes (due to non-migrated primary group).
            oldgid=`$AWK -F: '/^'"$OLD_USERNAME"':/ { print $4; exit }' $passwdorg`
            group_line=`$AWK -F: '/:'"$oldgid"':/ { print; exit }' $grp`
            if [ "x$group_line" != "x" ]; then
                    group_name=`echo $group_line | $AWK -F: '{ print $1 }'`
                    group_members=`echo $group_line | $AWK -F: '{ print $4 }'`
                    user_in_group=`echo $group_members | $GREP -E [,]\?$NEW_USERNAME[,]\?`
                    if [ $? -eq 1 ]; then
                            awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Adding as secondary member to primary group $group_name($oldgid)"
                            if [ "x$DRYRUN" = "x1" ]; then
                                cp $grp ${grp}.tmp
                                $SED "s/$group_line/$group_line,$NEW_USERNAME/" ${grp}.tmp > $grp
                                rm ${grp}.tmp
                            fi
                    fi
            fi
	else
            awesomeprint "WRAPPER INFO: passwd: $OLD_USERNAME: Translates to $NEW_USERNAME (local)"
        fi
    done < $passwd_accounts
fi
cp_verbose /etc/passwd $pswd

$ECHO "\nWRAPPER INFO: BEGIN GROUP ACCOUNT MIGRATION..."
if [ -n "$groupmap" -o "$OStype" = "aix" ]; then
    group_accounts=$OUTFILE_DIR/group_accounts.$$

    if [ `uname -s` = "AIX" -o "x$DO_ENABLE_LOCAL_PROVIDER" = "x2" ]; then
        MOVE2LOCAL=1
    else
        MOVE2LOCAL=0
    fi

    $AWK -F: '{print $1}' $grouporg | $SED  -e 's/[\]/\\\\/g' > $group_accounts

    while read OLD_GROUPNAME; do

        if [ -f "$SKIP_GROUP_LIST" ]; then
            SKIP=`$GREP -c "^$OLD_GROUPNAME$" "$SKIP_GROUP_LIST"`
            if [ ${SKIP} -gt 0 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Listed in $SKIP_GROUP_LIST. Will not perform chown or delete operations."
                #localexception $OLD_GROUPNAME
                #error `ERR_CHOWN`
                continue
            fi
        fi

        oldgid=`$AWK -F: '/^'"$OLD_GROUPNAME"':/ { print $3; exit }' $grouporg`
        NEW_GROUPNAME=`translate "group" "$OLD_GROUPNAME"`
        $FINDOBJECTS --group --by-name --provider lsa-activedirectory-provider "$NEW_GROUPNAME" | $GREP -q "Enabled: yes"

        if [ $? -eq 0 ]; then
            group_migrated_to_ad=1
        else
            group_migrated_to_ad=0
        fi

        if [ $group_migrated_to_ad = 1 ]; then    #Group is in AD we update local mappings
            awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Translates to $NEW_GROUPNAME (AD)"
            if [ "x$NEW_GROUPNAME" != "x$OLD_GROUPNAME" ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Updating local mappings to $NEW_GROUPNAME."
                if [ "x$DRYRUN" = "x1" ]; then
                    awesomeprint "WRAPPER INFO: DRYRUN: cp $grp ${grp}.tmp"
                    awesomeprint "WRAPPER INFO: DRYRUN: $SED -e "s/^$OLD_GROUPNAME:/$NEW_GROUPNAME:/" ${grp}.tmp > $grp"
                else
                    cp $grp ${grp}.tmp
                    $SED -e "s/^$OLD_GROUPNAME:/$NEW_GROUPNAME:/" ${grp}.tmp > $grp
                    rm ${grp}.tmp
                fi
            fi

            newgid=`$FINDGROUPBYNAME "$NEW_GROUPNAME" | $AWK /Gid/'{ print $2 }'`

            if [ -z "$newgid" ]; then
                awesomeprint "WRAPPER ERROR: group: $NEW_GROUPNAME: New GID is empty."
            elif [ -z "$oldgid" ]; then
                awesomeprint "WRAPPER ERROR: group: $OLD_GROUPNAME: Old GID is empty."
            elif [ $newgid -ne $oldgid ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Added to group map for chown operations. Old:$oldgid;New:$newgid."
                awesomeprint "$oldgid	$newgid	$OLD_GROUPNAME	$NEW_GROUPNAME" >> $groupmap
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Updating password and group files."
                if [ "x$DRYRUN" = "x1" ]; then
                    awesomeprint "WRAPPER INFO: DRYRUN: cp $grp ${grp}.tmp"
                    awesomeprint "WRAPPER INFO: DRYRUN: $SED -e "s/^${NEW_GROUPNAME}:[^:]*:${oldgid}:/${NEW_GROUPNAME}:x:${newgid}:/" ${grp}.tmp > $grp"
                    awesomeprint "WRAPPER INFO: DRYRUN: cp $pswd ${pswd}.tmp"
                    awesomeprint "WRAPPER INFO: DRYRUN: $SED -e "s/^\([^:]*:[^:]*:[^:]*\):${oldgid}:/\1:${newgid}:/" ${pswd}.tmp > $pswd"
                else
                    cp $grp ${grp}.tmp
                    $SED -e "s/^${NEW_GROUPNAME}:[^:]*:${oldgid}:/${NEW_GROUPNAME}:x:${newgid}:/" ${grp}.tmp > $grp
                    rm ${grp}.tmp
                    cp $pswd ${pswd}.tmp
                    $SED -e "s/^\([^:]*:[^:]*:[^:]*\):${oldgid}:/\1:${newgid}:/" ${pswd}.tmp > $pswd
                    rm ${pswd}.tmp
                fi
            fi
        else
            awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Translates to $NEW_GROUPNAME (local)."
            newgid=$oldgid
        fi

        # Get group members
        unset MEMBERSA
        LINE=`$AWK '/^'"$NEW_GROUPNAME"':/ { print $0; exit }' $grp`
        if [ -n "$LINE" ]; then
            MEMBERS=`$ECHO $LINE | $AWK -F: '{ print $4 }' `
            MEMBERS2=`$GREP "^[^:]*:[^:]*:[^:]*:$newgid:" $pswd | $AWK -F: '{ print $1 }'`
            MEMBERSA=`$ECHO $MEMBERS2; $ECHO $MEMBERS | $SED -e 's/,/ /g'`
        fi

        group_contains_local_users=0
        group_contains_ad_users=0

        add_group_attempted=0
        add_user_success=0
        add_user_error=0

        if [ -n "$MEMBERSA" ]; then
            for MEMBER in $MEMBERSA; do
                $FINDOBJECTS --user --by-name --provider lsa-activedirectory-provider "$MEMBER" | $GREP -q "Enabled: yes"
                if [ $? = 0 ]; then
                    if [ $group_migrated_to_ad -eq 0 -a $MOVE2LOCAL -eq 1 ]; then
                        awesomeprint $NEW_GROUPNAME | $GREP -q '\\'
                        if [ $? -ne 0 -a $add_group_attempted -eq 0 -a $newgid -gt 999 ]; then
                            awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Local group contains AD members. Will migrate to LSASS Local Provider."
                            if [ "x$DRYRUN" = "x1" ]; then
                                add_group_success=1
                            else
                                add_group_to_local_provider $NEW_GROUPNAME
                                if [ $? -eq 0 ]; then
                                    add_group_success=1
                                else
                                    add_group_success=0
                                fi
                                add_group_attempted=1
                            fi
                        elif [ $newgid -lt 1000 ]; then
                            awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Local group contains AD members. Will NOT migrate to LSASS Local Provider (GID $newgid < 1000)."
                            add_group_success=0
                        fi

                        if [ $add_group_success -eq 1 ]; then
                            if [ "x$DRYRUN" = "x1" ]; then
                                add_user_success=1
                            else
                                add_users_to_local_provider $MEMBER $NEW_GROUPNAME
                                if [ $? -eq 0 ]; then
                                    add_user_success=1
                                else
                                    add_user_success=0
                                    add_user_error=1
                                fi
                            fi
                        fi
                    fi

                    # Remove AD Users from migrated local groups
                    if [ "x$DO_GROUP_CLEANUP" = "x1" ]; then
                        if ( [ $group_migrated_to_ad -eq 1 ] )  || ( [ $group_migrated_to_ad -eq 0 ] && [ $MOVE2LOCAL -eq 1 ] && [ $add_user_success -eq 1 ] ); then
                            awesomeprint "WRAPPER INFO: group: $NEW_GROUPNAME: Removing AD user $MEMBER."
                            if [ "x$DRYRUN" != "x1" ]; then
                                cp $grp ${grp}.tmp
                                $SED -e "s/^\($NEW_GROUPNAME:.*:.*:\)$MEMBER$/\1/" \
                                -e "s/^\($NEW_GROUPNAME:.*:.*:\)$MEMBER,\(.*\)$/\1\2/" \
                                -e "s/^\($NEW_GROUPNAME:.*:.*:\)\(.*\)$MEMBER,\(.*\)$/\1\2\3/" \
                                -e "s/^\($NEW_GROUPNAME:.*:.*:\)\(.*\),$MEMBER$/\1\2/" ${grp}.tmp > $grp
                                rm ${grp}.tmp
                            fi
                        fi
                    fi
                    group_contains_ad_users=1
                else
                    group_contains_local_users=1
                fi
            done
        fi

        # Handle/Report on group status
        if [ $group_migrated_to_ad -eq 1 ]; then
            if [ $group_contains_ad_users -eq 1 -a $group_contains_local_users -eq 0 ]; then
                if [ "x$DO_GROUP_CLEANUP" = "x1" ]; then
                    awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). All members have been migrated to AD. Deleting local group."
                    delete_local_group $NEW_GROUPNAME
                else
                    #$ECHO "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). All members have been migrated to AD. Local group can be (manually) deleted."
                    #Keeping these separate in case we decide to for different behavior.  For now migrated groups that contained only AD users will always be removed.
                    awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). All members have been migrated to AD. Deleting local group."
                    delete_local_group $NEW_GROUPNAME
                fi
            elif [ $group_contains_ad_users -eq 1 -a $group_contains_local_users -eq 1 ]; then
                if [ "x$DO_GROUP_CLEANUP" = "x1" ]; then
                    awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). Migrated AD members have been removed from local group."
                else
                    awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). Migrated AD members remain in local group."
                fi
            elif [ $group_contains_ad_users -eq 0 -a $group_contains_local_users -eq 1 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). Only local members."
            elif [ $group_contains_ad_users -eq 0 -a $group_contains_local_users -eq 0 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Migrated to $NEW_GROUPNAME (AD). No members."
            fi
        elif [ $group_migrated_to_ad -eq 0 ]; then
            if [ $group_contains_ad_users -eq 1 -a $group_contains_local_users -eq 0 ]; then
                awesomeprint "WRAPPER WARNING: group: $OLD_GROUPNAME: Not migrated to AD. Contains only AD members. This group could be (manually) migrated to AD."
                if [ $MOVE2LOCAL -eq 1 ]; then
                    if [ $add_group_success -eq 1 -a $add_user_error -eq 0 ]; then
                        awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Not migrated to AD. AD members migrated to Local LSASS Provider group."
                    else
                        awesomeprint "WRAPPER WARNING: group: $OLD_GROUPNAME: Not migrated to AD. Problem creating or populating Local LSASS Provider group."
                        awesomeprint "WRAPPER WARNING: group: $OLD_GROUPNAME: Will need to be migrated to AD or have the local GID changed."
                        error `ERR_CHOWN`
                    fi
                fi
            elif [ $group_contains_ad_users -eq 1 -a $group_contains_local_users -eq 1 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Not migrated to AD. Contained local and AD members."
                if [ $MOVE2LOCAL -eq 1 ]; then
                    if [ $add_group_success -eq 1 -a $add_user_error -eq 0 ]; then
                        awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Not migrated to AD. AD members migrated to Local LSASS Provider group."
                    else
                        awesomeprint "WRAPPER WARNING: group: $OLD_GROUPNAME: Not migrated to AD.  Problem creating or populating Local LSASS Provider group."
                        error `ERR_CHOWN`
                    fi
                fi
            elif [ $group_contains_ad_users -eq 0 -a $group_contains_local_users -eq 1 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Not migrated to AD. Only local members."
            elif [ $group_contains_ad_users -eq 0 -a $group_contains_local_users -eq 0 ]; then
                awesomeprint "WRAPPER INFO: group: $OLD_GROUPNAME: Not migrated to AD. No members."
            fi
        fi
    done < $group_accounts
fi

$ECHO "WRAPPER INFO: Copying back updated account files..."
if [ -f $grp ]; then
    # since $grp is processed by sed_expr_build and sed_inline_run, it's procssed by code written by code, so we want a sanity check
    lines=`cat $grp | wc -l`
    if [ $lines -gt 5 ]; then
        if [ "x$DRYRUN" = "x1" ]; then
            $ECHO "WRAPPER INFO: DRYRUN: cp_verbose $grp /etc/group"
            $ECHO "WRAPPER INFO: DRYRUN: cp_verbose $pswd /etc/passwd"
        else
            cp_verbose $grp /etc/group
            cp_verbose $pswd /etc/passwd
        fi
    else
        $ECHO "WRAPPER ERROR: file $grp is less than 5 lines - something went horribly wrong!"
        $ECHO "WRAPPER ERROR: not replacing existing /etc/group file with modified version"
        error `ERR_FILE_ACCESS`
    fi
else
    $ECHO "WRAPPER ERROR: file $grp does not exist - something went horribly wrong!"
    $ECHO "WRAPPER ERROR: not replacing existing /etc/group file with modified version"
    error `ERR_FILE_ACCESS`
fi

if [ -f /etc/gshadow ]; then
    # Needs to be done to re-sync the group shadow file.
    if [ "x$DRYRUN" = "x1" ]; then
        $ECHO "WRAPPER INFO: DRYRUN: /usr/sbin/grpconv"
    else
        $ECHO "WRAPPER INFO: Running grpconv to sync /etc/gshadow ..."
        /usr/sbin/grpconv
        if [ $? -ne 0 ]; then
            $ECHO "WRAPPER WARNING: Error running grpcov to re-sync /etc/gshadow.  Manual cleanup/sync may be required."
        fi
    fi
fi

if [ -f $BACKUP_DIR/privgroup ]; then
    $ECHO "WRAPPER INFO: HP-UX Trusted Mode requires /etc/privgroup to be restored."
    if [ "x$DRYRUN" = "x1" ]; then
        $ECHO "WRAPPER INFO: DRYRUN: cp_verbose $BACKUP_DIR/privgroup /etc/privgroup"
    else
        cp_verbose $BACKUP_DIR/privgroup /etc/privgroup
    fi
fi
#source ./mapcreate-and-chown.sh
fi

# Do removal of local user accounts which may have been migrated to AD
# based on a list of users in a list.
if [ -n "$DO_USERDEL_FILE" ]; then
    psection "MODULE START: PROCESS USER DELETE FILE"
# This block included from: ././userdel-list.sh.
$ECHO "WRAPPER INFO: Reading users from $DEL_USER_LIST to then remove from /etc/passwd."
if [ -f $DEL_USER_LIST ]; then
	for name in `$AWK -F: '{ print $1 }' /etc/passwd | $GREP -w -f $DEL_USER_LIST`; do
		$ECHO "WRAPPER INFO: Deleting $name..."
		userdel $name
		returncode=$?
		if [ $? -ne 0 ]; then
			$ECHO "WRAPPER WARNING: Could not delete $name! Code $returncode"
		fi
	done
        $ECHO "WRAPPER INFO: Completed processing of $DEL_USER_LIST"
else
    $ECHO "WRAPPER WARNING: DO_USERDEL_FILE enabled but $DEL_USER_LIST not found."
fi
fi

# Attempt to unjoin/remove/shutdown Alternate Providers
if [ -n "$DO_ALT_PROVIDER_REMOVE" ] && [ -n "$ALT_PROVIDER_NAMES_INSTALLED" ]; then
    psection "MODDULE START: UNINSTALLING ALTERNATE AUTHENTICATION PROVIDERS."
# This block included from: ././alt-provider-uninstall.sh.


for alt_provider_name in $ALT_PROVIDER_NAMES_INSTALLED; do
    if [ $alt_provider_name = "CENTRIFY" ]; then
        touch $BACKUP_DIR/alt.provider.centrify.removed
        $ECHO "WRAPPER INFO: Uninstalling Centrify..."
        if [ -x /usr/share/centrifydc/bin/uninstall.sh ]; then
            /usr/share/centrifydc/bin/uninstall.sh -n
            ALT_PROVIDER_REMOVE_RESULT=$?
        elif [ $OStype = "linux-rpm" ]; then
            centrify_packages=`rpm -qa |grep CentrifyDC`
            if [ $? -eq 0 ]; then
                rpm -e $centrify_packages
                ALT_PROVIDER_REMOVE_RESULT=$?
            fi
        fi
        if [ $ALT_PROVIDER_REMOVE_RESULT -ne 0 ]; then
            $ECHO "WRAPPER WARNING: Centrify may not be fully uninstalled"
        fi
    fi

    if [ $alt_provider_name = "VAS" ]; then
        # See http://dell.to/1JWlxlr
        $ECHO "WRAPPER INFO: Uninstalling VAS..."
        touch $BACKUP_DIR/alt.provider.vas.removed
        if [ -x vas/install.sh ]; then
            vas/install.sh remove
            ALT_PROVIDER_REMOVE_RESULT=$?
        elif [ $OStype = "linux-deb" ]; then
            dpkg -r vasgp vasclnt
            ALT_PROVIDER_REMOVE_RESULT=$?
        elif [ $OStype = "linux-rpm" ]; then
            rpm -e vasgp vasclnt
            ALT_PROVIDER_REMOVE_RESULT=$?
        fi
        if [ $ALT_PROVIDER_REMOVE_RESULT -ne  0 ]; then
            $ECHO "WRAPPER WARNING: VAS may not be fully uninstalled"
        fi
    fi

    if [ $alt_provider_name = "WINBIND" ]; then
        $ECHO "WRAPPER WARNING: Disabling winbind - restart this on SAMBA servers after running samba-interop-install." 
        touch $BACKUP_DIR/alt.provider.winbind.removed
        servicehandler "disable" "winbind" 
        ALT_PROVIDER_REMOVE_RESULT=$?
        if [ $ALT_PROVIDER_REMOVE_RESULT -ne  0 ]; then
            $ECHO "WRAPPER WARNING: Winbind may not be fully disabled"
        fi
    fi
    if [ $alt_provider_name = "SSSD" ]; then
        # Can't shut down sssd, because it might be used for other non-passwd/group services
        $ECHO "WRAPPER WARNING: Leaving sssd running, in case it handles non-passwd/group services"
        touch $BACKUP_DIR/alt.provider.sssd.removed
    fi

    done
fi

# Check for account maps and run/inform on required Chown operations
if [ -n "$DO_USERDEL" ]; then
    psection "MODULE START: Migrate Data (chown files)"
# This block included from: ././stagemaps-and-chown.sh.
groupmapcmd=""
passwdmapcmd=""

if [ -n "$passwdmap" ] && [ -f $passwdmap ]; then
    lines=`wc -l $passwdmap | $AWK '{ print $1 }'`
    if [ $lines -eq 1 ]; then
        mv $passwdmap $passwdmap.notused
        passwdmapcmd=""
    else
        passwdmapcmd="-u $passwdmap"
    fi
fi

if [ -n "$groupmap" ] && [ -f "$groupmap" ]; then

    lines=`wc -l $groupmap | $AWK '{ print $1 }'`
    if [ "$lines" -eq "1" ]; then
        mv $groupmap $groupmap.notused
        groupmapcmd=""
    else
        groupmapcmd="-g $groupmap"
    fi
fi

if [ -z "$passwdmapcmd" ] && [ -z "$groupmapcmd" ]; then
    $ECHO "WRAPPER INFO: No account map files exist.  Migration (chown) of file data is not required."
else
    $ECHO "WRAPPER INFO: Account map files exist.  Migration (chown) of file data is required for full system migration."
    
    if [ "$ZONEtype" = "sparse" ]; then
        excludefilecmd="-e $DEPLOY_DIR/exclude-solaris-child.txt"
    else
        excludefilecmd="-e $EXCLUDE_FILE"
    fi

    CHOWNDRY=""
    if [ "x$DRYRUN" = "x1" ]; then
        CHOWNDRY="-d"
    fi

    if [ -z "$DO_CHOWN" ]; then
        $ECHO "WRAPPER WARNING: DO_CHOWN not enabled. Run this command when the script is complete:\n"
        $ECHO "$PERL $DEPLOY_DIR/chown-all-files.pl $CHOWNDRY $passwdmapcmd $groupmapcmd $excludefilecmd -v warning -l $OUTFILE_DIR/`hostname`-chown-log-$TODAY.log\n"
    else
        $ECHO "WRAPPER INFO: DO_CHOWN enabled. Now running chown-all-files.pl with command:\n"
        $ECHO "$PERL $DEPLOY_DIR/chown-all-files.pl $CHOWNDRY $passwdmapcmd $groupmapcmd $excludefilecmd -v warning -l $OUTFILE_DIR/`hostname`-chown-log-$TODAY.log\n"
        $PERL $DEPLOY_DIR/chown-all-files.pl $CHOWNDRY $passwdmapcmd $groupmapcmd $excludefilecmd -v warning -l $OUTFILE_DIR/`hostname`-chown-log-$TODAY.log
    fi
fi
fi


# Customer "drop-in" files.  Code to run at wrapper end.
if [ -n "$DO_RUN_CUSTOMER_SCRIPTS" ]; then
    psection "MODULE START: CUSTOMER POST-WRAPPER SCRIPTS"
    # $customer_post_wrapper_script did not exist on build host, expecting customer to provide it.
    if [ -f $customer_post_wrapper_script ]; then
        . $customer_post_wrapper_script
    else
        $ECHO "WRAPPER WARNING: $customer_post_wrapper_script wasn't found, and it was supposed to be included!"
    fi
fi

# Unmount any NFS paths used during install if they were mounted by this script
if [ -n "$DO_NFS_MOUNT" ]; then
    psection "MODULE START: NFS UNMOUNT"
# This block included from: ././nfsumount.sh.
umount $MOUNTPOINT
umounterror=$?
if [ $umounterror -ne 0 ]; then
    pline
    pblank
    pblank
    $ECHO "WARNING: Unmounting $NFSPATH failed with error $umounterror"
    $ECHO "WARNING: Continuing install, please try this command as root manually:"
    $ECHO "umount $MOUNTPOINT"
    pblank
    pblank
else
    rmdir -p $MOUNTPOINT
fi

fi

# Give summary of userdel issues at script completion
USERCLEANUP=`$AWK '/User data can be manually cleaned up/ { getline; print $0; getline; print $0 }' $OUTFILE_PATH`
if [ -n "$USERCLEANUP" ]; then
    $ECHO "WRAPPER WARNING: Failed to userdel one or more users (users logged in?)"
    $ECHO "WRAPPER WARNING: Please clean up the following users by running the below sed commands:"
    pblank
    $ECHO "$USERCLEANUP\n"
fi

psection "COMPLETED RUN of $0"

exit_status $gRetVal

# Revisions:
# 0.1 2008/07/14 Robert Auch Initial from healthcheck and Kaplan's installer
# 0.2 2008/08/20 Robert Auch - Updates for customer (skel, pam_security, backups)
# 0.3 2008/08/22 Robert Auch - backport NIS / SSHD Privsep user from previous script
# 0.4 2008/08/22 Robert Auch - comments, options, usage() (Documentation fix)
# 0.5 2008/09/05 Robert Auch - upgrades, changes to logging options.  not merged with 5.0
# 0.6 2008/10/15 Robert Auch - ldap/winbind/samba related fixups - not merged with 5.0
# 1.0 2008/09/02 Justin Pittman - port to LWISE 5
# 1.5 2008/09/08 Justin Pittman - merge original and port for LWISE 4 & 5 installs
# 1.6 2008/10/06 Yvo van Doorn - cleaning up the commented scripts. they are in svn if you need to reference them
# 2.0 2008/11/04 Robert Auch - modularized the code to prepare merge with 5.0
# 2.1 2008/11/04 Robert Auch - merge 5.0 and 4.1, adding $LW_VERSION to control
# 2.2 2008/11/11 Robert Auch - add require-membership-of and cache
# 2.3 2008/11/14 Robert Auch - add samba32-lw-install.sh integration for samba installs
# 2.4 2008/11/15 Robert Auch - disable SELinux on linux-rpm
# 2.5 2008/12/01 Yvo van Doorn - Removed a ton of bashisms. Started using Solaris 10 as lowest base line test. Added in netgroup support & lsof support. Limited Darwin support (3.0 completeion)
# 2.6 2009/07/27 Robert Auch - add 5.2 through 5.5 support
# 2.7 2010/05/17 Robert Auch - remove disambiguation for 5.x, remove 4.1 code.
# 3.0 2010/07/01 Robert Auch - FreeBSD support. Support finding files in DEPLOYMENTS ISO "agents/" direcotory "pam_ldap" removal under "DO_LDAP"
# 3.1 2010/08/02 Robert Auch - add NFS automount support (including nfs-util install for apt/yum clients)
# 3.5 2010/11/30 Robert Auch - add 6.0 handling, new audit-by-regshell feature, checks for solaris pgk issues, LD_LIBRARY_PATH fixup
# 3.6 2010/11/30 Kyle Stemen - add user-rename function
# 3.7 2010/12/01 Kyle Stemen - add ssh test and pkgchk functions
# 3.8 2010/12/20 Robert Auch - fixed DO_USERDEL overload
# 3.9 2011/01/19 Dean Wills - Fixed issue with USERDEL removing users from /etc/group
# 3.9 2011/02/09 Dean Wills  - add NSCD disable group/passwd cache
# 4.0 2011/01/20 Robert Auch - fixed backup issues, finalize error handling to work properly, fix USER_RENAME to also not remove useres from local groups (by renaming the group lists as well)
# 4.1 and 4.2 2011/08/17 Robert Auch - bugfixes on new usermapping, upgrades from LW4.1 to LW6
# 4.3 2011/10/20 Dean Wills - adjust for winbind/ldap - get directory before delete
# 4.4 2012/01/27 Dean Wills - replaced userdel with migrate (users and groups). deleted user_rename
# 4.5 2012/02/27 Robert Auch - bugfixes for migrate.sh, wording, add ALLOW_SPARSE_INSTALL and DISABLE_YPBIND
# 4.6 2012/03/02 Robert Auch - support 6.5 and 7.0 path renames and package changes.  add floating point math.
# 5.0 2012/04/10 Robert Auch - small bugfixes for floating point math, standardization of new routines, clean up logging
# 5.1 2012/04/20 Robert Auch - userdel issues on Solaris
# 5.2 2012/05/01 Robert Auch - add support for wget pull of required files (removed post 5.12)
# 5.3 2012/08/04 Robert Auch - add backup/restore of HP-UX Trusted Mode users/groups, which were being missed
# 5.5 2014/03/11 Robert Auch - add install via repo, custom changes for large AZ customer
# 5.6 2014/07/21 Robert Auch - fix 5.0 uninstalls, 8.1 installs, and "NONE" for OU means a blank OU
# 5.7 2014/10/09 Robert Auch - increase stability if there's bad data locally (like home of "/home" rather than "/home/username"
# 5.8 2014/11/10 Robert Auch - add registry-settings.sh inclusion, fix up require-membership-of for multiple groups, add handling of "skip_groups.txt" for protectoin
# 5.9 2015/01/13 Robert Auch - add option to install via repo, and an option to link instead of move home directory
# 5.10 2015/04/17 Robert Auch - intelligent OU handling, bugfixes for an Oil customer, pull pbis-input-parameters from /root as well
# 5.11 2015/07/14 Robert Auch - fix solaris '-e' issues again in require-membership-of handling
# 5.12 2015/07/16 Ben Hendin - Added DO_CUSTOM_CONTIG, fixed up PRE/POST.  Added pam_winbind.  Lots of output (re)formatting, informational messages,  and some consolidation of code.
# 5.13 2015/07/23 Ben Hendin - Removed DO_ALT_CONFIG section.  Added DO_ASSUME_DEFAULT_DOMAIN.  More (re)formatting, informational messages,  and some consolidation of code.
# 6.0 2015/09/22 Ben Hendin - Added lwsmd restart prior to account gathering. Added DO_SKIP_LOCAL_UID_CONFLICTS. Fixed various grep to matches for exact (^*$)
#...Skip DO_UNINSTALL when DO_INSTALL is skipped. Added DO_PURGE_ACCOUNT_DATA. Added LSAAUTHTEST in post-join tests. Added LASTJOINCOMMAND.
#...Fixed DO_DEBUG to restart debugging on all lsass restarts.  Fixed NUMBER_OF_DOMAINS to parse get-status output.  Many fixes to add-user.
#...Added create-deploy-files and support for deploy file commends. Added UPDATE_DNS, DELETE_PAM_LINES.  Major overhaul of require-membership-of.sh including REQUIRE_MEMBERSHIP_VALIDATE
#...Removed DO_DCERPCD, DO_SITE_PRECACHE/PRECACHE_DC, and DO_EDIT_LWIAUTHD
# 6.1 2015/09/23 Rob Auch - rewrite fncjoin() to handle spaces and weird OU characters properly. See http://mywiki.wooledge.org/BashFAQ/050
# 6.1.1 2015/10/16 Robert Auch - update add-user.sh to support AIX properly
# 6.1.2 2015/12/29 Ben Hendin - Updated migrate.sh to properly handle local account providers (AIX)
# 6.2.0 2016/01/06 Robert Auch and Ben Hendin - updates for userdel handling, bashism removal, solaris error handling, and others
# 6.2.1 2016/01/27 Ben Hendin - structure updating, more userdel fixes, addition of customer-x-scripts.  Reworked DO_INSTALL/DO_REPO logic. 
# 6.2.2 2016/09/26 Robert Auch - update backup/restore for sss on Ubuntu
# 6.2.3 2016/10/06 Robert Auch - clean up some errors printed to screen unexpectedly
# 6.3.0 2016/11/22 Robert Auch - add sssd as an alternate-provider, RATHER than pam/nss provider
# 6.3.1 2016/12/01 Robert Auch - typo cleanup
# 6.3.2 2017/04/05 Robert Auch - backup /etc/security/access.conf
# 6.4.0 2017/05/09 RObert Auch - rewrite service/daemon restarts to use servicehandler() globally
# 6.5.0 2017/05/17 Robert Auch - force enumeration on for sssd domains for user account gathering
# 6.5.1 2017/07/19 Robert Auch - Add sleep for post-join user lookup errors.
# 6.5.2 2017/09/18 Robert Auch - add /etc/passwd detection before adding user to /etc/pbis/user-ignore
# 6.5.3 2017/09/22 Robert Auch - typo fixes
# 6.5.4 2017/09/28 Robert Auch - fix HPUX installer path detection
# 6.5.5 2017/09/29 Robert Auch - passwd_compat can show up on SUSE now, too!
# 6.6.0 2017/10/12 Robert Auch - AIX servicehandler should be "startsrc" not "initv", or we miss everything EXCEPT lwsmd
