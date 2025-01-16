/**
 * This file needs a description
 * @class com.servicemax.client.sfwdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfwImpl = SVMX.Package("com.servicemax.client.sfwdelivery.impl");

	sfwImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("SFW-IMPL");
		},

		beforeInitialize : function(){
			com.servicemax.client.sfwdelivery.engine.init();
			com.servicemax.client.sfwdelivery.commands.init();
			com.servicemax.client.sfwdelivery.responders.init();
		},

		initialize : function(){
			// hack: force DEFAULT theme (temporary)
			/*var origMethod = SVMX.getUrlParameter;
			SVMX.getUrlParameter = function(name){
				if(name == 'theme'){
					return 'DEFAULT';
				}
				return origMethod(name);
			};*/
		},

		afterInitialize : function(){
		}

	});

	sfwImpl.Class("SFWDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); },

		triggerEvent : function(e) {
			SVMX.getLoggingService().getLogger("SFWDeliveryEngineEventBus").info("Trigger event : " + e.type);
			return this.__base(e);
		}

	}, {});

})();