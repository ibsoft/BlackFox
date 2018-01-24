#!/bin/bash

cd /home/ioannisb/bin/BlackFox/

#
# Ioannis A. Bouhras -- Block bad reputation IP Addresses from known blacklists
#

#Application NGINX - APACHE HTTP SERVERS

BLACKFOX_HOME=`pwd`
LOGFILE="$BLACKFOX_HOME/logs/blackfox.log"


export BLACKFOX_HOME=$BLACKFOX_HOME


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
	  make
	  cp dateutil /usr/bin/
      cd ..
	}
fi



#Source config file

echo  "`dateutil today` " " `date +"%T"` Reading config file.">>$LOGFILE

. config

#Download ipsets for countries

if [ $DOWNLOAD_ZONES == "yes" ] ; then
{

rm -rf country-zones/*.zone

timeout -s KILL 60 wget --trust-server-names -p country-zones http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz

cd country-zones

tar xvzf all-zones.tar.gz

cd ..

}

fi


#validate is url is active
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

echo "`dateutil today` " " `date +"%T"` Cleaning existing ufw/user.rules.">>$LOGFILE
rm -rf ufw/user.rules


if [ -f "tmp/ufw-ipset.tmp" ] ; then
{
  rm -rf tmp/ufw-ipset.tmp
}
fi

if [ -f "tmp/nginx-ipset.tmp" ] ; then
{
  rm -rf tmp/nginx-ipset.tmp
}
fi

if [ -f "tmp/apache-ipset.tmp" ] ; then
{
  rm -rf tmp/apache-ipset.tmp
}
fi


if [ -f "ufw/user-deny-countries.rules" ] ; then
{
  rm -rf tmp/user-deny-countries.rules
}
fi

#
#ufw deny country rules generation
#


if [ $UFW_BLOCK_COUNTRIES == "yes" ] ; then
   {

cd $BLACKFOX_HOME


echo "`dateutil today` " " `date +"%T"` Generating UFW Block  rules for countries [ $DENY_COUNTRIES ] ">>$LOGFILE

#reset current

cat /dev/null >ufw/user-deny-countries.rules


for i in $DENY_COUNTRIES
 do
 for ipset in $(cat "country-zones/$i.zone")
   do
   echo "### tuple ### deny any any 0.0.0.0/0 any $ipset in">>ufw/user-deny-countries.rules             
   echo "-A ufw-user-input -s $ipset -j DROP">>ufw/user-deny-countries.rules
   echo "">>ufw/user-deny-countries.rules
 done

done

echo "`dateutil today` " " `date +"%T"` UFW deny counties rules generation completed.">>$LOGFILE


}

fi


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
		  timeout -s KILL 60 wget --trust-server-names -p $p $p
		  echo $p >>../logs/success-providers.log
		}
    else
        {
        echo "`dateutil today` " " `date +"%T"` Provider $p not active.">>$LOGFILE
        }
	fi
done <../providers.conf


echo "`dateutil today` " " `date +"%T"` Unziping files.">>$LOGFILE

find . -name '*.gz' -exec gunzip '{}' \;
 

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
	}
	fi
        

	if [ "$APACHE" == "yes" ]
	then
	{
	extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny from "$2""}'>>../tmp/apache-ipset.tmp`)
	}

	fi

	if [ "$UFW" == "yes" ]
        then
        {
        extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "### tuple ### deny any any 0.0.0.0/0 any"" " $2" ""in"  "\n" "-A ufw-user-input -s"" "$2" " "-j DROP" "\n"  }'>>../tmp/ufw-ipset.tmp `)

        }
        fi
	
        
done

if [ "$NGINX" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
       #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
       awk '!a[$0]++' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
       echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for NGINX.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Generation of nginx blockips.conf completed.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Copying file to NGINX HOME.">>$LOGFILE
       cp $NGINX_HOME/blockips.conf $NGINX_HOME/blockips.conf.blackfoxbak
       cp ../nginx/blockips.conf $NGINX_HOME
       echo "`dateutil today` " " `date +"%T"` Reloading NGINX.">>$LOGFILE
       service nginx reload
    }
fi

if [ "$APACHE" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
       #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
       awk '!a[$0]++' ../tmp/apache-ipset.tmp >>../apache/htaccess
       echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Nginx.">>$LOGFILE
       echo "allow from all" >>../apache/htaccess
       echo "`dateutil today` " " `date +"%T"` Generation of apache htaccess completed.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Copying file to APACHE HOME.">>$LOGFILE
       cp $APACHE_HOME/.htaccess $APACHE_HOME/.htaccess.blackfoxbak
       cp ../apache/htaccess $APACHE_HOME/.htaccess
       service apache2 reload
    }
fi


if [ "$UFW" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
       #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
       cat ../ufw/ufw.header >>../ufw/user.rules
       awk '!a[$0]++' ../tmp/ufw-ipset.tmp >>../ufw/user.rules
       if [ $UFW_BLOCK_COUNTRIES == "yes" ] && [ -f "../ufw/user-deny-countries.rules" ] ; then
       {
          cat ../ufw/user-deny-countries.rules >>../ufw/user.rules
       }
       fi
       cat ../ufw/allow.rules >>../ufw/user.rules
       cat ../ufw/ufw.footer >>../ufw/user.rules
       rules=`cat ../ufw/user.rules|wc -l`
       echo "`dateutil today` " " `date +"%T"` `echo "$rules" | awk '{print int($1/2)}'` Bad reputation IP Addresses generated for UFW.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Generation of UFW Rules completed.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Copying file to UFW HOME.">>$LOGFILE
       cp $UFW_HOME/user.rules $UFW_HOME/user.rules.blackfoxbak
       cp ../ufw/user.rules $UFW_HOME/user.rules
       service ufw restart
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
     }

     fi
 
     if [ "$APACHE" == "yes" ]
     then
     {
     extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0- 9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "deny from "$2""}'>>../tmp/apache-ipset.tmp`)
     }
     fi
     
     if [ "$UFW" == "yes" ]
        then
        {
        extract=$(`rgrep -r -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' $file * |awk -F":" '{print "### tuple ### deny any any 0.0.0.0/0 any"" " $2" ""in"  "\n" "-A ufw-user-input -s"" "$2" " "-j DROP" "\n"  }'>>../tmp/ufw-ipset.tmp `)

        }
        fi

 done

 if [ "$NGINX" == "yes" ]; then
     {
        echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
        #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
        awk '!a[$0]++' ../tmp/nginx-ipset.tmp >>../nginx/blockips.conf
        echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Apache.">>$LOGFILE
        echo "`dateutil today` " " `date +"%T"` Generation of nginx blockips.conf completed.">>$LOGFILE
        echo "`dateutil today` " " `date +"%T"` Copying file to NGINX HOME.">>$LOGFILE
        cp $NGINX_HOME/blockips.conf $NGINX_HOME/blockips.conf.blackfoxbak
        cp ../nginx/blockips.conf $NGINX_HOME
        echo "`dateutil today` " " `date +"%T"` Reloading NGINX.">>$LOGFILE
        service nginx reload


     }
 fi

 if [ "$APACHE" == "yes" ]; then
     {
        echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
        #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
        awk '!a[$0]++' ../tmp/apache-ipset.tmp >>../apache/htaccess
        echo "`dateutil today` " " `date +"%T"` `cat ../nginx/blockips.conf|wc -l` Bad reputation IP Addresses generated for Nginx.">>$LOGFILE
        echo "allow from all" >>../apache/htaccess
        echo "`dateutil today` " " `date +"%T"` Generation of apache htaccess completed.">>$LOGFILE
        echo "`dateutil today` " " `date +"%T"` Copying file to APACHE HOME.">>$LOGFILE
        cp $APACHE_HOME.htaccess $APACHE_HOME.htaccess.blackfoxbak
        cp ../apache/htaccess $APACHE_HOME.htaccess
        service apache2 reload


     }
 fi


 if [ "$UFW" == "yes" ]; then
    {
       echo "`dateutil today` " " `date +"%T"` Removing dublicates.">>$LOGFILE
       #sed '$!N; /^\(.*\)\n\1$/!P; D' ../tmp/apache-ipset.tmp >>../apache/htaccess
       cat ../ufw/ufw.header >>../ufw/user.rules
       awk '!a[$0]++' ../tmp/ufw-ipset.tmp >>../ufw/user.rules
       if [ $UFW_BLOCK_COUNTRIES == "yes" ] && [ -f "../ufw/user-deny-countries.rules" ] ; then
       {
          cat ../ufw/user-deny-countries.rules >>../ufw/user.rules
       }
       fi
       cat ../ufw/allow.rules >>../ufw/user.rules
       cat ../ufw/ufw.footer >>../ufw/user.rules
       rules=`cat ../ufw/user.rules|wc -l`
       echo "`dateutil today` " " `date +"%T"` `echo "$rules" | awk '{print int($1/2)}'` Bad reputation IP Addresses generated for UFW.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Generation of UFW Rules completed.">>$LOGFILE
       echo "`dateutil today` " " `date +"%T"` Copying file to UFW HOME.">>$LOGFILE
       cp $UFW_HOME/user.rules $UFW_HOME/user.rules.blackfoxbak
       cp ../ufw/user.rules $UFW_HOME/user.rules
       service ufw restart
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


