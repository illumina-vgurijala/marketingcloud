// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\app.js

(function(){
	    var appImpl = SVMX.Package("com.servicemax.client.installigence.app");
	    
    appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{
        __rootContainer : null,
        __rootModel : null, __spinner : null, __pendingMessage : null,
        __insertRecordSyncParams : null,
        __ObjectInfo : null,
        __constructor : function(){
        		
        },
        
        __onAppLaunched: function(evt) {
            var me = this;


            /*
                Commenting below code for LUMA since we are passing the data while we create the
                PIQ window.
            */
            
            /*
            // var nativeService = com.servicemax.client.installigence.offline.sal.model.nativeservice.Facade;
            var nativeService = me.getParentWindowNativeServiceFacade();
            var req = nativeService.createSetExternalHandlerRequest();
            req.bind("REQUEST_COMPLETED", function(evt) {
                
            });
            req.bind("REQUEST_ERROR", function(evt) {
                
            });
            req.execute({
                handler: "window.externalRequestHandler",
            });  

                     
            
            window.externalRequestHandler = function(data) {
            	SVMX.getCurrentApplication().setPendingMessage(data);
            	var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
            	SVMX.getClient().triggerEvent(evt);            	
            };
            */

            //Now read the PIQ external data from PIQ window.
            var piqContainer = window.parent.Ext.ComponentQuery.query('#productIQSheetAsWindow')[0];
            if (piqContainer) {
                if (piqContainer.message) {
                        var data = SVMX.toObject(piqContainer.message);
                        SVMX.getCurrentApplication().setPendingMessage(data);
                        SVMX.getCurrentApplication().setObjectInfo(data);
                        var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
                        SVMX.getClient().triggerEvent(evt); 
                }
            }
        },

        /*
            Method Description :
            Below method is used to get the native service of parent window i.e LUMA Services.
        */

        getNativeServiceRequest : function() {
            if(window.parent.SVMX.getClient().getApplicationParameter("client-type").toLowerCase() == "laptop") {
                return window.parent.com.servicemax.client.offline.sal.model.nativeservice.Facade;
            } else {
                return com.servicemax.client.installigence.offline.sal.model.nativeservice.Facade;
            }
        },
        
        setPendingMessage: function(message){
        	this.__pendingMessage = message;
        },
        
        getPendingMessage: function(){
        	return this.__pendingMessage;
        },
        setObjectInfo: function(message){
        	this.__ObjectInfo = {};
        	this.__ObjectInfo.object = message.object;
        	this.__ObjectInfo.objectId = message.recordID;
        },
        
        getObjectInfo: function(){
        	return this.__ObjectInfo;
        },
        
        emptyPendingMessage: function(){
        	this.__pendingMessage = null;
        },
        
        run : function(){
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
            
            var me = this; 
            
            // create the named default controller
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){

                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);
                    this.runInternal();
                }, context : this});

            }, context : this, additionalParams : { eventBus : com.servicemax.client.installigence.impl.EventBus.getInstance() }});
        },
        
        runInternal : function(){
        	
        	this.__onAppLaunched();
            // register for sync events
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.bind("SYNC.STATUS", function(evt){
                var status = evt.data.type;
                var message = evt.data.msg;
                var syncType = evt.data.syncType;
                SVMX.getLoggingService().getLogger().info("SYNC.STATUS: " + status + " " + message);
                
                if(status === "start" && 
                    (syncType === "initial" || syncType === "reset" || syncType === "ib")){
                    this.__handleSyncSetupStarted(evt.data);
                }else if(status === "canceled"){
                    this.__handleSyncCanceled(evt.data);
                }else if(status === "complete"){
                    this.__insertRecordSyncParams = evt.data;
                    this.__handleSyncCompleted(evt.data);
                    if(syncType === "incremental" || syncType === "insert_local_records"){
                        this.__checkSyncConflicts();
                    }
                }
            }, this);
            // end sync events

            // setup translation
            this.blockUI();
            var me = this;

            var translationService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.translation").getInstance();
            translationService.refresh().done(function(){
                // setup the global $TR           	
                window.$TR = translationService;
                me.unblockUI();
                me.setup();
            });
        },
        
        __clearLocks : function(params){
        	var updatedRecs = params.state ? params.state.updated : undefined;
        	if(updatedRecs) {
        		
        		var recordIds = [];
        		for(var obj in updatedRecs){
        			if(updatedRecs[obj]){
        				recordIds = recordIds.concat(updatedRecs[obj]);
        			}
        		}        		
        		var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "INSTALLIGENCE.EXECUTE_API", this, {request : {context : this, recordIds: recordIds, method: "CLEARLOCKS"}});
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        	}        	 
        },

        __checkSyncConflicts : function(){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_SYNC_CONFLICTS", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onGetSyncConflictsComplete : function(result){
            if(result && result.length){
                this.__rootContainer.showSyncConflicts();
            }

            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance();
            if(syncService && syncService.__currentSyncType && syncService.__currentSyncType === "insert_local_records"){
                if(result && result.length){
                    var params = {};
                    params.syncType = "INSERT_LOCAL_RECORDS";
                    params.result  = result;
                    this.__handleInsertRecSyncCompleted(params);
                }else{
                    this.__handleInsertRecSyncCompleted(this.__insertRecordSyncParams);
                }
            }
        },
        
        __handleInsertRecSyncCompleted : function(params){
            if(params && params.state){
                var insertRecordsMap = {};
                this.hideDataLoading();
                if(params.state.insertRecordsMap && params.state.insertRecordsMap.length){
                    for(var i=0; i< params.state.insertRecordsMap.length ; i++){
                        insertRecordsMap[params.state.insertRecordsMap[i].localId] = params.state.insertRecordsMap[i].remoteId;
                    }
                }    
                var response = {
                    action : 'SYNC',
                    operation: params.syncType.toUpperCase(),
                    type: 'RESPONSE',
                    data: { insertRecordsMap: insertRecordsMap}};

                this.getRootContainer().invokeLMWithResponse(response);

                this.__insertRecordSyncParams = null;
            }else if(params && params.result){
                var response = {
                    action : 'SYNC',
                    operation: params.syncType.toUpperCase(),
                    type: 'RESPONSE',
                    data: { error : {type : "SYNC_FAILED", message : params.result[0].Message}}};

                this.getRootContainer().invokeLMWithResponse(response);
            }
        },
        
        __handleSyncCompleted : function(params){
			//Send Response to MFL
            /*if(params && params.state){
                var insertRecordsMap = {};
                this.hideDataLoading();
                if(params.state.insertRecordsMap && params.state.insertRecordsMap.length){
                	for(var i=0; i< params.state.insertRecordsMap.length ; i++){
                        insertRecordsMap[params.state.insertRecordsMap[i].localId] = params.state.insertRecordsMap[i].remoteId;
                    }
                }    
                var response = {
                    action : 'SYNC',
                    operation: params.syncType.toUpperCase(),
                    type: 'RESPONSE',
                    data: { insertRecordsMap: insertRecordsMap}};

                this.getRootContainer().invokeLMWithResponse(response);
            }*/

            if(params.syncType === "incremental"){// || params.syncType === "purge"
                this.hideDataLoading();
                this.__clearLocks(params);
            }else{
                this.unblockUI();
                this.__rootContainer.handleHome({
                    type : "sync_complete",
                    params : params
                });
            }
            
            //clear locks
        },

        __handleSyncCanceled : function(params){
            this.__handleSyncCompleted(params);
        },
        
        __handleSyncSetupStarted : function(params){
            this.__rootContainer.handleProgress(params);
        },
        
        blockUI : function(){
            this.__blockCounter = this.__blockCounter || 0;
            this.__blockCounter++;
            if(this.__spinner){
                // Already blocked
                return;
            }
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
            var rootElement = $("#spincenter")[0];
            if(!rootElement){
                $('body').append(
                    '<div id="spincenter" style="position:fixed;top:50%;left:50%;z-index:999999"></div>'
                );
                rootElement = $("#spincenter")[0];
            }
            this.__spinner = new Spinner(opts).spin(rootElement);
        },
        
        unblockUI : function(){
            this.__blockCounter--;
            if(this.__blockCounter > 0){
                return;
            } else {
                this.__blockCounter = 0;
            }
            if(!this.__spinner){
                return;
            }
            var rootElement = $("#" + SVMX.getDisplayRootId())[0];
            rootElement.style.height = 'auto';
            this.__spinner.stop();
            delete this.__spinner;
        },

        showDataLoading : function(){
            var opts = {
                lines: 13, // The number of lines to draw
                length: 6, // The length of each line
                width: 3, // The line thickness
                radius: 7, // The radius of the inner circle
                corners: 1, // Corner roundness (0..1)
                rotate: 0, // The rotation offset
                direction: 1, // 1: clockwise, -1: counterclockwise
                color: '#ffffff', // #rgb or #rrggbb or array of colors
                speed: 3, // Rounds per second
                trail: 60, // Afterglow percentage
                shadow: false, // Whether to render a shadow
                hwaccel: false, // Whether to use hardware acceleration
                className: 'spinner', // The CSS class to assign to the spinner
                zIndex: 2e9 // The z-index (defaults to 2000000000)
            }; 
            $(".logo.img").hide();
            $(".logo.spinner").show();
            this.__dataSpinner = new Spinner(opts).spin($(".logo.spinner")[0]);
        },

        hideDataLoading : function(){
            $(".logo.img").show();
            $(".logo.spinner").hide();
            if(this.__dataSpinner){
                this.__dataSpinner.stop();
            }
        },

        showQuickMessage : function(type, message, options, callback){
            if(message !== undefined && message.length > 0){
                message += '<br><br>'
            }
            type = type.toLowerCase();
            if(typeof options === 'function'){
                callback = options;
                options = {};
            }
            if(type === "confirm"){
                typeMessage = $TR.__getValueFromTag($TR.MESSAGE_CONFIRM,'Confirm');
                //Ext.Msg.confirm(typeMessage, message, callback);
                //Ext.MessageBox.confirm(typeMessage, message, callback);
                 //  var msgBox = Ext.create('Ext.window.MessageBox',{draggable: false});
            //    msgBox.confirm(typeMessage, message, callback);
               com.servicemax.client.installigence.ui.components.utils.Utils
            .confirm({title : 'Confirm', message : message,handler:callback });
            }else{
                switch(type){
                    case "success":
                        typeMessage = $TR.__getValueFromTag($TR.MESSAGE_SUCCESS,'Success');
                        break;
                    case "error":
                        typeMessage = $TR.__getValueFromTag($TR.MESSAGE_ERROR,'Error');
                        break;
                    case "info":
                    // TODO: add more types as needed
                    default:
                        typeMessage = $TR.__getValueFromTag($TR.MESSAGE_INFO,'Info');
                        break;
                }
                //Ext.Msg.alert(typeMessage, message);
                //Ext.MessageBox.alert(typeMessage, message);
                //var msgBox = Ext.create('Ext.window.MessageBox',{draggable: false,closable:false});
               // msgBox.alert(typeMessage, message);
                Ext.Msg.alert({
                title:typeMessage, message: message,
                buttonText:{ok:$TR.__getValueFromTag($TR.OK_BTN,'Ok')},
                closable:false,
                
            });
            }
        },

        /**
         * Show a connection warning. There is an intermittent connection.
         *
         */
        showConnectionWarningDialog : function(params){
            var me = this;

            Ext.Msg.buttonText.ok = $TR.__getValueFromTag($TR.CONTINUE_BTN,'Continue');
            Ext.Msg.buttonText.cancel = $TR.__getValueFromTag($TR.CANCEL,'Cancel');

            $("#spincenter").hide();
            Ext.Msg.show({
                title : $TR.__getValueFromTag($TR.CONNECTION_WARNING_TITLE,'Connection Warning'),
                msg : $TR.__getValueFromTag($TR.CONNECTION_WARNING_MSG,'Poor connectivity detected. Please continue when internet connectivity has improved.')+"<br><br>",
                buttons : Ext.Msg.OKCANCEL,
                fn : SVMX.proxy(
                    me,
                    function(buttonId) {
                        $("#spincenter").show();
                        if(buttonId === "ok"){
                            params.onRetry && params.onRetry();
                        }else{
                            params.onCancel && params.onCancel();
                        }
                    }
                )
            });

            // Reset button text
            Ext.Msg.buttonText.ok = $TR.__getValueFromTag($TR.OK_BTN,'Ok');
        },

        /**
         * Show a connection failure notification. Sync was not able to connect to network.
         *
         */
        showConnectionErrorDialog : function(params){
            var me = this;

            Ext.Msg.buttonText.ok = $TR.__getValueFromTag($TR.SYNC_CONFLICT_RETRY_BTN,'Retry');
            Ext.Msg.buttonText.cancel = $TR.__getValueFromTag($TR.CANCEL,'Cancel');

            $("#spincenter").hide();
            this.__connectionMsg = Ext.Msg.show({
                title : $TR.__getValueFromTag($TR.CONNECTION_ERROR_TITLE,'Connection Error'),
                msg : $TR.__getValueFromTag($TR.CONNECTION_ERROR_MSG,'Internet connectivity lost. Please retry when connectivity is available')+"<br><br>",
                buttons : Ext.Msg.OKCANCEL,
                fn : SVMX.proxy(
                    me,
                    function(buttonId) {
                        $("#spincenter").show();
                        if(buttonId === "ok"){
                            params.onRetry && params.onRetry();
                        }else{
                            params.onCancel && params.onCancel();
                        }
                    }
                )
            });

            // Reset button text
            Ext.Msg.buttonText.ok = $TR.__getValueFromTag($TR.OK_BTN,'Ok');
        },

        /**
         * Show a request failure notification. Server returned an error repeatedly.
         *
         */
        showRequestErrorDialog : function(params){
            var me = this;
			var message;
            if(params.errorMessage){
                message = params.errorMessage;
            }else{
                message = $TR.__getValueFromTag($TR.SERVER_ERROR_MSG,'The server is unable to complete your request')+"<br><br>";
            }
            Ext.Msg.buttonText.ok = SYNC_CONFLICT_RETRY_BTN;
            Ext.Msg.buttonText.cancel = $TR.__getValueFromTag($TR.CANCEL,'Cancel');

            $("#spincenter").hide();
            this.__connectionMsg = Ext.Msg.show({
                title : $TR.__getValueFromTag($TR.SERVER_ERROR_TITLE,'Server Error'),
                msg : message,
                buttons : Ext.Msg.OKCANCEL,
                fn : SVMX.proxy(
                    me,
                    function(buttonId) {
                        $("#spincenter").show();
                        if(buttonId === "ok"){
                            params.onRetry && params.onRetry();
                        }else{
                            params.onCancel && params.onCancel();
                        }
                    }
                )
            });

            // Reset button text
            Ext.Msg.buttonText.ok = $TR.__getValueFromTag($TR.OK_BTN,'Ok');
        },
        
        getSearchResultsLimit : function(){
            return 250; // TODO: move to configuration
        },
        
        getAppFocus : function(){
        	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_APP_FOCUS", this, {request : {}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        updateDependentRecords: function(data){
            var mapRecordIds = data.insertRecordsMap || {};
            var lstLocalRecIds = [];
            for(var localId in mapRecordIds){
                lstLocalRecIds.push(localId);
            }

            this.updateInRecordNameTable(mapRecordIds, lstLocalRecIds); 

            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("parent_object_name, local_id, parent_record_id, parent_field_name").from("SyncDependentLog")
            .where("local_id").within(lstLocalRecIds).execute()
            .done(SVMX.proxy(this, function(resp){
                if(resp && resp.length > 0){
                    var count = resp.length;
                    for(var i=0; i<resp.length; i++){
                        this.updateParentRecord(resp[i], mapRecordIds, function(){
                            count--;
                            if(!count){
                                // Call the sync.
                                this.getRootContainer().handleIncrementalSync();
                            }
                        });
                    }
                }

            }));
        },

        errorFromMFL: function(error){
            var errorType = error.type;
            var messageType;

            if(errorType === 'SYNC_PAUSED' || errorType === 'REQUEST_REJECTED')
                messageType = $TR.__getValueFromTag($TR.MESSAGE_INFO,'Info');
            else if(errorType === 'SYNC_FAILED')
                messageType = $TR.__getValueFromTag($TR.MESSAGE_ERROR,'Error');

            Ext.Msg.alert(messageType, error.message);
        },

        getRootContainer: function(){
            return this.__rootContainer;
        },

        updateParentRecord: function(record, mapRecordIds, callback){
            var updateSet = record["parent_field_name"] + " = '" + mapRecordIds[record["local_id"]] + "'";
            var tableName = record["parent_object_name"];
            var whereCondition = "Id = '" + record["parent_record_id"] + "'";
            var queryObjUpdate = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObjUpdate.update(tableName)
            .setValue(updateSet);
            queryObjUpdate.where(whereCondition).execute()
            .done(SVMX.proxy(this, function(resp){
                this.deleteDependentLogEntry(record, callback);
            }));
        },
        
        deleteDependentLogEntry: function(record, callback){
            var qo = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            qo.deleteFrom("SyncDependentLog")
            .where("parent_field_name").equals(record["parent_field_name"])
            .where("parent_record_id").equals(record["parent_record_id"])
            .execute().done(function(){
                callback.call(this);
            });
        },

        //LUMA : renaming RecordName to SFRecordName
        updateInRecordNameTable: function(mapRecordIds, lstLocalRecIds){
            var d = SVMX.Deferred();
            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("Id,Name")
            .from("SFRecordName")
            .where("Id").within(lstLocalRecIds)
            .execute()
            .done(SVMX.proxy(this, function(resp){
                if(resp && resp.length > 0){
                    var count = resp.length;
                    for(var i=0; i<resp.length; i++){
                        this.updateRecordNameEntry(resp[i], mapRecordIds, function(){
                            count--;
                            if(!count){
                                // Call the sync.
                                d.resolve();
                            }
                        });
                    }
                }

            }));
            return d;
        },

        //LUMA : Renaming RecordName to SFRecordName.
        updateRecordNameEntry: function(record, mapRecordIds, callback){
            var updateSet = "Id = '" + mapRecordIds[record["Id"]] + "'";
            var whereCondition = "Id = '" + record["Id"] + "'";
            var queryObjUpdate = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObjUpdate.update("SFRecordName")
            .setValue(updateSet)
            .where(whereCondition).execute()
            .done(SVMX.proxy(this, function(resp){
                callback.call(this);
            }));
        },

        externalMessage: function(edata){
            var data = SVMX.toObject(edata);
            if(data.type === "RESPONSE") {
                if(data.operation === "INSERT_LOCAL_RECORDS" && data.data.error){
                    this.errorFromMFL(data.error);
                }

                if(data.data && data.data.insertRecordsMap){
                    this.updateDependentRecords(data.data );    
                }else if(data.action === "SYNC" && data.operation === "INCREMENTAL" && !(data.data && data.data.error)){
                    this.getRootContainer().handleIncrementalSync();
                }
            }

            if(data.action === "SYNC" && data.operation === "INSERT_LOCAL_RECORDS" && data.type === "REQUEST"){
                this.getRootContainer().handleInsertRecordsSync(data.data.recordIds);
           }
        },

        isAppEmbedded : function(){
            var isEmbedded = false;
            if(SVMX.appType === 'embedded'){
                isEmbedded = true;   
            }
            return isEmbedded;
        },
        
        setup : function(){
            this.__rootModel = SVMX.create("com.servicemax.client.installigence.metamodel.Root");
            this.__rootContainer = SVMX.create('com.servicemax.client.installigence.root.Root', { meta : this.__rootModel });
            
            SVMX.getClient().bind("EXTERNAL_MESSAGE", function(evt){
                this.externalMessage(evt.data);
            }, this);
            
            
            SVMX.onWindowResize(function(size){
                // this.__rootContainer.setHeight(size.height - 40);
                this.__rootContainer.setHeight(size.height - 2);
                this.__rootContainer.doLayout();
            }, this);
            
            var me = this;
            SVMX.doLater(function(){
                me.__rootContainer.doLayout();

                 //for integrated app sync is handled by the launchig app.
                if(me.isAppEmbedded()){
                    me.__rootContainer.handleHome({type : "initialize"});
                    me.__rootModel.initialize();
                    return;
                }

                // navigate to find and get if this is the first time
                var pendingMessage = SVMX.getCurrentApplication().getPendingMessage();
                if(pendingMessage !== null){
                	pendingMessage = SVMX.toObject(pendingMessage);                	          	
                }
                
                var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();
                
                syncService.getLastConfigSyncDetails(me)
                .done(function(){
                    syncService.hasUserChanged().done(function(result){
                        if(result){
                            me.__rootContainer.handleFindAndGet({syncType : "initial"});
                        }else if(pendingMessage !== null && pendingMessage.action === "SYNC" && pendingMessage.operation === "INCREMENTAL"){
                    		me.__rootContainer.handleIncrementalSync();
                    		SVMX.getCurrentApplication().emptyPendingMessage();
                    	}else if(pendingMessage !== null && pendingMessage.action === "SYNC" 
                    		&& pendingMessage.operation === "INSERT_LOCAL_RECORDS" && pendingMessage.type === "REQUEST"){
                            me.__rootContainer.handleInsertRecordsSync(data.data.recordIds);
                    		SVMX.getCurrentApplication().emptyPendingMessage();
                    	}else {
                            // sync is complete and user has not changed
                            me.__rootContainer.handleHome({type : "initialize"});
                            me.__rootModel.initialize();
                        }
                    });
                })
                .fail(function(){
                    me.__rootContainer.handleFindAndGet({syncType : "initial"});
                });
                // end navigate
                
            });
        }
        
    },{});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\app3.js

(function(){
	var appImpl = SVMX.Package("com.servicemax.client.installigence.app");
	
	appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{

		__constructor : function(){

		},
		
		run : function(){
		
		var svmxtreestore = Ext.create('Ext.data.TreeStore', {
			root: {
				expanded: true,
				children: [
					{ text: "PEVGEOT Piossing", expanded: true, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon1.png', checked: false, children: [
						{ text: "Electrical Room 1", checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png', expanded: true, children: [{text: 'Switch Board', checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon3.png'}] },
						{ text: "Electrical Room 2", checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png', expanded: true, children: [{text: 'MV Ring Main', checked: true, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png'}] },
						{ text: "Electrical Room 3", checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png', expanded: true, children: [{text: 'Switch Board', checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon3.png'}] },
						{ text: "Electrical Room 4", checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png', expanded: true, children: [{text: 'MV Ring Main', checked: false, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png'}] },
						{ text: "Electrical Room 5", checked: false, iconCls : 'product-icon', expanded: true, children: [{text: 'MV Ring Main', checked: false, iconCls : 'sub-location-icon',}] }
						
					] },
					{ text: "Sub Site", expanded: true, checked: false, leaf: true, icon: 'http://localhost/Installigence5/trunk/dev/js/src/modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon6.png' }
				]
			}
		});
		
		var getMenu = function (cmp) {			    				    	
			var menu = cmp.down('menu'); 
			if (!menu) {
				menu = Ext.create('Ext.menu.Menu', {
					cls: 'svmx-nav-menu',
					plain: true,
					height: '80%',
					items: [
							{text: 'Find & Get'},
							{text: 'Sync Configuration'},
							{text: 'Sync Data'},
							{text: 'Sync Status'},
							{text: 'Show Alerts'}
					]
				});
			}
			return menu;
		};
		
		
		var store = Ext.create('Ext.data.Store', {
			storeId:'simpsonsStore',
			fields:['name', 'email', 'phone'],
			data:{'items':[
				{ 'name': 'Decommision',  "type":"Field Map",  "action":"SVMX_Default_Decomm"  },
				{ 'name': 'Configurator',  "type":"External App",  "action":"Abc.exe" },
				{ 'name': 'Decommision',  "type":"Field Map",  "action":"SVMX_Default_Decomm"  },
				{ 'name': 'Configurator',  "type":"External App",  "action":"Abc.exe" },
				{ 'name': 'Decommision',  "type":"Field Map",  "action":"SVMX_Default_Decomm"  },
				{ 'name': 'Configurator',  "type":"External App",  "action":"Abc.exe" },
				{ 'name': 'Decommision',  "type":"Field Map",  "action":"SVMX_Default_Decomm"  },
				{ 'name': 'Configurator',  "type":"External App",  "action":"Abc.exe" },
			]},
			proxy: {
				type: 'memory',
				reader: {
					type: 'json',
					rootProperty: 'items'
				}
			}
		});
		
		var pgb = Ext.create('Ext.ProgressBar', {
			text: 'Updating...'
		});
		
		var prog = 0;

		setInterval(function() {
			prog = (prog + 5) % 105;

			pgb.updateProgress(prog / 100);
		}, 100);

		var items = [
			{
				xtype: 'panel',
				ui: 'svmx-gray-panel',
				title: 'Panel',
				margin: '20 20',
				cls: 'grid-panel-borderless',
				html:'<div style="padding:15px">Panel content comes here</div>'
			},
			{
				xtype: 'panel',
				margin: '60 20',
				dockedItems: [{
					xtype: 'toolbar',
					dock: 'top',
					cls: 'grid-panel-borderless',
					items: [{
						text: 'Toolbar Docked to the top'
					}]
				},{
					xtype: 'toolbar',
					dock: 'bottom',
					cls: 'grid-panel-borderless',
					items: [{
						text: 'Toolbar Docked to the bottom'
					}]
				}],
				//title: 'Panel',
				//margin: '3',
				items: [
					{
						xtype: 'button',
						margin: '7',
						text: 'Small'
					},{
						xtype: 'button',
						margin: '7',
						text: 'Medium',
						scale : 'medium'
					},{
						xtype: 'button',
						margin: '7',
						text: 'Large',
						scale : 'large'
					},{
						xtype: 'button',
						margin: '7',
						cls: 'plain-btn-text-center',
						text: 'Action Button 1'
					}
				]
			},{
				xtype: 'toolbar',
				margin: '60 20 5',
				cls: 'grid-panel-borderless',
				items: ['->',
					{xtype: 'button', text: 'Toolbar Button 1'},
					{xtype: 'button', text: 'Toolbar Button 2'},
					{xtype: 'button', text: 'Toolbar Button 3'}
				]
			},{
				xtype: 'toolbar',
				ui: 'svmx-plain-toolbar',
				dock: 'bottom',
				margin: '5 20',
				items: ['->',
					{xtype: 'button', text: 'Plain Toolbar Button 1'},
					{xtype: 'button', text: 'Plain Toolbar Button 2'},
					{xtype: 'button', text: 'Plain Toolbar Button 3'}
				]
			},{
				xtype: 'panel',
				margin: '60 0 0',
				cls: 'grid-panel-borderless',
				layout: {
					type: 'hbox',
					align: 'stretch'
				},
				items:[
					{
						xtype: 'form',
						title: 'Form Panel',
						//cls: 'grid-panel-borderless',
						//width: '50%',
						margin: '0 15',
						flex: 1,
						//layout: 'anchor',
						defaults: {
							anchor: '90%',
							labelAlign: 'right',
							labelWidth: '40%',
							padding: '10 0 10 0'
						},
						items: [{
									fieldLabel: 'Text Field ',
									xtype     : 'textfield',
									name      : 'textfield1'
								},{
									fieldLabel: 'ComboBox ',
									xtype: 'combo',
									store: ['Foo', 'Bar']
								},{
									fieldLabel: 'Number Field ',
									xtype     : 'numberfield',
									name      : 'number'
								},{
									fieldLabel: 'DateField ',
									xtype     : 'datefield',
									name      : 'date'
								},{
									fieldLabel: 'TimeField ',
									name: 'time',
									xtype: 'timefield'
								},{
									fieldLabel: 'Lookup ',
									xtype     : 'textfield',
									cls: 'svmx-lookup-icon'
								},
								{
									fieldLabel: 'Checkboxes ',
									xtype: 'checkboxgroup',
									columns: [100,100],
									items: [
										{boxLabel: 'Foo', checked: true,id:'fooChk',inputId:'fooChkInput'},
										{boxLabel: 'Bar'}
									]
								},{
									fieldLabel: 'Radios ',
									xtype: 'radiogroup',
									columns: [100,100],
									items: [{boxLabel: 'Foo', checked: true, name: 'radios'},{boxLabel: 'Bar', name: 'radios'}]
								},{
									fieldLabel: 'TextArea ',
									xtype     : 'textareafield',
									name      : 'message',
									cls       : 'x-form-valid',
									value     : 'This field is hard-coded to have the "valid" style'
								}
						]
					},{
						xtype: 'window',
						id: 'basicWindow',
						hidden: false,
						title: 'Window',
						margin: '0 20 0 20',
						width: '50%',
						//bodyPadding: 5,
						html       : '<div style="padding: 15px">Click Submit for Confirmation Msg.</div>',
						collapsible: false,
						floating   : false,
						closable   : true,
						draggable  : false,
						//width: 300,
						//height: 300,
						buttons: [
							{
								text   : 'Submit',
								id     : 'message_box',
								handler: function() {
									Ext.MessageBox.confirm('Confirm', 'Are you sure you want to do that?');
								}
							}
						]
					}
				]		
			},{
				xtype: 'gridpanel',
				margin: '60 20 0 20',
				//height: 400,
				cls: 'panel-radiusless',
				store: Ext.data.StoreManager.lookup('simpsonsStore'),
				columns: [
					{
						menuDisabled: true,
						sortable: false,
						xtype: 'actioncolumn',
						width: 50,
						items: [{
									iconCls: 'delet-icon',
									tooltip: 'Delete'
								}]
					},
					{ text: 'Name', sortable: true, menuDisabled: false, dataIndex: 'name', width: 200 },
					{ text: 'Type', sortable: true, menuDisabled: false, dataIndex: 'type', width: 250, flex: 1 },
					{ text: 'Action', sortable: true, menuDisabled: false, dataIndex: 'action', width: 350 },
					{ text: 'Is Global', xtype : 'svmx.columncheck', dataIndex: 'visible', sortable: false, menuDisabled: true }                                                    
				],
				tbar: [{
						xtype: 'textfield',
						width: '40%',
						cls: 'search-textfield',
						emptyText : 'Search'
						//trigger1Cls: Ext.baseCSSPrefix + 'form-clear-trigger',
						//trigger2Cls: Ext.baseCSSPrefix + 'form-search-trigger'
					},'->',{
						xtype: 'button',
						cls: 'plain-btn',
						iconCls: 'plus-icon'
					},{
						xtype: 'button',
						cls: 'plain-btn',
						iconCls: 'delete-icon'
					},{
						xtype: 'button',
						cls: 'plain-btn',
						iconCls: 'options-orange-icon'
					},{
						xtype: 'button',
						cls: 'plain-btn',
						tooltip: 'Create',
						iconCls: 'create-from-ib-icon'
					},{
						xtype: 'button',
						cls: 'plain-btn',
						tooltip: 'Save as',
						iconCls: 'save-as-icon'
					}
				]
			},{
				xtype: 'panel',
				margin: '60 20 0',
				cls: 'grid-panel-borderless',
				layout: {
					type: 'hbox',
					align: 'stretch'
				},
				items: [{
						xtype: 'treepanel',
						cls: 'svmx-tree-panel',
						margin: '0 0 10 0',
						//width: '40%',
						//height: 480,
						flex: 1,
						store: svmxtreestore,
						rootVisible: false
					},{
						xtype: 'panel',
						margin: '0 0 0 140',
						cls: 'grid-panel-borderless',
						border: false,
						flex: 1,
						items: {
							xtype: 'datepicker'
						}
					},{
						xtype: 'panel',
						ui: 'svmx-gray-panel',
						title: 'Action Buttons',
						cls: 'grid-panel-borderless',
						flex: 1,
						items: [
							{
								xtype: 'button',
								width: '100%',
								cls: 'plain-btn-text-center border-botton',
								text: 'Action Button 1'
							},{
								xtype: 'button',
								width: '100%',
								cls: 'plain-btn-text-center border-botton',
								text: 'Action Button 2'
							},{
								xtype: 'button',
								width: '100%',
								cls: 'plain-btn-text-center border-botton',
								text: 'Action Button 3'
							}
						]
					}
				]
			
			},{
				xtype: 'panel',
				//flex: 1,
				width: '50%',
				margin: '60 0 0 20',
				items:[{
						xtype: 'toolbar',
						cls: 'grid-panel-borderless',
						style:'background-color: #fff',
						margin: '0',
						items:[{
									xtype: 'textfield',
									cls: 'toolbar-search-textfield',
									width: '95%',
									emptyText : 'Search'
								},{
									//width: '2%',
									flex: 1,
									xtype: 'button',
									iconCls: 'option-button'
								}
						]
					}
				]
			},{
				xtype: 'tabpanel',
				cls: 'horizontal-tab-panel grid-panel-borderless panel-radiusless',
				plain : 'true',
				margin: '60 20 0',
				height: 200,
				items: [{
					title: 'Horizontal Tab 1',
					html: '<div style="margin: 10px">Horizontal Tab 1</div>'
					},{
						title: 'Horizontal Tab 2',
						html: '<div style="margin: 10px">Horizontal Tab 2. Horizontal Tab 2</div>'
					}]
			},{
				xtype: 'tabpanel',
				height: 300,
				//width: 600,
				tabPosition: 'left',
				tabRotation: 0,
				tabBar: {
					border: false
				},
				margin: '80 20 0 20',
				cls: 'panel-radiusless',
				ui: 'setup-tabpanel',
				defaults: {
					textAlign: 'left',
					bodyPadding: 7
				},
				items: [{
						title: 'Vertical Tab 1',
						html: "Vertical Tab 1"
					},{
						title: 'Vertical Tab 2',
						html: "Vertical Tab 2. Vertical Tab 2"
					}, {
						title: 'Vertical Tab 3',
						html: "Vertical Tab 3. Vertical Tab 3. Vertical Tab 3"
					}
				]
			},{
				xtype: 'panel',
				margin: '60 20 0 20',
				items: [
					pgb
				]
			},{
				xtype: 'panel',
				height: 80,
				//width: '100%',
				margin: '60 20 0 20',
				autoScroll: true,
				overflowX:'hidden',
				id: 'Parent',
				cls: 'svmx-documents-carousel',
				layout: {
					type: 'hbox',
					align: 'stretch',
					pack: 'center'                    
				},
				dockedItems: [{
						xtype: 'button',
						itemId: 'slideLeft',
						width: 20,
						dock: 'left',
						cls: 'carousel-slide-left',
						listeners: {
							click: {
								fn: function () {
									Ext.getCmp('Parent').scrollBy(-600, 0, true);
								}
							}
						}
					},{
						xtype: 'button',
						itemId: 'slideRight',
						width: 20,
						dock: 'right',
						cls: 'carousel-slide-right',
						listeners: {
							click: {
								fn: function () {
									Ext.getCmp('Parent').scrollBy(600, 0, true);
								}
							}
						}
					}
				],
				items: [{
						xtype: 'panel',
						cls: 'grid-panel-borderless svmx-carousel-btn-panel',
						defaults: {
							//xtype: 'image',
							//cls: 'item-image',
							//height: 160,
							listeners: {
								click: {

								}
							}
						},
						items: [
							{
								xtype: 'button',
								text: 'Change.mp4',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Manual.pdf',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-pdf',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Design.jpg',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-img-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Change2.mp4',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Manual2.pdf',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-pdf',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Design2.jpg',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-img-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Change3.mp4',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Manual3.pdf',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-pdf',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Design3.jpg',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-img-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Change4.mp4',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Manual4.pdf',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-pdf',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Design4.jpg',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-img-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Change5.mp4',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-icon',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'Manual5.pdf',
								height: 60,
								cls: 'svmx-carousel-btn',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-audio-pdf',
								margin: '0 10'
							},{
								xtype: 'button',
								text: 'ADD',
								height: 60,
								cls: 'svmx-carousel-btn svmx-btn-text-bold',
								iconAlign: 'top',
								scale : 'medium',
								iconCls: 'svmx-carousel-add-icon',
								margin: '0 10'
							}]
					}]
			}			
		];
		mainContainer = Ext.create('Ext.panel.Panel', {
	        renderTo: SVMX.getDisplayRootId(),
	        items: items,
	        title: '<span class="title-text">UI Components</span> <div class="logo"/></div>',
			titleAlign: 'center', 
			frame: 'true',
			collapsible : false,
			style: 'margin:10px',
			height : 3200,
			toolPosition: 0,
			tools: [{
				type:'hamburger',
				cls: 'hamburger',
				handler: function(e, el, owner, tool){			
					getMenu(owner).showBy(owner,'tl-bl?');			
				}
			}],
			layout: {
				padding: '0'
			}
    	});
		}
		
	},{});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\commands.js
