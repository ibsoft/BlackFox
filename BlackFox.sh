#!/bin/bash


#
# Ioannis A. Bouhras -- Block bad reputation IP Addresses from known blacklists
#

#Application NGINX - APACHE HTTP SERVERS

BLACKFOX_HOME=`pwd`
LOGFILE="$BLACKFOX_HOME/logs/blackfox.log"

cat /dev/null >$LOGFILE

echo `dateutil today` " " `date +"%T"`" Starting BlackFox v1.1.">>$LOGFILE

#install my dateutil if not exists

if [ -f "/usr/bin/dateutil" ] ; then
	{
	echo "`dateutil today` " " `date +"%T"` Dateutil installed.">>$LOGFILE
	}
     else
	{
      echo "`dateutil today` " " `date +"%T"` Toolset not found, installing dateutil.">>$LOGFILE
	  cd dateutil
	  make clean
	  make
	  cp dateutil /usr/bin/ 
	}
fi



#Source config file

echo  "`dateutil today` " " `date +"%T"` Reading config file.">>$LOGFILE

. config

function validate_url(){
  if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then echo "0";else echo "1"; fi
}

#generating config of active providers

echo "`dateutil today` " " `date +"%T"` Generating providers.conf from providers.available.">>$LOGFILE
grep "^[^#;]" providers.available > providers.conf

#total providers
echo "`dateutil today` " " `date +"%T"` `cat providers.available|wc -l` total providers.">>$LOGFILE

#Active providers

echo "`dateutil today` " " `date +"%T"` `cat providers.conf|wc -l` active providers.">>$LOGFILE

#cleaning current 
echo "`dateutil today` " " `date +"%T"` Cleaning existing nginx/blockips.conf.">>$LOGFILE
rm -rf nginx/blockips.conf

echo "`dateutil today` " " `date +"%T"` Cleaning existing apache/htaccess.">>$LOGFILE
rm -rf apache/htaccess
echo "order allow,deny" >apache/htaccess


#Goto queue

echo "`dateutil today` " " `date +"%T"` Entering queue.">>$LOGFILE
cd queue


#
#Generating choise
#

if [ "$GENERATE_FROM_CURRENT" == "no" ]
then
    {

#clean queue
echo "`dateutil today` " " `date +"%T"` Cleaning queue.">>$LOGFILE

rm -rf *


echo "`dateutil today` " " `date +"%T"` Fetching ipset from providers.">>$LOGFILE

#reset active prividers log
cat /dev/null >../logs/success-providers.log

while read p; do
	
	validate=$(validate_url $p)

	if [[ "$validate" == "0" ]]
       	then
		{
		  mkdir -p $p
		  echo "`dateutil today` " " `date +"%T"` Downloading $p.">>$LOGFILE
		  timeout -s KILL 60 wget -p $p $p
		  echo $p >>../logs/success-providers.log
		}
    else
        {
        echo "`dateutil today` " " `date +"%T"` Provider $p not active.">>$LOGFILE
        }
	fi
done <../providers.conf 

echo "`dateutil today` " " `date +"%T"` Fetching providers completed.">>$LOGFILE


#test if queue is empty

if test "$(ls -A "../queue")"; then
    {

    echo "`dateutil today` " " `date +"%T"` Generating  IP Address sets.">>$LOGFILE


for file in `ls -d */`
do
	if [ "$NGINX" == "yes" ]
	then
	{
	extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny "$2";"}'>>../tmp/nginx-ipset.tmp`)
	sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
	}
	fi

	if [ "$APACHE" == "yes" ]
	then
	{
	extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny from "$2""}'>>../tmp/apache-ipset.tmp`)
	sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
	}
	fi
done

if [ "$NGINX" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Apache.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Generation of nginx blockips.conf completed.">>$LOGFILE

    }
fi

if [ "$APACHE" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Nginx.">>$LOGFILE
       echo "allow from all" >>../apache/htaccess
       echo "`dateutil today` " " `date +"%T"` Generation of apache htaccess completed.">>$LOGFILE

    }
fi


echo "`dateutil today` " " `date +"%T"` Removing temp ipsets.">>$LOGFILE


rm -rf ../tmp/nginx-ipset.tmp
rm -rf ../tmp/apache-ipset.tmp


echo "`dateutil today` " " `date +"%T"` Completed.">>$LOGFILE
}
else
    {
      echo "`dateutil today` " " `date +"%T"` Could not download lists from providers.">>$LOGFILE
      exit 1
    }
fi


}
else
    {

#
# Genarate from current
#

 if test "$(ls -A "../queue")"; then
     {
 

 echo "`dateutil today` " " `date +"%T"` Generating from current ipsets.">>$LOGFILE
 
 
 for file in `ls -d */`
 do
     if [ "$NGINX" == "yes" ]
     then
     {
     extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny "$2";"}'>>../tmp/nginx-ipset.tmp`)
     sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
     }

     fi
 
     if [ "$APACHE" == "yes" ]
     then
     {
     extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0- 9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny from "$2""}'>>../tmp/apache-ipset.tmp`)
     sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
     }
     fi
 done

 if [ "$NGINX" == "yes" ]; then
     {
        echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Apache.">>$LOGFILE
        echo "`dateutil today` " " `date +"%T"` Generation of nginx blockips.conf completed.">>$LOGFILE

     }
 fi

 if [ "$APACHE" == "yes" ]; then
     {
        echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Nginx.">>$LOGFILE
        echo "allow from all" >>../apache/htaccess
        echo "`dateutil today` " " `date +"%T"` Generation of apache htaccess completed.">>$LOGFILE

     }
 fi


 echo "`dateutil today` " " `date +"%T"` Removing tmp ipsets.">>$LOGFILE
 
 rm -rf ../tmp/nginx-ipset.tmp
 rm -rf ../tmp/apache-ipset.tmp
 
 echo "`dateutil today` " " `date +"%T"` Completed.">>$LOGFILE


}
 else
     {
       echo "`dateutil today` " " `date +"%T"` Could not download lists from providers.">>$LOGFILE
       exit 1
     }
 fi

   }
 fi




cd ..
