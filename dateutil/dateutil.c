/*
 * dateutil
 *
 * Manipulates dates
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

//#define DEBUG
//#define DEBUG2

char *Months[] = {
"Jan", "Feb", "Mar", "Apr", "May", "Jun",
"Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

int Date_Format=0;

int get_year(int *yy)
{
        struct tm *tm;
        time_t ltime;

        time( &ltime );
        tm = localtime( &ltime );

        *yy = tm->tm_year;
        if (*yy < 1900)
                *yy += 1900;

        return 1;
}

int get_datetime(char *sdate, char *stime)
{
        struct tm *tm;
        time_t ltime;
        int yy;

        time( &ltime );
        tm = localtime( &ltime );

        yy = tm->tm_year;
        if (yy < 1900)
                yy += 1900;

        sprintf(sdate, "%02d/%02d/%04d",
                tm->tm_mday, tm->tm_mon+1, yy);
        sprintf(stime, "%02d:%02d:%02d",
                tm->tm_hour, tm->tm_min, tm->tm_sec);

        return 1;
}

/*
 * input data is in YYYYMMDD format. Returns y,m,d as integers
 */
int parse_normalized_date(char *sdate, int *y, int *m, int *d)
{
	char str[9];

	if (strlen(sdate) != 8)
		return 0;

	memcpy(str, sdate, 4);
	str[4] = 0;
	*y = atoi(str);

	memcpy(str, &sdate[4], 2);
	str[2] = 0;
	*m = atoi(str);

	memcpy(str, &sdate[6], 2);
	str[2] = 0;
	*d = atoi(str);

	return 1;
}

int parse_date(char *dat_in, char *dat)
{
	const char delm[] = "-/. ";
	char s[32], *p;
	int fmt_ymd, i, j, found, a, b, c, yy, mm, dd;

#ifdef DEBUG2
	printf("parse_date(%s)\n", dat_in);
#endif
	strncpy(s, dat_in, 31);
	s[31] = 0;

	/* check for date in the form "Nov 19" or "19 Nov" */
	found = 0;
	for (i=0; i<12; i++)
	{
		if ((p = strstr(s, Months[i])) != NULL)
		{
			found = 1;
			break;
		}
	}
	if (found)
	{
		j = p - s;
		if (j == 0)
		{
			mm = i+1;
			sscanf(&p[4], "%d", &dd);
		}
		else
		{
			sscanf(s, "%d", &dd);
			mm = i+1;
			sscanf(&p[4], "%d", &yy);
		}

		if (yy == 0)
		{
			get_year(&yy);
		}

		goto done;
	}

	/* date is in numerical form YYYY-MM-DD */
	if (strchr(s, '-') != NULL)
		fmt_ymd = 1;
	else
		fmt_ymd = 0;
        
	/* date is in numerical form MM/DD/YYYY */
	p = strtok(s, delm);
	if (!p) return 0;
	a = atoi(p);

	p = strtok(NULL, delm);
	if (!p) return 0;
	b = atoi(p);

	p = strtok(NULL, delm);
	if (!p) return 0;
	c = atoi(p);

	if (fmt_ymd || a > 1900) 
	{
		yy = a;
		mm = b;
		dd = c;
	} 
	else 
	{
		dd = a;
		mm = b;
		yy = c;
	}

done:

	if (yy < 100 && yy >= 70)
		yy += 1900;
	else if (yy < 70)
		yy += 2000;

	sprintf(dat, "%04d%02d%02d", yy, mm, dd);

#ifdef DEBUG2
	printf("(%s)\n", dat);
#endif
	return 1;
}

/*
 * converts date from human format to Unixdate format
 */
int str2unixdate(char *sdate, int *udate)
{
	char norm_date[9];
	int y, m, d;
	struct tm when;
	time_t secs;

	if (!parse_date(sdate, norm_date))
		return 0;

	if (!parse_normalized_date(norm_date, &y, &m, &d))
		return 0;

	memset(&when, 0, sizeof(when));
	when.tm_year = y - 1900;
	when.tm_mon = m - 1;
	when.tm_mday =  d;
	if ((secs = mktime(&when)) == (time_t)-1)
		return 0;

	*udate = secs;

	return 1;
	
}

int today(char *sdate2)
{
    char sdate[12], stime[12], sdate1[12];
    int y, m, d;
    
    get_datetime(sdate, stime);
    parse_date(sdate, sdate1);
    parse_normalized_date(sdate1, &y, &m, &d);
    
    if (Date_Format == 0)
        sprintf(sdate2, "%04d-%02d-%02d", y, m, d);
    else
        sprintf(sdate2, "%02d/%02d/%04d", d, m, y);

    return 1;
}

int date_add(char *sdate, int days, char *sdate2)
{
	char norm_date[9];
	int y, m, d;
	struct tm when, *newtime;
	time_t secs, secs2;

	if (!parse_date(sdate, norm_date))
		return 0;

	if (!parse_normalized_date(norm_date, &y, &m, &d))
		return 0;

	memset(&when, 0, sizeof(when));
	when.tm_year = y - 1900;
	when.tm_mon = m - 1;
	when.tm_mday =  d;
	if ((secs = mktime(&when)) == (time_t)-1)
		return 0;

	secs2 = secs + days*1440*60;
	newtime = localtime(&secs2);

	if (Date_Format == 0)
	    sprintf(sdate2, "%04d-%02d-%02d",
		newtime->tm_year+1900, newtime->tm_mon+1, newtime->tm_mday);
	else
	    sprintf(sdate2, "%02d/%02d/%04d",
		newtime->tm_mday, newtime->tm_mon+1, newtime->tm_year+1900);

	return 1;

}


void usage(char *progname)
{
	printf("usage: %s <operation> [<arguments> ...]\n", progname);
	printf("operations:\n");
	printf("    unix <date>        - returns unix date\n");
	printf("    add <date> <days>  - adds days to given date\n");
	printf("    today [<days>]     - adds days to today's date (if days not specified, returns today's date)\n");
	printf("format:\n");
	printf("    <date> : YYYY-MM-DD or DD/MM/YY[YY] or DD.MM.YY[YY]\n");
	printf("    <days> : integer (may be negative)\n");
}

int main(int argc, char *argv[])
{
	int udate, days;
	char sdate[12], sdate0[12];

	if (argc < 2)
		goto err;

	if (argc == 3 && strcmp(argv[1], "unix") == 0)
	{
		udate = 0;
		if (!str2unixdate(argv[2], &udate))
			goto err;
		fprintf(stdout, "%d\n", udate);
	}
	else if (argc == 4 && strcmp(argv[1], "add") == 0)
	{
		days = atoi(argv[3]);
		if (!date_add(argv[2], days, sdate))
			goto err;
		fprintf(stdout, "%s\n", sdate);
	}
	else if ((argc == 2 || argc == 3) && strcmp(argv[1], "today") == 0)
	{
	    if (argc == 3)
		days = atoi(argv[2]);
	    else
		days = 0;
		
	    if (!today(sdate0))
		goto err;
	    if (!date_add(sdate0, days, sdate))
		goto err;
	    fprintf(stdout, "%s\n", sdate);	
	}
	else
		goto err;

	return 0;

err:
	usage(argv[0]);
	return 1;
}
