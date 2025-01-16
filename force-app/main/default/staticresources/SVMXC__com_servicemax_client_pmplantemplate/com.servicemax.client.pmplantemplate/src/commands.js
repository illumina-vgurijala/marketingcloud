
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.commands");

	impl.init = function(){
	    impl.Class("GetFilterList", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_FILTER_LIST"});
	        }
	    }, {});

	    impl.Class("GetTaskTemplate", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_TASK_TEMPLATE"});
	        }
	    }, {});

	    impl.Class("GetActivityDateList", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_ACTIVITY_DATE_LIST"});
	        }
	    }, {});

	    impl.Class("GetPicklistValues", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_PICKLIST_VALUES"});
	        }
	    }, {});

	    impl.Class("SaveTemplateData", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.SAVE_TEMPLATE_DATA"});
	        }
	    }, {});

	    impl.Class("SearchObject", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.SEARCH_OBJECT"});
	        }
	    }, {});

	    impl.Class("GetRecordInfo", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_RECORD_INFO"});
	        }
	    }, {});

	    impl.Class("GetTechnicalAttribute", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_TECHNICAL_ATTRIBUTE"});
	        }
	    }, {});

	    impl.Class("GetSampleSchedules", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_SAMPLE_SCHEDULES"});
	        }
	    }, {});
	};
})();
