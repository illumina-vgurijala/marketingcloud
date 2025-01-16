/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.utils
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfmdeliveryutil = SVMX.Package("com.servicemax.client.sfmdelivery.utils");

sfmdeliveryutil.init = function(){
	// imports
	var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");
	// end imports

	/**
	 * Class to provide all the utility methods for SFMDelivery.
	 * Currently contains util functions fadein, fadeout, required and invalid messages
	 */
	sfmdeliveryutil.Class("SFMUtils", com.servicemax.client.lib.api.Object, {
			__constructor : function(){
				//TODO :
			}
		}, {
			fadeIn : function(elId){
				var lIntr = setInterval(function(){
					lCurrentOpacity += .2;
					$("#" + elId).css("opacity", lCurrentOpacity <= 1.0 ? lCurrentOpacity : 1.0);

					if(lCurrentOpacity >= 1.0){
						clearInterval(lIntr);
					}

				}, 50), lCurrentOpacity = 0;
			},

			fadeOut : function(elId, optionalCallback){
				var lIntr = setInterval(function(){
					lCurrentOpacity -= .2;
					$("#" + elId).css("opacity", lCurrentOpacity >= 0.0 ? lCurrentOpacity : 0.0);

					if(lCurrentOpacity <= 0.0){
						clearInterval(lIntr);
						if (optionalCallback) optionalCallback();
					}

				}, 50), lCurrentOpacity = 1;
			},

			//message to be displayed in error ui comp when required field is empty
			requiredFieldErrMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG127", "Required field is blank:") + " " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when required field is empty
			requiredFieldDescriptionMessage : function(fieldLabel){
				var msg = TS.T("FSA002_TAG030", "Required description field") + ": " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when invalid data is entered in a field
			invalidFieldErrMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG128", "Invalid value in field:") + " " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when field length exceeds maximum
			exceedsLengthFieldMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG120", "Exceeds maximum length: ") + " " + fieldLabel;
				return msg;
			},

			prepareDataForDisplay : function(data, type){
				if(type == "textarea" || type == "string"){
					if(data){
						data = data.split("<").join("&lt;");
				    	data = data.split(">").join("&gt;");
				    	data = data.split('"').join("&quot;");
					}
				}
				return data;
			},

			prepareDataForEdit : function(data, type){
				return data;
			}
	});
}
})();
// end of file