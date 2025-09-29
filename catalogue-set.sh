#!/bin/bash
set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR 

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.prav4cloud.online
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-roboshop/catalogue.log

mkdir -p $LOG_FOLDER 

echo "Script started execution at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run the script with root priviledges"
    exit 1
fi

#### Installing NodeJS #######

dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
echo -e "Installing NodeJS 20... $G SUCCESS $N"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE

cd /app

rm -rf /app/*

unzip /tmp/catalogue.zip &>>$LOG_FILE

npm install &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE
echo -e "Catalogue application setup... $G SUCCESS $N"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongoshf -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.prav4cloud.online --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Catalogue Products already exists... $Y SKIPPING $N" 
fi
systemctl restart catalogue
echo -e "Loading products and restarint catalogue ... $G SUCCESS $N"