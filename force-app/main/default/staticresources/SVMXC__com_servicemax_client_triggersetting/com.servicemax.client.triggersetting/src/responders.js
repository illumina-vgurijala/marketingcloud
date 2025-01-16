(function(){
    var impl = SVMX.Package("com.servicemax.client.triggersetting.responders");

	
    impl.init = function(){ 
		impl.Class("GetObjectName", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onGetObjectNameCompleted(data);
			}
		}, {});

		impl.Class("GetObjectTrigger", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetObjectTriggerCompleted(data, this.__callback);
			}
		}, {});


		impl.Class("SaveTriggerSetting", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSaveTriggerSettingConfig(data, this.__callback);
			}
		}, {});
	};

})();
