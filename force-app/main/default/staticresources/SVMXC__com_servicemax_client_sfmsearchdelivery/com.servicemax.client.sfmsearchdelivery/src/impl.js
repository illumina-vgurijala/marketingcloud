/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {

    var sfmsearchdeliveryImpl = SVMX.Package("com.servicemax.client.sfmsearchdelivery.impl");

    sfmsearchdeliveryImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor: function() {
            this.__base();
        },

        beforeInitialize: function() {

        },

        initialize: function() {
            com.servicemax.client.sfmsearchdelivery.commands.init();
            com.servicemax.client.sfmsearchdelivery.responders.init();
            com.servicemax.client.sfmsearchdelivery.engine.init();
        },

        afterInitialize: function() {
        }
    });

    sfmsearchdeliveryImpl.Class("SFMSearchDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor: function() {
            this.__base();
        },

        triggerEvent: function(e) {
            SVMX.getLoggingService().getLogger("SFMSearchDeliveryEngineEventBus").info("Trigger event : " + e.type);
            return this.__base(e);
        }

    }, {});

    sfmsearchdeliveryImpl.Class("UIElementsCreationHelper", com.servicemax.client.lib.api.Object, {
        __constructor: function() {},

        doCreate: function(className, config) {
            var obj = Ext.create(className, config);
            obj.__self = Ext.ClassManager.getClass(obj);
            return obj;
        }
    }, {});
})();

// end of file
