// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\app.js

(function(){
	var appImpl = SVMX.Package("com.servicemax.client.iot.admin.app");
	
    appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
		__eventBus : null,
		
		__constructor : function(){

		},
		
		beforeRun: function (options) {
			var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
			 
        	this.__eventBus = SVMX.create("com.servicemax.client.iot.admin.impl.IoTAdminEventBus", {});
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
        
        getSetupMetadata: function() {
            var me = this;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "IOT.GET_SETUP_METADATA", me,
                            {request : { context : me}});
            
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetSetupMetadataComplete: function(metadata) {
            
            var sforceObjectDescribes = metadata.sforceObjectDescribes;
            
            for(var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
                metadata[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
            }
            metadata.context = this;
            this.__processTranslations(metadata.translations);
            
            var iotAdmin = SVMX.create('com.servicemax.client.iot.admin.root.RootPanel',{
                collapsible : false,
                titleAlign: 'center', 
                frame: 'true',
                style: 'margin:10px',
                layout: {
                    padding: '0'
                },
                metadata: metadata
            });
            
        },

        __processTranslations: function(translationsArr) {
            
            var i, ilength = translationsArr.length;
            var translations = {};
            for(i = 0; i < ilength; i++) {
                translations[translationsArr[i].Key] = Ext.String.htmlEncode(translationsArr[i].Text) ;
            }
            window.$TR = translations;          
        },
        
		run : function(){	
            
            this.getSetupMetadata();
		},
        showQuickMessage : function(type, message, callback){
            if(type === "confirm"){
                typeMessage = $TR.MESSAGE_CONFIRM;
                Ext.Msg.confirm(typeMessage, message, callback);
            }else{
                switch(type){
                    case "success":
                        typeMessage = $TR.MESSAGE_SUCCESS;
                        break;
                    case "error":
                        typeMessage = $TR.MESSAGE_ERROR;
                        break;
                    case "info":
                    // TODO: add more types as needed
                    default:
                        typeMessage = $TR.MESSAGE_INFO;
                        break;
                }
                Ext.Msg.alert({
                    cls : 'piq-setup-info-alert',
                    title : typeMessage, 
                    message : message,
                    buttonText : { ok : $TR.OK },
                    closable : false
                });
            }
        },
        
        blockUI : function(){
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
        },
        
        unblockUI : function(){
        	this.__spinner.stop();
        }
	});	
	
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\celleditors.js
(function(){
        var cellEditors = SVMX.Package("com.servicemax.client.iot.admin.celleditors");

cellEditors.init = function() {
        
        Ext.define("com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXComboBox",
        constructor: function(config) {
                this.callParent([config]);
        },
        
        setRecord : function(record){
                this.__record = record;
        },
        
        setValue : function(value){
                if(this.__record && this.__record.data[this.fieldName + "_key"]){
                                value = this.__record.data[this.fieldName + "_key"];
                        }
                        this.callParent([value]);
        },
        
        getValue : function(){
                if(!this.__record) return null;
                var value = this.callParent();
                var displayValue = "";                                          
                if(this.findRecordByValue(value)){
                                displayValue = this.findRecordByValue(value).get(this.displayField);
                        }
                this.__record.data[this.fieldName + "_key"] = value;
                        return displayValue;
        }
        });
}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\commands.js


(function(){
	var iotadmincommands = SVMX.Package("com.servicemax.client.iot.admin.commands");
	
iotadmincommands.init = function(){
	
	iotadmincommands.Class("GetSetupMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.GET_SETUP_METADATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onGetSetupMetadataComplete(data);
		}
		
	},{});

	iotadmincommands.Class("Save", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.SAVE"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveComplete(data);
		}
		
	},{});

	iotadmincommands.Class("BackToSetupHome", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.BACK_TO_SETUP_HOME"});
		},
	
		result : function(data) {
		}
		
	},{});

	iotadmincommands.Class("DescribeObject", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__isRefobj : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			var me = this;
			me.__isRefobj = request.isRefobj;
			me.__cbContext = request.context;
			me._executeOperationAsync(request, me, {operationId : "IOT.DESCRIBE_OBJECT"});
		},
	
		result : function(data) {
			var me = this;
			if(me.__isRefobj){
				me.__cbContext.describeReferenceObjectComplete(data);
			}else{
				me.__cbContext.describeSelectedObjectComplete(data);
			}
		}
		
	},{});
	iotadmincommands.Class("GetAllEventTemplates", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.GET_ALL_EVENT_TEMPLATES"});
		},
	
		result : function(data) {
			this.__cbContext.loadAllEventTemplatesComplete(data);
		}
		
	},{});
	
};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\compositekey.js
(function(){
	var othersettings = SVMX.Package("com.servicemax.client.iot.admin.compositekey");

othersettings.init = function() {

		Ext.define("com.servicemax.client.iot.admin.compositeKeyGrid", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
	       __config: null, 
	       constructor: function(config) {
	       		this.__config = config;
	       		config.columns = [
	       			
                   new Ext.grid.RowNumberer()
	       		];
	       		
	       		if(config.forExternal){
	       			config.columns.push(this.createTextBoxColumn({
		       			text: $TR.EXTERNAL_FLD_NAME, 
		       			dataIndex: 'name', 
		       			width:400, 
		       			flex: 1
	       			}));
	       		}
	       		else{
	       			config.columns.push(this.createComboBoxColumn({
		       			text: $TR.IB_FLD_NAME, 
		       			dataIndex: 'name', 
		       			width:400, 
		       			flex: 1,
		       			renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                            },
	       			}));
	       		}

	       		config.columns.push({
						menuDisabled: true,
						sortable: false,
						xtype: 'actioncolumn',
						width: 50,
						items: [{
									iconCls: 'delet-icon',
									tooltip: $TR.DELETE
								}],
						handler: function(grid, rowIndex, colIndex) {
							var gridStore = grid.getStore();
		                    var rec = gridStore.getAt(rowIndex);
		                    gridStore.remove(rec);
		                    grid.refresh();      
		                },  		                
  		                renderer: function (value, metadata, record) {
  		                	config.columns[config.columns.length - 1].items[0].iconCls = 'delet-icon';
  		                }
                   });
	    	    this.callParent([config]);

	       },

	       createTextBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true
	    	   });
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   return txtboxCol;
               };
               
	    	   return fieldInfo;
	       },

	       createComboBoxColumn: function(fieldInfo) {
	    	   var me = this;

	    	   var ibFieldsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['fieldAPIName', 'fieldLabel'],
			        sorters: [{
                        property: 'fieldLabel',
                        direction: 'ASC'
                    }],
			        data: this.__config.metadata[SVMX.OrgNamespace + "__Installed_Product__c"].fields
   	 			});

	    	   
	    	   var fieldPicklist = SVMX.create('com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor',{
					displayField: 'fieldLabel',
			        queryMode: 'local',
			        editable: false,
			        valueField: 'fieldAPIName',
			        fieldName: 'name',
			        store: ibFieldsStore
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   fieldPicklist.setRecord(currentRecord);
                   return fieldPicklist;
               };
	    	   return fieldInfo;	    	   
	    	   
	       }

	    });


		Ext.define("com.servicemax.client.iot.admin.CompositeKey", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
	        sfKeyGrid: null, exKeyGrid: null,
	        sfKey: null, exKey: null, metadata: null, addRecButton: null,
	        constructor: function(config) {
	    	    var me = this;

	    	    this.metadata = config.metadata;
			   	this.refresh();
	    	   	var sfToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0'
				});

				this.addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text : $TR.ADD,
					cls:'iot-setup-add-button',
					handler : function(){

						me.onAddRecords(me.sfKeyGrid);
						this.setDisabled(true);
					}
				});

				this.sfKey = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : false
	    	    });		
				sfToolbar.add(this.sfKey);
				sfToolbar.add('->');
				sfToolbar.add(this.addRecButton);

				//external grid
				var exToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0'
				});

				var addExRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text : $TR.ADD,
					cls:'iot-setup-add-button',
					handler : function(){
						me.onAddRecords(me.exKeyGrid);
					}
				});

				this.exKey = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : false
	    	    });		
				exToolbar.add(this.exKey);
				exToolbar.add('->');
				exToolbar.add(addExRecButton);

				var sfData = this.resolveIBFields(config.metadata.compositeKey && 
												  config.metadata.compositeKey.ibFields &&
												  config.metadata.compositeKey.ibFields !== null
															? config.metadata.compositeKey.ibFields : []);
				var exData = config.metadata.compositeKey&& 
						     config.metadata.compositeKey.externalFields &&
						  	 config.metadata.compositeKey.externalFields !== null ? config.metadata.compositeKey.externalFields : [];


				//add to configuration items
	    	   	config = config || {};
	    	   	config.items = [];
	    	   	config.items.push(sfToolbar);
	    	   	this.sfKeyGrid = this.addGrid(config, false, sfData);
	    	   	if(sfData.length > 0) this.addRecButton.setDisabled(true);

	    	   	config.items.push(exToolbar);
	    	   	this.exKeyGrid = this.addGrid(config, true, exData);
	    	   	config.title = $TR.COMP_INFO;
			   	config.id = "CI";

			   	this.sfKeyGrid.getView().on('refresh', this.updateSFKey, this);
			   	this.exKeyGrid.getView().on('refresh', this.updateEXKey, this);
			   	this.callParent([config]);
	    	    
	        },

	        addGrid: function(config, forExternal, data){
	        	var compositeKeyStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['name'],
			        data: data
   	 			});
   	 			var compgrid = SVMX.create('com.servicemax.client.iot.admin.compositeKeyGrid',{
					cls: 'grid-panel-borderless panel-radiusless iot-setup-ta-grid',
					selType: 'cellmodel',
					height: 200,		        
				    plugins: [
				              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
				                  clicksToEdit: 2
				              })
				          ],
				    viewConfig:{
    						markDirty:false
						},
				    store: compositeKeyStore,
				    metadata: config.metadata,
				    forExternal: forExternal,
	            });
	        	
	    	   	
	            var userActionsPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					style: 'margin: 1px 0',
					layout: 'fit',
					title: forExternal ? $TR.COMP_KEY : $TR.EXT_KEY,
					cls: 'grid-panel-borderless',
					height: 200,
					defaults: {
						anchor: '40%'
					}
				});

				userActionsPanel.add(compgrid);
				config.items.push(userActionsPanel);
				return compgrid;
	        },
	         
	        onAddRecords: function(grid) {
	       		grid.addItems({});
	       		grid.getView().refresh();
	       		var rowIndex = grid.store.data.items.length - 1;
	    		var view = grid.getView();
          	    Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
          	    view.select(rowIndex);
	        },

	        updateSFKey: function(){
	        	this.updateKey(this.sfKeyGrid, this.sfKey);
	        	if(this.sfKeyGrid.getStore() && 
	        			this.sfKeyGrid.getStore() &&
	        			this.sfKeyGrid.getStore().getData())
	        		{
	        			var dataSize = this.sfKeyGrid.getStore().getData().length;
	        			if(dataSize == 0) this.addRecButton.setDisabled(false);
	        		}
	        },

	        updateEXKey: function(){
	        	this.updateKey(this.exKeyGrid, this.exKey);
	        },

	        resolveIBFields: function(ibFields){
	        	var iCount = 0, ibFieldsT = [], jCount = 0;
	        	var fields = this.metadata[SVMX.OrgNamespace + "__Installed_Product__c"].fields;
	        	for(iCount = 0; iCount < ibFields.length; iCount++){
	        		for(jCount = 0; jCount < fields.length; jCount++){
	        			if(fields[jCount].fieldAPIName == ibFields[iCount].name)
							ibFieldsT.push({
								name_key: fields[jCount].fieldAPIName,
								name: fields[jCount].fieldLabel
							});
	        		}
	        	}
	        	return ibFieldsT;
	        },

	        loadData: function(data){
	       		this.metadata = data;
        		var sforceObjectDescribes = this.metadata.sforceObjectDescribes;
    	
	        	for(var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
	        		this.metadata[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
	        	}

	       		var sfData = this.resolveIBFields(this.metadata.compositeKey ? this.metadata.compositeKey.ibFields : []);
				var exData = this.metadata.compositeKey ? this.metadata.compositeKey.externalFields : [];

	       		this.sfKeyGrid.getStore().loadData(sfData);
	       		this.sfKeyGrid.getStore().commitChanges();

	       		this.exKeyGrid.getStore().loadData(exData);
	       		this.exKeyGrid.getStore().commitChanges();
	        },

	        updateKey: function(grid, key){
	        	var iCounter= 0, iCounterLength = grid.store.data.length;
	        	var txt = "";
	        	for(iCounter = 1; iCounter <= iCounterLength; iCounter++){
	        		txt = txt.length > 0 ? txt + "+" : txt;
	        		txt = txt + iCounter;
	        	}
	        	key.setValue(txt);
	        },

	        getData: function(){
	        	var sfData = this.getRecords(this.sfKeyGrid.getStore(), true);
	        	var exData = this.getRecords(this.exKeyGrid.getStore());
	        	return {ibFields: sfData, externalFields: exData};
	        },

	        refresh: function(){
	        	var me = this;
	        	SVMX.getClient().bind("SAVE_SUCCESS", function(evt){
	                me.loadData(evt.data);
            	}, this);
	        	
	        },

	        getRecords: function(store, getKey) {
	    	   var records = [];
	    	   var fieldName = getKey ? "name_key" : "name"
	    	   store.each(function(rec) {          
	    			delete rec.data["id"];
	    			records.push({name: rec.data[fieldName], sequence: records.length + 1});
	    	   });
	    	   return records;
	       	}

		});
	
	}

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\createevent.js
/**
 *  Createevent.js.
 * @class com.servicemax.client.iot.admin.createevent
 * @author Madhusudhan HK
 *
 * @copyright 2017 ServiceMax, Inc.
 **/

