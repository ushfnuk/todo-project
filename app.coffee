express = require "express"
path = require 'path'

app = express()
server = (require 'http').createServer app
io = (require 'socket.io').listen server

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'
app.use express.static(path.join __dirname, 'public')
app.use require('connect-assets')()

app.get "/", (req, res) ->
  res.render 'index'

port = process.env.PORT

@todos = {}
io.sockets.on 'connection', (socket) =>
  console.log 'connected'
  socket.on 'joinList', (list) => 
    console.log "Joining list #{list}"
    socket.list = list
    socket.join(list)
    @todos[list] ?= []
    socket.emit 'syncItems', @todos[list]

server.listen port
console.log "Listening on port #{port}"