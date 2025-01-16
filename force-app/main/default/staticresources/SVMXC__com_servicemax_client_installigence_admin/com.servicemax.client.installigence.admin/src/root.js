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
