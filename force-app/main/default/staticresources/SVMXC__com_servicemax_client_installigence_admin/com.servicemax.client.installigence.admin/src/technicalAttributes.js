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


