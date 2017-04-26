do ->
  if window.JSONRPC2
    JSONRPC2 = window.JSONRPC2
  else if typeof require == 'function'
    JSONRPC2 = require 'ant-jsonrpc2/dist/jsonrpc2'
  else
    throw new Error('JSONRPC2 not found');

  class AdminApiClient
    constructor: (options)->
      # extract options
      {@url, @onopen, @onclose, logFn: @log} = options

      unless m = @url.match '^wss?://([^\/]+)'
        throw new Error 'Incorrect URL. It should start from ws:// or wss://'

      host = m[1]

      if location.host != host
        @getHttpCookie().then @connectWS.bind(@)
      else
        @connectWS()


    getHttpCookie: ->
      m = @url.match 'ws(s?)://(.+)$'

      http_url = "http#{m[1]}://#{m[2]}"
      log = @log

      new Promise (resolve, reject)->
        log 'get', 'Sending GET...', http_url

        $.ajax(http_url, crossDomain: true, xhrFields: {withCredentials: true})
          .then (data)->
            log 'got', 'OK', data
            resolve()
          # catch
          , (err)->
            log 'got', 'Error', err #.status, err.statusText, err.responseText
            # ignore error, continue
            resolve()

    connectWS: ->
      @log 'ws', 'Opening WS...', @url

      @transport  = new JSONRPC2.Transport.Websocket {
        @url
        onOpenHandler: @onOpenHandler.bind(@)
        onCloseHandler: @onCloseHandler.bind(@)}
      @client     = new JSONRPC2.Client(@transport).useDebug(@debug)
      @server     = new JSONRPC2.Server(@transport).useDebug(@debug)

      if @tmpRecievers
        for own name, rcvr of @tmpRecievers
          @addReciever name, rcvr
        delete @tmpRecievers

      return

    onOpenHandler: ->
      @log 'ws', 'WS Opened'
      @connected = true
      @onopen?()

    onCloseHandler: ->
      @log 'ws', 'WS Closed'
      @connected = false
      @onclose?()

    ###*
    # @param {string} name - reciever's namespace
    # @param {object} rcvr - reciever: {methodname: function(data){}, ...}
    ###
    addReciever: (name, rcvr)->
      if @server
        @server.register name, rcvr
      else
        # still recieving GET
        @tmpRecievers ?= {}
        @tmpRecievers[name] = rcvr
        false

    request: (action, data)->
      return false unless @connected

      req = new JSONRPC2.Model.Request action, data
      id = req.getID()

      @log? 'out', id, action, data

      new Promise (resolve, reject)=>
        req.send(@client)
        .then (data)=>
          @log? 'in', id, action, data
          resolve data
        # catch
        , (err)=>
          @log? 'err', id, action, err
          reject(err)

    convertOrder: (order)->
      if order and order instanceof Array
        order.map ([field, desc])-> {field, direction: desc && 'desc' || 'asc'}
      else
        null


    # API Methods

    auth: (login, password)->
      @request 'Auth.GetUser' # => {"user_name", "user_id"}

    login: (login, password)->
      @request 'Auth.Login', {login, password} # => {"user_name", "user_id"}

    logout: ->
      @request 'Auth.Logout'

    casinoList: (filter, order, offset, limit)->
      if filter || order || offset || limit
        params = {beta_filter: filter, offset, limit, order: @convertOrder(order)}
      else
        params = null

      @request 'Casino.List', params
      .then (data)->
        data.items =
          if data.items
            data.items.map (item)->item.item
          else
            []

        data


    ###*
    # Create Casino
    # @param {object <string_id, site, active>} params - Casino params
    ###
    casinoCreate: (params)->
      @request 'Casino.Create', item: params

    ###*
    # Update Casino
    # @param {int} id - Casino ID
    # @params {object} params - Casino params (as in @casinoCreate)
    ###
    casinoUpdate: (id, fields)->
      @request 'Casino.Update', {pk: {id}, fields}


    #Game.List({offset, limit, beta_filter: {k: v}})
    #Game.Create({item:{...}})
    #Game.Update(pk:{id:666}, fields: {name: "ololo"})

    # order: [[field:string, desc:bool]], eg: [['id'], [name, false]]
    gameList: (filter, order, offset, limit)->
      if filter || order || offset || limit
        params = {beta_filter: filter, offset, limit, order: @convertOrder(order)}
      else
        params = null

      @request 'Game.List', params
      .then (data)->
        data.items =
          if data.items
            data.items.map (item)->item.item
          else
            []

        data

    # <description, id, name, string_id, type_id>

    ###*
    # Create Game
    # @param {object} params - Casino params
    ###
    gameCreate: (params)->
      @request 'Game.Create', item: params

    gameUpdate: (id, fields)->
      @request 'Game.Update', {pk: {id}, fields}


  # register in system
  if module?.exports?
    module.exports = AdminApiClient
  else if window?
    window.AdminApiClient = AdminApiClient

  return