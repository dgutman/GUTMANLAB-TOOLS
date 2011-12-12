#!/bin/bash
# Author: Aditya Siram
# Date:   06/23/2010
#
# Script to upload DICOM data
# Arguments: $1=PROJECT_ID, $2=SUBJECT_ID, $3=SESSION_ID, $4=FOLDER $5=HOST, $6=USER $7=PASSWORD

PROJECT=$1
SUBJECT=$2
EXPERIMENT_ID=$3
ZIP_FILE=$4
HOST=$5
USER=$6
PASSWORD=$7

# Create subject (in case it doesn't exist)
echo "Creating Subject:"
subj=$(curl -u $USER:$PASSWORD -X PUT $HOST/data/archive/projects/$PROJECT/subjects/$SUBJECT)
echo " "

# Create session (in case it doesn't exist)
#echo "Creating Session:"
#sess=$(curl -u $USER:$PASSWORD -X PUT $HOST/data/archive/projects/$PROJECT/subjects/$SUBJECT/experiments/$EXPERIMENT_ID?xsiType=xnat:mrSessionData)
#echo " "

zip="$ZIP_FILE"

#echo "Creating $zip:" 
#for FILE in $(find $FOLDER -name "*")
#do
#    if [ "$(file -b $FILE)" == "DICOM medical imaging data" ];
#    then
#	zip -rq $zip $FILE
#     fi
#done

echo " "
echo "Uploading zip"
curl -u $USER:$PASSWORD --data-binary @$zip "$HOST/data/services/import?project=$PROJECT&subject=$SUBJECT&session=$EXPERIMENT_ID&overwrite=append&autoarchive=true&inbody=true" -H "Content-Type:application/zip"
echo " "

echo "Done uploading dicom zip $zip"
