(function(){

    var impl = SVMX.Package("com.servicemax.client.sal.spareparts.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
            this.__self.instance = this;
        },

        beforeInitialize: function() {
            com.servicemax.client.sal.spareparts.model.operations.init();
        },

        initialize: function() {
            // check if jsr should be used, only valid when running from web
            var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
            if(useJsr && useJsr === true){
                this.useJsr = true;
                //this.__logger.info("JSR is enabled. Will use this for server communication.");
            }else{
                this.useJsr = false;
            }
        },

        afterInitialize: function() {
        }
        
    }, {});


})();