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