/**
 * 
 */

(function(){
    var commandsImpl = SVMX.Package("com.servicemax.client.installigence.commands");
    
commandsImpl.init = function(){
    
    commandsImpl.Class("GetMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_METADATA"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetMetadataComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("FindByIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_BY_IB"});
        },
    
        result : function(data) { 
            this.__cbContext.onSearchByIBComplete(data);
        },

        error : function(data) {
            this.__cbContext.onSearchByIBError();
        }
        
    },{});
    
    commandsImpl.Class("GetTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_TOP_LEVEL_IBS"});
        },
    
        result : function(data) {
            this.__cbContext.onGetTopLevelIBsComplete(data);
        }
        
    },{});

    commandsImpl.Class("FetchToplevelAccounts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_TOPLEVEL_ACCOUNTS"});
        },
    
        result : function(data) {
            this.__cbContext.onGetTopLevelAccountsComplete(data);
        }
        
    },{});

    commandsImpl.Class("FindSelectedIBRecordInLocalDB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "FIND_SELECTED_IB_IN_LOCAL_DB"});
        },
    
        result : function(data) { 
            this.__cbContext.onSearchBySelectedIBComplete(data);
        }
        
    },{});
    
     commandsImpl.Class("FetchCustomFieldName", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_CUSTOM_FIELD"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
     commandsImpl.Class("UpdateRecordNameTable", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_RECORD_NAME_TABLE"});
        },
    
        result : function(data) { 
            this.__cbContext.recordNameUpdateSuccess(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetPageLayout", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_PAGELAYOUT"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetPageLayoutCompleted(data);
        }
        
    },{});
    
    commandsImpl.Class("GetPageData", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_PAGEDATA"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetPageDataCompleted(data);
        }
        
    },{});
    
    commandsImpl.Class("GetLocAccDetails", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOC_ACC_DETAILS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLocationAndAccountDetailsCompleted(data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetMoreIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_MORE_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetMoreIBsCompleted(data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("FindProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_PRODUCTS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
     commandsImpl.Class("SearchInstallBase", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SEACH_INSTALLBASE"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
     commandsImpl.Class("FetchValue", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_VALUES"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_RECORDS"});
        },
    
        result : function(data, isValid, parentNodeId) { 
            this.__cbHandler.call(this.__cbContext, data, isValid, parentNodeId);
        }
        
    },{});

    commandsImpl.Class("GetLocations", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOCATIONS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("CreateRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CREATE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});

    commandsImpl.Class("DeleteRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.DELETE_RECORDS"});
        },
    
        result : function(success) { 
            this.__cbHandler.call(this.__cbContext, success, this.__params);
        }
        
    },{});

    commandsImpl.Class("UpdateIBHierarchy", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_IB_HIERARCHY"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});

    commandsImpl.Class("ApplyFieldUpdate", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.APPLY_FIELD_UPDATE"});
        },
    
        result : function(data) { 
            this.__cbContext.onApplyFieldUpdateComplete.call(this.__cbContext, data);
        }
        
    },{});
    
    commandsImpl.Class("GetLMTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_TOP_LEVEL_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLMTopLevelIBsComplete(data);
        }
        
    },{});

    commandsImpl.Class("GetLMAccountsLocations", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_ACCOUNTS_LOCATIONS"});
        },
    
        result : function(accountIds, locationIds) {
            this.__cbContext.onGetLMAccountsLocationsComplete(accountIds, locationIds);
        }
        
    },{});

    commandsImpl.Class("GetLMProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_PRODUCTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLMProductsComplete(data);
        }
        
    },{});

     commandsImpl.Class("SaveMultipleRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_MULTIPLE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("SaveRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_RECORD"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("SaveRecordConfirm", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_RECORD_CONFIRM"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("CloneRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CLONE_RECORD"});
        },
    
        result : function(data) { 
            this.__cbContext.onCloneComplete(data);
        }
        
    },{});

    commandsImpl.Class("CloneMultipleRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CLONE_MULTIPLE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbContext.onCloneComplete(data);
        }
        
    },{});

    commandsImpl.Class("SaveState", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_STATE"});
        },
    
        result : function(data) { 
            //
        }
        
    },{});

    commandsImpl.Class("GetSyncConflicts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_SYNC_CONFLICTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetSyncConflictsComplete(data);
        }
        
    },{});

    commandsImpl.Class("UpdateSyncConflicts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_SYNC_CONFLICTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onUpdateSyncConflictsComplete(data);
        }
        
    },{});

    commandsImpl.Class("GetAllParentIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_ALL_PARENT_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onAllParentIBsComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("SendExternalMessage", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SEND_EXTERNAL_MSG"});
        },
    
        result : function(data) { 
            this.__cbContext.onSendExternalMessageComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("ExecuteAPI", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.EXECUTE_API"});
        },
    
        result : function(data) { 
            this.__cbContext.onExecuteAPIComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("GetApplicationFocus", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_APP_FOCUS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetAppFoucsComplete(data);
        }
        
    },{});
    commandsImpl.Class("GetLookupConfig", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOOKUPCONFIG"});
        }, 
    
        result : function(data) { 
            //this.__cbContext.__findComplete(data.data,true,data.parentNodeId,data.displayCols);
            this.__cbHandler.call(this.__cbContext, data.data,true,data.parentNodeId,data.displayCols);
        }
        
    },{});

    commandsImpl.Class("GetAllChildIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_ALL_CHILD_IBS"});
        }, 
    
        result : function(data) { 
           this.__cbHandler.call(this.__cbContext, data);
        }
        
    },{});
    
    commandsImpl.Class("IBSearchConfig", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_IBSEARCHCONFIG"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onGetMetadataCompleteForAdvanceSearch(data);
        }
        
    },{});

    commandsImpl.Class("FindTechnicalAttributeTemplateForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
           // debugger;
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_TA_TEMPLATE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            //debugger;
            this.__cbContext.__findTemplateComplete(data);
        }
        
    },{});

   

    commandsImpl.Class("SaveTechnicalAttributeTemplateInstanceForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_TA_TEMPLATE_INSTANCE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("UpdateTechnicalAttributeTemplateForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_TA_TEMPLATE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onUpdateComplete(data);
        }
        
    },{});
    
    
};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\impl.js

(function(){
	
	SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXC";
	SVMX.appType = SVMX.getClient().getApplicationParameter("app-type") || "external";
	SVMX.getCustomFieldName = function(name){ return SVMX.OrgNamespace + "__" + name + "__c"; };
	SVMX.getCustomObjectName = function(name){ return SVMX.OrgNamespace + "__" + name + "__c"; };
	SVMX.getCustomRelationName = function(name){ return SVMX.OrgNamespace + "__" + name + "__r"; };
	
	var instImpl = SVMX.Package("com.servicemax.client.installigence.impl");

	instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
			instImpl.Module.instance = this;
		},

		initialize : function(){
			com.servicemax.client.installigence.root.init();
			com.servicemax.client.installigence.filters.init();
			com.servicemax.client.installigence.actions.init();
			com.servicemax.client.installigence.documents.init();
			com.servicemax.client.installigence.topography.init();
			com.servicemax.client.installigence.configuration.init();
			com.servicemax.client.installigence.record.init();
			com.servicemax.client.installigence.ibtree.init();
			com.servicemax.client.installigence.ibswap.init();
			com.servicemax.client.installigence.home.init();
			com.servicemax.client.installigence.progress.init();
			com.servicemax.client.installigence.findandget.init();
			com.servicemax.client.installigence.contentarea.init();
			com.servicemax.client.installigence.commands.init();
			com.servicemax.client.installigence.ui.comps.init();
			com.servicemax.client.installigence.lookup.init();
			com.servicemax.client.installigence.objectsearch.init();
			com.servicemax.client.installigence.conflict.init();
			com.servicemax.client.installigence.loadselectedib.init();
			com.servicemax.client.installigence.utils.init();
			com.servicemax.client.installigence.mashups.init();
			com.servicemax.client.installigence.ibToolBar.init();
			com.servicemax.client.installigence.search.init();
			com.servicemax.client.installigence.ibSearch.init();
			com.servicemax.client.installigence.svmxPopup.init();
			com.servicemax.client.installigence.recordInformation.init();
			com.servicemax.client.installigence.recordDetails.init();
		},
		
		afterInitialize : function(){
			
		}
	}, {
		instance : null
	});
	
	instImpl.Class("EventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); }
	}, {
		__instance : null,
		getInstance : function(){
			if(!instImpl.EventBus.__instance){
				instImpl.EventBus.__instance = SVMX.create("com.servicemax.client.installigence.impl.EventBus", {});
			}
			return instImpl.EventBus.__instance;
		}
	});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\metamodel.js
/**
 * 
 */

(function(){
    var metaImpl = SVMX.Package("com.servicemax.client.installigence.metamodel");
    
    metaImpl.Class("AbstractMetamodel", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor : function(){
            this.__base();
        },
        
        initialize : function(){
            // do nothing
        },

        refresh : function() {
            // do nothing
        }
        
    }, {});
    
    metaImpl.Class("Root", com.servicemax.client.installigence.metamodel.AbstractMetamodel, {
        filters     : null,
        actions     : null,
        mappings    : null,
        profileId   : null,
        profileName : null,
        ibPriorityFields : null,
        ibHiddenFields : null,
        productDisplayFields : null,
        productSearchFields : null,
        locPriorityFields : null,
        locHiddenFields : null,
        slocPriorityFields : null,
        slocHiddenFields : null,
        accPriorityFields : null,
        accHiddenFields : null,
        ibDisplayFields : null,
        ibSearchFields : null,
        advanceSearch:null,
        
        __constructor : function(){
            this.__base();
            
            this.filters = [];
            this.actions = [];
            this.ibPriorityFields = [];
            this.ibHiddenFields = [];
            this.productSearchFields = [];
            this.productDisplayFields = [];
            this.locPriorityFields = [];
            this.locHiddenFields = [];
            this.slocPriorityFields = [];
            this.slocHiddenFields = [];
            this.accPriorityFields = [];
            this.accHiddenFields = [];
            this.ibDisplayFields = [];
            this.ibSearchFields = [];
            this.__bindSyncEvents();
            this.advanceSearch = {};
        },
        
        initialize : function(){
            this.refresh();
        },

        refresh : function(){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_METADATA", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
        },

        onGetMetadataComplete : function(data){
            // TODO: should it be more or less explicit here?
            var i, keys = Object.keys(data), l = keys.length;
            for(i = 0; i < l; i++){
                var key = keys[i];
                this[key] = data[key];
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_IBSEARCHCONFIG", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
            this.__notifyUpdate();
        },
	onGetMetadataCompleteForAdvanceSearch:function(searchConfig) {
            var displayFields = [];
            var searchFields = [];
			var refrenceDict = [];
			var advancedExpression;

            if (searchConfig) {
                for (var i = 0; i < searchConfig.length; i++) {
                    var searches = searchConfig[i].searches;
                    if (searches) {
                        for (var j = 0; j < searches.length; j++) {
                            var searchConfigFields = searches[j].searchfields;
                            refrenceDict = searches[j].searchfields;
                            advancedExpression = searches[j].advancedExpression; 
                        }
                    }
                }
            }

            // for (var i=0; i<data.length;i++) {
            //     var currentDictionary = data[i];
            //     var fieldType = currentDictionary.fieldType;
            //     var fieldName = currentDictionary.fieldName;

            //     if (fieldType == "Search"){
            //         searchFields.push(fieldName);
            //     }

            //     if (fieldType == "Result"){
            //         displayFields.push(fieldName);
            //     }
            // }

            this.advanceSearch = refrenceDict;//{"displayFields":displayFields,"searchFields":searchFields};
			this.advancedExpression = advancedExpression;
            this.__notifyUpdate();
        },

        __notifyUpdate : function(params){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "MODEL.UPDATE", this, params);
            this.triggerEvent(evt);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();

            syncService.bind("SYNC.STATUS", function(evt){
                var status = evt.data.type;
                var syncType = evt.data.syncType;
                if(status === "complete"){
                    if(syncType === "initial" || syncType === "reset" || syncType === "config"){
                        this.refresh();
                    }
                }
            }, this);
        }
        
    }, {});
    
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\actions.js
/**
 * 
 */

(function(){
    
    var actionsImpl = SVMX.Package("com.servicemax.client.installigence.actions");

    actionsImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.actions.Actions", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.actions',

            __allActions : null,
            __allActionProviders : null,
            __showingDisabledActions : true,
            __contentarea : null,
            __nodesSelected : null, 
            __meta : null,
            __menu:null,
            __Apikey:null,
            __objectInfo:null,
            __SelectedNode:null,


            constructor:function(config) {
                var me = this;
                this.__allActions = [];
                this.__allActionProviders = [];
                this.__showingDisabledActions = true;
                this.__meta = config.meta;
				this.__Apikey = this.__getApiKey();
				this.__objectInfo = SVMX.getCurrentApplication().getObjectInfo();

                this.__menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain:true,
                    width: 310,
                    scrollable: true,
                    maxHeight: 500,
                    layout: 'vbox'

                });

                config = Ext.apply({
                    items : [ 
                        { 
                            xtype: 'button', 
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG047,'Actions'), 
                            cls: 'ibtoolbar-actions-btn',
                            textAlign: 'right',
                            menuAlign: 'tr-br',
                            margin : '10 ',
                            width : '100px',
                            menu:this.__menu,
                            handler: function(){
                            	//me.checkingForOnline();
                            }

                        }
                    ]


                }, config || {});
                
                config.contentarea.on("node_selected", function(nodes){
                    // actions should work with more that one node.
                    // for now, we will mimic it
                    this.__SelectedNode = nodes;
                    if(!(nodes instanceof Array)) nodes = [nodes];
                        this.handleNodeSelect(nodes);
                        
                    //With ib node, we have to disable customAction 
                    this.disableCustomActionForLocation(nodes, me);
                    
                }, this);
                
                this.__contentarea = config.contentarea;
                this.callParent([config]);


                this.setup();


            }, // end of the constructor.
            
            checkingForOnline : function (){
            	var nodes = this.__SelectedNode;
            	if(nodes){
					if(nodes.nodeType == "LOCATION" || nodes.nodeType == "SUBLOCATION"){
						this.__isCustomActionUrlButtonEnabled(true, this);
					}else{
						this.disableURLIfOffline();
					}
				}else{
					this.disableURLIfOffline();
				}
            },
            
            disableURLIfOffline : function(){
            	var isEnabled = window.navigator.onLine;
				if(isEnabled)
					this.__isCustomActionUrlButtonEnabled( !isEnabled, this);
				else
					this.__isCustomActionUrlButtonEnabled( !isEnabled, this);
            },
            
        	disableCustomActionForLocation : function(nodes, me){
        		if(nodes){
					for(var i = 0; i < nodes.length; i++){
						if(nodes[i].nodeType == "LOCATION" || nodes[i].nodeType == "SUBLOCATION")
							me.__isCustomActionUrlButtonEnabled(true, me);
						else
							me.__isCustomActionUrlButtonEnabled(false, me);
					}
				}
        	},

           
            handleNodeSelect : function(nodes){
                    this.__nodesSelected = nodes;

                    var i, actions = this.__allActions, l = actions.length, ac, ap,menu=this.__menu;
                    for(i = 0; i < l; i++){
                        ac = actions[i]; ap = ac.provider;
                        ap.setContext(nodes);
                        if(ap.isValid()){
                            if (menu.items.items[i]) {
                                    menu.items.items[i].setDisabled(false);
                                    menu.items.items[i].setVisible(true);
                            }
                        }else{
                            if (menu.items.items[i]) {
                                menu.items.items[i].setDisabled(true);
                            }
                            if(!this.__showingDisabledActions){
                                menu.items.items[i].setVisible(false);
                            }
                        }
                    }
            }, //end of handleNodeSelect method.

            getNodesSelected : function(){
                return this.__nodesSelected;
            }, // end of the getNodesSelected method.
        
            setup : function() {
                this.__setupDefaults();
                this.meta.bind("MODEL.UPDATE", function(evt){
                    this.refresh();
                }, this);
            }, // end of setup method.

            __setupDefaults : function(){
                    var me = this;

                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.AddNew"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.CloneInstalledProduct"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.AddNewLocation"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.DeleteNew"});
                    // this.addActionProvider({className : "com.servicemax.client.installigence.actions.ComponentReplacement"});
                    //TODO: need to implement below methods.

                    // default actions
                    var i,l = this.__allActionProviders.length, b, ap,menuItem;
                    for(i = 0; i < l; i++){
                        ap = SVMX.create(this.__allActionProviders[i].className, {});

                        menuItem = {
                                    text: ap.getName(),
                                    provider : ap, 
                                    disabled : true,
                                    margin: '6 0 12 10',
                                //     draggable: {

                                //     //overriding the draggable delegates to stop eventPropogations
                                //             onDrag: function(e) {
                                            
                                //             },
                                //             onEnd: function(e) {
                                            
                                //             }
                                            
                                // },
                                    handler : function(){
                                                this.provider.act(this, me);
                                    }
                        };
                         

                        this.__menu.add(menuItem);
                        this.__allActions.push(menuItem);
                    }
                    
                    // add separator
                    var separator = SVMX.create("com.servicemax.client.installigence.ui.components.Label", {
                        html : "<div></div>", width: '100%', padding : 0, height : 25, style : {"background-color" : "#D0CDCD"}
                    });
                    // this.__menu.add(separator);
            }, //end of setupDefaults method.

            refresh : function(){
                var me = this;

                this.removeCustomActions();

                if(!this.meta.actions || !this.meta.actions.length){
                    return;
                }
                var m = this.meta.actions, l = m.length, i, b, ap;
                for(i = 0; i < l; i++){
                    if(m[i].isHidden){
                        if(m[i].isHidden === true)
                            continue;
                    }
                    m[i].mapping = this.__getMappingByName(m[i].action);
                    m[i].customUrls = this.__getCustomURLs(m[i].action);

                    ap = SVMX.create("com.servicemax.client.installigence.actions.CustomActionProvider", m[i]);

                    menuItem = {
                                    text: ap.getName(),
                                    provider : ap, 
                                    disabled : true,
                                    margin: '6 0 12 10',
                                    actionType: m[i].actionType,
                                    custom:true,
                                    ApiKey : this.__Apikey,
                                    // draggable: {

                                    // //overriding the draggable delegates to stop eventPropogations
                                    //         onDrag: function(e) {
                                            
                                    //         },
                                    //         onEnd: function(e) {
                                            
                                    //         }
                                            
                                    // },
                                    handler : function(){
                                                this.provider.act(this, me);
                                    }
                        };
                         

                    this.__menu.add(menuItem);
                    this.__allActions.push(menuItem);
                }
                this.__registorForNetworkStatusNotification();
            },// end of refresh method.

            __registorForNetworkStatusNotification : function(){
                
               
                 /* adding events online and offline to detecting the network changes*/
                var me = this,
                isOnline = function(){
               		//me.__isCustomActionUrlButtonEnabled(false, me);
            
                },isOffline = function(){
                	//me.__isCustomActionUrlButtonEnabled(true, me);
                }

                 if (window.addEventListener) {
                        /*
                            Works well in Firefox and Opera and Google Chrome.
                        */
                        window.addEventListener("online", isOnline, false);
                        window.addEventListener("offline", isOffline, false);
                    }
                    else {
                        /*
                            Works in IE.
                        */
                        document.body.ononline = isOnline;
                        document.body.onoffline = isOffline;
                    }
                /* End- online and offiline events*/

            },
             __isCustomActionUrlButtonEnabled: function(isEnabled, me){

                var i = me.__allActions.length,menu=me.__menu,menuItem;

                while(i > 0){
                    i--;
                    menuItem = menu.items.items[i];
                    if(menuItem){
                        if (menuItem.custom && menuItem.actionType === "customurl") {
                            menu.items.items[i].setDisabled(isEnabled);
                        }
                    }
                }
            },
            removeCustomActions : function(){
                var i = this.__menu.items.items.length,menu=this.__menu,menuItem;
                while(i > 0){
                    i--;
                    menuItem = menu.items.items[i];
                    if(menuItem.custom){
                        // var b = this.__allActions.splice(i, 1)[0];
                        this.__menu.remove(menuItem);
                    }
                }
            },

            __getMappingByName : function(mapName){
                if(!this.meta.mappings) return null;
                var i, l = this.meta.mappings.length;
                for(i = 0; i < l; i++){
                    if(this.meta.mappings[i].name === mapName){
                        return this.meta.mappings[i];
                    }
                }
            },

            __getCustomURLs : function(customURLName){
                if(!this.meta.customUrls) return null;
                var i, l = this.meta.customUrls.length;
                for(i = 0; i < l; i++){
                    if(this.meta.customUrls[i].name === customURLName){
                        return this.meta.customUrls[i];
                    }
                }
            },
        
            showDisabledActions : function(){
                var i, l = this.__allActions.length;
                for(i = 0; i < l; i++){
                    this.__allActions[i].setVisible(true);
                }
                this.__showingDisabledActions = true;
            },
        
            hideDisabledActions : function(){
                var i, l = this.__allActions.length;
                for(i = 0; i < l; i++){
                    if(this.__allActions[i].isDisabled()) this.__allActions[i].setVisible(false);
                }
                this.__showingDisabledActions = false;
            },
            
            toggleOptions : function(){
                this.__optionsPanel.toggleCollapse();
                this.doLayout();
            },
            
            addActionProvider : function(info){
                this.__allActionProviders.push(info);
            },
        
            getContentArea : function(){
                return this.__contentarea;
            },
            
            /* making request for API key for Literals */
            __getApiKey : function() {
				var me = this;
				// var nativeService = window.parent.com.servicemax.client.offline.sal.model.nativeservice.Facade;
                // var request = nativeService.createGenerateApiKeyRequest();

                var nativeService = SVMX.getCurrentApplication().getNativeServiceRequest();
                var request = nativeService.createGenerateApiKeyRequest();
                
 				request.bind("REQUEST_COMPLETED", function(evt){
				   me.__Apikey = evt.data.data;
				}, this);

				request.bind("REQUEST_ERROR", function(evt){
					me.__ApiKey = "";
				}, this);
				request.execute();
        }

        
    }); // ********* end of the define.

    actionsImpl.Class("ActionProvider", com.servicemax.client.lib.api.Object, {
            _meta : null, _context : null,
            __constructor : function(meta){ 
                this.__base(); 
                this._meta = meta;
            },
            getName: function(){
                return this._meta.name;
            },
            
            setContext : function(context){
                this._context = context;
            },
            
            isValid : function(){
                throw new Error("Please override this method <ActionProvider.isValid()>");
            },
            
            act : function(source, parent){
                throw new Error("Please override this method <ActionProvider.act()>");
            },

            _getTargetRecordIds : function(parent){
                var targetIds = [];
                var nodes = parent.getNodesSelected();
                var i, l = nodes.length;
                for(i = 0; i < l; i++){
                    targetIds.push(nodes[i].id);
                }
                return targetIds;
            }
    }, {}); // end of ActionProvider class.

    actionsImpl.Class("AddNew", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG032,'Add New Installed Product')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && (this._context[0].nodeType == "IB" || this._context[0].nodeType == "LOCATION" || this._context[0].nodeType == "SUBLOCATION")){ 
                return true;
            }else{ 
                return false;
            }
        },

        /*act : function(source, parent){
            var parentNode = this._context[0];
            var addType = "IB";
            parent.getContentArea().addToTree({}, parentNode, addType);
        }*/
        
        act : function(source, parent){

            //Hide the popover.
            var me = this;
            var parentNode = this._context[0];
            var displayFields = parent.__meta.productDisplayFields || [];
            var searchFields = parent.__meta.productSearchFields || [];
            var productSearch = SVMX.create("com.servicemax.client.installigence.objectsearch.ObjectSearch", {
                objectName : "Product2",
                columns : displayFields.length ? displayFields : [{name: 'Name'}],
                searchColumns : searchFields.length ? searchFields : [{name: 'Name'}],
                multiSelect : true,
                sourceComponent : source,
                mvcEvent : "FIND_PRODUCTS",
                createHandler : function(){
                    var records = [{Name: "New Installed Product"}];
                    parent.getContentArea().addToTree(records, parentNode, "IB");
                }
            });
            productSearch.find().done(function(results){
                parent.getContentArea().addToTree(results, me._context[0], "IB");
            });
        }
    }, {}); // end of the addNew class.

    actionsImpl.Class("CloneInstalledProduct", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG100,'Clone Install Product')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && this._context[0].nodeType == "IB"){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var me = this;
            window.action_cascade = false;
            SVMX.getCurrentApplication().showQuickMessage('confirm', $TR.__getValueFromTag($TR.PRODIQ001_TAG125,'Are you sure?') + '<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" />' + $TR.__getValueFromTag($TR.PRODIQ001_TAG138,'Clone all child records') +'</label>', function(resp){
                if(resp === "yes"){
                    me.__cascade = window.action_cascade;
                    me.__doCloneRecord(source, parent);
                }
            });
        },

        __doCloneRecord : function(source, parent){
            SVMX.getCurrentApplication().blockUI();
            this.__parent = parent;
            var targetId = this._getTargetRecordIds(parent)[0];
            var targetObject = SVMX.getCustomObjectName("Installed_Product");
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.CLONE_RECORD", this, {
                    request : {
                        context : this,
                        targetId : targetId,
                        objectName : targetObject,
                        cascade : this.__cascade
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onCloneComplete : function(record){
            SVMX.getCurrentApplication().unblockUI();
            this.__parent.getContentArea().addClonedToTree(record, this._context[0], "IB", this.__cascade);
        }

    }, {}); //end of cloneIB.


    actionsImpl.Class("AddNewLocation", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG033,'Add New Location')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && (this._context[0].nodeType == "ACCOUNT" || this._context[0].nodeType == "LOCATION")){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var parentNode = this._context[0];
            var addType = "LOCATION";
            parent.getContentArea().addToTree({}, parentNode, addType);
        }
    }, {}); // end of new location class.

    actionsImpl.Class("DeleteNew", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG101,'Delete')}); 
        },
        
        isValid : function(){
            var node = this._context.length === 1 && this._context[0];
            if(node){
                if(!this.__areAllNodesTransient(node)){
                    return false;
                }
                var nodeType = node.nodeType;
                if(nodeType == "IB" || nodeType == "LOCATION" || nodeType == "SUBLOCATION"){ 
                    return true;
                }
            }
            return false;
        },
        
        act : function(source, parent){
            var targetNode = this._context[0];
            SVMX.getCurrentApplication().showQuickMessage("confirm", $TR.__getValueFromTag($TR.DELETE_CONFIRM_MESSAGE,'Are you sure?'), function(resp){
                if(resp === "yes"){
                    parent.getContentArea().deleteFromTree(targetNode); 
                    source.setDisabled(true);
                }
            });
        },

        __areAllNodesTransient : function(node){
            if(node.recordId.indexOf('local') !== 4){
                return false;
            }else{
                return checkChildren(node.children);
            }
            function checkChildren(children){
                if(!children){
                    return true;
                }
                var areTransient = true;
                for(var i = 0; i < children.length; i++){
                    var childId = children[i].recordId;
                    if(childId && childId.indexOf('local') !== 4){
                        areTransient = false;
                    }
                    areTransient = areTransient && checkChildren(children[i].children);
                }
                return areTransient;
            }
        }
    }, {}); // end of delete class.

    // IB Swep 
    actionsImpl.Class("ComponentReplacement", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG102,'Component Replacement')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && this._context[0].nodeType == "IB"){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var me = this;
            var ibSwap = SVMX.create("com.servicemax.client.installigence.ibswap.IBSwap",{source : source, parent : parent});
            var selectedNode = parent.__contentarea.__ibtree.__selectedNodeId;
            ibSwap.getChildIBs(selectedNode);
        },
        
    }, {});

    actionsImpl.Class("CustomActionProvider", actionsImpl.ActionProvider, {
        __parent : null,

        __constructor : function(meta){
            this.__base(meta);
        },

        act : function(source, parent){
            var me = this;
            window.action_cascade = false;
            //SVMX.getCurrentApplication().showQuickMessage("confirm", 'Are you sure?<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" /> Apply to child nodes</label>', function(resp){
                //if(resp === "yes"){
                    me.__cascade = window.action_cascade;
                    me.__doCustomAction(source, parent);


                //}
            //});
        },

        __doCustomAction : function(source, parent){
            var me = this;
            this.__parent = parent;
            var targetIds = this._getTargetRecordIds(parent);
            switch(this._meta.actionType){
                // TODO: remove "Field Map"
                case "Field Map":
                case "fieldupdate":
                    SVMX.getCurrentApplication().showQuickMessage("confirm", 'Are you sure?<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" /> Apply to child nodes</label>', function(resp){
                        if(resp === "yes"){
                            var mapName = me._meta.action;
                            me.__cascade = window.action_cascade;
                            me.__applyFieldUpdate(targetIds, mapName);
                        }
                    });
                    break;
                case "customurl":
                    this.__openCustomURL();
                    break;
            }
        },

        __openCustomURL : function(){
            var me = this;

            this.getCustomURL(me).done(function(preparedurl){
                var customUrlName = me._meta.name;
                if(preparedurl)
                {
                    me.__launchUrl(preparedurl);
                }

            });
        },
        
        /* This method is responsible for launching CustomActionCall */
        __launchUrl : function(urlToLaunch) {
                var d = SVMX.Deferred();
                // var nativeService = window.parent.com.servicemax.client.offline.sal.model.nativeservice.Facade;
                var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
                var browserRequest = nativeservice.createBrowserRequest();

                browserRequest.bind("REQUEST_COMPLETED", function(evt){
                    var result = evt.data.data;
                    d.resolve(result);
                }, this);
                browserRequest.bind("REQUEST_ERROR", function(evt){
                    d.reject({
                      text: TS.T("TODO", "The application does not exist. Please contact your system administrator to update the application path or install the necessary software."),
                      type: "INFO"
                    });
                }, this);

                browserRequest.execute({
                    link: urlToLaunch
                });

                return d.promise();
            },

        getCustomURL : function(me){
            var d = SVMX.Deferred();

            this.getRecord(me).done(function(record) {
                var preparedurl = me._meta.customUrls.targetURL;
                var urlParameters = me._meta.customUrls.urlParameters;
                if(urlParameters && urlParameters.length > 0){
                	// if the link does not have a colon, we are assuming this is a url, so we prepend http://
                	preparedurl = (preparedurl.indexOf(":") == -1) ? "http://" + preparedurl : preparedurl;
                    preparedurl += "?";
                    for(var i=0; i<urlParameters.length ; i++){
                        if(i === 0)
                            preparedurl += me.__getEncriptValuevalue(urlParameters[i].name) + "=";
                        else
                            preparedurl += "&" + me.__getEncriptValuevalue(urlParameters[i].name) + "=";
                        
                        if(urlParameters[i].parameterType === "Field Name"){
                            if(record)
                                preparedurl += me.__getEncriptValuevalue(record[urlParameters[i].value]);
                            else
                                continue;
                        }else if(urlParameters[i].parameterType === "Value"){
                        	var value = me.__checkingForLitralsAndPassValue(urlParameters[i].value);
                            preparedurl += me.__getEncriptValuevalue(value);
                        }
                    }
                }
                d.resolve(preparedurl);
            }); 	
            return d;
        },
        
        __getEncriptValuevalue : function(plainText){
        	return encodeURIComponent(plainText);
        },
        
         __checkingForLitralsAndPassValue : function(value){
			var litralValue = value.toUpperCase();
			var updatedValue = '';
			switch (litralValue) {
				case "SVMX.PRODUCTIQWORKORDERID": // Here passing name os the WO
					if(this.__parent.__objectInfo.object == SVMX.getCustomObjectName("Service_Order"))
						updatedValue = this.__parent.__objectInfo.objectId;
					else
						updatedValue = "";
					break;
				case "SVMX.USERNAME":
					var userName = window.parent.SVMX.getCurrentApplication().__userInfo.UserLogin;
					updatedValue = userName;
					break;
				case "SVMX.DATAACCESSAPIKEY":
					updatedValue = this.__parent.__Apikey;
					break;
				default:
					updatedValue = value || "";
			}
			return updatedValue;
		},
		
        getRecord : function(currentContext){
            var d1 = SVMX.Deferred();
            var objName = currentContext._meta.customUrls.sourceObjectName;
            var recId = currentContext.__parent.__nodesSelected[0].recordId;
            if(!recId)
                d1.resolve();

            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("*").from(objName)
            .where("Id = '" + recId + "'");
            queryObj.execute()
            .done(function(resp){
                d1.resolve(resp[0]);
            });

            return d1;
            //var recId = currentContext.
        },

        __applyFieldUpdate : function(targetIds, mapName){
            SVMX.getCurrentApplication().blockUI();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.APPLY_FIELD_UPDATE", this, {
                    request : {
                        context : this,
                        targetIds : targetIds,
                        mapName : mapName,
                        cascade : this.__cascade
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onApplyFieldUpdateComplete : function(success){
            SVMX.getCurrentApplication().unblockUI();
            if(success){
                this.__parent.getContentArea().refreshRecord();
                //SVMX.getCurrentApplication()
                //    .showQuickMessage('success', $TR.FIELD_UPDATE_APPLIED_MESSAGE);
            }
        },

        isValid : function(){
            var targetObjectName = null;
            if(this._context[0].nodeType === "LOCATION"){
                targetObjectName = SVMX.getCustomObjectName("Site");
            }else if(this._context[0].nodeType === "SUBLOCATION"){
                targetObjectName = SVMX.getCustomObjectName("Sub_Location");
            }else if(this._context[0].nodeType === "ACCOUNT"){
                targetObjectName = "Account";
            }else if(this._context[0].nodeType === "IB"){
                targetObjectName = SVMX.getCustomObjectName("Installed_Product");
            }
            if(this._meta.actionType && this._meta.actionType === "fieldupdate"){
                if(this._meta && this._meta.mapping && this._meta.mapping.targetObjectName === targetObjectName){
                    return true;
                }else{
                    return false;
                }    
            }else if(this._meta.actionType && this._meta.actionType === "customurl"){
                if(this._meta.customUrls && this._meta.customUrls.sourceObjectName === targetObjectName)
                    return true;
                else
                    return false;
            }else{
                return false;
            }
        }

    }, {}); // end of CustomActionProvider class.


    
  }; // end of the init.

})();

