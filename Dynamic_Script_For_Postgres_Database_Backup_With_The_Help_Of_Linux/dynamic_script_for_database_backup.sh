#!/bin/bash

echo "Enter server ip!!!"
read ip
echo "************************************************"
echo "Enter the port number!!!"
read port
echo "************************************************"
echo "Enter database name!!!"
read databasename
echo "************************************************"
echo "Enter the user name who have database backup permission!!!"
read user
echo "------------------------------------------------------------------------------------"


# PostgreSQL Database Backup cmd
pg_dump -h $ip -U $user -p $port -d $databasename > $HOME/$databasename$(date +_%Y_%m_%d).sql 


#find 0 kb file on $HOME and remove that backup file if exists

sudo find $HOME -size 0k | grep -i $databasename$(date +_%Y_%m_%d).sql && sudo rm $HOME/$databasename$(date +_%Y_%m_%d).sql

if test -e $HOME/$databasename$(date +_%Y_%m_%d).sql  
then
	echo "Backup Successful,check your Home Directory for file"
else
	echo "Backup Failed"
fi

