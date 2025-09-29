#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-roboshop/shipping.log
MYSQL_HOST=mysql.prav4cloud.online
START_TIME=$(date +%s)

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

#### java based application ###

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the shipping application"

cd /app &>>$LOG_FILE
VALIDATE $? "Change directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing existing code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Install dependencies"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip the application code"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying systemctl service"

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

dnf install mysql -y &>>$LOG_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE #mysql command to check for dbs exists or not
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting Shipping"

