(function(){

	var searchImpl = SVMX.Package("com.servicemax.client.installigence.search");;

	searchImpl.init = function() {

		searchImpl.Class("Search",com.servicemax.client.lib.api.Object, { // defining the class.

			//defining the class variable or private ivars.
			__config: null,
			__displayFields:null,
			__searchFields:null,
			__displayFilter:null,
			__referenceFilter:null,
			__window:null,
			__store:null,
			__grid:null,
			__objectInfo : null,
			__fieldsMap : null,
			__configArray : null,
			__data :null,

			//defining the constructor.
		__constructor:function(advanceSearch) {
				var me = this;
				this.__config = advanceSearch;
				this.__parseConfig(advanceSearch);
				this.__configArray = this.__config.config;
				this.__init();
			}, //constructor ends
			
		__parseConfig:function(Config){
			var displayFields = [];
            var searchFields = [];
            var displayFilter = [];
            var referenceFilter = [];
            var searchConfigFields = Config.config;
			if (searchConfigFields) {
                for (var k = 0; k < searchConfigFields.length; k++) {
                    var currentDictionary = searchConfigFields[k];
                    var fieldType = currentDictionary.fieldType;
                    var fieldName = currentDictionary.fieldName;
					if (fieldType == "Search"){
                        searchFields.push(fieldName);
                    }else if (fieldType == "Result"){
                        displayFields.push(fieldName);
                    }else
                    {
                    	if(currentDictionary.displayType != "REFERENCE"){
                    		displayFilter.push(currentDictionary);
                    	}else
                    	{
                    		if(currentDictionary.fKeyNameField)
                    		{
                    			referenceFilter.push(currentDictionary);
                    		}
                    	}
                    }
                }
                this.__displayFields = displayFields;
				this.__searchFields = searchFields;
				this.__displayFilter = displayFilter;
				this.__referenceFilter = referenceFilter;
            }
		},
		__init : function(){
			var syncService = SVMX.getClient().getServiceRegistry()
    		.getService("com.servicemax.client.installigence.sync").getInstance(), me = this;
			syncService.getSObjectInfo(SVMX.getCustomObjectName("Installed_Product"))
			.done(function(info){
				me.__objectInfo = info;
				me.__fieldsMap = {};
				var i = 0,l = info.fields.length;
				for(i = 0; i < l; i++){
					me.__fieldsMap[info.fields[i].name] = info.fields[i]
				}
				me.__initComplete();
			});
			
		}, //__init ends here
		__initComplete : function(){
			this.__showUI();
		},

		__showUI:function() {
				var me = this;
				this.__window = this.__getUI();
				this.__window.show();
				this.__find({});

			}, //__showUI ends here

		__find : function(params){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCE." + this.__config.mvcEvent, this, {
						request : { 
							context : this, 
							handler : this.__findComplete, 
							text : params.text, 
							displayFields : this.__getFields(this.__displayFields),
							searchFields : this.__searchFields,
							displayFilter : this.__displayFilter,
							referenceFilter : this.__referenceFilter
						}
					});
			com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
		}, //__find ends here
		
		__findComplete : function(data){
			this.__getRefrenceFieldValue(data).done(function(){
				//Loade screen here, If there is no reference filed config field there
			});
			this.__store.loadData(data);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__getRefrenceFieldValue:function(data){
			var def = SVMX.Deferred();
			this.__data = data;//{};
			var idList = [];
			var me = this;
			for(var kConfig = 0; kConfig < this.__configArray.length; kConfig++ ){
				var configDict = this.__configArray[kConfig];
				if(configDict){
					if(configDict.displayType == "REFERENCE"){
						for(var k = 0; k < data.length; k++ ){
							var dataDict = data[k];
							var fieldName = configDict.fieldName;
							var value ;
							if(fieldName){	
								value = dataDict[fieldName];
								me.__data[value] = dataDict;
								if(value){
									idList.push(value);
								}
							}
						}
						this.__fetchRefValue(idList,configDict);
                	}else{
                		console.log("fetch value");
               	 	}
				}
			}			
			return def;
		},
		
		__fetchRefValue : function (ids,configDict){
			SVMX.getCurrentApplication().blockUI();
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"INSTALLIGENCE." + "FETCH_VALUES_Ref", this, {
						request : { 
							context : this, 
							handler : this.__referenceComplete,
							kIds: ids,
							kConfigDict:configDict,
							referenceFilter : this.__referenceFilter
						}
					});
			com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
			SVMX.getCurrentApplication().unblockUI();
		},
		
		__referenceComplete: function (data){
			var me = this;
			for(var kConfig = 0; kConfig < this.__configArray.length; kConfig++ ){
				var configDict = this.__configArray[kConfig];
				if(configDict){
					if(configDict.displayType == "REFERENCE"){
						for(var k = 0; k < this.__data.length; k++ ){
							var dataDict = this.__data[k];
							var fieldName = configDict.fieldName;
							var value ;
							if(fieldName){	
								value = dataDict[fieldName];
								if(value){
									var refData = data.rData[value];
									if(refData){
										if(refData[configDict.fKeyNameField]){
 											dataDict[fieldName] =  refData[configDict.fKeyNameField];
 										} 
									}
								}
							}
						}
					}
				}
			}
			this.__store.loadData(this.__data);
			SVMX.getCurrentApplication().unblockUI();
		},
			//this method is for fetching column name 
		__getDisplayFields : function(fields){
			var colFields = [];
			for (var i = 0; i < fields.length; i++) {
				var string = fields[i];
				var label = this.__fieldsMap[string].label;
				colFields.push(label);
			}
			return colFields;
		},
		__getFields : function(fields){
			var colFields = ["Id", "Name"];
			for (var i = 0; i < fields.length; i++) {
				var string = fields[i];
				if(string && string.toLowerCase() == "id") continue;
				if(string && string.toLowerCase() == "name") continue;
				colFields.push(string);
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
		
		__slectedIBS : function(selectedRec){
			var data = {};
			data.action = "VIEW";
			data.recordIds = [selectedRec.data.Id];
			data.object = SVMX.getCustomObjectName("Installed_Product");
			var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt); 
			this.__window.close();
		},

		__getUI:function() {

				var me = this;
				var cols = me.__getDisplayFields(this.__displayFields);
				var  l = cols.length;
				// store
			    var fields = [];
			    for(var i = 0; i < l; i++){ 
			    	fields.push(cols[i]); 
			    }
			    var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});

			    var gridColumns = [];

			    for (var i = 0; i < l; i++) {
			    	gridColumns.push({ text : cols[i], handler : function(){this.__slectedIBS},dataIndex : this.__displayFields[i], flex : 1 });
			    }

			    var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
        	    	store: store,
        	   		//selModel: {selType : 'checkboxmodel', injectCheckbox: false},
        	    	columns: gridColumns, flex : 1, width: "100%",
        	    	viewConfig: {
                  		listeners: {
                    		select: function(dataview, record, item, index, e) {
                    			me.__slectedIBS(record);
                       		}
                   		}
                	}
        	   });


			    // searchText
        		var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
        			width: '80%', emptyText : 'Search', enableKeyEvents : true,
        			listeners : {
        			keyup : function(that, e, opts) {
        				if(e.getKey() == e.ENTER){
        					console.log("inside this constructor");
        					me.__find({ text : searchText.getValue()});
        				}
        			}
        		}
        		});
        	
			// window
			var winItems = [
				searchText,
				{ xtype: 'button', text: "Search", handler : function(){
					me.__find({ text : searchText.getValue()});
				}}
			];
			if(this.__config.createHandler){
				winItems.push({
					xtype: 'button',
					text: "Search",
					handler : function(){
						me.__config.createHandler();
						me.__win.close();
					}}
				);
			}

			var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
				layout : {type : "vbox"}, height : 700, width : 800, title : "Search",
				dockedItems : [
				    {
				    	dock: 'top', xtype: 'toolbar', margin: '0',
				    	items : winItems
				    }
				],
				maximizable : true, items : [grid], modal : true,
				buttons : [
				    {text : "Cancel", handler : function(){ win.close(); }}
				]
			});
			
			this.__store = store;
			this.__grid = grid;
			return win;

			}, // end the of the getUI.
		


			find : function(){
				console.log('Reached');
			}

		}, {});


	}


})(); // defination of anonomus function.