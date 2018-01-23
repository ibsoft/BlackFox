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
       cp $APACHE_HOME.htaccess $APACHE_HOME.htaccess.blackfoxbak
       cp ../apache/htaccess $APACHE_HOME.htaccess
       service apache2 reload
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

#Generate ufw rules



declare -A COUNTRY_NAMES='([eu]="European Union" [ap]="African Regional Industrial Property Organization" [as]="American Samoa" [ge]="Georgia" [ar]="Argentina" [gd]="Grenada" [dm]="Dominica" [kp]="North Korea" [rw]="Rwanda" [gg]="Guernsey" [qa]="Qatar" [ni]="Nicaragua" [do]="Dominican Republic" [gf]="French Guiana" [ru]="Russia" [kr]="Republic of Korea" [aw]="Aruba" [ga]="Gabon" [rs]="Serbia" [no]="Norway" [nl]="Netherlands" [au]="Australia" [kw]="Kuwait" [dj]="Djibouti" [at]="Austria" [gb]="United Kingdom" [dk]="Denmark" [ky]="Cayman Islands" [gm]="Gambia" [ug]="Uganda" [gl]="Greenland" [de]="Germany" [nc]="New Caledonia" [az]="Azerbaijan" [hr]="Croatia" [na]="Namibia" [gn]="Guinea" [kz]="Kazakhstan" [et]="Ethiopia" [ht]="Haiti" [es]="Spain" [gi]="Gibraltar" [nf]="Norfolk Island" [ng]="Nigeria" [gh]="Ghana" [hu]="Hungary" [er]="Eritrea" [ua]="Ukraine" [ne]="Niger" [yt]="Mayotte" [gu]="Guam" [nz]="New Zealand" [om]="Oman" [gt]="Guatemala" [gw]="Guinea-Bissau" [hk]="Hong Kong" [re]="Réunion" [ag]="Antigua and Barbuda" [gq]="Equatorial Guinea" [ke]="Kenya" [gp]="Guadeloupe" [uz]="Uzbekistan" [af]="Afghanistan" [hn]="Honduras" [uy]="Uruguay" [dz]="Algeria" [kg]="Kyrgyzstan" [ae]="United Arab Emirates" [ad]="Andorra" [gr]="Greece" [ki]="Kiribati" [nr]="Nauru" [eg]="Egypt" [kh]="Cambodia" [ro]="Romania" [ai]="Anguilla" [np]="Nepal" [ee]="Estonia" [us]="United States" [ec]="Ecuador" [gy]="Guyana" [ao]="Angola" [km]="Comoros" [am]="Armenia" [ye]="Yemen" [nu]="Niue" [kn]="Saint Kitts and Nevis" [al]="Albania" [si]="Slovenia" [fr]="France" [bf]="Burkina Faso" [mw]="Malawi" [cy]="Cyprus" [vc]="Saint Vincent and the Grenadines" [mv]="Maldives" [bg]="Bulgaria" [pr]="Puerto Rico" [sk]="Slovak Republic" [bd]="Bangladesh" [mu]="Mauritius" [ps]="Palestine" [va]="Vatican City" [cz]="Czech Republic" [be]="Belgium" [mt]="Malta" [zm]="Zambia" [ms]="Montserrat" [bb]="Barbados" [sm]="San Marino" [pt]="Portugal" [io]="British Indian Ocean Territory" [vg]="British Virgin Islands" [sl]="Sierra Leone" [mr]="Mauritania" [la]="Laos" [in]="India" [ws]="Samoa" [mq]="Martinique" [im]="Isle of Man" [lb]="Lebanon" [tz]="Tanzania" [so]="Somalia" [mp]="Northern Mariana Islands" [ve]="Venezuela" [lc]="Saint Lucia" [ba]="Bosnia and Herzegovina" [sn]="Senegal" [pw]="Palau" [il]="Israel" [tt]="Trinidad and Tobago" [bn]="Brunei" [sa]="Saudi Arabia" [bo]="Bolivia" [py]="Paraguay" [bl]="Saint-Barthélemy" [tv]="Tuvalu" [sc]="Seychelles" [vi]="U.S. Virgin Islands" [cr]="Costa Rica" [bm]="Bermuda" [sb]="Solomon Islands" [tw]="Taiwan" [cu]="Cuba" [se]="Sweden" [bj]="Benin" [vn]="Vietnam" [li]="Liechtenstein" [mz]="Mozambique" [sd]="Sudan" [cw]="Curaçao" [ie]="Ireland" [sg]="Singapore" [jp]="Japan" [my]="Malaysia" [tr]="Turkey" [bh]="Bahrain" [mx]="Mexico" [cv]="Cape Verde" [id]="Indonesia" [lk]="Sri Lanka" [za]="South Africa" [bi]="Burundi" [ci]="Ivory Coast" [tl]="East Timor" [mg]="Madagascar" [lt]="Republic of Lithuania" [sy]="Syria" [sx]="Sint Maarten" [pa]="Panama" [lu]="Luxembourg" [ch]="Switzerland" [tm]="Turkmenistan" [bw]="Botswana" [jo]="Hashemite Kingdom of Jordan" [me]="Montenegro" [tn]="Tunisia" [ck]="Cook Islands" [bt]="Bhutan" [lv]="Latvia" [wf]="Wallis and Futuna" [to]="Tonga" [jm]="Jamaica" [sz]="Swaziland" [md]="Republic of Moldova" [br]="Brazil" [mc]="Monaco" [cm]="Cameroon" [th]="Thailand" [pe]="Peru" [cl]="Chile" [bs]="Bahamas" [pf]="French Polynesia" [co]="Colombia" [ma]="Morocco" [lr]="Liberia" [tj]="Tajikistan" [bq]="Bonaire, Sint Eustatius, and Saba" [tk]="Tokelau" [vu]="Vanuatu" [pg]="Papua New Guinea" [cn]="China" [ls]="Lesotho" [ca]="Canada" [is]="Iceland" [td]="Chad" [fj]="Fiji" [mo]="Macao" [ph]="Philippines" [mn]="Mongolia" [zw]="Zimbabwe" [ir]="Iran" [ss]="South Sudan" [mm]="Myanmar (Burma)" [iq]="Iraq" [sr]="Suriname" [je]="Jersey" [ml]="Mali" [tg]="Togo" [pk]="Pakistan" [fi]="Finland" [bz]="Belize" [pl]="Poland" [mk]="F.Y.R.O.M." [pm]="Saint Pierre and Miquelon" [fo]="Faroe Islands" [st]="São Tomé and Príncipe" [ly]="Libya" [cd]="Congo" [cg]="Republic of the Congo" [sv]="El Salvador" [tc]="Turks and Caicos Islands" [it]="Italy" [fm]="Federated States of Micronesia" [mh]="Marshall Islands" [by]="Belarus" [cf]="Central African Republic" [cx]="Christmas Island" [xk]="Kosovo" [aq]="Antarctic")'



