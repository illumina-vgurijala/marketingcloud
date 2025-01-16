/**
 * 
 */
(function(){
	
	var objSearchImpl = SVMX.Package("com.servicemax.client.installigence.objectsearch");

objSearchImpl.init = function(){
	
	objSearchImpl.Class("ObjectSearch", com.servicemax.client.lib.api.Object, {
		__d : null, __inited : false, __config : null,
		__objectInfo : null, __store : null, __grid : null, __win : null, __fieldsMap : null,
		
		__constructor : function(config){
			this.__inited = false;
			this.__config = config;
		},
		
		find : function(){
			this.__d = $.Deferred();
			
			if(this.__inited == false){ this.__init();}
			else{ this.__showUI(); }
			
			return this.__d;
		},
		
		__init : function(){
			var syncService = SVMX.getClient().getServiceRegistry()
    		.getService("com.servicemax.client.installigence.sync").getInstance(), me = this;
			syncService.getSObjectInfo(this.__config.objectName)
			.done(function(info){
				me.__objectInfo = info;
				me.__fieldsMap = {};
				var i = 0,l = info.fields.length;
				for(i = 0; i < l; i++){
					me.__fieldsMap[info.fields[i].name] = info.fields[i]
				}
				me.__initComplete();
			});
		},
		
		__initComplete : function(){
			this.__inited = true;
			this.__showUI();
		},
		
		__getFields : function(fields){
			var colFields = ["Id", "Name"];
			for(var key in fields){
				if(fields[key].name && fields[key].name.toLowerCase() == "id") continue;
				if(fields[key].name && fields[key].name.toLowerCase() == "name") continue;				
				colFields.push(fields[key].name);				
			}
			
			return colFields;
		},
		
		__getSearchFields : function(fields){
			var colFields = [];
			for(var key in fields){				
				colFields.push(fields[key].name);
			}
			
			return colFields;
		},
		
		__find : function(params){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCE." + this.__config.mvcEvent, this, 
					{request : { context : this, handler : this.__findComplete, text : params.text, 
													displayFields : this.__getFields(this.__config.columns),
													searchFields : this.__getSearchFields(this.__config.searchColumns),
													fieldsDescribe : this.__fieldsMap}});
			com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
		},
		
		__findComplete : function(data){
			this.__store.loadData(data);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__showUI : function(){
			// prepare UI
			this.__win = this.__getUI();
			this.__win.draggable = false;
			this.__win.setPosition(window.screen.width/8, window.screen.height/6); 

			this.__win.show(this.__config.sourceComponent);
			
			this.__find({});
		},
		
		__tryResolve : function(){
			var selectedRecords = this.__grid.getSelectionModel().getSelection();
        	if(selectedRecords.length == 0) return;
        	
        	var recs = [], i, l = selectedRecords.length;
        	for(i = 0; i < l; i++){
        		recs.push(selectedRecords[i].data);
        	}
        	
        	this.__d.resolve(recs);
        	this.__win.close();
		},
		
		__getUI : function(){
			
			var cols = this.__config.columns, i, l = cols.length, me = this;
			
			var clsName = 'installigence-lookup-grid';
			if (navigator.appVersion.indexOf("Win")!=-1){
				clsName = 'windowObjectSearchCheckbox';
			}

			// store
			var fields = [];
			for(i = 0; i < l; i++){ fields.push(cols[i].name); }
			var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});
			
			//grid
			var gridColumns = [], objectInfo = this.__objectInfo, j, oFields = objectInfo.fields, t = oFields.length, c;
			for(i = 0; i < l; i++){
				c = cols[i];
				for(j = 0; j < t; j++){
					if(c.name == oFields[j].name){
						gridColumns.push({ text : oFields[j].label,minWidth: 175, dataIndex : c.name, flex : 1, cls:'installigence-lookup-grid-header' });
					}
				}
			}

			var grid = null;
			if(this.__config.fromIBSwap !== undefined && this.__config.fromIBSwap == true){
				grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
	                store: store,
	                cls : 'installigence-lookup-grid',
	                forceFit : true, columns: gridColumns, flex : 1, width: "100%", autoScroll: true,
	                viewConfig: {
	                    listeners: {
	                        itemdblclick: function(dataview, record, item, index, e) {
	                            me.__win.close();
	                        }
	                    }
	                }
	            });
			}else{
				grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
        	    	store: store,
        	    	cls : clsName,
        	    	selModel: {selType : 'checkboxmodel', checkOnly : true},
        	    	columns: gridColumns, flex : 1, width: "100%"
        		});	
			}
			
			
			// searchText
        	var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
        		width: '70%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'), enableKeyEvents : true,
        		listeners : {
        			keyup : function(that, e, opts) {
        				if(e.getKey() == e.ENTER){
        					me.__find({ text : searchText.getValue()});
        				}
        			}
        		}
        	});
        	
			// window
			var winItems = [
				searchText,
				{ xtype: 'button', text: $TR.__getValueFromTag($TR.PRODIQ001_TAG139,'Go'), handler : function(){
					me.__find({ text : searchText.getValue()});
				}}
			];
			if(this.__config.createHandler){
				winItems.push({
					xtype: 'button',
					text: $TR.__getValueFromTag($TR.PRODIQ001_TAG140,'Create New'),
					handler : function(){
						me.__config.createHandler();
						me.__win.close();
					}}
				);
			}
			var buttons = [];
			if(this.__config.fromIBSwap === undefined ||(this.__config.fromIBSwap !== undefined && this.__config.fromIBSwap == false)){
				buttons.push({text : $TR.__getValueFromTag($TR.IPAD014_TAG086,'Add'), handler : function(){ me.__tryResolve(); }});
				buttons.push({text : $TR.__getValueFromTag($TR.IPAD026_TAG018,'Cancel'), handler : function(){ win.close(); }});
			}
			var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
				layout : {type : "vbox"}, height : 400, width : 700, title : objectInfo.labelPlural,
				closable: false,
				cls: 'NewIB-Poup-Centered',
				dockedItems : [
				    {
				    	dock: 'top', xtype: 'toolbar', margin: '0',
				    	items : winItems
				    }
				],
				tools:[
                	// {
//                 		xtype: 'button', 
//                 		text: $TR.RESET_NO,
//                     	handler : function(){
//                     		me.__win.focus();
//                         	me.__win.close();
//                     	}
//                 	}
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
                },
				maximizable : false, items : [grid], modal : true,
				buttons : buttons
			});
			
			this.__store = store;
			this.__grid = grid;
			return win;
		}
	}, {});
};

})();