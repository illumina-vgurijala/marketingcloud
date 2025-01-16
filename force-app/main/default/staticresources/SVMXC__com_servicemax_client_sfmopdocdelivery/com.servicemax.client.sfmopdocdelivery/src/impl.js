/**
 * This file needs a description
 * @class com.servicemax.client.sfmopdocdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfmopdocdeliveryImpl = SVMX.Package("com.servicemax.client.sfmopdocdelivery.impl");

	sfmopdocdeliveryImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
		},

		beforeInitialize : function(){
			com.servicemax.client.sfmopdocdelivery.utils.init();
			com.servicemax.client.sfmopdocdelivery.constants.init();
			com.servicemax.client.sfmopdocdelivery.engine.init();
			com.servicemax.client.sfmopdocdelivery.commands.init();
		}

	}, {});

	sfmopdocdeliveryImpl.Class("SFMOPDOCDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); },

		triggerEvent : function(e) {
			SVMX.getLoggingService().getLogger("SFMOPDOCDeliveryEngineEventBus").info("Trigger event : " + e.type);
			return this.__base(e);
		}

	}, {});

})();