(function() {
    var createevent = SVMX.Package("com.servicemax.client.iot.admin.createevent");
    createevent.init = function() {
        createevent.Class("CreateEvent", com.servicemax.client.lib.api.Object, {
            __config: null,
            __win: null,
            __applyButton: null,
            __searchTextField: null,
            __selectedCell: null,
            __parentContext: null,
            __recordIndex: null,
            __payload: null,
            __metadata: null,
            __constructor: function(config) {
                var me = this;
                me.__config = config;
                me.__metadata = config.metadata;
                me.__selectedCell = config.selectCell;
                me.__parentContext = config.parentContext;
                me.__recordIndex = config.recordIndex;
                me.__payload = config.payload;
                me.__win = me.__getUI();
                me.__win.show();
                me.__refresh();
            },
            __refresh: function() {
                var me = this,
                    objName, fld;
                if (!$.isEmptyObject(me.__payload)) {
                    objName = me.__payload.objName;
                    fld = me.__payload.fld;
                    me.showObjects.setValue(objName);
                    me.fieldGridStore.loadData(fld);
                    me.__describeSelectedObject(objName);
                    var refObjects = [];
                    for (var i = 0; i < fld.length; i++) {
                        if (fld[i].fldType === 'REFERENCE') {
                            refObjects.push(fld[i].refObj);
                        }
                    }
                    if (refObjects) me.fieldGrid.__describeReferenceObject(refObjects);
                } else {
                    me.showObjects.setValue("--None--");
                    me.__resetFieldGrid();
                }
            },
            __getUI: function() {
                var me = this;
                me.__applyButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton", {
                    text: $TR.APPLY,
                    id: 'applybutton',
                    docked: 'right',
                    disabled: true,
                    align: 'right',
                    cls: 'piq-setup-picklist-apply-button',
                    parentContext: me,
                    handler: function() {
                        this.parentContext.__apply();
                    }
                });
                var bottomBar = ['->', me.__applyButton];
                var objectsData = me.__getObjectListData();
                me.objectStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: ['objectName', 'objectLabel'],
                    data: objectsData
                });
                me.showObjects = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox', {
                    fieldLabel: $TR.SELECT_OBJECT + ' <span class="req" style="color:red">*</span>',
                    store: me.objectStore,
                    labelWidth: 150,
                    width: '60%',
                    displayField: 'objectLabel',
                    valueField: 'objectName',
                    queryMode: 'local',
                    editable: true,
                    disabled: false,
                    selectedObject: undefined,
                    listeners: {
                        select: {
                            fn: me.__onSelectObjects,
                            scope: me
                        },
                        afterrender: function(combo) {
                            var recordSelected = combo.getStore().getAt(0);
                            combo.setValue(recordSelected.get('objectLabel'));
                        }
                    }
                });
                me.fieldGridStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldLabel', type: 'string' },
                        { name: 'fldApi', type: 'string' },
                        { name: 'fldKey', type: 'string' },
                        { name: 'fldType', type: 'string' },
                        { name: 'refObj', type: 'string' },
                        { name: 'refFld', type: 'string' },
                        { name: 'refLabel', type: 'string' },
                        { name: 'isExternalId', type: 'boolean' }
                    ],
                    data: []
                });
                me.fieldStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldApi', type: 'string' }, { name: 'fldLabel', type: 'string' }, { name: 'fldType', type: 'string' }, { name: 'referenceTo', type: 'string' }, { name: 'isExternalId', type: 'boolean' }],
                    data: [],
                    sorters: [{
                        property: 'fldLabel',
                        direction: 'ASC'
                    }]
                });
                me.fieldGrid = SVMX.create('com.servicemax.client.iot.admin.FieldsGrid', {
                    cls: 'grid-panel-borderless panel-radiusless piq-setup-ta-grid iot-create-map-for-object-grid',
                    store: me.fieldGridStore,
                    fieldStore: me.fieldStore,
                    height: 350,
                    margin: '7 7 7 7',
                    width: 'calc(100% - 25px)',
                    autoScroll: true,
                    layout: 'fit',
                    selType: 'cellmodel',
                    parentContext: me,
                    editRowIndex: 0,
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {},
                    listeners: {
                        celldblclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {},
                        cellclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {
                            cell.config.grid.editRowIndex = rowIndex;
                            var row = this.getView().getRow(rowIndex);
                            Ext.get(row).removeCls('piq-setup-new-attributes-row');
                        },
                        edit: function(editor, e, eOpts) {}
                    }
                });
                var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                    layout: { type: "vbox" },
                    height: 500,
                    width: 820,
                    items: [me.fieldGrid],
                    title: $TR.CREATE_EVENT,
                    cls: 'piq-setup-ta-picklist-window',
                    closable: true,
                    maximizable: false,
                    titleAlign: 'left',
                    layout: {
                        padding: 5
                    },
                    layout: 'fit',
                    modal: true,
                    dockedItems: [{
                            dock: 'top',
                            xtype: 'toolbar',
                            margin: '0',
                            items: me.showObjects
                        },
                        {
                            dock: 'bottom',
                            xtype: 'toolbar',
                            margin: '0',
                            items: bottomBar
                        }
                    ],
                    listeners: {
                        show: function(win) {
                            if (this.modal) {
                                var dom = Ext.dom.Query.select('.x-mask');
                                for (var i = 0; i < dom.length; i++) {
                                    Ext.get(dom[i]).setStyle('opacity', 1);
                                    var el = Ext.get(dom[i]);
                                    el.addCls('customWinMask');
                                }
                            }
                        },
                        close: function(win) {
                            if (this.modal) {
                                var dom = Ext.dom.Query.select('.x-mask');
                                for (var i = 0; i < dom.length; i++) {
                                    Ext.get(dom[i]).setStyle('opacity', 1);
                                    var el = Ext.get(dom[i]);
                                    el.removeCls('customWinMask');
                                }
                            }
                        }
                    }
                });
                return win;
            },
            __getObjectListData: function(){
                var me = this;
                var objectListData = [{ objectName: "--None--", objectLabel: $TR.NONE }];
                if(me.__metadata.eventObjects) objectListData.push.apply(objectListData,me.__metadata.eventObjects);
                return objectListData;
            },
            __apply: function() {
                var me = this;
                var shouldApply = me.__shouldAllowApply();
                if (!shouldApply.isValid) {
                    SVMX.getCurrentApplication().showQuickMessage('error', shouldApply.message);
                    me.__highlightRow(shouldApply.rowIndex);
                } else {
                    var objName = me.showObjects.getSelectedRecord().data.objectName;
                    var objLbl = me.showObjects.getSelectedRecord().data.objectLabel;
                    var fld = [];
                    var allFields = me.__getAllFieldDetails();
                    if (allFields) fld = allFields;
                    var payload = {
                        objName: objName,
                        fld: fld,
                        objLbl: objLbl
                    };
                    me.__parentContext.applyEvent(me.__selectedCell, me.__recordIndex, payload);
                    me.__win.close();
                }
            },
            __getAllFieldDetails: function() {
                var me = this;
                var allFields = [];
                var items = me.fieldGridStore.data.items;
                var l = items.length;
                for (var i = 0; i < l; i++) {
                    var data = items[i].data;
                    var fldObject = {
                        fldLabel: data.fldLabel,
                        fldKey: data.fldKey,
                        fldApi: data.fldApi,
                        fldType: data.fldType,
                        refLabel: data.refLabel,
                        isExternalId: data.isExternalId
                    }
                    if (data.fldType == 'REFERENCE') {
                        fldObject.refObj = data.refObj;
                        fldObject.refFld = data.refFld;
                    }
                    allFields.push(fldObject);
                }
                return allFields;
            },
            __shouldAllowApply: function() {
                var me = this;
                var returnObj = {
                    isValid: false,
                    message: '',
                    rowIndex: 0
                };
                var allKeys = me.__getAllKeys();
                var allFields = me.__getAllFields();
                var allLookUps = me.__getAllLookups();
                var duplicateFields = me.__validateDuplicateValues(allFields);
                var emptyKeyIndex = me.__checkEmptyValues(allKeys);
                var emptyFieldIndex = me.__checkEmptyValues(allFields.apis);
                var emptyLookups = me.__checkEmptyValues(allLookUps);
                var duplicateValues = [];
                if (allKeys.length == 0 && allFields.apis.length == 0) {
                    returnObj.message = $TR.EMPTY_FIELD;
                    returnObj.rowIndex = 0;
                } else if (emptyKeyIndex !== -1) {
                    returnObj.message = $TR.EMPTY_KEY;
                    returnObj.rowIndex = emptyKeyIndex;
                } else if (emptyFieldIndex !== -1) {
                    returnObj.message = $TR.EMPTY_FIELD;
                    returnObj.rowIndex = emptyFieldIndex;
                } else if (duplicateFields.isFound) {
                    duplicateValues = duplicateFields.duplicateValues.join();
                    returnObj.message = $TR.DUPLICATE_FIELD + ' : ' + duplicateValues;
                    returnObj.rowIndex = duplicateFields.rowIndex;
                } else if (emptyLookups !== -1) {
                    returnObj.message = $TR.EMPTY_LOOKUP_ID;
                    returnObj.rowIndex = emptyFieldIndex;
                } else {
                    returnObj.isValid = true;
                }
                return returnObj;
            },
            __validateDuplicateValues: function(allFlds) {
                var allValues = allFlds.apis;
                var allLabels = allFlds.labels;
                var duplicateValues = [];
                var caseInsensitiveValues = [];
                var isFound = false;
                var rowIndex = 0;
                for (var i = 0; i < allValues.length; i++) {
                    var value = allValues[i];
                    var num = allValues.reduce(function(count, label) {
                        if (label.toLowerCase() === value.toLowerCase())
                            count++;
                        return count;
                    }, 0);
                    if (num > 1) {
                        if (caseInsensitiveValues.indexOf(value.toLowerCase()) > -1) {
                            //In the array!
                        } else {
                            duplicateValues.push(allLabels[i]);
                            caseInsensitiveValues.push(value.toLowerCase());
                        }
                        isFound = true;
                        rowIndex = i;
                    }
                }
                var returnObject = {
                    duplicateValues: duplicateValues,
                    isFound: isFound,
                    rowIndex: rowIndex
                };
                return returnObject;
            },
            __highlightRow: function(rowIndex) {
                var me = this;
                var view = me.fieldGrid.getView();
                var row = view.getRow(rowIndex);
                Ext.get(row).scrollIntoView(view.getEl(), null, true);
                Ext.get(row).addCls('piq-setup-new-attributes-row');
            },
            __checkEmptyValues: function(allItems) {
                return $.inArray("", allItems);
            },
            __checkIfArrayValuesAreUnique: function(keyArray) {
                return keyArray.length === new Set(keyArray).size;
            },
            __getAllLookups: function() {
                var lookups = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    lookups.push(allItems[i].data.refLabel);
                }
                return lookups;
            },
            __getAllKeys: function() {
                var keys = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var ikey = 0; ikey < allItems.length; ikey++) {
                    keys.push(allItems[ikey].data.fldKey);
                }
                return keys;
            },
            __getAllFields: function() {
                var fldApis = [];
                var fldLabels = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var ikey = 0; ikey < allItems.length; ikey++) {
                    fldApis.push(allItems[ikey].data.fldApi);
                    fldLabels.push(allItems[ikey].data.fldLabel);
                }
                var flds = {
                    apis: fldApis,
                    labels: fldLabels
                };
                return flds;
            },
            __onSelectObjects: function(combo, record) {
                var me = this;
                me.__resetFieldGrid();
                if (combo.getSelectedRecord().get("objectName") == "--None--") {
                    me.fieldGrid.addFieldButton.setDisabled(true);
                    me.__applyButton.setDisabled(true);
                } else {
                    var selectedObjectName = combo.getSelectedRecord().get("objectName");
                    me.__describeSelectedObject(selectedObjectName);
                }
            },
            __describeSelectedObject: function(selectedObjectName) {
                var me = this;
                me.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.DESCRIBE_OBJECT",
                    me, {
                        request: {
                            context: me,
                            requestData: {
                                allObjects: [{ objectAPIName: selectedObjectName }]
                            }
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            describeSelectedObjectComplete: function(data) {
                var me = this;
                me.fieldGrid.addFieldButton.setDisabled(false);
                me.__applyButton.setDisabled(false);
                me.__loadFieldStoreData(data);
            },
            __loadFieldStoreData: function(data) {
                var me = this;
                var __fieldStoreData = [];
                var describeObject = data.sforceObjectDescribes[0];
                var allFields = describeObject.fields;
                for (var i = 0; i < allFields.length; i++) {
                    var field = allFields[i];
                    __fieldStoreData.push({ fldApi: field.fieldAPIName, fldLabel: field.fieldLabel, fldType: field.type, referenceTo: field.referenceTo, isExternalId: field.isExternalId });
                }
                me.fieldStore.setData(__fieldStoreData);
                me.unblockUI();
            },
            __resetFieldGrid: function() {
                var me = this;
                me.fieldGridStore.clearData();
                me.fieldGridStore.removeAll();
                me.fieldGrid.view.refresh();
            },
            blockUI: function() {
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

                this.__spinner = new Spinner(opts).spin($("#" + this.__win.el.dom.id)[0]);
            },

            unblockUI: function() {
                this.__spinner.stop();
            }
        });
        //FieldsGrid   class start.
        Ext.define("com.servicemax.client.iot.admin.FieldsGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            fieldStore: null,
            __refObjDescribes: null,
            constructor: function(config) {
                var me = this;
                var config = config || {};
                me.__refObjDescribes = {};
                if (config.fieldStore) me.fieldStore = config.fieldStore || {};
                me.addFieldButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'piq-setup-add-button',
                    disabled: true,
                    id: 'addFieldRecordbutton',
                    handler: function() {
                        me.addFieldRecord({ name: '' });
                    }
                });
                config.dockedItems = [{
                    xtype: 'toolbar',
                    dock: 'top',
                    items: [{ xtype: 'tbfill' }, me.addFieldButton]
                }];
                config.columns = [{
                    menuDisabled: true,
                    sortable: false,
                    xtype: 'actioncolumn',
                    width: 50,
                    items: [{ iconCls: 'delet-icon', tooltip: $TR.DELETE }],
                    handler: function(grid, rowIndex, colIndex) {
                        var gridStore = grid.getStore();
                        var rec = gridStore.getAt(rowIndex);
                        gridStore.remove(rec);
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[0].items[0].iconCls = 'delet-icon';
                    }
                }];
                config.columns.push(me.createComboBoxColumn({
                    text: $TR.FILED_NAME,
                    dataIndex: 'fldLabel',
                    flex: 1,
                    store: me.fieldStore,
                    renderer: function(value) {
                        return Ext.String.htmlEncode(value);
                    }
                }));
                config.columns.push(me.createComboBoxColumnForReference({
                    text: $TR.LOOKUP_FIELD_ID,
                    dataIndex: 'refLabel',
                    flex: 1,
                }));
                config.columns.push(me.createTextBoxColumn({ text: $TR.FIELD_KEY, dataIndex: 'fldKey', flex: 1, listeners: null }));
                me.callParent([config]);
            },
            __describeReferenceObject: function(objects) {
                var allObjects = [];
                for (var i = 0; i < objects.length; i++) {
                    allObjects.push({ objectAPIName: objects[i] });
                }
                var me = this;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.DESCRIBE_OBJECT", me, {
                    request: {
                        context: me,
                        requestData: {
                            allObjects: allObjects
                        },
                        isRefobj: true
                    }
                });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            describeReferenceObjectComplete: function(data) {
                this.__reloadObjectDescribes(data);
            },
            __reloadObjectDescribes: function(data) {
                var sforceObjectDescribes = data.sforceObjectDescribes;
                for (var i = 0; i < sforceObjectDescribes.length; i++) {
                    var objName = sforceObjectDescribes[i].objectAPIName;
                    var objLbl = sforceObjectDescribes[i].objectLabel;
                    var fields = [];
                    var flds = sforceObjectDescribes[i].fields;
                    for (var fldIndex = 0; fldIndex < flds.length; fldIndex++) {
                        var fld = flds[fldIndex];
                        if (fld.fieldAPIName === 'Name' || fld.fieldAPIName === 'Id' || fld.isExternalId == true) {
                            fields.push(fld);
                        }
                    }
                    var describeObject = {
                        objName: objName,
                        objLbl: objLbl,
                        flds: fields
                    }
                    this.__refObjDescribes[objName] = describeObject;
                }
            },
            addFieldRecord: function(records) {
                if (!records) return;
                var rowIndex = this.getStore().count();
                this.store.insert(this.getStore().count(), records);
                var view = this.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
            },
            __updateLookUpLabel: function(label) {
                var model = this.getSelectionModel();
                var fldRec = model.getSelection()[0];
                fldRec.set("refLabel", label);
            },
            createComboBoxColumn: function(fieldInfo) {
                var me = this;
                var fldCombo = SVMX.create('com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor', {
                    displayField: 'fldLabel',
                    queryMode: 'local',
                    editable: false,
                    valueField: 'fldApi',
                    fieldName: fieldInfo.dataIndex,
                    store: fieldInfo.store,
                    parentContext: me,
                    rowIndex: -1,
                    listeners: {
                        select: function(combo, record, index) {
                            var me = this;
                            var gridRowIndex = me.parentContext.editRowIndex;
                            var comboData = record.data;
                            me.parentContext.store.data.items[gridRowIndex].data.fldType = comboData.fldType;
                            me.parentContext.store.data.items[gridRowIndex].data.fldApi = comboData.fldApi;
                            me.parentContext.store.data.items[gridRowIndex].data.refObj = comboData.referenceTo;
                            me.parentContext.store.data.items[gridRowIndex].data.isExternalId = comboData.isExternalId;
                            me.parentContext.store.data.items[gridRowIndex].data.refFld = '';

                            if (comboData.fldType === 'REFERENCE') {
                                if (!me.parentContext.__refObjDescribes[comboData.referenceTo]) {
                                    me.parentContext.__describeReferenceObject([comboData.referenceTo]);
                                }
                                me.parentContext.__updateLookUpLabel('');
                            } else {
                                me.parentContext.__updateLookUpLabel($TR.NA);
                            }
                        },
                        beforeedit: function(cellEditor, context, eOpts) {
                            console.log(context.rowIdx);
                            rowIndex = context.rowIdx;
                        }
                    }
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.menuDisabled = false;
                fieldInfo.sortable = true;
                fieldInfo.parentContext = me,
                    fieldInfo.getEditor = function(currentRecord) {
                        fldCombo.setRecord(currentRecord);
                        fldCombo.setValue(currentRecord.data.fldApi);
                        return fldCombo;
                    };
                return fieldInfo;
            },
            createComboBoxColumnForReference: function(fieldInfo) {
                var me = this;
                var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldApi', type: 'string' }, { name: 'fldLabel', type: 'string' }, { name: 'fldType', type: 'string' }],
                    data: [],
                    sorters: [{
                        property: 'fldLabel',
                        direction: 'ASC'
                    }]
                });
                var fldCombo = SVMX.create('com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor', {
                    displayField: 'fldLabel',
                    queryMode: 'local',
                    editable: false,
                    valueField: 'fldApi',
                    fieldName: fieldInfo.dataIndex,
                    store: store,
                    parentContext: me,
                    rowIndex: -1,
                    listeners: {
                        select: function(combo, record, index) {
                            var me = this;
                            var gridRowIndex = me.parentContext.editRowIndex;
                            me.parentContext.store.data.items[gridRowIndex].data.refFld = combo.value;
                        },
                        beforeedit: function(cellEditor, context, eOpts) {

                        }
                    }
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.menuDisabled = false;
                fieldInfo.sortable = true;
                fieldInfo.parentContext = me,
                    fieldInfo.getEditor = function(currentRecord) {
                        var editor;
                        var data = currentRecord.data;
                        var type = data.fldType;
                        if (!type || type !== "REFERENCE") {
                            editor = null;
                        } else {
                            fldCombo.setRecord(currentRecord);
                            fldCombo.setValue(currentRecord.data.refFld);
                            var flds = this.parentContext.__refObjDescribes[data.refObj].flds;
                            var storeData = [];
                            for (var i = 0; i < flds.length; i++) {
                                var field = flds[i];
                                storeData.push({
                                    fldApi: field.fieldAPIName,
                                    fldLabel: field.fieldLabel
                                });
                            }
                            fldCombo.store.setData(storeData);
                            editor = fldCombo;
                        }
                        return editor;
                    };
                return fieldInfo;
            },
            createTextBoxColumn: function(fieldInfo) {
                var me = this;
                var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                    allowBlank: true,
                    editable: true,
                    maskRe: /[^ ]/
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return txtboxCol;
                };
                return fieldInfo;
            }

        });
        //FieldsGrid class end.
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\impl.js

