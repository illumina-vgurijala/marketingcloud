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