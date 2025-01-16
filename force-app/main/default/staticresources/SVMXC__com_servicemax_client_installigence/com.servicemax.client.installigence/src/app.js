
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