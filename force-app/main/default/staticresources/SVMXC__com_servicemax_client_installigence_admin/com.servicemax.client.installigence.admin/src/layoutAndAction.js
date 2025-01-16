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
