/**
 * This file needs a description 
 * @class com.servicemax.client.automation.chromeutils
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var chromeUtilsImpl = SVMX.Package("com.servicemax.client.automation.chromeutils");
	
	chromeUtilsImpl.Class("EventHelper", com.servicemax.client.lib.api.Object, { __constructor : function(){} }, {
		sendKeysFromString : function(strKeys, targetEl){
			var i , l = strKeys.length, code;
			for(i = 0; i < l; i++){
				code = strKeys.charCodeAt(i);
				chromeUtilsImpl.EventHelper.sendCharCode(code, targetEl);
			}
		},
		
		sendEnterKey : function(targetEl){
			chromeUtilsImpl.EventHelper.sendKeyCode(13, targetEl);
		},
		
		sendDeleteKey : function(targetEl){
			chromeUtilsImpl.EventHelper.sendCharCode(46, targetEl);
		},
		
		sendBackspaceKey : function(targetEl){
			chromeUtilsImpl.EventHelper.sendCharCode(8, targetEl);
		},
		
		sendKeyCode : function(keyCodeVal, targetEl){
			var e = document.createEvent('KeyboardEvent');
			e.keyCodeVal = keyCodeVal;
			Object.defineProperty(e, 'keyCode', {     
                get : function(){
                    return this.keyCodeVal;
                }
            })
            
			e.initKeyboardEvent('keydown', true, false, null, 0, 0, 0, 0, keyCodeVal, 0);
			targetEl.dispatchEvent(e);
		},
		
		sendCharCode : function(charCodeVal, targetEl){
			var e = document.createEvent('KeyboardEvent');
            
            Object.defineProperty(e, 'keyCode', {     
                get : function(){
                    return this.charCodeVal;
                }
            })
            
             Object.defineProperty(e, 'which', {     
                get : function(){
                    return this.charCodeVal;
                }
            })

			e.initKeyboardEvent('keypress', true, true, document.defaultView, false, false, false, false, charCodeVal, charCodeVal);
			e.charCodeVal = charCodeVal;
			targetEl.value += String.fromCharCode(charCodeVal);
			targetEl.dispatchEvent(e);
		}
	});
})();

// end of file
