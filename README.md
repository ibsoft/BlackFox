What is this repository for?

BlackFox is an IT tool written in pure Bash, helping Administrators generate blocking lists for NGINX , Apache server, and UFW Firewall  based on 218 list providers.
    v1.1
    http://blackfox.ibsoft.com.gr

How do I get set up?

    APACHE
    NGINX

Contribution guidelines

Easy to run and setup

Who do I talk to?

Repo owner Ioannis A. Bouhras info@ibsoft.com.gr



NGINX - Setup

Nginx comes with a simple module called ngx_http_access_module to allow or deny access to IP address. The syntax is as follows:

eny IP; deny subnet; allow IP; allow subnet;
block all ips

deny all;
allow all ips

allow all;

How Do I Configure Nginx To Block IPs?

Edit nginx.conf file, enter (note my nginx path is set to /usr/local/nginx/, replace this according to your setup):
cd /usr/local/nginx/conf/
vi nginx.conf

Add the following line in http section:
Block spammers and other unwanted visitors

include blockips.conf;

Save and close the file. Finally, create blockips.conf in /usr/local/nginx/conf/, enter:
vi blockips.conf

Append / add entries as follows:

deny 1.2.3.4; deny 91.212.45.0/24; deny 91.212.65.0/24;

Save and close the file. Test the config file, enter:
/usr/local/nginx/sbin/nginx -t

Sample outputs:

the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok configuration file /usr/local/nginx/conf/nginx.conf test is successful

Reload the new config, enter:
/usr/local/nginx/sbin/nginx -s reload

How Do I Customize HTTP 403 Forbidden Error Messages?

Create a file called error403.html in default document root, enter:
cd /usr/local/nginx/html
vi error403.html

<html> <head><title>Error 403 - IP Address Blocked</title></head> <body> Your IP Address is blocked. If you this an error, please contact webmaster with your IP at webmaster@example.com </body> </html>

If SSI enabled, you can display the client IP easily from the html page itself:

Your IP Address is <!--#echo var="REMOTE_ADDR" --> blocked.

Save and close the file. Edit your nginx.conf file, enter:
vi nginx.conf
redirect server error pages to the static page

error_page 403 /error403.html; location = /error403.html { root html; }

Save and close the file. Reload nginx, enter:
/usr/local/nginx/sbin/nginx -s reload
