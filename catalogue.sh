#!/bin/bash

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

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "ERROR:: $2...$R FAILURE $N" | tee -a $LOG_FILE
        exit1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi  
}

#### Installing NodeJS #######

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the catalogue application"

cd /app
VALIDATE $? "Change directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip the application code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying systemctl service"

systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb client"

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load Catalogue Products"
else
    echo -e "Catalogue Products already exists... $Y SKIPPING $N" 
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"