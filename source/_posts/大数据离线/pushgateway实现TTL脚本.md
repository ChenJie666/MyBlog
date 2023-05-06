---
title: pushgateway实现TTL脚本
categories:
- 大数据离线
---
```
trap 'echo "got sigterm" ; exit 0' SIGTERM

EXPIRATION_SECONDS=${EXPIRATION_SECONDS:-900}
PGW_URL=${PGW_URL:-http://192.168.1.1:9091}

#function convert_to_standardnotation(){
#    # convert number from scientific notation to standar d( ie  '1.5383780136826127e+09' )
#    printf '%.0f' $1
#}

function convert_to_standardnotation() {
    # convert number from scientific notation to standard( ie  '1.5383780136826127e+09' )
    echo $1 | awk '{printf("%.0f", $1)}'
}

function extract_pushgateway_variable(){
 local -r _METRIC=$1
 local -r _VARNAME=$2
 #echo 'push_time_seconds{instance="10.32.32.7",job="bk_jenkins"} 1.5383802210997093e+09' | sed -r 's/.*instance="([^"]*).*/\1/g'
 echo $_METRIC | sed -r "s/.*${_VARNAME}=\"([^\"]*).*/\1/g"
 # sample usage :
 # extract_pushgateway_variable 'push_time_seconds{instance="10.32.32.7",job="bk_jenkins"} 1.5383802210997093e+09' 'instance'
}

function check_metric_line(){
    local -r _line=$1
    METRIC_TIME=$(echo $_line | awk '{print $2}' )
    #echo "mtime = $_line -> $METRIC_TIME "
    METRIC_TIME=$(convert_to_standardnotation $METRIC_TIME)
    #echo "$CURRENT_TIME - $METRIC_TIME "
    METRIC_AGE_SECONDS=$((CURRENT_TIME-METRIC_TIME))

    if [ "$METRIC_AGE_SECONDS" -gt "$EXPIRATION_SECONDS" ]; then

        metricInstance=$(extract_pushgateway_variable "$_line" 'instance')
        metricJob=$(extract_pushgateway_variable "$_line" 'job')
    
        echo "[INFO] job should be deleted $metricJob  - $metricInstance  age: $METRIC_AGE_SECONDS "
    #  curl -s -X DELETE "$PGW_URL/metrics/job/${metricJob}/instance/${metricInstance}"
        curl -s -X DELETE "$PGW_URL/metrics/job/${metricJob}"
    fi


}


function check_expired_metric_loop(){

    export CURRENT_TIME=$(date +%s)
    METRICS_LIST=$(curl -s  $PGW_URL/metrics | egrep "^push_time_seconds")
    echo "$METRICS_LIST" | while  read -r line || [[ -n "$line" ]]; do
        check_metric_line "$line"
    done
    sleep $((EXPIRATION_SECONDS / 3 ))

}
while : ; do
check_expired_metric_loop
done 
```
