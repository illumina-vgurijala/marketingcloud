(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        Ext.define("com.servicemax.client.spm.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'spm-root-container',

            layout: 'fit',
            width: '100%', height: 650,

            constructor: function (config) {
                config = Ext.apply({
                    title: TS.T( 'TAG001', 'Service Performance Metrics Setup'),
                    titleAlign: 'center', collapsible: false,
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            padding: '0', //width: 32, height: 32,
                            //iconCls : "svmx-spm-back-icon", scale: "large",
                            text : TS.T("TAG029", "Back To Setup Home"),
                            handler: function(e, el, owner, tool) {
                                //Added if condition for the story BAC-4797
                                if((typeof sforce != 'undefined') && (sforce != null)){
                                    sforce.one.navigateToURL("/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup");
                                }
                                else{
                                    window.location = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                }
                            }
                        }]
                    },
                    items : [{
                        xtype: "svmx.tabpanel", itemId: 'spm-horizontal-tab-container',
                        defaults: { autoScroll: true, border: false, frame: false },
                        width: "100%", height: 460, activeTab: 0, border: false,
                        items : [{
                            xtype: "spm.general", padding:'5',
                            title: TS.T("TAG002", "Metrics"),
                            metaModel: config.deliveryEngine.getMetaModel(),
                            __parent: this,
                        },
	                    {
	                        xtype: "spm.config", padding:'5',
	                        title: TS.T( 'TAG086', 'Business Process Config'),
	                        metaModel: config.deliveryEngine.getMetaModel(),
	                        __parent: this,
	                    }],
                        tabBar: {
                            items: [
                                { xtype: 'tbfill' },
                                {
                                    iconCls : 'svmx-spm-help-icon ',
                                    cursor:'pointer',
                                    scale : 'small',
                                    cls: 'svmx-ent-help',
                                    tooltip: TS.T( 'TAG069', 'SPM Help'),
                                    href: TS.T( 'TAG070', 'http://userdocs.servicemax.com:8080/ServiceMaxHelp/Spring16/en_us/svmx_redirector.htm?uid=SPM|SPMConfiguration_Setup'),
                                    closable: false,
                                }
                            ],
                        }
                    }],

                }, config || {});

                this.callParent(arguments);
            }
        });
    }
})();