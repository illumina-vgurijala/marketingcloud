// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.technicalattributes\src\api.js
/**
 * ServiceMax UIControl/Component Library for Technnical Attribute.
 * @class com.servicemax.client.technicalattributes.api
 */
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.technicalattributes.api");
appImpl.init = function(){

    appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
        __constructor : function(){

        },

        beforeRun: function (options) {
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
             
            this.__eventBus = SVMX.create("com.servicemax.client.technicalattributes.impl.EventBus", {});
            // create the named default controller
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){
                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);
                }, context : this});
            }, context : this, additionalParams : { eventBus : this.__eventBus }});
            options.handler.call(options.context);
        },
        
        getEventBus : function(){
            return this.__eventBus;
        },

        run : function(){
            this.__recordId = SVMX.getUrlParameter("Id");
            this.getMetaData();
        },

        getMetaData: function() {
            this.blockUI();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "TECHNICALATTRIBUTE.GET_META_DATA", this,
                            {
                                request : { 
                                    context : this,
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetMetaDataComplete: function(metaData) {
            this.updateMetaData(metaData);
            if(SVMX && SVMX.getClient() && SVMX.getClient().__appParams && metaData.instanceName){
                SVMX.getClient().__appParams.instanceName = metaData.instanceName;
            }
            var translations = {};
            for (var arrayTran in metaData.translations){
                    // BAC-4394 - Addressing XSS issue for all translations (tags) in this page.
                    translations[arrayTran] = Ext.String.htmlEncode(metaData.translations[arrayTran])
                    
            };
            window.$TR = translations;
            if (!this.__recordId) {
                this.unblockUI();
                alert($TR.PARAMS_ERROR);
            } else {
                this.getTemplateData();
            }

        },

        updateMetaData: function(metaData) {
            var newMetaData = {};
            var isProductIQEnabled = metaData.isProductIQEnabled;
            if (isProductIQEnabled && isProductIQEnabled.toLowerCase() == 'true') {
                newMetaData['isProductIQEnabled'] = true;
            } else {
                newMetaData['isProductIQEnabled'] = false;
            }
            var isTechnicalAttributesEnabled = metaData.isTechnicalAttributesEnabled;
            if (isTechnicalAttributesEnabled && isTechnicalAttributesEnabled.toLowerCase() == 'true') {
                newMetaData['isTechnicalAttributesEnabled'] = true;
            } else {
                newMetaData['isTechnicalAttributesEnabled'] = false;
            }
            newMetaData.timeZone = metaData.timeZone;
            this.__metaData = newMetaData;
        },
        getTemplateData: function() {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "TECHNICALATTRIBUTE.GET_TEMPLATE_DATA", this,
                            {
                                request : { 
                                    context : this,
                                    recordId: this.__recordId
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetTemplateDataComplete: function(templateData) {
            this.unblockUI();
            const me = this;
            Ext.onReady(function() {
                me.createRootPanel(templateData);
            });
        },  

        createRootPanel:function(templateData){
            SVMX.create('com.servicemax.client.technicalattributes.root.RootPanel',{
                collapsible : false,
                titleAlign: 'center', 
                frame: 'true',
                template: templateData,
                metaData: this.__metaData,
                recordId: this.__recordId
            });
        },
            
        blockUI : function(){
          if (this.__spinner) {
            this.__spinner.spin($("#" + SVMX.getDisplayRootId())[0]);
          }
          else {
            var top = window.innerHeight/2 - 100;
            var opts = {
              lines: 25, // The number of lines to draw
              length: 25, // The length of each line
              width: 5, // The line thickness
              radius: 30, // The radius of the inner circle
              corners: 1, // Corner roundness (0..1)
              rotate: 0, // The rotation offset
              direction: 1, // 1: clockwise, -1: counterclockwise
              color: '#ffa384', // #rgb or #rrggbb or array of colors
              speed: 3, // Rounds per second
              trail: 60, // Afterglow percentage
              shadow: false, // Whether to render a shadow
              hwaccel: false, // Whether to use hardware acceleration
              className: 'spinner', // The CSS class to assign to the spinner
              zIndex: 2e9, // The z-index (defaults to 2000000000)
              top: top
            };
            this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
          }
        },
        
        unblockUI : function(){
          this.__spinner.stop();
        },
    });
}

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.technicalattributes\src\commands.js
(function(){
	var technicalattributecommands = SVMX.Package("com.servicemax.client.technicalattributes.commands");
	
	technicalattributecommands.init = function(){
		technicalattributecommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_META_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetMetaDataComplete(data);
			}
			
		},{});
		
		technicalattributecommands.Class("GetTemplateData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_TEMPLATE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetTemplateDataComplete(data);
			}
			
		},{});

		technicalattributecommands.Class("SaveTechnicalAttribute", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.SAVE_TA"});
			},
		
			result : function(data) { 
				this.__cbContext.onSaveComplete(data);
			}
			
		},{});

		technicalattributecommands.Class("GetHistoryRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_HISTORY_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onHistoryFetchComplete(data);
			}
			
		},{});

	};
})()

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.technicalattributes\src\impl.js

