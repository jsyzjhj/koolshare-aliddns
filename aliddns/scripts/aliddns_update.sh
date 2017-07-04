#!/bin/sh

eval `dbus export aliddns_`

if [ "$aliddns_enable" != "1" ]; then
    echo "not enable"
    exit
fi

now=`date`

die () {
    echo $1
    dbus ram aliddns_last_act="$now: failed($1)"
}

[ "$aliddns_curl" = "" ] && aliddns_curl="curl -s whatismyip.akamai.com"
[ "$aliddns_dns" = "" ] && aliddns_dns="223.5.5.5"
[ "$aliddns_ttl" = "" ] && aliddns_ttl="600"

ip=`$aliddns_curl 2>&1` || die "$ip"

current_ip=`nslookup $aliddns_name.$aliddns_domain $aliddns_dns 2>&1`
current_ip1=`nslookup $aliddns_name1.$aliddns_domain1 $aliddns_dns 2>&1`
current_ip2=`nslookup $aliddns_name2.$aliddns_domain2 $aliddns_dns 2>&1`
current_ip3=`nslookup $aliddns_name3.$aliddns_domain3 $aliddns_dns 2>&1`
current_ip4=`nslookup $aliddns_name4.$aliddns_domain4 $aliddns_dns 2>&1`

if [ "$?" -eq "0" ]
then
    current_ip=`echo "$current_ip" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`
    current_ip1=`echo "$current_ip1" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`
    current_ip2=`echo "$current_ip2" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`
    current_ip3=`echo "$current_ip3" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`
    current_ip4=`echo "$current_ip4" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`

    if [ "$ip" = "$current_ip" ] && [ "$ip" = "$current_ip1" ] && [ "$ip" = "$current_ip2" ] && [ "$ip" = "$current_ip3" ] && [ "$ip" = "$current_ip4" ];
    then
        echo "skipping"
        dbus set aliddns_last_act="$now: skipped($ip)"
        exit 0
    fi 
fi


timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c
    do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

send_request() {
    local args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$1.$2&Timestamp=$timestamp"
}

update_record() {
    send_request "UpdateDomainRecord" "RR=$1&RecordId=$2&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$ip"
}

add_record() {
    send_request "AddDomainRecord&DomainName=$1" "RR=$2&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$ip"
}

#add support */%2A and @/%40 record
case  $aliddns_name  in                                                                                                                               
      \*)                                                                                                                                             
        aliddns_name=%2A                                                                                                                             
        ;;                                                                                                                                            
      \@)                                                                                                                                             
        aliddns_name=%40                                                                                                                             
        ;;                                                                                                                                            
      *)                                                                                                                                              
        aliddns_name=$aliddns_name                                                                                                                   
        ;;                                                                                                                                            
esac   

aliddns_record_id=`query_recordid $aliddns_name $aliddns_domain | get_recordid`

if [ "$aliddns_record_id" = "" ]
then
    aliddns_record_id=`add_record $aliddns_domain $aliddns_name | get_recordid`
    echo "added record $aliddns_record_id"
else
    update_record $aliddns_name $aliddns_record_id
    echo "updated record $aliddns_record_id"
fi

sleep 1
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
#add support */%2A and @/%40 record
case  $aliddns_name1  in                                                                                                                               
      \*)                                                                                                                                             
        aliddns_name1=%2A                                                                                                                             
        ;;                                                                                                                                            
      \@)                                                                                                                                             
        aliddns_name1=%40                                                                                                                             
        ;;                                                                                                                                            
      *)                                                                                                                                              
        aliddns_name1=$aliddns_name1                                                                                                                   
        ;;                                                                                                                                            
esac   

aliddns_record_id1=`query_recordid $aliddns_name1 $aliddns_domain1 | get_recordid`

if [ "$aliddns_record_id1" = "" ]
then
    aliddns_record_id1=`add_record $aliddns_domain1 $aliddns_name1 | get_recordid`
    echo "added record $aliddns_record_id1"
