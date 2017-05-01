# global
api = null

# closure
do ->
  log = (data...)->
    $('#out').append $('<div>').text JSON.stringify data
    $('#btn-cls').show()
    return

  log2 = (type, data...)->
    $('#out').append $('<div>').addClass(type).text JSON.stringify data
    $('#btn-cls').show()
    return

  clearLog = ->
    $('#out').children().remove()
    $('#btn-cls').hide()
    return

  ifApi = (cb)->
    if api
      if api.connected
        cb()
      else
        log 'Not connected'
    else
      log 'Not started'

  window.logTable = logTable = (items)->
    if items?.length

      keys = Object.keys items[0]
      table = $('<table>')

      headRow = $('<tr>').appendTo(table)
      for key in keys
        th = $('<th>').text(key).appendTo(headRow)

      for item in items
        row = $('<tr>').appendTo(table)
        for key in keys
          td = $('<td>').text(
            if _.isObject(item[key]) then JSON.stringify(item[key]) else item[key].toString?() || item[key]
          ).appendTo(row)

      $('#out').append(table)


  api = null
  values = {url: "ws://192.168.0.192/ws/"}
  storage = window.localStorage

  unless storage
    log 'Браузер не поддерживает localStorage. Данные не будут сохранены'

  ###*
  # @param {string...} item List of values names
  ###
  initValues = (items...)->
    debugger
    for name in items
      do (name)->

        if val = storage?.getItem(name)
          values[name] = val
        else if values[name]
          val = values[name]
        else
          val = values[name] = ''

        el = $('#val-'+name)

        unless el.attr('type') == 'checkbox'
          el.val val # set

          el.on 'change keyup blur', ->
            values[name] = val = el.val()
            storage?.setItem name, val
            return

        else
          # checkbox
          val = values[name] = (val == 'true')
          el.prop 'checked', val

          el.on 'change', ->
            values[name] = val = el.prop 'checked'
            storage?.setItem name, val
            return

    return

  connect = ->
    if api
      log 'Already started'
      return

    try
      api = new AdminApiClient
        url: values.url
        maxReconnectAttempts: 10
        debug: true
        #onopen: -> log 'Connected'
        #onclose: -> log 'Disconnected'
        logFn: log2

      api.addReciever 'Test',
        Call: (data)->
          log2 'rcv', 'Test.Call', data
          return some: 'Calling back'

        Notification: (data)->
          log2 'rcv', 'Test.Notification', data
          return 'blah blah'

      console.log api

    catch e
      log e.constructor.name || 'Error', e.message, e.stack

    return


  # on ready
  $ ->

    initValues 'autoconnect'
    initValues 'url', 'method', 'params'
    initValues 'casino-id', 'casino-string-id', 'casino-site', 'casino-active'
    initValues 'game-id', 'game-string-id', 'game-name', 'game-description'
    initValues 'gamesection-id', 'gamesection-string-id', 'gamesection-name'

    if values.autoconnect
      connect()

    $('#val-url').on 'change', ->
      $('#val-autoconnect').prop('checked', false).trigger('change')
      return

    $('#val-autoconnect').on 'change', ->
      if values.autoconnect and !api
        connect()
      return

    $('fieldset').each (i, el)->
      el = $ el
      el.on 'click', '> legend', -> el.toggleClass 'open'




    $('#btn-cls').on 'click', clearLog

    $('#btn-connect').on 'click', connect

    $('#btn-auth').on 'click', ->
      ifApi -> api.auth()

    $('#btn-login').on 'click', ->
      login = 'admin'
      password = '123123'

      ifApi -> api.login(login, password)

    $('#btn-logout').on 'click', ->
      ifApi -> api.logout()

    $('#btn-send').on 'click', ->
      method = values.method
      unless method
        log 'Method is empty'
        return

      params = try JSON.parse '{' + values.params + '}'
      unless params
        log 'Cannot parse Params'
        return

      ifApi -> api.request method, params

    $('#btn-casino-list').on 'click', ->
      ifApi ->
        id          = $('#val-casino-filter-id').val()          || null
        string_id   = $('#val-casino-filter-string-id').val()   || null
        site        = $('#val-casino-filter-site').val()        || null
        create_time = $('#val-casino-filter-create-time').val() || null
        active      = $('#val-casino-filter-active').val()      || null
        offset      = $('#val-casino-filter-offset').val()      || null
        limit       = $('#val-casino-filter-limit').val()       || null
        order_f0    = $('#val-casino-order-field0').val()       || null
        order_f1    = $('#val-casino-order-field1').val()       || null
        order_d0    = $('#val-casino-order-desc0').prop('checked')
        order_d1    = $('#val-casino-order-desc1').prop('checked')

        id = parseInt(id) if id
        active = (active == 'true') if id
        offset  = parseInt(offset) if offset
        limit   = parseInt(limit) if limit

        id      = null if isNaN id
        offset  = null if isNaN offset
        limit   = null if isNaN limit

        if id || string_id || site || create_time || active?
          filter = {id, string_id, site, create_time, active}
        else
          filter = null

        if order_f0
          order = []
          order.push [order_f0, order_d0]

          if order_f1
            order.push [order_f1, order_d1]

        else
          order = null

        api.casinoList(filter, order, offset, limit).then (data)-> logTable data.items

    $('#btn-game-list').on 'click', ->
      ifApi ->
        id          = $('#val-game-filter-id').val()          || null
        string_id   = $('#val-game-filter-string-id').val()   || null
        name        = $('#val-game-filter-name').val()        || null
        description = $('#val-game-filter-description').val() || null
        offset      = $('#val-game-filter-offset').val()      || null
        limit       = $('#val-game-filter-limit').val()       || null
        order_f0    = $('#val-game-order-field0').val()       || null
        order_f1    = $('#val-game-order-field1').val()       || null
        order_d0    = $('#val-game-order-desc0').prop('checked')
        order_d1    = $('#val-game-order-desc1').prop('checked')

        id      = parseInt(id) if id
        offset  = parseInt(offset) if offset
        limit   = parseInt(limit) if limit

        id      = null if isNaN id
        offset  = null if isNaN offset
        limit   = null if isNaN limit

        if id || string_id || name || description
          filter = {id, string_id, name, description}
        else
          filter = null

        if order_f0
          order = []
          order.push [order_f0, order_d0]

          if order_f1
            order.push [order_f1, order_d1]

        else
          order = null

        api.gameList(filter, order, offset, limit).then (data)-> logTable data.items


    $('#btn-gamesection-list').on 'click', ->
      ifApi ->
        id          = $('#val-gamesection-filter-id').val()          || null
        string_id   = $('#val-gamesection-filter-string-id').val()   || null
        name        = $('#val-gamesection-filter-name').val()        || null
        offset      = $('#val-gamesection-filter-offset').val()      || null
        limit       = $('#val-gamesection-filter-limit').val()       || null
        order_f0    = $('#val-gamesection-order-field0').val()       || null
        order_f1    = $('#val-gamesection-order-field1').val()       || null
        order_d0    = $('#val-gamesection-order-desc0').prop('checked')
        order_d1    = $('#val-gamesection-order-desc1').prop('checked')

        id      = parseInt(id) if id
        offset  = parseInt(offset) if offset
        limit   = parseInt(limit) if limit

        id      = null if isNaN id
        offset  = null if isNaN offset
        limit   = null if isNaN limit

        if id || string_id || name
          filter = {id, string_id, name}
        else
          filter = null

        if order_f0
          order = []
          order.push [order_f0, order_d0]

          if order_f1
            order.push [order_f1, order_d1]

        else
          order = null

        api.gameSectionList(filter, order, offset, limit).then (data)-> logTable data.items


    $('#btn-casino-create').on 'click', ->
      ifApi ->
        params =
          id: values['casino-id']
          string_id: values['casino-string-id']
          site: values['casino-site']
          active: values['casino-active']

        api.casinoCreate params

    $('#btn-casino-update').on 'click', ->
      ifApi ->
        id = values['casino-id']
        unless id
          log 'id is empty'
          return

        params =
          string_id: values['casino-string-id']
          site: values['casino-site']
          active: values['casino-active']

        api.casinoUpdate id, params


    $('#btn-game-create').on 'click', ->
      ifApi ->
        params =
          string_id: values['game-string-id']
          name: values['game-name']
          description: values['game-description']

        api.gameCreate params



    $('#btn-game-update').on 'click', ->
      ifApi ->
        id = values['game-id']
        unless id
          log 'id is empty'
          return

        params =
          string_id: values['game-string-id']
          name: values['game-name']
          description: values['game-description']

        api.gameUpdate id, params

    $('#btn-gamesection-create').on 'click', ->
      ifApi ->
        params =
          string_id: values['gamesection-string-id']
          name: values['gamesection-name']

        api.gameSectionCreate params



    $('#btn-gamesection-update').on 'click', ->
      ifApi ->
        id = values['gamesection-id']
        unless id
          log 'id is empty'
          return

        params =
          string_id: values['gamesection-string-id']
          name: values['gamesection-name']

        api.gameSectionUpdate id, params

