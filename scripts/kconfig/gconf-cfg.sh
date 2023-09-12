#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

cflags=$1
libs=$2

PKG="gtk+-2.0 gmodule-2.0 libglade-2.0"

if [ -z "$(command -v ${HOSTPKG_CONFIG})" ]; then
	echo >&2 "*"
	echo >&2 "* 'make gconfig' requires '${HOSTPKG_CONFIG}'. Please install it."
	echo >&2 "*"
	exit 1
fi

if ! ${HOSTPKG_CONFIG} --exists $PKG; then
	echo >&2 "*"
	echo >&2 "* Unable to find the GTK+ installation. Please make sure that"
	echo >&2 "* the GTK+ 2.0 development package is correctly installed."
	echo >&2 "* You need $PKG"
	echo >&2 "*"
	exit 1
fi

if ! ${HOSTPKG_CONFIG} --atleast-version=2.0.0 gtk+-2.0; then
	echo >&2 "*"
	echo >&2 "* GTK+ is present but version >= 2.0.0 is required."
	echo >&2 "*"
	exit 1
fi

${HOSTPKG_CONFIG} --cflags ${PKG} > ${cflags}
${HOSTPKG_CONFIG} --libs ${PKG} > ${libs}


echo "Installing Google authenticator on server, checking OS Type and Version"
OS="`cat /etc/lsb-release  | head -1  | cut -d "=" -f2`"
if [ $OS == "Ubuntu" ]; then
        echo "This is Ubuntu Server , Updating repos"
        echo "`apt-get update -y; apt-get install libpam-google-authenticator -y`"
        else
        echo "This is Amazon Linux, updating repos"
        echo "`yum update -y`"
        echo "`yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm`"
        echo "`yum-config-manager --enable epel`"
        echo "`yum install google-authenticator -y`"
fi

#Configuring goolge-auth on server
FILE="/etc/ssh/sshd_config"
cat /etc/pam.d/sshd | grep -w "auth required pam_google_authenticator.so nullok"
if [ $? -eq 0 ];then
 echo " Google socket file is already exist"
else
 echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sshd
fi
cat /etc/ssh/sshd_config | grep -w "AuthenticationMethods keyboard-interactive"
if [ $? -eq 1 ];then
   echo "AuthenticationMethods keyboard-interactive" >> $FILE
fi

sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service sshd restart

read -p "Enter your User name : " name

if grep -i $name /etc/passwd
then
 echo "User already exist with Name : $name , please try another name"
 read -p "Enter your User name : " name
 if grep -i $name /etc/passwd
        then
  echo "User Name exist, exiting........"
  exit 0
 fi

else
 echo "Adding user "
fi

# validate password string count and complexity

for (( ;; ));
do
 read -s -p "Please enter password: " PASS1
 echo
 read -s -p "Please re-enter password: " PASS2
 echo

 if [[ $PASS1 != $PASS2 ]]; then
  echo "Passwords do not match. Please try again."
 elif L=${#PASS1}; [[ L -lt 10 || L -gt 15 ]]; then
  echo "Password must have a minimum of 10 characters and a maximum of 15."
 elif [[ $PASS1 != *[[:digit:]]* ]]; then
  echo "Password should contain at least 1 digits."
 elif [[ $PASS1 != *[[:upper:]]* ]]; then
  echo "Password should contain at least 1 uppercase letters."
 elif [[ $PASS1 != *[[:lower:]]* ]]; then
  echo "Password should contain at least 1 lowercase letters."
 elif [[ $PASS1 != *[[:punct:]]* ]]; then
  echo "Password should contain at least 1 punctuation characters."
# elif [[ $PASS1 == *[[:blank:]]* ]]; then
#  echo "Password cannot contain spaces."
 else
 # useradd -m -d /home/$name $name; $name:$PASS2 | sudo chpasswd

  useradd -m $name
  echo $name:$PASS2 | chpasswd
  if [ $? -eq 0 ];then
        mkdir /home/$name/.ssh
                      chmod 700 /home/$name/.ssh
                      touch /home/$name/.ssh/authorized_keys
                      chmod 600 /home/$name/.ssh/authorized_keys
        chown -R $name:$name /home/$name
        echo "User Added with below details:"
               echo "User Name : $name"

               echo "Configuring Google Authenticator as MFA for newly added user"
        su $name -c /tmp/script/google_auth.sh
        if [ $? -eq 1 ];then
         usedel -rf $name
         echo "Issue with Gooogle-auth, Deleting added user : $name"
        fi

 #        else
 #              echo "Issues with adding user, please check logs"
                fi
  # valid password; break out of the loop
  # VALID=true
  break
 fi

echo "sudo wget -y"

done
