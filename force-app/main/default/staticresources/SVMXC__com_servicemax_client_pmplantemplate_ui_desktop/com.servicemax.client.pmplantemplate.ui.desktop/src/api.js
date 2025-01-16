
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.api");

    appImpl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            cls: "pmplantemplate-root-container",
            id: 'pmPlanTemplateContainer',
            width: "100%",
            height: 730,
            __parent: this,
            __runOpts: null,
            constructor: function(config) {
                config = Ext.apply({
                    collapsible: false,
                    title: SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" : TS.T("TAG001", "Preventive Maintenance Plan Template"),
                    titleAlign: "center",
                    layout: {
                        type: "border"
                    }
                }, config || {});
                this.callParent([config]);
            },

            run: function(options) {
                var me = this;
                this.__runOpts = options;

                var templateMainPanel = SVMX.create("Ext.form.FormPanel", {
                    id: 'templateMainPanel',
                    collapsible: false,
                    region: "center",
                    width: "100%",
                    border: false,
                    layout: 'anchor',
                    layout: {
                        type: "anchor",
                        align: "stretch"
                    },
                    buttons: [{ 
                        text: TS.T("COMM_TAG002", "Cancel"),
                        __parent: this,
                        cls: 'pmplantemplate-cancel-btn',
                        height: 30,
                        listeners: {
                            click: function( btn , e , eOpts) {
                                var messageBox = {
                                    title : TS.T("TAG048", "Warning"),
                                    msg : TS.T("TAG045", "All your changes will be discarded. Do you want to continue?"),
                                    width : 300,
                                    closable : false,
                                    icon : Ext.MessageBox.WARNING,
                                    buttons : Ext.Msg.YESNO,
                                    __parent: btn.__parent,
                                    buttonText : {
                                        yes : TS.T("COMM_TAG005", "Yes"),
                                        no : TS.T("COMM_TAG006", "No"),
                                    },
                                    fn : function(buttonValue, inputText, showConfig){
                                        if(buttonValue === 'yes'){
                                            var urlString = '/'+showConfig.__parent.deliveryEngine.getKeyPrefixForTemplateObject();
                                            if((typeof sforce != 'undefined') && (sforce != null)){
                                                sforce.one.navigateToURL(urlString);
                                            }
                                            else{
                                                window.location.href = urlString;
                                            }
                                        }
                                    }
                                };
                                SVMX.MessageBox.show(messageBox);
                            }
                        }
                    },{ 
                        text: TS.T("COMM_TAG001", "Save"),
                        __parent: this,
                        cls: 'pmplantemplate-save-btn',
                        height: 30,
                        listeners: {
                            click: function( btn , e , eOpts) {
                                var templateMainPanel = Ext.getCmp('templateMainPanel');
                                var formData = templateMainPanel.getForm().getFieldValues();
                                var conditionTypeValue = formData.conditionType;

                                if(this.__parent.validateFormData(formData)){
                                    if(conditionTypeValue === null || conditionTypeValue === '' || conditionTypeValue === 'Usage_Frequency'){
                                        var conditionRuleStore = Ext.getStore('Condition_Rule_Store');
                                        var ruleData = conditionRuleStore.data.items;
                                        if(this.__parent.validateGridData(ruleData)){
                                            this.__parent.deliveryEngine.saveTemplateData(formData, ruleData);
                                        }
                                    }
                                    else if(conditionTypeValue === 'Criteria_Comparison'){
                                        var conditionRuleStoreCB = Ext.getStore('Condition_Rule_Store_CB');
                                        var ruleData = conditionRuleStoreCB.data.items;
                                        if(this.__parent.validateCriteriaGridData(ruleData)){
                                            this.__parent.deliveryEngine.saveTemplateData(formData, ruleData);
                                        }
                                    }
                                }
                            }
                        }
                    }]
                });
                this.add(templateMainPanel);

                //Template Name
                var templateName = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXText", {
                    id: 'templateNameBox',
                    name: 'templateName',
                    fieldLabel: TS.T("TAG002", "Template Name")+'*',
                    labelAlign: 'top',
                    labelSeparator: '',
                    msgTarget : 'under'
                });

                //Schedule Type
                var scheduleTypeStore = Ext.create('Ext.data.Store', {
                    storeId: 'Schedule_Type_Store',
                    fields: ['name', 'label']
                });
                var scheduleType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG003", "Schedule Type"),
                    labelSeparator: '',
                    name: 'scheduleType',
                    id: 'scheduleTypeCombo',
                    store: scheduleTypeStore,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'name',
                    labelAlign: 'top',
                    editable: false,
                    readOnly: true,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                //Condition Type
                var conditionTypeStore = Ext.create('Ext.data.Store', {
                    storeId: 'Condition_Type_Store',
                    fields: ['name', 'label'],
                    data : [
                         {name: 'Usage_Frequency',    label: TS.T("TAG060", "Usage/Frequency Based")},
                         {name: 'Criteria_Comparison', label: TS.T("TAG061", "Criteria/Comparison Based")}
                     ]
                });
                var conditionType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG062", "Condition Type")+'*',
                    labelSeparator: '',
                    name: 'conditionType',
                    id: 'conditionTypeCombo',
                    store: conditionTypeStore,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'name',
                    labelAlign: 'top',
                    editable: false,
                    value: 'Usage_Frequency',
                    __parent: this,
                    listeners: {
                        beforeselect: function( combo, records, eOpts ){
                            var oldValue = this.getValue();
                            var ConditionRuleStore = Ext.getStore('Condition_Rule_Store');
                            var ConditionRuleStoreCB = Ext.getStore('Condition_Rule_Store_CB');
                            if(ConditionRuleStore.getCount() > 0 || ConditionRuleStoreCB.getCount() > 0){
                                Ext.Msg.show({
                                    title : TS.T("COMM_TAG007", "Warning"),
                                    msg : TS.T("TAG064", "Changing the Condition type will reset the fields on the Condition grid. Are you sure you want to proceed?"),
                                    width : 300,
                                    closable : false,
                                    icon : Ext.MessageBox.WARNING,
                                    buttons : Ext.Msg.YESNO,
                                    __parent: this.__parent,
                                    __comboCmp : this,
                                    buttonText : {
                                        yes : TS.T("COMM_TAG008","Ok"),
                                        no : TS.T("COMM_TAG009","Cancel"),
                                    },
                                    fn : function(buttonValue, inputText, showConfig){
                                        if(buttonValue === 'yes'){
                                            showConfig.__comboCmp.changeComponentState(records, ConditionRuleStoreCB, ConditionRuleStore);
                                        }
                                        else{
                                            combo.setValue(oldValue);
                                        }
                                    }
                                });
                            }
                            else{
                                this.changeComponentState(records, ConditionRuleStoreCB, ConditionRuleStore);
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    changeComponentState: function(records, ConditionRuleStoreCB, ConditionRuleStore){
                        var conditionTypeValue = records.get('name');
                        var useCurrentFieldValCmp = Ext.getCmp('useCurrentFieldVal');
                        var conditionRuleTabPanelCmp = Ext.getCmp('conditionRuleTabPanel');
                        var conditionRuleTabPanelForCriteriaCmp = Ext.getCmp('conditionRuleTabPanelForCriteria');
                        if(conditionTypeValue === 'Usage_Frequency'){
                            //set visibility of the component
                            useCurrentFieldValCmp.setVisible(true);
                            conditionRuleTabPanelCmp.setVisible(true);
                            conditionRuleTabPanelForCriteriaCmp.setVisible(false);
                            //Clear store data
                            ConditionRuleStoreCB.removeAll();
                            //Enable add row button
                            Ext.getCmp('addRowButton').setDisabled(false);
                        }
                        else if(conditionTypeValue === 'Criteria_Comparison'){
                            //set visibility of the component
                            useCurrentFieldValCmp.setVisible(false);
                            conditionRuleTabPanelCmp.setVisible(false);
                            conditionRuleTabPanelForCriteriaCmp.setVisible(true);
                            //Clear store data
                            ConditionRuleStore.removeAll();
                            //Enable add row button
                            Ext.getCmp('addRowButton_CB').setDisabled(false);
                        }
                        //Clear advanced expression
                        Ext.getCmp('advancedExpression').setValue('');
                        //disable Build sample schedule button
                        Ext.getCmp('buildSampleSchedule').setDisabled(true);
                        //populate attribute column with values
                        var productId = Ext.getCmp('productCombo').getValue();
                        if(productId != null){ //This condition is added as part of defect BAC-2805 fix
                            this.__parent.deliveryEngine.getTechnicalAttribute(productId, conditionTypeValue);
                        }
                    }
                });

                //Coverage type
                var coverageTypeStore = Ext.create('Ext.data.Store', {
                    storeId: 'Coverage_Type_Store',
                    fields: ['name', 'label']
                });
                var coverageType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'coverageTypeCombo',
                    name: 'coverageType',
                    fieldLabel: TS.T("TAG004", "Coverage Type")+'*',
                    labelSeparator: '',
                    store: coverageTypeStore,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'name',
                    labelAlign: 'top',
                    editable: false,
                    readOnly: true,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                //Product
                var productSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'column',
                    defaults: {
                        columnWidth: 0.5
                    },
                    collapsible: false,
                    border: false,
                    style: 'background-color: white !important'
                });
                var productStore = Ext.create('Ext.data.Store', {
                    storeId: 'Product_Store',
                    fields: ['name', 'label'],
                });
                var product = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG005", "Product")+'*',
                    labelSeparator: '',
                    name: 'product',
                    id: 'productCombo',
                    store: productStore,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'name',
                    labelAlign: 'top',
                    msgTarget : 'under',
                    columnWidth: 0.95,
                    listeners: {
                        select: function (combo, record) {
                            var productId = record[0].getData().name;
                            var condtionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                            this.deliveryEngine.getTechnicalAttribute(productId, condtionTypeValue);
                        },
                        scope: this
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                productSec.add(product);

                //Product Filter
                productSec.add({
                    iconCls : 'svmx-filter-icon',
                    cursor:'pointer', 
                    scale : 'small',
                    cls: 'img-header-default',
                    border: false,
                    columnWidth: 0.05,
                    style: 'top: 20px',
                    listeners: {
                        el: {
                            click: function() {
                                var productSearchText = Ext.getCmp('productCombo');
                                var searchRequest ={};
                                searchRequest.objAPIName = 'Product2';
                                searchRequest.searchtext = productSearchText.getRawValue();
                                searchRequest.whereClause = ' IsActive = true '
                                if(searchRequest.searchtext.length < 3){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG010", "Please enter atleast first three characters and click Search")); 
                                }
                                else{
                                    var pmplanComponent = Ext.getCmp('pmPlanTemplateContainer');
                                    pmplanComponent.getDeliveryEngine().searchObject(searchRequest); 
                                }
                            }
                        }
                    },
                });

                //Installed Product Filter
                var installedProductFilterStore = Ext.create('Ext.data.Store', {
                    storeId: 'IB_Filter_Store',
                    fields: ['exprId', 'exprName']
                });
                var installedProductFilter = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG006", "Installed Product Filter"),
                    labelSeparator: '',
                    name: 'installedProductFilter',
                    id: 'installedProductFilterCombo',
                    store: installedProductFilterStore,
                    queryMode: 'local',
                    displayField: 'exprName',
                    valueField: 'exprId',
                    labelAlign: 'top',
                    editable: false,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                //Activity Date
                var activityDateStore = Ext.create('Ext.data.Store', {
                    storeId: 'Activity_Date_Store',
                    fields: ['fieldApiName', 'fieldLabel']
                });
                var activityDate = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG007", "Activity Date")+'*',
                    labelSeparator: '',
                    id: 'activityDateCombo',
                    name: 'activityDate',
                    store: activityDateStore,
                    queryMode: 'local',
                    displayField: 'fieldLabel',
                    valueField: 'fieldApiName',
                    labelAlign: 'top',
                    editable: false,
                    allowBlank : false,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                //Work Order Purpose
                var workOrderPurposeStore = Ext.create('Ext.data.Store', {
                    storeId: 'WO_Purpose_Store',
                    fields: ['taskTemplateId', 'taskTemplateName']
                });
                var workOrderPurpose = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: TS.T("TAG008", "Work Order Purpose"),
                    labelSeparator: '',
                    name: 'workOrderPurpose',
                    id: 'workOrderPurposeCombo',
                    store: workOrderPurposeStore,
                    queryMode: 'local',
                    displayField: 'taskTemplateName',
                    valueField: 'taskTemplateId',
                    labelAlign: 'top',
                    editable: false,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var useCurrentFieldVal = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckbox", {
                    labelSeparator: '',
                    name: 'useCurrentFieldVal',
                    id: 'useCurrentFieldVal',
                    boxLabelAlign: 'after',
                    hidden: true,
                    boxLabel: TS.T("TAG059", "Use Current Field Value")
                });

                var firstFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    items:[templateName, coverageType, installedProductFilter, workOrderPurpose, useCurrentFieldVal]
                };

                var secondFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    items:[scheduleType, conditionType, productSec, activityDate]
                };

                var templateFieldsPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    collapsible: false,
                    region: "center",
                    width: "100%",
                    border: false,
                    layout: 'column',
                    defaults: {
                        bodyPadding: 0
                    },
                    items: [firstFieldSetForFields, secondFieldSetForFields]
                });

                templateMainPanel.add(templateFieldsPanel);

                //Adding condition rule panel
                var conditionRulePanel = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRule", {
                    itemId: 'conditionRulePanelCmp',
                    collapsible: false,
                    region: "center",
                    width: "100%",
                    layout: 'anchor',
                    __parent: this,
                    defaults: {
                        bodyPadding: 0,
                        anchor: '100%'
                    }
                });

                var conditionRulePanelForCriteria = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleCriteriaBased", {
                    itemId: 'conditionRulePanelForCriteriaCmp',
                    collapsible: false,
                    region: "center",
                    width: "100%",
                    layout: 'anchor',
                    __parent: this,
                    defaults: {
                        bodyPadding: 0,
                        anchor: '100%'
                    }
                });
                var conditionRuleTabPanel = {
                    id: 'conditionRuleTabPanel',
                    xtype: 'tabpanel',
                    items: [conditionRulePanel],
                    cls: 'pmplantemplate-tab-panel',
                    margin: '10px 10px 10px 10px',
                    hidden: true
                };

                var conditionRuleTabPanelForCriteria = {
                    id: 'conditionRuleTabPanelForCriteria',
                    xtype: 'tabpanel',
                    items: [conditionRulePanelForCriteria],
                    cls: 'pmplantemplate-tab-panel',
                    margin: '10px 10px 10px 10px',
                    hidden: true
                };
                templateMainPanel.add(conditionRuleTabPanelForCriteria);
                templateMainPanel.add(conditionRuleTabPanel);

                //Advance Expression
                var advancedExpression = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXText", {
                    id: 'advancedExpression',
                    name: 'advancedExpression',
                    fieldLabel: TS.T("TAG051", "Advanced Expression"),
                    labelAlign: 'top',
                    labelSeparator: '',
                    width: "98%",
                    margin: '10px 10px 10px 10px'
                });
                templateMainPanel.add(advancedExpression);

                var buildSampleSchedule = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton",{
                    id: 'buildSampleSchedule',
                    name: 'buildSampleSchedule',
                    text: TS.T("TAG054", "Build sample schedule"),
                    disabled: true,
                    __parent: this,
                    margin: '10px 10px 10px 0px',
                    style:{
                        marginLeft: '44% !important'
                    },
                    cls: 'pmplantemplate-blue-link',
                    listeners: {
                        click: function( btn , e , eOpts) {
                            var templateMainPanel = Ext.getCmp('templateMainPanel');
                            var formData = templateMainPanel.getForm().getFieldValues();
                            var conditionTypeValue = formData.conditionType;
                            var conditionRuleStore = (conditionTypeValue == 'Criteria_Comparison') ? Ext.getStore('Condition_Rule_Store_CB') : Ext.getStore('Condition_Rule_Store');
                            var ruleData = conditionRuleStore.data.items;
                            var isRuleDataValid = (conditionTypeValue == 'Criteria_Comparison')? btn.__parent.validateCriteriaGridData(ruleData) : btn.__parent.validateGridData(ruleData);
                            if(isRuleDataValid){
                                var scheduleWindow = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow.ScheduleWindow", {
                                    id: "scheduleWindow",
                                    cls: 'pmplantemplate-schedule-window',
                                    __parent: this,
                                    maxHeight: 550,
                                    width: 530,
                                    conditionTypeValue: conditionTypeValue
                                });
                                btn.__parent.getDeliveryEngine().getSampleSchedules(formData, ruleData);
                            }
                        }
                    }
                });
                templateMainPanel.add(buildSampleSchedule);

                this.resize();
            },

            validateFormData: function(formData){
                //validate the data in UI
                var IsValidationSuccess = true;
                if(formData.templateName == null || formData.templateName == ''){
                    Ext.getCmp('templateNameBox').markInvalid(TS.T("TAG041", "This is a required field."));
                    IsValidationSuccess = false;
                }
                if(formData.product == null || formData.product == ''){
                    Ext.getCmp('productCombo').markInvalid(TS.T("TAG041", "This is a required field."));
                    IsValidationSuccess = false;
                }
                return IsValidationSuccess;
            },

            validateGridData: function(ruleData){
                var fieldListStore = Ext.data.StoreManager.lookup('Field_List_Store');
                var isGridHasErrors = false;
                var isProductChanged = false;
                var isRequiredFieldValueMissing = false;
                var isStopAtLessThanToday = false;
                for(var i=0; i<ruleData.length; i++){
                    if(!isGridHasErrors){
                        if(ruleData[i].data.isRowHasError === true){
                            isGridHasErrors = true;
                        }
                    }
                    if(!isProductChanged){
                        var fieldValue = ruleData[i].data.selectedField;
                        if(fieldValue != null && fieldValue != ''){
                            var recIndex = fieldListStore.findExact('fieldApiName', fieldValue);
                            if(recIndex === -1){
                                isProductChanged = true;
                            }
                        }
                    }
                    if(!isRequiredFieldValueMissing){
                        var fieldValue = ruleData[i].data.selectedField;
                        var operatorValue = ruleData[i].data.selectedOperator;
                        var frequencyValue = ruleData[i].data.frequency;
                        if(fieldValue === null || fieldValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                        else if(operatorValue === null || operatorValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                        else if(frequencyValue === null || frequencyValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                    }
                    if(!isStopAtLessThanToday){
                        var selectedFieldValue = ruleData[i].data.selectedField;
                        if(selectedFieldValue === 'Months' || selectedFieldValue === 'Weeks' || selectedFieldValue === 'Years'){
                            var startAt = ruleData[i].data.startAt;
                            if(startAt === null || startAt === ''){
                                var stopAt = ruleData[i].data.stopAt;
                                var todayDate = new Date();
                                todayDate = todayDate.setHours(0,0,0,0);
                                if(stopAt < todayDate){
                                    isStopAtLessThanToday = true;
                                }
                            }
                        }
                    }
                }
                if(isProductChanged){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG047", "There is a mismatch between the product and attribute chosen. Please choose the correct attribute and save."), 7000, 'success');
                    return false;
                }
                else if(isRequiredFieldValueMissing){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG050", "Please fill values for the following columns in Condition Rule : Attribute, Operator and Frequency"), 7000, 'success');
                    return false;
                }
                else if(isGridHasErrors){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG046", "One or more conditions is invalid. Please review the conditions and save"), 7000, 'success');
                    return false;
                }
                else if(isStopAtLessThanToday){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG053", "Stop At cannot be less than today. Please validate your condition"), 7000, 'success');
                    return false;
                }
                return true;
            },

            validateCriteriaGridData: function(ruleData){
                var fieldListStoreCB = Ext.data.StoreManager.lookup('Field_List_Store_CB');
                var isProductChanged = false;
                var isRequiredFieldValueMissing = false;
                for(var i=0; i<ruleData.length; i++){
                    if(!isProductChanged){
                        var fieldValue = ruleData[i].data.selectedField;
                        if(fieldValue != null && fieldValue != ''){
                            var recIndex = fieldListStoreCB.findExact('fieldApiName', fieldValue);
                            if(recIndex === -1){
                                isProductChanged = true;
                            }
                        }
                    }
                    if(!isRequiredFieldValueMissing){
                        var fieldValue = ruleData[i].data.selectedField;
                        var operatorValue = ruleData[i].data.selectedOperator;
                        var frequencyValue = ruleData[i].data.value;
                        if(fieldValue === null || fieldValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                        else if(operatorValue === null || operatorValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                        else if(frequencyValue === null || frequencyValue === ''){
                            isRequiredFieldValueMissing = true;
                        }
                    }
                }
                if(isProductChanged){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG047", "There is a mismatch between the product and attribute chosen. Please choose the correct attribute and save."), 7000, 'success');
                    return false;
                }
                else if(isRequiredFieldValueMissing){
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG065", "Please fill values for the following columns in Condition Rule : Attribute, Operator and Value"), 7000, 'success');
                    return false;
                }
                return true;
            },

            resize: function(size) {
                if (!this.getEl()) return SVMX.timer.job(this.id + ".resize", 10, this, "resize");
                if (!size) size = this.getEl().getViewSize();

                // -4 because of internal padding
                if (size.width) size.width = size.width - 4;
                if (size.height) size.height = size.height - 6;

                if (size.width) this.setWidth(size.width);
                if (size.height) this.setHeight(size.height);
            },

            blockApplication: function(params) {
                var p = params || {
                    request: {
                        state: "block",
                        deliveryEngine: this.getDeliveryEngine()
                    },
                    responder: {}
                };
                var currentApp = this.getDeliveryEngine().getEventBus();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "PMPLAN.CHANGE_APP_STATE", this, p);
                currentApp.triggerEvent(evt);
            },

            unblockApplication: function(params) {
                var p = params || {
                    request: {
                        state: "unblock",
                        deliveryEngine: this.getDeliveryEngine()
                    },
                    responder: {}
                };
                var currentApp = this.getDeliveryEngine().getEventBus();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "PMPLAN.CHANGE_APP_STATE", this, p);
                currentApp.triggerEvent(evt);
            },

            getDeliveryEngine: function() {
                return this.deliveryEngine;
            }
        });
    }
})();