// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\api.js
/**
 * ServiceMax UIControl/Component Library for IBTree.
 * @class com.servicemax.client.installedbasetree.api
 */
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.installedbasetree.api");
appImpl.init = function(){

    appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
        __constructor : function(){

        },

        beforeRun: function (options) {
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
             
            this.__eventBus = SVMX.create("com.servicemax.client.installedbasetree.impl.EventBus", {});
            // create the named default controller
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){
                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);
                }, context : this});
            }, context : this, additionalParams : { eventBus : this.__eventBus }});
            options.handler.call(options.context);
        },
        
        getEventBus : function(){
            return this.__eventBus;
        },

        run : function(){   
            this.__recordId = SVMX.getUrlParameter("Id");
            this.__objName = SVMX.getUrlParameter('objName');
            this.getMetaData();
        },

        getMetaData: function() {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "IBTREE.GET_META_DATA", this,
                            {
                                request : { 
                                    context : this,
                                    objName: this.__objName
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetMetaDataComplete: function(metaData) {
            
            var translations = {};
            for (var arrayTran in metaData.translations){
                    translations[arrayTran] = Ext.String.htmlEncode(metaData.translations[arrayTran])
            }
            window.$TR = translations;
            if (!this.__recordId) {
                alert($TR.PARAMS_ERROR);
            } else {
                this.__metaData = metaData;
                this.getTreeData();
            }
        },

        getTreeData: function() {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "IBTREE.GET_TREE_DATA", this,
                            {
                                request : { 
                                    context : this,
                                    recordId: this.__recordId,
                                    objName:this.__objName,
                                    reload: false,
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetTreeDataComplete: function(treeData) {
            SVMX.create('com.servicemax.client.installedbasetree.root.RootPanel',{
                collapsible : false,
                titleAlign: 'center', 
                frame: 'true',
                treeData: treeData,
                metaData: this.__metaData,
                recordId: this.__recordId,
                objName:this.__objName
            });
        },

        
    });
}

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\commands.js
(function(){
	var ibTreecommands = SVMX.Package("com.servicemax.client.installedbasetree.commands");
	
	ibTreecommands.init = function(){

		ibTreecommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_META_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetMetaDataComplete(data);
			}
			
		},{});
		
		ibTreecommands.Class("GetTreeData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_TREE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetTreeDataComplete(data);
			}
			
		},{});

		ibTreecommands.Class("LoadMoreData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_LOAD_MORE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetLoadMoreDataComplete(data);
			}
			
		},{});

		ibTreecommands.Class("treeConfigureColumns", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.TREE_CONFIGURE_COLUMN"});
			},
		
			result : function(data) { 
				this.__cbContext.onConfigureColumnsComplete(data);
			}
			
		},{});
	};
})()

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\configureColumns.js
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.installedbasetree.configureColumns");