(function(){
	SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXC";
	
	var iotImpl = SVMX.Package("com.servicemax.client.iot.admin.impl");

	iotImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
			//SVMX.orgNamespace = S
		},

		afterInitialize : function(){
			
		},
		
		beforeInitialize: function() {
			com.servicemax.client.iot.admin.root.init();
			com.servicemax.client.iot.admin.celleditors.init();
			com.servicemax.client.iot.admin.othersettings.init();
			com.servicemax.client.iot.admin.commands.init();
			com.servicemax.client.iot.admin.operations.init();
			com.servicemax.client.iot.admin.compositekey.init();
			com.servicemax.client.iot.admin.ioteventmap.init();
			com.servicemax.client.iot.admin.createevent.init();
			com.servicemax.client.iot.admin.maptoobject.init();
		},

		registerForSALEvents : function(serviceCall, operationObj){
			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("registerForSALEvents was invoked without operationObj!");
			}

			serviceCall.bind("REQUEST_ERROR", function(errEvt){

				// unblock the UI if is blocked
				var currentApp = operationObj ? operationObj.getEventBus() : SVMX.getCurrentApplication();
				//var de = operationObj ? operationObj.getEventBus().getDeliveryEngine() : null;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.CHANGE_APP_STATE", this, {request : {state : "unblock"}, responder : {}});
				currentApp.triggerEvent(evt);
				var message = "Custom Tag ";
 				try{ message  += "::" + errEvt.data.xhr.statusText + "=>" + errEvt.data.xhr.responseText; }catch(e){}
 				// notify about the error
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_APP_ERROR", this, {request : {message : message }, responder : {}});
 				currentApp.triggerEvent(evt);

				//this.__logger.error(message);
			}, this);
		},
		
		createServiceRequest : function(params, operationObj){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
			servDef.getInstanceAsync({handler : function(service){
				var options = params.options || {};
				var p = {type : options.type || "REST", endPoint : options.endPoint || "",
									nameSpace : "SVMXDEV"};
				var sm = service.createServiceManager(p);
				var sRequest = sm.createService();
				this.registerForSALEvents(sRequest, operationObj);
				params.handler.call(params.context, sRequest);
			}, context:this });
		},
		
		checkResponseStatus : function(operation, data, hideQuickMessage, operationObj){
			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("checkResponseStatus was invoked without operationObj!");
			}

			var ret = true, message = "", msgDetail = "";

			// the success attributes are available in the response from ServiceMax APEX services
			if(data){
				if(data.response && (data.response.success === false || data.response.success === "false")){
					ret = false;

					// user friendly data
					if(data.response.msgDetails && data.response.msgDetails.message){
						message = data.response.msgDetails.message;
						msgDetail = data.response.msgDetails.details;
					}else{
						message = data.response.message;
					}
				}else if(data.success === false || data.success === "false"){
					ret = false;

					// user friendly data
					if(data.msgDetails && data.msgDetails.message){
						message = data.msgDetails.message;
						msgDetail = data.msgDetails.details;
					}else{
						message = data.message;
					}
				}
			}

			var currentApp = operationObj ? operationObj.getEventBus() : SVMX.getCurrentApplication(), evt;
			if(ret == false){
				// unblock the UI if is blocked
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.CHANGE_APP_STATE", this, {
						request : {state : "unblock"}, responder : {}});
				currentApp.triggerEvent(evt);

					// notify about the error
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_APP_ERROR", this, {
						request : {
							message : message,
							msgDetail : msgDetail
						},
						responder : {}});
				currentApp.triggerEvent(evt);
				var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");
				this.__logger.error(operation + " : " + TS.T("TAG035") + " " + message);
			}else if(!hideQuickMessage){
				var quickMessage = null, quickMessageType = null;
				if(data.response && data.response.message){
					quickMessage = data.response.message;
					quickMessageType = data.response.messageType;
				}else if(data.message){
					quickMessage = data.message;
					quickMessageType = data.messageType;
				}

				if(quickMessage && typeof(quickMessage) == 'string'){
					evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_QUICK_MESSAGE", this, {
						request : {
							message : quickMessage,
							type : quickMessageType
						},
						responder : {}});
					currentApp.triggerEvent(evt);
				}
			}

			return ret;
		}
		
	}, {instance : null});
	
	iotImpl.Class("IoTAdminEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); },
		
		triggerEvent : function(e) {
			return this.__base(e);
		}
		
	}, {});
	
	
	
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\iotadminoperations.js
(function() {
    var iotadminoperations = SVMX.Package("com.servicemax.client.iot.admin.operations");
    iotadminoperations.init = function() {
        var Module = com.servicemax.client.installigence.ui.components.impl.Module;
        iotadminoperations.Class("GetSetupMetadata", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {
                };
                InstalligenceSetupJsr.JsrGetSetupMetadata(requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("Save", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {
                    events: request.events,
                    deletedEvents: request.deletedEvents,
                    compositeKey: request.compositeKey,
                    objectMapEvents: request.objectMapEvents,
                    deletedObjectMap: request.deletedObjectMap

                };
                InstalligenceSetupJsr.JsrSave(requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("BackToSetupHome", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {};
                InstalligenceSetupJsr.JsrBackToSetupHome(requestData, function(result, evt) {
                }, this);
            }
        }, {});
        iotadminoperations.Class("DescribeObject", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                InstalligenceSetupJsr.JsrDescribeObject(request.requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("GetAllEventTemplates", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var module = Module.instance;
                Module.instance.createServiceRequest({
                    handler: function(sRequest) {
                        sRequest.bind("REQUEST_COMPLETED", function(evt) {
                            if (module.checkResponseStatus("GetAllEventTemplates", evt.data, false, this) == true) {
                                responder.result(evt.data.records);
                            }
                        }, this);
                        sRequest.bind("REQUEST_ERROR", function(evt) {
                            if (module.checkResponseStatus("GetAllEventTemplates", evt.data, false, this) == true) {
                                responder.result([]);
                            }
                        }, this);
                        var query = encodeURI('SELECT Id,' + SVMX.OrgNamespace + '__SM_Event_Name__c,' + SVMX.OrgNamespace + '__SM_Description__c ,' + SVMX.OrgNamespace + '__SM_JSON_Payload__c  FROM ' + SVMX.OrgNamespace + '__SM_IoT_Field_Mapping__c');
                        sRequest.callApiAsync({ url: "query?q=" + query });
                    },
                    context: this
                }, this);
            }
        }, {});
    };
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\ioteventmap.js
(function() {
    var ioteventmap = SVMX.Package("com.servicemax.client.iot.admin.ioteventmap");
    ioteventmap.init = function() {
        Ext.define("com.servicemax.client.iot.admin.ioteventmap", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            constructor: function(config) {
                var me = this;
                // Map to Apex.
                me.otherSettings = SVMX.create('com.servicemax.client.iot.admin.OtherSettings', {
                    metadata: metadata
                });
                // Map to Object.
                 me.maptoobject = SVMX.create('com.servicemax.client.iot.admin.Maptoobject', {
                    metadata: metadata
                });
               
                me.eventTabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel', {
                    tabPosition: 'top',
                    tabRotation: 0,
                    cls: 'iot-setup-tab-horizantal'
                    
                });
                me.eventTabPanel.add(me.otherSettings);
                me.eventTabPanel.add(me.maptoobject);
                me.eventTabPanel.setActiveTab("OS");
                config = config || {};
                config.items = [me.eventTabPanel];
                config.title = $TR.IOT_EVENTS;
                config.id = 'EM';
                me.callParent([config]);
            },
            getData: function() {
                var me = this;
                var otherSettingData = me.otherSettings.getData();
                var maptoobjectData = me.maptoobject.getData();
                var finalData = otherSettingData.data.concat(maptoobjectData.data);
                var finalDeletedEvents = otherSettingData.deletedEvents.concat(maptoobjectData.deletedEvents);
                var data = {
                    data: finalData,
                    deletedEvents: finalDeletedEvents
                };
                return data;
            },
            getMappingRecords: function() {
                var records = {};
                records = this.maptoobject.getMappingRecords();
                return records;
            },
            shouldSave: function() {
                var me = this;
                var returnObject = {};
                returnObject = me.maptoobject.shouldSave();
                if (returnObject.isValid) {
                    var otherSettingEvents = me.otherSettings.getAllEventName();
                    var maptoObjectEvents = me.maptoobject.getAllEventName();
                    var allEvents = [];
                    allEvents = otherSettingEvents.concat(maptoObjectEvents);
                    returnObject = me.__validateDuplicateValues(allEvents);
                }
                return returnObject;
            },
            __validateDuplicateValues: function(allValues) {
                var duplicateValues = [];
                var caseInsensitiveValues = [];
                var isFound = false;
                for (var i = 0; i < allValues.length; i++) {
                    var value = allValues[i];
                    var num = allValues.reduce(function(count, label) {
                        if (label.toLowerCase() === value.toLowerCase())
                            count++;
                        return count;
                    }, 0);
                    if (num > 1) {
                        if (caseInsensitiveValues.indexOf(value.toLowerCase()) > -1) {
                            //In the array!
                        } else {
                            duplicateValues.push(allValues[i]);
                            caseInsensitiveValues.push(value.toLowerCase());
                        }
                        isFound = true;
                    }
                }
                var returnObject = {
                    message: $TR.DUPLICATE_EVENT_NAMES + duplicateValues.join(),
                    isValid: !isFound
                };
                return returnObject;
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\maptoobject.js
(function() {
    var maptoobject = SVMX.Package("com.servicemax.client.iot.admin.maptoobject");
    maptoobject.init = function() {
        Ext.define("com.servicemax.client.iot.admin.Maptoobject", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            metadata: null,
            constructor: function(config) {
                var me = this;
                me.refresh();
                me.metadata = config.metadata,
                    config.items = [];
                me.eventStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'eventName', type: 'string' }, { name: 'eventDescription', type: 'string' }, { name: 'objectName', type: 'string' }, { name: 'sfdc', type: 'string' }, { name: 'eventId', type: 'string' }, { name: 'payload', type: 'string' }],
                    data: []
                });
                me.eventGrid = SVMX.create('com.servicemax.client.iot.admin.EventGrid', {
                    cls: 'grid-panel-borderless panel-radiusless iot-setup-ta-grid iot-create-map-for-object-grid',
                    store: me.eventStore,
                    autoScroll: true,
                    parentContext: me,
                    selType: 'cellmodel',
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {
                        markDirty: false,
                        getRowClass: function(record, index) {
                            return 'iot-maptoobject-object-cell';
                        }
                    },
                    listeners: {
                        cellclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {
                            if (cell.config.grid.columns[cellIndex].dataIndex === "objectName") {
                                var payloadString = cell.config.grid.getStore().data.items[rowIndex].data.payload,
                                    payload = null;
                                if (payloadString !== "") payload = JSON.parse(payloadString);
                                var createEventObject = SVMX.create("com.servicemax.client.iot.admin.createevent.CreateEvent", { recordIndex: rowIndex, selectCell: cell, parentContext: cell.config.grid.parentContext, metadata: cell.config.grid.parentContext.metadata, payload: payload });
                            }
                        },
                        edit: function(editor, e, eOpts) {}
                    }
                });
                var searchToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-width: 0'
                });
                var addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'iot-setup-add-button',
                    handler: function() {
                        me.__onAddRecords();
                    }
                });
                searchToolbar.add('->');
                searchToolbar.add(addRecButton);
                var formPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel', {
                    style: 'margin: 1px 0',
                    layout: 'fit',
                    cls: 'grid-panel-borderless',
                    defaults: {
                        anchor: '40%'
                    }
                });
                formPanel.add(me.eventGrid);
                config.items.push(searchToolbar);
                config.items.push(formPanel);
                config.title = $TR.MAP_TO_OBJECT;
                config.id = 'MO';
                me.callParent([config]);
                me.__loadAllEventTemplates();
            },
            shouldSave: function() {
                var me = this;
                var returnObject = {
                    isValid: true,
                    message: ''
                };
                var maps = me.__getAllMappings();
                var names = me.getAllEventName();
                var emptyRowIndex;
                if (Boolean($.inArray("", maps) + 1)) {
                    returnObject.isValid = false;
                    returnObject.message = $TR.SELECT_FIELD_MAP;
                    emptyRowIndex = $.inArray("", maps);
                } else if (Boolean($.inArray("", names) + 1)) {
                    returnObject.isValid = false;
                    returnObject.message = $TR.EMPTY_EVENT_NAME;
                    emptyRowIndex = $.inArray("", names);
                }
                if(!returnObject.isValid) me.__highlightRow(emptyRowIndex);
                return returnObject;
            },
            getAllEventName: function() {
                var names = [];
                var me = this;
                var allItems = me.eventStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    names.push(allItems[i].data.eventName);
                }
                return names;
            },
            __getAllMappings: function() {
                var maps = [];
                var me = this;
                var allItems = me.eventStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    maps.push(allItems[i].data.payload);
                }
                return maps;
            },
            getMappingRecords: function() {
                var grid = this.eventGrid;
                var data = grid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    records.push(data[iData].data);
                }
                return { data: records, deletedEventMapIds: grid.deletedEventMapIds };
            },
            getData: function() {
                var grid = this.eventGrid;
                var data = grid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    var eventData = data[iData].data;
                    var record = {
                        eventName: eventData.eventName,
                        className: "COMM_IoTRestApiEngine"
                    }
                    if (eventData.eventId !== "") record.eventId = eventData.eventId;
                    records.push(record);
                }
                return { data: records, deletedEvents: grid.deletedEventIds };
            },
            __onAddRecords: function(records) {
                var me = this;
                me.eventGrid.addItems({ 'objectName': $TR.SELECT });
                me.eventGrid.getView().refresh();
                var rowIndex = me.eventGrid.store.data.items.length - 1;
                var view = me.eventGrid.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
                view.select(rowIndex);
            },
            __loadAllEventTemplates: function() {
                var me = this;
                SVMX.getCurrentApplication().blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.GET_ALL_EVENT_TEMPLATES", me, { request: { context: me } });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            loadAllEventTemplatesComplete: function(data) {
                var me = this;
                var l = data.length;
                var eventData = [];
                for (var iEvt = 0; iEvt < l; iEvt++) {
                    var iData = data[iEvt];
                    var jsonObject = JSON.parse(iData[SVMX.OrgNamespace + '__SM_JSON_Payload__c']);
                    var objName = jsonObject.objLbl;
                    var eventRowData = {
                        eventName: iData[SVMX.OrgNamespace + '__SM_Event_Name__c'],
                        eventDescription: iData[SVMX.OrgNamespace + '__SM_Description__c'],
                        sfdc: iData['Id'],
                        objectName: objName,
                        payload: iData[SVMX.OrgNamespace + '__SM_JSON_Payload__c']
                    };
                    var eventItems = me.__getEventItems(me.metadata.events, eventRowData.eventName);
                    if (eventItems) {
                        var eventId = eventItems.eventId;
                        eventRowData.eventId = eventId;
                    }
                    eventData.push(eventRowData);
                }
                me.eventStore.loadData(eventData);
                SVMX.getCurrentApplication().unblockUI();
            },
            __getEventItems: function(allEvents, eventName) {
                var event = null;
                for (var iEvent = 0; iEvent < allEvents.length; iEvent++) {
                    if (allEvents[iEvent].eventName === eventName) {
                        event = allEvents[iEvent];
                        break;
                    }
                }
                return event;
            },
            applyEvent: function(cell, recordIndex, payload) {
                var me = this;
                var stringPayload = JSON.stringify(payload);
                me.eventGrid.store.data.items[recordIndex].data.objectName = payload.objLbl;
                me.eventGrid.store.data.items[recordIndex].data.payload = stringPayload;
                me.eventGrid.getView().refresh();
            },
            refresh: function() {
                var me = this;
                SVMX.getClient().bind("SAVE_SUCCESS", function(evt) {
                    me.metadata = evt.data;
                    me.__loadAllEventTemplates();
                }, me);

            },
            __highlightRow: function(rowIndex) {
                var me = this;
                var view = me.eventGrid.getView();
                var row = view.getRow(rowIndex);
                Ext.get(row).scrollIntoView(view.getEl(), null, true);
                Ext.get(row).addCls('piq-setup-new-attributes-row');
            },
        });
        // event grid class start.
        Ext.define("com.servicemax.client.iot.admin.EventGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            deletedEventMapIds: null,
            deletedEventIds: null,
            constructor: function(config) {
                var me = this;
                me.deletedEventMapIds = [];
                me.deletedEventIds = [];
                var config = config || {};
                me.addFieldButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'piq-setup-add-button',
                    disabled: false,
                    id: 'addFieldRecordbutton',
                    handler: function() {
                        me.addFieldRecord({ name: '' });
                    }
                });
                config.columns = [{
                    menuDisabled: true,
                    sortable: false,
                    xtype: 'actioncolumn',
                    width: 50,
                    items: [{ iconCls: 'delet-icon', tooltip: $TR.DELETE }],
                    handler: function(grid, rowIndex, colIndex) {
                        var gridStore = grid.getStore();
                        var rec = gridStore.getAt(rowIndex);
                        gridStore.remove(rec);
                        var data = rec.data;
                        if (data.sfdc && data.eventId) {
                            me.deletedEventMapIds.push(data.sfdc);
                            me.deletedEventIds.push(data.eventId);
                        }
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[0].items[0].iconCls = 'delet-icon';
                    }
                }];
                config.columns.push(me.createTextBoxColumn({
                    text: $TR.EVENT_NAME,
                    dataIndex: 'eventName',
                    flex: 1,
                    parentContext: me,
                    maskRe: /[^ ]/,
                    listeners: {
                        blur: function(field) {
                            setTimeout(function() {
                                var allEventsName = field.parentContext.__getAllEventsName();
                                var newEventName = field.value;
                                var numOfEvent = allEventsName.reduce(function(count, label) {
                                    if (label.toLowerCase() === newEventName.toLowerCase())
                                        count++;
                                    return count;
                                }, 0);
                                if (numOfEvent > 1) {
                                    SVMX.getCurrentApplication().showQuickMessage('error', 'Event name already exists');
                                }
                            }, 200);
                        }
                    }
                }));
                config.columns.push(this.createTextBoxColumn({ text: $TR.EVENT_DESCRIPTION, dataIndex: 'eventDescription', flex: 1, listeners: null }));
                config.columns.push(this.createObjectColumn({ text: $TR.OBJECT, dataIndex: 'objectName', flex: 1, listeners: null, tdCls: 'x-change-cell' }));
                me.callParent([config]);
            },
            __getAllEventsName: function() {
                var eventsName = [];
                var me = this;
                var allItems = me.store.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    eventsName.push(allItems[i].data.eventName);
                }
                return eventsName;
            },
            addFieldRecord: function(records) {
                if (!records) return;
                var rowIndex = this.getStore().count();
                this.store.insert(this.getStore().count(), records);
                var view = this.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
            },
            createTextBoxColumn: function(fieldInfo) {
                var me = this;
                var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                    allowBlank: true,
                    editable: true,
                    listeners: fieldInfo.listeners,
                    parentContext: fieldInfo.parentContext,
                    maskRe: fieldInfo.maskRe
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return txtboxCol;
                };
                return fieldInfo;
            },
            createObjectColumn: function(fieldInfo) {
                var me = this;
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return null;
                };
                return fieldInfo;
            }
        });
        // event grid class end.   
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\othersettings.js
(function() {
    var othersettings = SVMX.Package("com.servicemax.client.iot.admin.othersettings");

    othersettings.init = function() {

        Ext.define("com.servicemax.client.iot.admin.eventsGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            metadata: null,
            deletedIds: null,
            constructor: function(config) {
                var me = this;
                this.deletedIds = [];
                config.columns = [];
                config.columns.push(this.createTextBoxColumn({
                    text: $TR.EVENT_NAME,
                    dataIndex: 'eventName',
                    width: 400,
                    flex: 1
                }));

                config.columns.push(this.createTextBoxColumn({
                    text: $TR.CLASS_NAME,
                    dataIndex: 'className',
                    width: 400,
                    flex: 1
                }));

                config.columns.push({
                    menuDisabled: true,
                    sortable: true,
                    xtype: 'actioncolumn',
                    width: 50,
                    items: [{
                        iconCls: 'delet-icon',
                        tooltip: $TR.DELETE
                    }],
                    handler: function(grid, rowIndex, colIndex) {
                        var gridStore = grid.getStore();
                        var rec = gridStore.getAt(rowIndex);
                        var eventId = rec.data["eventId"];
                        if (eventId)
                            me.deletedIds.push(eventId)
                        gridStore.remove(rec);
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[config.columns.length - 1].items[0].iconCls = 'delet-icon';
                    }
                });

                this.metadata = config.metadata;
                this.callParent([config]);
                this.loadData();
            },

            getDeletedEvents: function() {
                return this.deletedIds;
            },

            loadData: function() {
                var me = this;
                me.store.loadData(me.filterMapToObjectEvents());
                me.store.commitChanges();
            },
            filterMapToObjectEvents: function() {
                var events = this.metadata.events.filter(function(items) {
                    return items.className !== "COMM_IoTRestApiEngine";
                });
                return events;
            },
            createTextBoxColumn: function(fieldInfo) {
                var me = this;
                var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                    allowBlank: true,
                    editable: true,
                    maskRe: /[^ ]/
                });

                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return txtboxCol;
                };

                return fieldInfo;
            }
        });

        Ext.define("com.servicemax.client.iot.admin.OtherSettings", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            eventsGrid: null,
            constructor: function(config) {
                var me = this;
                this.refresh();

                var eventsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: ['eventId', 'eventName', 'className'],
                    data: []

                });
                this.eventsGrid = SVMX.create('com.servicemax.client.iot.admin.eventsGrid', {
                    cls: 'grid-panel-borderless panel-radiusless iot-setup-ta-grid',
                    selType: 'cellmodel',
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {
                        markDirty: false
                    },
                    sortable: true,
                    store: eventsStore,
                    metadata: config.metadata
                });

                var userActionsPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel', {
                    style: 'margin: 1px 0',
                    layout: 'fit',
                    cls: 'grid-panel-borderless',
                    defaults: {
                        anchor: '40%'
                    }
                });
                userActionsPanel.add(this.eventsGrid);

                var searchToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-width: 0'
                });

                var addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'iot-setup-add-button',
                    handler: function() {
                        me.onAddRecords();
                    }
                });

                searchToolbar.add('->');
                searchToolbar.add(addRecButton);

                config = config || {};
                config.items = [];
                config.items.push(searchToolbar);
                config.items.push(userActionsPanel);
                config.title = $TR.MAP_TO_APEX;
                config.id = "OS";
                this.callParent([config]);
            },

            onAddRecords: function(grid) {
                this.eventsGrid.addItems({});
                this.eventsGrid.getView().refresh();
                var rowIndex = this.eventsGrid.store.data.items.length - 1;
                var view = this.eventsGrid.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
                view.select(rowIndex);
            },

            getData: function() {
                var data = this.eventsGrid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    if (!$.isEmptyObject(data[iData].data)) {
                        records.push(data[iData].data);
                    }
                }
                return { data: records, deletedEvents: this.eventsGrid.getDeletedEvents() };
            },

            refresh: function() {
                var me = this;
                SVMX.getClient().bind("SAVE_SUCCESS", function(evt) {
                    me.eventsGrid.metadata = evt.data;
                    var sforceObjectDescribes = metadata.sforceObjectDescribes;

                    for (var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
                        me.eventsGrid.metadata[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
                    }
                    me.eventsGrid.loadData();
                }, this);

            },
            getAllEventName: function() {
                var names = [];
                var me = this;
                var allItems = me.eventsGrid.getStore().data.items;
                for (var i = 0; i < allItems.length; i++) {
                    if(allItems[i].data.eventName)names.push(allItems[i].data.eventName);
                }
                return names;
            },
            createTextField: function(label) {
                return SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                    allowBlank: true,
                    editable: true,
                    margin: '5, 5',
                    labelAlign: 'right',
                    fieldLabel: label,
                    labelWidth: 200,
                    width: 550,
                    listeners: {
                        change: function(field, value) {

                        }
                    }
                });

            }
        });

    }

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.iot.admin\src\root.js
(function() {
    var root = SVMX.Package("com.servicemax.client.iot.admin.root");

    root.init = function() {
        Ext.define("com.servicemax.client.iot.admin.root.RootPanel", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            metadata: null,
            __spinner: null,
            constructor: function(config) {
                var me = this;

                config = config || {};
                config.renderTo = SVMX.getDisplayRootId();
                config.title = "<span class='title-text'>" + $TR.IOT_SETUP + "</span>";
                metadata = config.metadata;

                var otherSettings = SVMX.create('com.servicemax.client.iot.admin.OtherSettings', {
                    metadata: metadata
                });
                var iotEventMap = SVMX.create('com.servicemax.client.iot.admin.ioteventmap', {
                    metadata: metadata
                });

                var compositeKey = SVMX.create('com.servicemax.client.iot.admin.CompositeKey', {
                    metadata: metadata
                });

                var tabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel', {
                    height: 465,
                    tabPosition: 'left',
                    tabRotation: 0,
                    cls: 'iot-setup-tab-body',
                    tabBar: {
                        border: false,
                        cls: 'iot-setup-left-nav'
                    },
                    margin: '4 4 0 4',
                    ui: 'setup-tabpanel',
                    defaults: {
                        textAlign: 'left',
                        bodyPadding: 7,
                        cls: 'iot-setup-content-body',
                    }
                });
                tabPanel.add(iotEventMap);
                tabPanel.add(compositeKey);
                tabPanel.setActiveTab("EM");
                var saveButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.SAVE,
                    cls: 'iot-setup-save',
                    handler: function() {
                        me.save(compositeKey, iotEventMap);
                    }
                });

                var closeButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.BACK_TO_SETUP_HOME,
                    cls: 'iot-setup-back-to-home',
                    docked: 'left',
                    rigion: 'left',
                    align: 'left',
                    handler: function() {
                        //me.backToSetupHome();
                        //Added for the story BAC-4797
                        var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup";
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location.href = urlString;
                        }
                    }
                });

                var tools = [closeButton];
                config.tools = tools;

                var saveCloseButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.CANCEL,
                    cls: 'iot-setup-cancel',
                    handler: function() {
                        window.location.reload();
                    }
                });


                var toolBarItems = ['->', saveButton, saveCloseButton];
                var savencloseToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-top-width: 0 !important',
                    cls: 'iot-setup-profile-selection',
                    dock: 'top',
                    items: toolBarItems

                });


                config.items = [];
                config.items.push(savencloseToolbar);
                config.items.push(tabPanel);
                this.callParent([config]);
            },
            backToSetupHome: function() {
                this.blockUI();
                var me = this;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "IOT.BACK_TO_SETUP_HOME", me, { request: { context: me } });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            save: function(compositeKey, events) {
                var me = this;
                var shouldAllowSave = me.__shouldAllowSave(events);
                if (!shouldAllowSave.isValid) {
                    SVMX.getCurrentApplication().showQuickMessage('error', shouldAllowSave.message);
                } else {
                    me.blockUI();
                    var recs = events.getData();
                    var keys = compositeKey.getData();
                    var mappingRecs = events.getMappingRecords();
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "IOT.SAVE", me, {
                            request: {
                                context: me,
                                events: recs.data,
                                deletedEvents: recs.deletedEvents,
                                compositeKey: keys,
                                objectMapEvents: mappingRecs.data,
                                deletedObjectMap: mappingRecs.deletedEventMapIds
                            }
                        });
                    SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
                }
            },
            __shouldAllowSave: function(events) {
                return events.shouldSave();
            },
            onSaveComplete: function(data) {
                this.unblockUI();
                metadata = data;
                this.dataSavedSucessfullyMessage();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "SAVE_SUCCESS", this, data);
                SVMX.getClient().triggerEvent(evt);

            },

            dataSavedSucessfullyMessage: function(msg) {
                var messageToShow = $TR.SAVE_SUCCESS; //"Data Saved Successfully.";
                if (msg)
                    messageToShow = msg;

                var mb = Ext.Msg.alert({
                    title: $TR.INFO,
                    msg: messageToShow,
                    closable: false,
                    buttonText: { ok: $TR.OK },
                    fn: function(btn) {} // singleton
                });

            },

            blockUI: function() {
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
            },

            unblockUI: function() {
                this.__spinner.stop();
            }
        });

    }

})();

