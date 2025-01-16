/**
 * This file needs a description
 * @class com.servicemax.client.sal.model.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var salModelImpl = SVMX.Package("com.servicemax.client.sal.model.impl");

	salModelImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		useJsr : false,
		__constructor : function(){
			this.__base();
			this.__self.instance = this;
			this.__logger = SVMX.getLoggingService().getLogger("SAL-MODEL");
		},

		beforeInitialize : function(){

		},

		initialize : function(){
			// check if jsr should be used, only valid when running from web
			var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
			if(useJsr && useJsr === true){
				this.useJsr = true;
				this.__logger.info("JSR is enabled. Will use this for server communication.");
			}else{
				this.useJsr = false;
			}
		},

		afterInitialize : function(){
			com.servicemax.client.sal.model.sfmdelivery.operations.init();
		},

		setUserInfo : function(userInfo){
			// This is under the assumption that the service is already loaded
			var serv = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache").getInstance();;

			var key = userInfo.UserId + "-SFMDELIVERY-USERLANGUAGE", language = serv.getItem(key);
			if(language){
				if(language != userInfo.Language){

					// user language or user has changed. reset the cache
					this.__logger.info("User language OR User login has changed. Will clear cache");
					this.clearCache();
				}
			}

			//the user time format; UserContext defined in index.html
			if(UserContext){
				var timeFormat = UserContext.timeFormat;
				userInfo.TimeFormat = timeFormat;
			}

			salModelImpl.ModelState.getInstance().add("userInfo", userInfo);
			serv.setItem(key, userInfo.Language);


            SVMX.getCurrentApplication().setUserInfo(userInfo);
		},

		registerForSALEvents : function(serviceCall, operationObj){
			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("registerForSALEvents was invoked without operationObj!");
			}

			serviceCall.bind("REQUEST_ERROR", function(errEvt){

				// unblock the UI if is blocked
				var currentApp = operationObj ? operationObj.getEventBus() : SVMX.getCurrentApplication();
				//var de = operationObj ? operationObj.getEventBus().getDeliveryEngine() : null;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.CHANGE_APP_STATE", this, {request : {state : "unblock"}, responder : {}});
				currentApp.triggerEvent(evt);
				var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");
 				var message = TS.T("TAG015");
 				try{ message  += "::" + errEvt.data.xhr.statusText + "=>" + errEvt.data.xhr.responseText; }catch(e){}
 				// notify about the error
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_APP_ERROR", this, {request : {message : message }, responder : {}});
 				currentApp.triggerEvent(evt);

				this.__logger.error(message);
			}, this);
		},

		// params = {handler : , context : , options : {type : , endPoint : , namespace :}}
		createServiceRequest : function(params, operationObj){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
			servDef.getInstanceAsync({handler : function(service){
				var options = params.options || {};
				var p = {type : options.type || "REST", endPoint : options.endPoint || "SFMDeliveryServiceIntf",
									nameSpace : options.namespace === null ? null : SVMX.OrgNamespace};
				var sm = service.createServiceManager(p);
				var sRequest = sm.createService();
				this.registerForSALEvents(sRequest, operationObj);
				params.handler.call(params.context, sRequest);
			}, context:this });
		},

		checkResponseStatus : function(operation, data, hideQuickMessage, operationObj){

            var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");

			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("checkResponseStatus was invoked without operationObj!");
			}

			var ret = true, message = "", msgDetail = "";

			// the success attributes are available in the response from ServiceMax APEX services
			if(data){
				if(data.response && (data.response.success === false || data.response.success === "false")){
					ret = false;

					// user friendly data
					if(data.response.msgDetails && data.response.msgDetails.message){
						message = data.response.msgDetails.message;
						msgDetail = data.response.msgDetails.details;
					}else{
						message = data.response.message;
					}
				}else if(data.success === false || data.success === "false"){
					ret = false;

					// user friendly data
					if(data.msgDetails && data.msgDetails.message){
						message = data.msgDetails.message;
						msgDetail = data.msgDetails.details;
					}else{
						message = data.message;
					}
				}
			}

			var currentApp = operationObj ? operationObj.getEventBus() : SVMX.getCurrentApplication(), evt;
			if(ret == false){
				// unblock the UI if is blocked
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.CHANGE_APP_STATE", this, {
						request : {state : "unblock"}, responder : {}});
				currentApp.triggerEvent(evt);

 					// notify about the error
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_APP_ERROR", this, {
						request : {
							message : message,
							msgDetail : msgDetail
						},
						responder : {}});
 				currentApp.triggerEvent(evt);
				var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");
				this.__logger.error(operation + " : " + TS.T("TAG035") + " " + message);
			}else if(!hideQuickMessage || ((data.eventType == "quick save" || data.eventType == "save") && data.success == true)){
				var quickMessage = null, quickMessageType = null;
				if(data.response && data.response.message){
					quickMessage = data.response.message;
					quickMessageType = data.response.messageType;
				}else if(data.message){
					quickMessage = data.message;
					quickMessageType = data.messageType;
				}

                if ((data.eventType == "quick save" || data.eventType == "save") && data.success == true) {
                    quickMessage = TS.T("TAG020", "Saved Succesfully");
                    quickMessageType = 'SVMX_SUCCESS';
                }

				if(quickMessage && typeof(quickMessage) == 'string'){
					evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_QUICK_MESSAGE", this, {
						request : {
							message : quickMessage,
							type : quickMessageType
						},
						responder : {}});
					currentApp.triggerEvent(evt);
				}
			}

			return ret;
		},

		clearItemFromCache : function(key){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache");

			key = this.__getKey(key);

			// This is under the assumption that the service is already loaded
			var serv = servDef.getInstance();
			serv.clear(key);
			this.__logger.info("Successfully cleared <" + key + "> from cache");
		},

		getItemFromCache : function(key){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache");

			key = this.__getKey(key);

			// This is under the assumption that the service is already loaded
			var serv = servDef.getInstance();
			var value = serv.getItem(key);
			if(value)
				this.__logger.info("Successfully retrieved <" + key + "> from cache");

			return value;
		},

		setItemToCache : function(key, value){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache");

			key = this.__getKey(key);

			// This is under the assumption that the service is already loaded
			var serv = servDef.getInstance();

			this.__logger.info("Setting <" + key + "> into cache");
			return serv.setItem(key, value);
		},

		clearCache : function(){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache");

			// This is under the assumption that the service is already loaded
			var serv = servDef.getInstance();
			this.__logger.info("Clearing cache...");
			serv.reset();
		},

		__getKey : function(key){
			var userInfo = salModelImpl.ModelState.getInstance().get("userInfo");
				return userInfo.UserId + "-" + userInfo.Language + "-" + key;
			}
	}, {
		instance : null
	});

	salModelImpl.Class("LookupCacheUtil", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		addToCache : function(data){
			var key = "SFMDELIVERY-LOOKUPDATA-" + data.lookupId;
			var items = salModelImpl.Module.instance.getItemFromCache(key);

			if(!items)
				items = [];

			var bFound = false, i, l = items.length;
			for(i = 0; i < l; i++){
				if(data.record.Id == items[i].Id){
					bFound = true;
					break;
				}
			}

			if(!bFound){
				items[items.length] = data.record;

				var limit = SVMX.getClient().getApplicationParameter("svmx-sfm-lookup-cache-limit");
				if(limit){
					if(items.length > limit){
						SVMX.getLoggingService().getLogger("SFMDELIVERY-LOOKUP-CACHEUTIL")
							.info("The limit for look up data cache is exceeded! Will flushed the oldest item now.");
						items.splice(0, 1);
					}
				}

				salModelImpl.Module.instance.setItemToCache(key, items);
			}
		},

		getFromCache : function(lid){
			var key = "SFMDELIVERY-LOOKUPDATA-" + lid, ret = [];
			var items = salModelImpl.Module.instance.getItemFromCache(key);

			if(items){
				ret = items;
			}
			return ret;
		}
	});

	salModelImpl.Class("ModelState", com.servicemax.client.lib.api.Object, {
		__state : null,
		__constructor : function(){
			this.__state = {};
		},

		add : function(key, value){
			this.__state[key] = value;
		},

		get : function(key){
			return this.__state[key];
		},

		remove : function(key){
			var val = null;
			try{
				val = this.__state[key];
			}catch(e){}

			this.__state[key] = null;
			return val;
		}

	}, {
		getInstance : function(){
			if(this.__instance == null){
				this.__instance = new salModelImpl.ModelState();
			}
			return this.__instance;
		},

		__instance : null
	});

	salModelImpl.Class("UploadAttachment", com.servicemax.client.lib.api.Object, {
		__state : null,
		__data : null,
		__requestId : null,
		__attachmentData:null,
		__attachmentCount: null,
		__questionWithAttachmentID: null,
		__unsyncRecord : null,
		__constructor : function(data){
			this.__data = data;
			if(this.__data.result && this.__data.result.resultIds && this.__data.result.resultIds.length > 0){
				this.__requestId = this.__data.result.resultIds[0];
			}
			if(this.__data && this.__data.request && this.__data.request.data && this.__data.request.data.__attachementData && this.__data.request.data.__attachementData.__attachementDataHash){
				this.__attachmentData = this.__data.request.data.__attachementData.__attachementDataHash;
			}
			this.__questionWithAttachmentID = {};
		},

		__uploadtoServer : function(name, imageData, questionId){
			var me = this;
			var module = com.servicemax.client.sal.model.impl.Module;
			 module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){
                	me.__questionWithAttachmentID[evt.data.questionId] = evt.data.attachmentId;
					me.__attachmentCount--;
					if(me.__attachmentCount <= 0){
						me.__uploadChecklistAttachment();
					}
                }, this);
                sRequest.bind("REQUEST_ERROR", function(evt){
					me.__attachmentCount--;
					if(me.__attachmentCount <= 0){
						me.__uploadChecklistAttachment();
					}
                }, this);
                var sessionId = SVMX.getClient().getApplicationParameter("session-id");
				var apiVersion = "20";
				var sessionURL = me.getIDFromSession(sessionId);
				var header = {SOAPAction:'sObject'};
                sRequest.callMethodAsync({'questionId': questionId, 'methodName':'""','header':header,'url':sessionURL,'sessionId':sessionId,'type':"Attachment",'isPrivate':false,'ParentId':me.__requestId,'name':name,'body':imageData});
            }, context : this, options : {type : "SOAP", subType:'sObject', endPoint : 'test', namespace : SVMX.OrgNamespace}}, this);
		},

		uploadAttachments : function(){
			var attachmentsHash = this.__attachmentData;
			if(attachmentsHash){
				var records = Object.keys(attachmentsHash);
				var recordsLength = records.length;
				this.__attachmentCount = records.length;
				for (var index = 0; index < recordsLength; index++) {
					var record = attachmentsHash[records[index]];
					record[SVMX.OrgNamespace + '__SM_Checklist__c'] =this.__requestId;
					if(record && !record[SVMX.OrgNamespace + '__SM_Attachment_ID__c']){
						if(record.attachmentURL){
							this.__uploadtoServer(record[SVMX.OrgNamespace + '__SM_Attachment_Name__c'],record.attachmentURL,record[SVMX.OrgNamespace + '__SM_Internal_Question_ID__c']);
						} else {
							this.__attachmentCount--;
						}
						
					} else {
						this.__attachmentCount--;
					}
				}
				if(this.__attachmentCount <= 0){
					this.__uploadChecklistAttachment();
				}
			}
		},

		__uploadChecklistAttachment : function(){
			//uploadAttachmentData abd remove url
			var me = this;
			this.__unsyncRecord = [];
			var attachmentsHash = this.__attachmentData;
			if(attachmentsHash){
				var records = Object.keys(attachmentsHash);
				var recordsLength = records.length;
				for (var index = 0; index < recordsLength; index++) {
					var record = attachmentsHash[records[index]];
					record.attachmentURL = null;
					delete record.attachmentURL;
					record[SVMX.OrgNamespace + '__SM_Checklist__c'] =this.__requestId;
					if(record && !record[SVMX.OrgNamespace + '__SM_Attachment_ID__c']){
						this.__unsyncRecord.push(record);
						record[SVMX.OrgNamespace + '__SM_Attachment_ID__c'] = this.__questionWithAttachmentID[record[SVMX.OrgNamespace + '__SM_Internal_Question_ID__c']];
					}
				}
			}
			//call target update
			this.__data.request.data.__attachementData.unSyncedRecord = this.__unsyncRecord;
			this.__data.request.data.result = this.__data.result;
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "SFMDELIVERY.SAVE_TARGETATTACHMENTRECORD", this, {
                    request: me.__data.request,
                    responder: me.__data.responder
                }
            );
            this.__data.request.deliveryEngine.getEventBus().triggerEvent(evt);
		},

		getIDFromSession: function(sessionId){
			var ids = sessionId.split("!");
			var id = '00DJ0000003LMuB';
			if(ids.length > 1){
				id = ids[0];
			}
			return id;
		}


	}, {});

	salModelImpl.Class("SFMAttachmentDeliveryData", com.servicemax.client.lib.api.EventDispatcher, {

		__constructor : function(data){
			this.__deletedRecords = {};
 	    	this.__records = data.response.records || [];
 	    	this.__attachementDataHash = this.getAttachmentDataHash(data.response.records);
		},

		getAttachmentDataHash: function(data) {
		    var attachmentDataHash = {};
		    if (data) {
		      var attachmentData = data;
		      for (var i = 0; i < attachmentData.length; i++) {
		        if (attachmentData && attachmentData[i] && attachmentData[i][SVMX.OrgNamespace + '__SM_Internal_Question_ID__c']) {
		          attachmentDataHash[attachmentData[i][SVMX.OrgNamespace+'__SM_Internal_Question_ID__c']] = attachmentData[i];
		        }
		      }
		    }
		    return attachmentDataHash;
		},

		getAttachmentValuefromPath: function(path) {
		    return this.__attachementDataHash[path];
		},

		setAttachmentValueToPath: function(path, value) {
		    var attachmentData = value;
		    if (value) {
		      if (Object.prototype.hasOwnProperty.call(this.__attachementDataHash, path)) {
		        if (value[SVMX.OrgNamespace+'__SM_Attachment_ID__c'] !== this.__attachementDataHash[path][SVMX.OrgNamespace + '__SM_Attachment_ID__c']) {
		          this.__deletedRecords[path] = this.__attachementDataHash[path];
		        }
		      }
		      this.__attachementDataHash[path] = attachmentData;
		    }
		},

		getRawAttachmentData: function() {
		   return attachmentData;
		},

		getDeletedAttachmentRecords: function() {
		   return this.__deletedRecords;
		},

		getAttachmentQuestionFields: function() {
		   return Object.keys(this.__attachementDataHash);
		}

	}, {});


	salModelImpl.Class("SFMDeliveryData", com.servicemax.client.lib.api.EventDispatcher, {
		__data : null, _targetRecordId : null, _sourceRecordId : null, __logger : null, __deletedRecords : null,
		__objectNameMap : null, __attachmentData : null,

		__constructor : function(data){
			this.__base();
			this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-SAL_DATA");
			this.__data = data;
			this.__deletedRecords = [];
			this.__objectNameMap = data.objectNameMap;
			this._initialize();
		},

		_initialize : function(){
			this._targetRecordId = this.__data.pageDataSet.sobjectinfo.Id;
			this._sourceRecordId = this.__data.pageDataSet.sourceRecordID;
			if (this.__data.response && this.__data.response.records && this.__data.response.processType === 'CHECKLIST') {
       			this.__attachementData = SVMX.create("com.servicemax.client.sal.model.impl.SFMAttachmentDeliveryData",this.__data);
     		}
			this._initialize2();
		},

		_resolveRecordTypes: function(sobjectinfo, tableName) {
			var recordTypeId = sobjectinfo.RecordTypeId;
			if (sobjectinfo.RecordTypeId && sobjectinfo.RecordTypeId.fieldvalue && sobjectinfo.RecordTypeId.fieldvalue.key) {
				var recordTypeId = sobjectinfo.RecordTypeId.fieldvalue.key;
				var key = "SFMDELIVERY-RECORDTYPES-" +  tableName;
				var recordTypeEntries = salModelImpl.Module.instance.getItemFromCache(key);
				var recordTypeEntry = SVMX.array.get(recordTypeEntries, function(entry) {
					return entry.recordTypeId == recordTypeId;
				});

				var recordTypeName = recordTypeEntry ? recordTypeEntry.name : null;
				if (recordTypeName) {
					sobjectinfo.RecordTypeId.fieldvalue.value = recordTypeName;
				}
			}

		},

		_initialize2 : function(){
			/**
			 * Set up a new node "sfmData" which consolidates header and details in way that
			 * they can be referenced by a structure agnostic path/expression
			 */
			this.__data.sfmData = this.__extractData(this.__data.pageDataSet);
			if (this.__objectNameMap) {
				this._resolveRecordTypes(this.__data.sfmData, this.__objectNameMap.header);
			}

			// set up the details
			this.__data.sfmData.details = {};
			var ds = this.__data.detailDataSet;
			if(ds){

				if(!(ds instanceof Array)){
					ds = [ds];
				}

				var i, l = ds.length;	// all data sets
				for(i = 0; i < l; i++){
					var pds = ds[i].pageDataSet, id = ds[i].aliasName;
					var detail = {lines : []};
					if(pds){		// all the lines

						if(!(pds instanceof Array)){
							pds = [pds];
						}

						if(pds.length > 0){
							var j, pdsLength = pds.length;
							for(j = 0; j < pdsLength; j++){
								detail.lines[j] = this.__extractData(pds[j]);
								if (this.__objectNameMap) {
									this._resolveRecordTypes(detail.lines[j], this.__objectNameMap[id]);
								}
							}
						}
					}
					this.__data.sfmData.details[id] = detail;
				}
			}
		},

		/**
		 * Extract the data from the bubble info!. This is required to get the values
		 * for reference fields.
		 *
		 * @param pageDataSet
		 * @returns
		 */
		__extractData : function(pageDataSet){
			var sobject = pageDataSet.sobjectinfo, bubbleInfo = pageDataSet.bubbleInfo, i, l = 0;

			// clean up all the null values in the sobject
			if(sobject){
				var propName;
				for(propName in sobject){
					if(sobject[propName] === null) delete sobject[propName];
				}
			}
			// end clean up null values

			if(bubbleInfo){
				if(!(bubbleInfo instanceof Array)){
					bubbleInfo = [bubbleInfo];
				}
				l = bubbleInfo.length;
			}

			for(i = 0; i < l; i++){
				var bi = bubbleInfo[i], apiName = bi.fieldapiname, value = {};
				value.fieldapiname = apiName;
				value.fieldvalue = {};

				// make sure that Id is available as a simple attribute to generate target record consistently
				if(apiName == "Id"){
					value = bi.fieldvalue.value;
				}else{
					// the data is slightly different when got from GetData Vs when returned from event response
					if(bi.fieldvalue){
						if (bi.fieldvalue.value1 !== undefined && bi.fieldvalue.value1 !== null) {
							value.fieldvalue = {key : bi.fieldvalue.value, value : bi.fieldvalue.value1};
						} else {
							value.fieldvalue = {key : bi.fieldvalue.key, value : bi.fieldvalue.value};
						}
					}
				}

				sobject[apiName] = value;
			}

			// setup the source record ID, specifically for details
			// when a SOAP service is invoked, even though sourceRecordID is null, when converting from XML to JSON object,
			// the empty element in the XML gets converted to empty object! So we have to check if is a string.
			if(pageDataSet.sourceRecordID && typeof(pageDataSet.sourceRecordID) == 'string'){
				sobject.sourceRecordID = pageDataSet.sourceRecordID;
			}

			// setup the source Record in case of Checklist.
			// The source record is provided by server to evaluate the Entry criteria.
			if(pageDataSet.sourceRecord && typeof(pageDataSet.sourceRecord) === 'object'){
				sobject.sourceRecord = pageDataSet.sourceRecord;
			}

			// setup the record ID
			// when a SOAP service is invoked, even though Id is null, when converting from XML to JSON object,
			// the empty element in the XML gets converted to empty object! So we have to check if is a object.
			if(sobject && sobject.Id && typeof(sobject.Id) == 'object'){
				delete sobject.Id;
			}
			return sobject || {};
		},

		reset : function(newData, notifyListeners){
			this.__logger.info("Performing reset of sal-model");

			this.__data = newData;
			this._initialize2();

			this.__logger.info("Notifying the listeners that the sal-model has been reset");
			// notify the model listeners
			if(notifyListeners){
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", "MODEL_UPDATED", this, {});
			 	this.triggerEvent(evt);
		 	}
		},

		updateFromEvent : function(newData){
			this.reset(newData, true);
		},

		copyFromTargetRecord : function(targetRecord){
			// this happens when we an event is executed that runs locally (for example, JS events)

			var newData = {
			    pageDataSet : {
					sobjectinfo : {
					    attributes: {type: targetRecord.headerRecord.objName}
					},
					bubbleInfo : []
				},
			    detailDataSet : []
			};

			// copy the header
			var hr = targetRecord.headerRecord.records[0].targetRecordAsKeyValue, i, l = hr.length;
			for(i = 0; i < l; i++){
				newData.pageDataSet.bubbleInfo[i] = {fieldapiname : hr[i].key, fieldvalue : {key : hr[i].value, value : hr[i].value1}};
				if(newData.pageDataSet.bubbleInfo[i].fieldvalue.value === null || newData.pageDataSet.bubbleInfo[i].fieldvalue.value === undefined){
					newData.pageDataSet.bubbleInfo[i].fieldvalue.value = newData.pageDataSet.bubbleInfo[i].fieldvalue.key;
				}
			}

			// copy details
			var details = targetRecord.detailRecords, l = details.length;
			for(i = 0; i < l; i++){
				var detail = details[i], aliasName = detail.aliasName,
					records = detail.records, j, rl = records.length, detailDataSetItem = null;

				detailDataSetItem = {aliasName : aliasName, pageDataSet : []};
				for(j = 0; j < rl; j++){
					var sourceRecord = records[j].targetRecordAsKeyValue, k, srl = sourceRecord.length, m;
					detailDataSetItem.pageDataSet[j] = {
					    sobjectinfo : {
							attributes: {
							    type: detail.objName
							}
					    }
					};					var bi = detailDataSetItem.pageDataSet[j].bubbleInfo = [];

					// setup the source record ID
					if(records[j].sourceRecordId){
						detailDataSetItem.pageDataSet[j].sobjectinfo.sourceRecordID = records[j].sourceRecordId;
					}

					for(k = 0, m = 0; k < srl; k++){

						if(sourceRecord[k].key == "Id"){
							detailDataSetItem.pageDataSet[j].sobjectinfo.Id = sourceRecord[k].value;
						}else{
							bi[m] = {fieldapiname : sourceRecord[k].key, fieldvalue : {key : sourceRecord[k].value, value : sourceRecord[k].value1}};
							if(bi[m].fieldvalue.value === null || bi[m].fieldvalue.value === undefined){
								bi[m].fieldvalue.value = bi[m].fieldvalue.key;
							}
							m++;
						}
					}
				}

				newData.detailDataSet[newData.detailDataSet.length] = detailDataSetItem;
			}
			this.updateFromEvent(newData);
		},

		getTargetRecordId : function(){
			return this._targetRecordId;
		},

		setTargetRecordId : function(value){
			this._targetRecordId = value;
		},

		getSourceRecordId : function(){
			return this._sourceRecordId;
		},

		getDeletedRecords : function(){
			return this.__deletedRecords;
		},

		getValueFromPath : function(path){
			var pathItems = path.split("."), i, l = pathItems.length, value = this.__data.sfmData;
			for(i = 0; i < l; i++){
				value = value[pathItems[i]];

				if(!value) break;
			}
			return value;
		},

		getRawData : function(){
			return this.__data;
		},


		/**
		 * getRawValues
		 * @param {Object} inOptions:
		 *    {String} [referenceValue] "key" or "value" or null to get entire reference value
		 *    {Object} [data] If provided, then use this data instead of sobjectinfo.  Why use this?
		 *             So that we don't have to call getRawValues on all 300 line items all at once,
		 *             and can pass in line items as inData.
		 *    {boolean} [includeLineItems] include the values of all line items.  If false, we just return
		 *              the raw data without conversion. TODO: NOT YET IMPLEMENTED
		 *    {Object} [fieldTypes] If converting fields, we need a hash describing the field types.
		 *              See request.deliveryEngine.__page.getFieldTypes().
		 */
		getRawValues : function(inOptions) {
			if (!inOptions) return this.__data.pageDataSet.sobjectinfo;

			var obj = {}, key;
			var src = inOptions.data || this.__data.pageDataSet.sobjectinfo;
			var field = inOptions.referenceValue;
			for (key in src) {
				if (key == "details") {
					obj.details = src.details;
				} else if (field && src[key] && typeof src[key] === "object" && "fieldvalue" in src[key] && field in src[key].fieldvalue) {
					obj[key] = src[key].fieldvalue[field];
				} else {
					obj[key] = src[key];
				}
				if (obj[key] !== undefined && obj[key] !== null && typeof obj[key] !== "object" && inOptions.fieldTypes && "attributes" in src) {
					var objectType = src.attributes.type;
					var objectFields = inOptions.fieldTypes[objectType];
					var fieldType = objectFields[key];
					obj[key] = this.__convertFieldValue(obj[key], fieldType);
				}
			}
			return obj;
		},

        /*
         * validates a data object, retuns true or false
         *
         * @param   {Object}    inDate
         *
         * @return  {Boolean}
         */
        __isDateObject : function(inDate) {
            if ((inDate instanceof Date) && (!isNaN(inDate.getTime()))) {
                return true;
            }

            this.__logger.error("Invalid Date Object;", inDate);
            return false;
        },

		__convertFieldValue : function(inValue, inType) {
			switch(inType) {
				case "date":
            if (!inValue) return inValue;
            //039811
            var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDate(inValue);
            //Defect 30027,038690, 038154
            //var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(inValue);
            if (this.__isDateObject(d)) {
                d.setHours(0,0,0);
            }
            return d;
        case "datetime":
            if (!inValue) return inValue;
            //var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDate(inValue);
            //Defect 30027,038690, 038154
            var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(inValue);
            //quick check logs it if it's invalid
            this.__isDateObject(d);
            return d;
				case "boolean":
					return inValue === "true" || inValue === true;
				case "double":
				case "percent":
				case "currency":
					if (typeof inValue === "string") {
						return Number(inValue);
					} else {
						return inValue;
					}
				default:
					return inValue;
			}
		},

		deleteDetailRecords : function(records, alias){
			var bindingPath = "details." + alias, details = this.getValueFromPath(bindingPath),
					i, l = records.length, rowIndex;
			for(i = 0; i < l; i++){
				rowIndex = records[i].rowIndex;
				var deletedLine = details.lines.splice(rowIndex, 1), id = deletedLine[0].Id;
				if(id){
					this.__deletedRecords.push({alias : alias, id :id});
				}
			}

			// notify the model listeners
			var evt = SVMX.create("com.servicemax.client.lib.api.Event", "DETAIL_RECORDS_DELETED",
						this, {lines : records, bindingPath : bindingPath});
		 	this.triggerEvent(evt);
		},

		addNewDetailRecords : function(records, alias, callback){
			var bindingPath = "details." + alias, details = this.getValueFromPath(bindingPath),
						i, l = records.length, newRecords = {lines : []};

			for(i = 0; i < l; i++){
				newRecords.lines[i] = details.lines[details.lines.length] = this.__extractData(SVMX.cloneObject(records[i]));
			}

			// notify the model listeners
			var evt = SVMX.create("com.servicemax.client.lib.api.Event", "DETAIL_RECORDS_ADDED",
						this, {
						    newRecords : SVMX.toObject(SVMX.toJSON(newRecords)),
						    bindingPath : bindingPath,
						    onSuccess: callback
						});
		 	this.triggerEvent(evt);
		},

		setValueToPath : function(path, value){

			var pathItems = path.split("."), i, l = pathItems.length, data = this.__data.sfmData, item, itemPath;
			for(i = 0; i < l; i++){
				item = data;
				itemPath = pathItems[i];
				data = data[itemPath];

				if(!data) break;
			}

			item[itemPath] = value;
		},

		getError : function() {return this.__error;}
	}, {});

	salModelImpl.Class("SFMDeliveryDataFromPageLayout", salModelImpl.SFMDeliveryData, {
		__constructor : function(data){
			this.__base(data);
		},

		_initialize : function(){
			/**
			 * Set up a new node "sfmData" which consolidates header and details in way that
			 * they can be referenced by a structure agnostic path/expression
			 */
			this.__data.sfmData = this.__extractHeaderData(this.__data.page.header);

			this._targetRecordId = this.__data.page.header.hdrData.Id;
			this._sourceRecordId = this.__data.page.header.sourceRecordId;

			// set up the details
			this.__data.sfmData.details = {};
			var ds = this.__data.page.details;

			if(ds){
				var i, l = ds.length;	// all data sets
				for(i = 0; i < l; i++){
					var pds = ds[i].bubbleinfolist, id = ds[i].dtlLayoutId;
					var detail = {lines : []};
					if(pds && pds.length > 0){		// all the lines
						var j, pdsLength = pds.length;
						for(j = 0; j < pdsLength; j++){
							detail.lines[j] = this.__extractLineData(pds[j]);
						}
					}

					this.__data.sfmData.details[id] = detail;
				}
			}
		},

		/**
		 * Extract the header info from the bubble info!. This is required to get the values
		 * for reference fields.
		 *
		 * @param pageDataSet
		 * @returns
		 */
		__extractHeaderData : function(header){
			var sobject = header.hdrData, sections = header.sections, i, l = sections.length;
			for(i = 0; i < l; i++){
				var section = sections[i], j, fields = section.fields, fl = fields.length;
				for(j = 0; j < fl; j++){
					var bi = fields[j].bubbleinfo, apiName = bi.fieldapiname;
					sobject[apiName] = bi;
				}
			}
			return sobject;
		},

		/**
		 * Extract the line data from the bubble info!. This is required to get the values
		 * for reference fields.
		 *
		 * @param pageDataSet
		 * @returns
		 */
		__extractLineData : function(pageDataSet){
			var sobject = pageDataSet.sobjectinfo, bubbleInfo = pageDataSet.bubbleinfolist, i, l = bubbleInfo.length;
			for(i = 0; i < l; i++){
				var bi = bubbleInfo[i], apiName = bi.fieldapiname;
				sobject[apiName] = bi;
			}
			return sobject;
		}
	}, {});

	salModelImpl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
		__constructor : function(){

		},

		isEventSupported : function(eventInfo){
			return true;
		},

		isActionButtonVisible : function(buttonInfo){
			var showInWeb = buttonInfo.buttonDetail[SVMX.OrgNamespace + "__Show_In_Web__c"];
			return !!showInWeb;
		},

		showRecordFrombubbleInfo : function(info){
			SVMX.openInBrowserWindow("/" + info.key + "?isdtp=mn");
		},

		getProcessLMD : function(){
			return window['svmx_sfm_delivery_process_lmd'];
		},

		getAttachmentsEnabled : function() {
			return false;
		},

		/**
		 * Figure out what value should be displayed for a Lookup field that is a reference.
		 *
		 *
		 */
		getRefDisplayValue : function(path, value, metaModelData) {
			var d = new $.Deferred();
			d.resolve(value);

			return d;
		},

		getQualificationInfo : function(recordID, record, processId, callback){
			var isSFMProcess = window['svmx_sfm_delivery_is_sfmprocess'] === undefined ?
									true : window['svmx_sfm_delivery_is_sfmprocess'];

			var isQualified = window['svmx_sfm_delivery_is_qualified'] === undefined ?
									true : window['svmx_sfm_delivery_is_qualified'];

			var errorMessage = window['svmx_sfm_delivery_error_message'] === undefined ?
									"" : window['svmx_sfm_delivery_error_message'];

			var result =  {isSFMProcess : isSFMProcess,
							isQualified : isQualified,
							errorMessage : errorMessage};

			callback(result);
		},

		getBasicDisplayTags : function(){
			var ret = {};
			var bdt = window['svmx_sfm_delivery_basic_display_tags'] || "[]";
			var bdtList = SVMX.toObject(bdt), i, l = bdtList.length, pair;
			for(i = 0; i < l ; i++){
				pair = bdtList[i].split("~");
				ret[pair[0]] = pair[1];
			}
			return ret;
		},

		performNewAfterSave : function(){
			// reload the page so that a new record can be created
		    setTimeout(function(){SVMX.reloadPage();}, 1000);
		},

		navigateToTargetRecord : function(resultantRecord, callback){
			// navigate to the resulting record
			setTimeout(function(){
				var baseUrl = SVMX.getClient().getApplicationParameter("svmx-base-url") || "";
				if (baseUrl && baseUrl.indexOf("/") != 0) baseUrl = "/" + baseUrl;

				// Defect 012775
				var fullUrl = baseUrl + "/" + resultantRecord;
				if (SVMX.navigateToCheckExternal) {
					SVMX.navigateToCheckExternal(fullUrl, SVMX.getUrlParameter("SVMX_recordId") != resultantRecord);
				}
				else {
					SVMX.navigateTo(fullUrl);
				}
			}, 1000);
		},

		getItemFromCache : function(key){
			var items = salModelImpl.Module.instance.getItemFromCache(key);
			return items;
		},

		isEmailValid : function(email){
    		return true;
		},

		getFormattedDateTimeValue : function(value, timeZoneOffset){
			if(value !== null && value !== undefined && value !== "") {
				var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
				// Ensure that this is the correct format (ISO 8601 Datetime notation)
				value = DatetimeUtils.getFormattedDatetime(value, 'YYYY-MM-DD[T]HH:mm:ss');
				value = value + timeZoneOffset;
			} else {
				value = "null";
			}

			return value;
		},

		getFormattedDateValue : function(value){
			if(value !== null && value !== undefined && value !== "") {
				var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
				// Ensure that this is the correct format (ISO 8601 Datetime notation)
				value = DatetimeUtils.getFormattedDatetime(value, 'YYYY-MM-DD');
			} else {
				value = "null";
			}

			return value;
		}
	}, {});
})();

// end of file
