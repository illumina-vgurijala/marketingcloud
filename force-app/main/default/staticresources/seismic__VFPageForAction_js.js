function getOrCreateIframe(id) {
	var ifr = document.getElementById(id);
	if(ifr == null) {
		ifr = document.createElement("iframe");
		ifr.id = id;
		ifr.style.border = 'none';
		resizeWindow(ifr);
		document.body.appendChild(ifr);
	}
	
	return ifr;
}

var getWindowSize = function() {
    var e = window,
        a = 'inner';
    if (!('innerWidth' in window)) {
        a = 'client';
        e = document.documentElement || document.body;
    }

    return {
        width: e[a + 'Width'],
        height: e[a + 'Height']
    }
};

function resizeWindow(ifr) {
	ifr = ifr || document.getElementById("seismicIframe");
	if(!ifr)return;
	var size = getWindowSize();
	ifr.width = size.width;
	ifr.height = size.height;
}

window.onresize = function(){resizeWindow();};

window.setSeismicUrl = function(url) {
	url = eval("(" + url + ")");
    getOrCreateIframe("seismicIframe").src = url;
    if (navigator.userAgent.match(/Android|BlackBerry|iPhone|iPad|iPod|IEMobile/i) && window.location.search.match(/isdtp=/i)) {
        window.addEventListener("message", function(event) {
            var _ed = event.data;
            var isSeismic = (url || "").toLowerCase().indexOf((event.origin || "").toLowerCase()) > -1;
            if (isSeismic && _ed) {
                var id = _ed.substring(0, 4) == "$id:" ? _ed.substring(4) : null;
                if (id) {
                    Sfdc.canvas.publisher.publish({ name: "publisher.close", payload:{ refresh:"true" }});                    
                    sforce.one.navigateToSObject(id);
                } else {
                    window.open(_ed, "_system");
                }
            }
        }, false);
    }
};

var isInApp = false;
var searches = (window.location.search || "").replace(/^\?/, "").split("&");
for(var i = 0; i < searches.length; i++){
    if(/^isdtp\=/.test(searches[i])) {
        isInApp = true;
    }
}

var _p = window.location.host.replace(/^https?\\\:\\\/\\\//, "").replace(/-api/ig, "").split(".");
var _ist = _p.length == 3 ? _p[0] : (_p.length == 5 ? _p[1] : (_p.length == 4 && _p[1] != "visual" && _p[2] == "force" && _p[3] == "com" ? _p[1] : ""));

sforce.connection.remoteFunction({url:"https://" + _ist + ".salesforce.com/services/apexrest/seismic/jsonp/?isInApp="+isInApp+"&r=surl&oid="+window.sobjectId
	+"&btnName="+window.btnValue+"&pageUrl="+encodeURIComponent(location.href),onSuccess:function(url){
		window.setSeismicUrl(url);
	},requestHeaders:{Authorization:'Bearer '+__sfdcSessionId, Accept:"application/json, */*"}});
