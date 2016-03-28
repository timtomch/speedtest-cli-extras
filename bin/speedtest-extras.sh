#!/bin/bash
###########################################################################
# Enhances the speedtest-cli command-line interface to speedtest.net
# Output can be exported as CSV, send to an IFTTT Maker channel or to Loggly
#
# Usage:
# speedtest-extras.sh [-d] [-c] [-h] [-i secret-key] [-l]
#    -d: debugging-mode (reuses previously logged speedtest result instead of queriying speedtest - faster)
#    -c: CSV mode
#    -h: Print CSV header (only if used together with the -c flag)
#    -i: IFTTT mode. Takes an IFTTT Maker Channel secret key as argument (required)
#    -l: Loggly mode. Takes a Loggly Customer Token as argument (required)
#
# Originally written by: Henrik Bengtsson, 2014
# https://github.com/HenrikBengtsson/speedtest-cli-extras
# Modified by: Thomas Guignard, 2016
# Inspired by
# http://makezine.com/projects/send-ticket-isp-when-your-internet-drops/
# http://blog.scphillips.com/posts/2015/05/monitoring-broadband-speed-with-loggly/
# License: GPL (>= 2.1) [http://www.gnu.org/licenses/gpl.html]
###########################################################################


# Define functions and global variables

debugmode=false
csvheader=false

start=""
stop=""
from=""
from_ip=""
server=""
server_dist=""
server_ping=""
download=""
upload=""
share_url=""


# Character for separating values when exporting to CSV
# (commas are not safe, because some servers return speeds with commas)
sep=";"

# Temporary file holding speedtest-cli output
# Get directory in which this script lives
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Set location of logfile relative to this directory
log=$DIR/../log/speedtest-extras.log

# Local functions
function str_extract() {
 pattern=$1
 # Extract
 res=`grep "$pattern" $log | sed "s/$pattern//g"`
 # Drop trailing ...
 res=`echo $res | sed 's/[.][.][.]//g'`
 # Trim
 res=`echo $res | sed 's/^ *//g' | sed 's/ *$//g'`
 echo $res
}

############################################################################
# Speedtest
############################################################################

function run-speedtest() {
    
    mkdir -p `dirname $log`
    
    start=`date -u +"%Y-%m-%d %H:%M:%S UTC"`
    
    if test "$debugmode" = true && test -f "$log"; then
    # Reuse existing results (useful for debugging)
        1>&2 echo "** Reusing existing results: $log"
    else
    # Query Speedtest
        speedtest-cli --share > $log
    fi

    stop=`date -u +"%Y-%m-%d %H:%M:%S UTC"`
    
    # Parse
    from=`str_extract "Testing from "`
    from_ip=`echo $from | sed 's/.*(//g' | sed 's/).*//g'`
    from=`echo $from | sed 's/ (.*//g'`

    server=`str_extract "Hosted by "`
    server_ping=`echo $server | sed 's/.*: //g'`
    server=`echo $server | sed 's/: .*//g'`
    server_dist=`echo $server | sed 's/.*\\[//g' | sed 's/\\].*//g'`
    server=`echo $server | sed 's/ \\[.*//g'`

    download=`str_extract "Download: "`
    upload=`str_extract "Upload: "`
    share_url=`str_extract "Share results: "`
}

  ############################################################################
  # CSV Mode
  ############################################################################

function speedtest-csv() {
    # Display header?
    if test "$csvheader" = true; then
      start="start"
      stop="stop"
      from="from"
      from_ip="from_ip"
      server="server"
      server_dist="server_dist"
      server_ping="server_ping"
      download="download"
      upload="upload"
      share_url="share_url"
    else
      run-speedtest
    fi

    # Standardize units?
    #if test "$1" = "--standardize"; then
    #  download=`echo $download | sed 's/Mbits/Mbit/'`
    #  upload=`echo $upload | sed 's/Mbits/Mbit/'`
    #fi
    
    # Output CSV results
    echo $start$sep$stop$sep$from$sep$from_ip$sep$server$sep$server_dist$sep$server_ping$sep$download$sep$upload$sep$share_url
}

############################################################################
# IFTTT Mode
############################################################################
function speedtest-ifttt() {
    secret_key=$1
    
    run-speedtest
    
    # Send results to IFTTT
    value1=`echo $server_ping | cut -d" " -f1`
    value2=`echo $download | cut -d" " -f1`
    value3=`echo $upload | cut -d" " -f1` 
    json="{\"value1\":\"${value1}\",\"value2\":\"${value2}\",\"value3\":\"${value3}\"}"
    curl -s -X POST -H "Content-Type: application/json" -d "${json}" https://maker.ifttt.com/trigger/speedtest/with/key/${secret_key} >/dev/null 
}

############################################################################
# Loggly Mode
############################################################################
function speedtest-loggly() {
    cust_token=$1
    
    run-speedtest
    
    # Send results to Loggly
    json="{\"start\":\"${start}\",\"stop\":\"${stop}\",\"from\":\"${from}\",\"from_ip\":\"${from_ip}\",\"server\":\"${server}\",\"server_dist\":\"${server_dist}\",\"server_ping\":\"${server_ping}\",\"download\":\"${download}\",\"upload\":\"${upload}\",\"share_url\":\"${share_url}\"}"
    curl -s -X POST -H "Content-Type: application/json" -d "${json}" http://logs-01.loggly.com/bulk/${cust_token}/tag/speedtest >/dev/null
}

############################################################################
# Main
############################################################################
# Process arguments
# The flags will be checked in the order they are specified. In order for the script
# to work if optional flags like -d or -h are given after the mode flags, we test for them first.
# 1. Process options
while getopts "dchi:l:" flag; do
    case $flag in
        d)
            # debug mode
            debugmode=true
        ;;
        h)
            # Header will be added to CSV output
            csvheader=true
        ;;
    esac
done

# Restart processing flags
OPTIND=1

# 2. Choose mode and run script
while getopts "dchi:l:" flag; do
    case $flag in
        c)
            # CSV mode
            speedtest-csv
        ;;
        i)
            # IFTTT mode
            speedtest-ifttt $OPTARG
        ;;
        l)
            # Loggly mode
            speedtest-loggly $OPTARG
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
done
