#!/usr/bin/env python
import os
import btceapi
import time
import math
import sys
import datetime
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk

print("Starting BTCE client\n")


if not ("ELASTICSEARCH_HOST" in os.environ):
    print("WARN: No elasticsearch host given. Using http://localhost instead", file=sys.stderr)

host = os.environ.get("ELASTICSEARCH_HOST", "http://localhost")
port = os.environ.get("ELASTICSEARCH_PORT", "9200")
address = host + ":" + port
print("INFO: Connecting to Elasticsearch host at %s" % address)

es = Elasticsearch([address])


with btceapi.BTCEConnection() as connection:
    info = btceapi.APIInfo(connection)

    delay = None

    def processed_messages():
        """Scrape BTCE and process each message"""

        global delay

        mainPage = info.scrapeMainPage()
        receivedTimestamp = math.floor(time.time())
        messages = mainPage.messages;


        firstTs = None
        lastTs = None

        for message in messages:
            msgId, user, btceTime, text = message
            doc = {
                '_index': 'datafeed',
                '_type': 'btce_message',
                '_id': msgId,
                'message': text,
                'btceUsername': user,
                'btceTime': btceTime,
                'receivedTimestamp':receivedTimestamp
            }
            #print("%s: %s %s: %s" % (msgId, btceTime, user, text))
            yield doc

            if firstTs is None:
                firstTs = btceTime
            lastTs = btceTime

        #Compute timedelta between first and last message
        if firstTs is None:
          #No messages in this period. Best write a warinng
          print("No new messages captured", file=sys.stderr)

        delta = lastTs - firstTs;
        secs = delta.total_seconds()

        # Insurance constant $c$. It should be between 0 and 1. Higher
        # values means less polling, which means better performance,
        # but higher risk of skipping a chat message.
        c = 0.5

        # Maximum delay period. If calculated delay is bigger, this
        # value will be used
        maxDelay = 120

        # Delay between next scrape. We use
        if secs == 0:
            # We received only one message this time. This is weird,
            # so log it and choose some reasonalbe constant
            print("Received a singe message", file=sys.stderr)
            delay = 30
        else:

            delay = min(maxDelay, math.floor(secs * c))
        print("Sleeping for %s seconds" % delay)
        return


    while True:
        bulk(es,processed_messages())
        time.sleep(delay)
