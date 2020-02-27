#!/bin/bash

if [[ -f ./queue1.txt && -f ./queue30.txt ]]; then
        rm -rf queue1.txt queue30.txt
fi
echo "####### Verifying rabbitmqadmin command #######"
kubectl.exe exec -it rabbitmq-0 -n rabbitmq-namespace -- /bin/bash -c "if ! [ -x $(command -v rabbitmqadmin) ]; then echo 'rabbitmqadmin command not found, Installing the command' && apt-get update && apt-get install wget python -y && wget https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v3.7.8/bin/rabbitmqadmin && chmod +x rabbitmqadmin && mv rabbitmqadmin /bin/; fi "

echo "####### Finding the message name, message count having publish_rate is 0.0 #######"
for queue0 in `kubectl.exe exec -it rabbitmq-0 -n rabbitmq-namespace -- /bin/bash -c "rabbitmqadmin list queues name messages message_stats.publish_details.rate | sort -t '|' -k3 -nr | sed '/--------/d' | sed '/message_stats/d' | tr -s ' '| sed 's/ //g' | sed 's/^|//g'" 2>/dev/null`
do
        messages_count=`echo $queue0 | cut -d"|" -f2`
        message_rate=`echo $queue0 | cut -d"|" -f3`
        if [ "$messages_count" -gt 0 ] && [ "$message_rate" = "0.0" ] ; then
                        echo $queue0 >> queue1.txt
        fi
done
sleep 30
for queue30 in `kubectl.exe exec -it rabbitmq-0 -n rabbitmq-namespace -- /bin/bash -c "rabbitmqadmin list queues name messages message_stats.publish_details.rate | sort -t '|' -k3 -nr | sed '/--------/d' | sed '/message_stats/d' | tr -s ' '| sed 's/ //g' | sed 's/^|//g'" 2>/dev/null`
do
        messages_count=`echo $queue30 | cut -d"|" -f2`
        message_rate=`echo $queue30 | cut -d"|" -f3`
        if [ "$messages_count" -gt 0 ] && [ "$message_rate" = "0.0" ] ; then
                        echo $queue30 >> queue30.txt
        fi
done

awk -F\| 'FNR==NR{A[$1] = $2; next}($1 in A) && $2 >= A[$1]' queue1.txt queue30.txt
