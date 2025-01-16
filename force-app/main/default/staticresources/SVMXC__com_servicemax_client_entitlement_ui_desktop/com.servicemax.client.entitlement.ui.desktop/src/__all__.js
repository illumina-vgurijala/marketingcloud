// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\api.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api");

    appImpl.init = function () {

        var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");

        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'entitlement-root-container', // ToDo : Talk to Jessie to create the class
            width: '100%',
            __workOrderHeaderRecord: null,

            constructor: function (config) {
                config = Ext.apply({
                    title: ENTITLEMENT.T('TAG060', 'Check Entitlement: Work Order'), 
                    header: false,
                }, config || {});

                this.callParent(arguments);
            },
            entitlementSelectionPanel:null,
            initComponent: function() {

                this.callParent(arguments);

                var me = this; 

                var workOrderDetailInfo = me.__engine.getWorkOrderDetailInfo();
                me.__workOrderHeaderRecord = workOrderDetailInfo.headerRecord;
                var unEntitledData = [];
                var entitlementToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    cls:'svmx-ent-headerToolBar',
                    dock: "top",
                    autoHeight: true,
                });

                /* <----------- Start of Entitlement Header ---------> */

                var workOrderInfoPanel = SVMX.create('Ext.form.Panel',{
                    border : false,
                    flex: 1,
                    autoHeight: true,
                    layout: {
                        type: 'vbox',
                        align: 'stretch',
                    },
                    items: [{
                            xtype: 'label',
                            text: ENTITLEMENT.T('TAG060', 'Check Entitlement: Work Order'),
                            cls: 'svmx-ent-title'
                        },
                        {
                            xtype: 'label',
                            text: me.__workOrderHeaderRecord.recordName,
                            cls: 'svmx-ent-WOName'
                        },
                        {
                            xtype: 'label',
                            text: me.__workOrderHeaderRecord.accountName,
                            cls: 'svmx-ent-WOAccount',
                            hidden: me.__workOrderHeaderRecord.accountName == null
                        },
                        {
                            xtype: 'label',
                            text: ENTITLEMENT.T("TAG009", 'Contact')+ ': '+me.__workOrderHeaderRecord.contactName ,
                            cls: 'svmx-ent-WOContact',
                            hidden: me.__workOrderHeaderRecord.contactName == null
                        }
                    ]
                }); 
                 
                entitlementToolBar.add(workOrderInfoPanel);

                me.__showDetailView = workOrderDetailInfo.entitlementSettings.entitlementSupportOnLines == 'True'? true: false;

                if(me.__showDetailView){
                    var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                        cls: 'svmx-text-filter-icon svmx-ent-toolbarElement',
                        emptyText: ENTITLEMENT.T("TAG061", 'Enter Installed Product or Product'),
                        width: "30%", height: 30,  
                        id: "searchtext",
                        listeners: {
                            change: function(f, e) {
                                me.entitlementPanel.workDetailstore.clearFilter();
                                me.entitlementPanel.workDetailstore.filter(
                                    new Ext.util.Filter({
                                        filterFn: function(item){
                                            var searchtest,installedBaseNameVal,recordNameVal;
                                            var escapere = Ext.String.escapeRegex;
                                            searchtest =  new RegExp( Ext.escapeRe( Ext.String.htmlEnode(searchtext.getValue() )), 'i');
                                            installedBaseNameVal = searchtest.test(item.data.installedBaseName);
                                            recordNameVal = searchtest.test(item.data.productName);
                                            // if any of the fields matched, return true, which will include  record in filtered set
                                            if(installedBaseNameVal || recordNameVal) {
                                                return true;
                                            }
                                            else {
                                                return false;
                                            }
                                        }
                                    })
                                );
                            }
                        }
                    });

                    entitlementToolBar.add(searchtext); 

                    var showAll = SVMX.create('Ext.form.Checkbox',{
                        boxLabel  : ENTITLEMENT.T("TAG062", 'Show All'),
                        checked   :  me.__engine.__manualEntitlementSettings.showAllLines == 'True'? true: false,
                        id        : 'showAll',
                        cls: 'svmx-ent-showAllCheckbox',
                        handler :function(){
                            // Reload the DetailList if showAll is checked
                            if(showAll.getValue()){
                                me.entitlementPanel.__showAll = true; 
                                me.entitlementPanel.loadData(me.__workOrderHeaderRecord.listDetailRecords);
                            }
                            else{
                                me.entitlementPanel.__showAll = false; 
                                me.entitlementPanel.loadData(me.getUnentitledData(me.__workOrderHeaderRecord.listDetailRecords));
                            }
                        }
                    });
                    entitlementToolBar.add(showAll);
                }

                var checkEntitlementBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG007", 'Check Entitlement'), //Icon Class for lookup button,
                    id: 'checkentitlement',
                    scale: 'medium',
                    height: 30,
                    cls:'svmx-ent-toolbarElement',
                    handler: function() {
                        me.checkEntitlementCallBack();
                    }
                });

                entitlementToolBar.add(checkEntitlementBtn);

                var settingDisplayBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG043", 'Settings'), //Icon Class for lookup button,
                    cls:'svmx-ent-toolbarElement',
                    margin: '0 3',
                    scale: 'medium',
                    height: 30,
                    handler: function() {
                        me.showSettingPanel(me.__engine.getEntitlementSettings());
                    }
                });

                entitlementToolBar.add(settingDisplayBtn);
                var backToHomeBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG026", 'Back to Work Order'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30,
                    handler: function () {
                        window.location = '/' + SVMX.getUrlParameter('id');
                    }
                });
                entitlementToolBar.add(backToHomeBtn)
                entitlementToolBar.add({
                    iconCls: 'svmx-ent-help-icon ',
                    cursor: 'pointer',
                    scale: 'large',
                    cls: 'svmx-ent-help',
                    tooltip: ENTITLEMENT.T("TAG015", 'Entitlement Check Help'),
                    href: ENTITLEMENT.T("TAG000", 'Entitlement Check Help')
                });
                me.add(entitlementToolBar);

                me.settingPanel = SVMX.create("com.servicemax.client.entitlement.ui.desktop.api.SettingPanel", {
                    __parent: me,
                    __engine: me.__engine,
                    border: false,
                    collapsible: false,
                    hidden: true,
                    title: ENTITLEMENT.T('TAG005', 'Entitlement Settings')
                });

                me.entitlementSelectionPanel = SVMX.create("com.servicemax.client.entitlement.ui.desktop.api.EntitlementSelectionPanel", {
                    __parent: me,
                    __engine: me.__engine,
                    border: false,
                    collapsible: false,
                    hidden: true,
                    __selectedEntitlement: null,
                });
                me.add(me.settingPanel);

                /* <----------- End of Work Order/ Work Detail Entitlement Info ---------> */

                var entitlementActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    style : 'margin-top: 20px', 
                    border: false,
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                entitlementActions.add(tabFill3);

                var cancelEntitlementBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG063", 'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    handler: function() {
                        window.location = '/'+SVMX.getUrlParameter('id');
                    }
                });

                entitlementActions.add(cancelEntitlementBtn);

                var saveEntitlementBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG008", 'Save Entitlement'), //Icon Class for lookup button,
                    disabled: true,
                    scale: 'medium',
                    height: 30, 
                    id: 'saveEnttoDatabase',
                    handler: function(button, e) {
                        var saveEntitlementReq = {};
                        button.setDisabled(true);
                        saveEntitlementReq.entitlementSettings = me.__engine.getEntitlementSettings();
                        saveEntitlementReq.headerId = me.__workOrderHeaderRecord.recordID;
                        saveEntitlementReq.entitlementInfoMap =  []; 
                        // On check entitlement, get the Id of all the elements perform entitlement for all lines on UI i.e. max 20 
                        
                        if(me.__showDetailView){
                            //selection.push[workOrderHeaderRecord.recordID];
                            var selectedEntitlementArray = me.entitlementPanel.workDetailstore.data.items;  
                            selectedEntitlementArray.forEach(function(record,j){
                                if(record.raw.selectedPSEntitlement != undefined && record.raw.selectedPSEntitlement != null)
                                    saveEntitlementReq.entitlementInfoMap.push(record.raw.selectedPSEntitlement);
                            });
                        }
                        else{
                            var selectedEntitlement = {};
                            selectedEntitlement.recordID = SVMX.getUrlParameter('id');
                            selectedEntitlement.entitlementInfo  = me.entitlementSelectionPanel.__selectedEntitlement;
                            saveEntitlementReq.entitlementInfoMap.push(selectedEntitlement);
                        }
                        me.__engine.saveEntitlement(saveEntitlementReq, function(result){
                            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000);
                            if(me.__showDetailView){
                                if(result.success){
                                    var workDetailPannel = Ext.getCmp('workDetailPannel');
                                    var listofOldDetailRecords = workDetailPannel.__parent.__workOrderHeaderRecord.listDetailRecords;
                                                                    
                                    if(result.headerRecord != null){
                                        var workDetailStoreList= result.headerRecord.listDetailRecords;
                                        workDetailStoreList.forEach(function(newUpdatedRecord, j){
                                            listofOldDetailRecords.forEach(function(oldrecord, j){
                                                if(oldrecord.recordID == newUpdatedRecord.recordID){ 
                                                    if(newUpdatedRecord.entitlementPerformed){
                                                        oldrecord.selectedEntitlementInfo = newUpdatedRecord.selectedEntitlementInfo;
                                                        oldrecord.entitlementPerformed = newUpdatedRecord.entitlementPerformed;
                                                        // Clear previously stored values
                                                        oldrecord.selectedPSEntitlement =  null;
                                                        if(newUpdatedRecord.selectedEntitlementInfo.warrantyOrScon != 'notcovered'){
                                                            oldrecord.selectEntitlementName = newUpdatedRecord.selectedEntitlementInfo.recordName
                                                            //oldrecord.selectedEntitlementInfo.installedProduct = oldrecord.installedBaseName;
                                                        }
                                                        else{
                                                            oldrecord.selectEntitlementName = 'Not Covered';
                                                        }
                                                    }
                                                }
                                            });
                                        });

                                        var searchtextVal = Ext.getCmp('searchtext');
                                        searchtextVal.setValue('');
                                        
                                        workDetailPannel.__parent.__workOrderHeaderRecord.listDetailRecords = listofOldDetailRecords;
                                        
                                        if(workDetailPannel.__showAll){
                                            workDetailPannel.loadData(workDetailPannel.__parent.__workOrderHeaderRecord.listDetailRecords);
                                        }
                                        else{
                                            workDetailPannel.loadData(workDetailPannel.__parent.getUnentitledData(workDetailPannel.__parent.__workOrderHeaderRecord.listDetailRecords));
                                        }
                                    }
                                }
                            }
                            else{
                                //JAYSUKH: BAC-4785
                                if((!(typeof sforce === 'undefined' || typeof sforce.one === 'undefined') && SVMX.getClient().getApplicationParameter('prefix')) || (SVMX.getClient().getApplicationParameter('uiTheme') && SVMX.getClient().getApplicationParameter('uiTheme') == 'Theme4d') ){
                                    sforce.one.navigateToSObject(SVMX.getUrlParameter('id'));
                                } else {
                                     window.location = '/'+SVMX.getUrlParameter('id');      
                                }
                            }
                        });
                    }
                });

                entitlementActions.add(saveEntitlementBtn);

                if(me.__showDetailView){
                    me.entitlementPanel = SVMX.create("com.servicemax.client.entitlement.ui.desktop.api.EntitlementPanel", {
                        __parent: me,
                        __engine: me.__engine,
                        border: false,
                        collapsible: false,
                        hidden: true,
                        __showAll: showAll.getValue(),

                    });
                    me.add(me.entitlementPanel);
                    // Load Data in the table to show all the product serviced which are not entitled
                    if(me.entitlementPanel.__showAll){
                        me.entitlementPanel.loadData(me.__workOrderHeaderRecord.listDetailRecords);
                    }
                    else{
                        me.entitlementPanel.loadData(me.getUnentitledData(me.__workOrderHeaderRecord.listDetailRecords));
                    }
                    me.entitlementPanel.show(); 
                }
                else{
                    me.entitlementSelectionPanel.__selectedEntitlement = me.__workOrderHeaderRecord.selectedEntitlementInfo;
                    me.entitlementSelectionPanel.loadData(me.__workOrderHeaderRecord.listEntitlementInfo, me.__workOrderHeaderRecord);
                    me.entitlementSelectionPanel.loadParentData();
                    me.entitlementSelectionPanel.show();
                    me.checkEntitlementCallBack(); 
                    me.add(me.entitlementSelectionPanel);                             
                }
 
                me.add(entitlementActions);     
            },
            showSettingPanel: function(record) {
                this.settingPanel.show();
                this.disable(); 
            },
            showEntitlementSelectionPanel: function(entitlementWindow, record) {
                entitlementWindow.add(this.entitlementSelectionPanel);
                entitlementWindow.__workdetailSelected = record; 
                this.entitlementSelectionPanel.loadData(record.raw.listEntitlementInfo, record.raw);
                this.entitlementSelectionPanel.loadParentData();
                this.entitlementSelectionPanel.show();
            },
            getUnentitledData: function(detailRecords){
                var unEntitledData = [];

                if(detailRecords != null){
                    detailRecords.forEach(function(record){
                        if(record.selectedEntitlementInfo == null)
                           unEntitledData.push(record); 
                    })    
                }
                return unEntitledData;
            },
            checkEntitlementCallBack: function(){
                parentWin = this; 
                var checkEntitlementreq = {};
                checkEntitlementreq.headerId = parentWin.__workOrderHeaderRecord.recordID;
                checkEntitlementreq.entitlementSettings = parentWin.__engine.getEntitlementSettings();
                
                // On Save entitlement, get the Id of selected warranty or Service Contract or Not covered.  
                if(parentWin.__showDetailView){
                    //selection.push[workOrderHeaderRecord.recordID];
                    var detailLineIDs = [];
                    var getProductServiceLines = parentWin.entitlementPanel.workDetailstore.data.items;
                    Ext.each(getProductServiceLines, function (record) {
                        detailLineIDs.push(record.data.recordID); 
                    });

                    checkEntitlementreq.detailLineIDs = detailLineIDs;
                }
                parentWin.__engine.CheckEntitlement(checkEntitlementreq, function(result){
                    if(result.success){
                        if(parentWin.__showDetailView){
                            // After check entitlement, we have to reload the data in entitlement panel
                            // me.entitlementPanel.loadData(result.headerRecord.listDetailRecords);
                            
                            result.headerRecord.listDetailRecords.forEach(function(entitledRecord, index){
                                parentWin.entitlementPanel.workDetailstore.findRecord('recordID', entitledRecord.recordID).raw = entitledRecord;   
                                // Need to update Orginal data as well, so that we get entitled data after switching the data as well.
                                var indexOfAllData =  parentWin.entitlementPanel.workDetailstore.allData.forEach(function(allDatarecordID, index){
                                    if(allDatarecordID.recordID == entitledRecord.recordID){ 
                                            if(parentWin.entitlementPanel.workDetailstore.allData[index].selectedPSEntitlement != null && parentWin.entitlementPanel.workDetailstore.allData[index].selectedPSEntitlement != undefined){
                                                entitledRecord.selectedPSEntitlement = parentWin.entitlementPanel.workDetailstore.allData[index].selectedPSEntitlement;
                                            }
                                                
                                            parentWin.entitlementPanel.workDetailstore.allData[index] = entitledRecord;
                                    }
                                }) 
                                // We need to update the listDetailRecords with updated entitled Info
                                var indexOflistDetailRecords =  parentWin.__workOrderHeaderRecord.listDetailRecords.forEach(function(detailRecordID, index){
                                    if(detailRecordID.recordID == entitledRecord.recordID){ 
                                            if(parentWin.__workOrderHeaderRecord.listDetailRecords[index].selectedPSEntitlement != null && parentWin.__workOrderHeaderRecord.listDetailRecords[index].selectedPSEntitlement != undefined){
                                                entitledRecord.selectedPSEntitlement = parentWin.__workOrderHeaderRecord.listDetailRecords[index].selectedPSEntitlement;
                                            }
                                            parentWin.__workOrderHeaderRecord.listDetailRecords[index] = entitledRecord;
                                    }
                                }) 
                            });
                        }
                        else{
                            var listEntitlementInfo = result.headerRecord.listEntitlementInfo;
                            parentWin.entitlementSelectionPanel.loadData(listEntitlementInfo, result.headerRecord);
                            parentWin.entitlementSelectionPanel.loadParentData();
                        }
                    }
                    else{
                        SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(result.messageList[0]), 7000, 'success');
                    }
                });
            },
            entHistoryCall: function(){
                this.entHisPanel.callEntHisWebservice();
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\entitlement.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.entitlement");

    appImpl.init = function () {

		var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");

        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.EntitlementPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            width:'100%' , height: '100%',border: false,
            id:'workDetailPannel',

            constructor: function(config) {                
                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);

                var me = this;
                /* <----------- Start of Work Order/ Work Detail Entitlement Info ---------> */
                Ext.define('DetailLines',{
                    extend: 'Ext.data.Model',
                    fields:[                    
                        {name: "selectEntitlementName"}, {name: "productName"}, {name: "recordName"}, {name: "installedBaseName"}, {name: 'description'}, {name: "selectedEntitlementInfo", type: 'object'}, {name: "updatedEntitlementInfo", type: 'object'}, {name: "recordID"}, {name: 'entitlementPerformed'},{name: "listEntitlementInfo", type: 'object'}
                    ]
                });

                var entitlementSelectionWindow = this.__entitlementSelectionWindow = SVMX.create('Ext.window.Window', {
                    id: 'entitlementSelectionWindow',
                    layout: 'anchor', border: false,
                    title: ENTITLEMENT.T('TAG072', 'Select Warranty/Contract'), header: { 
                        titleAlign: 'center',
                    }, closable:true,
                    hidden: true, 
                    closeAction: 'hide', 
                    width: '60%',
                    __parentWin: me, 
                    resizable: false, 
                    overflowY: 'auto', 
                    cls: 'entitlement-root-container',
                    listeners:{
                        beforehide: function(thisWindow, eOpts ){
                            var allTabPannels = Ext.getCmp('selectionWindowTab');
                            // Set focus on tab 0- Entitlement Selection
                            allTabPannels.items.items[0].setVisible(true);

                            // Reset Entitlement History Tab
                            Ext.getCmp('entHisPanel').loadEntHis([]);

                            //Remove All tabs except Entitlement Selection & Entitlement History
                            allTabPannels.items.each(function(item,j){
                                if(j != 0 && j != 1){
                                    allTabPannels.remove(item);
                                }
                            });
                        },
                        hide: function(thisWindow, eOpts){
                            thisWindow.hide();
                            Ext.getCmp('selectEntBtn').setDisabled(true);
                            thisWindow.__parentWin.enable();
                        }
                    }
                });

                me.add(entitlementSelectionWindow);

                var entitlementWindowActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false, 
                    style : 'margin-top: 20px', 
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                entitlementWindowActions.add(tabFill3);

                var saveEntitlementWindowBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG021", 'Select'), //Icon Class for lookup button,
                    id: 'selectEntBtn',
                    disabled: true,
                    scale: 'medium',
                    height: 30, 
                    handler: function(button, e) {
                        var selectedPSEntitlement = {};
                        var selectionPSWindow = Ext.getCmp('entitlementSelection');
                        selectedPSEntitlement.recordID = selectionPSWindow.__parentData.recordID;
                        selectedPSEntitlement.entitlementInfo  = selectionPSWindow.__selectedEntitlement;
                        selectionPSWindow.__parentData.selectedPSEntitlement  = selectedPSEntitlement;
                        selectionPSWindow.__selectedEntitlement = null;
                        // Enable Save to Database
                        var saveEnttoDatabase = Ext.getCmp('saveEnttoDatabase');
                        saveEnttoDatabase.setDisabled(false);
                        button.setDisabled(true);
                        entitlementSelectionWindow.hide();
                        entitlementSelectionWindow.__parentWin.enable();

                        var selectedWorkDetail = entitlementSelectionWindow.__workdetailSelected ;
                        selectedWorkDetail.set('updatedEntitlementInfo', selectionPSWindow.__parentData.selectedPSEntitlement.entitlementInfo);
                        selectedWorkDetail.store.fireEvent('refresh');
                    }
                });

                /*var cancelEntitlementWindowBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG063", 'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    handler: function(button,e) {
                        entitlementSelectionWindow.hide();
                        Ext.getCmp('selectEntBtn').setDisabled(true);
                        entitlementSelectionWindow.__parentWin.enable();
                    }
                });

                entitlementWindowActions.add(cancelEntitlementWindowBtn);*/
                entitlementWindowActions.add(saveEntitlementWindowBtn);
                

                var itemsPerPage = 20;
                me.workDetailstore =  SVMX.create('Ext.data.Store', {
                    model: 'DetailLines',
                    data: [],
                    storeId: 'entitlement_store',
                    autoLoad: false, 
                    pageSize: itemsPerPage,
                    proxy: {
                        type: 'memory',
                        reader: {type: 'array', root : 'data', totalProperty : 'total'}
                    },
                    allData:[],
                    listeners : {
                        beforeload : function(store, operation, eOpts){

                            var data=this.allData||[];
                            
                            var page = operation.start;
                            var limit = operation.limit;  

                            var pagedData=data.slice(page,page+limit);

                            var pagedModelData=[];
                            for(var i=0;i<pagedData.length;i++)
                            {
                                var entObj=Ext.create('DetailLines',pagedData[i]);
                                pagedModelData.push(entObj);
                            }

                            store.proxy.data ={ 
                                data: pagedModelData,
                                total : data.length,
                            };
                        }
                    }
                });

                // cls: 'borderless', 
                var workDetailGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{               
                    autoScroll: true, maxHeight:450, margin: '5 10', anchor: '100%',
                    store: me.workDetailstore,
                    border: false,
                    emptyText: ENTITLEMENT.T("TAG077", 'No valid Products Serviced lines to display'),
                    viewConfig: { 
                        deferEmptyText: false,
                    },
                    columns : [  
                        { xtype: 'rownumberer', text: ENTITLEMENT.T("TAG080", 'No.') , align: 'left', flex:1/5},                   
                        { flex: 1, text: ENTITLEMENT.T("TAG045", 'Warranties/Service Contracts'), dataIndex: 'selectEntitlementName', align: 'left', resizable: true, readOnly: true, 
                            renderer: function(value, md, record, row, col, store) {
                                var displayVal = '';
                                if(record.data.updatedEntitlementInfo != '' && record.data.updatedEntitlementInfo != undefined){
                                    displayVal = record.data.updatedEntitlementInfo.recordName != undefined ? record.data.updatedEntitlementInfo.recordName: ENTITLEMENT.T('TAG068', 'Not Covered'); 
                                    md.tdCls = 'svmx-ent-uncommitedChanges';
                                }
                                else{
                                    if((record.data.selectedEntitlementInfo != null && record.data.selectedEntitlementInfo != undefined) && record.data.entitlementPerformed) {
                                        if(record.data.selectedEntitlementInfo.warrantyOrScon == 'notcovered'){
                                            md.tdCls= 'svmx-ent-notCovered';  
                                            displayVal = ENTITLEMENT.T('TAG068', 'Not Covered');
                                        }
                                        else{
                                            displayVal = record.data.selectedEntitlementInfo.recordName != null?  record.data.selectedEntitlementInfo.recordName : record.data.selectedEntitlementInfo.warrantyTermName;
                                        }
                                    }
                                    else{
                                        md.tdCls= 'svmx-ent-emptytext';
                                        md.style = 'font-style: italic !important'; 
                                        displayVal = ENTITLEMENT.T("TAG081", 'Select for Contract/Warranty options');
                                    }  
                                }
                                return Ext.String.htmlEncode(displayVal);
                            }
                        },   
                        { flex: 1, text: ENTITLEMENT.T("TAG073", 'Product'), dataIndex: 'productName', align: 'left', resizable : false, readOnly: true, sortable: true, 
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T("TAG074", 'Installed Product'), dataIndex: 'installedBaseName', align: 'left', resizable : false, readOnly: true, sortable: true,
                        renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T("TAG075", 'Description') , dataIndex: 'description', align: 'left', resizable: false, readOnly: true, sortable: false,
                        renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        }
                        
                    ],
                    dockedItems: [{
                        xtype: 'pagingtoolbar',
                        store: me.workDetailstore,   // same store GridPanel is using
                        dock: 'bottom',
                        displayInfo: false,
                        layout: {pack: 'center'},
                        beforePageText : ENTITLEMENT.T("TAG079", 'Page'),
                        listeners: {
                            afterrender : function() {
                                this.child('#refresh').hide();
                            }
                        }
                    }],
                    listeners: {
                        cellclick: function( grid, td, cellIndex, record, tr, rowIndex, e ) {                                
                            entitlementSelectionWindow.add(me.__parent.showEntitlementSelectionPanel(entitlementSelectionWindow, record));
                            entitlementSelectionWindow.add(entitlementWindowActions); 
                            entitlementSelectionWindow.show(); 
                            entitlementSelectionWindow.__parentWin.disable();
                        }
                    }
                });
                me.add(workDetailGrid);  
            },
            loadData: function(data) {
                this.workDetailstore.allData=data;
                this.workDetailstore.loadPage(1);
            },
        });
    }
})();



// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\entitlementHistory.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.entitlementHistory");

    appImpl.init = function () {
        var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");


        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.EntitlementHistoryPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            autoScroll: true, cls: 'entitlement-root-container',
            id: 'entHisPanel',
            constructor: function(config) {                
                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                me.entHisStore =  SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "warrantyOrSconName"}, {name: "warrantyOrSconId"}, {name: "startDate"}, {name: "endDate"},{name: "slaTermName"} ,{name: "slaTermID"} ,{name: "dateOfEntitlement"} ,{name: "coveredBy"},{name: "recordId"} ,{name: "recordName"},
                    ],
                    data: [],
                    storeId: 'entitlementHis_store',
                });

                var entHisGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{
                    autoScroll: true, margin: '5 10', anchor: '100%',
                    store: me.entHisStore,
                    emptyText: ENTITLEMENT.T("TAG095", 'No Entitlement History Available') ,
                    border: false,
                    id:'entHistoryGrid',
                    height : 330,
                    viewConfig: { 
                        deferEmptyText: false, 
                    },
                    columns : [ 
                        { flex: 1, text: ENTITLEMENT.T("TAG017", 'Entitlement History')  , dataIndex: 'recordName', resizable: true, readOnly: true, sortable: true,
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.recordName != null){
                                    return '<a class="entHistoryRecord" href="#">'+ record.data.recordName+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },  
                        { flex: 1, text: ENTITLEMENT.T("TAG045", 'Warranties/Service Contracts'), dataIndex: 'warrantyOrSconName', resizable: true, readOnly: true, sortable: true,
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.warrantyOrSconName != null){
                                    return '<a class="sconWarrantyRecord" href="#">'+ Ext.String.htmlEncode(record.data.warrantyOrSconName)+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },   
                        { flex: 1, text: ENTITLEMENT.T('TAG055', 'SLA Terms') , dataIndex: 'slaTermName', align: 'center', resizable : false, readOnly: true,sortable: true, 
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.slaTermName != null){
                                    return '<a class="slaRecord" href="#">'+ Ext.String.htmlEncode(record.data.slaTermName)+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG052', 'Start Date') , dataIndex: 'startDate', align: 'center', resizable : false, readOnly: true, sortable: true,
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG053', 'End Date') , dataIndex: 'endDate', align: 'center', resizable : false,readOnly: true,sortable: true,
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG096', 'Date of Entitlement')  , dataIndex: 'dateOfEntitlement', align: 'center', resizable : false,readOnly: true, hidden: true, sortable: true
                        },
                    ],
                    listeners: {
                        cellclick: function(grid, td, cellIndex, record, tr, rowIndex, e) {

                            var rowRecord = grid.store.getAt(rowIndex);
                            e.preventDefault();

                            if (e.getTarget('a.entHistoryRecord')) {
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.recordName, record.data.recordId);
                            }

                            if (e.getTarget('a.sconWarrantyRecord')){
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.warrantyOrSconName, record.data.warrantyOrSconId);
                            }

                            if (e.getTarget('a.slaRecord')){
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.slaTermName, record.data.slaTermID);
                            }
                        },
                    }
                    
                });
                me.add(entHisGrid); 

                var entHisToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false
                });
            },
            callEntHisWebservice: function(){
                var me = this;
                var entHisConfig ={};
                entHisConfig.headerId = me.__parentRecordID;
                var entitlementHistoryList = me.__engine.getEntitlementHistory(entHisConfig, function (result){
                    if(result.headerRecord.entitlementHistoryMap != null){
                        me.loadEntHis(result.headerRecord.entitlementHistoryMap[entHisConfig.headerId]); 
                    }
                }); 
            },
            loadEntHis : function(data){
                if(this.__parent.__parent.__showDetailView){
                    var serviceContractGridTable = Ext.getCmp('entHistoryGrid');
                    serviceContractGridTable.down('[dataIndex=slaTermName]').hide();
                }
                this.entHisStore.loadData(data);
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\entitlementSelection.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.entitlementSelection");

    appImpl.init = function () {

		
        var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");

        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.EntitlementSelectionPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            height: '100%', border: false,
            id: 'entitlementSelection',
            __parentData : null,
            autoscroll : true,
            style: 'top: 10px;',
            layout: 'anchor',
            constructor: function(config) {                
                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                // This section is common for Work Order & Work Detail Enctilemnt selection,
                // we should pass only the availble SC or warranty option to this page.  
                var entitle = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection",{
                    title: ENTITLEMENT.T('TAG067', 'Entitlement Selection'),
                    bodyPadding: 10,
                    items: [],
                });

                
                /*var productPreviousEntitlement = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: 'Loading in progress...',
                    id :'entitlementInfoLabel',
                    cls: 'svmx-ent-entitlementInfo',
                    items:[]
                });*/

                var productPreviousEntitlement = SVMX.create('Ext.form.Panel',{
                    border : false, 
                    id :'entitlementInfoLabel',
                    cls: 'svmx-ent-entitlementInfoPanel',
                    layout: {
                        type: 'vbox',
                    },
                    items:[]
                });
                        
                entitle.add(productPreviousEntitlement);

                var coveredServiceWindow = SVMX.create('Ext.window.Window', {
                        id: 'coveredServiceWindow',
                        layout: 'anchor',
                        border: false,
                        title: ENTITLEMENT.T('TAG082', 'Included Services'), header: { 
                            titleAlign: 'center',
                        }, 
                        closable:true, 
                        hidden: true, 
                        closeAction: 'close', 
                        width: '60%',
                        layout: 'anchor', 
                        resizable: false, 
                        autoScroll: true, 
                        cls: 'entitlement-root-container', 
                        __parentWin: me, 
                        listeners:{
                            hide: function(thisWindow, eOpts){
                                thisWindow.hide();
                                thisWindow.__parentWin.enable();
                            }
                        },
                });

                me.coveredServiceStore = SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "serviceName"}, {name: "allowedUnits"}, {name: "consumedUnits"}, {name: "tracked"}, {name: "recordID"}, {name: "selected"}
                    ],
                    data: [],
                    storeId: 'cs_store',
                    listeners:{
                        datachanged : function(store, eOpts ){
                            var coveredServiceOnLoad = store.getRange();
                            // By default always select None
                            if(coveredServiceOnLoad.length > 0){
                                coveredServiceOnLoad[0].set('result_row_selected', true);
                            }

                            Ext.each(coveredServiceOnLoad, function (record) {
                                if(record.data.selected){
                                    record.set('result_row_selected', true);
                                    coveredServiceOnLoad[0].set('result_row_selected', false);
                                }
                            });
                        }
                    }
                });  

                var coveredServiceGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{
                    autoScroll: true, 
                    margin: '20 10', 
                    anchor: '100%',
                    store: me.coveredServiceStore,
                    border: false,
                    columns : [ 
                        {
                            maxWidth: 40,
                            width: 40,
                            xtype: 'svmx.columnradio',
                            dataIndex: "result_row_selected",
                            contentAlign: 'left',
                            id: 'selectedEntitlement',
                            sortable: false,
                            listeners : {
                                onselect: function(cmp, record, selected) {
                                    var selectedSCWindow = Ext.getCmp('coveredServiceWindow'); 
                                    var selSCInfo = selectedSCWindow.__SCParentData.getData();
                                    selSCInfo.coveredService.forEach(function(csInfo){
                                        if(csInfo.recordID == record.data.recordID){
                                            csInfo.selected = true;
                                        }
                                        else{
                                            csInfo.selected = false; 
                                        }
                                    });

                                    // Now update the UI with selected covered Service
                                    var parentSCRec = selectedSCWindow.__SCParentData;
                                    parentSCRec.set('coveredService', selSCInfo.coveredService);
                                    parentSCRec.store.fireEvent('refresh');
                                }
                            }
                        },                   
                        { flex: 1, text: ENTITLEMENT.T('TAG083', 'Service Name'), dataIndex: 'serviceName', resizable: false, readOnly: true, sortable: false, 
                            renderer: function(value, md, record, row, col, store) {
                                     return Ext.String.htmlEncode(value);
                                }
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG084', 'Allowed Units') , dataIndex: 'allowedUnits', align: 'center', resizable : false, readOnly: true, sortable: false, 
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG085', 'Consumed Units') , dataIndex: 'consumedUnits', align: 'center', resizable : false, readOnly: true, sortable: false, 
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG086', 'Tracked?') , dataIndex: 'tracked', align: 'center', resizable: false, readOnly: true, sortable: false},     
                    ]
                });
                                
                coveredServiceWindow.add(coveredServiceGrid);

                var coveredServiceWindowActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom"
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                coveredServiceWindowActions.add(tabFill3);

                // Adding close button to Covered Service Window
                var closeCoveredServiceBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG088", 'Close'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    handler: function(button,e) {
                        coveredServiceWindow.close();
                        coveredServiceWindow.__parentWin.enable();
                    }
                });

                coveredServiceWindowActions.add(closeCoveredServiceBtn);
                coveredServiceWindow.add(coveredServiceWindowActions);

                me.warrantystore =  SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "recordName"}, {name: "startDate"}, {name: "endDate"},{name: 'coveredBy'},{name: 'sLARecordName'},{name: 'coveredService'}, {name: "recordId"},{name: "sLARecordId"}, {name: "uniqueID"}, {name:"warrantyOrScon"}, {name:"warrantyTermId"}, {name:"warrantyTermName"}, {name:"installedBaseName"} 
                    ],
                    data: [],
                    storeId: 'warranty_store',
                    listeners:{
                        datachanged : function(store, eOpts ){
                            //if(warrantyGrid.getStore().getRange())
                            var getAllWarrantyLOnLoad = store.getRange();
                            if(getAllWarrantyLOnLoad.length >0){
                                var parentContainer = Ext.getCmp('entitlementSelection');
                                
                                Ext.each(getAllWarrantyLOnLoad, function (record) {
                                    if(parentContainer.__parentData.selectedPSEntitlement != undefined){
                                        if(parentContainer.__parentData.selectedPSEntitlement.entitlementInfo != null && parentContainer.__parentData.selectedPSEntitlement.entitlementInfo.uniqueID != null && record.data.uniqueID == parentContainer.__parentData.selectedPSEntitlement.entitlementInfo.uniqueID){
                                                record.set('result_row_selected', true);
                                        }
                                    }
                                    else{
                                        if(parentContainer.__parentData.selectedEntitlementInfo != null && parentContainer.__parentData.selectedEntitlementInfo.uniqueID != null && record.data.uniqueID == parentContainer.__parentData.selectedEntitlementInfo.uniqueID){
                                                record.set('result_row_selected', true);
                                        } 
                                    }
                                });
                            }
                        }
                    }
                });

                me.serviceContractstore =  SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "recordName"}, {name: "startDate"}, {name: "endDate"}, {name: 'coveredBy'},{name: 'sLARecordName'},{name: 'coveredService'},{name: 'coveredServiceName'} ,{name: "recordId"},{name: "uniqueID"}, {name: "sLARecordId"}, {name:"warrantyOrScon"}, {name:"warrantyTermId"}, {name:"warrantyTermName"}
                    ],
                    data: [],
                    storeId: 'sc_store',
                    listeners:{
                        datachanged : function(store, eOpts ){
                            //if(warrantyGrid.getStore().getRange())
                            var getAllSCOnLoad = store.getRange();
                            if(getAllSCOnLoad.length >0){
                                var parentContainer = Ext.getCmp('entitlementSelection');
                                
                                Ext.each(getAllSCOnLoad, function (record) {
                                    
                                    if(parentContainer.__parentData.selectedPSEntitlement != undefined){
                                        if(parentContainer.__parentData.selectedPSEntitlement.entitlementInfo != null && parentContainer.__parentData.selectedPSEntitlement.entitlementInfo.uniqueID != null && record.data.uniqueID == parentContainer.__parentData.selectedPSEntitlement.entitlementInfo.uniqueID){
                                            record.set('result_row_selected', true);
                                             return false;
                                        }
                                    }
                                    else{
                                        if(parentContainer.__parentData.selectedEntitlementInfo != null){
                                            if(parentContainer.__parentData.selectedEntitlementInfo.uniqueID != null){
                                                if(record.data.uniqueID == parentContainer.__parentData.selectedEntitlementInfo.uniqueID){
                                                    record.set('result_row_selected', true);
                                                     return false;
                                                }
                                                else{
                                                    // if uniqueId just contains ID, then the record was entitled using Auto Entitlement
                                                    if(parentContainer.__parentData.selectedEntitlementInfo.uniqueID != null && parentContainer.__parentData.selectedEntitlementInfo.uniqueID == record.data.recordId && record.data.uniqueID.startsWith(parentContainer.__parentData.selectedEntitlementInfo.uniqueID)){
                                                        record.set('result_row_selected', true);
                                                        return false;
                                                    }
                                                }
                                            } 
                                        }
                                    }
                                });
                            }
                        }
                    }
                });

                me.notCoveredstore =  SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "notCovered"}
                    ],
                    data: [
                        {notCovered: ENTITLEMENT.T('TAG068', 'Not Covered')}
                    ],
                    storeId: 'notCovered'
                });

                var notcoveredGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{               
                    autoScroll: true, margin: '5 10', anchor: '100%', 
                    store: me.notCoveredstore, hideHeaders:true,
                    border: false,
                    bodyCls: 'svmx-ent-selectionTable svmx-ent-notCovered',
                    columns : [ 
                        {
                            maxWidth: 30,
                            width: 30,
                            xtype: 'svmx.columnradio',
                            dataIndex: "result_row_selected",
                            contentAlign: 'center',
                            id: 'selectedEntitlement',
                            listeners : {
                                onselect: function(cmp, record, selected) {
                                    var getAllWarranty = warrantyGrid.getStore().getRange();
                                    Ext.each(getAllWarranty, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                        record.set('result_row_selected', false); 
                                    });

                                    var getAllSC = serviceContractGrid.getStore().getRange();
                                    Ext.each(getAllSC, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                            record.set('result_row_selected', false); 
                                    });

                                    var selectionContainer = Ext.getCmp('entitlementSelection');
                                    selectionContainer.__selectedEntitlement = {};
                                    var entNotestText = Ext.getCmp('entNotes'); 
                                    selectionContainer.__selectedEntitlement.entitlementNotes = entNotestText.getValue(); 
                                    selectionContainer.__selectedEntitlement.warrantyOrScon = 'notcovered'; 
                                    selectionContainer.enableDisbaleSelectbtn();
                                }
                            }
                        },                   
                        { flex: 1, text: 'Not Covered', dataIndex: 'notCovered', resizable: false, border: false}  
                    ]
                });
             
                
                entitle.add(notcoveredGrid);

                var warrantyGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{
                    autoScroll: true, margin: '5 10', anchor: '100%',
                    store: me.warrantystore,
                    emptyText: ENTITLEMENT.T('TAG071', 'No warranty available') ,
                    border: false,
                    bodyCls: 'svmx-ent-selectionTable',
                    viewConfig: { 
                        deferEmptyText: false,
                        cls: 'svmx-ent-gridempty',
                    },
                    columns : [ 
                        {
                            maxWidth: 30,
                            width: 30,
                            xtype: 'svmx.columnradio',
                            dataIndex: "result_row_selected",
                            contentAlign: 'center',
                            id: 'selectedEntitlement',
                            resizable: false,
                            listeners : {
                                onselect: function(cmp, record, selected) {
                                    var getAllSC = serviceContractGrid.getStore().getRange();
                                    Ext.each(getAllSC, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                            record.set('result_row_selected', false); 
                                    });
                                    var getNotCovered = notcoveredGrid.getStore().getRange();
                                    Ext.each(getNotCovered, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                            record.set('result_row_selected', false); 
                                    });

                                    var selectionContainer = Ext.getCmp('entitlementSelection');
                                    selectionContainer.__selectedEntitlement = record.data;
                                    var entNotestText = Ext.getCmp('entNotes'); 
                                    selectionContainer.__selectedEntitlement.entitlementNotes = entNotestText.getValue(); 
                                    selectionContainer.enableDisbaleSelectbtn();
                                    //record.selectedEntitlement = record.data;
                                }
                                
                            }
                        },                   
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG057', 'Warranty Name'), 
                            dataIndex: 'recordName', 
                            resizable: true, 
                            readOnly: true, 
                            renderer: function(value, md, record, row, col, store) {
                                return '<a class="detailRecord" href="#">'+ Ext.String.htmlEncode(record.data.recordName) + '</a>';
                            }
                        },   
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG052', 'Start Date') , 
                            dataIndex: 'startDate', 
                            align: 'center', 
                            resizable : false, 
                            readOnly: true,                           
                        },
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG053', 'End Date') , 
                            dataIndex: 'endDate', 
                            align: 'center', 
                            resizable : false, 
                            readOnly: true,
                        },
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG058', 'Installed Product') , 
                            dataIndex: 'installedBaseName', 
                            align: 'center', 
                            resizable: false, 
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },     
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG059', 'Warranty Terms') , 
                            dataIndex: 'warrantyTermName', 
                            align: 'center', 
                            resizable: false, 
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },   
                    ],
                    listeners: {
                        cellclick: function(grid, td, cellIndex, record, tr, rowIndex, e) {
                            var el = e.getTarget('a.detailRecord');
                            if (el) {
                                var rowRecord = grid.store.getAt(rowIndex);
                                e.preventDefault();
                                var warrantySelContainer = Ext.getCmp('entitlementSelection');
                                me.findDuplicateTab(entitlementInfoTab, warrantySelContainer, record.data.recordName, record.data.recordId);
                            }
                        }
                    }
                });
                entitle.add(warrantyGrid); 

                var serviceContractGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{               
                    autoScroll: true, margin: '5 10', anchor: '100%',
                    store: me.serviceContractstore,
                    id: 'scGrid',
                    emptyText: ENTITLEMENT.T('TAG070', 'No service contract available'),
                    border: false,
                    bodyCls: 'svmx-ent-selectionTable',
                    viewConfig: { 
                        deferEmptyText: false,
                        cls: 'svmx-ent-gridempty',
                    },
                    columns : [
                        {
                            maxWidth: 30,
                            width: 30,
                            xtype: 'svmx.columnradio',
                            dataIndex: "result_row_selected",
                            contentAlign: 'center',
                            id: 'selectedEntitlement',
                            resizable: false,
                            listeners : {
                                onselect: function(cmp, record, selected) {
                                    var getAllWarranty = warrantyGrid.getStore().getRange();
                                    Ext.each(getAllWarranty, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                        record.set('result_row_selected', false); 
                                    });

                                    var getNotCovered = notcoveredGrid.getStore().getRange();
                                    Ext.each(getNotCovered, function (record) {
                                        if(record.data.result_row_selected != 'undefined' )
                                            record.set('result_row_selected', false); 
                                    });

                                    var selectionContainer = Ext.getCmp('entitlementSelection');
                                    if(record.data.coveredService != null && record.data.coveredService.length > 0){
                                        // If none is selected, then make covered Service as null
                                        record.data.coveredService.forEach(function(csRec, index){
                                            if(csRec.selected && csRec.index == 0){ 
                                                record.data.coveredService = null;
                                                return;  
                                            }
                                        });

                                        var coveredServiceWin = Ext.getCmp('coveredServiceWindow');
                                        coveredServiceWin.__SCParentData = record;
                                        
                                        var csStore = Ext.getStore('cs_store'); 
                                        csStore.loadData(record.data.coveredService);  
                                        coveredServiceWin.show();
                                        coveredServiceWin.__parentWin.disable();    
                                    }                                    
                                    selectionContainer.__selectedEntitlement = record.data; 
                                    var entNotestText = Ext.getCmp('entNotes'); 
                                    selectionContainer.__selectedEntitlement.entitlementNotes = entNotestText.getValue(); 
                                    selectionContainer.enableDisbaleSelectbtn();
                                }
                            }
                        },                 
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG056', 'Contract Name/Number'), 
                            dataIndex: 'recordName', 
                            resizable: true, 
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                return '<a class="detailRecord" href="#">'+ Ext.String.htmlEncode(record.data.recordName)+ '</a>';
                            }
                        },   
                        { 
                            flex: 0.7, 
                            text: ENTITLEMENT.T('TAG052', 'Start Date'), 
                            dataIndex: 'startDate', 
                            align: 'center', 
                            resizable : false, 
                            readOnly: true,
                            sortable: true,
                          
                        },
                        { 
                            flex: 0.7, 
                            text: ENTITLEMENT.T('TAG053', 'End Date')  , 
                            dataIndex: 'endDate', 
                            align: 'center', 
                            resizable : false, 
                            readOnly: true,
                            sortable: true, 
                            
                        },
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG025', 'Covered By'), 
                            dataIndex: 'coveredBy', 
                            align: 'center', 
                            resizable: false, 
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },       
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG055', 'SLA Terms'), 
                            dataIndex: 'sLARecordName',
                            align: 'center',
                            resizable: false,
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },      
                        { 
                            flex: 1, 
                            text: ENTITLEMENT.T('TAG054', 'Covered Service'), 
                            dataIndex: 'coveredServiceName', 
                            align: 'center', 
                            resizable: false, 
                            readOnly: true,
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.coveredService != null){
                                        var coveredService = '';
                                        record.data.coveredService.forEach(function(coveredServiceRec){
                                            if(coveredServiceRec.selected){
                                                coveredService += '<a class="coveredServiceLink" style="text-align:left" target="_blank" href="/'+coveredServiceRec.recordID+' ">'+ coveredServiceRec.serviceName+ '</a> <br/>';
                                                coveredService +=  ENTITLEMENT.T('TAG087', 'Available Units') + '  ' +coveredServiceRec.availableUnits; 
                                                record.data.coveredServiceName = coveredServiceRec.serviceName; 
                                            }
                                        });
                                        //record.data.coveredServiceName = coveredServiceRec.serviceName; 
                                        return coveredService; 
                                }
                                else{
                                    record.data.coveredServiceName = coveredService 
                                }
                                return Ext.String.htmlEncode(coveredService);
                            }   
                        }
                    ],
                    listeners: {
                        cellclick: function(grid, td, cellIndex, record, tr, rowIndex, e) {
                            var el = e.getTarget('a.detailRecord');
                            if (el) {
                                var rowRecord = grid.store.getAt(rowIndex);
                                e.preventDefault();
                                var scSelContainer = Ext.getCmp('entitlementSelection');
                                me.findDuplicateTab(entitlementInfoTab, scSelContainer, record.data.recordName, record.data.recordId);
                            }
                        },
                    }
                });
                entitle.add(serviceContractGrid); 

                var entHisPanel = SVMX.create("com.servicemax.client.entitlement.ui.desktop.api.EntitlementHistoryPanel", {
                    __parent: me, __engine: me.__engine, border: false, collapsible:false, hidden: true,__parentRecordID: null
                });
 
                var entHisoryTab = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection",{
                    tabConfig: {
                        title: ENTITLEMENT.T("TAG017", 'Entitlement History'),
                        margin: '0 0 0 4'
                    },
                    autoScroll: true,
                    closable: false,
                    id: 'recordEntHis',
                    listeners:{
                        activate: function(tabPanel, tab, eOpts ){
                            if(tabPanel.id == 'recordEntHis'){
                                var entHisTable = Ext.getCmp('entHisPanel');
                                entHisTable.__parentRecordID =  Ext.getCmp('entitlementSelection').__parentData.recordID, 
                                entHisTable.callEntHisWebservice();
                                entHisTable.show();
                            }
                        },
                    }
                });

                entHisoryTab.add(entHisPanel);
                 
		  var entitlementInfoTab = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXTabPanel", {
                    activeTab: 0,
                    id:'selectionWindowTab', 
                    layout:'fit',
                    autoScroll: true,
                    tabBar: {
                        height: 40,
                    },
                    items:[
                        entitle, entHisoryTab,
                    ],
                    listeners:{
                        beforeadd: function(tabpane, component, index) {
                            if(index==5)
                                tabpane.getComponent(2).close();
                        },
                    }
                });

                me.add(entitlementInfoTab);
            }, 
            loadData : function (record, parentData){
                var warrantyStoreData = [];
                var serviceContractStoreData = [];
                this.__parentData = parentData;

                var currentSelectedEntitlement = parentData.selectedEntitlementInfo;

                var selectEntitlementIds = [];

                // Before selecting Not covered, initialize it.
                this.notCoveredstore.loadData([{notCovered: ENTITLEMENT.T('TAG068', 'Not Covered')}]);
                
                if(parentData.selectedPSEntitlement != undefined && parentData.selectedPSEntitlement.entitlementInfo.warrantyOrScon == 'notcovered'){
                    this.selectNotCovered();
                }
                else if(parentData.selectedEntitlementInfo != null && parentData.selectedEntitlementInfo.warrantyOrScon == 'notcovered' && parentData.selectedPSEntitlement == undefined){
                      this.selectNotCovered(); 
                }
                

                /*if(currentSelectedEntitlement != null){
                    if(currentSelectedEntitlement.warrantyOrScon == 'scontract'){
                        serviceContractStoreData.push(currentSelectedEntitlement);
                    }
                    if(currentSelectedEntitlement.warrantyOrScon == 'warranty'){
                        warrantyStoreData.push(currentSelectedEntitlement);
                    }
                    selectEntitlementIds.push(currentSelectedEntitlement.recordId);
                }*/

                // All the records from Entitlement Info will be added to the List
                if(record != null){

                    record.forEach(function(record,j){
                        if(record.warrantyOrScon == 'scontract'){
                            serviceContractStoreData.push(record);
                        }
                        if(record.warrantyOrScon == 'warranty'){
                            warrantyStoreData.push(record);
                        }
                    });
                }

                //Check if selectedEntitlement is also in the list, if yes then don't add.  
                var isSelEntAvailable = false; 
                if(currentSelectedEntitlement != null){
                    
                    if(currentSelectedEntitlement.warrantyOrScon == 'scontract'){
                        serviceContractStoreData.forEach(function(entData, index){
                            if(entData.recordId == currentSelectedEntitlement.recordId){ 
                                isSelEntAvailable = true;
                                return;  
                            }
                        })
                        if(!isSelEntAvailable){
                            serviceContractStoreData.push(currentSelectedEntitlement);
                        } 
                    }
                    if(currentSelectedEntitlement.warrantyOrScon == 'warranty'){
                        warrantyStoreData.forEach(function(entData, index){
                            if(entData.recordId == currentSelectedEntitlement.recordId){ 
                                isSelEntAvailable = true;
                                return;  
                            }
                        })
                        if(!isSelEntAvailable){
                            warrantyStoreData.push(currentSelectedEntitlement);
                        } 
                    }
                }


                this.serviceContractstore.loadData(serviceContractStoreData);
                this.warrantystore.loadData(warrantyStoreData);

                if(this.__parent.__showDetailView){
                    var serviceContractGridTable = Ext.getCmp('scGrid');
                    serviceContractGridTable.down('[dataIndex=sLARecordName]').hide();
                    serviceContractGridTable.down('[dataIndex=coveredServiceName]').hide();
                }
            },
            loadParentData : function(){
                var parentDataLoad = this.__parentData;
                var currentEntitlementInfo = '';
                var getEntitlementInfoLabel = Ext.getCmp('entitlementInfoLabel');
                getEntitlementInfoLabel.removeAll();
                if(parentDataLoad.productName != null){
                    var productName = SVMX.create('Ext.form.Label',{
                        text: parentDataLoad.productName,
                        cls: 'svmx-ent-entitlementInfo',
                    });
                    getEntitlementInfoLabel.add(productName);
                    
                }
                if(parentDataLoad.installedBaseName != null){
                    var IBName = SVMX.create('Ext.form.Label',{
                        text: ENTITLEMENT.T("TAG074", 'Installed Product') + ': ' +parentDataLoad.installedBaseName,
                        cls: 'svmx-ent-entitlementInfoPre',
                    });
                    getEntitlementInfoLabel.add(IBName);
                    
                }

                var entitlementNotesText = ''; 

                var entNotesField = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXTextArea',{
                    grow      : true,
                    labelAlign : 'top', 
                    fieldLabel: 'Entitlement Notes',
                    anchor    : '100%',
                    resizable: false,
                    width: 500,
                    height: 86,
                    value: entitlementNotesText,
                    id: 'entNotes',
                    enableKeyEvents: true,
                    fieldCls: 'svmx-ent-entitlementnotes', 
                    listeners: {
                        keyup: function( record, isDirty, eOpts ){
                            // button can be enabled only if we have any selected value
                            var selectionContainer = Ext.getCmp('entitlementSelection');
                            if(selectionContainer.__selectedEntitlement != undefined){
                                selectionContainer.__selectedEntitlement.entitlementNotes = record.getValue();
                                selectionContainer.enableDisbaleSelectbtn();
                            }
                            else if(selectionContainer.__parentData.selectedEntitlementInfo != null){
                                selectionContainer.__selectedEntitlement = selectionContainer.__parentData.selectedEntitlementInfo 
                                selectionContainer.__selectedEntitlement.entitlementNotes = record.getValue();
                                selectionContainer.enableDisbaleSelectbtn();
                            }
                        }
                    }
                });
                
                
                //If user has changed the values, then we need to update the Entitlement Notes with recently updated values
                // and if recently selected value is not available, check for selected Entitlement Info
                if(parentDataLoad.selectedPSEntitlement != null  && parentDataLoad.selectedPSEntitlement.entitlementInfo.entitlementNotes != null){
                    entitlementNotesText = parentDataLoad.selectedPSEntitlement.entitlementInfo.entitlementNotes; 
                }
                else if(parentDataLoad.selectedEntitlementInfo != null && parentDataLoad.selectedEntitlementInfo.entitlementNotes != null){
                    entitlementNotesText = parentDataLoad.selectedEntitlementInfo.entitlementNotes; 
                }
                
                entNotesField.setValue(entitlementNotesText);
                getEntitlementInfoLabel.add(entNotesField);
                
            },
            enableDisbaleSelectbtn : function(){
                var selectContractWarrantOnUI = Ext.getCmp('selectEntBtn');
                if(selectContractWarrantOnUI != undefined){
                    selectContractWarrantOnUI.setDisabled(false);
                }
                else{
                    var saveEnttoDatabase = Ext.getCmp('saveEnttoDatabase');
                    saveEnttoDatabase.setDisabled(false);
                }

            },
            selectNotCovered : function(){
                var getNotCoveredOnLoad = this.notCoveredstore.getRange();
                Ext.each(getNotCoveredOnLoad, function (record) {
                    record.set('result_row_selected', true);
                });
            },
            findDuplicateTab: function(entitlementInfoTab, parentContainer, recordName, recordId){
                var isTabExisting = false; 
                for(i =1 ; i <entitlementInfoTab.items.items.length; i++ ){
                    if(entitlementInfoTab.items.items[i].itemId != undefined && entitlementInfoTab.items.items[i].itemId == recordId ){
                        entitlementInfoTab.setActiveTab(entitlementInfoTab.items.items[i])
                        isTabExisting = true; 
                        break;
                    }
                }

                if(!isTabExisting){
                    var scTab = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection",{
                        tabConfig: {
                            title: Ext.String.htmlEncode(recordName),
                            margin: '0 0 0 4'
                        },
                        closable: true,
                        itemId : recordId,
                        loader: {
                            autoLoad:true,
                            url : parentContainer.__parent.__engine.__manualEntitlementSettings.recordViewPage + recordId,
                        }
                    });
                    entitlementInfoTab.add(scTab);
                    entitlementInfoTab.setActiveTab(scTab); 
                }
            }
        });
    }
})();



// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			com.servicemax.client.entitlement.ui.desktop.api.entitlement.init();
			com.servicemax.client.entitlement.ui.desktop.api.setting.init();
			com.servicemax.client.entitlement.ui.desktop.api.entitlementSelection.init();
			com.servicemax.client.entitlement.ui.desktop.api.entitlementHistory.init();
        },

        initialize: function() {
        	com.servicemax.client.entitlement.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.entitlement.ui.desktop\src\setting.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.setting");

    appImpl.init = function () {
        var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");


		Ext.define("com.servicemax.client.entitlement.ui.desktop.api.SettingPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXWindow",
            hidden: true, 
            width: '60%',
            layout: 'anchor', 
            closable: true, 
            closeAction: 'hide',
            resizable: false, 
            autoScroll: true, 
            cls: 'entitlement-root-container',
            __settingObj: null,
            header: { 
                titleAlign: 'center',
            },
            listeners:{
                hide: function(thisWindow, eOpts){
                    thisWindow.hide();
                    Ext.getCmp('savesettingBtn').setDisabled(true);
                    thisWindow.__parent.enable();
                }
            },
            constructor: function(config) {
                if(window.innerHeight < 675) {
                    this.height = 350;
                }
                this.center();               
                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;
                me.__settingObj = me.__engine.getEntitlementSettings();

                var entitlementSettingTopPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection",{
                    layout:{
                        type:'column',
                    },
                    collapsible:false,
                    border: false, 
                    margin : '30 0 0 30',
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                        },
                        afterlayout: function( container, layout, eOpts ){
                            me.updateAccountProductSettings(me.__settingObj.entitleUsingAccountOrProduct);
                        }
                    }
                });

               
                var counterDatesGroup = SVMX.create("Ext.form.RadioGroup", {
                    columns: 3,
                    vertical: true,
                    width: '100%',
                    items: [
                        {
                            boxLabel: ENTITLEMENT.T('TAG090', 'Dates'),
                            inputValue: 'Dates',
                            name:'considerCountersOrDates',
                            id: 'attributeDates', 
                            checked: me.__settingObj.considerCountersOrDates == 'Dates' ,
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG091', 'Counters'),
                            inputValue: 'Counters',
                            name:'considerCountersOrDates',
                            id: 'attributeCounter',
                            checked: me.__settingObj.considerCountersOrDates == 'Counters',
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG092', 'Both'),
                            inputValue: 'Both',
                            name:'considerCountersOrDates',
                            id: 'attributeBoth',
                            checked: me.__settingObj.considerCountersOrDates == 'Both',
                        } 
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                            me.__settingObj.considerCountersOrDates = e.considerCountersOrDates;
                        }
                    }
                    
                });
                
                // ToDo: Write the logic to display fields.
                var settingGroupShowFutureExpired = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckboxGroup", {
                    columns: 1,
                    fieldLabel: ENTITLEMENT.T('TAG064', 'Validity'),
                    width: '50%',
                    labelAlign: 'top',
                    items:[
                        {
                            boxLabel: ENTITLEMENT.T('TAG032', 'Show Future Entitlements'),
                            checked : me.stringToBoolean( me.__settingObj.showFutureEntitlement ),
                            inputValue: 'showFutureEntitlement',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.showFutureEntitlement = newValue;
                                }
                            } 
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG034', 'Show Expired Entitlements'),
                            checked : me.stringToBoolean( me.__settingObj.showExpiredEntitlement ),
                            inputValue: 'showExpiredEntitlement',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.showExpiredEntitlement = newValue;
                                }
                            }
                        }
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                        }
                    }
                });

                var attributesGroup = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    columns: 1,
                    width: '50%',
                    header: false,
                    bodyBorder: false,
                    border: false,
                    items: [
                        settingGroupShowFutureExpired,  counterDatesGroup,
                    ],                    
                });

                entitlementSettingTopPanel.add(attributesGroup);

                var dummySpace = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckboxGroup", {
                    columns: 1,
                });
                entitlementSettingTopPanel.add(dummySpace);

                var settingGroup = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckboxGroup", {
                    columns: 1,
                    vertical:true,
                    fieldLabel: ENTITLEMENT.T('TAG078', 'Matching'),
                    labelAlign: 'top',
                    width: '50%',
                    items:[
                        {
                            boxLabel: ENTITLEMENT.T('TAG036', 'Match Account'),
                            checked : me.stringToBoolean( me.__settingObj.matchAccount ),
                            inputValue: 'matchAccount',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.matchAccount = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG038', 'Match Contact') ,
                            checked : me.stringToBoolean( me.__settingObj.matchContact ),
                            inputValue: 'matchContact',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.matchContact = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG076', 'Match Location') ,
                            checked : me.stringToBoolean( me.__settingObj.matchLocation ),
                            inputValue: 'matchLocation',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.matchLocation = newValue;
                                }
                            }
                        }
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                        }
                    }
                });
                entitlementSettingTopPanel.add(settingGroup);
                
                me.add(entitlementSettingTopPanel);

                // Adding HR kind of line
                me.add({
                        xtype: 'container',
                        style: 'border:1px solid #A1A1A1 !important',
                        margin : '20 30 20 30',
                });

                var entitlementSettingBottomPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection",{
                    layout:{
                        type:'column',
                    },
                    collapsible:false,
                    margin : '0 0 0 30',
                    border: false
                });

                var settingProductAttributesGroup = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXCheckboxGroup", {
                    columns: 2,
                    vertical:true,
                    fieldLabel: ENTITLEMENT.T('TAG065', 'Product Attributes') ,
                    labelAlign: 'top',
                    width: '50%',
                    items:[
                        {
                            boxLabel: ENTITLEMENT.T('TAG033', 'Parent Product') ,
                            checked : me.stringToBoolean( me.__settingObj.coverageOnParentProduct ),
                            inputValue: 'coverageOnParentProduct',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnParentProduct = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG035', 'Top-Level Product'),
                            checked : me.stringToBoolean( me.__settingObj.coverageOnTopLevelProduct ),
                            inputValue: 'coverageOnTopLevelProduct',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnTopLevelProduct = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG037', 'Child Product') ,
                            checked : me.stringToBoolean( me.__settingObj.coverageOnChildProduct ),
                            inputValue: 'coverageOnChildProduct',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnChildProduct = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG039', 'Part Number') ,
                            checked : me.stringToBoolean( me.__settingObj.coverageOnPartProduct ),
                            inputValue: 'coverageOnPartProduct',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnPartProduct = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG041', 'Product Family'),
                            checked : me.stringToBoolean( me.__settingObj.coverageOnProductFamily ),
                            inputValue: 'coverageOnProductFamily',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnProductFamily = newValue;
                                }
                            }
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG042', 'Product Line') ,
                            checked : me.stringToBoolean( me.__settingObj.coverageOnProductLine ),
                            inputValue: 'coverageOnProductLine',
                            name:'settingvalues',
                            height: 30,
                            listeners: {
                                change : function( checkbox, newValue, oldValue ) {
                                    me.__settingObj.coverageOnProductLine = newValue;
                                }
                            }
                        },
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                        }
                    }
                });
                entitlementSettingBottomPanel.add(settingProductAttributesGroup);

                var radioGroup = SVMX.create("Ext.form.RadioGroup", {
                    columns: 2,
                    vertical:true,
                    fieldLabel: ENTITLEMENT.T('TAG040', 'Entitle Using') ,
                    labelAlign: 'top',
                    width: '68%',
                    items:[
                        {
                            boxLabel: ENTITLEMENT.T('TAG010', 'Account') , 
                            name: 'entitleUsingAccountOrProduct', 
                            inputValue: 'Account',
                            id: 'entitleUsingAccount',
                            disabled: !me.stringToBoolean( me.__settingObj.allowEntitlementFilters), 
                            checked: me.__settingObj.entitleUsingAccountOrProduct == 'Account',
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG003', 'Product') , 
                            name: 'entitleUsingAccountOrProduct', 
                            inputValue: 'Product',
                            id: 'entitleUsingProduct',
                            disabled: !me.stringToBoolean( me.__settingObj.allowEntitlementFilters), 
                            checked: me.__settingObj.entitleUsingAccountOrProduct == 'Product',
                        }, 
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                            me.__settingObj.entitleUsingAccountOrProduct = e.entitleUsingAccountOrProduct;
                            me.updateAccountProductSettings(e.entitleUsingAccountOrProduct); 
                        }
                    }
                });

                var warrantyServiceContractGroup = SVMX.create("Ext.form.RadioGroup", {
                    columns: 3,
                    vertical: true,
                    width: '100%',
                    id: 'warrantyServiceContractGroup', 
                    items: [
                        {
                            boxLabel: ENTITLEMENT.T('TAG094', 'Service Contract') ,
                            checked: me.__settingObj.entUsingWarrantyOrSC == 'Service Contract',
                            inputValue: 'Service Contract',
                            height: 30,
                            id: 'entitleUsingSC',
                            name:'entUsingWarrantyOrSC',
                            
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG093', 'Warranty') ,
                            checked: me.__settingObj.entUsingWarrantyOrSC == 'Warranty',
                            inputValue:'Warranty',
                            height: 30,
                            id: 'entitleUsingWarranty',
                            name:'entUsingWarrantyOrSC',
                            
                        },
                        {
                            boxLabel: ENTITLEMENT.T('TAG092', 'Both') ,
                            checked: me.__settingObj.entUsingWarrantyOrSC == 'Both',
                            inputValue: 'Both',
                            height: 30,
                            id: 'entitleUsingBoth',
                            name:'entUsingWarrantyOrSC',
                            
                        }
                    ],
                    listeners:{
                        change: function(f, e) {
                            saveEntitlementBtn.setDisabled(false);
                            me.__settingObj.entUsingWarrantyOrSC = e.entUsingWarrantyOrSC;
                        }
                    }
                });

                var entitleUsingGroup = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    columns: 1,
                    width: '50%',
                    header: false,
                    bodyBorder: false,
                    border: false,
                    items: [
                        radioGroup, warrantyServiceContractGroup
                    ],                    
                });

                entitlementSettingBottomPanel.add(entitleUsingGroup);

                me.add(entitlementSettingBottomPanel);

                // Adding HR kind of line
                me.add({
                        xtype: 'container',
                        style: 'border:1px solid #A1A1A1 !important;',
                        margin : '20 30 20 30',
                });
               
                var settingToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false
                });

                var tabFill = SVMX.create("Ext.Toolbar.Fill",{ });
                settingToolBar.add(tabFill);

                /*var cancelEntitlementBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T('TAG063', 'Cancel') , //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    handler: function() {
                        saveEntitlementBtn.setDisabled(true);
                        me.hide();
                        me.__parent.enable();
                    }
                });

                settingToolBar.add(cancelEntitlementBtn);*/

                var saveEntitlementBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T('TAG066', 'Apply'), //Icon Class for lookup button,
                    disabled: true,
                    scale: 'medium',
                    id: 'savesettingBtn',
                    height: 30, 
                    handler: function() {
                        saveEntitlementBtn.setDisabled(true);
                        me.hide();
                        me.__parent.enable();
                        Ext.getCmp('checkentitlement').el.dom.click();
                    },
                });

                settingToolBar.add(saveEntitlementBtn);    
                me.add(settingToolBar);         
            },
            stringToBoolean: function( string ) {
                if(string != null){
                    switch( string.toLowerCase().trim() ){
                        case "true": case "yes": case "1": return true;
                        case "false": case "no": case "0": case null: return false;
                        default: return Boolean(string);
                    }
                }
            },
            updateAccountProductSettings:  function(string){
                // If Account is selected for Entitilement Type, then disable Warranty & Both and Counters and Both
                if(string != null && string == 'Account'){
                    Ext.getCmp('entitleUsingWarranty').hide(); 
                    Ext.getCmp('entitleUsingBoth').hide(); 
                    Ext.getCmp('attributeCounter').hide();
                    Ext.getCmp('attributeBoth').hide();
                    Ext.getCmp('attributeDates').setValue(true);
                    Ext.getCmp('entitleUsingSC').setValue(true)
                }
                else{
                    Ext.getCmp('entitleUsingWarranty').show(); 
                    Ext.getCmp('entitleUsingBoth').show(); 
                    Ext.getCmp('attributeCounter').show();
                    Ext.getCmp('attributeBoth').show();
                }
                
            }
        });
    }
})();



