#!/bin/bash 
#Date: 18 Feb 2021
#Author: ILM4zz4
#Purpose: To upload FILEs to AWS S3 via Curl
#Uploads FILE at the top level folder by default

function usage() {

    echo -e " 

Usage: bash $0 [-r <string> -r <string> -f <string> -p string]

   -r : to specify the aws region 

   -b : to specify the the S3_BUCKET name

   -f : to specify the FILE to copy

   -p : to specify the remote forlder

   -l : to specify the local folder

   "
    exit 2 1>&2
    exit 1
}

if [ $# == 0 ]; then
    usage
    echo "Exiting .."
    exit 2
fi

#S3 parameters
S3STORAGETYPE="STANDARD" #REDUCED_REDUNDANCY or STANDARD etc.

LOCAL_PATH="."
REMOTE_PATH=""

while getopts "b:r:p:f:l:d" o; do
    case "${o}" in
    b)
        S3_BUCKET=${OPTARG}
        ;;
    r)
        AWS_REGION=${OPTARG}
        ;;

    f)
        FILE=${OPTARG}
        ;;

    p)
        REMOTE_PATH=${OPTARG}
        ;;

    l)
        LOCAL_PATH=${OPTARG}
        ;;

    d)
        set -x         
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))


function putS3() {

    resource="/${S3_BUCKET}/${REMOTE_PATH}${FILE}"
    contentType="application/x-compressed-tar"
    dateValue=$(date -R)
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=$(echo -en ${stringToSign} | openssl sha1 -hmac ${AWS_SECRET_ACCESS_KEY} -binary | base64)
    curl -X PUT --upload-FILE "${LOCAL_PATH}/${FILE}" \
        -H "Host: ${S3_BUCKET}.s3.amazonaws.com" \
        -H "Date: ${dateValue}" \
        -H "Content-Type: ${contentType}" \
        -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
        https://${S3_BUCKET}.s3.amazonaws.com/${REMOTE_PATH}${FILE}
    echo "FILE correctly uploaded at  https://s3.console.aws.amazon.com/s3/buckets/${S3_BUCKET}?region=us-east-1&prefix=${REMOTE_PATH}"
}

putS3 