// end of file 

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\comps.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\configuration.js
/**
 * 
 */

(function(){
	
	var configurationImpl = SVMX.Package("com.servicemax.client.installigence.configuration");

configurationImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.configuration.Configuration", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXFormPanel",
        alias: 'widget.installigence.configuration',
        
        constructor: function(config) {	
        	config = Ext.apply({
        		title: 'Configuration',
        		titleAlign: 'center',
        		ui: 'svmx-white-panel',
        		listeners: {
					collapse: function () {
					   this.up().doLayout();
					},
					expand: function () {
						this.up().doLayout();
					}
				},
				layout: 'anchor',
				defaults: {
					anchor: '100%',
					padding: '10',
					labelAlign: 'right'
				},
				defaultType: 'textfield',
				items: [{
					fieldLabel: 'Throughput',
					name: 'throughput'
				},{
					fieldLabel: 'Oil Level',
					name: 'oillevel'
				}]
            }, config || {});
            this.callParent([config]);
        }
    });
	
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\conflict.js
/**
 * 
 */
(function(){
    
    var conflictImpl = SVMX.Package("com.servicemax.client.installigence.conflict");

conflictImpl.init = function(){
    
    conflictImpl.Class("Conflict", com.servicemax.client.lib.api.Object, {
        __config : null,
        __data : null,
        __store : null,
        __grid : null,
        __win : null,
        __root : null,
        
        __constructor : function(config){
            this.__config = config;
            this.__root = config.root;
        },
        
        show : function(){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_SYNC_CONFLICTS", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onGetSyncConflictsComplete : function(result){
            this.__data = result;
            this.__showUI();
        },
        
        __showUI : function(){
            this.__win = this.__getUI();
            this.__store.setData(this.__data);
            this.__win.show(this.__config.sourceComponent);
        },

        __save : function(){
            var records = [];
            for(var i = 0; i < this.__store.getCount(); i++){
                var rec = this.__store.getAt(i);
                records.push({
                    Id : rec.get("Id"),
                    Action : rec.get("Action")
                });
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.UPDATE_SYNC_CONFLICTS", this, {request : {context : this, records : records}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __startSync : function(){
            this.__syncing = true;
            this.__save();
        },

        __selectTreeNode : function(recordId){
            this.__root.selectTreeNode(recordId);
        },

        onUpdateSyncConflictsComplete : function(a, b, c){
            if(this.__syncing){
                this.__root.handleIncrementalSync();
                delete this.__syncing;
            }
        },
        
        __getUI : function(){
            var me = this;

            var conflictData = [
                {disp : "Select action", val : ""},
                {disp : "Apply online changes", val : "SERVER_OVERRIDE"}];
            var errorInsertData = [
                {disp : "Select action", val : ""},
                {disp : "Delete record", val : "CLIENT_DELETE"},
                {disp : "Retry", val : "CLIENT_OVERRIDE"}];
            var errorData = [
                {disp : "Select action", val : ""},
                {disp : "Restore record from online", val : "SERVER_OVERRIDE"},
                {disp : "Retry", val : "CLIENT_OVERRIDE"}];

            var setStore = function(type, operation, store) {
                store.removeAll();
                if (type == "conflict") {
                    store.add(conflictData);
                } else if (type == "error" && operation == "insert") {
                    store.add(errorInsertData);
                } else if (type == "error") {
                    store.add(errorData);
                }
            };

            var actionselect = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox', {
                valueField : "val",
                displayField : "disp",
                queryMode: "local",
                store : {
                    xtype : "svmx.store",
                    fields : ["val", "disp"],
                    data : []
                },
                listeners : {
                    beforequery : function(queryPlan, eOpts) {
                        var grid = me.__win.items.get(0);
                        var error_type = grid.selModel.getSelection()[0].get("Type");
                        var operation =  grid.selModel.getSelection()[0].get("Operation");
                        setStore(error_type, operation, actionselect.store);
                    }
                }
            });
            
            var datastore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                fields : ["Id", "Message", "CreatedDate", "Action", "record"],
                data : []
            });
            var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
                flex : 1, width: "100%",
                store : datastore,
                selModel: 'cellmodel',
                plugins: {
                    ptype: 'cellediting',
                    clicksToEdit: 1
                },
                columns: [
                    {
                        text : $TR.__getValueFromTag($TR.PRODIQ001_TAG089,'Record'),
                        dataIndex : "Id",
                        flex : 1.5,
                        renderer : SVMX.proxy(this, this.__nameFieldRenderer)
                    },
                    {
                        text : $TR.__getValueFromTag($TR.PRODIQ001_TAG120,'Message'),
                        dataIndex : "Message",
                        flex : 2,
                        renderer : function(value){
                            return '<div style="white-space: pre-wrap">'+value+'</div>';
                        }
                    },
                    /*{
                        text : "Conflict Date",
                        dataIndex : "CreatedDate",
                        flex : 1,
                        renderer : function(value){
                            return new Date(value);
                        }
                    },*/
                    {
                        text : $TR.__getValueFromTag($TR.PRODIQ001_TAG091,'Action'),
                        dataIndex : "Action",
                        flex : 1.5,
                        editor : actionselect,
                        readOnly : false,
                        queryCaching : false,
                        renderer : function(value, styleObj, record) {
                            var error_type = record.get("Type");
                            var operation =  record.get("Operation");
                            setStore(error_type, operation, actionselect.store);
                            var idx = actionselect.store.find(actionselect.valueField, value);
                            var rec = actionselect.store.getAt(idx);
                            return rec ? rec.get(actionselect.displayField) : "<b><i>"+"Select action"+"...</i></b>";
                        }
                    }
                ]
            });
            
            var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                layout : {type : "vbox"}, height : 400, width : 800,
                title : $TR.__getValueFromTag($TR.PRODIQ001_TAG088,'Synchronization Conflicts/Errors'),
                maximizable : false,
                closable:false,
                items : [grid],
                modal : true,
                buttons : [
                    {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG063,'Retry'), handler : function(){
                        me.__startSync();
                        win.close();
                    }},
                    {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG093,'Hold'), handler : function(){
                        me.__save();
                        win.close();
                    }},
                    {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG094,'Close'), handler : function(){
                        win.close();
                    }}
                ]
            });
            
            this.__store = datastore;
            this.__grid = grid;
            return win;
        },

        __nameFieldRenderer : function(value, meta, record){
            var me = this;
            var id = Ext.id();
            var rec = record.get('record');
            var recordId = rec.Id || value;
            var nameValue = rec.CaseNumber || rec.Name;
            if(nameValue !== false){
                nameValue = nameValue || "New Record";
                Ext.defer(function(){
                    $('<a>', {
                        text: nameValue,
                        href: 'javascript:void(0);',
                        click: function() {
                            me.__selectTreeNode(recordId);
                            me.__win.close();
                        }
                    }).appendTo('#' + id);
                }, 25);
                return Ext.String.format('<div id="{0}"></div>', id);
            }else{
                return "--None--";
            }
        }

    }, {});
};

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\contentarea.js
/**
 * 
 */

(function(){
	
	var contentareaImpl = SVMX.Package("com.servicemax.client.installigence.contentarea");

contentareaImpl.init = function(){
	
	/**
	 * EVENTS:
	 * 01. node_selected
	 */
	Ext.define("com.servicemax.client.installigence.contentarea.ContentArea", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.contentarea',
        __ibtree : null, __record : null, __meta : null, __mashUp : null, __recordInformation : null, __details : null,
        
        constructor: function(config) {
        	
        	this.__meta = config.meta;
        	var ibtree = SVMX.create("com.servicemax.client.installigence.ibtree.IBTree", {
                cls: 'installigence-ibtree', 
    			width: '33.3%', margin: '0', meta : config.meta, root : config.root
    		});
        	var me = this;
        	ibtree.on("node_selected", function(nodes){
                if(this.__mashUp){
                    this.__mashUp.setVisible(false); 
                }
                if(this.__record){
                    this.__record.setVisible(true); 
                }
                // Enable details tab for nodeType IB and disable for others.
                if(nodes.nodeType == 'IB' && this.__meta.isTechnicalAttributesEnabled == 'true'){
                    if(me.__recordInformation.tabPanel.items.length >= 2){}else{
                    	this.__details = null;
                    	this.__details = SVMX.create("com.servicemax.client.installigence.recordDetails.RecordDetails", {
                			flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
               				 parentPanelContext: recordInformation, tree:ibtree
            			});
            			me.__recordInformation.tabPanel.add(this.__details);
            		}
                    me.__details.__findTemplate(nodes);
                }else{
                    me.__recordInformation.tabPanel.remove(me.__details);
                }
        		this.fireEvent("node_selected", nodes);
        	}, this);
        	
    		/*var documents = SVMX.create("com.servicemax.client.installigence.documents.Documents", {
    			flex: 1, margin: '2 3 0 0', collapsible:true, collapseDirection:'left'
    		});
    		
    		var topography = SVMX.create("com.servicemax.client.installigence.topography.Topography", {
    			flex: 1, margin: '2 7 0 4', collapsible:true, collapseDirection:'right'
    		});
    		
    		var configuration = SVMX.create("com.servicemax.client.installigence.configuration.Configuration", { 
    			flex: 1, margin: '0 7 0 2', collapsible:true, collapseDirection:'right'
    		});*/
    		
    		 var recordInformation = SVMX.create("com.servicemax.client.installigence.recordInformation.RecordInformation", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                tree : ibtree, meta : this.__meta,layout: 'fit'
            });
             this.__recordInformation = recordInformation;
             //overview.
             var record = SVMX.create("com.servicemax.client.installigence.record.Record", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                tree : ibtree, meta : this.__meta, parentPanelContext: recordInformation
            });
             //details.
             this.__details = SVMX.create("com.servicemax.client.installigence.recordDetails.RecordDetails", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                parentPanelContext: recordInformation, tree:ibtree
            });
             
             recordInformation.tabPanel.add(record);
             //recordInformation.tabPanel.add(this.__details); // defect #035443.
             recordInformation.tabPanel.setActiveItem(0)
    		
            var mashup = SVMX.create("com.servicemax.client.installigence.mashups.Mashups", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px', hidden : true
            });
	
        	config = Ext.apply({
        		cls: 'mid-panels-container',
				style: 'border-width: 0 !important;',
				layout: {
					type: 'hbox',
					align: 'stretch'
				},
				items:[
				       {
						xtype: 'container', width: '100%',
						layout: { type: 'vbox', align: 'stretch' },
						items: [{
							xtype: 'container', flex: 1,
							layout: { type: 'hbox', align: 'stretch' },
							items: [ibtree, recordInformation, mashup/*configuration*/]
						}/*,{
							xtype: 'container', flex: 1,
							layout: { type: 'hbox', align: 'stretch' },
							items: [documents, topography]
						}*/]
					}
				]
            }, config || {});
        	
        	this.__ibtree = ibtree;
            this.__record = record;
            this.__mashUp = mashup;
        	this.setup();
            this.callParent([config]);
        },
        
        addToTree : function(children, parent, type){
            this.__ibtree.addToTree(children, parent, type);
        },

        addClonedToTree : function(record, cloned, type, cascade){
            this.__ibtree.addClonedToTree(record, cloned, type, cascade);
        },

        deleteFromTree : function(node){
            this.__ibtree.deleteFromTree(node);
        },
        
        refreshContent : function(params){
        	this.__ibtree.refreshContent(params);
        },

        refreshRecord : function(){
            this.__record.refreshData();
        },

        selectTreeNode : function(recordId){
            this.__ibtree.selectTreeNode(recordId);
        },
        
        setup : function() {
            this.__meta.bind("MODEL.UPDATE", function(evt){
                this.refresh(evt);
            }, this);
        },
        
        refresh : function(data) {
        	var me = this;
            if(data.target.isTechnicalAttributesEnabled == 'true'){
            	if(this.__recordInformation.tabPanel.items.length >= 2){}else{
            		this.__recordInformation.tabPanel.add(this.__details);
            	}
            }else{
            	this.__recordInformation.tabPanel.remove(this.__details);
            }
        },

        openCustomURL : function(preparedurl, actionName){
            if(this.__mashUp){
                this.__mashUp.__urlToLoad = preparedurl;
                this.__mashUp.__title = actionName;
                
                //Ext.getCmp("TestURLId").autoEl.src = preparedurl;
                this.__mashUp.setVisible(true); 

                 var frame = Ext.getCmp('TestURLId'); 
                 if(frame && frame.rendered ){ 
                    frame.getEl().dom.src = preparedurl;//"http://it.wikipedia.org/wiki/Robot"; 
                 }

            }
            if(this.__record){
                this.__record.setVisible(false); 
            }
        }
    });
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\documents.js
/**
 * 
 */

(function(){
	
	var documentsImpl = SVMX.Package("com.servicemax.client.installigence.documents");

documentsImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.documents.Documents", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.documents',
        
        constructor: function(config) {	
        	config = Ext.apply({
        		title: 'Documents',
				cls: 'image-holder',
				listeners: {
					collapse: function () {
					   this.up().doLayout();
					},
					expand: function () {
					   this.up().doLayout();
					}
				},
				items:[{
					xtype: 'image',								
					src: 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy1.jpg'
				}]
            }, config || {});
            this.callParent([config]);
        }
    });
	
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\filters.js
/**
 * 
 */

(function(){
    
    var filtersImpl = SVMX.Package("com.servicemax.client.installigence.filters");

filtersImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.filters.Filters", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.filters',
        meta : null,
        __checkedIndex : null,
        
        constructor: function(config) { 
            this.meta = config.meta || [];
            this.__checkedIndex = {};
            
            config = Ext.apply({
                title: $TR.__getValueFromTag($TR.FILTERS,'Filters'),
                ui: 'svmx-white-panel',
                cls: 'filter-region',
                layout : {type : "vbox"},
                defaults : {padding : '0 0 0 5'}
            }, config || {});
            this.callParent([config]);
            this.setup();
        },
        
        setup : function(){
            this.meta.bind("MODEL.UPDATE", function(evt){
                this.refresh();
            }, this);
        },

        refresh : function(){
            this.removeAll();
            if(!this.meta.filters || !this.meta.filters.length){
                return;
            }
            var me = this;
            var i, l = this.meta.filters.length;
            for(i = 0; i < l; i++){
                var filter = this.meta.filters[i];
                var filterName = filter.name;
                var cb = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                    boxLabel : filterName,
                    filterExpression : filter.expression,
                    inputValue : i,
                    value : me.__checkedIndex[filterName],
                    handler : function(){
                        // Index checked state so that it can be restored
                        me.__checkedIndex[this.boxLabel] = this.value;
                        me.__fireFiltersSelected();
                    }
                });
                this.add(cb);
            }
            // TODO: handle incremental state updates?
        },

        __fireFiltersSelected : function(){
            var selectedExprs = [];
            var i, l = this.items.getCount();
            for(var i = 0; i < l; i++){
                var item = this.items.getAt(i);
                if(item.checked){
                    selectedExprs.push(item.filterExpression);
                }
            }
            this.fireEvent("filters_selected", selectedExprs);
        }
    });
    
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\findandget.js
/**
 * 
 */

(function(){
    
    var findandgetImpl = SVMX.Package("com.servicemax.client.installigence.findandget");

findandgetImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.findandget.FindAndGet", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.findandget',
        cls : 'installigence-findandget',
        meta : null, root: null, grid : null, __params : null, __searchStatus : null, __inited : null, 
        __config : null, __fieldsMap : null, __objectInfo : null, __config : null, __store : null,
        
        constructor: function(config) { 
        	
        	this.__inited = false;
			
            this.meta = config.meta;
            this.root = config.root;
            var me = this;
            this.__init();           
            this.meta.bind("MODEL.UPDATE", function(evt){
            	
                this.__init(); 
                //this.__initComplete();
            }, this);
            config = Ext.apply({
                title: '<span class="title-text">' + $TR.__getValueFromTag($TR.PRODIQ001_TAG027,'Find & Get') +'</span>',
                titleAlign: 'center', 
                // frame: 'true',
                collapsible : false,
                // style: 'margin:10px',
                // height : SVMX.getWindowInnerHeight() - 40,
                height : SVMX.getWindowInnerHeight() - 2,
                toolPosition: 0,
                tools: [{
                    type:'backbtn',
                    cls: 'svmx-back-btn',
                    handler: function(e, el, owner, tool){          
                        me.__handeNavigateBack();       
                    }
                }],
                layout: "fit",
                border : false,
                items : this.__getUI(),
                dockedItems : this.__getDockedUI()
            }, config || {});
            this.callParent([config]);            
        },
		
		__init : function(){
			var syncService = SVMX.getClient().getServiceRegistry()
    		.getService("com.servicemax.client.installigence.sync").getInstance(), me = this;
			syncService.getSObjectInfo(SVMX.getCustomObjectName("Installed_Product"))
			.done(function(info){
				me.__objectInfo = info;
				me.__fieldsMap = {};
				var i = 0,l = info ? info.fields.length : 0;
				for(i = 0; i < l; i++){
					if(info.fields[i].name == "Id") info.fields[i].label = "Id";
					me.__fieldsMap[info.fields[i].name] = info.fields[i]
				}				
				me.__initComplete();
			});
		},
		
		__getDisplayColumns : function(){
			var columns = [];
            var INSTALLED_PRODUCT_ID_LABEL = $TR.__getValueFromTag($TR.PRODIQ001_TAG040,'Installed Product ID');
			var displayColumns = this.meta.ibDisplayFields && this.meta.ibDisplayFields.length > 0 ? this.meta.ibDisplayFields : [{name: "Name", priority: "1"}];			
			if(this.__fieldsMap && this.__fieldsMap["Name"]){
				var i = 0, l = displayColumns.length;
				for(i = 0; i < l; i++){
					columns.push(this.__fieldsMap[displayColumns[i].name].label);
				}
			}else
				columns.push(INSTALLED_PRODUCT_ID_LABEL);
			if(columns.indexOf("Id") < 0){
				columns.push("Id");
			}
			return columns;
		},
		
		__getAPIColumns : function(){
			var dispcolumns = 
					this.meta.ibDisplayFields && this.meta.ibDisplayFields.length > 0 ? this.meta.ibDisplayFields : [{name: "Name", priority: "1"}];			
			var columns = [],i , l = dispcolumns.length;
			for(i = 0; i < l ; i++){
				columns.push(dispcolumns[i].name);
			}
			if(columns.indexOf("Id") < 0){
				columns.push("Id");
			}
			return columns;
		},
		
		__getSearchColumns : function(){
			var searcolumns = 
				this.meta.ibSearchFields && this.meta.ibSearchFields.length > 0 ? this.meta.ibSearchFields : [{name: "Name", priority: "1"}];			
			var columns = [],i , l = searcolumns.length;
			for(i = 0; i < l ; i++){
				columns.push(searcolumns[i].name);
			}
			return columns;
		},		
		
		__initComplete : function(){
			this.__inited = true;
			var dispcolumns = this.__getDisplayColumns();
            var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                fields: dispcolumns,
                data:[]
            });
            this.__store.fields = dispcolumns;
            var i = 0, l = dispcolumns.length, columns = [];
            for(i = 0; i < l; i++){
            	if(dispcolumns[i] == "Id") continue;
            	columns.push({text: dispcolumns[i],  dataIndex: dispcolumns[i], flex: 1 });
            }
            this.grid.columns = columns; 
            this.grid.reconfigure(this.__store, columns);
		},
        
        __getDockedUI : function(){
            var me = this;
            
            // search
            var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                width: '25%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'), enableKeyEvents : true,
                listeners : {
                    keyup : function(that, e, opts) {
                        if(e.getKey() == e.ENTER){
                            me.find(this.getValue(), findBtn.actionId);
                        }
                    }
                }
            });
            
            // find button
            var findBtn = null;
            findBtn = SVMX.create('Ext.button.Split', {
                text: $TR.__getValueFromTag($TR.PRODIQ001_TAG035,'Find by Top-Level IB'), actionId : "FIND_BY_IB", 
                handler: function() {
                    me.find(searchText.getValue(), this.actionId);
                },
                __update : function(item){
                    this.setText(item.text);
                    this.actionId = item.actionId;
                    this.handler();
                },
                menu: SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    cls: 'findget-filter-findbytoplevel-menu',
                    showSeparator : false,
                    items: [
                        {actionId : "FIND_BY_IB", text: $TR.__getValueFromTag($TR.PRODIQ001_TAG035,'Find by Top-Level IB'), handler: function(item){  findBtn.__update(item); }},
                        {actionId : "FIND_BY_TEMPLATE", disabled : true, text: $TR.__getValueFromTag($TR.PRODIQ001_TAG036,'Find By Template'), handler: function(item){  findBtn.__update(item); }},
                        {actionId : "FIND_BY_PRODUCT", disabled : true, text: $TR.__getValueFromTag($TR.PRODIQ001_TAG037,'Find By Product'), handler: function(item){  findBtn.__update(item); }}
                    ]
                })
            });
            
            this.__searchStatus = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXDisplayField", {});
            
            var items = 
            [
                {dock: 'top', xtype: 'toolbar', margin: '0',cls:'findget-toolbar-search',
                items:[ 
                        searchText,
                        findBtn,
                        this.__searchStatus,
                        '->',
                        { xtype: 'button', text: $TR.__getValueFromTag($TR.PRODIQ001_TAG038,'Get'), handler : function(){
                            me.getIBs();
                        }}
                ]}
            ];
            
            return items;
        },
        
        findLMIBs : function(){
            this.root.blockUI();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_LM_TOP_LEVEL_IBS", this, {request : { context : this, ids: [], params : this.__params}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onGetLMTopLevelIBsComplete : function(results){
            this.root.unblockUI();
            var actionId = "FIND_BY_IB";
            if(results.length > 0){
                this.find("", actionId, results, true);
            }else if(this.__findingLMIBs){
                this.getIBs();
            }
        },      
        
        getIBs : function(){
            var selectedRecords = this.grid.getSelectionModel().getSelection();
            // Should continue to sync if findingLMIBs, even with no IBs
            if(!this.__findingLMIBs && selectedRecords.length == 0) return;
            
            var ids = [], i, l = selectedRecords.length;
            for(i = 0; i < l; i++){
                ids.push(selectedRecords[i].getData().Id);
            }
            
            this.root.blockUI();
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();
            
            var p = {
                IBs : ids,
                type : this.__params ? this.__params.syncType : "ib"
            };
            
            syncService.start(p);
        },

        resetLocalIBs : function(){
            this.root.blockUI();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_TOP_LEVEL_IBS", this, {request : { context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);    
        },

        onGetTopLevelIBsComplete : function(data){
            var ids = [];
            for(var i = 0; i < data.ibs.length; i++){
                var id = data.ibs[i].Id;
                if (id.indexOf('transient-') === 0) continue;
                ids.push(id);
            }
            var p = {
                IBs : ids,
                type : "reset"
            };
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.start(p);
        },
        
        handleFocus : function(params){
            var me = this;
            this.__params = params;
            this.grid.getStore().loadData([]);
            this.__searchStatus.setValue("");
            if(params && (params.syncType === "initial" || params.syncType === "reset")){
                this.__checkLaptopMobileExists()
                .done(function(exists){
                    if(exists){
                        // Trigger auto start if LM exists
                        me.__findingLMIBs = true;
                    }
                    me.findLMIBs();
                });
            }
        },

        __checkLaptopMobileExists : function(){
            var d = SVMX.Deferred();
            var request = {
                appName : "LaptopMobile"
            };
            // var req = com.servicemax.client.installigence.offline.sal.model.nativeservice.Facade.createCheckExternalRequest();
            var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
            var req = nativeservice.createCheckExternalRequest();

            req.bind("REQUEST_COMPLETED", function(evt){
                var appinfo = evt.data.data;
                var app = SVMX.toObject(evt.data.data);
                d.resolve(app[0].Installed === "true");
            }, this);
            req.bind("REQUEST_ERROR", function(evt){
                d.resolve({});
            }, this);
            req.execute(request);
            return d;
        },
        
        find : function(text, action, locationIds, selectAll){
            this.root.blockUI();
            if(this.__inited == false){ this.__init();}
            else {
            	var fieldDescribe = this.__fieldsMap && this.__fieldsMap["Name"] ? 
            			this.__fieldsMap : {Name: {label: $TR.__getValueFromTag($TR.PRODIQ001_TAG040,'Installed Product ID'), type: "text"}, Id : {label: "Id", type: "text"}};
            	
            	var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "INSTALLIGENCE." + action, this, {request : { context : this, text : text, 
                        	params : this.__params, locationIds : locationIds, selectAll : selectAll,
                        	fields : this.__getAPIColumns(), searchFields : this.__getSearchColumns(), fieldsDescribe : fieldDescribe}});
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            }
            
        },
        
        onSearchByIBComplete : function(results){
            this.root.unblockUI();
            this.__searchStatus.setValue(
                    results.data.length + ( results.hasMoreRecords ? "+" : "") + " record(s) found.");

            this.grid.getStore().loadData(results.data);
            if(results.selectAll || this.__findingLMIBs){
                var sm = this.grid.getSelectionModel();
                sm.selectAll(false);
            }
            
            // auto get IBs when triggered from LM
            if(this.__findingLMIBs){
                this.getIBs();
                delete this.__findingLMIBs;
            }
        },

        onSearchByIBError : function(){
            this.root.unblockUI();
        },
        
        __getUI : function(){
            var items = [];
            var dispcolumns = this.__getDisplayColumns();
            var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                fields: dispcolumns,
                data:[]
            });
            this.__store = store;
            var i = 0, l = dispcolumns.length, columns = [];
            for(i = 0; i < l; i++){
            	if(dispcolumns[i] == "Id") continue;
            	columns.push({text: dispcolumns[i],  dataIndex: dispcolumns[i], flex: 1 });
            }
            
            this.grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
                store: store,
                border : false,
                selModel: {selType : 'checkboxmodel', renderer : function(value, metaData, record, rowIndex, colIndex, store, view){
                    if(false && record.get('availableInDB')){
                        return '';
                    }else{
                        return '<div class="x-grid-row-checker installigence-findget-grid-column" role="presentation">&#160;</div>';
                    }
                }, listeners : { beforeselect : function( that, record, index, eOpts ){
                    return true;//!record.get('availableInDB');
                }}, 
                checkOnly : true},
                columns: columns,
                height: "100%",
                cls:"findget-grid",
                width: "100%",
                scroll: "vertical",
                viewConfig : {   
                    getRowClass: function(record, index) {
                        if (record.get('availableInDB')) {
                            return 'svmx-disabled-row';
                        }
                    }
                }
            });
            
            items.push(this.grid);
            return items;
        },
        
        __handeNavigateBack : function(){
            this.root.handleNavigateBack();
        }
    });
    
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\home.js
/**
 * 
 */

(function(){
    
    var homeImpl = SVMX.Package("com.servicemax.client.installigence.home");

homeImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.home.Home", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.home',
        meta : null, root : null,
        __contentArea : null,
        __actions : null,
        __menu : null,
        
        constructor: function(config) { 
            
            this.meta = config.meta;
            this.root = config.root;
            this.__setSelectedAccountId();
            
            /*
            var filters = SVMX.create("com.servicemax.client.installigence.filters.Filters", {
                region: 'west', collapsed: true, collapsible: true, split: false, width: 200, meta : this.meta
            });
			*/
            
            var contentarea = SVMX.create("com.servicemax.client.installigence.contentarea.ContentArea", {
                region: 'center', collapsible: false, floatable: false, split: false, meta : this.meta, root : this.root
            });
            
            var actions = SVMX.create("com.servicemax.client.installigence.actions.Actions", {
                region: 'east', collapsed: false, split: false, width: 200, floatable: true, meta : this.meta,
                contentarea : contentarea
            });
            
           var toolBarItems = SVMX.create("com.servicemax.client.installigence.ibToolBar.ToolBarItems", {
                region: 'north', margin: '0 0 0 0',cls:'ibtoolbar-home-account-filter', collapsed: false, split: false, height:50, floatable: true, meta : this.meta,
                contentarea : contentarea
                
            });

            // Prevent context menu
           /* Ext.getDoc().on('contextmenu', function(e){
               e.preventDefault();
            });*/

            var me = this;
            config = Ext.apply({
                //title: '<span class="title-text">ProductIQ</span> <div class="logo img"/></div> <div class="logo spinner" style="background-image: none"/></div>',
                //titleAlign: 'center', 
                // frame: 'true',
                collapsible : false,
                // style: 'margin:10px',
                // height : SVMX.getWindowInnerHeight() - 40,
                height : SVMX.getWindowInnerHeight() - 2,
                
                layout: {
                    type: 'border'
                    // padding: '3'
                },
                defaults: {
                    collapsible: true,
                    split      : true
                },
                //items : [ contentarea, actions ]
                items : [ contentarea, toolBarItems ]
            }, config || {});

            if(!SVMX.getCurrentApplication().isAppEmbedded()) {
                config = Ext.apply({
                    title: '<span class="title-text">ProductIQ</span> <div class="logo img"/></div> <div class="logo spinner" style="background-image: none"/></div>',
                    titleAlign: 'center', 
                    toolPosition: 0,
                    tools: [{
                        type:'hamburger',
                        cls: 'hamburger',
                        handler: function(e, el, owner, tool){
                            
                            if(!me.__showingMenu){
                                me.__showingMenu = true;
                                me.getMenu(owner).showBy(owner,'tl-bl?');
                            }else{
                                me.__showingMenu = false;
                                me.getMenu(owner).hide();
                            }
                        }
                    }]
                }, config || {});
            }
            
            this.__contentArea = contentarea;
            this.__actions = actions;

            this.__bindSyncEvents();

            this.callParent([config]);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.bind("SYNC.STATUS", function(evt){
                var status = evt.data.type;
                var message = evt.data.msg;
                var syncType = evt.data.syncType;
                if(status === "start"){
                    this._disableMenuItem($TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'));
                }else if(status === "complete" || status === "canceled"){
                    this._enableMenuItem($TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'));
                }
            }, this);
        },
        
        getMenu : function(){
            var me = this;
            if (!me.__menu) {
                me.__menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    cls: 'svmx-nav-menu',
                    plain: true,
                    height: '80%',
                    items: [
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG027,'Find & Get'), handler : function(){
                                me._handleFindAndGet({syncType : "ib"});
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG048,'Sync Configuration'), handler : function(){
                                me._handleConfigSync();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'), handler : function(){
                                me._handleIncrementalSync();
                            }},
                            // TODO: $TR.SYNC_CONFLICTS
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG099,'Sync Conflicts'), handler : function(){
                                me._showSyncConflicts();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG095,'Purge Data'), handler : function(){
                                me._handlePurgeSync();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG051,'Reset Application'), handler : function(){
                                me._handleResetApplication();
                            }}
                    ]
                });
            }
            return me.__menu;
        },

        _disableMenuItem : function(menuText){
            var items = this.getMenu().items.items;
            for(var i = 0; i < items.length; i++){
                if(items[i].text === menuText){
                    items[i].disable();
                    break;
                }
            }
        },

        _enableMenuItem : function(menuText){
            var items = this.getMenu().items.items;
            for(var i = 0; i < items.length; i++){
                if(items[i].text === menuText){
                    items[i].enable();
                    break;
                }
            }
        },
        
        _handleResetApplication : function(){
            this.root.handleResetApplication();
        },
        
        _handleFindAndGet : function(){
            this.root.handleFindAndGet();
        },

        _handleConfigSync : function(){
            this.root.handleConfigSync();
        },

        _handleIncrementalSync : function(){
            this.root.handleIncrementalSync();
        },

        _handlePurgeSync : function(){
            this.root.handlePurgeSync();
        },

        _showSyncConflicts : function(){
            this.root.showSyncConflicts();
        },
        
        handleFocus : function(params){
            this.__contentArea.refreshContent(params);
        },

        selectTreeNode : function(recordId){
            this.__contentArea.selectTreeNode(recordId);
        },

        __setSelectedAccountId : function() {
            var me = this;
            SVMX.getClient().bind("ACCOUNT_ID_MESSAGE", function(evt){
                var data = SVMX.toObject(evt.data);
                if (data.accountId) { 
                    me.meta.accountId = data.accountId;
                }
            });
        } 
    });
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\ibSearch.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\ibswap.js
/**
 * @class com.servicemax.client.installigence
 * @author Amar Joshi
 * @since       : 1.0
 * @copyright 2015 ServiceMax, Inc.
 */

