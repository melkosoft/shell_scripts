#!/usr/bin/env bash
set -o nounset
set -eo pipefail

CONVERT=$(which ebook-convert)
ETAG=pdf
OPTIONS=--enable-heuristics
REGEXP="-(pdf|epub|azw3|mobi)"
CNT=0
usage () {
 echo "Usage: $0 [-format]  [flist] "
 echo "   -format    - output format: ${REGEXP//|/,} (default: -pdf)"
 echo "    flist     - list of files to convert or read list from stdin"
 echo
 exit 0
}
convert() {
	((CNT++))
	EDIR=$(dirname "$1")
	EBOOK=$(basename "$1")
	ENAME=${EBOOK%.*}
	EEXT=${1##*.}
	echo "Converting $EBOOK..."
	if [ "$EEXT" != "$ETAG" ]; then
        	$CONVERT "$1" "$EDIR/$ENAME.$ETAG" $OPTIONS
        fi
}
while (( "$#" )); do
	if [[ $1 =~ $REGEXP ]]; then
		ETAG=${1##-}

		shift
		continue
	fi
	case "$1" in
           --)    
		shift
		break
		;;
           -*)
	      echo "Unsupported flag"
	      exit 1
	      ;;
	   *)
              convert "$1"
	      shift
	      ;;
	esac
done
while read -t 1 -r fullname
do
	convert "$fullname" 
done
if [[ $CNT = "0" ]]; then
	usage
	exit 0
fi
