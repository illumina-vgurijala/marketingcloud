// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\app.js

(function(){
	var appImpl = SVMX.Package("com.servicemax.client.installigence.admin.app");
	
	appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
		__eventBus : null,
		
		__constructor : function(){

		},
		
		beforeRun: function (options) {
			var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
			 
        	this.__eventBus = SVMX.create("com.servicemax.client.installigence.admin.impl.InstalligenceAdminEventBus", {});
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
			var me = this;
			me.getSetupMetadata();
		},
        
        getSetupMetadata: function() {
	       	var me = this;
	       	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
							"INSTALLIGENCEADMIN.GET_SETUP_METADATA", me,
							{request : { context : me}});
	       	
	       	SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        showQuickMessage : function(type, message, callback){
            type = type.toLowerCase();
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
                // Ext.Msg.alert(typeMessage, message);
                Ext.Msg.alert({
                    cls : 'piq-setup-info-alert',
                    title : typeMessage, 
                    message : message,
                    buttonText : { ok : $TR.OK_BTN },
                    closable : false
                });
            }
        },
        
        onGetSetupMetadataComplete: function(metadata) {
        	
        	var sforceObjectDescribes = metadata.sforceObjectDescribes;
        	
        	for(var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
        		metadata[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
        	}
        	metadata.context = this;
        	this.__processTranslations(metadata.translations);
        	var instAdmin = SVMX.create('com.servicemax.client.installigence.admin.root.RootPanel',{
				collapsible : false,
				titleAlign: 'center', 
    			frame: 'true',
    			style: 'margin:10px',
    			layout: {
    				padding: '0'
    			},
        		metadata: metadata
            });
	       	/*var me = this;
	       	var svmxProfiles = metadata.svmxProfiles;
	       	var ibValueMappings = metadata.ibValueMaps;
	       	if(svmxProfiles !== undefined)
	       		me.profiles.loadData(svmxProfiles);
	       	if(ibValueMappings !== undefined)
	       		me.actionSearchGrid.ibFieldMappingsComboBox.getStore().loadData(ibValueMappings);*/
        	
        },
        
        __processTranslations: function(translationsArr) {
        	
        	var i, ilength = translationsArr.length;
        	var translations = {};
        	for(i = 0; i < ilength; i++) {
                translations[translationsArr[i].Key] = Ext.String.htmlEncode(translationsArr[i].Text) ;
        	}
        	window.$TR = translations;        	
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\attachment.js
/**
 *  Attachment.
 * @class com.servicemax.client.insralligence.admin.attachment.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/

  (function(){

	var attachment = SVMX.Package("com.servicemax.client.installigence.admin.attachment");
	attachment.init = function() {


		Ext.define("com.servicemax.client.installigence.admin.Attachment", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

	         __root: null,
	         constructor: function(config) {
	         	var me = this;
	         	config = config || {};
				config.title = $TR.ATTACHMENTS;
				config.id = "attachment";
				this.__root = config.root;
				this.__registerForDidProfileSelectCall();

				me.showProfiles = config.root.showProfiles;

				 me.enableAttachmentCheckbox = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                    boxLabel : $TR.ENABLE_ATTACHMENTS_DOWNLOAD_DURING_SYNC,
                    scope: this,
                    disabled: true,
                    handler : function(field, value){
                        if (value) {
                        	me.__enableOrDisableAttachmentTabFields(false);
                        } else {
							me.__enableOrDisableAttachmentTabFields(true);
                        }
                    }
                });

				me.horizontalLine = {
				    xtype: 'box',
				    autoEl : {
				        tag : 'hr'
				    }
				}; 

				me.attachmentSettingTitle = {
			    	xtype : 'label',
			    	forId : 'myFieldId',
			    	text : $TR.ATTACHMENT_SETTING_TITLE, 
			    	style: 'font-weight: 600;',
			    	margin : '40 0 10 10'
			    }; 


				 me.fileTypeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   width : 600,
	    		   disabled: true,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.DOWNLOAD_ONLY_THESE_FILES_TYPE,
	    	   });

				 me.maxFileSizeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.ENTER_MAXIMUM_FILES_SIZE_TO_DOWNLOAD,
	    		   maskRe: /[0-9]/
	    	   });

				me.sfilesSettingTitle = {
			    	xtype : 'label',
			    	forId : 'myFieldId',
			    	text : $TR.SFILE_SETTING_TITLE, 
			    	style: 'font-weight: 600;',
			    	margin : '40 0 10 10'
			    }; 

			    me.sfileTypeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   width : 600,
	    		   disabled: true,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.DOWNLOAD_ONLY_THESE_FILES_TYPE,
	    	    });

				me.sfileMaxFileSizeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.ENTER_MAXIMUM_FILES_SIZE_TO_DOWNLOAD,
	    		   maskRe: /[0-9]/
	    	    });	 

			    me.sfileTagsTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.SFILE_TAGS_TYPES
	    	    });	



				config.items = [me.enableAttachmentCheckbox,me.horizontalLine,me.attachmentSettingTitle,me.fileTypeTextFields,me.maxFileSizeTextFields, me.sfilesSettingTitle, me.sfileTypeTextFields,me.sfileMaxFileSizeTextFields,me.sfileTagsTextFields];
				this.callParent([config]);

	         },

	         __enableOrDisableAttachmentTabFields:function(isDisable) {
         		this.fileTypeTextFields.setDisabled(isDisable);
				this.maxFileSizeTextFields.setDisabled(isDisable);
				this.sfileTypeTextFields.setDisabled(isDisable);
				this.sfileMaxFileSizeTextFields.setDisabled(isDisable);
				this.sfileTagsTextFields.setDisabled(isDisable);
	         },

			__updateAttachmentDetails:function(combo, record){

				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.enableAttachmentCheckbox.setDisabled(true);
					this.__enableOrDisableAttachmentTabFields(true);
				}else{

					this.enableAttachmentCheckbox.setDisabled(false);

					if (this.enableAttachmentCheckbox.getValue()) {
						this.__enableOrDisableAttachmentTabFields(false);
					} else {
						this.__enableOrDisableAttachmentTabFields(true);
					}
					
				}

				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().attachment == undefined){
					this.enableAttachmentCheckbox.setValue(false);
					this.fileTypeTextFields.setValue('');
					this.maxFileSizeTextFields.setValue('');
					this.sfileTypeTextFields.setValue('');
					this.sfileMaxFileSizeTextFields.setValue('');
					this.sfileTagsTextFields.setValue('');

				}else if(selecetedProfile.getData().attachment.length > 0){
					
					var pAttachment = selecetedProfile.getData().attachment[0];
					(pAttachment.isAttachmentsEnabled == 'true'? this.enableAttachmentCheckbox.setValue(true): this.enableAttachmentCheckbox.setValue(false)) ;
					this.fileTypeTextFields.setValue(pAttachment.fileTypes);
					this.maxFileSizeTextFields.setValue(pAttachment.maximumFileSize);
					this.sfileTypeTextFields.setValue(pAttachment.sfdcFileTypes);
					this.sfileMaxFileSizeTextFields.setValue(pAttachment.maxSfdcFileSize);
					this.sfileTagsTextFields.setValue(pAttachment.sfdcFileTags);


				}else{
					//TODO: 
				}
				
			},
			__registerForDidProfileSelectCall: function(){
				var me = this;
	           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){

	              	 var data = SVMX.toObject(evt.data);
	            	 var combo = evt.target.result.combo;
	            	 var record = evt.target.result.record;
	            	 this.showProfiles.setRawValue(record.get('profileName'));
	          	 	this.__updateAttachmentDetails(combo, record);	
					

	           }, this); 
			},

			__persistAttachment:function(selecetedProfile){
				
				var pAttachment;
				if(selecetedProfile.getData().attachment == undefined){
					selecetedProfile.set("attachment", []);
					pAttachment = {};
				}else if(selecetedProfile.getData().attachment.length > 0){
					
					pAttachment = selecetedProfile.getData().attachment[0];
					
				}else{
					pAttachment = {};
				}
				

				pAttachment.isAttachmentsEnabled = this.enableAttachmentCheckbox.getValue().toString();
				pAttachment.fileTypes = this.fileTypeTextFields.getValue();
				pAttachment.maximumFileSize = this.maxFileSizeTextFields.getValue();

				pAttachment.sfdcFileTypes = this.sfileTypeTextFields.getValue();
				pAttachment.maxSfdcFileSize = this.sfileMaxFileSizeTextFields.getValue();
				pAttachment.sfdcFileTags = this.sfileTagsTextFields.getValue();

				selecetedProfile.set('attachment',[pAttachment]);
			}
			
	     });

	}
})();


// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\celleditors.js
(function(){
	var cellEditors = SVMX.Package("com.servicemax.client.installigence.admin.celleditors");

cellEditors.init = function() {
	
	Ext.define("com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor", {
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\commands.js
/**
 * This file needs a description 
 * @class com.servicemax.client.sfmopdocdelivery.commands
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	var installigenceadmincommands = SVMX.Package("com.servicemax.client.installigence.admin.commands");
	
installigenceadmincommands.init = function(){
	
	installigenceadmincommands.Class("GetSetupMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_SETUP_METADATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onGetSetupMetadataComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("SaveSetupData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.SAVE_SETUP_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveSetupDataComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("BackToSetupHome", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.BACK_TO_SETUP_HOME"});
		},
	
		result : function(data) {
		}
		
	},{});
	
	installigenceadmincommands.Class("GetTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.FIND_TOPLEVEL_IBS"});
		},
	
		result : function(data) { 
			this.__cbContext.__findComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("GetTemplateFromIB", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TEMPLATE_FROM_IB"});
		},
	
		result : function(data) { 
			this.__cbContext.GetTemplateFromIBComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetAllProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_PRODUCTS"});
		},
	
		result : function(data) { 
			this.__cbContext.__findComplete(data);
		}
		
	},{});
	installigenceadmincommands.Class("GetAllTechnicalAttributesTemplates", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_ATTRIBUTESTEMPLATES"});
		},
	
		result : function(data) { 
			this.__cbContext.__reloadTemplateGrid(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetTemplateCount", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TEMPLATE_COUNT"});
		},
	
		result : function(data) { 
			this.__cbContext.__getTemplateCountForSearchValueCompleted(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetTechnicalAttributesTemplateCriteria", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TA_TEMPLATE_CRITERIA"});
		},
	
		result : function(data) { 
			this.__cbContext.__getTemplateCriteriaInfoCompleted(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetAllTAPicklistDefination", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_TA_PICKLIST_DEFINATION"});
		},
	
		result : function(data) { 
			this.__cbContext.__onFetchingPicklistComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("SavePicklistData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.SAVE_PICKLIST_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveSetupPicklistDataComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("DeletePicklistData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.DELETE_PICKLIST_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onPicklistDeleteComplete(data);
		}
		
	},{});
	
};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\datavalidationrules.js
(function(){
	var setupDataValidationRules = SVMX.Package("com.servicemax.client.installigence.admin.datavalidationrules");

	setupDataValidationRules.init = function() {

		Ext.define("com.servicemax.client.installigence.admin.dataValidationRulesGrid", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
			constructor: function(config) {
				var me = this;
				var config = config || {};

				config.columns = [{
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
		                },  		                
  		                renderer: function (value, metadata, record) {
  		                	config.columns[0].items[0].iconCls = 'delet-icon';
  		                }
                }];

                var me = this;
                config.columns.push(this.createComboBoxColumn({text: $TR.RULE_NAME, dataIndex: 'ruleName', width:350, flex: 1, rulesStore: config.rulesStore, listeners: config.ruleChangeListeners}));//'Rule Name'
                config.columns.push(this.createLabelColumn({text: $TR.DESCRIPTION, dataIndex: 'description', width:350, flex: 1, rulesStore: config.rulesStore}));//'Description'
                config.columns.push(this.createLabelColumn({text: $TR.MESSAGE_TYPE, dataIndex: 'messageType', width:350, flex: 1, rulesStore: config.rulesStore, listeners : config.nameFieldListner}));//'Message Type'

                this.callParent([config]);
			},

	       	createComboBoxColumn: function(fieldInfo) {
	    	   	var me = this;
	    	   
	    	   me.optionPicklist = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					displayField: 'ruleName',
			        queryMode: 'local',
			        editable: false,
			        valueField: 'ruleId',
			        fieldName: 'name',
			        store: fieldInfo.rulesStore,
			        listeners: fieldInfo.listeners
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   me.optionPicklist.setRecord(currentRecord);
                   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
							field: me.optionPicklist
                            });
               };
               fieldInfo.listeners = {
               		blur : function(field, e){
               			var text = field.value;
               		}

               };
	    	   return fieldInfo;   
	       	},

	       	createLabelColumn: function(fieldInfo){
	       		var labelRuleInfo = SVMX.create('com.servicemax.client.installigence.ui.components.Label', {
	       			listeners : fieldInfo.listeners
	       		});

	       		var fieldInfo = fieldInfo || {};
	    	   	fieldInfo.menuDisabled = true;
	    	   	fieldInfo.sortable = false;

	    	   	return fieldInfo;
	       	},

	       	addRecords: function(records){
	       		if (!records) return;
	       		this.store.insert(this.getStore().count(), records);
	       	},

	       	getProfileRecords: function() {
	    	   	var records = [];
	    	   	this.store.each(function(rec) {          
	    			delete rec.data["id"];           		
	           		records.push(rec.data);
	    	   	});
	    	   	return records;
	       	},

	       	__onSelectRule: function(combo, record){

	       	}
		});

		Ext.define("com.servicemax.client.installigence.admin.DataValidationRules", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
			__root: null,
			constructor: function(config) {
				var me = this;
				this.__registerForDidProfileSelectCall();
				this.__root = config.root;
				var profiles = config.metadata.svmxProfiles;
				me.objectToRules = config.metadata.dataValidationRules;

				Ext.define('dataValidationRulesModel', {
				    extend: 'Ext.data.Model',
				    fields: [ 
				    			{name: 'ruleId',  type: 'string'},
				    			{name: 'ruleName',  type: 'string'},
				              	{name: 'description',   type: 'string'},
				              	{name: 'messageType', type: 'string'}
				            ]
				});

				me.dataValidarionRulesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				    model: 'dataValidationRulesModel',
				    data: []
				});

				var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				var objectsData = [{objectName: "--None--", objectLabel: $TR.NONE}];
				var validationRuleData = [{objectName: "--None--", objectLabel: $TR.NONE}];

				var iProfile = 0, iProfileLength = profiles.length;
				for(iProfile = 0; iProfile < iProfileLength; iProfile++) {
					if(profiles[iProfile].profileId !== 'global'){
						profilesData.push(profiles[iProfile]);
					}
				}
				
				if(me.objectToRules){
					var iObj = 0;
					for(iObj = 0; iObj < me.objectToRules.length; iObj++) {
						objectsData.push(me.objectToRules[iObj]);
					}	
				}

				me.profiles = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['profileId', 'profileName'],
			        data: profilesData
			    });

			    me.objects = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['objectName', 'objectLabel'],
			        data: objectsData
			    });

				me.rulesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				    model: 'dataValidationRulesModel',
				    data: validationRuleData
				});

			    me.rulesGrid = SVMX.create('com.servicemax.client.installigence.admin.dataValidationRulesGrid',{
					cls: 'grid-panel-borderless panel-radiusless',
					store: me.dataValidarionRulesStore,
					height: 320,
				    selType: 'cellmodel',
				    rulesStore: me.rulesStore,		        
				    plugins: [
				        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
				            clicksToEdit: 2
				        })
				    ],
			        ruleChangeListeners: {
			        	select: function(combo, record){
			        		var typ = record;	
			        		var rec = me.rulesGrid.getSelectionModel().getSelection()[0];
			        		rec.set("ruleId", record.getData().ruleId);
			        		rec.set("ruleName", record.getData().ruleName);
			        		rec.set("rule_key", record.getData().rule_key);
			        		rec.set("description", record.getData().description);
			        		rec.set("messageType", record.getData().messageType);
			        	}
			        }
	            });

			    me.rulePanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
					style: 'margin: 1px 0',
					layout: 'fit',
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				me.rulePanel.add(me.rulesGrid);

			    me.addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'plus-icon',
					tooltip: $TR.ADD,
					disabled: true,
					handler : function(){
						me.onAddRecords();
					}
				});

				/*me.showProfiles = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_PROFILE,
			        store: me.profiles,
			        labelWidth: 140,
			        width: 450,
			        displayField: 'profileName',
			        queryMode: 'local',
			        editable: false,
			        selectedProfile: undefined,
			        listeners: {
			        	select: {
			        		fn: me.__didSelectProfileWithInfo,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('profileName'));
						}
						afterrender :{
							fn : me.__showProfilesAfterrender,
							scope : me
						}
			        }
				});*/
				me.showProfiles = config.root.showProfiles;

				//'Select a Object'
				me.showObjects = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_OBJECT,
			        store: me.objects,
			        width: 450,
			        labelWidth: 140,
			        displayField: 'objectLabel',
			        queryMode: 'local',
			        editable: false,
			        disabled: true,
			        margin:'10 0',
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

				me.profilePanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					width: '450',
					style: 'margin: 3px 0',
					layout: 'vbox',
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				//me.profilePanel.add(me.showProfiles);
				me.profilePanel.add(me.showObjects);

				me.profileFormPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					//width: 450,
					style: 'margin: 3px 0',
					layout: 'fit',
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				me.profileFormPanel.add(me.profilePanel);

				me.selectObjectToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0',
					width: '100%'
				});	

				
				me.selectObjectToolbar.add('->');
				me.selectObjectToolbar.add(me.addRecButton);

				me.profileFormPanel.add(me.selectObjectToolbar);
				me.profileFormPanel.add(me.rulePanel);

				config = config || {};
				config.items = [];
				config.items.push(me.profileFormPanel);
				config.title = $TR.DATA_VALIDATION_RULE;//'Data Validation Rules'; //
				config.id = "DVR";
				this.callParent([config]);
			},

			onAddRecords: function(){
				var objName = this.showObjects.getCurrentConfig().selection.getData().objectName;
				this.rulesGrid.addRecords({ruleId: '', ruleName: '', description: '', messageType:'', objectName: objName});
			},
			__showProfilesAfterrender : function(combo){
				
				var recordSelected; 
						if(this.__root.selectedProfile)
						{
							recordSelected =  this.__root.selectedProfile; 
						}else
						{
							recordSelected = combo.getStore().getAt(0);
						}
						combo.setValue(recordSelected.get('profileName'));
						
			},
			__didSelectProfileWithInfo:function(combo, record){
				this.__root.selectedProfile = record;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "SELECTED_PROFILE_CALL",{result: {combo:combo,record:record}},
                                                             this);
                    SVMX.getClient().triggerEvent(evt);
                    

			},
			__onSelectProfile: function(combo, record){

				this.showObjects.setValue('--None--');
				this.rulesGrid.getStore().removeAll();
				this.showObjects.selectedObject = undefined;
				
				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.showObjects.setDisabled(true);
					this.addRecButton.setDisabled(true);
				}else{
					this.showObjects.setDisabled(false);
				}

				if(combo.getSelectedRecord() && combo.getSelectedRecord().get("profileId") !== "--None--"){
					var selProfileObj = this.showProfiles.selectedProfile;
					if(selProfileObj)
						this.__persistDataValidationRules(selProfileObj);
				}

				if(combo.getSelectedRecord().get("profileId") !== "--None--"){
					this.showProfiles.selectedProfile = record;
				}else{
					this.showProfiles.selectedProfile = undefined;
					this.rulesGrid.getStore().removeAll();
				}
			},

			__onSelectObjects: function(combo, record){
				if(combo.getSelectedRecord().get("objectName") === "--None--"){
					this.rulesGrid.getStore().removeAll();
					this.addRecButton.setDisabled(true);
					this.showObjects.selectedObject = undefined;
				}else{
					this.addRecButton.setDisabled(false);
				}
				
				if(combo.getSelectedRecord().get("objectName") !== "--None--"){
					
					var validationRuleData = [], savedValidationRuleData = [];
					var iObj = 0;
					var savedRulesFromProfile = this.showProfiles.selectedProfile.getData().rulesWithObjectInfo;

					for(iObj = 0; iObj < this.objectToRules.length; iObj++) {
						if(this.objectToRules[iObj].objectName === combo.getSelectedRecord().get("objectName")){
							var iRule  = 0; iRuleLen = this.objectToRules[iObj].rules.length;
							for(iRule = 0; iRule < iRuleLen; iRule++){
								var dataValidationRuleData = {};
								dataValidationRuleData.objectLabel = this.objectToRules[iObj].objectLabel;
								dataValidationRuleData.objectName = this.objectToRules[iObj].objectName;
								dataValidationRuleData.ruleId = this.objectToRules[iObj].rules[iRule].ruleId;
								dataValidationRuleData.ruleName = this.objectToRules[iObj].rules[iRule].ruleName;
								dataValidationRuleData.messageType = this.objectToRules[iObj].rules[iRule].messageType;
								dataValidationRuleData.description = this.objectToRules[iObj].rules[iRule].description;
								validationRuleData.push(dataValidationRuleData);
							}
							break;
						}
					}

					if(savedRulesFromProfile){
						for(iObj = 0; iObj < savedRulesFromProfile.length; iObj++) {
							if(savedRulesFromProfile[iObj].objectName === combo.getSelectedRecord().get("objectName")){
								var iRule  = 0; iRuleLen = savedRulesFromProfile[iObj].rules.length;
								for(iRule = 0; iRule < iRuleLen; iRule++){
									var dataValidationRuleData = {};
									dataValidationRuleData.objectName = savedRulesFromProfile[iObj].rules[iRule].objectName;
									dataValidationRuleData.ruleId = savedRulesFromProfile[iObj].rules[iRule].ruleId;
									dataValidationRuleData.ruleName = savedRulesFromProfile[iObj].rules[iRule].ruleName;
									dataValidationRuleData.messageType = savedRulesFromProfile[iObj].rules[iRule].messageType;
									dataValidationRuleData.description = savedRulesFromProfile[iObj].rules[iRule].description;
									savedValidationRuleData.push(dataValidationRuleData);
								}
								break;
							}
						}
					}
					
					if(combo.getSelectedRecord() && combo.getSelectedRecord().get("objectName") !== "--None--"){
						var selProfileObj = this.showProfiles.selectedProfile;
						if(selProfileObj)
							this.__persistDataValidationRules(selProfileObj);
					}

					this.showObjects.selectedObject = this.showObjects.getCurrentConfig().selection.getData().objectName;
					
					this.__loadDataValidationRules(validationRuleData);
					this.__loadSavedDataValidationRules(savedValidationRuleData);
				}
			},

			__persistDataValidationRules: function(record){
				if(!record){
					return;
				}

				var dataValidationRulesInfo = this.rulesGrid.getProfileRecords();
				this.__savePicklistValues(dataValidationRulesInfo);
				
				var dVR = record.get("rulesWithObjectInfo");
				var objectName = "";

				if(this.showObjects.selectedObject){
					objectName = this.showObjects.selectedObject;	
				}/*else{
					objectName = this.showObjects.getCurrentConfig().selection.getData().objectName;
				}*/

				if(dVR){
					var i=0;
					for(i=0;i<dVR.length;i++){
						if(dataValidationRulesInfo && dataValidationRulesInfo.length){
							if(dVR[i].objectName === dataValidationRulesInfo[0].objectName){
								dVR.splice(i,1);
								break;
							}
						}else if(objectName && objectName.length){
							if(dVR[i].objectName === objectName){
								dVR.splice(i,1);
								break;
							}	
						}
					}
					
				}
				else{
					dVR = [];
				}
				var dVRObject = {};
				if(dataValidationRulesInfo && dataValidationRulesInfo.length){
					dVRObject.objectName = dataValidationRulesInfo[0].objectName;
					dVRObject.rules = dataValidationRulesInfo;
					dVR.push(dVRObject);	
				}else if(objectName && objectName.length){
					dVRObject.objectName = objectName;
					dVRObject.rules = [];
					dVR.push(dVRObject);
				}
				record.set("rulesWithObjectInfo", dVR);
			},

			__loadDataValidationRules: function(record){
				if(!record) {
					record = [];
				}
				this.__loadPicklistValues(record);
				this.rulesGrid.rulesStore.loadData(record);
			},

			__loadSavedDataValidationRules: function(record){
				if(!record) {
					record = [];
				}
				this.rulesGrid.getStore().loadData(record);
			},

			__loadPicklistValues: function(records){
				var iRules = 0, iRulesLen = records.length;
				for(iRules = 0; iRules < iRulesLen; iRules++) {
					var currRec = records[iRules];
					currRec.rule_key = currRec.ruleId;
					currRec.ruleId = this.rulesGrid.rulesStore.findRecord("value", currRec.ruleId) !== null ? 
							   this.rulesGrid.rulesStore.findRecord("value", currRec.ruleId).get("label") : currRec.ruleId;
					currRec.rule_key = currRec.ruleId;
					
					currRec.ruleId = this.rulesGrid.rulesStore.findRecord("ruleId", currRec.ruleId) !== null ? 
							   this.rulesGrid.rulesStore.findRecord("ruleId", currRec.ruleId).get("ruleName") : currRec.ruleId;
				}
			},

			__savePicklistValues: function(records) {
				var iRules = 0, iRulesLen = records.length;
				for(iRules = 0; iRules < iRulesLen; iRules++) {
					var currRec = records[iRules];
					if(currRec.rule_key) {
						currRec.ruleId = currRec.rule_key;
						delete currRec["rule_key"];
					}
				}	
			},
			__registerForDidProfileSelectCall: function(){

           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){
               var data = SVMX.toObject(evt.data);
             var combo = evt.target.result.combo;
             var record = evt.target.result.record;
          	 
             this.__onSelectProfile(combo,record);
             this.showProfiles.setRawValue(record.get('profileName'));
           		}, this); 
			}
		});
	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\filters.js
