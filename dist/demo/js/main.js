var api,
  slice = [].slice;

api = null;

(function() {
  var clearLog, connect, ifApi, initValues, log, log2, logTable, storage, values;
  log = function() {
    var data;
    data = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    $('#out').append($('<div>').text(JSON.stringify(data)));
    $('#btn-cls').show();
  };
  log2 = function() {
    var data, type;
    type = arguments[0], data = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    $('#out').append($('<div>').addClass(type).text(JSON.stringify(data)));
    $('#btn-cls').show();
  };
  clearLog = function() {
    $('#out').children().remove();
    $('#btn-cls').hide();
  };
  ifApi = function(cb) {
    if (api) {
      if (api.connected) {
        return cb();
      } else {
        return log('Not connected');
      }
    } else {
      return log('Not started');
    }
  };
  window.logTable = logTable = function(items) {
    var headRow, item, j, k, key, keys, l, len, len1, len2, ref, row, table, td, th;
    if (items != null ? items.length : void 0) {
      keys = Object.keys(items[0]);
      table = $('<table>');
      headRow = $('<tr>').appendTo(table);
      for (j = 0, len = keys.length; j < len; j++) {
        key = keys[j];
        th = $('<th>').text(key).appendTo(headRow);
      }
      for (k = 0, len1 = items.length; k < len1; k++) {
        item = items[k];
        row = $('<tr>').appendTo(table);
        for (l = 0, len2 = keys.length; l < len2; l++) {
          key = keys[l];
          td = $('<td>').text(_.isObject(item[key]) ? JSON.stringify(item[key]) : ((ref = item[key]) != null ? typeof ref.toString === "function" ? ref.toString() : void 0 : void 0) || item[key]).appendTo(row);
        }
      }
      return $('#out').append(table);
    }
  };
  api = null;
  values = {
    url: "ws://192.168.0.192/ws/"
  };
  storage = window.localStorage;
  if (!storage) {
    log('Браузер не поддерживает localStorage. Данные не будут сохранены');
  }

  /**
   * @param {string...} item List of values names
   */
  initValues = function() {
    var fn, items, j, len, name;
    items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    fn = function(name) {
      var el, val;
      if (val = storage != null ? storage.getItem(name) : void 0) {
        values[name] = val;
      } else if (values[name]) {
        val = values[name];
      } else {
        val = values[name] = '';
      }
      el = $('#val-' + name);
      if (el.attr('type') !== 'checkbox') {
        el.val(val);
        return el.on('change keyup blur', function() {
          values[name] = val = el.val();
          if (storage != null) {
            storage.setItem(name, val);
          }
        });
      } else {
        val = values[name] = val === 'true';
        el.prop('checked', val);
        return el.on('change', function() {
          values[name] = val = el.prop('checked');
          if (storage != null) {
            storage.setItem(name, val);
          }
        });
      }
    };
    for (j = 0, len = items.length; j < len; j++) {
      name = items[j];
      fn(name);
    }
  };
  connect = function() {
    var e;
    if (api) {
      log('Already started');
      return;
    }
    try {
      api = new AdminApiClient({
        url: values.url,
        maxReconnectAttempts: 10,
        debug: true,
        logFn: log2
      });
      api.addReciever('Test', {
        Call: function(data) {
          log2('rcv', 'Test.Call', data);
          return {
            some: 'Calling back'
          };
        },
        Notification: function(data) {
          log2('rcv', 'Test.Notification', data);
          return 'blah blah';
        }
      });
      console.log(api);
    } catch (error) {
      e = error;
      log(e.constructor.name || 'Error', e.message, e.stack);
    }
  };
  return $(function() {
    initValues('url', 'method', 'params');
    initValues('casino-id', 'casino-string-id', 'casino-site', 'casino-active');
    initValues('game-id', 'game-string-id', 'game-name', 'game-description', 'game-type-id');
    initValues('gamesection-id', 'gamesection-string-id', 'gamesection-name');
    initValues('gametype-id', 'gametype-string-id', 'gametype-name');
    initValues('patch-id', 'patch-name', 'patch-casino-id', 'patch-string-id', 'patch-type');
    initValues('autoconnect');
    if (values.autoconnect) {
      connect();
    }
    $('#val-url').on('change', function() {
      $('#val-autoconnect').prop('checked', false).trigger('change');
    });
    $('#val-autoconnect').on('change', function() {
      if (values.autoconnect && !api) {
        connect();
      }
    });
    $('fieldset').each(function(i, el) {
      el = $(el);
      return el.on('click', '> legend', function() {
        return el.toggleClass('open');
      });
    });
    $('#btn-cls').on('click', clearLog);
    $('#btn-connect').on('click', connect);
    $('#btn-auth').on('click', function() {
      return ifApi(function() {
        return api.auth();
      });
    });
    $('#btn-login').on('click', function() {
      var login, password;
      login = 'admin';
      password = '123123';
      return ifApi(function() {
        return api.login(login, password);
      });
    });
    $('#btn-logout').on('click', function() {
      return ifApi(function() {
        return api.logout();
      });
    });
    $('#btn-send').on('click', function() {
      var method, params;
      method = values.method;
      if (!method) {
        log('Method is empty');
        return;
      }
      params = (function() {
        try {
          return JSON.parse('{' + values.params + '}');
        } catch (error) {}
      })();
      if (!params) {
        log('Cannot parse Params');
        return;
      }
      return ifApi(function() {
        return api.request(method, params);
      });
    });
    $('#btn-casino-list').on('click', function() {
      return ifApi(function() {
        var active, create_time, filter, id, limit, offset, order, order_d0, order_d1, order_f0, order_f1, site, string_id;
        id = $('#val-casino-filter-id').val() || null;
        string_id = $('#val-casino-filter-string-id').val() || null;
        site = $('#val-casino-filter-site').val() || null;
        create_time = $('#val-casino-filter-create-time').val() || null;
        active = $('#val-casino-filter-active').val() || null;
        offset = $('#val-casino-filter-offset').val() || null;
        limit = $('#val-casino-filter-limit').val() || null;
        order_f0 = $('#val-casino-order-field0').val() || null;
        order_f1 = $('#val-casino-order-field1').val() || null;
        order_d0 = $('#val-casino-order-desc0').prop('checked');
        order_d1 = $('#val-casino-order-desc1').prop('checked');
        if (id) {
          id = parseInt(id);
        }
        if (id) {
          active = active === 'true';
        }
        if (offset) {
          offset = parseInt(offset);
        }
        if (limit) {
          limit = parseInt(limit);
        }
        if (isNaN(id)) {
          id = null;
        }
        if (isNaN(offset)) {
          offset = null;
        }
        if (isNaN(limit)) {
          limit = null;
        }
        if (id || string_id || site || create_time || (active != null)) {
          filter = {
            id: id,
            string_id: string_id,
            site: site,
            create_time: create_time,
            active: active
          };
        } else {
          filter = null;
        }
        if (order_f0) {
          order = [];
          order.push([order_f0, order_d0]);
          if (order_f1) {
            order.push([order_f1, order_d1]);
          }
        } else {
          order = null;
        }
        return api.casinoList(filter, order, offset, limit).then(function(data) {
          return logTable(data.items);
        });
      });
    });
    $('#btn-casino-create').on('click', function() {
      return ifApi(function() {
        var params;
        params = {
          id: values['casino-id'],
          string_id: values['casino-string-id'],
          site: values['casino-site'],
          active: values['casino-active']
        };
        return api.casinoCreate(params);
      });
    });
    $('#btn-casino-update').on('click', function() {
      return ifApi(function() {
        var id, params;
        id = values['casino-id'];
        if (!id) {
          log('id is empty');
          return;
        }
        params = {
          string_id: values['casino-string-id'],
          site: values['casino-site'],
          active: values['casino-active']
        };
        return api.casinoUpdate(id, params);
      });
    });
    $('#btn-game-list').on('click', function() {
      return ifApi(function() {
        var description, filter, id, limit, name, offset, order, order_d0, order_d1, order_f0, order_f1, string_id, type_id;
        id = $('#val-game-filter-id').val() || null;
        string_id = $('#val-game-filter-string-id').val() || null;
        name = $('#val-game-filter-name').val() || null;
        description = $('#val-game-filter-description').val() || null;
        type_id = $('#val-game-filter-type-id').val() || null;
        offset = $('#val-game-filter-offset').val() || null;
        limit = $('#val-game-filter-limit').val() || null;
        order_f0 = $('#val-game-order-field0').val() || null;
        order_f1 = $('#val-game-order-field1').val() || null;
        order_d0 = $('#val-game-order-desc0').prop('checked');
        order_d1 = $('#val-game-order-desc1').prop('checked');
        if (id) {
          id = parseInt(id);
        }
        if (offset) {
          offset = parseInt(offset);
        }
        if (limit) {
          limit = parseInt(limit);
        }
        if (type_id) {
          type_id = parseInt(type_id);
        }
        if (isNaN(id)) {
          id = null;
        }
        if (isNaN(offset)) {
          offset = null;
        }
        if (isNaN(limit)) {
          limit = null;
        }
        if (isNaN(type_id)) {
          type_id = null;
        }
        if (id || string_id || name || description || type_id) {
          filter = {
            id: id,
            string_id: string_id,
            name: name,
            description: description,
            type_id: type_id
          };
        } else {
          filter = null;
        }
        if (order_f0) {
          order = [];
          order.push([order_f0, order_d0]);
          if (order_f1) {
            order.push([order_f1, order_d1]);
          }
        } else {
          order = null;
        }
        return api.gameList(filter, order, offset, limit).then(function(data) {
          return logTable(data.items);
        });
      });
    });
    $('#btn-game-create').on('click', function() {
      return ifApi(function() {
        var params, type_id;
        type_id = values['game-type-id'] || null;
        if (type_id) {
          type_id = parseInt(type_id);
        }
        if (isNaN(type_id)) {
          type_id = null;
        }
        params = {
          string_id: values['game-string-id'],
          name: values['game-name'],
          description: values['game-description'],
          type_id: type_id
        };
        return api.gameCreate(params);
      });
    });
    $('#btn-game-update').on('click', function() {
      return ifApi(function() {
        var id, params, type_id;
        id = values['game-id'];
        if (!id) {
          log('id is empty');
          return;
        }
        type_id = values['game-type-id'] || null;
        if (type_id) {
          type_id = parseInt(type_id);
        }
        if (isNaN(type_id)) {
          type_id = null;
        }
        params = {
          string_id: values['game-string-id'],
          name: values['game-name'],
          description: values['game-description'],
          type_id: type_id
        };
        return api.gameUpdate(id, params);
      });
    });
    $('#btn-gamesection-list').on('click', function() {
      return ifApi(function() {
        var filter, id, limit, name, offset, order, order_d0, order_d1, order_f0, order_f1, string_id;
        id = $('#val-gamesection-filter-id').val() || null;
        string_id = $('#val-gamesection-filter-string-id').val() || null;
        name = $('#val-gamesection-filter-name').val() || null;
        offset = $('#val-gamesection-filter-offset').val() || null;
        limit = $('#val-gamesection-filter-limit').val() || null;
        order_f0 = $('#val-gamesection-order-field0').val() || null;
        order_f1 = $('#val-gamesection-order-field1').val() || null;
        order_d0 = $('#val-gamesection-order-desc0').prop('checked');
        order_d1 = $('#val-gamesection-order-desc1').prop('checked');
        if (id) {
          id = parseInt(id);
        }
        if (offset) {
          offset = parseInt(offset);
        }
        if (limit) {
          limit = parseInt(limit);
        }
        if (isNaN(id)) {
          id = null;
        }
        if (isNaN(offset)) {
          offset = null;
        }
        if (isNaN(limit)) {
          limit = null;
        }
        if (id || string_id || name) {
          filter = {
            id: id,
            string_id: string_id,
            name: name
          };
        } else {
          filter = null;
        }
        if (order_f0) {
          order = [];
          order.push([order_f0, order_d0]);
          if (order_f1) {
            order.push([order_f1, order_d1]);
          }
        } else {
          order = null;
        }
        return api.gameSectionList(filter, order, offset, limit).then(function(data) {
          return logTable(data.items);
        });
      });
    });
    $('#btn-gamesection-create').on('click', function() {
      return ifApi(function() {
        var params;
        params = {
          string_id: values['gamesection-string-id'],
          name: values['gamesection-name']
        };
        return api.gameSectionCreate(params);
      });
    });
    $('#btn-gamesection-update').on('click', function() {
      return ifApi(function() {
        var id, params;
        id = values['gamesection-id'];
        if (!id) {
          log('id is empty');
          return;
        }
        params = {
          string_id: values['gamesection-string-id'],
          name: values['gamesection-name']
        };
        return api.gameSectionUpdate(id, params);
      });
    });
    $('#btn-gametype-list').on('click', function() {
      return ifApi(function() {
        var filter, id, limit, name, offset, order, order_d0, order_d1, order_f0, order_f1, string_id;
        id = $('#val-gametype-filter-id').val() || null;
        string_id = $('#val-gametype-filter-string-id').val() || null;
        name = $('#val-gametype-filter-name').val() || null;
        offset = $('#val-gametype-filter-offset').val() || null;
        limit = $('#val-gametype-filter-limit').val() || null;
        order_f0 = $('#val-gametype-order-field0').val() || null;
        order_f1 = $('#val-gametype-order-field1').val() || null;
        order_d0 = $('#val-gametype-order-desc0').prop('checked');
        order_d1 = $('#val-gametype-order-desc1').prop('checked');
        if (id) {
          id = parseInt(id);
        }
        if (offset) {
          offset = parseInt(offset);
        }
        if (limit) {
          limit = parseInt(limit);
        }
        if (isNaN(id)) {
          id = null;
        }
        if (isNaN(offset)) {
          offset = null;
        }
        if (isNaN(limit)) {
          limit = null;
        }
        if (id || string_id || name) {
          filter = {
            id: id,
            string_id: string_id,
            name: name
          };
        } else {
          filter = null;
        }
        if (order_f0) {
          order = [];
          order.push([order_f0, order_d0]);
          if (order_f1) {
            order.push([order_f1, order_d1]);
          }
        } else {
          order = null;
        }
        return api.gameTypeList(filter, order, offset, limit).then(function(data) {
          return logTable(data.items);
        });
      });
    });
    $('#btn-gametype-create').on('click', function() {
      return ifApi(function() {
        var params;
        params = {
          string_id: values['gametype-string-id'],
          name: values['gametype-name']
        };
        return api.gameTypeCreate(params);
      });
    });
    $('#btn-gametype-update').on('click', function() {
      return ifApi(function() {
        var id, params;
        id = values['gametype-id'];
        if (!id) {
          log('id is empty');
          return;
        }
        params = {
          string_id: values['gametype-string-id'],
          name: values['gametype-name']
        };
        return api.gameTypeUpdate(id, params);
      });
    });
    $('#btn-patch-list').on('click', function() {
      return ifApi(function() {
        var casino_id, filter, id, limit, name, offset, order, order_d0, order_d1, order_f0, order_f1, string_id, type;
        id = $('#val-patch-filter-id').val() || null;
        name = $('#val-patch-filter-name').val() || null;
        casino_id = $('#val-patch-filter-casino-id').val() || null;
        string_id = $('#val-patch-filter-string-id').val() || null;
        type = $('#val-patch-filter-type').val() || null;
        offset = $('#val-patch-filter-offset').val() || null;
        limit = $('#val-patch-filter-limit').val() || null;
        order_f0 = $('#val-patch-order-field0').val() || null;
        order_f1 = $('#val-patch-order-field1').val() || null;
        order_d0 = $('#val-patch-order-desc0').prop('checked');
        order_d1 = $('#val-patch-order-desc1').prop('checked');
        if (id) {
          id = parseInt(id);
        }
        if (casino_id) {
          casino_id = parseInt(casino_id);
        }
        if (offset) {
          offset = parseInt(offset);
        }
        if (limit) {
          limit = parseInt(limit);
        }
        if (isNaN(id)) {
          id = null;
        }
        if (isNaN(casino_id)) {
          casino_id = null;
        }
        if (isNaN(offset)) {
          offset = null;
        }
        if (isNaN(limit)) {
          limit = null;
        }
        if (id || name || type || string_id || casino_id) {
          filter = {
            id: id,
            name: name,
            type: type,
            casino_id: casino_id,
            string_id: string_id
          };
        } else {
          filter = null;
        }
        if (order_f0) {
          order = [];
          order.push([order_f0, order_d0]);
          if (order_f1) {
            order.push([order_f1, order_d1]);
          }
        } else {
          order = null;
        }
        return api.patchList(filter, order, offset, limit).then(function(data) {
          return logTable(data.items);
        });
      });
    });
    $('#btn-patch-create').on('click', function() {
      return ifApi(function() {
        var casino_id, params;
        casino_id = values['patch-casino-id'] || null;
        if (casino_id) {
          casino_id = parseInt(casino_id);
        }
        if (isNaN(casino_id)) {
          casino_id = null;
        }
        params = {
          name: values['patch-name'],
          casino_id: casino_id,
          string_id: values['patch-string-id'],
          type: values['patch-type']
        };
        return api.patchCreate(params);
      });
    });
    return $('#btn-patch-update').on('click', function() {
      return ifApi(function() {
        var casino_id, id, params;
        id = values['patch-id'];
        if (!id) {
          log('id is empty');
          return;
        }
        casino_id = values['patch-casino-id'] || null;
        if (casino_id) {
          casino_id = parseInt(casino_id);
        }
        if (isNaN(casino_id)) {
          casino_id = null;
        }
        params = {
          casino_id: casino_id,
          name: values['patch-name'],
          type: values['patch-type']
        };
        return api.patchUpdate(id, params);
      });
    });
  });
})();
