/**
 * This file needs a description
 * @class com.servicemax.client.sal.model.sfmdelivery.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfmdeliveryoperations = SVMX.Package("com.servicemax.client.sal.model.sfmdelivery.operations");

sfmdeliveryoperations.init = function(){

	// imports
	var ModelState = com.servicemax.client.sal.model.impl.ModelState;
	var Module = com.servicemax.client.sal.model.impl.Module;
	var OpUtils = com.servicemax.client.sfmdelivery.operationutils.Utilities;
	var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
	var SVMXprofiler = SVMX.getProfilingService();
	// end imports

    addJSRDataToProfiler = function(data) {
        var details = data.details || [];
        var item = null;
        for (var i=0; i < details.length; i++) {
            item = details[i];
            if (!!SVMXprofiler.addServerEntry) {
                SVMXprofiler.addServerEntry(item);
            }
        }
    };

    getProfileDataFromResult = function(result) {
        var profileData = null;

        if (!!result.data) {
            if (!!result.data.response) {
                if (!!result.data.response.profileData) {
                    profileData = result.data.response.profileData;
                }
            }
        } else {
            if (!!result.response) {
                if (!!result.response.profileData) {
                    profileData = result.response.profileData;
                }
            }
        }

        return profileData;
    };

	sfmdeliveryoperations.Class("GetPageLayout", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var module = Module.instance, key = '', ret = null, isCacheValid = true;

			// check if cache process information is out-dated. If yes, then get the latest and over-write
			var platformSpecifics = SVMX.getClient()
				.getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
			key = "SFMDELIVERY-PROCESS-LMD-" + request.processId;
			var lmd = platformSpecifics.getProcessLMD();

			var lmdFromCache = module.getItemFromCache(key);
			if(lmdFromCache !== undefined && lmdFromCache !== null){
				if(lmd > lmdFromCache){
					isCacheValid = false;
				}
			}
			module.setItemToCache(key, lmd);
			// end check for out-dated process information

			key = "SFMDELIVERY-PAGELAYOUT-" + request.processId;

			if(isCacheValid){
				// check whether the data is already present in cache
				ret = module.getItemFromCache(key);
			}else{
				SVMX.getLoggingService().getLogger().info("Process information in the cache is out-dated. It will be updated now.");
			}

			if(ret){
				setTimeout(function(){ responder.result(ret); }, 1);
			}else{
				var data = {processId : request.processId, recordId : request.recordId};

				if(Module.instance.useJsr){
                    SVMXJsr.JsrGetPageLayout(data, function(result, evt){
                    	var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

                        if(module.checkResponseStatus("GetPageLayout", result, false, this) == true){
							this.__cacheDefinitions(request, result, isCacheValid);
							var data = this.__restructureData(result);
							module.setItemToCache(key, data);	// store in the cache
							responder.result(data);
						}
					}, this);
				}else{
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){
							if(module.checkResponseStatus("GetPageLayout", evt.data, false, this) == true){
								this.__cacheDefinitions(request, evt.data, isCacheValid);
								var data = this.__restructureData(evt.data);
								module.setItemToCache(key, data);	// store in the cache
								responder.result(data);
							}
						}, this);

						sRequest.callMethodAsync({methodName : "getPageLayout",
								data : data});
					}, context : this}, this);
				}
			}
		},

		__cacheDefinitions : function(request, data, isCacheValid){
			this.__cacheLookupDefinitions(data);
			this.__cacheDetailMappedLiterals(request, data);
			this.__cacheChildRecordTemplates(request, data);
			this.__cacheRecordTypeTranslations(request, data);

			// clear the process's related the objects cache too
			if(!isCacheValid){
				var objects = [data.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"]];
				var details = data.page.details, i, l = details.length, key;
				for(i = 0; i < l; i++){
					var detail = details[i];
					objects[i+1] = detail.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
				}

				l = objects.length;
				for(i = 0; i < l; i++){
					key = "SFMDELIVERY-DESCRIBE_OBJECT_" + objects[i];
					Module.instance.clearItemFromCache(key);
				}
			}
			// end clear
		},

		__cacheRecordTypeTranslations: function(request, data) {
			var recordTypeData = data.page.recordTypeList || [];
			var cachedDataList = {}, parentObjName, key;
			if (recordTypeData.length) {
				parentObjName = recordTypeData[0].value1;
				SVMX.array.forEach(recordTypeData, function(item) {
					// May have several different object names that need cached
					if (!cachedDataList[item.value1]) {
						cachedDataList[item.value1] = {};
					}

					cachedDataList[item.value1][item.key] = item.value;
				});

				for (parentObjName in cachedDataList) {
					key = "SFMDELIVERY-RECORDTYPE-TRANSLATIONS-" + parentObjName;
					Module.instance.setItemToCache(key,cachedDataList[parentObjName]);
				}
			}
		},

		__cacheDetailMappedLiterals : function(request, data){
			var details = data.page.details;
			if(details && details.length > 0){
				var i, l = details.length, mappedLiterals, mappedValues, detailId, key;
				for(i = 0; i < l; i++){
					mappedLiterals = details[i].mappedLiterals;
					mappedValues = details[i].mappedValues;

					detailId = details[i].dtlLayoutId;

					key = "SFMDELIVERY-DETAIL-MAPPED-INFO-" + request.processId + "-" + detailId;
					Module.instance.setItemToCache(key,
						SVMX.cloneObject({mappedLiterals : mappedLiterals, mappedValues : mappedValues}));
				}
			}
		},

		__cacheChildRecordTemplates : function(request, data){
			var details = data.page.details;
			if(details && details.length > 0){
				var i, l = details.length, recordTemplate, detailId, rt, key;
				for(i = 0; i < l; i++){
					recordTemplate = details[i].recordTemplate;

					if(!recordTemplate) continue;

					detailId = details[i].dtlLayoutId;
					rt = [{sobjectinfo : recordTemplate, bubbleInfo : []}];
					for(var name in recordTemplate){
						if(name == "attributes" || name == "attributes__key") continue;

						rt[0].bubbleInfo.push({fieldapiname : name,
							fieldvalue : {value : recordTemplate[name], value1 : recordTemplate[name]}});
					}
					key = "SFMDELIVERY-ADDRECORDS-TEMPLATE-" + request.processId + "-" + detailId;
					Module.instance.setItemToCache(key, rt);
				}
			}
		},

		__cacheLookupDefinitions : function(data){
			if(data.page.lookupDefinitions){
				var ludefs = SVMX.cloneObject(data.page.lookupDefinitions), i, l = ludefs.length, key, def;
				delete data.page.lookupDefinitions;

				for(i = 0; i < l; i++){
					def = ludefs[i];
					key = "SFMDELIVERY-LOOKUP-CONFIG-" + def.key;
					Module.instance.setItemToCache(key, def);
				}

			}
		},

		__restructureData : function(data){
			var sm = data.response.stringMap, i, l = sm.length;
			for(i = 0; i < l; i++){
				if(sm[i].key == "PROCESSTYPE"){
					data.response.sfmProcessType = sm[i].value;
					break;
				}
			}

			switch(data.response.sfmProcessType) {
	           case "SOURCETOTARGET":
			       data.response.sfmProcessType = "SOURCE TO TARGET ALL";
			       break;
			   case "SOURCETOTARGETONLYCHILDROWS":
			       data.response.sfmProcessType = "SOURCE TO TARGET CHILD";
			       break;
			    case "EDIT":
			       data.response.sfmProcessType = "STANDALONE EDIT";
			       break;
			    case "VIEWRECORD":
			       data.response.sfmProcessType = "VIEW RECORD";
			       break;
			}
			return data;
		}

	}, {});


	sfmdeliveryoperations.Class("GetDetailMappedInfo", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var module = Module.instance, key = '', ret = null;

			key = "SFMDELIVERY-DETAIL-MAPPED-INFO-" + request.processId + "-" + request.alias;
			ret = module.getItemFromCache(key);
			SVMX.doLater(function() {
				responder.result(ret);
			});
		}

	}, {});

	sfmdeliveryoperations.Class("RetrieveSettings", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			// if settings is embeded into the container html/vf
			if(window["svmx_sfm_delivery_settings"] != undefined && window["svmx_sfm_delivery_settings"] != null ){
				setTimeout(function(){
					ret = window["svmx_sfm_delivery_settings"];
					ret = SVMX.toObject(ret);
					responder.result(ret);
				}, 1);
			}else{

				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){

						if(Module.instance.checkResponseStatus("RetrieveSettings", evt.data, false, this) == true){
							responder.result(evt.data);
						}
					}, this);

					sRequest.callMethodAsync({methodName : "retrieveSettings", data : request});
				}, context : this}, this);
			}
		}

	}, {});


	sfmdeliveryoperations.Class("GetLookupConfig", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData = {}, callType = request.callType, key = "SFMDELIVERY-LOOKUP-CONFIG-", waitForData = false,
				response = {
				namesearchinfo : {
					namedSearch : [{
						namedSearchHdr : {},
						namedSearchDetails : [{ fields : [] }]
					}]
				},
				data : [],
				advFilters : []
			};

			if(request.LookupRecordId){
				key += request.LookupRecordId;
			}else{
				key += request.ObjectName;
			}

			var lookupDef = Module.instance.getItemFromCache(key), refMetaModel = responder.__parent.getReferenceMetaModel();
			var pfc = OpUtils.replaceLiteralsWithValue(lookupDef.lookupDefDetail.preFilterCriteria, refMetaModel, key);

			request.preFilterCriteria = pfc;

			if(!lookupDef){
				// error! ask user to clear cache and continue
				Module.instance.checkResponseStatus("GetLookupConfig", {success : false,
					message : "Could not find the lookup definition. This may be due to outdated client cache. Please clear the cache and try again!"}, false, this);
				return;
			}

			var namedSearchHdr = response.namesearchinfo.namedSearch[0].namedSearchHdr,
				namedSearchDetails = response.namesearchinfo.namedSearch[0].namedSearchDetails[0],
				fields = namedSearchDetails.fields, i, l;

			namedSearchHdr[SVMX.OrgNamespace + "__Default_Lookup_Column__c"] = lookupDef.lookupDefDetail.defaultLookupColumn;

			var displayFields = lookupDef.lookupDefDetail.displayFields, fld;
			l = displayFields.length;

			SVMX.array.forEach(displayFields, function(item) {
				fields.push(this.__createFieldObject(item));
			}, this);

			var lookupDefRequest = SVMX.cloneObject(lookupDef);
			lookupDefRequest = OpUtils.extractDefWithFiltersToQuery(request, lookupDefRequest);

			//check whethere pfc criteria has value after operator
			var emptyPfc = this.__isPFCValueEmpty(request.preFilterCriteria);
			if(request.preFilterCriteria != undefined && request.preFilterCriteria != null && request.preFilterCriteria != "" && (!emptyPfc)){
				lookupDefRequest.lookupDefDetail.preFilterCriteria = request.preFilterCriteria;
			} else {
	            delete lookupDefRequest.lookupDefDetail.preFilterCriteria;
			}

			lookupDefRequest.lookupDefDetail.formFillFields = SVMX.array.map(request.formFillFields,
				function(inName,i) {
					return {
						apiName: inName,
						dataType: null,
						fieldRelationshipName: null,
						operandType: null,
						refObjectName: null,
						refObjectNameField: null
					};
				}
			);

			if(callType == "DATA" || callType == "BOTH"){
				waitForData = true;
				requestData.lookupRequest = {
					LookupDef : lookupDefRequest, KeyWord : request.KeyWord, Operator : request.SearchOperator,
					ContextValue : request.LookupContext, ContextMatchField : request.LookupQueryField
				};

				if(Module.instance.useJsr){
                    SVMXJsr.JsrGetLookupData(requestData, function(result, evt){
                    	var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

						if(Module.instance.checkResponseStatus("GetLookupConfig", result, false, this) == true){
							response.data = this.__createDisplayRecords(result.records, fields);
							response.advFilters = lookupDef.advFilters;
							responder.result(response);
						}
					}, this);
				}else{
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){

							if(Module.instance.checkResponseStatus("GetLookupConfig", evt.data, false, this) == true){
								response.data = this.__createDisplayRecords(evt.data.records, fields);
								response.advFilters = lookupDef.advFilters;
								responder.result(response);
							}
						}, this);
						sRequest.callMethodAsync({methodName : "getLookupData", data : requestData});
					}, context : this}, this);
				}
			}

			if(!waitForData){

				var cacheKey = request.LookupRecordId;
				if(!cacheKey){
					cacheKey = request.ObjectName;
				}

				// populate the recent items from the cache
				response.data = this.__createDisplayRecords(
					com.servicemax.client.sal.model.impl.LookupCacheUtil.getFromCache(cacheKey) );

				//TODO : Revisit this logic post sum13 - Vinod
				//START - callType for recent items is META and the condition above is checked for BOTH and DATA, which means advFilters is never populated
				//for recent items. Hence the below code.
				if(lookupDef.advFilters.length > 0 && response.advFilters.length == 0){
					response.advFilters = lookupDef.advFilters;
				}
				//END

				responder.result(response);
			}
		},

		__createFieldObject : function(field) {
			var fld = {};
			fld[SVMX.OrgNamespace + "__Field_Name__c"] = field.apiName;
			fld[SVMX.OrgNamespace + "__Sequence__c"] = field.sequence;
			fld[SVMX.OrgNamespace + "__Search_Object_Field_Type__c"] = "Result";
			fld["nameField"] = field.refObjectNameField;
			fld["dataType"] = field.dataType;
			fld["relationshipName"] = field.fieldRelationshipName;
			return fld;
		},

		//check whether pfc criteria has value or not.
		//returns TRUE if pfc criteria doesnt have value. (Exampe: "SVMXDEV__CustDateField__c=")
		//returns FALSE if pfc criteria has a value. (Example : "SVMXDEV__CustDateField__c=2015-09-04")
		__isPFCValueEmpty : function(pfcString){
			var op,
			indexOfOp,
			opArray = ["<", ">", "=", "LIKE"], //SFD-315
			i = 0;

			if(pfcString == null) {
				return true;
			}

			//get the operator.
			for(i = 0; i < opArray.length; i++){
				var index = pfcString.indexOf(opArray[i]);
				if(index > 0){
					op = opArray[i];
					indexOfOp = index;
				}
			}

			//return false only if the length is greater than index which means it has a value
			if(op && pfcString.length > indexOfOp +1){
				return false;
			}
			return true;
		},
		__createDisplayRecords : function(records, fieldsInfo){
			var ret = [];
			if(records){
				var i, l = records.length, rec, key, record, value, value1, fieldInfo, rkey;
				for(i = 0; i < l; i++){
					rec = {FieldMap : []}; record = records[i];

					for(key in record){
						if(key == "attributes") continue;

						value = record[key];

						if(fieldsInfo){
							fieldInfo = this.__getFieldInfo(fieldsInfo, key);
							if(fieldInfo && fieldInfo.dataType == "REFERENCE"){
								rkey = fieldInfo.relationshipName;
								if(record[rkey]){
									rec.FieldMap.push({
										ftype: "Reference",
										key: key + "__key",
										value: value
									});
									value = record[rkey][fieldInfo.nameField];
								}
							}
						}

						rec.FieldMap.push({
							ftype : "Result",
							key : key,
							value : value
						});
					}

					ret.push(rec);
				}
			}
			return ret;
		},

		__getFieldInfo : function(fieldsInfo, fieldName){
			var i, l = fieldsInfo.length, ret = null;
			for(i = 0; i < l; i++){
				if(fieldsInfo[i][SVMX.OrgNamespace + "__Field_Name__c"] == fieldName){
					ret = fieldsInfo[i];
					break;
				}
			}
			return ret;
		}

	}, {});

	sfmdeliveryoperations.Class("GetUserInfo", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			// if user information is embeded into the container html/vf
			if(window["svmx_sfm_delivery_userinfo"] != undefined && window["svmx_sfm_delivery_userinfo"] != null ){
				setTimeout(function(){
					ret = window["svmx_sfm_delivery_userinfo"];
					ret = SVMX.toObject(ret);

					// store the user info in the module, used later by cache management
					Module.instance.setUserInfo(ret);
					responder.result(ret);
				}, 1);
			}else{

				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){

						// store the user info in the module, used later by cache management
						Module.instance.setUserInfo(evt.data);
						responder.result(evt.data);
					});

					sRequest.callMethodAsync({methodName : "getUserInfo", data : request});
				}, context : this}, this);
			}
		}

	}, {});

	/**
	 * Deprecated!
	 * TODO: Delete this
	 */
	sfmdeliveryoperations.Class("DescribeObject_OLD", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			// check whether the data is already present in cache
			var module = Module.instance, key = "SFMDELIVERY-DESCRIBE_OBJECT_" + request.objectName;
			var ret = module.getItemFromCache(key);
			if(ret){
				setTimeout(function(){ responder.result(ret); }, 1);
			}else{
				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){

						if(module.checkResponseStatus("DescribeObject", evt.data, false, this) == true){
							module.setItemToCache(key, evt.data);
							responder.result(evt.data);
						}
					}, this);

					sRequest.callApiAsync({url : "sobjects/" + request.objectName + "/describe", data : {objectName : request.objectName}});
				}, context : this}, this);
			}
		}

	}, {});

	sfmdeliveryoperations.Class("DescribeObject", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		// used internally while doing add new detail records
		getObjectDescribe : function(objectName){
			var module = Module.instance, key = "SFMDELIVERY-DESCRIBE_OBJECT_" + objectName;
			var ret = module.getItemFromCache(key);
			return ret;
		},

		performAsync : function(request, responder) {
			// check whether the data is already present in cache
			var module = Module.instance, key = "SFMDELIVERY-DESCRIBE_OBJECT_" + request.objectName;
			var ret = module.getItemFromCache(key), useServerCache = true;

			var shouldUserServerCache = SVMX.getClient().getApplicationParameter("svmx-use-server-cache");
			if(shouldUserServerCache === false){
				useServerCache = false;
				SVMX.getLoggingService().getLogger().info("Server cache is disabled. Using the SFDC meta api");
			}

			if(ret){
				var fl = ret.fields;
				if(typeof fl !== 'object') {
					var fields = [];
					for(var i = 0;i<fl; i++) {
						var newKey = key +"_field_" + i;
						var field = module.getItemFromCache(newKey);
						fields.push(field);
					}
					ret.fields = fields;			
				}
				setTimeout(function(){ responder.result(ret); }, 1);
			}else{

				var requestData = {objectName : request.objectName};

				if(useServerCache){
					if(Module.instance.useJsr){
						SVMXJsr.JsrDescribeObject(requestData, function(result, evt){
                            var profileData = getProfileDataFromResult(result);
                            if (!!profileData){
                                addJSRDataToProfiler(profileData);
                            }

							if(Module.instance.checkResponseStatus("DescribeObject", result, false, this) == true){
								this.__cacheDefinitions(key, requestData, result);
								responder.result(result);
							}
						}, this);
					}else{
						Module.instance.createServiceRequest({handler : function(sRequest){
							sRequest.bind("REQUEST_COMPLETED", function(evt){

								if(module.checkResponseStatus("DescribeObject", evt.data, false, this) == true){
									this.__cacheDefinitions(key, requestData, evt.data);
									responder.result(evt.data);
								}
							}, this);

							sRequest.callMethodAsync({methodName : "getObjectDescription", data : requestData});
						}, context : this}, this);
					}
				}else{
					// use the metadata API
					var me = this;
					this.__describeViaApi(requestData, function(data){
						me.__cacheDefinitions(key, requestData, data);
						responder.result(data);
					});
				}
			}
		},

		__describeViaApi : function(requestData, callback){

			Module.instance.createServiceRequest({handler : function(sRequest){
				sRequest.bind("REQUEST_COMPLETED", function(evt){
					var describeResult = SVMX.xmlToJson(evt.data), describeLayoutResult = null;
					describeResult = describeResult.Envelope.Body.describeSObjectResponse.result;

					if(!describeResult.recordTypeInfos) {
						describeResult.recordTypeInfos = [];
					}

					// single objects are not converted to array while un-marshalling
					if(!(describeResult.recordTypeInfos instanceof Array)){
						describeResult.recordTypeInfos = [describeResult.recordTypeInfos];
					}

					if(!(describeResult.fields instanceof Array)) describeResult.fields = [describeResult.fields];

					var i, fields = describeResult.fields, l = fields.length, field;
					for(i = 0; i < l; i++){
						field = fields[i];

						field.dataType = field.type;
						field.accessible = true;

						if(!field.picklistValues) {
							field.picklistValues = [];
						}

						if(!(field.picklistValues instanceof Array)) {
							field.picklistValues = [field.picklistValues];
						}

						// checkbox types can be controlling fields. simulate the picklist values
						if(field.dataType == 'boolean'){
							field.picklistValues = [
								{label : "false", value : "false"},
								{label : "true", value : "true"}
							];
						}
					}
					// end checkbox

					// check for record type information
					var translations = Module.instance.getItemFromCache("SFMDELIVERY-RECORDTYPE-TRANSLATIONS-" + requestData.objectName);
					var rti = describeResult.recordTypeInfos, recordTypes = [];
					l = rti.length;
					for(i = 0; i < l; i++){
						if(translations && translations[rti[i].recordTypeId] || !translations && rti[i].name !== "Master"){
                            //Defect SER-4958 SFM does not respect Record Type for picklist fields
                            // Do not limit record types based on availability
                            //if (rti[i].available) {
                                recordTypes.push(rti[i].recordTypeId);
                            //}
						}
					}


					if(recordTypes.length > 0){

						Module.instance.createServiceRequest({
						    handler : function(sRequest){
    							sRequest.bind("REQUEST_COMPLETED", function(evt){
    								describeLayoutResult = SVMX.xmlToJson(evt.data);

    								describeLayoutResult =
    									describeLayoutResult.Envelope.Body.describeLayoutResponse.result;
    									OpUtils.processDescribeResult(describeResult, describeLayoutResult);
    									callback(describeResult);
    									return;
    							}, this);

    							sRequest.callApiSync({methodName : "describeLayout",
    								data : {sObjectType : requestData.objectName, recordTypeIds : recordTypes}});
    						},
    						context : this,
    						options : {type : "SOAP"}
    					}, this);

					}else{
						OpUtils.processDescribeResult(describeResult, describeLayoutResult);
						callback(describeResult);
						return;
					}


				}, this);

				sRequest.callApiSync({methodName : "describeSObject", data : {sObjectType : requestData.objectName}});
			}, context : this, options : {type : "SOAP"}}, this);
		},


		__cacheDefinitions : function(key, request, data){
			this.__cacheRecordTypes(request, data);
			this.__cacheDescribeInfo(key, data);
		},

		__cacheDescribeInfo : function(key, data){
			var clonedData = SVMX.cloneObject(data);
			var fields = clonedData.fields;
			if(fields && fields.length>0) {
				clonedData.fields = fields.length;
				var fl = fields.length;
				for(var i = 0;i<fl; i++) {
					var newKey = key +"_field_" + i;
					Module.instance.setItemToCache(newKey, fields[i]);
				}
			}
			Module.instance.setItemToCache(key, clonedData);				
		},

		__cacheRecordTypes : function(request, data){
			var allRecordTypeMapping = data.recordTypeMapping, i, l, item,
				key = "SFMDELIVERY-RECORDTYPES-" + request.objectName;
			if(allRecordTypeMapping){

				Module.instance.setItemToCache(key, allRecordTypeMapping);
				delete data.recordTypeMapping;
			}
		}

	}, {});
	sfmdeliveryoperations.Class("SaveTargetRecord", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var targetRecord = SVMX.create(
				"com.servicemax.client.sfmdelivery.operationutils.SFMTargetRecord", request.data, request.metadata, request.additionalInfo);
			var requestData = targetRecord.getRequest();

			requestData = this._normalizeDatetimes(requestData, request.metadata);

			if(Module.instance.useJsr){
				SVMXJsr.JsrSaveTarget(requestData, function(result, evt){
                    var profileData = getProfileDataFromResult(result);
                    if (!!profileData){
                        addJSRDataToProfiler(profileData);
                    }

					if(Module.instance.checkResponseStatus("SaveTargetRecord", result, false, this) == true){
						var data = request.data;
						if(result && result.resultIds && result.resultIds.length > 0){
							data.setTargetRecordId(result.resultIds[0]);
						}

						//Checking for checklist process.
						if(request.deliveryEngine.getMetaModel().getProcessType() === 'CHECKLIST'){
							var isLocalAttachment = this.isLocalAttachment(request);
							if(isLocalAttachment){
								var attachmentData = {'request':request, 'responder': responder, 'result': result};
								var sfmdeliveryData = SVMX.create("com.servicemax.client.sal.model.impl.UploadAttachment", attachmentData);
								sfmdeliveryData.uploadAttachments();
							} else {
								responder.result(result);
							}
						} else{
							responder.result(result);
						}
					}
				}, this);
			}else{
				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){
							if(Module.instance.checkResponseStatus("SaveTargetRecord", evt.data, false, this) == true){
								// update the target record Id, especially when creating a new record
								var data = request.data;
								if(evt.data && evt.data.resultIds && evt.data.resultIds.length > 0){
									data.setTargetRecordId(evt.data.resultIds[0]);
								}
								responder.result(evt.data);
							}
					}, this);

					sRequest.callMethodAsync({methodName : "saveTarget", data : requestData});
				}, context : this}, this);
			}
		},

		isLocalAttachment : function(request){
			var isLocalAttachment = false;
			var attachmentsHash = request.data.__attachementData.__attachementDataHash;
			if(attachmentsHash){
				var records = Object.keys(attachmentsHash);
				var recordsLength = records.length;
				for (var index = 0; index < recordsLength; index++) {
					var record = attachmentsHash[records[index]];
					if(record && !record[SVMX.OrgNamespace + '__SM_Attachment_ID__c']){
						isLocalAttachment = true;
						break;
					}
				}
			}
			return isLocalAttachment;
		},

		/**
		 *  Normalize datetimes and dates to local time and ISO 8601 format, for parsing by Salesforce.
		 *  This has to be done because the JSR only accepts local time
		 *
		 * @param		(Object)	data	SFM data object
		 * @param		(Object)	meta	SFM metadata object
		 *
		 * @return 	(Object)	SFM data object with normalized dates and times
		 */
		_normalizeDatetimes : function (data, meta) {
				var headerFields = {};
				var detailFields = {};
				var section, field, detail;
				if (data.page === null || data.headerRecord === undefined) return data;

				for (section in meta.page.header.sections) {
					for (field in meta.page.header.sections[section].fields) {
						detail = meta.page.header.sections[section].fields[field].fieldDetail;

						if (detail === undefined || detail === null) {
							continue;
						}

						if (SVMX.OrgNamespace+"__DataType__c" in detail && SVMX.OrgNamespace+"__Field_API_Name__c" in detail) {
							if (detail[ SVMX.OrgNamespace+"__DataType__c" ] == "datetime" || detail[ SVMX.OrgNamespace+"__DataType__c" ] == "date") {
								headerFields[ detail[ SVMX.OrgNamespace+"__Field_API_Name__c" ] ] = detail[ SVMX.OrgNamespace+"__DataType__c" ] ;
							}
						}
					}
				}

				// All detail lines share the same set of fields, so we don't need to iterate through every detail line
				for (section in meta.page.details) {
					for (field in meta.page.details[section].fields) {
						detail = meta.page.details[section].fields[field].fieldDetail;

						if (detail === undefined || detail === null) {
							continue;
						}

						if (SVMX.OrgNamespace+"__DataType__c" in detail && SVMX.OrgNamespace+"__Field_API_Name__c" in detail) {
							if (detail[ SVMX.OrgNamespace+"__DataType__c" ] == "datetime" || detail[ SVMX.OrgNamespace+"__DataType__c" ] == "date") {
								detailFields[detail[ SVMX.OrgNamespace+"__Field_API_Name__c" ]] = detail[ SVMX.OrgNamespace+"__DataType__c" ] ;
							}
						}
					}
				}

				var obj, type, record, valueid;

				for (record = 0; record < data.headerRecord.records.length; record++) {
					for (valueid = 0; valueid < data.headerRecord.records[record].targetRecordAsKeyValue.length; valueid++) {
						obj = data.headerRecord.records[record].targetRecordAsKeyValue[valueid];
						if (obj.key === undefined || headerFields[ obj.key ] === undefined || headerFields[ obj.key ] === null) continue; // Skip this value, it's not a date or datetime

						type = headerFields[ obj.key ];
						if (type == "datetime") {
							// This is literally the worst. Salesforce/our online layer should accept UTC ISO 8601 dates, but it doesn't. So we have to convert the time to local.
							obj.value = DatetimeUtils.convertToTimezone(obj.value);
							data.headerRecord.records[record].targetRecordAsKeyValue[valueid].value = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD[T]HH:mm:ss');
							// Some records have this "value1" attribute, set it to the right format as well, just to be sure.
							data.headerRecord.records[record].targetRecordAsKeyValue[valueid].value1 = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD[T]HH:mm:ss');
						} else if (type == "date") {
							data.headerRecord.records[record].targetRecordAsKeyValue[valueid].value = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD');
							// Some records have this "value1" attribute, set it to the right format as well, just to be sure.
							data.headerRecord.records[record].targetRecordAsKeyValue[valueid].value1 = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD');
						}
					}
				}

				obj = undefined;
				type = undefined;

				for (var detailLine = 0; detailLine < data.detailRecords.length; detailLine++) {
					for (record = 0; record < data.detailRecords[detailLine].records.length; record++) {
						for (valueid = 0; valueid < data.detailRecords[detailLine].records[record].targetRecordAsKeyValue.length; valueid++) {
							obj = data.detailRecords[detailLine].records[record].targetRecordAsKeyValue[valueid];
							if (detailFields[ obj.key ] === undefined || detailFields[ obj.key ] === null) continue; // Skip this value, it's not a date or datetime

							type = detailFields[ obj.key ];
							if (type == "datetime") {
								// This is literally the worst. Salesforce/our online layer should accept UTC ISO 8601 dates, but it doesn't. So we have to convert the time to local.
								obj.value = DatetimeUtils.convertToTimezone(obj.value);
								data.detailRecords[detailLine].records[record].targetRecordAsKeyValue[valueid].value = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD[T]HH:mm:ss');
								// Some records have this "value1" attribute, set it to the right format as well, just to be sure.
								data.detailRecords[detailLine].records[record].targetRecordAsKeyValue[valueid].value1 = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD[T]HH:mm:ss');
							} else if (type == "date") {
								data.detailRecords[detailLine].records[record].targetRecordAsKeyValue[valueid].value = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD');
								// Some records have this "value1" attribute, set it to the right format as well, just to be sure.
								data.detailRecords[detailLine].records[record].targetRecordAsKeyValue[valueid].value1 = DatetimeUtils.getFormattedDatetime(obj.value, 'YYYY-MM-DD');
							}
						}
					}
				}

				return data;
		}

	}, {});

	sfmdeliveryoperations.Class("SaveTargetAttachmentRecord", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var additionalInfo = request.additionalInfo;
			additionalInfo.eventType = 'save checklist attachment';
			var targetRecord = SVMX.create(
				"com.servicemax.client.sfmdelivery.operationutils.SFMTargetAttachmentRecord", request, request.metadata, request.additionalInfo);
			var requestData = targetRecord.getRequest();
			if(Module.instance.useJsr){
				SVMXJsr.JsrSaveTarget(requestData, function(result, evt){
					responder.result(request.data.result);
				}, this);
			}
		}

	}, {});

	sfmdeliveryoperations.Class("GetPageData", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			// Move this over befor it gets stripped away
			this.objectNameMap = request.objectNameMap;
			if (request.layout !== undefined && request.layout !== null)
					this.layout = request.layout;

			// Need to test request object and strip out ALL unsupported properties
			request = this.__prepareRequestObject(request);

		    // check whether the page data is already retrieved via GetPageLayout call.
			var pageData = ModelState.getInstance().remove("pageData");
			if(pageData){
				responder.result(pageData);
			}else if(window["svmx_sfm_delivery_page_data"] != undefined && window["svmx_sfm_delivery_page_data"] != null ){
				// We don't use the embedded container html/vf any more. This is DEPRECATED as of Summer 15.
				console.warn("Unsupported use of embedded page data in HTML/VF! Embedded page data has been deprecated as of Summer 15.");
				// if page data is embeded into the container html/vf
				pageData = window["svmx_sfm_delivery_page_data"];
				pageData = SVMX.toObject(pageData);

				// clean up the embedded data
				window["svmx_sfm_delivery_page_data"] = null;

				pageData.data.objectNameMap = this.objectNameMap;
				responder.result(SVMX.create("com.servicemax.client.sal.model.impl.SFMDeliveryData", pageData.data));
			}else{

				if(Module.instance.useJsr){
					SVMXJsr.JsrGetPageData(request, function(result, evt){
						var profileData = getProfileDataFromResult(result);
						if (!!profileData){
							addJSRDataToProfiler(profileData);
						}

						if(Module.instance.checkResponseStatus("GetPageData", result, false, this) == true){
							this.__processResponseData(result, request, responder);
						}
					}, this);
				}else{
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){
							this.__processResponseData(evt.data, request, responder);
						}, this);
						sRequest.callMethodAsync({methodName : "getPageData", data : request});
					}, context : this}, this);
				}
			}
		},

		__prepareRequestObject : function(request) {
			/*
				Acceptable request parameters. Any property on the request object that does not belong will throw an error

				processId: string
				recordId: string
				qualify: bool
				actionType: string
		    */
		    var acceptable = {
		    	processId: true,
		    	recordId: true,
		    	targetId: true,
		    	qualify: true,
		    	actionType: true
		    };

		    if (request) {
		    	if (request.refreshData) {
			    	request.actionType = "QuickSave";
			    }

			    // Remove any property that does not belong
			    for(var key in request) {
			    	if (!acceptable[key]) {
			    		delete request[key];
			    	}
			    }
		    }

		    return request;
		},

		__processResponseData : function(data, request, responder){
			if(Module.instance.checkResponseStatus("GetPageData", data, false, this) == true){
				var resp = null;
				if(request.qualify && !data.isQualified ){
					resp = {isQualified : false};
				}else if(data.data.pageDataSet.sobjectinfo){
					data.data.objectNameMap = this.objectNameMap;
					if (this.layout !== undefined)
						data.data = this._normalizeDatetimes(data.data, this.layout);
					resp = SVMX.create("com.servicemax.client.sal.model.impl.SFMDeliveryData", data.data);
				}else if(data.data.pageDataSet.lstSobjectinfo!=undefined && data.data.pageDataSet.lstSobjectinfo.length>0){
						var sobjectinfo = SVMX.cloneObject(data.data.pageDataSet.lstSobjectinfo[0]);
						if(sobjectinfo.hasOwnProperty([SVMX.OrgNamespace +'__ChecklistMetaJSON__c']) && data.data.pageDataSet.lstSobjectinfo.length>1) {

								sobjectinfo[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'] = data.data.pageDataSet.lstSobjectinfo.map(function(eachRecord) {
								   return eachRecord.hasOwnProperty(SVMX.OrgNamespace + '__ChecklistMetaJSON__c') ? eachRecord[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'] : ""
								}).join("");

						}
						data.data.pageDataSet["sobjectinfo"] = sobjectinfo;

						data.data.objectNameMap = this.objectNameMap;
						if (this.layout !== undefined)
						data.data = this._normalizeDatetimes(data.data, this.layout);
						data.data.response.processType = 'CHECKLIST';
						resp = SVMX.create("com.servicemax.client.sal.model.impl.SFMDeliveryData", data.data);
					}

				responder.result(resp);
			}
		},

		/**
		 *  Normalize datetimes and dates to local time and ISO 8601 format, for parsing by Salesforce.
		 *  This has to be done because the JSR only accepts local time
		 *
		 * @param		(Object)	data	SFM data object
		 * @param		(Object)	meta	SFM metadata object
		 *
		 * @return 	(Object)	SFM data object with normalized dates and times
		 */
		_normalizeDatetimes : function (data, meta) {
				var headerFields = {};
				var detailFields = {};
				var section, field, detail;
				if (data.pageDataSet === null || data.pageDataSet === undefined) return data;

				for (section in meta.page.header.sections) {
					for (field in meta.page.header.sections[section].fields) {
						detail = meta.page.header.sections[section].fields[field].fieldDetail;

						if (detail === undefined || detail === null) {
							continue;
						}

						if (SVMX.OrgNamespace+"__DataType__c" in detail && SVMX.OrgNamespace+"__Field_API_Name__c" in detail) {
							if (detail[ SVMX.OrgNamespace+"__DataType__c" ] == "datetime" || detail[ SVMX.OrgNamespace+"__DataType__c" ] == "date") {
								headerFields[ detail[ SVMX.OrgNamespace+"__Field_API_Name__c" ] ] = detail[ SVMX.OrgNamespace+"__DataType__c" ] ;
							}
						}
					}
				}

				// All detail lines share the same set of fields, so we don't need to iterate through every detail line
				for (section in meta.page.details) {
					for (field in meta.page.details[section].fields) {
						detail = meta.page.details[section].fields[field].fieldDetail;

						if (detail === undefined || detail === null) {
							continue;
						}

						if (SVMX.OrgNamespace+"__DataType__c" in detail && SVMX.OrgNamespace+"__Field_API_Name__c" in detail) {
							if (detail[ SVMX.OrgNamespace+"__DataType__c" ] == "datetime" || detail[ SVMX.OrgNamespace+"__DataType__c" ] == "date") {
								detailFields[detail[ SVMX.OrgNamespace+"__Field_API_Name__c" ]] = detail[ SVMX.OrgNamespace+"__DataType__c" ] ;
							}
						}
					}
				}

				// We need to remove the Salesforce specific fields from the list, because they are actually GMT.
				delete headerFields['CreatedDate'];
				delete headerFields['LastActivityDate'];
				delete headerFields['LastModifiedDate'];
				delete headerFields['LastReferencedDate'];
				delete headerFields['LastViewedDate'];
				delete headerFields['SystemModstamp'];

				delete detailFields['CreatedDate'];
				delete detailFields['LastActivityDate'];
				delete detailFields['LastModifiedDate'];
				delete detailFields['LastReferencedDate'];
				delete detailFields['LastViewedDate'];
				delete detailFields['SystemModstamp'];

				var obj;
				var type;

				for (field = 0; field < data.pageDataSet.bubbleInfo.length; field++) {
					obj = data.pageDataSet.bubbleInfo[field];
					if (headerFields[obj.fieldapiname] === undefined || headerFields [obj.fieldapiname] === null) continue;

					type = headerFields[obj.fieldapiname];
					if (type == "datetime") {
						// This is literally the worst. Salesforce/our online layer should provide UTC ISO 8601 dates, but it doesn't. So we have to convert the local to GMT.
						obj.fieldvalue.key = DatetimeUtils.convertToTimezone(obj.fieldvalue.key, undefined, true);
						data.pageDataSet.bubbleInfo[field].fieldvalue.key = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD[T]HH:mm:ss');
						data.pageDataSet.bubbleInfo[field].fieldvalue.value = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD[T]HH:mm:ss');
					} else if (type == "date") {
						data.pageDataSet.bubbleInfo[field].fieldvalue.key = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD');
						data.pageDataSet.bubbleInfo[field].fieldvalue.value = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.value, 'YYYY-MM-DD');
					}
				}

				obj = undefined;
				type = undefined;

				for (field in headerFields) {
					// manipulate sobjectinfo just in case too
					obj = data.pageDataSet.sobjectinfo[field];
					if (obj === undefined || obj === null) continue;

					type = headerFields[field];
					if (type == "datetime") {
						// This is literally the worst. Salesforce/our online layer should provide UTC ISO 8601 dates, but it doesn't. So we have to convert the local to GMT.
						obj = DatetimeUtils.convertToTimezone(obj.split('+')[0], undefined, true);
						data.pageDataSet.sobjectinfo[field] = DatetimeUtils.getFormattedDatetime(obj, 'YYYY-MM-DD[T]HH:mm:ss');
					} else if (type == "date") {
						data.pageDataSet.sobjectinfo[field] = DatetimeUtils.getFormattedDatetime(obj, 'YYYY-MM-DD');
					}
				}

				obj = undefined;
				type = undefined;

				for (var detail = 0; detail < data.detailDataSet.length; detail++) {
					for (var record = 0; record < data.detailDataSet[detail].pageDataSet.length; record++) {
						// defect 24390 -- the following line avoids the app breaking when
						// data.detailDataSet[detail].pageDataSet[record].bubbleInfo is null
						if (!data.detailDataSet[detail].pageDataSet[record].bubbleInfo) continue;
						for (var field = 0; field < data.detailDataSet[detail].pageDataSet[record].bubbleInfo.length; field++) {
							obj = data.detailDataSet[detail].pageDataSet[record].bubbleInfo[field];
							if (!('fieldapiname' in obj)) continue;
							if (detailFields[obj.fieldapiname] === undefined || detailFields[obj.fieldapiname] === null) continue;

							type = detailFields[obj.fieldapiname];
							if (type == "datetime") {
								// This is literally the worst. Salesforce/our online layer should provide UTC ISO 8601 dates, but it doesn't. So we have to convert the local to GMT.
								obj.fieldvalue.key = DatetimeUtils.convertToTimezone(obj.fieldvalue.key, undefined, true);
								data.detailDataSet[detail].pageDataSet[record].bubbleInfo[field].fieldvalue.key = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD[T]HH:mm:ss');
								data.detailDataSet[detail].pageDataSet[record].bubbleInfo[field].fieldvalue.value = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD[T]HH:mm:ss');
							} else if (type == "date") {
								data.detailDataSet[detail].pageDataSet[record].bubbleInfo[field].fieldvalue.key = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.key, 'YYYY-MM-DD');
								data.detailDataSet[detail].pageDataSet[record].bubbleInfo[field].fieldvalue.value = DatetimeUtils.getFormattedDatetime(obj.fieldvalue.value, 'YYYY-MM-DD');
							}
						}

						obj = undefined;
						type = undefined;

						for (field in detailFields) {
							obj = data.detailDataSet[detail].pageDataSet[record].sobjectinfo[field];
							if (obj === undefined || obj === null) continue;

							type = detailFields[field];
							if (type == "datetime") {
								// This is literally the worst. Salesforce/our online layer should provide UTC ISO 8601 dates, but it doesn't. So we have to convert the local to GMT.
								obj = DatetimeUtils.convertToTimezone(obj, undefined, true);
								data.detailDataSet[detail].pageDataSet[record].sobjectinfo[field] = DatetimeUtils.getFormattedDatetime(obj, 'YYYY-MM-DD[T]HH:mm:ss');
							} else if (type == "date") {
								data.detailDataSet[detail].pageDataSet[record].sobjectinfo[field] = DatetimeUtils.getFormattedDatetime(obj, 'YYYY-MM-DD');
							}
						}

					}
				}

				return data;
		}

	}, {});

	sfmdeliveryoperations.Class("GetTemplateData", com.servicemax.client.mvc.api.Operation, {
		__sourceRecordId: null,
		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			// Move this over before it gets stripped away
			this.objectNameMap = request.objectNameMap;
			this.__sourceRecordId = request.recordId;

			// Temp Hack until we get server side to return true for CHECKLIST types
			window['svmx_sfm_delivery_is_sfmprocess'] = true;
			window['svmx_sfm_delivery_is_qualified'] = true;

			// Need to test request object and strip out ALL unsupported properties
			request = this.__prepareRequestObject(request);

		    // check whether the page data is already retrieved via GetPageLayout call.
			var pageData = ModelState.getInstance().remove("pageData");
			if(pageData){
				responder.result(pageData);
			}else if(window["svmx_sfm_delivery_page_data"] != undefined && window["svmx_sfm_delivery_page_data"] != null ){
				// if page data is embeded into the container html/vf
				pageData = window["svmx_sfm_delivery_page_data"];
				pageData = SVMX.toObject(pageData);

				// clean up the embedded data
				window["svmx_sfm_delivery_page_data"] = null;

				pageData.data.objectNameMap = this.objectNameMap;
				responder.result(
						SVMX.create("com.servicemax.client.sal.model.impl.SFMDeliveryData", pageData.data));
			}else{

				if(Module.instance.useJsr){
					SVMXJsr.JsrGetListOfChecklist(request, function(result, evt){
                    	var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

                        if(Module.instance.checkResponseStatus("GetTemplateData", result, false, this) == true){
							this.__processResponseData(result, request, responder);
						}
					}, this);
				}else{
					/* SUPPORTED ?
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){
								this.__processResponseData(evt.data, request, responder);
						}, this);
						sRequest.callMethodAsync({methodName : "getPageData", data : request});
					}, context : this}, this);
					*/
				}
			}
		},

		__prepareRequestObject : function(request) {
			/*
				Acceptable request parameters. Any property on the request object that does not belong will throw an error

				processId: string
				recordId: string
		    */
		    var acceptable = {
		    	processId: true,
		    	recordId: true
		    };

		    if (request) {
			    // Remove any property that does not belong
			    for(var key in request) {
			    	if (!acceptable[key]) {
			    		delete request[key];
			    	}
			    }
		    }

		    return request;
		},

		__processResponseData : function(data, request, responder){
			if(Module.instance.checkResponseStatus("GetTemplateData", data, false, this) == true){
				var resp = null;
				if(request.qualify && !data.isQualified ){
					resp = {isQualified : false};
				}else if(data.lstChecklistInfo !== undefined){
					var virtualData = {};

					virtualData.objectNameMap = this.objectNameMap;

					virtualData.pageDataSet = {
						sobjectinfo: {
							attributes: {
								type: "Virtual__c"
							}
						},
						sourceRecordID: this.__sourceRecordId,

						sourceRecord: data.stringFieldMap,    // Source Record for Checklist. Required for Entry criteria.
						
						bubbleInfo: [{
							fieldapiname: "LIST_SECTION_FIELD_ID",
							fieldvalue: {
								key: "templates",
								value: data.lstChecklistInfo || [],
								value1: null
							}
						}]
					};

					resp = SVMX.create("com.servicemax.client.sal.model.impl.SFMDeliveryData", virtualData);
				}
				responder.result(resp);
			}
		}

	}, {});

	sfmdeliveryoperations.Class("GetNextStepInfo", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var requestData = request;
			if (!requestData.recordId) requestData.recordId = SVMX.getUrlParameter("SVMX_recordId");
			if(Module.instance.useJsr){
				SVMXJsr.JsrGetNextStepInfo(requestData, function(result, evt){
					var profileData = getProfileDataFromResult(result);
                    if (!!profileData){
                        addJSRDataToProfiler(profileData);
                    }

                    if(Module.instance.checkResponseStatus("GetNextStepInfo", result, true, this) == true){
							var nextStepUrl = result.message;
							responder.result({nextStepUrl : nextStepUrl});
						}
				}, this);
			}else{
				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){

						if(Module.instance.checkResponseStatus("GetNextStepInfo", evt.data, true, this) == true){
							var nextStepUrl = evt.data.message;
							responder.result({nextStepUrl : nextStepUrl});
						}
					}, this);

					sRequest.callMethodAsync({methodName : "getNextStepInfo", data : requestData});
				}, context : this}, this);
			}
		}

	}, {});

	sfmdeliveryoperations.Class("InvokeEvent", com.servicemax.client.mvc.api.Operation, {
		__responder : null,
		__constructor : function(){ this.__base(); },
		performAsync : function(request, responder) {
            request.additionalInfo.eventType = request.event.eventType;
            this.__responder = responder;
            var eventInfo = request.event;
            if(eventInfo.callType == "WEBSERVICE"){
                this.__invokeWebServiceEvent(request);
            }else if(eventInfo.callType == "JAVASCRIPT"){
                this.__invokeJavaScriptEvent(request);
            }else if(eventInfo.callType == "URL"){
                this.__invokeUrlEvent(request);
            }else{
                // unknown event type
            }
        },

        __invokeUrlEvent : function(request){
            var me = this;
            SVMX.openInBrowserWindow(request.event.target);
            setTimeout(function(){ me.__responder.result(); }, 1);
        },

        __invokeJavaScriptEvent : function(request){
            var eventId = request.event.eventId, me = this;

            // check whether the data is already present in cache
            var module = Module.instance, key = "SFMDELIVERY-SNIPPET-" + eventId;
            var snippet = module.getItemFromCache(key);

            if(snippet){
                setTimeout(function(){ me.__invokeSnippet(snippet, request); }, 1);
            }else{
                // get the snippet from the server
                var requestData = {eventId : eventId};
                if(Module.instance.useJsr){
                    SVMXJsr.JsrGetSnippetForEvent(requestData, function(result, evt){
                        var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

                        this.__handleSnippetResponse(key, request, eventId, result);
                    }, this);
                }else{
                    Module.instance.createServiceRequest({handler : function(sRequest){
                        sRequest.bind("REQUEST_COMPLETED", function(evt){
                            this.__handleSnippetResponse(key, request, eventId, evt.data);
                        }, this);

                        sRequest.callMethodAsync({methodName : "getSnippetForEvent", data : requestData});
                    }, context : this}, this);
                }
            }
        },

        __handleSnippetResponse : function(key, request, eventId, data){
            if(Module.instance.checkResponseStatus("__invokeJavaScriptEvent", data, false, this) == true){
                var allInfo = data.stringMap, i, l = allInfo.length, snippet;
                for(i = 0; i < l; i++){
                    if(allInfo[i].key == "EventData"){
                        snippet = allInfo[i].value;
                        Module.instance.setItemToCache(key, snippet);
                        break;
                    }
                }

                if(snippet){
                    this.__invokeSnippet(snippet, request);
                }else{
                    SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-InvokeEvent").warning("No snippet found for =>" + eventId);
                    this.__responder.fault();
                }
            }
        },

        __invokeSnippet : function(snippet, request){
            var targetRecord = SVMX.create("com.servicemax.client.sfmdelivery.operationutils.SFMTargetRecord",
                request.data, request.metadata, request.additionalInfo);
            var requestData = targetRecord.getRequest();

            $EXPR.SVMXEvalExpression(snippet, requestData, function(result){
                request.data.copyFromTargetRecord(result);
                    this.__responder.result();
            }, this);
        },

        __invokeWebServiceEvent : function(request){
            var targetRecord = SVMX.create(
                "com.servicemax.client.sfmdelivery.operationutils.SFMTargetRecord", request.data, request.metadata, request.additionalInfo);
            var requestData = targetRecord.getRequest();
			var endpoint, ns;

			// WARNING: The entire concept of a return url will change once this is running within a console.
			requestData.stringMap = [
				{key: "SVMX_processId", value: request.additionalInfo.processId},
				{key: "SVMX_recordId",  value: (request.data.getRawValues().Id || SVMX.getUrlParameter("SVMX_recordId"))},
				{key: "SVMX_retURL",    value: SVMX.getUrlParameter("SVMX_retURL")},
				{key: "SVMX_NxtStepID", value: request.additionalInfo.nextStepId}
			];

            try{
                var target = request.event.target, targetInfo = target.split("."), endPointInfo = targetInfo[0],
                    method = targetInfo[1];
				ns = null;
				endPoint = endPointInfo;
                if(endPointInfo.indexOf("__") != -1){
                    endPointInfo = endPointInfo.split("__"); endPoint = endPointInfo[1]; ns = endPointInfo[0];
                }
            }catch(e){
                SVMX.getLoggingService().getLogger().error(
                    "There was an error while processing target info for WEBSERVICE event => " + request.event.target + ".." + e);
                responder.fault();
                return;
            }

            Module.instance.createServiceRequest({handler : function(sRequest){
                sRequest.bind("REQUEST_COMPLETED", function(evt){
					var data;
					try {
                        var ret = this.__processSoapXml(evt.data);
                        data = ret.Envelope.Body;
                        for(var name in data){  // skip the response data type
                            data = data[name];
                            break;
                        }
                    } catch(e) {
                        // Added so that when offline calls for soap and fails misserably, app can continue...
                        SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-InvokeEvent").error("Can't processSoapXml!");
                        this.__responder.result();
                        return;
                    }

                    if(Module.instance.checkResponseStatus("WS EVENT", data.result, false, this) == true){

                        // check if event execution results in navigation
                        if(this.__checkForNavigation(data.result) == false){

                            // it is possible that the event event response only contains
                            // status information and no data, typically in after save events. In such cases,
                            // continue without throwing any error
                            try{
                                request.data.updateFromEvent(data.result);
                            }catch(e){
                                SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-InvokeEvent")
                                    .warning("Could not update the client model from the event response. Ignoring. <" + e + ">");
                            }

                            this.__responder.result();
                        }
                    }
                }, this);

                sRequest.callMethodAsync({methodName : method, data : requestData});
            }, context : this, options : {type : "SOAP", endPoint : endPoint, namespace : ns}}, this);
        },

        __checkForNavigation : function(data){
            var navigateInfo = this.__getFromResponse(data, "NAVIGATE_TO"), ret = false;
            if(navigateInfo){
                ret = true;
                var baseUrl = "";
                // If its a salesforceId...
                if (navigateInfo.match(/^[a-zA-Z0-9]+$/)) {
					baseUrl = (SVMX.getClient().getApplicationParameter("svmx-base-url") || "") + "/";
    			}

                // perform navigation
                SVMX.navigateTo(baseUrl + navigateInfo);
            }

            return ret;
        },

        __getFromResponse : function(data, key){
            var sm = data.response.stringMap, ret = null;
            if(sm){
                if(!(sm instanceof Array)){
                    sm = [sm];
                }

                var i , l = sm.length;
                for(i = 0; i < l; i++){
                    if(sm[i].key == key){
                        ret = sm[i].value;
                        break;
                    }
                }
            }

            return ret;
        },
        __processSoapXml:function ( data ) {
            function xmlToJson ( xml ) {
                var attr;
                var childItemNode;
                var xmlAttributes = xml.attributes;
                var childNodes = xml.childNodes;
                var nodeType = xml.nodeType;
                var returnObject = {};
                var i = -1;

                if ( nodeType == 1 && xmlAttributes.length ) {
                    i = -1;
                } else if ( nodeType == 3 ) {
                    returnObject = xml.nodeValue;
                }
                while ( childItemNode = childNodes.item( ++i ) ) {
                    nodeType = childItemNode.nodeName;
                    nodeType = nodeType.indexOf( ":" ) != -1 ? nodeType.split( ":" )[1] : nodeType;
                    if ( returnObject.hasOwnProperty( nodeType ) ) {
                        if ( returnObject.toString.call( returnObject[nodeType] ) != '[object Array]' ) {
                            returnObject[nodeType] = [returnObject[nodeType]];
                        }
                        returnObject[nodeType].push( xmlToJson( childItemNode ) );
                    } else {
                        returnObject[nodeType] = xmlToJson( childItemNode );
                    }
                }

                return returnObject;
            }

            function correctObject ( returnObject ) {
                for ( var name in returnObject ) {
                    var objItem = returnObject[name];
                    if ( objItem && typeof(objItem) == 'object' ) {
                        if ( objItem.hasOwnProperty( "#text" ) ) {
                            returnObject[name] = objItem["#text"];
                        } else if ( name == "value1" && typeof(objItem) == 'object' ) {
                            returnObject[name] = null;
                        } else if ( name == "value" && typeof(objItem) == 'object' ) {
                            returnObject[name] = null;
                        } else if ( name == "key" && typeof(objItem) == 'object' ) {
                            returnObject[name] = null;
                        } else {
                            correctObject( objItem );
                        }
                    }
                }

                return returnObject;
            }

            var ret = correctObject( xmlToJson( data ) );

            return ret;
        }
    });

	sfmdeliveryoperations.Class("AddRecords", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData =  {processId : request.processId, alias : request.alias};

			var newRecordsFromCache = this.__addRecordsFromCache(request);
			var objectInfo = new sfmdeliveryoperations.DescribeObject().getObjectDescribe(request.objectName);

			if(newRecordsFromCache != null){
	            if(Module.instance.checkResponseStatus("AddRecords", newRecordsFromCache, false, this) == true){
					OpUtils.addRecords_processData({
						request: request,
						responder: responder,
						data: newRecordsFromCache,
						objectInfo: objectInfo,
						operation: this,
						cacheKey: "",
						onSuccess : function(data) {
                             responder.result(data);
						}
					});
				}
			}else{
				if(Module.instance.useJsr){
					SVMXJsr.JsrAddRecords(requestData, function(result, evt){
			            var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

                        if(Module.instance.checkResponseStatus("AddRecords", result, false, this) == true){
							getOpUtils().addRecords_processData({
								request: request,
								responder: responder,
								data: result,
								objectInfo: objectInfo,
								operation: this,
								cacheKey: this.__getCacheKey(request),
								onSuccess : function(data) {
		                             responder.result(data);
								}
							});
						}
					}, this);
				}else{
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){
				            if(Module.instance.checkResponseStatus("AddRecords", evt.data, false, this) == true){
								getOpUtils().addRecords_processData({
									request: request,
									responder: responder,
									data: evt.data,
									objectInfo: objectInfo,
									operation: this,
									cacheKey: this.__getCacheKey(request)
								});
							}
						}, this);

						sRequest.callMethodAsync({methodName : "addRecords",data : requestData});
					}, context : this}, this);
				}
			}
		},

		__addRecordsFromCache : function(request){

			// check whether the data is present in the cache
			var module = Module.instance, key = this.__getCacheKey(request);
			var template = module.getItemFromCache(key), ret = template;
			if(template) {
				SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-AddRecords")
						.info("Creating record(s) for <" + request.alias + "> from cache");
			}

			return ret;
	},

	__getCacheKey : function(request){
			return "SFMDELIVERY-ADDRECORDS-TEMPLATE-" + request.processId + "-" + request.alias;
		}

	}, {});

	sfmdeliveryoperations.Class("DeleteRecords", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			request.data.deleteDetailRecords(request.records, request.alias);
			responder.result({});
		}

	}, {});

	sfmdeliveryoperations.Class("LookupItemSelected", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			com.servicemax.client.sal.model.impl.LookupCacheUtil.addToCache(request);
		}

	}, {});

	sfmdeliveryoperations.Class("GetBubbleData", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var requestData = {
				RecordId : request.RecordId
			};
			if (request.LookupRecordId) {
				requestData.LookupRecordId = request.LookupRecordId;
			} else {
				requestData.ObjectName = request.ObjectName;
			}

			if(Module.instance.useJsr){
				SVMXJsr.JsrGetBubbleData(requestData, function(result, evt){
					var profileData = getProfileDataFromResult(result);
                    if (!!profileData){
                        addJSRDataToProfiler(profileData);
                    }

                    if(Module.instance.checkResponseStatus("GetBubbleData", result, false, this) == true){
						responder.result(result);
					}
				}, this);
			}else{
				Module.instance.createServiceRequest({handler : function(sRequest){
					sRequest.bind("REQUEST_COMPLETED", function(evt){

						if(Module.instance.checkResponseStatus("GetBubbleData", evt.data, false, this) == true){
							responder.result(evt.data);
						}
					}, this);

					sRequest.callMethodAsync({methodName : "getBubbleData", data : requestData});
				}, context : this}, this);
			}
		}

	}, {});

	sfmdeliveryoperations.Class("GetRecordTypes", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var module = Module.instance, key = "SFMDELIVERY-RECORDTYPES-" + request.objectName;
			var recordTypes = module.getItemFromCache(key);


			// This code assumes that we always get this as cached data
			if(recordTypes){
				var translationKey = "SFMDELIVERY-RECORDTYPE-TRANSLATIONS-" + request.objectName;
				var recordTypeNames = module.getItemFromCache(translationKey);
				if (recordTypeNames) {
					SVMX.array.forEach(recordTypes, function(recordType) {
						recordType.fixedName = recordTypeNames[recordType.recordTypeId];
					}, this);
				}


				setTimeout(function(){ responder.result(recordTypes); }, 1);
			}else{
				var requestData = { objectName : request.objectName };

				if(Module.instance.useJsr){
					SVMXJsr.JsrGetRecordTypes(requestData, function(result, evt){
						var profileData = getProfileDataFromResult(result);
                        if (!!profileData){
                            addJSRDataToProfiler(profileData);
                        }

                        if(Module.instance.checkResponseStatus("GetRecordTypes", result, false, this) == true){
							module.setItemToCache(key, result);
							responder.result(result);
						}
					}, this);
				}else{
					Module.instance.createServiceRequest({handler : function(sRequest){
						sRequest.bind("REQUEST_COMPLETED", function(evt){

							if(Module.instance.checkResponseStatus("GetRecordTypes", evt.data, false, this) == true){
								module.setItemToCache(key, evt.data);
								responder.result(evt.data);
							}
						}, this);

						sRequest.callMethodAsync({methodName : "getRecordTypes", data : requestData});
					}, context : this}, this);
				}
			}
		}

	}, {});


	/**
	 * @todo: Not yet implemented
	 */
    sfmdeliveryoperations.Class("GetRecordAlreadyOpen", com.servicemax.client.mvc.api.Operation, {

        __constructor: function() {
            this.__base();
        },

        performAsync: function(request, responder) {
            responder.result(false);
        }
    });

    sfmdeliveryoperations.Class("GetViewProcesses", com.servicemax.client.mvc.api.Operation, {

        __constructor: function() {
            this.__base();
        },

        performAsync: function(request, responder) {
        	responder.result([]);
        }
    }, {});
};
})();

// end of file