(function(){
	var setupFilters = SVMX.Package("com.servicemax.client.installigence.admin.filters");

setupFilters.init = function() {
		
		Ext.define("com.servicemax.client.installigence.admin.ExpressionBuilder", {
	        extend: "com.servicemax.client.installigence.ui.components.Tree",
	        
	       constructor: function(config) {
	    	   
	    	   var me = this;
	    	   config.viewConfig = {
                   listeners: {
                       itemcontextmenu: {
                           fn: me.onViewItemContextMenu,
                           scope: me
                       },
                       
                       itemclick: { 
                            fn: me.onNodeClick,
                            scope: me
                       },
                       cellclick : function(view, cell, cellIndex, record,row, rowIndex, e) {
                    	   var selModel = this.getSelectionModel();
                       }
                   },
                   markDirty:false
               };
	    	   	    	   
	    	   me.addCondition = SVMX.create('Ext.Action', {
	    		   text: $TR.ADD_CONDITION,
				   iconCls: 'svmx-add-condition',	    		   
	    		   handler: function(widget, event) {
	    			   var rec = me.getSelectionModel().getSelection()[0];
	    			   rec.appendChild({exprType: "expression", expandable:false, iconCls: 'svmx-no-icon', expanded: true})
	    		   }
	    	   });
	    	   
	    	   me.addGroup = SVMX.create('Ext.Action', {
	    		   text: $TR.ADD_GROUP,
				   iconCls: 'svmx-add-group',
	    		   menu: {
	                    xtype: 'menu',
	                    items: [
                            me.createGroup('And', $TR.AND, 'svmx-and-operator'),
                            me.createGroup('Or', $TR.OR,'svmx-or-operator'),
                            me.createGroup('Not And', $TR.NOT_AND, 'svmx-not-and-operator'),
                            me.createGroup('Not Or', $TR.NOT_OR,'svmx-not-or-operator')
                        ]
	                }
	    	   });
	    	   
	    	   me.changeGroup = SVMX.create('Ext.Action', {
	    		   text: $TR.CHANGE_GROUP,
				   iconCls: 'svmx-change-group',
	    		   menu: {
	                    xtype: 'menu',
	                    items: [
							me.modifyGroup('And', $TR.AND, 'svmx-and-operator'),
                            me.modifyGroup('Or', $TR.OR, 'svmx-or-operator'),
                            me.modifyGroup('Not And', $TR.NOT_AND, 'svmx-not-and-operator'),
                            me.modifyGroup('Not Or', $TR.NOT_OR, 'svmx-not-or-operator')
                
                        ]
	                }
	    	   });
	    	   
	    	   me.deleteGroup = SVMX.create('Ext.Action', {
	    		   text: $TR.DELETE_GROUP,
				   iconCls: 'svmx-delete-group',	    		   
	    		   handler: function(widget, event) {
	    			   var rec = me.getSelectionModel().getSelection()[0];
	    			   while(rec.firstChild) {
	    				   rec.removeChild(rec.firstChild);
	    			   }
	    			   rec.remove(true);
	    			   
	    			   me.getStore().sync();
	    		   }
	    	   });
	    	   
	    	   config.columns = [{
	               xtype: 'treecolumn', //this is so we know which column will show the tree
	               text: 'Task',
	               sortable: true,
	               width: 300,
	               dataIndex: 'operator',
	               renderer: function(value, meta, currentRecord) {
		    		   var currTypeValue = currentRecord.get('exprType');
		    		   if(currTypeValue === "expression" ) {
		    			   var parentNodeDepth = currentRecord.parentNode.data.depth;
			    		   var tdWidth = 35 * parentNodeDepth;
		    			   meta.tdStyle = "width:" + tdWidth + "px;";
		    		   }
		    		   return value;
	               }
	           }];
	    	   var fieldsColumn = this.createComboBoxColumn({text: 'Fields', dataIndex: 'field', width:250
						, store: config.ibFieldStore, displayField: 'fieldLabel', valueField: 'fieldAPIName', defaultValue: 'Account'});
	    	   config.columns.push(fieldsColumn);   	   
	    	   config.columns.push(this.createComboBoxColumn({text: 'Condition', dataIndex: 'condition', width:200
	    		   						, store: config.operatorsStore, displayField: 'opLabel', valueField: 'opValue', defaultValue: 'Equals'}));   	   
	    	   config.columns.push(this.createTextBoxColumn({text: 'Value', dataIndex: 'value', width:150}));
	    	   config.columns.push(
	    	                     {
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
	    	  		                    rec.remove(true);
	    	  		                    gridStore.sync();
	    	  		                    
	    	  		                },
	    	  		                
	    	  		                renderer: function (value, metadata, record) {
	    	  		                	if (record.get('exprType') === "expression") {
		    	  		                    config.columns[4].items[0].iconCls = 'delet-icon';
		    	  		                } else {
		    	  		                    config.columns[4].items[0].iconCls = '';
		    	  		                }
	    	  		                }		
	    	  					}                  
	    	                 );
	    	   config = config || {};
	    	   config.items = [];
	    	   this.callParent([config]);
	       },
	       
	       onViewItemContextMenu: function(dataview, record, item, index, e) {
	    	  e.stopEvent();
	    	  var contextMenu;
	    	  if(record.get("exprType") === 'operatorroot' || record.get("exprType") === 'operator') {
	    		   contextMenu = new Ext.menu.Menu({
	    			   items: [this.addCondition, this.addGroup, '-', this.changeGroup]
	    		   });
	    		   if(record.get("exprType") === 'operator'){
	    			   contextMenu.add(this.deleteGroup);
    	  		   }
	    		   contextMenu.showAt(e.getXY());
	    	  }	    	   
	       },
	       
	       createGroup: function(value ,text, iconcls) {
	    	   var group = {};
	    	   group.text = text;
			   group.iconCls = iconcls;
	    	   group.context = this;
	    	   group.handler = function(widget, event) {
    			   var rec = this.context.getSelectionModel().getSelection()[0];
    			   rec.appendChild({operator: text, exprType: "operator", iconCls: iconcls, expanded: true, operator_key: value})
	    	   }  
	    	   return group;
	       },
	       
	       modifyGroup: function(value, text, iconcls) {
	    	   var group = {};
	    	   group.text = text;
			   group.iconCls = iconcls;
	    	   group.context = this;
	    	   group.handler = function(widget, event) {
    			   var rec = this.context.getSelectionModel().getSelection()[0];
    			   rec.data.operator = text;
    			   rec.data.operator_key = value;
    			   rec.set('iconCls',iconcls);
    			   rec.set('title', text);
	    	   }  
	    	   return group;
	       },
	       
	       createTextBoxColumn: function(fieldInfo) {
	    	   
	    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   emptyText: $TR.ENTER_VALUE
	    	   });
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.editor = {
                   xtype: 'textfield',
                   emptyText: $TR.ENTER_VALUE
                   
               };
               fieldInfo.renderer = function(value, meta, currentRecord){
            	   var currTypeValue = currentRecord.get('exprType');
	    		   if(currTypeValue === "expression" ) {	    			   
	    			   if (value === undefined || value === "") {
	    				    meta.tdStyle = 'color:#ccc';
	    	                return 'enter a value';
	    	            } 
	    		   }
                   return Ext.String.htmlEncode(value);
               };
	    	   return fieldInfo;
	       },
	       
	       createComboBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var picklist = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					store: fieldInfo.store,
			        displayField: fieldInfo.displayField,
			        value: fieldInfo.defaultValue,
			        valueField: fieldInfo.valueField,
			        fieldName: fieldInfo.dataIndex,
			        queryMode: 'local',
			        width: '80px',
			        editable: false
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.renderer = function(value, meta, currentRecord) {
	    		   var currTypeValue = currentRecord.get('exprType');
	    		   picklist.setRecord(currentRecord);                   
	    		   if(currTypeValue === "expression" ) {
	    			   meta.tdCls = 'svmx-default-content';	    			   
	    			   if(value === undefined || value.length === 0) {
		    			   picklist.setValue(fieldInfo.store.getAt('0').get(fieldInfo.valueField));
		    			   value = picklist.getValue();
		    		   }	    			   
	    		   }	    		   
	    		   return Ext.String.htmlEncode(value);
	    	   };
	    	   
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   var currTypeValue = currentRecord.get('exprType');
	    		   if(currTypeValue !== "expression") {
	    			   return "";
	    		   }
	    		   picklist.setRecord(currentRecord); 
	    		   return picklist;
               };
	    	   return fieldInfo;	    	   
	    	   
	       }
		});
		
		Ext.define("com.servicemax.client.installigence.admin.Filters", {
		    extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
		   cls: 'grid-panel-borderless panel-radiusless',
		    
		    
		   constructor: function(config) {		   
			   
			    var me = this;
				me.filtersPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
						cls: 'grid-panel-borderless panel-radiusless',
						plain : 'true',
						height: 200,
						width: '100%'					   
				});
				
				me.searchFiltersToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0'
				});
				
				me.addFilterRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					cls:'piq-setup-add-button',
					text:$TR.ADD,
					disabled: true,
					handler : function(){
						me.onAddRecords();
					}
				});
				
				me.filtersTextSearch = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextSearch',{
					width: '40%',
					cls: 'search-textfield',
					emptyText : $TR.SEARCH_EMPTY_TEXT,
					listeners: {
	                    change: {
	                        fn: me.onTextFieldChange,
	                        scope: this,
	                        buffer: 500
	                    }
	               }
				});
				
				me.searchFiltersToolbar.add(me.filtersTextSearch);
				me.searchFiltersToolbar.add('->');
				me.searchFiltersToolbar.add(me.addFilterRecButton);
								
				//the below data model have to be replaced with the actual data
				me.filterStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				    fields: [ {name: 'name',  type: 'string'},
				              {name: 'isGlobal', type: 'boolean'} ,
				              {name: 'expression',   type: 'auto'}],
				    data: [				        
				    ]
				});
				
				me.filtersSearchGrid = SVMX.create('com.servicemax.client.installigence.admin.userActionsGrid',{
					cls: 'grid-panel-borderless panel-radiusless piq-setup-ta-grid',
					store: me.filterStore,
					height: 150,
				    selType: 'cellmodel',
				    plugins: [
			              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
			                  clicksToEdit: 2
			              })
			          ],
			        isFiltersGrid: true,
			        selectedExpression: undefined,
			        listeners: {
			             itemclick: function(dataview, record, item, index, e) {
			            	 me.expressiontree.setDisabled(false);
			            	 me.__persistNLoadExpression(record);
			             }
			        },
			        
			        nameFieldListner: {
			        	change: function(field, value) {
			        		 if(me.expressiontree.getStore().getData().items[0] !== undefined) {
			  	    		   me.expressiontree.getStore().getData().items[0].data.operator = value;
			  				   me.expressiontree.getStore().getData().items[0].set("title", value);
			  	    	   	}
			            }
			        }
	            });
				
				Ext.define('expressionModel', {
				    extend: 'Ext.data.Model',
				    fields: [{name: "operator", type: 'string'}, 
				             {name: "field", type: 'string'}, 
				             {name: "condition", type: 'string'}, 
				             {name: "value", type: 'string'}]
				});
				
				var expressionStore = Ext.create('Ext.data.TreeStore', {
					model: 'expressionModel',
				   root: {
					   nodeType: 'async',
					   attributes : [],
					   expanded: true,
					   children:[
				            { operator: $TR.SELECTED_EXPR, exprType: "root", iconCls:'svmx-expression-icon', expanded: true, 
				            	children: [{operator: 'And', exprType: "operatorroot", iconCls:'svmx-and-operator', expanded: true}]
				            }			            
					   ]
				   }
				});				
				
				var ibFieldsStore = this.__getIBFieldsStore(config.metadata);
				
				me.expressiontree = SVMX.create('com.servicemax.client.installigence.admin.ExpressionBuilder', { 
				   cls: 'grid-panel-borderless svmx-tree-panel svmx-expression-tree',
				   margin: '5 7 7 7',
				   //width: '100%',
				   height: 238,
				   store: expressionStore, 
				   header: false,
				   disabled: true,
				   selType: 'cellmodel',
				   plugins: [
			              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
			                  clicksToEdit: 1
			              })
		              ],
		           
				   rootVisible: false,
				   ibFieldStore: ibFieldsStore,
				   operatorsStore: this.__getOperatorsStore()
				});
			   
				config = config || {};
				config.items = [];
				config.items.push(me.searchFiltersToolbar);
				config.items.push(me.filtersSearchGrid);
				config.items.push(me.expressiontree);
				this.callParent([config]);
			   
		   },
		   
		   __getIBFieldsStore: function(metadata) {
			   var data = metadata[SVMX.OrgNamespace + "__Installed_Product__c"] ? metadata[SVMX.OrgNamespace + "__Installed_Product__c"]["fields"] : [];
			   var fields = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['fieldAPIName', 'fieldLabel'],
			        data: data,
			        sorters: [{
			            property: 'fieldLabel',
			            direction: 'ASC'
			        }],
			        sortRoot: 'fieldLabel',
			        sortOnLoad: true,
			        remoteSort: false,
			   });
			   return fields;
		   },
		   
		   __getOperatorsStore: function(metadata) {
			   var data = [{opLabel: $TR.EQUALS, opValue: "equals"},
			               {opLabel: $TR.NOT_EQUAL, opValue: "notequal"},
			               {opLabel: $TR.GREATER_THAN, opValue: "greaterthan"},
			               {opLabel: $TR.GREATER_OR_EQUAL, opValue: "greaterorequalto"},
			               {opLabel: $TR.LESS_THAN, opValue: "lessthan"},
			               {opLabel: $TR.LESS_OR_EQUAL, opValue: "lessorequalto"},
			               {opLabel: $TR.STARTS_WITH, opValue: "startswith"},
			               {opLabel: $TR.CONTAINS, opValue: "contains"},
			               {opLabel: $TR.DOES_NOT_CONTAIN, opValue: "doesnotcontain"},
			               {opLabel: $TR.INCLUDES, opValue: "includes"},
			               {opLabel: $TR.EXCLUDES, opValue: "excludes"},
			               {opLabel: $TR.ISNULL, opValue: "isnull"},
			               {opLabel: $TR.ISNOTNULL, opValue: "isnotnull"}]
			   var fields = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['opValue', 'opLabel'],
			        data: data
			   });
			   return fields;
		   },
	         
		   onTextFieldChange: function() {
			   var value = this.filtersTextSearch.getValue();
			   this.filtersSearchGrid.search(value);
		   },
         
		   onAddRecords: function() {
			   this.filtersSearchGrid.addItems({parentProfileId: this.filtersSearchGrid.selectedProfileId});
		   },
		   
		   persistNLoadExpression : function(record){
	    	   this.__persistNLoadExpression(record);
	       },
		   
		   __persistNLoadExpression: function(record) {
	    	   //store the existing Expression information to previous selected Expression
	    	   var prevSelExpression = this.filtersSearchGrid.selectedExpression;
	    	   if(this.filtersSearchGrid.selectedExpression) {
	    		   this.__persistExpression(prevSelExpression);
	    	   }
	    	   //load the Expression information to selected Expression
	    	   this.filtersSearchGrid.selectedExpression = record.getData ? record : undefined;
	    	   this.__loadExpression(record.getData ? record.getData() : {});
			   
		   },
		   
		   __persistExpression: function(record) {
			   var expressionInfo = {};
			   expressionInfo.children = this.__getRecords(this.expressiontree.getStore().getRootNode().childNodes[0]);
	    	   var storeRec = record;
	    	   if(storeRec) {
	    		   storeRec.set("expression", expressionInfo);
	    	   }
		   },
		   
	       __getRecords: function(rootNode) {
	    	 
	    	   return this.__getChildNodes(rootNode);
	       },
	       
	       __getChildNodes: function(node) {
	    	   
	    	   var rec = {};
	    	   if(node !== undefined && node.getData() !== undefined) {
		    	   rec.operator = node.getData().operator_key;
		    	   rec.exprType = node.getData().exprType;
		    	   rec.field = node.getData().field_key;
		    	   rec.condition = node.getData().condition_key;
		    	   rec.value = node.getData().value;
		    	   rec.expanded = true;
		    	   rec.iconCls = node.getData().iconCls;
		    	   if(node.isLeaf()) return;
		    	   if(node.childNodes && node.childNodes.length > 0){
		    		   rec.children = [];
			    	   var children = node.childNodes || [], i, l = children.length;
			    	   for(i = 0; i < l; i++){
			    		   rec.children.push(this.__getChildNodes(children[i]));
			    	   }
		    	   }
		    	   
	    	   }
	    	   return rec;	    	   
	       },
	       
		   __loadExpression: function(record) {
			   
			   if(record.expression === undefined || record.expression.length === 0) {
				   record.expression = {
					   nodeType: 'sync',
					   attributes : [],
					   expanded: true,
					   children:[
				            { operator: $TR.SELECTED_EXPR, exprType: "root", expanded: true, 
				            	children: [{operator: $TR.AND, exprType: "operatorroot", expanded: true, children:[], operator_key: "And"}]
				            }			            
					   ]
				   }
	    	   }
			   
			   this.__loadIconClsForNodes(record.expression.children[0] || record.expression.children);
	    	   this.expressiontree.getStore().setRootNode({
	    		   nodeType: 'sync',
				   attributes : [],
				   expanded: true,
    			   children: record.expression.children
    		   });
	    	   this.expressiontree.getStore().getRootNode().expand(true);
	    	   if(this.expressiontree.getStore().getData().items[0] !== undefined) {
	    		   this.expressiontree.getStore().getData().items[0].data.operator = record.name;
				   this.expressiontree.getStore().getData().items[0].set("title",record.name);
	    	   }	    	   
		   },
		   
		   __loadIconClsForNodes: function(record) {
			   
			   if(record.exprType === "root") {
				   record.iconCls = "svmx-expression-icon";
			   }else if(record.exprType === "operator" || record.exprType === "operatorroot") {
				   record.operator_key = record.operator;
				   if(record.operator === "And") {
					   record.operator = $TR.AND;
					   record.iconCls = "svmx-and-operator";
				   }else if(record.operator === "Or") {
					   record.operator = $TR.OR;
					   record.iconCls = "svmx-or-operator";
				   }else if(record.operator === "Not And") {
					   record.operator = $TR.NOT_AND;
					   record.iconCls = "svmx-not-and-operator";
				   }else if(record.operator === "Not Or") {
					   record.operator = $TR.NOT_OR;
					   record.iconCls = "svmx-not-or-operator";
				   }
			   }else if(record.exprType === "expression") {
				   record.iconCls = "svmx-no-icon";
				   record.expandable = false;
				   record.field_key = record.field;
				   record.condition_key = record.condition;
				   record.condition = this.__getOperatorsStore().findRecord("opValue", record.condition) !== null ? 
						   this.__getOperatorsStore().findRecord("opValue", record.condition).get("opLabel") : record.condition;
				   record.field = this.__getIBFieldsStore(this.metadata).findRecord("fieldAPIName", record.field) ? 
						   this.__getIBFieldsStore(this.metadata).findRecord("fieldAPIName", record.field).get("fieldLabel") : record.field;
			   }
			   if(record.children) {
				   var iData = 0, iLength = record.children.length || 0;
				   for(iData = 0; iData < iLength; iData++) {
					   this.__loadIconClsForNodes(record.children[iData]);
				   }
			   }
			   return record;
		   }
		});
	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\impl.js