appImpl.init = function() {        
        var uiComponents = com.servicemax.client.ui.components;
        var uiComposites = com.servicemax.client.ui.components.composites.impl;
        Ext.define("com.servicemax.client.installedbasetree.configureColumns.CongigureColumn", {

        	constructor : function(config){
                config = config || {};
                this.__width = 650;
                this.__height = 500;
                this.__allFields = config.allFields;
                this.__selectedFields = config.selectedFields.slice();
                this.__parent = config.parent;
                this.callParent([config]);
                this.showColumns();
            },

            showColumns: function() {
            	var me = this;
            	var headerPanel = {
            		xtype: "svmx.label",
					text: "Configure Columns",
                    itemId: "title",
                    width: '100%',
                    height:80
            	};
            	var bottomPanel = {
            		xtype: 'svmx.toolbar',
	                itemId: "topBar",
	                width: '100%',
                    height: 70,
	                items: [
                      '->',
                      {
	                    text: $TR.CANCEL,
	                    itemId:"cancelBtn",
                        cls: 'svmx-ibtree-btn-cancel',
	                    handler : function() {
                        	me.__window.close();
	                    }
                      },  
                      {
                        text: $TR.APPLY,
                        itemId:"applyBtn",
                        cls: 'svmx-ibtree-btn-apply',
                        handler : function() {
                        	me.applyColumns();
                        }
                      }                
                    ]
              	};
				var selectedDataStore = this.getSelectedStore();
				this.__selectedList = Ext.create(uiComposites.name+'.SVMXListComposite', {
				    store: selectedDataStore,
				    columns: [
				        { text: 'Selected Fields', dataIndex: 'fieldLabel', width:275, 
                        renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }
                        }
				    ],
				    height: 250,
				    width: 275,				    itemId:'selectedFields',
				    reserveScrollbar: true,
				    hideHeaders: true,
                    viewConfig: {
                        preserveScrollOnRefresh: true
                    }
				});
				this.__selectedList.selModel.setSelectionMode('MULTI');
				var moveUDPanel = {
	              	xtype: "svmx.toolbar",
	                collapsible:false,
	                border: false,
				    height: 50,
				    width:275,
				    style:{'background-color': 'transparent'},
				    margin:'-10 0 0 0',
				    layout:{type:'hbox',pack:'center'},
				    items:[
				    	{
		                    //text: "U",
                            cls: 'svmx-ibtree-btn-up',
                            width: 25,
                            height: 25,
		                    handler : function() {
		                    	me.moveFieldUp();
		                    }
	                    },
	                    ' ',
	                    {
	                        //text: "D",
                            cls: 'svmx-ibtree-btn-down',
                            width: 25,
                            height: 25,
	                        handler : function() {
	                        	me.moveFieldDown();
	                        }
	                    }
                    ]
				};
				var selectedPanel = {
	              	xtype: "svmx.section",
                    cls: 'svmx-ib-tree-field-container',
	                collapsible:false,
	                border: false,
	                layout:'vbox',
	                height: 350,
	                width: 275,
	                items: [
	                	{
                            xtype: "svmx.label",
                            text: $TR.SF,
                            width: "275px",
                            height:'28px'
	                	},
						this.__selectedList,
						moveUDPanel
	                ]
				}
				var availableDataStore = this.getAvailableStore();
				this.__availableList = Ext.create(uiComposites.name+'.SVMXListComposite', {
				    store: availableDataStore,
				    columns: [
				        { text: 'Available Fields', dataIndex: 'fieldLabel', width:275,
                        renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }
                        }
				    ],
				    height: 250,
				    width: 275,
				    itemId:'availableFields',
				    reserveScrollbar: true,
				    hideHeaders: true,
                    viewConfig: {
                        preserveScrollOnRefresh: true
                    }
				});
				var availablePanel = {
	              	xtype: "svmx.section",
                    cls: 'svmx-ib-tree-field-container',
	                collapsible:false,
	                border: false,
	                layout:'vbox',
	                height: 350,
	                width: 275,
	                items: [
	                	{
                            xtype: "svmx.label",
                            text: $TR.AF,
                            width: "275px",
                            height: '28px'
	                	},
						this.__availableList,
	                ]
				}
				this.__availableList.selModel.setSelectionMode('MULTI');
				var moveLRPanel = {
	              	xtype: "svmx.toolbar",
	                collapsible:false,
	                border: false,
				    height: 250,
				    width: 45,
				    vertical:true,
				    style:{'background-color': 'transparent'},
				    margin:'0 0 0 15',
				    layout:{type:'vbox',pack:'center'},
				    items:[
				    	{
		                    //text: "&#10095;",//unicode for right arrow
                            cls: 'svmx-ibtree-btn-right',
                            width: 25,
                            height: 25,
		                    handler : function() {
		                    	me.moveFieldRight();
		                    }
	                    },
	                    ' ',
	                    {
	                        //text: "&#10094;",
                            cls: 'svmx-ibtree-btn-left',
                            width: 25,
                            height: 25,
	                        handler : function() {
	                        	me.moveFieldLeft();
	                        }
	                    }
                    ]
				};				
              	var errorPanel = {
	              	xtype: "svmx.section",
	              	itemId:"errorPanel",
	                collapsible:false,
	                border: false,
	                height: 0,
	                items: [
		                {
                            xtype: "svmx.label",
                            text: $TR.SF_ERROR,
                            width: me.__width,
                            cls: 'svmx-ibtree-error-msg',
                            height:'40px',
                            itemId:'errorMsg'
		                }
	                ]
              	}
				var centerPanel = {                  
	              	xtype: "svmx.section",
	              	itemId:"centerPanel",
	                collapsible:false,
	                border: false,
	                layout:'hbox',
	                height: 380,
	                items: [
						availablePanel,
						moveLRPanel,
						selectedPanel
	                ]
              	};
              	var contentPanel = {
	              	xtype: "svmx.section",
	              	itemId:"contentPanel",
	                collapsible:false,
	                border: false,
	                height: 380,
	                margin: '20 0 0 20',
	                items: [
						errorPanel,
						centerPanel,
	                ]
              	}
              	this.__window = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXWindow", {
	                layout : {type : "vbox"}, 
	                height : me.__height, 
	                width : me.__width,
	                closable: false,
	                maximizable: false,
	                bodyBorder: false,
	                border: false,
	                header: false,
	                titleAlign:'left',
                    cls: 'svmx-ibtree-configure-columns',
	                layout: {
	                    padding: 5
	                }, 
	                layout : 'fit',
	                modal : true,
	                items: [
	                	contentPanel
	                ],
	                dockedItems : [
	                    {
	                        dock: 'top', xtype: 'toolbar', margin: '0', height:'80px',
	                        items : headerPanel
	                    },
	                    {
	                        dock: 'bottom', xtype: 'toolbar', margin: '0',
	                        items : bottomPanel, height:'70px'
	                    }
	                ],
	               
	                listeners: {
	                }
	                
	            });
              	this.__window.show();

            },
            applyColumns: function() {
            	var selectedItems = this.__selectedList.store.data.items;
            	var configuredColumns = [];
            	for(var i =0;i<selectedItems.length;i++) {
            		var item = selectedItems[i];
            		var object = item.raw;
            		configuredColumns.push(object);
            	}
            	this.saveConfiguredColumns(configuredColumns);
            },
            saveConfiguredColumns: function(configuredColumns) {
                this.__parent.blockUI();
                var configuredData = {};
                var objName = this.__parent.__objName;
                if (objName == SVMX.getCustomFieldName('Site')) {
                    objName = 'SITE'
                } else {
                    objName = 'IB'
                }
                configuredData['objectName'] = objName;
                configuredData['columnsToDisplay'] = configuredColumns;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "IBTREE.TREE_CONFIGURE_COLUMN", this,
                    {
                        request : { 
                            context : this,
                            configuredData: configuredData
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);

            },
            onConfigureColumnsComplete: function(data) {
              if(!(data.hasOwnProperty('status') && data.status == false)) {
                var configuredColumns = SVMX.getCustomFieldName('SM_Configured_Columns');
                var configuredData = JSON.parse(data[configuredColumns]);
                var parentObjName = this.__parent.__objName;;
                if (configuredData.length > 0) {
                    for(var i=0;i<configuredData.length;i++){
                        var columnData = configuredData[i];
                        if ((columnData.objectName === 'SITE' && parentObjName == SVMX.getCustomFieldName('Site')) ||
                            columnData.objectName === 'IB' && parentObjName == SVMX.getCustomFieldName('Installed_Product')) {
                            this.__parent.__configuredFields = columnData.columnsToDisplay;
                        }
                    }
                  	this.__window.close();
                  	this.__parent.getTreeData();
                }
              } else {
              	this.updateErrorPositions(data.message);
                this.__parent.unblockUI();
              }
            },
            getAvailableStore: function() {
            	var dataStore = this.filterAndSortAllFields();
	            var availableDataStore = Ext.create(uiComposites.name+'.SVMXStore',{
	               	fields:['fieldLabel'],
	              	data:dataStore,
					sorters: [{
					    property: 'fieldLabel',
					    direction: 'ASC'
					}],
	            });
	            return availableDataStore;
            },
            filterAndSortAllFields: function() {
            	var me = this;
        	    var dataStore = this.__allFields.filter(function(field){
        	    	if(me.checkForSelectedField(field['fieldName'])==-1) {
        	    		return true;
        	    	}
        	    	return false;
        	    });
                return dataStore;
            },
            getSelectedStore: function() {
	            var selectedDataStore = Ext.create(uiComposites.name+'.SVMXStore',{
	               	fields:['fieldLabel'],
	              	data:this.__selectedFields
	            });
	            return selectedDataStore;
            },
            checkForSelectedField: function(key) {
            	for(var i = 0; i< this.__selectedFields.length;i++) {
            		var field = this.__selectedFields[i];
            		if (field['fieldName']===key) {
            			return i;
            		}
            	}
            	return -1;
            },
            moveFieldLeft: function() {
            	var selectedModel = this.__selectedList.selModel;
            	if (selectedModel) {
            		var records = selectedModel.getSelection();
            		var totalSelectedCount = this.__selectedList.store.getCount();
            		if (records.length < totalSelectedCount) {
            			if (this.__errorShown) {
            				this.updateNormalPositions();
            			}
	            		if(records) {
	        				this.__selectedList.store.remove(records);
	        				this.__selectedList.getView().refresh();
	        				this.__availableList.store.add(records);
	        				this.__availableList.getView().refresh();
	            		}
            		} else {
            			this.updateErrorPositions($TR.SF_ERROR);
            		}
            	}
            },
            moveFieldRight: function() {
            	var selectedModel = this.__availableList.selModel;
            	if (selectedModel) {
            		var records = selectedModel.getSelection();
            		records.sort(function(a,b){//sorting selected fields from available Fields
            			var nameA = a.data.fieldLabel.toUpperCase();
            			var nameB = b.data.fieldLabel.toUpperCase();
            			return nameA > nameB;
            		});
            		if(records) {
            			if (this.__errorShown) {
            				this.updateNormalPositions();
            			}
        				this.__selectedList.store.add(records);
        				this.__selectedList.getView().refresh();
        				this.__availableList.store.remove(records);
        				this.__availableList.getView().refresh();
            		}
            	}
            },
            moveFieldUp: function() {
            	this.selectedListDataMove(-1);
            },
            moveFieldDown: function() {
            	this.selectedListDataMove(1);
            },
            selectedListDataMove: function(index) {
				if (this.__errorShown) {
					this.updateNormalPositions();
				}
            	var me = this;
            	var selectedModel = this.__selectedList.selModel;
            	if (selectedModel) {
            		var records = selectedModel.getSelection();
            		records.sort(function(a,b){//sorting selected fields from available Fields
            			var aPos = me.__selectedList.store.indexOf(a);
            			var bPos = me.__selectedList.store.indexOf(b);
            			if (index == -1) return aPos > bPos;
            			else return aPos < bPos;
            		});
            		if (records && records.length > 0 && this.canSelectedRecordsMove(records, index)) {
            			for(var i=0;i<records.length;i++) {
            				var record = records[i];
            				var position = this.__selectedList.store.indexOf(record);
            				position = position + index;
							this.__selectedList.store.remove(record, true);
							this.__selectedList.store.insert(position,record);
            			}
            			var gridView = this.__selectedList.getView();
            			gridView.select(records);
            		}
                }
            },
            canSelectedRecordsMove: function(records, index) {
            	var canMove = false;
            	for(var i=0;i<records.length;i++) {
            		var position = this.__selectedList.store.indexOf(records[i]);
            		if (index == -1) {
	            		if (position > 0) {
	            			canMove = true;
	            		} else {
	            			canMove = false;
	            			break;
	            		}
            		} else {
	            		if (position < this.__selectedList.store.getCount() - 1 ) {
	            			canMove = true;
	            		} else {
	            			canMove = false;
	            			break;
	            		}
            		}
            	}
            	return canMove;
            },

            updateErrorPositions: function(errorText) {
            	this.__errorShown = true;
            	var errorPanel = this.__window.query("#errorPanel")[0];
            	errorPanel.setHeight(40);
            	var availableList = this.__window.query("#availableFields")[0];
            	availableList.setHeight(210);
            	var selectedList = this.__window.query("#selectedFields")[0];
            	selectedList.setHeight(210);
            	var selectedList = this.__window.query("#selectedFields")[0];
            	var errorLabel = this.__window.query("#errorMsg")[0];
            	errorLabel.setText(errorText);
            },
            updateNormalPositions: function() {
            	this.__errorShown = false;
            	var errorPanel = this.__window.query("#errorPanel")[0];
            	errorPanel.setHeight(0);
            	var availableList = this.__window.query("#availableFields")[0];
            	availableList.setHeight(250);
            	var selectedList = this.__window.query("#selectedFields")[0];
            	selectedList.setHeight(250);
            }

        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\impl.js

(function(){
    
    SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXC";
    SVMX.appType = SVMX.getClient().getApplicationParameter("app-type") || "external";
    
    var instImpl = SVMX.Package("com.servicemax.client.installedbasetree.impl");

    instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor : function(){
            this.__base();
            instImpl.Module.instance = this;
        },

        initialize : function(){
        },
        
        afterInitialize : function(){
            
        },
        beforeInitialize: function() {
            com.servicemax.client.installedbasetree.root.init();
            com.servicemax.client.installedbasetree.configureColumns.init();
            com.servicemax.client.installedbasetree.api.init();
            com.servicemax.client.installedbasetree.commands.init();
            com.servicemax.client.installedbasetree.operations.init();
        },
        createServiceRequest : function(params, operationObj){
            var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
            servDef.getInstanceAsync({handler : function(service){
                var options = params.options || {};
                var p = {type : options.type || "REST", endPoint : options.endPoint || "",
                                    nameSpace : "SVMXC"};
                var sm = service.createServiceManager(p);
                var sRequest = sm.createService();
                params.handler.call(params.context, sRequest);
            }, context:this });
        },

    }, {
        instance : null
    });
    
    instImpl.Class("EventBus", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor : function(){ this.__base(); }
    }, {
        __instance : null,
        getInstance : function(){
            if(!instImpl.EventBus.__instance){
                instImpl.EventBus.__instance = SVMX.create("com.servicemax.client.installedbasetree.EventBus", {});
            }
            return instImpl.EventBus.__instance;
        }
    });
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\operations.js
(function(){
    var ibTreeoperations = SVMX.Package("com.servicemax.client.installedbasetree.operations");

ibTreeoperations.init = function(){
    var Module = com.servicemax.client.installedbasetree.impl.Module; 

    ibTreeoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var objName;
            if (request.objName == SVMX.getCustomFieldName('Site')) {
                objName = 'SITE';
            } else {
                objName = 'IB';
            }
            ibTreeOnWeb.JsrGetMetadata(objName, function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});

    ibTreeoperations.Class("GetTreeData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var requestObj = {"recordId":request.recordId, "reload":request.reload};
            var requestData = JSON.stringify(requestObj);
            if (request.objName == SVMX.getCustomFieldName('Site')) {
                ibTreeOnWeb.JsrGetLocationTreeViewData(requestData, function(result, evt){               
                    responder.result(result);
                }, this);
            } else {
                ibTreeOnWeb.JsrGetTreeViewData(requestData, function(result, evt){               
                    responder.result(result);
                }, this);
            }
        }
    },{});

    ibTreeoperations.Class("LoadMoreData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var parentNode = request.parentNode;
            var requestData = JSON.stringify(request.requestData);
            ibTreeOnWeb.JsrGetChildren(requestData, function(result, evt){ 
                var response = {
                    result: result,
                    parentNode: parentNode
                } 
                responder.result(response);
            }, this);
        }
    },{});

    ibTreeoperations.Class("treeConfigureColumns", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var requestData = JSON.stringify(request.configuredData);
            ibTreeOnWeb.JsrSaveConfiguredColumnsForIB(requestData, function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});
};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installedbasetree\src\root.js
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.installedbasetree.root");

