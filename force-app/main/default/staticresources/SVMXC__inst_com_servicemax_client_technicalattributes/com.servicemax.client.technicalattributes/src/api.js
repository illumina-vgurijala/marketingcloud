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
