#!/bin/sh

# Script that sets up the elasticsearch trollbox index. it depends on
# two environment variables: ES_HOST and ES_PORT. By default
# ES_HOST=http://localhost and ES_PORT=9200.



if [ -z "$ES_HOST" ]; then
    ES_HOST="http://localhost"
fi

if [ -z "$ES_PORT" ]; then
    ES_PORT="9200"
fi

ES_ADDRESS="${ES_HOST}:${ES_PORT}"

echo "Adding btce mapping to the datafeed index at address ${ES_ADDRESS}..."

curl -XPUT "${ES_ADDRESS}/datafeed/_mapping/btce_message" -d @- -H 'Content-Type: application/json' <<EOF
{
"properties": {
  "receivedTimestamp": { "type" : "date" },
  "btceTime": {"type" : "date"},
  "btceMsgId": { "type" : "long" },
  "btceUsername": { "type" : "keyword" },
  "message": { "type" : "text" }
}
}
EOF
