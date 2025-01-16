/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfmdeliveryImpl = SVMX.Package("com.servicemax.client.sfmdelivery.impl");

	sfmdeliveryImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize : function(){
			// this is the place to
			// 01. Initialize the packages which depend on APIs from other modules
			com.servicemax.client.sfmdelivery.constants.init();
			com.servicemax.client.sfmdelivery.responders.init();
			//Below are requires to load before initialize for the sfmdelivery.ui.** modules
			com.servicemax.client.sfmdelivery.utils.init();
			com.servicemax.client.sfmdelivery.operationutils.init();
		},

		initialize : function(){

			//TODO: Not so good to initialize sub packages here.
			// Need to figure out a way to chain initializations
			com.servicemax.client.sfmdelivery.commands.init();
			com.servicemax.client.sfmdelivery.engine.init();
			//com.servicemax.client.sfmdelivery.slaclock.init();
			//com.servicemax.client.sfmdelivery.attachments.init();
		},

		afterInitialize : function(){

			var serv = SVMX.getClient().getServiceRegistry()
								.getService("com.servicemax.client.preferences").getInstance();
			serv.addPreferenceKey("SFMD-EXT-TEXT-AREA");
			serv.addPreferenceKey("SFMD-EXT-EDIT");
			serv.addPreferenceKey("SFMD-LUP-WINDOW");
		}

	}, {});

	sfmdeliveryImpl.Class("SFMUIElementsCreationHelper", com.servicemax.client.lib.api.Object, {
		__constructor : function(){},

		doCreate : function(className, config){
			var obj = Ext.create(className, config);
			obj.__self = Ext.ClassManager.getClass(obj);
			return obj;
		}
	}, {});

	sfmdeliveryImpl.Class("SFMDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__de : null,
		__constructor : function(de){
			this.__base();
			this.__de = de;
		},

		triggerEvent : function(e) {
			SVMX.getLoggingService().getLogger("SFMDeliveryEngineEventBus").info("Trigger event : " + e.type);
			return this.__base(e);
		},

		getDeliveryEngine : function(){
			return this.__de;
		}

	}, {});
})();