appImpl.init = function() {        
        var uiComponents = com.servicemax.client.ui.components;
        Ext.define("com.servicemax.client.installedbasetree.root.RootPanel", {
            extend : "com.servicemax.client.ui.components.composites.impl.SVMXSection", 
            layout: 'border',
            width: '100%', 
            cls: 'svmx-ibtree-root-container',

            constructor : function(config){
              config = config || {};
              config.renderTo = SVMX.getDisplayRootId(); 
              config.autoScroll = true;
              this.callParent([config]);
              var viewHeight = window.innerHeight - this.getPosition()[1];
              this.setHeight(viewHeight);
              if (!window.$TR) {
                $TR = this.translations();
              }
              this.__recordID = config.recordId;
              this.__objName = config.objName;
              this.__treeData = config.treeData;
              this.__loadMoreIndex = -1;
              this.__lMoreObjects = [];
              this._recordsLimit = 40;
              this._doneInitialLoad = false;
              this.processInitData(config);
            },
            processInitData: function(config) {
              var msgShown = false;
              var items = [];
              var screenHeight = this.getHeight();
              var screenWidth = this.getWidth();
              if (this.__treeData.hasOwnProperty('status') && this.__treeData.status == false) {
                msgShown = true;
                var labelText = this.__treeData.message;
                var errorMsg = {
                      xtype: "svmx.label",
                      text: labelText,
                      cls: 'svmx-ibtree-invalid',
                      width: "100%",
                      height: 50,
                      margin: '20 0 20 0',
                    }
                items.push(errorMsg);
              } else {
                var header = this.addHeader();
                items.push(header);
                this.processMetaData(config.metaData);
                var contentPanel = {
                  xtype: "svmx.section",
                  collapsible:false,
                  width: screenWidth - 10,
                  height: screenHeight - 115,
                  layout:'auto',
                  itemId: "contentPanel",
                  cls: 'svmx-ibtree-grid-container',
                };
                items.push(contentPanel);
              }
              var panel = {
                xtype: "svmx.section",
                collapsible:false,
                width: '100%',
                layout:'auto',
                items: items,
              }
              this.add(panel);
              if (!msgShown) {
                this.blockUI();
                this.updateColumns();
                this.addLoading(screenWidth);
              }
            },
            addLoading: function(screenWidth) {
              var loadingPanel = {
                xtype: "svmx.section",
                collapsible:false,
                width: screenWidth - 10,
                layout:'vbox',
                itemId: "loadingPanel",
                cls:'svmx-tree-loadingview',
                hidden: true,
                items:[
                  {
                    xtype: "svmx.label",
                    text: $TR.LOADING+'...',
                    width: "100%",
                    height:30,
                    margin: '10 0 20 0',
                  }
                ]
              };
              this.add(loadingPanel);
            },
            processMetaData: function(metaData) {
              this.__configuredFields = metaData.defaultFieldObject;
              this.__allFields = metaData.sforceObjectDescribes[this.__objName].fields;
            },
            addHeader: function() {
              var me = this;
              var accountDetails = this.__treeData.ibAccount;
              var accountName = '<a';
              if (accountDetails.accountId) {
                accountName += " href='/"+ accountDetails.accountId +"'";
              }
              if (accountDetails.accountName) {
                accountName += ">" + Ext.String.htmlEncode(accountDetails.accountName)+ "</a>";
              } else {
                accountName += "></a>";
              }
              var ibName = "";
              if (accountDetails.ibName) {
                ibName = accountDetails.ibName;
              }
              var width = this.getWidth();
              var header = {
                  xtype: 'svmx.toolbar',
                  itemId: "topBar",
                  cls: 'svmx-ibtree-top-toolbar',
                  width: width - 10,
                  items: [
                      {
                        xtype: 'svmx.section',
                        layout: 'vbox',
                        collapsible: false,
                        width: '75%',
                        items:[
                          {
                            xtype: "svmx.label",
                            html: accountName,
                            itemId: "accountName",
                            width: '100%',
                          },
                          {
                            xtype: "svmx.label",
                            text: ibName,
                            itemId: "ibName",
                            width: '100%',
                          },
                        ]
                      },
                      '->',
                      {
                          text: $TR.CC,
                          disabled: false,
                          itemId:"configureColumns",
                          cls: 'svmx-ibtree-btn',
                          handler : function() {
                              me.configureColumns();
                          }
                      },
                  ]
              };
              return header;
            },

            configureColumns: function() {
              SVMX.create("com.servicemax.client.installedbasetree.configureColumns.CongigureColumn",{
                allFields:this.__allFields,
                selectedFields:this.__configuredFields,
                parent: this
              });
            },
            
            getTreeData: function() {
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                          "IBTREE.GET_TREE_DATA", this,
                          {
                              request : { 
                                  context : this,
                                  recordId: this.__recordID,
                                  objName:this.__objName,
                                  reload: true,
                              }
                          });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },

            onGetTreeDataComplete: function(treeData) {
              this.__treeData = treeData
              this.updateColumns();
            },

            updateColumns: function() {
              var me = this;
              var ibTree = this.query("#IBTree")[0];
              if (ibTree) {
                ibTree.destroy();
              }
              this.__tree = null;
              var contentPanel = this.query("#contentPanel")[0];
              this.__selectedPath = [];
              this.__lMoreObjects = [];
              this._nodeHighlighted = false;
              this.__tree = this.addTree();
              contentPanel.add(this.__tree);
              var rootNode = this.__tree.store.getRootNode();
              rootNode.raw.loadChildren = true;
              var pathLength = this.__selectedPath.length;
              if (pathLength > 1) {
                this.__levelLength = pathLength - 1;
              } else {
                this.__levelLength = 0;
              }
              this.__tree.disable();
              this.getChildren(rootNode);
              this._lastScrollValue = 0;
              this.__rowHeight = 0;
              this._scrollDiff = 0;
              var treeView = this.__tree.view;
              var treeViewHeight = treeView.getHeight();
              this.__clearLimit = treeViewHeight;
              this.__tree.view.getEl().on('scroll', function(e, t) { 
                var scrollUp = false;
                if (me._lastScrollValue > t.scrollTop) {
                  scrollUp = true;
                  me._scrollDiff += me._lastScrollValue - t.scrollTop;
                } else {
                  scrollUp = false;
                  me._scrollDiff += t.scrollTop - me._lastScrollValue;
                }
                me.updateScrolling(t,scrollUp);
                me._lastScrollValue = t.scrollTop;
              });
            },
            updateScrolling: function(t,scrollUp) {
              var scrollTop = t.scrollTop;
              if (this.__rowHeight > 0 && this._scrollDiff > 2*this.__rowHeight) {
                this._scrollDiff = 2*this.__rowHeight;
                if (scrollUp) {
                  scrollTop = this._lastScrollValue - this._scrollDiff;
                  this.__tree.scrollByDeltaY(-this._scrollDiff);
                } else {
                  scrollTop = this._lastScrollValue + this._scrollDiff;
                  this.__tree.scrollByDeltaY(this._scrollDiff);
                }
              }
              this.findFirstLoadMore(scrollTop);
              this.checkForClearing(t,scrollUp)
            },
            findFirstLoadMore: function(scrollTop) {
              var treeView = this.__tree.view;
              var treeViewHeight = treeView.getHeight();
              var loadMoreObjects = this.__lMoreObjects;
              var minNodeTop = -1;
              var firstLoadMore;
              for(var i = 0; i< loadMoreObjects.length; i++) {
                var loadMore = loadMoreObjects[i];
                var element = treeView.getNode(loadMore);
                if (element) {
                  var dom = Ext.fly(element);
                  var nodeTop = element.offsetTop;
                  if ((treeViewHeight + scrollTop) >= nodeTop && dom.isVisible()) {
                    this.__tree.disable();
                    if (minNodeTop == -1) {
                      minNodeTop = nodeTop;
                      firstLoadMore = loadMore;
                      this.__loadMoreIndex = i;                      
                    } else {
                      if (nodeTop < minNodeTop) {
                        minNodeTop = nodeTop;
                        firstLoadMore = loadMore;
                        this.__loadMoreIndex = i;                      
                      }
                    }
                  }
                }
              }
              if (firstLoadMore) {
                this.setLoadMoreBottom(firstLoadMore,scrollTop);
                if (!this._loadMoreCalled) {
                  this._loadMoreCalled = true;
                  this.loadMoreClicked(firstLoadMore.parentNode);
                }
              }
            },
            setLoadMoreBottom: function(loadMore,scrollTop) {
              var treeView = this.__tree.view;
              var treeViewHeight = treeView.getHeight();
              var element = treeView.getNode(loadMore);
              if (element) {
                var nodeTop = element.offsetTop;
                var loadMorePlace = treeViewHeight + scrollTop;
                var deltaY = nodeTop - loadMorePlace;
                this.__tree.scrollByDeltaY(deltaY);
              }
            },
            checkForClearing: function(t,scrollUp) {
              if (this.__rowHeight == 0) {
                this.getRowHeight();
              }
              if (this.__rowHeight > 0) {
                if (this.__borderNode) {
                  this.handleClearing(t,scrollUp);
                } else {
                  var treeView = this.__tree.view;
                  var treeViewHeight = treeView.getHeight();
                  var limit = treeViewHeight * 3;
                  if (t.scrollTop > limit) {
                    var allElements = treeView.all.elements;
                    this.__borderNode = allElements[0];
                    this.handleClearing(t,scrollUp);
                  }
                }
              }
            },
            getRowHeight: function() {
              var treeView = this.__tree.view;
              var element = treeView.getNode(0);
              if (element) {
                this.__rowHeight = Ext.get(element).getHeight();
              }
            },
            handleClearing: function(t,scrollUp){
              var me = this;
              var treeView = this.__tree.view;
              var treeViewHeight = treeView.getHeight();
              var allElements = treeView.all.elements;
              var rowCount = Math.floor(this._scrollDiff/this.__rowHeight);
              this._scrollDiff = this._scrollDiff%this.__rowHeight;
              if (rowCount == 0) {
                return;
              }
              var visibleRowCount = Math.floor(treeViewHeight/this.__rowHeight);
              var bottomLimit = 5*visibleRowCount;
              var index = allElements.indexOf(this.__borderNode);
              if (scrollUp) {
                var limit = 0;
                if (index > 0) {
                  var topElementIndex = index + 2*visibleRowCount+1;
                  if (topElementIndex < allElements.length) {
                    var topElement = allElements[topElementIndex];
                    if (topElement) {
                      var nodeTop = topElement.offsetTop;
                      var deltaY = nodeTop - t.scrollTop;
                      this.__tree.scrollByDeltaY(deltaY);
                    }
                  }
                  for(var i=index;i>= index-rowCount;i--) {                  
                    var element = allElements[i];
                    var domElement = Ext.fly(element);
                    if (domElement) {
                      domElement.setDisplayed(true);
                    }
                  }
                  this.__borderNode = allElements[index-rowCount];
                  if (t.scrollTop == 0 ) {
                    limit = index;
                    for(var i=index;i>= 0;i--) {
                      var element = allElements[i];
                      var domElement = Ext.fly(element);
                      if (domElement) {
                        domElement.setDisplayed(true);
                      }
                    }
                    this.__borderNode = allElements[0];
                  }
                }
                var bottomIndex = bottomLimit + index;
                if (bottomIndex < allElements.length) {
                  for(var i=bottomIndex+rowCount;i>=bottomIndex - limit;i--) {
                    if (i == allElements.length) {
                      break;
                    }
                    var element = allElements[i];
                    var domElement = Ext.fly(element);
                    if (domElement) {
                      domElement.setDisplayed(false);
                    }
                  }
                }
              } else {
                if (t.scrollTop > 2*treeViewHeight) {
                  var index = allElements.indexOf(this.__borderNode);
                  if (index > 0) {
                    var topElementIndex = index + 2*visibleRowCount+2;
                    if (topElementIndex < allElements.length) {
                      var topElement = allElements[topElementIndex];
                      var domElement = Ext.fly(topElement);
                      if (topElement && domElement.isVisible()) {
                        var nodeTop = topElement.offsetTop;
                        var deltaY = nodeTop - t.scrollTop;
                        this.__tree.scrollByDeltaY(deltaY);
                      }
                    }
                  }
                  var bottomIndex = bottomLimit + index;
                  for(var i=bottomIndex;i< bottomIndex+rowCount;i++) {
                    if (i == allElements.length) {
                      break;
                    }
                    var element = allElements[i];
                    var domElement = Ext.fly(element);
                    if (domElement) {
                      domElement.setDisplayed(true);
                    }
                  }
                  for(var i=index;i< index+rowCount;i++) {
                    var element = allElements[i];
                    var domElement = Ext.fly(element);
                    if (domElement) {
                      domElement.setDisplayed(false);
                    }
                  }
                  this.__borderNode = allElements[index+rowCount];
                }
              }
            },
            expandTree: function() {
              var me = this;
              var pathLength = this.__levelLength;
              var nodeId = this.__selectedPath[pathLength];
              var node = this.__tree.getStore().getNodeById(nodeId);
              if (node) {
                node.raw.loadChildren = true;
                node.expand();
                pathLength = pathLength-1;
                this.__levelLength = pathLength;
                if (this.__levelLength == 0) {
                  this._moveToNode = true;
                }
              }else {
                this.unblockUI();
              }
            },
            addTree: function() {
              var me = this;
              var treeFields = [];
              var treeColumns = [];
              treeFields.push("Name");
              var objName = this.__objName;
              var firstColumnTitle;
              if (objName == SVMX.getCustomFieldName('Site')) {
                firstColumnTitle = 'Location';
              } else {
                firstColumnTitle = 'Installed Product';
              }
              treeColumns.push({
                  xtype: 'treecolumn',
                  text: firstColumnTitle,
                  dataIndex: 'Name',
                  width: 400,
                  hideable: false,
                  draggable: false,
                  //sortable:false,
                  renderer: function(value) {
                    return Ext.String.htmlEncode(value);
                  }
              });
              var configuredFields = this.__configuredFields;
              for(var i=0; i<configuredFields.length; i++){
                var field = configuredFields[i];
                  var fieldName = field['fieldName'];
                  var fieldLabel = Ext.String.htmlEncode(field['fieldLabel']);
                  treeFields.push(fieldName);
                  treeColumns.push({
                      text: fieldLabel,
                      dataIndex: fieldName,
                      width: 130,
                      hideable: false,
                      draggable: false,
                      renderer: function(value, metaData, record, row, col, store, gridView) {
                        if(value == '' || !value || me.__objName != record.raw.objectName) {
                          return '-';
                        }
                        return Ext.String.htmlEncode(value);
                      }
                  });
              }
              var treeStore = this.getTreeStore();
              this._colWidth = 0;
              var tree = Ext.create('Ext.tree.Panel', {
                  fields: treeFields,
                  columns: treeColumns,
                  root: treeStore,
                  rootVisible: false,
                  itemId:'IBTree',
                  sortableColumns:false,
                  cls: 'svmx-ibtree-grid',
                  viewConfig:{
                    listeners:{
                      refresh:function(dataview) {
                        Ext.each(dataview.panel.columns, function (column) {
                          var columnEl = column.getEl();
                          var columnDom = Ext.getDom(columnEl);
                          if(columnDom.scrollWidth > column.width) {
                            column.width = columnDom.scrollWidth + 15;
                          }
                          var colIndex = column.getIndex();
                          if (colIndex == 0) {
                            me._colWidth = 0;
                          }
                          me._colWidth += column.width;
                          var colLength = dataview.panel.columns.length;
                          if (colIndex == colLength-1) {
                            var treeWidth = dataview.getWidth();
                            if(me._colWidth < treeWidth) {
                              var remWidth = treeWidth - me._colWidth;
                              column.width += remWidth;
                            }
                          }
                        });
                      }
                    }
                  },
                  listeners: {
                    afteritemexpand:function(node, index, item) {
                      me.getChildren(node);
                    },
                    afteritemcollapse: function(node, index, item) {
                      me.updateChildrenVisiblity(node,false);
                    },
                    itemexpand:function() {
                      me.highlightNode();
                    },                    
                    itemcollapse:function() {
                      me.highlightNode();
                    },
                    cellclick:function(panel,td,cellIndex,record,tr,rowIndex) {
                      if (record.raw.id !== me.__recordID) {
                        me.__tree.selModel.deselect(record);
                        me.highlightNode();
                      }
                    },
                  }
              });
              return tree;
            },
            highlightNode:function() {
              var node = this.__tree.getStore().getNodeById(this.__recordID);
              if (node) {
                var selectionModel = this.__tree.getSelectionModel();
                if (this._moveToNode) {
                  selectionModel.select(node);
                  this._moveToNode = false;
                } else {
                  var treeView = this.__tree.getView();
                  var selNode = treeView.getNode(node);
                  if (selNode) {
                    var selNodeObj = Ext.get(selNode);
                    if (selNodeObj) {
                      selectionModel.selected.clear();
                      selNodeObj.addCls('svmx-grid-row-selected');
                      this._nodeHighlighted = true;
                    }
                  }
                }
              }
            },
            loadMoreClicked: function(node) {
              if (node) {
                var me = this;
                this.removeLoadingNode(node);
                if (this.__loadMoreIndex > -1) {
                  this.__lMoreObjects.splice(this.__loadMoreIndex,1);
                  this.__loadMoreIndex = -1;
                }
                node.appendChild(this.getLoadingNodeObject());
                this.__lMoreObjects.push(node.lastChild);
                node.raw.loadChildren = true;
                setTimeout(function(){
                  me.getChildren(node);
                }, 100);
                var loadingPanel = this.query("#loadingPanel")[0];
                if (loadingPanel) {
                  loadingPanel.setVisible(true);
                  var treePos = this.__tree.getPosition();
                  var thisPos = this.getPosition();
                  var treeY = treePos[1] - thisPos[1];
                  var treeViewHeight = this.__tree.getHeight();
                  loadingPanel.setPosition(loadingPanel.x, treeY+treeViewHeight - 25);
                }
              }
            },
            updateChildrenVisiblity: function(node, expand) {
              if (this.__rowHeight == 0) {
                this.getRowHeight();
              }
              if (this.__rowHeight > 0) {
                var treeView = this.__tree.view;
                var treeViewHeight = treeView.getHeight();
                var allElements = treeView.all.elements;
                var visibleRowCount = Math.floor(treeViewHeight/this.__rowHeight);
                var nodeElement = treeView.getNode(node);
                var index = allElements.indexOf(nodeElement);
                var iStart = 0;
                var end = 0;
                var visible = true;
                if (expand) {
                  iStart = index +5*visibleRowCount;
                  visible = false;
                  end = allElements.length;
                } else {
                  iStart = index;
                  visible = true;
                  end = index +5*visibleRowCount;
                }
                if (iStart > -1 && iStart < allElements.length) {
                  for(var i=iStart;i<end;i++) {
                    if (i==allElements.length) {
                      break;
                    }
                    var element = allElements[i];
                    var domElement = Ext.fly(element);
                    if (domElement) {
                      domElement.setDisplayed(visible);
                    }
                  }
                }
              }
            },
            getChildren: function(node) {
              if (!node.raw.loadChildren) {
                this.highlightNode();
                this.updateChildrenVisiblity(node,true);
                return;
              }
              var nodeType = node.raw.objectName;
              var accountDetails = this.__treeData.ibAccount;
              var topLevel = node.raw.topLevelId;
              var index = 0;
              if (node.raw.index) {
                index = node.raw.index;
              } else {
                node.raw.index = 0;
              }
              index *= this._recordsLimit;
              var childLength = node.childNodes.length;
              var fromIB = false;
              var ibIndex = 0;
              if (node.raw.posAssigned) {
                fromIB = true;
                ibIndex = childLength - node.raw.ibIndex - 1;
              }
              var request = {
                objType : node.raw.objectName,
                sfdcId : node.raw.Id,
                accountId : accountDetails.accountId,
                index: index,
                recordsLimit : this._recordsLimit,
                topLevelIb : topLevel,
                treeType: this.__objName,
                isIB : fromIB,
                ibIndex: ibIndex
              };
              this.callForChildren(node,request);
            },
            callForChildren: function(node, request) {
              var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "IBTREE.GET_LOAD_MORE_DATA", this,
                        {
                            request : {
                              context : this,
                              requestData: request,
                              parentNode: node
                            }
                        });
              SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            onGetLoadMoreDataComplete: function(data) {
              var treeData = data.result;
              var node = data.parentNode;
              if (treeData.success == false || treeData.status == false) {
                if (node.raw.index * this._recordsLimit > 2000) {
                  Ext.Msg.alert($TR.ERROR,$TR.MAX_LIMIT);
                  if (this.__loadMoreIndex > -1) {
                    this.__lMoreObjects.splice(this.__loadMoreIndex,1);
                    this.__loadMoreIndex = -1;
                  }
                  this.removeLoadingNode(node);
                }
                this.enableTree();
                return;
              }
              this.loadTreeStore(treeData);
              this.loadChildren(node);
            },
            loadChildren: function(node) {
              node.raw.loadChildren = false;
              this.removeLoadingNode(node);
              var me = this;
              var nodeIndex = node.raw.index;
              if (!node.raw.childLength) {
                node.raw.childLength = 0;
              }
              var nodeChildren = this.getChildNodes(node);
              if (nodeChildren.length) {
                var lastChild = node.childNodes[node.childNodes.length-1];
                node.appendChild(nodeChildren);
                node.raw.childLength += nodeChildren.length;
              }
              if (node.raw.childLength < parseInt(node.raw.childrenCount)) {
                node.appendChild(this.getLoadMoreNode());
                this.__lMoreObjects.push(node.lastChild);
                node.raw.index = nodeIndex+1;
              }
              if (this.__levelLength > 0) {
                setTimeout(function(){
                  me.expandTree();
                }, 500);
              } else {
                this.unblockUI();
                this._doneInitialLoad = true;
                if(!this._nodeHighlighted || node.raw.id === this.__recordID) {
                  this.highlightNode();
                }
              }
              if (this.__loadMoreIndex > -1) {
                this.__lMoreObjects.splice(this.__loadMoreIndex,1);
                this.__loadMoreIndex = -1;
              }
              this.enableTree();
            },
            enableTree: function() {
              if (this.__tree.disabled && this._doneInitialLoad) {
                this.__tree.enable();
              }
              this._loadMoreCalled = false;
              var loadingPanel = this.query("#loadingPanel")[0];
              if (loadingPanel) {
                loadingPanel.setVisible(false);
              }
            },
            removeLoadingNode: function(node) {
              var children = node.childNodes;
              node.removeChild(children[children.length-1]);
            },
            getLoadMoreNode: function() {
              var loadingText = 'Load More...';
              var ret = {
                Name :  loadingText,
                iconCls : 'svmx-tree-load-more',
                href: '#',
                leaf: true,
                loadMore: true
              };
              return ret;
            },
            getTreeStore: function() {
              var treeData = this.__treeData.ibTree;
              this.mapInstalledBase = {};
              this.mapParrentChild = {};
              this.mapInstalledBase['root'] = this.getRootElement();
              this.loadTreeStore(treeData);
              this.findPath();
              var treeStore = this.getNode('root');
              return treeStore;
            },
            getRootElement: function() {
              var accountDetails = this.__treeData.ibAccount;
              var root = {};
              root['Id'] = 'root';
              root['Name'] = 'root';
              root['childrenCount'] = accountDetails.childrenCount;
              return root;
            },
            findPath:function() {
              var objIB = this.mapInstalledBase[this.__recordID];
              this.__selectedPath = ['root'];
              while(objIB && objIB.parentNodeId &&  objIB.parentNodeId != 'root') {
                this.__selectedPath.push(objIB.parentNodeId);
                objIB = this.mapInstalledBase[objIB.parentNodeId];
              }
            },
            loadTreeStore: function(treeData) {
              for(var i=0;i<treeData.length;i++){
                  
                  var objIB = treeData[i];
                  if(!this.mapParrentChild['root']) {
                      this.mapParrentChild['root'] = [];
                  }
                  if(!objIB.parentNodeId){
                    objIB.parentNodeId = 'root';
                  }
                  if(!this.mapParrentChild[objIB.parentNodeId]){
                      this.mapParrentChild[objIB.parentNodeId] = [];
                  }
                  if (this.mapParrentChild[objIB.parentNodeId].indexOf(objIB.Id) == -1) {
                    this.mapParrentChild[objIB.parentNodeId].push(objIB.Id);
                  }
                  this.mapInstalledBase[objIB.Id] = objIB;
              }
            },
            getChildNodes: function(parentNode) {
              var parentID = parentNode.raw.Id;
              var parentType = parentNode.raw.objectName;
              var lstChild = this.mapParrentChild[parentID];
              var children = [];
              if(lstChild){
                // var childLength = parentNode.childNodes.length;
                var childLength = parentNode.raw.childLength;
                for(var i=childLength;i<lstChild.length;i++){
                    var child = lstChild[i];
                    var childIB = this.getNode(child);
                    if ((parentType == 'root' || parentType == SVMX.getCustomFieldName('Site')) && !parentNode.raw.posAssigned &&
                      this.__selectedPath.indexOf(childIB.id) < 0 && childIB.id != this.__recordID) {
                      if (childIB.objectName == SVMX.getCustomFieldName('Installed_Product')) {
                        parentNode.raw.ibIndex = childLength + i;
                        parentNode.raw.posAssigned = true;
                      }
                    }
                    children.push(childIB);
                }
              }
              return children;
            },
            getNode: function(parentID){
                
              var objIB = this.mapInstalledBase[parentID];

              objIB['children'] = [];
              objIB["expanded"] = false;
              objIB["href"] = "/" + objIB.Id;
              objIB['id'] = objIB.Id;
              var objectName = objIB['objectName'];
              if (objectName == SVMX.getCustomFieldName('Installed_Product')) {
                  objIB["iconCls"] = "svmx-tree-ib-icon"; 
              } else {
                  objIB["iconCls"] = "svmx-tree-loc-icon"; 
              }
              if (parentID !== 'root') {
                if (parseInt(objIB.childrenCount)) {
                  objIB['children'].push(this.getLoadingNodeObject());
                  objIB['loadChildren'] = true;
                } else {
                  objIB["leaf"] = true;
                }
              }
              return objIB;
            },
            getLoadingNodeObject : function(){
              var loadingText = 'Please wait';
              var ret = {
                Name :  loadingText,
                iconCls : 'svmx-piq-loading-node',
                leaf: true
              };
              return ret;
            },

            blockUI : function(){
              if (this.__spinner) {
                this.__spinner.spin($("#" + SVMX.getDisplayRootId())[0]);
              }
              else {
                var opts = {
                  lines: 25, // The number of lines to draw
                  length: 25, // The length of each line
                  width: 5, // The line thickness
                  radius: 30, // The radius of the inner circle
                  corners: 1, // Corner roundness (0..1)
                  rotate: 0, // The rotation offset
                  direction: 1, // 1: clockwise, -1: counterclockwise
                  color: '#ffa384', // #rgb or #rrggbb or array of colors
                  speed: 3, // Rounds per second
                  trail: 60, // Afterglow percentage
                  shadow: false, // Whether to render a shadow
                  hwaccel: false, // Whether to use hardware acceleration
                  className: 'spinner', // The CSS class to assign to the spinner
                  zIndex: 2e9 // The z-index (defaults to 2000000000)
                };
                this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
              }
            },

            unblockUI : function(){
              if (this.__spinner) {
                this.__spinner.stop();
              }
            },
            translations: function() {
              return {
                AF:"Available Fields",
                APPLY:"Apply",
                CANCEL:"Cancel",
                CC:"Choose Columns",
                PARAMS_ERROR:"Insufficient number of parameters provided to IB Tree View. Please contact your ServiceMax administrator to resolve this.",
                SF:"Selected Fields",
                SF_ERROR:"Select at least one field",
                LOADING:"Loading",
                MAX_LIMIT:"Maximum Limit of Expanded node is reached.",
                ERROR: 'Error'
              };
            },
        });

    }
})();

