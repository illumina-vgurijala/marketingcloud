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


