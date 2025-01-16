/**
 * 
 */

(function(){
	var compsImpl = SVMX.Package("com.servicemax.client.installigence.ui.comps");

compsImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.ui.comps.StringField", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXTextField",
        alias: 'widget.inst.stringfield',
        
        constructor: function(config) {	
       	 	
       	 	var me = this;
			config.fld.getBinding().setter = function(value){
       	 		me.setValue(value);
	       	};
	       	
	       	config.fld.getBinding().getter = function(){
       	 		return me.getValue() || "";
	       	};
	       
          this.callParent([config]);       	 	
	       	config.fld.register(this);
        
        }
	 });
	 
	Ext.define("com.servicemax.client.installigence.ui.comps.StringFieldBarIcon", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXFieldContainer",
        alias: 'widget.inst.stringfieldBarIcon',
        __text : null, __btn : null, __lookup : null,__value: null,
        
        constructor: function(config) {	
       	 	
       	 	var me = this;
			config.fld.getBinding().setter = function(value){
       	 		me.setValue(value);
	       	};
	       	
	       	config.fld.getBinding().getter = function(){
       	 		return me.getValue() || "";
	       	};
	       	
	       	config.fld.getBinding().name = function(){
            	return me.getValue() || "";
          	};
	       	config = Ext.apply({
                layout : { type : "hbox"},
                items : [],
                defaults: {
                    hideLabel: true
                }
             }, config || {});
                     
            this.__lookup = SVMX.create("com.servicemax.client.installigence.ui.comps.TextFieldWithBarCodeIcon", config);
            this.__text = this.__lookup.getTextField();
            this.__btn = this.__lookup.getBarButton();
                
            this.callParent([config]);
	        config.fld.register(this.__text);
        },
        
        setValue : function(value){
        	this.__text.setValue(value);
        },
         getValue : function(){
            return this.__text.getValue();
        }
        
	 });
    
    compsImpl.Class("TextFieldWithBarCodeIcon", com.servicemax.client.lib.api.Object, {
        __config : null, 
        __lookupBtn : null, 
        __lookupText : null, 
        __selectedRecord : null, 
        __value : null,
        __constructor : function(config){
            this.__config = config || [];
            this.__config.items = [];
            this.__config.layout = 'hbox';
            this.__config.cls = 'svmx-barCodeField-field';
            this.__config.margin = '05, 30';
            this.__config.labelAlign ='top';        
            this.__lookupField();
            this.__selectedRecord = {};
        },
        
        getValue : function(){
            return this.__value;
        },
        
        getDisplayValue : function(){
            return this.__displayValue;
        },
        
        readOnly : function(){
            this.__lookupText.readOnly = true;
            this.__lookupBtn.disabled = true;
        },
        
        getTextField: function(){
        	return this.__lookupText;
        },
        
        getBarButton: function(){
        	return this.__lookupBtn;
        },
        
        __lookupField : function(){         
            
            // show the field
            var me = this;
            var items = [];
            this.__lookupBtn = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
            	iconCls: 'svmx_BarIcon_Icon',
               	margin: '0, 5',
                disabled: this.__config.fld.readOnly, 
                handler: function(){
                    me.launchScanner();
                }
            });
         
            this.__lookupText = SVMX.create('com.servicemax.client.installigence.lookup.TextField', {
                value: this.getValue(),
                readOnly: this.__config.fld.readOnly,
                allowBlank: !this.__config.fld.required,
                //fieldStyle: 'background-color: #ddd; background-image: none;',
                
                listeners: {
                    specialkey: function(f,e){
                        if(e.getKey() == e.ENTER){
                            alert("test1");
                        }
                    },
                    blur: function(){
                        if(this.getValue().trim() === ''){
                        
                            // Clear lookup value
                            //me.setValue('');
                        }
                        me.__lookupBtn.hide();
                    },
                    focus : function(){
                    	me.__lookupBtn.show();
                    }
                }
            });
            this.__lookupBtn.hide();
            this.__config.items.push(this.__lookupText);
            this.__config.items.push(this.__lookupBtn);
        },
         /* This method is responsible for launching CustomActionCall */
        launchScanner : function() {
        		var  me = this;
                var d = SVMX.Deferred();
                var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
                var browserRequest = nativeservice.createScanRequest();
                browserRequest.bind("REQUEST_COMPLETED", function(evt){
                if (evt.data.data && !evt.data.data.cancelled) {
                    var text = evt.data.data.text;
                    me.__lookupText.setValue(text);
                    me.__lookupText.focus();
                } else if (evt.data.data && evt.data.data.cancelled) {
                    //SVMX.getCurrentApplication().getRoot().setEnableHardwareBack(false);
                }
                    d.resolve(evt);
                }, this);
                browserRequest.bind("REQUEST_ERROR", function(evt){
                    d.reject({
                      //text: TS.T("TODO", "The application does not exist. Please contact your system administrator to update the application path or install the necessary software."),
                      //type: "INFO"
                    });
                }, this);

                browserRequest.execute({
                    link: ""
                },function(a,b){
                	
                });

                return d.promise();
            }
        
    });
	
	Ext.define("com.servicemax.client.installigence.ui.comps.BooleanField", {
        extend: "com.servicemax.client.installigence.ui.components.Checkbox",
        alias: 'widget.inst.booleanfield',
        
        constructor: function(config) {	
       	 	
       	 	var me = this;
       	 	config.fld.getBinding().setter = function(value, disableEvents){
            //blur is not firing in iPad web kit. Change event is implemented, if the new record(new node) is selected in tree
            //change event. suspendEvents and resume events if the new record is selected in the tree. 
            if(disableEvents) me.suspendEvents();
       	 		me.setValue(value);
            if(disableEvents) me.resumeEvents();
	       	};
	       	
	       	config.fld.getBinding().getter = function(){
       	 		return me.getValue();
	       	};
	       	this.callParent([config]);
       	 	
	       	config.fld.register(this);
        }
    });
	
	Ext.define("com.servicemax.client.installigence.ui.comps.ReferenceField", {
        extend: "com.servicemax.client.installigence.lookup.Container", 
        alias: 'widget.inst.fieldcontainer',
        	
        constructor: function(config) {	
        	var me = this;        	
       	    config.items = [];
       	    config.objectName = config.fld.referenceTo[0];
       	    
       	    config.columns = (config.objectName == "Product2" && config.meta.productDisplayFields) 
       	    									?  config.meta.productDisplayFields : [{name: 'Name'}];
       	    config.searchColumns = (config.objectName == "Product2" && config.meta.productDisplayFields) 
												?  config.meta.productSearchFields : [{name: 'Name'}];
       	    config.mvcEvent = "GET_RECORDS";
       	    
       	          	    
       	    this.callParent([config]);
       	    if(config.fld._parent.__objectName.toUpperCase() === "ACCOUNT" ) {              
              this.makeReadOnly();
            } 
       	 	
       	 	//now value setter and getters       	 	
       	 	config.fld.getBinding().setter = function(value){
       	 		me.setValue(value);
	       	};
	       	
	       	config.fld.getBinding().getter = function(){
    	 		  return me.getValue() || "";
	       	};

          config.fld.getBinding().name = function(){
            return me.getLookupText().getValue() || "";
          };
	          	
	       	config.fld.register(this.getLookupText());     	 	
       	 	
        }
    });
	
  Ext.define("com.servicemax.client.installigence.ui.comps.RecordTypeField", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXComboBox",
        alias: 'widget.inst.recordtypefield',

        constructor: function(config){

          var recordTypes = config.recordTypeMappings, values = [];

          if(recordTypes){
            for(var i=0; i< recordTypes.length; i++){
              values.push({value : recordTypes[i].recordTypeId, display : recordTypes[i].name});
            }
          }

          var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', 
              {fields: ['display', 'value'], data : values});
          
          config = Ext.apply({
            store : store,
            queryMode : 'local',
            displayField : 'display',
            valueField : 'value',
          }, config || {});

          
          var me = this;
          config.fld.getBinding().setter = function(value){
            me.setValue(value);
          };
          
          config.fld.getBinding().getter = function(){
          return me.getValue() || "";
          };

          config.fld.getBinding().updateStore = function(store){
          if(store.length > 0){
            me.store.loadData(store);
          }
          else{
            me.store.loadData([],false);
          }
          };
          
          this.callParent([config]);
          config.fld.register(this);
        }
  });

	Ext.define("com.servicemax.client.installigence.ui.comps.PicklistField", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXComboBox",
        alias: 'widget.inst.picklistfield',
        
        constructor: function(config) {	
       	 	
        	var lov = config.fld.getListOfValues(), l = lov.length, i, values = [];
       	 	if(!config.fld.dependentPickList){
		    	for(i = 0; i < l; i++){
		   	 		values.push({value : lov[i].value, display : lov[i].label});
		   	 	}
       	 	}	
        	
       	 	
       	 	var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', 
       	 			{fields: ['display', 'value'], data : values});
       	 	
       	 	config = Ext.apply({
              store : store,
              queryMode : 'local',
              displayField : 'display',
              valueField : 'value',
              triggerAction:'all',
              lastQuery :' ',
              enableKeyEvents: true,
              listeners: {
                 keyup: function() {

                      var string = this.getRawValue();
                      if (string.length === 0){
                            this.clearValue();
                            this.applyEmptyText();
                            this.reset();
                            this.lastSelection = [];
                            this.doQuery("", false);
                      }
                       this.store.filter('value', this.getRawValue(), false, false);
                 }
              }
              // editable : false //Rahman: To fix 028142 added below code
              
          }, config || {});
       	 
       	 	var me = this;
       	 	config.fld.getBinding().setter = function(value){
	       		me.setValue(value);
       	 	};
       	 	
       	 	config.fld.getBinding().getter = function(){
    	 		return me.getValue() || "";
	       	};

	       	config.fld.getBinding().updateStore = function(store){
    	 		if(store.length > 0){
    	 			me.store.loadData(store);
    	 		}
    	 		else{
    	 			me.store.loadData([],false);
    	 		}
	       	};
	       	
	       	this.callParent([config]);
	       	config.fld.register(this);       	
        }
    });
	
	Ext.define("com.servicemax.client.installigence.ui.comps.DateField", {
        extend: "com.servicemax.client.ui.components.controls.impl.SVMXDate",
        alias: 'widget.inst.datefield',
        
        constructor: function(config) {	
       	 	
       	 	config = Ext.apply({
              // editable : false //Rahman: To fix 028142 added below code
				
       	 	}, config || {});
       	 
       	 	var me = this;
       	 	config.fld.getBinding().setter = function(value, disableEvents){
            //blur is not firing in iPad web kit. Change event is implemented, if the new record(new node) is selected in tree
            //change event. suspendEvents and resume events if the new record is selected in the tree.
            if(disableEvents) me.suspendEvents();
	       		me.setValue(value);
            if(disableEvents) me.resumeEvents();
       	 	};
       	 	
       	 	config.fld.getBinding().getter = function(){
       	 		var value = me.getValue() || "";	 		
       	 		if(value && value != ""){
       	 			value = Ext.Date.format(me.getValue(),"Y-m-d")
       	 		}
       	 		return value;
	       	};
	       	
	       	this.callParent([config]);
	       	config.fld.register(this);        	
        }
    });
	
	Ext.define("com.servicemax.client.installigence.ui.comps.DatetimeField", {
        extend: "com.servicemax.client.ui.components.controls.impl.SVMXDatetime",
        alias: 'widget.inst.datetimefield',
        
        constructor: function(config) {	
       	 	
       	 	config = Ext.apply({
       	 		cls : 'svmx-custom-date-time'
       	 	}, config || {});
       	 
       	 	var me = this;
       	 	config.fld.getBinding().setter = function(value, disableEvents){
            //blur is not firing in iPad web kit. Change event is implemented, if the new record(new node) is selected in tree
            //change event. suspendEvents and resume events if the new record is selected in the tree.
            if(disableEvents) me.suspendEvents();
	       		if(value && value != ""){
              var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
	       			value = value.substring(0, "yyyy-mm-ddTHH:mm:ss".length).replace("T", " ");
              value = DatetimeUtils.convertToTimezone(value);
              // value = moment.utc(value).toDate(); // converting UTC date into local time zone.
	       			var dateString = DatetimeUtils.getFormattedDatetime(value, DatetimeUtils.getDefaultDateFormat());
              var timeString = DatetimeUtils.getFormattedDatetime(value, "HH:mm"); // 24 hour format.
	       			value = dateString + "T" + timeString;
	       		}

            
       	 		me.setValue(value);
            if(disableEvents) me.resumeEvents();
       	 	};
       	 	
       	 	config.fld.getBinding().getter = function(){
       	 		var value = me.getValue() || "";
       	 		var actValue = value;
       	 		if(value && value != ""){
       	 			value = new Date(value);
       	 			value = new Date(value.getTime() + (value.getTimezoneOffset() * 60000))
       	 			value = value.toISOString();
       	 			value = value.substring(0, value.length - 1);
       	 			value = value + "+0000";
       	 		}
    	 		return value;
	       	};
	       	
	       	this.callParent([config]);
	       	config.fld.register(this.getDateField());
	       	config.fld.register(this.getTimeField());        	
        }
    });
};

})();

// end of file