// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplantemplate.ui.desktop\src\api.js

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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplantemplate.ui.desktop\src\conditionRule.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRule", {
            extend: 'Ext.form.FormPanel',

            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG027", "Condition Rules")
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);

                var fieldListStore = Ext.create('Ext.data.Store', {
                    storeId: 'Field_List_Store',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });
                this.__grid = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRuleGrid", {
                    __fieldStore: fieldListStore
                });
                this.add(this.__grid);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.GroupComboBox', {
            extend: 'com.servicemax.client.ui.components.controls.impl.SVMXPicklist',
            groupField: 'group',
            listConfig: {
                cls: 'grouped-list',
                getInnerTpl: function(displayField) {
                    return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                }
            },
            initComponent: function() {
                var me = this;
                me.tpl = new Ext.XTemplate([
                    '{[this.currentGroup = null]}',
                    '<tpl for=".">',
                    '   <tpl if="this.shouldShowHeader('+me.groupField+')">',
                    '       <div class="group-header">{[this.showHeader(values.'+me.groupField+')]}</div>',
                    '   </tpl>',
                    '   <div class="svmx-boundlist-item">{'+me.displayField+'}</div>',
                    '</tpl>',
                    {  
                        shouldShowHeader: function(group){
                            return this.currentGroup != group;
                        },
                        showHeader: function(group){
                            this.currentGroup = group;
                            return group;
                        }
                    }
                ]);
                me.callParent(arguments);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRuleGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            __fieldStore: null,
            __rowData: null,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {
                this.fieldCombo = new SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.GroupComboBox",{
                    id: 'fieldComboCmp',
                    typeAhead: true,
                    queryMode: 'local',
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: this.__fieldStore,
                    displayField: 'fieldLabel',
                    valueField: 'fieldApiName',
                    groupField: 'category',
                    editable: false

                });

                var initialOperatorStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":TS.T("TAG032", "Every"), 
                            "value":"EYI",
                            "type": "Date"
                        },
                        {
                            "label":TS.T("TAG033", "Every decrement"), 
                            "value":"EYD",
                            "type": "Number"
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    }
                });
                this.operatorCombo = new Ext.form.field.ComboBox({
                    id: 'operatorComboCmp',
                    typeAhead: true,
                    triggerAction: 'all',
                    queryMode: 'local',
                    selectOnTab: true,
                    displayField: 'label',
                    store: initialOperatorStore,
                    valueField: 'value',
                    editable: false,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(selectedFieldValue === 'Months' || selectedFieldValue === 'Weeks' || selectedFieldValue === 'Years'){
                                    combo.store.filter('type','Date');
                                }
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.adjustmentTypeCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    editable: false,
                    queryMode: 'local',
                    store: [
                        ['None',TS.T("COMM_TAG004", "--None--")],
                        ['Actual',TS.T("TAG038", "Actual")],
                        ['Fixed',TS.T("TAG039", "Fixed")]
                    ],
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var initialAdjustmentUnitStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":TS.T("TAG040", "Days"), 
                            "value":"Days",
                            "type": "Date"
                        },
                        {
                            "label":TS.T("TAG034", "Count"), 
                            "value":"Count",
                            "type": "Number"
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    }
                });

                this.adjustmentUnitCombo = new Ext.form.field.ComboBox({
                    id: 'adjustmentUnitComboCmp',
                    displayField: 'label',
                    valueField: 'value',
                    queryMode: 'local',
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    editable: false,
                    store: initialAdjustmentUnitStore,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(selectedFieldValue === 'Months' || selectedFieldValue === 'Weeks' || selectedFieldValue === 'Years'){
                                    combo.store.filter('type','Date');
                                }
                                else{
                                    combo.store.filter('type','Number');
                                }
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    __parent: this,
                    listeners: {
                        beforeedit: function(editor, e){
                            this.__parent.__rowData = e.record.data;
                            var adjustmentUnitComboCmp = Ext.getCmp('adjustmentUnitComboCmp');
                            adjustmentUnitComboCmp.store.clearFilter();

                            var operatorComboCmp = Ext.getCmp('operatorComboCmp');
                            operatorComboCmp.store.clearFilter();
                        },
                        edit: function(editor, e){
                            if(e.field === 'selectedAdjustmentType' && (e.value === 'None') && (e.value !== e.originalValue)){
                                e.record.set('minAdjustment','');
                                e.record.set('maxAdjustment','');
                                e.record.set('adjustmentVal','');
                                e.record.set('selectedAdjustedUnit','');
                            }

                            if(e.field === 'selectedAdjustmentType' && (e.value === 'Actual') && (e.value !== e.originalValue)){
                                e.record.set('adjustmentVal','');
                            }

                            if(e.field === 'selectedField'){
                                if((e.value === 'Weeks' || e.value === 'Months' || e.value === 'Years') && (e.originalValue !== '' && e.originalValue !== 'Weeks' && e.originalValue !== 'Months' && e.originalValue !== 'Years')){
                                    e.record.set('startAt','');
                                    e.record.set('stopAt','');
                                    e.record.set('threshold','');
                                    e.record.set('frequency','');
                                    e.record.set('selectedOperator','');
                                    e.record.set('selectedAdjustedUnit','');
                                }
                                else if((e.value !== 'Weeks' && e.value !== 'Months' && e.value !== 'Years') && (e.originalValue !== '' && (e.originalValue === 'Weeks' || e.originalValue === 'Months' || e.originalValue === 'Years'))){
                                    e.record.set('startAt','');
                                    e.record.set('stopAt','');
                                    e.record.set('frequency','');
                                    e.record.set('selectedOperator','');
                                    e.record.set('selectedAdjustedUnit','');
                                }
                            }

                            //Setting required field error message column 7 when operator is Every
                            if(e.record.data.selectedOperator == 'EYI' && (e.record.data.stopAt === '' || e.record.data.stopAt === null)){
                                var editedCell = e.row.childNodes[7]; //Stop At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 5 when operator is Every decrement
                            if(e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt === '' || e.record.data.startAt === null)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 11 when Adjustment type: Change from Actual to Fixed
                            if(e.record.data.selectedAdjustmentType === 'Fixed' && (e.record.data.adjustmentVal === '' || e.record.data.adjustmentVal === null)){
                                var editedCell = e.row.childNodes[11]; //Adjustment value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }
                            else if(e.record.data.selectedAdjustmentType !== 'Fixed'){ //removing error class
                                var editedCell = e.row.childNodes[11]; //Adjustment value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') !== -1){
                                    editedCell.firstChild.setAttribute('class', classAttr.replace('make-cell-dirty','').trim());
                                }
                            }

                            //Setting error message for column 7 when stopAt less than startAt and Unit is Weeks OR Months OR Years OR Count
                            if(e.record.data.selectedOperator == 'EYI' && (e.record.data.startAt !== '' && e.record.data.startAt !== null) && (e.record.data.stopAt !== '' && e.record.data.stopAt !== null)){
                                var stopAtLessThanstartAt = false;
                                if((e.record.data.selectedField === 'Months' || e.record.data.selectedField === 'Weeks' || e.record.data.selectedField === 'Years') && e.record.data.stopAt < e.record.data.startAt){
                                    stopAtLessThanstartAt = true;
                                }
                                else if((e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Years') && parseFloat(e.record.data.stopAt) < parseFloat(e.record.data.startAt)){
                                    stopAtLessThanstartAt = true;
                                }
                                if(stopAtLessThanstartAt){
                                    var editedCell = e.row.childNodes[7]; //Stop At column
                                    var classAttr = editedCell.firstChild.getAttribute('class');
                                    if(classAttr.indexOf('make-cell-dirty') === -1){
                                        editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                        editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG042", "Stop At cannot be less than Start At."));
                                    }
                                }
                            }

                            //Setting error message for column 5 when stopAt greater than startAt and Unit is Count
                            if((e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Years') && e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt !== '' && e.record.data.startAt !== null) && (e.record.data.stopAt !== '' && e.record.data.stopAt !== null) && parseFloat(e.record.data.stopAt) > parseFloat(e.record.data.startAt)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG043", "Start At cannot be less than Stop At."));
                                }
                            }

                            //Removing error message when unit is Any value
                            if(e.record.data.selectedField !== null && e.record.data.selectedField !== ''){
                                var editedCell = e.row.childNodes[7]; //Stop At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Removing error message when field is not date based
                            if(e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Years'){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Removing error message when Adjustment Value column has value and AdjustmentType === 'Fixed'
                            if(e.record.data.selectedAdjustmentType === 'Fixed' && (e.record.data.adjustmentVal !== '' && e.record.data.adjustmentVal !== null)){
                                var editedCell = e.row.childNodes[11]; //Adjustment Value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Code to First column dirty state based on Column 5 and 7 and 11
                            var editedCellMakeDirty;
                            var editedClassAttr;
                            var makeFirstColDirty = false;
                            
                            var editedCellFifth = e.row.childNodes[5]; //Start At column
                            var classAttrFifth = editedCellFifth.firstChild.getAttribute('class');
                            if(classAttrFifth.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellFifth;
                                editedClassAttr = classAttrFifth;
                            }
                            
                            var editedCellSeventh = e.row.childNodes[7]; //Stop At column
                            var classAttrSeventh = editedCellSeventh.firstChild.getAttribute('class');
                            if(classAttrSeventh.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellSeventh;
                                editedClassAttr = classAttrSeventh;
                            }
                            
                            var editedCellEleventh = e.row.childNodes[11]; //Adjustment Value column
                            var classAttrEleventh = editedCellEleventh.firstChild.getAttribute('class');
                            if(classAttrEleventh.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellEleventh;
                                editedClassAttr = classAttrEleventh;
                            }
                            if(makeFirstColDirty){
                                e.record.set('isRowHasError',true);
                                editedCellMakeDirty.firstChild.setAttribute('class',editedClassAttr.replace('make-cell-dirty','').trim());
                                editedCellMakeDirty.firstChild.setAttribute('class',editedCellMakeDirty.firstChild.getAttribute('class')+' make-cell-dirty ');

                                var firstColumnCell = e.row.childNodes[0];
                                var firstClassAttr = firstColumnCell.firstChild.getAttribute('class');
                                if(firstClassAttr.indexOf('make-cell-dirty') === -1){
                                    firstColumnCell.firstChild.setAttribute('class',firstClassAttr+' make-cell-dirty ');
                                    firstColumnCell.firstChild.setAttribute('data-qtip', TS.T("TAG044", "This row has one or more issues. Please correct before proceeding"));
                                }
                            }
                            else{
                                e.record.set('isRowHasError',false);
                                var firstColumnCell = e.row.childNodes[0];
                                var firstClassAttr = firstColumnCell.firstChild.getAttribute('class');
                                var qtipAtrr = firstColumnCell.firstChild.getAttribute('data-qtip');
                                if(firstClassAttr.indexOf('make-cell-dirty') !== -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    firstColumnCell.firstChild.removeAttribute('data-qtip');
                                    firstColumnCell.firstChild.setAttribute('class',firstClassAttr.replace('make-cell-dirty','').trim());
                                }
                            }
                        }
                    }
                });

                this.comboBoxRenderer = function(combo) {
                  return function(value) {
                    var idx = combo.store.find(combo.valueField, value);
                    var rec = combo.store.getAt(idx);
                    return ((rec === null || rec === undefined) ? '' : Ext.String.htmlEncode(rec.get(combo.displayField)));
                  };
                }
                
                Ext.apply(this, {
                    width: 600,
                    plugins: [this.cellEditing],
                    store: new Ext.data.Store({
                        storeId: 'Condition_Rule_Store',
                        fields: [
                            'isRowHasError',
                            'conditionRuleId',
                            'sequence', 
                            'selectedField',
                            'selectedOperator',
                            'frequency',
                            'startAt',
                            'threshold',
                            'stopAt',
                            'selectedAdjustmentType',
                            'minAdjustment',
                            'maxAdjustment',
                            'adjustmentVal',
                            'selectedAdjustedUnit'
                        ]
                    }),
                    columns: [{
                        xtype: 'actioncolumn',
                        width: 40,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        items: [{
                            iconCls: 'pmplantemplate-delete-row-icon',
                            tooltip: TS.T("TAG029", "Delete"),
                            scope: this,
                            handler: this.onRemoveClick
                        }]
                    }, {
                        header: TS.T("TAG014", "Sequence"),
                        dataIndex: 'sequence',
                        width: 80,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center'
                    }, {
                        header: TS.T("TAG015", "Attribute"),
                        dataIndex: 'selectedField',
                        width: 150,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: TS.T("TAG016", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: this.comboBoxRenderer(this.operatorCombo),
                        __parent: this,
                        getEditor: function(record){
                            var selectedField = record.data.selectedField;
                            if(selectedField !== null && selectedField !== ''){
                                return this.__parent.operatorCombo;
                            }
                        }
                    }, {
                        header: TS.T("TAG017", "Frequency"),
                        dataIndex: 'frequency',
                        width: 100,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue !== null && fieldValue !== ''){
                                if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 1,
                                            allowDecimals: false,
                                            nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        })
                                    });
                                }
                                else{
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 0.1,
                                            enableKeyEvents: true,
                                            nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                            listeners: {
                                                keypress: function(field, e) {
                                                    var v = field.getValue();
                                                    if (!Ext.isEmpty(v)) {
                                                        if (/\.\d{2,}/.test(v)) {
                                                            e.stopEvent();
                                                        }
                                                    }
                                                }
                                            }
                                        })
                                    });
                                }
                            }
                        }
                    }, {
                        header: TS.T("TAG019", "Start At"),
                        dataIndex: 'startAt',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != '' && (record.data.selectedField === 'Weeks' || record.data.selectedField === 'Months' || record.data.selectedField === 'Years')){
                                var date = new Date(value);
                                var month = ("0" + (date.getMonth()+1)).slice(-2);
                                var day  = ("0" + date.getDate()).slice(-2);
                                return [month, day, date.getFullYear()].join("-");    
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                var dateField = Ext.create( 'Ext.form.field.Date', {
                                    format: 'm-d-Y',
                                    value: Ext.Date.dateFormat(record.data.startAt, 'm-d-Y'),
                                    invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                })
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: dateField
                                });
                            }
                            else{
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        enableKeyEvents: true,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        listeners: {
                                            keypress: function(field, e) {
                                                var v = field.getValue();
                                                if (!Ext.isEmpty(v)) {
                                                    if (/\.\d{2,}/.test(v)) {
                                                        e.stopEvent();
                                                    }
                                                }
                                            }
                                        }
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG020", "Threshold %"),
                        dataIndex: 'threshold',
                        width: 100,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var fieldValue = record.data.selectedField;
                            if(fieldValue !== 'Weeks' && fieldValue !== 'Months' && fieldValue !== 'Years'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        allowDecimals: false,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG021", "Stop At"),
                        dataIndex: 'stopAt',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != '' && (record.data.selectedField === 'Weeks' || record.data.selectedField === 'Months' || record.data.selectedField === 'Years')){
                                var date = new Date(value);
                                var month = ("0" + (date.getMonth()+1)).slice(-2);
                                var day  = ("0" + date.getDate()).slice(-2);
                                return [month, day, date.getFullYear()].join("-");    
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                var dateField = Ext.create( 'Ext.form.field.Date', {
                                    format: 'm-d-Y',
                                    value: Ext.Date.dateFormat(record.data.stopAt, 'm-d-Y'),
                                    invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                })
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: dateField
                                });
                            }
                            else{
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        enableKeyEvents: true,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        listeners: {
                                            keypress: function(field, e) {
                                                var v = field.getValue();
                                                if (!Ext.isEmpty(v)) {
                                                    if (/\.\d{2,}/.test(v)) {
                                                        e.stopEvent();
                                                    }
                                                }
                                            }
                                        }
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG022", "Adjustment Type"),
                        dataIndex: 'selectedAdjustmentType',
                        width: 110,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.adjustmentTypeCombo,
                        renderer: this.comboBoxRenderer(this.adjustmentTypeCombo)
                    }, {
                        header: TS.T("TAG023", "Minimum Adjustment"),
                        dataIndex: 'minAdjustment',
                        width: 125,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType; 
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        enableKeyEvents: true,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        listeners: {
                                            keypress: function(field, e) {
                                                var v = field.getValue();
                                                if (!Ext.isEmpty(v)) {
                                                    if (/\.\d{2,}/.test(v)) {
                                                        e.stopEvent();
                                                    }
                                                }
                                            }
                                        }
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG024", "Maximum Adjustment"),
                        dataIndex: 'maxAdjustment',
                        width: 130,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType; 
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        enableKeyEvents: true,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        listeners: {
                                            keypress: function(field, e) {
                                                var v = field.getValue();
                                                if (!Ext.isEmpty(v)) {
                                                    if (/\.\d{2,}/.test(v)) {
                                                        e.stopEvent();
                                                    }
                                                }
                                            }
                                        }
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG025", "Adjustment Value"),
                        dataIndex: 'adjustmentVal',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType;
                            if (adjustmentTypeValue === 'Fixed') {
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        enableKeyEvents: true,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        listeners: {
                                            keypress: function(field, e) {
                                                var v = field.getValue();
                                                if (!Ext.isEmpty(v)) {
                                                    if (/\.\d{2,}/.test(v)) {
                                                        e.stopEvent();
                                                    }
                                                }
                                            }
                                        }
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG026", "Adjustment Unit"),
                        dataIndex: 'selectedAdjustedUnit',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: this.comboBoxRenderer(this.adjustmentUnitCombo),
                        __parent: this,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType;
                            var selectedField = record.data.selectedField;
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None' && selectedField !== null && selectedField !== '' ){
                                return this.__parent.adjustmentUnitCombo;
                            }
                        }
                    }],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG028", "Add row"),
                        id: 'addRowButton',
                        scope: this,
                        handler: this.onAddClick,
                        cls: 'pmplantemplate-blue-link'
                    }]
                });
                
                this.callParent();
            },
            
            onAddClick: function(button){
                var recCount = this.getStore().getCount();
                var rec = {
                    sequence: recCount+1,
                    isRowHasError : false
                };
                if(recCount < 5){
                    //inserting row in the grid
                    this.getStore().insert(recCount, rec);
                    if(recCount == 4){
                        button.setDisabled(true);
                    }
                }
                Ext.getCmp('buildSampleSchedule').setDisabled(false);
            },
            
            onRemoveClick: function(grid, rowIndex, aa, bb){
                var store = this.getStore();
                store.removeAt(rowIndex);
                var recCount = store.getCount();
                for(var i = rowIndex; i<recCount; i++){
                    var rec = store.getAt(i);
                    rec.set('sequence', i+1);
                }

                var addRowButtonCmp = Ext.getCmp('addRowButton');
                if(recCount < 5 && addRowButtonCmp.isDisabled()){    
                    addRowButtonCmp.setDisabled(false);
                }

                if(recCount === 0){
                    Ext.getCmp('buildSampleSchedule').setDisabled(true);
                }
            }
        })
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplantemplate.ui.desktop\src\conditionRuleCriteriaBased.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleCriteriaBased", {
            extend: 'Ext.form.FormPanel',

            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG027", "Condition Rules")
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);

                var fieldListStore = Ext.create('Ext.data.Store', {
                    storeId: 'Field_List_Store_CB',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });
                this.__grid = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleGrid", {
                    __fieldStore: fieldListStore
                });
                this.add(this.__grid);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            __fieldStore: null,
            __rowData: null,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {
                this.fieldCombo = new SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.GroupComboBox",{
                    id: 'fieldComboCmp_CB',
                    typeAhead: true,
                    queryMode: 'local',
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: this.__fieldStore,
                    displayField: 'fieldLabel',
                    valueField: 'fieldApiName',
                    groupField: 'category',
                    editable: false
                });

                var initialOperatorStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":TS.T("COMM_TAG010", "Equals"), 
                            "value":"eq",
                            "type": "TEXT_PICKLIST"
                        },
                        {
                            "label":TS.T("COMM_TAG011", "Greater Than"), 
                            "value":"gt",
                            "type": ""
                        },
                        {
                            "label":TS.T("COMM_TAG012", "Less Than"), 
                            "value":"lt",
                            "type": ""
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    }
                });
                this.operatorCombo = new Ext.form.field.ComboBox({
                    id: 'operatorComboCmp_CB',
                    typeAhead: true,
                    triggerAction: 'all',
                    queryMode: 'local',
                    selectOnTab: true,
                    displayField: 'label',
                    store: initialOperatorStore,
                    valueField: 'value',
                    editable: false,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            var Fstore = Ext.getStore('Field_List_Store_CB');
                            var recFromStore = Fstore.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                            var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(dataTypeForSelectedField === 'TEXT' || dataTypeForSelectedField === 'PICKLIST'){
                                    combo.store.filter('type','TEXT_PICKLIST');
                                }
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var TA_PA_Store = Ext.create('Ext.data.Store', {
                    storeId: 'TA_PA_Store',
                    fields: ['fieldApiName', 'label', 'value']
                });
                this.TA_PA_Combo = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'TA_PA_ComboCmp',
                    store: TA_PA_Store,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'value',
                    editable: false,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                combo.store.filter('fieldApiName',selectedFieldValue);
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    __parent: this,
                    listeners: {
                        beforeedit: function(editor, e){
                            this.__parent.__rowData = e.record.data;
                            var operatorComboCmp = Ext.getCmp('operatorComboCmp_CB');
                            operatorComboCmp.store.clearFilter();

                            var TA_PA_ComboCmp = Ext.getCmp('TA_PA_ComboCmp');
                            TA_PA_ComboCmp.store.clearFilter();
                        },
                        edit: function(editor, e){
                            if(e.field === 'selectedField'){
                                var selectedFieldValue = e.value;
                                var originalSelectedFieldValue = e.originalValue;
                                var dataTypeForOriginalSelectedField = '';
                                var dataTypeForSelectedField = '';
                                var Fstore = Ext.getStore('Field_List_Store_CB');
                                var recFromStore = Fstore.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                                var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                if(originalSelectedFieldValue !== '' && originalSelectedFieldValue !== null){
                                    recFromStore = Fstore.findRecord('fieldApiName',originalSelectedFieldValue, 0, false, true, true);
                                    dataTypeForOriginalSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                }

                                if((dataTypeForSelectedField === 'TEXT' || dataTypeForSelectedField === 'PICKLIST') && (dataTypeForOriginalSelectedField !== '' && (dataTypeForOriginalSelectedField === 'NUMBER' || dataTypeForOriginalSelectedField === 'DATE'))) {
                                    e.record.set('selectedOperator','');
                                }
                                else if((dataTypeForSelectedField === 'NUMBER' || dataTypeForSelectedField === 'DATE') && (dataTypeForOriginalSelectedField !== '' && (dataTypeForOriginalSelectedField === 'TEXT' || dataTypeForOriginalSelectedField === 'PICKLIST'))){
                                    e.record.set('selectedOperator','');
                                }

                                if(dataTypeForOriginalSelectedField !== '' && (dataTypeForSelectedField !== dataTypeForOriginalSelectedField)){
                                    e.record.set('value','');
                                }
                                else if(dataTypeForSelectedField === 'PICKLIST' && dataTypeForOriginalSelectedField !== '' && (dataTypeForSelectedField === dataTypeForOriginalSelectedField) && (selectedFieldValue !== originalSelectedFieldValue)){
                                    e.record.set('value','');
                                }
                            }
                        }
                    }
                });

                this.comboBoxRenderer = function(combo) {
                  return function(value) {
                    var idx = combo.store.find(combo.valueField, value);
                    var rec = combo.store.getAt(idx);
                    return ((rec === null || rec === undefined) ? '' : rec.get(combo.displayField) );
                  };
                }
                
                Ext.apply(this, {
                    width: 600,
                    plugins: [this.cellEditing],
                    store: new Ext.data.Store({
                        storeId: 'Condition_Rule_Store_CB',
                        fields: [
                            'isRowHasError',
                            'conditionRuleId',
                            'sequence', 
                            'selectedField',
                            'selectedOperator',
                            'value'
                        ]
                    }),
                    columns: [{
                        xtype: 'actioncolumn',
                        width: 40,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        items: [{
                            iconCls: 'pmplantemplate-delete-row-icon',
                            tooltip: TS.T("TAG029", "Delete"),
                            scope: this,
                            handler: this.onRemoveClick
                        }]
                    }, {
                        header: TS.T("TAG014", "Sequence"),
                        dataIndex: 'sequence',
                        width: 80,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center'
                    }, {
                        header: TS.T("TAG015", "Attribute"),
                        dataIndex: 'selectedField',
                        width: 300,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: TS.T("TAG016", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 250,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: this.comboBoxRenderer(this.operatorCombo),
                        __parent: this,
                        getEditor: function(record){
                            var selectedField = record.data.selectedField;
                            if(selectedField !== null && selectedField !== ''){
                                return this.__parent.operatorCombo;
                            }
                        }
                    }, {
                        header: TS.T("TAG063", "Value"),
                        dataIndex: 'value',
                        width: 470,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        __parent: this,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != ''){
                                var fieldValue = record.data.selectedField;
                                var Fstore = Ext.getStore('Field_List_Store_CB');
                                var recFromStore = Fstore.findRecord('fieldApiName',fieldValue, 0, false, true, true);
                                var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                if(dataTypeForSelectedField === 'DATE'){
                                    var date = new Date(value);
                                    var month = ("0" + (date.getMonth()+1)).slice(-2);
                                    var day  = ("0" + date.getDate()).slice(-2);
                                    return [month, day, date.getFullYear()].join("-"); 
                                }
                                else{
                                    //return value;
                                    return Ext.String.htmlEncode(value);
                                }
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            var Fstore = Ext.getStore('Field_List_Store_CB');
                            var recFromStore = Fstore.findRecord('fieldApiName',fieldValue, 0, false, true, true);
                            var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                            if(dataTypeForSelectedField !== null && dataTypeForSelectedField !== ''){
                                if(dataTypeForSelectedField === 'DATE'){
                                    var dateField = Ext.create( 'Ext.form.field.Date', {
                                        format: 'm-d-Y',
                                        value: Ext.Date.dateFormat(record.data.value, 'm-d-Y'),
                                        invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                    })
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: dateField
                                    });
                                }
                                else if(dataTypeForSelectedField === 'TEXT'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Text', {
                                        })
                                    });
                                }
                                else if(dataTypeForSelectedField === 'NUMBER'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 0.1,
                                            enableKeyEvents: true,
                                            nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                            listeners: {
                                                keypress: function(field, e) {
                                                    var v = field.getValue();
                                                    if (!Ext.isEmpty(v)) {
                                                        if (/\.\d{2,}/.test(v)) {
                                                            e.stopEvent();
                                                        }
                                                    }
                                                }
                                            }
                                        })
                                    });
                                }
                                else if(dataTypeForSelectedField === 'PICKLIST'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: this.__parent.TA_PA_Combo
                                    });
                                }
                            }
                        }
                    }],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG028", "Add row"),
                        id: 'addRowButton_CB',
                        scope: this,
                        handler: this.onAddClick,
                        cls: 'pmplantemplate-blue-link'
                    }]
                });
                
                this.callParent();
            },
            
            onAddClick: function(button){
                var recCount = this.getStore().getCount();
                var rec = {
                    sequence: recCount+1,
                    isRowHasError : false
                };
                if(recCount < 5){
                    //inserting row in the grid
                    this.getStore().insert(recCount, rec);
                    if(recCount == 4){
                        button.setDisabled(true);
                    }
                }
                Ext.getCmp('buildSampleSchedule').setDisabled(false);
            },
            
            onRemoveClick: function(grid, rowIndex, aa, bb){
                var store = this.getStore();
                store.removeAt(rowIndex);
                var recCount = store.getCount();
                for(var i = rowIndex; i<recCount; i++){
                    var rec = store.getAt(i);
                    rec.set('sequence', i+1);
                }

                var addRowButtonCmp = Ext.getCmp('addRowButton_CB');
                if(recCount < 5 && addRowButtonCmp.isDisabled()){    
                    addRowButtonCmp.setDisabled(false);
                }

                if(recCount === 0){
                    Ext.getCmp('buildSampleSchedule').setDisabled(true);
                }
            }
        })
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplantemplate.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.pmplantemplate.ui.desktop.api.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.init();
        }

	}, {
		instance : null
	});

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplantemplate.ui.desktop\src\scheduleWindow.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow.ScheduleWindow", {
            extend: 'Ext.window.Window',
            id: 'scheduleWindow',
            border: 0,
            resizable: false,
            modal: true,
            closable: true,
            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG056", "Sample Schedules")
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                var schedulePanel = SVMX.create("Ext.form.FormPanel", {
                    id: 'schedulePanel',
                    collapsible: false,
                    region: 'center',
                    width: 'calc(100% - 20px)',
                    border: false,
                    layout: 'anchor',
                    layout: {
                        type: "anchor",
                        align: "stretch"
                    },
                    margin: '0 10px',
                    style:{
                        top: '20px'
                    }
                });

                //Creating a store for holding schedule
                var scheduleListStore = Ext.create('Ext.data.Store', {
                    storeId: 'Schedule_List_Store',
                    fields: ['scheduleName']
                });

                var noteLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    text: (this.conditionTypeValue == 'Usage_Frequency')? TS.T("TAG055", "These are some sample schedules for the condition defined. There may be more.") : TS.T("TAG066", "This is the sample schedule for the condition defined."),
                    style:{
                        fontSize: '14px'
                    }
                });
                schedulePanel.add(noteLabel);

                //Creating a grid to show sample schedules
                var scheduleGrid = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXListComposite",{
                    store: scheduleListStore,
                    margin: '15px 0px 10px 0px',
                    autoScroll: true,
                    maxHeight: 440,
                    columns: [{
                        text: TS.T("TAG057", "Schedule Output"),
                        dataIndex: 'scheduleName',
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        flex: 1,
                        renderer: function(value, metadata) {
                            metadata.style = 'white-space: normal;';
                            return Ext.String.htmlEncode(value);
                        }
                    }]
                });
                schedulePanel.add(scheduleGrid);
                me.add(schedulePanel);
            },

            loadDataInStore: function(data){
                var scheduleListStore = Ext.data.StoreManager.lookup('Schedule_List_Store');
                scheduleListStore.loadData(data);
            }
        });
    }
})();

