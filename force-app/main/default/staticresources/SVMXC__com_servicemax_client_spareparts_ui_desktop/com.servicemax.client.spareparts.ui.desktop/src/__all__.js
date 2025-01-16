// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spareparts.ui.desktop\src\api.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spareparts.ui.desktop.api");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");

        Ext.define("com.servicemax.client.spareparts.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'spareparts-root-container', // ToDo : Talk to Jessie to create the class
            width: '100%',
            id:'spareparts',
            layout: 'anchor',
            constructor: function (config) {
                config = Ext.apply({
                    title: TS.T('TAG001', 'Spare Parts Setup'),
                    titleAlign: 'center', collapsible: false,
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            cls : "spareparts-back-btn",
                            padding: '0', //scale: "medium",
                            text : TS.T('TAG002', 'Back to Setup Home'),
                            handler: function(e, el, owner, tool) {
                                var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                if((typeof sforce != 'undefined') && (sforce != null)){
                                    urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup"; //Added for the story BAC-4797
                                    sforce.one.navigateToURL(urlString);
                                }
                                else{
                                    window.location.href = urlString;
                                }
                            }
                        }]
                    },
                }, config || {});

                this.callParent(arguments);
            },
            initComponent: function() {

                this.callParent(arguments);

                var me = this;

                var sparepartsToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "top",
                    autoHeight: true,
                });

                var tabFill = SVMX.create("Ext.Toolbar.Fill",{ });
                sparepartsToolBar.add(tabFill);

                me.profilePicklistStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data: this.__engine.__profileData != null ? this.__engine.__profileData: [],
                });

                var profilePicklist = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'profilePicklist', name: 'profilePicklistName',
                    fieldLabel: TS.T("TAG003",'Select Profile'),
                    labelField:'label', valueField:'Id',
                     width: 350,
                    cls: 'spareparts-select-profile',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    queryMode: 'local', store: me.profilePicklistStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners:{
                        select: function( combo, records, eOpts ){
                            var parentCmp = Ext.getCmp('spareparts');

                            // Enable all the field sets and Enable locate part
                            Ext.getCmp('firstFieldSetForFields').setDisabled(false);
                            Ext.getCmp('secondFieldSetForFields').setDisabled(false);
                            Ext.getCmp('enableLocatePart').setDisabled(false);

                            Ext.getCmp('locatePartLabel').show();
                            Ext.getCmp('mobileInvLink').show();

                            // Always default Location type to Field

                            Ext.getCmp('enableDescriptionField').setValue(false);
                            Ext.getCmp('enableAttachmentField').setValue(false);

                            var distanceStoreArray = [];
                            var milesObj = {'Id': 'miles', 'name': TS.T("TAG045", 'Miles')};
                            var KilometerObj = {'Id': 'kilometer', 'name': TS.T("TAG046", 'kilometer')}; 
                            distanceStoreArray.push(milesObj, KilometerObj);

                            parentCmp.distanceStore.loadData(distanceStoreArray);

                            parentCmp.__engine.getSparePartConfig(records[0].data.Id, function(result){
                                if(result.success){

                                    // Defect Fix 
                                    var productPicklistValuesLoad = [];

                                    // For Description Create a new Value
                                    var detailDescriptionStore = [];
                                    var detailAttachmentStore = [];

                                    result.listproductfields.forEach(function (object, index){
                                        if(object.fieldtype.toLowerCase() == 'string' ){
                                           detailDescriptionStore.push(object);
                                           detailAttachmentStore.push(object);
                                        }

                                        if(object.fieldtype.toLowerCase() == 'textarea'){
                                            detailDescriptionStore.push(object);
                                        }
                                        else{
                                            productPicklistValuesLoad.push(object);
                                        }


                                    });

                                    // Load productFieldsPicklist Values
                                    parentCmp.productPicklistValues.loadData(productPicklistValuesLoad);
                                    parentCmp.descriptionPicklistValues.loadData(detailDescriptionStore);
                                    parentCmp.attachmentPicklistValues.loadData(detailAttachmentStore);



                                    // Default values of the Parts fields
                                    Ext.getCmp('columnone').setValue('Name');
                                    Ext.getCmp('columntwo').setValue('ProductCode');
                                    Ext.getCmp('columnthree').setValue('Family');
                                    Ext.getCmp('columnfour').setValue(SVMX.OrgNamespace +'__Product_Line__c');

                                    Ext.getCmp('columnDetailone').setValue('Name');
                                    Ext.getCmp('columnDetailtwo').setValue('ProductCode');
                                    Ext.getCmp('columnDetailthree').setValue('Family');
                                    Ext.getCmp('columnDetailDescription').setValue('');
                                    Ext.getCmp('columnDetailAttachment').setValue('');


                                    // populate Locate Part
                                    Ext.getCmp('enableLocatePart').setValue(result.locatepartsetup.isenabled);


                                    if(result.locatepartsetup.radius == null || result.locatepartsetup.radius == ''){
                                        Ext.getCmp('searchRadius').setValue('0');
                                        Ext.getCmp('distanceStorePicklist').setValue('miles');
                                    }
                                    else{
                                        Ext.getCmp('searchRadius').setValue(result.locatepartsetup.radius);
                                        Ext.getCmp('distanceStorePicklist').setValue(result.locatepartsetup.distanceinunit);
                                    }

                                    parentCmp.locationTypeStore.loadData(result.locatepartsetup.listlocationtype);

                                    // Update it with Default Value
                                    Ext.getCmp('locationTypePicklist').setValue('Field');

                                    if(result.locatepartsetup != null && result.locatepartsetup.locationtype != null && result.locatepartsetup.locationtype != ''){
                                        Ext.getCmp('locationTypePicklist').setValue(result.locatepartsetup.locationtype);
                                    }


                                    parentCmp.inventoryProcessStore.loadData(result.liststockinventoryprocess);
                                    // Anchal - Fix for Defect  BAC-2651; Load the picklist value afer loading the data
                                    Ext.getCmp('inventoryProcessPicklist').setValue(result.locatepartsetup.inventoryprocess);


                                    
                                    // Loop through the array to set values of column.
                                    if(result.layout != null && result.layout.partsfields != null && result.layout.partsfields != '' && result.layout.partsfields != []){
                                        result.layout.partsfields.forEach(function (object, index){
                                            if (object.sequence == 1)
                                                Ext.getCmp('columnone').setValue(object.fieldname);

                                            if (object.sequence == 2)
                                                Ext.getCmp('columntwo').setValue(object.fieldname);

                                            if (object.sequence == 3)
                                                Ext.getCmp('columnthree').setValue(object.fieldname);

                                            if (object.sequence == 4)
                                                Ext.getCmp('columnfour').setValue(object.fieldname);
                                        });
                                    }

                                    if(result.layout != null && result.layout.partsdetailfields != null && result.layout.partsdetailfields != '' && result.layout.partsdetailfields != []){
                                        result.layout.partsdetailfields.forEach(function (object, index){
                                            if (object.sequence == 1){
                                                Ext.getCmp('columnDetailone').setValue(object.fieldname);
                                            }

                                            if (object.sequence == 2){
                                                Ext.getCmp('columnDetailtwo').setValue(object.fieldname);
                                            }

                                            if (object.sequence == 3){
                                                Ext.getCmp('columnDetailthree').setValue(object.fieldname);
                                            }

                                            if (object.sequence == 4){

                                                var descCmp =  Ext.getCmp('columnDetailDescription')
                                                descCmp.setValue(object.fieldname);

                                                if(descCmp.getValue() != null && descCmp.getValue() != ''){
                                                    Ext.getCmp('enableDescriptionField').setValue(true);
                                                }
                                            }
                                        });
                                    }

                                    if(result.layout != null && result.layout.attachmentfilename != null && result.layout.attachmentfilename != ''){
                                        Ext.getCmp('columnDetailAttachment').setValue(result.layout.attachmentfilename);
                                        Ext.getCmp('enableAttachmentField').setValue(true);
                                    }

                                    // Load download criteia values:
                                    var downloadCretiaSection = Ext.getCmp('downloadRulePanelCmp');
                                    downloadCretiaSection.loadData (result.listproductstockstatus, result.listquantityfields, result.layout != null ? result.layout.downloadcriteria: '');

                                    Ext.getCmp('saveBtn').setDisabled(false);
                                }
                                else{
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messagelist[0]), 7000, 'success');
                                }
                            });

                            
                        }
                    }
                });


                sparepartsToolBar.add(profilePicklist);

                var tabFill = SVMX.create("Ext.Toolbar.Fill",{ });
                sparepartsToolBar.add(tabFill);

                var saveBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: TS.T("TAG011",'Save'), //Icon Class for lookup button,
                    scale: 'medium',
                    style: 'margin-left: 3px !important',
                    cls: 'spareparts-save-btn',
                    height: 30,
                    disabled: true,
                    id: 'saveBtn',
                    handler: function() {
                        var markInvalidData = false;

                        var config = {};
                        config.profileId = Ext.getCmp('profilePicklist').getValue();
                        config.locatepartsetup = {};
                        config.locatepartsetup.isenabled = Ext.getCmp('enableLocatePart').getValue();
                        config.locatepartsetup.radius = Ext.getCmp('searchRadius').getValue();

                        //BAC-3400 Field' value is still been selected even after clearing the multi-picklist values for 'Location Type' field.
                        // Make locationTypePicklist a required field to be populated.

                        var locationTypePicklistValue = Ext.getCmp('locationTypePicklist').getValue();

                        if(locationTypePicklistValue != null && locationTypePicklistValue != ''){
                            config.locatepartsetup.locationtype = Ext.getCmp('locationTypePicklist').getValue();
                        }
                        else{
                            Ext.getCmp('locationTypePicklist').markInvalid(TS.T("TAG044", 'Location Type is mandatory'));
                            markInvalidData = true;
                        }


                        config.locatepartsetup.inventoryprocess = Ext.getCmp('inventoryProcessPicklist').getValue();
                        config.locatepartsetup.distanceinunit = Ext.getCmp('distanceStorePicklist').getValue();

                        // Put in layout
                        config.layout = {};
                        config.layout.partsfields= [];
                        var recordColumnone = me.picklistRecord('columnone', '1', false, 'productPicklistValues');
                        if(recordColumnone == null){
                            Ext.getCmp('columnone').markInvalid(TS.T("TAG032", 'Column 1 is mandatory'));
                            markInvalidData = true;
                        }
                        else{
                            config.layout.partsfields.push(recordColumnone);
                        }


                        var recordColumntwo = me.picklistRecord('columntwo', '2', false, 'productPicklistValues');
                        if(recordColumntwo != null){
                            config.layout.partsfields.push(recordColumntwo);
                        }
                        else{
                            Ext.getCmp('columntwo').markInvalid(TS.T("TAG032", 'Column 2 is mandatory'));
                            markInvalidData = true;
                        }


                        var recordColumnthree = me.picklistRecord('columnthree', '3', false, 'productPicklistValues');
                        if(recordColumnthree != null){
                            config.layout.partsfields.push(recordColumnthree);
                        }
                        else{
                            Ext.getCmp('columnthree').markInvalid(TS.T("TAG032", 'Column 3 is mandatory'));
                            markInvalidData = true;
                        }

                        var recordColumnfour = me.picklistRecord('columnfour', '4', false, 'productPicklistValues');
                        if(recordColumnfour != null){
                            config.layout.partsfields.push(recordColumnfour);
                        }
                        else{
                            Ext.getCmp('columnfour').markInvalid(TS.T("TAG032", 'Column 4 is mandatory'));
                            markInvalidData = true;
                        }


                        config.layout.partsdetailfields= [];
                        var recordDetailsColumnone = me.picklistRecord('columnDetailone', '1', true, 'productPicklistValues');
                        if(recordDetailsColumnone != null){
                            config.layout.partsdetailfields.push(recordDetailsColumnone);
                        }
                        else{
                            Ext.getCmp('columnDetailone').markInvalid(TS.T("TAG032", 'Title is mandatory'));
                            markInvalidData = true;
                        }

                        var recordDetailsColumntwo = me.picklistRecord('columnDetailtwo', '2', true, 'productPicklistValues');
                        if(recordDetailsColumntwo != null){
                            config.layout.partsdetailfields.push(recordDetailsColumntwo);
                        }
                        else{
                            Ext.getCmp('columnDetailtwo').markInvalid(TS.T("TAG032", 'Detail 1 is mandatory'));
                            markInvalidData = true;
                        }


                        var recordDetailsColumnthree = me.picklistRecord('columnDetailthree', '3',true, 'productPicklistValues');
                        if(recordDetailsColumnthree != null){
                            config.layout.partsdetailfields.push(recordDetailsColumnthree);
                        }
                        else{
                            Ext.getCmp('columnDetailthree').markInvalid(TS.T("TAG032", 'Detail 2 is mandatory'));
                            markInvalidData = true;
                        }

                        var recordDescription = me.picklistRecord('columnDetailDescription', '4', false, 'descriptionPicklistValues');
                        if(recordDescription != null){
                            config.layout.partsdetailfields.push(recordDescription);
                        }
                        else{
                            if(Ext.getCmp('enableDescriptionField').getValue()){
                                Ext.getCmp('columnDetailDescription').markInvalid(TS.T("TAG032", 'Description field is mandatory'));
                                markInvalidData = true;
                            }
                        }


                        config.layout.downloadcriteria = [];

                        var downLoadCriteriaStore = Ext.getCmp('sparePartsGrid').getStore();
                        downLoadCriteriaStore.data.items.forEach(function(obj){
                            if(obj.data.productstockstatus != '' && obj.data.productstockstatus != null){
                                config.layout.downloadcriteria.push(obj.data);
                            }
                            else{
                                markInvalidData = true;
                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG033", 'Enter Product Stock Status'), 7000, 'success');
                            }
                        });

                        // Add value for attachment as well.
                        if(Ext.getCmp('enableAttachmentField').getValue()){

                            if(Ext.getCmp('columnDetailAttachment').getValue() != null && Ext.getCmp('columnDetailAttachment').getValue() != ''){
                                config.layout.attachmentfilename = Ext.getCmp('columnDetailAttachment').getValue();
                            }
                            else{
                                Ext.getCmp('columnDetailAttachment').markInvalid(TS.T("TAG032", 'Attachment field is mandatory'));
                                markInvalidData = true;
                            }
                        }


                        if(!markInvalidData){
                            me.__engine.saveSparePartConfig(config, function(result){
                                if(!result.success){
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messagelist[0]), 7000, 'success');
                                }
                                else{
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG023", 'Save Successful'), 7000, 'success');
                                }
                            });
                        }

                    }
                });

                var cancelBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: TS.T("TAG010",'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    style: 'margin-left: 3px !important',
                    cls: 'spareparts-cancel-btn',
                    height: 30,
                    handler: function() {
                        var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location.href = urlString;
                        }
                    }
                });

                sparepartsToolBar.add(saveBtn);

                sparepartsToolBar.add(cancelBtn);

                sparepartsToolBar.add({
                    //iconCls : 'spareparts-help-icon ',
                    cursor:'pointer',
                    scale : 'large',
                    cls: 'spareparts-help',
                    tooltip: TS.T("TAG038", 'Spare parts help link'),
                    href: TS.T("TAG039", 'http://helplink'),
                    width: 32,
                    height: 32,
                    margin: '0 0 0 15px',
                });

                me.add(sparepartsToolBar);

                var enableLocatePart = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckbox", {
                    labelSeparator: '',
                    name: 'enableLocatePart',
                    id: 'enableLocatePart',
                    boxLabelAlign: 'before',
                    boxLabel: TS.T("TAG006", "Enable Locate Part"),
                    width: 'calc(25% + 20px)',
                    cls: 'spareparts-checkbox-label',
                    disabled: true,
                    listeners:{
                        change: function(cmp, value) {
                            if(!value){
                                // remove the field values
                                Ext.getCmp('searchRadius').setValue('0');
                                Ext.getCmp('locationTypePicklist').setValue('Field');
                                Ext.getCmp('inventoryProcessPicklist').setValue('');
                                Ext.getCmp('distanceStorePicklist').setValue('miles');
                            }

                            Ext.getCmp('searchRadius').setDisabled(!value);
                            Ext.getCmp('locationTypePicklist').setDisabled(!value);
                            Ext.getCmp('inventoryProcessPicklist').setDisabled(!value);
                            Ext.getCmp('distanceStorePicklist').setDisabled(!value);

                        }
                    }
                });

                var locatePartLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel", {
                    text: TS.T("TAG036",'For this feature to work, "Enable Location Tracking" under Mobile Configuration should be True'),
                    cls: 'spareparts-checkbox-note',
                    hidden:true,
                    id: 'locatePartLabel'
                });

                var mobileInvLink = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel", {
                    html: '<a href="/apex/'+ SVMX.OrgNamespace+ '__CONF_MobileConfig" target = "_blank" class="spareparts-view-configuration">' + TS.T("TAG037",'View Mobile Configuration Setup')+ '</a><br/>' ,
                    hidden:true,
                    id: 'mobileInvLink'
                });

                var searchRadius = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXNumber", {
                    labelSeparator: '',
                    name: 'searchRadius',
                    id: 'searchRadius',
                    disabled: !(Ext.getCmp('enableLocatePart').getValue()),
                    
                    minValue: 0,
                    enforceMaxLength: true,
                    maxLength: 4,
                    fieldLabel: TS.T("TAG007", "Set Part Search Radius")
                });

                me.distanceStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                // BAC-3587- Adding editable: false to all columns in Layout to allow user to only select the picklist values.
                var distanceStorePicklist = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'distanceStorePicklist', name: 'distanceStorePicklist',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    editable: false,
                    disabled: !(Ext.getCmp('enableLocatePart').getValue()),
                    queryMode: 'local', store: me.distanceStore,

                });

                var radius = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    //bodyPadding: 10,
                    layout: 'column',
                    cls: 'spareparts-input-container',
                    width: '50%',
                    columns: 2,
                    header: false,
                    border: false,
                    items: [searchRadius,distanceStorePicklist],
                });

                me.locationTypeStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                // Anchal; Fix for defect BAC-3320; Extending Picklist to create new component SparePartsMultiSelectPicklist
                // BAC-3587- Adding editable: false to all columns in Layout to allow user to only select the picklist values.
                var locationTypePicklist = SVMX.create("com.servicemax.client.spareparts.ui.desktop.editors.SparePartsMultiSelectPicklist", {
                    id: 'locationTypePicklist',
                    name: 'locationTypePicklist',
                    cls: 'spareparts-input-container location-type-for-part-search',
                    width: '50%',
                    fieldLabel: TS.T("TAG008",'Select Location Type for Part Search'),
                    labelField:'label',
                    valueField:'Id',
                    displayField: 'name',
                    defaultAlign: 'center',
                    editable: false,
                    multiSelect: true,
                    msgTarget : 'under',
                    disabled: !(Ext.getCmp('enableLocatePart').getValue()),
                    store: me.locationTypeStore,

                });

                me.inventoryProcessStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                // BAC-3587- Adding editable: false to all columns in Layout to allow user to only select the picklist values.
                var inventoryProcessPicklist = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'inventoryProcessPicklist',
                    name: 'inventoryProcessPicklist',
                    cls: 'spareparts-input-container',
                    width: '50%',
                    fieldLabel: TS.T("TAG009",'Select Stock Transfer Inventory Transaction'),
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    multiSelect: false,
                    editable: false,
                    disabled: !(Ext.getCmp('enableLocatePart').getValue()),
                    queryMode: 'local', store: me.inventoryProcessStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                // Anchal, Fix for defect - BAC-2944. Updating the position for View Configuration Link.
                var locatePart = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    title: TS.T("TAG004", "Setup"),
                    id:'locatePart',
                    bodyPadding: 10,
                    items: [enableLocatePart, locatePartLabel, mobileInvLink, radius, locationTypePicklist, inventoryProcessPicklist],
                });

                var partsTableLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel", {
                    text: TS.T("TAG012",'Parts Table - Used for Trunk Stock and Parts Catalog'),
                });

                me.productPicklistValues = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}, {name: 'fieldtype'}],
                    id: 'productPicklistValues', 
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                // BAC-3587- Adding editable: false to all columns in Layout to allow user to only select the picklist values. 
                var columnone = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnone', name: 'columnone',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG013",'Column 1 - Primary Column'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                var columntwo = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columntwo', name: 'columntwo',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG014",'Column 2'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                var columnthree = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnthree', name: 'columnthree',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG015",'Column 3'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                var columnfour = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnfour', name: 'columnfour',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG016",'Column 4 show only in landscape orientation'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                var partsDetailLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel", {
                    text: TS.T("TAG017",'Parts Detail View'),
                });


                var columnDetailone = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnDetailone', name: 'columnDetailone',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG018",'Title'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                var columnDetailtwo = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnDetailtwo', name: 'columnDetailtwo',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG019",'Detail 1'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                var columnDetailthree = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnDetailthree', name: 'columnDetailthree',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    allowBlank: false,
                    editable: false,
                    msgTarget : 'under',
                    fieldLabel: TS.T("TAG020",'Detail 2'),
                    queryMode: 'local', store: me.productPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });



                var enableDescriptionField = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckbox", {
                    labelSeparator: '',
                    name: 'enableDescriptionField',
                    id: 'enableDescriptionField',
                    boxLabelAlign: 'before',
                    cls: 'spareparts-enable-checklist',
                    boxLabel: TS.T("TAG021", "Include Description"),
                    listeners:{
                        change: function(cmp, value) {
                            if(!value){
                                Ext.getCmp('columnDetailDescription').setValue('');
                            }
                            else{
                                Ext.getCmp('columnDetailDescription').setValue('Description');
                            }
                            Ext.getCmp('columnDetailDescription').setDisabled(!value);
                        }
                    }
                });

                me.descriptionPicklistValues = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}, {name: 'fieldtype'}],
                    id: 'descriptionPicklistValues',
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                var columnDetailDescription = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnDetailDescription', name: 'columnDetailDescription',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    msgTarget : 'under',
                    labelAlign: 'top',
                    editable: false,
                    disabled: true,
                    fieldLabel: TS.T("TAG022",'Description'),
                    queryMode: 'local', store: me.descriptionPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });


                var enableAttachmentField = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckbox", {
                    labelSeparator: '',
                    name: 'enableAttachmentField',
                    id: 'enableAttachmentField',
                    cls: 'spareparts-enable-checklist',
                    boxLabelAlign: 'before',
                    boxLabel: TS.T("TAG034", "Include Attachment"),
                    width: '50%',
                    listeners:{
                        change: function(cmp, value, oldvalue) {
                            if(value && Ext.getCmp('columnDetailAttachment').getValue() == ''){
                                // Anchal, Fix for defect - BAC-2941 (Custom labels for Yes & No, Confirm) & BAC-2944 (Default attachment name is Product Name).
                                Ext.MessageBox.confirm({
                                    title : TS.T("TAG041", "Confirm"),
                                    msg : TS.T("TAG040",'Each attachment will require an individual API call and will contribute towards Salesforce API limits. Do you want to continue?') ,
                                    fn : function(btn){
                                        if(btn == 'yes'){
                                            Ext.getCmp('columnDetailAttachment').setValue('Name');
                                        }
                                        else{
                                            cmp.setValue(false);
                                            value = false;
                                            Ext.getCmp('columnDetailAttachment').setDisabled(true);
                                            Ext.getCmp('columnDetailAttachment').setValue('');
                                        }
                                    },
                                    buttonText :
                                    {
                                        yes : TS.T("TAG042", "Yes"),
                                        no :  TS.T("TAG043", "No"),
                                    },
                                });

                            }

                            if(!value){
                               Ext.getCmp('columnDetailAttachment').setValue('');
                            }

                            Ext.getCmp('columnDetailAttachment').setDisabled(!value);
                        }
                    }
                });


                me.attachmentPicklistValues = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}, {name: 'fieldtype'}],
                    id: 'attachmentPicklistValues',
                    proxy: {
                        type: "memory"
                    },
                    data:[],
                });

                var columnDetailAttachment = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'columnDetailAttachment', name: 'columnDetailAttachment',
                    labelField:'label', valueField:'Id',
                    displayField: 'name',
                    labelSeparator: '',
                    defaultAlign: 'center',
                    labelAlign: 'top',
                    msgTarget : 'under',
                    editable: false,
                    disabled: true,
                    fieldLabel: TS.T("TAG035",'Attachment File Name'),
                    queryMode: 'local', store: me.descriptionPicklistValues,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },

                });

                var firstFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    style: 'top: 10px;',
                    disabled: true,
                    id: 'firstFieldSetForFields',
                    items:[partsTableLabel, columnone, columntwo, columnthree, columnfour]
                };

                var secondFieldSetForFields = {
                    xtype:'fieldset',
                    columnWidth: 0.5,
                    border: false,
                    defaults: {anchor: '100%'},
                    layout: 'anchor',
                    style: 'top: 10px;',
                    disabled: true,
                    id: 'secondFieldSetForFields',
                    items:[partsDetailLabel, columnDetailone, columnDetailtwo, columnDetailthree, enableDescriptionField, columnDetailDescription, enableAttachmentField, columnDetailAttachment]
                };

                var downloadRulePanel = SVMX.create("com.servicemax.client.spareparts.ui.desktop.downloadrule.DownloadrulePanel", {
                    id: 'downloadRulePanelCmp',
                    cls: 'spareparts-downloadRule',
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

                var selectFields = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    id:'selectFields',
                    collapsible: false,
                    region: "center",
                    layout: 'column',
                    border: false,
                    defaults: {
                        bodyPadding: 8,

                    },
                    items: [firstFieldSetForFields, secondFieldSetForFields],
                });

                var downloadCriteria = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    title: TS.T("TAG005", "Layout"),
                    id:'downloadCriteria',
                    collapsible: false,
                    region: "center",
                    layout: 'column',
                    border: false,
                    defaults: {
                        bodyPadding: 8,

                    },
                    items: [selectFields, downloadRulePanel],
                });

                //downloadCriteria.add(downloadRulePanel);

                var setupTabPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXTabPanel", {
                    activeTab: 0,
                    id:'setupTabPanel',
                    anchor:'100% 100%',
                    border: false,
                    defaults: { autoScroll: true, frame: false, border: false, padding: '0 0 0 0' },
                    items:[
                        locatePart, downloadCriteria
                    ],
                });

                me.add(setupTabPanel);

            },
            picklistRecord: function (componentId, sequence, showlabel, storeId){
                var parCmp = Ext.getStore(storeId);
                if(Ext.getCmp(componentId).getValue() != null && Ext.getCmp(componentId).getValue() != ''){
                    var index = parCmp.findExact('Id', Ext.getCmp(componentId).getValue()); // Compares Value from combo to field invoiceid and returns the index
                    if(index != -1){
                        var recordColumn = parCmp.getAt(index);
                        var recordWrapper = {};
                        recordWrapper.showlabel = showlabel;
                        recordWrapper.sequence = sequence;
                        recordWrapper.fieldname = recordColumn.data.Id;
                        recordWrapper.objectname = 'Product2';
                        recordWrapper.fieldtype = recordColumn.data.fieldtype;
                        return recordWrapper;
                    }
                    else
                        return null;

                }
                else {
                    return null;
                }
            },
        });

        // Created Custom definition for adding checkbox to each option in multiselect picklist.
        // This is a CSS addition to existing component.

        Ext.define("com.servicemax.client.spareparts.ui.desktop.editors.SparePartsMultiSelectPicklist",{
            extend: com.servicemax.client.ui.components.controls.impl.SVMXMultiSelectPicklist,
            alias: 'widget.spareparts.multipicklist',
            delimiter: ',',
            selectOnFocus: true,

            constructor: function(config) {
                if (!config)
                    config = {};

                var me = this;
                var width = 450;

                 config = Ext.apply(config, {
                    editable: true,
                    queryMode: 'local',
                    displayField: 'name',
                    valueField: 'Id',
                    editable: false,

                    listConfig: {
                        xtype: 'svmx.listcomposite',
                        hideHeaders: true,

                        selModel: SVMX.create('Ext.selection.CheckboxModel', {
                            checkOnly: false,
                            width: 30,
                            mode: 'SIMPLE',
                        }),

                        columns: [{
                            dataIndex: 'name',
                            width: width,

                            renderer: function(value, metadata, record, rowIndex) {
                                valuesToSelect = me.getValue();

                                if (valuesToSelect != undefined && valuesToSelect != null) {
                                    if (valuesToSelect.indexOf(record.data.Id) > -1) {
                                        this.getSelectionModel().select(rowIndex, true, true);
                                    }
                                }

                                return Ext.String.htmlEncode(value);
                            },

                            menuDisabled: true,
                        }],
                    },
                });

                this.callParent([config]);
            },
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spareparts.ui.desktop\src\downloadrule.js
(function () {
    var appImpl = SVMX.Package("com.servicemax.client.spareparts.ui.desktop.downloadrule");

    appImpl.init = function () {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");


        Ext.define("com.servicemax.client.spareparts.ui.desktop.downloadrule.DownloadrulePanel", {
            extend: 'Ext.form.FormPanel',
            id: 'downloadrule',
            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG024", "Download Criteria")
                },
                config || {});

                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                // Need to update Work Order Purpose List
                this.__downloadCriteriaGrid = SVMX.create("com.servicemax.client.spareparts.ui.desktop.downloadRule.CriteriaGrid", {
                });
                me.add(this.__downloadCriteriaGrid);
            },
            loadData: function(productStatusData, quantityData, griddata ){
                // Load Schedule Grid
                Ext.getCmp('addRowButton').setDisabled(false);   
                var productStatusStore = Ext.getStore('productStockStatus');
                productStatusStore.loadData(productStatusData);

                var quantityStore = Ext.getStore('quantityFields');
                quantityStore.loadData(quantityData);

                var downloadCriteria_store = Ext.getStore('downloadCriteria_store');
                if(griddata == null || griddata == ''){
                    griddata = []; 
                    /*var firstRow= {};
                    firstRow.includeserializedstock = false; 
                    firstRow.productstockstatus = '';
                    firstRow.quantityfield = '';
                    griddata.push(firstRow);*/
                }

                downloadCriteria_store.loadData(griddata);

                // Disbale Add Row button, when length of status picklist values == number of records
                if(productStatusData.length != griddata.length ){
                    Ext.getCmp('addRowButton').setDisabled(false);    
                }
            }
    
        });

        
        Ext.define('com.servicemax.client.spareparts.ui.desktop.downloadRule.CriteriaGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            viewConfig:{
                markDirty:false
            },
            initComponent: function() {

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    listeners: {
                        beforeedit: function(editor, e){
                            //This should work only on 1st column
                            var stockStatusStore = Ext.getStore('productStockStatus');
                            stockStatusStore.clearFilter();
                            if(e.colIdx == 1){
                                // reset all product stock status to default value
                                stockStatusStore.data.items.forEach(function(obj, rowVal){
                                    obj.data.isUsed = false;
                                });

                                var rowIndx = e.rowIdx;
                                // Get the spare parts Grid Store
                                var gridCmp = Ext.getCmp('sparePartsGrid').getStore().data.items;
                                
                                gridCmp.forEach(function(obj, rowVal){
                                    if(rowVal != rowIndx){
                                        var index = stockStatusStore.findExact('Id', obj.data.productstockstatus);
                                        if(index != -1){
                                            // Update Store with value isUsed
                                            stockStatusStore.getAt(index).data.isUsed = true;  
                                        }
                                    }
                                })
                            }
                        },
                    }
                });

                var productStockStatusStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}, {name: 'isUsed'}],
                    id: 'productStockStatus',
                    proxy: {
                        type: "memory"
                    }
                });

                this.productStockCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    typeAhead: true,
                    editable: false,
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: productStockStatusStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners: {
                        expand : function(combo){
                            // Get Spare Parts Grid records 
                            combo.store.filter('isUsed',false);
                        }
                    }
                });

                var quantityFieldsStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    id: 'quantityFields',
                    proxy: {
                        type: "memory"
                    }
                });

                this.quantityFieldCombo = new Ext.form.field.ComboBox({
                    typeAhead: false,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    editable: false,  // Anchal, Fix for defect - BAC-2941. Making all picklist Select non-editable
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: quantityFieldsStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var serializedStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    id: 'serializedStore',
                    proxy: {
                        type: "memory"
                    },
                    data: [
                        {
                            Id : true,
                            name: TS.T("TAG025", "Yes")
                        },
                        {
                            Id : false,
                            name: TS.T("TAG026", "No")
                        }
                    ]
                });

                this.serializedCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    typeAhead: false,
                    editable: false, // Anchal, Fix for defect - BAC-2941. Making all picklist Select non-editable
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: serializedStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
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
                    margin: '5',
                    plugins: [this.cellEditing],
                    id:'sparePartsGrid', 
                    cls: 'spareparts-download-criteria',
                    store: new Ext.data.Store({
                        storeId: 'downloadCriteria_store',
                        fields: [
                            'productstockstatus', 
                            'quantityfield',
                            'includeserializedstock',
                        ],
                    }),
                    columns: [
                            {
                            xtype: 'actioncolumn',
                            width: 40,
                            height: 40,
                            align: 'center',
                            sortable: false,
                            menuDisabled: true,
                            items: [{
                                //icon: 'extjs/examples/shared/icons/fam/cog_edit.png',
                                tooltip: TS.T("TAG027", "Delete"),
                                scope: this,
                                //height: 40,
                                iconCls: 'spareparts-delete-row-icon',
                                cls: 'spareparts-delete-row-icon',
                                handler: this.onRemoveClick
                            }]
                        },
                        { flex: 1, text: TS.T("TAG028", 'Product Stock Status'), dataIndex: 'productstockstatus', align: 'left', resizable: true, readOnly: true, editor: this.productStockCombo, renderer: this.picklistRenderer(this.productStockCombo)}, 
                        { flex: 1, text: TS.T("TAG029", 'Quantity'),dataIndex: 'quantityfield', align: 'left', resizable: true, readOnly: true, editor: this.quantityFieldCombo, renderer: this.picklistRenderer(this.quantityFieldCombo)}, 
                        { flex: 1, text: TS.T("TAG030", 'Include Serialized Stocks'), dataIndex: 'includeserializedstock', align: 'left', resizable: true, readOnly: true, editor: this.serializedCombo, renderer: this.picklistRenderer(this.serializedCombo)}, 
                    ],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG031", "Add Row"),
                        id: 'addRowButton',
                        scope: this,
                        disabled: true,
                        handler: this.onAddClick,
                        cls: 'spareparts-blue-link'
                    }]
                });
                this.callParent();
                
            },
            onAddClick: function(button){
                var recCount = this.getStore().getCount();
                // Before Adding new row to the Grid, check previous mandatory field
                var gridCmp = Ext.getCmp('sparePartsGrid');

                var lastGridRecord = this.getStore().getAt(recCount -1);

                if(lastGridRecord != null && lastGridRecord != ''){
                    if(lastGridRecord.data.productstockstatus == ''){
                        var classAttr = gridCmp.getNode(recCount-1).childNodes[1].getAttribute('class');
                        gridCmp.getNode(recCount-1).childNodes[1].setAttribute('class', classAttr+ ' make-cell-dirty-lt');
                        gridCmp.getNode(recCount-1).childNodes[1].setAttribute('data-qtip', TS.T("TAG032", "This is a required field."));
                    }
                    else{
                        
                        // Before adding new record see, if record count is 1 less than Product Stock Status
                        var stockStatusStore = Ext.getStore('productStockStatus'); 
                        stockStatusStore.clearFilter();
                        var productStockStatusCount = stockStatusStore.getCount();
                        if(recCount < productStockStatusCount){
                            var rec = {
                                productstockstatus: '',
                                quantityfield : '',
                                includeserializedstock: false
                            };
                            this.getStore().insert(recCount, rec); 

                            // Now disable the Add button
                            if(recCount == productStockStatusCount-1){
                                button.setDisabled(true);
                            }
                        }
                    }
                }
                else{
                    var recBlank =   {
                                    productstockstatus: '',
                                    quantityfield : '',
                                    includeserializedstock: false
                                };
                    this.getStore().insert(recCount, recBlank);  
                }
            },
            onRemoveClick: function(grid, rowIndex, aa, bb){
                var store = this.getStore();
                store.removeAt(rowIndex);    
               
                // Enable button all time 
                Ext.getCmp('addRowButton').setDisabled(false);
            }
            
        });

    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spareparts.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.spareparts.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			
        },

        initialize: function() {
        	com.servicemax.client.spareparts.ui.desktop.api.init();
        	com.servicemax.client.spareparts.ui.desktop.downloadrule.init();
        }

	}, {
		instance : null
	});

})();

