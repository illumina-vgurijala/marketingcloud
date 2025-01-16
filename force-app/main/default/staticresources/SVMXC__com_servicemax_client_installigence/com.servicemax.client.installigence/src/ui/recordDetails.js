/**
 *
 */

(function(){

    var documentsImpl = SVMX.Package("com.servicemax.client.installigence.recordDetails");

documentsImpl.init = function(){

    Ext.define("com.servicemax.client.installigence.recordDetails.RecordDetails", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.recordDetails',
         __selectedNode :null,
         __taTemplate: null,
         constructor: function(config) {

            var me = this;
            me.title =  $TR.__getValueFromTag($TR.PRODIQ001_TAG142,'Details');
            __taTemplate = {};
            config = config || {};
            this.callParent([config]);

        },
        __findTemplate: function(node){

           // SVMX.getCurrentApplication().blockUI();

          if (this.__selectedNode === null || this.__selectedNode.id !== node.id) {

              this.__selectedNode = node;

              var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                      "INSTALLIGENCE.FIND_TA_TEMPLATE_FOR_SELECTD_IB", this, {request : {
                          context : this, selectedIB:node
                      }});
              com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);

          }

        },
        __findTemplateComplete: function(data){


         if(data.IbAttributesHistory === undefined && data.IbAttributesTemplateInstance === undefined) {
              this.__saveDataIntoAttributeInstance(data);
         }
         this.__refreshPage(data);
          //SVMX.getCurrentApplication().unblockUI();

        },



      __saveDataIntoAttributeInstance : function(data) {

            if (data.length > 0) {

                var templeteData = data[0];
                var now = new Date();
                now.setHours(0,0,0,0);
                var currentDate = Ext.Date.format(now, "Y-m-d");
                templeteData.LastModifiedDate = currentDate;

                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "INSTALLIGENCE.SAVE_TA_TEMPLATE_INSTANCE_FOR_SELECTD_IB", this, {request : {
                            context : this, handler : this.onSaveComplete, data : templeteData, selectedIBNode : this.__selectedNode
                        }});
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);

            }

      },

      onSaveComplete : function(data) {

          if (data.IBAttributeInstanceId !== undefined && data.IBAttributeHistroryId !== undefined) {
                this.__taTemplate.IBAttributeInstanceId = data.IBAttributeInstanceId;
                this.__taTemplate.IBAttributeHistroryId = data.IBAttributeHistroryId;
          }
        },

      __updateTemplateData : function (field) {


              if (field.originalValue !== field.value) {
                  var keyForJSONPayLoad = SVMX.OrgNamespace+'__SM_Template_Json__c';
                  if (this.__taTemplate[keyForJSONPayLoad] === undefined) {
                    keyForJSONPayLoad = SVMX.OrgNamespace+'__SM_Attr_Payload__c';
                  }
                  var templateJson = JSON.parse(this.__taTemplate[keyForJSONPayLoad]);
                  var fields = templateJson.fields;
                  var selectedSection = fields[field.sectionIndex];
                  var selectedField = selectedSection.technicalAttributes[field.rowIndex];
                  selectedField.defaultValue = field.value;
                  var payLoadJSONString = JSON.stringify(templateJson);
                  this.__taTemplate[keyForJSONPayLoad] = payLoadJSONString;

                  var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                          "INSTALLIGENCE.UPDATE_TA_TEMPLATE_FOR_SELECTD_IB", this, {request : {
                              context : this, handler : this.onUpdateComplete, data : this.__taTemplate, selectedIBNode : this.__selectedNode
                          }});
                  com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);

              }


        },

        onUpdateComplete : function(data) {
          /*If last mode date is different thatn current date then we are making new entry in the
            histrory table. So we need to update the template now.
          */
          if (data.IBAttributeHistroryId !== undefined) {
                this.__taTemplate.IBAttributeHistroryId = data.IBAttributeHistroryId;
                var now = new Date();
                now.setHours(0,0,0,0);
                var currentDate = Ext.Date.format(now, "Y-m-d");
                this.__taTemplate.LastModifiedDate = currentDate;
          }

        },
        __refreshPage: function(data){

            var me = this;
            this.removeAll();

            if(data.length >0 || (data.IbAttributesHistory !== undefined && data.IbAttributesTemplateInstance !== undefined)){

              if(data.IbAttributesHistory === undefined && data.IbAttributesTemplateInstance === undefined) {
                  this.__taTemplate = data[0];
              }
              else {
                  var instanceDataArray = data.IbAttributesTemplateInstance;
                  var historyDataArray = data.IbAttributesHistory;

                  if (instanceDataArray.length > 0) {
                      var instanceData = instanceDataArray[0];
                      this.__taTemplate = instanceData;
                      this.__taTemplate.IBAttributeInstanceId = instanceData.Id;
                  }

                  if (historyDataArray.length > 0) {
                      var historyData = historyDataArray[0];
                      this.__taTemplate.IBAttributeHistroryId = historyData.Id;
                  }
              }

                me.topToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
                    style: 'border-width: 0',
                    width: '100%'
                });

                me.dateLabel = {
                    xtype: 'label',
                    forId: 'myFieldId',
                    text: com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(this.__taTemplate.LastModifiedDate,'LL'),
                    margin:'20 0 10 10',


                };
                me.topToolbar.add(me.dateLabel);
                me.topToolbar.add('->');
                me.topToolbar.add({
                                    xtype: 'button',
                                    cls: 'priq-button-disabled',
                                    text: $TR.__getValueFromTag($TR.PRODIQ001_TAG145,'Current'),
									                  disabled: true,
                                    handler : function(){
                                      //can be used to assign/remove enable /disabled class
                                    }
                                });
                me.topToolbar.add({
                                  cls: 'priq-vline-separator',
                                  text: ['|']
                                });
                 me.topToolbar.add({
                                    xtype: 'button',
                                    cls: 'priq-button-disabled',
                                    disabled: true,
                                    text: $TR.__getValueFromTag($TR.PRODIQ001_TAG146,'Previous'),
                                    handler : function(){

                                    }
                                });


                  me.bottomToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
                    style: 'border-width: 0',
                    width: '100%'
                });
                me.bottomToolbar.add('->');
                me.bottomToolbar.add({
                                    xtype: 'button',
                                    text: "",
                                    handler : function(){

                                    }
                                });

                    var allSectionsPanel = this.__getLayoutForAllSections();
                    this.add(me.topToolbar);
                    this.add(allSectionsPanel);
                    this.add(me.bottomToolbar);

            }else{

                var noTemplateFoundToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
                    style: 'border-width: 0',
                    width: '100%'
                });

                var noTemplateFoundLabel = {
                    xtype: 'label',
                    forId: 'myFieldId',
                    text: $TR.__getValueFromTag($TR.PRODIQ001_TAG147,'No technical attributes associated with this installed product.'),
                    margin:'20 0 10 10',


                };
                noTemplateFoundToolbar.add(noTemplateFoundLabel);
                this.add(noTemplateFoundToolbar);

            }
        },
        __getLayoutForAllSections: function(){

            var keyForJSONPayLoad = SVMX.OrgNamespace+'__SM_Template_Json__c';
            if (this.__taTemplate[keyForJSONPayLoad] === undefined) {
              keyForJSONPayLoad = SVMX.OrgNamespace+'__SM_Attr_Payload__c';
            }
            var templateJson = JSON.parse(this.__taTemplate[keyForJSONPayLoad]);
            var fields = templateJson.fields;
            var l = fields.length;

            var allSectionPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXPanel',{
                    autoScroll:true, layout: 'fit', cls:'svmx-priq-detail'
                });

           for(var i=0; i<l; i++){

             var section = SVMX.create('com.servicemax.client.installigence.recordDetails.SectionPanel',{
                       sectionDetails:fields[i], sectionIndex : i, parent : this, scrollable: false, autoScroll: false, cls: 'svmx-priq-detail-body'
                  });
             section.__layout();
             allSectionPanel.items.add(section);
           }
            return allSectionPanel;
        }
    });