(function(){
	SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXC";
	
	var instImpl = SVMX.Package("com.servicemax.client.installigence.admin.impl");

	instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
			//SVMX.orgNamespace = S
		},

		afterInitialize : function(){
			
		},
		
		beforeInitialize: function() {
			com.servicemax.client.installigence.admin.root.init();
			com.servicemax.client.installigence.admin.filters.init();
			com.servicemax.client.installigence.admin.useractions.init();
			com.servicemax.client.installigence.admin.datavalidationrules.init();
			com.servicemax.client.installigence.admin.producttemplates.init();
			com.servicemax.client.installigence.admin.othersettings.init();
			com.servicemax.client.installigence.admin.commands.init();
			com.servicemax.client.installigence.admin.operations.init();
			com.servicemax.client.installigence.admin.celleditors.init();
			com.servicemax.client.installigence.admin.objectsearch.init();
			com.servicemax.client.installigence.admin.search.init();
			com.servicemax.client.installigence.admin.technicalAttributes.init();
			com.servicemax.client.installigence.admin.productLookup.init();
			com.servicemax.client.installigence.admin.attachment.init();
			com.servicemax.client.installigence.admin.layoutAndAction.init();
			com.servicemax.client.installigence.admin.picklist.init();
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
									nameSpace : "SVMXC"};
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
	
	instImpl.Class("InstalligenceAdminEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); },
		
		triggerEvent : function(e) {
			return this.__base(e);
		}
		
	}, {});
	
	
	
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\installigenceadminoperations.js
(function(){
    var installigenceadminoperations = SVMX.Package("com.servicemax.client.installigence.admin.operations");

installigenceadminoperations.init = function(){

	var Module = com.servicemax.client.installigence.ui.components.impl.Module;	
	installigenceadminoperations.Class("GetSetupMetadata", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {

            };
           // var result;
            //result = {"status":true,"message":"","translations":[{"Text":"--None--","Key":"NONE"},{"Text":"Field Update","Key":"FIELD_UPDATE"},{"Text":"User Actions & Filters","Key":"USERACTIONS_FILTERS"},{"Text":"External App","Key":"EXTERNAL_APP"},{"Text":"Filters","Key":"FILTERS"},{"Text":"User Actions","Key":"USERACTIONS"},{"Text":"IB Templates","Key":"TEMPLATES"},{"Text":"Other Settings","Key":"OTHERSETTINGS"},{"Text":"Name","Key":"UAF_GRID_COL_NAME"},{"Text":"Type","Key":"UAF_GRID_COL_TYPE"},{"Text":"Action","Key":"UAF_GRID_COL_ACTION"},{"Text":"Is Global","Key":"UAF_GRID_COL_ISGLOBAL"},{"Text":"Select a profile","Key":"SELECT_PROFILE"},{"Text":"ProductIQ Setup","Key":"SETUP_TITLE"},{"Text":"Template Name","Key":"TEMPLATE_NAME"},{"Text":"Template ID","Key":"TEMPLATE_ID"},{"Text":"IB Display Text","Key":"IB_DISPLAY_TEXT"},{"Text":"Location Display Text","Key":"LOCATION_DISPLAY_TEXT"},{"Text":"Sub-Location Display Text","Key":"SUB_LOCATION_DISPLAY_TEXT"},{"Text":"Product","Key":"PRODUCT"},{"Text":"Icon","Key":"ICON"},{"Text":"Default values","Key":"DEFAULT_VALUES"},{"Text":"Value map for old IB","Key":"VALUE_MAP_OLD_IB"},{"Text":"Value map for new IB","Key":"VALUE_MAP_NEW_IB"},{"Text":"Select a template","Key":"SELECT_TEMPLATE"},{"Text":"Product Swap","Key":"PRODUCT_SWAP"},{"Text":"Product Configuration","Key":"PRODUCT_CONFIGURATION"},{"Text":"Selected Expression","Key":"SELECTED_EXPR"},{"Text":"Add Condition","Key":"ADD_CONDITION"},{"Text":"Add Group","Key":"ADD_GROUP"},{"Text":"Change Group","Key":"CHANGE_GROUP"},{"Text":"Delete Group","Key":"DELETE_GROUP"},{"Text":"And","Key":"AND"},{"Text":"Or","Key":"OR"},{"Text":"Not And","Key":"NOT_AND"},{"Text":"Not Or","Key":"NOT_OR"},{"Text":"Search","Key":"SEARCH_EMPTY_TEXT"},{"Text":"Add Product","Key":"ADD_PRODUCT"},{"Text":"Delete Product","Key":"DEL_PRODUCT"},{"Text":"Enter a value","Key":"ENTER_VALUE"},{"Text":"Automatically copy configuration while swapping products","Key":"OTHER_SET_SWAP_TEXT"},{"Text":"Starts With","Key":"STARTS_WITH"},{"Text":"Not Equal","Key":"NOT_EQUAL"},{"Text":"Less or Equal To","Key":"LESS_OR_EQUAL"},{"Text":"Less Than","Key":"LESS_THAN"},{"Text":"Is Null","Key":"ISNULL"},{"Text":"Is Not Null","Key":"ISNOTNULL"},{"Text":"Includes","Key":"INCLUDES"},{"Text":"Greater or Equal To","Key":"GREATER_OR_EQUAL"},{"Text":"Greater Than","Key":"GREATER_THAN"},{"Text":"Excludes","Key":"EXCLUDES"},{"Text":"Equals","Key":"EQUALS"},{"Text":"Does Not Contain","Key":"DOES_NOT_CONTAIN"},{"Text":"Contains","Key":"CONTAINS"},{"Text":"Create","Key":"CREATE"},{"Text":"Cancel","Key":"CANCEL"},{"Text":"Invoice Rules","Key":"MANDATORY_FIELDS"},{"Text":"Info","Key":"MESSAGE_INFO"},{"Text":"Success","Key":"MESSAGE_SUCCESS"},{"Text":"Error","Key":"MESSAGE_ERROR"},{"Text":"Confirm","Key":"MESSAGE_CONFIRM"},{"Text":"Product","Key":"MESSAGE_PRODUCT"},{"Text":"Standard Actions","Key":"STANDARD_ACTIONS"},{"Text":"Custom Actions","Key":"CUSTOM_ACTIONS"},{"Text":"Hide","Key":"HIDE_STANDARD_ACTIONS"},{"Text":"Data Validation Rules","Key":"DATA_VALIDATION_RULE"},{"Text":"Select an Object","Key":"SELECT_OBJECT"},{"Text":"Rule Name","Key":"RULE_NAME"},{"Text":"Description","Key":"DESCRIPTION"},{"Text":"Message Type","Key":"MESSAGE_TYPE"},{"Text":"Error(s)","Key":"MESSAGE_ERRORS"},{"Text":"Warning(s)","Key":"MESSAGE_WARNINGS"},{"Text":"Custom URL","Key":"CUSTOM_URL"},{"Text":"Record(s) saved successfully","Key":"SAVE_SUCCESS"},{"Text":"Save","Key":"SAVE"},{"Text":"Cancel","Key":"CANCEL"},{"Text":"Back To Setup Home","Key":"BACK_TO_SETUP_HOME"},{"Text":"Select a search","Key":"SELECT_SEARCH"}],"svmxProfiles":[{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"Default Group Profile","profileId":"a13550000008SNDAA2","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":[{"searches":[{"searchName":"GG_IB_Search1","searchLabel":null,"searchfields":null,"advancedExpression":null}],"objectName":"SVMXC__Installed_Product__c"}],"rulesWithObjectInfo":[],"profileName":"FerhanGP","profileId":"a13550000008SmwAAE","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":[{"searches":[{"searchName":"GG_IB_Search3rdLevel","searchLabel":null,"searchfields":null,"advancedExpression":null}],"objectName":"SVMXC__Installed_Product__c"}],"rulesWithObjectInfo":[{"rules":[{"ruleName":"CountryIndiaStateKarnakata","ruleId":"CountryIndiaStateKarnakata","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":null,"description":"Country cant be India && State cant be Karnakata","advExpr":null}],"objectName":"SVMXC__Installed_Product__c","objectLabel":null}],"profileName":"Garish_GP","profileId":"a13550000008jMaAAI","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[{"parentProfileId":"a13550000008jMaAAI","name":"iOS2","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"Scrap","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Status__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}},{"parentProfileId":"a13550000008jMaAAI","name":"AND","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"Bang","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__City__c","expRule":null,"exprType":"expression","condition":"contains","children":null},{"value":"Installed","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Status__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}}],"dataValidationRules":null,"customUrls":null,"actions":[{"parentProfileId":"a13550000008jMaAAI","name":"sandbox","isHidden":null,"isGlobal":false,"actionType":"customurl","action":"Sandbox"},{"parentProfileId":"a13550000008jMaAAI","name":"no prefix","isHidden":null,"isGlobal":false,"actionType":"customurl","action":"No prefix"},{"parentProfileId":"a13550000008jMaAAI","name":"IB Variables","isHidden":null,"isGlobal":false,"actionType":"customurl","action":"IB_variable_url"},{"parentProfileId":"a13550000008jMaAAI","name":"FieldUpdate1","isHidden":null,"isGlobal":false,"actionType":"fieldupdate","action":"FieldUpdate_IB"},{"parentProfileId":"a13550000008jMaAAI","name":"FieldUpdate2","isHidden":null,"isGlobal":false,"actionType":"fieldupdate","action":"MAP043V"},{"parentProfileId":"a13550000008jMaAAI","name":"Google.com","isHidden":null,"isGlobal":false,"actionType":"customurl","action":"google"},{"parentProfileId":"a13550000008jMaAAI","name":"SGG","isHidden":null,"isGlobal":false,"actionType":"fieldupdate","action":"SG_Field_Update"}],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":[{"searches":[{"searchName":"","searchLabel":null,"searchfields":null,"advancedExpression":null}],"objectName":"SVMXC__Installed_Product__c"}],"rulesWithObjectInfo":[{"rules":[{"ruleName":"AndCond","ruleId":"AndCond","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":null,"description":"City cant be Bangalore && State cant be Karnataka","advExpr":null},{"ruleName":"CityMy--StatusInventory--not allowed","ruleId":"CityMyStatusInventorynotallowed","objectName":"SVMXC__Installed_Product__c","messageType":"WARNING","errorMessage":null,"description":"CityMy--StatusInventory--not allowed","advExpr":null},{"ruleName":"Status-Rule","ruleId":"StatusRule","objectName":"SVMXC__Installed_Product__c","messageType":"WARNING","errorMessage":null,"description":"STATUS CANT BE ENG","advExpr":null}],"objectName":"SVMXC__Installed_Product__c","objectLabel":null}],"profileName":"Garish_GP1","profileId":"a1355000000AxXmAAK","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[{"parentProfileId":"a1355000000AxXmAAK","name":"GG_Filter_OR1","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"Or","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"GGargish","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Company__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"Bangalore","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__City__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}},{"parentProfileId":"a1355000000AxXmAAK","name":"GG_Filter2_OR2","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"Or","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"Bangalore","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__City__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"India","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Country__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}},{"parentProfileId":"a1355000000AxXmAAK","name":"GG_Filter3_AND","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"GGargish","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Company__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"Bangalore","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__City__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}},{"parentProfileId":"a1355000000AxXmAAK","name":"GG_Filter4_NotOR","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"Not Or","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"S","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Company__c","expRule":null,"exprType":"expression","condition":"startswith","children":null},{"value":"Bangalore","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__City__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}},{"parentProfileId":"a1355000000AxXmAAK","name":"GG_Filter5_NotAND","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"C","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Product__c","expRule":null,"exprType":"expression","condition":"startswith","children":null},{"value":"U","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Country__c","expRule":null,"exprType":"expression","condition":"startswith","children":null}]}]}]}},{"parentProfileId":"a1355000000AxXmAAK","name":"SG_Filter","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"Or","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operator","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Date_Installed__c","expRule":null,"exprType":"expression","condition":"isnull","children":null},{"value":"Shipped","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Status__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]},{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operator","condition":null,"children":[{"value":"Installed","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Status__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Date_Installed__c","expRule":null,"exprType":"expression","condition":"isnotnull","children":null}]}]}]}]}}],"dataValidationRules":null,"customUrls":null,"actions":[{"parentProfileId":"a1355000000AxXmAAK","name":"Config sync","isHidden":null,"isGlobal":false,"actionType":"customurl","action":"google"},{"parentProfileId":"a1355000000AxXmAAK","name":"SG_field update","isHidden":null,"isGlobal":false,"actionType":"fieldupdate","action":"SG_Field_Update"}],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":[{"searches":[{"searchName":"SearchForAll_IBs","searchLabel":null,"searchfields":null,"advancedExpression":null}],"objectName":"SVMXC__Installed_Product__c"}],"rulesWithObjectInfo":[{"rules":[{"ruleName":"City should not be Bangalore","ruleId":"City_should_not_be_Bangalore","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":null,"description":"","advExpr":null}],"objectName":"SVMXC__Installed_Product__c","objectLabel":null}],"profileName":"iPhone Group Profile","profileId":"a13550000008ex8AAA","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[{"parentProfileId":"a13550000008ex8AAA","name":"Trial Filter Set","isGlobal":false,"expression":{"value":null,"sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":null,"condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":null,"expRule":null,"exprType":"root","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"Or","fieldType":null,"field":null,"expRule":null,"exprType":"operatorroot","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operator","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Country__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Contact__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]},{"value":"","sequence":null,"parameterType":null,"operator":"And","fieldType":null,"field":null,"expRule":null,"exprType":"operator","condition":null,"children":[{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Country__c","expRule":null,"exprType":"expression","condition":"equals","children":null},{"value":"","sequence":null,"parameterType":null,"operator":null,"fieldType":null,"field":"SVMXC__Contact__c","expRule":null,"exprType":"expression","condition":"equals","children":null}]}]}]}]}}],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"Kala Group Profile","profileId":"a13550000008SjOAAU","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"mobileuser","profileId":"a1355000000BoyDAAS","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":null,"dataValidationRules":null,"customUrls":null,"actions":null,"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"NB Profile","profileId":"a1355000000B3ENAA0","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"SAR-GroupProfile","profileId":"a13550000008StsAAE","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"Servicemax technician","profileId":"a1355000000BUFUAA4","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"Servicemax Technician Profile_SR","profileId":"a1355000000Bpt0AAC","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":null,"dataValidationRules":null,"customUrls":null,"actions":null,"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"SG iPad Group Profile","profileId":"a1355000000Aw6yAAC","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":[{"rules":[],"objectName":"SVMXC__Installed_Product__c","objectLabel":null}],"profileName":"shagp","profileId":"a13550000008SqPAAU","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"SVMX - iOS Dev Technician Profile","profileId":"a1355000000Bjf3AAC","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":null,"dataValidationRules":null,"customUrls":null,"actions":null,"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"SVMX Technician","profileId":"a1355000000BUJAAA4","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":null,"dataValidationRules":null,"customUrls":null,"actions":null,"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"svmx_tech","profileId":"a1355000000BX7sAAG","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":null,"dataValidationRules":null,"customUrls":null,"actions":null,"accPriorityFields":null,"accHiddenFields":null},{"stdActions":null,"slocPriorityFields":null,"slocHiddenFields":null,"search":null,"rulesWithObjectInfo":null,"profileName":"","profileId":"global","productSearchFields":null,"productDisplayFields":null,"mappings":null,"locPriorityFields":null,"locHiddenFields":null,"ibSearchFields":null,"ibPriorityFields":null,"ibHiddenFields":null,"ibDisplayFields":null,"filters":[],"dataValidationRules":null,"customUrls":null,"actions":[],"accPriorityFields":null,"accHiddenFields":null}],"sforceObjectDescribes":[{"objectLabel":"Installed Product","objectAPIName":"SVMXC__Installed_Product__c","fields":[{"type":"ID","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Record ID","fieldAPIName":"Id"},{"type":"REFERENCE","relationshipName":"Owner","referenceTo":"Group","nameField":false,"fieldLabel":"Owner ID","fieldAPIName":"OwnerId"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Deleted","fieldAPIName":"IsDeleted"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":true,"fieldLabel":"Installed Product ID","fieldAPIName":"Name"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Currency ISO Code","fieldAPIName":"CurrencyIsoCode"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Created Date","fieldAPIName":"CreatedDate"},{"type":"REFERENCE","relationshipName":"CreatedBy","referenceTo":"User","nameField":false,"fieldLabel":"Created By ID","fieldAPIName":"CreatedById"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Modified Date","fieldAPIName":"LastModifiedDate"},{"type":"REFERENCE","relationshipName":"LastModifiedBy","referenceTo":"User","nameField":false,"fieldLabel":"Last Modified By ID","fieldAPIName":"LastModifiedById"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"System Modstamp","fieldAPIName":"SystemModstamp"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Activity Date","fieldAPIName":"LastActivityDate"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Viewed Date","fieldAPIName":"LastViewedDate"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Referenced Date","fieldAPIName":"LastReferencedDate"},{"type":"REFERENCE","relationshipName":"SVMXC__Access_Hours__r","referenceTo":"BusinessHours","nameField":false,"fieldLabel":"Access Hours","fieldAPIName":"SVMXC__Access_Hours__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Alternate Account","fieldAPIName":"SVMXC__Alternate_Company__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Asset Tag","fieldAPIName":"SVMXC__Asset_Tag__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Business_Hours__r","referenceTo":"BusinessHours","nameField":false,"fieldLabel":"Business Hours (Do Not Use)","fieldAPIName":"SVMXC__Business_Hours__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"City","fieldAPIName":"SVMXC__City__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Company__r","referenceTo":"Account","nameField":false,"fieldLabel":"Account","fieldAPIName":"SVMXC__Company__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Contact__r","referenceTo":"Contact","nameField":false,"fieldLabel":"Contact","fieldAPIName":"SVMXC__Contact__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Country","fieldAPIName":"SVMXC__Country__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Date Installed","fieldAPIName":"SVMXC__Date_Installed__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Date Ordered","fieldAPIName":"SVMXC__Date_Ordered__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Date Shipped","fieldAPIName":"SVMXC__Date_Shipped__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Distributor_Company__r","referenceTo":"Account","nameField":false,"fieldLabel":"Distributor Account","fieldAPIName":"SVMXC__Distributor_Company__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Distributor_Contact__r","referenceTo":"Contact","nameField":false,"fieldLabel":"Distributor Contact","fieldAPIName":"SVMXC__Distributor_Contact__c"},{"type":"TEXTAREA","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Installation Notes","fieldAPIName":"SVMXC__Installation_Notes__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Date Shipped","fieldAPIName":"SVMXC__Last_Date_Shipped__c"},{"type":"DOUBLE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Latitude","fieldAPIName":"SVMXC__Latitude__c"},{"type":"DOUBLE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Longitude","fieldAPIName":"SVMXC__Longitude__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Parent__r","referenceTo":"SVMXC__Installed_Product__c","nameField":false,"fieldLabel":"Parent","fieldAPIName":"SVMXC__Parent__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Preferred_Technician__r","referenceTo":"SVMXC__Service_Group_Members__c","nameField":false,"fieldLabel":"Preferred Technician","fieldAPIName":"SVMXC__Preferred_Technician__c"},{"type":"REFERENCE","relationshipName":"SVMXC__ProductIQTemplate__r","referenceTo":"SVMXC__ProductIQTemplate__c","nameField":false,"fieldLabel":"ProductIQ Template","fieldAPIName":"SVMXC__ProductIQTemplate__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Name","fieldAPIName":"SVMXC__Product_Name__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Product__r","referenceTo":"Product2","nameField":false,"fieldLabel":"Product","fieldAPIName":"SVMXC__Product__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Sales Order Number","fieldAPIName":"SVMXC__Sales_Order_Number__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Serial/Lot Number","fieldAPIName":"SVMXC__Serial_Lot_Number__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Service Contract End Date","fieldAPIName":"SVMXC__Service_Contract_End_Date__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Service Contract Exchange Type","fieldAPIName":"SVMXC__Service_Contract_Exchange_Type__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Service_Contract_Line__r","referenceTo":"SVMXC__Service_Contract_Products__c","nameField":false,"fieldLabel":"Service Contract Line","fieldAPIName":"SVMXC__Service_Contract_Line__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Service Contract Start Date","fieldAPIName":"SVMXC__Service_Contract_Start_Date__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Service_Contract__r","referenceTo":"SVMXC__Service_Contract__c","nameField":false,"fieldLabel":"Service Contract","fieldAPIName":"SVMXC__Service_Contract__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Site__r","referenceTo":"SVMXC__Site__c","nameField":false,"fieldLabel":"Location","fieldAPIName":"SVMXC__Site__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"State","fieldAPIName":"SVMXC__State__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Status","fieldAPIName":"SVMXC__Status__c"},{"type":"TEXTAREA","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Street","fieldAPIName":"SVMXC__Street__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Sub_Location__r","referenceTo":"SVMXC__Sub_Location__c","nameField":false,"fieldLabel":"Sub Location","fieldAPIName":"SVMXC__Sub_Location__c"},{"type":"REFERENCE","relationshipName":"SVMXC__Top_Level__r","referenceTo":"SVMXC__Installed_Product__c","nameField":false,"fieldLabel":"Top-Level","fieldAPIName":"SVMXC__Top_Level__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Warranty End Date","fieldAPIName":"SVMXC__Warranty_End_Date__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Warranty Exchange Type","fieldAPIName":"SVMXC__Warranty_Exchange_Type__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Warranty Start Date","fieldAPIName":"SVMXC__Warranty_Start_Date__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Warranty","fieldAPIName":"SVMXC__Warranty__c"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Zip","fieldAPIName":"SVMXC__Zip__c"},{"type":"REFERENCE","relationshipName":"Product_Stock__r","referenceTo":"SVMXC__Product_Stock__c","nameField":false,"fieldLabel":"Product Stock","fieldAPIName":"Product_Stock__c"},{"type":"DOUBLE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Number Test","fieldAPIName":"Number_Test__c"},{"type":"MULTIPICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"AppProduct","fieldAPIName":"AppProduct__c"},{"type":"MULTIPICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"MultiPickCust","fieldAPIName":"MultiPickCust__c"},{"type":"DOUBLE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Download to Mobile","fieldAPIName":"Download_to_Mobile__c"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"CustomDateTimeFields","fieldAPIName":"CustomDateTimeFields__c"},{"type":"DATE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"CustomDate","fieldAPIName":"CustomDate__c"}]},{"objectLabel":"Product","objectAPIName":"Product2","fields":[{"type":"ID","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product ID","fieldAPIName":"Id"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":true,"fieldLabel":"Product Name","fieldAPIName":"Name"},{"type":"STRING","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Code","fieldAPIName":"ProductCode"},{"type":"TEXTAREA","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Description","fieldAPIName":"Description"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Active","fieldAPIName":"IsActive"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Created Date","fieldAPIName":"CreatedDate"},{"type":"REFERENCE","relationshipName":"CreatedBy","referenceTo":"User","nameField":false,"fieldLabel":"Created By ID","fieldAPIName":"CreatedById"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Modified Date","fieldAPIName":"LastModifiedDate"},{"type":"REFERENCE","relationshipName":"LastModifiedBy","referenceTo":"User","nameField":false,"fieldLabel":"Last Modified By ID","fieldAPIName":"LastModifiedById"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"System Modstamp","fieldAPIName":"SystemModstamp"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Family","fieldAPIName":"Family"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Currency ISO Code","fieldAPIName":"CurrencyIsoCode"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Deleted","fieldAPIName":"IsDeleted"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Viewed Date","fieldAPIName":"LastViewedDate"},{"type":"DATETIME","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Last Referenced Date","fieldAPIName":"LastReferencedDate"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Enable Serialized Tracking of Stock","fieldAPIName":"SVMXC__Enable_Serialized_Tracking__c"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Inherit Parent Warranty","fieldAPIName":"SVMXC__Inherit_Parent_Warranty__c"},{"type":"CURRENCY","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Cost","fieldAPIName":"SVMXC__Product_Cost__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Line","fieldAPIName":"SVMXC__Product_Line__c"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Replacement Available?","fieldAPIName":"SVMXC__Replacement_Available__c"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Select","fieldAPIName":"SVMXC__Select__c"},{"type":"BOOLEAN","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Stockable","fieldAPIName":"SVMXC__Stockable__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Tracking","fieldAPIName":"SVMXC__Tracking__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Unit of Measure","fieldAPIName":"SVMXC__Unit_Of_Measure__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Product Type","fieldAPIName":"SVMXC__Product_Type__c"},{"type":"REFERENCE","relationshipName":"Work_Order__r","referenceTo":"SVMXC__Service_Order__c","nameField":false,"fieldLabel":"Work Order","fieldAPIName":"Work_Order__c"},{"type":"TEXTAREA","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Custom description","fieldAPIName":"Custom_description__c"},{"type":"MULTIPICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"ProdMultipicklist","fieldAPIName":"ProdMultipicklist__c"},{"type":"PICKLIST","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"SVMXC Related Business Unit","fieldAPIName":"SVMXC_Related_Business_Unit__c"},{"type":"DOUBLE","relationshipName":null,"referenceTo":null,"nameField":false,"fieldLabel":"Download To Mobile","fieldAPIName":"Download_To_Mobile__c"}]}],"productSearchFields":[],"productDisplayFields":[],"installigenceLogos":[],"ibValueMaps":[{"valueMapProcessName":"FieldUpdate_IB","valueMapName":"FieldUpdate_IB","id":"a15550000009RwsAAE"},{"valueMapProcessName":"SG_Field Update","valueMapName":"SG_Field_Update","id":"a15550000009ZRYAA2"},{"valueMapProcessName":"SVMXSTD: New Installed Product","valueMapName":"MAP043V","id":"a15550000008THIAA2"}],"ibTemplates":[],"ibActionURLs":[{"id":"a15550000008TT2AAM","actionURLProcessName":"Create Warranty","actionURLName":"OTH021"},{"id":"a15550000009KYKAA2","actionURLProcessName":"google","actionURLName":"google"},{"id":"a15550000009RdIAAU","actionURLProcessName":"IB variable url","actionURLName":"IB_variable_url"},{"id":"a15550000008TSnAAM","actionURLProcessName":"Installed Product: Validate Address","actionURLName":"OTH003"},{"id":"a15550000009KYPAA2","actionURLProcessName":"NO prefix","actionURLName":"No prefix"},{"id":"a15550000009KYFAA2","actionURLProcessName":"SalesforceUrl","actionURLName":"Sandbox"},{"id":"a15550000008TSmAAM","actionURLProcessName":"Update Counters","actionURLName":"OTH002"},{"id":"a15550000008TSlAAM","actionURLProcessName":"View Configuration","actionURLName":"OTH001"}],"dataValidationRules":[{"rules":[{"ruleName":"Status-Rule","ruleId":"StatusRule","objectName":"SVMXC__Installed_Product__c","messageType":"WARNING","errorMessage":"STATUS CANT BE ENG","description":"STATUS CANT BE ENG","advExpr":null},{"ruleName":"CityMy--StatusInventory--not allowed","ruleId":"CityMyStatusInventorynotallowed","objectName":"SVMXC__Installed_Product__c","messageType":"WARNING","errorMessage":"CityMy--StatusInventory--not allowed","description":"CityMy--StatusInventory--not allowed","advExpr":"1 AND 2"},{"ruleName":"AndCond","ruleId":"AndCond","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":"City cant be Bangalore && State cant be Karnataka","description":"City cant be Bangalore && State cant be Karnataka","advExpr":"1 AND 2"},{"ruleName":"Acc_City","ruleId":"AccCity","objectName":"SVMXC__Installed_Product__c","messageType":"WARNING","errorMessage":"Acc = GGargish & City = Bangalore","description":null,"advExpr":"1 AND 2"},{"ruleName":"City need to be Bangalore","ruleId":"CityneedtobeBangalore","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":"City cant be Bangalore","description":null,"advExpr":null},{"ruleName":"CountryIndiaStateKarnakata","ruleId":"CountryIndiaStateKarnakata","objectName":"SVMXC__Installed_Product__c","messageType":"Error","errorMessage":"Country cant be India && State cant be Karnakata","description":"Country cant be India && State cant be Karnakata","advExpr":"(1 AND 2) AND (3 AND 4)"}],"objectName":"SVMXC__Installed_Product__c","objectLabel":"Installed Product"}],"availableSearchProc":{"searches":[{"searchName":"GG-IB_Search2","searchLabel":"GG-IB_Search2","searchfields":null,"advancedExpression":null},{"searchName":"Search33","searchLabel":"Search33","searchfields":null,"advancedExpression":null},{"searchName":"GG_IB_Search1","searchLabel":"GG_IB_Search1","searchfields":null,"advancedExpression":null},{"searchName":"GG_IB_Search3rdLevel","searchLabel":"GG_IB_Search3rdLevel","searchfields":null,"advancedExpression":null},{"searchName":"ParentOnIBsearch","searchLabel":"ParentOnIBsearch","searchfields":null,"advancedExpression":null},{"searchName":"FER-AllObjectSearch","searchLabel":"FER-AllObjectSearch","searchfields":null,"advancedExpression":null},{"searchName":"TestRegression","searchLabel":"TestRegression","searchfields":null,"advancedExpression":null},{"searchName":"new_search_pp","searchLabel":"new_search_pp","searchfields":null,"advancedExpression":null},{"searchName":"IB_Search","searchLabel":"IB_Search","searchfields":null,"advancedExpression":null},{"searchName":"search_lastModifiedBy","searchLabel":"search_lastModifiedBy","searchfields":null,"advancedExpression":null},{"searchName":"SearchForAll_IBs","searchLabel":"SearchForAll_IBs","searchfields":null,"advancedExpression":null},{"searchName":"SeachForIB","searchLabel":"GG_SeachForIB","searchfields":null,"advancedExpression":null},{"searchName":"SFM Line Enhancement","searchLabel":"SFM Line Enhancement","searchfields":null,"advancedExpression":null}],"objectName":"SVMXC__Installed_Product__c"}};
            //responder.result(result);

            /*result = {"status":true,"message":"","translations":[{"Text":"--None--","Key":"NONE"},{"Text":"Field Update","Key":"FIELD_UPDATE"},{"Text":"User Actions & Filters","Key":"USERACTIONS_FILTERS"},{"Text":"External App","Key":"EXTERNAL_APP"},{"Text":"Filters","Key":"FILTERS"},{"Text":"User Actions","Key":"USERACTIONS"},{"Text":"IB Templates","Key":"TEMPLATES"},{"Text":"Other Settings","Key":"OTHERSETTINGS"},{"Text":"Name","Key":"UAF_GRID_COL_NAME"},{"Text":"Type","Key":"UAF_GRID_COL_TYPE"},{"Text":"Action","Key":"UAF_GRID_COL_ACTION"},{"Text":"Is Global","Key":"UAF_GRID_COL_ISGLOBAL"},{"Text":"Select a profile","Key":"SELECT_PROFILE"},{"Text":"ProductIQ Setup","Key":"SETUP_TITLE"},{"Text":"Template Name","Key":"TEMPLATE_NAME"},{"Text":"Template id","Key":"TEMPLATE_ID"},{"Text":"IB Display Text","Key":"IB_DISPLAY_TEXT"},{"Text":"Location Display Text","Key":"LOCATION_DISPLAY_TEXT"},{"Text":"Sub-Location Display Text","Key":"SUB_LOCATION_DISPLAY_TEXT"},{"Text":"Product","Key":"PRODUCT"},{"Text":"Icon","Key":"ICON"},{"Text":"Default values","Key":"DEFAULT_VALUES"},{"Text":"Value map for old IB","Key":"VALUE_MAP_OLD_IB"},{"Text":"Value map for new IB","Key":"VALUE_MAP_NEW_IB"},{"Text":"Select a template","Key":"SELECT_TEMPLATE"},{"Text":"Product Swap","Key":"PRODUCT_SWAP"},{"Text":"Product Configuration","Key":"PRODUCT_CONFIGURATION"},{"Text":"Selected Expression","Key":"SELECTED_EXPR"},{"Text":"Add Condition","Key":"ADD_CONDITION"},{"Text":"Add Group","Key":"ADD_GROUP"},{"Text":"Change Group","Key":"CHANGE_GROUP"},{"Text":"Delete Group","Key":"DELETE_GROUP"},{"Text":"And","Key":"AND"},{"Text":"Or","Key":"OR"},{"Text":"Not And","Key":"NOT_AND"},{"Text":"Not Or","Key":"NOT_OR"},{"Text":"Search","Key":"SEARCH_EMPTY_TEXT"},{"Text":"Add Product","Key":"ADD_PRODUCT"},{"Text":"enter a value","Key":"ENTER_VALUE"},{"Text":"Automatically copy configuration while swapping products","Key":"OTHER_SET_SWAP_TEXT"},{"Text":"Starts With","Key":"STARTS_WITH"},{"Text":"Not Equal","Key":"NOT_EQUAL"},{"Text":"Less or Equal To","Key":"LESS_OR_EQUAL"},{"Text":"Less Than","Key":"LESS_THAN"},{"Text":"Is Null","Key":"ISNULL"},{"Text":"Is Not Null","Key":"ISNOTNULL"},{"Text":"Includes","Key":"INCLUDES"},{"Text":"Greater or Equal To","Key":"GREATER_OR_EQUAL"},{"Text":"Greater Than","Key":"GREATER_THAN"},{"Text":"Excludes","Key":"EXCLUDES"},{"Text":"Equals","Key":"EQUALS"},{"Text":"Does Not Contain","Key":"DOES_NOT_CONTAIN"},{"Text":"Contains","Key":"CONTAINS"}],"svmxProfiles":[{"profileName":"Cloned Default for SP","profileId":"a10F0000002izWFIAY","mappings":null,"filters":[],"actions":[]},{"profileName":"Default Group Profile","profileId":"a10F0000002i2SvIAI","mappings":null,"filters":[{"parentProfileId":"a10F0000002i2SvIAI","name":"Test1","isGlobal":false,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":[{"value":"","operator":"Test1","field":null,"exprType":"root","condition":null,"children":[{"value":"","operator":"And","field":null,"exprType":"operatorroot","condition":null,"children":[{"value":"Prod1","operator":"","field":"SVMXDEV__Product_Name__c","exprType":"expression","condition":"startswith","children":null},{"value":"","operator":"And","field":null,"exprType":"operator","condition":null,"children":[{"value":"ACC","operator":"","field":"SVMXDEV__Distributor_Contact__c","exprType":"expression","condition":"lessthan","children":null}]}]}]}]}}],"actions":[{"parentProfileId":"a10F0000002i2SvIAI","name":"Actoin1","isGlobal":false,"actionType":"Field Map","action":"KKG_Mapps_inst_to_inst_FM"}]},{"profileName":"NV Group Profile","profileId":"a10F0000002is1mIAA","mappings":null,"filters":[{"parentProfileId":"a10F0000002is1mIAA","name":"SYMMETRA Device","isGlobal":false,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":[{"value":"","operator":"SYMMETRA Device","field":null,"exprType":"root","condition":null,"children":[{"value":"","operator":"And","field":null,"exprType":"operatorroot","condition":null,"children":[{"value":"SYMMETRA","operator":"","field":"SVMXDEV__Product_Name__c","exprType":"expression","condition":"equals","children":null}]}]}]}}],"actions":[{"parentProfileId":"a10F0000002is1mIAA","name":"Deinstall","isGlobal":false,"actionType":"fieldupdate","action":"Deinstall_PRIQ"},{"parentProfileId":"a10F0000002is1mIAA","name":"In Transit - Return","isGlobal":false,"actionType":"fieldupdate","action":"InTransit_PRIQ"},{"parentProfileId":"a10F0000002is1mIAA","name":"Installed","isGlobal":false,"actionType":"fieldupdate","action":"Installed_PRIQ"}]},{"profileName":"Santosh GP","profileId":"a10F0000003dHiYIAU","mappings":null,"filters":[],"actions":[{"parentProfileId":"a10F0000003dHiYIAU","name":"User Action~1","isGlobal":false,"actionType":"fieldupdate","action":"MAP043V"}]},{"profileName":"","profileId":"global","mappings":null,"filters":[],"actions":[]}],
            		"sforceObjectDescribes":[{"objectLabel":"Product","objectAPIName":"Product2","fields":[{"fieldLabel":"Enable Serialized Tracking of Stock","fieldAPIName":"SVMXC__Enable_Serialized_Tracking__c"},{"fieldLabel":"Product Code","fieldAPIName":"ProductCode"},{"fieldLabel":"Inherit Parent Warranty","fieldAPIName":"SVMXC__Inherit_Parent_Warranty__c"},{"fieldLabel":"Stockable","fieldAPIName":"SVMXC__Stockable__c"},{"fieldLabel":"Select","fieldAPIName":"SVMXC__Select__c"},{"fieldLabel":"Created Date","fieldAPIName":"CreatedDate"},{"fieldLabel":"Product Cost","fieldAPIName":"SVMXC__Product_Cost__c"},{"fieldLabel":"Tracking","fieldAPIName":"SVMXC__Tracking__c"},{"fieldLabel":"Replacement Available?","fieldAPIName":"SVMXC__Replacement_Available__c"},{"fieldLabel":"Created By ID","fieldAPIName":"CreatedById"},{"fieldLabel":"Last Modified Date","fieldAPIName":"LastModifiedDate"},{"fieldLabel":"Product ID","fieldAPIName":"Id"},{"fieldLabel":"Active","fieldAPIName":"IsActive"},{"fieldLabel":"Product Description","fieldAPIName":"Description"},{"fieldLabel":"Product Family","fieldAPIName":"Family"},{"fieldLabel":"Deleted","fieldAPIName":"IsDeleted"},{"fieldLabel":"Product Name","fieldAPIName":"Name"},{"fieldLabel":"Unit of Measure","fieldAPIName":"SVMXC__Unit_Of_Measure__c"},{"fieldLabel":"Product Line","fieldAPIName":"SVMXC__Product_Line__c"},{"fieldLabel":"System Modstamp","fieldAPIName":"SystemModstamp"},{"fieldLabel":"Last Modified By ID","fieldAPIName":"LastModifiedById"},{"fieldLabel":"Currency ISO Code","fieldAPIName":"CurrencyIsoCode"}]},{"objectLabel":"Installed Product","objectAPIName":"SVMXDEV__Installed_Product__c","fields":[{"fieldLabel":"Last Date Shipped","fieldAPIName":"SVMXDEV__Last_Date_Shipped__c"},{"fieldLabel":"Status","fieldAPIName":"SVMXDEV__Status__c"},{"fieldLabel":"Date Shipped","fieldAPIName":"SVMXDEV__Date_Shipped__c"},{"fieldLabel":"Asset Tag","fieldAPIName":"SVMXDEV__Asset_Tag__c"},{"fieldLabel":"Distributor Contact","fieldAPIName":"SVMXDEV__Distributor_Contact__c"},{"fieldLabel":"Created By ID","fieldAPIName":"CreatedById"},{"fieldLabel":"Last Activity Date","fieldAPIName":"LastActivityDate"},{"fieldLabel":"Service Contract Start Date","fieldAPIName":"SVMXDEV__Service_Contract_Start_Date__c"},{"fieldLabel":"Warranty","fieldAPIName":"SVMXDEV__Warranty__c"},{"fieldLabel":"Deleted","fieldAPIName":"IsDeleted"},{"fieldLabel":"Country","fieldAPIName":"SVMXDEV__Country__c"},{"fieldLabel":"System Modstamp","fieldAPIName":"SystemModstamp"},{"fieldLabel":"Parent","fieldAPIName":"SVMXDEV__Parent__c"},{"fieldLabel":"Product Name","fieldAPIName":"SVMXDEV__Product_Name__c"},{"fieldLabel":"Service Contract Line","fieldAPIName":"SVMXDEV__Service_Contract_Line__c"},{"fieldLabel":"Latitude","fieldAPIName":"SVMXDEV__Latitude__c"},{"fieldLabel":"Preferred Technician","fieldAPIName":"SVMXDEV__Preferred_Technician__c"},{"fieldLabel":"Date Installed","fieldAPIName":"SVMXDEV__Date_Installed__c"},{"fieldLabel":"Created Date","fieldAPIName":"CreatedDate"},{"fieldLabel":"Owner ID","fieldAPIName":"OwnerId"},{"fieldLabel":"Last Viewed Date","fieldAPIName":"LastViewedDate"},{"fieldLabel":"IsSwapped","fieldAPIName":"SVMXDEV__IsSwapped__c"},{"fieldLabel":"Business Hours (Do Not Use)","fieldAPIName":"SVMXDEV__Business_Hours__c"},{"fieldLabel":"Last Modified By ID","fieldAPIName":"LastModifiedById"},{"fieldLabel":"Sub Location","fieldAPIName":"SVMXDEV__Sub_Location__c"},{"fieldLabel":"Warranty Exchange Type","fieldAPIName":"SVMXDEV__Warranty_Exchange_Type__c"},{"fieldLabel":"Date Ordered","fieldAPIName":"SVMXDEV__Date_Ordered__c"},{"fieldLabel":"Distributor Account","fieldAPIName":"SVMXDEV__Distributor_Company__c"},{"fieldLabel":"Account","fieldAPIName":"SVMXDEV__Company__c"},{"fieldLabel":"Top-Level","fieldAPIName":"SVMXDEV__Top_Level__c"},{"fieldLabel":"Last Modified Date","fieldAPIName":"LastModifiedDate"},{"fieldLabel":"Record ID","fieldAPIName":"Id"},{"fieldLabel":"Service Contract Exchange Type","fieldAPIName":"SVMXDEV__Service_Contract_Exchange_Type__c"},{"fieldLabel":"Last Referenced Date","fieldAPIName":"LastReferencedDate"},{"fieldLabel":"Service Contract End Date","fieldAPIName":"SVMXDEV__Service_Contract_End_Date__c"},{"fieldLabel":"State","fieldAPIName":"SVMXDEV__State__c"},{"fieldLabel":"Longitude","fieldAPIName":"SVMXDEV__Longitude__c"},{"fieldLabel":"Street","fieldAPIName":"SVMXDEV__Street__c"},{"fieldLabel":"Installed Product ID","fieldAPIName":"Name"},{"fieldLabel":"Location","fieldAPIName":"SVMXDEV__Site__c"},{"fieldLabel":"Access Hours","fieldAPIName":"SVMXDEV__Access_Hours__c"},{"fieldLabel":"Zip","fieldAPIName":"SVMXDEV__Zip__c"},{"fieldLabel":"Contact","fieldAPIName":"SVMXDEV__Contact__c"},{"fieldLabel":"Warranty Start Date","fieldAPIName":"SVMXDEV__Warranty_Start_Date__c"},{"fieldLabel":"Alternate Account","fieldAPIName":"SVMXDEV__Alternate_Company__c"},{"fieldLabel":"Installation Notes","fieldAPIName":"SVMXDEV__Installation_Notes__c"},{"fieldLabel":"Product","fieldAPIName":"SVMXDEV__Product__c"},{"fieldLabel":"Sales Order Number","fieldAPIName":"SVMXDEV__Sales_Order_Number__c"},{"fieldLabel":"Service Contract","fieldAPIName":"SVMXDEV__Service_Contract__c"},{"fieldLabel":"Serial/Lot Number","fieldAPIName":"SVMXDEV__Serial_Lot_Number__c"},{"fieldLabel":"ProductIQ Template","fieldAPIName":"SVMXDEV__ProductIQTemplate__c"},{"fieldLabel":"City","fieldAPIName":"SVMXDEV__City__c"},{"fieldLabel":"Warranty End Date","fieldAPIName":"SVMXDEV__Warranty_End_Date__c"}]}],"installigenceLogos":[{"uniqueName":"Default","name":"Default","logoId":"015F0000004DdLHIA0"},{"uniqueName":"Electric_Solutions","name":"Electric Solutions","logoId":"015F0000004DionIAC"},{"uniqueName":"Energy_Efficiency","name":"Energy Efficiency","logoId":"015F0000004DiosIAC"},{"uniqueName":"Multitech","name":"Multitech","logoId":"015F0000004DioxIAC"},{"uniqueName":"Residential_Electric_Unit","name":"Residential Electric Unit","logoId":"015F0000004Dip2IAC"},{"uniqueName":"Smart_Technology","name":"Smart Technology","logoId":"015F0000004Dip7IAC"}],"ibValueMaps":[{"valueMapName":"Deinstall_PRIQ","id":"a12F00000047FPxIAM"},{"valueMapName":"Installed_PRIQ","id":"a12F00000047PFSIA2"},{"valueMapName":"InTransit_PRIQ","id":"a12F00000047IfCIAU"},{"valueMapName":"KKG_Mapps_Ins_to_Ins","id":"a12F0000003Ap9kIAC"},{"valueMapName":"MAP043V","id":"a12F0000002KDk0IAG"},{"valueMapName":"MAP043V2","id":"a12F000000460PQIAY"}],"ibTemplates":[{"templateName":"ProductIQ Template Tue Feb 03 2015 12:21:35 GMT+0530 (India Standard Time)","templateId":"ProductIQ_Template_1422946296","template":{"type":null,"text":null,"templateDetails":null,"product":null,"children":[{"type":"root","text":"ProductIQ Template Tue Feb 03 2015 12:21:35 GMT+0530 (India Standard Time)","templateDetails":{"templateName":"ProductIQ Template Tue Feb 03 2015 12:21:35 GMT+0530 (India Standard Time)","templateId":"ProductIQ_Template_1422946296","subLocationText":"","locationText":"","ibText":""},"product":null,"children":[{"type":"product","text":"prodPR1","templateDetails":null,"product":{"productId":"01tF0000003sbI7IAI","productIcon":"Electric_Solutions","productDefaultValues":"MAP043V","productConfiguration":[],"product":"prodPR1","oldProductValueMap":"MAP043V","newProductValueMap":"MAP043V2"},"children":null}]}]},"sfdcId":null,"mappings":null}]}
            responder.result(result); */           
            InstalligenceSetupJsr.JsrGetSetupMetadata(requestData, function(result, evt){				
                responder.result(result);
            }, this);
        }

    }, {});
	
	installigenceadminoperations.Class("SaveSetupData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
        	var requestData = {
        			profiles: request.profiles,
        			templates: request.ibTemplates,
        			delTemplateIds: request.delTemplateIds,
                    technicalAttributesTemplate: request.taTemplateConfiguration,
                    taDeletedTemplateIds: request.taDeletedTemplateIds,
                    isValideTAtemplate: request.isValideTAtemplate,
                    deletedTACriteriaIds: request.deletedTACriteriaIds
            };
        	/*var result = {};
        	//result = {"profiles":[{"profileName":"US Technician","profileId":"ustechnician","filters":[{"name":"Installed and In Warranty","isGlobal":true,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":null}},{"name":"Transit Return","isGlobal":false,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":null}}],"actions":[{"parentProfileId":null,"name":"Tech1","isGlobal":false,"actionType":"Field Map","action":"MAP001"}]},{"profileName":"US Manager","profileId":"ustechmanager","filters":[{"name":"Installed and In Warranty","isGlobal":true,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":null}},{"name":"Transit Return","isGlobal":false,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":null}}],"actions":[{"parentProfileId":null,"name":"Tech1","isGlobal":false,"actionType":"Field Map","action":"MAP001"}]}]};
        	result = {"profiles":[{"profileName":"US Technician","profileId":"ustechnician","filters":[{"name":"vvb","isGlobal":null,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":[{"value":"","operator":"vvb","field":"","exprType":"root","condition":"","children":[{"value":"","operator":"And","field":"","exprType":"operatorroot","condition":"","children":[{"value":"23","operator":"","field":"Field 2 Label","exprType":"expression","condition":"Includes","children":null}]}]}]}},{"name":"vvvg","isGlobal":null,"expression":{"value":null,"operator":null,"field":null,"exprType":null,"condition":null,"children":[{"value":"","operator":"vvvg","field":"","exprType":"root","condition":"","children":[{"value":"","operator":"And","field":"","exprType":"operatorroot","condition":"","children":null}]}]}}],"actions":[]},{"profileName":"US Manager","profileId":"ustechmanager","filters":[],"actions":[]}],
        	"templates":[{"templateName":"--None--","template":null},{"templateName":"Elevator - BUL1","template":{"type":"root","text":"Template Name","product":null,"children":[{"type":"product","text":"simultaneous Inventory Update","product":{"productIcon":null,"productDefaultValues":null,"productConfiguration":[],"product":"simultaneous Inventory Update","oldProductValueMap":null,"newProductValueMap":null},"children":[{"type":"product","text":"Laptop","product":{"productIcon":null,"productDefaultValues":null,"productConfiguration":null,"product":null,"oldProductValueMap":null,"newProductValueMap":null},"children":null}]}]}},{"templateName":"Elevator - BUL2","template":{"type":"root","text":"Template Name","product":null,"children":null}}]};
        	responder.result(result);*/
        	
        	InstalligenceSetupJsr.JsrSaveSetupData(requestData, function(result, evt){				
                responder.result(result);
            }, this);
        }

    }, {});	
	
    installigenceadminoperations.Class("BackToSetupHome", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var requestData = {};
            
            InstalligenceSetupJsr.JsrBackToSetupHome(requestData, function(result, evt){              
                
            }, this);
        }

    }, {});

	installigenceadminoperations.Class("GetTemplateFromIB", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
        	var requestData = {
        			InstalledProductId: request.topLevelIB
            };
        	var result = {};
        	
        	InstalligenceSetupJsr.JsrGetTemplateFromIB(requestData, function(result, evt){				
                responder.result(result);
            }, this);
        }

    }, {});	
	
	installigenceadminoperations.Class("GetTopLevelIBs", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
        	
        	var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
				sRequest.bind("REQUEST_COMPLETED", function(evt){

					if(module.checkResponseStatus("GetTopLevelIBs", evt.data, false, this) == true){
						responder.result(evt.data.records);
					}
				}, this);
				
				sRequest.bind("REQUEST_ERROR", function(evt){

					if(module.checkResponseStatus("GetTopLevelIBs", evt.data, false, this) == true){
						responder.result([]);//{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sbIbIAI"},"Id":"01tF0000003sbIbIAI","Name":"prodPR1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sZoWIAU"},"Id":"01tF0000003sZoWIAU","Name":"Laptop"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sbI7IAI"},"Id":"01tF0000003sbI7IAI","Name":"prodPR1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sbIWIAY"},"Id":"01tF0000003sbIWIAY","Name":"prodPR1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sbIRIAY"},"Id":"01tF0000003sbIRIAY","Name":"prodPR1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003t6XtIAI"},"Id":"01tF0000003t6XtIAI","Name":"Test's Prod"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003tABvIAM"},"Id":"01tF0000003tABvIAM","Name":"Charger"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sbICIAY"},"Id":"01tF0000003sbICIAY","Name":"prodPR1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003t1igIAA"},"Id":"01tF0000003t1igIAA","Name":"SmartPhone"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sREKIA2"},"Id":"01tF0000003sREKIA2","Name":"saProd1"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003tAC0IAM"},"Id":"01tF0000003tAC0IAM","Name":"Battery"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003tABlIAM"},"Id":"01tF0000003tABlIAM","Name":"Laptopset"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003t3NmIAI"},"Id":"01tF0000003t3NmIAI","Name":"OptiPlex 320"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sdRMIAY"},"Id":"01tF0000003sdRMIAY","Name":"newProductforINVT"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sSJwIAM"},"Id":"01tF0000003sSJwIAM","Name":"INVT_Product"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003tABqIAM"},"Id":"01tF0000003tABqIAM","Name":"Laptop"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003Ono6IAC"},"Id":"01tF0000003Ono6IAC","Name":"GenWatt Diesel 200kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003Ono7IAC"},"Id":"01tF0000003Ono7IAC","Name":"Coffee beans"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003Ono8IAC"},"Id":"01tF0000003Ono8IAC","Name":"Installation: Industrial - High"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003Ono9IAC"},"Id":"01tF0000003Ono9IAC","Name":"SLA: Silver"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoAIAS"},"Id":"01tF0000003OnoAIAS","Name":"GenWatt Propane 500kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoBIAS"},"Id":"01tF0000003OnoBIAS","Name":"SLA: Platinum"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoCIAS"},"Id":"01tF0000003OnoCIAS","Name":"GenWatt Propane 100kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoDIAS"},"Id":"01tF0000003OnoDIAS","Name":"GenWatt Propane 1500kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoEIAS"},"Id":"01tF0000003OnoEIAS","Name":"Coffee machine Filter"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoFIAS"},"Id":"01tF0000003OnoFIAS","Name":"SLA: Bronze"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoGIAS"},"Id":"01tF0000003OnoGIAS","Name":"GenWatt Gasoline 750kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoHIAS"},"Id":"01tF0000003OnoHIAS","Name":"Installation: Portable"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoIIAS"},"Id":"01tF0000003OnoIIAS","Name":"SLA: Gold"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoJIAS"},"Id":"01tF0000003OnoJIAS","Name":"GenWatt Gasoline 300kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoKIAS"},"Id":"01tF0000003OnoKIAS","Name":"Installation: Industrial - Low"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoLIAS"},"Id":"01tF0000003OnoLIAS","Name":"GenWatt Gasoline 2000kW"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003OnoMIAS"},"Id":"01tF0000003OnoMIAS","Name":"Installation: Industrial - Medium"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sW2RIAU"},"Id":"01tF0000003sW2RIAU","Name":"InvSerial"},{"attributes":{"type":"Product2","url":"/services/data/v24.0/sobjects/Product2/01tF0000003sW2WIAU"},"Id":"01tF0000003sW2WIAU","Name":"InvNonSerial"}]);
					}
				}, this);
				
				var query = encodeURI("select id, Name from "+ SVMX.OrgNamespace + "__Installed_Product__c where " + SVMX.OrgNamespace + "__Top_Level__c = ''");
				
				sRequest.callApiAsync({url : "query?q=" + query});
			}, context : this}, this);  
        	
        }

    }, {});	

    installigenceadminoperations.Class("GetAllProducts", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){

                    if(module.checkResponseStatus("GetAllProducts", evt.data, false, this) == true){
                        responder.result(evt.data.records);
                    }
                }, this);
                
                sRequest.bind("REQUEST_ERROR", function(evt){

                    if(module.checkResponseStatus("GetAllProducts", evt.data, false, this) == true){
                        responder.result([]);
                    }
                }, this);
                
                var query = encodeURI("SELECT Id,Name FROM Product2 where Name LIKE '%"+request.text +"%'");
                
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        }

    }, {}); 
installigenceadminoperations.Class("GetAllTechnicalAttributesTemplates", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){

                    if(module.checkResponseStatus("GetAllTechnicalAttributesTemplates", evt.data, false, this) == true){
                        responder.result(evt.data.records);
                    }
                }, this);
                
                sRequest.bind("REQUEST_ERROR", function(evt){

                    if(module.checkResponseStatus("GetAllTechnicalAttributesTemplates", evt.data, false, this) == true){
                        responder.result([]);
                    }
                }, this);
                
                 var query = encodeURI('SELECT Id,Name,'+SVMX.OrgNamespace+'__SM_Template_Json__c,'+SVMX.OrgNamespace+'__SM_Attr_Type_Template__c,'+SVMX.OrgNamespace+'__SM_Template_Description__c ,'+SVMX.OrgNamespace+'__SM_Title__c FROM '+ SVMX.OrgNamespace+"__SM_Attributes_Template__c where " +SVMX.OrgNamespace+"__SM_Title__c   LIKE  '%"+request.text+ "%' " +' OR ' +SVMX.OrgNamespace+"__SM_Template_Description__c   LIKE  '%"+request.text+ "%'  ORDER BY LastModifiedDate DESC limit 10 offset " + request.templateOffset ); 
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        } 

    }, {});
installigenceadminoperations.Class("GetTemplateCount", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){

                    if(module.checkResponseStatus("GetTemplateCount", evt.data, false, this) == true){
                        responder.result(evt.data.totalSize);
                    }
                }, this);
                
                sRequest.bind("REQUEST_ERROR", function(evt){

                    if(module.checkResponseStatus("GetTemplateCount", evt.data, false, this) == true){
                        responder.result([]);
                    }
                }, this);
                
                 var query = encodeURI('SELECT Count() from '+SVMX.OrgNamespace+'__SM_Attributes_Template__c where '+SVMX.OrgNamespace+"__SM_Title__c LIKE '%"+request.text+"%'" );
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        } 

    }, {});

