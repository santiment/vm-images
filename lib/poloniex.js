const {EventEmitter} = require('events')

const Entities = require('html-entities').AllHtmlEntities
const entities = new Entities()

const parse = (rawmsg)=> {
  const arr = JSON.parse(rawmsg.data)
  if (arr[0] !== 1001) {
    return null
  }

  if (arr[1] === 1) {
    return null
  }
  const ts = Date.now();
  const msg = entities.decode(  arr[3]);
  const obj = {
    receivedTimestamp: ts,
    counter: arr[1],
    username: arr[2],
    reputation: arr[4],
    message: msg
  };
  return obj;
}

module.exports = ({ws,logger,most, url})=> {

  return {
    openTrollboxStream: () => {
      const connection = new ws(url)
      const emitter = new EventEmitter()

      const pushTrollboxEvent = (arr)=> {
        const obj = parse(arr)
        if (obj !== null) {
          emitter.emit('trollbox', parse(arr))
        }
      }

      connection.on('open', ()=>{
        logger.info("Connection opened")
        connection.send('{"command" : "subscribe", "channel" : 1001}')
      })

      connection.on('close', (code,reason)=>{
        logger.info("Connection closed. Reason:",code,reason)
        process.exit(0)
      })

      connection.on('error', (error)=>{
        logger.error("Connection error:",error)
        process.exit(1)
      })

      return most.fromEvent('message', connection).map(parse).filter((obj)=>{
        return (obj!==null)
      })
    }
  }
}
