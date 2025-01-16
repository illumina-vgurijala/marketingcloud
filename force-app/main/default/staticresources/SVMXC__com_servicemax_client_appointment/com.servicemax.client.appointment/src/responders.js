
(function(){
    var impl = SVMX.Package("com.servicemax.client.appointment.responders");

	
    impl.init = function(){
		
		impl.Class("GetAppointmentSettings", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onGetAppointmentSettingsCompleted(data);
			}
		}, {});

		impl.Class("GetWorkDetails", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onGetWorkDetailsCompleted(data);
			}
		}, {});

		impl.Class("BookAppointment", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__callback = callback;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onBookAppointmentCompleted(data, this.__callback);
			}
		}, {});

		/*impl.Class("StartOptimaxJob", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__callback = callback;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onStartOptimaxJobCompleted(data, this.__callback);
			}
		}, {});*/

		impl.Class("GetOfferAppointments", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__callback = callback;
				this.__base(); 
			},

			result : function(data) {
				this.__engine.onGetOfferAppointmentsCompleted(data, this.__callback);
			}
		}, {});
    };

})();