// SectionPanel class start.
        Ext.define("com.servicemax.client.installigence.recordDetails.SectionPanel", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            alias: 'widget.installigence.sectionPanel',
            __sectionDetails: null,
            __sectionIndex : null,
            __parent : null,
            constructor: function(config) {
                var me = this;
                config = config || {};
                this.__sectionDetails = config.sectionDetails;
                this.__sectionIndex = config.sectionIndex;
                this.__parent = config.parent;
                this.callParent([config]);
             },
             __layout: function(){

                var me = this;
                var sectionTitle       = this.__sectionDetails.title;
                var sectionDescription = this.__sectionDetails.description;
                var attributes         = this.__sectionDetails.technicalAttributes;

                var attributesElems = [], attributesElem;
                var l = attributes.length;
                var attri, name, type, format,cls, ro, ronly='', defaultValue;
                for(var i=0; i<l; i++){
                    attri  = attributes[i];
                    format = attri.format;

                    if(attri.readOnly == 'YES'){
                        ro = false;
                        ronly = '-read-only';
                    }else{
                        ro = true;
                    }
                    defaultValue = attri.defaultValue;
                    if(format.toLowerCase() == "text"){

                        attributesElem = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
                           allowBlank : true,
                           editable : ro,
                           margin:'10, 30',
                           width:'70%',
                           cls: 'svmx-overview-attr-item' + ronly,
                           labelStyle: 'color: #0070D2; width:250px; white-space: nowrap; font-size: 16px;',
                           fieldLabel : attri.label + ' ('+attri.unit+')',
                           value:defaultValue,
                           labelSeparator : "",
                           enableKeyEvents : true,
                           listeners : {

                              blur : function(context, event, eOpts) {
                                me.__parent.__updateTemplateData(context);
                              }
                           }

                       });


                    }else if(format.toLowerCase() == "number"){

                       /* attributesElem = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
                           allowBlank : true,
                           editable : ro,
                           margin:'10, 30',
                           width:'70%',
                           labelStyle: 'color: #0070D2; width:250px; white-space: nowrap; font-size: 16px;',
                           fieldLabel : attri.label + ' ('+attri.unit+')',
                           value:defaultValue,
                           labelSeparator : "",
                           enableKeyEvents : true,
                           maskRe: /[0-9]/,
                           listeners : {

                              blur : function(context, event, eOpts) {
                                me.__parent.__updateTemplateData(context);
                              }
                           }
                       });*/
                        attributesElem = {
                                        xtype: 'numberfield',
                                        editable : ro,
                                        margin:'10, 30',
                                        width:'70%',
                                        labelStyle: 'color: #0070D2; width:250px; white-space: nowrap; font-size: 16px;',
                                        fieldLabel : attri.label + ' ('+attri.unit+')',
                                        value:defaultValue,
                                        labelSeparator : "",
                                        hideTrigger: true,
                                        keyNavEnabled: false,
                                        mouseWheelEnabled: false,
                                        cls: 'svmx-overview-attr-item' + ronly,
                                        listeners: {
                                            blur : function(context, event, eOpts) {
                                                me.__parent.__updateTemplateData(context);
                                              }
                                          }
                                      }


                    }else if(format.toLowerCase() == "boolean"){
                        attributesElem = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                                fieldLabel : attri.label,
                                margin:'10, 30',
                                readOnly : !ro,
                                scope: this,
								checked:defaultValue,
                                cls: 'priq-checkbox-label' + ronly,
                                handler : function(field, value){
                                  me.__parent.__updateTemplateData(field);
                                }
                            });
                    }else if(format.toLowerCase() == "picklist"){

                    }
                    /* line separator */
                    var lineSeparator = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                            cls: 'svmx-priq-line-separator',
                            items: [{
                                  text: ['<hr></hr>']
                              }]
                        });
                    attributesElem.rowIndex = i;
                    attributesElem.sectionIndex = this.sectionIndex;
                    attributesElems.push(attributesElem);
                    attributesElems.push(lineSeparator);
                }

                var sectionTitleToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar',{
                    style: 'border-width: 0',
                    width: '100%',
                    cls: 'svmx-priq-overview-section-title-toolbar',
                    items:[ {
                                xtype: 'label',
                                margin: '10 5 5 20',
                                text: sectionTitle
                            }]
                });

                var attrSettingPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                        cls: 'svmx-priq-overview-attr-setting',
                        items: [{
                              xtype: 'label',
                              forId: 'myFieldId',
                              text: $TR.__getValueFromTag($TR.PRODIQ001_TAG148,'Attributes'),
                              margin: '0 0 0 30'
                          },{
                              xtype: 'label',
                              forId: 'myFieldId',
                              text: $TR.__getValueFromTag($TR.PRODIQ001_TAG149,'Setting'),
                              margin: '0 0 0 180'
                          }]
                    });
                /* line separator */
                var lineSeparator = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                        cls: 'svmx-priq-line-separator',
                        items: [{
                              text: ['<hr></hr>']
                          }]
                    });
                /* line separator */
                var titleLineSeparator = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                        cls: 'svmx-priq-title-line-separator',
                        items: [{
                              text: ['<hr></hr>']
                          }]
                    });
            this.add(sectionTitleToolbar);
            this.add(titleLineSeparator);
            this.add(attrSettingPanel);
            this.add(lineSeparator);
            this.add(attributesElems);
        }
         });
// SectionPanel class end.
};

})();

// end of file