else
    update_record $aliddns_name1 $aliddns_record_id1
    echo "updated record $aliddns_record_id1"
fi

sleep 1
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
#add support */%2A and @/%40 record
case  $aliddns_name2  in                                                                                                                               
      \*)                                                                                                                                             
        aliddns_name2=%2A                                                                                                                             
        ;;                                                                                                                                            
      \@)                                                                                                                                             
        aliddns_name2=%40                                                                                                                             
        ;;                                                                                                                                            
      *)                                                                                                                                              
        aliddns_name2=$aliddns_name2                                                                                                                   
        ;;                                                                                                                                            
esac 

aliddns_record_id2=`query_recordid $aliddns_name2 $aliddns_domain2 | get_recordid`

if [ "$aliddns_record_id2" = "" ]
then
    aliddns_record_id2=`add_record $aliddns_domain2 $aliddns_name2 | get_recordid`
    echo "added record $aliddns_record_id2"
else
    update_record $aliddns_name2 $aliddns_record_id2
    echo "updated record $aliddns_record_id2"
fi

sleep 1
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
#add support */%2A and @/%40 record
case  $aliddns_name3  in                                                                                                                               
      \*)                                                                                                                                             
        aliddns_name3=%2A                                                                                                                             
        ;;                                                                                                                                            
      \@)                                                                                                                                             
        aliddns_name3=%40                                                                                                                             
        ;;                                                                                                                                            
      *)                                                                                                                                              
        aliddns_name3=$aliddns_name3                                                                                                                   
        ;;                                                                                                                                            
esac 

aliddns_record_id3=`query_recordid $aliddns_name3 $aliddns_domain3 | get_recordid`

if [ "$aliddns_record_id3" = "" ]
then
    aliddns_record_id3=`add_record $aliddns_domain3 $aliddns_name3 | get_recordid`
    echo "added record $aliddns_record_id3"
else
    update_record $aliddns_name3 $aliddns_record_id3
    echo "updated record $aliddns_record_id3"
fi

sleep 1
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
#add support */%2A and @/%40 record
case  $aliddns_name4  in                                                                                                                               
      \*)                                                                                                                                             
        aliddns_name4=%2A                                                                                                                             
        ;;                                                                                                                                            
      \@)                                                                                                                                             
        aliddns_name4=%40                                                                                                                             
        ;;                                                                                                                                            
      *)                                                                                                                                              
        aliddns_name4=$aliddns_name4                                                                                                                   
        ;;                                                                                                                                            
esac 

aliddns_record_id4=`query_recordid $aliddns_name4 $aliddns_domain4 | get_recordid`

if [ "$aliddns_record_id4" = "" ]
then
    aliddns_record_id4=`add_record $aliddns_domain4 $aliddns_name4 | get_recordid`
    echo "added record $aliddns_record_id4"
else
    update_record $aliddns_name4 $aliddns_record_id4
    echo "updated record $aliddns_record_id4"
fi

# save to file
if [ "$aliddns_record_id" = "" ]; then
    # failed
    dbus ram aliddns_last_act="$now: failed"
else
    dbus ram aliddns_record_id=$aliddns_record_id
    dbus ram aliddns_record_id1=$aliddns_record_id1
    dbus ram aliddns_record_id2=$aliddns_record_id2
    dbus ram aliddns_record_id3=$aliddns_record_id3
    dbus ram aliddns_record_id4=$aliddns_record_id4
    dbus ram aliddns_last_act="$now: success($ip)"
    #web ui show without @.                                                                                                                               
#    if [ "$aliddns_name" = "@" ] ;then                                                                                                                
#        nvram set ddns_hostname_x="$aliddns_domain"                                                                                                   
#        ddns_custom_updated 1                                                                                                                         
#    else                                                                                                                                              
#        nvram set ddns_hostname_x="$aliddns_name"."$aliddns_domain"                                                                                   
#        ddns_custom_updated 1                                                                                                                         
#    fi 
fi