installigenceadminoperations.Class("GetTechnicalAttributesTemplateCriteria", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){

                    if(module.checkResponseStatus("GetTechnicalAttributesTemplateCriteria", evt.data, false, this) == true){
                        responder.result(evt.data.records);
                    }
                }, this);
                
                sRequest.bind("REQUEST_ERROR", function(evt){

                    if(module.checkResponseStatus("GetTechnicalAttributesTemplateCriteria", evt.data, false, this) == true){
                        responder.result([]);
                    }
                }, this);
                
                var productAttributeObject = SVMX.OrgNamespace+'__SM_Product_Attributes__c';

                 var query = encodeURI('SELECT Id,Name,'+SVMX.OrgNamespace+'__SM_Product__r.Name,'+SVMX.OrgNamespace+'__SM_Product__c,'+SVMX.OrgNamespace+'__SM_Product_Code__c,'+SVMX.OrgNamespace+'__SM_Product_Family__c ,'+SVMX.OrgNamespace+'__SM_Product_Line__c FROM '+ SVMX.OrgNamespace+'__SM_Product_Attributes__c where '+ SVMX.OrgNamespace+'__SM_Attribute_Template_Id__c = '+"'"+request.taTemplateId+"' ORDER BY LastModifiedDate DESC" );
                //var query = encodeURI('SELECT '+productAttributeObject+'.Id, '+productAttributeObject+'.Name, '+productAttributeObject+'.'+SVMX.OrgNamespace+'__SM_Product__c, '+productAttributeObject+'.'+SVMX.OrgNamespace+'__SM_Product_Line__c, '+productAttributeObject+'.'+SVMX.OrgNamespace+'__SM_Product_Family__c, Product2Object.Name as productName FROM '+productAttributeObject+' LEFT JOIN Product2 as Product2Object ON '+productAttributeObject+'.'+SVMX.OrgNamespace+'__SM_Product__c = Product2Object.Id where '+productAttributeObject+'.'+SVMX.OrgNamespace+'__SM_Attribute_Template_Id__c = '+"'"+request.taTemplateId+"'");
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        } 

    }, {});

installigenceadminoperations.Class("GetAllTAPicklistDefination", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){

                    if(module.checkResponseStatus("GetAllTAPicklistDefination", evt.data, false, this) == true){
                        responder.result(evt.data.records);
                    }
                }, this);
                
                sRequest.bind("REQUEST_ERROR", function(evt){

                    if(module.checkResponseStatus("GetAllTAPicklistDefination", evt.data, false, this) == true){
                        responder.result([]);
                    }
                }, this);
                
                var query = encodeURI('SELECT Id,'+SVMX.OrgNamespace+'__SM_Name__c,'+SVMX.OrgNamespace+'__SM_Description__c,'+SVMX.OrgNamespace+'__SM_Values__c  FROM '+ SVMX.OrgNamespace+'__SM_TA_Picklist_Definition__c');
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        } 

    }, {});

installigenceadminoperations.Class("SavePicklistData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
           var requestObject = {
                sfdcId : request.sfid,
                name : request.name,
                description : request.description,
                picklistValues : request.values
            };
            InstalligenceSetupJsr.JsrSaveTechnicalAttributePicklistDefinition(requestObject, function(result, evt){              
                responder.result(result);
            }, this);
        }

    }, {}); 

installigenceadminoperations.Class("DeletePicklistData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var picklistId =  request.sfid;
            InstalligenceSetupJsr.JsrDeleteTechnicalAttributePicklistDefinition(picklistId, function(result, evt){ 
                responder.result(result);
            }, this);
        }

    }, {}); 

};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\layoutAndAction.js
/**
 *  LayoutAndAction.
 * @class com.servicemax.client.insralligence.admin.layoutAndAction.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/

  (function(){

	var layoutAndAction = SVMX.Package("com.servicemax.client.installigence.admin.layoutAndAction");
	layoutAndAction.init = function() {

		Ext.define("com.servicemax.client.installigence.admin.LayoutAndAction", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
			__root: null, __none: null,
	         constructor: function(config) {
	         	var me = this;
	         	this.__none = "--None--";
	         	config = config || {};
				config.items = [];
				config.title = $TR.LAYOUT_AND_ACTION;
				config.id = "layoutAndAction";
				this.__root = config.root;
				this.__registerForDidProfileSelectCall();
				me.showProfiles = config.root.showProfiles;
				var availableIbProcesData = [{sfdcId:this.__none, processId: this.__none, processName: $TR.NONE}].concat(config.metadata.availableIBEditProcess);
				var availableLocationProcesData = [{sfdcId:this.__none, processId: this.__none, processName: $TR.NONE}].concat(config.metadata.availableLocationEditProcess);

				 me.availableIbProcesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['processId', 'processName', 'sfdcId'],
			        data: availableIbProcesData
			    });

				  me.availableLocationProcesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['processId', 'processName', 'sfdcId'],
			        data: availableLocationProcesData
			    });

				  me.showIbProcess = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_SFM_FOR_OVERVIEW_LAYOUT +' <span class="req" style="color:red">*</span>',
			        store: me.availableIbProcesStore,
			        labelWidth: 300,
			        width: 600,
			        displayField: 'processName',
			        valueField:'sfdcId',
			        queryMode: 'local',
			        editable: false,
			        disabled: true,
			        margin:'20 0 50 30',
			        listeners: {
			        	select: {
			        		fn: me.__persistIBProcessData,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('sfdcId'));
						}
			        }
				});

				  me.showLocationProcess = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_SFM_FOR_OVERVIEW_LAYOUT +' <span class="req" style="color:red">*</span>',
			        store: me.availableLocationProcesStore,
			        labelWidth: 300,
			        width: 600,
			        displayField: 'processName',
			        valueField:'sfdcId',
			        queryMode: 'local',
			        editable: false,
			        disabled: true,
			        margin:'20 0 10 30',
			        listeners: {
			        	select: {
			        		fn: me.__persistLocationProcessData,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('sfdcId'));
						}
			        }
				});


				

				 me.ibTitleLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        text: $TR.INSTALLED_PRODUCT,
			         margin:'20 0 10 10',
			       
			        
			    };
			    me.locationTitleLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        text: $TR.LOCATION,
			        margin:'20 0 10 10',
			       
			        
			    };

			    me.serviceFlowWizardDisplayTitle = {
			    	xtype : 'label',
			    	cls : 'piq-setup-service-flow-wizard-display',
			    	forId : 'myFieldId',
			    	text : $TR.SERVICE_FLOW_WIZARD_DISPLAY,
			    	margin : '40 0 10 10'
			    };

			    me.checkboxFieldForIB = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.ENABLE_OPEN_TREE_VIEW_ON_IB,
			         cls : 'piq-setup-layout-checkbox',
			         margin :'20 0 10 10',
			         scope: me,
			         id : 'InstalledBaseOpenTreeViewAction',
			         checked   : true,
			         disabled: true,
			         handler: function(field, value) {
			         	me.__shouldEnableOpenTreeViewActionForProfile(field,value,me);
			         }
			     });

			    me.checkboxFieldForLocation = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.ENABLE_OPEN_TREE_VIEW_ON_LOCATION,
			         cls : 'piq-setup-layout-checkbox',
			         margin :'10 0 10 10',
			         scope: me,
			         id : 'LocationOpenTreeViewAction',
			         checked   : true,
			         disabled: true,
			         handler: function(field, value) {
			         	me.__shouldEnableOpenTreeViewActionForProfile(field,value,me);
			         }
			     });

			    me.checkboxFieldForWO = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.ENABLE_OPEN_TREE_VIEW_ON_WO,
			         cls : 'piq-setup-layout-checkbox',
			         margin :'10 0 10 10',
			         id : 'WorkOrderOpenTreeViewAction',
			         scope: me,
			         checked   : true,
			         disabled: true,
			         handler: function(field, value) {
			         	me.__shouldEnableOpenTreeViewActionForProfile(field,value,me);
			         }
			     });

			    //Auto sync changes.
			    me.autoSyncTitle = {
			    	xtype : 'label',
			    	cls : 'piq-setup-service-flow-wizard-display',
			    	forId : 'myFieldId',
			    	text : $TR.AUTO_SYNC_TITLE,
			    	margin : '40 0 10 10'
			    };

			    me.checkboxFieldForAutoSync = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.AUTO_SYNC_CHECKBOX_TITLE,
			         cls : 'piq-setup-layout-checkbox',
			         margin :'10 0 10 10',
			         id : 'AutoSyncId',
			         scope: me,
			         checked   : true,
			         disabled: true,
			         handler: function(field, value) {
			         	me.__shouldEnableAutoSyncForProfile(field,value,me);
			         }
			     });

			    

			    config.items.push(me.ibTitleLabel);
			    config.items.push(me.showIbProcess);
			    config.items.push(me.locationTitleLabel);
			    config.items.push(me.showLocationProcess);
			    config.items.push(me.serviceFlowWizardDisplayTitle);
			    config.items.push(me.checkboxFieldForIB);
			    config.items.push(me.checkboxFieldForLocation);
			    config.items.push(me.checkboxFieldForWO);
			    config.items.push(me.autoSyncTitle);
			    config.items.push(me.checkboxFieldForAutoSync);


				this.callParent([config]);
			},

			__shouldEnableOpenTreeViewActionOnProfileSelection : function() {
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				var serviceFlowWizardRecord = {};
				if(this.showProfiles.selectedProfile !== undefined) {
					if(selecetedProfile.getData().serviceFlowWizardDisplay == undefined){
						selecetedProfile.set("serviceFlowWizardDisplay", []);
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForInstallBase = true;
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForLocation = true;
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForWO = true;
						this.checkboxFieldForIB.setValue(true);
						this.checkboxFieldForLocation.setValue(true);
						this.checkboxFieldForWO.setValue(true);
						selecetedProfile.set("serviceFlowWizardDisplay", serviceFlowWizardRecord);
					} else {
						serviceFlowWizardRecord = selecetedProfile.get('serviceFlowWizardDisplay');
						this.checkboxFieldForIB.setValue(serviceFlowWizardRecord.isOpenTreeViewActionEnabledForInstallBase); ;
						this.checkboxFieldForLocation.setValue(serviceFlowWizardRecord.isOpenTreeViewActionEnabledForLocation);
						this.checkboxFieldForWO.setValue(serviceFlowWizardRecord.isOpenTreeViewActionEnabledForWO);
					}
				} else {
					selecetedProfile.set("serviceFlowWizardDisplay", {});
				}
				
			},

			__shouldEnableOpenTreeViewActionForProfile : function(field,isEnabled,context){
				var selecetedProfile = context.showProfiles.getSelectedRecord();
				var serviceFlowWizardRecord = {};
				if(selecetedProfile.getData().serviceFlowWizardDisplay == undefined){
					selecetedProfile.set("serviceFlowWizardDisplay", {});
				} else {
					serviceFlowWizardRecord = selecetedProfile.get('serviceFlowWizardDisplay');
				}
				
				switch(field.id) {
					case  "InstalledBaseOpenTreeViewAction" : {
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForInstallBase = isEnabled;
					}
					break;

					case "LocationOpenTreeViewAction" : {
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForLocation = isEnabled;
					}
					break;

					case "WorkOrderOpenTreeViewAction" : {
						serviceFlowWizardRecord.isOpenTreeViewActionEnabledForWO = isEnabled;
					}
					break;
				}
				selecetedProfile.set("serviceFlowWizardDisplay", serviceFlowWizardRecord);
				
			},

			__shouldEnableAutoSyncForProfile : function(field,isEnabled,context) {
				var selecetedProfile = context.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().isAutoSyncEnabled === undefined || selecetedProfile.getData().isAutoSyncEnabled === 'false'){
					selecetedProfile.set("isAutoSyncEnabled", "false");
				}
				selecetedProfile.set("isAutoSyncEnabled", isEnabled);
			},

			__persistAutoSyncCheckboxValue:function(combo, record){
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				var serviceFlowWizardRecord = {};
				if(this.showProfiles.selectedProfile !== undefined) {
					if(selecetedProfile.getData().isAutoSyncEnabled == undefined){
						this.checkboxFieldForAutoSync.setValue(true);
					} else {
						const autoSyncFlag = selecetedProfile.get('isAutoSyncEnabled');
						if (autoSyncFlag === false || autoSyncFlag === 'false') {
							this.checkboxFieldForAutoSync.setValue(false);
						} else {
							this.checkboxFieldForAutoSync.setValue(true);
						}
					}
				} 

				selecetedProfile.set("isAutoSyncEnabled", this.checkboxFieldForAutoSync.getValue());
			},

	
			__persistIBProcessData: function(combo, record){

				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().ibEditProces == undefined){
					selecetedProfile.set("ibEditProces", []);
				}


				if(this.showProfiles.getSelectedRecord() !== undefined &&
					this.showProfiles.getSelectedRecord().get("processName") !== this.__none){

					var selectedIbPrcocessRec = combo.getSelectedRecord().data;
					var finalIbProcessRec = {};
						if(selectedIbPrcocessRec){
							finalIbProcessRec.objectName = selectedIbPrcocessRec.objectName;
							finalIbProcessRec.processId = selectedIbPrcocessRec.processId;
							finalIbProcessRec.processName = selectedIbPrcocessRec.processName;
							finalIbProcessRec.sfdcId = selectedIbPrcocessRec.sfdcId;
						}

					selecetedProfile.set("ibEditProces", [finalIbProcessRec]);
					
				}else{
					selecetedProfile.set("ibEditProces", []);
				}
			},
			__persistLocationProcessData: function(combo, record){

				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().locationEditProces == undefined){
					selecetedProfile.set("locationEditProces", []);
				}

				if(this.showProfiles.getSelectedRecord() !== undefined &&
					this.showProfiles.getSelectedRecord().get("processName") !== this.__none){

					var selectedLocationPrcocessRec = combo.getSelectedRecord().data;
					var finalLocationProcessRec = {};
						if(selectedLocationPrcocessRec){
							finalLocationProcessRec.objectName = selectedLocationPrcocessRec.objectName;
							finalLocationProcessRec.processId = selectedLocationPrcocessRec.processId;
							finalLocationProcessRec.processName = selectedLocationPrcocessRec.processName;
							finalLocationProcessRec.sfdcId = selectedLocationPrcocessRec.sfdcId;
						}
						selecetedProfile.set("locationEditProces", [finalLocationProcessRec]);
					
				}else{
					selecetedProfile.set("locationEditProces", []);
				}


			},
			__onSelectProfile: function(combo, record){
				this.showIbProcess.setValue(this.__none);
				this.showLocationProcess.setValue(this.__none);
				
				if(combo.getSelectedRecord().get("profileId") == this.__none){
					this.showIbProcess.setDisabled(true);
					this.showLocationProcess.setDisabled(true);
					this.checkboxFieldForIB.setDisabled(true);
					this.checkboxFieldForLocation.setDisabled(true);
					this.checkboxFieldForWO.setDisabled(true);
					this.checkboxFieldForIB.setValue(true);
					this.checkboxFieldForLocation.setValue(true);
					this.checkboxFieldForWO.setValue(true);
					this.checkboxFieldForAutoSync.setDisabled(true);
					this.checkboxFieldForAutoSync.setValue(true);
					this.showProfiles.selectedProfile = undefined;
				}else{
					this.showIbProcess.setDisabled(false);
					this.showLocationProcess.setDisabled(false);
					this.checkboxFieldForIB.setDisabled(false);
					this.checkboxFieldForLocation.setDisabled(false);
					this.checkboxFieldForWO.setDisabled(false);
					this.checkboxFieldForAutoSync.setDisabled(false);
 					this.showProfiles.selectedProfile = record;

					var selectedIbProcess;
					var selectedIBProcessName = '';
					var selectedLocationProcessName = '';
					
					var selectedLocationProcess ;
					var __recordData = record.data;
					(!__recordData.ibEditProces || __recordData.ibEditProces.length == 0) ? selectedIbProcess = this.__getStandardIBProcess('sfdcId'): selectedIbProcess = __recordData.ibEditProces[0].sfdcId;
					(!__recordData.locationEditProces || __recordData.locationEditProces.length == 0) ? selectedLocationProcess = this.__getStandardLocationProcess('sfdcId'): selectedLocationProcess = __recordData.locationEditProces[0].sfdcId;

					(!__recordData.ibEditProces || __recordData.ibEditProces.length == 0) ? selectedIBProcessName = this.__getStandardIBProcess('processId'): selectedIBProcessName = __recordData.ibEditProces[0].processId;
					(!__recordData.locationEditProces || __recordData.locationEditProces.length == 0) ? selectedLocationProcessName = this.__getStandardLocationProcess('processId'): selectedLocationProcessName = __recordData.locationEditProces[0].processId;


					if (selectedIbProcess != this.__none) {
						var value = this.showIbProcess.getStore().data.items.find(function(object){
							if(object.data.sfdcId == selectedIbProcess) return true;
							return false;
						});
						if (!value || value.length == 0) { //if sfdcId is null then go with processId.
							selectedIbProcess = this.__none;
							var matchedObject = this.showIbProcess.getStore().data.items.find(function(object){
								if(object.data.processId == selectedIBProcessName) return true;
								return false;
							});
							if(typeof(matchedObject) === 'object' && (matchedObject || matchedObject.data.sfdcId.length > 0 )) {
								selectedIbProcess = matchedObject.data.sfdcId;
							} 
						}
					}
					if (selectedLocationProcess != this.__none) {
						var value = this.showLocationProcess.getStore().data.items.find(function(object){
							if(object.data.sfdcId == selectedLocationProcess) return true;
							return false;
						});
						if (!value || value.length == 0) {
							selectedLocationProcess = this.__none;
							var matchedObject = this.showLocationProcess.getStore().data.items.find(function(object){
								if(object.data.processId == selectedLocationProcessName) return true;
								return false;
							});
							if(typeof(matchedObject) === 'object' && (matchedObject || matchedObject.data.sfdcId.length > 0 )) {
								selectedLocationProcess = matchedObject.data.sfdcId;
							} 

						}
					}

					this.showIbProcess.setValue(selectedIbProcess);
					this.showLocationProcess.setValue(selectedLocationProcess);

					this.__persistIBProcessData(this.showIbProcess);
					this.__persistLocationProcessData(this.showLocationProcess);
				}
				this.__shouldEnableOpenTreeViewActionOnProfileSelection();
				this.__persistAutoSyncCheckboxValue(combo,record);

			},

			__getStandardIBProcess : function(type) {
				var ibItems = this.showIbProcess.getStore().data.items,l = ibItems.length;
				var selectedIbProcess = this.__none;
				var selectedIBProcessName = this.__none;
				var standIBProcessId = "View_And_Edit_Installed_Product";
				for(var i = 0; i < l ; i++) {
					var currentItemData = ibItems[i];
					if(currentItemData.data.processId === standIBProcessId) {
						selectedIbProcess = currentItemData.data.sfdcId;
						selectedIBProcessName = currentItemData.data.processId;
						break;
					}
				}
				if(type === 'sfdcId') {
					return selectedIbProcess;
				} else {
					return selectedIBProcessName;
				}
			},

			__getStandardLocationProcess : function(type) {
				var locationItems = this.showLocationProcess.getStore().data.items,l = locationItems.length;
				var selectedLocationProcess = this.__none;
				var selectedLocationProcessName = this.__none;
				var standLocationProcessId = "View_And_Edit_Location"; 
				for(var i = 0; i < l ; i++) {
					var currentItemData = locationItems[i];
					if(currentItemData.data.processId === standLocationProcessId) {
						selectedLocationProcess = currentItemData.data.sfdcId;
						selectedLocationProcessName = currentItemData.data.processId;
						break;
					}
				}
				if(type === 'sfdcId') {
					return selectedLocationProcess;
				} else {
					return selectedLocationProcessName;
				}
				
			},

			__registerForDidProfileSelectCall: function(){
				var me = this;
	           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){

	              	 var data = SVMX.toObject(evt.data);
	            	 var combo = evt.target.result.combo;
	            	 var record = evt.target.result.record;
	            	 this.showProfiles.setRawValue(record.get('profileName'));
	          		 this.__onSelectProfile(combo, record);
					

	           }, this); 
			},

			shouldAllowToSaveConfigurationData: function(){

				if(this.showProfiles.getSelectedRecord().get("profileId") == this.__none) return true;

				
				var shouldAllowToSave = false;
				if(this.showIbProcess.getSelectedRecord() !== undefined &&
					this.showIbProcess.getSelectedRecord().get("processId") !== this.__none)
				{
					 if(this.showLocationProcess.getSelectedRecord() !== undefined &&
					this.showLocationProcess.getSelectedRecord().get("processId") !== this.__none)
					{
						shouldAllowToSave =true;
					}else
					{
						shouldAllowToSave = false;
					}
	        		
				}else
				{
					shouldAllowToSave = false;
				}

				if(shouldAllowToSave == false){
					Ext.Msg.alert({
                    title : 'Error', 
                    message : 'An overview layout needs to be selected for both Installed Product and Location',
                    buttonText : { ok : $TR.OK_BTN },
                    closable : false
                });
				}
	        	return shouldAllowToSave;
	        }
		});


	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\objectsearch.js
/**
 * 
 */
(function(){
	
	var objSearchImpl = SVMX.Package("com.servicemax.client.installigence.admin.objectsearch");

objSearchImpl.init = function(){
	
	objSearchImpl.Class("ObjectSearch", com.servicemax.client.lib.api.Object, {
		__d : null, __inited : false, __config : null,
		__objectInfo : null, __store : null, __grid : null, __win : null,
		
		__constructor : function(config){
			this.__inited = false;
			this.__config = config;
		},
		
		find : function(){
			this.__d = $.Deferred();
			
			this.__showUI();
			
			return this.__d;
		},
		
		__init : function(){
			
		},
		
		__initComplete : function(){
			this.__inited = true;
			this.__showUI();
		},
		
		__find : function(params){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN." + this.__config.mvcEvent, this, 
					{request : { context : this, handler : this.__findComplete, text : params.text}});
			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
		},
		
		__findComplete : function(data){
			this.__store.loadData(data);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__showUI : function(){
			// prepare UI
			this.__win = this.__getUI();
			this.__win.show(this.__config.sourceComponent);
			
			this.__find({});
		},
		
		__tryResolve : function(){
			var selectedRecords = this.__grid.getSelectionModel().getSelection();
        	if(selectedRecords.length == 0) return;
        	
        	var recs = [], i, l = selectedRecords.length;
        	for(i = 0; i < l; i++){
        		recs.push(selectedRecords[i].data);
        	}
        	
        	this.__d.resolve(recs);
        	this.__win.close();
		},
		
		__getUI : function(){
			
			var cols = this.__config.columns, i, l = cols.length, me = this;
			var objectDescribe = this.__config.objectDescribe, objectFields = this.__config.objectDescribe.fields;
			// store
			var fields = [];
			for(i = 0; i < l; i++){ fields.push(cols[i].name); }
			var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});
			
			//grid
			var gridColumns = [], c, j;
			for(i = 0; i < l; i++){
				c = cols[i];
				for(j = 0; j < objectFields.length; j++) {
					if(objectFields[j].fieldAPIName === c.name) {
						gridColumns.push({ text : objectFields[j].fieldLabel, dataIndex : c.name, flex : 1 });
					}
				}
								
			}

			var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
        	    store: store,
        	    selModel: {selType : 'checkboxmodel', checkOnly : true, mode : 'SINGLE'},
        	    columns: gridColumns, flex : 1, width: "100%"
        	});
			
			// searchText
        	var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
        		width: '70%', emptyText : $TR.SEARCH_EMPTY_TEXT, enableKeyEvents : true,
        		listeners : {
        			keyup : function(that, e, opts) {
        				if(e.getKey() == e.ENTER){
        					me.__find({ text : searchText.getValue()});
        				}
        			}
        		}
        	});
        	
			// window
			var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
				layout : {type : "vbox"}, height : 400, width : 700, title : objectDescribe.objectLabel,
				dockedItems : [
				    {
				    	dock: 'top', xtype: 'toolbar', margin: '0',
				    	items : [
				    	    searchText,
					       	{ xtype: 'button', text: "Go", handler : function(){
					       		me.__find({ text : searchText.getValue()});
					       	}}
				    	]
				    }
				],
				maximizable : true, items : [grid], modal : true,
				buttons : [
				    {text : $TR.CREATE, handler : function(){ me.__tryResolve(); }},
				    {text : $TR.CANCEL, handler : function(){ win.close(); }}
				]
			});
			
			this.__store = store;
			this.__grid = grid;
			return win;
		}
	}, {});
};

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\othersettings.js
(function(){
	var setupOtherSettings = SVMX.Package("com.servicemax.client.installigence.admin.othersettings");

setupOtherSettings.init = function() {
		Ext.define("com.servicemax.client.installigence.admin.OtherSettings", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
	        
	       constructor: function(config) {
	    	   
	    	   var automaticSwapProperty = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
	    		   boxLabel: $TR.OTHER_SET_SWAP_TEXT,
	    		   style: 'margin: 3px 0'					
	    	   });
	    	   config = config || {};
	    	   config.items = [];
	    	   config.items.push(automaticSwapProperty);
	    	   config.title = $TR.OTHERSETTINGS;
	    	   this.callParent([config]);
	       }
		});
	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\picklist.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\productLookup.js
