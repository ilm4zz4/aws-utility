#!/bin/bash 
#Date: 18 Feb 2021
#Author: ILM4zz4
#Purpose: To upload files to AWS S3 via Curl
#Uploads file at the top level folder by default

function usage() {

    echo -e " 

Usage: bash $0 [-r <string> -r <string> -f <string> -p string]

   -r : to specify the aws region 

   -b : to specify the the bucket name

   -f : to specify the file to copy

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

while getopts "b:r:p:f:l:" o; do
    case "${o}" in
    b)
        S3BUCKET=${OPTARG}
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
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

#S3 parameters
S3STORAGETYPE="STANDARD" #REDUCED_REDUNDANCY or STANDARD etc.

function putS3() {
    bucket=$1
    remote_path=$2
    file=$3

    resource="/${bucket}/dev/${file}"
    contentType="application/x-compressed-tar"
    dateValue=$(date -R)
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=$(echo -en ${stringToSign} | openssl sha1 -hmac ${AWS_SECRET_ACCESS_KEY} -binary | base64)
    curl -X PUT --upload-file "${LOCAL_PATH}/${file}" \
        -H "Host: ${bucket}.s3.amazonaws.com" \
        -H "Date: ${dateValue}" \
        -H "Content-Type: ${contentType}" \
        -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
        https://${bucket}.s3.amazonaws.com/dev/${file}
    echo "File correctly uploaded at  https://s3.console.aws.amazon.com/s3/buckets/${bucket}?region=us-east-1&prefix=${remote_path}/"
}

putS3 ${S3BUCKET} ${REMOTE_PATH} ${FILE}