if [ $UFW == "yes" ] ; then
   {

cd $BLACKFOX_HOME




echo "`dateutil today` " " `date +"%T"` Generating UFW rules.">>$LOGFILE

#reset current

cat /dev/null >ufw/user.rules

cat ufw/ufw.header >>ufw/user.rules


for i in $DENY_COUNTRIES
 do
 for ipset in $(cat "country-zones/$i.zone")
   do
   countryname=""
   if [[ ${COUNTRY_NAMES[$i]} ]]; then
     countryname=${COUNTRY_NAMES[$i]}
   echo "#Country: $countryname">>ufw/user.rules
   echo "### tuple ### deny any any 0.0.0.0/0 any $ipset in">>ufw/user.rules		
   echo "-A ufw-user-input -s $ipset -j DROP">>ufw/user.rules
   echo "">>ufw/user.rules
   fi
 done

done

echo "`dateutil today` " " `date +"%T"` UFW rules generation completed.">>$LOGFILE

cat ufw/ufw.footer >>ufw/user.rules

echo "`dateutil today` " " `date +"%T"` Backing up existing UFW Rules.">>$LOGFILE

cp /etc/ufw/user.rules /etc/ufw/user.rules.blackfoxbak

echo "`dateutil today` " " `date +"%T"` Installing new UFW policy.">>$LOGFILE

cp ufw/user.rules /etc/ufw/user.rules

echo "`dateutil today` " " `date +"%T"` Installation of UFW rules completed.">>$LOGFILE

/usr/sbin/ufw reload

}

fi

cd ..