/**
 *  Product lookup.
 * @class com.servicemax.client.insralligence.admin.productlookup.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/
(function(){
	
	var productLookupImpl = SVMX.Package("com.servicemax.client.installigence.admin.productLookup");

productLookupImpl.init = function(){
	
	productLookupImpl.Class("ProductLookup", com.servicemax.client.lib.api.Object, {
		__d : null, __inited : false, __config : null,
		__objectInfo : null, __store : null, __grid : null, __win : null, __searchText: null,
		
		__constructor : function(config){
			this.__inited = false;
			this.__config = config;
			this.__searchText = config.searchText;
		},
		
		find : function(){
			this.__d = $.Deferred();
			
			this.__showUI();
			
			return this.__d;
		},
		
		__init : function(){
			
		},
		
		__initComplete : function(){
			this.__inited = true;
			this.__showUI();
		},
		
		__find : function(params){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN." + this.__config.mvcEvent, this, 
					{request : { context : this, handler : this.__findComplete, text : this.searchTextBox.value}});
			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
		},
		
		__findComplete : function(data){
			this.__store.loadData(data);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__showUI : function(){
			// prepare UI
			this.__win = this.__getUI();
			this.__win.show(this.__config.sourceComponent);
			if(this.__searchText) this.searchTextBox.setValue(this.__searchText);
			this.__find({});
		},
		
		__tryResolve : function(selectedRecord){
			
        	this.__d.resolve(selectedRecord.data);
        	this.__win.close();
		},
		
		__getUI : function(){
			
			var me = this;
			var cols = this.__config.columns, i, l = cols.length, me = this;
			var objectFields = ['Name'];
			// store
			var fields = [];
			for(i = 0; i < l; i++){ fields.push(cols[i].name); }
			var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});
			
			//grid
			var gridColumns = [], c, j;
			for(i = 0; i < l; i++){
				c = cols[i];
				for(j = 0; j < objectFields.length; j++) {
					
						gridColumns.push({ text : objectFields[j], dataIndex : c.name, flex : 1,
							renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                            } 
                        });
					
				}
								
			}

			var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
        	    store: store,
        	    cls : 'piq-setup-ta-grid',
        	   // selModel: {selType : 'checkboxmodel', checkOnly : true, mode : 'SINGLE'},
        	   viewConfig: {
                        listeners: {
                            /*select: function(dataview, record, item, index, e) {
                       		me.__tryResolve(record);

                              
                            },*/
                             itemdblclick: function(dataview, record, item, index, e) {

                             	me.__tryResolve(record);
                             }
                        }
                    },
        	    columns: gridColumns, flex : 1, width: "100%"
        	});
			
			// searchText
        	 me.searchTextBox = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
        		width: '70%', emptyText : $TR.SEARCH_EMPTY_TEXT, enableKeyEvents : true,
        		cls : 'piq-setup-ta-product-window-textfield',
        		listeners : {
        			change: {
	                        fn: me.__onTextFieldChange,
	                        scope: this,
	                        buffer: 500
	                    }
        		}
        	});
        	
			// window
			var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
				layout : {type : "vbox"}, height : 400, width : 800, title : $TR.PRODUCT_LIST,
				cls : 'piq-setup-ta-product-window-win',
				dockedItems : [
				    {
				    	dock: 'top', xtype: 'toolbar', margin: '0',
				    	items : [
				    	    me.searchTextBox, { xtype: 'button', text: $TR.GO,
				    	     handler : function(){
				    	     	me.__find();
				    	     }}
				    	]
				    }
				  
				],
				maximizable : false,closable: true, items : [grid], modal : true,
				buttons : [
				    
				    {text : $TR.CANCEL, handler : function(){ win.close(); }}
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
			
			this.__store = store;
			this.__grid = grid;
			return win;
		},

		__onTextFieldChange: function() {
	        	var value = this.searchTextBox.getValue();
	        	this.__grid.search(value);
	        	
	         }
	}, {});
};

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\producttemplates.js
(function(){
	var setupProductTemplates = SVMX.Package("com.servicemax.client.installigence.admin.producttemplates");

setupProductTemplates.init = function() {
	
		Ext.define("com.servicemax.client.installigence.admin.producttemplates.configSpecGrid", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
	        
	       constructor: function(config) {
	    	   
	    	   var config = config || {};
	    	   config.columns = [
	               {
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
		                }		
					}                  
	           ]
	    	   var me = this;
	    	   config.columns.push(this.createTextBoxColumn({text: 'Name', dataIndex: 'name', width:200}));
	    	   config.columns.push(this.createComboBoxColumn({text: 'Type', dataIndex: 'type', width:200, flex: 1}));
	    	   this.callParent([config]);
	       },
	       
	       createTextBoxColumn: function(fieldInfo) {
	    	   
	    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true
	    	   });
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(){
	               return txtboxCol;
	           };
	    	   return fieldInfo;
	       },
	       
	       createComboBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   this.options = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['Name', 'Type'],
			        data: [{ Id: 'text', Option: 'Text'},
			               { Id: 'number', Option: 'Number'}]
			   });
	    	   var optionPicklist = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					store: me.options,
			        displayField: 'Option',
			        queryMode: 'local',
			        editable: false
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.getEditor = function(){
	               return optionPicklist;
	           };
	    	   return fieldInfo;	    	   
	    	   
	       }		
		});		
		
		Ext.define("com.servicemax.client.installigence.admin.ProductTemplates", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
	        
	       constructor: function(config) {
	    	   var me = this;
	    	   var ibValueMapData = config.metadata.ibValueMaps;
	    	   var ibTemplatesData = [{templateId: "--None--", templateName: $TR.NONE}];
	    	   /*all stores goes here*/
	    	   var logosStore = me.__getInstalligenceLogosStore(config.metadata.installigenceLogos);
	    	   ibTemplatesData = ibTemplatesData.concat(config.metadata.ibTemplates);
	    	   ibDescribe = config.metadata[ SVMX.OrgNamespace + "__Installed_Product__c"];
	    	   /**/
	    	   
	    	   var ibFieldMappingsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['valueMapName', 'valueMapProcessName'],
			        data: ibValueMapData
			   });
	    	   
	    	   me.templatesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			       fields: ['templateId', 'templateName'],
			       data: ibTemplatesData
			   });
	    	   
	    	   me.deletedTemplateIds = [];
	    	   
	    	   me.showTemplates = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
	    		   fieldLabel: $TR.SELECT_TEMPLATE,
			       store: me.templatesStore,
			       labelWidth: 150,
			       displayField: 'templateName',
			       queryMode: 'local',
			       valueField: 'templateId',
			       value:'--None--',
			       selectedTemplate: undefined,
			       editable: false,
	    		   width: 400,
	    		   listeners: {
	    			   select: {
                           fn: me.__persistNLoadTemplate,
                           scope: me
                       },
                       
                       beforeselect: {
                    	   fn: me.__validateForm,
                           scope: me
                       }
                   }
	    	   });
	    	   
	    	   
	    	   me.templateActionsToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					
	    	   });	
	    	   
	    	   Ext.override(Ext.tree.View, {
	    		    collapse : function (record, deep, callback, scope) {
	    		        this.callParent(arguments);
	    		        this.refresh();
	    		    },
	    		    expand : function (record, deep, callback, scope) {
	    		        this.callParent(arguments);
	    		        this.refresh();
	    		    }       
	    		});
	    	   
	    	   //show the tree and their properties
	    	   me.templatePropertyPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
	    		   margin: '5 0 5 0',
	    		   layout: 'anchor',
	    		   cls: 'grid-panel-border',
	    		   height: 480,
	    		   flex: 1
	    	   });
	    	   
	    	   me.templateNameText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.TEMPLATE_NAME,
	    		   labelWidth: 200,
	    		   allowBlank: false,
	    		   width: 550,
	    		   listeners: {
		    		   change: function(field, value) {
		    			    me.templateTree.changeProductText(value);
		    		   }
	    		   }
	    	   });
	    	   
	    	   me.templateNameId = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.TEMPLATE_ID,
	    		   labelWidth: 200,
	    		   allowBlank: false,
	    		   width: 550
	    	   });
	    	   
	    	   me.ibNameText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.IB_DISPLAY_TEXT,
	    		   labelWidth: 200,
	    		   width: 550,
	    		   hidden: true
	    	   });
	    	   
	    	   me.locationNameText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.LOCATION_DISPLAY_TEXT,
	    		   labelWidth: 200,
	    		   width: 550,
	    		   hidden: true
	    	   });
	    	   
	    	   me.subLocationNameText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.SUB_LOCATION_DISPLAY_TEXT,
	    		   labelWidth: 200,
	    		   width: 550,
	    		   hidden: true
	    	   });
	    	   me.templatePropertyPanel.add(me.templateNameText);
	    	   me.templatePropertyPanel.add(me.templateNameId);
	    	   me.templatePropertyPanel.add(me.ibNameText);
	    	   me.templatePropertyPanel.add(me.locationNameText);
	    	   me.templatePropertyPanel.add(me.subLocationNameText);
	    	   
	    	   me.productPropertyPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
	    		   margin: '5 0 5 0',
	    		   layout: 'anchor',
	    		   cls: 'grid-panel-border',
	    		   height: 480,
	    		   flex: 1
	    	   });
	    	   
	    	   me.productNameText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXLookup',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   cls: 'svmx-lookup-field',
	    		   margin: '5, 5',
	    		   labelAlign:'right',
	    		   fieldLabel: $TR.PRODUCT,
	    		   labelWidth: 200,
	    		   width: 550,
	    		   textWidth: 500,
	    		   meta: config.metadata,
	    		   onValueSelected: function(field, value, idValue) {
	    			    me.templateTree.changeProductText(value);
	    		   }
	    	   });
	    	   
	    	   me.productIcon = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
	    		   fieldLabel: $TR.ICON,
			       store: logosStore,
			       labelWidth: 200,
			       labelAlign:'right',
			       margin: '5, 5',	    		   
			       displayField: 'name',
			       valueField: 'uniqueName',
			       queryMode: 'local',
			       editable: false,
	    		   width: 550,
	    		   listConfig: {
	    		        getInnerTpl: function() {
	    		        	var tpl = "<div style='width:100%;height:20px;' align='center'>" +	
	    		                      "<img src='/servlet/servlet.FileDownload?file={logoId}'>" +
	    		        			  "</div>" + "<div style='width:100%;height:30px;background:#f2f2f2' align='center'>" + 
	    		                      "{name}</div>";
	    		            return tpl;
	    		        }
	    		   },
	    		   listeners: {
	    			    select: function(combo, records, eOpts) {
	    			        me.templateTree.changeProductIcon(records.get('logoId'));
	    			    }
	    		   }
	    	   });
	    	   
	    	   me.productDefaultValues = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
	    		   fieldLabel: $TR.DEFAULT_VALUES,
			       store: ibFieldMappingsStore,
			       labelWidth: 200,
			       labelAlign:'right',
			       margin: '5, 5',	    		   
			       displayField: 'valueMapProcessName',
			       valueField: 'valueMapName',
			       queryMode: 'local',
			       editable: false,
	    		   width: 550
	    	   });
	    	   
	    	   Ext.define('templatemodel', {
				    extend: 'Ext.data.Model',
				    fields: [ 'text', 'type', 'product']
				});
	    	   
	    	   var store = Ext.create('Ext.data.TreeStore', {
	    		   model: templatemodel,
	    		   root: {
	    			   expanded: true,
	    			   children: [					
    			              { text: $TR.TEMPLATE_NAME, type:"root", expanded: true, iconCls: 'template-icon', templateDetails: {} }	    					
	    			   ]
	    		   }
	    	   });
	    	   
	    	   me.oldProductValueMap = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
	    		   fieldLabel: $TR.VALUE_MAP_OLD_IB,
			       store: ibFieldMappingsStore,
			       labelWidth: 200,
			       labelAlign:'right',
			       margin: '5, 5',	    		   
			       displayField: 'valueMapName',
			       valueField: 'valueMapName',
			       queryMode: 'local',
			       editable: false,
	    		   width: 545,
	    		   bind: {
	    	            store: '{store}',
	    	            selection: '{product.oldValueMap}'
	    		   }
	    	   });
	    	   
	    	   me.newProductValueMap = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
	    		   fieldLabel: $TR.VALUE_MAP_NEW_IB,
			       store: ibFieldMappingsStore,
			       labelWidth: 200,
			       labelAlign:'right',
			       margin: '5, 5',	    		   
			       displayField: 'valueMapName',
			       valueField: 'valueMapName',
			       queryMode: 'local',
			       editable: false,
	    		   width: 545
	    	   });
	    	   
	    	   var productSwapContainer = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
	    		   title: $TR.PRODUCT_SWAP,
	    		   margin: '10 5 10 5',
	    		   cls: 'grid-panel-borderless',
	    		   ui: 'svmx-gray-panel',
	    		   hidden : true
	    	   });
	    	   productSwapContainer.add(me.oldProductValueMap);
	    	   productSwapContainer.add(me.newProductValueMap);	    	   
	    	   
	    	 //the below data model have to be replaced with the actual data
	    	   me.productConfigStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
	    		   fields: ['name', 'type'],
	    		   data: []
	    	   });
	    	   
	    	   me.productConfigGrid = SVMX.create('com.servicemax.client.installigence.admin.producttemplates.configSpecGrid',{
	    		   cls: 'grid-panel-border panel-radiusless',
	    		   store: me.productConfigStore,
	    		   height: 165,
	    		   margin: '0 5 10 5',	
	    		   selType: 'cellmodel',
	    		   hidden : true,
	    		   plugins: [
			              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
			                  clicksToEdit: 2
			              })
		              	]
	    	   });
	    	   
	    	   var productConfigSpecContainer = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
	    		   margin: '10 5 0 5',
	    		   hidden: true
	    	   });
	    	   
	    	   var addTypeButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'plus-icon',
					handler : function(){
						me.productConfigGrid.addItems({});
					}
	    	   });
	    	   
	    	   var configSpecLabel = SVMX.create('com.servicemax.client.installigence.ui.components.Label',{
					text: $TR.PRODUCT_CONFIGURATION
	    	   });
	    	   productConfigSpecContainer.add(configSpecLabel);
	    	   productConfigSpecContainer.add('->');
	    	   productConfigSpecContainer.add(addTypeButton);
	    	   	    	   
	    	   me.productPropertyPanel.add(me.productNameText);
	    	   me.productPropertyPanel.add(me.productIcon);
	    	   me.productPropertyPanel.add(me.productDefaultValues);
	    	   me.productPropertyPanel.add(productSwapContainer);
	    	   me.productPropertyPanel.add(productConfigSpecContainer);
	    	   me.productPropertyPanel.add(me.productConfigGrid);
	    	   
	    	   //show the tree
	    	   me.templateTreePanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
	    		   margin: '5 7 5 0',
	    		   layout: 'anchor',
	    		   cls: 'grid-panel-border',
	    		   width: '30%',
	    		   height: 480
	    	   });	    	   
	    	   
	    	   me.templateTree = SVMX.create('com.servicemax.client.installigence.ui.components.Tree',{
	    		   cls: 'grid-panel-borderless svmx-tree-panel',
	    		   margin: '5 0 0 0',
	    		   width: '100%',
	    		   rootVisible: false,
	    		   height: 480,
	    		   store: store,
	    		   rootVisible: false,
	    		   selectedRec: undefined,
	    		   viewConfig: {
	                    listeners: {
	                        itemcontextmenu: {
	                            fn: me.onViewItemContextMenu,
	                            scope: me
	                        },
	                        
	                        itemclick: { 
	                             fn: me.onNodeClick,
	                             scope: me
	                        }
	                    }
	               },	                
	     	       changeProductIcon: function(iconId) {
	     	    	   var node = this.getSelectionModel().getSelection()[0];
	     	    	   node.set('iconCls','');
	     	    	   node.set('icon','/servlet/servlet.FileDownload?file=' + iconId);
	     	       },	                
	     	       changeProductText: function(value, idValue) {
	     	    	   var node = this.getSelectionModel().getSelection()[0];
	     	    	   node.data.text = value;
	     	    	   node.set('title', value);
	     	       }
	    	   });
	    	   
	    	   me.templateTreeSearch = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextSearch',{
					width: '97%', margin: '5 5 5 5',
					cls: 'search-textfield',
					emptyText : $TR.SEARCH_EMPTY_TEXT,
					listeners: {
	                    change: {
	                    	fn: me.onTextFieldChange,	                        
	                        scope: this,
	                        buffer: 500
	                    }
	               }
	    	   });
	    	   
	    	   me.addProduct = Ext.create('Ext.Action', {
	    		   text: $TR.ADD_PRODUCT,
	    		   iconCls: 'product-icon',
	    		   handler: function(widget, event) {
	    			   var rec = me.templateTree.getSelectionModel().getSelection()[0];
	    			   rec.appendChild({text: $TR.PRODUCT, type: "product", expanded: true, iconCls: 'product-icon', product: {}})
	    		   }
	    	   });
	    	   
	    	   me.deleteProduct = Ext.create('Ext.Action', {
	    		   text: $TR.DEL_PRODUCT,
	    		   iconCls: 'product-icon',
	    		   handler: function(widget, event) {
	    			   var rec = me.templateTree.getSelectionModel().getSelection()[0];
	    			   while(rec.firstChild) {
	    				   rec.removeChild(rec.firstChild);
	    			   }
	    			   rec.remove(true);
	    			   
	    			   me.templateTree.getStore().sync();
	    		   }
	    	   });
	    	   
	    	   me.templateTreePanel.add(me.templateTreeSearch);
	    	   me.templateTreePanel.add(me.templateTree);
	    	   
	    	   //show the properties	    	   
	    	   me.templateTreePropertiesPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
	    		   width: '100%',
	    		   style: 'margin: 3px 0',
	    		   layout: {
	    			   type: 'hbox',
	    			   align: 'strech'
    				  },
	    		   cls: 'grid-panel-borderless'	    		   
	    	   });    	   
	    	   
	    	   me.templateTreePropertiesPanel.add(me.templateTreePanel);	    	   
	    	   me.templateTreePropertiesPanel.add(me.templatePropertyPanel);
	    	   
	    	   var addTemplateButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'plus-icon',
					handler : function(){
						if(me.__validateForm() == false) return false;
						me.__addNewTemplate();
					}
	    	   });
	    	   
	    	   var delTemplateButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'delete-icon',
					handler : function(){
						me.__deleteTemplate();
					}
	    	   });
	    	   
	    	   var saveAsTemplateButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'save-as-icon'
	    	   });
	    	   
	    	   var createFromIBButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'create-from-ib-icon',
					handler: function(){
						if(me.__validateForm() == false) return false;						
						me.__createFromIB(this, me, ibDescribe);
					}
	    	   });
	    	   
	    	   me.templateActionsToolbar.add(me.showTemplates);
	    	   me.templateActionsToolbar.add('->');
	    	   me.templateActionsToolbar.add(addTemplateButton);
	    	   me.templateActionsToolbar.add(delTemplateButton);
	    	   //me.templateActionsToolbar.add(saveAsTemplateButton);
	    	   me.templateActionsToolbar.add(createFromIBButton);
	    	   config = config || {};
	    	   config.items = [];
	    	   config.items.push(me.templateActionsToolbar);
	    	   config.items.push(me.templateTreePropertiesPanel);
	    	   config.title = $TR.TEMPLATES;
	    	   this.callParent([config]);
	       },
	       
	       onViewItemContextMenu: function(dataview, record, item, index, e) {
	    	   e.stopEvent();
	    	   var me = this;
	    	   
	    	   if(record.get("type") === 'root' && record.childNodes && record.childNodes.length > 0) {
	    		   return true;
	    	   }
	    	   
	    	   contextMenu = new Ext.menu.Menu({
	    		   items: [me.addProduct]
	    		 });
	    	   if(record.get("type") === 'product') {
	    		   contextMenu = new Ext.menu.Menu({
	    			   items: [me.addProduct, me.deleteProduct]
	    		   });
	    	   }
	    	   contextMenu.showAt(e.getXY());
	    	   return true;
	       },
	       
	       onNodeClick: function(node, rec, item, index, e) {
	    	   //e.stopEvent();
	    	   if(rec.get("type") === 'product') {
	    		   this.templateTreePropertiesPanel.remove(this.templatePropertyPanel, false);
	    		   this.templateTreePropertiesPanel.add(this.productPropertyPanel);
	    	   }else if(rec.get("type") === 'root') {
	    		   this.templateTreePropertiesPanel.add(this.templatePropertyPanel);
	    		   this.templateTreePropertiesPanel.remove(this.productPropertyPanel, false);
	    	   }
    		   this.__persistNLoadProductData(rec);
	    	   return true;
	       },
	         
	       onTextFieldChange: function() {
	    	   var value = this.templateTreeSearch.getValue();
	    	   this.templateTree.search(value);
	       },
	       
	       __getInstalligenceLogosStore: function(logos) {
	    	   var data = logos;
			   var logosStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['name', 'uniqueName'],
			        data: data
			   });
			   return logosStore;
	       },
	       
	       __persistNLoadProductData: function(selectedRecord) {
	    	   //store the existing information to previous selected node
	    	   var prevSelRec = this.templateTree.selectedRec;
	    	   if(prevSelRec) {
	    		   if(prevSelRec.get("type") === "root"){
	    			   this.__persistTemplateDetails(prevSelRec);
	    		   }else {
	    			   this.__persistProductData(prevSelRec);
	    		   }    		   
	    	   }
	    	   //load the informnation to selected node
	    	   this.templateTree.selectedRec = selectedRecord;
	    	   if(selectedRecord.get("type") === "root"){
	    		   this.__loadTemplateDetails(selectedRecord);
	    	   }else {
	    		   this.__loadProductData(selectedRecord);
	    	   }
	       },
	       
	       __persistTemplateDetails: function(record) {
	    	   templInfo = {};
    		   templInfo.templateName = this.templateNameText.getValue();
    		   templInfo.templateId = this.templateNameId.getValue();
    		   templInfo.ibText = this.ibNameText.getValue();
    		   templInfo.locationText = this.locationNameText.getValue();
    		   templInfo.subLocationText = this.subLocationNameText.getValue();
    		   record.set("templateDetails", templInfo);
	    	   
	       },
	       
	       __loadTemplateDetails: function(record) {
	    	   var templInfo = record.getData().templateDetails;
	    	   if(!templInfo) {
	    		   templInfo = {};
	    	   }
	    	   this.__loadTemplateDet(templInfo);
	       },
	       
	       __loadTemplateDet: function(templInfo) {
	    	   this.templateNameId.setReadOnly(true);
	    	   if(!templInfo.templateId) {
	    		   this.templateNameId.setReadOnly(false);
	    	   }
	    	   this.templateNameText.setValue(templInfo.templateName);
    		   this.templateNameId.setValue(templInfo.templateId);
    		   this.ibNameText.setValue(templInfo.ibText);
    		   this.locationNameText.setValue(templInfo.locationText);
    		   this.subLocationNameText.setValue(templInfo.subLocationText);
	       },
	       
	       __persistProductData: function(record) {
	    	   var proInfo = record && record.getData() ? record.getData().product : undefined;
	    	   if(proInfo) {
	    		   proInfo.product = this.productNameText.getValue();
	    		   proInfo.productId = this.productNameText.getIdValue();
	    		   proInfo.productIcon = this.productIcon.getValue();
	    		   proInfo.productDefaultValues = this.productDefaultValues.getValue();
	    		   proInfo.oldProductValueMap = this.oldProductValueMap.getValue();
	    		   proInfo.newProductValueMap = this.newProductValueMap.getValue();
	    		   proInfo.productConfiguration = this.productConfigGrid.getRecords();
	    	   }	    	   
	       },
	       
	       __loadProductData: function(record) {
	    	   var proInfo = record.getData().product;
	    	   if(proInfo) {
	    		   this.productNameText.setValue(proInfo.product);
	    		   this.productNameText.setIdValue(proInfo.productId);
	    		   this.productIcon.setValue(proInfo.productIcon);
	    		   this.productDefaultValues.setValue(proInfo.productDefaultValues);
	    		   this.oldProductValueMap.setValue(proInfo.oldProductValueMap);
	    		   this.newProductValueMap.setValue(proInfo.newProductValueMap);
	    		   this.productConfigGrid.getStore().removeAll();
	    		   if(proInfo.productConfiguration && proInfo.productConfiguration.length > 0) {
	    			   this.productConfigGrid.getStore().loadData(proInfo.productConfiguration);
	    		   }	    		   
	    	   }
	       },
	       
	       __persistNLoadTemplate: function(combo, record) {
	    	   
	    	   //store the existing template information to previous selected template
	    	   var prevSelTemplate = this.showTemplates.selectedTemplate;
	    	   if(this.showTemplates.selectedTemplate && prevSelTemplate.getData().templateId !== "--None--") {
	    		   
	    		   this.__persistTemplate(prevSelTemplate);
	    	   }
	    	   //load the template information to selected template
	    	   this.showTemplates.selectedTemplate = record;
	    	   this.__loadTemplate(record.getData().template);
	       },
	       
	       __persistTemplate: function(record) {
	    	   var templateInfo = this.__getRecords(this.templateTree.getStore().getRootNode());
	    	   var templateName = this.showTemplates.selectedTemplate.getData().templateName;
	    	   var storeRec = this.showTemplates.getStore().findRecord("templateName", templateName);
	    	   if(storeRec) {
	    		   storeRec.set("template", templateInfo);
	    	   }
	       },
		   
	       __getRecords: function(rootNode) {
	    	 
	    	   return this.__getChildNodes(rootNode);
	       },
	       
	       __getChildNodes: function(node) {
	    	   
	    	   var rec = {};
	    	   
	    	   rec.text = node.getData().text;
	    	   rec.type = node.getData().type;
	    	   rec.product = node.getData().product;
	    	   rec.templateDetails = node.getData().templateDetails;
	    	   rec.expanded = true;
	    	   rec.iconCls = node.getData().iconCls;
	    	   if(node.isLeaf()) return;
	    	   
	    	   rec.children = [];
	    	   var children = node.childNodes || [], i, l = children.length;
	    	   for(i = 0; i < l; i++){
	    		   rec.children.push(this.__getChildNodes(children[i]));
	    	   }
	    	   return rec;	    	   
	       },
	       
	       __loadTemplate: function(record) {
	    	   if(record === undefined) {
	    		   record = {
	    			   expanded: true,
	    			   leaf: false,
	    			   children: [					
    			              { text: $TR.TEMPLATE_NAME, type:"root", expanded: true, iconCls: 'template-icon', templateDetails: {} }	    					
	    			   ]
	    		   }
	    	   }
	    	   
	    	   this.__loadIconClsForNodes(record.children[0]);	    	   
	    	   this.templateTree.getStore().setRootNode({
    			   expanded: true,
    			   leaf: false,
    			   children: record.children
    		   });
	    	   
	    	   this.templateTreePropertiesPanel.add(this.templatePropertyPanel);
    		   this.templateTreePropertiesPanel.remove(this.productPropertyPanel, false);
    		   this.templateTree.getStore().getRootNode().expand(true);
    		   this.templateTree.getSelectionModel().select(0);
    		   this.__loadTemplateDet(this.templateTree.getStore().getRootNode().getData().children[0].templateDetails || {});

			   this.templateTree.selectedRec = this.templateTree.getSelectionModel().getSelection()[0];
	    	   
	       },
		   
		   __loadIconClsForNodes: function(record) {
			   
			   var product = record.product;
			   productIcon = product && product.productIcon && product.productIcon !== null ? product.productIcon : undefined;
			   var productIconRec = this.productIcon.getStore().findRecord("uniqueName", productIcon);
			   record.iconCls = "product-icon";	
			   if(record.type === "root"){
				   record.iconCls = "template-icon";
			   }else if(productIconRec) {
				   record.iconCls = "";
				   record.icon = "/servlet/servlet.FileDownload?file=" + productIconRec.get("logoId");				   
			   }
			   if(record.children) {
				   var iData = 0, iLength = record.children.length || 0;
				   for(iData = 0; iData < iLength; iData++) {
					   this.__loadIconClsForNodes(record.children[iData]);
				   }
			   }
			   return record;
		   },
		   
		   __addNewTemplate: function() {
			   this.showTemplates.setValue("--None--");
			   this.templateNameId.setReadOnly(false);
			   this.showTemplates.getSelectedRecord().set("isNew", true);
			   this.__persistNLoadTemplate("", this.showTemplates.getSelectedRecord());
			   this.templateNameText.setValue("ProductIQ Template " + new Date);
			   this.templateNameId.setValue("ProductIQ_Template_" + Math.round(+new Date()/1000));
			   this.templateTree.selectedRec = this.templateTree.getSelectionModel().getSelection()[0];
		   },
		   
		   __deleteTemplate: function() {
			   var selectedRecord = this.showTemplates.getSelectedRecord();
			   var selectedTemplateId = selectedRecord.get("templateId");
			   if(selectedTemplateId === "--None--") {
				   return;			   
			   }
			   this.deletedTemplateIds.push(selectedRecord.get("templateId"));	
			   this.showTemplates.getStore().remove(selectedRecord);
			   this.showTemplates.setValue("--None--");
			   this.__loadTemplate(this.showTemplates.getSelectedRecord().template);
		   },
		   
		   __createFromIB: function(source, parent, objectDescribe) {
			   var getTopLevelIbs = SVMX.create("com.servicemax.client.installigence.admin.objectsearch.ObjectSearch", {
	                objectName :  SVMX.OrgNamespace + "__Installed_Product__c",
	                columns : [{name : "Name"}],
	                multiSelect : false,
	                sourceComponent : source,
	                objectDescribe: ibDescribe,
	                mvcEvent : "FIND_TOPLEVEL_IBS"
			   });
			   
			   getTopLevelIbs.find().done(function(results){
	               var topLevelIB = results[0].Id;
	               parent.__getTemplateForIB(topLevelIB);
			   });
		   },
		   
		   __getTemplateForIB: function(topLevelIB) {
			   var me = this;
		       	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
								"INSTALLIGENCEADMIN.GET_TEMPLATE_FROM_IB", me,
								{request : { context : me, topLevelIB : topLevelIB}});
		       	
		       	SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
		   },
		   
		   GetTemplateFromIBComplete: function(results) {
			   var results = results;
			   var record = {};
			   record.children = [];
			   var templateName = "ProductIQ Template " + new Date, templateId = "ProductIQ_Template_" + Math.round(+new Date()/1000);
			   record.children.push({ text: templateName, type:"root", expanded: true, iconCls: 'template-icon', 
				   templateDetails: {
					   templateName: templateName,
		    		   templateId: templateId
		    		   
			   }, children: [results] });
			   
			   this.showTemplates.findRecord("templateId","--None--").set("template", record);
			   this.__addNewTemplate(record);
		   },
		   
		   __validateForm: function(){
			   var isValid = true;
			   if(!this.templateNameText.getValue() || this.templateNameText.getValue().length == 0) isValid = false;
			   if(!this.templateNameId.getValue() || this.templateNameId.getValue().length == 0) isValid = false;
			   var selectedTemp = this.showTemplates.selectedTemplate;
			   if( !selectedTemp || 
					   (selectedTemp.getData().templateId == "--None--" && !selectedTemp.getData().isNew)) {
				   isValid = true;
			   }
			   if(isValid == false){
				   SVMX.getCurrentApplication().showQuickMessage("error", $TR.MANDATORY_FIELDS);
			   }			   
			   return isValid;
		   },
		   
		   validateForm: function(){
			   return this.__validateForm();
		   }
		   
	       
		});
	
	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\root.js
(function(){
	var root = SVMX.Package("com.servicemax.client.installigence.admin.root");

root.init = function() {		
	
		Ext.define("com.servicemax.client.installigence.admin.root.RootPanel", {
			extend : "com.servicemax.client.installigence.ui.components.SVMXPanel", 
			selectedProfile : null,
			selectedTab : null,
			isFilterNameEmpty : null,
			constructor : function(config){
				config = config || {};
				config.renderTo = SVMX.getDisplayRootId();		        
				config.title = "<span class='title-text'>" + $TR.SETUP_TITLE + "</span>";
				//this.selectedProfile = [{profileId: "--None--", profileName: $TR.NONE}];
				var me = this;
				this.isFilterNameEmpty = false;
				var profiles = config.metadata.svmxProfiles;
				var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				var iProfile = 0, iProfileLength = profiles.length;
				for(iProfile = 0; iProfile < iProfileLength; iProfile++) {
					if(profiles[iProfile].profileId !== 'global'){
						profilesData.push(profiles[iProfile]);
					}
				}

				me.profiles = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['profileId', 'profileName'],
			        data: profilesData
			    });

			    me.showProfiles = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_PROFILE,
			        store: me.profiles,
			        labelWidth: 140,
			        width: 450,
			        displayField: 'profileName',
			        queryMode: 'local',
			        editable: false,
			        selectedProfile: undefined,
			        cls: 'piq-setup-select-profile',
			        listeners: {
			        	select: {
			        		fn: me.__didSelectProfileWithInfo,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('profileName'));
						}
						
			        }
				});

			    me.layoutAndAction = SVMX.create('com.servicemax.client.installigence.admin.LayoutAndAction',{
					metadata: config.metadata,
					cls: 'piq-setup-layout-actions',
					id : "layoutAndAction",
					root: this
				});
				me.userActions = SVMX.create('com.servicemax.client.installigence.admin.UserActions',{
					metadata: config.metadata,
					cls: 'piq-setup-user-actions',
					id : "userActions",
					root: this
				});

				/*me.dataValidationRules = SVMX.create('com.servicemax.client.installigence.admin.DataValidationRules',{
					metadata: config.metadata,
					root: this
				});*/

				me.search = SVMX.create('com.servicemax.client.installigence.admin.Search',{
					metadata: config.metadata,
					cls: 'piq-setup-search',
					id: "search",
					root: this
				});
				
				/*me.productTemplates = SVMX.create('com.servicemax.client.installigence.admin.ProductTemplates',{
					metadata: config.metadata
				});*/
				
				me.otherSettings = SVMX.create('com.servicemax.client.installigence.admin.OtherSettings',{
					metadata: config.metadata,
					cls: 'piq-setup-other-settings',
					id:"otherSettings",
					hidden : true
				});

				me.technicalAttributes = SVMX.create('com.servicemax.client.installigence.admin.TechnicalAttributes',{
					metadata: config.metadata,
					cls: 'piq-setup-technical-attributes',
					id:"technicalAttributes",
					root: this
				});

				me.attachment = SVMX.create('com.servicemax.client.installigence.admin.Attachment',{
					metadata: config.metadata,
					cls: 'piq-setup-attachements',
					id:"attachment",
					root: this
				});
				
									
				me.tabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel',{
					height: 550,
					tabPosition: 'left',
					tabRotation: 0,
					cls : 'piq-setup-profile-body',
					tabBar: {
						border: false,
						cls : 'piq-setup-profile-nav',
						width: 200
					},
					margin: '4 4 0 4',
					ui: 'setup-tabpanel',
					defaults: {
						textAlign: 'left',
						bodyPadding: 7
					},
					listeners : {
						tabchange : function(currentTab,newCard,oldCard,eOpts) {
							me.selectedTab = currentTab.activeTab.id;
						}
					}
				});

				me.tabPanel.add(me.layoutAndAction);
				me.tabPanel.add(me.userActions);
				

				me.tabPanel.add(me.search);
				me.tabPanel.add(me.attachment);
				//me.tabPanel.add(me.productTemplates);
				me.tabPanel.add(me.otherSettings);	
				me.tabPanel.add(me.technicalAttributes);	

				// me.tabPanel.setActiveTab("layoutAndAction");
				var tabName = localStorage.piqSetuptabName;
				if(tabName) {
					me.tabPanel.setActiveTab(tabName);
					localStorage.removeItem("piqSetuptabName");
				} else {
					me.tabPanel.setActiveTab("layoutAndAction");
				}
				
				me.saveButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text: $TR.SAVE,//"Save",
					disabled:true,
					cls : 'piq-setup-save',
					rigion:'right',
					docked: 'right',
	                align: 'right',
					handler : function(){
						me.saveButton.focus();
						me.onSave();
					}
				});
				
				me.closeButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text: $TR.BACK_TO_SETUP_HOME,//"Back To Setup Home",
					cls : 'piq-setup-back-to-home',
					docked: 'left',
					rigion:'left',
	                align: 'left',
					handler : function(){
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

				var tools = [me.closeButton];	        
				config.tools = tools;

				
				me.saveCloseButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{

					text: $TR.CANCEL,//"Cancel",
					cls : 'piq-setup-cancel',
					rigion:'right',
					docked: 'right',
	                align: 'right',
					handler : function(){
						localStorage.piqSetuptabName = me.selectedTab;
						window.location.reload();
					}
				});
				
				me.savencloseToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-top-width: 0 !important',
					margin: '0 4 5',
					
	            });
				
	            var toolBarItems = ['->',me.showProfiles,me.saveButton,me.saveCloseButton];

				me.profileSelectionToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-top-width: 0 !important',
					cls: 'piq-setup-profile-selection',
					dock: 'top',
					items : toolBarItems
					
	            });

	            // me.profileSelectionToolbar.add(me.showProfiles);

				me.savencloseToolbar.add('->');

				// me.savencloseToolbar.add(me.saveButton);
				// me.savencloseToolbar.add(me.saveCloseButton);
				// me.savencloseToolbar.add(me.closeButton);

				

				
				config.items = [];
				config.items.push(me.profileSelectionToolbar);
				config.items.push(me.tabPanel);
				config.items.push(me.savencloseToolbar)
	            this.callParent([config]);
			},

			__didSelectProfileWithInfo:function(combo, record){
				 
				var me = this;
				var __shouldEnable;
				var createNewTATemplateElt = Ext.getCmp("createNewTATemplatePanel");

				if(createNewTATemplateElt.isVisible() || combo.getSelectedRecord().get("profileId") !== "--None--"){
					
					__shouldEnable = false;

				}else{

					__shouldEnable = true;
				}

				me.saveButton.setDisabled(__shouldEnable);

				this.selectedProfile = record;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "SELECTED_PROFILE_CALL",{result: {combo:combo,record:record}},
                                                             this);
                    SVMX.getClient().triggerEvent(evt);
                    

			},
			backToSetupHome: function(){
				this.blockUI();
				var me = this;
		       	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
								"INSTALLIGENCEADMIN.BACK_TO_SETUP_HOME", me,
								{request : { context : me}});
		       	SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
			},

			cancel: function(){
				var me = this;
		       	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
								"INSTALLIGENCEADMIN.GET_SETUP_METADATA", me,
								{request : { context : me}});
		       	
		       	SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
			},

			onSave: function() {
				

				var layoutShouldSaveConfigurationData = false;
				var taShouldSaveConfigurationData  = false;
				this.technicalAttributes.__templatePicklists = {}; //reset the templatepicklist.
				this.technicalAttributes.__templatePicklistSfIds = {}; //reset the templatePicklistSfIds.
				this.isFilterNameEmpty = false;

				layoutShouldSaveConfigurationData = this.layoutAndAction.shouldAllowToSaveConfigurationData();
				
				 if(layoutShouldSaveConfigurationData){
				 	taShouldSaveConfigurationData = this.technicalAttributes.shouldAllowToSaveConfigurationData();	
				 }
				 

				if(taShouldSaveConfigurationData){
					//if(this.productTemplates.validateForm() == false) return false;						
				
				//persist the existing configuration
				this.__persistScreenConfiguration();
				//var profiles = this.userActions.showProfiles.getRecords() || [];
				var profiles = [this.userActions.showProfiles.getSelectedRecord().data] || []; // As we have global profile selection for all module, save only selected profile.
				var profilesFinal = [];

				if(this.showProfiles.getSelectedRecord().get("profileId") !== "--None--"){

							var iProfiles = 0, iProfielsLength = profiles.length;

						

						for(iProfiles = 0; iProfiles < iProfielsLength; iProfiles++) {
							if(profiles[iProfiles].profileId === "--None--") continue;
							profiles[iProfiles].actions = this.__removeIdProperty(profiles[iProfiles].actions);
							profiles[iProfiles].filters = this.__removeExtPropertiesExpr(profiles[iProfiles].filters);
							profilesFinal.push(profiles[iProfiles]);
							this.__validateFilterName(profiles[iProfiles].filters);

						}
						
						profilesFinal.push({profileId: "global", actions: this.__removeIdProperty(this.userActions.globalActions)
										, filters: this.__removeExtPropertiesExpr(this.userActions.globalFilters)});
				} 
				
				
				//IB Templates removed for Summer'15
				var productTemplates = [];
				var productTemplateFinal = [];
				/*var productTemplates = this.productTemplates.showTemplates.getRecords() || [];
				var productTemplateFinal = [];
				var templlength = productTemplates.length, iTemplates = 0;
				for(var iTemplates = 0; iTemplates < templlength; iTemplates++) {
					if(productTemplates[iTemplates].templateId === "--None--") {
						if(productTemplates[iTemplates].isNew && productTemplates[iTemplates].template
								&&  productTemplates[iTemplates].template.children[0] && productTemplates[iTemplates].template.children[0].templateDetails &&
								productTemplates[iTemplates].template.children[0].templateDetails.templateId) {
							delete productTemplates[iTemplates]["isNew"];
						}else {
							continue;
						}
					}
					
					var templateDet = productTemplates[iTemplates].template.templateDetails ? 
							productTemplates[iTemplates].template.templateDetails : productTemplates[iTemplates].template.children[0].templateDetails;
					
					productTemplates[iTemplates].templateId =  templateDet.templateId;
					productTemplates[iTemplates].templateName = templateDet.templateName;					
					if(productTemplates[iTemplates].template) {
						productTemplates[iTemplates].template = this.__removeExtPropertiesProd(productTemplates[iTemplates].template);						
					}
					productTemplateFinal.push(productTemplates[iTemplates]);
				}*/


				// technical attributes template configurations.
				var taTemplateConfiguration = {};
				taTemplateConfigurationDetails = this.technicalAttributes.getTAtemplateConfigurationDetails();
				var taDeletedTemplateIds = [];
				taDeletedTemplateIds = this.technicalAttributes.technicalAttributesList.deletedTemplateIds;
				

				// get all TA criteria if they removed from template.
				var taDeletedCriteriaIds = [];
				taDeletedCriteriaIds = this.technicalAttributes.createNewTATemplate.deletedTACriteriaIds;

				if(this.technicalAttributes.__isDefaultPicklistSetToTA === true) {
					var messageToShow = $TR.PICKLIST_ERROR_MESSAGE;
					SVMX.getCurrentApplication().showQuickMessage("error", messageToShow);
				} else if(this.isFilterNameEmpty){
					var messageToShow = $TR.FILTER_NAME_ERROR;
					SVMX.getCurrentApplication().showQuickMessage("error", messageToShow);
				} else {
					this.blockUI();
					var me = this;
					me.saveButton.setDisabled(true);
			       	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
									"INSTALLIGENCEADMIN.SAVE_SETUP_DATA", me,
									{request : { context : me, profiles: profilesFinal, taTemplateConfiguration:taTemplateConfigurationDetails, taDeletedTemplateIds: taDeletedTemplateIds,isValideTAtemplate:'YES', deletedTACriteriaIds:taDeletedCriteriaIds }});//, ibTemplates: productTemplateFinal, delTemplateIds: this.productTemplates.deletedTemplateIds
			       	SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
					
					}
				}

				//this.technicalAttributes.refreshView();
				
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
	        },
			
			__persistScreenConfiguration: function() {				
				
				if(this.userActions.showProfiles.getSelectedRecord()) {
					//Store actions
					this.userActions.__persistUserActions(this.userActions.showProfiles.getSelectedRecord());
					//this.userActions.__persistUserStdActions(this.userActions.showProfiles.getSelectedRecord());
					
					//this.dataValidationRules.__persistDataValidationRules(this.dataValidationRules.showProfiles.getSelectedRecord());
					//persist expression
					var selectedExpr = this.userActions.filters.filtersSearchGrid.selectedExpression;
					if(selectedExpr) {
						this.userActions.filters.__persistExpression(selectedExpr);
					}
					//Store filters
					this.userActions.__persistFilters(this.userActions.showProfiles.getSelectedRecord());

					//Store attachment

					this.attachment.__persistAttachment(this.attachment.showProfiles.getSelectedRecord());

					// For Search
					this.search.__persistSearchData();
				}			
				
				//store product node data
				/*var selectedRecord = this.productTemplates.templateTree.getSelectionModel().getSelection()[0];
				this.productTemplates.__persistProductData(selectedRecord);
				
				//store template data
				var selectedTemplate = this.productTemplates.showTemplates.selectedTemplate;
				if(selectedTemplate) {
					this.productTemplates.__persistTemplate(selectedTemplate);
				}*/
				
			},
			
			onSaveSetupDataComplete: function(records){
	    			this.saveButton.setDisabled(false);
	    			if (typeof records.isValideTAtemplate != "undefined" && records.isValideTAtemplate == 'NO'){
	    				this.unblockUI();
	        			Ext.Msg.alert({
	        				cls : 'piq-setup-error-alert',
	            			title: $TR.MESSAGE_ERROR,
	            			message: $TR.TEMPLATE_SAVE_UNSUCCESSFULL,
	            			buttonText: { ok: $TR.OK_BTN },
	            			closable: false
	        			});
	    			}else{
	        			this.technicalAttributes.refreshView();
	        			var me = this;
	        			var evt = SVMX.create("com.servicemax.client.lib.api.Event","INSTALLIGENCEADMIN.GET_SETUP_METADATA", me,{request:{context:me}});
	        			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
	    			}
			},
			
			dataSavedSucessfullyMessage: function(msg){
				var messageToShow = $TR.SAVE_SUCCESS;//"Data Saved Successfully.";
				if(msg)
					messageToShow = msg;

				SVMX.getCurrentApplication().showQuickMessage("info", messageToShow);

				// var mb = Ext.MessageBox.show({
				//     title:'',
				//     msg: messageToShow,
				//     closable: false,
				//     fn:function(btn) { } // singleton
				// });

				// setTimeout(function(){
				//     mb.close();
				// }, 2000);
			},

	        onGetSetupMetadataComplete: function(records) {
	        	
	        	var sforceObjectDescribes = records.sforceObjectDescribes;
	        	
	        	for(var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
	        		records[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
	        	}
	        	
	        	var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				var profiles = records.svmxProfiles;
				var iSerProfiles = 0; iSerLength = profiles.length;
				for(iSerProfiles = 0; iSerProfiles < iSerLength; iSerProfiles++){
					if(profiles[iSerProfiles].profileId !== 'global'){
						profilesData.push(profiles[iSerProfiles])
					}else {
						this.userActions.globalActions = profiles[iSerProfiles].actions;
						this.userActions.globalFilters = profiles[iSerProfiles].filters;
					}
				}
				this.userActions.showProfiles.getStore().loadData(profilesData);
				
				
				/*var templatesData = [{templateId: "--None--", templateName: $TR.NONE}];
				templatesData =	templatesData.concat(records.ibTemplates);				
				this.productTemplates.showTemplates.getStore().loadData(templatesData);*/
	        	
				this.technicalAttributes.technicalAttributesList.resetData(records.totalTAtemplates);
	        	this.technicalAttributes.technicalAttributesList.refreshTemplateGrid();
	        	this.unblockUI();
	        	this.dataSavedSucessfullyMessage();
	        },
			
			__removeIdProperty: function(records) {
				for(var rec in records) {
					delete records[rec]["id"];
				}
				return records;				
			},
			
			__removeExtPropertiesExpr: function(records) {
				for(var rec in records) {
					delete records[rec]["id"];
					if(records[rec].expression && records[rec].expression.children) {
						var childrenLoc = records[rec].expression.children;
						childrenLoc = this.__isArray(childrenLoc) ? childrenLoc[0] : childrenLoc;
						records[rec]["expression"] = {children: [this.__getExpressionChildNodes(childrenLoc)]};
					}
					
				}
				return records;	
			},

			__validateFilterName : function(records) {
				for(var index = 0; index < records.length; index++) {
					var currrentRecord = records[index];
					if(currrentRecord) {
						var filterName = currrentRecord.name;
						filterName = filterName.replace(/\s/g, "");
						if(filterName.length === 0) {
							this.isFilterNameEmpty = true;
						}
					}
				}
			},
			
			__isArray: function(myArray) {
			    return myArray.constructor.toString().indexOf("Array") > -1;
			},
			
	        __getExpressionChildNodes: function(node) {
	    	   
	    	    var rec = {};
	    	    if(node !== undefined) {	    	    	
		    	    rec.operator = node.operator;
		    	    rec.exprType = node.exprType;
		    	    rec.field = node.field;
		    	    rec.condition = node.condition;
		    	    rec.value = node.value;
		    	    if(node.children && node.children.length > 0){
		    		    rec.children = [];
			    	    var children = node.children || [], i, l = children.length;
			    	    for(i = 0; i < l; i++){
			    		    rec.children.push(this.__getExpressionChildNodes(children[i]));
			    	    }
		    	    }
		    	   
	    	    }
	    	    return rec;	    	   
	        },
			
			__removeExtPropertiesProd: function(records) {
				
				var rec = {};
				if(records && records.children) {
					rec = this.__getProductChildNodes(records.children[0]);
				}				
				return rec;	
			},
			
	        __getProductChildNodes: function(node) {
	    	   
	    	    var rec = {};
	    	    if(node !== undefined && node != null) {	    	    	
		    	    rec.text = node.text;
		    	    rec.type = node.type;
		    	    rec.product = node.product;
		    	    //remove ext properties of product configuraton
		    	    if(rec.product && rec.product.productConfiguration) {
		    	    	rec.product.productConfiguration = this.__removeIdProperty(rec.product.productConfiguration)
		    	    }
		    	    rec.templateDetails = node.templateDetails;
		    	    
		    	    if(node.children && node.children.length > 0){
		    		    rec.children = [];
			    	    var children = node.children || [], i, l = children.length;
			    	    for(i = 0; i < l; i++){
			    		    rec.children.push(this.__getProductChildNodes(children[i]));
			    	    }
		    	    }		    	   
	    	    }
	    	    return rec;	    	   
	        }
			   
			
		});	
	}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\search.js
