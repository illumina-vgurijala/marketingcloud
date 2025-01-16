/**
 * ServiceMax UIControl/Component Library for IBTree.
 * @class com.servicemax.client.installedbasetree.api
 */
(function(){
    var appImpl = SVMX.Package("com.servicemax.client.installedbasetree.api");
appImpl.init = function(){

    appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
        __constructor : function(){

        },

        beforeRun: function (options) {
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
             
            this.__eventBus = SVMX.create("com.servicemax.client.installedbasetree.impl.EventBus", {});
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
            this.__objName = SVMX.getUrlParameter('objName');
            this.getMetaData();
        },

        getMetaData: function() {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "IBTREE.GET_META_DATA", this,
                            {
                                request : { 
                                    context : this,
                                    objName: this.__objName
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetMetaDataComplete: function(metaData) {
            
            var translations = {};
            for (var arrayTran in metaData.translations){
                    translations[arrayTran] = Ext.String.htmlEncode(metaData.translations[arrayTran])
            }
            window.$TR = translations;
            if (!this.__recordId) {
                alert($TR.PARAMS_ERROR);
            } else {
                this.__metaData = metaData;
                this.getTreeData();
            }
        },

        getTreeData: function() {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "IBTREE.GET_TREE_DATA", this,
                            {
                                request : { 
                                    context : this,
                                    recordId: this.__recordId,
                                    objName:this.__objName,
                                    reload: false,
                                }
                            });
            SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
        },

        onGetTreeDataComplete: function(treeData) {
            SVMX.create('com.servicemax.client.installedbasetree.root.RootPanel',{
                collapsible : false,
                titleAlign: 'center', 
                frame: 'true',
                treeData: treeData,
                metaData: this.__metaData,
                recordId: this.__recordId,
                objName:this.__objName
            });
        },

        
    });
}

})();
