const DashButton = require('dash-button');


const WebSocket = require('ws');
 
const wss = new WebSocket.Server({ port: 3030 });
var _ws;
var clients = [];

wss.on('connection', function connection(ws, req) {
  _ws = ws;
  const ip = req.connection.remoteAddress;
  clients.push(ip);
  console.log('connection from '+ip);
  _ws.on('message', function incoming(message) {
    console.log('received: %s', message);
    if (message == "GOT IT") {
      broadcast('{"type":"got it"}');
    }
  });
  _ws.on('close', function closed() {
    console.log('client disconnect '+ip);
    var index = clients.indexOf(ip);
    if (index > -1) {
      clients.splice(index, 1);
    }
  });
  console.log(clients.length + " Clients Connected");
});

function broadcast(data) {
  wss.clients.forEach(function each(client) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
};

buttons = [{"location": "207", "address": "34:d2:70:0d:9a:a5"}, 
           {"location": "207 B", "address": "88:71:e5:45:dc:f3"}, 
           {"location": "308", "address": "68:37:e9:f2:c3:8c"}];

buttons.forEach(function(element) {
  
  console.log(element.location+": "+element.address);
  const DASH_BUTTON_MAC_ADDRESS = element.address;
   
  let button = new DashButton(DASH_BUTTON_MAC_ADDRESS);

  let subscription = button.addListener(async () => {
    console.log('[' + new Date().toUTCString() + '] Button Pressed');
    broadcast('{"type":"button pressed", "location":"'+element.location+'"}');
  });

});
