(function () {

    var appImpl = SVMX.Package("com.servicemax.client.pmplan.ui.desktop.api");

    appImpl.init = function () {

        var PMPLAN = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplan.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'pmplan-root-container', // ToDo : Talk to Jessie to create the class
            width: '100%',
            id:'pmplan',
            constructor: function (config) {
                config = Ext.apply({
                    title: PMPLAN.T('TAG001', 'Preventive Maintenance Plan'), 
                    titleAlign: 'center', collapsible: false, 
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            //iconCls : "svmx-spm-back-icon", 
                            padding: '0', //scale: "medium",
                            text : SVMX.getUrlParameter('mode').toLowerCase()== 'sc'? PMPLAN.T("TAG002", 'Back to Service Contract'): (SVMX.getUrlParameter('mode').toLowerCase()== 'account'? PMPLAN.T("TAG068", 'Back to Account'): (SVMX.getUrlParameter('mode').toLowerCase()== 'location'?PMPLAN.T("TAG069", 'Back to Location'): PMPLAN.T("TAG070", 'Back to Installed Product'))),  
                            hidden: SVMX.getUrlParameter('pmPlanId') != null ? true:false,         
                            handler: function(e, el, owner, tool) {
                                var returnlocation = '';
                                if(SVMX.getUrlParameter('sourceId') != null){
                                    returnlocation = '/'+SVMX.getUrlParameter('sourceId');
                                } 
                                else{
                                    returnlocation = '/'+SVMX.getUrlParameter('pmPlanId');
                                }
                                if((typeof sforce != 'undefined') && (sforce != null)){
                                    sforce.one.navigateToURL(returnlocation);
                                }
                                else{
                                    window.location = returnlocation;
                                }
                                //window.location = '/'+returnlocation;
                            }
                        }]
                    },
                }, config || {});

                this.callParent(arguments);
            },
            initComponent: function() {

                this.callParent(arguments);

                var me = this; 

                var pmPlanDetails = me.__engine.__pmplanData.pmPlanRecord;

                // Load condition rule screen

                me.conditionrulePanel = SVMX.create("com.servicemax.client.pmplan.ui.desktop.api.ConditionrulePanel", {
                    __parent: me, __engine: me.__engine, border: false, collapsible:false, hidden:true, 
                });

                var planName = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    id: 'planName',
                    name: 'planName',
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T('TAG003', 'Plan Name'),
                    value: pmPlanDetails.pmPlanName,
                    labelSeparator: '',
                    allowBlank: false,
                    msgTarget : 'under',
                    style: 'top: 10px;',
                });

                me.planTemplateStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getPMTemplatelist()
                });

                // Write an onchange event to populate the Work Order Purpose and Activity Date
                var planTemplate = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'planTemplateName', name: 'planTemplateName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG004",'Plan Template'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name',
                    //value: pmPlanDetails.pmPlanTemplateId,
                    queryMode: 'local', store:  me.planTemplateStore ,
                    labelSeparator: '',
                    margins: '0 0 0 6',
                    editable: false,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners: {
                        beforeselect: function( combo, record, eOpts ){
                            //selectedPmPlanTemplateId = records.getData().Id;
                            var oldValue = this.getValue();
                            var newValue = record.getData().Id;
                            if(me.covergaeStore.data.length == 0){
                                if(newValue != 'NONE'){
                                    me.createPMTemplateReq(newValue);
                                }
                                else{
                                    me.createPMTemplateReq(null);
                                    Ext.getCmp('conditionTypeCombo').setReadOnly(false);
                                }
                            }
                            else if(newValue !== 'NONE' && me.covergaeStore.data.length != 0){
                                if(!(me.__engine.__mode.toLowerCase() == 'ib')){
                                    Ext.MessageBox.confirm('Confirm', PMPLAN.T("TAG027",'This operation will remove all coverages and schedules. Do you want to continue?') , function(btn){
                                        if(btn == 'yes'){
                                            if(record != null){
                                               me.createPMTemplateReq(newValue);
                                            }
                                            me.covergaeStore.removeAll();
                                        }
                                        else{
                                            combo.setValue(oldValue);
                                            Ext.getCmp('conditionTypeCombo').setReadOnly(true);
                                        }
                                    });
                                }
                                else{
                                    me.createPMTemplateReq(newValue);
                                }
                            }
                            else if(newValue === 'NONE' && me.covergaeStore.data.length != 0){
                                Ext.getCmp('conditionTypeCombo').setReadOnly(false);
                                if(!(me.__engine.__mode.toLowerCase() == 'ib')){
                                    Ext.MessageBox.confirm('Confirm', PMPLAN.T("TAG027",'This operation will remove all coverages and schedules. Do you want to continue?') , function(btn){
                                        if(btn == 'yes'){
                                            //Commented as part of defect fix BAC-2720
                                            /*if(record != null){
                                               me.createPMTemplateReq(null);
                                            }*/
                                            me.covergaeStore.removeAll();
                                            me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail = {};
                                        }
                                        else{
                                            combo.setValue(oldValue);
                                            Ext.getCmp('conditionTypeCombo').setReadOnly(true);
                                        }
                                    });
                                }
                                else{
                                    me.createPMTemplateReq(null);
                                }
                            }
                        },
                        afterrender: function(combo) {
                            if(pmPlanDetails.pmPlanTemplateId != null){
                                combo.setValue(pmPlanDetails.pmPlanTemplateId);
                            }
                            else{
                                combo.setValue('NONE');
                            }
                            
                        }
                    },
                    style: 'top: 10px;',
                });

                var serviceContractSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'column',
                    defaults: {
                          columnWidth: 0.5
                    },
                    collapsible: false,
                    border: false,
                    header: false,
                    hidden: (me.__engine.__mode).toLowerCase() == 'account' || (me.__engine.__mode).toLowerCase() == 'location',
                    cls: 'img-header-default',
                });

                me.serviceContractStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getServiceContract()
                });

                var serviceContract = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'serviceContractName', name: 'serviceContractName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG005",'Service/Maintenance Contract'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name', 
                    value: pmPlanDetails.serviceContractId,
                    labelSeparator: '',
                    columnWidth: 0.95,
                    queryMode: 'local', store: me.serviceContractStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners:{
                        select: function( combo, records, eOpts ){
                            if(Ext.getCmp('planTemplateName').getValue() != 'NONE'){
                                me.createPMTemplateReq(Ext.getCmp('planTemplateName').getValue());
                            }
                        }
                    }
                    
                });
                serviceContractSec.add(serviceContract);

                serviceContractSec.add({
                    iconCls : 'svmx-filter-icon',
                    cursor:'pointer', 
                    scale : 'medium', 
                    border: false,
                    columnWidth: 0.05,
                    style: 'top: 20px',
                    cls: 'img-header-default',
                    listeners: {
                        el: {
                            click: function() {
                                var scSearchText = Ext.getCmp('serviceContractName');
                                var searchRequest ={};
                                searchRequest.objAPIName = SVMX.OrgNamespace+'__Service_Contract__c';
                                searchRequest.searchtext = scSearchText.getRawValue();

                                if(searchRequest.searchtext.length < 3){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG025",'You must enter more than 3 characters to perform search'), 7000, 'success');
                                }
                                else{
                                    var pmplanComponent = Ext.getCmp('pmplan');
                                    pmplanComponent.__engine.searchObject(searchRequest, function(result){
                                        if(result.success){
                                            if(result.searchResponse.length > 0){
                                                me.loadData(result);
                                            }
                                            else{
                                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG024",'No matches found. Refine your search. ') , 7000, 'success');
                                            }
                                        }
                                        else{
                                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                        }
                                    });
                                }
                            }
                        }
                    },
                });


                var coverageTypeStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'key'}, {name: 'value'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getCoverageType()
                });

                var coverageType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'coverageTypeName', name: 'coverageTypeName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG006",'Coverage Type'),
                    labelField:'label', valueField:'value', 
                    displayField: 'key', defaultValue: 1,
                    readOnly: true,
                    value: 'Product (Must Have IB)',
                    labelSeparator: '',
                    queryMode: 'local', store: coverageTypeStore,
                    style: 'top: 10px;',
                });


                var scheduleTypeStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'key'}, {name: 'value'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getScheduleType()
                });

                var scheduleType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'scheduleTypeName', name: 'coverageTypeName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG007",'Schedule Type'),
                    labelField:'label', valueField:'value', 
                    displayField: 'key', defaultValue: 1,
                    readOnly: true,
                    value: 'Condition Based',
                    labelSeparator: '',
                    queryMode: 'local', store: scheduleTypeStore,
                    style: 'top: 10px;',
                });



                var accountSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'column',
                    defaults: {
                          columnWidth: 0.5
                    },
                    collapsible: false,
                    border: false,
                    hidden: (me.__engine.__mode).toLowerCase() == 'location',
                    header: false
                });

                me.accountStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getAccount()
                });


                var account = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'accountName', name: 'accountName',
                    labelAlign: 'top', 
                    fieldLabel: PMPLAN.T("TAG008",'Account'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name',
                    value: pmPlanDetails.accountId,
                    labelSeparator: '',
                    queryMode: 'local', store: me.accountStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    columnWidth: 0.95,
                });
                accountSec.add(account);

                accountSec.add({
                    iconCls : 'svmx-filter-icon',
                    cursor:'pointer', 
                    scale : 'large', 
                    border: false,
                    style: 'top: 20px',
                    columnWidth: 0.05,
                    cls: 'img-header-default',
                    listeners: {
                        el: {
                            click: function() {
                                var accountSearchText = Ext.getCmp('accountName');
                                var searchRequest ={};
                                searchRequest.objAPIName = 'Account';
                                searchRequest.searchtext = accountSearchText.getRawValue();
                                if(searchRequest.searchtext.length < 3){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG025",'You must enter more than 3 characters to perform search'), 7000, 'success');
                                }
                                else{
                                    var pmplanComponent = Ext.getCmp('pmplan');
                                    pmplanComponent.__engine.searchObject(searchRequest, function(result){
                                        if(result.success){
                                            if(result.searchResponse.length > 0){
                                                me.loadData(result);
                                            }
                                            else{
                                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG024",'No matches found. Refine your search. ') , 7000, 'success');
                                            }
                                        }
                                        else{
                                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                        }
                                    });    
                                }
                            }
                        }
                    },
                });


                me.slaTermsStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getSLAlist()
                });

                var slaTerms = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'slaTermsName', name: 'slaTermsName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG009",'SLA Terms'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name', 
                    value: pmPlanDetails.slaId,
                    labelSeparator: '',
                    queryMode: 'local', store: me.slaTermsStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    hidden: (me.__engine.__mode).toLowerCase() == 'account' || (me.__engine.__mode).toLowerCase() == 'location',
                    style: 'margin-top: 10px;',
                });


                var locationSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'column',
                    defaults: {
                          columnWidth: 0.5
                    },
                    collapsible: false,
                    border: false,
                    hidden: !((me.__engine.__mode).toLowerCase() == 'location'),
                    header: false
                });


                me.locationStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getLocationlist()
                });

                var location = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'locationName', name: 'locationName', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG029",'Location'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name', 
                    value: pmPlanDetails.locationId,
                    labelSeparator: '',
                    columnWidth: 0.95,
                    queryMode: 'local', store: me.locationStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    hidden: !((me.__engine.__mode).toLowerCase() == 'location'),
                    style: 'margin-top: 10px;',
                });

                locationSec.add(location);

                locationSec.add({
                    iconCls : 'svmx-filter-icon',
                    cursor:'pointer', 
                    scale : 'large', 
                    border: false,
                    style: 'top: 20px',
                    columnWidth: 0.05,
                    cls: 'img-header-default',
                    listeners: {
                        el: {
                            click: function() {
                                var locationSearchText = Ext.getCmp('locationName');
                                var searchRequest ={};
                                searchRequest.objAPIName = SVMX.OrgNamespace+'__Site__c';
                                searchRequest.searchtext = locationSearchText.getRawValue();
                                if(searchRequest.searchtext.length < 3){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG025",'You must enter more than 3 characters to perform search'), 7000, 'success');
                                }
                                else{
                                    var pmplanComponent = Ext.getCmp('pmplan');
                                    pmplanComponent.__engine.searchObject(searchRequest, function(result){
                                        if(result.success){
                                            if(result.searchResponse.length > 0){
                                                me.loadData(result);
                                            }
                                            else{
                                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG024",'No matches found. Refine your search. ') , 7000, 'success');
                                            }
                                        }
                                        else{
                                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                        }
                                    });    
                                }
                            }
                        }
                    },
                });


                var startDate = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXDate",{
                    fieldLabel: PMPLAN.T("TAG010",'Start Date'), 
                    labelAlign: 'top',
                    id: 'startDate',
                    allowBlank: false,
                    msgTarget : 'under',
                    value: pmPlanDetails.startDate , 
                    style: 'top: 10px;',
                    labelSeparator: '',
                    invalidText : PMPLAN.T("TAG079",'Enter valid date') ,
                    listeners: {
                        'select': function () {
                            if (this.getValue() != '') {
                                endDate.enable();
                            };
                            if (endDate.getValue() != null) {
                                if (this.getValue() > endDate.getValue()) {
                                    alert('Error! End Date Must Be Later Than The Start Date.')
                                    this.setValue(endDate.getValue())
                                };
                            };
                            endDate.setMinValue(startDate.getValue());
                            
                        },
                        change: function(){
                            me.startEndDateScheduleGeneration();
                        },
                        render: function(){
                            if (this.getValue() != '') {
                                endDate.enable();
                                endDate.setMinValue(startDate.getValue());
                            };
                        }
                    }
                });

                var endDate = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXDate",{
                    fieldLabel: PMPLAN.T("TAG011",'End Date'), 
                    labelAlign: 'top',
                    allowBlank: false,
                    id: 'endDate',
                    disabled: pmPlanDetails.endDate != null? false : true,
                    labelSeparator: '',
                    msgTarget : 'under',
                    style: 'top: 10px;',
                    value:pmPlanDetails.endDate,
                    invalidText : PMPLAN.T("TAG079",'Enter valid date') ,
                    listeners: {
                        change: function(){
                            me.startEndDateScheduleGeneration();
                        }
                    }
                });

                me.activityDateStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'key'}, {name: 'value'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getActivityDateList()
                });

                var activityDate = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'activityDate', name: 'activityDate', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG012",'Activity Date'),
                    labelField:'key', valueField:'key', 
                    displayField: 'value', defaultValue: 1,
                    value: pmPlanDetails.selectedActivityDate,
                    queryMode: 'local', store: me.activityDateStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    labelSeparator: '',
                    style: 'margin-top: 10px;',
                    
                });

                //Condition Type
                var conditionTypeStore = Ext.create('Ext.data.Store', {
                    storeId: 'Condition_Type_Store',
                    fields: ['name', 'label'],
                    data : [
                         {name: 'Usage_Frequency',    label: PMPLAN.T("TAG077", "Usage/Frequency Based")},
                         {name: 'Criteria_Comparison', label: PMPLAN.T("TAG078", "Criteria/Comparison Based")}
                     ]
                });
                var conditionType = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    fieldLabel: PMPLAN.T("TAG074", "Condition Type"),
                    labelSeparator: '',
                    name: 'conditionType',
                    id: 'conditionTypeCombo',
                    store: conditionTypeStore,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'name',
                    labelAlign: 'top',
                    editable: false,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    value: pmPlanDetails.conditionType != null ? pmPlanDetails.conditionType : 'Usage_Frequency',
                    readOnly: (pmPlanDetails.pmPlanId != null && pmPlanDetails.coverageList != null && pmPlanDetails.coverageList.length > 0) ? true : false
                });

                me.WOPurposeStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: me.__engine.getWOPurposelist()
                });

                var WOPurpose = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'WOPurpose', name: 'WOPurpose', 
                    labelAlign: 'top',
                    fieldLabel: PMPLAN.T("TAG013",'Work Order Purpose'),
                    labelField:'label', valueField:'Id', 
                    displayField: 'name', defaultValue: 1,
                    value: pmPlanDetails.woPurposeId,
                    queryMode: 'local', store: me.WOPurposeStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    labelSeparator: '',
                    style: 'top: 10px;',
                    
                });


                var description = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXTextArea',{
                    grow      : true,
                    columnWidth: 0.98,
                    labelAlign : 'top', 
                    id: 'description',
                    fieldLabel: PMPLAN.T("TAG014",'Description'),
                    width: '100%' ,
                    height: 86,
                    resizable: false,
                    bodyPadding: 4,
                    labelSeparator: '',
                    value: pmPlanDetails.description,
                    style    : 'margin-left: 10px;',
                });

                var firstFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    style: 'top: 10px;',
                    items:[planName, scheduleType,serviceContractSec, accountSec, locationSec, startDate, activityDate ]
                };

                var secondFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    style: 'top: 10px;',
                    items:[planTemplate, coverageType, conditionType, slaTerms, WOPurpose, endDate]
                };

                var pmPlanData = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    collapsible: false,
                    region: "center",
                    width: "99%",
                    layout: 'column',
                    border: false,
                    id:'pmPlanData',
                    style: 'margin-left: 8px;',
                    defaults: {
                        bodyPadding: 8,
                        
                    },
                    items: [firstFieldSetForFields, secondFieldSetForFields, description]
                });

                me.add(pmPlanData);

                var coveredIBSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    layout: 'column',
                    margin: '0 20 10 20',
                    defaults: {
                          columnWidth: 0.5
                    },
                    collapsible: false,
                    border: false,
                    header: false,
                    hidden: true,
                    id: 'coveredIBSec',
                    cls: 'img-header-default',
                });

                this.coveredIBStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: []
                });

                var coveredIB = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'coveredIBName', name: 'coveredIBName', 
                    labelAlign: 'top',
                    labelField:'label', valueField:'Id', 
                    displayField: 'name', 
                    labelSeparator: '',
                    columnWidth: 0.80,
                    queryMode: 'local', store: this.coveredIBStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners:{
                        select: function(cmp, newValue, oldValue, eOpts ){
                           // add row to grid and hide this sec
                            var recCount = me.covergaeStore.getCount();
                            var productId = me.__ibSearchList[newValue[0].data.Id][SVMX.OrgNamespace+'__Product__c'];
                            var isDifferentProduct = true;

                            if(me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null && me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.product != null && me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.product != ''){
                                if(me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.product == productId){
                                    isDifferentProduct = false;
                                }
                            }

                            var rec = {
                                installedProductName: newValue[0].data.name,
                                installedProductId: newValue[0].data.Id,
                                conditionRuleList: [],
                                scheduleList: [],
                                productId : productId,
                                isNewAddCov : true,
                                isDifferentProduct: isDifferentProduct,
                            };
                            // Add the covergae to grid and hide the search 
                            me.covergaeStore.insert(recCount, rec);
                            Ext.getCmp('coveredIBSec').hide();
                            this.clearValue();

                        }
                    }
                    
                });
                coveredIBSec.add(coveredIB);

                coveredIBSec.add({
                    iconCls : 'svmx-filter-icon',
                    cursor:'pointer', 
                    scale : 'medium', 
                    border: false,
                    columnWidth: 0.10,
                    style: 'top: -4px',
                    cls: 'img-header-default',
                    listeners: {
                        el: {
                            click: function() {
                                var scSearchText = Ext.getCmp('coveredIBName');
                                var searchRequest ={};
                                searchRequest.objAPIName = SVMX.OrgNamespace+'__Installed_Product__c';
                                searchRequest.searchtext = scSearchText.getRawValue();

                                if(searchRequest.searchtext.length < 3){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG025",'You must enter more than 3 characters to perform search'), 7000, 'success');
                                }
                                else{
                                    var pmplanComponent = Ext.getCmp('pmplan');
                                    pmplanComponent.__engine.searchObject(searchRequest, function(result){
                                        if(result.success){
                                            if(result.searchResponse.length > 0){
                                                me.loadData(result);
                                                me.__ibSearchList = result.mapSearchRecord;
                                            }
                                            else{
                                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG024",'No matches found. Refine your search. ') , 7000, 'success');
                                            }
                                        }
                                        else{
                                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                        }
                                    });
                                }
                            }
                        }
                    },
                });


                coveredIBSec.add({
                    iconCls : 'pmplan-delete-row-icon',
                    cls: 'pmplan-add-coverage',
                    cursor:'pointer',
                    border:false, 
                    columnWidth: 0.10,                                  
                    tooltip: PMPLAN.T("TAG017",'Remove Coverage'),
                    listeners: {
                        el: {
                            click: function() {
                                Ext.getCmp('coveredIBSec').hide();
                                Ext.getCmp('coveredIBName').clearValue();   
                            }
                        }                                     
                    }
                });


                var coveragesGridSec = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    collapsible: false,
                    border: false,
                    header: false,
                    id: 'coveragesGridSec',
                    cls: 'img-header-default',
                });
                
                me.covergaeStore =  SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{name: "installedProductName"}, {name: "delete"}, {name: "pmCovergaeId"}, {name: "advancedExpression"}, {name: "conditionRuleList",  type: 'object'}, 
                            {name: "pmCoverageName"}, {name: "productId"}, {name: "installedProductId"}, {name: "scheduleList",  type: 'object'}, {name: 'isNewAddCov'}, {name: 'isDifferentProduct'}],
                    proxy: {
                        type: "memory"
                    },
                    sorters: [{
                        property: 'productName',
                        direction: 'asc'
                    }],
                    data: me.__engine.getCovergaeList()
                });


                var coverageGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{               
                    autoScroll: true, maxHeight:450, margin: '40 20 10', anchor: '100%',
                    store: me.covergaeStore,
                    border: false,
                    id: 'coverageGrid',
                    emptyText: PMPLAN.T("TAG015", 'No Coverages to display'),
                    viewConfig: { 
                        deferEmptyText: false,
                    },
                    columns : [  
                        { flex: 1, text: PMPLAN.T("TAG016", 'Coverages'), dataIndex: 'installedProductName', align: 'left', resizable: true, readOnly: true,
                            renderer: function(value, meta, record, grid){
                                if(record.data.isDifferentProduct){
                                    //grid.addRowCls(rowIndex, 'bluerow');
                                    meta.tdCls= 'make-cell-dirty-lt';
                                    meta.tdAttr = "data-errorqtip='"+ PMPLAN.T("TAG071","Please add condition to newly added coverage as it's product is different from PM template product.")+ "'";
                                }
                                return Ext.String.htmlEncode(record.data.installedProductName);
                            }
                        },   
                        
                        {
                            xtype: 'actioncolumn', flex: 10/100, align: 'center',
                            resizable : false, dataIndex: 'delete', readOnly: true, sortable : false,
                            menuDisabled: true, align: 'center',
                            items: [
                                {   
                                    iconCls : 'pmplan-delete-row-icon',
                                    cursor:'pointer',                                   
                                    tooltip: PMPLAN.T("TAG017",'Remove Coverage'),
                                    handler: function (grid, rowIndex, colIndex ) {
                                        Ext.MessageBox.confirm('Confirm', PMPLAN.T("TAG026", 'Are you sure you want to delete coverage?') , function(btn){
                                            if(btn == 'yes'){
                                                var record = grid.getStore().getAt(rowIndex);
                                                me.covergaeStore.remove( record );
                                                if(me.covergaeStore.getCount() == 0 && Ext.getCmp('planTemplateName').getValue() == 'NONE'){
                                                    Ext.getCmp('conditionTypeCombo').setReadOnly(false);
                                                }
                                            }
                                        });                                      
                                    }
                                }
                            ]
                        }
                    ],
                    listeners:{
                        cellclick: function( grid, td, cellIndex, record, tr, rowIndex, e ) {   
                            if(cellIndex == 0 ){
                               
                                // Load the schedule records on click of covergae
                                var recordStoreData = record.getData();
                                var conditionGridStoreData = [];
                                conditionGridStoreData = (recordStoreData.conditionRuleList != '' && recordStoreData.conditionRuleList != null)? recordStoreData.conditionRuleList: (me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null ? me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.conditionRuleList: []);  
                                
                                var scheduleStoreData = recordStoreData.scheduleList;

                                var getTAAttReq = {};
                                var fieldAtt = {};
                                getTAAttReq.coverageId = recordStoreData.installedProductId; 
                                getTAAttReq.productId = recordStoreData.productId;
                                var conditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                                getTAAttReq.pmPlanRecord = {
                                    'conditionType': conditionTypeValue
                                };

                                me.__engine.getCoverageTechnicalAtt(getTAAttReq, function(result){
                                    if(result.success){
                                        fieldAtt = result.mapOfKeyAndListOfKeyValue;

                                        var conditionTypeValue = Ext.getCmp('conditionTypeCombo').getValue();
                                        if(conditionTypeValue === 'Criteria_Comparison'){
                                            me.loadAttributeStoreOfCriteriaType(fieldAtt);
                                        }

                                        var advExp = recordStoreData.advancedExpression != null && recordStoreData.advancedExpression != ''? recordStoreData.advancedExpression : (me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null ? me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.advancedExpression: '');
                                        
                                        // TO DO: Take care of Advanced condition
                                        if(scheduleStoreData != '' && scheduleStoreData != null){
                                            me.showConditionRulePanel(conditionGridStoreData, scheduleStoreData, recordStoreData, advExp, rowIndex, fieldAtt);
                                        }
                                        else{
                                            var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');

                                            var getScheduleReq = {};
                                            getScheduleReq.coverageId = recordStoreData.installedProductId; 
                                            
                                            if(!recordStoreData.isNewAddCov ){
                                                getScheduleReq.conditionRuleList = conditionGridStoreData;
                                                getScheduleReq.advancedExpression = advExp;
                                            }
                                            else{
                                                if(recordStoreData.conditionRuleList != null && recordStoreData.conditionRuleList.length > 0){
                                                    getScheduleReq.conditionRuleList = recordStoreData.conditionRuleList;
                                                }
                                                else{
                                                    getScheduleReq.conditionRuleList = [];
                                                }

                                                if(recordStoreData.advancedExpression != null && recordStoreData.advancedExpression != ''){
                                                    getScheduleReq.advancedExpression  = recordStoreData.advancedExpression;
                                                    advExp = getScheduleReq.advancedExpression 
                                                }
                                                else{
                                                    getScheduleReq.advancedExpression = '';
                                                    advExp = '';
                                                }
                                                
                                            }
                                            getScheduleReq.pmPlanRecord = {};
                                            getScheduleReq.pmPlanRecord.pmPlanId = me.__engine.__pmplanData.pmPlanRecord.pmPlanId;
                                            getScheduleReq.pmPlanRecord.pmTemplateDetail = JSON.parse(JSON.stringify(me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail)); 
                                            getScheduleReq.pmPlanRecord.conditionType = Ext.getCmp('conditionTypeCombo').getValue();

                                            // In cases when PM Template condition rules are of length =0, and conditionrule is not null 
                                            
                                            var startDateVal = Ext.getCmp('startDate').getValue();
                                            var endDateVal = Ext.getCmp('endDate').getValue(); 

                                            if(startDateVal != null){
                                                getScheduleReq.pmPlanRecord.startDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('startDate').getValue(), userInfo.TimezoneOffset, false);
                                                getScheduleReq.pmPlanRecord.startDate =  getScheduleReq.pmPlanRecord.startDate.substr(0,  getScheduleReq.pmPlanRecord.startDate.indexOf(' '));
                                            
                                            }

                                            if(endDateVal != null){
                                                getScheduleReq.pmPlanRecord.endDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('endDate').getValue(), userInfo.TimezoneOffset, false);
                                                getScheduleReq.pmPlanRecord.endDate =  getScheduleReq.pmPlanRecord.endDate.substr(0,  getScheduleReq.pmPlanRecord.endDate.indexOf(' '));
                                            }

                                            // Every Covergae can have its own Adv expression. Load that first, later check if there ia nay tem
                                            // Always load the selected Work Order Purpose 
                                            getScheduleReq.workOrderPurposeId = Ext.getCmp('WOPurpose').getValue();
                                            //getScheduleReq.workOrderPurposeId = me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null ? me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.workOrderPurpose: null;

                                            // Once we have got condition grid, check for advanced Expression
                                            if(getScheduleReq.conditionRuleList != null && getScheduleReq.conditionRuleList.length > 0 && (getScheduleReq.advancedExpression == '' || getScheduleReq.advancedExpression == null)){
                                                advExp = advancedExp(result.conditionRuleList.length);
                                            }

                                            //populate field label for selected field API name in the condition rules
                                            if(getScheduleReq.pmPlanRecord.conditionType === 'Criteria_Comparison' && getScheduleReq.conditionRuleList != null && getScheduleReq.conditionRuleList.length > 0){
                                                var fieldListStoreCB = Ext.data.StoreManager.lookup('Field_List_Store_CB');
                                                for(var i =0 ; i<getScheduleReq.conditionRuleList.length; i++){
                                                    var selectedFieldValue = getScheduleReq.conditionRuleList[i].selectedField;
                                                    var recFromStore = fieldListStoreCB.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                                                    var selectedFieldLabel = recFromStore && recFromStore.getData().fieldLabel;
                                                    getScheduleReq.conditionRuleList[i].selectedFieldLabel = selectedFieldLabel;
                                                }
                                            }
                                            
                                            me.__engine.getCoverageScheduleData(getScheduleReq, function(result){
                                                if(result.success){
                                                    var scheduleStoreData = result.scheduleList;

                                                    if(result.conditionRuleList == null || result.conditionRuleList.length == 0){
                                                        advExp = '';    
                                                    }

                                                    me.showConditionRulePanel(result.conditionRuleList, scheduleStoreData, recordStoreData, advExp, rowIndex, fieldAtt);
                                                }
                                                else{
                                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                                }
                                            })   
                                        } 
                                    }
                                    else{
                                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messageList[0], 7000, 'success');
                                    }
                                });
                            }
                        }
                    }
                });

                coveragesGridSec.add(coverageGrid);
                coveragesGridSec.add(coveredIBSec);

                me.add(coveragesGridSec);

                var addCovBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: PMPLAN.T("TAG018", 'Add Coverages'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    id: 'addCovBtn',
                    cls: 'pmplan-coverages-btn',
                    handler: function(button, e) {
                        Ext.getCmp('coveredIBSec').show(); 
                    }
                }); 

                me.add(addCovBtn);

                var pmPlanActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: 'calc(100% - 30px)',
                    dock: "bottom",
                    style : 'margin-top: 20px', 
                    border: false,
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                pmPlanActions.add(tabFill3);

                var cancelPMPlanBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: PMPLAN.T("TAG022", 'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    cls: 'pmplan-cancel-btn',
                    handler: function() {
                        var returnlocation = '';
                        if(me.__engine.__sourceId != undefined){
                            returnlocation = '/'+me.__engine.__sourceId;
                        } 
                        else{
                            returnlocation = '/'+me.__engine.__planId;
                        }
                        //window.location = '/'+returnlocation;
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            sforce.one.navigateToURL(returnlocation);
                        }
                        else{
                            window.location = returnlocation;
                        }
                    }
                });

                var savePMPlanBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: PMPLAN.T("TAG023", 'Save'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    id: 'savePMPlanBtn',
                    cls: 'pmplan-save-btn',
                    handler: function(button, e) {
                        me.savePMPlan('button');
                    }
                });

                pmPlanActions.add(cancelPMPlanBtn);
                pmPlanActions.add(savePMPlanBtn);

                me.add(pmPlanActions);
                    
            },
            onAddClick: function(button){
                Ext.getCmp('gridBbar').add(coveredIBSec);
            },
            advancedExp: function(conditionRuleCount){
                var strCriteria = '';
                for(var i = 0; i<conditionRuleCount; i++){
                    if(strCriteria.length > 0)
                        strCriteria += ' AND ';
                    strCriteria += i+1;
                }
                return strCriteria;
            },
            loadData: function(result) {
                if(result.objAPIName == 'Account')
                    this.accountStore.loadData(result.searchResponse);

                if(result.objAPIName == SVMX.OrgNamespace+'__PM_Plan_Template__c')
                    this.planTemplateStore.loadData(result.searchResponse);

                if(result.objAPIName == SVMX.OrgNamespace+'__Service_Contract__c')
                    this.serviceContractStore.loadData(result.searchResponse);

                if(result.objAPIName == SVMX.OrgNamespace+'SLA_Terms__c')
                    this.slaTermsStore.loadData(result.searchResponse);

                if(result.objAPIName == SVMX.OrgNamespace+'__Installed_Product__c')
                    this.coveredIBStore.loadData(result.searchResponse);


                if(result.objAPIName ==  SVMX.OrgNamespace+'__Site__c')
                    this.locationStore.loadData(result.searchResponse);

            },
            loadTemplateDetails: function(result){
                var updateActivityDate = Ext.getCmp('activityDate');
                updateActivityDate.setValue(result.pmPlanRecord.pmTemplateDetail.activityDate);

                var updateWorkOrderPurpose = Ext.getCmp('WOPurpose');
                updateWorkOrderPurpose.setValue(result.pmPlanRecord.pmTemplateDetail.workOrderPurpose);

                var updateConditionType = Ext.getCmp('conditionTypeCombo');
                //This is added as part of BAC-2246 story to handle updgrade scenario
                var conditionTypeValue = (result.pmPlanRecord.pmTemplateDetail.conditionType != null && (result.pmPlanRecord.pmTemplateDetail.conditionType) != '') ? result.pmPlanRecord.pmTemplateDetail.conditionType : 'Usage_Frequency';
                updateConditionType.setValue(conditionTypeValue);
                if(result.pmPlanRecord.coverageList != null && result.pmPlanRecord.coverageList.length > 0){
                    updateConditionType.setReadOnly(true);
                }
                
                // Updated Advanced Expression
                this.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail = result.pmPlanRecord.pmTemplateDetail;
                this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues = result.pmPlanRecord.pmPlanMappedValues;


                // Load all mapped values from template
                Ext.getCmp('planName').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues.Name);
                Ext.getCmp('serviceContractName').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Service_Contract__c']);
                Ext.getCmp('accountName').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Account__c']);
                Ext.getCmp('slaTermsName').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__SLA_Terms__c']);
                Ext.getCmp('locationName').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Location__c']);
                Ext.getCmp('startDate').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Start_Date__c']);
                
                Ext.getCmp('endDate').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__End_Date__c']);
                // Enable End Date 
                if (Ext.getCmp('endDate').getValue() != null){
                    Ext.getCmp('endDate').setDisabled(false);
                }

                Ext.getCmp('activityDate').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__SM_Adjustment_Activity_Date__c']);
                Ext.getCmp('description').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Description__c']);
                Ext.getCmp('WOPurpose').setValue(this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues[SVMX.OrgNamespace+'__Task_Template__c']);
         

                // Remove previoud data from store and intialize it with new data
                this.covergaeStore.removeAll();

                if(this.__engine.__mode.toLowerCase() == 'ib'){
                    if(result.pmPlanRecord.coverageList != null && result.pmPlanRecord.coverageList.length > 0){
                        result.pmPlanRecord.coverageList.forEach(function(item,j){
                            var parentCmp = Ext.getCmp('pmplan');
                            if(parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null && parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != ''){
                                if(parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.product != null && parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.product != item.productId){
                                    item.isDifferentProduct = true; 
                                    parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.conditionRuleList = [];
                                    parentCmp.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.advancedExpression = ''; 
                                }
                            }
                        });
                    }
                }
                if(result.pmPlanRecord.coverageList != null){
                    this.covergaeStore.loadData(result.pmPlanRecord.coverageList);
                }
            },
            createPMTemplateReq : function(templateId){
                var pmTemplateReq = {};
                //pmTemplateReq.pmTemplateId = Ext.getCmp('planTemplateName').getValue(); 
                pmTemplateReq.pmTemplateId = templateId; 
                pmTemplateReq.pmPlanDataUpdates ={};
                pmTemplateReq.pmPlanDataUpdates.serviceContractId = Ext.getCmp('serviceContractName').getValue();
                // Get the selected account
                var accountSelectedId = Ext.getCmp('accountName');
                pmTemplateReq.pmPlanDataUpdates.accountId = accountSelectedId.getValue();
                pmTemplateReq.pmPlanDataUpdates.locationId = Ext.getCmp('locationName').getValue();


                // Need to take care of values which are part of UI only
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues = this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues; 
                pmTemplateReq.pmPlanDataUpdates.pmTemplatePMPlanMapping = this.__engine.__pmplanData.pmPlanRecord.pmTemplatePMPlanMapping;

                // pmTemplatePMPlanMapping should always be upto date with UI values of Service Contract, Account, Location
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Account__c']            = pmTemplateReq.pmPlanDataUpdates.accountId; 
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Location__c']            = pmTemplateReq.pmPlanDataUpdates.locationId ;
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Service_Contract__c']    = pmTemplateReq.pmPlanDataUpdates.serviceContractId ;
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues['Name'] = Ext.getCmp('planName').getValue(); 
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__SLA_Terms__c'] = Ext.getCmp('slaTermsName').getValue();
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Task_Template__c'] = Ext.getCmp('WOPurpose').getValue();
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Description__c'] = Ext.getCmp('description').getValue(); 
                pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__SM_Adjustment_Activity_Date__c'] = Ext.getCmp('activityDate').getValue(); 


                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');

                var startDateVal = Ext.getCmp('startDate').getValue();
                var endDateVal = Ext.getCmp('endDate').getValue(); 

                if(startDateVal != null){
                    pmTemplateReq.pmPlanDataUpdates.startDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('startDate').getValue(), userInfo.TimezoneOffset, false);
                    var startDateConv = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('startDate').getValue(), userInfo.TimezoneOffset, false);
                    pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__Start_Date__c'] = startDateConv.substring(0, startDateConv.indexOf(' '));
                }

                if(endDateVal != null){
                    pmTemplateReq.pmPlanDataUpdates.endDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('endDate').getValue(), userInfo.TimezoneOffset, false);
                    var endDateConv = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('endDate').getValue(), userInfo.TimezoneOffset, false);
                    pmTemplateReq.pmPlanDataUpdates.pmPlanMappedValues[SVMX.OrgNamespace+'__End_Date__c'] = endDateConv.substring(0, endDateConv.indexOf(' '));
                }
                
                pmTemplateReq.mode = this.__engine.__mode;

                if(pmTemplateReq.mode.toLowerCase() == 'ib'){

                    var Ibcoverages = []; 
                    Ext.getCmp('coverageGrid').getStore().data.items.forEach(function(item,j){
                        Ibcoverages.push(item.data);
                    });
                    pmTemplateReq.pmPlanDataUpdates.coverageList = Ibcoverages;
                }

                this.__engine.getPMTemplateData(pmTemplateReq, function(result){
                    if(result.success){
                        var pmPlan = Ext.getCmp('pmplan');
                        pmPlan.loadTemplateDetails(result);
                    }
                    else{
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                    }
                }) 
                
            },
            showConditionRulePanel: function(conditionStoreData, scheduleStoreData, record, advancedExpression, recordIndex, fieldList) {
                this.conditionrulePanel.loadStore(conditionStoreData, scheduleStoreData, advancedExpression, fieldList);
                this.conditionrulePanel.setTitle(Ext.String.htmlEncode(record.installedProductName) ); // BAC-4097 - Identification and fixing for XSS
                this.conditionrulePanel.__recordIndex = recordIndex;
                this.conditionrulePanel.__covergaeId= record.productId;
                this.conditionrulePanel.__runScheduleCoverageId = record.pmCovergaeId; //This is added for fixing defect BAC-2849

                this.conditionrulePanel.show();
                this.disable(); 
            },

            loadAttributeStoreOfCriteriaType: function(fieldList){
                this.conditionrulePanel.loadAttributeStoreForCriteria(fieldList);
            },

            startEndDateScheduleGeneration: function(){
                var count = 0; 
                Ext.getCmp('coverageGrid').getStore().data.items.forEach(function(item,j){
                    if(item.data.scheduleList != null && item.data.scheduleList != ''){
                        count ++; 
                    }
                });

                if(count > 0){
                    Ext.MessageBox.confirm('Confirm', PMPLAN.T("TAG063",'Changing this will regenerate all unprocessed schedules for this Preventive maintenance plan. Do you want to continue?') , function(btn){
                        if(btn == 'yes'){
                            Ext.getCmp('coverageGrid').getStore().data.items.forEach(function(item,j){
                                if(item.data.scheduleList != null && item.data.scheduleList != ''){
                                    item.data.scheduleList = [];
                                }
                            });
                        }
                    }); 
                }
            },
            savePMPlan: function(clickType){

                var savePMPlanReq = {};
                        
                savePMPlanReq.sourceId = this.__engine.__sourceId;
                savePMPlanReq.mode = this.__engine.__mode;
                savePMPlanReq.pmPlanDataUpdates = {};
                var userInfo = SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo');

                // PM Plan can't be saved of there are no coverages
                var coverages = []; 
                var validationError = false;

                var covergaeGridVal = Ext.getCmp('coverageGrid'); 

                var covHasCond = true ;
                covergaeGridVal.getStore().data.items.forEach(function(item,j){
                    var classAttr = covergaeGridVal.getNode(j).childNodes[0].getAttribute('class');
                    if(classAttr.indexOf('make-cell-dirty-lt') != -1){
                        covHasCond = false; 
                        validationError = true; 
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(PMPLAN.T("TAG072", 'Add conditions to save the coverage.'), 7000, 'success');
                    }
                    coverages.push(item.data);
                });

                
                if(Ext.getCmp('planName').getValue().length == 0){
                    Ext.getCmp('planName').markInvalid(PMPLAN.T("TAG019", 'Enter PM Plan Name'));
                    validationError = true
                }
                else{
                    savePMPlanReq.pmPlanDataUpdates.pmPlanName = Ext.getCmp('planName').getValue();
                }

                if(Ext.getCmp('endDate').getValue() == null){
                    Ext.getCmp('endDate').markInvalid(PMPLAN.T("TAG020", 'Enter End Date'));
                    validationError = true
                }
                else{
                    savePMPlanReq.pmPlanDataUpdates.endDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('endDate').getValue(), userInfo.TimezoneOffset, false);                            
                }

                if(Ext.getCmp('startDate').getValue() == null){
                    Ext.getCmp('startDate').markInvalid(PMPLAN.T("TAG021", 'Enter Start Date'));
                    validationError = true
                }
                else{
                    savePMPlanReq.pmPlanDataUpdates.startDate = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(Ext.getCmp('startDate').getValue(), userInfo.TimezoneOffset, false);
                }

                // if any of the newly added covergae of different Product Type is tried to dave, throw error.


                /*if(coverages.length == 0){
                    validationError = true;
                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage('There should be atleast one covergae for PM Plan', 7000, 'success');
                }
                else if(this.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail != null){
                    if(this.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.conditionRuleList == null || me.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail.conditionRuleList.length == 0){
                        validationError = true;
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage('There should be atleast one condition rule or schedule defined for each covergae.', 7000, 'success');
                    }
                } 
                else{
                    // If you are here, that means you don't have any default condition rules defined, so loop through to find 
                    if(coverages.length > 0){
                        console.log('came here');

                    }
                }*/

                if(!validationError){
                    Ext.getCmp('savePMPlanBtn').setDisabled(true);
                    var pmPlanTemplateId = Ext.getCmp('planTemplateName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.pmPlanTemplateId = (pmPlanTemplateId !== 'NONE') ? pmPlanTemplateId : null;
                    savePMPlanReq.pmPlanDataUpdates.serviceContractId = Ext.getCmp('serviceContractName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.selectedCovergaeType = Ext.getCmp('coverageTypeName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.conditionType = Ext.getCmp('conditionTypeCombo').getValue();
                    savePMPlanReq.pmPlanDataUpdates.slaId = Ext.getCmp('slaTermsName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.accountId = Ext.getCmp('accountName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.locationId = Ext.getCmp('locationName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.description = Ext.getCmp('description').getValue();
                    savePMPlanReq.pmPlanDataUpdates.selectedScheduleType = Ext.getCmp('scheduleTypeName').getValue();
                    savePMPlanReq.pmPlanDataUpdates.coverageList = coverages;
                    savePMPlanReq.pmPlanDataUpdates.pmPlanId = this.__engine.__pmplanData.pmPlanRecord.pmPlanId;

                    savePMPlanReq.pmPlanDataUpdates.pmTemplateDetail = this.__engine.__pmplanData.pmPlanRecord.pmTemplateDetail ; 
                    savePMPlanReq.pmPlanDataUpdates.pmTemplateDetail.workOrderPurpose = Ext.getCmp('WOPurpose').getValue();
                    savePMPlanReq.pmPlanDataUpdates.pmTemplateDetail.activityDate = Ext.getCmp('activityDate').getValue();
                    savePMPlanReq.pmPlanDataUpdates.woPurposeId = Ext.getCmp('WOPurpose').getValue();
                    savePMPlanReq.pmPlanDataUpdates.selectedActivityDate = Ext.getCmp('activityDate').getValue();
                    savePMPlanReq.pmPlanDataUpdates.activatePMPlan = this.__engine.__pmplanData.pmPlanRecord.activatePMPlan;
                    savePMPlanReq.pmPlanDataUpdates.pmPlanMappedValues = this.__engine.__pmplanData.pmPlanRecord.pmPlanMappedValues;
                    
                    this.__engine.savePMPlan(savePMPlanReq, function(result){
                        if(result.success && clickType == 'button'){
                            var returnURL = '/'+result.pmPlanRecord.pmPlanId;
                            //window.location = '/'+result.pmPlanRecord.pmPlanId;
                            if((typeof sforce != 'undefined') && (sforce != null)){
                                sforce.one.navigateToURL(returnURL);
                            }
                            else{
                                window.location = returnURL;
                            }
                        }
                        /*else if(result.success && clickType == 'coverage'){
                            var pmplanComponent = Ext.getCmp('pmplan');
                            pmplanComponent.pmPlanId = result.pmPlanRecord.pmPlanId;
                            pmplanComponent.showConditionRulePanel();
                            pmplanComponent.covergaeStore.loadData(result.pmPlanRecord.coverageList);
                        }*/
                        else{
                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                        }
                        Ext.getCmp('savePMPlanBtn').setDisabled(false);
                    })    
                }    
            }
        });
    }
})();