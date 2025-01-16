(function () {

    var appImpl = SVMX.Package("com.servicemax.client.triggersetting.ui.desktop.api");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("TRIGGERSETTING");

        Ext.define("com.servicemax.client.triggersetting.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'triggersetting-root-container', // ToDo : Talk to Jessie to create the class
            width: '100%',
            id:'triggersetting',
            layout: 'anchor',
            height: 520,    
            constructor: function (config) {
                config = Ext.apply({
                    title: TS.T('TAG001', 'Trigger Setting'), 
                    titleAlign: 'center', collapsible: false, 
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            cls : 'triggersetting-back-btn', 
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

                var triggerToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "top",
                    autoHeight: true,
                });

                var tabFill = SVMX.create("Ext.Toolbar.Fill",{ });
                triggerToolBar.add(tabFill);


                me.objectPicklistStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'apiname'}, {name: 'label'}],
                    proxy: {
                        type: "memory"
                    },
                    data: this.__engine.__objectlist != null ? this.__engine.__objectlist: [],
                });

                var objectPicklist = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'objectPicklist', name: 'objectPicklistName', 
                    fieldLabel: TS.T("TAG003",'Select Object'),
                    labelField:'label', valueField:'apiname', 
                    //displayField: 'apiname',
                    displayField: 'label', //Added for fixing defect 044689
                    editable: false,
                    labelSeparator: '',
                    width: 350,
                    defaultAlign: 'center',
                    queryMode: 'local', store: me.objectPicklistStore,
                    listeners:{
                        select: function( combo, records, eOpts ){
                            var parentCmp = Ext.getCmp('triggersetting');
                            // Get the trigger value for Object Name

                            parentCmp.__engine.getObjectTriggerConfig(records[0].data.apiname, function(result){
                                if(result.success){
                                    parentCmp.triggerStore.loadData(result.triggersettingvalue);
                                    Ext.getCmp('triggerEnDisSec').show();
                                }
                                else{
                                    SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messagelist[0], 7000, 'success');
                                }
                            });
                        }
                    }
                });

                
                triggerToolBar.add(objectPicklist);

                var tabFill = SVMX.create("Ext.Toolbar.Fill",{ });
                triggerToolBar.add(tabFill);

                var saveBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: TS.T("TAG004",'Save'), //Icon Class for lookup button,
                    scale: 'medium',
                    style: 'margin-left: 3px !important',
                    height: 30, 
                    id: 'saveBtn',
                    cls: 'triggersetting-save-btn',
                    handler: function() {
                        var config = {};
                        config.triggersettingvalue = [];

                        me.triggerStore.data.items.forEach(function(object){
                            config.triggersettingvalue.push(object.data);
                        })
 
                        me.__engine.saveTriggerSettingConfig(config, function(result){
                            if(!result.success){
                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(result.messagelist[0], 7000, 'success');
                            } 
                            else{
                                SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(TS.T("TAG023", 'Save Successful'), 7000, 'success');
                            }   
                        });    
                    
                        
                    }
                });

                var cancelBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: TS.T("TAG005",'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    style: 'margin-left: 3px !important',
                    cls: 'triggersetting-cancel-btn',
                    height: 30, 
                    handler: function() {
                        var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                        if((typeof sforce != 'undefined') && (sforce != null)){
							urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup"; //Added for the story BAC-5255
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location.href = urlString;
                        }
                    }
                });

                triggerToolBar.add(saveBtn);

                triggerToolBar.add(cancelBtn);

                triggerToolBar.add({
                    //iconCls : 'triggersetting-help-icon ',
                    cursor:'pointer', 
                    scale : 'large', 
                    cls: 'triggersetting-help',                                 
                    tooltip: TS.T("TAG011", 'Trigger Control Help'),
                    href: TS.T("TAG010", 'http://helplink'),
                    width: 32,
                    height: 32,
                    margin: '0 0 0 15px',
                });

                me.add(triggerToolBar);

                var triggerLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: '<span>'+ TS.T("TAG008", 'Enable/ Disable Trigger: ') +'</span>',
                    cls: 'triggersetting-enable-title',
                });


                me.triggerStore =  SVMX.create('Ext.data.Store', {
                    fields: [{name: 'triggername'}, {name: 'isenabled',  type: 'boolean'}],
                    proxy: {
                        type: "memory"
                    },
                    data:[]
                });

                var triggerGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite', {
                    width: "100%", collapsible: false, store: me.triggerStore, multiSelect: false, border: false,
                    disableSelection: true,
                    id: 'triggerGrid',
                    columns: [{
                        text: TS.T("TAG006","Trigger Name"),                        
                        dataIndex: 'triggername',
                        sortable: true,
                        flex: 1.8/10,
                    },
                    {
                        xtype: 'checkColumnEditor',
                        text: TS.T("TAG007","Enable/Disable"),
                        dataIndex: 'isenabled',
                        flex: 0.7/10,
                        menuDisabled: true,
                        align: 'center',
                    }],
                });

                var triggerNote = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    html: '<span>'+ TS.T("TAG009", 'The trigger(s) displayed on this page get executed only when enabled. This is an org-wide setting.') +'</span>',
                    cls: 'triggersetting-enable-label',
                });

                
                var triggerSection = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXSection", {
                    id:'triggerEnDisSec',
                    bodyPadding: 10,
                    hidden: true,
                    header:false,
                    border: false,
                    items: [triggerLabel, triggerGrid],
                });

               
                me.add(triggerSection);

                me.add(triggerNote);


            },
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