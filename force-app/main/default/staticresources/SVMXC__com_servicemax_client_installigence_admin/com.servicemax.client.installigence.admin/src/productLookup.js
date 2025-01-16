/**
 *  Product lookup.
 * @class com.servicemax.client.insralligence.admin.productlookup.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/
(function(){
	
	var productLookupImpl = SVMX.Package("com.servicemax.client.installigence.admin.productLookup");

productLookupImpl.init = function(){
	
	productLookupImpl.Class("ProductLookup", com.servicemax.client.lib.api.Object, {
		__d : null, __inited : false, __config : null,
		__objectInfo : null, __store : null, __grid : null, __win : null, __searchText: null,
		
		__constructor : function(config){
			this.__inited = false;
			this.__config = config;
			this.__searchText = config.searchText;
		},
		
		find : function(){
			this.__d = $.Deferred();
			
			this.__showUI();
			
			return this.__d;
		},
		
		__init : function(){
			
		},
		
		__initComplete : function(){
			this.__inited = true;
			this.__showUI();
		},
		
		__find : function(params){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCEADMIN." + this.__config.mvcEvent, this, 
					{request : { context : this, handler : this.__findComplete, text : this.searchTextBox.value}});
			SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
		},
		
		__findComplete : function(data){
			this.__store.loadData(data);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__showUI : function(){
			// prepare UI
			this.__win = this.__getUI();
			this.__win.show(this.__config.sourceComponent);
			if(this.__searchText) this.searchTextBox.setValue(this.__searchText);
			this.__find({});
		},
		
		__tryResolve : function(selectedRecord){
			
        	this.__d.resolve(selectedRecord.data);
        	this.__win.close();
		},
		
		__getUI : function(){
			
			var me = this;
			var cols = this.__config.columns, i, l = cols.length, me = this;
			var objectFields = ['Name'];
			// store
			var fields = [];
			for(i = 0; i < l; i++){ fields.push(cols[i].name); }
			var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});
			
			//grid
			var gridColumns = [], c, j;
			for(i = 0; i < l; i++){
				c = cols[i];
				for(j = 0; j < objectFields.length; j++) {
					
						gridColumns.push({ text : objectFields[j], dataIndex : c.name, flex : 1,
							renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                            } 
                        });
					
				}
								
			}

			var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
        	    store: store,
        	    cls : 'piq-setup-ta-grid',
        	   // selModel: {selType : 'checkboxmodel', checkOnly : true, mode : 'SINGLE'},
        	   viewConfig: {
                        listeners: {
                            /*select: function(dataview, record, item, index, e) {
                       		me.__tryResolve(record);

                              
                            },*/
                             itemdblclick: function(dataview, record, item, index, e) {

                             	me.__tryResolve(record);
                             }
                        }
                    },
        	    columns: gridColumns, flex : 1, width: "100%"
        	});
			
			// searchText
        	 me.searchTextBox = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
        		width: '70%', emptyText : $TR.SEARCH_EMPTY_TEXT, enableKeyEvents : true,
        		cls : 'piq-setup-ta-product-window-textfield',
        		listeners : {
        			change: {
	                        fn: me.__onTextFieldChange,
	                        scope: this,
	                        buffer: 500
	                    }
        		}
        	});
        	
			// window
			var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
				layout : {type : "vbox"}, height : 400, width : 800, title : $TR.PRODUCT_LIST,
				cls : 'piq-setup-ta-product-window-win',
				dockedItems : [
				    {
				    	dock: 'top', xtype: 'toolbar', margin: '0',
				    	items : [
				    	    me.searchTextBox, { xtype: 'button', text: $TR.GO,
				    	     handler : function(){
				    	     	me.__find();
				    	     }}
				    	]
				    }
				  
				],
				maximizable : false,closable: true, items : [grid], modal : true,
				buttons : [
				    
				    {text : $TR.CANCEL, handler : function(){ win.close(); }}
				],
				listeners: {
	                    show: function(win) {
	                        if (this.modal) {
	                            var dom = Ext.dom.Query.select('.x-mask');
	                            for(var i=0; i<dom.length;i++){
	                                     Ext.get(dom[i]).setStyle('opacity',1);
	                                     var el = Ext.get(dom[i]);
	                                     el.addCls('customWinMask');

	                            }
	                        }
	                    },
	                    close:  function(win) {
	                        if (this.modal) {
	                            var dom = Ext.dom.Query.select('.x-mask');
	                            for(var i=0; i<dom.length;i++){
	                                     Ext.get(dom[i]).setStyle('opacity',1);
	                                     var el = Ext.get(dom[i]);
	                                     el.removeCls('customWinMask');

	                            }
	                        }
	                    }
	                }
			});
			
			this.__store = store;
			this.__grid = grid;
			return win;
		},

		__onTextFieldChange: function() {
	        	var value = this.searchTextBox.getValue();
	        	this.__grid.search(value);
	        	
	         }
	}, {});
};

})();