/**
 * 
 */
 (function(){

 	var mashupsImpl = SVMX.Package("com.servicemax.client.installigence.mashups");

mashupsImpl.init = function(){

	Ext.define("com.servicemax.client.installigence.mashups.Mashups", {
		extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
		alias: 'widget.installigence.mashups',
		id : 'testURLPanelId',
		__urlToLoad : null, __title : null, __iFrameToShow : null,

		layout: 'fit',
		frame:true,
		items:[
		    {
		    	id : 'TestURLId',
		        xtype: 'box',
		        autoEl: {
		            tag: 'iframe',
		            src: this.__urlToLoad,//'http://it.wikipedia.org/wiki/Robot'//
		        }
		    }
		],

		constructor : function(config){
			this.__urlToLoad = config.customURL;
			this.__title = config.title;

			config = Ext.apply({
                title: this.__title,
                ui: 'svmx-white-panel',
                cls: 'filter-region',
                titleAlign: 'center'
            }, config || {});

			this.callParent([config]);
		}
	});


};
})();