(function(){
    
    var ibSwapImpl = SVMX.Package("com.servicemax.client.installigence.ibswap");

    ibSwapImpl.init = function(){

        Ext.define("com.servicemax.client.installigence.ibswap.IBSwap", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            alias: 'widget.installigence.ibswap',
            __sourceComponent : null,
            __parentComponent : null,
            __meta : null,
            __ibtree : null,
            __record : null,
            __ibSwapIBTree : null,
            __ibSwapTreeData : null,
            __treeDataById : null,
            __expandedById : null,
           __productIconIndex : {},
           __selectedNode : null,
           __treeStore : {},
           __newSerialNoById : {},
           __ibRecord : null,
           __requiredFields : null,
           __fields : null,
           __recordName : null,
           __dataValidationRules : null,
           __ibRecordById : null,
           __win : null,

            constructor: function(config) { 
                var me = this;
                this.__sourceComponent = config.source;
                this.__parentComponent = config.parent;
                this.__meta = this.__parentComponent.__meta
                this.__ibtree = this.__parentComponent.__contentarea.__ibtree;
                this.__record = this.__parentComponent.__contentarea.__record;
                this.__treeDataById = SVMX.cloneObject(this.__ibtree.__treeDataById);
                this.__treeStore = {};
                this.__ibRecord = this.__record.__views[0];
                this.__requiredFields = this.__ibRecord.__pl.__requiredFields;
                this.__fields = this.__ibRecord.__pl.fields;
                this.__recordName = this.__ibRecord.__pl.__recordName;
                this.__dataValidationRules = this.__ibRecord.__pl.__dataValidationRules;
                this.__ibRecordById = {};
                
            },

            __openProductLookup : function(){
                var parentNode;// = this._context[0];
                var displayFields = this.__meta.productDisplayFields || [];
                var searchFields = this.__meta.productSearchFields || [];
                var productSearch = SVMX.create("com.servicemax.client.installigence.objectsearch.ObjectSearch", {
                    objectName : "Product2",
                    columns : displayFields.length ? displayFields : [{name: 'Name'}],
                    searchColumns : searchFields.length ? searchFields : [{name: 'Name'}],
                    multiSelect : false,
                    sourceComponent : this.__sourceComponent,
                    mvcEvent : "FIND_PRODUCTS",
                    fromIBSwap : true
                });
                var me = this;
                productSearch.find().done(function(results){
                    //To do :
                    // Update the Product Id in treeData Store.
                });
            },

            getFilterExpressions : function(){
                return this.__ibtree.getFilterExpressions();
            },

            getChildIBs : function(parentIB){
                this.__selectedNode = this.__treeDataById[parentIB];
                SVMX.getCurrentApplication().blockUI();
                var objectName = SVMX.getCustomObjectName("Installed_Product");
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_ALL_CHILD_IBS", this, {request : { context : this, targetId : parentIB, objectName : objectName, handler : this.__onChildIBCompleate}});
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            },


            __onChildIBCompleate : function(data){
               var me = this;
               // 1) Create all the nodes
               var ibsById = {};
               this.__ibRecordById = {};
                if(data){
                    for(var i = 0; i < data.length; i++){
                        var record = data[i];
                        this.__ibRecordById[record.Id] = record;
                        var parentId, parentType;
                        if(record[SVMX.getCustomFieldName("Parent")]){
                            parentId = record[SVMX.getCustomFieldName("Parent")];
                            parentType = "IB";
                        }else {
                            continue;
                        }
                        var ibNode = {
                            id : record.Id,
                            text : record.Name || ("(IB) "+record.Id),
                            icon : me.__getIconFor(record, "IB"),
                            children : [],
                            nodeType : "IB",
                            recordId : record.Id,
                            serialNo : record[SVMX.getCustomFieldName("Serial_Lot_Number")],
                            isSwapped : record[SVMX.getCustomFieldName("IsSwapped")],
                            parentId : parentId,
                            parentType : parentType,
                            expanded : true,
                            collapsible : true
                        };
                        ibsById[record.Id] = ibNode;
                    }
                }

               // 2) Assemble the hierarchy
                var ibsByIdToBeRemoved = {};
                for(var key in ibsById){
                    var node = ibsById[key];
                    if(node.parentType === "IB" && ibsById[node.parentId]){
                        ibsById[node.parentId].children.push(node);
                        ibsByIdToBeRemoved[node.id] = node;
                    }else{
                        warnParentInvalid(node);
                    }
                }
                for(var key in ibsByIdToBeRemoved){
                    delete ibsById[key];
                }
                var topNode = this.__selectedNode;
                topNode.collapsible = true;
                topNode.expanded = true;
                topNode.children = [];
                for(var key in ibsById){
                    var node = ibsById[key];
                    topNode.children.push(node);
                }
                var root = {}; 
                root.children = [], root.expanded = true, root.collapsible = true;
                root.children.push(topNode);
                var treeDate = {root : root};
                
                me.__getUI(treeDate);
                
                function warnParentInvalid(node){
                    console.warn('Tree structure invalid: Location '+node.id+' parent '+node.parentType+' '+node.parentId+' not found');
                }
            },

            __getUI : function(treeData){
                SVMX.getCurrentApplication().unblockUI();
                this.__ibSwapTreeData = treeData;
                var me = this;
                var treeStore = Ext.create('Ext.data.TreeStore', { root : treeData.root });
                this.__treeStore = treeStore;
                this.__expandedById = {};
                var cellEditing = Ext.create('Ext.grid.plugin.CellEditing', { clicksToEdit: 1 });

                this.__ibSwapIBTree =  SVMX.create("com.servicemax.client.installigence.ui.components.Tree", {
                    
                    cls: 'grid-panel-borderless svmx-tree-panel', margin: '5 0 0 0', width: '100%', store: this.__treeStore, flex : 1,
                    useArrows: true, rootVisible: false, multiSelect: false, collapsed: false,
                    plugins:[cellEditing], 
                    selModel: {
                        selType: 'checkboxmodel',
                        mode: 'SIMPLE'
                    },   
                    columns: [
                        {
                            xtype: 'treecolumn',
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG066,'Product'),
                            dataIndex: 'text',
                            width : '25%'
                        },
                        {
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG105,'Serial/Lot Number'),
                            dataIndex: 'serialNo',
                            width : '25%',
                            editor: {
                                xtype : "textfield"
                            }    
                        },
                        {
                            renderer: function(value, md, record, row, col, store) {
                                return '<a class="change-link" href="#">Change</a>';
                            }
                        },
                        
                    ],
                    listeners : {
                        select : function(that, record, index, eOpts){
                             Ext.defer(function() {
                                    cellEditing.startEdit(index, 2);
                                }, 100, this);
                        },
                        checkchange : function(node, checked, eOpts){
                            
                        },
                        afteritemexpand : function(node, index, item, eOpts) {
                        },
                        afteritemcollapse : function(node, index, item, eOpts) {
                                           
                        },
                        cellclick: function(grid, row, col, e) {
                            if (col === 3) {
                                me.__openProductLookup();
                            }
                        }
                    }
                });
                
                this.__win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                    layout : {type : "vbox"}, height : "100%", width : "100%",
                    title : $TR.__getValueFromTag($TR.PRODIQ001_TAG102,'Component Replacement'),
                    maximizable : true,
                    items : [this.__ibSwapIBTree],
                    modal : true,
                    buttons : [
                        {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'), handler : function(){
                                this.__win.close();
                        }},
                        {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG104,'Update'), handler : function(){
                            SVMX.getCurrentApplication().blockUI();
                           me.__performIBSwap();
                        }},
                    ]
                });
                this.__win.show();
            },

            __performIBSwap : function(){
                var d = SVMX.Deferred(), me =  this;
                this.__newSerialNoById = {};
                var seletedIBsForSwap = [];
                var IBs = [];
                var selectedRows = this.__ibSwapIBTree.getSelectionModel().getSelection();
                if(selectedRows !== undefined || selectedRows.length > 0){
                    for(var i = 0; i < selectedRows.length; i++){
                        var node = selectedRows[i].data;
                        if(node.serialNo === undefined || node.serialNo === null || node.serialNo === ""){
                            IBs.push(node.text);
                        }
                        else{
                            this.__newSerialNoById[node.recordId] = node.serialNo;
                            seletedIBsForSwap.push(node.recordId)
                        }
                    }
                    if(IBs.length > 0){
                        SVMX.getCurrentApplication().showQuickMessage("error", "Please enter serial no for: "+IBs.toString());
                    }
                    else{
                        // First Swap(clone) selected records 
                         var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "INSTALLIGENCE.CLONE_MULTIPLE_RECORDS", this, {
                            request : {
                                context : this,
                                recordIds : seletedIBsForSwap,
                                objectName : SVMX.getCustomObjectName("Installed_Product")
                                
                            }
                        });
                        com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
                    }    
                }
                
            },

            onCloneComplete : function(){
                var records = [];
                for(var key in this.__newSerialNoById){
                    var record = this.__ibRecordById[key];
                    var serialNo = SVMX.getCustomFieldName("Serial_Lot_Number");
                    for(var field in record){
                        if(field === serialNo){
                            record[field] = this.__newSerialNoById[key];
                        }
                    }
                    records.push(record);
                }
                //Update Exsisting Records
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.SAVE_MULTIPLE_RECORDS", this, {
                        request : { context : this, requiredFields : this.__requiredFields, objectName: SVMX.getCustomObjectName("Installed_Product"), meta : this.__fields, records : records, recordName : this.__recordName, root : this.__record, handler : this.onSaveComplete, dataValidationRules : this.__dataValidationRules}
                });
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            },

            onSaveComplete : function(){
                SVMX.getCurrentApplication().unblockUI();
                this.__win.close();
                this.__ibtree.refreshContent();
            },

            __getIconFor : function(record, type){
                switch(type){
                    case "IB":
                        var ibId = record[SVMX.getCustomFieldName("Top_Level")]
                            || record.Id;
                        var ibIndex = this.__productIconIndex[ibId];
                        var productId = record[SVMX.getCustomFieldName("Product")];
                        if(ibIndex && ibIndex[productId]){
                            // TODO: use native client method to get download path
                            var iconName = ibIndex[productId];
                            var iconPath = "C:/ProgramData/ServiceMax/ProductIQ/Downloads/"+iconName;
                            return iconPath;
                        }
                        return "modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon1.png";
                    default:
                        var defaultIcons = {
                            'LOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png',
                            'SUBLOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png',
                            'ACCOUNT' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png'
                        };
                        return defaultIcons[type];
                }
            },

        });    
    }
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\ibToolBar.js
/**
 * This file creates the toolbar items like search, action and filter.
 * @class com.servicemax.client.insralligence.src.ui.toolbar.js
 * @author Madhusudhan HK
 *
 * @copyright 2015 ServiceMax, Inc.
 **/

(function(){

	var toolBarImpl = SVMX.Package("com.servicemax.client.installigence.ibToolBar");

	toolBarImpl.init = function(){
		Ext.define("com.servicemax.client.installigence.ibToolBar.ToolBarItems",
			{
				extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
               alias: 'widget.installigence.ibToolBar',width:'100%',

               __meta: null,
               __contentarea: null,
               __installbaseSearch: null,
               __popup: null,
               
                constructor: function(config) {
						var me = this;
                        this.__contentarea = config.contentarea;
                        this.__meta = config.meta;
                        var actions = SVMX.create("com.servicemax.client.installigence.actions.Actions", {
                            region: 'east', collapsed: false, split: false, cls: "ibtoolbar-action-panel", style: 'border:0px;text-align:right', floatable: true, meta : this.__meta,
                            contentarea : this.__contentarea, width : '89%'
                        });
						
                        config = Ext.apply({
                        
                        ui: 'svmx-white-panel',
                        cls: 'filter-region',
                        layout : {type : "hbox"},
                        defaults : {padding : '0 5 0 0'},
                        items : [ 
                        /*{ xtype: 'button', 
                                    iconCls: 'filter-icon',
                                    margin: '9 20 20 20', //TODO. Relative margion has to be applied here
                                    handler : function(){
                                       
                                       var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "FILTER_ACTION_CALL",
                                                             this);
                                        SVMX.getClient().triggerEvent(evt);


                                    }
                                },*/{ 
                                    xtype: 'button', 
                                    text : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'),
                                    cls: 'ibtoolbar-search-heading-btn',
                                    height: 30,
                                    width : '10%',
                                    textAlign : 'left',
                                    margin: '10',  
                                    handler : function(){
                                        
                                        //Ext.Msg.alert('Search', 'Implement search here.');
                						//me.__installbaseSearch = SVMX.create("com.servicemax.client.installigence.search.Search",{
                						//config : me.__meta.advanceSearch,mvcEvent : "SEACH_INSTALLBASE"});
            							//me.__installbaseSearch.find();
                                        
                                        if(me.__meta.advanceSearch  && me.__meta.advanceSearch.length > 0){
                                         	var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "IB_SEARCH_ACTION_CALL",
                                                             this);
                                        	SVMX.getClient().triggerEvent(evt);
                                            me.__triggerClearFilters();
                                            
                                            //Disabling PIQ back button button 
                                            var btn = window.parent.Ext.getCmp('piqComBackbtn');
                          					btn.hide();
                                        }else{
                                        	var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
												height: 150,
												width: 390,
												layout: 'fit',
												buttonAlign: 'center',
												closable: false,
												text : $TR.__getValueFromTag($TR.PRODIQ001_TAG121,'Search (SFM) is not configured for this profile.'),
												title : $TR.__getValueFromTag($TR.MSG,'Message'),
                                                textAlign : "display:inline-block;text-align:center"
											});
											evt.filterButtonAction(evt);
                                        	evt.show();
                                        } 
                                        
                                    }
                                },
                                // { xtype: 'button', 
                                //     text : 'Action',
                                //     width: 150,
                                //     height: 30,
                                //     margin: '-30 0 0 750', //TODO. Relative margion has to be applied here
                                      
                                //     handler : function(){
                                        
                                //         Ext.Msg.alert('Action', 'Implement Action here.');
                                //     }
                                // }
                                actions
                            ]
                        
                            } , config || {});

                         this.callParent([config]);

                },

                __triggerClearFilters : function() {

                    var data = {};
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event", "CLEAR_FILTERS_MESSAGE", this, data);
                    SVMX.getClient().triggerEvent(evt); 
                },

                filterButtonAction : function(){

                        
                },

                searchButtonAction: function(){

                        
                }    
			});
	}

})();

/* custom code for popup */
Ext.define('SVMX.alertPopup.message', {
    extend: 'com.servicemax.client.ui.components.controls.impl.SVMXWindow',
    alias: 'widget.installigence.ibToolBar',
    height: 150,
    width: 390,
    id: 'popup',
    layout: 'fit',
    buttonAlign: 'center',
    closable: false,
    text : 'No sfm search',
    title : 'Message',
    msglbl:null,
    parent:null,
    items: [
        {
            xtype: 'form',
            frame: false,
            border: 0,
            layout: {
                type: 'hbox',
                align: 'middle'
            },
            fieldDefaults: {
                msgTarget: 'side',
                labelWidth: 55
            },
            items: [
                {
                    xtype: 'container',
                    flex: 1,
                    padding: 2,
                    layout: {
                        type: 'vbox',
                        align: 'stretch'
                    },
                    items: [
                    	{
                        	xtype: 'label',
                        	itemId: 'msglblId',
                        	text : 'Search (SFM) is not configured for this profile',
                        	style: 'display:inline-block;text-align:center'
                    	}
                    ]
                }
            ],
            listeners: [
			]
        }
    ],
    buttons: [
        {
            text: 'ok',//$TR.__getValueFromTag($TR.PRODIQ001_TAG112,'OK'),
            itemId: 'okBtnId',
            listeners: {
        		click : function(b, e) {
             		parent.close();
             	}
       	 	}
        }
    ],
    closeme : function(me, title, bodyText){
    	parent = me;
    	title: title;
    	text: bodyText;
    }
});

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\ibtree.js
/**
 * 
 */

