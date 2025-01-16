
(function(){

    var appImpl = SVMX.Package("com.servicemax.client.admin.appfilters.ui.desktop.api");

    appImpl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("APFT");

        Ext.define("com.servicemax.client.admin.appfilters.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            cls: "apft-root-container",
            layout: 'anchor',
            width: "100%",
            height: 520,            
            __parent: this,
            __resultsViewPanel: null,
            __runOpts: null,
            constructor: function(config) {
                config = Ext.apply({
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            padding: '0',
                            text : TS.T("TAG002", "Back To Setup Home"),           
                            handler: function(e, el, owner, tool) {
                                var tempStore = Ext.data.StoreManager.lookup('appStore');
                                var records = tempStore.getModifiedRecords();
                                var isAtLeastOneRecordModified = (records.length > 0) ? true : false;
                                if(isAtLeastOneRecordModified){
                                    Ext.Msg.show({
                                        title : TS.T("TAG022", "Warning"),
                                        msg : TS.T("TAG019", "Changes have not been saved. Are you sure to discard the changes?"),
                                        width : 300,
                                        closable : false,
                                        icon : Ext.MessageBox.WARNING,
                                        buttons : Ext.Msg.YESNO,
                                        buttonText : {
                                            yes : TS.T("TAG020","OK"),
                                            no : TS.T("TAG021","Cancel"),
                                        },
                                        fn : function(buttonValue, inputText, showConfig){
                                            if(buttonValue === 'yes'){
                                                var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                                if((typeof sforce != 'undefined') && (sforce != null)){
                                                    urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup"; //Added for the story BAC-4797
                                                    sforce.one.navigateToURL(urlString);
                                                }
                                                else{
                                                    window.location.href = urlString;
                                                }
                                            }
                                        }
                                    });
                                }
                                else{
                                    var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                    if((typeof sforce != 'undefined') && (sforce != null)){
                                        urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup"; //Added for the story BAC-4797
                                        sforce.one.navigateToURL(urlString);
                                    }
                                    else{
                                        window.location.href = urlString;
                                    }
                                }
                            }
                        }]
                    },
                    collapsible: false,
                    title: SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" : TS.T("TAG001", "SFM App Permissions"),
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

                this.__libraryPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    collapsible: false,
                    region: "center",
                    width: "100%",
                    anchor: "100%", 
                    layout: 'anchor',
                    layout: {
                        type: "anchor",
                        align: "stretch"
                    }
                });
                this.add(this.__libraryPanel);

                //toolbar for dropdown
                var toolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    dock: "top", height: 73, width: '100%', layout: 'hbox', align: 'stretchmax'
                });

                //Dropdown for filter list
                var filterListStore = SVMX.create('Ext.data.ArrayStore',{ fields: ['name', 'label'] });
                this.__filterListStore = filterListStore;

                var filterListDropDown = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    name: 'label', fieldLabel: TS.T("TAG006","Select Process Type"),
                    labelField:'label', valueField:'name', displayField: 'label', defaultValue: TS.T("TAG003", "--None--"), value: TS.T("TAG003", "--None--"),
                    queryMode: 'local', editable: false, store: filterListStore, labelAlign: 'top', 
                    //height: 30, 
                    width: 280,
                    labelCls: 'svmx-apft-dropdown',
                    style: {
                        marginLeft: '20px',
                    },
                    labelSeparator : "",
                    listeners: {
                        beforeselect: function( combo, records, eOpts ){
                            var oldValue=this.getValue();
                            var modifiedRec = me.__tableStore.getModifiedRecords();
                            var hasModifiedRecords = (modifiedRec.length > 0) ? true : false;
                            if(hasModifiedRecords){
                                Ext.Msg.show({
                                    title : TS.T("TAG022", "Warning"),
                                    msg : TS.T("TAG019", "Changes have not been saved. Are you sure to discard the changes?"),
                                    width : 300,
                                    closable : false,
                                    icon : Ext.MessageBox.WARNING,
                                    buttons : Ext.Msg.YESNO,
                                    buttonText : {
                                        yes : TS.T("TAG020","OK"),
                                        no : TS.T("TAG021","Cancel"),
                                    },
                                    fn : function(buttonValue, inputText, showConfig){
                                        if(buttonValue === 'yes'){
                                            var objectValue = records.get('name');
                                            if(objectValue !== 'None'){
                                                me.__objectListDropDown.setDisabled(false);
                                                me.deliveryEngine.getAllSourceObjects(objectValue);
                                            }
                                            else{
                                                me.__objectListDropDown.setDisabled(true);
                                            }
                                            me.__resultsViewPanel.hide();
                                            me.__objectListDropDown.setValue(TS.T("TAG003", "--None--"));
                                            me.__tableStore.removeAll();
                                        }
                                        else{
                                            combo.setValue(oldValue);
                                        }
                                    }
                                });
                            }
                            else{
                                var objectValue = records.get('name');
                                if(objectValue !== 'None'){
                                    me.__objectListDropDown.setDisabled(false);
                                    me.deliveryEngine.getAllSourceObjects(objectValue);
                                }
                                else{
                                    me.__objectListDropDown.setDisabled(true);
                                }
                                me.__resultsViewPanel.hide();
                                me.__objectListDropDown.setValue(TS.T("TAG003", "--None--"));
                                me.__tableStore.removeAll();
                            }
                        },
                        afterrender: function(combo) { 
                            combo.setValue(this.defaultValue);
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });
                toolbar.addItemsLeft(filterListDropDown);                
                this.__filterListDropDown = filterListDropDown;

                //Dropdown for list of Objects
                var objectListStore = SVMX.create('Ext.data.ArrayStore',{ fields: ['name', 'label'] });
                this.__objectListStore = objectListStore;

                var objectListDropDown = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'objectDropDown', name: 'label', fieldLabel: TS.T("TAG007","Select Object"), labelWidth: 150, labelField:'label', 
                    valueField:'name', displayField: 'label', defaultValue: TS.T("TAG003", "--None--"), 
                    value: TS.T("TAG003", "--None--"), queryMode: 'local', disabled: true, store: objectListStore, 
                    //height: 30, 
                    width: 280, labelAlign: 'top',
                    style: {
                        marginLeft: '22px'
                    },
                    labelCls: 'svmx-apft-dropdown',
                    labelSeparator : "",
                    listeners: {
                        beforeselect: function( combo, records, eOpts ){
                            var oldValue=this.getValue();
                            var modifiedRec = me.__tableStore.getModifiedRecords();
                            var hasModifiedRecords = (modifiedRec.length > 0) ? true : false;
                            if(hasModifiedRecords){
                                Ext.Msg.show({
                                    title : TS.T("TAG022", "Warning"),
                                    msg : TS.T("TAG019", "Changes have not been saved. Are you sure to discard the changes?"),
                                    width : 300,
                                    closable : false,
                                    icon : Ext.MessageBox.WARNING,
                                    buttons : Ext.Msg.YESNO,
                                    buttonText : {
                                        yes : TS.T("TAG020","OK"),
                                        no : TS.T("TAG021","Cancel"),
                                    },
                                    fn : function(buttonValue, inputText, showConfig){
                                        if(buttonValue === 'yes'){
                                            var filterValue = me.__filterListDropDown.getValue();
                                            var objectValue = records.get('name');
                                            if(objectValue !== 'None'){
                                                me.deliveryEngine.getApplicationFilter(filterValue, objectValue);
                                                me.__resultsViewPanel.show();
                                                me.__saveButton.setDisabled(true);
                                            }
                                            else{
                                                me.__tableStore.removeAll();
                                                me.__resultsViewPanel.hide();
                                            }
                                        }
                                        else{
                                            combo.setValue(oldValue);
                                        }
                                    }
                                });
                            }
                            else{
                                var filterValue = me.__filterListDropDown.getValue();
                                var objectValue = records.get('name');
                                if(objectValue !== 'None'){
                                    me.deliveryEngine.getApplicationFilter(filterValue, objectValue);
                                    me.__resultsViewPanel.show();
                                    me.__saveButton.setDisabled(true);
                                }
                                else{
                                    me.__tableStore.removeAll();
                                    me.__resultsViewPanel.hide();
                                }
                            }
                        },
                        afterrender: function(combo) { 
                            combo.setValue(this.defaultValue);
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });
                toolbar.addItemsLeft(objectListDropDown);
                this.__objectListDropDown = objectListDropDown;

                //Help Icon
                var helpIcon = { iconCls : 'svmx-appfilter-help-icon', cursor:'pointer', scale : 'small',
                    tooltip: TS.T( 'TAG023', 'Help'), href: TS.T( 'HLPURL', 'http://userdocs.servicemax.com:8080/ServiceMaxHelp/Summer16/en_us/svmx_redirector.htm?uid=SFM|SFMAppPermissions'),
                    style: {
                        marginRight: '25px',
                    }
                };
                toolbar.addItemsRight(helpIcon);

                //Save button
                var saveBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG005", "Save"), height: 30, width: 100, disabled: true,
                    style: {
                        marginRight: '1px',
                        marginTop: '13px'
                    },
                    handler: function() {
                        var keyword = me.__searchtext.getValue();
                        var tempStore = me.__tableStore;    
                        tempStore.clearFilter();
                        var modifiedRecords = tempStore.getModifiedRecords();
                        me.deliveryEngine.saveApplicationFilter(modifiedRecords);
                    }
                });
                this.__saveButton = saveBtn;

                //Adding toolbar to main panel
                this.__libraryPanel.add(toolbar);
                this.__toolbar = toolbar;

                // search text field
                var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    cls: 'svmx-text-filter-icon',  width: 587, emptyText: Ext.String.htmlDecode(TS.T("TAG004", "Search for process name or process IDs")), selectOnFocus: true,
                    listeners: {
                        change: function(f, e) {
                            var keyword = searchtext.getValue();
                            me.__resultsViewPanel.getStore().clearFilter();
                            if (!!keyword) {
                                var filters = [ new Ext.util.Filter({ filterFn: function (item) {
                                    //return item.get('processId').toLowerCase().indexOf(keyword.toLowerCase()) > -1 || item.get('name').toLowerCase().indexOf(keyword.toLowerCase()) > -1;
                                    //Defect 033709 fix
                                    return Ext.String.htmlDecode(item.get('processId')).toLowerCase().indexOf(keyword.toLowerCase()) > -1 || Ext.String.htmlDecode(item.get('name')).toLowerCase().indexOf(keyword.toLowerCase()) > -1;
                                }})];
                                me.__resultsViewPanel.getStore().filter(filters);
                            }
                        }
                    }
                });
                this.__searchtext = searchtext;
                
                Ext.define('appModel', {
                    extend: 'Ext.data.Model',
                    fields: [
                        {name: 'name',                  type: 'string'},
                        {name: 'processId',             type: 'string'},
                        {name: 'description',           type: 'string'},
                        {name: 'onlineEnabled',         type: 'boolean'},
                        {name: 'iPadEnabled',           type: 'boolean'},
                        {name: 'iPhoneEnabled',         type: 'boolean'},
                        {name: 'androidPhoneEnabled',   type: 'boolean'},
                        {name: 'androidTabletEnabled',  type: 'boolean'},
                        {name: 'windowsEnabled',        type: 'boolean'}
                    ]
                });

                var tableStore = SVMX.create('Ext.data.ArrayStore', {
                    model: 'appModel',
                    storeId: 'appStore',
                    proxy: {
                        type: 'memory'
                    },
                    folderSort: true
                });
                this.__tableStore = tableStore;

                var tableGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite', {
                    width: "100%", collapsible: false, store: tableStore, multiSelect: false, border: false,
                    disableSelection: true, hidden: true, height: 520,
                    tbar: [
                      searchtext,  '->', saveBtn
                    ],
                    style: {
                        marginLeft: '20px',
                        marginRight: '25px'
                    },
                    columns: [{
                        text: TS.T("TAG008","Process ID"),                        
                        dataIndex: 'processId',
                        sortable: true,
                        baseCls: 'svmx-noncheckcolumn-header-text',
                        flex: 1.8/10,
                        menuDisabled: true
                    },{                        
                        text: TS.T("TAG009","Process Name"),                       
                        sortable: true,
                        dataIndex: 'name',
                        baseCls: 'svmx-noncheckcolumn-header-text',
                        flex: 1.8/10,
                        menuDisabled: true
                    },{
                        text: TS.T("TAG010","Description"),
                        flex: 2.2/10,
                        dataIndex: 'description',
                        sortable: false,
                        baseCls: 'svmx-noncheckcolumn-header-text',
                        menuDisabled: true
                    }, {
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG011","Online"),
                        dataIndex: 'onlineEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    },{
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG012","iPad"),
                        dataIndex: 'iPadEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    },{
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG013","Android Tablet"),
                        dataIndex: 'androidTabletEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    },{
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG014","Windows"),
                        dataIndex: 'windowsEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    },{
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG015","iPhone"),
                        dataIndex: 'iPhoneEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    },{
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG016","Android Phone"),
                        dataIndex: 'androidPhoneEnabled',
                        flex: 0.7/10,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        baseCls: 'svmx-checkcolumn-header-text',
                        listeners: {
                            checkchange: function(checkbox, rowIndex, checked, eOpts) {
                                me.enableDisableSaveButton();
                            }
                        }
                    }],
                    listeners: {
                        viewready: function (grid) {
                            var view = grid.view;
                            // record the current cellIndex
                            grid.mon(view, {
                                uievent: function (type, view, cell, recordIndex, cellIndex, e) {
                                    grid.cellIndex = cellIndex;
                                    grid.recordIndex = recordIndex;
                                }
                            });
                            
                            grid.tip = Ext.create('Ext.tip.ToolTip', {
                                target: view.el,
                                delegate: '.svmx-grid-cell',
                                trackMouse: true,
                                listeners: {
                                    beforeshow: function updateTipBody(tip) {
                                        if (!Ext.isEmpty(grid.cellIndex) && grid.cellIndex !== -1) {
                                            header = grid.headerCt.getGridColumns()[grid.cellIndex];
                                            var val = grid.getStore().getAt(grid.recordIndex).get(header.dataIndex);
                                            tip.update(val+'');
                                        }
                                    }
                                }
                            });
                        }
                    }
                });

                 // results view
                this.__resultsViewPanel = tableGrid;
                this.__libraryPanel.add(this.__resultsViewPanel);
                // end results view

                //loading data in the grid Store
                this.__filterListStore.loadData(this.metaModel.__data);
                this.resize();
            },

            enableDisableSaveButton: function(){
                var modifiedRecords = this.__tableStore.getModifiedRecords();
                var isModified = (modifiedRecords.length > 0) ? true : false;
                this.__saveButton.setDisabled(!isModified);
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
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "APFT.CHANGE_APP_STATE", this, p);
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
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "APFT.CHANGE_APP_STATE", this, p);
                currentApp.triggerEvent(evt);
            },

            getDeliveryEngine: function() {
                return this.deliveryEngine;
            }
        });


        Ext.define('Ext.ux.CheckBoxColumnEditor', {
        extend: 'Ext.grid.column.Column',
        alias: 'widget.checkColumnEditor',

        /**
         * @cfg {Boolean} [stopSelection=true]
         * Prevent grid selection upon mousedown.
         */
        stopSelection: true,        

        tdCls: Ext.baseCSSPrefix + 'grid-cell-checkcolumn',

        constructor: function() {
            this.addEvents(
                /**
                 * @event beforecheckchange
                 * Fires when before checked state of a row changes.
                 * The change may be vetoed by returning `false` from a listener.
                 * @param {Ext.ux.CheckColumn} this CheckColumn
                 * @param {Number} rowIndex The row index
                 * @param {Boolean} checked True if the box is to be checked
                 */
                'beforecheckchange',
                /**
                 * @event checkchange
                 * Fires when the checked state of a row changes
                 * @param {Ext.ux.CheckColumn} this CheckColumn
                 * @param {Number} rowIndex The row index
                 * @param {Boolean} checked True if the box is now checked
                 */
                'checkchange'
            );
            this.callParent(arguments);
        },

        /**
         * @private
         * Process and refire events routed from the GridView's processEvent method.
         */
        processEvent: function(type, view, cell, recordIndex, cellIndex, e, record, row) {
            var me = this,
                key = type === 'keydown' && e.getKey(),
                mousedown = type == 'mousedown';

            if (mousedown || (key == e.ENTER || key == e.SPACE)) {
                var dataIndex = me.dataIndex,
                    checked = !record.get(dataIndex);

                // Allow apps to hook beforecheckchange
                if (me.fireEvent('beforecheckchange', me, recordIndex, checked) !== false) {
                    record.set(dataIndex, checked);
                    me.fireEvent('checkchange', me, recordIndex, checked);

                    // Mousedown on the now nonexistent cell causes the view to blur, so stop it continuing.
                    if (mousedown) {
                        e.stopEvent();
                    }

                    // Selection will not proceed after this because of the DOM update caused by the record modification
                    // Invoke the SelectionModel unless configured not to do so
                    if (!me.stopSelection) {
                        view.selModel.selectByPosition({
                            row: recordIndex,
                            column: cellIndex
                        });
                    }

                    // Prevent the view from propagating the event to the selection model - we have done that job.
                    return false;
                } else {
                    // Prevent the view from propagating the event to the selection model if configured to do so.
                    return !me.stopSelection;
                }
            } else {
                return me.callParent(arguments);
            }
        },

        // Note: class names are not placed on the prototype bc renderer scope
        // is not in the header.
        renderer : function(value){
            var cssPrefix = Ext.baseCSSPrefix,
                cls = [cssPrefix + 'grid-checkheader'];

            if (value) {
                cls.push(cssPrefix + 'grid-checkheader-checked');
            }
            return '<center><div class="' + cls.join(' ') + '">&#160;</div></center>';
        }
    });

    }
})();