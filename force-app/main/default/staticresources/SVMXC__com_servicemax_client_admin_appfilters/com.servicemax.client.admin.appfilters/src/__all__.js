// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.appfilters\src\commands.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.admin.appfilters.commands");

	impl.init = function(){
		impl.Class("GetSupportedRecordTypes", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_SUPPORTED_RECORD_TYPES"});
	        }
	    }, {});

		impl.Class("GetAllSourceObjects", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_ALL_SOURCE_OBJECTS"});
	        }
	    }, {});

	    impl.Class("GetApplicationFilter", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_APPLICATION_FILTER"});
	        }
	    }, {});

	    impl.Class("SaveApplicationFilter", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.SAVE_APPLICATION_FILTER"});
	        }
	    }, {});
	};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.appfilters\src\console.js
/**
 * APFT console app
 * @class com.servicemax.client.sfmsearchdelivery.console
 * @author Unknown
 * @copyright 2013 ServiceMax, Inc.
 */
(function() {

    var console = SVMX.Package("com.servicemax.client.admin.appfilters.console");

    console.init = function() {

        /**
         * So we can live offline in the SFM Console, Summer 15 release will move this out of here and completely separate UI from the controller/common modules
         */
        console.Class("ConsoleAppImpl", com.servicemax.client.sfmconsole.api.AbstractConsoleApp, {
            engine: null,
            __options: null,

            start: function(options) {
                options = options || {};

                this.__options = options;

                this.showLoadMask();

                var engine = SVMX.create("com.servicemax.client.admin.appfilters.engine.DeliveryEngineImpl");
                this.engine = engine.getInterface();

                this.engine.initAsync({
                    handler: this.__onEngineInit,
                    context: this
                });
                console.log('Inside start');
            },

            __onEngineInit: function() {
                this.engine.run({
                    onReady: {
                        handler: this.__onEngineReady,
                        context: this
                    }
                });
            },

            __onEngineReady: function() {
                this.setRootContainer(this.engine.getRoot());
                this.hideLoadMask();

                this.setAppInfo({
                    groupName: '',
                    windowTitle: this.engine.translate("TAG0002")
                });
            },

            onClose: function() {

            },

            onAppHide: function(event) {
                // TODO: got to sleep
            },

            // On waking up, refresh all showing search results
            onAppShow: function(event) {
                // TODO: wake up
            },

            // On reset, refresh all searches and either clear all searches or refresh all searches
            reset : function() {
                if (this.engine) {
                    this.engine.reset();
                }
            },

            onAppResize: function(event) {
                if (this.engine.getRoot()) {
                    this.engine.getRoot().resize(event);
                }
            }

        }, {});

    };
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.appfilters\src\engine.js
/**
 * This file needs a description
 * @class com.servicemax.client.admin.appfilters.engine
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {
    var engine = SVMX.Package("com.servicemax.client.admin.appfilters.engine");

    engine.init = function() {
        // Need to set up translation tags for APFT
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("APFT");

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
                this.__eventBus = SVMX.create("com.servicemax.client.admin.appfilters.impl.APFTEngineEventBus", {});

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

                var responder = SVMX.create("com.servicemax.client.admin.appfilters.responders.GetSupportedRecordTypesResponder", this);
                var request = {};

                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_SUPPORTED_RECORD_TYPES', this, 
                    { request: request, responder: responder }
                );

                this.triggerEvent(evt);
            },

            onGetSupportedRecordTypesCompleted: function(result){
                var filterArrayList = result.objectInfoList;
                var actualResult = [{
                        'label' : TS.T("TAG003", "--None--"),
                        'name' : 'None'
                    }
                ];
                for(var i=0; i<filterArrayList.length; i++){
                    actualResult.push(filterArrayList[i]);
                }

                this.__metaModel = SVMX.create("com.servicemax.client.admin.appfilters.engine.APFTMetaModel", this, actualResult);
                this.__metaModel.initialize();

                // This is defined in sfmchecklistadmindelivery.ui.desktop/manifest/module.json file
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    metaModel: this.__metaModel,
                    deliveryEngine: this
                });

                this.__root.run({
                    // Any options that should be passed.
                });

                // Render in our root div.
                this.__root.render(SVMX.getDisplayRootId());

                var containerHeight = (this.__isContainerExternal) ? Ext.getDom("client_display_root").parentNode.clientHeight : Ext.getBody().getViewSize().height;

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

            getAllSourceObjects: function(data){
                this.changeApplicationState("block");
                var request = {
                    'recordTypeName': data
                };
                var responder = SVMX.create("com.servicemax.client.admin.appfilters.responders.GetAllSourceObjectsResponder", this);
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_ALL_SOURCE_OBJECTS', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetAllSourceObjectsCompleted: function(result){
                //Added for the defect 032913 fix
                if(!result.success){
                    this.showMessage(result.message, TS.T("TAG018","Failure"));
                    this.changeApplicationState("unblock");
                    return;
                }

                var objectArrayList = result.objectInfoList;
                var actualResult = [{
                        'label' : TS.T("TAG003", "--None--"),
                        'name' : 'None'
                    }
                ];
                for(var i=0; i<objectArrayList.length; i++){
                    actualResult.push(objectArrayList[i]);
                }
                this.__root.__objectListStore.loadData(actualResult);
                this.changeApplicationState("unblock");
            },

            getApplicationFilter: function(filterName, objectName){
                this.changeApplicationState("block");
                var request = {
                    'recordTypeName': filterName,
                    'sourceObjectName': objectName
                };
                var responder = SVMX.create("com.servicemax.client.admin.appfilters.responders.GetApplicationFilterResponder",this);
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.GET_APPLICATION_FILTER', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },  
            onGetApplicationFilterCompleted: function(result){
                //Added for the defect 032913 fix
                if(!result.success){
                    this.showMessage(result.message, TS.T("TAG018","Failure"));
                    this.changeApplicationState("unblock");
                    return;
                }
                
                var WizList = result.filterInfoList;
                this.__root.__lastModifiedDateOfRecords = result.lastModifiedOn;
                this.__root.__tableStore.loadData(WizList);
                this.__root.__searchtext.setValue('');
                this.__root.__resultsViewPanel.store.sync();
                this.changeApplicationState("unblock");
            },

            saveApplicationFilter: function(modifiedRecords){
                this.changeApplicationState("block");
                var request = this.transformModifiedRecordsInRequest(modifiedRecords);
                var responder = SVMX.create("com.servicemax.client.admin.appfilters.responders.SaveApplicationFilterResponder",this);
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'APFT.SAVE_APPLICATION_FILTER', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onSaveApplicationFilterCompleted: function(result){
                this.changeApplicationState("unblock");
                if(result.success){
                    this.__root.__lastModifiedDateOfRecords = result.lastModifiedOn;
                    this.__root.__searchtext.setValue('');
                    this.__root.__resultsViewPanel.store.sync();
                    this.__root.__saveButton.setDisabled(true);
                    this.showMessage(result.message, TS.T("TAG017","Success"));
                }
                else{
                    this.showMessage(result.message, TS.T("TAG018","Failure"));
                }
            },

            transformModifiedRecordsInRequest: function(records){
                var listOfRecords = [];
                var lastModifiedOn = this.__root.__lastModifiedDateOfRecords;
                var recordTypeName = this.__root.__filterListDropDown.getValue();
                for(var i=0; i<records.length; i++){
                    if(records[i].dirty){
                        //Updated for the Defect 033708 fix 
                        listOfRecords.push(SVMX.cloneObject(records[i].data));
                        listOfRecords[i].processId = Ext.String.htmlDecode(listOfRecords[i].processId);
                    }
                }
                var request = {
                    'lastModifiedOn':lastModifiedOn,
                    'recordTypeName':recordTypeName,
                    'filterInfoList':listOfRecords
                };
                return request;
            },

            showMessage: function(mesg, title){
                mesg = Ext.String.htmlEncode(mesg);
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.appfilters\src\impl.js

(function(){

	var impl = SVMX.Package("com.servicemax.client.admin.appfilters.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.admin.appfilters.commands.init();
        	com.servicemax.client.admin.appfilters.responders.init();
        	com.servicemax.client.admin.appfilters.engine.init();
        	com.servicemax.client.admin.appfilters.console.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("APFTEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("APFTEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.admin.appfilters\src\responders.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.admin.appfilters.responders");

	impl.init = function(){

		/**
		 * A do nothing responder, our caller will handle the data response directly from the event.
		 * Use this if you want a more generic and universal way of responding from the engine.
		 */
		impl.Class("GetSupportedRecordTypesResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetSupportedRecordTypesCompleted(data);
	        }
	    }, {});

	    impl.Class("GetAllSourceObjectsResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetAllSourceObjectsCompleted(data);
	        }
	    }, {});

	    impl.Class("GetApplicationFilterResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetApplicationFilterCompleted(data);
	        }
	    }, {});

	    impl.Class("SaveApplicationFilterResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onSaveApplicationFilterCompleted(data);
	        }
	    }, {});
	};

})();

