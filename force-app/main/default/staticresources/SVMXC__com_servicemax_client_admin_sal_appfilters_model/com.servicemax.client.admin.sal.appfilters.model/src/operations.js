
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