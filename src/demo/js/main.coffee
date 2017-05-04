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
            if _.isObject(item[key]) then JSON.stringify(item[key]) else item[key]?.toString?() || item[key]
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

    initValues 'url', 'method', 'params'
    initValues 'casino-id', 'casino-string-id', 'casino-site', 'casino-active'
    initValues 'game-id', 'game-string-id', 'game-name', 'game-description', 'game-type-id'
    initValues 'gamesection-id', 'gamesection-string-id', 'gamesection-name'
    initValues 'gametype-id', 'gametype-string-id', 'gametype-name'
    initValues 'patch-id', 'patch-name', 'patch-casino-id', 'patch-string-id', 'patch-type'
    initValues 'autoconnect'

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


    # custom method
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

    # casino
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


    # game
    $('#btn-game-list').on 'click', ->
      ifApi ->
        id          = $('#val-game-filter-id').val()          || null
        string_id   = $('#val-game-filter-string-id').val()   || null
        name        = $('#val-game-filter-name').val()        || null
        description = $('#val-game-filter-description').val() || null
        type_id     = $('#val-game-filter-type-id').val()     || null
        offset      = $('#val-game-filter-offset').val()      || null
        limit       = $('#val-game-filter-limit').val()       || null
        order_f0    = $('#val-game-order-field0').val()       || null
        order_f1    = $('#val-game-order-field1').val()       || null
        order_d0    = $('#val-game-order-desc0').prop('checked')
        order_d1    = $('#val-game-order-desc1').prop('checked')

        id      = parseInt(id) if id
        offset  = parseInt(offset) if offset
        limit   = parseInt(limit) if limit
        type_id = parseInt(type_id) if type_id

        id      = null if isNaN id
        offset  = null if isNaN offset
        limit   = null if isNaN limit
        type_id = null if isNaN type_id

        if id || string_id || name || description || type_id
          filter = {id, string_id, name, description, type_id}
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

    $('#btn-game-create').on 'click', ->
      ifApi ->
        type_id = values['game-type-id'] || null
        type_id = parseInt(type_id) if type_id
        type_id = null if isNaN type_id

        params =
          string_id: values['game-string-id']
          name: values['game-name']
          description: values['game-description']
          type_id: type_id

        api.gameCreate params

    $('#btn-game-update').on 'click', ->
      ifApi ->
        id = values['game-id']
        unless id
          log 'id is empty'
          return

        type_id = values['game-type-id'] || null
        type_id = parseInt(type_id) if type_id
        type_id = null if isNaN type_id

        params =
          string_id: values['game-string-id']
          name: values['game-name']
          description: values['game-description']
          type_id: type_id

        api.gameUpdate id, params


    # game section
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

    # game type
    $('#btn-gametype-list').on 'click', ->
      ifApi ->
        id          = $('#val-gametype-filter-id').val()          || null
        string_id   = $('#val-gametype-filter-string-id').val()   || null
        name        = $('#val-gametype-filter-name').val()        || null
        offset      = $('#val-gametype-filter-offset').val()      || null
        limit       = $('#val-gametype-filter-limit').val()       || null
        order_f0    = $('#val-gametype-order-field0').val()       || null
        order_f1    = $('#val-gametype-order-field1').val()       || null
        order_d0    = $('#val-gametype-order-desc0').prop('checked')
        order_d1    = $('#val-gametype-order-desc1').prop('checked')

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

        api.gameTypeList(filter, order, offset, limit).then (data)-> logTable data.items

    $('#btn-gametype-create').on 'click', ->
      ifApi ->
        params =
          string_id: values['gametype-string-id']
          name: values['gametype-name']

        api.gameTypeCreate params

    $('#btn-gametype-update').on 'click', ->
      ifApi ->
        id = values['gametype-id']
        unless id
          log 'id is empty'
          return

        params =
          string_id: values['gametype-string-id']
          name: values['gametype-name']

        api.gameTypeUpdate id, params

    # patch
    $('#btn-patch-list').on 'click', ->
      ifApi ->
        id          = $('#val-patch-filter-id').val()          || null
        name        = $('#val-patch-filter-name').val()        || null
        casino_id   = $('#val-patch-filter-casino-id').val()   || null
        string_id   = $('#val-patch-filter-string-id').val()   || null
        type        = $('#val-patch-filter-type').val()        || null
        offset      = $('#val-patch-filter-offset').val()      || null
        limit       = $('#val-patch-filter-limit').val()       || null
        order_f0    = $('#val-patch-order-field0').val()       || null
        order_f1    = $('#val-patch-order-field1').val()       || null
        order_d0    = $('#val-patch-order-desc0').prop('checked')
        order_d1    = $('#val-patch-order-desc1').prop('checked')

        id      = parseInt(id) if id
        casino_id = parseInt(casino_id) if casino_id
        offset  = parseInt(offset) if offset
        limit   = parseInt(limit) if limit

        id      = null if isNaN id
        casino_id = null if isNaN casino_id
        offset  = null if isNaN offset
        limit   = null if isNaN limit

        if id || name || type || string_id || casino_id
          filter = {id, name, type, casino_id, string_id}
        else
          filter = null

        if order_f0
          order = []
          order.push [order_f0, order_d0]

          if order_f1
            order.push [order_f1, order_d1]

        else
          order = null

        api.patchList(filter, order, offset, limit).then (data)-> logTable data.items

    $('#btn-patch-create').on 'click', ->
      ifApi ->
        casino_id = values['patch-casino-id'] || null
        casino_id = parseInt(casino_id) if casino_id
        casino_id = null if isNaN casino_id

        params =
          name: values['patch-name']
          casino_id: casino_id
          string_id: values['patch-string-id']
          type: values['patch-type']

        api.patchCreate params

    $('#btn-patch-update').on 'click', ->
      ifApi ->
        id = values['patch-id']
        unless id
          log 'id is empty'
          return

        casino_id = values['patch-casino-id'] || null
        casino_id = parseInt(casino_id) if casino_id
        casino_id = null if isNaN casino_id

        params =
          casino_id: casino_id
          name: values['patch-name']
          type: values['patch-type']

        api.patchUpdate id, params

