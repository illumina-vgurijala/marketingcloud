/**
 *  Picklist.
 * @class com.servicemax.client.installegence.admin.picklist
 * @author Rahman Sab C
 *
 * @copyright 2016 ServiceMax, Inc.
 **/

 (function(){

 	var picklist = SVMX.Package("com.servicemax.client.installigence.admin.picklist");
 	picklist.init = function() {

 		picklist.Class("Picklist",com.servicemax.client.lib.api.Object,{
 			__config : null,
 			__grid : null,
 			__store : null,
 			__win : null,
 			__selectedRecord : null,
 			__applyButton : null,
 			__searchTextField : null,
 			__constructor : function(config) {
 				var me = this;
 				this.__config = config;
 				this.__getTAPicklistDefinationRecords();
 				this.__win = this.__getUI();
 				this.__win.show(this.__config.selectedCell);
 			},

 			__getTAPicklistDefinationRecords : function() {
	 			SVMX.getCurrentApplication().blockUI();
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
						"INSTALLIGENCEADMIN." + this.__config.mvcEvent, this, 
						{request : { context : this, handler : this.__onFetchingPicklistComplete}});
				SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
 			},

 			__onFetchingPicklistComplete : function(data) {
 				this.__store.loadData(data);
 				SVMX.getCurrentApplication().unblockUI();
 			},

 			__getUI : function() {

 				var me = this;

 				//create the store.
 				var fields = this.__getGridDateStoreFileds();
 				var cols = this.__getGridColumnFields();
 				var name = SVMX.OrgNamespace+'__SM_Name__c';
	 			var description = SVMX.OrgNamespace+'__SM_Description__c';
 				
 				var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
 					fields:fields, 
 					data:[] //{SVMXDEV__SM_Name__c:'Name',SVMXDEV__SM_Description__c:'Name'}
 				});

 				//create the grid.
 				var gridColumns = [], c, j, l = cols.length;
 				gridColumns.push({
					menuDisabled: true,
					sortable: false,
					menuText: $TR.DELETE,
					xtype: 'actioncolumn',
					parentContext : me,
					width: 50,
					items: [{
								iconCls: 'piq-setup-delete-icon',
								tooltip: $TR.DELETE
							}],
					handler: function(grid, rowIndex, colIndex) {
						Ext.Msg.confirm({
							cls : 'piq-setup-alert-message',
						    title: $TR.CONFIRM_DELETE,
						    msg: $TR.ARE_YOU_SURE,
						    id : 'piq-setup-alert-message',
						    buttons: Ext.MessageBox.YESNO,
						    closable : false,
						    parentContext : me,
						    buttonText:{ 
				                yes: $TR.MESSAGE_CONFIRM, 
				                no:  $TR.CANCEL
				            },
						    fn: function(btn) {
						        if (btn === 'yes') {
						        	var gridStore = grid.getStore();
						            var rec = gridStore.getAt(rowIndex);
						            var me = Ext.Msg.cfg.parentContext;
						            me.__selectedRecord = rec;
						            me.__applyButton.setDisabled(true);
						            me.__deletePicklist(rec);
						        }else {
						        }
						    }
						});
	                },  		                
	                renderer: function (value, metadata, record) {
	                	
	                }
                });
                gridColumns.push({
					menuDisabled: true,
					sortable: false,
					xtype: 'actioncolumn',
					menuText: $TR.EDIT,
					width: 50,
					items: [{
								iconCls: 'piq-setup-edit-icon', //Replace with edit icon.
								tooltip: $TR.EDIT
							}],
					handler: function(grid, rowIndex, colIndex) {
						var gridStore = grid.getStore();
			            var rec = gridStore.getAt(rowIndex);
						var picklistObject = SVMX.create("com.servicemax.client.installigence.admin.picklist.PicklistDefination",{
				    		parentContext : me, picklistType : 'edit', selectedRecord : rec, grid : grid, rowIndex : rowIndex,metadata : me.__config.technicalAttributesContext.root.metadata		
				    	});
	                },  		                
	                renderer: function (value, metadata, record) {
	                	
	                }
                });
				for(i = 0; i < l; i++){
					c = cols[i];
					gridColumns.push({ text : c.name, dataIndex : c.dataIndex, flex : 1,
						renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                            } 
                        });
				}

				var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
	        	    store: store,
	        	    cls : 'piq-setup-ta-grid',
	        	    multiSelect: true,
	        	    viewConfig: {
	        	    	enableTextSelection: true,
                    },
	        	    columns: gridColumns, flex : 1, width: "100%",
	        	    listeners : {
	        	    	cellclick : function(cell , td , cellIndex , record , tr , rowIndex , e , eOpts) {

	        	    	},
	        	    	rowclick : function(row , record , element , rowIndex , e , eOpts) {
	        	    		// Ext.get(element).highlight();
	        	    		me.__grid.getSelectionModel().select(rowIndex);
	        	    		me.__selectedRecord = record;
	        	    		me.__applyButton.setDisabled(false);
	        	    	},
	        	    	afterrender: function(grid){
				            // grid.getSelectionModel().select(0);
				        }
	        	    }
	        	});


 				this.__searchTextField = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
	                width: '40%', emptyText : $TR.SEARCH_EMPTY_TEXT, enableKeyEvents : true,
	                docked: 'left',
	                align: 'left',
	                cls: 'piq-setup-picklist-textfield',
	                listeners : {
	                    change: {
	                        fn: me.__onTextFieldChange,
	                        scope: this,
	                        buffer: 500
	                    }
	                }
	            }); 

	            var addButton =  SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text:$TR.ADD,
					disabled: false,
					rigion:'right',
					docked: 'right',
					align: 'right',
					cls: 'piq-setup-add-button',
					parentContext:me,
					handler : function(){
						var picklistObject = SVMX.create("com.servicemax.client.installigence.admin.picklist.PicklistDefination",{
				    		parentContext : this, picklistType : 'create',grid : me.__grid, metadata : me.__config.technicalAttributesContext.root.metadata	
				    	});
					}
				});

				this.__applyButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{ 
                    text: $TR.APPLY, 
                    id : 'applybutton',
                    docked: 'right',
                    disabled : true,
                    align: 'right',
                    cls: 'piq-setup-picklist-apply-button',
                    parentContext:me,
                    handler : function(){
                    	if(this.parentContext.__selectedRecord) {
                    		var picklistName = this.parentContext.__selectedRecord.data[SVMX.OrgNamespace+'__SM_Name__c'];
                    		var picklistValues = this.parentContext.__selectedRecord.data[SVMX.OrgNamespace+'__SM_Values__c']
                    		var picklistSfId = this.parentContext.__selectedRecord.data["Id"];
                    		this.parentContext.__config.cellSelectedRecord.set('defaultValue','');
                    		this.parentContext.__config.cellSelectedRecord.set('picklistName',picklistName);
                    		this.parentContext.__config.cellSelectedRecord.set('picklistSfId',picklistSfId);
                    		this.parentContext.__config.cellSelectedRecord.set('defaultDisplayValue','');
                    		this.parentContext.refreshTechnicalAttributePageForPicklist(picklistSfId,picklistName);
                    		picklistName = picklistName.replace(/\s/g, "");
                    		var picklistValuesJSONObj = JSON.parse(picklistValues);
                    		if(picklistValuesJSONObj && picklistValuesJSONObj.setDefaultValue) {
                    			var valuesArray = picklistValuesJSONObj.values;
                    			if(valuesArray && valuesArray.length > 0) {
                    				this.parentContext.__config.cellSelectedRecord.set('defaultDisplayValue',valuesArray[0]);
                    			}
                    		}
							this.parentContext.__config.technicalAttributesContext.__templatePicklistModel[picklistName] = picklistValuesJSONObj;
                    	} 
                    	this.parentContext.__win.close();
                    }

                });
                var toolBarItems = [this.__searchTextField,'->',addButton];
                var toolBarItemsForBottomBar = ['->',this.__applyButton];

 				// window
	            var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
	                layout : {type : "vbox"}, 
	                height : 400, 
	                width : 820,
	                title : $TR.PICKLIST_SELECTION,
	                cls: 'piq-setup-ta-picklist-window',
	                closable: true,
	                maximizable: false,
	                titleAlign:'left',
	                layout: {
	                    padding: 5
	                }, 
	                layout : 'fit',
	                items : [grid],
	                modal : true,
	                dockedItems : [
	                    {
	                        dock: 'top', xtype: 'toolbar', margin: '0',
	                        items : toolBarItems
	                    },
	                    {
	                        dock: 'bottom', xtype: 'toolbar', margin: '0',
	                        items : toolBarItemsForBottomBar
	                    }
	                ],
	               
	                listeners: {
	                    show: function(win) {
	                        if (this.modal) {
	                            var dom = Ext.dom.Query.select('.x-mask');
	                            for(var i=0; i<dom.length;i++){
	                                     Ext.get(dom[i]).setStyle('opacity',1);
	                                     var el = Ext.get(dom[i]);
	                                     el.addCls('customWinMask');

	                            }
	                        }
	                    },
	                    close:  function(win) {
	                        if (this.modal) {
	                            var dom = Ext.dom.Query.select('.x-mask');
	                            for(var i=0; i<dom.length;i++){
	                                     Ext.get(dom[i]).setStyle('opacity',1);
	                                     var el = Ext.get(dom[i]);
	                                     el.removeCls('customWinMask');

	                            }
	                        }
	                    }
	                }
	                
	            });

	            // win.setPosition(window.screen.width/4, window.screen.height/6);
	            this.__grid = grid;
	            this.__store = store;
	            return win;

	 			}, // end of getUI() method.

	 			__getGridColumnFields : function() {
	 				var cols = [
	 					{name: $TR.PICKLIST_NAME,dataIndex: SVMX.OrgNamespace+'__SM_Name__c'},
	 					{name: $TR.PICKLIST_DESCRIPTION,dataIndex: SVMX.OrgNamespace+'__SM_Description__c'}
 					]; 
 					return cols;
	 			},

	 			__getGridDateStoreFileds : function() {
	 				var fields = ["Id",SVMX.OrgNamespace+'__SM_Name__c',SVMX.OrgNamespace+'__SM_Description__c',SVMX.OrgNamespace+'__SM_Values__c'];
	 				return fields;
	 			},
	 			__onTextFieldChange: function(field, newValue, oldValue, options) {
		        	this.__grid.store.clearFilter();
		            if (newValue) {
				        var matcher = new RegExp(Ext.String.escapeRegex(newValue), "i");
				        this.__grid.store.filter({
				            filterFn: function(record) {
				                return matcher.test(record.get(SVMX.OrgNamespace+'__SM_Name__c')) ||
				                    matcher.test(record.get(SVMX.OrgNamespace+'__SM_Description__c'));
				            }
				        });
				   }
		         },
		         __deletePicklist : function(rec) {
		         	var me = this;
		         	SVMX.getCurrentApplication().blockUI();
		         	var sfid = rec.data.Id;
					var evt = SVMX.create("com.servicemax.client.lib.api.Event",
								"INSTALLIGENCEADMIN.DELETE_PICKLIST_DATA",me,
								{request : {context : me, sfid : sfid }});
		       		var eventBus = SVMX.getCurrentApplication().getEventBus();
		       		eventBus.triggerEvent(evt);
		         },
		         onPicklistDeleteComplete : function(data) {
		         	SVMX.getCurrentApplication().unblockUI();
		         	var gridStore = this.__grid.getStore();
                    gridStore.remove(this.__selectedRecord); 
		         },
		         refreshTechnicalAttributePageForPicklist : function(editedPicklistSfId,picklistName) {
		         	var l = this.__config.technicalAttributesContext.createNewTATemplate.__sections.length, filedDetails, currentSection;
		        	var allSections = this.__config.technicalAttributesContext.createNewTATemplate.__sections;
		        	for(var i = 0; i<l; i++){
		        		currentSection = allSections[i];
		        		var items = currentSection.attributesGrid.store.data.items;
			        	var itemLength = items.length, field = {}, allFields = [];
			        	var found = false;
			        	for(var j = 0; j<itemLength; j++){
			        		var data = items[j].data;
			        		var picklistAttrSfid = data.picklistSfId;
			        		if(data.format === 'Picklist' && picklistAttrSfid === editedPicklistSfId && data.defaultValue !== picklistName) {
			        			data.defaultValue = picklistName;
			        			found = true;
			        		}
		        		}
		        		if(found) {
		        			currentSection.attributesGrid.getView().refresh();
		        		}
		        	}
		         }

 		});


		picklist.Class("PicklistDefination",com.servicemax.client.lib.api.Object,{

			__config : null,
			__picklistNameField : null,
			__picklistDescriptionField : null,
			__picklistValuesField : null,
			__win : null,	
			__constructor : function(config) {
 				var me = this;
 				this.__config = config;
 				this.__win = this.__getUIForPicklistDefination();
 				this.__win.show();
 			},

 			__getUIForPicklistDefination : function() {
 				var me = this;
 				
	        	this.__picklistNameField = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : false,
	    		   cls: 'piq-setup-ta-picklist-name-textfield',
	    		   editable : true,
	    		   margin:'10 10 10 10',
	    		   width: '600px',
	    		   height: '26px',
	    		   labelWidth: 150,
	    		   parentContext : me,
	    		   id : "picklist-name-field",
	    		   enableKeyEvents : true,
	    		   fieldLabel: $TR.PICKLIST_NAME +' <span class="req" style="color:red">*</span>',
	    		   listeners : {
		    		   	change : function(field,evt,eOpts) {
		    		   		var currentFieldValue = field.value;
		    		   		var picklistValuesString = Ext.getCmp("picklist-values-field").getValue();
		    		   		var picklistDescriptionString = Ext.getCmp("picklist-description-field").getValue();
	    		   			picklistValuesString = $.trim(picklistValuesString);
	    		   			picklistDescriptionString = $.trim(picklistDescriptionString);
	    		   			currentFieldValue = $.trim(currentFieldValue);
		    		   		if(currentFieldValue.length > 0 && picklistValuesString.length > 0 && picklistDescriptionString.length > 0) {
		    		   			me.__saveButton.setDisabled(false);
		    		   		} else {
		    		   			me.__saveButton.setDisabled(true);
		    		   		}
		    		   	}
	    		   }
	    	   });

			   this.__picklistDescriptionField = {	
			   		xtype : 'textareafield',
			        grow  : false,
			        allowBlank : false,
			        labelWidth: 150,
			        id : 'picklist-description-field',
			        name  : 'description',
			        cls   : 'piq-setup-ta-picklist-description-textarea',
			        fieldLabel: $TR.PICKLIST_DESCRIPTION +' <span class="req" style="color:red">*</span>',
			        margin :'10 10 10 10',
			        width  : '600px',
					height : '60px',
					enableKeyEvents : true,
					parentContext : me,
					listeners : {
						change : function(field,evt,eOpts) {
							var currentFieldValue = field.value;
							var picklistValuesString = Ext.getCmp("picklist-values-field").getValue();
		    		   		var picklistNameString = Ext.getCmp("picklist-name-field").getValue();
	    		   			picklistNameString = $.trim(picklistNameString);
	    		   			picklistValuesString = $.trim(picklistValuesString);
	    		   			currentFieldValue = $.trim(currentFieldValue);
		    		   		if(currentFieldValue.length > 0 && picklistValuesString.length > 0 && picklistNameString.length > 0) {
		    		   			me.__saveButton.setDisabled(false);
		    		   		} else {
		    		   			me.__saveButton.setDisabled(true);
		    		   		}
		    		   	}
					}
			    };

			    this.__picklistValuesLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        cls : 'piq-setup-picklist-display-label',
			        text: $TR.PICKLIST_DISPLAY_MESSAGE,
			        margin :'10 10 0 165',
			        width : '445px'
			    };

			    this.__picklistValuesField = {	
			   		xtype : 'textareafield',
			        grow  : false,
			        allowBlank : false,
			        id : 'picklist-values-field',
			        labelWidth: 150,
			        name  : 'picklistValues',
			        cls   : 'piq-setup-ta-picklist-values-textarea',
			        fieldLabel: $TR.PICKLIST_VALUES +' <span class="req" style="color:red">*</span>',
			        margin :'10 10 10 10',
			        width  : '600px',
					height : '120px',
					enableKeyEvents : true,
					parentContext : me,
					listeners : {
						change : function(field,evt,eOpts) {
							var currentFieldValue = field.value;
							var picklistDescriptionString = Ext.getCmp("picklist-description-field").getValue();
		    		   		var picklistNameString = Ext.getCmp("picklist-name-field").getValue();
		    		   		picklistDescriptionString = $.trim(picklistDescriptionString);
		    		   		picklistNameString = $.trim(picklistNameString);
		    		   		currentFieldValue = $.trim(currentFieldValue);
		    		   		if(currentFieldValue.length > 0 && picklistDescriptionString.length > 0 && picklistNameString.length > 0) {
		    		   			me.__saveButton.setDisabled(false);
		    		   		} else {
		    		   			me.__saveButton.setDisabled(true);
		    		   		}
		    		   	}
					}
			    };

			    this.__picklistCheckboxField = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.PICKLIST_CHECKBOX_FIELD_NAME,
			         cls : 'piq-setup-ta-picklist-checkbox',
			         margin :'0 10 10 165',
			         scope: me,
			         disabled: false,
			         handler: function(field, value) {
			         }
			     });

			    var picklistDefinationPanel = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXPanel",{
			    	items : [this.__picklistNameField,this.__picklistDescriptionField,this.__picklistValuesLabel,this.__picklistValuesField,this.__picklistCheckboxField],
			    	layout : {type : "vbox"},

 				});

 				this.__saveButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text: $TR.SAVE,//"Save",
					disabled:true,
					handler : function(){
						me.onSave();
					}
				});
				
				var closeButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text: $TR.CANCEL,//"Cancel",
					handler : function(){
						me.__win.close();
					}
				});

				var toolBarItemsForBottomBar = ['->',this.__saveButton,closeButton];

			    // window
	            var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
	                layout : {type : "vbox"}, 
	                height : 440, 
	                width : 830,
	                title : $TR.PICKLIST_DEFINATION,
	                cls: 'piq-setup-ta-picklist-window',
	                closable: true,
	                maximizable: false,
	                titleAlign:'left',
	                layout: {
	                    padding: 5
	                }, 
	                layout : 'fit',
	                items : [picklistDefinationPanel],
	                modal : true,
	                dockedItems : [
	                    {
	                        dock: 'bottom', xtype: 'toolbar', margin: '0',
	                        items : toolBarItemsForBottomBar
	                    }
	                ],
	               
	                listeners: {
	                }
	                
	            });

	            this.__updatePicklistDefinationModelForEdit();

	            return win;

 			},
 			__updatePicklistDefinationModelForEdit : function() {
 				if(this.__config.picklistType === "edit") {
 					this.__saveButton.setDisabled(false);
					var data = this.__config.selectedRecord.data;
					var picklistNameString = data[SVMX.OrgNamespace+'__SM_Name__c'];
					var picklistDescriptionString = data[SVMX.OrgNamespace+'__SM_Description__c'];
					var picklistValuesString = data[SVMX.OrgNamespace+'__SM_Values__c'];
					var picklistValuesObject = JSON.parse(picklistValuesString);
					if(picklistNameString) {
						this.__picklistNameField.setValue(picklistNameString);
					}
					if(picklistDescriptionString) {
						Ext.getCmp("picklist-description-field").setValue(picklistDescriptionString);
					}
					if(picklistValuesObject) {
						var picklistValues = picklistValuesObject.values;
						var appendNewLineToPicklistValuesArray = picklistValues.join('\r\n');
						var checkboxValue = picklistValuesObject.setDefaultValue;
						Ext.getCmp("picklist-values-field").setValue(appendNewLineToPicklistValuesArray);
						this.__picklistCheckboxField.setValue(checkboxValue);
					}
				}
 			},
 			onSave : function() {
 				var me = this;
 				var sfid = null;
 				if(this.__config.picklistType === "edit" && this.__config.selectedRecord.data.Id) {
 					sfid = this.__config.selectedRecord.data.Id;
 				} 
 				var picklistValuesString = Ext.getCmp("picklist-values-field").getValue();
 				var removeDuplicateNewLinesFromValues = picklistValuesString.replace(/\n\s*\n/g, '\n');
 				var picklistValueArray = removeDuplicateNewLinesFromValues.split("\n");
 				var modifiedPicklistValuesArray = [];
 				for(var i = 0; i < picklistValueArray.length ; i++) {
 					var picklistValueString = picklistValueArray[i];
 					var removeWhiteSpaces = picklistValueString.replace(/^\s+$/,'');
 					if(removeWhiteSpaces.length > 0) {
 						modifiedPicklistValuesArray.push(picklistValueString);
 					}
 				}
 				var picklistDescriptionString = Ext.getCmp("picklist-description-field").getValue();
 				var picklistNameString = this.__picklistNameField.value;
 				picklistNameString = $.trim(picklistNameString);
 				picklistDescriptionString = $.trim(picklistDescriptionString);
 				var sitelist = { values : modifiedPicklistValuesArray, setDefaultValue : this.__picklistCheckboxField.value};
 				var sitelistString = JSON.stringify(sitelist);
 				var fieldsLengthInfo = this.__validateTextAndTextAreaLength(picklistNameString,picklistDescriptionString,sitelistString);
 				if(!fieldsLengthInfo.isValid) {
 					SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, fieldsLengthInfo.errorMessage);
 				} else {
 					SVMX.getCurrentApplication().blockUI();
 					var evt = SVMX.create("com.servicemax.client.lib.api.Event",
								"INSTALLIGENCEADMIN.SAVE_PICKLIST_DATA", me,
								{request : { context : me, sfid : sfid, name : picklistNameString, description : picklistDescriptionString, values : sitelist }});//, ibTemplates: productTemplateFinal, delTemplateIds: this.productTemplates.deletedTemplateIds
		       		SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
 				}

		    },

		    onSaveSetupPicklistDataComplete : function(data) {
		    	SVMX.getCurrentApplication().unblockUI();
		    	if(!data.isValidPicklistDefinition) {
		    		SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.PICKLIST_EXITS_ERROR_MESSAGE);
		    	} else {
			    	var gridStore = this.__config.grid.getStore();
				    var picklistValuesString = JSON.stringify(data["picklistValues"]);
				    var responseData = {};
				    responseData.Id = data["sfdcId"];
				    responseData[SVMX.OrgNamespace+'__SM_Name__c'] = data["name"];
				    responseData[SVMX.OrgNamespace+'__SM_Description__c'] = data["description"];
				    responseData[SVMX.OrgNamespace+'__SM_Values__c'] = picklistValuesString ;
			    	if(this.__config.picklistType === "edit") {
			    		var rec = gridStore.getAt(this.__config.rowIndex);
			    		rec.data = responseData;
			    		var gridData = gridStore.data.items;
			    		gridStore.loadData(gridData);
			    	} else {
			    		gridStore.add(responseData);
			    		var rowIndex = gridStore.data.items.length - 1;
			    		var view = this.__config.grid.getView();
	              	    Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
			    	}
			    	this.__win.close();
		    	}

		    },
		    __validateTextAndTextAreaLength : function(picklistNameString,picklistDescriptionString,sitelist) {
		    	var returnValues = { isValid: true, errorMessage: '' };
		    	var fields = this.__config.metadata[SVMX.OrgNamespace+'__SM_TA_Picklist_Definition__c'].fields, fieldsLength = fields.length;
 				for (var j = 0; j < fieldsLength; j++) {
 					var currentField = fields[j];
 					switch(currentField.fieldAPIName) {
 						case SVMX.OrgNamespace+'__SM_Name__c' : {
 							if(picklistNameString.length > currentField.fieldLength ) {
 								returnValues.errorMessage = $TR.PICKLIST_NAME + ' : ' + $TR.TOO_LONG;
 								returnValues.isValid = false;
 							}
 						break;
 						}
 						case SVMX.OrgNamespace+'__SM_Description__c' : {
 							if(picklistDescriptionString.length > currentField.fieldLength ) {
 								returnValues.errorMessage = $TR.PICKLIST_DESCRIPTION + ' : ' + $TR.TOO_LONG;
 								returnValues.isValid = false;
 							}
 						break;	
 						}
 						case SVMX.OrgNamespace+'__SM_Values__c' : {
 							if(sitelist.length > currentField.fieldLength ) {
 								returnValues.errorMessage = $TR.PICKLIST_VALUES + ' : ' + $TR.TOO_LONG;
 								returnValues.isValid = false;
 							}
 						break;	
 						}
 					}
 				}
 				return  returnValues;
		    }

		});
 		

 	}

 })();