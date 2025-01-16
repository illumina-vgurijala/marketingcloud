/**
 * 
 */

(function(){
	
	var documentsImpl = SVMX.Package("com.servicemax.client.installigence.recordInformation");

documentsImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.recordInformation.RecordInformation", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.recordInformation',
            
            __ibtree: null,
            __meta:  null,

        constructor: function(config) {	
            var me = this;
            config = config || {};
            this.__ibtree = config.ibtree;
            this.__meta   = config.meta;
            config.title = $TR.__getValueFromTag($TR.RECORD_VIEW_TITLE,'Select an item from the tree');
            config.titleAlign = 'center';
            config.ui = 'svmx-white-panel';
            config

                     
                     me.tabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel',{
                    
                    tabRotation: 0,
                    cls:'productiq-tabpanel',

                    tabBar: {
                        border: true,
                        style : 'background-color:transparent;'
                    },

                    items: []
                   });
            config.items = [me.tabPanel];
            this.callParent([config]);

        }
    });
	
};

})();

// end of file