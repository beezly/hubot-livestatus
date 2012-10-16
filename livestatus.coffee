# Description:
#   Uses MK_Livestatus to check a host and it's services
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_LIVESTATUS_HOST - name of your mk_livestatus server
#   HUBOT_LIVESTATUS_PORT - port of your mk_livestatus server
#
# Commands:
#   hubot check <server> - Reports results of latest checks on  <server>
#
# Author:
#   beezly

module.exports = (robot) ->
  robot.respond /check (.*)/i, (msg) ->
    checkStatus msg, msg.match[1]

checkStatus = (msg, domain) ->
  console.log "We have to do something about #{domain}"
  net = require 'net'
  databack = "";
  status_host = process.env.HUBOT_LIVESTATUS_HOST || 'localhost'
  status_port = process.env.HUBOT_LIVESTATUS_PORT || '6557'
  client = net.connect {host: status_host, port: status_port}, () ->
    console.log 'isup connected'
    client.write "GET hosts\nFilter: host_name =~ #{domain}\nColumns: last_state notes_url services_with_state\nOutputFormat: json\n\n"
  client.on 'data', (data) ->
    databack += data.toString()
  client.on 'end', () ->
    resp = JSON.parse databack
    respdata = []
    if resp.length > 0 
      hostresp msg, domain, respdata, hostdata for hostdata in resp
    else
      respdata.push "Couldn't find a host called #{domain}"
    msg.send respdata.join '\n'

hostresp = (msg, domain, respdata, hostdata) ->
  resp_map = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']
  notes_url = if hostdata[1] then " (#{hostdata[1]})" else ""
  respdata.push "#{domain} is #{resp_map[hostdata[0]]}#{notes_url}"
  respdata.push "#{domain}:#{service[0]} is #{resp_map[service[1]]}" for service in hostdata[2]