(function(){
    
    var ibtreeImpl = SVMX.Package("com.servicemax.client.installigence.ibtree");

ibtreeImpl.init = function(){
    
    /**
     * EVENTS:
     * 01. node_selected
     * 02. records_selected
     * 03. node_loaded
     */
    Ext.define("com.servicemax.client.installigence.ibtree.IBTree", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.ibtree',
        __meta : null,
        __tree : null,
        __treeData : null,
        __treeDataById : null,
        __expandedById : null,
        __searchText : null,
        __optionsPanel : null,
        __filterExpressions : null,
        __transientFilters : null,
        __allNodeFilters : null,
        __appliedNodeFilters : null,
        __productIconIndex : null,
        __transientRecordIndex : null,
        __locationsVisible : true,
        __swappedVisible : true,
        __selectedNodeId : null,
        //Below variables are required for selecting single account tree data at a time.
        __accountsMenubarButton : null,
        __selectedAccountName : null,
        __currentAccountId : null, //current account selected
        __selectedAccountId : null, //initial account selected
        __isAccountChanged : null, //used to track if account changed.
        __isWorkOrderFilterChecked : null, //used to track work order filter check status.
        __selectedWorkOrderFilterData : null,
        __dragEnabled : null,
        __root : null,
        __selectFromRegisterExternal : null,
        __IBReferenceINFO : null, //Storing all reference field value for IB
        __isDataSyncTriggerd : null, //to check weather data sync is trigger is not.

        resizable : true,
        
        constructor: function(config) { 
            var me = this;
            this.__productIconIndex = {}; //assign an empty object for this ivar.
            this.__isDataSyncTriggerd = false; //default value.
            //Add account drop down here.
            var accountMenuButton =  this.__createAccountMenubarWithButton(); 
            this.__isAccountChanged = false;
            this.__isWorkOrderFilterChecked = true;
            this.__selectFromRegisterExternal = false;
            this.__dragEnabled = false;
            this.__registerExternalRequest();
            this.__setAccountIdOnLaunch();
            this.__registerForFilterActionCall();
            this.__getAllTopLevelAccounts();
            this.__clearAllFiltersForIbSearch();
			this.__getIBReference();
            var store = Ext.create('Ext.data.TreeStore', {
                
            });

            // meta model
            this.__meta = config.meta;
            this.__root = config.root;
            this.__meta.bind("MODEL.UPDATE", function(evt){
                this.__refreshFilterOptions();
            }, this);

            // options panel
            /*var cbLocations = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox",{ 
                boxLabel : $TR.SHOW_LOCATIONS,
                checked : this.__locationsVisible,
                margin: '0 0 0 5',
                handler : function(){
                    me.__locationsVisible = this.value;
                    if(this.value){
                        me.showNodes('loc');
                    }else{
                        me.hideNodes('loc');
                    }
                }
            });
            var cbSwappedProducts = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox",{ 
                boxLabel : $TR.SHOW_SWAPPED_PRODUCTS,
                checked : this.__swappedVisible,
                margin: '0 0 0 5',
                handler : function(){
                    me.__swappedVisible = this.value;
                    if(this.value){
                        me.showNodes('swap');
                    }else{
                        me.hideNodes('swap');
                    }
                }
            });*/

            var filterOptions = this.__getFilterOptions();
            var optionPanelItems = filterOptions;/*.concat([
                cbLocations,
                cbSwappedProducts
            ]);*/
            this.__optionsPanel = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXPanel", {
                layout : {type : "vbox"}, cls: 'svmx-options-panel',
                items : optionPanelItems,
                header : false, collapsed : true, width : "100%", margin: '2 3 0 3'
            });
            
            // tree
            this.__expandedById = {};
            this.__tree = SVMX.create("com.servicemax.client.installigence.ui.components.Tree", {
                cls: 'grid-panel-borderless svmx-tree-panel', margin: '5 0 0 0', width: '100%', 
                store: store, rootVisible: false, flex : 1,
                viewConfig: {
                    plugins: {
                        ptype : 'treeviewdragdrop',
                        enableDrag : true,
                        enableDrop : true,
                        appendOnly : true,
						containerScroll : true
                    },
                    listeners : {
                        nodedragover : function(targetNode, position, dragData, e, eOpts){
                            return me.__canDropOn(dragData, targetNode);
                        },
                        beforedrop : function(node, data, overModel, dropPosition, dropHandlers, eOpts){
                             me.__dragEnabled = true;
                            return me.__handleDropOn(data, overModel, dropHandlers);
                        },
                        drop : function(){
                            
                        }
                    }
                },
                
                listeners : {
                    select : function(that, record, index, eOpts){
                        if(me.__selectedNodeId !== record.data.id){
                            me.__selectedNodeId = record.data.id;
                            me.fireEvent("node_selected", me.__treeDataById[record.data.id]);
                        }
                    },
                    checkchange : function(node, checked, eOpts){
                        // one more records may have been selected via checkbox. fire a different event
                        me.__fireRecordsSelected();
                    },
                    afteritemexpand : function(node, index, item, eOpts) {
                        var treeNode = me.__treeDataById[node.id];
                        if(treeNode){
                            treeNode.expanded = true;
                            // Ensure parents are expanded internally (even if filtered)
                            var parent = me.__treeDataById[treeNode.parentId];
                            while(parent){
                                parent.expanded = true;
                                var parent = me.__treeDataById[parent.parentId];
                            }
                            me.__expandedById[node.id] = true;
                        }
                        if(node.data.nodeType == "IB" && me.__dragEnabled === false) { 
                            setTimeout(function(){
                                me.__showMore({node : node});
                            },1);
                        }
                    },
                    afteritemcollapse : function(node, index, item, eOpts) {
                        var treeNode = me.__treeDataById[node.id];
                        if(treeNode){
                            treeNode.expanded = false;
                            me.__expandedById[node.id] = false;
                        }
                    }
                }
            });
            
            // search
            this.__searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                cls: 'toolbar-search-textfield', width: '90%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'), enableKeyEvents : true,
                listeners : {
                    keyup : function(that, e, opts) {
                        me.__tree.search(that.getValue());
                    }
                }
            });
            
            // Filter button with menu option.
            var filterMenu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain:true,
                    width: 250,
                    collapsible: false, floatable: false, split: false,
                    autoScroll:true

                });
            var filterButton = 
                            {   xtype : 'button', 
                                text : $TR.__getValueFromTag($TR.PRODIQ001_TAG124,'Filter'),
                                cls : 'ibtree-filter-btn',
                                menuAlign : 'tr-br',
                                menu :filterMenu,
                                region : 'west',
                                // width: 100, 
                                width : '35%',
                                // margin:  '-30 0 0 200',
                                textAlign : 'right',
                                layout : {
                                      align: 'right'
                                },

                                handler : function(){
                                                me.toggleOptions();
                                }
                          };

            this.__transientFilters = [];

            this.__setupNodeFilters();

            this.__bindSyncEvents();

            var toptoolbar = Ext.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                id: 'ttool',
                cls: 'ibtree-toolbar',
                style:'border-bottom: 1px solid #d7d7d7 !important;',
                width: '100%',
                items: [
                          accountMenuButton,  filterButton      
                ]        

            });
            
            config = Ext.apply({
                layout : {type : "vbox"},
                dockedItems : [
                    {dock: 'top', xtype: 'toolbar', cls: 'grid-panel-borderless svmx-ibtree-toolbar', style:'background-color: #fff', margin: '0',
                    /*items:[ this.__searchText,
                            { xtype: 'button', iconCls: 'filter-icon', handler : function(){
                                me.toggleOptions();
                            }}
                    ]*/}
                ],
                items:[toptoolbar,this.__optionsPanel,this.__tree]
            }, config || {});
            this.callParent([config]);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();

            syncService.bind("SYNC.STATUS", function(evt){
                var type = evt.data.type;
                if(type === "complete"){
                    var syncType = evt.data.syncType;
                    // Clear the account-menu items after initial sync.
                    if(syncType==="initial" && !SVMX.getCurrentApplication().isAppEmbedded()){
                         this.__selectedAccountId=null;
                         this.__currentAccountId=null;
                         this.__accountsMenubarButton.setText(' ');
                         this.__accountsMenubarButton.menu.items.removeAll();
                    }
                   
                    //Get top level IB's accounts only if synch completes for standalone app.
                    if (!this.__currentAccountId && !SVMX.getCurrentApplication().isAppEmbedded()) {
                        this.__getAllTopLevelAccounts();
                    }
                    
                    //if the sync type is purge then clear transiant filters. Defect - 016736
                    if(syncType === "purge" || syncType === "reset"){
                        this.deleteTransientFilters();
                        this.toggleOptions();
                    }
                    if(syncType === "incremental" || syncType === "purge" || syncType === "insert_local_records"){
                        this.__isDataSyncTriggerd = true;
                        this.refreshContent();
                    }
                }else if(type === "recordstatus"){
                    var recordId = evt.data.recordId;
                    var isTransient = !evt.data.valid;
                    this.setTreeNodeTransient(recordId, isTransient);
                    // Maintain the transient record index
                    var index = this.__transientRecordIndex.indexOf(recordId);
                    if(isTransient){
                        if(index === -1){
                            this.__transientRecordIndex.push(recordId);
                        }
                    }else{
                        if(index !== -1){
                            this.__transientRecordIndex.splice(index, 1);
                        }
                    }
                }
            }, this);
        },
        
        __registerExternalRequest : function(){
            SVMX.getClient().bind("EXTERNAL_MESSAGE", function(evt){
                var data = SVMX.toObject(evt.data);

                if (data.action === "SYNC" ) { //initiate initial sync once MFL app completes its sync.
                    if(data.operation === 'INITIAL' && !SVMX.getCurrentApplication().isAppEmbedded()) {
                        this.__root.handleFindAndGet({syncType : "initial"});
                    }
                    return;
                }

                if (data.recordIds === undefined) {
                    return;
                }
                var nodeId = data.recordIds[0];
                /*
                    if search is opened then trying to invoke wo from MFL. it was not getting refreshed. 
                    So close the search screen and invoke IB from MFL
                    Here cardIndex referes to IB Search screen.
                */
                if (this.__root.currentView.cardIndex === 3 && data.focused === undefined && !SVMX.getCurrentApplication().isAppEmbedded()) {
                    this.__root.handleNavigateBack();
                }

                if (data.accountId) {

                         /*
                        NOTE:
                            Apply below changes only for stand alone PIQ.
                            1. Clear app work order filters before invoking.
                            2. Clear transients data since we are clearing WO filters.
                            3. Clear appliedNodFilter data sincw we are clearing WO filters
                        
                        */

                        if (!SVMX.getCurrentApplication().isAppEmbedded() && data.focused === undefined ) {

                            var optionItems = this.__optionsPanel.items.items;
                            for(var i = 0; i < optionItems.length; i++){
                                var checkbox = optionItems[i];
                                if(checkbox.isTransientFilter === true) {
                                    this.__optionsPanel.remove(optionItems[i]);
                                } 
                                checkbox.setValue(false);
                            }
                            if (this.__transientFilters) {
                                for (var i = 0; i < this.__transientFilters.length; i++) {
                                    this.__transientFilters.splice(i,1);
                                }
                            }

                            var filterKeys = Object.keys(this.__appliedNodeFilters);
                            for(var i = 0; i < filterKeys.length; i++){
                                delete this.__appliedNodeFilters[filterKeys[i]];
                            }

                        }

                        if (data.focused === undefined) {
                            this.__searchForSelectedIBInLocalDatabase(data);
                        }

                        this.__selectedNodeId = null; // reset the value before invoking.
                        if(data.object === SVMX.getCustomObjectName("Installed_Product") || data.object === SVMX.getCustomObjectName("Site") ){
                            this.__isIBorLocationRecordSelected = true;
                        }else {
                            this.__isIBorLocationRecordSelected = false;
                        }
                        this.__selectFromRegisterExternal = true;
                        this.__selectedAccountId = data.accountId;
                        this.__currentAccountId = data.accountId;
                        this.__setSelectedAccountIdForIBSearch();
                        var menu = this.__accountsMenubarButton.menu;
                        var l = menu.items.items.length;
                        for (var i = 0; i < l; i++) {
                                var menuItem = menu.items.items[i];
                                if (menuItem.Id === this.__currentAccountId) {
                                        this.__accountsMenubarButton.setText(menuItem.text);
                                        this.__selectedAccountName = menuItem.text;
                                        break;
                                }
                         }
                         this.__isAccountChanged = false;
                         this.refreshContent();
                } 
                else {
                    SVMX.getCurrentApplication().getAppFocus();
                    this.__showErorrMessageForSelectedAccount();
                }
                
            }, this);           
        },

        __setAccountIdOnLaunch:function() {
            // Handle pending external messages
            var pendingMessage = SVMX.getCurrentApplication().getPendingMessage();
            if(pendingMessage !== null){
                pendingMessage = SVMX.toObject(pendingMessage);
                if (pendingMessage.accountId) {
                        this.__selectedAccountId = pendingMessage.accountId;
                        this.__currentAccountId = pendingMessage.accountId;
                        this.__setSelectedAccountIdForIBSearch();
                        this.__searchForSelectedIBInLocalDatabase(pendingMessage);
                } else {
                    if(SVMX.getCurrentApplication().isAppEmbedded()){
                        this.__showErorrMessageForSelectedAccount();
                    }
                    
                }
            } else {
                this.__isWorkOrderFilterChecked = false; // this flag is used to load first record, if there is no external data.
            }
        },

        __showErorrMessageForSelectedAccount : function()  { 
            SVMX.getCurrentApplication().showQuickMessage($TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'), $TR.__getValueFromTag($TR.PRODIQ001_TAG119,'The selected record does not have an account associated with it. Please contact your administrator to resolve this issue.'));
        },

        __setSelectedAccountIdForIBSearch : function() {
            var data = {};
            data.accountId = this.__currentAccountId;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "ACCOUNT_ID_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt); 

        },

        __clearAllFiltersForIbSearch : function () {
            var me = this;
            SVMX.getClient().bind("CLEAR_FILTERS_MESSAGE", function(evt){
                // me.__uncheckFilters();
                var optionItems = me.__optionsPanel.items.items;
                for(var i = 0; i < optionItems.length; i++){
                    var checkbox = optionItems[i];
                    checkbox.setValue(false);
                }
            });
        },

        __registerForFilterActionCall : function(){
            
            SVMX.getClient().bind("FILTER_ACTION_CALL", function(evt){
                var data = SVMX.toObject(evt.data);
                this.toggleOptions();
            }, this);           
        },

        __searchForSelectedIBInLocalDatabase : function(data) {
            if(data.object === SVMX.getCustomObjectName("Service_Order") || data.object === SVMX.getCustomObjectName("Installed_Product")){
                data = SVMX.toObject(data);
                var selectedIBId =  data.recordIds[0];
                var accountId = data.accountId;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.FIND_SELECTED_IB_IN_LOCAL_DB", this, {
                    request : {
                        context : this,
                        handler : this.onSearchBySelectedIBComplete,
                        params : {
                            accountId : accountId,
                            selectedIBId : selectedIBId
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            }

        },
        onSearchBySelectedIBComplete : function(result) {
            if (result === false) {
                SVMX.getCurrentApplication().showQuickMessage($TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'), $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'));
            }
        },
        
        __handleExternalMessage : function(data){
            if(data.object === SVMX.getCustomObjectName("Service_Order")){
                this.__selectFromExternal = true;
                this.__createTransientFilter(data);
            }else if(data.object === SVMX.getCustomObjectName("Installed_Product")){
                this.__selectFromExternal = true;
                this.__uncheckFilters();
                this.__selectTreeNodes(data);
            }else if(data.object === SVMX.getCustomObjectName("Site")){
                this.__selectFromExternal = true;
                this.__uncheckFilters();
            	this.__showLocationNode(data);
            } else {
                // Unrelated to IB tree
            }
        },

        __createTransientFilter : function(data){
            var me = this;
            var transFilter = SVMX.create("com.servicemax.client.installigence.ibtree.TransientFilter", {parent : this, data : data,meta : this.__meta});
            var exists = false;
            if(this.__transientFilters){
                for(var i = 0; i < this.__transientFilters.length; i++){
                    if(this.__transientFilters[i].getAlias() === transFilter.getAlias()){
                        // Already exists, let it reinitialize
                        exists = true;
                        transFilter = this.__transientFilters[i];
                        transFilter.setChecked();
                        break;
                    }
                }
                // Expand all the nodes
                this.__selectTreeNodes(data, function(){
                    if(!exists){
                        //Fixed: 027684 issue.
                        if (me.__transientFilters) {
                            var firstRecord = me.__transientFilters[0];
                            if (firstRecord === undefined) {
                                me.__transientFilters.push(transFilter);
                                transFilter.initialize(false);
                            } else {
                                for (var i = 0; i < me.__transientFilters.length; i++) {
                                    var workOrderName = me.__transientFilters[i].__data.sourceRecordName;
                                    var filterSourceRecordName = transFilter.__data.sourceRecordName;
                                    if (workOrderName !== filterSourceRecordName) {
                                        me.__transientFilters.push(transFilter);
                                        transFilter.initialize(false);
                                    } 
                                }
                            }
                        }
                    }else{
                        transFilter.setup();
                    }
                });
            }
        },

        enableAccountsMenuBarButton : function() {
            if (this.__accountsMenubarButton) {
                    this.__accountsMenubarButton.setDisabled(false);
            }
        },

        disableAccountsMenuBarButton : function() {

            if (this.__accountsMenubarButton) {
                    this.__accountsMenubarButton.setDisabled(true);
                    this.__accountsMenubarButton.setText(this.__selectedAccountName);
            }
        },
        enableOrDisableThePanels : function(flag) {
            if(window.parent.SVMX.getClient().getApplicationParameter("client-type").toLowerCase() !== "laptop")  {
                this.__optionsPanel.setDisabled(flag); 
                this.__tree.setDisabled(flag);
            }
        },

        __uncheckFilters : function(){
            var optionItems = this.getOptionsPanel().items.items;
            for(var i = 0; i < optionItems.length; i++){
                var checkbox = optionItems[i];
                checkbox.setValue(false);
            }
            this.__selectFromRegisterExternal = false;// reset the flag.

        },

        getTransientFilters : function(){
            var transFilter = [];
            if(this.__transientFilters){
                transFilter = this.__transientFilters;
            }
            return transFilter;
        },

        deleteTransientFilters : function(){
            var transientFilters = this.getTransientFilters();
            for(var i = 0; i < transientFilters.length; i++){
                transientFilters[i].hide();
            } 
            delete this.__transientFilters;
        },

        selectTreeNode : function(recordId, params, callback){
            this.__selectTreeNodes({recordIds : [recordId]}, callback, params);
        },
        
        __selectTreeNodes : function(data, callback, params){
            data = SVMX.toObject(data);
            this.__showSelectedIBRecord(data, callback, params);
        },
        
        __showLocationNode : function(data){
        	data = SVMX.toObject(data);
        	var root = SVMX.cloneObject(this.__treeData.root);
            var isRecordFound = this.__searchForLocation(root.children, root, data.recordIds[0]);
            if(isRecordFound === false && this.__selectFromExternal){
                SVMX.getCurrentApplication().showQuickMessage("info", $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'));
                delete this.__selectFromExternal;
            }
        },
        
        __searchForLocation : function(children, parentNode, recordId){
            var isRecordFound = false;
            if(!children) return isRecordFound;
            for(var i = 0; i < children.length; i++){
                var child = children[i];
                if(child.id === recordId){
                    var node = this.__tree.getStore().getNodeById(recordId);
                    if(node){
                        isRecordFound = true;
                        this.__tree.selectPath(node.getPath());
                        break;
                    }
                }else{
                    isRecordFound = this.__searchForLocation(child.children, parentNode, recordId);
                    if(isRecordFound === true) break;
                }
            }
            return isRecordFound;
        },
        
        __showSelectedIBRecord : function(data, callback, params) {
            var root = SVMX.cloneObject(this.__treeData.root);
            var loadSelectedIB = SVMX.create("com.servicemax.client.installigence.loadselectedib.LoadSelectedIB", {
                parent : this,
                selectedIB : data,
                root : root,
                callback : callback,
                params : params
            });
        },

        __createAccountMenubarWithButton:function() {
            //Add drop down for showing selected account.
            var me = this;
            var menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain :true,
                    width : 310,
                    maxHeight : 500,
                    cls :' ibtree-account-filter',
                    scrollable : true,
                    layout: 'vbox',
                    listeners : {

                                    hide : function(item,eOpts) {
                                        if (me.__menuItemSelected === false) {
                                                me.enableOrDisableThePanels(false); 
                                        }    
                                    }
                                }
                });               

            this.__accountsMenubarButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{ 
                    width : '65%',
                    // width : 300,
                    cls : 'border-botton', 
                     region : 'east',
                    disabled : false,
                    docked : 'left',
                    textAlign : 'left',
                    // margin: '8 3 0 3',
                    margin : '0 0 0 -5',
                    menuAlign : 'tl-bl',
                    layout : {
                      align : 'left'
                    },
                    menu : menu

                });
            return this.__accountsMenubarButton;
        },

        __getFilterOptions : function(){
            var me = this;
            if(!this.__filterExpressions){
                this.__filterExpressions = [];
            }

            var options = [];
            if(this.__meta.filters && this.__meta.filters.length){
                this.__filterState = this.__filterState || {};
                if(this.__meta.state && this.__meta.state.filters){
                    this.__filterState = this.__meta.state.filters;
                }
                for(i = 0; i < this.__meta.filters.length; i++){
                    var filter = this.__meta.filters[i];
                    var filterName = filter.name;
                    var cb = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                        boxLabel : filterName,
                        filterExpression : filter.expression,
                        inputValue : i,
                        value : me.__filterState[filterName],
                        margin: '0 0 0 5',
                        handler : function(){
                            // Index checked state so that it can be restored
                            me.__filterState[this.boxLabel] = this.value;
                            me.__selectFilterExpressions();
                            // me.__setFilterState();
                        }
                    });
                    options.push(cb);
                }
                // Restore from saved state
                if(this.__meta.state && this.__meta.state.filters){
                    SVMX.doLater(function(){
                        me.__selectFilterExpressions();
                    });
                }
            }

            return options;
        },

        __setFilterState : function(){
            var newState = SVMX.cloneObject(this.__meta.state);
            newState.filters  = newState.filters || {};
            $.extend(newState.filters, this.__filterState);
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.SAVE_STATE", this, {
                request : {context : this, state: newState}
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
        },

        __selectFilterExpressions : function(){
            this.__filterExpressions = [];
            var i, l = this.__optionsPanel.items.getCount();
            for(var i = 0; i < l; i++){
                var item = this.__optionsPanel.items.getAt(i);
                if(item.checked && item.filterExpression){
                    this.__filterExpressions.push(item.filterExpression);
                }
            }
            this.refreshContent({viaFilter : true});
        },

        __refreshFilterOptions : function(){
            var filterOptions = this.__getFilterOptions();
            var i, l = this.__optionsPanel.items.getCount();
            for(var i = 0; i < l; i++){
                var item = this.__optionsPanel.items.getAt(i);
                if(!item.filterExpression){
                    filterOptions.push(item);
                }
            }
            this.__optionsPanel.removeAll(false);
            for(var i = 0; i < filterOptions.length; i++){
                this.__optionsPanel.add(filterOptions[i]);
            }
        },
                
        getFilterExpressions : function(){
            return this.__filterExpressions;
        },

        __appendChildToParent : function(parent, child){
            parent.push({
                id : child.id,
                text : child.text,
                children : child.children,
                icon : child.icon,
                nodeType : child.nodeType,
                recordId : child.recordId
            });
        },

        __setupNodeFilters : function(){
            // setup internal node filters
            this.__allNodeFilters = {
                "loc": {
                    criteriaHandler : function(child){
                        return child.nodeType === "LOCATION"
                            || child.nodeType === "SUBLOCATION";
                    },
                    breakHandler : function(child){
                        return child.nodeType === "IB";
                    }
                },
                "swap": {
                    criteriaHandler : function(child){
                        return child.nodeType === "IB" && child.isSwapped;
                    }
                }
            };
            this.__appliedNodeFilters = {};
        },

        addNodeFilter : function(alias, criteriaHandler, breakHandler){
            this.__allNodeFilters[alias] = {
                criteriaHandler : criteriaHandler,
                breakHandler : breakHandler
            };
        },

        enableNodeFilter : function(alias){
            if(this.__allNodeFilters[alias]){
                this.__appliedNodeFilters[alias] = this.__allNodeFilters[alias];
            }
        },

        disableNodeFilter : function(alias){
            if(this.__appliedNodeFilters[alias]){
                delete this.__appliedNodeFilters[alias];
            }
        },

        hideNodes : function(alias, criteriaHandler, breakHandler){
            // Hide nodes based on criteria function, using alias to reference
            // Break handler is used ot prevent excessive recursion when
            // parent filters do not apply (i.e. locations)
            this.enableNodeFilter(alias);
            this.__applyNodeFilters(true);
        },

        showNodes : function(alias,doRemoveProperty){
            this.disableNodeFilter(alias);
            this.__applyNodeFilters(doRemoveProperty);
        },

        __applyNodeFilters : function(doRemoveProperty){
            var me = this;
            var treeData = this.__getTreeDataCloned();
            var root = treeData.root;

            //Defect fix - 24337 - Records are getting lost when user create location or IB while WO transient filter is "On"
            if(doRemoveProperty !== undefined && doRemoveProperty === true)
                me.__deleteUnWantedTreeDataProperties(root.children);
            var hasFilters = false;
            if(this.__appliedNodeFilters){
                var filterKeys = Object.keys(this.__appliedNodeFilters);
                for(var i = 0; i < filterKeys.length; i++){
                    if(this.__appliedNodeFilters[filterKeys[i]]){
                        hasFilters = true;
                        break;
                    }
                }
            }
            if(hasFilters){
                //disable the accounts menubar, if applied filters are true.
                this.disableAccountsMenuBarButton();
                filterNodes(root.children, root, true);
            } else {
                //enable the accounts menu bar.
                this.enableAccountsMenuBarButton();
            }

            if (this.__isIBorLocationRecordSelected == true) {
                this.__resetTreeStoreData(this.__treeData);
                this.enableAccountsMenuBarButton();
            } else {
                this.__resetTreeStoreData(treeData);
            }

            // this.__resetTreeStoreData(treeData);
            
            function criteriaHandler(node){
                for(var alias in me.__appliedNodeFilters){
                    if(!me.__appliedNodeFilters[alias]){
                        return true;
                    }
                    if(me.__appliedNodeFilters[alias].criteriaHandler(node)){
                        return true;
                    }
                }
            }
            function breakHandler(node){
                for(var alias in me.__appliedNodeFilters){
                    if(!me.__appliedNodeFilters[alias]){
                        continue;
                    }
                    if(me.__appliedNodeFilters[alias].breakHandler
                        && me.__appliedNodeFilters[alias].breakHandler(node)){
                        return true;
                    }
                }
            }
            function filterNodes(children, parentNode){
                if(!children) return;
                for(var i = 0; i < children.length; i++){
                    var child = children[i];
                    if(criteriaHandler(child)){
                        if(!parentNode.reset){
                            parentNode.reset = true;
                            parentNode.children = [];
                            // TODO: fix this hack, should be generic
                            if(!child.isSwapped || child.isSwapped === "false"){ // HACK
                                for(var j = 0; j < i; j++){
                                    parentNode.children.push(children[j]);
                                }
                            }
                        }
                        if(!child.isSwapped || child.isSwapped === "false"){ // HACK
                            filterNodes(child.children, parentNode);
                        }
                    }else{
                        if(child.nodeType !== "LOADING"){
                            if(parentNode.reset){
                                parentNode.children.push(child);
                            }
                            if(breakHandler(child)){
                                continue;
                            }
                            filterNodes(child.children, child);
                        }
                    }
                }
            }
        },

        __deleteUnWantedTreeDataProperties : function(children)
        {
            var me = this;
            for(var i = 0; i < children.length; i++){
                var child = children[i];
                var properties = ["allowDrag", "allowDrop", "checked", "cls", "depth", "expandable","href", "hrefTarget" ,"iconCls", "index", "isFirst" ,"isLast", "leaf" , "loaded" ,"loading", "qshowDelay", "qtip" ,"qtitle", "root" , "transient" ,"visible"];
                for(var j = 0; j < properties.length; j++){
                    delete child[properties[j]];
                }
                if(child.children){
                    me.__deleteUnWantedTreeDataProperties(child.children);
                }
                else{
                    return;
                }
            }
        },

        getTreeData : function(){
            return this.__treeData;
        },

        getTreeDataById : function(){
            return this.__treeDataById;
        },

        getTree : function() {
        	return this.__tree;
        },

        __getTreeDataCloned : function(){
            // Clone to prevent inconsistency after of modifying the tree
            return SVMX.cloneObject(this.__treeData);
        },

        __setTreeData : function(treeData, reloaded){
            if(reloaded){
                this.__setTreeDataReloaded(treeData);
            }
            // Clone to prevent inconsistency after of modifying the tree
            this.__treeData = SVMX.cloneObject(treeData);
            this.__treeDataById = {};
            this.__forEachChild(this.__treeData.root, function(child, parent){
                if(!child.id) return;
                // TODO: this check should not be necessary
                // But there exists a bug where a single parent can be referenced from children
                // in different parts of the tree, so we need to prevent that double reference
                // TODO: fix the tree issue and remove this check later
                if(!this.__treeDataById[child.id]){
                    this.__treeDataById[child.id] = child;
                    child.parentId = parent.id;
                }
                if(this.__expandedById[child.id]){
                    // If data was reloaded, then delay expandion of top level IBs
                    if(reloaded && child.nodeType === "IB"){
                        child.__expanded = true;
                    }else{
                        child.expanded = true;
                    }
                }
            });
            // Reset tree data
            this.__resetTreeStoreData(treeData);
            // Restore internal node filters
            if(!this.__locationsVisible){
                // Note: disabled until further notice
                //this.__appliedNodeFilters.loc = this.__allNodeFilters.loc;
            }
            if(!this.__swappedVisible){
                // Note: disabled until further notice
                //this.__appliedNodeFilters.swap = this.__allNodeFilters.swap;
            }
            if(this.__transientFilters){
                for(var i = 0; i < this.__transientFilters.length; i++){
                    if(this.__transientFilters[i].isChecked()){
                        var transAlias = this.__transientFilters[i].getAlias();
                        this.__appliedNodeFilters[transAlias]
                            = this.__allNodeFilters[transAlias];
                    }
                }
            }

            if (this.__isIBorLocationRecordSelected !== undefined && this.__isIBorLocationRecordSelected === true) {
                    this.__applyNodeFilters();
            }
        },

        __setTreeDataReloaded : function(treeData){
            var priorTreeDataById = this.__treeDataById;
            if(priorTreeDataById){
                var newTreeIBsById = {};
                this.__forEachChild(treeData.root, function(child, parent){
                    if(!child.id) return;
                    if(child.nodeType === "IB"){
                        if(priorTreeDataById[child.id]){
                            // TODO: good idea or bad idea?
                            /*if(this.__expandedById[child.id]){
                                var priorChildren = priorTreeDataById[child.id].children;
                                child.children = priorChildren;
                                child.expanded = true;
                            }*/
                        }else{
                            delete this.__expandedById[child.id];
                        }
                        newTreeIBsById[child.id] = child;
                    }
                });
                // Collapse children which are no longer visible
                this.__forEachChild(this.__treeData.root, function(child, parent){
                    if(child.nodeType === "IB" && child.id && !newTreeIBsById[child.id]){
                        delete this.__expandedById[child.id];
                    }
                });
            }
        },

        __setTreeDataTransients : function(){
            // Restore transient record state indicators
            if(this.__transientRecordIndex){
                for(var i = 0; i < this.__transientRecordIndex.length; i++){
                    var recordId = this.__transientRecordIndex[i];
                    this.setTreeNodeTransient(recordId, true);
                }
            }
        },

        __resetTreeStoreData : function(treeData){
            // this.__tree.getStore().removeAll();
            // this.__tree.getStore().setRootNode(treeData.root);

            var parent = this.__tree.getRootNode();
            if (parent !== null)
            {
                var delNode;
                    while (delNode = parent.childNodes[0])
                        parent.removeChild(delNode);

                this.__tree.saveState();    

            }

            this.__tree.getStore().removeAll();
            this.__tree.getStore().setRootNode(treeData.root);

        },

        __forEachChild : function(node, callback){
            // iterate through node children from top down
            if(!node.children) return;
            for(var i = 0; i < node.children.length; i++){
                callback.call(this, node.children[i], node);
                this.__forEachChild(node.children[i], callback);
            }
        },

        __detachChildFromParent : function(parent, child){
            for(var i = 0; i < parent.children.length; i++){
                if(parent.children[i].id === child.id){
                    parent.children.splice(i, 1);
                    return;
                }
            }
        },
        
        __canDropOn : function(nodes, parent){
            /******************************************
             * Rules: ALL CHANGES WITHIN SAME ACCOUNT
             * IB to different parent IB
             * IB to different location
             * IB to different to sub-location
             * Sublocation to different location
             * Sublocation to different sublocation
             * Child Location to different child location
             ******************************************/

            var dropNode = parent.data;
            var dropId = dropNode.recordId;
            var dropType = dropNode.nodeType;
            var accountId4Parent = this.__getAccountId4ChildNode(parent);

            var i, recs = nodes.records, l = recs.length, r, ret = true;
            for(i = 0; i < l; i++){
                r = recs[i];

                // if different account
                var accountId4Node = this.__getAccountId4ChildNode(r);
                if(accountId4Node != accountId4Parent){
                    return false;
                }

                var dragNode = r.data;
                var dragType = dragNode.nodeType;
                var dragParent = this.__treeDataById[dragNode.parentId];
                var dragParentType = dragParent.nodeType;

                // if it is the same parent
                if(r.parentNode.data.recordId == dropId){
                    return false;
                }

                if(dropType == "IB"){
                    if(dragType != "IB"){
                        ret = false;
                    }
                }else if(dropType == "SUBLOCATION"){
                    if(!(dragType == "IB" || dragType == "SUBLOCATION")){ 
                        ret = false;
                    }
                }else if(dropType == "LOCATION"){
                    if(!(dragType == "IB" || dragType == "SUBLOCATION" || dragType == "LOCATION")){ 
                        ret = false;
                    }
                    if(dragType == "LOCATION" && dragParentType === "ACCOUNT"){ 
                        ret = false;
                    }
                }else if(dropType == "ACCOUNT"){
                    ret = false;
                }else{
                    ret = false;
                }

                if(ret === false){
                    return false;
                }
            }
            return true;
        },

        __handleDropOn : function(nodes, parent, dropHandlers){
            dropHandlers.wait = true;
            var me = this;
            var parentData = parent.data;
            var parentType = parentData.nodeType;
            var parentId = parentData.recordId;
            var i, recs = nodes.records, l = recs.length, r, nodeType;
            var ur = {}; // ur = {Id, Site, SubLocation, Parent, Top_Level}
            var objectName = {};

            // used below to modify internal tree data
            var dropChildren = [];
            var dropParent = this.__treeDataById[parent.id];
            var dropParentNode = this.__tree.getStore().findNode("id", parent.id);

            // TODO: refactor this to work on treeData instead of store nodes
            for(i = 0; i < l; i++){
                r = recs[i]; nodeType = r.data.nodeType;
                ur.Id = r.data.recordId;
                dropChildren.push(this.__treeDataById[r.id]);
                // being dragged
                if(nodeType == "IB"){
                    objectName = SVMX.getCustomObjectName("Installed_Product");
                    // being dropped on
                    if(parentType == "IB"){
                        // get location, sublocation, and toplevel
                        var tmpParent = parent;
                        var topLevelId;
                        var locationId;
                        var sublocationId;
                        while(tmpParent != null){
                            if(tmpParent.data.nodeType == "IB"){
                                topLevelId = tmpParent.data.recordId;
                            }else if(tmpParent.data.nodeType == "SUBLOCATION" && !sublocationId){
                                sublocationId = tmpParent.data.recordId;
                            }else if(tmpParent.data.nodeType == "LOCATION" && !locationId){
                                locationId = tmpParent.data.recordId;
                            }
                            tmpParent = tmpParent.parentNode;
                        }

                        // update the parent
                        ur[SVMX.getCustomFieldName("Site")] = locationId;
                        ur[SVMX.getCustomFieldName("Parent")] = parentId;
                        ur[SVMX.getCustomFieldName("Top_Level")] = topLevelId;
                        ur[SVMX.getCustomFieldName("Sub_Location")] = sublocationId;
                    }else if(parentType == "SUBLOCATION"){
                        // This IB becomes top level 
                        var locationId = parent.parentNode.data.recordId;
                        ur[SVMX.getCustomFieldName("Site")] = locationId;
                        ur[SVMX.getCustomFieldName("Parent")] = "";
                        ur[SVMX.getCustomFieldName("Top_Level")] = "";
                        ur[SVMX.getCustomFieldName("Sub_Location")] = parentId;
                    }else if (parentType == "LOCATION"){
                        // This IB becomes toplevel
                        ur[SVMX.getCustomFieldName("Site")] = parentId;
                        ur[SVMX.getCustomFieldName("Parent")] = "";
                        ur[SVMX.getCustomFieldName("Top_Level")] = "";
                        ur[SVMX.getCustomFieldName("Sub_Location")] = "";
                    }else{
                        // should not happen
                        dropHandlers.wait = false;
                    }

                }else if(nodeType == "LOCATION"){
                    objectName = SVMX.getCustomObjectName("Site");
                    if(parentType == "LOCATION"){
                        parentId = parent.data.id;
                        // update the parent
                        ur[SVMX.getCustomFieldName("Parent")] = parentId;
                    }else{
                        dropHandlers.wait = false;
                    }
                }else if(nodeType == "SUBLOCATION"){
                    objectName = SVMX.getCustomObjectName("Sub_Location");
                    // TODO:
                    dropHandlers.wait = false;
                }else{
                    // should not happen
                    dropHandlers.wait = false;
                }
            }

            if(!dropHandlers.wait) return false;

            // process drop first to avoid double loading data from operation
            dropHandlers.processDrop();
            // update internal tree data
            var dropNodeSelectedId = false
            for(var i = 0; i < dropChildren.length; i++){
                var prevParent = this.__treeDataById[dropChildren[i].parentId];
                this.__detachChildFromParent(prevParent, dropChildren[i]);
                dropParent.children.push(dropChildren[i]);
                dropChildren[i].parentId = dropParent.id;
                dropChildren[i].prevParentId = prevParent.id;
                if(this.__selectedNodeId === dropChildren[i].id){
                    dropNodeSelectedId = dropChildren[i].id;
                }
            }

            // Cause the tree to reload parent

            //Commented below code to fix the issue : 035241 (dropParent is already loaded into tree. Hence reload is not required)
            // dropParent.loaded = false;

            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.UPDATE_IB_HIERARCHY", this, {
                    request : {
                        context : this,
                        params : {},
                        record : ur,
                        objectName : objectName,
                        handler : function(data){
                            // Reset the record view if a dropped node is selected
                            me.__dragEnabled = false; //reset drag flag.
                            if(dropNodeSelectedId){
                                me.fireEvent("node_selected", me.__treeDataById[dropNodeSelectedId]);
                            }
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __getAccountId4ChildNode : function(node){
            var ret = null;
            while(node != null){
                if(node.data.nodeType == "ACCOUNT"){
                    ret = node.data.recordId;
                    break;
                }
                node = node.parentNode;
            }
            return ret;
        },

        __fireRecordsSelected : function(){
            var selectedRecords = this.__tree.getChecked(), nodes = [];
            for(var i = 0; i < selectedRecords.length; i++){
                nodes.push(selectedRecords[i].data);
            }
            this.fireEvent("records_selected", nodes);
        },
        
        __showMore : function(p){
            var parentNode = this.__treeDataById[p.node.id];

            if(parentNode.allIBsLoaded){
                SVMX.getLoggingService().getLogger("All nodes loaded for " + parentNode.id);
                return;
            }
            
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_MORE_IBS", this, {
                    request : { context : this, params : {
                        parentNode : parentNode,
                        iBReferenceInfo : this.__IBReferenceINFO,
                        thisNode : null // TODO: what was this for? if not needed remove it
                    },
                    lastIBIndex : parentNode.lastIBIndex,
                    parentIBId : parentNode.id
                }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            return this.__showMoreD = SVMX.Deferred();
        },
        
        onGetMoreIBsCompleted : function(data, params){
            var updatedLastIndex = 0, i, l = data.length, d;
            var parentNode = this.__tree.getStore().findNode("id", params.parentNode.id);

            var internalParentNode = this.__treeDataById[parentNode.id];
            
            // remove LOADING Node
            for(var i = 0; i < internalParentNode.children.length; i++){ 
                var child = internalParentNode.children[i];
                if(child.nodeType == "LOADING"){ 
                    internalParentNode.children.splice(i, 1);
                    break;
                }
            }
            
            var items = [];
            for(i = 0; i < l; i++){
                d = data[i];
                updatedLastIndex = d["RecordId"];
                var children = [];
                if (d.hasChild) {
                    children = [this.__getLoadingNodeObject()];
                }
                items.push({
                    id : d["Id"],
                    text : d["Name"],
                    children : children,
                    icon : this.__getIconFor(d, "IB"),
                    //checked : false,
                    nodeType : "IB",
                    recordId : d["Id"]
                });
            }

            if(!internalParentNode.children){
                internalParentNode.children = items;
            }else{
                for(var i = items.length-1; i >= 0; i--){
                    internalParentNode.children.unshift(items[i]);
                }
            }
            internalParentNode.lastIBIndex = updatedLastIndex;
            internalParentNode.expanded = true;
            internalParentNode.allIBsLoaded = true;

            // if node has no children, undo the expand state internally
            if(internalParentNode.children.length === 0){
                internalParentNode.expanded = false;
                this.__expandedById[parentNode.id] = false;
            }

            // Apply changes incrementally to data store
            parentNode.removeChild(parentNode.childNodes[0]);

            parentNode.collapse();
            for(var i = 0; i < items.length; i++){
                parentNode.appendChild(items[i]);
                this.__treeDataById[items[i].id] = items[i];
            }
            parentNode.expand();

            // Note: can't use setTreeData here because
            // it causes a locked focus on the expanded item
            //this.__setTreeData(this.__treeData);
            this.__setTreeDataTransients();
            this.fireEvent('node_loaded', data);

            if(this.__selectedNodeId){
                this.selectTreeNode(this.__selectedNodeId);
            }

            // parentNode.expand();

            this.__showMoreD.resolve();
        },
        
        __getIBChildNodes : function(parentId, childIBs){
            var children = [];
            if(childIBs && childIBs.length){
                var parentField = SVMX.getCustomFieldName("Parent");
                for(var i = 0; i < childIBs.length; i++){
                    var child = childIBs[i];
                    if(child[parentField] === parentId){
                        children.push({
                            id : child.Id,
                            text : child.Name,
                            children : this.__getIBChildNodes(child.Id, childIBs),
                            icon : this.__getIconFor(child, "IB"),
                            //checked : false,
                            nodeType : "IB",
                            recordId : child.Id
                        });
                    }
                }
            }
            if(!children.length){
                children.push(this.__getLoadingNodeObject());
            }
            return children;
        },

        __getLoadingNodeObject : function(){
            var loadingText = "Please wait";
            var ret = {
                text :  loadingText,
                icon : com.servicemax.client.installigence.impl.Module.instance.getResourceUrl("images/paging.gif"),
                nodeType : "LOADING"
            };
            
            return ret;
        },
        
        toggleOptions : function(){
            this.__optionsPanel.toggleCollapse();
            this.doLayout();
        },

        getOptionsPanel : function(){
            return this.__optionsPanel;
        },
        
        addToTree : function(children, parent, type){
            if(type == "IB"){
                this.__addIBsToTree(children, parent, type);
            }else if(type == "LOCATION"){
                this.__addLocationToTree(children, parent, type);
            }else if(type == "SUBLOCATION"){
                this.__addSubLocationToTree(children, parent, type);
            }
        },

        __addLocationToTree : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Location"; // default name
            if(parent.nodeType === "ACCOUNT"){
                r[SVMX.getCustomFieldName("Account")] = parent.id;
            }else if(parent.nodeType === "LOCATION"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var accParent = parent;

                if (this.__currentAccountId) {
                    r[SVMX.getCustomFieldName("Account")] = this.__currentAccountId;
                } else {
                    while(accParent.nodeType !== "ACCOUNT"){
                        accParent = this.__treeDataById[accParent.parentId];
                    }
                    r[SVMX.getCustomFieldName("Account")] = accParent.id;
                }
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Site"));
        },

        __addSubLocationToTree : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Sub-Location"; // default name
            if(parent.nodeType === "LOCATION"){
                r[SVMX.getCustomFieldName("Location")] = parent.id;
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Account")] = accParent.id;
            }else if(parent.nodeType === "SUBLOCATION"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Location")] = locParent && locParent.id;
                if (this.__currentAccountId) {
                    r[SVMX.getCustomFieldName("Account")] = this.__currentAccountId;
                } else {
                    r[SVMX.getCustomFieldName("Account")] = accParent.id;
                }
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Sub_Location"));
        },

        /*__addIBsToTree_other : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Installed Product"; // default name
            if(parent.nodeType === "LOCATION"){
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Site")] = parent.id;
                r[SVMX.getCustomFieldName("Company")] = accParent.id;
            }else if(parent.nodeType === "SUBLOCATION"){
                r[SVMX.getCustomFieldName("Sub_Location")] = parent.id;
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                r[SVMX.getCustomFieldName("Site")] = locParent && locParent.id;
            }else if(parent.nodeType === "IB"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var ibParent = parent;
                while(this.__treeDataById[ibParent.parentId].nodeType === "IB"){
                    ibParent = this.__treeDataById[ibParent.parentId];
                }
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                var sublocParent = parent;
                while(sublocParent && sublocParent.nodeType !== "SUBLOCATION"){
                    sublocParent = this.__treeDataById[sublocParent.parentId];
                }
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Top_Level")] = ibParent.id;
                r[SVMX.getCustomFieldName("Site")] = locParent && locParent.id;
                r[SVMX.getCustomFieldName("Sub_Location")] = sublocParent && sublocParent.id;
                r[SVMX.getCustomFieldName("Company")] = accParent.id;
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Installed_Product"));
        },*/

        __addIBsToTree : function(children, parent, type){
            var pnode = this.__tree.getStore().findNode("id", parent.id);
            var records = this.__createNewIBRecordData(pnode, children);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Installed_Product"));
        },

        __addRecords : function(records, parent, type, objectName){
            SVMX.getCurrentApplication().blockUI();
            var pnode = this.__tree.getStore().findNode("id", parent.id);
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.CREATE_RECORDS", this, {
                    request : {
                        context : this,
                        handler : this.onCreateRecordsComplete,
                        objectName : objectName,
                        params : {
                            parentNode : pnode,
                            type : type
                        },
                        records : records
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        addClonedToTree : function(record, cloned, type, cascade){

            if (cloned.nodeType === "IB" && cloned.parentType === "ACCOUNT") {
                this.addClonedRecordToRootNode([record], {
                        type : type,
                        parentNode : null, //in this case there is no parent node. So we need to add to root node.
                        insertAfter : cloned,
                        hasChildren : cascade
                    });
            } else {
                    var parentNode = this.__tree.getStore().findNode("id", cloned.parentId);
                    this.onCreateRecordsComplete([record], {
                        type : type,
                        parentNode : parentNode,
                        insertAfter : cloned,
                        hasChildren : cascade
                    });
            }
        },

        deleteFromTree : function(node){
            SVMX.getCurrentApplication().blockUI();
            node = this.__tree.getStore().findNode("id", node.id);

            var objectName;
            switch(node.data.nodeType){
                case "ACCOUNT":
                    objectName = SVMX.getCustomObjectName("Account");
                    break;
                case "LOCATION":
                    objectName = SVMX.getCustomObjectName("Site");
                    break;
                case "SUBLOCATION":
                    objectName = SVMX.getCustomObjectName("Sub_Location");
                    break;
                case "IB":
                    objectName = SVMX.getCustomObjectName("Installed_Product");
                    break;
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.DELETE_RECORDS", this, {
                    request : {
                        context : this,
                        handler : this.onDeleteRecordsComplete,
                        objectName : objectName,
                        recordId : node.data.recordId,
                        params : {
                            node : node,
                            type : node.nodeType
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onDeleteRecordsComplete : function(success, params){
            SVMX.getCurrentApplication().unblockUI();
            if(!success){
                SVMX.getCurrentApplication().showQuickMessage("error", $TR.__getValueFromTag($TR.PRODIQ001_TAG045,'Unable to delete synced records.'));
                return;
            }
            var treeParent;
            if (params.node.data.parentId === "root" && params.node.data.nodeType === "IB") {
                 // update internal tree
                var treeNode = this.__treeDataById[params.node.id];
                treeParent = this.__tree.getRootNode();
                this.__detachChildFromParent(treeParent.data, treeNode);

            } else {
                // update internal tree
                var treeNode = this.__treeDataById[params.node.id];
                treeParent = this.__treeDataById[treeNode.parentId];
                this.__detachChildFromParent(treeParent, treeNode);
            }
            // remove from data store
            params.node.remove();

            //Once deletion complete, select its parent node.
            var parentId = treeParent.id;
            if (parentId) {
                this.__selectedNodeId = parentId;
                this.selectTreeNode(this.__selectedNodeId, params);
            } 
        },

        __createNewIBRecordData : function(pnode, children){
            var accountId = null;
            var locationId = null;
            var sublocationId = null;
            var topLevel = null;
            var records = [], r, i, l = children.length, c, tmpParent = pnode;
            
            var parentRecordId = null;
            if(pnode.data.nodeType === "IB"){
                parentRecordId = pnode.data.recordId;
            }
            while(tmpParent != null){   
                if(tmpParent.data.nodeType == "LOCATION" && !locationId){
                    locationId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "SUBLOCATION" && !sublocationId){
                    sublocationId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "ACCOUNT"){
                    accountId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "IB"){
                    topLevel = tmpParent.data.recordId;
                }
                
                tmpParent = tmpParent.parentNode;
            }

            //set the accountId here.
            if (this.__currentAccountId) {
                accountId = this.__currentAccountId;
            }

            for(i = 0; i < l; i++){
                c = children[i];
                r = {};
                r["Name"] = c.Name;
                r[SVMX.getCustomFieldName("Company")] = accountId;
                r[SVMX.getCustomFieldName("Site")] = locationId;
                r[SVMX.getCustomFieldName("Sub_Location")] = sublocationId;
                r[SVMX.getCustomFieldName("Product")] = c.Id;
                r[SVMX.getCustomFieldName("Product_Name")] = c.Name;
                r[SVMX.getCustomFieldName("Parent")] = parentRecordId;
                r[SVMX.getCustomFieldName("Top_Level")] = topLevel;
                // TEMP: Hard coded mappings from product
                // TODO: Remove these after field mapping is available for add new IB action
                r['Category__c'] = c.CategoryId__c__id;     // Range
                r['DeviceType2__c'] = c.DeviceType2__c__id; // DeviceType
                r['Brand2__c'] = c.Brand2__c__id;           // Brand
				records.push(r);
            }
            
            return records;
        },
        
        onCreateRecordsComplete : function(data, params){

            SVMX.getCurrentApplication().unblockUI();

            var parentNode = this.__tree.getStore().findNode("id", params.parentNode.id);
            parentNode.expand(false);

            // if the parent node is not expanded, just return, the first-time expand code
            // will fetch the newly inserted records along with the other records
            var internalParentNode = this.__treeDataById[parentNode.id];
            if(internalParentNode.nodeType == "IB" && !internalParentNode.allIBsLoaded){
                this.__selectedNodeId = data[0].Id;
                return;
            }
            
            var childNodes = [];
            var i, l = data.length, d;
            for(i = 0; i < l; i++){
                d = data[i];
                var child = {
                    id : d.Id,
                    text : d.Name,
                    children : [],
                    icon : this.__getIconFor(d, params.type),
                    //checked : false,
                    nodeType : params.type,
                    recordId : d.Id
                };
                if(params.type === "IB"){
                    child.isSwapped = d[SVMX.getCustomFieldName("IsSwapped")];
                }
                if(params.hasChildren){
                    child.children = [this.__getLoadingNodeObject()];
                }
                childNodes.push(child);
                this.__treeDataById[child.id] = child;
            }
            if(params.insertAfter){
                var afterNode = this.__tree.getStore().findNode("id", params.insertAfter.id);
                for(var i = 0; i < internalParentNode.children.length; i++){
                    if(internalParentNode.children[i].id === params.insertAfter.id){
                        for(var j = 0; j < childNodes.length; j++){
                            internalParentNode.children.splice(i+j+1, 0, childNodes[j]);
                            parentNode.insertChild(i+1, childNodes[j]);
                            this.__tree.getStore().findNode("id", childNodes[j].id).loaded = false;
                        }
                        break;
                    }
                }
            }else{
                for(var i = 0; i < childNodes.length; i++){
                    internalParentNode.children.unshift(childNodes[i]);
                    parentNode.appendChild(childNodes[i]);
                    // parentNode.insertChild(0, childNodes[i]);
                    this.__tree.getStore().findNode("id", childNodes[i].id).loaded = false;
                }
            }

            // Cause parent to reload
            parentNode.loaded = false;
            
            this.__setTreeDataTransients();

            if(params.insertAfter){
                this.__tree.getStore().findNode("id", params.insertAfter.id).collapse(false);
            }
            this.__tree.getStore().findNode("id", childNodes[0].id).expand(false);
            this.selectTreeNode(childNodes[0].id);
        },

        addClonedRecordToRootNode : function(data, params) {

            SVMX.getCurrentApplication().unblockUI();
            if (!params.parentNode) {
                    var childNodes = [];
                    var i, l = data.length, d;
                    for(i = 0; i < l; i++){
                        d = data[i];
                        var child = {
                            id : d.Id,
                            text : d.Name,
                            children : [],
                            icon : this.__getIconFor(d, params.type),
                            //checked : false,
                            nodeType : params.type,
                            recordId : d.Id
                        };
                        if(params.type === "IB"){
                            child.isSwapped = d[SVMX.getCustomFieldName("IsSwapped")];
                        }
                        if(params.hasChildren){
                            child.children = [this.__getLoadingNodeObject()];
                        }
                        childNodes.push(child);
                        this.__treeDataById[child.id] = child;
                    }

                    if(params.insertAfter){
                        var afterNode = this.__tree.getStore().findNode("id", params.insertAfter.id);
                        var treeNode = this.__tree.getRootNode();
                        for(var i = 0; i < treeNode.data.children.length; i++){
                            if(treeNode.data.children[i].id === params.insertAfter.id){
                                for(var j = 0; j < childNodes.length; j++){
                                    this.__treeData.root.children.splice(i+j+1, 0, childNodes[j]);
                                    treeNode.insertChild(i+1, childNodes[j]);
                                    this.__tree.getStore().findNode("id", childNodes[j].id).loaded = false;
                                }
                                break;
                            }
                        }
                    } 
                    // Cause parent to reload
                    // parentNode.loaded = false;
                    
                    this.__setTreeDataTransients();

                    if(params.insertAfter){
                        this.__tree.getStore().findNode("id", params.insertAfter.id).collapse(false);
                    }
                    this.__tree.getStore().findNode("id", childNodes[0].id).expand(false);
                    this.selectTreeNode(childNodes[0].id);
            }

        },
        
        __getIconFor : function(record, type){
            switch(type){
                case "IB":
                    var ibId = record[SVMX.getCustomFieldName("Top_Level")]
                        || record.Id;
                    var ibIndex = this.__productIconIndex[ibId];
                    var productId = record[SVMX.getCustomFieldName("Product")];
                    if(ibIndex && ibIndex[productId]){
                        // TODO: use native client method to get download path
                        var iconName = ibIndex[productId];
                        var iconPath = "C:/ProgramData/ServiceMax/ProductIQ/Downloads/"+iconName;
                        return iconPath;
                    }
                    return "modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon1.png";
                default:
                    var defaultIcons = {
                        'LOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png',
                        'SUBLOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png',
                        'ACCOUNT' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png'
                    };
                    return defaultIcons[type];
            }
        },

        refreshContent : function(p){

            if (!this.__currentAccountId) { // if there is no accountId, then just return it.
                return;
            }

            var bRefresh = true;
            if(p){
                if(p.type == "initialize"){
                    // nothing yet
                }else if(p.params && p.params.syncType && 
                    (p.params.syncType == "initial" || p.params.syncType == "reset" || p.params.syncType == "ib" || p.params.syncType === "insert_local_records")){
                    
                    // TODO: not sure tree should be refreshed when type is 'ib'
                    
                    // this may not be the right place
                    this.fireEvent("reset");
                }else{
                    bRefresh = false;
                }
                if(p.viaFilter !== undefined && p.viaFilter == true){
                    var me = this;
                    setTimeout(function(){
                        me.__refreshContentInternal(p);
                    }, 50);
                }
            }
            if(bRefresh){
                var me = this;
                setTimeout(function(){
                    me.__refreshContentInternal();
                }, 50);
            }
        },
        
        __refreshContentInternal : function(params){

            SVMX.getCurrentApplication().unblockUI();//first unblock UI, if its already exits.
            SVMX.getCurrentApplication().blockUI();

            if (this.__currentAccountId) {
                    if (params) {
                        params.accountId = this.__currentAccountId;
                    } else {
                        params = {accountId:this.__currentAccountId};
                    }
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_TOP_LEVEL_IBS", this, {request : 
                        { 
                            context : this, 
                            params : params,
                            iBReferenceInfo : this.__IBReferenceINFO
                        }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        /* Requesting for reference field info */
        __getIBReference: function(){
         		var me = this;
         		if(SVMX.getCurrentApplication().isAppEmbedded()) {
               		this.getIbLookupFieldInfoRelation("IB").execute().done(function(lookUpResult){
                		me.__IBReferenceINFO = me.getRelationshipNames(lookUpResult);
            		});
            	}else{
            		this.fetchMFLLabelDetail();
            	}
            	
        },
         /*  This method fetch custom name of the display column of the configuration */
        fetchMFLLabelDetail : function(){
             var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(), 
            me = this;
            syncService.getSObjectInfos([SVMX.getCustomObjectName("Installed_Product")])
            .done(function(info){
            	if(info && info.length>0){
            		for(var f_index = 0; f_index < info.length; f_index++){
						me.__IBReferenceINFO = {};
						var fieldsInfo = info[f_index];
						var i = 0,l = info[f_index].fields.length,fieldInfo = [];
						for(i = 0; i < l; i++){
							var fieldObject = info[f_index].fields[i];
							if(fieldObject.type.toUpperCase() == "REFERENCE")
								me.__IBReferenceINFO[fieldObject.name] = me.getObjectName(fieldObject);
						}
					}
            	}
            });
        },
        
        /* making reference model */
        getObjectName:function(fieldObject){
        	if(fieldObject){
        		var fieldInfo = {};
        		fieldInfo["relationName"] = fieldObject.relationshipName;
         		fieldInfo["referenceTo"] = fieldObject.referenceTo[0];
         		fieldInfo["fieldName"] = fieldObject.name;
        		return fieldInfo;
        	}
        	return fieldObject;
        },
         
        /* making reference info from DB, This is for iPad only */
         getIbLookupFieldInfoRelation : function(relationTable){
            var qo = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            qo.select("reference_To, relationship_name, api_name").from("SFObjectField");
            qo.where("object_api_name='"+SVMX.getCustomObjectName("Installed_Product")+"'");
            qo.where("type = 'reference'");
            return qo;
        },
        
        /* Making reference model */
        getRelationshipNames : function (lookUpResult){
            var relationshipName = {};
            for(var rIndex = 0; rIndex < lookUpResult.length; rIndex++){
                var config = lookUpResult[rIndex];
                relationshipName[config.fieldName] = config;
            }
            return relationshipName;
        },

        __getAllTopLevelAccounts:function(params) {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.FETCH_TOPLEVEL_ACCOUNTS", this, {request : 
                        { 
                            context : this, params : params
                        }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        updateRecordName : function(id, name){
            var node = this.__treeDataById[id];
            if(node){
                this.__setTreeNodeName(node, name);
            }
        },
        
        updateRecordWithErrorStar : function(id, name){
        	var node = this.__treeDataById[id];
            if(node){
                this.__setTreeNodeError(node, name);
        	   //node.text = name+"*";
            }
        },
        
        __getLocationAndAccountDetails : function(treeData, listOfLocations, listOfSubLocations, listOfAccounts){
            var locIds = [];
            var sublocIds = [];
            var accIds = [];
            var i, l = listOfLocations.length;
            for(i = 0; i < l; i++){
                locIds.push(listOfLocations[i].id);
            }
            l = listOfSubLocations.length;
            for(i = 0; i < l; i++){
                sublocIds.push(listOfSubLocations[i].id);
            }
            l = listOfAccounts.length;
            for(i = 0; i < l; i++){
                accIds.push(listOfAccounts[i].id);
            }
            
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_LOC_ACC_DETAILS", this, {
                    request : { 
                        context : this,
                        locIds : locIds,
                        sublocIds : sublocIds,
                        accIds : accIds,
                        params : {
                            treeData : treeData,
                            listOfLocations : listOfLocations,
                            listOfSubLocations : listOfSubLocations,
                            listOfAccounts : listOfAccounts
                        }
                    }
                }
            );
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onGetLocationAndAccountDetailsCompleted : function(data, params){
            var treeData = params.treeData;
            var listOfAccounts = params.listOfAccounts || [];
            var listOfLocations = params.listOfLocations || [];
            var listOfSubLocations = params.listOfSubLocations || [];
            var accounts = data.accounts || [];
            var locations = data.locations || [];
            var sublocations = data.sublocations || [];
            
            // locations
            var id2nameMap = {}, i;
            for(i = 0; i < locations.length; i++){
                id2nameMap[locations[i].Id] = locations[i].Name;
            }
            
            for(i = 0; i < listOfLocations.length; i++){
                var n = listOfLocations[i].text;
                if(id2nameMap[listOfLocations[i].id]){
                    n = id2nameMap[ listOfLocations[i].id ];
                }
                listOfLocations[i].text = n;
            }
            // end locations

            // sublocations
            id2nameMap = {};
            for(i = 0; i < sublocations.length; i++){
                id2nameMap[sublocations[i].Id] = sublocations[i].Name;
            }
            
            for(i = 0; i < listOfSubLocations.length; i++){
                var n = listOfSubLocations[i].text;
                if(id2nameMap[listOfSubLocations[i].id]){
                    n = id2nameMap[ listOfSubLocations[i].id ];
                }
                listOfSubLocations[i].text = n;
            }
            // end sublocations
            
            // accounts
            id2nameMap = {};
            for(i = 0; i < accounts.length; i++){
                id2nameMap[accounts[i].Id] = accounts[i].Name;
            }
            
            for(i = 0; i < listOfAccounts.length; i++){
                var n = listOfAccounts[i].text;
                if(id2nameMap[listOfAccounts[i].id]){
                    n = id2nameMap[ listOfAccounts[i].id ];
                }
                listOfAccounts[i].text = n;
            }
            // end accounts

            this.onDataLoadComplete(treeData);
        },

       onDataLoadComplete : function(treeData, params){

            var me = this;
            // Finally set new tree data
            this.__setTreeData(treeData, true);
            this.__setTreeDataTransients();
            // Reload previously expanded IBs
            //this.__asyncExpandPriorIBs();

            SVMX.getCurrentApplication().unblockUI();

            // setTimeout(function(){
            //         if (me.__menuItemSelected) {
            //             me.enableOrDisableThePanels(false);
            //             me.__menuItemSelected = false;
            //         }
            // }, 800);

            //Case: action type is SYNC
            var pendingMessage = SVMX.getCurrentApplication().getPendingMessage();
            if(pendingMessage !== null){ //sync from MFL
                pendingMessage = SVMX.toObject(pendingMessage);
                if (pendingMessage.action === "SYNC" && (pendingMessage.operation === "INCREMENTAL" || pendingMessage.operation === "PURGE" || pendingMessage.operation === "INSERT_lOCAL_RECORDS")) {
                     // Re-select previous note when filtering
                    if(this.__selectedNodeId){
                        this.selectTreeNode(this.__selectedNodeId, params);
                    }
                    this.__isDataSyncTriggerd = false; //reset the value to false.
                    return;
                }
            } 
            if (this.__isDataSyncTriggerd === true) { // manual data sync check from PIQ.
                this.__isDataSyncTriggerd = false; //reset the value to false.
                if(this.__selectedNodeId){
                    this.selectTreeNode(this.__selectedNodeId, params);
                }
                return;
            }

            //Case: action type is VIEW 
            var flag = false;
            if (this.__isAccountChanged == false) {
                    // Handle pending external messages
                    if(pendingMessage !== null){
                        pendingMessage = SVMX.toObject(pendingMessage);
                        this.__handleExternalMessage(pendingMessage);               
                        if(pendingMessage.action === "VIEW"){
                            SVMX.getCurrentApplication().emptyPendingMessage();
                        } else {
                            flag = true;
                        }
                    } else {
                        flag = true;
                    }
            } else {
                    flag = true;
            }

            //Case : Selecting first node if no external data available.
            if (flag === true && this.__isWorkOrderFilterChecked == false) { // select first record the tree view data.
                this.__selectedNodeId = treeData.root.children[0].id;
            }


            //Case : Work order filter selection from different account.
            if (this.__isWorkOrderFilterChecked === true && this.__selectedWorkOrderFilterData) {
                this.__handleExternalMessage(this.__selectedWorkOrderFilterData);  
            }

            // Re-select previous note when filtering
            if(this.__selectedNodeId){
                this.selectTreeNode(this.__selectedNodeId, params);
            }
        },


        onGetTopLevelAccountsComplete : function(data) {
            var i,l = data.length,menuItem;
            var me = this;
            var menu = this.__accountsMenubarButton.menu;
            for(i = 0; i < l; i++){
                var record = data[i];
                menuItem = Ext.create('Ext.menu.Item', {
                                text : record.Name,
                                Id : record.Id,
                                margin: '6 0 12 10',
                                listeners : {
                                    click : function(item,e,eOpts) {
                                        me.__menuItemSelected = true;
                                        me.enableOrDisableThePanels(true);
                                        me.__loadSelectedAccountRecords(item);
                                    }
                                }
                                
                });
                menu.add(menuItem);
                if (this.__currentAccountId == record.Id) {
                        this.__accountsMenubarButton.setText(record.Name);
                        this.__selectedAccountName = record.Name;
                }
             }

             //check accountId and recordId here. If not exits then set first account treedata and
             //refresh the content.
             if (!this.__selectedAccountId && menu) {
                    var menuItem = menu.items.items[0];
                    this.__accountsMenubarButton.setText(menuItem.text);
                    this.__selectedAccountName = menuItem.Name;
                    this.__selectedAccountId = menuItem.Id;
                    this.__currentAccountId = menuItem.Id;
                    this.__setSelectedAccountIdForIBSearch();
                    this.refreshContent();//Now we have accountId. So refreshContent.
             }
        },

        __loadSelectedAccountRecords : function(menuItem) {

            var me = this;
            this.__selectFromRegisterExternal = false;
            this.__isWorkOrderFilterChecked = false;
            if (this.__currentAccountId !== menuItem.Id) {
                this.__currentAccountId = menuItem.Id;
                this.__accountsMenubarButton.setText(menuItem.text);
                if (this.__currentAccountId == this.__selectedAccountId) {
                    this.__isAccountChanged = false;
                } else {
                    this.__isAccountChanged = true;
                }
                this.__setSelectedAccountIdForIBSearch();
                this.refreshContent();
            } 

            setTimeout(function(){
                    me.enableOrDisableThePanels(false);
                    me.__menuItemSelected = false;

            }, 1500);
        },

        __asyncExpandPriorIBs : function(){
            var me = this;
            for(var id in this.__treeDataById){
                if(this.__treeDataById[id].__expanded){
                    this.__showMore({node : this.__tree.getStore().findNode("id", id)})
                    .done(function(){
                        // Continue recursively expanding top level nodes
                        //me.__asyncExpandPriorIBs();
                    });
                    this.__treeDataById[id].expanded = true;
                    delete this.__treeDataById[id].__expanded;
                    //break;
                }
            }
        },
        
        onGetTopLevelIBsComplete : function(data){

            this.__loadTreeData(data);
        },

        __loadTreeData : function(data){
            var me = this, params = data.params;
            var treeData = {
                root : {
                    expanded : true,
                    children : []
                }
            };
            data = data || [];

            if(data.templates){
                this.__indexProductIconsFromTemplates(data);
            }
            if(data.transients){
                this.__transientRecordIndex = data.transients;
            }

            // 1) Create all the nodes
            var accountsById = {};
            if(data.accounts){
                for(var i = 0; i < data.accounts.length; i++){
                    var record = data.accounts[i];
                    var accountNode = {
                        id : record.Id,
                        text : record.Name || ("(Acc) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png',
                        children : [],
                        nodeType : "ACCOUNT",
                        recordId : record.Id
                    };
                    accountsById[record.Id] = accountNode;
                }
            }
            var locationsById = {};
            if(data.locations){
                for(var i = 0; i < data.locations.length; i++){
                    var record = data.locations[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "LOCATION";
                    }
                    else if(record[SVMX.getCustomFieldName("Account")]){
                        parentId = record[SVMX.getCustomFieldName("Account")];
                        parentType = "ACCOUNT";
                    }
                    var locationNode = {
                        id : record.Id,
                        text : record.Name || ("(Loc) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png',
                        children : [],
                        nodeType : "LOCATION",
                        recordId : record.Id,
                        parentId : parentId,
                        parentType : parentType
                    };
                    locationsById[record.Id] = locationNode;
                }
            }
            var sublocationsById = {};
            if(data.sublocations){
                for(var i = 0; i < data.sublocations.length; i++){
                    var record = data.sublocations[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "SUBLOCATION";
                    }else if(record[SVMX.getCustomFieldName("Location")]){
                        parentId = record[SVMX.getCustomFieldName("Location")];
                        parentType = "LOCATION";
                    }
                    var sublocationNode = {
                        id : record.Id,
                        text : record.Name || ("(Sub) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png',
                        children : [],
                        nodeType : "SUBLOCATION",
                        recordId : record.Id,
                        parentId : parentId,
                        parentType : parentType
                    };
                    sublocationsById[record.Id] = sublocationNode;
                }
            }
            var ibsById = {};
            if(data.ibs){
                for(var i = 0; i < data.ibs.length; i++){
                    var record = data.ibs[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "IB";
                    }else if(record[SVMX.getCustomFieldName("Sub_Location")]){
                        parentId = record[SVMX.getCustomFieldName("Sub_Location")];
                        parentType = "SUBLOCATION";
                    }else if(record[SVMX.getCustomFieldName("Site")]){
                        parentId = record[SVMX.getCustomFieldName("Site")];
                        parentType = "LOCATION";
                    }else if(record[SVMX.getCustomFieldName("Company")]){
                        parentId = record[SVMX.getCustomFieldName("Company")];
                        parentType = "ACCOUNT";
                    }else {
                        continue;
                    }
                    var children = [];

                    if (record.hasChild) {
                        children = [this.__getLoadingNodeObject()]
                    }
                    var ibNode = {
                        id : record.Id,
                        text : record.Name || ("(IB) "+record.Id),
                        icon : me.__getIconFor(record, "IB"),
                        children : children,
                        nodeType : "IB",
                        recordId : record.Id,
                        serialNo : record[SVMX.getCustomFieldName("Serial_Lot_Number")],
                        isSwapped : record[SVMX.getCustomFieldName("IsSwapped")],
                        parentId : parentId,
                        parentType : parentType
                    };
                    ibsById[record.Id] = ibNode;
                }
            }

            // 2) Assemble the hierarchy
            for(var key in locationsById){
                var node = locationsById[key];
                if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "ACCOUNT" && accountsById[node.parentId]){
                    if(accountsById[node.parentId]){
                        accountsById[node.parentId].children.push(node);
                    }
                }else{
                    warnParentInvalid(node);
                }
            }
            for(var key in sublocationsById){
                var node = sublocationsById[key];
                if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "SUBLOCATION" && sublocationsById[node.parentId]){
                    sublocationsById[node.parentId].children.push(node);
                }else{
                    warnParentInvalid(node);
                }
            }
            for(var key in ibsById){
                var node = ibsById[key];
                if(node.parentType === "ACCOUNT" && accountsById[node.parentId]){
                    accountsById[node.parentId].children.push(node);
                }else if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "SUBLOCATION" && sublocationsById[node.parentId]){
                    sublocationsById[node.parentId].children.push(node);
                }else if(node.parentType === "IB" && ibsById[node.parentId]){
                    ibsById[node.parentId].children.push(node);
                }else{
                    warnParentInvalid(node);
                }
            }

            if (this.__currentAccountId) { // filter tree data using selected accountId.
                    for(var key in accountsById){
                        var node = accountsById[key];
                        var childLocations = node.children;
                        if (childLocations) {
                            for (var i = 0; i < childLocations.length; i++) {
                                var childNode = childLocations[i];
                                treeData.root.children.push(childNode);
                            }
                        }
                    }
            } else {
                    for(var key in accountsById){
                        var node = accountsById[key];
                        treeData.root.children.push(node);
                }
            }




            this.onDataLoadComplete(treeData, params);

            function warnParentInvalid(node){
                console.warn('Tree structure invalid: Location '+node.id+' parent '+node.parentType+' '+node.parentId+' not found');
            }
        },

        __indexProductIconsFromTemplates : function(data){
            var index = this.__productIconIndex = {};
            for(var i = 0; i < data.ibs.length; i++){
                var ib = data.ibs[i];
                var tplId = ib[SVMX.getCustomFieldName("ProductIQTemplate")];
                if(tplId && data.templates[tplId]) {
                    indexIBProductIconsRecursive(
                        ib.Id, data.templates[tplId].template
                    );
                }
            }

            function indexIBProductIconsRecursive(ibId, template) {
                if(template.children){
                    var i, l = template.children.length;
                    for(i = 0; i < l; i++){
                        indexIBProductIconsRecursive(ibId, template.children[i]);
                    }
                }
                var product = template.product;
                if(product && product.productIcon){
                    index[ibId] = index[ibId] || {};
                    index[ibId][product.productId] = product.productIcon;
                }
            }
        },

        setTreeNodeTransient : function(id, isTransient){
            var me = this;
            var node = this.__treeDataById[id];
            if(!node) return;
            // Unref previous parent (set from handleDropOn...)
            if(node.transient && node.prevParentId){
                var prevParent = this.__treeDataById[node.prevParentId];
                if(prevParent){
                    unrefNode(prevParent);
                }
            }
            isTransient = (isTransient === undefined) ? true : isTransient;
            if(isTransient) {
                refNode(node);
            }else{
                unrefNode(node);
            }
            node.transient = isTransient;
            delete node.prevParentId;
            function refNode(node){
                node.transientRefs = node.transientRefs || [];
                if(node.transientRefs.indexOf(id) === -1){
                    node.transientRefs.push(id);
                }
                if(!node.origText){
                    node.origText = node.text;
                    node.text = node.text+"*";
                    me.__tree.getStore().findNode("id", node.id)
                        .updateInfo(true, {text: node.text});
                }
                var parent = me.__treeDataById[node.parentId];
                if(parent){
                    refNode(parent);
                }
            }
            function unrefNode(node){
                if(node.transientRefs){
                    var idx = node.transientRefs.indexOf(id);
                    if(idx !== -1){
                        node.transientRefs.splice(idx, 1);
                    }
                    if(!node.transientRefs.length && node.origText){
                        node.text = node.origText;
                        me.__tree.getStore().findNode("id", node.id)
                            .updateInfo(true, {text: node.text});
                        delete node.origText;
                    }
                }
                var parent = me.__treeDataById[node.parentId];
                if(parent){
                    unrefNode(parent);
                }
            }
            return;
            this.__setTreeData(this.__treeData);
        },

        __setTreeNodeName : function(node, name){
            if(!node.transientRefs || !node.transientRefs.length){
                node.text = name;
                delete node.origText;
            }else{
                node.origText = name;
                node.text = name+"*";
            }
            this.__tree.getStore().findNode("id", node.id)
                .updateInfo(true, {text: node.text});
        },

        __setTreeNodeError : function(node, name){
            node.origText = name;
            node.text = name+"*";
            this.__tree.getStore().findNode("id", node.id)
                .updateInfo(true, {text: node.text});
        }
    });

    /**
     * Transient filter functionality for IBtree
     * Used to manage and apply transient filters upon IBtree
     * Example: Filter IBs for WO-000000X, from external request
     */
    ibtreeImpl.Class("TransientFilter", com.servicemax.client.lib.api.Object, {
        __ibtree : null,
        __data : null,
        __alias : null,
        __checked : null,
        __checkbox : null,
        __meta : null,

        __constructor : function(params){
            this.__ibtree = params.parent;
            this.__data = params.data;
            this.__meta = params.meta;
            this.__alias = this.__data.sourceRecordName;
            this.__checked = true;
        },

         initialize : function(){
            var me = this;
            this.__checkbox = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", { 
                boxLabel : me.__alias,
                checked : true,
                margin: '0 0 0 5',
                isTransientFilter : true,
                handler : function(){
                    me.__checked = this.value;
                    var accountId = me.__data.accountId;
                    var ibId = me.__data.recordIds[0];
                    /* This is about open standalone */
                    me.__data.focused = true;

                 me.__ibtree.__isIBorLocationRecordSelected = false; //reset the flag.

                 if (me.__ibtree.__currentAccountId === accountId) {
                            if(this.value){
                                me.__ibtree.__selectedNodeId = ibId;
                                me.__ibtree.__isWorkOrderFilterChecked = true;
                                me.__uncheckOtherTransientFilters();
                                me.__ibtree.hideNodes(me.__alias);
                                me.__ibtree.__handleExternalMessage(me.__data);
                            }else{
                                if(!me.__ibtree.isUncheckingTransientFilters){
                                    me.__ibtree.__isWorkOrderFilterChecked = false;
                                    me.__ibtree.showNodes(me.__alias,true);
                                    me.__addTransientNodeFilter(true);
                                }
                            }
                            if(me.__ibtree.__selectedNodeId){
                                me.__ibtree.selectTreeNode(me.__ibtree.__selectedNodeId);
                            }
                    } else {

                            if (me.__ibtree.__selectFromRegisterExternal === false || me.__ibtree.__selectFromRegisterExternal === undefined) {
                                    me.__ibtree.__selectedNodeId = ibId;
                                    me.__ibtree.__isWorkOrderFilterChecked = true;
                                    me.__ibtree.__currentAccountId = accountId;
                                    var menu = me.__ibtree.__accountsMenubarButton.menu;
                                    var l = menu.items.items.length;

                                    for (var i = 0; i < l; i++) {
                                        var menuItem = menu.items.items[i];
                                        if (menuItem.Id === accountId) {
                                            me.__ibtree.__accountsMenubarButton.setText(menuItem.text);
                                            me.__ibtree.__selectedAccountName = menuItem.text;
                                            break;
                                        }
                                    }
                                    //updating accountID on filter selection
                                    me.__meta.accountId = accountId;
                                    me.__ibtree.__selectedWorkOrderFilterData = me.__data;
                                    me.__ibtree.refreshContent();
                         }
                    }
                }
               
            });
            this.__ibtree.getOptionsPanel().add(this.__checkbox);
            this.__ibtree.getOptionsPanel().expand();
            this.setup();
        },

        setup : function(){
            var me = this;
            this.__ibtree.__selectedNodeId = this.__data.recordIds[0];
            this.__addTransientNodeFilter();
            this.__uncheckOtherTransientFilters();
            this.__ibtree.hideNodes(this.__alias);
            this.__ibtree.selectTreeNode(this.__data.recordIds[0]);
            this.__selectFromRegisterExternal = false;
        },

        setChecked : function(){
            this.__checkbox.setValue(true);
        },

        isChecked : function(){
            return this.__checked; 
        },

        getAlias : function(){
            return this.__alias; 
        },

        hide : function(){
            this.__checkbox.setValue(false);
            this.__checkbox.hide();
        },

        __addTransientNodeFilter : function(reset){
            if (!this.__transientNodeFilter || reset) {
                this.__transientNodeFilter = this.__createTransientNodeFilter()
            }
            this.__ibtree.addNodeFilter(this.__alias,
                this.__transientNodeFilter
            );
        },

        __createTransientNodeFilter : function(){
            var me = this;
            // Find applicable parent locations, sublocations and account
            this.__parentAccounts = [];
            this.__parentIBs = [];
            this.__parentLocations = [];
            this.__parentSublocations = [];
            var treeDataById = this.__ibtree.getTreeDataById();
            for(var i = 0; i < this.__data.recordIds.length; i++){
                var recordId = this.__data.recordIds[i];
                var node = treeDataById[recordId];
                findNodeParents(node);
            }
            function findNodeParents(node){
                if(!node) return;
                var parent = treeDataById[node.parentId];
                if(!parent) return;
                if(parent.nodeType === "ACCOUNT"
                    && me.__parentAccounts.indexOf(parent.id) === -1){
                    me.__parentAccounts.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "LOCATION"
                    && me.__parentLocations.indexOf(parent.id) === -1){
                    me.__parentLocations.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "SUBLOCATION"
                    && me.__parentSublocations.indexOf(parent.id) === -1){
                    me.__parentSublocations.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "IB"
                    && me.__parentIBs.indexOf(parent.id) === -1){
                    me.__parentIBs.push(parent.id);
                    parent.expanded = true;
                }
                findNodeParents(parent);
            }
            return function(child){
                // Filter out all records that do not match transient tree
                if(child.nodeType === "ACCOUNT"){
                    if(me.__parentAccounts.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "LOCATION"){
                    if(me.__parentLocations.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "SUBLOCATION"){
                    if(me.__parentSublocations.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "IB"){
                    if(me.__parentIBs.indexOf(child.id) === -1 && me.__data.recordIds.indexOf(child.id) === -1){
                        return true;
                    }
                }
                return false;
            };
        },

        __uncheckOtherTransientFilters : function(){
            var transFilters = this.__ibtree.getTransientFilters();
            for(var i = 0; i < transFilters.length; i++){
                this.__ibtree.disableNodeFilter(transFilters[i].getAlias());
            }
            var optionItems = this.__ibtree.getOptionsPanel().items.items;
            this.__ibtree.isUncheckingTransientFilters = true;
            for(var i = 0; i < optionItems.length; i++){
                var checkbox = optionItems[i];
                if(!checkbox.isTransientFilter) continue;
                if(checkbox.boxLabel === this.__alias) continue;
                checkbox.setValue(false);
            }
            delete this.__ibtree.isUncheckingTransientFilters;
        }

    }, {
        // Only for testing
        testTrigger : function(){
            var data = {
                action : 'VIEW',
                // Test serials under MAccount
                recordIds : [
                    'a0HF000000Nwd7XMAR', // INROW...
                    'a0HF000000Nv0qSMAR', // MInstalled 3
                    'a0HF000000NwcSfMAJ', // Coffee machine...
                    'a0HF000000NwkmQMAR', // ArchProd11
                    'a0HF000000NwkmZMAR'  // ArchProd10
                ],
                object : SVMX.getCustomObjectName("Installed_Product"), // ???
                sourceRecordName : "WO-100000TEST1"
            };
            if(window.previouslySet){
                data.sourceRecordName = "WO-100000TEST2";
            }
            window.previouslySet = true;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt); 
        }
    });
    
};

})();

//end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\loadselectedib.js
/**
 * 
 */

(function(){
    
    var loadselectedibImpl = SVMX.Package("com.servicemax.client.installigence.loadselectedib");

loadselectedibImpl.init = function(){
    loadselectedibImpl.Class("LoadSelectedIB", com.servicemax.client.lib.api.Object, {
    __selectedIB : null, __parent : null, __root : null, __parentIBs : null, __accountNode : null,
    __ibtree : null, __treeDataById : null, __isCallback : null,
    __focusFromSearch : null,

    
    __constructor : function(options){
        this.__root = options.root;
        this.__parent = options.parent;
        this.__ibtree = options.parent.getTree();
        this.__treeDataById = options.parent.getTreeDataById();
        this.__callback = options.callback || function(){};
        this.__selectedFirst = null;
        this.__params = options.params;

        if (options.selectedIB.focused) {
            this.__focusFromSearch = options.selectedIB.focused
        }

        var loadingMore = false;
        for(var i = 0; i < options.selectedIB.recordIds.length; i++){
            var recordId = options.selectedIB.recordIds[i];

            var ibNode = this.__ibtree.getStore().getNodeById(recordId);
            if (ibNode != null) {
                // Only select the first path
                if (this.__selectedFirst !== true) {
                    this.__selectedFirst = true;
                    this.__parent.fireEvent("node_selected", ibNode.data);
                    this.__ibtree.selectPath(ibNode.getPath());
                }
                continue;
            }
            loadingMore = true;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_ALL_PARENT_IBS", this, {
                    request : { context : this, params : {}, record : {Id : recordId}, 
                        handler : this.onAllParentIBsComplete
                        }
                });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);

        }
        if(!loadingMore){
            this.__callback();
        }
    },
        
    onAllParentIBsComplete : function(data) {
        if (data == null || data.length == 0) {
            if (this.__parent.__selectFromExternal) {
                this.__callback();
                this.showMessageForParent();
            }
        } else {
            this.traverseNodes(data);
        }
    },
    
    traverseNodes : function (data) {
        if (data.length == 0) {
            return;
        }
        var rec = data.pop();
        var ibNode = this.__ibtree.getStore().getNodeById(rec.ids);
        if (!ibNode) {
            this.__callback();
            this.showMessageForParent();
            return;
        }
        var parentNode = this.__treeDataById[ibNode.id];
        if (data.length == 0 && this.__selectedFirst !== true) {
            this.__selectedFirst = true;
            this.__parent.fireEvent("node_selected", ibNode.data);
            this.__ibtree.selectPath(ibNode.getPath());
            
            if(!this.__isCallback){
               this.__isCallback = true; 
               this.__callback();
            }
            
            return;
        }else if(data.length == 0){
            if(!this.__isCallback){
               this.__isCallback = true; 
               this.__callback();
            }
            return;
        }
        // Children are already loaded. Lazy loading is not required.
        if (parentNode != null && parentNode.allIBsLoaded == true) {
            this.traverseNodes(data);
        }
        this.__parent.on("node_loaded", function(input) {
                this.traverseNodes(data);
        }, this, {single : true});

        // ibNode.expand(false);
        var time = 15;
        if (this.__focusFromSearch === true) {
            time = 800;
        }
        setTimeout(function(){
                    ibNode.expand(false);
         }, time);
    },

    showMessageForParent : function(){

        if (this.params === undefined) {
            return;
        }
         if (!this.__params.viaFilter === true) { // this.__params === undefined  ||
         
         /* Using custom window for message */
         	var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
				height: 175,
				width: 550,
				layout: 'fit',
				buttonAlign: 'center',
				closable: false,
				text : $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'),
				title : $TR.__getValueFromTag($TR.PRODIQ001_TAG056,'Info'),
                textAlign : "display:inline-block;text-align:left"
			});
			evt.filterButtonAction(evt);
			evt.show();
			
            //SVMX.getCurrentApplication().showQuickMessage("Info", $TR.MESSAGE_IB_NOT_EXISTS);
            delete this.__parent.__selectFromExternal;
        } 
    }
            
    }, {});
    
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\lookup.js
(function(){
    var lookupImpl = SVMX.Package("com.servicemax.client.installigence.lookup");

lookupImpl.init = function(){

    Ext.define("com.servicemax.client.installigence.lookup.TextField", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXTextField",
        alias: 'widget.inst.referencefield',

        constructor: function(config) {
            this.callParent([config]);
        }
    });

    Ext.define("com.servicemax.client.installigence.lookup.Container", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXFieldContainer", // temporary
        alias: 'widget.inst.fieldcontainer',
        __text : null, __btn : null, __lookup : null,

        constructor: function(config) {
            var me = this;
            config = Ext.apply({
                layout : { type : "hbox"},
                items : [],
                defaults: {
                    hideLabel: true
                }
             }, config || {});

            this.__lookup = SVMX.create("com.servicemax.client.installigence.lookup.Lookup", config);
            this.__text = this.__lookup.getLookupText();
            this.__btn = this.__lookup.getLookupBtn();

            this.callParent([config]);


        },

        setValue : function(value){
           this.__lookup.setValue(value);
        },

        getValue : function(){
            return this.__lookup.getValue();
        },

        makeReadOnly : function(){
            this.__lookup.readOnly();
        },

        getLookupText : function(){
            return this.__lookup.getLookupText();
        },

        getLookupBtn : function(){
            return this.__lookup.getLookupBtn();
        },

        onAdded : function( container, pos, instanced ){
            this.callParent([ container, pos, instanced ]);

            var me = this;
            container.on("resize", function(){
                me.readjustItemsWidth(container.getWidth() - 40);
            }, this);

            container.on("all_fields_added", function(){
                me.readjustItemsWidth(container.getWidth() - 40);
            }, this);
        },

        readjustItemsWidth : function(width){

            var scrollbarWidth = 38;
                if(!SVMX.getCurrentApplication().isAppEmbedded()) {
                    var scrollbarWidth = 73;
                }

            //var labelWidth = this.labelEl.getWidth();
            var availableWidth = width - scrollbarWidth - this.__btn.getWidth(); // 25 scrollbar
            this.__text.setWidth(availableWidth);

        }
    });

    lookupImpl.Class("Lookup", com.servicemax.client.lib.api.Object, {
        __config : null, __lookupBtn : null, __lookupText : null, __inited : false, __objectInfo : null,
        __store : null, __grid : null, __win : null, __value : null, __displayValue : null, __objectName : null,
        __displayFields : null, __searchFields : null, __fields : null, __searchFields : null,__fieldsMap : null,
        __isConnected : true, __selectedRecord : null, __fieldLabel: null,
        __constructor : function(config){
            this.__config = config || [];
            this.__config.items = [];
            this.__config.layout = 'hbox';
            this.__config.cls = 'svmx-lookup-field';
            this.__config.margin = '05, 30';
            this.__config.labelAlign ='top';
            this.__fieldLabel = config.fieldLabel;
            this.__parent = config.parent;
            this.__inited = false;
            this.__objectName = this.__config.objectName;
            this.__value = "";
            this.__displayValue = "";
            this.__lookupField();
            this.__fields = this.__getFields(this.__config.columns);
            this.__searchFields = this.__getSearchFields(this.__config.searchColumns);
            this.__parentNodeId = this.__parent.__node.id;
            this.__selectedRecord = {};
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

        __showWindow : function(){
            if(this.__inited == false){ this.__init();}
            else{ this.__showUI(); }
        },

        __find1 : function(params){
            SVMX.getCurrentApplication().blockUI();
            this.__parentNodeId = this.__parent.__node.id;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_LOOKUPCONFIG", this,
                    {request : {
                        context: this,
                        keyword : params.text,
                        handler : params.handler,
                        doQueryMFL : params.doQueryMFL,
                        doQueryOnline :params.onlineChecked,
                        callType : "BOTH",
                        objectName : this.__objectName,
                        lookupContext : "",
                        lookupQueryField : "",
                        searchOperator : "contains",
                        parentNodeId : this.__config.parent.__node.id
                    }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __find : function(params){
            SVMX.getCurrentApplication().blockUI();
            this.__parentNodeId = this.__parent.__node.id;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE." + this.__config.mvcEvent, this,
                    {request : {
                        context : this,
                        handler : params.handler,
                        doQueryMFL : params.doQueryMFL,
                        doQueryOnline :params.doQueryOnline,
                        fields : params.fields || this.__fields,
                        searchFields : this.__searchFields,
                        objectName: params.objectName || this.__objectName,
                        text : params.text,
                        id : params.value,
                        fieldsDescribe: this.__fieldsMap,
                        parentNodeId : this.__config.parent.__node.id
                    }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __findComplete : function(data, isValid, parentNodeId, gridColomns){
            SVMX.getCurrentApplication().unblockUI();
            if(parentNodeId !== this.__parentNodeId){
                return;
            }
            if(data.length || isValid){
                data = this.__checkForEmptyLocalRecNameValue(data);
                this.__store.loadData(data);
                // This is implemented for LookupConfig. Do not call __getUI() insted call __ShowUI() and it will call __getUI()
                //this.__win.show();
                //this.__win = this.__getUI(gridColomns);
            }else{
                this.__initDisable();
            }
        },

        __checkForEmptyLocalRecNameValue : function(data){
             var i = 0, j = data.length;
             for(i = 0; i < j; i++){
                 if(data[i] && data[i].Name !== undefined && data[i].Name.length === 0 && (data[i].Id.indexOf("-") >= 0 || data[i].Id.indexOf("_") >= 0)){
                    data[i].Name = data[i].Id;
                 }
             }
             return data;
        },

        __initialLoad : function(data){
            SVMX.getCurrentApplication().unblockUI();
            if(data && data[0]){
                this.setDisplayValue(data[0].Name, data[0].Id);

            }else{
                //search actual records, which may search remote (thereby slower)
                this.__find({value: this.__value, handler : this.__getNameFieldComplete});
            }
        },

        __getNameFieldComplete: function(data, isValid, parentNodeId){
            SVMX.getCurrentApplication().unblockUI();
            if(parentNodeId !== this.__parentNodeId){
                return;
            }
            if(data && data[0]){
                this.setDisplayValue(data[0].Name, data[0].Id);
            }else{
                this.setDisplayValue('');
            }
        },

        __searchComplete : function(data, isValid, parentNodeId){
            SVMX.getCurrentApplication().unblockUI();
            this.__store.loadData(data);
        },
        
        launchScanner : function(textView) {
			var  me = this;
			var d = SVMX.Deferred();
			var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
			var browserRequest = nativeservice.createScanRequest();
			browserRequest.bind("REQUEST_COMPLETED", function(evt){
			debugger;
			if (evt.data.data && !evt.data.data.cancelled) {
				var text = evt.data.data.text;
				textView.setValue(text);
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
		},
        
       getItem : function(searchText,barCode,goButton){
            	var items = [];
            	if(window.parent.SVMX.getClient().isBarCodeEnabled())
            		return [searchText,barCode,goButton];
            	else
            		return [searchText,goButton];
        },

        __init : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(), me = this;
            syncService.getSObjectInfo(this.__config.objectName)
            .done(function(info){
                me.__objectInfo = info;
                me.__fieldsMap = {};
                if(info){
                    var i = 0,l = info.fields.length;
                    for(i = 0; i < l; i++){
                        me.__fieldsMap[info.fields[i].name] = info.fields[i]
                    }
                }else{
                    me.__fieldsMap = {
                        Id : {type : "text"},
                        Name : {type : "text"}
                    };
                    me.__objectInfo = {
                        fields : [
                            {name : "Name", label : "Name"}
                        ]
                    }
                }
                me.__initComplete();
            });
        },

        __initComplete : function(){
            this.__inited = true;
            this.__showUI();
        },

        __initDisable : function(){
            // Amar Joshi : Don't know the reason why below two line was implemented. To Fix defect 021250 - Lookup gets disabled if searched with a value that has no match,
            // commented bolow two lines

            /*this.__lookupText.disable();
            this.__lookupBtn.disable();*/
            //SVMX.getCurrentApplication().showQuickMessage("info", "No records found");
            var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
				height: 150,
				width: 390,
				layout: 'fit',
				buttonAlign: 'center',
				closable: false,
				text : $TR.__getValueFromTag($TR.PRODIQ001_TAG123,'No records found'),
				title : $TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'),
                textAlign : "display:inline-block;text-align:center"
			});
			evt.filterButtonAction(evt);
			evt.show();

            if(this.__win){
                this.__win.close();
            }
        },

        __showUI : function(){
            var me = this;
          /*  me.__checkConnectivity().done(function(result){
                me.__isConnected = true;
                if(result == 'False'){
                    me.__isConnected = false;
                }
                me.__find({handler : me.__findComplete, text : me.__lookupText.getValue(), fields: me.__fields, doQueryMFL : true});
                me.__win = me.__getUI();
                me.__win.show();
            });*/
            me.__find({handler : me.__findComplete, text : me.__lookupText.getValue(), fields: me.__fields, doQueryMFL : true, doQueryOnline : true});
            //this.__find1({handler : this.__findComplete, keyWord : this.__lookupText.getValue(), objectName : this.__objectName});
            this.__win = this.__getUI();
        me.__win.show();

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

        //LUMA : renaming RecordName with SFRecordName
        setValue: function(value){
            this.__value= value;
            if(!value || value == ""){
                this.setDisplayValue(""); return;
            }
            if(this.__store == null || this.__store.find("Id", value) == -1){
                this.setDisplayValue('');
                this.__find({value: value, handler : this.__initialLoad, objectName : "SFRecordName"});
            }else{
                this.setDisplayValue(this.__store.findRecord("Id", value).get("Name"), value);
            }
        },

        setDisplayValue: function(value, id){
            this.__displayValue = value;
            this.__lookupText.setValue(value);
            if(id && (id.indexOf("_") >= 0 || id.indexOf("-") >= 0) && (!value && value == "")){
                this.__displayValue = id;
                this.__lookupText.setValue(id);
            }

        },

        getLookupText: function(){
            return this.__lookupText;
        },

        getLookupBtn: function(){
            return this.__lookupBtn;
        },

        __lookupField : function(){

            // show the field
            var me = this;
            var items = [];
            this.__lookupBtn = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                iconCls: 'svmx-lookup-icon',
                margin: '0, 5',
                disabled: this.__config.fld.readOnly,
                handler: function(){
                    me.__showWindow();
                }
            });

            this.__lookupText = SVMX.create('com.servicemax.client.installigence.lookup.TextField', {
                value: this.getValue(),
                readOnly: this.__config.fld.readOnly,
                allowBlank: this.__config.fld.required,

                listeners: {
                    specialkey: function(f,e){
                        if(e.getKey() == e.ENTER){
                            me.__showWindow();
                        }
                    },
                    //Rahman: To fix 028142 added below code
                    // afterrender: function(c) {
                    //     c.inputEl.on('click', function() {
                    //         me.__showWindow();
                    //     });
                    // },
                    blur: function(){
                        if(this.getValue().trim() === ''){
                            // Clear lookup value
                            me.setValue('');
                        }
                    }
                }
            });

            /* wrapper for lookup label and button */
            this.__lookupWrapper = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                    cls: 'svmx-priq-lookup-field',
                    layout: { type : 'hbox'},
                    items: [this.__lookupText,this.__lookupBtn]
                });
            this.__config.items.push(this.__lookupWrapper);
        },

        __checkConnectivity : function(){
            var d = SVMX.Deferred();
            var me = this;
            var params = {
                type : "CONNECTIVITY",
                method : "CHECKCONNECTIVITY"
            };

            // var req = com.servicemax.client.installigence.offline.sal.model.nativeservice.Facade.createConnectivityRequest();
            var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
            var req = nativeservice.createConnectivityRequest();
            req.bind("REQUEST_COMPLETED", function(evt){
                d.resolve(evt.data.data);
            }, me);
            req.bind("REQUEST_ERROR", function(evt){
                d.resolve("False");
            }, me);
            req.execute(params);
            return d;
        },

        __getUI : function(){//displayCols
            var cols = this.__fields, i, l = cols.length, me = this;
            /*if(displayCols && displayCols !== undefined && displayCols.length > 0){
                cols = displayCols;
                l = cols.length;
            }*/
            // store
            var fields = [];
            for(i = 0; i < l; i++){ fields.push(cols[i]); }
            var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});

            //grid
            var gridColumns = [], objectInfo = this.__objectInfo, j, oFields = objectInfo.fields, t = oFields.length, c;
            for(i = 0; i < l; i++){
                c = cols[i];
                for(j = 0; j < t; j++){
                    if(c == oFields[j].name && c != "Id"){
                        gridColumns.push({ text : oFields[j].label, minWidth: 175, dataIndex : c, flex : 1, cls:'installigence-lookup-grid-header' });
                    }
                }
            }

            //LUMA : Renaming RecordName with SFRecordName.
            var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
                store: store,
                cls : 'installigence-lookup-grid',
                forceFit : true, columns: gridColumns, flex : 1, width: "100%", autoScroll: true,
                viewConfig: {
                    listeners: {
                        itemdblclick: function(dataview, record, item, index, e) {
                            // TODO: remove this mapping eventually
                            if(me.__objectName === "Product2"){
                                for(var i = 0; i < me.__parent.items.items.length; i++){
                                    var item = me.__parent.items.items[i];
                                    if(item.fld.name === "Category__c"){
                                        item.setValue(record.data.CategoryId__c);
                                    }else if(item.fld.name === "DeviceType2__c"){
                                        item.setValue(record.data.DeviceType2__c);
                                    }else if(item.fld.name === "Brand2__c"){
                                        item.setValue(record.data.Brand2__c);
                                    }
                                }
                            }
                            me.__selectedRecord = {};
                            me.__selectedRecord = record.data;
                            me.setValue(record.data.Id);
                            me.setDisplayValue(record.data.Name);
                            me.__lookupText.focus();
                            me.__win.close();
                            if(record.data.SVMXIsFromServer){
                                me.__find({value: record.data.Id, handler : me.__LocalCheckComplete, objectName : "SFRecordName"});
                            }
                        }
                    }
                }
            });

                        // searchText
            var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                width: '40%', emptyText : 'Search', enableKeyEvents : true,
                value: me.getDisplayValue(),
                listeners : {
                    keyup : function(that, e, opts) {
                        if(e.getKey() == e.ENTER){
                            me.__find({
                                text : searchText.getValue(),
                                handler : me.__searchComplete,
                                fields: me.__fields,
                                doQueryMFL : true,
                                doQueryOnline : true
                            });
                        }
                    }
                }
            });  
            
            var barCode = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                	 iconCls: 'svmx_BarIcon_button',
                	 text : ' ',
 					 margin: '0, 5', 
 					 width: '15%',
                     flex: 1,
                     handler : function(){
					     me.launchScanner(searchText);
					}
            });
            
            var goButton =  {
                                xtype: 'button', 
                                text: $TR.__getValueFromTag($TR.PRODIQ001_TAG139,'Go'), 
                                handler : function(){
                                    me.__find({
                                        text : searchText.getValue(),
                                        handler : me.__searchComplete,
                                        fields: me.__fields,
                                        doQueryMFL : true,
                                        doQueryOnline : true
                                        
                                    });
                                }
                            };
            var toolBarItems = me.getItem(searchText,barCode,goButton);
                 
            // window
            var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                layout : {type : "vbox"}, height : 400, width : 820,
                cls: 'LookUP-Poup-Centered',
                closable: false, maximizable: false, animateTarget: me.__lookupBtn,
                titleAlign:'center',
                title: this.__fieldLabel +$TR.__getValueFromTag($TR.IPAD014_TAG136,'Lookup'),
                dockedItems : [
                    {
                        dock: 'top', xtype: 'toolbar', margin: '0',
                        items : toolBarItems
                    }
                ],
                tools:[
                    {
                        xtype: 'button', 
                        text: $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'),
                        handler : function(){
                        me.__win.close();
                    }
                }],
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
                minWidth: this.__lookupText.width , layout: {
                    padding: 5
                }, layout : 'fit', items : [grid], modal : true
            });
            // var toXY = this.__lookupText.getXY();
            win.setPosition(window.screen.width/4, window.screen.height/6);
            this.__store = store;
            this.__grid = grid;
            return win;
        },

        //LUMA : Renaming RecordName with SFRecordName.

        __LocalCheckComplete : function(data){
            SVMX.getCurrentApplication().unblockUI();
            if(data.length == 0){
                SVMX.getCurrentApplication().blockUI();
                var recordNames = [];
                recordNames.push({
                    Id : this.__selectedRecord.Id,
                    Name : this.__selectedRecord.Name
                });
                var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
                queryObj.replaceInto("SFRecordName")
                .columns([{name : "Id"}, {name : "Name"}])
                .values(recordNames)
                .execute().done(function(){
                    SVMX.getCurrentApplication().unblockUI();
                });
            }
        }

    });
}
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\mashups.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\objectsearch.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\progress.js
/**
 * 
 */

