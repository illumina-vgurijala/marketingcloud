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