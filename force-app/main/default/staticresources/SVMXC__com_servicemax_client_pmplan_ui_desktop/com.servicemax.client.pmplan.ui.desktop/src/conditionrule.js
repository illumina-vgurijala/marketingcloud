(function () {
    var appImpl = SVMX.Package("com.servicemax.client.pmplan.ui.desktop.api.conditionrule");

    appImpl.init = function () {
        var PMPLAN = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");


        Ext.define("com.servicemax.client.pmplan.ui.desktop.api.ConditionrulePanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXWindow",
            layout: 'anchor', height: '100%', border: false,
            header: { 
                titleAlign: 'center',
                height: 40,
            },
            style: 'background-color: #FFFFFF;',
            hidden: true, width: '65%', height: '80%', layout: 'anchor', closable: false, closeAction: 'hide',
            resizable: false, autoScroll: true, cls: 'pmplan-window-container', 
            id: 'conditionrule',

            listeners:{
                hide: function(thisWindow, eOpts){
                    thisWindow.hide();
                    thisWindow.__parent.enable();
                }
            },
            constructor: function(config) {                
                this.callParent([config]);

            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                var fieldListStore = Ext.create('Ext.data.Store', {
                    storeId: 'field_list_store',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });

                var fieldListStoreCB = Ext.create('Ext.data.Store', {
                    storeId: 'Field_List_Store_CB',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });

                var conditionRuleLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: '<span>'+ PMPLAN.T("TAG064", 'Condition Rule:') +'</span>',
                    style: 'position: relative; top: 10px; margin: 10px 10px 0px 12px',
                    padding: '5 5 5 4',
                    cls: 'pmplan-grid-title'
                });
                me.add(conditionRuleLabel);

                this.__conditionRulegrid = SVMX.create("com.servicemax.client.pmplan.ui.desktop.conditionRule.ConditionRuleGrid", {
                    __fieldStore: fieldListStore

                });
                this.add(this.__conditionRulegrid);

                this.__conditionRulegridCB = SVMX.create("com.servicemax.client.pmplan.ui.desktop.conditionRule.ConditionRuleGridCriteria", {
                    __fieldStore: fieldListStoreCB
                });
                this.add(this.__conditionRulegridCB);

                var advancedExpression = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    id: 'advExp',
                    name: 'advExp',
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T('TAG030', 'Advanced Expression'),
                    labelSeparator: '',
                    margin: '0 15 10 15',
                    width: 'calc(100% - 30px)',
                });

                me.add(advancedExpression);

                var messageLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: '<span>'+ PMPLAN.T("TAG065", 'If you have defined new conditions or changed existing ones, please click "Run schedule" to regenerate schedules for the updated conditions.') + '</span>',
                    margin: '0 15 0',
                });
                me.add(messageLabel);

                var scheduleSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'hbox',
                    collapsible: false,
                    border: false,
                    header: false,
                    id: 'scheduleSec',
                    cls: 'img-header-default',
                });


                var schedulOPLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: '<span>'+ PMPLAN.T('TAG066', 'Scheduled Output:') +'</span>',
                    //style: 'position: relative; top: 10px; margin: 10px 10px 0px 12px',
                    //padding: '5 5 5 4',
                    cls: 'pmplan-grid-title'
                });

                var rerunScheduleLink = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton",{
                    text: PMPLAN.T('TAG067', 'Run Schedule'),
                    cls: 'pmplan-schedule-link',
                    disabled: true,
                    id: 'scheduleLink',
                    style: 'top: 14px !important',
                    handler: function(e, target){
                       
                        var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');

                        var getScheduleReq = {};
                        getScheduleReq.conditionRuleList = []; 
                        getScheduleReq.coverageId = Ext.getCmp('conditionrule').__covergaeId;
                        getScheduleReq.runScheduleCoverageId = Ext.getCmp('conditionrule').__runScheduleCoverageId; //This is added for fixing defect BAC-2849
                        var coverages = []; 

                        // To Do: Identify  the Strat nad End date and convert it before recalculation schedule.
                        /*Ext.getStore('condition_rule_store').data.items.forEach(function(item,j){
                            getScheduleReq.conditionRuleList.push(item.data);
                        });*/

                        getScheduleReq.conditionRuleList = me.validateConditionRule(); 

                        getScheduleReq.pmPlanRecord = {};

                        getScheduleReq.pmPlanRecord.conditionType = Ext.getCmp('conditionTypeCombo').getValue();

                        var startDateVal = Ext.getCmp('startDate').getValue();
                        var endDateVal = Ext.getCmp('endDate').getValue(); 

                        var conditionRuleModal = Ext.getCmp('conditionrule');

                        if(startDateVal != null){
                            getScheduleReq.pmPlanRecord.startDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('startDate').getValue(), userInfo.TimezoneOffset, false);
                        }

                        if(endDateVal != null){
                            getScheduleReq.pmPlanRecord.endDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('endDate').getValue(), userInfo.TimezoneOffset, false);
                        }
                        getScheduleReq.advancedExpression = Ext.getCmp('advExp').getValue(); 

                        if(getScheduleReq.conditionRuleList != null && getScheduleReq.conditionRuleList.length > 0 && (getScheduleReq.advancedExpression == '' || getScheduleReq.advancedExpression == null)){
                            getScheduleReq.advancedExpression = me.__parent.advancedExp(getScheduleReq.conditionRuleList.length);
                        }

                        getScheduleReq.workOrderPurposeId = Ext.getCmp('WOPurpose').getValue();
                        getScheduleReq.pmPlanRecord.pmTemplateDetail = {};
                        getScheduleReq.pmPlanRecord.pmTemplateDetail.conditionRuleList = getScheduleReq.conditionRuleList;

                        //populate field label for selected field API name in the condition rules
                        if(getScheduleReq.pmPlanRecord.conditionType === 'Criteria_Comparison' && getScheduleReq.conditionRuleList != null && getScheduleReq.conditionRuleList.length > 0){
                            var fieldListStoreCB = Ext.data.StoreManager.lookup('Field_List_Store_CB');
                            for(var i =0 ; i<getScheduleReq.conditionRuleList.length; i++){
                                var selectedFieldValue = getScheduleReq.conditionRuleList[i].selectedField;
                                var recFromStore = fieldListStoreCB.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                                var selectedFieldLabel = recFromStore.getData().fieldLabel;
                                getScheduleReq.conditionRuleList[i].selectedFieldLabel = selectedFieldLabel;
                            }
                        }

                        if(getScheduleReq.conditionRuleList != null && getScheduleReq.conditionRuleList != ''){
                            var expressionValidationReq = {};
                            expressionValidationReq.conditionRuleList = getScheduleReq.conditionRuleList; 
                            expressionValidationReq.advancedExpression = getScheduleReq.advancedExpression 
                            me.__engine.validateExpression(expressionValidationReq, function(result){
                                if(result.success){
                                    conditionRuleModal.__engine.getCoverageScheduleData(getScheduleReq, function(result){
                                        if(result.success){
                                            var scheduleStoreData = result.scheduleList;
                                            var scheduleOPStore = Ext.getStore('schedule_op_store');
                                            scheduleOPStore.loadData(scheduleStoreData);
                                            Ext.getCmp('advExp').setValue(expressionValidationReq.advancedExpression);
                                            
                                        }
                                        else{
                                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                        }
                                    }) ; 
                                }
                                else{
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                }
                            });
                        }

                           
                    }
                });

                scheduleSec.add(schedulOPLabel);
                scheduleSec.add(rerunScheduleLink);

                me.add(scheduleSec);
                

                // Need to update Work Order Purpose List
                this.__scheduleGrid = SVMX.create("com.servicemax.client.pmplan.ui.desktop.conditionRule.ScheduleGrid", {
                });
                me.add(this.__scheduleGrid);


                var conditionRuleActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    style : 'margin-top: 20px', 
                    border: false,
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                conditionRuleActions.add(tabFill3);

                var cancelConditionRuleBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: PMPLAN.T("TAG022", 'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    cls: 'pmplan-cancel-btn',
                    handler: function() {
                        me.cancelAction();
                    }
                });

                var saveConditionRuleBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: PMPLAN.T("TAG023", 'Save'), //Icon Class for lookup button,
                    scale: 'medium',
                    margin: '0 10 0 10',
                    height: 30, 
                    id: 'saveConditionRuleBtn',
                    cls: 'pmplan-save-btn',
                    handler: function(button, e) {

                        
                        var conditionRuleList = me.validateConditionRule(); 
                         
                        var scheduleGridStore = me.__scheduleGrid.getStore().data.items;

                        var covergaeGridCmp = Ext.getCmp('coverageGrid');

                        var updatedSchRec = [];

                        scheduleGridStore.forEach(function(value,index){
                           updatedSchRec.push(value.data);
                        })

                        
                        // After validating condition Grid, validate expression; 
                        if(conditionRuleList != null && conditionRuleList != ''){
                            var expressionValidationReq = {};
                            expressionValidationReq.conditionRuleList = conditionRuleList; 
                            expressionValidationReq.advancedExpression = Ext.getCmp('advExp').getValue(); 

                            if(expressionValidationReq.advancedExpression == '' || expressionValidationReq.advancedExpression == null){
                                expressionValidationReq.advancedExpression = me.__parent.advancedExp(conditionRuleList.length);
                            }

                            me.__engine.validateExpression(expressionValidationReq, function(result){
                                if(result.success){
                                    if(updatedSchRec && updatedSchRec.length === 0){ //Added condition to fix issue BAC-4631
                                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG081", 'No PM Schedules have been generated for this coverage. This may be due to an issue with the Condition Rules. Please Review.'), 7000, 'success');
                                    }
                                    else{
                                        covergaeGridCmp.getStore().data.items[me.__recordIndex].data.conditionRuleList =  conditionRuleList
                           
                                        covergaeGridCmp.getStore().data.items[me.__recordIndex].data.scheduleList = updatedSchRec; 
                                        covergaeGridCmp.getStore().data.items[me.__recordIndex].data.advancedExpression = expressionValidationReq.advancedExpression; 

                                        if(conditionRuleList != null && conditionRuleList != '' && conditionRuleList.length > 0){
                                            var classAttr = covergaeGridCmp.getNode(me.__recordIndex).childNodes[0].getAttribute('class');
                                            if(classAttr.indexOf('make-cell-dirty-lt') != -1){
                                                covergaeGridCmp.getNode(me.__recordIndex).childNodes[0].setAttribute('class', classAttr.replace('make-cell-dirty-lt','').trim());
                                                covergaeGridCmp.getNode(me.__recordIndex).childNodes[0].removeAttribute('data-errorqtip');
                                            }
                                        }

                                        var conditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                                        me.__parent.__changeevent = true;
                                        if(conditionTypeValue === 'Usage_Frequency'){
                                            me.__conditionRulegrid.getStore().removeAll();
                                            Ext.getCmp('addRowButton').setDisabled(false);
                                        }
                                        else if(conditionTypeValue === 'Criteria_Comparison'){
                                            me.__conditionRulegridCB.getStore().removeAll();
                                            Ext.getCmp('addRowButton_CB').setDisabled(false);
                                        }
                                        Ext.getCmp('scheduleLink').setDisabled(true);
                                        Ext.getCmp('conditionTypeCombo').setReadOnly(true);
                                        me.hide();
                                        me.__parent.enable();
                                    }
                                }
                                else{
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                }
                            });
                        }
                        else{
                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG072", 'Add conditions to save the coverage.'), 7000, 'success');
                        }
                    }
                });

                conditionRuleActions.add(cancelConditionRuleBtn);
                conditionRuleActions.add(saveConditionRuleBtn);

                me.add(conditionRuleActions);
            },

            loadStore: function(conditionStoreData, scheduleStoreData, advancedExpression, fieldList) {
                // load condition grid. 

                // Load the field values with IB physical fields & technical attribute 
                // First consider values from template (if present), else load the fields from pmplan 
                this.__conditionRuleGridOldVal = conditionStoreData;
                var fieldListOfBoth = fieldList;
                var listOfStoreRecords = [];
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
                    }
                }

                var conditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                var conditionStore;
                if(conditionTypeValue === '' || conditionTypeValue === 'Usage_Frequency'){
                    var fieldListStore = Ext.getStore('field_list_store');
                    conditionStore = Ext.getStore('condition_rule_store');
                    if(conditionStoreData != null && conditionStoreData.length > 0){
                        var conditionRuleList = conditionStoreData;
                        var conditionRuleListSize = conditionRuleList.length;
                        for(var i=0; i<conditionRuleList.length; i++){
                            var fieldValue;
                            var selectedFreqUnitValue = conditionRuleList[i].selectedFreqUnit;
                            var selectedFieldValue = conditionRuleList[i].selectedField;
                            if(selectedFreqUnitValue === 'Count'){
                                fieldValue = selectedFieldValue;
                            }
                            else{
                                fieldValue = selectedFreqUnitValue;
                            }

                            // overwrite the selected field
                            conditionRuleList[i].selectedField = fieldValue; 
                            if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years'){
                                if(conditionRuleList[i].startAt !== null && conditionRuleList[i].startAt !== ''){
                                    var splitDate = conditionRuleList[i].startAt.split('-');
                                    conditionRuleList[i].startAt = new Date(splitDate[0], parseInt(splitDate[1])-1, splitDate[2]);
                                }
                                if(conditionRuleList[i].stopAt !== null && conditionRuleList[i].stopAt !== ''){
                                    splitDate = conditionRuleList[i].stopAt.split('-');
                                    conditionRuleList[i].stopAt = new Date(splitDate[0], parseInt(splitDate[1])-1, splitDate[2]);
                                }
                            }
                            conditionRuleList[i].isRowHasError = false;
                        }

                        if(conditionRuleListSize >= 5){
                            Ext.getCmp('addRowButton').setDisabled(true);
                        }
                    }
                    fieldListStore.loadData(listOfStoreRecords);
                    this.__conditionRulegrid.setVisible(true);
                    this.__conditionRulegridCB.setVisible(false);
                    Ext.getCmp('scheduleOPGrid').columns[3].setVisible(true);
                }
                else if(conditionTypeValue === 'Criteria_Comparison'){
                    conditionStore = Ext.getStore('Condition_Rule_Store_CB');
                    var conditionRuleListSize = conditionStoreData.length;
                    for(var i=0; i<conditionRuleListSize; i++){
                        conditionStoreData[i].isRowHasError = false;
                    }

                    if(conditionRuleListSize >= 5){
                        Ext.getCmp('addRowButton_CB').setDisabled(true);
                    }

                    this.__conditionRulegrid.setVisible(false);
                    this.__conditionRulegridCB.setVisible(true);
                    Ext.getCmp('scheduleOPGrid').columns[3].setVisible(false);
                }
                conditionStore.loadData(conditionStoreData);

                if(conditionStoreData.length > 0){
                    Ext.getCmp('scheduleLink').setDisabled( false );
                }

                // Load Schedule Grid
                var scheduleOPStore = Ext.getStore('schedule_op_store');
                scheduleOPStore.loadData(scheduleStoreData);

                var woPurStore = Ext.getStore('workOrderPurposeStore');
                woPurStore.loadData(this.__engine.__pmplanData.pmPlanRecord.woPurposeList);

                // Load Schedule Grid
                var advExpText = Ext.getCmp('advExp');
                advExpText.setValue(advancedExpression);

            },

            loadAttributeStoreForCriteria: function(fieldList){
                var fieldListOfBoth = fieldList;
                var listOfPicklistValues = [];
                var listOfStoreRecords = [];
                for(var i=0; i<fieldListOfBoth.length; i++){
                    var category = fieldListOfBoth[i].key;
                    var listOfFields = fieldListOfBoth[i].lstOfKeyValue;
                    for(var j=0; j<listOfFields.length; j++){
                        var record = {
                            'fieldApiName': listOfFields[j].key,
                            'fieldLabel': listOfFields[j].value,
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
                Ext.getStore('Field_List_Store_CB').loadData(listOfStoreRecords);
                Ext.getStore('TA_PA_Store').loadData(listOfPicklistValues);
            },

            validateConditionRule: function(){
                // In this we will store condition rule & schedule to Covergae.
                // Perform Validation on Field Store
                var isGridHasErrors = false;
                var isProductChanged = false;
                var isRequiredFieldValueMissing = false;
                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');
                var listOfRule = [];
                var coniditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                if(coniditionTypeValue === 'Usage_Frequency'){
                    var ruleData = this.__conditionRulegrid.getStore().data.items;
                    var fieldListStore = Ext.getStore('field_list_store');  
                    for(var i=0; i<ruleData.length; i++){
                        if(!isGridHasErrors){
                            if(ruleData[i].data.isRowHasError === true || ruleData[i].data.isRowHasError === ''){
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
                    }
                    if(isProductChanged){
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG031", "There is a mismatch between the product and attribute chosen. Please choose the correct attribute and save."), 7000, 'success');
                        return;
                    }
                    else if(isRequiredFieldValueMissing){
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG032", "Please fill the values for the following columns in Condition Rule list: Field, Operator and Frequency"), 7000, 'success');
                        return;
                    }
                    else if(isGridHasErrors){
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG033", "One or more conditions is invalid. Please review the conditions and save"), 7000, 'success');
                        return;
                    }

                    // Update the Condition grid & schedule records
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
                }
                else if(coniditionTypeValue === 'Criteria_Comparison'){
                    var ruleData = this.__conditionRulegridCB.getStore().data.items;
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
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG031", "There is a mismatch between the product and attribute chosen. Please choose the correct attribute and save."), 7000, 'success');
                        return;
                    }
                    else if(isRequiredFieldValueMissing){
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG076", "Please fill values for the following columns in Condition Rule : Attribute, Operator and Value"), 7000, 'success');
                        return;
                    }

                    for(var i=0; i<ruleData.length; i++){
                        var objRule = JSON.parse(JSON.stringify(ruleData[i].data));
                        var selectedFieldValue = ruleData[i].data.selectedField;
                        var recFromStore = fieldListStoreCB.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                        objRule.selectedField = selectedFieldValue;
                        objRule.fieldAttType = recFromStore.getData().attributeType;
                        objRule.fieldDataType = recFromStore.getData().dataType;

                        if(objRule.fieldDataType === 'DATE'){
                            if(ruleData[i].data.value != null && ruleData[i].data.value != ''){
                                objRule.value = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].data.value, userInfo.TimezoneOffset, false).substring(0,10);
                            }
                        }
                        listOfRule.push(objRule);
                    }
                }
                return listOfRule;
            },
            cancelAction: function(){
                var ruleData = this.__conditionRuleGridOldVal;
                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');
                var coniditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();

                if(coniditionTypeValue === 'Usage_Frequency'){
                    // On cancel, it is taking the Convert Date format. We need to store it back as normal date
                    for(var i=0; i<ruleData.length; i++){
                        if(ruleData[i].selectedFreqUnit != 'Count'){
                            if(ruleData[i].startAt != null && ruleData[i].startAt != ''){
                               ruleData[i].startAt = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].startAt, userInfo.TimezoneOffset, false).substring(0,10);
                            }
                            if(ruleData[i].stopAt != null && ruleData[i].stopAt != ''){
                                ruleData[i].stopAt = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].stopAt, userInfo.TimezoneOffset, false).substring(0,10);
                            }
                        }
                    }
                    this.__conditionRulegrid.getStore().removeAll();
                    Ext.getCmp('addRowButton').setDisabled(false);
                }
                else if(coniditionTypeValue === 'Criteria_Comparison'){
                    var fieldListStoreCB = Ext.data.StoreManager.lookup('Field_List_Store_CB');
                    for(var i=0; i<ruleData.length; i++){
                        var selectedFieldValue = ruleData[i].selectedField;
                        var recFromStore = fieldListStoreCB.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                        var fieldDataType = recFromStore.getData().dataType;
                        if(fieldDataType === 'DATE'){
                            if(ruleData[i].value != null && ruleData[i].value != ''){
                               ruleData[i].value = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(ruleData[i].value, userInfo.TimezoneOffset, false).substring(0,10);
                            }
                        }
                    }
                    this.__conditionRulegridCB.getStore().removeAll(); 
                    Ext.getCmp('addRowButton_CB').setDisabled(false); 
                }
                
                var covergaeGridCmp = Ext.getCmp('coverageGrid');
                if(covergaeGridCmp.getStore().data.items[this.__recordIndex].data.conditionRuleList != null && covergaeGridCmp.getStore().data.items[this.__recordIndex].data.conditionRuleList.length >0){
                    covergaeGridCmp.getStore().data.items[this.__recordIndex].data.conditionRuleList = ruleData;
                }
                else{
                    covergaeGridCmp.getStore().data.items[this.__recordIndex].data.conditionRuleList = null;
                }
                
                Ext.getCmp('scheduleLink').setDisabled(true);   
                this.hide();
                this.__parent.enable();
            }
        });

        Ext.define('com.servicemax.client.pmplan.ui.desktop.conditionRule.GroupComboBox', {
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

        Ext.define('com.servicemax.client.pmplan.ui.desktop.conditionRule.ConditionRuleGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            __fieldStore: null,
            __rowData: null,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {
                this.fieldCombo = new SVMX.create("com.servicemax.client.pmplan.ui.desktop.conditionRule.GroupComboBox",{
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
                            "label":PMPLAN.T("TAG034", "Every"), 
                            "value":"EYI",
                            "type": "Date"
                        },
                        {
                            "label": PMPLAN.T("TAG035", "Every decrement"), 
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
                    valueField: 'value',
                    editable: false,
                    store: initialOperatorStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
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
                    }
                });
        
                this.adjustmentTypeCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    editable: false,
                    queryMode: 'local',
                    store: [
                        ['None',PMPLAN.T("COMM_TAG004", "--None--")],
                        ['Actual',PMPLAN.T("TAG036", "Actual")],
                        ['Fixed',PMPLAN.T("TAG037", "Fixed")]
                    ],
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                var initialAdjustmentUnitStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":PMPLAN.T("TAG038", "Days"), 
                            "value":"Days",
                            "type": "Date"
                        },
                        {
                            "label":PMPLAN.T("TAG039", "Count"), 
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
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
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

                            //Setting required field error message column 8 when operator is Every
                            if(e.record.data.selectedOperator == 'EYI' && (e.record.data.stopAt === '' || e.record.data.stopAt === null)){
                                var editedCell = e.row.childNodes[7]; //Stop At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG040", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 6 when operator is Every decrement
                            if(e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt === '' || e.record.data.startAt === null)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG040", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 11 when Adjustment type: Change from Actual to Fixed
                            if(e.record.data.selectedAdjustmentType === 'Fixed' && (e.record.data.adjustmentVal === '' || e.record.data.adjustmentVal === null)){
                                var editedCell = e.row.childNodes[11]; //Adjustment value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG040", "This is a required field."));
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
                                        editedCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG041", "Stop At cannot be less than Start At."));
                                    }
                                }
                            }

                            //Setting error message for column 5 when stopAt greater than startAt and Unit is Count
                            if((e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Years') && e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt !== '' && e.record.data.startAt !== null) && (e.record.data.stopAt !== '' && e.record.data.stopAt !== null) && parseFloat(e.record.data.stopAt) > parseFloat(e.record.data.startAt)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG041", "Start At cannot be less than Stop At."));
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
                            var editedCellSixth = e.row.childNodes[5]; //Start At column
                            var classAttrSixth = editedCellSixth.firstChild.getAttribute('class');
                            if(classAttrSixth.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellSixth;
                                editedClassAttr = classAttrSixth;
                            }
                            var editedCellEighth = e.row.childNodes[7]; //Stop At column
                            var classAttrEighth = editedCellEighth.firstChild.getAttribute('class');
                            if(classAttrEighth.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellEighth;
                                editedClassAttr = classAttrEighth;
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
                                    firstColumnCell.firstChild.setAttribute('data-qtip', PMPLAN.T("TAG042", "This row has one or more issues. Please correct before proceeding"));
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
                    return ((rec === null || rec === undefined) ? '' : rec.get(combo.displayField) );
                  };
                }
                
                Ext.apply(this, {
                    width: '60%',
                    autoScroll: true, maxHeight:450,
                    id:'conditionRuleGrid', 
                    //cls: 'pmplan-root-container',
                    margin: '10 10 30',
                    plugins: [this.cellEditing],
                    store: new Ext.data.Store({
                        storeId: 'condition_rule_store',
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
                            'selectedAdjustedUnit',
                            'fieldAttType',
                            'fieldDataType',
                            'selectedFreqUnit',
                        ]
                    }),
                    columns: [{
                        xtype: 'actioncolumn',
                        width: 40,
                        height: 40,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        items: [{
                            iconCls: 'pmplan-delete-row-icon',
                            tooltip: PMPLAN.T("TAG043", "Delete"),
                            scope: this,
                            height: 40,
                            handler: this.onRemoveClick
                        }]
                    }, {
                        header: PMPLAN.T("TAG044", "Sequence"),
                        dataIndex: 'sequence',
                        width: 80,
                        height: 40,
                        align: 'center'
                    }, {
                        header: PMPLAN.T("TAG045", "Field"),
                        dataIndex: 'selectedField',
                        width: 150,
                        height: 40,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: PMPLAN.T("TAG046", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 120,
                        height: 40,
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
                        header: PMPLAN.T("TAG047", "Frequency"),
                        dataIndex: 'frequency', 
                        width: 100,
                        height: 40,
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
                                            nanText: PMPLAN.T("TAG080", "Enter a valid number"),
                                        })
                                    });
                                }
                                else{
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 0.1,
                                            enableKeyEvents: true,
                                            nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG048", "Start At"),
                        dataIndex: 'startAt',
                        width: 120,
                        height: 40,
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
                                    invalidText: PMPLAN.T("TAG079", "Enter a valid date")
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG049", "Threshold %"),
                        dataIndex: 'threshold',
                        width: 100,
                        height: 40,
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
                                    })
                                });
                            }
                        }
                    }, {
                        header: PMPLAN.T("TAG050", "Stop At"),
                        dataIndex: 'stopAt',
                        width: 120,
                        height: 40,
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
                                    invalidText: PMPLAN.T("TAG079", "Enter a valid date")
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG051", "Adjustment Type"),
                        dataIndex: 'selectedAdjustmentType',
                        width: 110,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.adjustmentTypeCombo,
                        renderer: this.comboBoxRenderer(this.adjustmentTypeCombo)
                    }, {
                        header: PMPLAN.T("TAG052", "Minimum Adjustment"),
                        dataIndex: 'minAdjustment',
                        width: 120,
                        height: 40,
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG053", "Maximum Adjustment"),
                        dataIndex: 'maxAdjustment',
                        width: 120,
                        height: 40,
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG054", "Adjustment Value"),
                        dataIndex: 'adjustmentVal',
                        width: 120,
                        height: 40,
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
                                        nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        header: PMPLAN.T("TAG055", "Adjustment Unit"),
                        dataIndex: 'selectedAdjustedUnit',
                        width: 120,
                        height: 40,
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
                        text: '+ ' + PMPLAN.T("TAG056", "Add Row"),
                        id: 'addRowButton',
                        scope: this,
                        handler: this.onAddClick,
                        cls: 'pmplan-blue-link'
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

                if(this.getStore().getCount() > 0){
                    Ext.getCmp('scheduleLink').setDisabled( false );
                }
                else{
                    Ext.getCmp('scheduleLink').setDisabled( true );
                }
                
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

                if(this.getStore().getCount() > 0){
                    Ext.getCmp('scheduleLink').setDisabled( false );
                }
                else{
                    Ext.getCmp('scheduleLink').setDisabled( true );
                }
                
            }
        })

        Ext.define('com.servicemax.client.pmplan.ui.desktop.conditionRule.ScheduleGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            emptyText: PMPLAN.T("TAG057", 'No Schedules to display'),
            frame: true,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                });

                var workOrderPurposeStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    id: 'workOrderPurposeStore',
                    proxy: {
                        type: "memory"
                    }
                });

                this.workOrderPuproseTemplate = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: workOrderPurposeStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                this.picklistRenderer = function(combo) {
                  return function(value) {
                    var idx = combo.store.find(combo.valueField, value);
                    var rec = combo.store.getAt(idx);
                    return ((rec === null || rec === undefined) ? '' : Ext.String.htmlEncode(rec.get(combo.displayField)));
                  };
                }

                
                Ext.apply(this, {
                    width: '60%',
                    autoScroll: true,
                    margin: '0 10 30 10',
                    plugins: [this.cellEditing],
                    id:'scheduleOPGrid', 
                    cls: 'pmplan-schedule-grid',
                    emptyText: PMPLAN.T("TAG057", 'No Schedules to display'),
                    viewConfig: { 
                        deferEmptyText: false,
                    },
                    store: new Ext.data.Store({
                        storeId: 'schedule_op_store',
                        fields: [
                            'internalExpression', 
                            'scheduleId',
                            'scheduleName',
                            'selectedWOPurpose',
                            'sequence',
                            'status',
                            'statusLabel',
                            'actualOpName',
                            'advancedExpression',
                            'actualOpExpression'
                        ],
                        data : [],
                        sorters:
                        {
                            field: 'sequence',
                            direction: 'ASC'
                        }
                    }),
                    columns: [
                        { flex: 1, text: PMPLAN.T("TAG058", 'Sequence'), dataIndex: 'sequence', align: 'left', resizable: true, readOnly: true, hidden: true},  
                        { 
                            flex: 1,
                            text: PMPLAN.T("TAG059", 'PM Schedule Output'), 
                            dataIndex: 'scheduleName', 
                            align: 'left', 
                            resizable: true, 
                            readOnly: true,
                            renderer: function(value, metadata) {
                                metadata.style = 'white-space: normal;';
                                return Ext.String.htmlEncode(value);
                            }
                        },   
                        { flex: 1, text: PMPLAN.T("TAG060", 'Status'), dataIndex: 'statusLabel', align: 'left', resizable: true, readOnly: true ,renderer: function(value) {
                                return Ext.String.htmlEncode(value);
                            }}, 
                        { flex: 1, text: PMPLAN.T("TAG061", 'Actual Output'), dataIndex: 'actualOpName', align: 'left', resizable: true, readOnly: true, renderer: function(value) {
                                return Ext.String.htmlEncode(value);
                            }},  
                        { flex: 1, text: PMPLAN.T("TAG062", 'Work Order Purpose'), dataIndex: 'selectedWOPurpose', align: 'left', resizable: true, readOnly: true, editor: this.workOrderPuproseTemplate, renderer: this.picklistRenderer(this.workOrderPuproseTemplate)}, 
                    ],
                    selModel: {
                        selType: 'cellmodel'
                    },
                });
                
                this.callParent();
                
            },
            
        });

        Ext.define('com.servicemax.client.pmplan.ui.desktop.conditionRule.ConditionRuleGridCriteria', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            __fieldStore: null,
            __rowData: null,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {
                this.fieldCombo = new SVMX.create("com.servicemax.client.pmplan.ui.desktop.conditionRule.GroupComboBox",{
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
                            "label":PMPLAN.T("COMM_TAG006", "Equals"), 
                            "value":"eq",
                            "type": "TEXT_PICKLIST"
                        },
                        {
                            "label":PMPLAN.T("COMM_TAG008", "Greater Than"), 
                            "value":"gt",
                            "type": ""
                        },
                        {
                            "label":PMPLAN.T("COMM_TAG010", "Less Than"), 
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
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
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
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                combo.store.filter('fieldApiName',selectedFieldValue);
                            }
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
                    width: '60%',
                    autoScroll: true, maxHeight:450,
                    id:'conditionRuleGridCB',
                    margin: '10 10 30',
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
                            iconCls: 'pmplan-delete-row-icon',
                            tooltip: PMPLAN.T("TAG043", "Delete"),
                            scope: this,
                            handler: this.onRemoveClick
                        }]
                    }, {
                        header: PMPLAN.T("TAG044", "Sequence"),
                        dataIndex: 'sequence',
                        width: 70,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center'
                    }, {
                        header: PMPLAN.T("TAG075", "Attribute"),
                        dataIndex: 'selectedField',
                        width: 270,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: PMPLAN.T("TAG046", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 180,
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
                        header: PMPLAN.T("TAG073", "Value"),
                        dataIndex: 'value',
                        width: 400,
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
                                        invalidText: PMPLAN.T("TAG079", "Enter a valid date"),
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
                                            nanText: PMPLAN.T("TAG080", "Enter a valid number"),
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
                        text: '+ ' + PMPLAN.T("TAG056", "Add row"),
                        id: 'addRowButton_CB',
                        scope: this,
                        handler: this.onAddClick,
                        cls: 'pmplan-blue-link'
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

                if(this.getStore().getCount() > 0){
                    Ext.getCmp('scheduleLink').setDisabled( false );
                }
                else{
                    Ext.getCmp('scheduleLink').setDisabled( true );
                }
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

                if(this.getStore().getCount() > 0){
                    Ext.getCmp('scheduleLink').setDisabled( false );
                }
                else{
                    Ext.getCmp('scheduleLink').setDisabled( true );
                }
            }
        })
    }
})();
