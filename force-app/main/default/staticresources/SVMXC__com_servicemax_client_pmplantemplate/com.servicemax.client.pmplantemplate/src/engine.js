/**
 * @class com.servicemax.client.pmplantemplate.engine
 * @author Manish
 *
 * @copyright 2017 ServiceMax, Inc.
 */

(function() {
    var engine = SVMX.Package("com.servicemax.client.pmplantemplate.engine");

    engine.init = function() {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
            __root: null,
            __loadMask: null,
            __isContainerExternal: null,
            __parent: null,
            __translation: null,
            __view: null,
            __constructor: function() {
                this.__base();
                this.__isContainerExternal = false;
            },

            initAsync: function(options) {

                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.pmplantemplate.impl.PMPLANEngineEventBus", {});

                // create the named default controller
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        // now create the named default model
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                // Now it is the view's turn
                                ni.createNamedInstanceAsync("PMPLAN.VIEW",{ handler : function(view){
                                    this.__view = view;
                                    options.handler.call(options.context);
                                }, context: this, additionalParams: {eventBus: this.getEventBus()}});
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: {
                        eventBus: this.__eventBus
                    }
                });
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            translate: function(key) {
                return TS.T(key);
            },

            getAllTranslation: function() {
                return this.__translation;
            },

            __appCurrentState: "",
            changeApplicationState: function(newState) {
                if (this.__appCurrentState === newState) return;

                this.__appCurrentState = newState;
                if (newState == "block") {
                    if (!this.__loadMask) {
                        this.__loadMask = new com.servicemax.client.ui.components.utils.LoadMask({
                            parent: this.__root
                        });
                    }
                    this.__loadMask.show({});
                    this.__loadMask.setZIndex(50000); // some high number
                } else if (newState == "unblock" && this.__loadMask !== null) {
                    if (this.__loadMask !== null) {
                        this.__loadMask.hide();
                    }
                }
            },

            reset: function() {
                this.getRoot().destroy();
                this.__root = null;
                this.run(this.options);
            },

            triggerEvent: function(evt) {
                this.__eventBus.triggerEvent(evt);
            },

            run: function(options) {
                this.options = options || {};

                //----Start-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event
                var userInfo = SVMX.toObject(SVMX.getClient().getApplicationParameter('svmx-pmplantemplate-userinfo'));
                var client = SVMX.getClient();
                var evtUserInfo = SVMX.create('com.servicemax.client.lib.api.Event', 'GLOBAL.HANDLE_USER_INFO', this, userInfo);
                client.triggerEvent(evtUserInfo);
                //----End-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event

                this.changeApplicationState("block");
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetFilterListResponder", this);
                var request = {
                    objectName: SVMX.OrgNamespace+'__Installed_Product__c'
                };
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_FILTER_LIST', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetFilterListCompleted: function(result){
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    deliveryEngine: this
                });

                this.__root.run({
                    // Any options that should be passed.
                });

                // Render in our root div.
                this.__root.render(SVMX.getDisplayRootId());

                if (this.options.onReady) {
                    this.options.onReady.handler.call(this.options.onReady.context || this);
                }

                //Setting default value for checkbox
                var recordId = SVMX.getUrlParameter('SVMX_RecordId');
                if(recordId === undefined){
                    Ext.getCmp('useCurrentFieldVal').setVisible(true);
                    Ext.getCmp('useCurrentFieldVal').setValue(true); //Create New mode
                    Ext.getCmp('conditionRuleTabPanel').setVisible(true);
                }

                this.transformResponseDataToStoreForm(result,'exprId','exprName',true,'IB_Filter_Store','installedProductFilterCombo');

                //get Task Template
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetTaskTemplateResponder", this);
                var request = {};
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_TASK_TEMPLATE', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetTaskTemplateCompleted: function(result){
                this.transformResponseDataToStoreForm(result,'taskTemplateId','taskTemplateName',true,'WO_Purpose_Store','workOrderPurposeCombo');

                //get Activity Date list
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetActivityDateListResponder", this);
                var request = {};
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_ACTIVITY_DATE_LIST', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetActivityDateListCompleted: function(result){
                this.transformResponseDataToStoreForm(result,'fieldLabel','fieldApiName',false,'Activity_Date_Store','activityDateCombo');

                //get Picklist Values
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetPicklistValuesResponder", this);
                var listOfField = [SVMX.OrgNamespace+'__Coverage_Type__c', SVMX.OrgNamespace+'__SM_Schedule_Type__c'];
                var request = {
                    'lstOfValues':listOfField
                };
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_PICKLIST_VALUES', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetPicklistValuesCompleted: function(result){
                //set the key prefix in the variable
                if(result.listKeyValue != null && result.listKeyValue.length > 0 && result.listKeyValue[0].key == 'KEYPREFIX')
                    this.__keyPrefix = result.listKeyValue[0].value;

                var listOfObjectNameAndPickValue = result.mapOfKeyAndListOfKeyValue;
                if(listOfObjectNameAndPickValue != null && listOfObjectNameAndPickValue.length > 0){
                    var listOfValueForCoverage = [];
                    var listOfValueForSchedule = [];
                    for(var i=0; i<listOfObjectNameAndPickValue.length; i++){
                        var objKeyObject = listOfObjectNameAndPickValue[i];
                        var listOfValues = objKeyObject.lstOfKeyValue;
                        for(var j=0; j<listOfValues.length; j++){
                            var objForDropDown = {
                                'name': listOfValues[j].key,
                                'label': listOfValues[j].value
                            };
                            if(objKeyObject.key == SVMX.OrgNamespace+'__Coverage_Type__c'){   
                                listOfValueForCoverage.push(objForDropDown);
                            }
                            else if(objKeyObject.key == SVMX.OrgNamespace+'__SM_Schedule_Type__c'){
                                listOfValueForSchedule.push(objForDropDown);
                            }
                        }
                    }
                    var scheduleTypeStore = Ext.data.StoreManager.lookup('Schedule_Type_Store');
                    scheduleTypeStore.loadData(listOfValueForSchedule);
                    var valueOfFirstRecord = scheduleTypeStore.getAt(scheduleTypeStore.findExact('name', 'Condition Based')).getData('name').name;
                    var combo = Ext.getCmp('scheduleTypeCombo');
                    combo.setValue(valueOfFirstRecord);

                    var CoverageTypeStore = Ext.data.StoreManager.lookup('Coverage_Type_Store');
                    CoverageTypeStore.loadData(listOfValueForCoverage);
                    valueOfFirstRecord = CoverageTypeStore.getAt(CoverageTypeStore.findExact('name', 'Product (Must Have IB)')).getData('name').name;
                    combo = Ext.getCmp('coverageTypeCombo');
                    combo.setValue(valueOfFirstRecord);
                }
                this.changeApplicationState("unblock");

                //Get Record Data if load mode is edit
                var recordId = SVMX.getUrlParameter('SVMX_RecordId');
                if(recordId != undefined && recordId.length > 0){
                    var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetRecordInfoResponder", this);
                    var request = {
                        'pmPlanTemplateId': recordId
                    };
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_RECORD_INFO', this, 
                        { request: request, responder: responder }
                    );
                    this.triggerEvent(evt);
                }
            },

            onGetRecordInfoCompleted: function(result){
                //populate the data in the UI
                var pmPlanTemplate = result.pmPlanTemplate;
                if(result.success && pmPlanTemplate.templateId != null){
                    Ext.getCmp('templateNameBox').setValue(pmPlanTemplate.templateName);
                    Ext.getCmp('scheduleTypeCombo').setValue(pmPlanTemplate.scheduleType);
                    Ext.getCmp('coverageTypeCombo').setValue(pmPlanTemplate.coverageType);
                    Ext.getCmp('installedProductFilterCombo').setValue((pmPlanTemplate.installedProductFilter === null ? 'None' : pmPlanTemplate.installedProductFilter));
                    Ext.getCmp('activityDateCombo').setValue(pmPlanTemplate.activityDate);
                    Ext.getCmp('workOrderPurposeCombo').setValue((pmPlanTemplate.workOrderPurpose === null ? 'None' : pmPlanTemplate.workOrderPurpose));
                    Ext.getCmp('advancedExpression').setValue(pmPlanTemplate.advancedExpression);
                    Ext.getCmp('useCurrentFieldVal').setValue(pmPlanTemplate.useCurrentFieldVal);
                    Ext.getCmp('conditionTypeCombo').setValue(pmPlanTemplate.conditionType);

                    if(pmPlanTemplate.conditionType === 'Usage_Frequency'){
                        Ext.getCmp('useCurrentFieldVal').setVisible(true);
                        Ext.getCmp('conditionRuleTabPanel').setVisible(true);
                        Ext.getCmp('conditionRuleTabPanelForCriteria').setVisible(false);
                    }
                    else if(pmPlanTemplate.conditionType === 'Criteria_Comparison'){
                        Ext.getCmp('useCurrentFieldVal').setVisible(false);
                        Ext.getCmp('conditionRuleTabPanel').setVisible(false);
                        Ext.getCmp('conditionRuleTabPanelForCriteria').setVisible(true);
                    }

                    var productInfo = [{
                        'name': pmPlanTemplate.product,
                        'label': pmPlanTemplate.productName
                    }];
                    var productStore = Ext.data.StoreManager.lookup('Product_Store');
                    productStore.loadData(productInfo);
                    Ext.getCmp('productCombo').setValue(pmPlanTemplate.product);
                    this.__templateId = pmPlanTemplate.templateId;

                    //load the field list
                    this.onGetTechnicalAttributeCompleted(result);

                    //loading condition rule data
                    if(result.conditionRuleList != null && result.conditionRuleList.length > 0){
                        var conditionRuleInfo = [];
                        var conditionRuleList = result.conditionRuleList;
                        var conditionRuleListSize = conditionRuleList.length;
                        for(var i=0; i<conditionRuleListSize; i++){
                            var conditionRuleObject;
                            if(pmPlanTemplate.conditionType === 'Usage_Frequency'){
                                var fieldValue;
                                var selectedFreqUnitValue = conditionRuleList[i].selectedFreqUnit;
                                var selectedFieldValue = conditionRuleList[i].selectedField;
                                if(selectedFreqUnitValue === 'Count'){
                                    fieldValue = selectedFieldValue;
                                }
                                else{
                                    fieldValue = selectedFreqUnitValue;
                                }
                                conditionRuleObject = conditionRuleList[i];
                                conditionRuleObject.selectedField = fieldValue;
                                if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years'){
                                    if(conditionRuleObject.startAt !== null && conditionRuleObject.startAt !== ''){
                                        var splitDate = conditionRuleObject.startAt.split('-');
                                        conditionRuleObject.startAt = new Date(splitDate[0], parseInt(splitDate[1])-1, splitDate[2]);
                                    }
                                    if(conditionRuleObject.stopAt !== null && conditionRuleObject.stopAt !== ''){
                                        splitDate = conditionRuleObject.stopAt.split('-');
                                        conditionRuleObject.stopAt = new Date(splitDate[0], parseInt(splitDate[1])-1, splitDate[2]);
                                    }
                                }
                                conditionRuleObject.isRowHasError = false;
                            }
                            else if(pmPlanTemplate.conditionType === 'Criteria_Comparison'){
                                var fieldDataTypeValue = conditionRuleList[i].fieldDataType;
                                conditionRuleObject = conditionRuleList[i];
                                if(fieldDataTypeValue.toUpperCase() === 'DATE'){
                                    if(conditionRuleObject.value !== null && conditionRuleObject.value !== ''){
                                        var splitDate = conditionRuleObject.value.split('-');
                                        conditionRuleObject.value = new Date(splitDate[0], parseInt(splitDate[1])-1, splitDate[2]);
                                    }
                                }
                                conditionRuleObject.isRowHasError = false;
                            }
                            conditionRuleInfo.push(conditionRuleObject);
                        }
                        //Disable the add row button if rules are five
                        if(conditionRuleListSize >= 5){
                            Ext.getCmp('addRowButton').setDisabled(true);
                            Ext.getCmp('addRowButton_CB').setDisabled(true);
                        }
                        var conditionRuleStore;
                        if(pmPlanTemplate.conditionType === 'Usage_Frequency'){
                            conditionRuleStore = Ext.data.StoreManager.lookup('Condition_Rule_Store');
                        }
                        else if(pmPlanTemplate.conditionType === 'Criteria_Comparison'){
                            conditionRuleStore = Ext.data.StoreManager.lookup('Condition_Rule_Store_CB');
                        }
                        conditionRuleStore.loadData(conditionRuleInfo);

                        //Enable the sample schedule button
                        Ext.getCmp('buildSampleSchedule').setDisabled(false);
                    }
                }
            },

            searchObject: function(request){
                //search product records
                this.changeApplicationState("block");
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.SearchObjectResponder", this);
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.SEARCH_OBJECT', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onSearchObjectCompleted: function(result){
                //populate the list of product records
                if(result.success){
                    var productStore = Ext.data.StoreManager.lookup('Product_Store');
                    if(result.searchResponse != null && result.searchResponse.length > 0){
                        var productList = result.searchResponse;
                        var productListArray = [];
                        for(var i=0; i<productList.length; i++){
                            var productInfo = {
                                'name': productList[i].Id,
                                'label': productList[i].name
                            };
                            productListArray.push(productInfo);
                        }
                        productStore.loadData(productListArray);
                    }
                    else{
                        productStore.removeAll();
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG011", "No matches found. Please refine your search criteria"), 7000, 'success');
                    }
                }
                else{
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                }
                this.changeApplicationState("unblock");
            },

            saveTemplateData: function(formData, ruleData){
                //call the remote action to save data
                this.changeApplicationState("block");
                var transformedRuleData;
                if(formData.conditionType === '' || formData.conditionType === 'Usage_Frequency'){
                    transformedRuleData = this.transformedRuleDataInRequest(ruleData);
                }
                else if(formData.conditionType === 'Criteria_Comparison'){
                    transformedRuleData = this.transformedCriteriaRuleDataInRequest(ruleData);
                }
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.SaveTemplateDataResponder", this);
                var request = {
                    'pmPlanTemplate': formData,
                    'pmPlanTemplateId': this.__templateId,
                    'conditionRuleList': transformedRuleData
                };
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.SAVE_TEMPLATE_DATA', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onSaveTemplateDataCompleted: function(result){
                //On save complete, navigate the page to saved record
                this.__templateId = result.pmPlanTemplateId;
                this.changeApplicationState("unblock");
                if(result.success){
                    if(result.pmPlanTemplateId != null && result.pmPlanTemplateId.length > 0){
                        var urlString = '/'+result.pmPlanTemplateId;
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location.href = urlString;
                        }
                    }
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                }
                else{
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                }
            },

            getTechnicalAttribute: function(productId, condtionTypeValue){
                //call the remote action to fetch technical attributes
                this.changeApplicationState("block");
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetTechnicalAttributeResponder", this);
                var request = {
                    'productId': productId,
                    'pmPlanTemplate': {
                        'conditionType': condtionTypeValue
                    }
                };
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_TECHNICAL_ATTRIBUTE', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetTechnicalAttributeCompleted: function(result){
                if(result.success){
                    var fieldListOfBoth = result.mapOfKeyAndListOfKeyValue;
                    var listOfStoreRecords = [];
                    var listOfPicklistValues = [];
                    for(var i=0; i<fieldListOfBoth.length; i++){
                        var category = fieldListOfBoth[i].key;
                        var listOfFields = fieldListOfBoth[i].lstOfKeyValue;
                        for(var j=0; j<listOfFields.length; j++){
                            var sanitizedFieldLabel = SVMX.sanitizeHTML(listOfFields[j].value);
                            var record = {
                                'fieldApiName': listOfFields[j].key,
                                'fieldLabel': sanitizedFieldLabel,
                                'dataType': listOfFields[j].dataType,
                                'category': category,
                                'attributeType': listOfFields[j].attrType
                            };
                            listOfStoreRecords.push(record);

                            //Creating list of picklist values
                            if(listOfFields[j].dataType.toUpperCase() === 'PICKLIST'){
                                var listOfValues = listOfFields[j].lstValues || [];
                                for(var k=0; k<listOfValues.length; k++){
                                    var valueRec = {
                                        'fieldApiName': listOfFields[j].key,
                                        'label': listOfValues[k].label,
                                        'value': listOfValues[k].value
                                    };
                                    listOfPicklistValues.push(valueRec);
                                }
                            }
                        }
                    }
                    var fieldListStore;
                    if(result.pmPlanTemplate.conditionType === '' || result.pmPlanTemplate.conditionType === 'Usage_Frequency'){
                        fieldListStore = Ext.data.StoreManager.lookup('Field_List_Store');
                    }
                    else if(result.pmPlanTemplate.conditionType === 'Criteria_Comparison'){
                        fieldListStore = Ext.data.StoreManager.lookup('Field_List_Store_CB');
                        var picklistValueStoreCB = Ext.data.StoreManager.lookup('TA_PA_Store');
                        picklistValueStoreCB.loadData(listOfPicklistValues);
                    }
                    fieldListStore.loadData(listOfStoreRecords);
                }
                else{
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                }
                this.changeApplicationState("unblock");
            },

            getSampleSchedules: function(formData, ruleData){
                //call the remote action to fetch Sample Schedules
                this.changeApplicationState("block");
                var transformedRuleData;
                //This is added as part of BAC-2246 story to handle updgrade scenario
                if(formData.conditionType === 'Criteria_Comparison'){
                    transformedRuleData = this.transformedCriteriaRuleDataInRequest(ruleData);
                }
                else{
                    transformedRuleData = this.transformedRuleDataInRequest(ruleData);
                }
                var advancedExpression = formData.advancedExpression;
                var responder = SVMX.create("com.servicemax.client.pmplantemplate.responders.GetSampleSchedulesResponder", this);
                var pmPlanTemplate = {
                    'advancedExpression': advancedExpression,
                    'conditionType': formData.conditionType
                };
                var request = {
                    'conditionRuleList': transformedRuleData,
                    'pmPlanTemplate': pmPlanTemplate
                };
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'PMPLAN.GET_SAMPLE_SCHEDULES', this, 
                    { request: request, responder: responder }
                );
                this.triggerEvent(evt);
            },

            onGetSampleSchedulesCompleted: function(result){
                this.changeApplicationState("unblock");
                if(result.success){
                    var scheduleRecList = [];
                    var scheduleList = result.scheduleList;
                    var scheduleListCount = scheduleList.length<=50 ? scheduleList.length : 50
                    for(var i=0; i<scheduleListCount; i++){
                        var scheduleRec = {
                            'scheduleName': scheduleList[i].scheduleName
                        }
                        scheduleRecList.push(scheduleRec);
                    }
                    var scheduleWindow = Ext.getCmp('scheduleWindow');
                    scheduleWindow.loadDataInStore(scheduleRecList);
                    scheduleWindow.show();
                }
                else{
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                }
            },

            transformResponseDataToStoreForm: function(result, fieldValue, fieldLabel, addNone, storeId, componentId){
                //transforming the reponse data to respective store and setting the default value
                var dataList = result.listKeyValue;
                if(dataList != null && dataList.length > 0){
                    var dataListArray = [];
                    if(addNone){
                        var obj = {};
                        obj[fieldValue] = 'None';
                        obj[fieldLabel] = TS.T("COMM_TAG004", "--None--");
                        dataListArray.push(obj);
                    }
                    for(var i=0; i<dataList.length; i++){
                        var dataObj = {};
                        dataObj[fieldValue] = dataList[i].value;
                        dataObj[fieldLabel] = dataList[i].key;
                        dataListArray.push(dataObj);
                    }
                    var store = Ext.data.StoreManager.lookup(storeId);
                    store.loadData(dataListArray);

                    var valueOfFirstRecord = store.getAt(0).getData(fieldValue)[fieldValue];
                    if(storeId === 'Activity_Date_Store'){ //Added for the defect RS-7614 fix
                        valueOfFirstRecord = store.getAt(0).getData(fieldLabel)[fieldLabel];
                    }
                    var combo = Ext.getCmp(componentId);
                    combo.setValue(valueOfFirstRecord);
                }
            },

            transformedRuleDataInRequest: function(ruleData){
                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplantemplate-userinfo');
                var listOfRule = [];
                var fieldListStore = Ext.data.StoreManager.lookup('Field_List_Store');

                for(var i=0; i<ruleData.length; i++){
                    var objRule = JSON.parse(JSON.stringify(ruleData[i].data));
                    var fieldValue = ruleData[i].data.selectedField;
                    var selectedFreqUnitValue;
                    var selectedFieldValue;
                    if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years'){
                        selectedFieldValue = '';
                        selectedFreqUnitValue = fieldValue;
                        objRule.fieldDataType = 'Date';
                    }
                    else{
                        selectedFieldValue = fieldValue;
                        selectedFreqUnitValue = 'Count';
                    }
                    var recFromStore = fieldListStore.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                    objRule.selectedField = selectedFieldValue;
                    objRule.selectedFreqUnit = selectedFreqUnitValue;
                    if(recFromStore != null){
                        objRule.fieldAttType = recFromStore.getData().attributeType;
                        objRule.fieldDataType = recFromStore.getData().dataType;
                    }
                    if(selectedFreqUnitValue === 'Count'){
                        objRule.startAt = ruleData[i].data.startAt;
                        objRule.stopAt = ruleData[i].data.stopAt;
                    }
                    else{
                        if(ruleData[i].data.startAt != null && ruleData[i].data.startAt != ''){
                            objRule.startAt = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].data.startAt, userInfo.TimezoneOffset, false).substring(0,10);
                        }
                        if(ruleData[i].data.stopAt != null && ruleData[i].data.stopAt != ''){
                            objRule.stopAt = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].data.stopAt, userInfo.TimezoneOffset, false).substring(0,10);
                        }
                    }
                    listOfRule.push(objRule);
                }
                return listOfRule;
            },

            transformedCriteriaRuleDataInRequest: function(ruleData){
                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplantemplate-userinfo');
                var listOfRule = [];
                var fieldListStoreCB = Ext.data.StoreManager.lookup('Field_List_Store_CB');

                for(var i=0; i<ruleData.length; i++){
                    var objRule = JSON.parse(JSON.stringify(ruleData[i].data));
                    var selectedFieldValue = ruleData[i].data.selectedField;
                    var recFromStore = fieldListStoreCB.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                    objRule.selectedField = selectedFieldValue;
                    objRule.fieldAttType = recFromStore.getData().attributeType;
                    objRule.fieldDataType = recFromStore.getData().dataType;
                    objRule.selectedFieldLabel = recFromStore.getData().fieldLabel;

                    if(objRule.fieldDataType === 'DATE'){
                        if(ruleData[i].data.value != null && ruleData[i].data.value != ''){
                            objRule.value = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].data.value, userInfo.TimezoneOffset, false).substring(0,10);
                        }
                    }
                    listOfRule.push(objRule);
                }
                return listOfRule;
            },

            getKeyPrefixForTemplateObject: function(){
                return this.__keyPrefix;
            },

            getRoot: function() {
                return this.__root;
            },

            onResize: function(size) {
                this.getRoot().resize(size);
            }
        }, {});
    };
})();
// end of file