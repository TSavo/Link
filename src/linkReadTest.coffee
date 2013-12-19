bitcoin = require 'bitcoin'
client = new bitcoin.Client
  host: 'localhost'
  port: 8332
  user: 'Kevlar'
  pass: 'zabbas'

db = require('./linkDB').getDB("Feathercoin", client)
    
setInterval ()->
  db.search "pirate", console.log
, 100
  
