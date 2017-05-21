#!/usr/bin/env node
const ws = require('ws')
const most = require('most')
const R = require('ramda')
const elasticsearch = require('elasticsearch')

// All configuration is read from the environment or from the .env
// file in the root of the codebase
require('dotenv').config()

const defaultConfig = {
  TC_ELASTICSEARCH_API_VERSION:"5.3",
  TC_ELASTICSEARCH_PORT:"9200",
  TC_POLONIEX_WEBSOCKET_URL:"wss://api2.poloniex.com:443",
  TC_ELASTICSEARCH_HOST:"http://localhost"
}

const config = R.merge(defaultConfig, process.env)

const es_url = config.TC_ELASTICSEARCH_HOST+":"+config.TC_ELASTICSEARCH_PORT

const {openTrollboxStream} = require('./lib/poloniex')({
  ws,
  most,
  logger:console,
  url:config.TC_POLONIEX_WEBSOCKET_URL
})

const {recordTrollboxMessage} = require('./lib/elasticsearch')({
  elasticsearch,
  host:es_url,
  apiVersion: config.TC_ELASTICSEARCH_API_VERSION,
  logger:console
})

const stream = openTrollboxStream()

stream.observe( (message)=>{
  recordTrollboxMessage(message).fork(console.error,()=>{})
})
