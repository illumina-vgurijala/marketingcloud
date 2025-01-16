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