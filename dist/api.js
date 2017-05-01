var hasProp = {}.hasOwnProperty;

(function() {
  var AdminApiClient, JSONRPC2;
  if (window.JSONRPC2) {
    JSONRPC2 = window.JSONRPC2;
  } else if (typeof require === 'function') {
    JSONRPC2 = require('ant-jsonrpc2/dist/jsonrpc2');
  } else {
    throw new Error('JSONRPC2 not found');
  }
  AdminApiClient = (function() {
    function AdminApiClient(options) {
      var host, m, ref;
      this.options = options;
      ref = this.options, this.url = ref.url, this.onopen = ref.onopen, this.onclose = ref.onclose, this.log = ref.logFn, this.errorHandler = ref.errorHandler;
      if (!(m = this.url.match('^wss?://([^\/]+)'))) {
        throw new Error('Incorrect URL. It should start from ws:// or wss://');
      }
      host = m[1];
      if (location.host !== host) {
        this.getHttpCookie().then(this.connectWS.bind(this));
      } else {
        this.connectWS();
      }
    }

    AdminApiClient.prototype.getHttpCookie = function() {
      var http_url, log, m;
      m = this.url.match('ws(s?)://(.+)$');
      http_url = "http" + m[1] + "://" + m[2];
      log = this.log;
      return new Promise(function(resolve, reject) {
        log('get', 'Sending GET...', http_url);
        return $.ajax(http_url, {
          crossDomain: true,
          xhrFields: {
            withCredentials: true
          }
        }).then(function(data) {
          log('got', 'OK', data);
          return resolve();
        }, function(err) {
          log('got', 'Error', err);
          return resolve();
        });
      });
    };

    AdminApiClient.prototype.connectWS = function() {
      var name, rcvr, ref;
      this.log('ws', 'Opening WS...', this.url);
      this.transport = new JSONRPC2.Transport.Websocket({
        url: this.url,
        alwaysReconnectOnClose: true,
        maxReconnectAttempts: this.options.maxReconnectAttempts,
        onOpenHandler: this.onOpenHandler.bind(this),
        onCloseHandler: this.onCloseHandler.bind(this)
      });
      this.client = new JSONRPC2.Client(this.transport).useDebug(this.debug);
      this.server = new JSONRPC2.Server(this.transport).useDebug(this.debug);
      if (this.tmpRecievers) {
        ref = this.tmpRecievers;
        for (name in ref) {
          if (!hasProp.call(ref, name)) continue;
          rcvr = ref[name];
          this.addReciever(name, rcvr);
        }
        delete this.tmpRecievers;
      }
    };

    AdminApiClient.prototype.onOpenHandler = function() {
      this.log('ws', 'WS Opened');
      this.connected = true;
      return typeof this.onopen === "function" ? this.onopen() : void 0;
    };

    AdminApiClient.prototype.onCloseHandler = function() {
      this.log('ws', 'WS Closed');
      this.connected = false;
      return typeof this.onclose === "function" ? this.onclose() : void 0;
    };


    /**
     * @param {string} name - reciever's namespace
     * @param {object} rcvr - reciever: {methodname: function(data){}, ...}
     */

    AdminApiClient.prototype.addReciever = function(name, rcvr) {
      if (this.server) {
        return this.server.register(name, rcvr);
      } else {
        if (this.tmpRecievers == null) {
          this.tmpRecievers = {};
        }
        this.tmpRecievers[name] = rcvr;
        return false;
      }
    };

    AdminApiClient.prototype.request = function(action, data) {
      var id, req;
      if (!this.connected) {
        return false;
      }
      req = new JSONRPC2.Model.Request(action, data);
      id = req.getID();
      if (typeof this.log === "function") {
        this.log('out', id, action, data);
      }
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return req.send(_this.client).then(function(data) {
            if (typeof _this.log === "function") {
              _this.log('in', id, action, data);
            }
            return resolve(data);
          }, function(err) {
            if (typeof _this.log === "function") {
              _this.log('err', id, action, err);
            }
            if (_this.errorHandler) {
              return _this.errorHandler(err);
            } else {
              return reject(err);
            }
          });
        };
      })(this));
    };

    AdminApiClient.prototype.convertOrder = function(order) {
      if (order && order instanceof Array) {
        return order.map(function(arg) {
          var desc, field;
          field = arg[0], desc = arg[1];
          return {
            field: field,
            direction: desc && 'desc' || 'asc'
          };
        });
      } else {
        return null;
      }
    };

    AdminApiClient.prototype.outputPlainItemsData = function(data) {
      data.items = data.items ? data.items.map(function(item) {
        return item.item;
      }) : [];
      return data;
    };

    AdminApiClient.prototype.auth = function(login, password) {
      return this.request('Auth.GetUser');
    };

    AdminApiClient.prototype.login = function(login, password) {
      return this.request('Auth.Login', {
        login: login,
        password: password
      });
    };

    AdminApiClient.prototype.logout = function() {
      return this.request('Auth.Logout');
    };

    AdminApiClient.prototype.casinoList = function(filter, order, offset, limit) {
      var params;
      if (filter || order || offset || limit) {
        params = {
          beta_filter: filter,
          offset: offset,
          limit: limit,
          order: this.convertOrder(order)
        };
      } else {
        params = null;
      }
      return this.request('Casino.List', params).then(this.outputPlainItemsData.bind(this));
    };


    /**
     * Create Casino
     * @param {object <string_id, site, active>} params - Casino params
     */

    AdminApiClient.prototype.casinoCreate = function(params) {
      return this.request('Casino.Create', {
        item: params
      });
    };


    /**
     * Update Casino
     * @param {int} id - Casino ID
     * @params {object} params - Casino params (as in @casinoCreate)
     */

    AdminApiClient.prototype.casinoUpdate = function(id, fields) {
      return this.request('Casino.Update', {
        pk: {
          id: id
        },
        fields: fields
      });
    };

    AdminApiClient.prototype.gameList = function(filter, order, offset, limit) {
      var params;
      if (filter || order || offset || limit) {
        params = {
          beta_filter: filter,
          offset: offset,
          limit: limit,
          order: this.convertOrder(order)
        };
      } else {
        params = null;
      }
      return this.request('Game.List', params).then(this.outputPlainItemsData.bind(this));
    };


    /**
     * Create Game
     * @param {object} params - Casino params
     */

    AdminApiClient.prototype.gameCreate = function(params) {
      return this.request('Game.Create', {
        item: params
      });
    };

    AdminApiClient.prototype.gameUpdate = function(id, fields) {
      return this.request('Game.Update', {
        pk: {
          id: id
        },
        fields: fields
      });
    };


    /**
     * Get Games Sections list
     */

    AdminApiClient.prototype.gameSectionList = function(filter, order, offset, limit) {
      var params;
      if (filter || order || offset || limit) {
        params = {
          beta_filter: filter,
          offset: offset,
          limit: limit,
          order: this.convertOrder(order)
        };
      } else {
        params = null;
      }
      return this.request('GameSection.List', params).then(this.outputPlainItemsData.bind(this));
    };

    AdminApiClient.prototype.gameSectionCreate = function(params) {
      return this.request('GameSection.Create', {
        item: params
      });
    };

    AdminApiClient.prototype.gameSectionUpdate = function(id, fields) {
      return this.request('GameSection.Update', {
        pk: {
          id: id
        },
        fields: fields
      });
    };


    /**
     * Get Games Types list
     */

    AdminApiClient.prototype.gameTypeList = function(filter, order, offset, limit) {
      var params;
      if (filter || order || offset || limit) {
        params = {
          beta_filter: filter,
          offset: offset,
          limit: limit,
          order: this.convertOrder(order)
        };
      } else {
        params = null;
      }
      return this.request('GameType.List', params).then(this.outputPlainItemsData.bind(this));
    };

    AdminApiClient.prototype.gameTypeCreate = function(params) {
      return this.request('GameType.Create', {
        item: params
      });
    };

    AdminApiClient.prototype.gameTypeUpdate = function(id, fields) {
      return this.request('GameType.Update', {
        pk: {
          id: id
        },
        fields: fields
      });
    };

    return AdminApiClient;

  })();
  if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
    module.exports = AdminApiClient;
  } else if (typeof window !== "undefined" && window !== null) {
    window.AdminApiClient = AdminApiClient;
  }
})();
