/**
 * This file needs a description
 * @class com.servicemax.client.sal.sfw.model.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfwOperations = SVMX.Package("com.servicemax.client.sal.sfw.model.operations");

sfwOperations.init = function(){
	 // imports
	 var Module = com.servicemax.client.sal.sfw.model.impl.Module;

	 // end imports

	 sfwOperations.Class("GetWizardInfo", com.servicemax.client.mvc.api.Operation, {
		 __constructor : function(){ this.__base(); },

		 performAsync : function(request, responder) {
	   		 var me = this;
	   		 var r = {RecordId : request.RecordId};

			 if(Module.instance.useJsr){
				SVMXJsr.JsrGetWizardInfo(r, function(result, evt){
					// TODO: Error handling
					me.__handleResponse(request, responder, result);
				}, this);
			 } else {
				 SVMX.create("com.servicemax.client.sal.sfw.model.impl.ServiceRequest", {
					 handler : function(sRequest){
						 sRequest.callMethodAsync({data : r, methodName : "getWizardInfo"});

						 sRequest.bind("REQUEST_COMPLETED", function(evt){
 							 if(evt.data){
								 me.__handleResponse(request, responder, evt.data);
							 }else{
								 responder.fault(evt.data);
							 }
						 });
					 }
				 });
			 }
		 },

		 __handleResponse : function(request, responder, resp){
            var sfwInfo = resp.SFWInfo;
            var settings = resp.Settings;

            if (sfwInfo.SFWs) {
                sfwInfo.SFWs.sort(this.__sequenceSFW);
            }

		 	Module.instance.updateSettings(settings);
		 	responder.result(sfwInfo);
		 },

         /*
          * sort function
          */
         __sequenceSFW : function(a, b) {
            // make the single digit string into double
            function makeDoubleDigit(value) {
                 var rtn = "";
                 var str = String(value);
                 if (str.length == 1) {
                    rtn = "0" + value;
                 } else {
                    rtn = str;
                 }
                return rtn;
            }

            var aseq= parseInt(a.row + "" + makeDoubleDigit(a.col));
            var bseq= parseInt(b.row + "" + makeDoubleDigit(b.col));

            return (aseq - bseq);
         }

	 }, {});

};
})();