(function(){
	var search = SVMX.Package("com.servicemax.client.installigence.admin.search");

search.init = function() {

		Ext.define("com.servicemax.client.installigence.admin.Search", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
			__root: null,
			constructor: function(config) {
				var me = this;
				this.__registerForDidProfileSelectCall();
				this.__root = config.root;
				var profiles = config.metadata.svmxProfiles;
				var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				var objectsData = [{objectName: "--None--", objectLabel: $TR.NONE}, {objectName: SVMX.OrgNamespace  + "__Installed_Product__c", objectLabel: "Installed Product"}];
				var availSearchData = [{sfdcId: "--None--", searchLabel: $TR.NONE}].concat(config.metadata.availableSearchProc.searches);
				var searches = [];

				var iProfile = 0, iProfileLength = profiles.length;
				for(iProfile = 0; iProfile < iProfileLength; iProfile++) {
					if(profiles[iProfile].profileId !== 'global'){
						profilesData.push(profiles[iProfile]);
					}
				}

				me.profiles = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['profileId', 'profileName'],
			        data: profilesData
			    });

			    me.objects = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['objectName', 'objectLabel'],
			        data: objectsData
			    });

			    me.availableSearches = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['sfdcId', 'searchLabel'],
			        data: availSearchData
			    });
				/*me.showProfiles = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_PROFILE,
			        store: me.profiles,
			        labelWidth: 140,
			        width: 450,
			        displayField: 'profileName',
			        queryMode: 'local',
			        editable: false,
			        selectedProfile: undefined,
			        listeners: {
			        	select: {
			        		fn: me.__didSelectProfileWithInfo,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('profileName'));
						}
						afterrender :{
							fn : me.__showProfilesAfterrender,
							scope : me
						}
			        }
				});*/

				me.showProfiles = config.root.showProfiles;

				//'Select a Object'
				me.showObjects = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_OBJECT,
			        store: me.objects,
			        labelWidth: 150,
			        width: 450,
			        displayField: 'objectLabel',
			        valueField:'objectName',
			        queryMode: 'local',
			        editable: false,
			        margin:'10 0',
			        disabled: true,
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

				me.showSearchs = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_SEARCH,
			        store: me.availableSearches,
			        labelWidth: 150,
			        width: 450,
			        displayField: 'searchLabel',
			        valueField:'sfdcId',
			        queryMode: 'local',
			        editable: false,
			        disabled: true,
			        listeners: {
			        	select: {
			        		fn: me.__persistSearchData,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('searchLabel'));
						}
			        }
				});

				config = config || {};
				config.items = [];
				//config.items.push(me.showProfiles);
				config.items.push(me.showObjects);
				config.items.push(me.showSearchs);

				
				config.title = $TR.SEARCH_EMPTY_TEXT; //
				config.id = "Search";
				this.callParent([config]);

			},

			__showProfilesAfterrender : function(combo){
				
					var recordSelected; 
						if(this.__root.selectedProfile)
						{
							recordSelected =  this.__root.selectedProfile; 
						}else
						{
							recordSelected = combo.getStore().getAt(0);
						}
						combo.setValue(recordSelected.get('profileName'));

			},
			__didSelectProfileWithInfo:function(combo, record){
				this.__root.selectedProfile = record;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "SELECTED_PROFILE_CALL",{result: {combo:combo,record:record}},
                                                             this);
                    SVMX.getClient().triggerEvent(evt);
                    

			},
			__onSelectProfile: function(combo, record){

				this.showObjects.setValue('--None--');
				this.showSearchs.setValue('--None--');

				
				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.showObjects.setDisabled(true);
					this.showSearchs.setDisabled(true);
				}else{
					this.showObjects.setDisabled(false);
				}

				if(combo.getSelectedRecord() && combo.getSelectedRecord().get("profileId") !== "--None--"){
					var selProfileObj = this.showProfiles.selectedProfile;
				}

				if(combo.getSelectedRecord().get("profileId") !== "--None--"){
					this.showProfiles.selectedProfile = record;
				}else{
					this.showProfiles.selectedProfile = undefined;
				}
			},

			__onSelectObjects: function(combo, record){
				if(combo.getSelectedRecord().get("objectName") == "--None--"){
					this.showSearchs.setDisabled(true);
				}else{
					this.showSearchs.setDisabled(false);
				}
				this.__loadSearchData(combo, record);

			},

			__persistSearchData: function(){
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().search == undefined){
					selecetedProfile.set("search", []);
				}
				if(this.showObjects.getSelectedRecord() && this.showObjects.getSelectedRecord() !== undefined &&
					this.showObjects.getSelectedRecord().get("objectName") !== "--None--"){

					var searchName = this.showSearchs.getSelectedRecord().get("searchName");	
					var objectName = this.showObjects.getSelectedRecord().get("objectName");
					var sfdcId = this.showSearchs.getSelectedRecord().get("sfdcId");
					var selectedSearchObject = this.__getObjectSearchData(selecetedProfile, objectName);

					if(!selectedSearchObject){
						selectedSearchObject = {objectName: objectName};
						selecetedProfile.set("search", [selectedSearchObject]);
					}
					if(sfdcId == "--None--") sfdcId = "";
					selectedSearchObject.searches = [{sfdcId: sfdcId}];
					if(selectedSearchObject.searches.length > 0 && sfdcId) {
						selectedSearchObject.searches[0].sfdcId = sfdcId;
					}
					if(selectedSearchObject.searches.length > 0 && searchName) {
						selectedSearchObject.searches[0].searchName = searchName;
					}

				}
			},
			__getObjectSearchData: function(selectedProfile, objectName){
				var iSearchData = 0, iSearchLen = selectedProfile.getData().search.length;
				for(iSearchData = 0; iSearchData < iSearchLen; iSearchData++){
					if(selectedProfile.getData().search[iSearchData].objectName == objectName){
						return selectedProfile.getData().search[iSearchData];
					}
				}
				return undefined;
			},

			__loadSearchData: function(combo, record){
				var selectedObjectName = combo.getSelectedRecord().get("objectName");
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				var selectedSearch = "";
				var selectedSearchProcessId = '';
				var selectedSearchObject = '';
				if(selectedObjectName !== "--None--" && selecetedProfile.getData().search){
					selectedSearchObject = this.__getObjectSearchData(selecetedProfile, selectedObjectName);
					if(selectedSearchObject){
						//get the selected object search data
						selectedSearch = selectedSearchObject.searches[0].sfdcId;
						selectedSearchProcessId = selectedSearchObject.searches[0].searchName;
					}
				}
				var item = this.showSearchs.store.data.items.find(function(object){
								if(object.data.sfdcId == selectedSearch) return true;
								return false;
							});
				if(!item) { //incase if  process is not available for selected sfdcid then show none.
					var len = this.showSearchs.getStore().data.items.length, items = this.showSearchs.getStore().data.items, matched = false;
					for(var i = 0; i < len; i++) {
						var currentProcessId = items[i].data.searchName;
						if(currentProcessId === selectedSearchProcessId) {
							//update the sfdcId here.
							selectedSearch = items[i].data.sfdcId;
							matched = true;
							var selecetedProfile = this.showProfiles.getSelectedRecord();
							if(selecetedProfile.getData().search == undefined){
								selecetedProfile.set("search", []);
							}
							var selectedSearchObject = this.__getObjectSearchData(selecetedProfile, selectedObjectName);
							if(!selectedSearchObject){
								selectedSearchObject = {selectedObjectName: selectedObjectName};
								selecetedProfile.set("search", [selectedSearchObject]);
							}
							if(selectedSearch === "--None--") selectedSearch = "";
							selectedSearchObject.searches = [{sfdcId: selectedSearch}];
							if(selectedSearchObject.searches.length > 0 && selectedSearch) {
								selectedSearchObject.searches[0].sfdcId = selectedSearch;
							}
							if(selectedSearchObject.searches.length > 0 && selectedSearchProcessId) {
								selectedSearchObject.searches[0].searchName = selectedSearchProcessId;
							}
							break;
						}
					}
					if(!matched) {
						selectedSearch = "--None--";
					}
				}

				if(!selectedSearch || selectedSearch.length == 0) selectedSearch = "--None--";

    		   this.showSearchs.setValue(selectedSearch);
			},

			__registerForDidProfileSelectCall: function(){

           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){
               var data = SVMX.toObject(evt.data);
             var combo = evt.target.result.combo;
             var record = evt.target.result.record;
          	 
             this.__onSelectProfile(combo, record);
             this.showProfiles.setRawValue(record.get('profileName'));
           		}, this); 
			}
		});

	}
	})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\technicalAttributes.js
