(function(){

    var impl = SVMX.Package("com.servicemax.client.admin.sal.appfilters.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
        },

        beforeInitialize: function() {

        },

        initialize: function() {
            // Should usually be in beforeInitialize because we want this available ASAP
            // but for now we need it to be run after
            // sal.js which normally would be part of the VF page and already loaded
            com.servicemax.client.admin.sal.appfilters.model.operations.init();
        },

        afterInitialize: function() {

        }

    }, {});

    /**
     * Pattern used to handle platform specific calls offline vs online
     * any methods here should have an offline equivalent
     */
    impl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
        __constructor : function(){

        }


    }, {});


})();