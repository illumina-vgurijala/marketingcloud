(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.schedule");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        Ext.define('com.servicemax.client.spm.ui.desktop.api.schedule.Schedule', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.schedule',

           title: TS.T("TAG003", "Schedule & Notifications"), layout: 'fit', border: false, autoScroll: true, 

            constructor: function (config) {
                config = Ext.apply({
                    dockedItems: [{
                        xtype: 'toolbar',
                        dock: 'top',                        
                        items: [
                            { xtype: 'tbfill' }, 
                            {                                 
                                tooltip : 'Save', 
                                xtype: 'svmx.button', //width: 28, height: 24,
                                text: 'Save',
                                //iconCls : "svmx-spm-add-icon",scale   : "medium",
                                handler: SVMX.proxy(this, function(){    
                                    this.__parent.saveProcessConfig({
                                        processId: this.processId,
                                        scheduleInfo: this.getData()
                                    });                            
                                })
                            }
                        ]                        
                    }]
                    /*buttons: [{
                        text: 'Apply',
                        handler: SVMX.proxy(this, function() {
                            var data = this.topPanel.down('form').getForm().getValues();
                            var selections = this.topPanel.down('grid').getSelectionModel().getSelection();

                            data.selections = [];                            
                            selections.forEach(function(item){
                                data.selections.push(item.data.processId);
                            });
                            data.raw = this.raw;
                            this.__parent.saveScheduleConfig(data);
                        })
                    }]*/
                }, config || {});
                this.callParent(arguments);
            },

            initComponent: function (config) {
                this.callParent(arguments);
                this.topPanel = this.add({
                    title: 'SPM Report Schedule', header: false,
                    anchor: '100%', autoScroll: true, border: false
                });
            },

            loadRecord: function(record){
                this.scheduleId = record.data ? record.data.details.scheduleId: null;
                this.editRecord(record);
            },

            /*onActivate: function() {
                if(this.topPanel) this.topPanel.destroy();
                this.topPanel = this.add({
                    //title: 'SPM Report Schedule',
                    anchor: '100%', autoScroll: true
                });
                
                this.metaModel.getScheduleList( SVMX.proxy(this, function(data) {
                    if(data){
                        var toolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                            dock: "top"
                        });
                        
                        var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                            cls: 'svmx-text-filter-icon',
                            emptyText: 'Search for SPM Report', width: "40%", height: 30, 
                            style: { 
                                marginLeft: '20px', 
                                marginRight: '2px', 
                                marginTop: '0px', 
                                marginBottom: '0px'
                            },

                            listeners: {
                                change: SVMX.proxy(this, function(f, e) {
                                    this.topPanel.listPanel.store.clearFilter();
                                    this.topPanel.listPanel.store.filter('processName',  new RegExp( Ext.escapeRe( searchtext.getValue() ), 'i') );                                    
                                })
                            }
                        });
                        toolbar.addItemsLeft(searchtext);
                        this.topPanel.addDocked(toolbar);

                        this.raw = data.raw;
                        this.topPanel.listPanel = this.topPanel.add({ 
                            xtype: 'spm.report.schedulelistpanel', 
                            itemId: this.itemId + '_schedulelistpanel', border: true,
                            fields: data.fields, __parent: this
                        });
                        this.topPanel.listPanel.store.loadData( (data && data.records) ? data.records : [] );
                    }
                }));
            },*/

            getData: function() {
                var data  = this.topPanel.down('form').getForm().getValues();
                data.scheduleId = this.scheduleId;
                return data;
            },

            loadData: function(record) {
            },

            editRecord: function(record){
                if(this.topPanel.editPanel){
                  this.topPanel.editPanel.destroy();  
                } 
                this.topPanel.editPanel = this.topPanel.add({ 
                    xtype: 'spm.schedule.scheduleform', 
                    itemId: 'scheduleform', anchor: '100%',
                    metaModel: this.metaModel,
                    processId: this.processId
                });

                if(record.data) {
                    var form = this.topPanel.editPanel.getForm();
                    form.setValues(record.data.details);
                    if(record.data.details.weekOn){
                        form.findField('weekOn').setValue(record.data.details.weekOn);
                    }
                    if(record.data.details.dayToRun){
                        form.findField('dayToRun').setValue(record.data.details.dayToRun);
                    }
                }
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ScheduleListPanel', {
            extend: 'Ext.grid.Panel',
            alias:'widget.spm.report.schedulelistpanel',

            constructor: function (config) {
                var me = this;

                config = Ext.apply({
                    autoScroll: false,
                    columns: [
                        { text: 'SPM Report Name',  dataIndex: 'processName', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: 'Period',  dataIndex: 'period', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: 'Last Modified', dataIndex: 'lastModified', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } }
                    ],
                    store: {
                        storeId: config.itemId + '_store',
                        fields: config.fields, proxy: { type: 'memory' }
                    },
                    /*selModel: SVMX.create('Ext.selection.CheckboxModel', { 
                        mode: 'SIMPLE'
                    }),*/
                    listeners: {
                        select: function( grid, record, index, eOpts ){
                            //me.__parent.editRecord(record);
                        }
                    }
                }, config || {});
                this.callParent(arguments); 
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.schedule.ScheduleForm', {
            extend: 'Ext.form.Panel',
            alias:'widget.spm.schedule.scheduleform',

            layout: 'anchor', padding:10, border: false, autoScroll: true,bodyPadding: 5,
            defaults: { labelAlign: 'top', anchor: '100%', padding:'10px' }, buttonAlign: 'left',

            constructor: function(config){
                config = Ext.apply({
                    
                }, config || {});
                this.callParent(arguments); 
            },

            initComponent: function(){
                this.callParent(arguments);

                var me = this;
                me.TS = { T: function(tagId, val){ return val; } };

                var onStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'weekOn'], 
                    data: [
                        ['Monday', TS.T("TAG036", 'Monday')], 
                        ['Tuesday', TS.T("TAG037",'Tuesday')], 
                        ['Wednesday', TS.T("TAG038",'Wednesday')], 
                        ['Thursday', TS.T("TAG039",'Thursday')], 
                        ['Friday', TS.T("TAG040",'Friday')], 
                        ['Saturday', TS.T("TAG041",'Saturday')], 
                        ['Sunday', TS.T("TAG042",'Sunday')]
                    ]
                });

                var atStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'timeAt'],
                    data: [
                        [1, '12:00 '+ TS.T("TAG072", 'am')], [2, '1:00 '+ TS.T("TAG072", 'am')], [3, '2:00 '+ TS.T("TAG072", 'am')], [4, '3:00 '+ TS.T("TAG072", 'am')], 
                        [5, '4:00 '+ TS.T("TAG072", 'am')], [6, '5:00 '+ TS.T("TAG072", 'am')], [7, '6:00 '+ TS.T("TAG072", 'am')], 
                        [8, '7:00 '+ TS.T("TAG072", 'am')], [9, '8:00 '+ TS.T("TAG072", 'am')], [10, '9:00 '+ TS.T("TAG072", 'am')], [11, '10:00 '+ TS.T("TAG072", 'am')], [12, '11:00 '+ TS.T("TAG072", 'am')], [13, '12:00 '+ TS.T("TAG073", 'pm')], [14, '1:00 '+ TS.T("TAG073", 'pm')], 
                        [15, '2:00 '+ TS.T("TAG073", 'pm')], [16, '3:00 '+ TS.T("TAG073", 'pm')], [17, '4:00 '+ TS.T("TAG073", 'pm')], [18, '5:00 '+ TS.T("TAG073", 'pm')], [19, '6:00 '+ TS.T("TAG073", 'pm')], [20, '7:00 '+ TS.T("TAG073", 'pm')], [21, '8:00 '+ TS.T("TAG073", 'pm')], 
                        [22, '9:00 '+ TS.T("TAG073", 'pm')], [23, '10:00 '+ TS.T("TAG073", 'pm')], [24, '11:00 '+ TS.T("TAG073", 'pm')]
                    ]
                });

                var frequecyStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'period'],
                    data: [
                        ['Daily', TS.T("TAG043", 'Daily')], 
                        ['Weekly', TS.T("TAG044",'Weekly')],
                        ['Monthly', TS.T("TAG045",'Monthly')]
                    ]
                });

                var dayStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'day'],
                    data: [
                        [1, '1'], [2, '2'], [3, '3'], [4, '4'], [5, '5'], 
                        [6, '6'], [7, '7'], [8, '8'], [9, '9'], [10, '10'], 
                        [11, '11'], [12, '12'], [13, '13'], [14, '14'], [15, '15'], 
                        [16, '16'], [17, '17'], [18, '18'], [19, '19'], [20, '20'], 
                        [21, '21'], [22, '22'], [23, '23'], [24, '24'], [25, '25'],
                        [26, '26'], [27, '27'], [28, '28'], [29, '29'], [30, '30'], [31, '31']
                    ]
                });

                var timezoneStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'name'],
                    proxy: { type: "memory" },
                    data: me.metaModel.getTimezoneList()
                });

                var fieldSet = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG053",'Choose the times and days to run metric generation engine'),
                    layout: 'anchor', padding:'10'
                });

                me.add( fieldSet );

                var timezone = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'timezone', name: 'timezone', fieldLabel: TS.T("TAG018",'Time Zone'),
                    labelField:'label', valueField:'Id', displayField: 'name', margins: '0 5 0 0',
                    queryMode: 'local', editable: false, anchor: '50%', flex: 1,
                    store: timezoneStore, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var container = fieldSet.add({
                    xtype: 'fieldcontainer', layout: {type: 'hbox', align: 'spaced'},                          
                    anchor: '100%', fieldDefaults: {labelAlign: 'top'},
                });

                fieldSet.add(container);

                container.add( timezone );

                container.add({
                    xtype:'tbspacer',
                    flex:1
                }); 

                container.add({

                    xtype:'label', anchor: '50%', align: 'right', style: "text-decoration: underline !important;",
                    html:'<a href="#" align: "right" style: "text-decoration: underline !important;">' + TS.T("TAG049", 'Run Now') + '</a>', 
                    listeners: {
                        afterRender:function() { 
                            this.el.on('click',function() { 
                                me.metaModel.executeBatch(me.processId, function(result){
                                    if(result){
                                        Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                                    }
                                });
                            });
                        }
                    }
                });
                /*
                container.add({
                        xtype: 'svmx.button', text: TS.T("TAG049", 'Run Now'), align: 'right',
                        anchor: '50%', tooltip: TS.T("TAG015", 'Execute report now'),
                        handler: function(){
                            var me = this.up('form');
                            me.metaModel.executeBatch(me.processId, function(result){
                                if(result){
                                    Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                                }
                            });
                        }
                    });*/

                var period = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'period', name: 'period', fieldLabel: TS.T("TAG017",'Period'),
                    labelField:'period', valueField:'Id', displayField: 'period', defaultValue: 'Daily', value: 'Daily',
                    queryMode: 'local', editable: false, store: frequecyStore, flex: 1, anchor: '30%', labelAlign: 'top', padding:'10',
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            switch( newValue ) {
                                case TS.T("TAG043",'Daily'): {
                                    me.__on.reset();
                                    me.__on.setValue( ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'] );
                                    me.__on.hide();
                                    me.__dayToRun.hide();
                                    break;
                                }
                                case TS.T("TAG044",'Weekly'): {
                                    me.__dayToRun.hide();
                                    me.__on.reset();
                                    me.__on.setValue( [TS.T("TAG036",'Monday')] );
                                    me.__on.show();                                  
                                    break;
                                }
                                case TS.T("TAG045",'Monthly') : {

                                    me.__on.reset();
                                    me.__on.hide();
                                    me.__dayToRun.show();
                                }
                            }
                        }
                    },
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                fieldSet.add(period);

                var weekOn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'weekOn', name: 'weekOn', fieldLabel: TS.T("TAG020",'Create Schedule on'),
                    labelField:'label', valueField:'Id', displayField: 'weekOn',
                    queryMode: 'local', editable: false, multiSelect: true, anchor: '30%', flex: 1, 
                    store: onStore, value: 'Monday', hidden: true, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                me.__on = fieldSet.add(weekOn);

                var dayToRun = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'dayToRun', name: 'dayToRun', fieldLabel: TS.T("TAG021",'Day'),
                    labelField:'label', valueField:'Id', displayField: 'day', 
                    queryMode: 'local', editable: false, multiSelect: false, anchor: '30%', flex: 1, 
                    store: dayStore, value: 1, hidden: true, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                me.__dayToRun = fieldSet.add(dayToRun);

                var timeAt = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'timeAt', name: 'timeAt', fieldLabel: TS.T("TAG019",'At'),
                    labelField:'label', valueField:'timeAt', displayField: 'timeAt',
                    queryMode: 'local', editable: false, anchor: '30%', margins: '0 0 0 5', flex: 1,
                    store: atStore, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                fieldSet.add(timeAt);

                /*me.add({
                    xtype: 'checkboxfield', 
                    boxLabel  : 'Enable Email Notification',
                    name      : 'enableEmailNotification',
                    listeners: {
                        change: function(ele, val){
                            if(val) email.show(); 
                            else email.hide();
                        }
                    }
                });*/

                var fieldSetNotification = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG054",'Specify recipients of notifications and alerts'),
                    layout: 'anchor', padding:'10'
                });

                me.add( fieldSetNotification );

                var emailOnSuccess = fieldSetNotification.add({
                    xtype: 'textfield', fieldLabel : TS.T("TAG022",'Email on Job Execution'), name : 'emailOnSuccess',
                    anchor: '50%', labelAlign: 'top', padding:'10', margins: '0 0 0 5'
                });
            }
        }); 
    }
})();