/**
 *  Technical Attributes.
 * @class com.servicemax.client.insralligence.admin.technicalAttributes.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/
 (function(){

	var technicalAttributes = SVMX.Package("com.servicemax.client.installigence.admin.technicalAttributes");
	technicalAttributes.init = function() {

// TechnicalAttributes class start.
			Ext.define("com.servicemax.client.installigence.admin.TechnicalAttributes", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

	         __root: null,
	         __templatePicklistModel : null,
	         __templatePicklists : null,
	         __templatePicklistSfIds : null,
	         __isDefaultPicklistSetToTA : null,
	         constructor: function(config) {
	        	var me = this;
	        	this.__root = config.root;
	        	this.__templatePicklistModel = {};
	        	this.__templatePicklists = {};
	        	this.__templatePicklistSfIds = {};
	        	this.__isDefaultPicklistSetToTA = false;
	        	config = config || {};
				config.title = $TR.TECHNICAL_ATTRIBUTES;
				config.id = "technicalAttributes";
				

				me.technicalAttributesList = SVMX.create('com.servicemax.client.installigence.admin.ListAllTechnicalAttributes',{
					metadata: config.metadata,hidden:false,id:'technicalAttributesListPanel',
					cls: 'piq-setup-list-ta',
					root: config.root, parentContext:this
				});

				me.createNewTATemplate = SVMX.create('com.servicemax.client.installigence.admin.CreateNewTechnicalAttributesTemplate',{
					metadata: config.metadata,hidden:true,id:'createNewTATemplatePanel', autoScroll:true,layout: 'fit',
					root: config.root,  parentContext:this, cls:'piq-setup-create-new-ta'
				});
				config.items = [me.technicalAttributesList,me.createNewTATemplate];

	        	 this.callParent([config]);
	         },

	        getTAtemplateConfigurationDetails: function(){
	        	
	        	var templateConfiguration = {};
	        	var createNewTATemplateElt = Ext.getCmp("createNewTATemplatePanel");
	        	if(createNewTATemplateElt.isVisible() == false) return null;	
	        	
				
				var isInValideTemplate = (this.createNewTATemplate.productReferenceField.selectedProduct == null && this.createNewTATemplate.productFamilyComboBox.getSelectedRecord().data.fieldLabel === "--None--" && this.createNewTATemplate.productLineComboBox.getSelectedRecord().data.fieldLabel === "--None--" );
				
 
				if(!createNewTATemplateElt.isVisible() == false && isInValideTemplate == false){
					if(this.createNewTATemplate.__currentTemplateRecord.data === undefined){
						
					}else{
						templateConfiguration.templateId = this.createNewTATemplate.__currentTemplateRecord.data.Id;
					}
					
					templateConfiguration.templateTitle = this.createNewTATemplate.titleTextFields.value;
					templateConfiguration.templateDescription = Ext.getCmp("taTemplateDescriptionField").getValue();
					templateConfiguration.templateApplicationCriteria = this.__getApplicationCriteriaForTemplate();
					templateConfiguration.templateAttributesDetails = this.__getTemplateAttributesDetails();
					 
					templateConfiguration.templateAttributesType = 'TECHNICAL';
					templateConfiguration.templateIsActive = 'true';
					templateConfiguration.templatePicklistId = this.__getPicklistIds();
				}
				console.log('templateConfiguration:' + templateConfiguration);
				return templateConfiguration;
	        	
	        },

	        __getApplicationCriteriaForTemplate: function(){
	        	
	        	var allApplicationCriteria = [];
	        	

	        	//if(this.createNewTATemplate.__currentApplicationCriteriaRecords.length > 0){
				//		applicationCriteria.criteriaId = this.createNewTATemplate.__currentApplicationCriteriaRecords[0].Id;
				//	}
					if(this.createNewTATemplate.productReferenceField.selectedProduct !== null){
						 
	        			var applicationCriteriaForProduct = {};
	        			
						
						applicationCriteriaForProduct.productId = this.createNewTATemplate.productReferenceField.selectedProduct.Id;		
						
						if(this.createNewTATemplate.productReferenceField.recordIndex)
							applicationCriteriaForProduct.criteriaId = this.createNewTATemplate.productReferenceField.recordIndex;
						
						allApplicationCriteria.push(applicationCriteriaForProduct);
						applicationCriteriaForProduct = null;
						
					}else{

						if(this.createNewTATemplate.productReferenceField.recordIndex)
							this.createNewTATemplate.deletedTACriteriaIds.push(this.createNewTATemplate.productReferenceField.recordIndex);

					}
	        	
	        		if(this.createNewTATemplate.productFamilyComboBox.getSelectedRecord().data.fieldLabel !== "--None--"){
	        			var applicationCriteriaForFamily = {};
	        			
	        			
	        			applicationCriteriaForFamily.productFamily = this.createNewTATemplate.productFamilyComboBox.getSelectedRecord().data.fieldLabel;		
	        			
	        			if(this.createNewTATemplate.productFamilyComboBox.recordIndex)
							applicationCriteriaForFamily.criteriaId = this.createNewTATemplate.productFamilyComboBox.recordIndex;
	        			
	        			allApplicationCriteria.push(applicationCriteriaForFamily);
	        			applicationCriteriaForFamily = null;
	        			
	        		}else{

						if(this.createNewTATemplate.productFamilyComboBox.recordIndex)
							this.createNewTATemplate.deletedTACriteriaIds.push(this.createNewTATemplate.productFamilyComboBox.recordIndex);

					}
	        	
	        		if(this.createNewTATemplate.productLineComboBox.getSelectedRecord().data.fieldLabel !== "--None--"){
	        			var applicationCriteriaLine = {};
	        			
	        			
	        			applicationCriteriaLine.productLine   = this.createNewTATemplate.productLineComboBox.getSelectedRecord().data.fieldLabel;		
	        			
	        			if(this.createNewTATemplate.productLineComboBox.recordIndex)
							applicationCriteriaLine.criteriaId = this.createNewTATemplate.productLineComboBox.recordIndex;
	        			
	        			allApplicationCriteria.push(applicationCriteriaLine);
	        			applicationCriteriaLine = null;
	        			
	        		}else{

						if(this.createNewTATemplate.productLineComboBox.recordIndex)
							this.createNewTATemplate.deletedTACriteriaIds.push(this.createNewTATemplate.productLineComboBox.recordIndex);

					}
	        	
	        	//applicationCriteria.productCode   = '';

	        	return allApplicationCriteria;

	        },
	        __getTemplateAttributesDetails: function(){
	        	var attributesDetails ;
	        	attributesDetails = {};
	        	attributesDetails.fields   = this.__getCategoryDetails();
	            attributesDetails.picklist = this.__getPicklistDetails();
	        	var attributesDetailsInString = JSON.stringify(attributesDetails);
	        	return attributesDetailsInString;
	        },

	        __getCategoryDetails: function(){

	        	var categoryDetails = [];
	        	var l = this.createNewTATemplate.__sections.length, filedDetails, currentSection;
	        	var allSections = this.createNewTATemplate.__sections;

	        	for(var i = 0; i<l; i++){
	        		filedDetails = {};
	        		currentSection = allSections[i];
	        		filedDetails.title = currentSection.titleTextFields.value;
	        		filedDetails.description = Ext.getCmp('textareafield'+currentSection.id).getValue();
	        		filedDetails.technicalAttributes = this.__getAllTechnicalAttributesDetailsInCategory(currentSection);
	        		categoryDetails.push(filedDetails);
	        	}


	        	return categoryDetails;
	        },

	        __getAllTechnicalAttributesDetailsInCategory: function(section){
	        	var items = section.attributesGrid.store.data.items;
	        	var l = items.length, field = {}, allFields = [];
	        	for(var i=0; i<l; i++){
	        		var data = items[i].data;
	        		var format = '';
	        		if(section.attributesGrid.formatTypeStore.findRecord("label", data.format)) format = section.attributesGrid.formatTypeStore.findRecord("label", data.format).get("value");
	        		let requiredField = null;
	        		if(data.req === 'YES'){
	        			requiredField = '1';
	        		} else if(data.req === 'NO'){
	        			requiredField = '0';
	        		}
	        		field = {
					    label: data.label,
					    type: data.type,
					    sequence: i,
					    defaultValue: (data.defaultValue === ' ') ? '' : data.defaultValue,
					    unit: data.unit,
					    readOnly: data.readOnly,
					    format: format,
					    req: requiredField,
					    maxNumber : data.maxNumber,
					    minNumber : data.minNumber,
					    message : data.message,
					};
	        		if(data.format === 'Picklist') {
	        			var defaultValueString = data.defaultValue;
	        			this.__templatePicklists[data.picklistName] = data.picklistName;
	        			field["picklistId"] = defaultValueString.replace(/\s/g, "");
	        			this.__templatePicklistSfIds[data.picklistSfId] = data.picklistSfId;
	        			field["picklistSfId"] = data.picklistSfId;
	        			field["picklistName"] = data.picklistName;
	        			if(data.defaultDisplayValue && data.defaultDisplayValue.length > 0) {
	        				field["defaultValue"] = data.defaultDisplayValue;
	        				field["defaultDisplayValue"] = data.defaultDisplayValue;
	        			} else {
	        				field["defaultValue"] = '';
	        				field["defaultDisplayValue"] = '';
	        			}
	        			
	        		}
	        		
	        		allFields.push(field);
	        	}	        	
	        	return allFields;
	        },

	        __getPicklistDetails : function() {
	        	var finalPicklistModel = {};
	        	this.__isDefaultPicklistSetToTA = false;
	        	var defaultPicklistTag = $TR.SELECT;
	        	var picklistKeysArray = Object.keys(this.__templatePicklists);
	        	for(var i = 0; i < picklistKeysArray.length; i++) {
	        		key1 = picklistKeysArray[i];
	        		if(defaultPicklistTag === key1) {
	        			this.__isDefaultPicklistSetToTA = true;
	        			break;
	        		} else {
	        			key1 = key1.replace(/\s/g, "");
	        			for (var key2 in this.__templatePicklistModel) {
		        			var values = this.__templatePicklistModel[key2];
		        		    key2 = key2.replace(/\s/g, "");
		        			if(key1 === key2) {
		        				if(typeof values === 'string') {
		        				 	finalPicklistModel[key2] = JSON.parse(values);
		        				} else {
		        					finalPicklistModel[key2] = values;
		        				}
		        				break;
		        			}
		        		}
	        		}
	        	}
	        	return finalPicklistModel;
	        },
	        __getPicklistIds : function() {
	        	var picklistKeysArray = Object.keys(this.__templatePicklistSfIds);
	        	return picklistKeysArray.join(',');;
	        },
	        
	        refreshView: function(){

						this.technicalAttributesList.setVisible(true);
						this.createNewTATemplate.setVisible(false);
						this.createNewTATemplate.resetPage();
						//this.technicalAttributesList.updateTemplateList();
	        },

	       loadTemplatePage: function(record){

	       				// Enable save action.
	       				this.__root.saveButton.setDisabled(false);
	        			this.technicalAttributesList.setVisible(false);
						this.createNewTATemplate.setVisible(true);
						this.createNewTATemplate.reloadTemplatePage(record);

	        },

	        shouldAllowToSaveConfigurationData: function() {
		         var returnValue;
		         var isValidCriteria;
		         var __createNewTATemplate = this.createNewTATemplate;
		         if(__createNewTATemplate.productFamilyComboBox.getSelectedRecord()) 
		         	isValidCriteria = (__createNewTATemplate.productReferenceField.selectedProduct == null  && __createNewTATemplate.productFamilyComboBox.getSelectedRecord().data.fieldLabel === '--None--' && __createNewTATemplate.productLineComboBox.getSelectedRecord().data.fieldLabel === '--None--');
		         var isInValidTemplate = ( isValidCriteria || !Boolean(__createNewTATemplate.titleTextFields.value.length) || !Boolean(Ext.getCmp("taTemplateDescriptionField").getValue().length));
		         var createNewTATemplateElt = Ext.getCmp("createNewTATemplatePanel");
		         var fieldsLengthInfo = this.__validateTextAndTextAreaLength();
		         var isInvalidProductFamily = (this.createNewTATemplate.productFamilyComboBox.getSelectedRecord() == null);
		         var isInvalidProductLine = (this.createNewTATemplate.productLineComboBox.getSelectedRecord() == null);
		         var duplicateAttributeObject = this.__validateDuplicateAttibutesName();
		         var isEmptyLabelFound = this.__validateEmptyAttributeLabel();
		         if(!createNewTATemplateElt.isVisible()){
		         	returnValue = true;
		         } else if(isInvalidProductFamily) {
		         	SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.PRODUCT_FAMILY + ' : ' + $TR.MISSING_OR_INCORRECT_ENTRY);
		            returnValue = false;
		         } else if(isInvalidProductLine) {
		         	SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.PRODUCT_LINE + ' : ' + $TR.MISSING_OR_INCORRECT_ENTRY);
		            returnValue = false;
		         } else if (this.createNewTATemplate.productFamilyComboBox.getSelectedRecord() == null || !createNewTATemplateElt.isVisible()) {
		             returnValue = true;
		         } else if (createNewTATemplateElt.isVisible() && isInValidTemplate == true) {
		             SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.MANDATORY_FIELDS_TA_TEMPLATE);
		             returnValue = false;
		         } else if (!fieldsLengthInfo.isValid) {
		             SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, fieldsLengthInfo.errorMessage);
		             returnValue = false;
		         } else if (!duplicateAttributeObject.isValidAttributes) {
		         	 var duplicateAttributesName =  duplicateAttributeObject.duplicateAttributes.join();
		         	 SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.DUPLICATE_ATTRIBUTES+ ' : '+ duplicateAttributesName );
		             returnValue = false;
		         } else if(isEmptyLabelFound.isEmpty){
		         	SVMX.getCurrentApplication().showQuickMessage($TR.MESSAGE_ERROR, $TR.ATTRIBUTE_NAME_AND_FORMATE_REQUIRED);
		         	this.createNewTATemplate.heighlightAttribute(isEmptyLabelFound.attribute);
		         	returnValue = false;
		         } else {
		             returnValue = true;
		         }
		         return returnValue;
		     },

		     __validateEmptyAttributeLabel: function(){
		     	var isEmptyLabelFound = this.createNewTATemplate.isAttributeLabelEmpty();
		     	return isEmptyLabelFound;
		     },
		     __validateDuplicateAttibutesName: function(){
		     	var duplicateAttributes = [];
		     	var caseInsensitiveAttributes = [];
		     	var isValidAttributes = true;
		     	var allAttributes = this.createNewTATemplate.getAllAttributesName();
		     	for(var iAttribute=0; iAttribute < allAttributes.length; iAttribute++){
		     		var attributeName = allAttributes[iAttribute];
		     		var num = allAttributes.reduce(function(count,label){
    									if(label.toLowerCase() === attributeName.toLowerCase())
       										count++;
    									return count;
									},0);
		     		if(num > 1){
		     			if (caseInsensitiveAttributes.indexOf(attributeName.toLowerCase()) > -1) {
    							//In the array!
							} else {
								duplicateAttributes.push(attributeName);
								caseInsensitiveAttributes.push(attributeName.toLowerCase());
							}
		     			
		     			isValidAttributes = false;
		     		}

		     	}
		     	var returnObject = {
		     		duplicateAttributes: duplicateAttributes,
		     		isValidAttributes: isValidAttributes
		     	};
		     	
		     	return returnObject;
		     },
		     __validateTextAndTextAreaLength: function() {
		         var returnValues = { isValid: false, errorMessage: '' };
		         var maxTextLength = 255;
		         var maxTextAreaLength = 131072;
		         var templateTitle = this.createNewTATemplate.titleTextFields.value;
		         var templateDescription = Ext.getCmp("taTemplateDescriptionField").getValue();
		         var templateJSON = this.__getTemplateAttributesDetails();
		         if (templateTitle.length > maxTextLength) {
		             returnValues.errorMessage = $TR.TEMPLATE_NAME + ' : ' + $TR.TOO_LONG;
		         } else if (templateDescription.length > maxTextLength) {
		             returnValues.errorMessage = $TR.TEMPLATE_DESCRIPTION + ' : ' + $TR.TOO_LONG;
		         } else if (templateJSON.length > maxTextAreaLength) {
		             returnValues.errorMessage = $TR.DEFINE_TA_SECTION + ' : ' + $TR.TOO_LONG;
		         } else {
		             returnValues.isValid = true;
		         }
		         return returnValues;
		     }
	        
	     });
// TechnicalAttributes class end.

// ListAllTechnicalAttributes class start.
		Ext.define("com.servicemax.client.installigence.admin.ListAllTechnicalAttributes", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

			__meta : null,
			__isTechnicalAttributesEnabled : null,
			__grid : null,
			__store : null,
			__root: null,
			__parentContext: null,
			deletedTemplateIds: null,
			__templateOffset: null,
			__taTemplateCount: null,
			__offsetCount : null,
			constructor: function(config) {
			     var me = this;
			     me.__templateOffset = 0;
			     me.__taTemplateCount = config.metadata.totalTAtemplates;
			     me.__offsetCount = 10;
			     me.deletedTemplateIds = [];
			     me.__registerForDidProfileSelectCall();
			     me.__root = config.root;
			     me.__parentContext = config.parentContext;
			     var profiles = config.metadata.svmxProfiles;
			     var profilesData = [{ profileId: "--None--", profileName: $TR.NONE }];
			     var iProfile = 0,
			         iProfileLength = profiles.length;
			     for (iProfile = 0; iProfile < iProfileLength; iProfile++) {
			         if (profiles[iProfile].profileId !== 'global') {
			             profilesData.push(profiles[iProfile]);
			         }
			     }
			     me.showProfiles = config.root.showProfiles;
			     me.enableTAcheckbox = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
			         boxLabel: $TR.ENABLE_TECHNICAL_ATTRIBUTES,
			         scope: me,
			         disabled: true,
			         handler: function(field, value) {
			             me.__shouldEnableTechnicalAttributesForProfile(value, me);
			         }
			     });
			     me.searchTAtemplateTextBox = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextSearch', {
			         width: '40%',
			         cls: 'search-textfield',
			         emptyText: $TR.SEARCH_EMPTY_TEXT,
			         listeners: {
			             change: {
			                 //fn: me.__onTextFieldChange,
			                 scope: me,
			                 buffer: 500
			             }
			         }
			     });
			     me.goButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
			         text: $TR.GO,
			         cls: 'piq-setup-add-button',
			         disabled: false,
			         rigion: 'right',
			         parentContext: me,
			         handler: function() {
			         	var parentContext = this.parentContext;
			         	parentContext.refreshTemplateGrid();
			         }
			     });
			     me.nextButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
			         text: $TR.NEXT,
			         cls: 'piq-setup-add-button',
			         disabled: true,
			         rigion: 'right',
			         parentContext: me,
			         handler: function() {
			         	var parentContext = this.parentContext;
			         	 parentContext.previousButton.setDisabled(false);
			             parentContext.__templateOffset += parentContext.__offsetCount;

			             if((parentContext.__templateOffset + parentContext.__offsetCount) >= parentContext.__taTemplateCount) this.setDisabled(true);
			             parentContext.updateTemplateList();
			         }
			     });
			     me.previousButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
			         text: $TR.PREVIOUS,
			         cls: 'piq-setup-add-button',
			         disabled: true,
			         rigion: 'right',
			         parentContext: me,
			         handler: function() {
			         	var parentContext = this.parentContext;
			         	parentContext.nextButton.setDisabled(false);
			            parentContext.__templateOffset -= parentContext.__offsetCount;
			            if(parentContext.__templateOffset == 0) this.setDisabled(true);
			            parentContext.updateTemplateList();
			         }
			     });
			     me.addTAtemplateButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
			         text:$TR.ADD,
			         cls: 'piq-setup-add-button',
			         disabled: false,
			         rigion: 'right',
			         parentContext: me,
			         handler: function() {
			             //Enable Save action button
			             me.__root.saveButton.setDisabled(false);
			             var taListElt = Ext.getCmp("technicalAttributesListPanel");
			             var createNewTATemplateElt = Ext.getCmp("createNewTATemplatePanel");
			             taListElt.setVisible(false);
			             createNewTATemplateElt.setVisible(true);
			         }
			     });
			     //Create the grid for template list.
			     var cols = [SVMX.OrgNamespace + '__SM_Title__c', SVMX.OrgNamespace + '__SM_Template_Description__c'],
			         columnsDisplayLabel = [$TR.TEMPLATE_NAME, $TR.TEMPLATE_DESCRIPTION],
			         l = cols.length,
			         me = this;
			     var fields = [];
			     for (i = 0; i < l; i++) { fields.push(cols[i]); }
			     var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			         fields: fields,
			         data: []
			     });
			     var gridColumns = [];
			     gridColumns.push({
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
			             me.deletedTemplateIds.push(rec.data.Id);
			             me.__root.saveButton.setDisabled(false);
			         }
			     });
			     for (var i = 0; i < l; i++) {
			         gridColumns.push({
			             text: columnsDisplayLabel[i],
			             handler: function() {},
			             dataIndex: cols[i],
			             renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                            },
			             flex: 1
			         });
			     }
			     me.templateGrid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
			         store: store,
			         cls: 'piq-setup-ta-grid',
			         layout: 'fit',
			         height: 400,
			         columns: gridColumns,
			         flex: 1,
			         width: "100%",
			         viewConfig: {
			             listeners: {
			                 select: function(dataview, record, item, index, e) {
			                     me.__parentContext.loadTemplatePage(record);
			                 }
			             }
			         }
			     });
			     me.otherOptionsToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
			         style: 'border-width: 0',
			         width: '100%'
			     });
			     me.otherOptionsToolbar.add(me.searchTAtemplateTextBox);
			     me.otherOptionsToolbar.add(me.goButton);
			     me.otherOptionsToolbar.add('->');
			     me.otherOptionsToolbar.add(me.addTAtemplateButton);
			     me.otherOptionsToolbar.add(me.previousButton);
			     me.otherOptionsToolbar.add(me.nextButton);
			     var bottomToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
			         style: 'border-width: 0',
			         width: '100%'
			     });
			     var restrictedLabel = {
			         xtype: 'label',
			         id: 'restrictedLabelId',
			         text: $TR.RESTRICTED_RELEASE_FEATURE,
			         margin: '20 0 10 10'
			     };
			    // bottomToolbar.add(restrictedLabel);
			     config.items = [me.enableTAcheckbox, me.otherOptionsToolbar, me.templateGrid];
			     me.__store = store;
			     me.callParent([config]);
			     //me.__reloadTemplateGrid();
			     me.updateTemplateList();
			 },
			
			__onTextFieldChange: function() {
	        	var value = this.searchTAtemplateTextBox.getValue();
	        	this.templateGrid.search(value);
	        	
	         },
			__reloadTemplateGrid: function(data){
				// Hardcoded template list.
				
				//var data = [{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'},{'templateID':'213214','templateName':'Batteries 2006','templateDescription':'Configuration for Batteries manufactured in 2006'},{'templateID':'213214','templateName':'Circute Z-cross','templateDescription':'Configuration for Z-cross'},{'templateID':'213214','templateName':'Voltage 300KV','templateDescription':'Configuration for IBs Voltage 300KV'}];
				this.__store.loadData(data);
				SVMX.getCurrentApplication().unblockUI();

				// Disable save action.
				if(this.showProfiles.getSelectedRecord().get("profileId") == "--None--")
	       				this.__root.saveButton.setDisabled(true);
               
	       		
			},

			__shouldEnableTechnicalAttributesForProfile: function(isEnabled,context){
				var selecetedProfile = context.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().isTechnicalAttributesEnabled == undefined){
					selecetedProfile.set("isTechnicalAttributesEnabled", "false");
				}

				selecetedProfile.set("isTechnicalAttributesEnabled", isEnabled);


			},
			__updateEnableTAcheckboxValue:function(combo, record){

				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.enableTAcheckbox.setDisabled(true);
				}else{
					this.enableTAcheckbox.setDisabled(false);
				}
				
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().isTechnicalAttributesEnabled == undefined || selecetedProfile.getData().isTechnicalAttributesEnabled === "false" ){
					this.enableTAcheckbox.setValue(false);
				}else if(selecetedProfile.getData().isTechnicalAttributesEnabled === "true"){
					this.enableTAcheckbox.setValue(true);
				}
				
			},
			__registerForDidProfileSelectCall: function(){
				var me = this;
           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){

              	 var data = SVMX.toObject(evt.data);
            	 var combo = evt.target.result.combo;
            	 var record = evt.target.result.record;
          	 	this.__updateEnableTAcheckboxValue(combo, record);	
				this.showProfiles.setRawValue(record.get('profileName'));

           }, this); 
			},
			updateTemplateList: function(){
				var me = this;
				if(me.__templateOffset == 0 && this.__taTemplateCount >10){
					me.previousButton.setDisabled(true);
					me.nextButton.setDisabled(false);
				}
				SVMX.getCurrentApplication().blockUI();
				var params = {text: this.searchTAtemplateTextBox.getValue().trim()};
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN.GET_ALL_ATTRIBUTESTEMPLATES" , this, 
					{request : { context : this, handler : this.__reloadTemplateGrid, text : params.text, templateOffset: me.__templateOffset }});
			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
			},
			refreshTemplateGrid: function(){
				var me = this;
				me.previousButton.setDisabled(true);
				me.nextButton.setDisabled(true);
				var params = {text: me.searchTAtemplateTextBox.getValue().trim()};
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN.GET_TEMPLATE_COUNT" , this, 
					{request : { context : this, handler : this.__getTemplateCountForSearchValueCompleted, text : params.text, templateOffset: me.__templateOffset }});
				SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);

			},
			__getTemplateCountForSearchValueCompleted: function(data) {
				this.resetData(data);
				this.updateTemplateList();
			},
			resetData: function(templateCount){
				if(templateCount != null) this.__taTemplateCount = templateCount;
				this.__templateOffset = 0;
				this.__offsetCount = 10;
			}



		});

// ListAllTechnicalAttributes class end.

// CreateNewTechnicalAttributesTemplate class start.
	
	Ext.define("com.servicemax.client.installigence.admin.CreateNewTechnicalAttributesTemplate", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

			__sections:null,
			__currentTemplateRecord: null,
			__currentApplicationCriteriaRecords: null,
			deletedTACriteriaIds:null,

			constructor: function(config) {
				var me = this;
				me.__sections = [];
				me.__currentTemplateRecord = {};
				me.__currentApplicationCriteriaRecords = [];
				me.deletedTACriteriaIds = [];

				//technical Attributes Template Model.
				Ext.define('technicalAttributesTemplateModel', {
						    extend: 'Ext.data.Model',
						    fields: [
						        {name: 'title',  type: 'string'},
						        {name: 'description',   type: 'string'},
						        {name: 'template_json',   type: 'string'},
						        
						    ],

						    validate: function() {
						        
						    }
					});
				
				config = config || {};
				

				 me.titleLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        text: $TR.TA_TEMPLATE,
			        cls: 'piq-setup-new-ta-title-labele',
			        margin:'20 0 10 10',
			       
			        
			    };

				me.titleTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : false,
	    		   editable : true,
	    		   cls: 'piq-setup-new-ta-title-text',
	    		   margin:'20 0 10 10',
	    		   width: '90%',
	    		   labelStyle: 'width:150px; white-space: nowrap;', 
	    		   fieldLabel: $TR.TEMPLATE_NAME +' <span class="req" style="color:red">*</span>',
	    	   });

				me.descriptionTextAreaField = {	xtype     : 'textareafield',
			        grow      : true,
			        allowBlank: false,
			        name      : 'description',
			        cls: 'piq-setup-new-ta-description',
			        fieldLabel: $TR.DESCRIPTION +' <span class="req" style="color:red">*</span>',
			        margin:'20 0 10 10',
			        width: '90%',
			        id:'taTemplateDescriptionField',
			        labelStyle: 'width:150px; white-space: nowrap;',
			    };


			    
			    //temp: hardcoded org name 
			   
			   // var OrgNamespace = 'SVMXDEV';
			    var OrgNamespace = SVMX.OrgNamespace;
			   	var productObjectdescribe = config.metadata['Product2'];
			    var productLines = null;
			    var productFamily = null;
			    var i=0;
			    for(i=0; i<productObjectdescribe.fields.length; i++){

			    	var field = productObjectdescribe.fields[i];
			    	if(field.type == "PICKLIST" && field.fieldAPIName == OrgNamespace + "__Product_Line__c"){

			    		productLines = field.picklistValues;

			    	}else if(field.type == "PICKLIST" && field.fieldAPIName == 'Family'){

			    		productFamily = field.picklistValues;

			    	}
			    }

			  	var productLineData = [{fieldLabel: "--None--", fieldName: $TR.NONE}];
				var pLine = 0, pLineLength = 0;
				if(productLines)pLineLength = productLines.length;
				for(pLine = 0; pLine < pLineLength; pLine++) {
					
						productLineData.push(productLines[pLine]);
					
				}

				me.productLineStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['fieldLabel', 'fieldName'],
			        data: productLineData
			    });

			    me.productLineComboBox = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.PRODUCT_LINE,
			        store: me.productLineStore,
			        cls: 'piq-setup-new-ta-productline-combobox',
			        labelWidth: 140,
			        width: '30%',
			        queryMode: 'local',
			        displayField: 'fieldName',
			        labelAlign: 'top',
			        editable: false,
			        region: 'center',
			        recordIndex:null, // TODO: required this variable to get rec Id from dataModel
			        listeners: {
			        	select: {
			        		
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('fieldName'));
						}
			        	
						
			        }
				});


				var productFamilyData = [{fieldLabel: "--None--", fieldName: $TR.NONE}];
				var pFamily = 0, pFamilyLength = productFamily.length;
				for(pFamily = 0; pFamily < pFamilyLength; pFamily++) {
					
						productFamilyData.push(productFamily[pFamily]);
					
				}

				me.productFamilyStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['fieldLabel', 'fieldName'],
			        data: productFamilyData
			    });

			    me.productFamilyComboBox = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.PRODUCT_FAMILY,
			        store: me.productFamilyStore,
			        cls: 'piq-setup-new-ta-productfamily-combobox',
			        labelWidth: 140,
			        width: '30%',
			        queryMode: 'local',
			        displayField: 'fieldName',
			        labelAlign: 'top',
			        editable: false,
			        recordIndex:null, // TODO: required this variable to get rec Id from dataModel
			        listeners: {
			        	
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('fieldName'));
						}
			        	
			        	
						
			        }
				});

				 me.productReferenceField = SVMX.create('com.servicemax.client.installigence.admin.productReferenceField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   cls: 'svmx-lookup-field',
	    		   cls: 'piq-setup-new-ta-product-referance',
	    		   width: '30%',
	    		   fieldLabel: $TR.PRODUCT,
	    		   labelAlign: 'top',
	    		    margin:'20 10 10 0',
	    		   meta: config.metadata,
	    		   recordIndex:null // TODO: required this variable to get rec Id from dataModel
	    		  
	    	   });
	    	   

	    	 
			    
			    me.criteriaToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0',
					cls: 'piq-setup-new-ta-criteria-toolbar',
					width: '100%'
				});
				me.criteriaToolbar.add(me.productReferenceField);
				//me.criteriaToolbar.add(me.__lookupText);
				me.criteriaToolbar.add(me.productLineComboBox);
				me.criteriaToolbar.add(me.productFamilyComboBox);
				
			   

			    me.criteriaLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        text: $TR.APPLICATION_CRITERIA,
			        cls: 'piq-setup-new-ta-criteria-label',
			        margin:'20 0 10 10'
			        
			    };

			     me.defineTemplateHeaderLabel = {
			        xtype: 'label',
			        forId: 'myFieldId',
			        cls: 'piq-setup-new-ta-criteria-header-label',
			        text: $TR.DEFINE_TA_SECTION,
			        margin:'10 0 10 10'
			        
			    };

			    var sectionPanelObject = SVMX.create('com.servicemax.client.installigence.admin.SectionPanel',{
					metadata: config.metadata,id:'SectionPanel',
					cls: 'piq-setup-ta-section',
					parentContext: this,
					margin:'20 0 10 10'
				});

			    me.__sections.push(sectionPanelObject);

				if(this.__sections.length == 1)
				this.__shouldDisableDeleteSectionButtonForFirstSection(true);


			    var addNewSectionButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					cls: 'plain-btn',
					//ui: 'svmx-toolbar-icon-btn',
					//scale: 'large',
					//iconCls: 'plus-icon',
					tooltip: $TR.ADD,
					text:$TR.ADD_SECTION,
					disabled: false,
					handler : function(){
						me.__addNewSection();
						

					}
				});

				 me.addNewSectionToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0',
					cls: 'piq-setup-new-ta-add-new-section-toolbar',
					width: '100%'
				});
				me.addNewSectionToolbar.add(addNewSectionButton);
				me.bottomSpaceToolItems = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0',
					cls: 'piq-setup-new-ta-bottom-space-toolbar',
					width: '100%',
					height: 150
				});

				config.items = [me.titleLabel,me.titleTextFields,me.descriptionTextAreaField,me.criteriaLabel,me.criteriaToolbar,me.defineTemplateHeaderLabel,sectionPanelObject,me.addNewSectionToolbar,me.bottomSpaceToolItems];

				
	    	   
			this.callParent([config]);
			},


			__getRandomArbitrary: function(){
				 return 'section'+Math.floor((Math.random() * 100) + 1);
			},

			__addNewSection: function(){
				var sId = this.__getRandomArbitrary();
				var sectionPanelObject = SVMX.create('com.servicemax.client.installigence.admin.SectionPanel',{
					metadata: this.config.metadata,id:sId,
					cls: 'piq-setup-ta-section',
					parentContext: this,
					margin:'20 0 10 10'
				});
				this.__sections.push(sectionPanelObject);

				var atIndex = this.items.indexOf(this.addNewSectionToolbar);
				this.insert(atIndex, sectionPanelObject);

				
				if(this.__sections.length >1){
					this.__shouldDisableDeleteSectionButtonForFirstSection(false);
				}else if(this.__sections.length == 1){
					this.__shouldDisableDeleteSectionButtonForFirstSection(true);
				}
				
			},

			__removeSection: function(objectId){
				
				var length = this.__sections.length;

				if(length > 1){

					for(var i =0; i<length; i++){

						var sectionObject = this.__sections[i];
						if(sectionObject.id == objectId){
						this.__sections.splice(i, 1);
						var objectToRemove = Ext.getCmp(objectId);
					    this.remove(objectToRemove);
					    if(this.__sections.length == 1)
						this.__shouldDisableDeleteSectionButtonForFirstSection(true);	
					    return;
						}

					}
					
				}
				
				
			},
			__shouldDisableDeleteSectionButtonForFirstSection: function(value){
				var firstSection = Ext.getCmp(this.__sections[0].id);
					firstSection.deleteSectionButton.setDisabled(value);
			},
			resetPage: function(){
				this.titleTextFields.setValue('');
				Ext.getCmp("taTemplateDescriptionField").setValue('');
				
				
				this.productLineComboBox.setValue(this.productLineStore.getAt(0).get('fieldName'));
				this.productFamilyComboBox.setValue(this.productFamilyStore.getAt(0).get('fieldName'));
				this.productReferenceField.lookupText.setValue('');
				this.productReferenceField.selectedProduct = null;
				//this.productReferenceField.selectedProduct = {};
				this.productReferenceField.recordIndex = null;
				this.productFamilyComboBox.recordIndex = null;
				this.productLineComboBox.recordIndex  = null;
				this.deletedTACriteriaIds = [];
				this.__currentTemplateRecord = {};


				
				var l = this.__sections.length;
				for(var i=0; i<l; i++){
					var objectToRemove = Ext.getCmp(this.__sections[i].id);
					this.remove(objectToRemove);
				}
				this.__sections.splice(0, l);
				this.__addNewSection();


			},
			reloadTemplatePage: function(record){

				
				this.__currentTemplateRecord = record;
				var templateTitle = SVMX.OrgNamespace+'__SM_Title__c';
				var templateDescription = SVMX.OrgNamespace+'__SM_Template_Description__c';
				var templateJSON  = SVMX.OrgNamespace+'__SM_Template_Json__c';

				var templatePicklistId = record.data[SVMX.OrgNamespace + '__SM_Picklist_Id__c'];
				if(templatePicklistId && this.config.parentContext.__templatePicklistSfIds) {
					var templatePicklistSfIdArray = templatePicklistId.split(',');
					for(var i = 0; i < templatePicklistSfIdArray.length; i++) {
						var picklistSfId = templatePicklistSfIdArray[i];
						this.config.parentContext.__templatePicklistSfIds[picklistSfId] = picklistSfId
					}
				}
				
				var sectionDetails = this.__parseJSONdata(record.data[templateJSON]);
				this.__loadAllSectionDetails(sectionDetails);

				this.titleTextFields.setValue(record.data[templateTitle]);
				Ext.getCmp("taTemplateDescriptionField").setValue(record.data[templateDescription]);
				this.__getTemplateCriteriaInfo(record.data.Id);

			},
			__parseJSONdata: function(jsonString){
				var obj = JSON.parse(jsonString);
				return obj;
			},
			__loadAllSectionDetails: function(sectionDetails){
				var fields = sectionDetails.fields;
				var l = fields.length;
				this.config.parentContext.__templatePicklistModel = sectionDetails.picklist;
				
				if(l > this.__sections.length){
					for(var i=1; i<l; i++){
						this.__addNewSection();
					}
				}
				this.__loadValuesForAllSections(fields);

			},

			__loadValuesForAllSections: function(sections){
				var l = this.__sections.length;
				
				for(var i=0; i<l; i++){
					var sectionPanelObject;
					sectionPanelObject = this.__sections[i];
					sectionPanelObject.titleTextFields.setValue(sections[i].title);
					Ext.getCmp('textareafield'+sectionPanelObject.id).setValue(sections[i].description);

					var attributes = sections[i].technicalAttributes;
					if(!attributes) {
	        		 attributes = [];
	        		 }
					for(var iAttributs = 0; iAttributs < attributes.length; iAttributs++){
						attributes[iAttributs].isNewAttribute = 'NO';
						if(attributes[iAttributs].format === "Picklist") {
							attributes[iAttributs].defaultValue = attributes[iAttributs].picklistName;
						}
					}
					sectionPanelObject.attributesStore.loadData(attributes);
				}
			},


			__getTemplateCriteriaInfo: function(templateId){
				SVMX.getCurrentApplication().blockUI();
				var params = {};
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN.GET_TA_TEMPLATE_CRITERIA" , this, 
					{request : { context : this,taTemplateId:templateId, handler : this.__getTemplateCriteriaInfoCompleted, text : params.text}});
			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
			},

			__getTemplateCriteriaInfoCompleted: function(data){
				this.__currentApplicationCriteriaRecords = data;
				var l = data.length;
				var pLine   =  SVMX.OrgNamespace+'__SM_Product_Line__c';
				var pFamily =  SVMX.OrgNamespace+'__SM_Product_Family__c';
				var pId     =  SVMX.OrgNamespace+'__SM_Product__c';
				var pName   =  SVMX.OrgNamespace+'__SM_Product__r';

				for(var iCriteriaRec=0; iCriteriaRec<l; iCriteriaRec++){
						
						var criteriaObject = data[iCriteriaRec];
						if(criteriaObject[pLine] !== null){
							this.productLineComboBox.setValue(criteriaObject[pLine]);
							this.productLineComboBox.recordIndex = criteriaObject.Id;
						}
						

						if(criteriaObject[pFamily] !== null){
							this.productFamilyComboBox.setValue(criteriaObject[pFamily]);
							this.productFamilyComboBox.recordIndex = criteriaObject.Id;;
						}
						
						
						if(criteriaObject[pId] !== null)
						this.productReferenceField.lookupText.setValue(criteriaObject[pName]['Name']);

						if(criteriaObject[pId] !== null){
							this.productReferenceField.selectedProduct = {'Id':criteriaObject[pId]};
							this.productReferenceField.recordIndex = criteriaObject.Id;;
						}

						criteriaObject = null;
						
				}

				SVMX.getCurrentApplication().unblockUI();
				
			},
			getAllAttributesName: function(){
				var attributesName = [];
				var sections = this.__sections;
				for(var iSec=0; iSec<sections.length; iSec++){
					var attributeItems = sections[iSec].attributesStore.data.items;
					for(var iAttri=0; iAttri<attributeItems.length; iAttri ++){
						if(attributeItems[iAttri].data.label) attributesName.push(attributeItems[iAttri].data.label);
					}
				}
				return attributesName;
			},
			isAttributeLabelEmpty: function(){
				var isEmpty = false;
				var sections = this.__sections;
				for(var iSec=0; iSec<sections.length; iSec++){
					var attributeItems = sections[iSec].attributesStore.data.items;
					for(var iAttri=0; iAttri<attributeItems.length; iAttri ++){
						if(attributeItems[iAttri].data.label.trim() === "" || attributeItems[iAttri].data.format === "" ){
							isEmpty = true;
							var attribute = {
								sectionIndex: iSec,
								attributeIndex: iAttri,
								section: sections[iSec]
							}
							break;
						} 
					}
					if(isEmpty) break;
				}
				var returnObject = {
					isEmpty: isEmpty,
					attribute: attribute
				};
				return returnObject;
			},
			heighlightAttribute: function(attribute){
				var scrollPosition = (attribute.sectionIndex+1) * 500;
				this.body.scrollTo('top',scrollPosition);
				var rowIndex = attribute.attributeIndex;
	       		var view = attribute.section.attributesGrid.getView();
              	Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
              	var row = view.getRow(rowIndex); 
              	Ext.get(row).addCls('piq-setup-new-attributes-row');
			}

		});

// CreateNewTechnicalAttributesTemplate class end.


// productReferenceField class start.
   Ext.define("com.servicemax.client.installigence.admin.productReferenceField", {
	         extend: "Ext.form.FieldContainer",
	         
	         selectedProduct:null,

	         constructor: function(config) {
	        	 var me = this;
	        	 config = config || [];
	        	 selectedProduct = {};
	               
	        	 config.items = config.items || [];
	        	 config.layout = 'hbox';
	        	

	             
                 me.lookupBtn = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                	 iconCls: 'svmx-lookup-icon',
                	 cls: 'piq-setup-ta-product-lookup-button',
 					 margin: '0, 5', 
                     flex: 1,
                     handler : function(){
					       		
					       		var getAllProducts = SVMX.create("com.servicemax.client.installigence.admin.productLookup.ProductLookup", {
	                objectName : 'Product2',
	                columns : [{name : "Name"}],
	                multiSelect : false,
	                sourceComponent : this,
	                searchText:me.lookupText.value,
	                cls : 'piq-setup-ta-product-window',
	                mvcEvent : "GET_ALL_PRODUCTS"
			   });
			   me.lookupText.setValue('');
			   getAllProducts.find().done(function(results){
	               me.selectedProduct = results;
	               me.lookupText.setValue(results.Name);
	               
			   });
					       			}
                 });
	        	 
	        	 me.lookupText = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                     minWidth: 5,
                     cls: 'piq-setup-ta-product-lookup-textfield',
                     width: '100%',
                     listeners: {
                     	change: function(field) {
								if(!field.value)
									me.selectedProduct = null;	
							}
                    	 
                     }
                 });	       	 
	        	
	        	 config.items.push(me.lookupText);
	        	 config.items.push(me.lookupBtn);
	        	 
	        	 this.callParent([config]);
	         },
	         
	        
	     });

// productReferenceField class end.

// SectionPanel class start.
		Ext.define("com.servicemax.client.installigence.admin.SectionPanel", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

	         
	         constructor: function(config) {
	        	var me = this;
	        	
	        	config = config || {};

	        	
	        	 me.deleteSectionButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					cls: 'plain-btn',
					//ui: 'svmx-toolbar-icon-btn',
					//scale: 'small',
					//iconCls: 'delet-icon',
					tooltip: $TR.DELETE,
					text:$TR.REMOVE_SECTION,
					cls: 'piq-setup-ta-delete-section',
					sectionId: config.id,
					disabled: false,
					parent:config.parentContext,
					handler : function(dButton, eventObject){
						var i = dButton.sectionId;
						dButton.parent.__removeSection(i);

					}
				});
				config.dockedItems= [{
								    xtype: 'toolbar',
								    dock: 'top',
								    items: [me.deleteSectionButton]
								}];

	        	me.titleTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   cls: 'piq-setup-ta-section-title-textfield',
	    		   editable : true,
	    		   margin:'20 0 10 0',
	    		   width: '90%',
	    		   fieldLabel: $TR.SECTION_NAME,
	    		   labelStyle: 'width:150px; white-space: nowrap;', 

	    	   });

				me.descriptionTextAreaField = {	xtype     : 'textareafield',
			        grow      : true,
			        name      : 'description',
			        cls: 'piq-setup-ta-section-description-textarea',
			        fieldLabel: $TR.DESCRIPTION,
			        id: 'textareafield' + config.id ,
			        margin:'20 0 10 0',
			        anchor    : '100%',
			        width: '90%',
	    			labelStyle: 'width:150px; white-space: nowrap;', 
			    };

	        	me.attributeTypeStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['value', 'label'],
			        data: [
		        		{ value: 'static', label: 'Static'}
		        		
			        ]
   	 			});
   	 			me.formatTypeStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['value', 'label'],
			        data: [
		        		{ value: 'Number', label: 'Number'},
		        		{ value: 'Text', label: 'Text'},
		        		{ value: 'Boolean', label: 'Boolean'},
		        		{ value: 'Picklist', label: 'Picklist'} 
		        		
			        ]
   	 			});

   	 			me.readOnlyTypeStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['value', 'label'],
			        data: [
		        		{ value: 'yes', label: 'YES'},
		        		{ value: 'no', label: 'NO'}
		        		
			        ]
   	 			});

   	 			me.isMandatoryTypeStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['value', 'label'],
			        data: [
		        		{ value: '1', label: 'YES'},
		        		{ value: '0', label: 'NO'}
		        		
			        ]
   	 			});

/*
				Ext.define('attributesModel', {
				    extend: 'Ext.data.Model',
				    fields: [ {name: 'name',  type: 'string'},
				    		{name: 'attributeType',   type: 'string'},
				    		{name: 'format',   type: 'string'},
				    		{name: 'value',   type: 'string'},
				    		{name: 'unit',   type: 'string'},
				    		{name: 'readOnly',   type: 'string'},
				    		{name: 'default',   type: 'string'},

				              ]
				});

*/
				me.attributesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				   // model: 'attributesModel',
				     fields: [ {name: 'label',  type: 'string'},
				    		{name: 'type',   type: 'string'},
				    		{name: 'format',   type: 'string'},
				    		//{name: 'value',   type: 'string'},
				    		{name: 'unit',   type: 'string'},
				    		{name: 'readOnly',   type: 'string'},
				    		{name: 'defaultValue',   type: 'string'},
				    		{name: 'isNewAttribute',   type: 'string'},
				    		{name: 'req',   type: 'string'},
				    		{name: 'maxNumber',   type: 'string'},
				    		{name: 'minNumber',   type: 'string'},
				    		{name: 'message',   type: 'string'},
				              ],
				    data: [			        
				        
				    ]
				});
				
	        	me.attributesGrid = SVMX.create('com.servicemax.client.installigence.admin.TechnicalAttributesGrid',{
					cls: 'grid-panel-borderless panel-radiusless piq-setup-ta-grid',
					store: me.attributesStore,
					height: 300,
					width: 'calc(100% - 25px)',
					margin: '7 7 7 7',
					autoScroll:true,
					layout: 'fit',
				    selType: 'cellmodel',
				    parentContext : me,
				    topPanelContext:config.parentContext,
				    attributeTypeStore: me.attributeTypeStore,	
				    formatTypeStore: me.formatTypeStore,	
				    readOnlyTypeStore: me.readOnlyTypeStore,
				    isMandatoryTypeStore: me.isMandatoryTypeStore,        
				    plugins: [
				              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
				                  clicksToEdit: 2
				              })
				          ],
				    viewConfig: {
				        getRowClass: function(record, index) {
				            if(record.data.format === "Picklist") {
				            	return 'piq-setup-ta-row';
				            }else if(record.data.label == ""){
				            	return 'piq-setup-new-attributes-row';
				            }
				            
				        }
				    },      
				    listeners : {
				    	celldblclick : function(cell , td , cellIndex , record , tr , rowIndex , e , eOpts) {
				    	},
				    	cellclick : function(cell , td , cellIndex , record , tr , rowIndex , e , eOpts) {
				    		if(record.data.format === "Picklist" && cell.config.grid.columns[cellIndex].dataIndex === "defaultValue") {
				    			var technicalAttributesContext = this.config.parentContext.parentContext.parentContext;
				    			var picklistObject = SVMX.create("com.servicemax.client.installigence.admin.picklist.Picklist",{
				    				mvcEvent:'GET_ALL_TA_PICKLIST_DEFINATION', selectedCell : cell, cellSelectedRecord : record, technicalAttributesContext : technicalAttributesContext
				    			});
			    			}

			    			var row = this.getView().getRow(rowIndex); 
              				Ext.get(row).removeCls('piq-setup-new-attributes-row');
				    		
				    	},
				    	edit : function(editor,e,eOpts) {
				    		var record = e.record;
				    		var selectTag = $TR.SELECT;
			    			if(record.data.format === "Picklist") {
			    				if(record.data.defaultValue === " " || record.data.defaultValue === selectTag) {
			    					record.set('defaultValue',selectTag); 
			    					record.set('picklistName',selectTag); 
			    					record.set('defaultDisplayValue',selectTag); 
			    				}	
			    			}
				    	}

				    }      
	            });
	        	
	            config.items = [];
	            config.items.push(me.titleTextFields);
	            config.items.push(me.descriptionTextAreaField);
				config.items.push(me.attributesGrid);
	            
	          
	        	this.callParent([config]);
	         }
	        
	         
	        
	     });
// SectionPanel class end.