(function(){
    var progressImpl = SVMX.Package("com.servicemax.client.installigence.progress");
    
progressImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.progress.Progress", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.progress',
        meta : null, root : null, __bar : null, __stepCount : 0, __carousel : null,
        
        constructor: function(config) { 
            this.meta = config.meta;
            this.root = config.root;

            this.__bar = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXProgressBar", {width : "100%"});
            this.__carousel = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXCarousel", {
                width : "100%", flex : 1, cls: 'installigence-progress-imageview'
            });

            var content = "", i, l = 3;
            var module = com.servicemax.client.installigence.impl.Module.instance;
            for(i = 0; i < l; i++){
                content += 
                '<div><img style="width:75%;display:block;margin-left:auto;margin-right:auto;" src="' 
                + module.getResourceUrl("progress/img0" + i + ".png") + '"/></div>';
            }
            
            this.__carousel.setContent(content);
            
            this.__stepCount = 0;
            
            config = Ext.apply({
                titleAlign: 'center', 
                // frame: 'true',
                collapsible : false,
                // style: 'margin:10px',
                // height : SVMX.getWindowInnerHeight() - 40,
                height : SVMX.getWindowInnerHeight() - 2,
                toolPosition: 0,
                items : [this.__bar, this.__carousel],
                layout : { type : "vbox"},
                border : false,
                defaults : {margin : '20 20 20 20'}
            }, config || {});
            
            this.callParent([config]);
            
            // register for sync events
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.bind("SYNC.STATUS", function(evt){
                
                if(evt.data.type == "start" && (evt.data.syncType == "initial" || evt.data.syncType == "reset" || evt.data.syncType == "config" || evt.data.syncType == "purge")){
                    this.__stepCount = -1;
                    this.__updateStep(syncService.totalStepCount, "");
                }else if(evt.data.type == "step"){
                    this.__updateStep(syncService.totalStepCount, evt.data.msg);
                }
            }, this);
            // end sync events
        },
        
        __updateStep : function(totalCount, message){
            this.__stepCount++;
            this.__bar.updateProgress(this.__stepCount/totalCount, message, true);
        },
        
        handleFocus : function(params){
            var title = "";
            if(params.syncType == "initial" || params.syncType == "reset"){
                title = $TR.__getValueFromTag($TR.PRODIQ001_TAG042,'Preparing ProductIQ for the first time use. Please wait') + "...";
            }else if(params.syncType == "config"){
                title = $TR.__getValueFromTag($TR.PRODIQ001_TAG122,'Configuration Sync in Progress') + "...";
            }else if(params.syncType == "ib"){
                title = $TR.__getValueFromTag($TR.PRODIQ001_TAG043,'Downloading the selected Installed Products. Please wait') + "...";
            }else if(params.syncType == "purge"){
                title = $TR.__getValueFromTag($TR.PRODIQ001_TAG103,'Data purge in Progress') + "...";
            }
            this.setProgressTitle(title);
        },
        
        setProgressTitle : function(title){
            title = '<span class="title-text">' + (title || '') + '</span></div>';
            this.setTitle(title);
        }
    });
};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\record.js
/**
 * 
 */

