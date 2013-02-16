Storage::setObj = (key, obj) ->
  @setItem key, JSON.stringify(obj)

Storage::getObj = (key) ->
  JSON.parse @getItem(key)


class TodoApp

  constructor: ->
    @cacheElements()
    @bindEvents()
    @displayItems()
  
  cacheElements: ->
    @$input = $ '#new-todo'
    @$todoList = $ '#todo-list'
    @$clearCompleted = $ '#clear-completed'
    @$joinListName = $ '#join-list-name'
    @$join = $ '#join'
    @$connect = $ '#connect'
    @$disconnect = $ '#disconnect'
    @$connectedList = $ '#connected-list'
    @$leave = $ '#leave'

  bindEvents: ->
    @$input.on 'keyup', (e) => @create e
    @$todoList.on 'click', '.destroy', (e) => @destroy e.target
    @$todoList.on 'change', '.toggle', (e) => @toggle e.target
    @$clearCompleted.on 'click', => @clearCompleted()
    @$join.on 'click', => @joinList()
    @$leave.on 'click', => @leaveList()

  create: (e) ->
    val = $.trim @$input.val()
    return unless e.which == 13 and val
    
    randomId = Math.floor Math.random() * 999999

    newItem = 
      id: randomId
      title: val
      completed: false
    
    localStorage.setObj randomId, newItem
    @socket.emit 'newItem', newItem if @socket
    @$input.val ''
    @displayItems()
  
  displayItems: ->
    @clearItems()
    @addItem(localStorage.getObj id) for id in Object.keys(localStorage)
  
  clearItems: ->
    @$todoList.empty()
  
  addItem: (item) ->
    html = """
      <li #{if item.completed then 'class="completed"' else ''}
data-id = "#{item.id}">
        <div class="view">
          <input class="toggle" type="checkbox"
#{if item.completed then 'checked' else ''}>
          <label>#{item.title}</label>
          <button class="destroy"></button>
        </div>
      </li>
    """
    @$todoList.append html
  
  destroy: (elem) ->
    id = $(elem).closest('li').data('id')
    localStorage.removeItem id
    @socket.emit 'removeItem', id if @socket
    @displayItems()
  
  toggle: (elem) ->
    id = ($(elem).closest 'li').toggleClass('completed').data('id')
    item = localStorage.getObj id
    item.completed = !item.completed
    localStorage.setObj id, item
    @socket.emit 'toggleItem', item if @socket
  
  clearCompleted: ->
    for id in Object.keys(localStorage) when (localStorage.getObj id).completed
      localStorage.removeItem id
      @socket.emit 'removeItem', id if @socket
    @displayItems()
  
  joinList: ->
    if @socket
      @socketConnect()
      @setCurrentList()
      return

    @socketConnect()

    @socket.on 'connect', =>
      @setCurrentList()

      @socket.on 'syncItems', (items) => @syncItems items

      @socket.on 'itemAdded', (item) =>
        localStorage.setObj item.id, item
        @displayItems()

      @socket.on 'itemRemoved', (id) =>
        localStorage.removeItem id
        @displayItems()

  socketConnect: ->
    @socket = io.connect 'http://localhost:3000/'

  setCurrentList: ->
    @currentList = @$joinListName.val()
    @socket.emit 'joinList', @currentList if @socket
  
  syncItems: (items) ->
    console.log 'sync items'
    localStorage.clear()
    localStorage.setObj item.id, item for item in items
    @displayItems()
    @displayConnected(@currentList)
  
  displayConnected: (listName) ->
    @$disconnect.removeClass 'hidden'
    @$connectedList.text listName
    @$connect.addClass 'hidden'
  
  leaveList: ->
    @socket.emit 'leaveList' if @socket

    @displayDisconnected()
  
  displayDisconnected: ->
    @$disconnect.addClass 'hidden'
    @$connect.removeClass 'hidden'

$ ->
  new TodoApp()