(function(){
    
    SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXC";
    SVMX.appType = SVMX.getClient().getApplicationParameter("app-type") || "external";
    
    var instImpl = SVMX.Package("com.servicemax.client.technicalattributes.impl");

    instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor : function(){
            this.__base();
            instImpl.Module.instance = this;
        },

        initialize : function(){
        },
        
        afterInitialize : function(){
            
        },
        beforeInitialize: function() {
            com.servicemax.client.technicalattributes.api.init();
            com.servicemax.client.technicalattributes.root.init();
            com.servicemax.client.technicalattributes.commands.init();
            com.servicemax.client.technicalattributes.operations.init();
        },

        createServiceRequest : function(params, operationObj){
            var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
            servDef.getInstanceAsync({handler : function(service){
                var options = params.options || {};
                var p = {type : options.type || "REST", endPoint : options.endPoint || "",
                                    nameSpace : "SVMXC"};
                var sm = service.createServiceManager(p);
                var sRequest = sm.createService();
                params.handler.call(params.context, sRequest);
            }, context:this });
        },
        
    }, {
        instance : null
    });
    
    instImpl.Class("EventBus", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor : function(){ this.__base(); }
    }, {
        __instance : null,
        getInstance : function(){
            if(!instImpl.EventBus.__instance){
                instImpl.EventBus.__instance = SVMX.create("com.servicemax.client.technicalattributes.EventBus", {});
            }
            return instImpl.EventBus.__instance;
        }
    });
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.technicalattributes\src\operations.js
(function(){
    var technicalattributeoperations = SVMX.Package("com.servicemax.client.technicalattributes.operations");

technicalattributeoperations.init = function(){
    var Module = com.servicemax.client.technicalattributes.impl.Module; 
    
    technicalattributeoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            technicalAttributeOnWeb.JsrGetMetadata('', function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});

    technicalattributeoperations.Class("GetTemplateData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder) {
            var me = this;
            var requestData = request.recordId;
            technicalAttributeOnWeb.JsrGetAttributesTemplateInstanceForIB(requestData, function(result, evt){               
                responder.result(result);
            }, this);
        }

    }, {});

    technicalattributeoperations.Class("SaveTechnicalAttribute", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder) {

            technicalAttributeOnWeb.JsrSaveTechnicalAttributeDetails(request.instanceObject, function(result, evt){               
                responder.result(result);
            }, this);
        }

    }, {});

    technicalattributeoperations.Class("GetHistoryRecord", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                var payload = SVMX.getCustomFieldName('SM_Attr_Payload');
                var capturedOn = SVMX.getCustomFieldName('SM_Captured_On');
                var timeZone = request.timeZone;
                sRequest.bind("REQUEST_COMPLETED", function(evt){
                    var records = evt.data.records;
                    if (records.length > 0) {
                        var object = records[0];
                        var capturedOnDate = object[capturedOn];
                        var payloadJson = object[payload];
                        var data = {};
                        data["capturedOn"] = capturedOnDate;
                        data["template"] = payloadJson;
                        responder.result(data);
                    }
                    else {
                        responder.result([]);
                    }
                }, this);
                sRequest.bind("REQUEST_ERROR", function(evt){
                    responder.result([]);
                }, this);
                var table = SVMX.getCustomFieldName('SM_IB_Attributes_History');
                var IB_Id = SVMX.getCustomFieldName('SM_Installed_Product_Id');
                var filterOnCapturedOnDate = '';
                var previousCapturedOnDate ;
                if(request.presentCapturedOnDate){
                    previousCapturedOnDate = request.presentCapturedOnDate;
                    var prevDateM = moment.tz(previousCapturedOnDate,timeZone);
                    var prevDate = prevDateM._d;
                    prevDate = new Date(prevDate.valueOf() + prevDate.getTimezoneOffset() * 60000);
                    var formattedDate;
                    if (request.isPreviousRecord) {
                        formattedDate = Ext.Date.format(prevDate,'Y-m-d 00:00:00');
                    } else {
                        formattedDate = Ext.Date.format(prevDate,'Y-m-d 23:59:59');
                    }
                    var newDate = new Date(formattedDate);
                    var gmtDate = new Date(newDate.valueOf() - prevDateM._offset * 60000);
                    var newFormattedString = Ext.Date.format(gmtDate,'Y-m-d\\TH:i:s.000\\Z');
                    previousCapturedOnDate = newFormattedString;

                } 
                if(request.isPreviousRecord){
                    filterOnCapturedOnDate = ' AND '+capturedOn+' < ' + previousCapturedOnDate + " order by " + capturedOn + " desc limit 1  ";
                }else{
                    filterOnCapturedOnDate = ' AND '+capturedOn+' > ' + previousCapturedOnDate + " order by " + capturedOn + " asc limit 1  ";
                }
                //var query = encodeURI("select " + capturedOn + "," + payload + " from "+ table + " where " + IB_Id + " = '" + request.recordId + "' order by " + capturedOn + " desc limit 1 offset " + request.offset);
                var query = encodeURI("select " + capturedOn + "," + payload + " from "+ table + " where " + IB_Id + " = '" + request.recordId + "'" + filterOnCapturedOnDate);
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        }

    }, {}); 

};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.technicalattributes\src\root.js
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.technicalattributes.root");

