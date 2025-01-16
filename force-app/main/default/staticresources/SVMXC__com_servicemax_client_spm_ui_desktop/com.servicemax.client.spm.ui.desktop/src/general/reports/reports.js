(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.reports");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        var isAccountSummary = true; //Variable to track if the current view is for Account-Summary Flow.

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.report', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.report',
			cls:'spm-components-container',
            layout: { type: 'vbox', align: 'stretch' }, border: false,

            initComponent: function(){
                this.callParent(arguments); 
            },

            loadData: function(data, isNewRecord){
                /*if(!!isNewRecord){
                    this.destroyProcessListPanel();
                }*/
                
                isAccountSummary = (this.processId != 'AccountSummary') ? false : true;               

                this.destroyProcessListPanel();
                this.destroyEditProcessPanel();

                this.listPanel = this.add({ 
                    xtype: 'spm.report.processlistpanel', 
					cls:'spm-components-tab', processId: this.processId,
                    itemId: this.tabPanelId + '_processlistpanel', 
                    fields: data.fields, data: (data && data.records) ? data.records : [],
                    __parent: this, padding: '0 0 10 0'
                });
                
                //var record = this.listPanel.store.getAt(0);
                //if(record){
                //    this.editRecord(record);
                //}
            },

            editRecord: function(record){                
                isAccountSummary = (this.processId != 'AccountSummary') ? false : true;                
                this.destroyEditProcessPanel();

                var tabPanel = this.add({
                    flex:1, xtype: 'spm.report.editprocesspanel',
                    itemId: this.tabPanelId + '_editprocesspanel', border: false,
                    record: record, __parent: this
                }); 
            },

            getMetaModel: function(){
                return this.__parent.metaModel;
            },

            getFirstDefaultProcessConfig : function(processId){
                return this.getMetaModel().getFirstDefaultProcessConfig(processId);
            },

            /*refreshEditPanel: function(data){
                setTimeout(SVMX.proxy(this, function(){
                    data.isNewRecord = true;
                    this.editRecord(data);
                }), 1);
            },

            getDefaultProcessConfig: function(method){
                return this.getMetaModel().getDefaultProcessConfig(this.processId, method);
            },

            getProcessConfig: function(isNewRecord, callback, refresh){
                if(!isNewRecord){
                    this.getMetaModel().getProcessConfig(this.processId, callback, refresh);
                }else{
                    callback && callback(this.getFirstDefaultProcessConfig(this.processId));
                }
            },*/

            saveProcessConfig: function(config){
                config.processId = this.processId;
                // BAC-4107 - Security (XSS) - Text is not getting decoded, When loaded back in the UI. HtmlEncode has been taken care at grid where description has displied.
                //config.appliesTo = Ext.String.htmlEncode( config.appliesTo ); 
                this.__parent.saveProcessConfig(config);
            },

            deleteProcessConfig: function(config){
                config.processId = this.processId;
                this.__parent.deleteProcessConfig(config);
            },

            destroyProcessListPanel: function(){
                var panel = this.getComponent(this.tabPanelId + '_processlistpanel');
                if(panel) panel.destroy(); 
            },

            destroyEditProcessPanel: function(){
                var panel = this.getComponent(this.tabPanelId + '_editprocesspanel');
                if(panel) panel.destroy();
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ProcessListPanel', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            alias:'widget.spm.report.processlistpanel',
			cls:'spm-process-list-panel',
            hidden: false, border: false, maxHeight : 172,

            constructor: function (config) {
                
                config = Ext.apply({
                    columns: [
                        //{ text: 'Name',  dataIndex: 'name', flex: 1 },
                        //{ text: "Name",  dataIndex: 'name', flex: 1.5/10 },
                        { dataIndex: 'cSequence', flex: 0.5/10, menuDisabled: true, sortable: false },                        
                        //{ text: TS.T("TAG008", "Calculation Method"),  dataIndex: 'method', flex: 2.4/10 },
                        { text: TS.T("TAG009", "Description"),  dataIndex: 'appliesTo', flex: 7/10, menuDisabled: true, sortable: false,
                            renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG010", "Last Modified On"), dataIndex: 'lastModifiedOn', flex: 2/10, menuDisabled: true, sortable: false },
                        { 
                            xtype: 'actioncolumn', align: 'center', 
                            flex: 0.4/10, sortable: false, menuDisabled: true,
                            items: [{
                                //icon:'some_icon.png',
                                tooltip : TS.T("TAG012", "Delete Calculation Method"), 
                                //xtype: 'svmx.button',
                                iconCls : "svmx-spm-delete-icon",
                                disabled: isAccountSummary,
                                handler : SVMX.proxy(this, function(grid, rowIndex, colIndex, item, e, record) {
                                    var me = this;
                                    Ext.MessageBox.confirm({
                                    	title:TS.T("TAG051", "Confirm"),
                            			msg : TS.T("TAG076", 'Are you sure ? Would you like to delete this Calculation Method ?' ),
                            			buttons: Ext.MessageBox.YESNO,
                                        buttonText:{
                                            yes: TS.T("TAG074", 'Yes' ), 
                                            no: TS.T("TAG075", 'No' ) 
                                        },
                                    	icon : Ext.MessageBox.QUESTION,
                                    	fn :function(btn, text){
                                    		if (btn == 'yes'){
                                                me.__parent.deleteProcessConfig({recordId: record.data.raw.recordId});
                                            }
                                    	}
                                    });   
                                })
                            }] 
                        }
                    ],
                    store: Ext.create('Ext.data.Store', {
                        storeId: config.itemId + '_store', proxy: { type: 'memory' },
                        fields: config.fields, data: config.data
                    }),
                    listeners: {
                        select: function( grid, record, index, eOpts ){
                            this.__parent.editRecord(record);
                        }
                    },
                    dockedItems: [{
                        xtype: 'toolbar',
                        dock: 'top',
                        //style: 'background-color: lightgray;',
                        items: [
                            { xtype: 'tbfill' }, 
                            
                            {                                 
                                tooltip : TS.T("TAG011", "Add Calculation Method"), 
                                xtype: 'svmx.button', //width: 28, height: 24,
                                text: TS.T("TAG071", "Add"),
                                cursor:'pointer',
                                disabled: isAccountSummary,
                                //iconCls : "svmx-spm-add-icon",scale   : "medium",
                                handler: SVMX.proxy(this, function(){
                                    var config = this.__parent.getFirstDefaultProcessConfig(this.processId);
                                    config = { data: config, isNewRecord: true};
                                    this.__parent.editRecord(config);
                                    this.__parent.listPanel.getSelectionModel().deselectAll();
                                })
                            }                            
                        ]                        
                    }]  
                }, config || {});
                this.callParent(arguments); 
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.EditProcessPanel', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXTabPanel',
            alias:'widget.spm.report.editprocesspanel',
            border: true, 
			cls:'spm-edit-process-panel',
            initComponent: function(){
                this.callParent(arguments);                
                this.tabBar.add([
                    { xtype: 'tbfill' }, 
                    {
                        xtype: 'svmx.button', margin: '2 2 0 0',
                        //iconCls : "svmx-spm-save-icon", 
                        tooltip : TS.T("TAG013", "Save Calculation Method"),
                        text: TS.T("TAG062", "Save"),
                        disabled: isAccountSummary,
                        //scale   : "medium", 
                        handler : SVMX.proxy(this, function(){
                            var tabPanel = this, result = {};
                            tabPanel.items.items.forEach(function(item){ 
                                if(item.getData){
                                    var data = item.getData(); 
                                    if(item.itemId == tabPanel.id + "spm_schedule"){
                                        result.scheduleInfo = data;
                                    }else{
                                        for(var key in data){
                                            result[key] = data[key];
                                        }
                                    }
                                }
                            });
                            tabPanel.__parent.saveProcessConfig(result);
                        })
                    },{
                        xtype: 'svmx.button', margin: '2 5 0 0',
                        tooltip : TS.T("TAG014", "Cancel"),
                        text : TS.T("TAG063", "Cancel"),
                        disabled: isAccountSummary,
                        //iconCls : "svmx-spm-cancel-icon", 
                        //margin: '0 0 0 2', 
                        //scale : "medium", 
                        handler : SVMX.proxy(this, function(){
                            var tabPanel = this;
                            /*tabPanel.__parent.destroyEditProcessPanel();
                            tabPanel.__parent.listPanel.getSelectionModel().deselectAll();*/
                            
                            Ext.MessageBox.confirm({
                            	title:TS.T("TAG051", "Confirm"),
                    			msg : TS.T("TAG052", 'Would you like to discard your changes ?' ),
                    			buttons: Ext.MessageBox.YESNO,
                                buttonText:{
                                    yes: TS.T("TAG074", 'Yes' ), 
                                    no: TS.T("TAG075", 'No' ) 
                                },
                            	icon : Ext.MessageBox.QUESTION,
                            	fn :function(btn, text){
	                                if (btn == 'yes'){
	                                    /*me.__parent.getProcessConfig(isNewRecord, function(config){
	                                        me.__parent.loadData(config, isNewRecord);
	                                    });*/
	                                    tabPanel.__parent.destroyEditProcessPanel();
	                                    tabPanel.__parent.listPanel.getSelectionModel().deselectAll();
	                                }
                            	}
                            });
                            
                        })
                    }
                ]);

                if(!this.record) return;

                var me = this;
                var isNewRecord = me.record.isNewRecord || false;
                var record = me.record.data || {};

                var components = [];
                var fieldSetGeneral = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG065", 'Metric Information'),
                    layout: 'column', padding:'10',
                    defaults: { padding: '10px', labelAlign: 'top' }
                });
                components.push(fieldSetGeneral);
                
                var keyArray = ['isActive', 'sourceObjectLabel', 'targetObjectLabel', 'appliesTo'];
                if(record.method === 'SPMMTBF: Standard'){
                    keyArray = ['isActive', 'sourceObjectLabel', 'targetObjectLabel', 'entryTypeForMTBF', 'appliesTo'];
                }
                if (record.entryTypeForMTBF === '' || record.entryTypeForMTBF === null  || isNewRecord) {
                    record.entryTypeForMTBF = 'Multiple_MTBF';
                }
                SVMX.array.forEach(keyArray, function(key){
                    if(!(key in record)) return;
                    switch(key){
                        case 'name': 
                            fieldSetGeneral.add({ fieldLabel: 'Name', name: key, readOnly: true });
                            break;
                        case 'isActive':
                            fieldSetGeneral.add({ xtype: 'checkbox', boxLabel: TS.T("TAG050", "Active"), readOnly: isAccountSummary,
                                name: key, value:record[key], columnWidth: 1.0, labelAlign: 'top'
                            });
                            break;
                        case 'method_values': 
                            fieldSetGeneral.add({
                                xtype: 'svmx.picklist', name: 'method', fieldLabel: TS.T("TAG008", "Calculation Method"), 
                                displayField: 'name', valueField: 'name', value: record.method, hidden: true,
                                columnWidth: 1.0, labelAlign: 'top',
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.id+'_'+key+'_store', 
                                    fields: ['name'], data: record[key], 
                                    proxy: { type: 'memory' }
                                }),
                                listeners: {
                                    change: function(cmp, nv){
                                        /*if(isNewRecord){
                                            var config = me.__parent.getDefaultProcessConfig(nv);
                                            me.__parent.refreshEditPanel({ data: config });
                                        }*/
                                    }
                                },
                                listConfig: {
                                    getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }
                            });
                            break;
                        case 'entryTypeForMTBF':
                            fieldSetGeneral.add({
                                xtype: 'svmx.picklist', name: 'entryTypeForMTBF', fieldLabel: TS.T("TAG090", "Define how many entries must be maintained per Installed Product in this metric"), 
                                displayField: 'label', valueField: 'name', value: record.entryTypeForMTBF,
                                columnWidth: 1.0, labelAlign: 'top', editable: false, readOnly: !isNewRecord,
                                store: Ext.create('Ext.data.Store', {
                                    storeId: 'entryTypeForMTBFStore', 
                                    fields: ['label', 'name'],
                                    data : [
                                        {"name": "Single_MTBF", "label": TS.T("TAG091", "Single MTBF")},
                                        {"name": "Multiple_MTBF", "label": TS.T("TAG092", "Multiple MTBF")},
                                    ], 
                                    proxy: { type: 'memory' }
                                }),
                                listConfig: {
                                    getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }
                            });
                            break;
                        case 'appliesTo': 
                            fieldSetGeneral.add({ xtype: 'svmx.textarea', labelAlign: 'top', columnWidth: 1.0, readOnly: isAccountSummary, fieldLabel: TS.T("TAG009", "Description"), name: key });
                            break;
                        case 'dashboardId': 
                            if(record[key]){
                                fieldSetGeneral.add({
                                    xtype: 'component', 
                                    autoEl: { 
                                        tag: 'a', align: 'right', //style: 'padding:10px 0px 0px 310px;', 
                                        target: '_blank', style: 'text-decoration: underline !important;',
                                        href: '/../../'+record[key], html: TS.T("TAG030", "Launch Dashboard")
                                    }
                                }); 
                            }
                            break;
                        case 'sourceObjectLabel': 
                            fieldSetGeneral.add({ xtype: 'textfield', columnWidth: 1.0, readOnly: true,
                                fieldLabel: TS.T("TAG060", "Object(s) from which this metric is derived"), 
                                name: key, value: record[key], labelAlign: 'top'
                            });
                            break;
                        case 'targetObjectLabel': 
                            fieldSetGeneral.add({ xtype: 'textfield', columnWidth: 1.0, readOnly: true,
                                fieldLabel: TS.T("TAG061", "Object(s) where metrics are collected"), 
                                name: key, value: record[key], labelAlign: 'top'
                            });
                            break;
                    }
                }, me);

                if(components.length){
                    me.add({ 
                        xtype: 'form',cls:'spm-report-config-general', title: TS.T("TAG055", "Metric Definition"), items: components, height: '100%',
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG055", "Metric Definition"), border: false, labelAlign: 'top', padding: 10,
                        defaults: { padding: '10px', columnWidth: 1.0, labelAlign: 'top' }, autoScroll: true,
                        getData: function(){
                            return this.getForm().getValues();
                        } 
                    });
                }

                components = [];

                var fieldSetAdditionalCriterias = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG068", 'Please define inputs to be used in metric calculation' ),
                    layout: 'column', padding:'10', columnWidth: 1
                });
                var selectedMatrixTab = this.__parent ;
                var hasAdditionalCriteria = false;
                for(var key in record) {
                	
                    if(key.match('_fields')) {
                        if( record[key].isCriteria == true ) {
                            hasAdditionalCriteria = true;
                            fieldSetAdditionalCriterias.add({
                                xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,id: 'selectbox_Id'+selectedMatrixTab.processId+record[key].componentId,
                                fieldLabel: record[key].name, displayField: 'label', valueField: 'name',
                                labelAlign: 'top', padding: 10, multiSelect: record[key].multiSelect,
                                listeners: {
                                    change: function(cb, exprId, eOpts){
                                    	if(selectedMatrixTab.processId === "FirstTimeFix"){
	                                    	if(exprId === 'WorkDetail'){
	                                    		if(Ext.getCmp('selectbox_IdFirstTimeFixPeriod') != undefined && Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder') != undefined){
		                                    		Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder').hide();
		                                            Ext.getCmp('selectbox_IdFirstTimeFixPeriod').show();
		                                         if(Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id') != undefined && Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id') != undefined ){
		                                            	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id').up().hide();
		                                          	    Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id').up().show();
		                                            }
	                                    		}
	                                        }
	                                    	if(exprId === 'WorkOrder'){
	                                        	if(Ext.getCmp('selectbox_IdFirstTimeFixPeriod') != undefined && Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder') != undefined){
	                                        		Ext.getCmp('selectbox_IdFirstTimeFixPeriod').hide();
	                                          	    Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder').show();
	                                          	    if(Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id') != undefined && Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id') != undefined ){
	                                          	    	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id').up().show();
	                                          	    	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id').up().hide();
	                                          	    }
	                                        	}
	                                        }
                                    	}
                                    }
                                },
                                listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }, 
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.itemId + '_'+record[key].name+'_store', 
                                    fields: ['name','label','displayType'], data: record[key].values, 
                                    proxy: { type: 'memory' },
                                })
                            });
                        }
                    } 
                }

                if( hasAdditionalCriteria ) {
                    components.push( fieldSetAdditionalCriterias );    
                }

                var fieldSet = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG066", 'Please define the object mapping for this metric'),
                    layout: 'column', padding:'10', 
                });                
                components.push(fieldSet);

                for(var key in record) {
                    if(key.match('_fields')) {
                        if( record[key].isCriteria == false ) {
                            fieldSet.add({
                                xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,
                                fieldLabel: record[key].name, displayField: 'label', valueField: 'name',
                                labelAlign: 'top', padding: 10, multiSelect: record[key].multiSelect,
                                listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                },                                   
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.itemId + '_'+record[key].name+'_store', 
                                    fields: ['name','label','displayType'], data: record[key].values, 
                                    proxy: { type: 'memory' }
                                })
                            });
                        }  
                    } 
                }

                for(var key in record){
                    if(key.match('_mappings')){
                        fieldSet.add({
                            xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,
                            fieldLabel: record[key].name, displayField: 'name', valueField: 'mapId',
                            labelAlign: 'top', padding: 10,
                            listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                            },  
                            store: Ext.create('Ext.data.Store', {
                                storeId: me.itemId + '_'+record[key].name+'_store', 
                                fields: ['name','mapId'], data: record[key].values, 
                                proxy: { type: 'memory' }
                            })
                        });   
                    } 
                }     
                
                if(components.length && !isAccountSummary) {
                    me.add({ 
                        xtype: 'form', cls:'spm-report-config-settings', title: TS.T("TAG006", "Settings"), items: components, 
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG056", "Settings"), padding: 10,
                        defaults: { padding: '10px', columnWidth: 1.0, labelAlign: 'top' }, autoScroll: true,
                        getData: function(){
                            return this.getForm().getValues();
                        } 
                    });
                }

                components = [];
                Ext.each(record.expressions || [], function(item){
                    components.push({
                        xtype: 'spm.report.exprpanel', columnWidth: 1,
                        itemId: me.itemId + '_expression_' + item.type, 
                        title: item.label, rules: item.rules, value: item.value
                    });
                }, me);

                if(components.length){
                    me.add({ 
                        xtype: 'form', cls:'spm-report-config-criteria', title: TS.T("TAG007", "Criteria(s)"), items: components, autoScroll: true,
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG057", "Criteria(s)"),
                        defaults: { padding: '10px', columnWidth: 0.5, labelAlign: 'top' },
                        getData: function(){
                            var record = this.getForm().getRecord();
                            if(!isNewRecord) record = record.getData();
                            else record = record.data;

                            var expressions = {};
                            Ext.each(record.expressions, function(item){
                                var cmp = this.getComponent(me.itemId + '_expression_' + item.type);
                                var val = cmp.getSelectedExpression();
                                if(val) expressions[item.type] = val;
                            }, this);

                            var params = this.getForm().getValues();
                            var retValue = {

                                expressions: expressions, 
                                raw: record.raw
                            };

                            if( params ) {
                                for( var key in params ) {
                                    if( key != 'advExp') {
                                        retValue[key] = params[key];
                                    }
                                }    
                            }

                            return retValue;
                        }
                    });
                }

     //            me.add([{
     //                xtype: 'spm.schedule',
					// cls:'spm-report-config-schedule-tab',
     //                itemId: this.id + "spm_schedule",
     //                metaModel: this.__parent.getMetaModel(),
     //                processId: this.__parent.processId,
     //                tooltip: TS.T("TAG058", "Schedule & Notifications"),
     //            },{
     //                xtype: 'spm.status',
					// cls:'spm-report-config-status-tab',
     //                metaModel: this.__parent.getMetaModel(),
     //                processId: this.__parent.processId,
     //                tooltip: TS.T("TAG059", "Status"),
     //                listeners: {
     //                    activate: function( tabPanel, eOpts ){
     //                        if(tabPanel.onActivate){
     //                            tabPanel.onActivate();
     //                        }
     //                    }
     //                }
     //            }])

                me.setActiveTab(0);
                me.loadData(me.record);
            },

            loadData: function(record){
                SVMX.array.forEach( this.items.items, function(item){
                    if(item.loadRecord){
                        item.loadRecord(record || this.record);
                    }
                }, this);
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ExpressionPanel', {
            extend: 'Ext.form.FieldSet',
            alias:'widget.spm.report.exprpanel',
			cls:'spm-report-expression-panel',
			id: '',
            layout: 'column', border: false, margin: '10',
            labelStyle: 'font-weight:bold;padding:0',
            defaults: { padding: '5', columnWidth: 0.5, labelAlign: 'top' },

            initComponent: function () {
                this.callParent(arguments);

                var me = this;
                this.add([{
                    xtype: 'svmx.picklist', itemId: me.itemId + '_expression', id:me.itemId + 'fieldset_id',
                    displayField: 'name', valueField: 'exprId', editable: false,
                    store: Ext.create('Ext.data.Store', {
                        storeId: me.itemId + '_expression_store', 
                        fields: ['exprId', 'name', 'expressions', 'advExp'],
                        data : me.rules, proxy: { type: 'memory' }
                    }),
                    listeners: {
                        change: function(cb, exprId){
                            var list = cb.store.data.items, item;
                            for(i = 0, l = list.length; i < l; i++){
                                item = list[i];
                                if(item.data.exprId == exprId || item.data.name == exprId){

                                    var grid = me.getComponent(me.itemId + '_expression_details');
                                    grid.store.loadData(item.data.expressions);
                                    grid.show();  

                                    var advExp = me.getComponent(me.itemId + '_advExp');
                                    if(item.data.advExp){
                                      advExp.setValue(item.data.advExp);  
                                      advExp.show();  
                                    } 
                                    else advExp.hide();

                                    break;
                                }
                            }
                        }
                    },
                    listConfig: {
                                getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                }
                    }
                },{
                    xtype: 'svmx.listcomposite', columnWidth: 1,
                    itemId: me.itemId + '_expression_details', hidden: false,
                    columns: [
                        { text: TS.T("TAG032", "Sequence"),  dataIndex: 'sequence', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG033", "Field"),  dataIndex: 'field', flex: 2, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG034", "Operator"), dataIndex: 'operator', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG035", "Value"), dataIndex: 'value', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } }
                    ],
                    store: Ext.create('Ext.data.Store', {
                        storeId: me.itemId + '_expression_grid_store',
                        fields: ['sequence', 'field', 'operator', 'value'],
                        proxy: { type: 'memory' }
                    })
                },{
                    xtype: 'svmx.text', name: 'advExp', itemId: me.itemId + '_advExp', hidden: true,
                    fieldLabel: TS.T("TAG031", "Advanced Expression"), readOnly: true,columnWidth: 1
                }]);

                this.items.get(this.itemId + '_expression').setValue(this.value);
            },

            getSelectedExpression: function(){
                return this.items.get(this.itemId + '_expression').getValue();
            }
        });
    }
})();