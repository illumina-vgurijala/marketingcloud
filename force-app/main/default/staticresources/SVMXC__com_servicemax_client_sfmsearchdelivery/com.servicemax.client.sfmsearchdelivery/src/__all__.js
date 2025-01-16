// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmsearchdelivery\src\commands.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {
    var sfmsearchdeliverycommands = SVMX.Package("com.servicemax.client.sfmsearchdelivery.commands");

    sfmsearchdeliverycommands.init = function() {

        sfmsearchdeliverycommands.Class("GetSearchInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_INFO"
                });
            }
        }, {});

        sfmsearchdeliverycommands.Class("GetSearchResults", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_RESULTS"
                });
            }
        }, {});
		sfmsearchdeliverycommands.Class("GetUserInfo", com.servicemax.client.mvc.api.Command, {

		__constructor : function(){ this.__base(); },

		/**
		 *
		 * @param request
		 * @param responder
		 */
			executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMSEARCHDELIVERY.GET_USERINFO"});
		}
	}, {});
		
        sfmsearchdeliverycommands.Class("ChangeApplicationState", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                request.deliveryEngine.changeApplicationState(request.state);
            }
        }, {});
        

        sfmsearchdeliverycommands.Class("GetOnlineResults", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_ONLINE_RESULTS"
                });
            }
        }, {});

         sfmsearchdeliverycommands.Class("DownloadRecordOnDemand", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.DOWNLOAD_RECORD_ON_DEMAND"
                });
            }
        }, {});

        sfmsearchdeliverycommands.Class("GetSearchResultLimitSettings", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_RESULT_LIMIT_SETTINGS"
                });
            }
        }, {});
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmsearchdelivery\src\engine.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.engine
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {
    var engine = SVMX.Package("com.servicemax.client.sfmsearchdelivery.engine");

    engine.init = function() {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");

        engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
            __searchMetamodel: null,
            __searchRoot: null,
            __loadMask: null,
            __isContainerExternal: null,
            __parent: null,
            __translation: null,
			__view: null,
            searchResultsMaxCount:null,
            defaultResultsMaxCount:null,
            __constructor: function() {
                this.__base();
                this.__isContainerExternal = false;

                com.servicemax.client.lib.datetimeutils.DatetimeUtil.setAmPmText(TS.T("FSA016_TAG005", "AM"), TS.T("FSA016_TAG006", "PM"));
            },

            initAsync: function(options) {

                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.sfmsearchdelivery.impl.SFMSearchDeliveryEngineEventBus", {});

                // create the named default controller
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {

                        // now create the named default model
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);

                                ni.createNamedInstanceAsync("SFMSEARCHDELIVERY.VIEW",{ handler : function(view){
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
                            parent: this.__searchRoot
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
                this.__searchRoot = null;
                this.__searchMetamodel.destroy();
                this.__searchMetamodel = null;
                this.run(this.options);
            },

            run: function(options) {
                this.options = options || {};

                var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", this.getEventBus(), [
                    SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMSEARCHDELIVERY.GET_SEARCH_INFO", this, {
                            request: {}
                        }),
					SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMSEARCHDELIVERY.GET_USERINFO", this, {
                            request: {}
                        }),
                    SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMSEARCHDELIVERY.GET_SEARCH_RESULT_LIMIT_SETTINGS", this, {
                            request: {}
                        })

                ]);

                ec.triggerAll(function(evtCol) {
                    var items = evtCol.items(),
                        size = items.length,
                        i;
                    for (i = 0; i < size; i++) {
                        var item = items[i];
                        if (item.type() == "SFMSEARCHDELIVERY.GET_SEARCH_INFO") {
                            this.onGetSearchInfoCompleted(item.response);
                        }
						if (item.type() == "SFMSEARCHDELIVERY.GET_USERINFO") {
                            this.onGetUserInfoCompleted(item.response);
                        }
                        if (item.type() == "SFMSEARCHDELIVERY.GET_SEARCH_RESULT_LIMIT_SETTINGS") {
                            this.onGetSearchResultLimitSettingsCompleted(item.response);
                        }
                    }

                    this.__searchMetamodel.initialize();
                    this.__searchRoot = this.__view.createComponent("ROOTCONTAINER", {
                        metamodel: this.__searchMetamodel,
                        deliveryEngine: this,
                        consoleAppInstance: options.consoleAppInstance
                    });

                    SVMX.getCurrentApplication().defaultSearchInstance = this;

                    var keyWord = SVMX.getUrlParameter("SVMX_keyWord"),
                        processId = SVMX.getUrlParameter("SVMX_SearchName"),
                        processObjectId = SVMX.getUrlParameter("SVMX_SearchId");

                    if (this.__searchRoot) {
                        this.__searchRoot.run({
                            keyWord: keyWord,
                            processId: processId,
                            processObjectId: processObjectId
                        });

                        this.__searchRoot.render(SVMX.getDisplayRootId(), this.__isContainerExternal);
                    }

                    if (this.options.onReady) {
                        this.options.onReady.handler.call(this.options.onReady.context || this);
                    }

                }, this);
            },

            getRoot: function() {
                return this.__searchRoot;
            },

            getSearchType: function() {
                return "SFMSEARCHDELIVERY";
            },

            onGetSearchInfoCompleted: function(searchInfo) {
                this.__searchMetamodel = SVMX.create("com.servicemax.client.sfmsearchdelivery.engine.SFMSearchMetaModel", this, searchInfo);
            },

			onGetUserInfoCompleted : function(userInfo) {

				// inform all the interested parties about the available user info
				var client = SVMX.getClient();
				var evtUserInfo = SVMX.create("com.servicemax.client.lib.api.Event",
				 "GLOBAL.HANDLE_USER_INFO", this, userInfo);
				client.triggerEvent(evtUserInfo);
	        	// end user info related event
			},

            // Cheats a bit here by just returning the part of the model that contains meaningful data
            // All other data in __searchMetamodel is data used to generate searchInfo.
            getMetaModel: function() {
                return this.__searchMetamodel.searchInfo;
            },
            onGetSearchResultLimitSettingsCompleted:function(settingValues){

                var resultMaxCount=settingValues.maxLimit;
                var defaultMaxCount=settingValues.defaultLimit;

                this.searchResultsMaxCount=resultMaxCount;
                this.defaultResultsMaxCount=defaultMaxCount;
                //TODO Default Value.
            },

            onResize: function(size) {
                this.getRoot().resize(size);
            }
        }, {});

        engine.Class("SFMSearchMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null,
            __data: null,
            searchInfo: null,
            defaultSearchOperator: null,

            __constructor: function(parent, data) {
                //this.__base();
                this.__parent = parent;
                this.__data = data;
                this.searchInfo = [];
            },

            initialize: function() {
                var allSrchInfo = this.__data.lstSearchInfo || [],
                    i, l = allSrchInfo.length,
                    sp;

                // extract default search operator
                this.defaultSearchOperator = this.__extractDefaultSearchOperator();

                for (i = 0; i < l; i++) {
                    sp = SVMX.create("com.servicemax.client.sfmsearchdelivery.engine.SFMSearchProcessMetaModel", this, allSrchInfo[i]);
                    sp.initialize();
                    this.searchInfo.push(sp);
                }
            },

            __extractDefaultSearchOperator: function() {
                var settings = this.__data.stringMap || [],
                    i, l = settings.length,
                    ret = "Contains";

                for (i = 0; i < l; i++) {
                    if (settings[i].key == "SEARCH_OPERATOR") {
                        ret = settings[i].value;
                        break;
                    }
                }
                return ret;
            },

            getSearchInfoFor: function(id) {
                var allSrchInfo = this.searchInfo || [],
                    i, l = allSrchInfo.length,
                    ret = null;
                for (i = 0; i < l; i++) {
                    if (allSrchInfo[i].processObjectId == id) {
                        ret = allSrchInfo[i];
                        break;
                    }
                }
                return ret;
            },


            destroy: function() {
                SVMX.array.forEach(this.searchInfo, function(item) {item.destroy();});
                delete this.seachInfo;
                this.__parent = null;
                this.__data = null;
                this.searchInfo = null;
            }
        }, {});

        engine.Class("SFMSearchProcessMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null,
            __data: null,
            name: null,
            description: null,
            processId: null,
            isDefault: false,
            processObjectId: null,
            searchDetails: null,

            __constructor: function(parent, data) {
                this.__parent = parent;
                this.__data = data;
            },

            initialize: function() {
                this.name = this.__data.searchDef[SVMX.OrgNamespace + "__Name__c"];
                this.processId = this.__data.searchDef[SVMX.OrgNamespace + "__ProcessID__c"];
                this.processObjectId = this.__data.searchDef.Id;
                this.description = this.__data.searchDef[SVMX.OrgNamespace + "__Description__c"];
                this.isDefault = this.__data.searchDef[SVMX.OrgNamespace + "__IsDefault__c"];
                this.searchDetails = [];

                // create search details
                var allSearchDetails = this.__data.searchDetails || [],
                    i, l = allSearchDetails.length,
                    sd;
                for (i = 0; i < l; i++) {
                    sd = SVMX.create("com.servicemax.client.sfmsearchdelivery.engine.SFMSearchDetailMetaModel", this, allSearchDetails[i]);
                    sd.initialize();
                    this.searchDetails.push(sd);
                }

                this.searchDetails=this.searchDetails.sort(function sortByObjectDisplaySequence(i1,i2){
                        return i1.objectDisplaySequence - i2.objectDisplaySequence;
                    });
            },

            destroy: function() {
                SVMX.array.forEach(this.searchDetails, function(item) {item.destroy();});
                this.__parent = null;
                this.__data = null;
                delete this.searchDetails;
            }
        }, {});

        engine.Class("SFMSearchDetailMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null,
            __data: null,
            targetObjectName: null,
            targetObjectLabel: null,
            objectDisplaySequence:null,
            fields: null,
            detailObjectId: null,

            __constructor: function(parent, data) {
                this.__parent = parent;
                this.__data = data;
            },

            initialize: function() {
                this.targetObjectLabel = this.__data.objectLable; // ridiculous spelling mistake!
                this.targetObjectName = this.__data.objectDetails[SVMX.OrgNamespace + "__Target_Object_Name__c"];
                this.detailObjectId = this.__data.objectDetails.Id;
                this.objectDisplaySequence=this.__data.objectDetails[SVMX.OrgNamespace + "__Sequence__c"];
                this.fields = [];

                // create all the fields
                var allFields = this.__data.fields || [],
                    i, l = allFields.length,
                    fld;
                for (i = 0; i < l; i++) {
                    fld = SVMX.create("com.servicemax.client.sfmsearchdelivery.engine.SFMSearchDetailFieldMetaModel",
                        this, allFields[i]);
                    fld.initialize(this.__data.fieldsLable);
                    this.fields.push(fld);
                }

                // sort all the fields
                this.fields = SVMX.sort(this.fields, "sequence");
            },
            destroy: function() {
                SVMX.array.forEach(this.fields, function(item) {item.destroy();});
                delete this.fields;
                this.__parent = null;
                this.__data = null;

            }

        }, {});

        engine.Class("SFMSearchDetailFieldMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null,
            __data: null,
            fieldName: null,
            displayType: null,
            sequence: 0,
            fieldLabel: null,

            __constructor: function(parent, data) {
                this.__parent = parent;
                this.__data = data;
            },

            initialize: function(labelCollection) {
                this.fieldName = this.__data[SVMX.OrgNamespace + "__Field_Name__c"];
                this.displayType = this.__data[SVMX.OrgNamespace + "__Display_Type__c"];
                this.sequence = this.__data[SVMX.OrgNamespace + "__Sequence__c"];
                this.parentName = this.__data[SVMX.OrgNamespace + "__Object_Name2__c"];
                this.parentReferenceName = this.__data[SVMX.OrgNamespace + "__Lookup_Field_API_Name__c"];
                // pull out the field label
                var i, l = labelCollection.length;
                for (i = 0; i < l; i++) {
                    if (labelCollection[i].value1 == this.getId()) {
                        this.fieldLabel = labelCollection[i].value;
                        break;
                    }
                }
            },

            getId: function() {
                return this.__data.Id;
            },

            // If changing "-", see sfmsearchdeliveryoperations: if (parentName) fname = parentName + "-" + fname;
            getFullFieldName: function() {
                return this.parentName && this.parentName != this.__parent.targetObjectName ? this.parentReferenceName + "-" + this.fieldName : this.fieldName;
            },


            getObjectApiName: function() {
                return this.__parent.targetObjectName;
            },


            getReferenceFieldObjectApiName: function() {
                return this.__data[SVMX.OrgNamespace + "__Object_Name__c"];
            },

            destroy: function() {
                this.__parent = null;
                this.__data = null;
            }
        }, {});
    };
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmsearchdelivery\src\impl.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmsearchdelivery\src\responders.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.responders
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {

    var sfmsearchdeliveryresponders = SVMX.Package("com.servicemax.client.sfmsearchdelivery.responders");

    sfmsearchdeliveryresponders.init = function() {

        sfmsearchdeliveryresponders.Class("GetSearchInfoResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __constructor: function(parent) {
                this.__base();
                this.__parent = parent;
            },

            result: function(data) {
                this.__parent.onGetSearchInfoCompleted(data);
            },

            fault: function(data) {
                // TODO:
            }

        }, {});

        sfmsearchdeliveryresponders.Class("GetSearchResultResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __constructor: function(parent) {
                this.__base();
                this.__parent = parent;
            },

            result: function(data) {},

            fault: function(data) {
                // TODO:
            }

        }, {});
    };
})();

// end of file

