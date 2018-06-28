# 
# DEFAULT_DO_RUN_CUSTOMER_SCRIPTS
# Set to 1
# customer_post_wrapper_script=$DEPLOY_DIR/customer_post_wrapper.sh

#
OSMAJOR=`cat /etc/redhat-release |awk '{print $7}' - |cut -d "." -f1`
SSHD_PATH=/etc/ssh/sshd_config
SYS_AUTH_PATH=/etc/pam.d/system-auth-ac

# Fix the Banner in sshd and restart
f_sshd_fix()
{
grep -q "^Banner \/etc\/issue" $SSHD_PATH
  if [ $? != 0 ]
	then 
	sed -i 's/^#Banner.*/Banner \/etc\/issue/g' $SSHD_PATH
  	if [ $OSMAJOR = 6 ] || [ $OSMAJOR = 5 ]
	  then 
		echo "OS Major is $OSMAJOR" : restarting sshd after changes
		service sshd restart
  	elif [ $OSMAJOR = 7]
	  then 
		echo "OS Major is $OSMAJOR" : restarting sshd after changes
		systemctl restart sshd.service
  	fi
  fi
grep -q "\/etc\/issue.net" $SSHD_PATH
  if [ $? = 0 ]
	then 
	sed -i 's/^#Banner.*/Banner \/etc\/issue/g' $SSHD_PATH
  	if [ $OSMAJOR = 6 ]
	  then 
		echo "OS Major is $OSMAJOR" : restarting sshd after changes
		service sshd restart
  	elif [ $OSMAJOR = 7]
	  then 
		echo "OS Major is $OSMAJOR" : restarting sshd after changes
		systemctl restart sshd.service
  	fi
  fi
}

#Post install put back x bit on semodule (Exadata):

f_semod()
{
if [ ! -x /usr/sbin/semodule ]
	then chmod +x /usr/sbin/semodule
fi
}



# sed -i -e <REMOVAL_REGEX> -e <ADDITION REGEX> <YOUR_PAM_FILE>
# Fix for lsass in system-auth-ac file in password grouping

f_fix_pam()
{
echo "Correcting order of system-auth-ac passwd section"
sed -i -e '/^password[[:space:]]\+sufficient[[:space:]]\+pam_lsass.so/d' -e 's|^password[[:space:]]\+required[[:space:]]\+pam_deny.so$|password    sufficient    pam_lsass.so\npassword    required      pam_deny.so|' $SYS_AUTH_PATH 

}


f_fix_pam
f_sshd_fix

