#!/usr/bin/env bash
# 2023-08-09 P.E.Smit - add memory check Load > 2.0 and mem <20%, add --log and --test
# Cron: # * * * * *  /home/<user>/cron-log-cpu.sh --log /home/<user>/cpu_usage.log
#
SHORT=l:,t
LONG=log:,test
OPTS=$(getopt --alternative --name load-log --options $SHORT --longoptions $LONG -- "$@")
eval set -- "$OPTS"
#
flagtest="false"
log_file="cpu_usage.log"
#
while :
do
    case "$1" in
        -l | --log )
            log_file="$2"
            shift 2
        ;;
        -t | --test | -test )
            echo "# Test mode, use test input from /test/"
            flagtest="true"
            shift
            ;;
        --)
            shift;
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done
#
## meminfo=$(cat test/proc_meminfo.txt)
if [[ "${flagtest}" == "true" ]]; then
    meminfo=$(cat test/proc_meminfo.txt)
    loadavg="$(cat test/loadavg.txt)"
else
    meminfo=$(cat /proc/meminfo)
    loadavg="$(cat /proc/loadavg)"
fi
#
#
mem_total="$( echo "$meminfo"     | grep MemTotal     | awk '{ print $2 }' | sed 's/^\s*\|\s*$//g')"
mem_available="$( echo "$meminfo" | grep MemAvailable | awk '{ print $2 }' | sed 's/^\s*\|\s*$//g')"
#
#
mem_pct=$( echo "scale=2; 100.0 * $mem_available / $mem_total" | bc )
[[ "${flagtest}" == "true" ]] && echo "DEBUG: mem_total=$mem_total , mem_available=$mem_available , mem_pct=$mem_pct%, loadavg=$( echo "$loadavg" | awk '{ print ($1) }' )"
#
if  [[ $( echo "$loadavg" | awk '{ print ($1 > 2.0) }' ) -eq 1 ]] ||
    [[ $( echo "$mem_pct" | awk '{ print ($1 < 20 ) }' ) -eq 1 ]];
then
    # top remove -c and -w not available on mac or busybox
    [[ "${flagtest}" == "true" ]] && echo "DEBUG: Test mode, log triggered"
    ( echo; date -Iseconds; echo "mem_pct_available=${mem_pct}%"; COLUMNS=500 top -b -n1 -H -c -w | head -n 12 | grep -v "^$" ) >> ${log_file}
else
    # Check if last update as Low loadave in last hour, should start with date
    if [[ -f ${log_file} ]] && tail -n 2 ${log_file} | grep -q "^$( date -Iseconds | cut -c1-13)" > /dev/null; then
        :
    else
        [[ "${flagtest}" == "true" ]] && echo "DEBUG: Update after 1h, log marker."
        echo
        echo "$( date -Iseconds ) Low loadavg 1,5,15min $( cat /proc/loadavg ) ,mem_pct_available=${mem_pct}%" >> ${log_file}
    fi
fi

# The END
