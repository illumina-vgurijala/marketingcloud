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
