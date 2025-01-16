/**
 * This file needs a description 
 * @class com.servicemax.client.sfmconsole.constants
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var constantsImpl = SVMX.Package("com.servicemax.client.sfmconsole.constants");

constantsImpl.init = function(){
	constantsImpl.Class("Constants", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		PREF_LOGGING					: "LOGGING"
	});
}	
})();

// end of file
