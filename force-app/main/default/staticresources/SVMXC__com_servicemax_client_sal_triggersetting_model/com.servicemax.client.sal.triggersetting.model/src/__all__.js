// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.triggersetting.model\src\impl.js
(function(){

    var impl = SVMX.Package("com.servicemax.client.sal.triggersetting.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
            this.__self.instance = this;
        },

        beforeInitialize: function() {
            com.servicemax.client.sal.triggersetting.model.operations.init();
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.triggersetting.model\src\operations.js
(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.triggersetting.model.operations");

    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("TRIGGERSETTING");

	impl.init = function(){
		var Module = com.servicemax.client.sal.triggersetting.model.impl.Module.instance;  
		
		impl.Class("GetObjectName", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetObjectName(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("GetObjectTrigger", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetObjectTrigger(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("SaveTriggerSetting", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSaveTriggerSetting(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});
	};
})();

