((function() {
  var TIMEOUT = 45000;
  var cometd = window.org.cometd;

  function _setHeaders(xhr, headers) {
    if (headers) {
      for (var headerName in headers) {
        if (headers.hasOwnProperty(headerName)) {
          if (headerName.toLowerCase() === 'content-type') {
            continue;
          }
          xhr.setRequestHeader(headerName, headers[headerName]);
        }
      }
    }
  }

  function post(options) {
    var xhr = new XMLHttpRequest();
    xhr.withCredentials = true;
    xhr.timeout = TIMEOUT;

    xhr.addEventListener('load', function (e) {
      var status = xhr.status;

      if (status >= 200 && status < 300 || status === 304) {
        var result = xhr.response;
        options.success(result, status, xhr);
      } else {
        options.error(status, e);
      }
    });

    xhr.addEventListener('error', function (e) {
      options.error(xhr.status, e);
    });

    xhr.addEventListener('timeout', function (e) {
      options.error(408, e);
    });

    xhr.open('POST', options.url, true);
    xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8')
    _setHeaders(xhr, options.headers)

    xhr.send(options.data);
  }

  function LongPollingTransport() {
    var _super = new cometd.LongPollingTransport();
    var that = cometd.Transport.derive(_super);

    that.xhrSend = function(packet) {
      post({
        url: packet.url,
        data: packet.body,
        headers: packet.headers,
        success: function(result, status, xhr) {
          if (xhr.aborted) {
            return;
          }

          packet.onSuccess(result,status,xhr);
        },
        error: function(reason, exception) {
          packet.onError(reason, exception);
        }
      });
    };

    return that;
  }

  var CharketCometd = function() {
    var instance = new cometd.CometD();
    instance.unregisterTransports();
    instance.registerTransport('long-polling', new LongPollingTransport());

    return instance;
  };

  window.CharketCometd = CharketCometd;
})());
