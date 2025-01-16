
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplan.responders");

	
    impl.init = function(){ 
		impl.Class("GetPMPlanData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 

			},

			result : function(data) {
				this.__engine.onGetPMPlanDataCompleted(data);
			}
		}, {});

		impl.Class("GetPMTemplateData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetPMTemplateData(data, this.__callback);
			}
		}, {});

		impl.Class("SearchObject", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSearchObjectCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("SavePMPlanData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSavePMPlanCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("GetCoverageScheduleData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetCoverageScheduleDataCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("GetCoverageTechnicalAtt", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetCoverageTechnicalAttCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("ValidateExpression", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onValidateExpressionCompleted(data, this.__callback);
			}
		}, {});
	};

})();
