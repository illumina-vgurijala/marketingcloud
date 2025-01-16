var searches = (window.location.search || "").replace(/^\?/, "").split("&");
var isInline = false, isInApp = false;
for(var i = 0; i < searches.length; i++){
	if((/^inline\=/.test(searches[i]) && "1" == searches[i].match(/^inline\=(.*)/)[1]) 
	   || /^isdtp\=/.test(searches[i])){
		isInline = true;
	}
	
	if(/^isdtp\=/.test(searches[i])) {
		isInApp = true;
	}
}

window.onload = function (){            
	if(window.isMobile.any() && isInApp) {
		Sfdc.canvas.controller.subscribe({name : 'seismic.openSObject', onData : function (e) {
			if(e && e.id) {
				sforce.one.navigateToSObject(e.id);
			} else if(typeof e == 'string'){
				window.open(e, '_system');
			}
		}});        
	}
}

if(isInApp) {
	document.body.style.backgroundColor = '#f0f1f2';
}

var isMobile = {
	Android: function () {
		return navigator.userAgent.match(/Android/i) ? true : false;
	},
	BlackBerry: function () {
		return navigator.userAgent.match(/BlackBerry/i) ? true : false;
	},
	iOS: function () {
		return navigator.userAgent.match(/iPhone|iPad|iPod/i) ? true : false;
	},
	Windows: function () {
		return navigator.userAgent.match(/IEMobile/i) ? true : false;
	},
	any: function () {
		return (isMobile.Android() || isMobile.BlackBerry() || isMobile.iOS() || isMobile.Windows());
	}
};