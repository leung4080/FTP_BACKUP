#!/bin/bash - 
#===============================================================================
#
#          FILE: FTP_BACKUP.sh
# 
#         USAGE: ./FTP_BACKUP.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: LiangHuiqiang(Leung4080@gmail.com) 
#  ORGANIZATION: 
#       CREATED: 2013/2/18 15:42:55 中国标准时间
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
THIS_PID=$$
export LANG=c
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/sbin
SCRIPT_PATH=$(dirname $0);
cd $SCRIPT_PATH


declare -a DATE=`date +%Y%m%d`
declare -a ConfigFile="./FTP_BACKUP.conf"

declare -a Backup_Dir=
declare -a FileName=
declare -a LogFileName=

declare -a FTP_USERNAME=
declare -a FTP_PASSWORD=
declare -a FTP_Dir=

declare -a Local_OldFile_Clean=





#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getConfigVariable
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getConfigVariable(){

#检查配置文件是否存在 
  if [ -f $ConfigFile ] ; then
      source $ConfigFile;  
  else
    echo `date +"%Y-%m-%d %H:%M:%S"`" - [error]: config file not exist!"
     exit 1;
  fi
#检查本地备份目录是否存在
  if [ ! -d $Backup_Dir ] ; then
      mkdir -p $Backup_Dir; 
  fi
#检查FTP服务器备份目录是否存在
  if [ ! -d $FTP_Dir ] ; then
      mkdir -p $FTP_Dir; 
  fi

}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  runBackupCmd
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function runBackupCmd(){
  FILE_NAME=`echo "$FileName"|sed 's/########/'"$DATE"'/g';`
  BACKUP_FILE=$Backup_Dir"/"$FILE_NAME;
  which db_backup  1>/dev/null 2>&1   
  if [ $? -ge 1 ] ; then
    echo `date +"%Y-%m-%d %H:%M:%S"`" - [error]: db_backup not found !"
    exit 1;
  else
    db_backup -dc $BACKUP_FILE  #2>> $LogFileName
  fi

  if [ ! -s $BACKUP_FILE ] ; then
      echo " db_backup failed !"
      exit 1;
  fi
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  putFileToFTP
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function putFileToFTP(){
  echo $FTP_Dir;
  ftp -niv $FTP_IPADDR <<EOF
  user $FTP_USERNAME $FTP_PASSWORD
  binary
  lcd $Backup_Dir
  mkdir  $FTP_Dir
  cd $FTP_Dir
  mput $FILE_NAME
  bye
EOF
  
if [ $Local_OldFile_Clean = "yes" ] || [ $Local_OldFile_Clean = "YES" ] || [ $Local_OldFile_Clean = "1" ]; then
  rm -f $BACKUP_FILE;
fi

}

getConfigVariable;
runBackupCmd;
putFileToFTP;
