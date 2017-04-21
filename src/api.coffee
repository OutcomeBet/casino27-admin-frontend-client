do ->

  class AdminApiClient
    constructor: (options)->
      unless JSONRPC2?
        throw new Error 'JSONRPC2 not found'

      {@url, @onopen, @onclose, logFn: @log} = options

      @transport  = new JSONRPC2.Transport.Websocket {
        @url
        onOpenHandler: @onOpenHandler.bind(@)
        onCloseHandler: @onCloseHandler.bind(@)}
      @client     = new JSONRPC2.Client(@transport).useDebug(@debug)
      @server     = new JSONRPC2.Server(@transport).useDebug(@debug)

    onOpenHandler: ->
      @connected = true
      @onopen?()

    onCloseHandler: ->
      @connected = false
      @onclose?()

    ###*
    # @param {string} name - reciever's namespace
    # @param {object} rcvr - reciever: {methodname: function(data){}, ...}
    ###
    addReciever: (name, rcvr)->
      @server.register name, rcvr

    request: (action, data)->
      return false unless @connected

      req = new JSONRPC2.Model.Request action, data
      id = req.getID()

      @log? 'out', id, action, data

      req.send(@client)
      .then (data)=>
        @log? 'in', id, action, data
        data
      .catch (err)=>
        @log? 'err', id, action, err
        null


    # API Methods

    auth: (login, password)->
      @request 'Auth.GetUser' # => {"user_name", "user_id"}

    login: (login, password)->
      @request 'Auth.Login', {login, password} # => {"user_name", "user_id"}

    casinoList: ->
      @request 'Casino.List'


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
    casinoUpdate: (id, params)->
      @request 'Casino.Update', pk: {id}, item: params



    #Game2.List({offset, limit, beta_filter: {k: v}})
    #Game2.Create({item:{...}})
    #Game2.Update(pk:{id:666}, fields: {name: "ololo"})

    gameList: (filter, order, offset, limit)->
      if filter || order || offset || limit
        params = {beta_filter: filter, offset, limit}
      else
        params = null

      @request 'Game2.List', params
      .then (data)->
        data.items = data.items.map (item)->item.item
        data

    # <description, id, name, string_id, type_id>

    ###*
    # Create Game
    # @param {object <string_id, section>} params - Casino params
    ###
    gameCreate: (params)->
      @request 'Game2.Create', item: params

    gameUpdate: (id, params)->
      @request 'Game2.Update', pk: {id}, fields: params


  # register in system
  if module?.exports?
    module.exports = AdminApiClient
  else if window?
    window.C25AdminApiClient = AdminApiClient

  return