(function(){
    var impl = SVMX.Package("com.servicemax.client.spareparts.responders");

	
    impl.init = function(){ 
		impl.Class("GetProfileData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onGetProfileDataCompleted(data);
			}
		}, {});

		impl.Class("GetSparePartConfig", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetSparePartConfigCompleted(data, this.__callback);
			}
		}, {});


		impl.Class("SaveSparePartConfig", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSaveSparePartConfigCompleted(data, this.__callback);
			}
		}, {});
	};

})();