(function(){
    
    var recordImpl = SVMX.Package("com.servicemax.client.installigence.record");

recordImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.record.Record", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.record', __views : null, __title : null, __meta : null, __selectedNode:null,
        __parentPanelContext: null,
        constructor: function(config) { 
            
            this.__meta = config.meta;
            this.__parentPanelContext = config.parentPanelContext;
            // create different views
            this.__views = this.__createViews();
            this.__title = $TR.__getValueFromTag($TR.PRODIQ001_TAG028,'Select an item from the tree');
            config = Ext.apply({
                //title: this.__title,
                title: $TR.__getValueFromTag($TR.PRODIQ001_TAG141,'Overview'),
                titleAlign: 'center',
                ui: 'svmx-white-panel',
                listeners: {
                    collapse: function () {
                       this.up().doLayout();
                    },
                    expand: function () {
                        this.up().doLayout();
                    }
                },
                layout: {type : "card"},
                items: this.__views
            }, config || {});
            
            config.tree.on("node_selected", function(node){
                this.__selectedNode = node;
                this.__render(node);
            }, this);
            
            config.tree.on("reset", function(node){
                this.__resetView();
            }, this);
            
            this.callParent([config]);
           this.__setup();  
        },
        
        __resetView : function(){
            this.removeAll(true);
            //this.setTitle(this.__title);
            this.__parentPanelContext.setTitle(this.__title);
            this.__views = this.__createViews();
            var i, l = this.__views.length;
            for(i = 0; i < l; i++){
                this.add(this.__views[i]);
            }
        },
        
        __createViews : function(){
            var viewClasses = [
                "IBRecord", "LocationRecord", "SubLocationRecord", "AccountRecord"
            ];
            var views = [];
            for(var i = 0; i < viewClasses.length; i++){
                var v = SVMX.create("com.servicemax.client.installigence.record." + viewClasses[i], { root : this, meta : this.__meta});
                v.cardIndex = i;
                views.push(v);
            }
            
            return views;
        },
        
        __render : function(node){
            var v = this.__getViewForNode(node);
            
            if(!v) return; // should not happen!
            
            this.getLayout().setActiveItem(v.cardIndex);
            v.renderNode(node);
            v.currentlyActive = true;
        },
        
        __getViewForNode : function(node){
            var i, v = this.__views, l = v.length;
            for(i = 0; i < l; i++){
                v[i].currentlyActive = false;
                if(v[i].getViewType() == node.nodeType){
                    return v[i];
                }
            }
        },

        __getActiveView : function(){
            var i, v = this.__views, l = v.length;
            for(i = 0; i < l; i++){
                if(v[i].currentlyActive){
                    return v[i];
                }
            }
        },

        refreshData : function(){
            this.__getActiveView().refreshData();
        },

        __setup : function() {
                 var me =this;
                this.meta.bind("MODEL.UPDATE", function(evt){
                 
                  if(me.__selectedNode && me.__selectedNode.nodeType == "IB"){ //TODO: Should handle for for all type of nodes(IB, location and sub-location)
                   this.__resetView();
                    this.__render(me.__selectedNode);
                    
                 }
                    
                }, this);
            }
    });
    Ext.define("com.servicemax.client.installigence.record.errorConfirmationView", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.errorConfirmationView',
        __okButtonToConfirm : null, __cancelButtonToConfirm : null, __errorConfirmationLabel : null,
        constructor: function(config) { 
            var me =this;
            
            this.__parent = config.parent;

            this.__errorConfirmationLabel = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXPanel", {
                layout: 'vbox', border: false, width: '100%', style: 'border: none !important;'

            });

            this.__okButtonToConfirm = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton", {
                hidden : true, text: $TR.__getValueFromTag($TR.PRODIQ001_TAG112,'Ok'), flex: 1, margin: '2,2,2,2',
                handler : SVMX.proxy(this, function() {
                    //Save Directly -> saveConfirm
                    
                    this.__parent.__pl.saveConfirm();
                    this.__parent.__errorConfirmationPanel.hide();
                    this.__okButtonToConfirm.hide();
                    this.__cancelButtonToConfirm.hide();
                    this.__parent.root.tree.updateRecordName(this.__parent.__pl.__record.__r.Id, this.__parent.__pl.__record.__r.Name);
                })
            });

            this.__cancelButtonToConfirm = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton", {
                hidden : true, text: $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'), flex: 1, margin: '2,2,2,2',
                handler : SVMX.proxy(this, function() {
                    //Save Directly -> saveConfirm
                    
                    this.__parent.refreshData();
                    this.__parent.__errorConfirmationPanel.hide();
                    me.__okButtonToConfirm.hide();
                    me.__cancelButtonToConfirm.hide();
                })
            });

			this.__errorConfirmationButtons = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXPanel", {
                layout: 'hbox', width: '30%',style: 'border: none !important;', border: false, defaults: {style: 'border: none !important; margin: 0px -30px'},
                items: [this.__okButtonToConfirm, this.__cancelButtonToConfirm]
            });
            config = Ext.apply({
                layout : {type : "vbox", align:'center', pack: 'center'},
                overflowY : "auto",
                cls : "grid-panel-borderless",
                border: false,
                items : [
                    this.__errorConfirmationLabel, this.__errorConfirmationButtons
                ]
            }, config || {});
            
            this.callParent([config]);
        },

        hideErrorPanel: function(){

        }
    });

    Ext.define("com.servicemax.client.installigence.record.RecordView", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.recordview',
        __root : null, __bInitialized : false, __node : null, __pl : null, __bPageLayoutInitialized : false,
        __objectName : null, __searchText : null, __readOnly : false, __meta : null,__errorConfirmationPanel : null,
        constructor: function(config) { 
            
            var me = this;
            // search
            this.__searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                cls: 'toolbar-search-textfield', width: '100%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG039,'Find an attribute') + '...', enableKeyEvents : true,
                listeners : {
                    keyup : function(that, e, opts) {
                        clearTimeout(me.__filterTimeout);
                        me.__filterTimeout = setTimeout(function(){
                            me.__filterFields(that.getValue());
                        }, 25);
                    }
                }
            });
            
            this.__errorConfirmationPanel = SVMX.create("com.servicemax.client.installigence.record.errorConfirmationView", {
                hidden : true, autoRender : true, parent : this, width: '100%', layout : 'vbox', border: false
            });

            config = Ext.apply({
                layout : {type : "column"},
                overflowY : "scroll",
                width: '100%',
                cls : "grid-panel-borderless",
                items : [],
                dockedItems : [
                   /* {dock : 'top', xtype : 'toolbar', margin : '0',
                        items : [ this.__searchText ]
                    },*/
                    {dock : 'top', xtype : 'toolbar', margin : '0',
                        items : [ this.__errorConfirmationPanel]
                    }
                ]
            }, config || {});
            
            this.__root = config.root;
            this.__objectName = config.objectName;
            this.__bInitialized = false;
            this.__readOnly = config.readOnly;
            this.__meta = config.meta;
            this.callParent([config]);
        },
        
        showErrorConfirmation : function(dataValidationResult){
            var bErrors = dataValidationResult.errors;
            var bWarnings = dataValidationResult.warnings;
            if(bErrors.length > 0 || bWarnings.length > 0){
                var errors = "";
                var errorNumber = 1;

                this.__errorConfirmationPanel.__errorConfirmationLabel.removeAll();

                if(bErrors.length > 0){

                    this.__errorConfirmationPanel.__okButtonToConfirm.hide();
                    this.__errorConfirmationPanel.__cancelButtonToConfirm.hide();
                    
                    this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: $TR.__getValueFromTag($TR.PRODIQ001_TAG083,'Error(s)'),
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'margin:0px 17px;'
                                });

                    var i=0;
                    for(i=0; i< bErrors.length; i++){
                        
                        if(errors.length === 0){
                            if(bErrors.length > 1){
                                this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: " • " + bErrors[i].message,
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                                });
                            }else{
                                this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: bErrors[i].message,
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                                });
                            }
                        }else{
                            this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                xtype: 'label',
                                text: " • " + bErrors[i].message,
                                padding: '4px',
                                width: '100%',
                                    border: false,
                                style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                            });
                        }
                    }
                } else if(bWarnings.length > 0){

                    this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: $TR.__getValueFromTag($TR.PRODIQ001_TAG084,'Warning(s)'),
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'margin:0px 17px;'
                                });

                    this.__pl.okcallback = dataValidationResult.okCallBack;
                    for(i=0; i< bWarnings.length; i++){
                        
                        if(errors.length === 0){
                            if(bWarnings.length > 1){
                                this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: " • " + bWarnings[i].message,
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                                });
                            }else{
                                this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                    xtype: 'label',
                                    text: bWarnings[i].message,
                                    padding: '4px',
                                    width: '100%',
                                    border: false,
                                    style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                                });
                            }
                        }else{
                            this.__errorConfirmationPanel.__errorConfirmationLabel.add({
                                xtype: 'label',
                                text: " • " + bWarnings[i].message,
                                padding: '4px',
                                    width: '100%',
                                    border: false,
                                style: 'text-wrap: normal !important; color:red;margin:0px 17px;'
                            });
                        }
                    }
                    this.__errorConfirmationPanel.__okButtonToConfirm.show();
                    this.__errorConfirmationPanel.__cancelButtonToConfirm.show();
                }
                this.__errorConfirmationPanel.show();
            }
        },

        hideErrorConfirmation : function(){
            this.__errorConfirmationPanel.hide();
        },

        initComponent: function() {
            this.on('beforeadd', function(me, field){
              if (!field.allowBlank)
                field.labelSeparator += '<span style="color: rgb(255, 0, 0); padding-left: 2px;">*</span>';
            });
            this.callParent(arguments);
        },
        
        __filterFields : function(val){
            var items = this.items || [], i , l = items.length, item, lbl, re;
            
            if(l == 0) return;

            for(i = 0; i < l; i++){
                item = items.getAt(i);
                if(!val) {
                    // Note: Use jQuery for speed. Tests show this is over 10-50x faster
                    $('#'+item.getId()).show();
                    //item.setVisible(true);
                }else{
                    lbl = item.getFieldLabel();
                    re = new RegExp( val, 'i' );
                    if(re.test(lbl)){
                        $('#'+item.getId()).show();
                        //item.setVisible(true);
                    }else{
                        $('#'+item.getId()).hide();
                        //item.setVisible(false);
                    }
                }
            }
        },
        
        getViewType : function(){
            throw new Error("This method should be overridden!");
        },
        
        getPriorityFields : function(){
            throw new Error("This method should be overridden!");
        },
        
        getHiddenFields : function(){
            throw new Error("This method should be overridden!");
        },
        
        renderNode : function(node){
            //this.__root.setTitle(node.text);
            this.__root.__parentPanelContext.setTitle(node.text);
            this.__node = node;
        
            if(!this.__bInitialized && !this.__bPageLayoutInitialized){
                this.__init();
            }else if(this.__bInitialized){
                this.refreshData();
				this.hideErrorConfirmation();
            }
        },
        
        __init : function(){
            SVMX.getCurrentApplication().blockUI();
            this.__bPageLayoutInitialized = true;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_PAGELAYOUT", this, 
                    {request : { context : this, objectName : this.__objectName }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onGetPageLayoutCompleted : function(pl){
        	this.__pl = SVMX.create("com.servicemax.client.installigence.record.PageLayout", {objectName : this.__objectName, root: this.__root, requiredFields : this.getRequiredField(this.getPriorityFields())});
            //this.__pl.init(pl.DescribeResult, pl.dataValidationRules);
			this.__pl.init(pl);
            this.__bInitialized = true;
            this.__layout();
        },
        
        __layout : function(){
        	SVMX.getCurrentApplication().unblockUI();
            var labelLength;
            var allFields = this.__pl.fields, i, l = allFields.length, f, type, cls, fieldElem, name, ro, ab, isAutoNumber, fields = [];
            var priorityFields = this.getFields(this.getPriorityFields());
            var requiredFields = this.getRequiredField(this.getPriorityFields());
            var hiddenFields = this.getFields(this.getHiddenFields());
            var priorityUIFields = {};
            var recordTypeMapping = this.__pl.describeLayoutResult;
            //var nameSearchInfo = this.__pl.nameSearchInfo;
            
            if(this.getPriorityFields().length > 0){
                for(var i = 0; i < l; i++){
                    if(priorityFields[allFields[i].name]){
                        fields.push(allFields[i]);
                    }
                } 
            }else{
                fields = allFields; 
            }

            var fieldElems = [];
            i = 0; l = fields.length;
            for(i = 0; i < l; i++){
                f = fields[i]; type = f.type, name = f.name, isAutoNumber = f.autoNumber;
                if(type == "id") continue;
                
                if(     name == "SystemModstamp"   || name == "LastReferencedDate" || name == "LastViewedDate"
                    ||  name == "LastActivityDate" || name == "CreatedDate"        || name == "CreatedById"
                    ||  name == "LastModifiedById" || name == "LastModifiedDate"   || name == "OwnerId") continue; //||  hiddenFields[name] (we are no longer supporting hidden fields.)
                    
                if(name == "RecordTypeId"){
                    cls = "RecordTypeField";
                }else if(type == "reference"){
                    cls = "ReferenceField";
                }else if(type == "string"){
                	if(window.parent.SVMX.getClient().isBarCodeEnabled())
                    	cls = "StringFieldBarIcon";
                    else
                    	cls = "StringField";
                }else if(type == "boolean"){
                    cls = "BooleanField";
                }else if(type == "picklist"){
                    cls = "PicklistField";
                }else if(type == "date"){
                    cls = "DateField";
                }else if(type == "datetime"){
                    cls = "DatetimeField";
                }else{
                    // default to 'string' type
                    if(window.parent.SVMX.getClient().isBarCodeEnabled())
                    	cls = "StringFieldBarIcon";
                    else
                    	cls = "StringField";
                }
                
                ro = this.__readOnly || f.readOnly;
                // Make non-createable/updateable fields readonly
                if(!f.__f.createable || !f.__f.updateable){
                    ro = true;
                }
                // Defect Fix 014330 - If field type is Auto Number then change required attribute to false so that red asterix sign should not come
                ab = !f.required; // Default value base on database required attribute
                // If Field type is Auto number then mark it as not required.
                if(isAutoNumber === true)
                	ab = true;
                //Override DataBase required attribute if it is defined in the field set.
                if(requiredFields[name]){
                    ab =  !requiredFields[name];
                }
                fieldElem = SVMX.create("com.servicemax.client.installigence.ui.comps." + cls, 
                        {parent : this, fld : f, fieldLabel : f.label, labelAlign : "top", width:'90%', margin:'5, 30',labelSeparator : "", readOnly : ro, allowBlank : ab, meta : this.__meta, recordTypeMappings : recordTypeMapping});
                
                if(priorityFields[name]){
                    priorityUIFields[priorityFields[name]] = fieldElem;
                    continue;
                }
                fieldElems.push(fieldElem);
            }
            this.add(fieldElems);

            //now insert the priority fields
            var ipr, iprlength = this.getPriorityFields().length, nxtFldPos = 1;
            for(ipr = 1; ipr <= iprlength; ipr++){
                if(priorityUIFields[ipr]){
                    this.insert(nxtFldPos - 1 , priorityUIFields[ipr]);
                    nxtFldPos++;
                }
            }
            
            var me = this;
            setTimeout(function(){
                me.fireEvent("all_fields_added", this);
                me.refreshData();
            }, 1600);
        },
        
        getFields : function(fields){
            var i = 0, ilength = fields.length;
            var fieldsPriority = {};
            for(i = 0; i < ilength; i++){
                fieldsPriority[fields[i].name] = fields[i].priority;
            }
            return fieldsPriority;
        },

        getRequiredField : function(fields){
            var i = 0, ilength = fields.length;
            var fieldsRequired = {};
            for(i = 0; i < ilength; i++){
                fieldsRequired[fields[i].name] = fields[i].required;
            }
            return fieldsRequired;
        },
        
        refreshData : function(){
            //first unblock the UI if ite already blocked.
            SVMX.getCurrentApplication().unblockUI();
            SVMX.getCurrentApplication().blockUI();
            
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_PAGEDATA", this, {request : { 
                        context : this, objectName : this.__objectName, id : this.__node.recordId
                    }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onGetPageDataCompleted : function(data){
            SVMX.getCurrentApplication().unblockUI();
            var dr = SVMX.create("com.servicemax.client.installigence.record.DataRecord", {r : data});
            this.__pl.setRecord(dr);
			
			this.root.tree.updateRecordName(this.__pl.__record.__r.Id, this.__pl.__record.__r.Name);
			//this.root.setTitle(this.__pl.__record.__r.Name);
            this.root.__parentPanelContext.setTitle(this.__pl.__record.__r.Name);
        }
    });
    
    Ext.define("com.servicemax.client.installigence.record.IBRecord", {
        extend: "com.servicemax.client.installigence.record.RecordView",
        alias: 'widget.installigence.ibrecord',
        __root : null, __bInitialized : false, __node : null, __pl : null, __meta : null,
        
        constructor: function(config) { 
            config = Ext.apply({
                objectName : SVMX.getCustomObjectName("Installed_Product")
            }, config || {});
            this.__meta = config.meta;
            this.callParent([config]);
        },
        
        getViewType : function(){
            return "IB";
        },
        
        getPriorityFields: function(){
            return this.__meta.ibPriorityFields || [];
        },
        
        getHiddenFields: function(){
            return this.__meta.ibHiddenFields || [];
        }
    });
    
    Ext.define("com.servicemax.client.installigence.record.LocationRecord", {
        extend: "com.servicemax.client.installigence.record.RecordView",
        alias: 'widget.installigence.locationrecord',
        
        constructor: function(config) { 
            
            config = Ext.apply({
                objectName : SVMX.getCustomObjectName("Site")
            }, config || {});
            
            this.callParent([config]);
        },
        
        getViewType : function(){
            return "LOCATION";
        },
        
        getPriorityFields: function(){
            return this.__meta.locPriorityFields || [];
        },
        
        getHiddenFields: function(){
            return this.__meta.locHiddenFields || [];
        }
    });

    Ext.define("com.servicemax.client.installigence.record.SubLocationRecord", {
        extend: "com.servicemax.client.installigence.record.RecordView",
        alias: 'widget.installigence.locationrecord',
        
        constructor: function(config) { 
            
            config = Ext.apply({
                objectName : SVMX.getCustomObjectName("Sub_Location")
            }, config || {});
            
            this.callParent([config]);
        },
        
        getViewType : function(){
            return "SUBLOCATION";
        },
        
        getPriorityFields: function(){
            return this.__meta.locPriorityFields || [];
        },
        
        getHiddenFields: function(){
            return this.__meta.locHiddenFields || [];
        }
    });
    
    Ext.define("com.servicemax.client.installigence.record.AccountRecord", {
        extend: "com.servicemax.client.installigence.record.RecordView",
        alias: 'widget.installigence.accountrecord',
        __root : null,
        
        constructor: function(config) { 
            config = Ext.apply({
                objectName : "Account",
                readOnly : true
            }, config || {});
            
            this.__root = config.root;
            this.callParent([config]);
        },
        
        getViewType : function(){
            return "ACCOUNT";
        },
        
        getPriorityFields: function(){
            return this.__meta.accPriorityFields || [];
        },
        
        getHiddenFields: function(){
            return this.__meta.accHiddenFields || [];
        }
    });
    
    recordImpl.Class("PageLayout", com.servicemax.client.lib.api.Object, {
        fields : null,
        __requiredFields : null,
        bindings : null,
        __root : null,
        __objectName : null,
        __record : null,
        objectDescribe : null,
        lookupDef : null, 
        masterDependentArray :  null,
        __dataValidationRules : null,
        __lookupValueToDisplayValue : {},
        me : this,
        describeLayoutResult : null,
        
        __constructor : function(config){
            this.__base();
            this.fields = [];
            this.bindings = [];
            this.__root = config.root;
            this.__objectName = config.objectName;
			me = this;
            this.objectDescribe = null;
            this.lookupDef = null;
            this.masterDependentArray = [];
            this.describeLayoutResult = null;
            this.__requiredFields = config.requiredFields;
        },
        
        init : function(pl){
        	this.objectDescribe = pl.DescribeResult;
        	//Update Dependent picklist information
        	SVMX.create("com.servicemax.client.installigence.utils.dependentPickList", {param : this.objectDescribe});
        	
        	var i , fields = this.objectDescribe.fields, l = fields.length, fld;
            for(i = 0; i < l; i++){
                if(fields[i].type == 'picklist'){
                    fld = SVMX.create("com.servicemax.client.installigence.record.PicklistPageField", {parent : this});
                }else if(fields[i].type == 'boolean'){
                    fld = SVMX.create("com.servicemax.client.installigence.record.BooleanPageField", {parent : this});
                }else{
                    fld = SVMX.create("com.servicemax.client.installigence.record.PageField", {parent : this});
                }
                
                fld.init(fields[i]);
                this.fields.push(fld);
            }
            
            SVMX.sort(this.fields, "label");
			
			this.__dataValidationRules = pl.dataValidationRules;
            if(pl.describeLayoutResult && pl.describeLayoutResult.recordTypeMappings && pl.describeLayoutResult.recordTypeMappings.length > 0)
                this.describeLayoutResult = pl.describeLayoutResult.recordTypeMappings;
        },
        
        registerBinding : function(b){
            this.bindings.push(b);
        },
        
        setRecord : function(r){
            var i, l = this.bindings.length;
            for(i = 0; i < l; i++){
                this.bindings[i].setRecord(r);
                this.bindings[i].push();
            }
            this.__recordName = r.__r.Name;
            this.__record = r; 
            this.__updateDependetPickList();
        },
        
        saveConfirm : function(){
            var d = this.okcallback.handler.call(this.okcallback.context, this.__objectName, this.fields, this.__record, this.__dataValidationRules);
            
            d.done(this.onSaveComplete);
        },
        
        __getDependencyChainOfFields : function(){
        	var i, masterPickListVsDependentPickList = this.objectDescribe.masterPickListVsDependentPickList, l = masterPickListVsDependentPickList.length;
        	for(i = 0; i < l; i++){
        		this.__resolveDependencyChain(masterPickListVsDependentPickList[i].dependentField,masterPickListVsDependentPickList[i].masterField);
        	}
        },
       
        __resolveDependencyChain : function(dependentField, masterField){
        	var i, masterPickListVsDependentPickList = this.objectDescribe.masterPickListVsDependentPickList, l = masterPickListVsDependentPickList.length;
        	for(i = 0; i < l; i++){
        		if(dependentField === masterPickListVsDependentPickList[i].masterField){
        			this.__resolveDependencyChain(masterPickListVsDependentPickList[i].dependentField,masterPickListVsDependentPickList[i].masterField);
        		}
        		else{
        			var j, m = this.masterDependentArray.length, isInArray = false;
        			for(j = 0; j < m; j++){
        				if(this.masterDependentArray[j].master === masterField && this.masterDependentArray[j].dependent === dependentField)
        					isInArray = true;
        			}
        			if(!isInArray)
        				this.masterDependentArray.push({"master" : masterField, "dependent" : dependentField});
        		}
        	}
        },
        
        // Update dependent picklist values. 
        __updateDependetPickList : function(){
        	this.__getDependencyChainOfFields();
        	var i, j, fields = this.fields, m = fields.length, masterDependentArray = this.masterDependentArray, l = masterDependentArray.length;
        	for(i = 0; i < l; i++){
        		for(j = 0; j < m; j++){
        			if(masterDependentArray[i].master === fields[j].name){
        				var currentValue = this.__record.__r[fields[j].name];
    					fields[j].updateDependentPickList(currentValue,false); // Do not clean set value 
    					break;
        			}
        		}
        	}
        },
        
        save : function(){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.SAVE_RECORD", this, {
                        request : { context : this, requiredFields : this.__requiredFields, objectName: this.__objectName, meta : this.fields, record : this.__record, recordName : this.__recordName, root : this.__root, handler : this.onSaveComplete, dataValidationRules : this.__dataValidationRules}
                });
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onSaveComplete: function(resp){
            if(resp && (resp.errors || resp.warnings) && (resp.errors.length > 0 || resp.warnings.length > 0) ){
				this.root.tree.updateRecordWithErrorStar(this.record.__r.Id, this.record.__r.Name);
                    
                //Show Data Validation Error/Confirmation.
                for (var i = this.root.__views.length - 1; i >= 0; i--) {
                    if(this.root.__views[i].__objectName === this.objectName){
                        this.root.__views[i].showErrorConfirmation(resp);
                        break;
                    }
                } 
            }
            else{
                //Hide Data Validation Error/Confirmation.
                
                for (var i = me.__root.__views.length - 1; i >= 0; i--) {
                    if(me.__root.__views[i].__objectName === me.__objectName){
                        me.__root.__views[i].hideErrorConfirmation();
                        break;
                    }
                }

                // if(me.__recordName && me.__recordName !== me.__record.__r.Name){
                // // Update IB tree record name
                //     me.__root.tree.updateRecordName(me.__record.__r.Id, me.__record.__r.Name);
                // }

                if(this.recordName && this.record.__r.Id && this.record.__r.Name){
                // Update IB tree record name
                    me.__root.tree.updateRecordName(this.record.__r.Id, this.record.__r.Name);
                    //this.root.setTitle(me.__record.__r.Name);
                    this.root.__parentPanelContext.setTitle(me.__record.__r.Name);
                    me.__updateRecordNameTable(this.record.__r.Id,this.record.__r.Name);
                }
                
                me.__updateDependentRecords(me.__objectName, me.__record.__r, me.fields);
            }
        },
        __updateRecordNameTable : function(recordId,recordName){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.UPDATE_RECORD_NAME_TABLE", this, {
                        request : { context : this, recordId: recordId, recordName : recordName }
                });
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        recordNameUpdateSuccess : function() {
            // alert('record update');
        },
        __updateDependentRecords: function(objectName, record, fields){
            var fieldLocalId = '';
            var recNameField = '';
            for(var i=0; i< fields.length; i++){

                if(fields[i].type === 'reference'){
                    console.log('Reference Field:- ' + fields[i].name);
                }

                if(fields[i].type === 'reference' && record[fields[i].name] && record[fields[i].name].indexOf('_local_') != -1){
                    me.__createDependentEntry(record[fields[i].name], objectName, record['Id'], fields[i].name);

                    fieldLocalId = record[fields[i].name];
                    recNameField = me.__lookupValueToDisplayValue[record[fields[i].name]];
                    me.__createRecordNameEntry(fieldLocalId, recNameField);
                }
            }
        },

        //LUMA: Renaming RecordName with SFRecordName
        __createRecordNameEntry: function(fieldLocalId, recNameField){
            
            if(!fieldLocalId || fieldLocalId.length === 0 || !recNameField || recNameField.length === 0){
                return;
            }

            var cols = [{name: "Id"}, {name: "Name"}];
            var colValue = {Id: fieldLocalId, Name: recNameField};
            var colValues = [colValue];

            var qoInsert = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            qoInsert.insertInto("SFRecordName")
            .columns(cols)
            .values(colValues)
            .execute()
            .done(function(resp){
                if(resp){
                    console.log("After Insert of RecordName Table");
                }
            });
        },

        __createDependentEntry: function(fieldValue, objectName, recId, fieldName){
            var d = SVMX.Deferred();
            var cols = [{name: "parent_object_name"}, {name: "local_id"}, {name: "parent_record_id"}, {name: "parent_field_name"}];

            var colValue = {parent_object_name: objectName, local_id: fieldValue, parent_record_id: recId, parent_field_name: fieldName};
            var colValues = [colValue];
            var whereCondition = "parent_record_id = '" + recId + "' AND parent_field_name = '" + fieldName + "'";
            var updateSet = "parent_object_name = '" + objectName + "', local_id = '" + fieldValue + "', parent_record_id = '" + recId + "', parent_field_name = '" + fieldName + "'";
            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("parent_object_name, local_id, parent_record_id, parent_field_name").from("SyncDependentLog")
            .where(whereCondition).execute()
            .done(function(resp){
                if(resp && resp.length > 0){
                    var qoUpdate = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
                    qoUpdate.update("SyncDependentLog")
                    .setValue(updateSet)
                    .where(whereCondition).execute()
                    .done(function(resp){
                        d.resolve();
                    });
                }else{
                    var qoInsert = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
                    qoInsert.insertInto("SyncDependentLog")
                    .columns(cols)
                    .values(colValues)
                    .execute()
                    .done(function(resp){
                        d.resolve();
                    });
                }
            });
        }
    }, {});
    
    recordImpl.Class("PageField", com.servicemax.client.lib.api.Object, {
        _parent : null, label : null, type : null, name : null, __f : null,
        _binding : null, required : false, readOnly : false, autoNumber : false, dependetFields : [], masterPickListFieldDependentPickListField : [], 
        __constructor : function(config){
            this.__base();
            this._parent = config.parent;
            this.dependetFields = [];
            this.masterPickListFieldDependentPickListField = [];
        },
        
        init : function(fldInfo){
            this.label = fldInfo.label;
            this.name = fldInfo.name;
            this.type = fldInfo.type;
            this.readOnly = !fldInfo.updateable;
            this.required = !fldInfo.nillable;
            this.referenceTo = fldInfo.referenceTo;
            this.autoNumber = fldInfo.autoNumber;
            this.__f = fldInfo;
            
            if(this._parent.objectDescribe.hasOwnProperty("masterPickListVsDependentPickList") && this._parent.objectDescribe.masterPickListVsDependentPickList != null){
            	masterPickListFieldDependentPickListField = this._parent.objectDescribe.masterPickListVsDependentPickList;
            	var i, l = masterPickListFieldDependentPickListField.length;
            	for(i = 0; i < l; i++){
            		if(this.name === masterPickListFieldDependentPickListField[i].masterField){
            			this.dependetFields.push(masterPickListFieldDependentPickListField[i].dependentField);
            		}
            	}
            	
            }
        },
        
        getBinding : function(){
            if(this._binding == null){
                this._binding = SVMX.create("com.servicemax.client.installigence.record.PageFieldBinding", 
                        {name : this.name});
                this._parent.registerBinding(this._binding);
            }
            
            return this._binding;
        },
        
        register : function(field){
            var me = this;
            switch(field.getXType()) {
                case "inst.stringfield" :
                case "inst.referencefield" :
                    field.on('blur', function(context, event, eOpts){
                    	if(field.value == field.rawValue){
							var value = field.value || "";
							if(me._parent.__record && me._parent.__record.__r[me.name] != value){
								me.getBinding().pull();

								if(field.getXType() === "inst.referencefield"){
								   me._parent.__lookupValueToDisplayValue[me._parent.__record.__r[me.name]] = value;
								}
								me._parent.save();
							}
						}else{
							var value = field.rawValue || "";
							if(me._parent.__record && me._parent.__record.__r[me.name] != value){
								me.getBinding().pull();

								if(field.getXType() === "inst.referencefield"){
								   me._parent.__lookupValueToDisplayValue[me._parent.__record.__r[me.name]] = value;
								}
								me._parent.save();
							}
						}
                    });
                    break;
                case "inst.datefield" :
                case "svmx.datefield" :
                    field.on('change', function(context, event, eOpts){
                        var value = field.value || "";
                        if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                            me.getBinding().pull();
                            me._parent.save();
                        }
                    });
                    break;
                case "inst.picklistfield" :
                    field.on('select', function(combo, records, eOpts) {
                        var value = field.value || "";
                        if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                           // Update All Dependent picklist field of this value. Also clean set value as per the salesforce functionality.
                        	me.updateDependentPickList(value, true);
                        	me.getBinding().pull();
                            me._parent.save();
                        }
                    });
                    //Fixed: 028736
                    field.on('change', function(combo, newValue,oldValue, eOpts) {
                        var value = field.value;

                        if (newValue === null || newValue.length === 0) {
                            if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                               // Update All Dependent picklist field of this value. Also clean set value as per the salesforce functionality.
                                me.updateDependentPickList(value, true);
                                me.getBinding().pull();
                                me._parent.save();
                            }
                        }
                    });
                    break;
                case "inst.booleanfield" :
                    field.on('change', function(field, newValue, oldValue, eOpts) {
                        var value = field? field.value: "";
                        if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                        	// Update All Dependent picklist field of this value. Also clean set value as per the salesforce functionality.
                        	me.updateDependentPickList(value.toString(), true);
                        	me.getBinding().pull();
                            me._parent.save();
                        }
                    });
                    break;
                case "svmx.timefield" :
                    field.on('select', function(combo, records, eOpts) {
                        var value = field.value || "";
                        if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                            me.getBinding().pull();
                            me._parent.save();
                        }
                    });
                    break;
                case "inst.recordtypefield" :
                    field.on('select', function(combo, records, eOpts) {
                        var value = field.value || "";
                        if(me._parent.__record && me._parent.__record.__r[me.name] != value){
                            me.updatePickListForRecordType(value, field.recordTypeMappings);
                            me.getBinding().pull();
                            me._parent.save();
                        }
                    });
                    break;
            }
            
        },
        
        updatePickListForRecordType : function(currentValue, recordTypeMappings){
            for(var i=0; i<recordTypeMappings.length; i++){
                if(recordTypeMappings[i].recordTypeId === currentValue || recordTypeMappings[i].name === currentValue){
                    //picklistsForRecordType
                }
            }
        },
        
        updateDependentPickList : function(currentValue,cleanSetValue){
        	var i, values = this.getListOfValues(), l = values.length, dependentFieldArray = [];
        	for(i = 0; i < l; i++){
        		if(currentValue == values[i].value && values[i].hasOwnProperty("dependendPicklist")){
        			var dependentArray = values[i].dependendPicklist, j, m = dependentArray.length;
        			if(dependentArray.length > 0){
	        			for(j = 0; j < m; j++){
	        				var dpFieldAPIName = dependentArray[j].fieldAPIName, dpValueIndices = dependentArray[j].value, allPickListValues = null;
	        				dependentFieldArray.push(dpFieldAPIName);
	        				dpValueIndices = dpValueIndices.split(';');
	        				allPickListValues = this.getPickListValueForFieldName(dpFieldAPIName);
	        				var result = [], k, x, allPVLength = allPickListValues.length;
	        				for(k = 0, x = 0; k < allPVLength; k++){
								if(dpValueIndices[x] == k){
									var data = {};
									data.display = allPickListValues[k].label; 
									data.value 	= allPickListValues[k].value;
									result.push(data);
									x++;
								}
							}
	        				this.__updateStoresForDependent(dpFieldAPIName,result,cleanSetValue);
	        	       	}
	        		}
        			else{
        				// If for the master picklist value, no dependent indices found then empty the sotre and store set value.
        				var j, depndentFields = this.dependetFields, m = depndentFields.length;
        				for(j = 0; j < m; j++){
        					this.__updateStoresForDependent(depndentFields[j],[],true);
        					this.__updateDependencyChain(depndentFields[j],true);
        				}
        			}
        		}	
        	}
        	if(dependentFieldArray.length > 0){
        		l = dependentFieldArray.length;
        		for(i = 0; i < l; i++){
        			this.__updateDependencyChain(dependentFieldArray[i],cleanSetValue);
        		}
        	}
        }, 
        
        __updateDependencyChain : function(dependentField,cleanSetValue){
        	var i, l = masterPickListFieldDependentPickListField.length;
        	for(i = 0; i < l; i++){
        		if(dependentField === masterPickListFieldDependentPickListField[i].masterField){
        			this.__updateStoresForDependent(masterPickListFieldDependentPickListField[i].dependentField,[],cleanSetValue);
        			this.__updateDependencyChain(masterPickListFieldDependentPickListField[i].dependentField,cleanSetValue);
        		}
        	}
        }, 
        
        __updateStoresForDependent : function(dpFieldAPIName, data, cleanSetValue){
        	var i, bindings  = this._parent.bindings, l =  bindings.length;
        	for(i = 0; i < l; i++){
        		if(bindings[i].__name === dpFieldAPIName){
        			bindings[i].updateStore(data);
        			if(cleanSetValue){
            			bindings[i].setter("");
            		}
        			bindings[i].pull();
        		}
        	}
        }, 
        
        getPickListValueForFieldName : function(fieldName){
        	var fields = this._parent.fields, i, l = fields.length, ret = [];
        	for(i = 0; i < l; i++){
        		if(fields[i].name === fieldName){
        			ret = fields[i].__f.picklistValues;
        			break;
        		}
        	}
        	return ret;
        },
		
		getListOfValues : function(){
        	return this.__f.picklistValues;
        }
        
    }, {});
    
    recordImpl.Class("PicklistPageField", recordImpl.PageField, {
    	 isDependentPickList : false, controllerName : null, 
    	__constructor : function(config){
            this.__base(config);
            this.isDependentPickList = false;
            this.controllerName = null;
        },
        
        init : function(fldInfo){
            this.__base(fldInfo);
           if(fldInfo.dependentPicklist){
            	this.isDependentPickList = true;
            	this.controllerName = fldInfo.controllerName;
            }
        }
    
    }, {});
    
    recordImpl.Class("BooleanPageField", recordImpl.PageField, {
        
        __constructor : function(config){
            this.__base(config);
        },
        
        init : function(fldInfo){
            this.__base(fldInfo);
            this.required = false;
        }
    
    }, {});
    
    recordImpl.Class("PageFieldBinding", com.servicemax.client.lib.api.Object, {
        __name : null, __record : null, setter : null, fieldUpdate : false,
        
        __constructor : function(config){
            this.__base();
            this.__name = config.name;
        },
        
        setRecord : function(r){
            this.__record = r;
        },
        
        getRecord : function(){
            return this.__record;
        },
        
        push : function(){
            this.setter(this.__record.pull(this.__name), true);
        },
        
        pull : function(){
            this.__record.push(this.__name, this.getter());
        }
        
    }, {});
    
    recordImpl.Class("DataRecord", com.servicemax.client.lib.api.Object, {
        __r : null,
        __constructor : function(config){
            this.__base();
            this.__r = config.r || {};
        },
        
        pull : function(name){
            return this.__r[name];
        },
        
        push : function(name, value){
            this.__r[name] = value;
        }
    }, {});
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\recordDetails.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\recordInformation.js
/**
 * 
 */

