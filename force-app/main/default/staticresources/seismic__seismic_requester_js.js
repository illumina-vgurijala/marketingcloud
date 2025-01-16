var MessageHandlers = {
  openDocumentDetail: function (data) {
    var url = null;
    if(data.url) {
      url = data.url;
    } else if(data.params) {
      url = docViewerUrl + data.params + (_getParamsFromUrl() || '');
    }
    
    if(isLightning){
        var detailUrl=packageBaseUrl;
            detailUrl+=docViewerUrl;
            detailUrl+=data.params;
            detailUrl+='&fromUrl=' + encodeURIComponent(window.location.href);
            detailUrl+='&ILE='+isLightning;
		window.location.href = detailUrl;
	}
    else{
        window.top.location.href = url+'&ILE='+isLightning;
    }
  },

  pushState: function (data) {
    window.history.pushState("", "", _buildUrl(data));
  }
}

function _buildUrl(data) {
  var url = data.url;
  if(/^&/.test(data.url)) {
    var params = window.location.search.replace(/^\?/, '').split('&').map(function(v){
      return v.split("=")
    });

    var result = window.location.search;
    data.url.replace(/^&/, '').split('&').forEach(function(v){
      var key = v.split('=')[0],
        value = v.split('=')[1];

        if(result.indexOf('&' + key + '=') > -1 || result.indexOf('?' + key + '=') > -1) {
          result = result.replace(new RegExp('(&|\\?)' + key + '=[^&]*'), '$1' + key + '=' + value)
        } else {
          result += (window.location.search.indexOf('?') == 0 ? '&' : '?') + key + '=' + value;
        }
    });

    url = result;
  }

  return url;
}

function _getParamsFromUrl () {
  var url = '';
  if (window.location.search && window.location.search.length > 1) {
    var queryString = window.location.search.substring(1);
    var querySections = queryString.split('&');
    for (var index in querySections) {
      var querySection = querySections[index];
      if (querySection && typeof querySection == 'string') {
        var equalIndex = querySection.indexOf('=');
        if (equalIndex > 0) {
          var name = querySection.substr(0, equalIndex);
          var value = querySection.substring(equalIndex + 1);
          switch (name.toLowerCase()) {
            case "isdtp":
              url += "&isdtp=" + value;
              break;
            case "sfdcIFrameOrigin".toLowerCase():
              url += "&sfdcIFrameOrigin=" + value;
              break;
            case "sfdcIFrameHost".toLowerCase():
              url += "&sfdcIFrameHost=" + value;
              break;
          }
        }
      }
    }
  }

  url += '&fromUrl=' + encodeURIComponent(window.location.href);

  return url;
}

window.addEventListener("message", function(e){
  if(e && e.data) {
    try{
      var data = JSON.parse(e.data);
      if(data && data.isFromSeismic) {
        var method = data.method;
        if(MessageHandlers[method]) {
          MessageHandlers[method](data);
        }
      }
    } catch(e){}
  }
});