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

port = 3000

todos = {}
io.sockets.on 'connection', (socket) ->
  console.log 'connected'

  firstRun = true
  socket.on 'joinList', (list) ->
    console.log "Joining list #{list}"
    socket.list = list
    socket.join list
    todos[list] ?= []
#    console.log todos
    socket.emit 'syncItems', todos[list]

    unless firstRun
      return

    firstRun = false

    socket.on 'newItem', (todo) ->
      todos[socket.list].push todo
      io.sockets.in(socket.list).emit 'itemAdded', todo
    
    socket.on 'removeItem', (id) ->
      todos[socket.list] =
        (item for item in todos[socket.list] when item.id isnt id)
      io.sockets.in(socket.list).emit 'itemRemoved', id

    socket.on 'toggleItem', (todo) ->
      for t, i in todos[socket.list] when t.id is todo.id
        todos[socket.list][i] = todo
      io.sockets.in(socket.list).emit 'syncItems', todos[socket.list]

    socket.on 'leaveList', ->
      socket.leave socket.list

server.listen port
console.log "Listening on port #{port}"