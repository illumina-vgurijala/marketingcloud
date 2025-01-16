/**
 *
 * @class com.servicemax.client.opt.engine
 * @singleton
 * @author Abhishek
 */

(function() {
    var engine = SVMX.Package("com.servicemax.client.opt.engine");

    engine.init = function() {
        // Need to set up translation tags for APFT
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("OPT");

        engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
            __root: null,
            __loadMask: null,
            __isContainerExternal: null,
            __parent: null,
            __translation: null,
            __view: null,
            __constructor: function() {
                this.__base();
                this.__isContainerExternal = false;
            },

            initAsync: function(options) {

                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.opt.impl.APFTEngineEventBus", {});

                // create the named default controller
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        // now create the named default model
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                // Now it is the view's turn
                                ni.createNamedInstanceAsync("APFT.VIEW",{ handler : function(view){
                                    this.__view = view;
                                    options.handler.call(options.context);
                                }, context: this, additionalParams: {eventBus: this.getEventBus()}});
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: {
                        eventBus: this.__eventBus
                    }
                });
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            translate: function(key) {
                return TS.T(key);
            },

            getAllTranslation: function() {
                return this.__translation;
            },

            __appCurrentState: "",
            changeApplicationState: function(newState) {
                if (this.__appCurrentState === newState) return;

                this.__appCurrentState = newState;
                if (newState == "block") {
                    if (!this.__loadMask) {
                        this.__loadMask = new com.servicemax.client.ui.components.utils.LoadMask({
                            parent: this.__root
                        });
                    }
                    this.__loadMask.show({});
                    this.__loadMask.setZIndex(50000); // some high number
                } else if (newState == "unblock" && this.__loadMask !== null) {
                    if (this.__loadMask !== null) {
                        this.__loadMask.hide();
                    }
                }
            },

            reset: function() {
                this.getRoot().destroy();
                this.__root = null;
                this.run(this.options);
            },

            triggerEvent: function(evt) {
                this.__eventBus.triggerEvent(evt);
            },

            run: function(options) {
                this.options = options || {};
                var actualResult = [];

                this.__metaModel = SVMX.create("com.servicemax.client.opt.engine.APFTMetaModel", this, actualResult);
                this.__metaModel.initialize();

                // This is defined in sfmchecklistadmindelivery.ui.desktop/manifest/module.json file
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    metaModel: this.__metaModel,
                    deliveryEngine: this
                });
                
                // Render in our root div.
                this.__root.render(SVMX.getDisplayRootId());

                //var containerHeight = (this.__isContainerExternal) ? Ext.getDom("client_display_root").parentNode.clientHeight : Ext.getBody().getViewSize().height;
               

                if (!SVMX.getClient().getApplicationParameter("svmx-sfm-no-window-resize")) {
                    SVMX.onWindowResize(function(){
                        var height = Ext.getBody().getViewSize().height;
                        var width =  Ext.getBody().getViewSize().width;

                        if (this.__isContainerExternal){
                            if (!!this.__parent) {
                                height = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
                                width =  Math.max(document.documentElement.clientWidth, window.innerWidth || 0);

                                height = (height > 0) ?  (height - this.__parent.heightOffset): height;
                                width =  (width > 0) ? (width - this.__parent.widthOffset): width;
                            } else {
                                height = Ext.getDom("client_display_root").parentNode.clientHeight;
                                width =  Ext.getDom("client_display_root").parentNode.clientWidth;
                            }
                        }
                        var size = {
                            width: width,
                            height: height
                        };

                        this.onResize(size);
                    }, this);
                }
                
                this.__root.setHeight(containerHeight);

                if (this.options.onReady) {
                    this.options.onReady.handler.call(this.options.onReady.context || this);
                }
            },

            onprocessLatestRunCompleted: function(result){
                var LatestRuntList = result.message;
               this.__root.reportLatestRuns(LatestRuntList);
            },
            onpurgeLatestRunCompleted: function(result){
                var purgeLatestRunList = result.message;
                this.__root.purgeLatestRun(purgeLatestRunList);
            },
            ongetJobListForPurgeCompleted: function(result){
                this.__root.getJobListForPurge(result);
            },
            ongetJobListForExecutionCompleted: function(result){
                this.__root.getJobListForExecution(result);
            },
            onpurgeSelectedRunsCompleted: function(result){
                var purgeSelectedRunsList = result.message;
                this.__root.purgeSelectedRuns(purgeSelectedRunsList);
            },
            onexecutionSelectedRunsCompleted: function(result){
                var executionSelectedRunsList = result.message;
                this.__root.executionSelectedRuns(executionSelectedRunsList);
            },
            onloadDispatchProcessNamesCompleted: function(result){
                this.__root.loadDispatchProcessNames(result);
            },
            onsaveOptConfigurationCompleted: function(result){
                this.__root.saveOptConfiguration(result);
            },
            
            processLatestRunHandler : function(){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.processLatestRun", this);
                var request = {};

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_PROCESS_LATEST_RUN', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            
            purgeLatestRunHandler : function(){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.purgeLatestRun", this);
                var request = {};

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_PURGE_LATEST_RUN', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            
            getJobListForPurgeHandler: function(param){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.getJobListForPurge", this);
                var request = param;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_JOB_LIST_FOR_PURGE', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            getJobListForExecutionHandler: function(param){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.getJobListForExecution", this);
                var request = param;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_JOB_LIST_FOR_EXECUTION', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            
            purgeSelectedRunsHandler: function(){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.purgeSelectedRuns", this);
                var request = param;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_PURGE_SELECTED_RUNS', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            executionSelectedRunsHandler: function(param){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.executionSelectedRuns", this);
                var request = param;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_EXECUTION_SELECTED_RUNS', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            loadDispatchProcessNamesHandler: function(){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.loadDispatchProcessNames", this);
            	var request = {};

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.LOAD_DISPATCH_PROCESS_NAME', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            saveOptConfigurationHandler: function(param){
            	var responder = SVMX.create("com.servicemax.client.opt.responders.saveOptConfiguration", this);
            	var request = param;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.SAVE_OPT_CONFIGURATION', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },
            showMessage: function(mesg, title){
                Ext.Msg.show({
                    title : title,
                    msg : mesg,
                    width : 300,
                    closable : false,
                    buttons : Ext.Msg.OK,
                    buttonText : {
                        ok : TS.T("TAG020","OK")
                    },
                    fn : function(buttonValue, inputText, showConfig){
                    }
                });
            },

            getRoot: function() {
                return this.__root;
            },

            onResize: function(size) {
                this.getRoot().resize(size);
            }
        }, {});

        /**
         * MetaModel
         */
        engine.Class("APFTMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null,
            __data: null,

            __constructor: function(engine, data) {
                this.__parent = engine;
                this.__data = data;
            },

            initialize: function() {

            },  

            getQuestionInfo: function(){
                return this.__data;
            },

            addQuestionList: function(queList){
                this.__data = queList;
            },

            destroy: function() {
                this.__data = null;
            }
        }, {});
    };
})();
// end of file