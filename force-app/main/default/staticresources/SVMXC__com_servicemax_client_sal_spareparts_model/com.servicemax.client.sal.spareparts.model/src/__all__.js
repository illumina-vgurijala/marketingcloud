// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.spareparts.model\src\impl.js
(function(){

    var impl = SVMX.Package("com.servicemax.client.sal.spareparts.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
            this.__self.instance = this;
        },

        beforeInitialize: function() {
            com.servicemax.client.sal.spareparts.model.operations.init();
        },

        initialize: function() {
            // check if jsr should be used, only valid when running from web
            var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
            if(useJsr && useJsr === true){
                this.useJsr = true;
                //this.__logger.info("JSR is enabled. Will use this for server communication.");
            }else{
                this.useJsr = false;
            }
        },

        afterInitialize: function() {
        }
        
    }, {});


})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.spareparts.model\src\operations.js
(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.spareparts.model.operations");

    var SPAREPARTS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");

	impl.init = function(){
		var Module = com.servicemax.client.sal.spareparts.model.impl.Module.instance;  
		
		impl.Class("GetProfileData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetProfileData(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("GetSparePartConfig", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetSparePartConfig(request, function(result, evt){
	                    result = result || {};

	                    if(result.listproductstockstatus != null){
	                    	result.listproductstockstatus.forEach(function(obj){
	                    		obj.isUsed = false;
	                    	});
	                    }
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("SaveSparePartConfig", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSaveSparePartConfig(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});
	};
})();

