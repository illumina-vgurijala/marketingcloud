
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplan.commands");

	impl.init = function(){

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});

	    impl.Class("GetPMPlanData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_PMPLAN_DATA"});
	        }
	    }, {});

	    impl.Class("GetPMTemplateData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_PMTEMPLATE_DATA"});
	        }
	    }, {});

	    impl.Class("SavePMPlanData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.SAVE_PMPLAN_DATA"});
	        }
	    }, {});

	    impl.Class("GetCoverageScheduleData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_COVERAGE_SCHEDULE_DATA"});
	        }
	    }, {});

	    impl.Class("GetCoverageTechnicalAtt", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_COVERAGE_TECHNICAL_ATTRIBUTE"});
	        }
	    }, {});

	    impl.Class("ValidateExpression", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.VALIDATE_EXPRESSION"});
	        }
	    }, {});

	    impl.Class("SearchObject", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.OBJECT_SEARCH"});
	        }
	    }, {});
	};

})();