//TechnicalAttributesGrid class start.
	Ext.define("com.servicemax.client.installigence.admin.TechnicalAttributesGrid", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
			__currentEditingRec: null,

			constructor: function(config) {
				var me = this;
				var config = config || {};


				var addAttributesButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					text:$TR.ADD,
					cls:'piq-setup-add-button',
					disabled: false,
					handler : function(){
						me.addAttributeRecord({name:''});
					}
				});
				config.dockedItems= [{
								    xtype: 'toolbar',
								    dock: 'top',
								    items: [{
								        xtype: 'tbfill'
								    },addAttributesButton]
								}];
				config.columns = [{
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
		                },  		                
  		                renderer: function (value, metadata, record) {
  		                	config.columns[0].items[0].iconCls = 'delet-icon';
  		                	if(record && record.data && record.data.req){
  		                		if(record.data.req === '1'){
  		                			record.data.req = 'YES';
  		                		} else if(record.data.req === '0'){
  		                			record.data.req = 'NO';
  		                		}
  		                	}
  		                }
                }];

                var me = this;
                config.columns.push(this.createTextBoxColumn(
                	{	
                		text: $TR.ATTRIBUTE_NAME, 
                		dataIndex: 'label',
                		minWidth: 150, 
                		flex: 1,
                		topPanelContext:config.topPanelContext,
                		listeners : {
                			blur:function(field){
                				setTimeout(function() {
	                				var allAttributes = field.topPanelContext.getAllAttributesName();
	                				var newAttributeName = field.value;
	                				var numOflabel = allAttributes.reduce(function(count,label){
	    										if(label.toLowerCase()  === newAttributeName.toLowerCase())
	       										count++;
	    										return count;
											},0);
	                				if(numOflabel > 1){
	                					var fieldContext = field;
	                					Ext.Msg.alert({
	                								title:$TR.MESSAGE_ERROR, message: $TR.ATTRIBUTE_NAME_ALREADY_EXISTS,
	               									 buttonText:{ ok: $TR.OK_BTN },
	              								     closable:false,
	              								     fieldContext:fieldContext,
	              								     fn: function(argument) {
	              								     	var fld = fieldContext;
	              								     	Ext.defer(function(){
															   fld.focus();
														}, 0);

	              								     }
	            							});
	                				}
                				
								}, 200);
                				
                			}
                		}
                	}));
                config.columns.push(this.createComboBoxColumn({text: $TR.TYPE, dataIndex: 'type', minWidth: 100,  flex: 1, 
		    		   store: config.attributeTypeStore}));
                config.columns.push(this.createComboBoxColumn({text: $TR.FORMATE, dataIndex: 'format', minWidth: 100,  flex: 1, 
		    		   store: config.formatTypeStore}));
               // config.columns.push(this.createTextBoxColumn({text: 'Values', dataIndex: 'value', flex: 1, listeners :null}));
                config.columns.push(this.createTextBoxColumn({text: $TR.UNIT, dataIndex: 'unit', minWidth: 100,  flex: 1, listeners :null}));
                config.columns.push(this.createComboBoxColumn({text: $TR.READY_ONLY, dataIndex: 'readOnly', minWidth: 100,  flex: 1, 
		    		   store: config.readOnlyTypeStore}));
                config.columns.push(this.createComboBoxColumnIsMandatory({text:$TR.MANDATORY||'Mandatory', dataIndex: 'req', minWidth: 125,  flex: 1, listeners :null, store: config.isMandatoryTypeStore})); //IsMeditory
                config.columns.push(this.createTextBoxColumnForDefaultField({text: $TR.DEFAULT_VALUES, dataIndex: 'defaultValue', minWidth: 160,  flex: 1, listeners :null,tdCls: 'x-change-cell', 
                	renderer: function(value) {
                        return Ext.String.htmlEncode(value);
                    }}));

                config.columns.push(this.createTextBoxColumnForMaxField({text:$TR.MAX_VALUE||'MAX Value', dataIndex: 'maxNumber', minWidth: 100,  flex: 1, listeners :null})); // Max
                config.columns.push(this.createTextBoxColumnForMinField({text:$TR.MIN_VALUE||'MIN Value', dataIndex: 'minNumber', minWidth: 100,  flex: 1, listeners :null})); // Min
                config.columns.push(this.createMessageBoxColumnForMinField({text:$TR.MESSAGE||'Message', dataIndex: 'message', minWidth: 150,  flex: 1, listeners :null})); // Min
                this.callParent([config]);
			},		
				
			createTextBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   listeners : fieldInfo.listeners,
	    		   isNewAttribute: 'YES',
	    		   topPanelContext:fieldInfo.topPanelContext
	    	   });
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   var isNew;
	    		   if(currentRecord.get('isNewAttribute')){
	    		   		isNew = currentRecord.get('isNewAttribute');
	    		   }else{
	    		   		isNew = 'YES';
	    		   }
	    		   txtboxCol.isNewAttribute = isNew;
	    		   return txtboxCol;
               };
               
	    	   return fieldInfo;
	       },

	       createTextBoxColumnForDefaultField: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){

	    	   		var returnEditor = null;
	    	   		var currentFormate = currentRecord.get('format');
	    	   		if(currentFormate == 'Number'){
	    	   			
	    	   			returnEditor = Ext.create('Ext.grid.CellEditor', { 
						        field: Ext.create('Ext.form.field.Number', {
						            allowBlank: false
						            
						        })
						    });

	    	   		}else if(!currentFormate || currentFormate == 'Text'){
	    	   			
	    	   			returnEditor = Ext.create('Ext.grid.CellEditor', { 
						        field: Ext.create('Ext.form.field.Text', {
						            allowBlank: false
						            
						        })
						    });

	    	   		}else if(currentFormate == 'Boolean'){
	    	   			 returnEditor = Ext.create('Ext.grid.CellEditor', { 
						        field: {
			                        xtype: 'combobox',
			                        forceSelection: true,
			                        editable: false,
			                        triggerAction: 'all',
			                        allowBlank: false, 
			                        valueField:'value',
			                        displayField:'descr',
			                        store: Ext.create('Ext.data.Store',{
			                            fields:['descr','value'],
			                            data:[{
			                                descr:'YES',
			                                value:'YES'
			                            },{
			                                descr:'NO',
			                                value:'NO'
			                            }]
			                        })
			                    }
						    });

	    	   		}else if(currentFormate == 'Picklist') {
						    returnEditor = null;
	    	   		}
	    	   	return returnEditor;

	    		   
               };
               
	    	   return fieldInfo;
	       },

	       createMessageBoxColumnForMinField: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    	   		var returnEditor = null;
	    	   		var currentFormate = currentRecord.get('format');
	    	   		returnEditor = Ext.create('Ext.grid.CellEditor', { 
						field: Ext.create('Ext.form.field.Text', {
						})
					});
	    	   	return returnEditor;

	    		   
               };
               
	    	   return fieldInfo;
	       },

	       createTextBoxColumnForMaxField: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    	   		var returnEditor = null;
	    	   		var currentFormate = currentRecord.get('format');
	    	   		returnEditor = Ext.create('Ext.grid.CellEditor', { 
						field: Ext.create('Ext.form.field.Number', {
						})
					});
	    	   	return returnEditor;

	    		   
               };
               
	    	   return fieldInfo;
	       },

	       createTextBoxColumnForMinField: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    	   		var returnEditor = null;
	    	   		var currentFormate = currentRecord.get('format');
	    	   		returnEditor = Ext.create('Ext.grid.CellEditor', { 
						field: Ext.create('Ext.form.field.Number', {
						})
					});
	    	   	return returnEditor;

	    		   
               };
               
	    	   return fieldInfo;
	       },

	       createComboBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var optionPicklist = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					displayField: 'label',
			        queryMode: 'local',
			        editable: false,
			        //valueField: 'value',
			        fieldName: fieldInfo.dataIndex,
			        store: fieldInfo.store,
			        parentContext: me,
			        listeners: {
   						select: function(combo, record, index) {
							if(this.parentContext.__currentEditingRec){
								if(combo.fieldName == "format"){
									this.parentContext.__currentEditingRec.set('defaultValue',' ');
								} else if(combo.fieldName == "readOnly" && record.data.value =='yes'){
									this.parentContext.__currentEditingRec.set('req','0');
								}
							}
					 	}
					}
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.parentContext = me,
	    	   fieldInfo.getEditor = function(currentRecord){
	    	   		if(this.parentContext.__currentEditingRec) this.parentContext.__currentEditingRec = null;
	    	   		this.parentContext.__currentEditingRec = currentRecord;

	    		   var currTypeValue = currentRecord.get('parentProfileId');
	    		    
	    		  // if(currentRecord.get('isGlobal') === true && currTypeValue !== me.selectedProfileId) {
	    			//   return "";
	    		   //}
	    		   optionPicklist.setRecord(currentRecord);
                   return optionPicklist;
               };
	    	   return fieldInfo;	    	   
	    	   
	       },

	       createComboBoxColumnIsMandatory: function(fieldInfo) {
	    	   var me = this;
	    	   var optionPicklist = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					displayField: 'label',
			        queryMode: 'local',
			        editable: false,
			        fieldName: fieldInfo.dataIndex,
			        store: fieldInfo.store,
			        parentContext: me,
			        listeners: {
   						select: function(combo, record, index) {
      						if(this.parentContext.__currentEditingRec){
								if(combo.fieldName == "req" && record.data.value =='1'){
									this.parentContext.__currentEditingRec.set('readOnly','');
								}
							}
						}
					}
	    	   	});	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.parentContext = me,
	    	   fieldInfo.getEditor = function(currentRecord){
	    	   		if(this.parentContext.__currentEditingRec){
	    	   			this.parentContext.__currentEditingRec = null;
	    	   		}
	    	   		this.parentContext.__currentEditingRec = currentRecord;
	    		   	var currTypeValue = currentRecord.get('parentProfileId');
	    		   	optionPicklist.setRecord(currentRecord);
                   	return optionPicklist;
               	};
	    	   return fieldInfo;	    	   
	    	   
	       },
	       addAttributeRecord: function(records){
	       		if (!records) return;
	       		var rowIndex = this.getStore().count();
	       		this.store.insert(this.getStore().count(), records);
	       		var view = this.getView();
              	Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
              	//view.select(rowIndex);
              	var row = this.getView().getRow(rowIndex-1); 
              	Ext.get(row).removeCls('piq-setup-new-attributes-row');
              	

	       	}
	       
		});
		

//TechnicalAttributesGrid class end.

	}
// init ends here

 })();



// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\useractions.js
(function(){
	var setupUserActions = SVMX.Package("com.servicemax.client.installigence.admin.useractions");

setupUserActions.init = function() {
		
		/*Ext.define("com.servicemax.client.installigence.admin.userStandardActionsGrid", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
			
			constructor: function(config){
				var me = this;
				var config = config || {};
				config.viewConfig = {
		    	        
	    	        getRowClass: function(record, index) {
	    	        }
	    	    };
				config.columns = [];
				var me = this;
				config.columns.push(this.createCheckBoxColumn({text: $TR.HIDE_STANDARD_ACTIONS, dataIndex: 'isHidden'}));
				config.columns.push(this.createTextBoxColumn({text: $TR.UAF_GRID_COL_NAME, dataIndex: 'name', width:200, flex: 1, listeners : config.nameFieldListner}));
				config.columns.push(this.createTextBoxColumn({text: $TR.UAF_GRID_COL_ACTION, dataIndex: 'action', width:200, flex: 1, listeners : config.nameFieldListner}));
				this.callParent([config]);
			},
			createCheckBoxColumn: function(fieldInfo) {
		    	   var me = this;
		    	   fieldInfo = fieldInfo || {};
		    	   fieldInfo.xtype = 'checkcolumn';
		    	   fieldInfo.menuDisabled = true;
		    	   fieldInfo.sortable = false;
		    	   fieldInfo.renderer = function(value, meta, record){
		    		   return (new Ext.ux.CheckColumn()).renderer(value);
		           };
		           fieldInfo.listeners = { 
		        		   beforecheckchange  : function( component, rowIndex, checked, eOpts ){
		        			   return true;
		           			}
			           }
		    	   return fieldInfo;
		       },
			createTextBoxColumn: function(fieldInfo) {
		    	   var me = this;
		    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
		    		   allowBlank : true,
		    		   editable : false,
		    		   listeners : fieldInfo.listeners
		    	   });
		    	   
		    	   var fieldInfo = fieldInfo || {};
		    	   fieldInfo.sortable = false;
		    	   fieldInfo.editable = true;
		    	   fieldInfo.getEditor = function(currentRecord){
		    		   return txtboxCol;
	               };
		    	   return fieldInfo;
		       },
		       createActionFieldColumn: function(fieldInfo) {
		    	   var me = this;
		    	   var valueMapData = [];
		    	   var i = 0;
		    	   var ibFieldMappingsStore = fieldInfo.valueMapStore;
		    	   
		    	   this.ibFieldMappingsComboBox = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
						store: ibFieldMappingsStore,
				        displayField: 'mapName',
				        valueField: 'mapId',
				        queryMode: 'local',
				        editable: false,
				        fieldName: 'action'
		    	   });
		    	   
		    	   fieldInfo = fieldInfo || {};
		    	   fieldInfo.getEditor = function(currentRecord) {
		    		   var gridStore = me.getStore();
		    		   var currTypeValue = currentRecord.get('actionType_key');
		    		   if(!currTypeValue){
		    		   		currTypeValue = currentRecord.data.actionType;
		    		   }
		    		   //change this to valuefield, now comparing with display field
		    		   if(currentRecord.get('isGlobal') === true && currentRecord.get('parentProfileId') !== me.selectedProfileId) {
		    			   return "";
		    		   } else if(currTypeValue === 'fieldupdate') {
						   me.ibFieldMappingsComboBox.setRecord(currentRecord);
		    			   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
								field: me.ibFieldMappingsComboBox
	                            });
		    		   }else {
		    			   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
	                                    field: me.createTextBoxColumn(fieldInfo)
	                                });
		    		   }
		    	   };
		    	   return fieldInfo;
		       },

		       getProfileRecords: function() {
		    	   var records = [];
		    	   this.store.each(function(rec) {          
		    			delete rec.data["id"];           		
		           		records.push(rec.data);
		    	   });
		    	   return records;
		       },
		       
		});*/
		
		Ext.define("com.servicemax.client.installigence.admin.userActionsGrid", {
	        extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
	        
	       constructor: function(config) {
	    	   
	    	   var me = this;
	    	   var config = config || {};
	    	   config.viewConfig = {
	    	        
	    	        getRowClass: function(record, index) {
	    	        	if (record.get('isGlobal') === true && record.get('parentProfileId') !== me.selectedProfileId) {
  		                    return 'svmx-disabled-row';
  		                }
  		                else
  		                {
  		                	return "user-actions-row";
  		                }
	    	        }
	    	    };
	    	   config.columns = [
                   {
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
		                    if (rec.get('isGlobal') === null || rec.get('isGlobal') === false 
		                    		|| (rec.get('isGlobal') === true && rec.get('parentProfileId') === me.selectedProfileId)) {
		                    	gridStore.remove(rec);
	  		                }		                    
		                },  		                
  		                renderer: function (value, metadata, record) {
  		                	if (record.get('isGlobal') === null || record.get('isGlobal') === false 
  		                			|| (record.get('isGlobal') === true && record.get('parentProfileId') === me.selectedProfileId)) {
	  		                    config.columns[0].items[0].iconCls = 'delet-icon';
	  		                } else {
	  		                    config.columns[0].items[0].iconCls = 'svmx-global-icon';
	  		                }
  		                }
                   }
               ];
	    	   var me = this;
	    	   config.columns.push(this.createTextBoxColumn({text: $TR.UAF_GRID_COL_NAME, dataIndex: 'name', width:200, flex: 1, listeners : config.nameFieldListner}));
	    	   if(!config.isFiltersGrid) {
		    	   config.columns.push(this.createComboBoxColumn({text: $TR.UAF_GRID_COL_TYPE, dataIndex: 'actionType', width:200, flex: 1, 
		    		   actionTypeStore: config.actionTypeStore}));
		    	   config.columns.push(this.createActionFieldColumn({text: $TR.UAF_GRID_COL_ACTION, sortable: false, 
		   				menuDisabled: true, dataIndex: 'action', width:200, valueMapStore: config.valueMapStore, actionURLStore: config.actionURLStore}));
	    	   }
	    	   config.columns.push(this.createCheckBoxColumn({text: $TR.UAF_GRID_COL_ISGLOBAL, dataIndex: 'isGlobal', minWidth: 150}));
	    	   this.callParent([config]);
	       },
	       
	       createCheckBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   fieldInfo = fieldInfo || {};
	    	   fieldInfo.xtype = 'checkcolumn';
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.renderer = function(value, meta, record){
	    		   var currTypeValue = record.get('parentProfileId');
	    		   if(record.get('isGlobal') === true && currTypeValue !== me.selectedProfileId) {
	    			   return "";
	    		   }
	    		   return (new Ext.ux.CheckColumn()).renderer(value);
	           };
	           fieldInfo.listeners = { 
        		   beforecheckchange  : function( component, rowIndex, checked, eOpts ){
        			   var row = component.getView().getRow(rowIndex),
        	            record = component.getView().getRecord(row);
        			   var currTypeValue = record.get('parentProfileId');
    	    		   if(record.get('isGlobal') === true && currTypeValue !== me.selectedProfileId) {
    	    			   return false;
    	    		   }
    	    		   return true;
           			}
	           }
	           fieldInfo.checkOnly = true;
	    	   
	    	   return fieldInfo;
	       },
	       
	       setIBFieldMappings: function(){
	    	   return this.ibFieldMappings;
	       },
	       
	       createActionFieldColumn: function(fieldInfo) {
	    	   
	    	   var me = this;
	    	   var valueMapData = [];
	    	   var i = 0;
	    	   
	    	   
	    	   var ibFieldMappingsStore = fieldInfo.valueMapStore;
	    	   var ibActionURLStore = fieldInfo.actionURLStore;
	    	   
	    	   this.ibFieldMappingsComboBox = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					store: ibFieldMappingsStore,
			        displayField: 'mapName',
			        valueField: 'mapId',
			        queryMode: 'local',
			        editable: false,
			        fieldName: 'action'
	    	   });	 //com.servicemax.client.installigence.ui.components.SVMXComboBox
	    	   

	    	   this.ibActionURLComboBox = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					store: ibActionURLStore,
			        displayField: 'actionURLName',
			        valueField: 'actionURLId',
			        queryMode: 'local',
			        editable: false,
			        fieldName: 'action'
	    	   });	 //com.servicemax.client.installigence.ui.components.SVMXComboBox
	    	   

	    	   fieldInfo = fieldInfo || {};
	    	   fieldInfo.getEditor = function(currentRecord) {
	    		   var gridStore = me.getStore();
	    		   var currTypeValue = currentRecord.get('actionType_key');
	    		   
	    		   if(!currTypeValue){
	    		   		currTypeValue = currentRecord.data.actionType;
	    		   }

	    		   //change this to valuefield, now comparing with display field
	    		   if(currentRecord.get('isGlobal') === true && currentRecord.get('parentProfileId') !== me.selectedProfileId) {
	    			   return "";
	    		   } else if(currTypeValue === 'fieldupdate') {
					   me.ibFieldMappingsComboBox.setRecord(currentRecord);//.get('action_key')
	    			   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
							field: me.ibFieldMappingsComboBox
                            });
	    		   }else if(currTypeValue === 'customurl'){
	    		   		me.ibActionURLComboBox.setRecord(currentRecord);//.get('action_key')
	    			   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
							field: me.ibActionURLComboBox
                            });
	    		   }else{
	    			   return SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditor', {
                                    field: me.createTextBoxColumn(fieldInfo)
                                });
	    		   }
	    	   };
	    	   return fieldInfo;
	       },
	       
	       createTextBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   listeners : fieldInfo.listeners
	    	   });
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.editable = true;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   var currTypeValue = currentRecord.get('parentProfileId');
	    		   if(currentRecord.get('isGlobal') === true && currTypeValue !== me.selectedProfileId) {
	    			   return "";
	    		   }
	    		   return txtboxCol;
               };
               
	    	   return fieldInfo;
	       },
	       
	       createComboBoxColumn: function(fieldInfo) {
	    	   var me = this;
	    	   
	    	   var optionPicklist = SVMX.create('com.servicemax.client.installigence.admin.celleditors.SVMXComboBoxCellEditor',{
					displayField: 'label',
			        queryMode: 'local',
			        editable: false,
			        valueField: 'value',
			        fieldName: 'actionType',
			        store: fieldInfo.actionTypeStore
	    	   });	    	   
	    	   
	    	   var fieldInfo = fieldInfo || {};
	    	   fieldInfo.menuDisabled = true;
	    	   fieldInfo.sortable = false;
	    	   fieldInfo.getEditor = function(currentRecord){
	    		   var currTypeValue = currentRecord.get('parentProfileId');
	    		   if(currentRecord.get('isGlobal') === true && currTypeValue !== me.selectedProfileId) {
	    			   return "";
	    		   }
	    		   optionPicklist.setRecord(currentRecord);
                   return optionPicklist;
               };
	    	   return fieldInfo;	    	   
	    	   
	       },
	       
	       addItemBeforeGlobalRecs : function(records, noOfGlobalRecs) {
	    	   noOfGlobalRecs = (noOfGlobalRecs === undefined || noOfGlobalRecs.length === 0) ? 0 : noOfGlobalRecs; 
	    	   if (!records) return;
               this.store.insert(this.getStore().count() - noOfGlobalRecs, records);
	       },
	       
	       getProfileRecords: function() {
	    	   var records = [];
	    	   this.store.each(function(rec) {           		
		    		if(rec.get("isGlobal") !== true) {
		    			delete rec.data["id"];           		
		           		records.push(rec.data);
		    		}           		
	    	   });
	    	   return records;
	       },
	       
	       getGlobalRecords: function() {
	    	   var records = [];
	    	   this.store.each(function(rec) {           		
		    		if(rec.get("isGlobal") === true) {
		    			delete rec.data["id"];           		
		           		records.push(rec.data);
		    		}           		
	    	   });
	    	   return records;
	       }
		});		
	
		Ext.define("com.servicemax.client.installigence.admin.UserActions", {
	         extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
	         __root: null,
	        constructor: function(config) {
   	 			var me = this;
   	 			this.__registerForDidProfileSelectCall();
   	 			this.__root = config.root;
   	 			var profiles = config.metadata.svmxProfiles;
   	 			var ibValueMapData = config.metadata.ibValueMaps;
   	 			var ibActionURLData = config.metadata.ibActionURLs;
				
	   	 		/*Ext.define('stdActionsModel', {
				    extend: 'Ext.data.Model',
				    fields: [ {name: 'isHidden', type: 'boolean'},
				              {name: 'name',  type: 'string'},
				              {name: 'action', type: 'string'}]
				});*/
	   	 		
   	 			Ext.define('actionsModel', {
				    extend: 'Ext.data.Model',
				    fields: [ {name: 'name',  type: 'string'},
				              {name: 'actionType',   type: 'string'},
				              {name: 'action', type: 'string'},
				              {name: 'isGlobal', type: 'boolean'}]
				});
   	 			
   	 			this.actionTypeStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['value', 'label'],
			        data: [
		        		{ value: 'fieldupdate', label: $TR.FIELD_UPDATE},
		        		{ value: 'customurl', label: $TR.CUSTOM_URL}//'Custom URL'
			        ]/*,
			               { value: 'externalapp', label: $TR.EXTERNAL_APP}]*/
   	 			});
				
				//the below data model have to be replaced with the actual data
				me.actionsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				    model: 'actionsModel',
				    data: [			        
				        
				    ]
				});
				
				/*me.stdActionsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
				    model: 'stdActionsModel',
				    data: [			        
				        
				    ]
				});*/
				
				var i = 0;
		    	var valueMapData = [];
		    	for(i=0; i< ibValueMapData.length; i++){
		    		   valueMapData[i] = {mapId: ibValueMapData[i].valueMapName, mapName: ibValueMapData[i].valueMapProcessName};
		    	}

		    	var actionURLData = [];
				for(i=0; i< ibActionURLData.length; i++){
		    		   actionURLData[i] = {actionURLId: ibActionURLData[i].actionURLName, actionURLName: ibActionURLData[i].actionURLProcessName};
		    	}		    	
  
				this.valueMapStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['mapId', 'mapName'],
			        data: valueMapData
   	 			});

   	 			this.actionURLStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['actionURLId', 'actionURLName'],
			        data: actionURLData
   	 			});

				
				var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				me.globalActions = [];
				me.globalFilters = [];
				var iProfile = 0, iProfileLength = profiles.length;
				for(iProfile = 0; iProfile < iProfileLength; iProfile++) {
					if(profiles[iProfile].profileId !== 'global'){
						profilesData.push(profiles[iProfile])
					}else {
						me.globalActions = profiles[iProfile].actions;
						me.globalFilters = profiles[iProfile].filters;
					}
				}				
				
				me.profiles = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['profileId', 'profileName'],
			        data: profilesData
			    });
							
				me.actionSearchGrid = SVMX.create('com.servicemax.client.installigence.admin.userActionsGrid',{
					cls: 'grid-panel-borderless panel-radiusless',
					store: me.actionsStore,
					height: 360,
				    selType: 'cellmodel',
				    actionTypeStore: me.actionTypeStore,			        
				    plugins: [
				              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
				                  clicksToEdit: 2
				              })
				          ],
				    valueMapStore: me.valueMapStore,
				    actionURLStore: me.actionURLStore
	            });			
				
				me.addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton',{
					//cls: 'plain-btn',
					ui: 'svmx-toolbar-icon-btn',
					scale: 'large',
					iconCls: 'plus-icon',
					tooltip: $TR.ADD,
					disabled: true,
					handler : function(){
						me.onAddRecords();
					}
				});
				
				me.actionsTextSearch = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextSearch',{
					width: '40%',
					cls: 'search-textfield',
					emptyText :$TR.SEARCH_EMPTY_TEXT,
					listeners: {
	                    change: {
	                        fn: me.onTextFieldChange,
	                        scope: this,
	                        buffer: 500
	                    }
	               }
				});
				
				/*me.showProfiles = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_PROFILE,
			        store: me.profiles,
			        labelWidth: 120,
			        width: 450,
			        displayField: 'profileName',
			        queryMode: 'local',
			        editable: false,
			        selectedProfile: undefined,
			        listeners: {
			        	select: {
			        		fn: me.__didSelectProfileWithInfo,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('profileName'));
						}
			        }
				});*/

				me.showProfiles = config.root.showProfiles;
				
				me.profileFormPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					width: 450,
					style: 'margin: 3px 0 9px 0',
					layout: 'fit',
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				//me.profileFormPanel.add(me.showProfiles);
				
				me.actionsTabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel',{
						cls: 'horizontal-tab-panel grid-panel-borderless panel-radiusless',
						plain : 'true'
                });
				
				me.searchToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
					style: 'border-width: 0'
				});				
				
				me.searchToolbar.add(me.actionsTextSearch);
				me.searchToolbar.add('->');
				me.searchToolbar.add(me.addRecButton);

				/*me.stdActionSearchGrid = SVMX.create('com.servicemax.client.installigence.admin.userStandardActionsGrid',{
					cls: 'grid-panel-borderless panel-radiusless',
					store: me.stdActionsStore,
					height: 160,
				    selType: 'cellmodel',
				    plugins: [
				              SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
				                  clicksToEdit: 2
				              })
				          ],
				    valueMapStore: me.valueMapStore
	            });
				
				me.stdUserActionsPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					style: 'margin: 1px 0',
					layout: 'fit',
					title: $TR.STANDARD_ACTIONS,
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				me.stdUserActionsPanel.add(me.stdActionSearchGrid);*/
				
				me.userActionsPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel',{
					style: 'margin: 1px 0',
					layout: 'fit',
					title: $TR.CUSTOM_ACTIONS,
					cls: 'grid-panel-borderless',
					defaults: {
						anchor: '40%'
					}
				});
				me.userActionsPanel.add(me.actionSearchGrid);
				
				/*me.actionsTabPanel.add({id:"UA", title: $TR.USERACTIONS, items: [ 
				  me.searchToolbar,
				  //me.stdUserActionsPanel,
				  me.userActionsPanel
				  ]
				});*/
				
				me.filters = SVMX.create("com.servicemax.client.installigence.admin.Filters", {
					metadata: config.metadata
				});
				//me.actionsTabPanel.add({title: $TR.FILTERS, items: [me.filters]});
				//me.actionsTabPanel.setActiveTab("UA");
				
				config = config || {};
				config.items = [];
				config.items.push(me.profileFormPanel);
				//config.items.push(me.actionsTabPanel);
				config.items.push(me.filters);
				//config.title = $TR.USERACTIONS_FILTERS;
				config.title = $TR.FILTERS;
				config.id = "UF";
				this.callParent([config]);
	         },
	         
	         onTextFieldChange: function() {
	        	var value = this.actionsTextSearch.getValue();
	        	this.actionSearchGrid.search(value);
	        	//this.stdActionSearchGrid.search(value);
	         },
	         
	         onAddRecords: function() {
	        	 this.actionSearchGrid.addItemBeforeGlobalRecs({parentProfileId: this.actionSearchGrid.selectedProfileId}, this.globalActions.length);
	         },
	         __showProfilesAfterrender : function(combo){
				
							var recordSelected =  this.__root.selectedProfile;                
							combo.setValue(recordSelected.get('profileName'));
			},
	         __didSelectProfileWithInfo:function(combo, record){
	         	this.__root.selectedProfile = record;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "SELECTED_PROFILE_CALL",{result: {combo:combo,record:record}},
                                                             this);
                    SVMX.getClient().triggerEvent(evt);
                   // this.__persistNLoadUserActionFilters(combo, record);

			},
			
	         __persistNLoadUserActionFilters: function(combo, record) { 
	        	 
	        	 //all disable goes here
	        	 this.addRecButton.setDisabled(combo.getSelectedRecord().get("profileId") == "--None--");
	        	 this.filters.addFilterRecButton.setDisabled(combo.getSelectedRecord().get("profileId") == "--None--");
	        	 this.filters.expressiontree.setDisabled(true);
	        	 
	        	 if(combo.getSelectedRecord() && combo.getSelectedRecord().get("profileId") !== "--None--")
        		 {
	        		 this.actionSearchGrid.selectedProfileId = combo.getSelectedRecord().get("profileId");
	        		 this.filters.filtersSearchGrid.selectedProfileId = combo.getSelectedRecord().get("profileId");
        		 }        	 
	        	 var prevSelTemplate = this.showProfiles.selectedProfile;
	        	 if(prevSelTemplate) {
        		 	   this.filters.persistNLoadExpression({});		        	 
		    		   this.__persistUserActions(prevSelTemplate);
		    		   //this.__persistFilters(prevSelTemplate);
		    		   //this.__persistUserStdActions(prevSelTemplate);
	        	 }
	        	 if(combo.getSelectedRecord().get("profileId") !== "--None--"){
	        		 this.showProfiles.selectedProfile = record;
		        	 this.__loadUserActions(record.getData().actions);
		        	 //this.__loadUserStdActions(record.getData().stdActions);
		        	 this.__loadFilters(record.getData().filters);
	        	 }else {
	        		 this.showProfiles.selectedProfile = undefined;
	        		 this.actionSearchGrid.getStore().removeAll();
	        		 this.filters.filtersSearchGrid.getStore().removeAll();
	        		 //this.stdActionSearchGrid.getStore().removeAll();
        		 }        	 
	         },
	         
	         __persistUserActions: function(record) {
	        	 var userActionsInfo = this.actionSearchGrid.getProfileRecords();
	        	 this.globalActions = this.actionSearchGrid.getGlobalRecords();
	        	 this.__savePicklistValues(userActionsInfo);
	        	 this.__savePicklistValues(this.globalActions);
	        	 record.set("actions", userActionsInfo);
	         },
	         
	         /*__persistUserStdActions: function(record) {
	        	 var userActionsInfo = this.stdActionSearchGrid.getProfileRecords();
	        	 this.__savePicklistValues(userActionsInfo);
	        	 record.set("stdActions", userActionsInfo);
	         },*/
	         
	         __persistFilters: function(record) {
	        	 var filtersInfo = this.filters.filtersSearchGrid.getProfileRecords();
	        	 this.globalFilters = this.filters.filtersSearchGrid.getGlobalRecords();	        	 
	        	 record.set("filters", filtersInfo)
	         },
	         
	         __loadUserActions: function(record) {
	        	 if(!record) {
	        		 record = [];
	        	 }
	        	 record = record.concat(this.globalActions);
        		 this.__loadPicklistValues(record);
        		 this.actionSearchGrid.getStore().loadData(record)
	         },

	         /*__loadUserStdActions: function(record) {
	        	 if(!record) {
	        		 record = [];
	        	 }
        		 this.__loadPicklistValues(record);
        		 this.stdActionSearchGrid.getStore().loadData(record);
	         },*/
	         
	         __loadFilters: function(record) {
	        	 if(!record) {
	        		 record = [];
	        	 }
	        	 record = record.concat(this.globalFilters);
        		 this.filters.filtersSearchGrid.getStore().loadData(record)
	         },
	         
	         __loadPicklistValues: function(records) {
	        	 var iActionsRecs = 0, iActionRecsLen = records.length;
	        	 for(iActionsRecs = 0; iActionsRecs < iActionRecsLen; iActionsRecs++) {
	        		 var currRec = records[iActionsRecs];
	        		 currRec.actionType_key = currRec.actionType;
	        		 currRec.actionType = this.actionTypeStore.findRecord("value", currRec.actionType) !== null ? 
							   this.actionTypeStore.findRecord("value", currRec.actionType).get("label") : currRec.actionType;
					currRec.action_key = currRec.action;
					
					currRec.action = this.valueMapStore.findRecord("mapId", currRec.action) !== null ? 
							   this.valueMapStore.findRecord("mapId", currRec.action).get("mapName") : currRec.action;
					currRec.action = this.actionURLStore.findRecord("actionURLId", currRec.action) !== null ? 
							   this.actionURLStore.findRecord("actionURLId", currRec.action).get("actionURLName") : currRec.action;
	        	 }
	         },
	         
	         __savePicklistValues: function(records) {
	        	 var iActionsRecs = 0, iActionRecsLen = records.length;
	        	 for(iActionsRecs = 0; iActionsRecs < iActionRecsLen; iActionsRecs++) {
	        		 var currRec = records[iActionsRecs];
	        		 if(currRec.actionType_key) {
	        			 currRec.actionType = currRec.actionType_key;
		        		 delete currRec["actionType_key"];
	        		 }
	        		 if(currRec.action_key) {
	        			 currRec.action = currRec.action_key;
		        		 delete currRec["action_key"];
	        		 }
	        	 }
	         },
	         __registerForDidProfileSelectCall: function(){

           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){
               var data = SVMX.toObject(evt.data);
             var combo = evt.target.result.combo;
             var record = evt.target.result.record;
          	this.__persistNLoadUserActionFilters(combo, record); 
          	this.showProfiles.setRawValue(record.get('profileName'));

           }, this); 
			}
	         
	     });
	};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence.admin\src\util.js
(function(){

// Array.prototype.find is not supported in any version of IE hence adding Polyfill for same.
	
	if (!Array.prototype.find) {
  	Object.defineProperty(Array.prototype, 'find', {
    value: function(predicate) {
     // 1. Let O be ? ToObject(this value).
      if (this == null) {
        throw new TypeError('"this" is null or not defined');
      }

      var o = Object(this);

      // 2. Let len be ? ToLength(? Get(O, "length")).
      var len = o.length >>> 0;

      // 3. If IsCallable(predicate) is false, throw a TypeError exception.
      if (typeof predicate !== 'function') {
        throw new TypeError('predicate must be a function');
      }

      // 4. If thisArg was supplied, let T be thisArg; else let T be undefined.
      var thisArg = arguments[1];

      // 5. Let k be 0.
      var k = 0;

      // 6. Repeat, while k < len
      while (k < len) {
        // a. Let Pk be ! ToString(k).
        // b. Let kValue be ? Get(O, Pk).
        // c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
        // d. If testResult is true, return kValue.
        var kValue = o[k];
        if (predicate.call(thisArg, kValue, k, o)) {
          return kValue;
        }
        // e. Increase k by 1.
        k++;
      }

      // 7. Return undefined.
      return undefined;
    }
  });
}
})();

