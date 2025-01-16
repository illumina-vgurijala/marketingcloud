(function(){
    var impl = SVMX.Package("com.servicemax.client.qbm.ui.desktop.editQuestion");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("CQL");
        
        Ext.define("com.servicemax.client.qbm.ui.desktop.editQuestion.EditQuestionPanel", {
            extend: 'Ext.form.FormPanel',

            __actionType: null,
 
           constructor: function(config) {

                config = Ext.apply({
                    layout: 'anchor', defaultType: 'textfield', bodyPadding: 25, autoScroll: true, border: false,
                    defaults: {anchor: '100%'}, fieldDefaults: {labelAlign: 'top', labelWidth: 100},
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                // Define the model for a State
                Ext.define('State', {
                    extend: 'Ext.data.Model',
                    fields: [
                        {type: 'string', name: 'name'},
                    ]
                });

                var tagsStore = Ext.create('Ext.data.Store', {
                    model: 'State',
                    //data: tags,
                    data : [],
                    proxy: {
                        type: 'memory'
                    }
                });

                this.__tagstore = tagsStore;

                // Basic BoxSelect using the data store
                var basicBoxselect = Ext.create('com.servicemax.client.qbm.ui.desktop.boxselect.BoxSelect', {
                    fieldLabel: TS.T("TAG024","Tags"),
                    displayField: 'name',
                    name:'TagField',
                    id:'tagsList',
                    anchor: '50%',
                    multiSelect : true,
                    forceSelection:false,
                    hideTrigger:true,
                    editable:true,
                    store: tagsStore,
                    queryMode: 'local',
                    createNewOnEnter: true,
                    createNewOnBlur: true,
                    filterPickList: true,
                    triggerOnClick: false,
                    pinList: false,
                    delimiter : ',',
                });

                me.add({
                    fieldLabel: TS.T("TAG025","Question Text"), name: 'questionText',
                    id: SVMX.OrgNamespace+'__Question__c',
                    anchor: '50%', allowBlank: false, padding: '0 0 15',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required")
                });

                me.add({
                    fieldLabel: 'Question ID', name: 'questionId',
                    id: SVMX.OrgNamespace+'__QuestionID__c',
                    anchor: '50%', padding: '0 0 15', hidden: 'true'
                });

                //Added for the story BAC-2300
                me.add({
                    fieldLabel : TS.T("TAG051","Default Answer"), name: 'defaultResponseText',
                    id: 'defaultResponseText',
                    anchor: '50%', padding: '0 0 15', xtype : 'textfield', maxLength : 255, enforceMaxLength: true
                });

                //Added for the story BAC-2300
                me.add({
                    fieldLabel : TS.T("TAG051","Default Answer"), name: 'defaultResponseNumber',
                    id: 'defaultResponseNumber',
                    anchor: '50%', padding: '0 0 15', xtype : 'numberfield', hidden: 'true',
                    enforceMaxLength: true, maxLength: 14 //Added for fixing defect 
                });

                //Added for the story BAC-2303
                var valueFunctionStore = SVMX.create('Ext.data.Store',{
                    fields: ['value', 'label'],
                    data:{'items':[{
                            "label":TS.T("COMM002","Value"), 
                            "value":"Value"
                        },{
                            "label":TS.T("COMM001","Function"), 
                            "value":"Function",
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

                //Added for the story BAC-2303
                var valueFunctionComboCmp = {
                    xtype: 'combobox', 
                    padding: '0 0 15', 
                    id: 'valueFunctionCombo',
                    name: 'valueFunctionCombo', fieldLabel: TS.T("TAG051","Default Answer"),
                    labelField:'label', valueField:'value', displayField: 'label', defaultValue: 'Value', value: 'Value',
                    queryMode: 'local', editable: false, 
                    anchor: '50%',
                    store: valueFunctionStore,
                    hidden: true,
                    listeners: {              
                        change: function(field, newValue, oldValue) {
                            var dateCmp = Ext.getCmp('defaultResponseDate');
                            var literalCmp = Ext.getCmp('literalCombo');
                            if(newValue === 'Value'){
                                literalCmp.hide();
                                dateCmp.reset();
                                dateCmp.show();
                            }
                            else if(newValue === 'Function'){
                                dateCmp.hide();
                                literalCmp.reset();
                                literalCmp.show();
                            }
                        }, 
                        afterrender: function(combo) { 
                            combo.setValue(this.defaultValue);
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                };

                //Added for the story BAC-2303
                var defaultResponseDateCmp = {
                    xtype : 'datefield',
                    name: 'defaultResponseDate',
                    id: 'defaultResponseDate',
                    anchor: '50%', 
                    padding: '0 0 15',
                    editable: false,
                    hidden: true,
                };

                //Added for the story BAC-2303
                var literalStore = Ext.create('Ext.data.Store',{
                    fields: ['value', 'label', 'type'],
                    data:{'items':[{
                            "label": TS.T("COMM004","Today"), 
                            "value": "Today",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM005","Tomorrow"), 
                            "value": "Tomorrow",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM006","Yesterday"), 
                            "value": "Yesterday",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM007","Now"), 
                            "value": "Now",
                            "type": "DateTimeAns"
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    },
                    sorters: [{
                        property: 'label',
                        direction: 'ASC'
                    }]
                });

                //Added for the story BAC-2303
                var literalCombo = {
                    xtype: 'combobox', 
                    padding: '0 0 15', 
                    id: 'literalCombo',
                    name: 'literalCombo',
                    labelField:'label', 
                    valueField:'value', 
                    displayField: 'label',
                    queryMode: 'local', 
                    editable: false, 
                    anchor: '50%',
                    store: literalStore,
                    hidden: true,
                    emptyText: TS.T("COMM003","Select"),
                    listeners: {              
                        expand : function(combo){
                            var answerTypeValue = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                            if(answerTypeValue !== null && answerTypeValue !== '' && answerTypeValue === 'Date'){
                                combo.store.filter('type','DateAns');
                            }
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                };

                me.add(valueFunctionComboCmp);
                me.add(defaultResponseDateCmp);
                me.add(literalCombo);

                me.add({
                    fieldLabel: TS.T("TAG044","Help URL"), name: 'helpURL',
                    id: SVMX.OrgNamespace+'__Help_URL__c',
                    anchor: '50%', padding: '0 0 15'
                });

                var responseType = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'response_Type'],
                    data: [
                        ['Text', TS.T("TAG026","Text")],
                        ['Checkbox', TS.T("TAG027","Checkbox")],
                        ['Radio Button', TS.T("TAG028","Radio Button")],
                        ['Picklist', TS.T("TAG029","Picklist")],
                        ['Multi-select Picklist', TS.T("TAG030","Multi-select Picklist")],
                        ['Number', TS.T("TAG031","Number")],
                        ['DateTime', TS.T("TAG032","DateTime")],
                        ['Date', TS.T("TAG033","Date")],
                        ['Attachment', TS.T("TAG048","Attachment")]//Added for the story BAC-2322
                    ],
                    //This is addded for sorting response type values during implementation of BAC-2322
                    sorters: [{
                        property: 'response_Type',
                        direction: 'ASC'
                    }]
                });

                this.__responseTypeDropDown = me.add({
                    xtype: 'combobox', padding: '0 0 15', 
                    id: SVMX.OrgNamespace+'__Response_Type__c',
                    name: 'response_Type', fieldLabel: TS.T("TAG034","Answer Type"),
                    labelField:'label', valueField:'Id', displayField: 'response_Type', defaultValue: 'Text', value: 'Text',
                    queryMode: 'local', editable: false, anchor: '50%',
                    store: responseType,
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            //Clear filter literal combo - //Added for the story BAC-2322
                            var literalComboCmp = Ext.getCmp('literalCombo');
                            if(literalComboCmp != null){
                                literalComboCmp.store.clearFilter();
                            }

                            if(newValue === 'Checkbox' || newValue === 'Picklist' || newValue === 'Multi-select Picklist' || newValue === 'Radio Button'){
                                me.showHideResponseSetDropDown(true);
                                me.showResponseOptions(true);
                                me.showHideNewResponseSetName(true);
                            }else{
                                me.showHideResponseSetDropDown(false);
                                me.showResponseOptions(false);
                                me.showHideNewResponseSetName(false);
                            }

                            //Added for the story BAC-2322
                            if(newValue === 'Attachment'){
                                me.showHideOpdocDescriptionFields(true);
                            }
                            else{
                                me.showHideOpdocDescriptionFields(false);
                            }

                            //------Start-----Added for the story BAC-2300
                            me.hideAllDefaultAnsCmp();
                            if(newValue === 'Text' || newValue === 'Number' || newValue === 'Date' || newValue === 'DateTime'){
                                switch(newValue){
                                    case 'Text':
                                        me.resetAndShowCmp('defaultResponseText');
                                        break;
                                    case 'Number':
                                        me.resetAndShowCmp('defaultResponseNumber');
                                        break;
                                    case 'Date':
                                    case 'DateTime':
                                        me.resetAndShowCmp('valueFunctionCombo');
                                        me.resetAndShowCmp('defaultResponseDate');
                                        break;
                                }
                            }
                            //------End-----Added for the story BAC-2300

                            //-------Start------Added for the defect BAC-3361 fix
                            if(newValue === 'Attachment'){
                                Ext.getCmp('clearDefault').hide();
                            }
                            else{
                                Ext.getCmp('clearDefault').show();
                            }
                            //-------End------Added for the defect BAC-3361 fix
                        },  
                        afterrender: function(combo) { 
                            combo.setValue( this.defaultValue );
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                //Added for the story BAC-2322
                me.add({
                    xtype: 'checkbox', 
                    boxLabel: TS.T("TAG049","Include in Output Document"),
                    name: 'includeInOpDoc',
                    id: SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c',
                    anchor: '50%',
                    padding: '0 0 15',
                    hidden: true
                });

                //Added for the story BAC-2322
                me.add({
                    xtype: 'checkbox', 
                    boxLabel: TS.T("TAG050","Description required"),
                    name: 'descriptionRequired',
                    id: SVMX.OrgNamespace+'__SM_Description_Required__c',
                    anchor: '50%',
                    padding: '0 0 15',
                    hidden: true
                });

                var responseSet = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'responseSetName', 'responseSetValues'],
                    data: []
                });

                this.__responseSetStore = responseSet;

                this.__responseSetDropDown = me.add({
                    xtype: 'combobox', padding: '0 0 15', 
                    hidden: 'true',
                    id: SVMX.OrgNamespace+'__Response_Set__c',
                    name: 'responseSetName', fieldLabel: TS.T("TAG035","Response Set"),
                    labelField:'label', valueField:'Id', displayField: 'responseSetName', defaultValue: 'CreateNew', value: 'CreateNew',
                    queryMode: 'local', editable: false, anchor: '50%',
                    store: responseSet,
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            if(newValue === 'CreateNew'){
                                me.showHideNewResponseSetName(true);
                                me.__activeRecord.responseOptions = [""];
                                me.showResponseOptions(true);
                            }else{
                                var responseValues = [""];
                                var store = me.__responseSetDropDown.store;
                                var Items = store.data.items || [];
                                for(var i = 0; i < Items.length; i++){
                                    var tempData = Items[i].data;
                                    if(tempData.Id === newValue){
                                        me.__newResponseSetName.setValue(tempData.responseSetName);//Setting value in response set text box
                                        responseValues = tempData.responseSetValues && tempData.responseSetValues.split(";");
                                        if(responseValues && responseValues.length>0)
                                            responseValues.splice(responseValues.length-1, 1);
                                        break;
                                    }
                                }
                                me.__activeRecord.responseOptions = responseValues;
                                me.showResponseOptions(true);
                                //me.showHideNewResponseSetName(false);
                            }
                        },  
                        afterrender: function(combo) {
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.__newResponseSetName = me.add({
                    fieldLabel: TS.T("TAG036","Response Set Name"), name: 'newResponseSetName',
                    id: 'Name',
                    anchor: '50%', allowBlank: false, padding: '0 0 15',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required")
                });
                
                me.add(basicBoxselect);

                //-------Start---------Added for the story BAC-2303
                var clearDefault = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    id:'clearDefault',
                    text: TS.T("TAG052", "Clear Default"),
                    __parent: this, //Added for the story BAC-2301
                    //This is commented for fixing defect BAC-3578 as it is not needed
                    //anchor: '11%', //Changed for defect BAC-3361 fix
                    style: {
                        marginLeft: '0px',
                        marginRight: '0px',
                        marginTop: '10px',
                        marginBottom: '5px'
                    },
                    handler: function() {
                        //Here condition is added to fix defect BAC-3365
                        var answerTypeValue = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                        switch(answerTypeValue){
                            case 'Text':
                                Ext.getCmp('defaultResponseText').reset();
                                break;
                            case 'Number':
                                Ext.getCmp('defaultResponseNumber').reset();
                                break;
                            case 'Date':
                            case 'DateTime':
                                Ext.getCmp('valueFunctionCombo').reset();
                                Ext.getCmp('defaultResponseDate').reset();
                                Ext.getCmp('literalCombo').reset();
                                break;

                            //-------Start---------Added for the story BAC-2301
                            case 'Radio Button':
                            case 'Picklist':
                                var answerPanelItems = this.__parent.__responseOptionsPanel.__fields, l = answerPanelItems.length;
                                for(var i=0; i<l; i++){
                                    var radioButtonId = answerPanelItems[i].radioField.getId();
                                    if(radioButtonId != null){
                                        var radioCmp = Ext.getCmp(radioButtonId);
                                        //Here condition is added for fixing BAC-3399 defect
                                        if(radioCmp){
                                            radioCmp.setValue(false);
                                        }
                                    }
                                }
                            //-------End---------Added for the story BAC-2301

                            //------Start-----Added for the story BAC-2302
                            case 'Multi-select Picklist':
                            case 'Checkbox':
                                var answerPanelItems = this.__parent.__responseOptionsPanel.__fields, l = answerPanelItems.length;
                                for(var i=0; i<l; i++){
                                    var checkboxFieldId = answerPanelItems[i].checkboxField.getId();
                                    if(checkboxFieldId != null){
                                        var checkboxCmp = Ext.getCmp(checkboxFieldId);
                                        //Here condition is added for fixing BAC-3399 defect
                                        if(checkboxCmp){
                                            checkboxCmp.setValue(false);
                                        }
                                    }
                                }
                            //------End-----Added for the story BAC-2302
                        }
                    }
                });
                //me.add(clearDefault); This is commented for fixing defect BAC-3578
                //----Start------//Below code is added for fixing defect BAC-3578 by adding panel in page and
                //inside the panel added the button for auto width
                var clearDefaultButtonPanel = Ext.create("Ext.form.Panel",{
                    layout: 'vbox', border: false, anchor: '50%'
                });
                clearDefaultButtonPanel.add(clearDefault);
                me.add(clearDefaultButtonPanel);
                //------End--------//

                //-------End---------Added for the story BAC-2303
                
                this.radioButton = me.add({
                    xtype: 'radiogroup',
                    id: 'operationTypeCmp', //Added for the story BAC-2301
                    columns: 1,
                    vertical: true,
                    items: [{ 
                        boxLabel: TS.T("TAG037","Update library (all checklists using this question will be updated)"), 
                        name: 'Operationtype', inputValue: 'SAVE', checked: true
                    },{ 
                        boxLabel: TS.T("TAG038","Save as a new question in the library"), 
                        name: 'Operationtype', inputValue: 'SAVEAS'
                    }],
                    listeners: {
                        change: function( rgroup, newValue, oldValue, eOpts ){
                            me.__actionType = newValue.Operationtype;
                        }
                    }
                });
                
                this.showResponseOptions();
            },

            //Added for the story BAC-2300
            hideAllDefaultAnsCmp: function(){
                Ext.getCmp('defaultResponseText').hide();
                Ext.getCmp('defaultResponseNumber').hide();
                Ext.getCmp('valueFunctionCombo').hide();
                Ext.getCmp('defaultResponseDate').hide();
                Ext.getCmp('literalCombo').hide();
            },

            //Added for the story BAC-2300
            resetAndShowCmp: function(cmpId){
                var cmp = Ext.getCmp(cmpId);
                cmp.reset();
                cmp.show();
            },

            //Added for the story BAC-2322
            showHideOpdocDescriptionFields: function(isShow){
                var showInOpdocCmp = Ext.getCmp(SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c');
                var descriptionRequiredCmp = Ext.getCmp(SVMX.OrgNamespace+'__SM_Description_Required__c');
                if(isShow){
                    showInOpdocCmp.setValue(true);
                    descriptionRequiredCmp.setValue(true);
                    showInOpdocCmp.show();
                    descriptionRequiredCmp.show();
                }
                else{
                    showInOpdocCmp.setValue(false);
                    descriptionRequiredCmp.setValue(false);
                    showInOpdocCmp.hide();
                    descriptionRequiredCmp.hide();
                }
            },

            showHideResponseSetDropDown: function(isShow){
                if(isShow){
                    this.__responseSetDropDown.reset();
                    this.__responseSetDropDown.show();
                }
                else
                    this.__responseSetDropDown.hide();
            },

            showHideNewResponseSetName: function(isShow){
                if(isShow){
                    this.__newResponseSetName.reset();
                    this.__newResponseSetName.show();
                }
                else
                    this.__newResponseSetName.hide();
            },

            showResponseOptions: function(isShow){
                if(this.__responseOptionsPanel) this.__responseOptionsPanel.destroy();
                if(!isShow) return;

                this.__responseOptionsPanel = SVMX.create('com.servicemax.client.qbm.ui.desktop.editQuestion.ResponseOptionsPanel', {
                    data: (this.__activeRecord && this.__activeRecord.responseOptions) || null,
                    defaultValueForRadio: (this.__activeRecord && this.__activeRecord.defaultValueForRadio) || null, //Added for the story BAC-2301
                    defaultValueForCheckbox: (this.__activeRecord && this.__activeRecord.defaultValueForCheckbox) || null //Added for the story BAC-2302
                });

                //Changed to fix defect BAC-3578 for setting correct position
                //var ind = (!this.radioButton.hidden && this.items.length-2) || this.items.length-2; 
                var ind = (!this.radioButton.hidden && this.items.length-3) || this.items.length-3;
                this.add(ind, this.__responseOptionsPanel);
            },

            loadQuestionDataInEditMode: function(isEditMode, record){
                //this.resetData();
                this.resetComponentData(); //Added for the story BAC-2301
                
                //Added for the story BAC-2322
                if(record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'] === 'Attachment'){
                    this.showHideOpdocDescriptionFields(true);
                }
                else{
                    this.showHideOpdocDescriptionFields(false);
                }

                this.showHideNewResponseSetName(false);
                if(!isEditMode){
                    this.showResponseOptions(false);
                    this.showHideResponseSetDropDown(false);
                }

                //-------Start---------Added for the story BAC-2303
                this.hideAllDefaultAnsCmp();
                this.resetAndShowCmp('defaultResponseText');
                var answerType = record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'];
                if(answerType === 'Date' || answerType === 'DateTime'){
                    this.resetAndShowCmp('valueFunctionCombo');
                    if(record['valueFunctionCombo'] && record['valueFunctionCombo'] === 'Value'){
                        this.resetAndShowCmp('defaultResponseDate');
                    }
                    else if(record['valueFunctionCombo'] && record['valueFunctionCombo'] === 'Function'){
                        this.resetAndShowCmp('literalCombo');
                    }
                }
                //-------End---------Added for the story BAC-2303

                //-------Start------Added for the defect BAC-3361 fix
                if(answerType === 'Attachment'){
                    Ext.getCmp('clearDefault').hide();
                }
                else{
                    Ext.getCmp('clearDefault').show();   
                }
                //-------End------Added for the defect BAC-3361 fix

                this.__activeRecord = record;
                this.getForm().setValues(record);

                //Added for fixing issue (After opening picklist question then open text question in edit mode it shows the answers panel which should not come in text question)
                if(record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'] === 'Text'){
                    this.showResponseOptions(false);
                }

                if(isEditMode) this.__actionType = "SAVE";
                else this.__actionType = "SAVEAS";
            },

            //Added for the story BAC-2301 for reseting all the component value before loading new data
            resetComponentData: function(){
                Ext.getCmp(SVMX.OrgNamespace+'__Question__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__QuestionID__c').reset();
                Ext.getCmp('defaultResponseText').reset();
                Ext.getCmp('defaultResponseNumber').reset();
                Ext.getCmp('valueFunctionCombo').reset();
                Ext.getCmp('defaultResponseDate').reset();
                Ext.getCmp('literalCombo').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__Help_URL__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__SM_Description_Required__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').reset();
                Ext.getCmp('tagsList').reset();
                Ext.getCmp('operationTypeCmp').reset();
            },

            getData: function(){
                var data = this.getForm().getFieldValues();
                data.Operationtype = this.__actionType;

                if(this.__actionType === "SAVE"){
                    data.Id = this.__activeRecord.Id;
                }

                return data;
            },

            resetData: function() {
                this.getForm().reset();
            },

            getActionType:  function(){
                return this.__actionType;
            }
        });

        Ext.define("com.servicemax.client.qbm.ui.desktop.editQuestion.ResponseOptionsPanel", { 
            extend: 'Ext.form.FieldSet',
 
           constructor: function(config) {

                config = Ext.apply({
                    title: TS.T("TAG039","Answer Values"), 
                    layout: 'vbox', border: true, anchor: '50%'
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function(){
                this.callParent(arguments);
                var me = this;

                this.__addButton = me.add({
                    xtype: 'button', text: '+'+TS.T("TAG040","Add Answer"), anchor: '10%', margins: '8 8',
                    disabled: true,
                    listeners: {
                        click: function(){
                            me.addOption();
                            me.__addButton.setDisabled(true);
                            me.__disableDeleteButton();
                        }
                    }
                });

                this.__fields = [];

                var localDefaultValueForRadio = this.defaultValueForRadio; //Added for the story BAC-2301
                var localDefaultValueForCheckbox = this.defaultValueForCheckbox; //Added for the story BAC-2302
                var data = this.data || [""],
                    i, l = data.length, 
                    item;

                for(i=0; i<l; i++){
                    item = data[i];
                    //me.addOption(item);
                    me.addOption(item, localDefaultValueForRadio, localDefaultValueForCheckbox); //Added for the story BAC-2301
                }

                this.__disableDeleteButton();
            },

            //addOption: function(item){
            addOption: function(item, localDefaultValueForRadio, localDefaultValueForCheckbox){    //Added for the story BAC-2301
                var me = this;
                item = item || "";

                //-----Start-------Added for the story BAC-2301
                var checkStatusForRadio = false;
                if(item === localDefaultValueForRadio){
                    checkStatusForRadio = true;
                }
                var answerType = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                //-----End-------Added for the story BAC-2301

                //------Start-----Added for the story BAC-2302
                var checkStatusForCheckbox = false;
                if(localDefaultValueForCheckbox != null && localDefaultValueForCheckbox.length > 0){
                    var len = localDefaultValueForCheckbox.length;
                    for(var i=0; i<len; i++){
                        if(item === localDefaultValueForCheckbox[i]){
                            checkStatusForCheckbox = true;
                            break;
                        }
                    }
                }
                //------End-----Added for the story BAC-2302

                var mainPanel = this.add(this.items.length-1, {
                    layout: 'hbox', width: '100%', border: false, flex: 1, padding: '8 8'
                });

                var fld = mainPanel.add({
                    xtype: 'textfield', name: 'answers', flex:0.9, allowBlank: false, padding: '0 5',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required"),
                    value: item,
                    listeners:{ 
                        change: function(){
                            var answerType = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                            if(answerType === 'Radio Button' || answerType === 'Picklist'){
                                me.__setValueOfRadio(); //Added for the story BAC-2301
                            }
                            me.__addButton.setDisabled(!me.__isValid());
                        }
                    }
                });

                //------Start-----Added for the story BAC-2302
                var checkboxFieldForDefaultAns = Ext.create('Ext.form.field.Checkbox',{
                    name: 'defaultAnsForCheckbox', boxLabel: TS.T("TAG053","Default"), 
                    //flex:0.2, //Commented for the defect BAC-3420 fix
                    value: item, 
                    checked: checkStatusForCheckbox
                });
                if(answerType === 'Checkbox' || answerType === 'Multi-select Picklist'){
                    mainPanel.add(checkboxFieldForDefaultAns);
                }
                //------End-----Added for the story BAC-2302

                //--------Start-------Added for the story BAC-2301
                var radioFieldForDefaultAns = Ext.create('Ext.form.field.Radio',{
                    xtype: 'radiofield', name: 'defaultAnsForRadio', boxLabel: TS.T("TAG053","Default"), 
                    //flex:0.2, //Commented for the defect BAC-3420 fix
                    inputValue: item, 
                    checked: checkStatusForRadio,
                    listeners:{ 
                        change: function(cmpRadio, newValue, oldValue, eOpts){
                            me.__setValueOfRadio();
                        }
                    }
                });
                if(answerType === 'Radio Button' || answerType === 'Picklist'){
                    mainPanel.add(radioFieldForDefaultAns);
                }
                //--------End-------Added for the story BAC-2301

                var btn = mainPanel.add({
                    xtype: 'button', name: 'del', text: 'X', flex:0.1,
                    margin: '0 0 0 5', //Added for the defect BAC-3420 fix
                    listeners:{ 
                        click: function(){
                            mainPanel.destroy();   
                            me.__disableDeleteButton(true);
                        }
                    }
                });

                //this.__fields.push({fld: fld, btn: btn});
                this.__fields.push({fld: fld, btn: btn, radioField: radioFieldForDefaultAns, checkboxField: checkboxFieldForDefaultAns}); //Modified for the story BAC-2301
            },

            //Added for the story BAC-2301
            __setValueOfRadio: function(){
                var items = this.__fields, l = items.length;
                for(var i =0; i<l; i++){
                    items[i].radioField.inputValue = items[i].fld.getValue();
                }
            },

            __isValid: function(){
                var items = this.__fields,
                    i, l = items.length,
                    item;

                for(i = 0; i < l; i++){
                    item = items[i];
                    if(item && !item.fld.isDestroyed && !item.fld.getValue()){
                        return false;
                    }
                }
                return true;
            },

            __disableDeleteButton: function(){
                var items = this.__fields,
                    i, l = items.length,
                    item, btn, count = 0;

                for(i = 0; i < l; i++){
                    item = items[i];
                    if(item && !item.btn.isDestroyed){
                        item.btn.setDisabled(false);
                        if(!count) btn = item.btn;
                        count++;
                    }
                }

                if(count === 1 && btn) btn.setDisabled(true);
                this.__addButton.setDisabled(!this.__isValid());
            }
        });
    }
})();
