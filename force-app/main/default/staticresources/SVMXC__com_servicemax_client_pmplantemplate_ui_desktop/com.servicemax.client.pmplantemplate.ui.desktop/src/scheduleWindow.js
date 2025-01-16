
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow.ScheduleWindow", {
            extend: 'Ext.window.Window',
            id: 'scheduleWindow',
            border: 0,
            resizable: false,
            modal: true,
            closable: true,
            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG056", "Sample Schedules")
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                var schedulePanel = SVMX.create("Ext.form.FormPanel", {
                    id: 'schedulePanel',
                    collapsible: false,
                    region: 'center',
                    width: 'calc(100% - 20px)',
                    border: false,
                    layout: 'anchor',
                    layout: {
                        type: "anchor",
                        align: "stretch"
                    },
                    margin: '0 10px',
                    style:{
                        top: '20px'
                    }
                });

                //Creating a store for holding schedule
                var scheduleListStore = Ext.create('Ext.data.Store', {
                    storeId: 'Schedule_List_Store',
                    fields: ['scheduleName']
                });

                var noteLabel = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXLabel",{
                    text: (this.conditionTypeValue == 'Usage_Frequency')? TS.T("TAG055", "These are some sample schedules for the condition defined. There may be more.") : TS.T("TAG066", "This is the sample schedule for the condition defined."),
                    style:{
                        fontSize: '14px'
                    }
                });
                schedulePanel.add(noteLabel);

                //Creating a grid to show sample schedules
                var scheduleGrid = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXListComposite",{
                    store: scheduleListStore,
                    margin: '15px 0px 10px 0px',
                    autoScroll: true,
                    maxHeight: 440,
                    columns: [{
                        text: TS.T("TAG057", "Schedule Output"),
                        dataIndex: 'scheduleName',
                        sortable: false,
                        menuDisabled: true,
                        align: 'center',
                        flex: 1,
                        renderer: function(value, metadata) {
                            metadata.style = 'white-space: normal;';
                            return Ext.String.htmlEncode(value);
                        }
                    }]
                });
                schedulePanel.add(scheduleGrid);
                me.add(schedulePanel);
            },

            loadDataInStore: function(data){
                var scheduleListStore = Ext.data.StoreManager.lookup('Schedule_List_Store');
                scheduleListStore.loadData(data);
            }
        });
    }
})();