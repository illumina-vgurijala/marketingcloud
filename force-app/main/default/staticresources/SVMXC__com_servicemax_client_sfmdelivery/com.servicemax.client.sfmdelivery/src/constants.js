/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.constants
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var constantsImpl = SVMX.Package("com.servicemax.client.sfmdelivery.constants");

constantsImpl.init = function(){
	constantsImpl.Class("Constants", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		NO_VALUE 						: "noValue",
		RECORD_TYPE_ID 					: "RecordTypeId",
		PREF_LOGGING					: "LOGGING",
		LOOKUP_CALL_TYPE_BOTH			: "BOTH",
		LOOKUP_CALL_TYPE_DATA			: "DATA",
		LOOKUP_CALL_TYPE_META			: "META"
	});
}
})();

// end of file
