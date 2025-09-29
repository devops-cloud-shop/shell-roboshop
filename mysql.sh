#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-roboshop/mysql.log
START_TIME=$(date +%s)

mkdir -p $LOG_FOLDER  # -p creates folder if not exists

echo "Script started execution at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then #checking if the user is root or not
    echo "ERROR:: Please execute the script with root priviledges"
    exit 1
fi

VALIDATE(){                
if [ $1 -ne 0 ]; then 
    echo -e "ERROR:: $2 ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$2... $G SUCCESS $N" | tee -a $LOG_FILE
fi
}

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing mysql server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling mysqld"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting mysql server"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setting up root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME seconds $N"
