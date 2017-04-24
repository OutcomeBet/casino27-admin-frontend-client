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
      var host, m;
      this.url = options.url, this.onopen = options.onopen, this.onclose = options.onclose, this.log = options.logFn;
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
      return req.send(this.client).then((function(_this) {
        return function(data) {
          if (typeof _this.log === "function") {
            _this.log('in', id, action, data);
          }
          return data;
        };
      })(this))["catch"]((function(_this) {
        return function(err) {
          if (typeof _this.log === "function") {
            _this.log('err', id, action, err);
          }
          return null;
        };
      })(this));
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

    AdminApiClient.prototype.casinoList = function() {
      return this.request('Casino.List');
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

    AdminApiClient.prototype.casinoUpdate = function(id, params) {
      return this.request('Casino.Update', {
        pk: {
          id: id
        },
        item: params
      });
    };

    AdminApiClient.prototype.gameList = function(filter, order, offset, limit) {
      var params;
      if (filter || order || offset || limit) {
        params = {
          beta_filter: filter,
          offset: offset,
          limit: limit
        };
      } else {
        params = null;
      }
      return this.request('Game2.List', params).then(function(data) {
        data.items = data.items.map(function(item) {
          return item.item;
        });
        return data;
      });
    };


    /**
     * Create Game
     * @param {object <string_id, section>} params - Casino params
     */

    AdminApiClient.prototype.gameCreate = function(params) {
      return this.request('Game2.Create', {
        item: params
      });
    };

    AdminApiClient.prototype.gameUpdate = function(id, params) {
      return this.request('Game2.Update', {
        pk: {
          id: id
        },
        fields: params
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
