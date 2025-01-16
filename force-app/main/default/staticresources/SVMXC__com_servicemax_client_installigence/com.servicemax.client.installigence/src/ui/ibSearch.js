/**
 * This Search IBs.
 * @class com.servicemax.client.insralligence.src.ui.ibSearch.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/

(function(){

	var toolBarImpl = SVMX.Package("com.servicemax.client.installigence.ibSearch");

	toolBarImpl.init = function(){
		Ext.define("com.servicemax.client.installigence.ibSearch.IBSearch",
			{
				extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.ibSearch',

        //defining the class variable or private ivars.
            meta : null,
            root: null,
            grid : null,
            __params : null,
            __config: null, /* here we are storing configuration of SFM search */
            __displayFields:null, /*  Filtring display value for grid UI*/
            __searchFields:null, /* Storing search field configuration from SFM configuration */
            __referenceFilter:null,
            __searchFilter:null,
            __window:null,
            __store:null, /* Store for grid UI */
            __grid:null,
            __objectInfo : null,
            __fieldsMap : null,
            __configArray : null,
            __orderBy : null, /* Storing column name for short */
            __searchText : null, /* Search String for  */
            __accountsMenubarButton : null,
            __SearchOptions : null,
            __searchCondition : null,
            __displayConfig : null,
            __orderConfig : null,
            __columnNames : null,
            __CustomObjectName : null,
            advancedExpression : null,
            __relationTable: null, // storing table name for relation in join
            __relationtableName : null,
            __backUpDisplayName : null,

        constructor: function(searchConfig) {
            this.meta = searchConfig.meta;
            this.root = searchConfig.root;
            this.__config = searchConfig;
            this.__CustomObjectName = {};
            this.__backUpDisplayName = [];
            this.__searchCondition = "Contains";
            //this.__SearchOptions = ['Contains','Start With','Exact Match','End With'];
            this.__SearchOptions = [$TR.__getValueFromTag($TR.PRODIQ001_TAG118,'Contains'), $TR.__getValueFromTag($TR.PRODIQ001_TAG115,'Start with'), $TR.__getValueFromTag($TR.PRODIQ001_TAG117,'Exact Match'), $TR.__getValueFromTag($TR.PRODIQ001_TAG116,'End with')];
            var me = this;
            this.__init();
            this.meta.bind("MODEL.UPDATE", function(evt){
            	var searchConfig = this.getSearchConfiguration(evt);
            	this.checkForProperConfiguration(searchConfig);
            }, this);
            searchConfig = Ext.apply({
               // title: '<span class="title-text">' + 'Search' +'</span>',
               // titleAlign: 'left',
                frame: 'true',
                collapsible : false,
                style: 'margin:1px',
                height : SVMX.getWindowInnerHeight() - 10,
                toolPosition: 0,
               /* tools: [{
                    type:'backbtn',
                    //cls: 'svmx-back-btn',
                    handler: function(e, el, owner, tool){
                        me.__handeNavigateBack();
                    }
                }],*/
                layout: "fit",
								autoScroll: true,
								scrollable: true,
                items : this.__getUI(),
                dockedItems: [
                    {
                        dock: 'top', xtype: 'toolbar', margin: '0',cls: 'ibsearch-toolbar',
                        items : this.__getDockedUI()
                    }
                ],
            }, searchConfig || {});
            this.callParent([searchConfig]);
        },

        getSearchConfiguration : function(evn){
        	var displayFields = [];
            var searchFields = [];
			var refrenceDict = [];
			this.advancedExpression = evn.target.advancedExpression;
			var searchConfig = evn.target.search;
            if (searchConfig) {
                for (var i = 0; i < searchConfig.length; i++) {
                    var searches = searchConfig[i].searches;
                    if (searches) {
                        for (var j = 0; j < searches.length; j++) {
                            refrenceDict = searches[j].searchfields;
                            this.advancedExpression = searches[j].advancedExpression;
                        }
                    }
                }
            }
            return refrenceDict;
        },

        /*  this is for taking existing table name */
        checkForProperConfiguration : function(configurationArray){
        	var existingTable = {};
        	var tableConfig = configurationArray;
        	var me = this;
         	var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(),
            me = this;
            syncService.getObjectName()
            .done(function(info){
            	for(var tableIndex = 0; tableIndex < info.length ; tableIndex++){
            		existingTable[info[tableIndex].name] = info[tableIndex];
            	}
            	me.getConfigsyncAndLoadTable(existingTable, tableConfig);
            });
        },

        /* compair with existing table name, If not exist then not adding for search configuration */
        getConfigsyncAndLoadTable : function(existingTable, configurationArray){
        	var existingConfiguration = [];
        	for(var config in configurationArray){
        		if(this.isTableExist(configurationArray[config], existingTable)){
        			existingConfiguration.push(configurationArray[config]);
        		}
        	}
        	this.__parseConfig(existingConfiguration);
            this.__configArray = existingConfiguration;
            //this.__initComplete();

			/* Here checking if other  */
			this.fetchCustomObject();
			// if(SVMX.getCurrentApplication().isAppEmbedded()) {
// 				this.fetchCustomObject();
// 			}else{
// 				this.fetchMFLLabelDetail();
// 			}
        },

        /* checking with search configuration, wether table exist or not, If its exist then return TRUE otherwise FALSE */
        isTableExist : function(Config,existingTable){
        	var isTableExist = true;
			if(Config.lookupFieldAPIName){

				/* taking alise of the table, If tables relation is created */
				if(Config.objectName2){
					if(existingTable[Config.objectName2])
						isTableExist = true;
					else
						return false;
				}

				/* If lookup have some reference value then this should send reference value also */
				if(Config.displayType.toUpperCase() == "REFERENCE"){
					if(Config.relatedObjectName){
						if(existingTable[Config.relatedObjectName])
							isTableExist = true;
						else
							return false;
					}
				}
			}else{
				/* reference table name */
				if(Config.displayType.toUpperCase() == "REFERENCE"){
					if(Config.relatedObjectName){
						if(existingTable[Config.relatedObjectName])
							isTableExist = true;
						else
							return false;
					}
				}
			}
			return isTableExist;
        },

        /*  This method fetch custom name of the display column of the configuration */
        fetchMFLLabelDetail : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(),
            me = this;
            syncService.getSObjectInfos(this.__relationTable)
            .done(function(info){
            	me.__relationtableName = {};
            	for(var f_index = 0; f_index < info.length; f_index++){
					me.__objectInfo = info[f_index];
					me.__fieldsMap = {};
					var i = 0,l = me.__objectInfo.fields.length,fieldInfo = [];
					for(i = 0; i < l; i++){
						me.__fieldsMap[me.__objectInfo.fields[i].name] = me.__objectInfo.fields[i]
					}
					me.__relationtableName[me.__objectInfo.name] = me.__fieldsMap;
				}
				me.fetchMFLCustomFieldObject();
            });
        },

        /* Calling on completion of custom field Call */
        __customFieldComplete : function(data){
        	var displayColumnName = {};
			for(var kDataConfig = 0; kDataConfig < data.length; kDataConfig++ ){
				var config = data[kDataConfig];
				//displayColumnName[config.objectName + "_" + config.fieldName]= config.label;
				displayColumnName[config.object_api_name + "_" + config.api_name]= config.label;
			}

			/* Adding sequence of the column, This will help full  if one table's column name comes in two time */
			for(var kDisplayIndex = 0; kDisplayIndex < this.__backUpDisplayName.length; kDisplayIndex++ ){
				var kDisplayInde = kDisplayIndex + 1;
				var columnName = this.__backUpDisplayName[kDisplayIndex]+ "_" + kDisplayInde;
				this.__CustomObjectName[columnName] = displayColumnName[this.__backUpDisplayName[kDisplayIndex]];
				this.__displayFields[kDisplayIndex] = columnName;
			}
			this.__initComplete();
		},

		fetchMFLCustomFieldObject : function (){
        	var displayColumnName = {};
        	for(var kCustomfield = 0; kCustomfield < this.__displayConfig.length; kCustomfield++ ){
        		var config = this.__displayConfig[kCustomfield];
        		var objectFieldName = this.__relationtableName[config.objectName];
        		displayColumnName[config.objectName + "_" + config.fieldName] = objectFieldName[config.fieldName].label;
        	}
        	/* Adding sequence of the column, This will help full  if one table's column name comes in two time */
			for(var kDisplayIndex = 0; kDisplayIndex < this.__backUpDisplayName.length; kDisplayIndex++ ){
				var kDisplayInde = kDisplayIndex + 1;
				var columnName = this.__backUpDisplayName[kDisplayIndex]+ "_" + kDisplayInde;
				this.__CustomObjectName[columnName] = displayColumnName[this.__backUpDisplayName[kDisplayIndex]];
				this.__displayFields[kDisplayIndex] = columnName;
			}
			this.__initComplete();
        },

		/* refreshing UI of the screen */
        reSetScreen : function (){
            if(this.__searchText)
            	this.__searchText.setValue("");
        },

        /*  This method fetch custom name of the field */
        __init : function(){

            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(),
            me = this;
            syncService.getSObjectInfos([SVMX.getCustomObjectName("Installed_Product")])
            .done(function(info){
            	me.__relationtableName = {};
            	for(var f_index = 0; f_index < info.length; f_index++){
					me.__objectInfo = info[f_index];
					me.__fieldsMap = {};
					var i = 0,l = me.__objectInfo.fields.length,fieldInfo = [];
					for(i = 0; i < l; i++){
						me.__fieldsMap[me.__objectInfo.fields[i].name] = me.__objectInfo.fields[i]
					}
					me.__relationtableName[me.__objectInfo.name] = me.__fieldsMap;
				}
            });

        },

		/* On custom name field completion */
        __initComplete : function(){


               var cols = this.__getDisplayFields();

               var  l = cols.length;

                // store
                var fields = [];
                for(var i = 0; i < l; i++){
                    fields.push(cols[i]);
                }


                var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields,style : {"background-color" : "#D0CDCD","text-align":"left"},data:[]});

               this.__store.fields = cols;
                var gridColumns = [];
                for (var i = 0; i < l; i++) {
                    gridColumns.push({ text : cols[i],
                    	minWidth: 250,
                        handler : function(){
                        this.__slectedIBS
                        },
                        dataIndex : this.__displayFields[i],
                        flex : 1 });
                }

                this.__grid.columns = gridColumns;
                this.__grid.reconfigure(this.__store, gridColumns);



        },

		/* On tap of search button, Passing search text for filter the records */
        __find : function(params){
        	var accountID = this.meta.accountId;

        	//get current user detail from here
        	var userinfo = window.parent.SVMX.getCurrentApplication().__userInfo;

        	//TODO: Remove this condition for Search of the string
			if(params){
            	SVMX.getCurrentApplication().blockUI();
            	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE." + this.__config.mvcEvent, this, {
                        request : {
                            context : this,
                            handler : this.__findComplete,
                            text : params.text,
                            displayFields : this.__getFields(this.__displayFields),
                            displayConfig : this.__displayConfig,
                            searchFields : this.__searchFields,
                            referenceFilter : this.__referenceFilter,
                            searchFilter : this.__searchFilter,
                            searchCondition: this.__searchCondition,
                            advancedExpression : this.advancedExpression,
                            orderBy : this.__orderBy,
                            accountDetail : accountID,
                            relationTable : this.__relationTable,
                        	orderConfig : this.__orderConfig,
                        	mflRelation : this.__relationtableName,
                        	userInfo : userinfo
                        }
                    });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            }
            else{
            	SVMX.getCurrentApplication().blockUI();
            	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE." + this.__config.mvcEvent, this, {
                        request : {
                            context : this,
                            handler : this.__findComplete,
                            displayFields : this.__getFields(this.__displayFields),
                            displayConfig : this.__displayConfig,
                            searchFields : this.__searchFields,
                            referenceFilter : this.__referenceFilter,
                            advancedExpression : this.advancedExpression,
                            orderBy : this.__orderBy,
                            accountDetail : accountID,
                            relationTable : this.__relationTable,
                            orderConfig : this.__orderConfig,
                            mflRelation : this.__relationtableName,
                            userInfo : userinfo
                        }
                    });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            }

        },


        __findComplete : function(data){

            this.__store.loadData(data);
            SVMX.getCurrentApplication().unblockUI();
            this.__disableColumnSorting(true);
        },
         /* As we have the SFM configuration for sorting the search record,
disable the column sort for search grid*/
            __disableColumnSorting: function (disable){
             var grid = Ext.getCmp('searchGrid'),
                 cols = grid.query('gridcolumn'),
                 colLength = cols.length,
                 i = 0;


                 for(i; i < colLength; i++) {
                     if (disable) {
                         cols[i].sortable= false;
                     } else {
                         cols[i].sortable= true;
                     }
                 }
            },

		/* Fetching custom name of the field, If custom name is not there putting column name it self */
         __getDisplayFields : function(){
            var colFields = [];

            //var displayColumns = this.meta.advanceSearch.displayFields && this.meta.advanceSearch.displayFields.length > 0 ? this.meta.advanceSearch.displayFields : ['Name'];
             var displayColumns = this.__displayFields && this.__displayFields.length > 0 ? this.__displayFields : ['Name'];
            this.__displayFields = displayColumns;

            if(this.__displayFields){
                for (var i = 0; i < displayColumns.length; i++) {
                	var string = displayColumns[i];
                	var label ;//= this.__fieldsMap[string].label;
					if(this.__CustomObjectName[string])
						label = this.__CustomObjectName[string];
					else
						label = string;

                	colFields.push(label);
            	}
            }else{
                colFields.push('Name');
            }


            return colFields;
        },

        /* Initial field  name for loading the record */
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

        /* This method is opening selected IBs from search list */
        __slectedIBS : function(selectedRec){
            var data = {};
            data.action = "VIEW";
            data.recordIds = [selectedRec.data.Id];

            /* This is about open standalone */
            data.focused = true;
            data.accountId = this.meta.accountId;
            data.selectedIB = true;
            data.object = SVMX.getCustomObjectName("Installed_Product");
            SVMX.getCurrentApplication().setPendingMessage(data);
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt);


            this.__handeNavigateBack();
        },

		/* Making search UI for display search record */
        __getUI:function() {

                var me = this;
                var items = [];


                var cols = me.__getDisplayFields();
                var  l = cols.length;
                // store
                var fields = [];
                for(var i = 0; i < l; i++){
                    fields.push(cols[i]);
                }
                var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields,style : {"background-color" : "#D0CDCD","text-align":"left"}, this:[]});

                var gridColumns = [];

                for (var i = 0; i < l; i++) {
                    gridColumns.push({ text : cols[i], handler : function(){this.__slectedIBS},dataIndex :  this.__displayFields[i], flex : 1 });
                }

                var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
                    store: store,
                    //selModel: {selType : 'checkboxmodel', injectCheckbox: false},
                    columns: gridColumns, flex : 1,id:'searchGrid', width: "100%",
                    cls: 'ibsearch-grid',
                    viewConfig: {
                        listeners: {
                            select: function(dataview, record, item, index, e) {
                                /* trigger iOS web-container(UIWebview)'s delegate methods to hide/show back button*/
					                      if(SVMX.getCurrentApplication().isAppEmbedded()) {
					                      	//Enabline PIQ back button
					                          var btn = window.parent.Ext.getCmp('piqComBackbtn');
					                          btn.show();
					                      }
                                me.__slectedIBS(record);
                            }
                        }
                    }
               });

            this.__store = store;
            this.__grid = grid;

            // PRIQ-1417: Wrap grid in a container so that it's size change doesn't affect the toolbar.
            var gridWrapper = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXContainer", {
                width: '100%',
                height: '100%',
								//scrollable: true,
                items: [
                    grid
                ]
            });
            items.push(gridWrapper);

            return items;

            },



            find : function(){
                console.log('Reached');
            },

            __handeNavigateBack : function(){
// Defect- 028722, Work around for this defect, Scroll grid to top most position which will remove the white/blank space.
             var scrollPosition = 99999999;
             Ext.getCmp('searchGrid').getEl().down('.x-grid-view').scroll('top', scrollPosition, true);

                this.root.handleNavigateBack();
            },

            handleFocus : function(params){
                var me = this;
                me.__grid.getStore().loadData([]);
                me.__find();
            },
             __getDockedUI : function(){

                // searchText
                var me = this;
                 var searchlbl =  SVMX.create("com.servicemax.client.installigence.ui.components.Label", {
                        html : "<div></div>", width: '21.5%',cls: 'ibsearch-heading-label', padding : 5, height : 25, text: $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search') ,style : {"text-align":"left"}
                    });
                var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                    width: '38%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'), enableKeyEvents : true,
                    style: 'margin:10px',
                    listeners : {
                    keyup : function(that, e, opts) {
                        if(e.getKey() == e.ENTER){
                            me.__find({ text : searchText.getValue()});
                        }
                    }
                }

                });
                 var searchButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{
                 	xtype: 'button',
                 	cls:'ibsearch-search-btn',
                 	width: '13%',
                 	text: $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'),
                 	handler : function(){
                 		searchButton.focus();
                    	me.__find({ text : searchText.getValue()});
                	}
                });

                var cancelButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{
                	xtype: 'button',
                	cls:'ibsearch-cancel-btn',
                	width: '12%',
                	text: $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'),
                	handler : function(){

                    /* trigger iOS web-container(UIWebview)'s delegate methods to hide/show back button */
                      if(SVMX.getCurrentApplication().isAppEmbedded()) {
                          //Enabline PIQ back button button
                          var btn = window.parent.Ext.getCmp('piqComBackbtn');
                          btn.show();
                      }

                    me.__handeNavigateBack();
                }});
                var filterButton = me.__createSearchMenubarWithButton();

               /* taking UI reference for reSet value */
				this.__searchText = searchText;
                var winItems = [
                	searchlbl,
                	'->',
                	filterButton,
                	searchText,
                	searchButton,
                	cancelButton
        		];
            return winItems;

             },
             __createSearchMenubarWithButton:function() {
             	var me = this;
             	var menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain:true,
                    width: '17%',
                    maxHeight: 600,
                    autoScroll:true

                });
                for( var index = 0; index < this.__SearchOptions.length; index++){
                	var menuItem = {
                    	text : me.__SearchOptions[index],
                    	slectedIndex : index,
                    	style : {"text-align":"left"},
                    	handler : function(){
                        	me.__loadSelectedAccountRecords(this);
                    	}
                	};
                	menu.add(menuItem);
                }

            	this.__accountsMenubarButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{
                    //width: '15%',
                    cls: 'border-botton ibsearch-contains-filter',
                    disabled : false,
                    width: '18%',
                    text : $TR.__getValueFromTag($TR.PRODIQ001_TAG118,'Contains'),
                    titleAlign : 'right',
                    margin: '8 3 3 3',
                    menuAlign : 'tl-bl',
                    style : {"text-align":"right"},
                    menu : menu

                });
                return this.__accountsMenubarButton;
             },
			__loadSelectedAccountRecords : function(menuItem){
				this.__accountsMenubarButton.setText(menuItem.text);
				var conditionString = ['contains','sw','eq','ew'];
				this.__searchCondition = conditionString[menuItem.slectedIndex];
			},

			/* Here filtring the record of the SFM config */
            __parseConfig:function(Config){
				var displayFields = [];
				var searchFields = [];
				var referenceFilter = [];
				var searchFilter = [];
				var displayConfig = [];
				var searchConfigFields = Config;
				var orderConfig = [];
				var relationTable = [];
				relationTable.push(SVMX.getCustomObjectName("Installed_Product"));
				if (searchConfigFields) {
					for (var k = 0; k < searchConfigFields.length; k++) {
						var currentDictionary = searchConfigFields[k];
						this.getTableNameForRelation(currentDictionary, relationTable);
						if(currentDictionary.expressionType == "SRCH_Object_Fields"){
							var fieldType = currentDictionary.fieldType; //this will decide for field type
							var fieldName = currentDictionary.fieldName;
							if (fieldType == "Search"){

							/* filtring Search field for IBs */
								searchFields.push(fieldName);
								//if(currentDictionary.displayType != "REFERENCE"){
									searchFilter.push(currentDictionary);
								//}
							}else if (fieldType == "Result"){

							/* filtring display value for IBs */
								displayConfig.push(currentDictionary);

							}else if (fieldType == "OrderBy"){
								orderConfig.push(currentDictionary);
							}
						}else if(currentDictionary.expressionType == "SRCH_Object_Prefilter_Criteria"){
							referenceFilter.push(currentDictionary);
						}
					}
					/* shorting record with sequence given by config */
					this.__displayConfig = this.shortDisplatWithSequence(displayConfig);
					this.__displayFields = this.makingDisplayField(this.__displayConfig);
					this.__searchFields = searchFields;
					this.__referenceFilter = referenceFilter;
					this.__searchFilter = searchFilter;
					this.__orderConfig = orderConfig;
					this.__relationTable = relationTable;
					this.__backUpDisplayName = this.makingDisplayField(this.__displayConfig);
					/* If no advance expression there then making expression with AND condition */
					this.makingAdvanceExpression(referenceFilter.length);
				}
       		},

       		/* making sequence of the display field */
       		shortDisplatWithSequence : function (arr){
				arr.sort(function(a, b) {
    				return parseFloat(a.sequence) - parseFloat(b.sequence);
				});
				return arr;
			},

			/* Making uniq name of the colunm */
			makingDisplayField : function(displayFiled){
				var displayFields = [];
				for (var displayIndex = 0; displayIndex < displayFiled.length; displayIndex++) {
					var currentDictionary = displayFiled[displayIndex];

					/* this change for column name of the record, in one table might be there is same column name
					So adding with table name and making uniq */

					/* Here we have to make column name unique for multiColumn name support */
					displayFields.push(currentDictionary.objectName+ "_" +currentDictionary.fieldName);
					//displayFields.push(currentDictionary.object_api_name+ "_" +currentDictionary.api_name);
				}
				return displayFields;
			},

			/* If expression is not coming from server, Making expression with AND condition */
       		makingAdvanceExpression : function (expressionCount){
       			if(!this.advancedExpression){
       				var stringEx = "";
       				for(var ExIndex = 1; ExIndex <= expressionCount; ExIndex++){
       					if(ExIndex > 1)
       						stringEx = stringEx + " AND ";
       					stringEx = stringEx + " " + ExIndex;
       				}
       				this.advancedExpression = stringEx;
       			}
       		},

       		/* take table name for reference field */
       		getTableNameForRelation : function(config, relationArray){
       			if(config.lookupFieldAPIName){
       				relationArray.push(config.objectName);
       			}
       		},

			/* Making request for custom field of the column */
			fetchCustomObject : function(){
        		SVMX.getCurrentApplication().blockUI();
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
						"INSTALLIGENCE." + "FETCH_CUSTOM_FIELD_NAME", this, {
							request : {
								context : this,
								handler : this.__customFieldComplete,
								kConfigDict:this.__displayConfig,
							}
						});
				com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
				SVMX.getCurrentApplication().unblockUI();
       	 	}
		});
	}
})();
