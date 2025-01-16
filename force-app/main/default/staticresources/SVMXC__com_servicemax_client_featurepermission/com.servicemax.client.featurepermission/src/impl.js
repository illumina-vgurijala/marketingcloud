(function() {

    SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXDEV";
    SVMX.appType = SVMX.getClient().getApplicationParameter("app-type") || "external";
    var instImpl = SVMX.Package("com.servicemax.client.featurepermission.impl");
    instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor: function() {
            this.__base();
            instImpl.Module.instance = this;
        },

        initialize: function() {},

        afterInitialize: function() {

        },
        beforeInitialize: function() {
            com.servicemax.client.featurepermission.api.init();
            com.servicemax.client.featurepermission.root.init();
            com.servicemax.client.featurepermission.commands.init();
            com.servicemax.client.featurepermission.operations.init();
        },

        createServiceRequest: function(params, operationObj) {
            var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
            servDef.getInstanceAsync({
                handler: function(service) {
                    var options = params.options || {};
                    var p = {
                        type: options.type || "REST",
                        endPoint: options.endPoint || "",
                        nameSpace: SVMX.OrgNamespace
                    };
                    var sm = service.createServiceManager(p);
                    var sRequest = sm.createService();
                    params.handler.call(params.context, sRequest);
                },
                context: this
            });
        },

    }, {
        instance: null
    });

    instImpl.Class("EventBus", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor: function() { this.__base(); }
    }, {
        __instance: null,
        getInstance: function() {
            if (!instImpl.EventBus.__instance) {
                instImpl.EventBus.__instance = SVMX.create("com.servicemax.client.featurepermission.EventBus", {});
            }
            return instImpl.EventBus.__instance;
        }
    });
})();