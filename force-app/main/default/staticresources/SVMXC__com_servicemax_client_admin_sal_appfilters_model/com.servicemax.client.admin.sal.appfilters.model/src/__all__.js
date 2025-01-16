// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.sal.appfilters.model\src\impl.js
(function(){

    var impl = SVMX.Package("com.servicemax.client.admin.sal.appfilters.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
        },

        beforeInitialize: function() {

        },

        initialize: function() {
            // Should usually be in beforeInitialize because we want this available ASAP
            // but for now we need it to be run after
            // sal.js which normally would be part of the VF page and already loaded
            com.servicemax.client.admin.sal.appfilters.model.operations.init();
        },

        afterInitialize: function() {

        }

    }, {});

    /**
     * Pattern used to handle platform specific calls offline vs online
     * any methods here should have an offline equivalent
     */
    impl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
        __constructor : function(){

        }


    }, {});


})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.sal.appfilters.model\src\operations.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.admin.sal.appfilters.model.operations");

	impl.init = function(){

		var AppFilJsr=window.SVMXJsr;
		impl.Class("GetSupportedRecordTypes", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = AppFilJsr.JsrGetSupportedRecordTypes(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetAllSourceObjects", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = AppFilJsr.JsrGetAllSourceObjects(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetApplicationFilter", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = AppFilJsr.JsrGetApplicationFilter(request, function(data){
	            		var dataAsObject = SVMX.toObject(data);
	            		for(var i=0; i<dataAsObject.filterInfoList.length; i++){
	            			dataAsObject.filterInfoList[i].processId = Ext.String.htmlEncode(dataAsObject.filterInfoList[i].processId);
	            			dataAsObject.filterInfoList[i].name = Ext.String.htmlEncode(dataAsObject.filterInfoList[i].name);
	            			dataAsObject.filterInfoList[i].description = Ext.String.htmlEncode(dataAsObject.filterInfoList[i].description);
	            		}
	            		responder.result(dataAsObject);	
	            	}, this);
	            }
	    }, {});

	    impl.Class("SaveApplicationFilter", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = AppFilJsr.JsrSaveApplicationFilter(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});
	};
})();