(function(){
	
	var documentsImpl = SVMX.Package("com.servicemax.client.installigence.recordInformation");

documentsImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.recordInformation.RecordInformation", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.recordInformation',
            
            __ibtree: null,
            __meta:  null,

        constructor: function(config) {	
            var me = this;
            config = config || {};
            this.__ibtree = config.ibtree;
            this.__meta   = config.meta;
            config.title = $TR.__getValueFromTag($TR.RECORD_VIEW_TITLE,'Select an item from the tree');
            config.titleAlign = 'center';
            config.ui = 'svmx-white-panel';
            config

                     
                     me.tabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel',{
                    
                    tabRotation: 0,
                    cls:'productiq-tabpanel',

                    tabBar: {
                        border: true,
                        style : 'background-color:transparent;'
                    },

                    items: []
                   });
            config.items = [me.tabPanel];
            this.callParent([config]);

        }
    });
	
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\root.js
/**
 * 
 */

(function(){
    
    var rootImpl = SVMX.Package("com.servicemax.client.installigence.root");

rootImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.root.Root", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.root',
        meta : null, home : null, findandget : null, navigationStack : null, progress : null, conflict : null,
        currentView : null, ibSearch : null,
        
        constructor: function(config) { 
            this.meta = config.meta;
            this.navigationStack = [];
             this.__registerForIbSearchActionCall(); 
            this.home = SVMX.create("com.servicemax.client.installigence.home.Home", { meta : this.meta, root : this });
            if(!SVMX.getCurrentApplication().isAppEmbedded()) {
                this.findandget = SVMX.create("com.servicemax.client.installigence.findandget.FindAndGet", { meta : this.meta, root : this });
                this.progress = SVMX.create("com.servicemax.client.installigence.progress.Progress", { meta : this.meta, root : this });
                this.conflict = SVMX.create("com.servicemax.client.installigence.conflict.Conflict", { meta : this.meta, root : this, sourceComponent : this.home.getMenu() });     
                this.findandget.cardIndex = 1;
                this.progress.cardIndex = 2;
            }
            
            this.ibSearch = SVMX.create("com.servicemax.client.installigence.ibSearch.IBSearch", { meta : this.meta, root : this , mvcEvent : "SEACH_INSTALLBASE"});
           

           if(!SVMX.getCurrentApplication().isAppEmbedded()) {
               this.ibSearch.cardIndex = 3;
           }else{
              this.ibSearch.cardIndex = 1; 
           }

            this.home.cardIndex = 0;
            
            config = Ext.apply({
                renderTo: SVMX.getDisplayRootId(),
                layout : {type : "card"},

                items : [this.home, this.findandget,this.progress, this.ibSearch]

            }, config || {});
            this.callParent([config]);
            
            this.currentView = this.home;
            //once the app loaded invoke LM
            this.invokeLM();
        },
        
        invokeLM : function(){
        	 var message = {
    			 action : 'START'
             };
        	 var evt = SVMX.create("com.servicemax.client.lib.api.Event", "INSTALLIGENCE.SEND_EXTERNAL_MSG", 
        			 this, {request : { context : this, message : message, appName : "LaptopMobile"}});
             com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        invokeLMSync : function(recordIds){
            var message = {
                action : 'SYNC',
                operation: 'INSERT_LOCAL_RECORDS',
                type: 'REQUEST',
                data: { recordIds: recordIds || [] }
            };
            this.__invokeLMSync(message);    
        },

        invokeLMWithResponse: function(message){
            this.__invokeLMSync(message);
        },

        __invokeLMSync: function(message){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "INSTALLIGENCE.SEND_EXTERNAL_MSG",
            this, {request : { context : this, message : message, appName : "LaptopMobile"}});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        handleFindAndGet : function(params){
            this.navigationStack.push(this.currentView);
            this.currentView = this.findandget;
            this.getLayout().setActiveItem(this.currentView.cardIndex);
            this.findandget.handleFocus(params);
        },

        handleConfigSync : function(params){
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.start({type : "config"});
            this.handleProgress({syncType : "config"});
        },

        handleIncrementalSync : function(params){
            var me = this;
            me.__checkForDependentRecords()
            .done( function(lstLocalRecIds){

                if(lstLocalRecIds && lstLocalRecIds.length > 0){
                    me.invokeLMSync(lstLocalRecIds);
                }else{
                    var syncService = SVMX.getClient().getServiceRegistry()
                        .getService("com.servicemax.client.installigence.sync").getInstance();
                    syncService.start({type: "incremental"});
                    me.showDataLoading();
                }
            });
        },
        
        handleInsertRecordsSync : function(recordIds){
        	 var syncService = SVMX.getClient().getServiceRegistry()
    	 			.getService("com.servicemax.client.installigence.sync").getInstance();
    	 	 syncService.start({type: "insert_local_records", recordIds: recordIds});
    	 	 this.showDataLoading();
        },        

        __checkForDependentRecords: function(){
            var lstLocalRecIds = [];
            var d = SVMX.Deferred();
            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("local_id").from("SyncDependentLog").execute()
            .done(function(resp){
                if(resp && resp.length > 0){
                    for(var i=0; i< resp.length; i++){
                        lstLocalRecIds.push(resp[i].local_id);
                    }
                }
                d.resolve(lstLocalRecIds);
            });
            return d;
        },

        handlePurgeSync : function(params){
            var me = this;
            var title = $TR.__getValueFromTag($TR.PRODIQ001_TAG095,'Purge Data') + "?";
            var message = $TR.__getValueFromTag($TR.PRODIQ001_TAG096,'Purging data may remove locally stored ProductIQ data that has grown over time to ensure only relevant data is stored. This process cannot be undone.');
            com.servicemax.client.installigence.ui.components.utils.Utils
            .confirm({title : title, message : message, buttonText : {yes : $TR.__getValueFromTag($TR.PRODIQ001_TAG097,'Purge'), no : $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel')}, handler : function(answer){
                if(answer == "yes"){
                    var syncService = SVMX.getClient().getServiceRegistry()
                        .getService("com.servicemax.client.installigence.sync").getInstance();
                    syncService.start({type: "purge"});
                    //me.showDataLoading();
                    me.handleProgress({syncType : "purge"});
                }
            }});
        },
        
        handleHome : function(params){
            this.currentView = this.home;
            this.getLayout().setActiveItem(this.currentView.cardIndex);
            this.currentView.handleFocus(params);
        },
        
        handleProgress : function(params){
            this.currentView = this.progress;
            this.getLayout().setActiveItem(this.currentView.cardIndex);
            this.currentView.handleFocus(params);
        },
        
        handleNavigateBack : function(){
            this.currentView = this.navigationStack.pop();
            this.getLayout().setActiveItem(this.currentView.cardIndex);
        },
        
        handleResetApplication : function(){
            var me = this;
            var title = $TR.__getValueFromTag($TR.PRODIQ001_TAG051,'Reset Application') + "?";
            var message = $TR.__getValueFromTag($TR.PRODIQ001_TAG034,'Resetting the application erases ALL ProductIQ data from your device and restores data and configuration from the server. This process cannot be undone.');
            com.servicemax.client.installigence.ui.components.utils.Utils
            .confirm({title : title, message : message, buttonText : {yes : $TR.__getValueFromTag($TR.PRODIQ001_TAG052,'Reset'), no : $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel')}, handler : function(answer){
                if(answer == "yes"){
                    me.handleFindAndGet({syncType : "reset"});
                }
            }});
        },

        showSyncConflicts : function(){
            this.conflict.show();
        },

        selectTreeNode : function(recordId){
            this.home.selectTreeNode(recordId);
        },
        
        blockUI : function(){
            SVMX.getCurrentApplication().blockUI();
        },
        
        unblockUI : function(){
            SVMX.getCurrentApplication().unblockUI();
        },

        showDataLoading : function(){
            SVMX.getCurrentApplication().showDataLoading();
        },

        hideDataLoading : function(){
            SVMX.getCurrentApplication().hideDataLoading();
        },

        showQuickMessage : function(type, message){
            SVMX.getCurrentApplication().showQuickMessage(type, message);
        },
        __registerForIbSearchActionCall : function(){
           
           SVMX.getClient().bind("IB_SEARCH_ACTION_CALL", function(evt){
               var data = SVMX.toObject(evt.data);
               
        	this.navigationStack.push(this.currentView);
        	this.currentView = this.ibSearch;
           	this.getLayout().setActiveItem(this.ibSearch.cardIndex);
           	this.ibSearch.handleFocus();
         	this.ibSearch.reSetScreen();
           

           }, this);           
       }
    });
    
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\search.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\svmxPopup.js
/**
 * This file creates the toolbar items like search, action and filter.
 * @class com.servicemax.client.insralligence.src.ui.toolbar.js
 * @author Madhusudhan HK
 *
 * @copyright 2015 ServiceMax, Inc.
 **/

(function(){

	var toolBarImpl = SVMX.Package("com.servicemax.client.installigence.svmxPopup");

	toolBarImpl.init = function(){
		Ext.define("com.servicemax.client.installigence.svmxPopup.popupMessage",
			{
				extend: "com.servicemax.client.ui.components.controls.impl.SVMXWindow",
               	alias: 'widget.installigence.svmxPopup',
               	width:'100%',
               	__popup: null,
                constructor: function(config) {
                	var me = this;
                	 config = Ext.apply({
                        extend: 'com.servicemax.client.ui.components.controls.impl.SVMXWindow',
    					alias: 'widget.installigence.ibToolBar',
   	 					height: config.height,
    					width: config.width,
    					layout: config.layout,
    					buttonAlign: config.buttonAlign,
    					closable: config.closable,
    					text : config.text,
    					title : config.title,
    					items: [
        					{
								xtype: 'form',
								frame: false,
								border: 0,
								layout: {
									type: 'hbox',
									align: 'middle'
								},
								fieldDefaults: {
									msgTarget: 'side',
									labelWidth: 55
								},
								items: [
									{
										xtype: 'container',
										flex: 1,
										padding: 2,
										layout: {
											type: 'vbox',
											align: 'stretch'
										},
										items: [
											{
												xtype: 'label',
												itemId: 'msglblId',
												text : config.text,
												style: config.textAlign
											}
										]
									}
								],
								listeners: [
								]
							}
						],
						buttons: [
							{
								text: $TR.__getValueFromTag($TR.PRODIQ001_TAG112,'Ok'),
								itemId: 'okBtnId',
								listeners: {
									click : function(b, e) {
										me.__popup.close();
									}
								}
							}
						]
                    } , config || {});
                    this.callParent([config]);
				},

                filterButtonAction : function(popup){
					this.__popup = popup;
                        
                },

                searchButtonAction: function(){

                        
                }    
			});
		}
	})
();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\topography.js
/**
 * 
 */

(function(){
	
	var topographyImpl = SVMX.Package("com.servicemax.client.installigence.topography");

topographyImpl.init = function(){
	
	Ext.define("com.servicemax.client.installigence.topography.Topography", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.topography',
        
        constructor: function(config) {	
        	config = Ext.apply({
        		title: 'Topography',
				cls: 'image-holder',
				listeners: {
					collapse: function () {
					   this.up().doLayout();
					},
					expand: function () {
					   this.up().doLayout();
					}
				},
				items:[{
					xtype: 'image',								
					src: 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy2.jpg'
				}]
            }, config || {});
            this.callParent([config]);
        }
    });
	
};

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.installigence\src\ui\utils.js
/**
 * 
 */

(function(){
    
    var utilsImpl = SVMX.Package("com.servicemax.client.installigence.utils");

utilsImpl.init = function(){
    
   utilsImpl.Class("dependentPickList", com.servicemax.client.lib.api.Object, {
      
	   __constructor : function(config){ 
            this.__base(); 
            this.calcualteDependentPickList(config.param);
        },
        
        calcualteDependentPickList : function(objectDescribeResult){
        	// Add pickList value true, false for boolean fields
        	objectDescribeResult = this.__PopulatePickListValuesForBoolean(objectDescribeResult); 
        	var i, fields = objectDescribeResult.fields, l = fields.length, field, cname, cfield, masterPickListVsDependentPickList = [];
			for(i = 0; i < l; i++){
				field = fields[i];
				if(field.dependentPicklist){
					var masterDependentObj = {masterField : field.controllerName, dependentField : field.name};
        			masterPickListVsDependentPickList.push(masterDependentObj);
					cname = field.controllerName;
					cfield = this.__getField(cname, objectDescribeResult);
					if(cfield){
						this.__updateControllingPicklistWithDependents(cfield, field);
					}
				}
			}
			objectDescribeResult.masterPickListVsDependentPickList = masterPickListVsDependentPickList;
		},
        
        __PopulatePickListValuesForBoolean : function(objectDescribeResult){
        	var i, fields = objectDescribeResult.fields, l = fields.length;
        	for(i = 0; i < l; i++){
        		if(fields[i].type === "boolean"){
        			var falseValObj = {label:"false", value:"false"};
        			var trueValObj = {label:"true", value:"true"};
        			fields[i].picklistValues.push(falseValObj);
        			fields[i].picklistValues.push(trueValObj);
        		}
        	}
        	return objectDescribeResult;
        },
        
        __updateControllingPicklistWithDependents : function(cfield, dfield){
			var cvalues = cfield.picklistValues, i, l = cvalues.length, validForBytes,
				j, dvalues = dfield.picklistValues, c = dvalues.length, isValid,
				dependentPicklistArray, dependentPicklistInfo, k, s;

			for(i = 0; i < l; i++){

				if(!cvalues[i].dependendPicklist){ cvalues[i].dependendPicklist = []; }

				dependentPicklistArray = cvalues[i].dependendPicklist;

				for(j = 0; j < c; j++){

					validForBytes = dvalues[j].validFor; isValid = this.checkIfBytesAreValid(validForBytes, i);

					if(isValid){
						dependentPicklistInfo = null; s = dependentPicklistArray.length;
						for(k = 0; k < s; k++){
							if(dependentPicklistArray[k].fieldAPIName == dfield.name){
								dependentPicklistInfo = dependentPicklistArray[k];
								break;
							}
						}

						if(!dependentPicklistInfo){
							dependentPicklistInfo = {fieldAPIName : dfield.name, value : ""};
							dependentPicklistArray.push(dependentPicklistInfo);
						}

						dependentPicklistInfo.value += j + ";";
					}
				}

				// before proceeding with the next value, cleanup the trailing semi-colon
				for(j = 0; j < dependentPicklistArray.length; j++){
					var finalValue = dependentPicklistArray[j].value;
					if(finalValue.length > 0){
						if(SVMX.stringEndsWith(finalValue, ";")){
							finalValue = finalValue.substring(0, finalValue.length - 1);
						}
						dependentPicklistArray[j].value = finalValue;
					}
				}
			}
		},

		/**
         *  Overcome issues with SFDC SOAP API Issues and Bugs
         * @param inputBytes
         * @param parentIndex
         * @returns {boolean}
         */
         checkIfBytesAreValid : function(inputBytes, parentIndex){

            var bitsCount = inputBytes.length * 6, bitValuesArray = [], i, bitIndexInByte, bteIndex, b, biteValue;
            var base64IndexTable = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

            for (i = 0; i < bitsCount; i++) {

                // the byte to pull the bit from
                var remindValue = i % 6;
                var quoValue = (i - remindValue) / 6;

                if(quoValue < 0){
                    bteIndex = Math.ceil(quoValue);
                }else {bteIndex = Math.floor(quoValue)};

                bitIndexInByte = 5 - (i % 6);

                b = inputBytes[bteIndex], biteValue = base64IndexTable.indexOf(b);
                bitValuesArray.push( ((biteValue >> bitIndexInByte) & 1) );
            }

            return bitValuesArray[parentIndex] == 1;
        },

        __getField : function(name, describeResult){
        	var ret = null, fields = describeResult.fields, i, l = fields.length;
			for(i = 0; i < l; i++){
				if(fields[i].name == name){
					ret = fields[i];
					break;
				}
			}
			return ret;
		}
        
    }, {});
    
};

})();

// end of file