appImpl.init = function() {        
        var uiComposites = com.servicemax.client.ui.components.composites.impl;
        Ext.define("com.servicemax.client.technicalattributes.root.RootPanel", {
            extend : "com.servicemax.client.ui.components.composites.impl.SVMXSection", 
            layout: 'border',
            width: window.innerWidth,
            cls:'svmx-ta-root-container',
            minWidth: 500,
            sectionCount:0,
            constructor : function(config){
                var me = this;
                config = config || {};
                config.renderTo = SVMX.getDisplayRootId();
                var screenHeight = window.innerHeight;
                config.height = screenHeight+"px";             
                config.autoScroll = true;
                config.title = "<span class='title-text'>"+$TR.TA+"</span>";
                this.callParent([config]);
                this.__recordId = config.recordId;
                this.__historyOffset = 0;
                var items = [];
                var templateData = config.template;
                this.noneStr = $TR.NONE;
                this.__historyCount = templateData.totalHistoryRecords;
                this.__showCurrent = true;
                var templateNotAvailable = false;
                var templateNotRenderable = false;
                var metaData = config.metaData;
                var productIQEnabled = metaData.isProductIQEnabled;
                var taEnabled = metaData.isTechnicalAttributesEnabled;
                this.__timeZone = metaData.timeZone;
                this.__isPreviousRecord = true;
                this.__presentCapturedOnDate = '';
                if (productIQEnabled && taEnabled) {
                  if (templateData) {
                    if (templateData.isTemplateFound) {
                      var attributesPayload = templateData.attributesTemplateInstance.attributesPayload;
                      if (attributesPayload) {
                          attributesPayload = JSON.parse(attributesPayload);
                      }
                      if (attributesPayload) {
                        if(!this.checkForAttributesError(attributesPayload)) {
                          var header = this.addTitleButtons();
                          items.push(header);
                          this.__payloadJson = attributesPayload;
                          var templateLayout = this.addLayoutForAllSections(attributesPayload);
                          var panel = {
                            xtype: "svmx.section",
                            collapsible:false,
                            id: 'bodyPanel',
                            cls: 'svmx-ta-content-body',
                            width: '100%',
                            height: screenHeight - 100,
                            layout:'auto',
                            items: [templateLayout],
                            itemId: "contentPanel"
                          };
                          items.push(panel);
                        } else {
                          templateNotRenderable = true;
                        }
                      } else {
                        templateNotRenderable = true;
                      }
                    } else {
                      templateNotAvailable = true;
                    }
                  } else {
                    templateNotAvailable = true;
                  }
                }
                if (templateNotAvailable || templateNotRenderable || !productIQEnabled || !taEnabled) {
                  var labelText = '';
                  if(!productIQEnabled) {
                    labelText = $TR.PIQ_DISABLED;
                  } else if (!taEnabled) {
                    labelText = $TR.TA_DISABLED;
                  } else if (templateNotRenderable) {
                    labelText = $TR.ATTRIBUTES_ERROR;
                  } else {
                    labelText = $TR.NO_TA;
                  }
                  var errorMsg = {
                        xtype: "svmx.label",
                        text: labelText,
                        width: "100%"
                      }
                  items.push(errorMsg);
                }
                var panel = {
                  xtype: "svmx.section",
                  collapsible:false,
                  border: false,
                  width: '100%',
                  layout:'auto',
                  items: items,
                }
                this.add(panel);
                if (!templateNotAvailable || !templateNotRenderable || productIQEnabled || taEnabled) {
                  this.__prevBtn = this.query("#previousButton")[0];
                  this.__nextBtn = this.query("#nextButton")[0];
                  this.__currBtn = this.query("#currentButton")[0];
                  this.__saveBtn = this.query("#saveButton")[0];
                  this.__lmdLabel = this.query("#lastModifiedDate")[0];
                  this.__errorlbl = this.query("#errorlbl")[0];
                  this.setDefault();
                }
                Ext.EventManager.onWindowResize(function(w, h) {
                    var bodyPanel = Ext.getCmp('bodyPanel');
                    var toolbarPanel = Ext.getCmp('toolbarPanel');
                    if(w < 500) w = 500;
                    me.setSize(w,h);
                    var errorlbl = Ext.getCmp('errorlbl');
                    errorlbl.setSize(w,errorlbl.getHeight());
                    bodyPanel.setHeight(h - 100);
                    for(var i = 0; i< me.sectionCount; i++) {
                      var sectionPanel = Ext.getCmp('sectionPanel'+i);
                      sectionPanel && sectionPanel.setSize(w - 30,sectionPanel.getHeight());
                      var headerToolbar = Ext.getCmp('toolbarHeader'+i);
                      headerToolbar && headerToolbar.setSize(w - 30,headerToolbar.getHeight());
                    }
                    toolbarPanel.setWidth(w - 30);
                });
            },

            checkForAttributesError: function(templateJson) {
              var attributesError = true;
              var sections = templateJson.fields;
              for(var i = 0; i< sections.length; i++) {
                var section = sections[i];
                var attributes = section.technicalAttributes;
                for(var j = 0; j< attributes.length; j++) {
                  var attribute = attributes[j];
                  if(attribute.hasOwnProperty('label') && attribute.hasOwnProperty('defaultValue') && attribute.label) {
                    attributesError = false;
                    break;
                  }
                }
              }
              return attributesError;
            },

            setDefault: function() {
              this.__prevBtn.setDisabled(true);
              this.__nextBtn.setDisabled(true);
              this.__currBtn.setDisabled(true);
              this.__saveBtn.setDisabled(false);
              if (this.__historyCount && this.__historyCount > 1) {
                this.__prevBtn.setDisabled(false);
              }
            },

            addTitleButtons: function() {
              var me = this;
              var displaycurrentLmd = this.getCurrentFormatedLMD();
              var header = {
                  xtype: 'svmx.toolbar',
                  itemId: "topBar",
                  id: "toolbarPanel",
                  cls: 'svmx-ta-toolbar',
                  margin: '5 0 5 10',
                  width: this.width - 20,
                  items: [
                      {
                          xtype: "svmx.label",
                          text: displaycurrentLmd,
                          docked  : "left",
                          itemId: "lastModifiedDate",
                      },
                      '->',
                      {
                          text: $TR.PREVIOUS,
                          disabled: false,
                          itemId:"previousButton",
                          cls:'svmx-nav-btn',
                          handler : function() {
                            me.prevButtonClicked();
                          }
                      },
                      '-',
                      {
                          text: $TR.NEXT,
                          disabled: false,
                          itemId:"nextButton",
                          cls:'svmx-nav-btn',
                          handler : function() {
                            me.nextButtonClicked();
                          }
                      },
                      '-',
                      {
                          text: $TR.CURRENT,
                          disabled: false,
                          itemId:"currentButton",
                          cls:'svmx-nav-btn',
                          handler : function() {
                            me.currentButtonClicked();
                          }
                      },
                      { xtype: 'tbspacer', width: 20 },
                      {
                        text: $TR.SAVE,
                        itemId: "saveButton",
                        cls: 'svmx-ta-save-btn',
                        minWidth: '75',
                        handler: function() {
                          me.setCurrentDate(me.getCurrentTime());
                          me.saveTA();
                        }
                      }
                  ]
              };
              return header;
            },

            getCurrentFormatedLMD: function() {
              var attributeInstance = this.template.attributesTemplateInstance;
              if (attributeInstance) {
                var lmdString = attributeInstance.capturedOn;
                if (!lmdString) {
                  lmdString = attributeInstance.lmd;
                  this.__presentCapturedOnDate = this.template.lastHistoryCapturedOn;
                } else {
                  this.__presentCapturedOnDate = lmdString;
                }
                return this.getFormatedDate(lmdString);
              }
              return "";
            },

            getFormatedDate: function(dateStr) {
              if (dateStr) {
                var mObject = moment.tz(dateStr,this.__timeZone)._d;
                var lmd = new Date(mObject.valueOf() + mObject.getTimezoneOffset() * 60000);
                var formatedLMD = Ext.Date.format(lmd, 'F j, Y, g:i a');
                return formatedLMD;
              }
              return "";
            },

            setCurrentDate: function(text){
              if(text === null || text === undefined){
                text = '';
              }
              this.__lmdLabel.setText(text);
            },

            getCurrentTime: function(){
              return Ext.Date.format(new Date(), 'F j, Y, g:i a');
            },

            prevButtonClicked: function() {
              this.__isPreviousRecord = true;
              this.__historyOffset++;
              this.enablingButtons();
              this.fetchHistoryData();
            },

            nextButtonClicked: function() {
              this.__isPreviousRecord = false;
              this.__historyOffset--;
              this.enablingButtons();
              if (this.__historyOffset == 0) {
                this.currentButtonClicked();
              } else {
                this.fetchHistoryData();
              }
            },

            enablingButtons: function() {
              var historyCount = this.__historyCount;
              if (this.__historyOffset < historyCount) {
                this.__nextBtn.setDisabled(false);
              } else {
                this.__nextBtn.setDisabled(true);
              }
              if ((this.__historyOffset + 1) < historyCount) {
                this.__prevBtn.setDisabled(false);
              } else {
                this.__prevBtn.setDisabled(true);
              }
              this.__currBtn.setDisabled(false);
              this.__saveBtn.setDisabled(true);
              this.__showCurrent = false;
            },

            currentButtonClicked: function() {
              this.__historyOffset = 0;
              this.__showCurrent = true;
              this.setDefault();
              var payloadJson = this.__payloadJson;
              if (payloadJson) {
                var contentSection = this.query("#contentSection")[0];
                if (contentSection) {
                  contentSection.destroy();
                }
                var taPanel = this.query("#contentPanel")[0];
                var contentPanel = this.addLayoutForAllSections(payloadJson, false);
                taPanel.add(contentPanel);
              }
              var displaycurrentLmd = this.getCurrentFormatedLMD();
              this.__lmdLabel.setText(displaycurrentLmd);
            },

            fetchHistoryData: function() {
              this.blockUI();
              var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                              "TECHNICALATTRIBUTE.GET_HISTORY_DATA", this,
                              {
                                  request : { 
                                      context : this,
                                      recordId: this.__recordId,
                                      offset: this.__historyOffset,
                                      isPreviousRecord: this.__isPreviousRecord,
                                      presentCapturedOnDate: this.__presentCapturedOnDate,
                                      timeZone:this.__timeZone
                                  }
                              });
              SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },

            onHistoryFetchComplete: function(data) {
              if (data) {
                var historyTemplate = data.template;
                if (historyTemplate) {
                  var attributesPayload = JSON.parse(historyTemplate);
                  if (attributesPayload) {
                    var contentSection = this.query("#contentSection")[0];
                    if (contentSection) {
                      contentSection.destroy();
                    }
                    var taPanel = this.query("#contentPanel")[0];
                    var contentPanel = this.addLayoutForAllSections(attributesPayload, true, true);
                    taPanel.add(contentPanel);
                  }
                }
                var capturedOn = data.capturedOn;
                this.__presentCapturedOnDate = capturedOn;
                var capturedOnDate = this.getFormatedDate(capturedOn);
                this.__lmdLabel.setText(capturedOnDate);
              }
              this.unblockUI();
            },

            addLayoutForAllSections: function(attributesPayload,disableAllItems, isHistory) {
              var sections = attributesPayload.fields;
              this.sectionCount = sections.length;
              this.fieldBindings = this.fieldBindings || [];
              var editors = [];
              var errorSection = this.createErrorSection();
              editors.push(errorSection);
              for(var i = 0; i< sections.length; i++) {
                var section = sections[i];
                var attributes = section.technicalAttributes;
                if(!this.checkForSectionAttributes(attributes)) {
                  var sectionItem = this.createSectionItem(section,i,disableAllItems, isHistory);
                  editors.push(sectionItem);
                }
              }
              var fieldSet = {
                  xtype:      "svmx.fieldset",
                  layout: 'auto',
                  width: '100%',
                  items:      editors,
                  itemId: "contentSection",
                  overrideFieldLabelAlign: false,
                  labelAlign: "top"
              };
              return fieldSet;
            },

            checkForSectionAttributes: function(attributes) {
              var attributesError = true;
              for(var j = 0; j< attributes.length; j++) {
                var attribute = attributes[j];
                if(attribute.hasOwnProperty('label') && attribute.hasOwnProperty('defaultValue') && attribute.label) {
                  attributesError = false;
                  break;
                }
              }
              return attributesError;
            },

            createErrorSection : function(){
              var errorMSG = {
                xtype: 'label',
                forId: 'myFieldId',
                text: '',
                id: 'errorlbl',
                hidden: false,
                style: {
                  'color':'red',
                  'style': 'Helvetica',
                  'font-size': '15px',
                  'textAlign':'center',
                },
                margin: '0 0 0 10',
                }
              return errorMSG;
            },

            createSectionItem: function(sections, sectionIndex,disableAllItems, isHistory) {
              var attributes = sections.technicalAttributes;
              var editors = [];
              for(var i = 0; i< attributes.length; i++) {
                var attribute = attributes[i];
                if(attribute.hasOwnProperty('label') && attribute.hasOwnProperty('defaultValue') && attribute.label) {
                  var fieldItem = this.createFieldItem(attribute,sectionIndex, i, disableAllItems, isHistory);
                  editors.push(fieldItem);
                }
              }
              var fieldSet = {
                  xtype:      "svmx.fieldset",
                  layout: 'auto',
                  width: '100%',
                  items:      editors,
                  overrideFieldLabelAlign: false,
                  labelAlign: "top"
              };
              var sectionTitle = Ext.String.htmlEncode(sections.title); //BAC-4081 -- XSS security issue, 
              var header = {
                  xtype: 'svmx.toolbar',
                  width: this.width - 30,
                  id: 'toolbarHeader'+ sectionIndex,
                  items: [
                      {
                          xtype: "svmx.label",
                          text: $TR.ATTRIBUTES,
                          width: "50%"
                      },
                      {
                          xtype: "svmx.label",
                          text: $TR.SETTING,
                          width: "50%"
                      },
                  ] 
              };
              var panel = {
                xtype: "svmx.section",
                id: 'sectionPanel' + sectionIndex,
                cls: 'svmx-ta-section-container',
                width: '100%',
                collapsible:false,
                layout:'auto',
                items: [header, fieldSet],
                title: sectionTitle,
              }
              return panel;
            },

            createFieldItem: function(attribute, sectionIndex, rowIndex, disableAllItems, isHistory) {
              var me = this;
              var format = attribute.format;
              var ro,defaultValue,fieldItem;
              var readOnly = attribute.readOnly;
              if(readOnly && (readOnly.toLowerCase() == 'yes' || readOnly.toLowerCase() == 'true' || readOnly == '1')){
                  ro = true;
              }else{
                  ro = false;
              }
              if (disableAllItems) {
                ro = true;
              }
              defaultValue = attribute.defaultValue;
              var labelText = this.getDisplayText(attribute);
              if(format && format.toLowerCase() == "number"){
                fieldItem = {
                    xtype: 'svmx.number',
                    disabled  : ro,
                    hideTrigger: true,
                    fieldLabel : labelText,
                    labelWidth: "50%",
                    width: '100%',
                    cls: 'svmx-ta-form-text',
                    margin:'20 10 20 0',
                    defaultValue:defaultValue,
                    enableKeyEvents: true,
                    decimalPrecision : 3,
                    nanText: $TR.ENTER_VALID_NUMBER,
                    allowBlank : true,
                    validator:function(value){
                      if(fieldItem.allowBlank === true || !me.isValueNull(value, attribute.format)){
                        return true;
                      }
                    },
                    listeners: {
                      render: function( context) {
                        context.setValue(defaultValue);
                        me.fieldBindings.push(context);
                      },
                      blur: function(context) {
                        me.updateModifiedValue(context);
                      },
                      keypress: function(context, e) {
                        if (context.value) {
                          var value = context.value.toString();
                          if (value.length > 15) {
                            e.stopEvent();
                          }
                        }
                      }
                    }
                  }
              }else if(format && format.toLowerCase() == "boolean"){
                if (Ext.typeOf(defaultValue) === 'string') {
                  if (defaultValue.toLowerCase() === 'yes' || defaultValue.toLowerCase() === 'true' || defaultValue.toLowerCase() === '1') {
                    defaultValue = true;
                  }
                  else {
                    defaultValue = false;
                  }
                }
                fieldItem =  {
                    xtype: 'svmx.checkbox',
                    fieldLabel :labelText,
                    labelWidth: "50%",
                    width:'100%',
                    margin:'20 10 20 0',
                    disabled: ro,
                    defaultValue:defaultValue,
                    allowBlank : true,
                    validator:function(value){
                      if(fieldItem.allowBlank === true || !me.isValueNull(value, attribute.format)){
                        return true;
                      }
                    },
                    listeners:{
                      render: function( context) {
                        context.setValue(context.defaultValue);
                        me.fieldBindings.push(context);
                      },
                      change: function(context) {
                        me.updateModifiedValue(context);
                      }
                    }
                };
                
              } else if(format && format.toLowerCase() == "picklist"){
                var dataStore = null;
                var forceSelection = true;
                if(isHistory){
                  forceSelection = false;
                }
                if (this.__showCurrent) {
                  dataStore = me.picklistDataStore(attribute);
                }
                fieldItem =  {
                  xtype: 'svmx.picklist',
                  fieldLabel : labelText,
                  labelWidth: "50%",
                  width:'100%',
                  cls: 'svmx-ta-form-picklist',
                  margin:'20 10 20 0',
                  store: dataStore,
                  queryMode: 'local',
                  displayField: 'value',
                  valueField: 'value',
                  disabled: ro,
                  forceSelection: forceSelection,
                  allowBlank : true,
                  caseSensitive : false,
                  defaultValue:defaultValue===''?this.noneStr:defaultValue,
                  validator:function(value){
                    if(fieldItem.allowBlank === true || !me.isValueNull(value, attribute.format)){
                      return true;
                    }
                  },
                  listeners:{
                    render: function( context) {
                      context.setValue(context.defaultValue);
                      me.fieldBindings.push(context);
                    },
                    change: function(context, newValue, OldValue, event) {
                      me.updateModifiedValue(context);
                      if(newValue === '' || newValue === null || newValue === undefined){
                        context.setValue('');
                      }
                    }
                  },
                  listConfig: {
                    matchFieldWidth: true,
                    getInnerTpl: function(displayField) {
                      return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                      }
                    }                       
                };
              } else {
                  fieldItem = {
                    xtype: "svmx.text",
                    fieldLabel: labelText,
                    labelWidth: "50%",
                    width: '100%',
                    cls: 'svmx-ta-form-text',
                    margin:'20 10 20 0',
                    disabled  : ro,
                    defaultValue:defaultValue,
                    allowBlank : true,
                    validator:function(value){
                      if(fieldItem.allowBlank === true || !me.isValueNull(value, attribute.format)){
                        return true;
                      }
                    },
                    listeners : {
                      render: function(context) {
                        context.setValue(context.defaultValue);
                        me.fieldBindings.push(context);
                      },
                      blur: function(context) {
                        me.updateModifiedValue(context);
                      },
                    }
                  }
              }

              if(attribute.req && attribute.req === '1'){
                fieldItem.labelSeparator = '<span style="color: rgb(255, 0, 0); padding-left: 2px;">*</span>';
                fieldItem.allowBlank = false;
              }
              if (fieldItem) {
                fieldItem.rowIndex = rowIndex;
                fieldItem.sectionIndex = sectionIndex;
                return fieldItem;
              }
            },

            isValueNull: function(value, dataType){
              let isBlank = false;
              if((dataType.toLowerCase() === "picklist" && value === "--None--") || (value==='' && value===null && value===undefined)){
                isBlank = true;
              }
              return isBlank;
            },

            getDisplayText: function(attribute) {
              //SFD-2407 :  StartsWith is a ES6 method, adding Polyfill
              if (!String.prototype.startsWith) {
                Object.defineProperty(String.prototype, 'startsWith', {
                    value: function(search, rawPos) {
                        var pos = rawPos > 0 ? rawPos|0 : 0;
                        return this.substring(pos, pos + search.length) === search;
                    }
                });
              }
              //SFD-2407 : EndsWith is a ES6 method, adding Polyfill
              if (!String.prototype.endsWith) {
                String.prototype.endsWith = function(search, this_len) {
                  if (this_len === undefined || this_len > this.length) {
                    this_len = this.length;
                  }
                  return this.substring(this_len - search.length, this_len) === search;
                };
              }
              var label = attribute.label;
              var unit = attribute.unit;
              if (unit) {//trim extra spaces
                unit = Ext.String.trim(unit);
              }
              if (unit && unit.startsWith('(')) {//cut if unit has '(' and ')'
                unit = unit.replace('(','');
              }
              if (unit && unit.endsWith(')')) {
                unit = unit.replace(/.$/,'');
              }
              var returnText = label;
              if (unit && unit!=='') {
                returnText += ' (' + unit + ')';
              }
              return returnText;
            },

            picklistDataStore: function(attribute) {
              var picklistId = attribute.picklistId;
              var dataStoreValues = [];
              if (picklistId) {
                var attributesTemplateInstance = this.template.attributesTemplateInstance;
                var attributesPayload = attributesTemplateInstance.attributesPayload;
                var attributesPayloadObj = JSON.parse(attributesPayload);
                var picklist = attributesPayloadObj.picklist;
                var picklistValues = picklist[picklistId];
                if (picklistValues) {
                  var hasDefaultValue = picklistValues.setDefaultValue;
                  var valuesArr = picklistValues.values;
                  var noneObj = {"value":this.noneStr};
                  dataStoreValues.push(noneObj);
                  for (var i = 0; i < valuesArr.length; i++) {
                    var obj = {};
                    obj["value"] = valuesArr[i];
                    dataStoreValues.push(obj);
                  }
                }
              }

              var dataStore = Ext.create(uiComposites.name+'.SVMXStore',{
                fields:['value'],
                data:dataStoreValues
              });
              return dataStore;
            },

            updateModifiedValue: function(context) {
              if (!this.__showCurrent) return;
              var attributesPayload = this.__payloadJson;
              if (attributesPayload) {
                var value;
                if(context.xtype === "svmx.checkbox"){
                  if (context.getValue()) {
                   value = true;
                  }else{
                    value = false;
                  }
                } else if(context.xtype === "svmx.picklist"){
                  value = context.getValue();
                  if (value === this.noneStr) {
                    value = '';
                  }
                } else{
                  value = context.getValue();
                }
                var fields = attributesPayload.fields;
                var selectedSection = fields[context.sectionIndex];
                var selectedField = selectedSection.technicalAttributes[context.rowIndex];
                selectedField.defaultValue = value;
              }
            },

            saveTA: function() {
              var me = this;
              var errorlbl = Ext.getCmp('errorlbl');
              const error = this.excuteValidation();
              if(error){
                errorlbl.setText($TR.REQ_ERRO || 'Please enter all mandatory fields');
                return;
              }
              errorlbl.setText(' ');
              setTimeout(function(){
                var attributesPayload = me.__payloadJson;
                if (attributesPayload) {
                  me.blockUI();
                  var payloadJson = JSON.stringify(attributesPayload);
                  var attributeInstance = me.template.attributesTemplateInstance;
                  attributeInstance.attributesPayload = payloadJson;
                  var instanceJson = JSON.stringify(me.template);
                  var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                                  "TECHNICALATTRIBUTE.SAVE_TA", me,
                                  {
                                    request : 
                                      { 
                                        context : me,
                                        instanceObject:instanceJson
                                      }
                                  });
                  SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
                }
              },10);
            },

            excuteValidation: function(){
              let isError = false;
               for(let fieldIndex = 0; this.fieldBindings.length > fieldIndex; fieldIndex++){
                  if(!this.fieldBindings[fieldIndex].isValid()){
                    isError = true;
                  };
               }
              return isError;
            },

            onSaveComplete: function(data) {
              this.unblockUI();
              if (data.success == undefined) {
                window.close();
              } else {
                Ext.Msg.alert('Error','Saving Failed');
              }
            },

            blockUI : function(){
              if (this.__spinner) {
                this.__spinner.spin($("#" + SVMX.getDisplayRootId())[0]);
              }
              else {
                var opts = {
                  lines: 25, // The number of lines to draw
                  length: 25, // The length of each line
                  width: 5, // The line thickness
                  radius: 30, // The radius of the inner circle
                  corners: 1, // Corner roundness (0..1)
                  rotate: 0, // The rotation offset
                  direction: 1, // 1: clockwise, -1: counterclockwise
                  color: '#ffa384', // #rgb or #rrggbb or array of colors
                  speed: 3, // Rounds per second
                  trail: 60, // Afterglow percentage
                  shadow: false, // Whether to render a shadow
                  hwaccel: false, // Whether to use hardware acceleration
                  className: 'spinner', // The CSS class to assign to the spinner
                  zIndex: 2e9 // The z-index (defaults to 2000000000)
                };
                this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
              }
            },
            
            unblockUI : function(){
              this.__spinner.stop();
            },

        });
        Ext.define("com.servicemax.client.technicalattributes.root.SVMXFieldSets", {
          extend: "Ext.form.FieldSet",
          alias: 'widget.svmx.fieldset',

          constructor: function(config) {
              this.callParent([config]);
          }
        });
    }
})();

