/**
 * This file needs a description
 * @class com.servicemax.client.sfmopdocdelivery.engine
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var engine = SVMX.Package("com.servicemax.client.sfmopdocdelivery.engine");

engine.init = function(){
	//imports
	var CONSTANTS = com.servicemax.client.sfmopdocdelivery.constants.Constants;
	var utils = com.servicemax.client.sfmopdocdelivery.utils.SFMOPDOCUtils;
	//end imports

	engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
		__nodeProcessor : null, __orgNamespace : null, styleNodeValue : null, __timeFormat : null, __dateFormat : null, __uniqueObjects : null,
		__depthCount : 2, __uniqueObjects : null, __jsee : null, __pendingNodeItems : null, __metadata : null, __data : null,
		__processedMetadata : null, __recsInfo : null, __aliasObjectName : null, __aliasDescribeInfo : null, __imageIds : null,
		__eventBus : null, __signaturesPending : null, __allowSignatures : null, __allowDraft : null, __spinner : null,
		__displayTags : null, __settings : null,
		__recordId : null, __processId : null, __sourceRecord : null, __objectLabel : null, __isCheckListProcess:false, __isLightning:null, __isSalesForceIsInLightning:null,
		initAsync : function(options){
			// nothing to initialize, return
			//options.handler.call(options.context);
			var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
			this.__eventBus = SVMX.create("com.servicemax.client.sfmopdocdelivery.impl.SFMOPDOCDeliveryEngineEventBus", {});

			// create the named default controller
			ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){

				// now create the named default model
				ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
					controller.setModel(model);
					options.handler.call(options.context);
				}, context : this});

			}, context : this, additionalParams : { eventBus : this.__eventBus }});
		},

		run : function(options){
			if(options !== undefined && options !== null &&
					options.options !== undefined && options.options !== null) {
				this.__processId = options.options.SVMX_processId;
				this.__recordId = options.options.SVMX_recordId;
				this.__processName = options.options.SVMX_processName;
				this.changeStyleSignature = options.changeStyleSignature;
				this.removeSignatureButtons = options.removeSignatureButtons;
				this.createSignatureButtons = options.createSignatureButtons;
				this.addReplaceCapturedSignature = options.addReplaceCapturedSignature;
				this.onEngineRendered = options.onRendered;

				//as of now used for only laptop mobile
				this.__sourceRecord = options.options.SVMX_record;
			}
			this.__isLightning = SVMX.getClient().getApplicationParameter('lightning');
			this.__isSalesForceIsInLightning = SVMX.getClient().getApplicationParameter('isSalesforceLightning');;
			if(this.__processId === undefined || this.__processId === null) {
				this.__processId = SVMX.getUrlParameter("SVMX_processId");
			}

			if(this.__recordId === undefined || this.__recordId === null) {
				this.__recordId = SVMX.getUrlParameter("SVMX_recordId");
			}

			var serv = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
			serv.createNamedInstanceAsync("NODE_PROCESSOR",{ handler : function(processor){
				this.__nodeProcessor = processor;
				this.__orgNamespace = SVMX.getClient().getApplicationParameter("org-name-space");
				this.__allowSignatures = SVMX.getClient().getApplicationParameter("allow-signatures");
				this.__allowDraft = SVMX.getClient().getApplicationParameter("allow-draft");
				this.__runInternal(options);
			}, context : this });
		},

		__runInternal : function(options){
			this.__rootNode = options.container ? options.container.body.dom : $("#" + SVMX.getDisplayRootId());
			this.__rootNode.css('width', '100%');
			$($("body")[0]).css('background-image', 'none');
			var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
			this.returnUrl  = SVMX.getUrlParameter("SVMX_retURL");
			var qInfo = platformSpecifics.getQualificationInfo(this.__recordId, this.__processId, this.__process, this);
			this.__requestClose = options.requestClose;
			this.__requestCancel = options.requestCancel;
			this.__settings = platformSpecifics.getSettingsInfo();
		},

		__process : function(qInfo){
			if(!qInfo.isQualified){
				var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
				platformSpecifics.alert(qInfo.errorMessage, this.__requestCancel);
				platformSpecifics.navigateBack(this.returnUrl);
			}
			else{
				//show the spinner
				this.__includeSpinner();
				this.__jsee = new com.servicemax.client.sfmopdocdelivery.jsel.JSExpressionEngine(this);
				this.__pendingNodeItems = new com.servicemax.client.sfmopdocdelivery.engine.PendingNodeProcessCollection();
				this.__signaturesPending = new com.servicemax.client.sfmopdocdelivery.engine.PendingSignatures(this);

				//special handling for image processing
				SVMX.getClient().triggerEvent(new com.servicemax.client.lib.api.Event("SFMOPDOCDELIVERY.JSEE_CREATED", this, {jsee : this.__jsee}));
				this.__jsee.initialize({ contextRoots : ["$D","$M"] });

				//invoking events for getTemplate, Userinfo, Metadata, and Data
				var currentApp = this.getEventBus();
				var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection",currentApp,
						[
						 	SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.GET_TEMPLATE", this, {request : { context : this, processId : this.__processId }}),
							SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.GET_USERINFO", this, {request : { context : this }}),
							SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.GET_DOCUMENT_METADATA", this, {request : { context : this, processId : this.__processId }}),
							SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.GET_DOCUMENT_DATA", this, {request : { context : this, returnUrl : this.returnUrl, processId : this.__processId, recordId : this.__recordId }}),
							SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.GET_DISPLAY_TAGS", this, {request : { context : this }})

						 ]);

				ec.triggerAll(function(evtCol){
					var items = evtCol.items(), size = items.length, i, template = null;
					for(i = 0; i < size; i++){
						var item = items[i];
						if(item.type() == "SFMOPDOCDELIVERY.GET_DOCUMENT_METADATA"){
							this.__metadata = item.response;
						}else if(item.type() == "SFMOPDOCDELIVERY.GET_DOCUMENT_DATA"){
							this.__data = item.response;	
						}else if(item.type() == "SFMOPDOCDELIVERY.GET_USERINFO"){
							this.__onGetUserInfoComplete(item.response);
						}else if(item.type() == "SFMOPDOCDELIVERY.GET_TEMPLATE"){
							template = item.response;
						}else if(item.type() == "SFMOPDOCDELIVERY.GET_DISPLAY_TAGS"){
							this.__displayTags = item.response;
						}
					}
					if (template) {
						this.__onGetTemplateComplete(template);
						this.__getObjectDescribeInfo();
					} else {
						var failureEvents = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection",currentApp,
						[
						 	SVMX.create("com.servicemax.client.lib.api.Event",
								"SFMOPDOCDELIVERY.MISSING_TEMPLATE", this, {request : { context : this }})
						]);

						// Let everyone know we cannot open the O/P Doc and let them take appropriate action
						failureEvents.triggerAll();
					}


				},this)
			}


		},
		
		__makeAttachmentProperty : function(){
			var data = this.__data;
			if(this.__isChecklistAttachmentHasPermission()){
				var count = data.DocumentData.length;
				for (var index = 0; index < count; index++) {
    	        	var key = data.DocumentData[index]["Key"];
    	        	if (key != undefined && key.indexOf("Checklist") >= 0) {
    	        		this.__jsee.setProperty("allChecklistAttachment",this.__getObjectHashMapFromArray(data.DocumentData[index].relatedRecords));
    	        		break;
    	        	}
    	        }
			} else {
				this.__jsee.setProperty("allChecklistAttachment",[]);
			}
		},

		__isChecklistAttachmentHasPermission:function(){
			if(this.__aliasDescribeInfo && this.__aliasDescribeInfo.Checklist_Attachment){
				var attachObjectDescribe = this.__aliasDescribeInfo.Checklist_Attachment;
				var og = this.__orgNamespace;
				var isAccessiable = true;
				var fieldArray = [og + '__SM_Internal_Question_ID__c', og + '__SM_Attachment_ID__c', og + '__SM_Attachment_Name__c', og + '__SM_Checklist__c'];
				for (var index = 0; index < fieldArray.length; index++) {
					var df = attachObjectDescribe[fieldArray[index]];
					if(!df || (df && !df.accessible)){
						isAccessiable = false;
						break;
					} 
				}
				return isAccessiable;
			}
			return false;
		},

		__getObjectHashMapFromArray :function(relatedRecords){
			var attachmentMap = {};
			if(relatedRecords && relatedRecords.length > 0){
				var relatedRecordslength = relatedRecords.length;
				for (var index = 0; index < relatedRecordslength; index++) {
					var records = relatedRecords[index];
					attachmentMap[records.headerRecordId] = records.records;
				}
			}
			return attachmentMap;
		},

		__evaluateBusinessRule : function(){
			var mataData = this.__metadata;
			var data = this.__data;
			var count = data.DocumentData.length;
			 for (var index = 0; index < count; index++) {
    	        var records = data.DocumentData[index]["Records"];
    	        var SpecialFields = data.DocumentData[index]["SpecialFields"];
    	        var key = data.DocumentData[index]["Key"];
    	        if (key != undefined && key.indexOf("Checklist") >= 0) {
    	        	var recordLength = records.length;
					var processedData = [];
					for (var dataIndex = 0; dataIndex < recordLength; dataIndex++) {
						var record = records[dataIndex];
						var rules = this.getRuleFormId(mataData, record[SVMX.OrgNamespace + "__ChecklistProcessID__c"]);
						if(rules){
							var objectName = SVMX.OrgNamespace + "__Checklist__c";
							var fields ={};
							fields[objectName] =this.getField(record);
							var values = SVMX.toObject(record[SVMX.OrgNamespace + "__ChecklistJSON__c"]);
							//need to exclude if field value is not there
							var fieldValue = this.addingNullForSkipSection(values, rules);
							values.attributes = {'type':SVMX.OrgNamespace +'__Checklist__c','url':""};
							var businessRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.BusinessRuleValidator");
							var excuteRule = businessRuleValidator.evaluateEntryCriteriaBusinessRules({
								rules: rules,
								fieldValueData: fieldValue,
								fields: fields,
								data: fieldValue
							});
							if(excuteRule && excuteRule.errors && excuteRule.errors.length > 0){
								processedData.push(record);
							}
						} else {
							processedData.push(record);
						}
					}
					data.DocumentData[index]["Records"] = processedData;

    	        }
			}	
		},

		addingNullForSkipSection:function(checklistAns, businessRules){
			var header = businessRules.header;
			var updatedValue = {};
			if(header){
				var rules = header.rules;
				var rulesLength = rules.length;
				for (var index = 0; index < rulesLength; index++) {
					var rule = rules[index];
					var ruleInfo = rule.ruleInfo;
					if(ruleInfo){
						var bizRuleDetails = ruleInfo.bizRuleDetails;
						if(bizRuleDetails){
							var bizRuleDetailsLength = bizRuleDetails.length;
							for (var bIndex = 0; bIndex < rulesLength; bIndex++) {
								var ruleDetail = bizRuleDetails[bIndex];
								var fieldName = ruleDetail[SVMX.OrgNamespace + '__Field_Name__c'];
								if(!checklistAns.hasOwnProperty(fieldName)){
									updatedValue[fieldName] = null;
								} else {
									updatedValue[fieldName] = checklistAns[fieldName];
								}
							}
						}
					}
				}
			}
			return updatedValue;
		},

		getRuleFormId: function(mataData, processId){
			var listOftheRules = mataData.outputDocConfigurationObject.lstSelectedChecklistProcess;
			var listOftheRulesLength = listOftheRules.length;
			var recordRule;
			for (var index = 0; index < listOftheRulesLength; index++) {
				var rule = listOftheRules[index];
				if(rule.checklistProcessSFId === processId){
						if(rule.businessRules && rule.businessRules.ruleInfo && rule.businessRules.ruleInfo.bizRule && rule.businessRules.ruleInfo.bizRuleDetails){
							recordRule = this.getBusinessRule(rule.businessRules);
						}
					break;
				}
			}
			return recordRule;
		},

		getBusinessRule : function(processRule){
			var rule = {"aliasName":null, "message":null, "sequence":null, "ruleInfo":null};
			rule.ruleInfo = processRule.ruleInfo;
			rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Message_Type__c"] =  "Error";
			rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Advance_Expression__c"] = this.getAdvanceExpression(processRule.ruleInfo.bizRuleDetails);
			var rules = [];
			rules.push(rule);
			var businessRule = {};
			businessRule.header = {"key":null, "rules":rules};
			return businessRule;
		},

		getAdvanceExpression : function(bizRuleDetails){
			if(bizRuleDetails && bizRuleDetails.length > 1){
				var bizRuleDetailsLength = bizRuleDetails.length;
				var expression = "1";
				for (var exIndex = 0 ; exIndex < bizRuleDetailsLength; exIndex++) {
					var expIndex = exIndex+1;
					if(exIndex > 0){
						expression = expression + " OR " + expIndex;
					}
				}
				return "(" + expression + ")";
			}
			return null;
		},

		getField : function(record){
			var fields = {};
			if(record){
				if (record[SVMX.OrgNamespace + "__ChecklistJSON__c"]) {
                    var questionIds = Object.keys(SVMX.toObject(record[SVMX.OrgNamespace + "__ChecklistJSON__c"]));
                    var questionIdsLength = questionIds.length;
                    for (var questionIdsIndex = 0; questionIdsIndex < questionIdsLength; questionIdsIndex++) {
                    	fields[questionIds[questionIdsIndex]] = 'question';
                    }
                }
			}
			return fields;
		},


		__getObjectDescribeInfo : function(){
			this.__uniqueObjects = {};
			//parse through metadata
			this.__processMetaDataCollection();

			//create events for all the objects
			this.__parseForImageIds();
			var describeList = [];
			var intCount = 0;
			for(var i in this.__uniqueObjects){
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
						"SFMOPDOCDELIVERY.DESCRIBE_OBJECT", this, {request : {objectName : this.__uniqueObjects[i]}});
				describeList[intCount] = evt;
				intCount++;
			}
			if(intCount > 0){
				var currentApp = this.getEventBus();
				var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", currentApp, describeList);
				ec.triggerAll(this.onDescribeObjectsComplete, this);
			//invoke all
			}
			else{
				//then process the template
				this.__processTemplate();
			}

		},

		onDescribeObjectsComplete : function(evtCol){
			this.__aliasDescribeInfo = {};
			this.__objectLabel = "";
			//add all labels to the context
			var items = evtCol.items(), size = items.length, i;
			var objMetadataMap = {};
			var objType = "";
			if(this.__sourceRecord !== undefined && this.__sourceRecord !== null &&
					this.__sourceRecord.attributes !== undefined && this.__sourceRecord.attributes !== null
					&& this.__sourceRecord.attributes.type !== undefined && this.__sourceRecord.attributes.type !== null) {
				objType = this.__sourceRecord.attributes.type;
			}

			//process and assign the fields to object
			for(i = 0; i < size; i++){
				var item = items[i], objectName = item.getEventObj().data.request.objectName;
				var objMetadataFields = item.response.fields;
				objMetadataMap[objectName] = this.__processObjectDescribe(objMetadataFields);
				if(objectName === objType) {
					this.__objectLabel = item.response.label;
				}
			}

			//loop through all alias information and assign reference fields
			var depthCount = this.__depthCount;
			for(var alias in this.__aliasObjectName){
				var objName = this.__aliasObjectName[alias];
				if (objMetadataMap[objName]) {
					var context = {};
					context[alias] = this.__processRefFieldsObjectDescribe(objName,objMetadataMap,depthCount);
					this.__aliasDescribeInfo[alias] = context[alias];
					this.__jsee.addContext(context, "$M");
				}
			}
			//then process the template
			this.__processTemplate();
		},

		__processRefFieldsObjectDescribe : function(objName,objMetadataMap, depthCount){
			var objMetadata = objMetadataMap[objName];
			for(var name in objMetadata){
				if(((objMetadata[name].dataType && objMetadata[name].dataType === "reference") ||
						(objMetadata[name].type && objMetadata[name].type === "reference")) &&
							objMetadata[name].referenceTo && objMetadataMap[objMetadata[name].referenceTo]){
					if(depthCount > 0){
						this.__processRefFieldsObjectDescribe(objMetadata[name].referenceTo, objMetadataMap, depthCount - 1);
					}
					this.__assignFields(objMetadata[name], objMetadataMap[objMetadata[name].referenceTo]);
				}
			}
			return objMetadata;
		},

		__assignFields : function(refFieldInfo, objMetadata){

			var refField = refFieldInfo;
			for(var field in objMetadata){
				refField[field] = objMetadata[field];
			}
			return refField;
		},

		__processObjectDescribe : function(objectFields){

			var objectMetadata = {};
			for(var i in objectFields){
				objectMetadata[objectFields[i].name] = objectFields[i];
			}
			return objectMetadata;

		},

		__processChecklist : function() {
			if(this.__isCheckListProcess) {
				if(this.__metadata.outputDocConfigurationObject && this.__metadata.outputDocConfigurationObject.processOutputDoc){
					this.__jsee.setProperty("includeSkippedSections",this.__metadata.outputDocConfigurationObject.processOutputDoc[this.__orgNamespace + "__SM_Include_Skipped_Sections__c"]);
				}
				this.__makeAttachmentProperty();
				this.__evaluateBusinessRule();	
			}
		},


		__processTemplate : function(){

			this.__processChecklist();
			this.__processDataCollection();
			this.__processReferenceData();
			this.__onDataFetchComplete();
		},



		getEventBus : function(){
			//return SVMX.getCurrentApplication();
			return this.__eventBus;
		},

		__onDataFetchComplete : function(){

			// process svmx-data bound attributes
			var nodesToProcess = $("[svmx-data]", $(this.__rootNode)), node;
			var i = 0, l = nodesToProcess.length;
			for (i = 0; i < l; i++) {
				node = nodesToProcess[i];
				this.__nodeProcessor.process(
					{engine : this, node : node, jsee : this.__jsee, pendingNodeItems : this.__pendingNodeItems});
			}
			// end svmx-data processing
			//debugger;
			// inline expression processing
			var allInlineNodeTypes = [	{type : "div", 		name: "ILDIV"},
										{type : "strong", 	name: "ILSTRONG"},
										{type : "u", 		name: "ILU"},
										{type : "i", 		name: "ILI"},
										{type : "p", 		name: "ILP"},
										{type : "pre", 		name: "ILPRE"},
										{type : "h1", 		name: "ILH"},
										{type : "h2", 		name: "ILH"},
										{type : "h3", 		name: "ILH"},
										{type : "h4", 		name: "ILH"},
										{type : "h5", 		name: "ILH"},
										{type : "h6", 		name: "ILH"},
										{type : "style", 	name: "ILS"},
										{type : "span", 	name: "ILSP"},
										{type : "em", 		name: "ILEM"},
										{type : "strike", 	name: "ILSTRIKE"},
										{type : "sub", 		name: "ILSUB"},
										{type : "sup", 		name: "ILSUP"},
										{type : "ol ", 		name: "ILOL"},
										{type : "li", 		name: "ILLI"},
										{type : "ul", 		name: "ILUL"},
										{type : "b", 		name: "ILB"},
										{type : "td", 		name: "ILTD"},
										{type : "th", 		name: "ILTH"}], j, k = allInlineNodeTypes.length;
			for(j = 0; j < k; j++){
				nodesToProcess = $(allInlineNodeTypes[j].type, $(this.__rootNode)); l = nodesToProcess.length;

				for(i = 0; i < l; i++){
					node = nodesToProcess[i];
					this.__nodeProcessor.process(
						{engine : this, node : node, jsee : this.__jsee, name : allInlineNodeTypes[j].name});
				}
			}
			// end inline expression processing
			//if there are mandatory signatures then stay in HTML view(stop processing here)
			//Revised: Show HTML on Click of Finalize draft then generate the report pdf

			$("#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode)).show();
			this.__spinner.stop();

			if(SVMX.getClient().getApplicationParameter('use_jsr') !== true && this.__signaturesPending.isPending()){
				if (document.getElementById("svmx_draft")) {
					document.getElementById("svmx_draft").disabled = true; 
					document.getElementById("svmx_draft").style.opacity = 0.3;
				}
				
				if (document.getElementById("svmx_finalize")) {
					document.getElementById("svmx_finalize").disabled = true; 
					document.getElementById("svmx_finalize").style.opacity = 0.3;
				}
			} else {
				if(document.getElementById("svmx_draft")) {
					document.getElementById("svmx_draft").disabled = false; 
					document.getElementById("svmx_draft").style.opacity = 1.0;
				}

				if(document.getElementById("svmx_finalize")) {
					document.getElementById("svmx_finalize").disabled = false; 
					document.getElementById("svmx_finalize").style.opacity = 1.0;
				}
			}
			if (this.onEngineRendered) {
				//TODO: Sum14SP sort out proper displayObj
				//TODO: Sum14SP sort out Process name, don't use Id.
				var nameField = this.__sourceRecord._fields.getNameField().name;
				var displayObj = this.__objectLabel;
				//var titleProcessName = this.__sourceRecord[nameField] + ": &nbsp;&nbsp;" + this.__processId;
				var titleProcessName = this.__processName;
				//Display Object
				this.onEngineRendered.handler.apply(
			         this.onEngineRendered.context,
				    [displayObj, titleProcessName]
			    );
			}
		},

		getRoot : function(){
			return this.__rootNode;
		},

		__checkForPendingNodeItems : function(){
			var me = this;
			if(this.__pendingNodeItems.isPending()){
				setTimeout(function(){
					me.__checkForPendingNodeItems();
				},100)
			}else{
				var outputString = $( "#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode)).html();
				outputString = outputString.replace(this.__processedStyleNodeValue,"");
				if(this.__processedStyleNodeValue !== null &&
				this.__processedStyleNodeValue !== undefined &&
				this.__processedStyleNodeValue.length > 0){
					outputString = this.__processedStyleNodeValue + outputString;
				}
				//trigger submit document
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
							"SFMOPDOCDELIVERY.SUBMIT_DOCUMENT", me, {request : { context : me, document : outputString }});

				me.getEventBus().triggerEvent(evt);
			}
		},

		__onGetUserInfoComplete : function(userInfo){

			this.__jsee.setProperty(CONSTANTS.TODAY, userInfo.Today);
			this.__jsee.setProperty(CONSTANTS.TOMORROW, userInfo.Tomorrow);
			this.__jsee.setProperty(CONSTANTS.YESTERDAY, userInfo.Yesterday);
			this.__jsee.setProperty(CONSTANTS.NOW, userInfo.Now);
			this.__jsee.setProperty(CONSTANTS.USERNAME, userInfo.UserName);
			this.__jsee.setProperty(CONSTANTS.ADDRESS, userInfo.Address);
			this.__jsee.setProperty(CONSTANTS.LOCALE, userInfo.Locale);
			this.__timeFormat = userInfo.TimeFormat;
			this.__dateFormat = userInfo.DateFormat;
			this.__jsee.setProperty('userTimezoneOffset', userInfo.TimezoneOffset);
			com.servicemax.client.lib.datetimeutils.DatetimeUtil.setAmPmText(userInfo.amText, userInfo.pmText);

		},

		__onGetTemplateComplete : function(template){
			if(this.__allowDraft != null && this.__allowDraft === true){
				this.__createDraftButton();
			}
			else{
				this.__createFinalizeButton();
			}

			var metadata = this.__metadata.AllObjectInfo;
			var i, count = metadata.length;
			var alias;
			var headerClass = 'classic-root-opdoc';
			if(this.__isSalesForceIsInLightning){
				headerClass = 'lightning-root-opdoc';
			}
			for (i = 0; i < count; i++) {
				if( metadata[i][this.__orgNamespace + "__Type__c"] === 'Detail_Object' && metadata[i][this.__orgNamespace + "__Object_Name__c"] === (this.__orgNamespace + "__Checklist__c") ) {
					alias = metadata[i][this.__orgNamespace + "__Alias__c"];
				}
			}

			// SER-3858 Output document support for checklist.
			template.Template = template.Template.replace('{{$F.CHECKLIST()}}','<div class="part-details"><table border="0" cellpadding="0" cellspacing="0" style="width: 100%" svmx-data="{{$D.' + alias + '}}"><thead><tr><th class="theader" svmx-data="{{$F.CHECKLIST($D.' + alias + '.' + this.__orgNamespace + '__ChecklistJSON__c,$D.' + alias + '.' + this.__orgNamespace +'__ChecklistMetaJSON__c,$D.' + alias + '.Id)}}">	&nbsp;</th></tr></thead></table></div>' );

			this.styleNodeValue = this.__parseforStyle(template.Template);
			var cssClassName = '';
			if(this.__isLightning){
				if(this.__isSalesForceIsInLightning){
					cssClassName = 'opdoc-document-page-container';
				}
			} else{
				cssClassName = 'document-page-container';
			}
			$(this.__rootNode).append("<div class='" + cssClassName + "'><div style='border-radius:5px; margin-top: 5px;padding: 5px' id='" + CONSTANTS.DOCUMENT_PAGE + "'></div></div>");

            $(this.__rootNode).addClass(headerClass);
			document.getElementById($(this.__rootNode)[0].id).style.overflow = "auto";
			$("#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode)).append(template.Template);
			$("#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode)).hide();

		},

		__includeSpinner : function(){
			var opts = {
			  lines: 17, // The number of lines to draw
			  length: 40, // The length of each line
			  width: 10, // The line thickness
			  radius: 59, // The radius of the inner circle
			  corners: 1, // Corner roundness (0..1)
			  rotate: 85, // The rotation offset
			  direction: 1, // 1: clockwise, -1: counterclockwise
			  color: '#da5e28', // #rgb or #rrggbb
			  speed: 2.2, // Rounds per second
			  trail: 60, // Afterglow percentage
			  shadow: false, // Whether to render a shadow
			  hwaccel: false, // Whether to use hardware acceleration
			  className: 'spinner', // The CSS class to assign to the spinner
			  zIndex: 2e9, // The z-index (defaults to 2000000000)
			  top: 'auto', // Top position relative to parent in px
			  left: 'auto' // Left position relative to parent in px
			};
			if(this.__isLightning){
				opts.className = 'spinner-lightning';
				opts.line = 0;
				opts.length = 0;
				opts.radius = 0;
				opts.speed = 0;
				opts.top = -10;
				opts.left = -10;
				$(this.__rootNode).append("<div id='" + CONSTANTS.DOCUMENT_SPINNER + "' class='spinner-lightning-container'></div>");
			} else {
				$(this.__rootNode).append("<div style='position:fixed;top:50%;left:50%' id='" + CONSTANTS.DOCUMENT_SPINNER + "'></div>");
			}
			var spinnerTarget = $('#' + CONSTANTS.DOCUMENT_SPINNER, $(this.__rootNode))[0];
			this.__spinner = new Spinner(opts).spin(spinnerTarget);
		},

		handleFinalizeButtonClick : function(){
			if(document.getElementById("svmx_finalize")){
				document.getElementById("svmx_finalize").disabled = true; // SFD-635
				document.getElementById("svmx_finalize").style.opacity = 0.3;
			}
			if(this.removeSignatureButtons)
			{
				this.removeSignatureButtons.handler.apply(
						 this.removeSignatureButtons.context
				);
			}else{
				var docPageNode = $("#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode));
				var buttons = $(docPageNode).find("button");
				if(buttons && buttons.length > 0){
					for(var i = 0;i < buttons.length; i++){
						var isSignatureButton = $(buttons[0]).attr("signature-name") != undefined ? true : false;
						if(isSignatureButton === true){
							$(buttons[i]).remove();
						}
					}
				}
			}

			var outputString = $( "#" + CONSTANTS.DOCUMENT_PAGE, $(this.__rootNode)).html();
			outputString = outputString.replace(this.__processedStyleNodeValue,"");
			if(this.__processedStyleNodeValue !== null &&
			this.__processedStyleNodeValue !== undefined &&
			this.__processedStyleNodeValue.length > 0){
				outputString = this.__processedStyleNodeValue + outputString;
			}
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
				"SFMOPDOCDELIVERY.FINALIZE", this,{
					request : {
						processId 		 : this.__processId,
						recordId 		 : this.__recordId,
						htmlContent		 : outputString,
						sourceRecord	 : this.__sourceRecord,
						requestClose     : this.__requestClose
					}
				});

			this.getEventBus().triggerEvent(evt);
		},

		__createFinalizeButton : function(){
			var me = this;
			var buttonTitle = this.__getTagValue("SFM004_TAG006");
			var cancelbtnTitle = this.__getTagValue("SFM004_TAG013");
			if(buttonTitle == null){
				buttonTitle = CONSTANTS.FINALIZE;
			}

			if(cancelbtnTitle == null){
				cancelbtnTitle = CONSTANTS.CANCEL;
			}

			var finalizeBtn = "<input style='background:#f16138; -moz-border-radius:3px; -webkit-border-radius:3px; border-radius:3px; font: normal 13px tahoma,arial,verdana,sans-serif; border: 1px solid #db3202; color:#FFFFFF; font-weight:bold; padding:3px 15px; cursor:pointer; width: 20%; height: 50px' type='button' id='svmx_finalize' value='"+ buttonTitle +"'>";
			var cancelBtn = "<input style='background:#f16138; -moz-border-radius:3px; -webkit-border-radius:3px; border-radius:3px; font: normal 13px tahoma,arial,verdana,sans-serif; border: 1px solid #db3202; color:#FFFFFF; font-weight:bold; padding:3px 15px; cursor:pointer; width: 20%; height: 50px' type='button' id='svmx_finalize' value='"+ cancelbtnTitle +"'>";
			$(this.__rootNode).append("<div style='background:#a4d0e7; -moz-border-radius:5px; -webkit-border-radius:5px; border-radius:5px; border: 1px solid #72b3d5;padding: 5px' id='" + CONSTANTS.FINALIZE_DIV + "'></div>");
			$("#" + CONSTANTS.FINALIZE_DIV, $(this.__rootNode)).append(finalizeBtn);
			const useJsr = SVMX.getClient().getApplicationParameter('svmx-sfm-sal-model-use-jsr');
			if(useJsr && useJsr === true){ //Cancel button is for SFD only.
				$("#" + CONSTANTS.FINALIZE_DIV, $(this.__rootNode)).append(cancelBtn);
			}
			$('#' + 'svmx_finalize', $(this.__rootNode) ).on("click", SVMX.proxy(this, this.handleFinalizeButtonClick));
			if(document.getElementById("svmx_finalize")){
				document.getElementById("svmx_finalize").disabled = true; // SFD-635
				document.getElementById("svmx_finalize").style.opacity = 0.3;
			}
		},

		__onCaptureSignature : function(data){
			var node = $("#" + data.uniqueName, $(this.__rootNode));
			if(node != undefined && node && data.path != undefined && data.path.length > 0){
				var imgNode = node.find("img");
				if(imgNode){
					imgNode.remove();
				}
				var imageName = "";
											var url = data.path;
											var segements = url.split("/");
											imageName = segements[segements.length - 1];

				if(this.addReplaceCapturedSignature)
				{
					this.addReplaceCapturedSignature.handler.apply(
							 this.addReplaceCapturedSignature.context,
							 [data, imageName, node]
					);
				}else{
					node.prepend("<img style='width:" + data.width + "; height:" + data.height + ";' svmx-data='"+ imageName +"' src='" + data.path + "'/>");
				}

				this.__signaturesPending.removeItem(data.uniqueName);
			}
		},

		__createDraftButton : function(){
			var me = this;
			var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
			var handleDraftButtonClick = function(){
				if(document.getElementById("svmx_draft")){
					document.getElementById("svmx_draft").disabled = true; // SFD-329
					document.getElementById("svmx_draft").style.opacity = 0.3;
				}
				var retVal = true;
				if(me.__signaturesPending.isPending()){
					if(me.__settings["SET001"] !== undefined && me.__settings["SET001"] === "Allow"){
						retVal = true;
					}else if(me.__settings["SET001"] !== undefined && me.__settings["SET001"] === "Warn"){
						retVal = platformSpecifics.confirm(me.__getTagValue("SFM004_TAG007"));
					}else if(me.__settings["SET001"] !== undefined && me.__settings["SET001"] === "Disallow"){
						platformSpecifics.alert(me.__getTagValue("SFM004_TAG008"));
						retVal = false;
					}
				}
				if(retVal == true){
					me.__checkForPendingNodeItems();
				}
				else {
					if(document.getElementById("svmx_draft")){
						document.getElementById("svmx_draft").disabled = false; // SFD-329
						document.getElementById("svmx_draft").style.opacity = 1.0;
					}
				}

			}

			var buttonTitle = this.__getTagValue("SFM004_TAG006");
			if(buttonTitle == null){
				buttonTitle = CONSTANTS.DRAFT;
			}

			var draftBtn = "<input style='background:#f16138; -moz-border-radius:3px; -webkit-border-radius:3px; border-radius:3px; font: normal 13px tahoma,arial,verdana,sans-serif; border: 1px solid #db3202; color:#FFFFFF; font-weight:bold; padding:3px 15px; cursor:pointer' type='button' id='svmx_draft' value='"+ buttonTitle +"'>";
			if(this.__isLightning){
				draftBtn = this.__makeLightningComponents();
			} else {
				//hide the Object title
				$(this.__rootNode).append("<div style='background:#a4d0e7; -moz-border-radius:5px; -webkit-border-radius:5px; border-radius:5px; border: 1px solid #72b3d5;padding: 5px' id='" + CONSTANTS.DRAFT_DIV + "'></div>");
			}

			//finalize button configuration for genrating the PDF.
			$("#" + CONSTANTS.DRAFT_DIV, $(this.__rootNode)).append(draftBtn);
			$('#' + 'svmx_draft', $(this.__rootNode) ).on("click", SVMX.proxy(this, handleDraftButtonClick));

			if(document.getElementById("svmx_draft")){
				document.getElementById("svmx_draft").disabled = true; // SFD-574
				document.getElementById("svmx_draft").style.opacity = 0.3;
			}
		},

		__makeLightningComponents: function(){
			var cancelbtnTitle = this.__getTagValue("SFM004_TAG013");
			if(cancelbtnTitle == null){
				cancelbtnTitle = CONSTANTS.CANCEL;
			}

			var saveBtnTitle = this.__getTagValue("SFM004_TAG014");
			if(saveBtnTitle == null){
				saveBtnTitle = CONSTANTS.SAVE;
			}

			var handleCancelButtonClick = function(){
				var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
				platformSpecifics.navigateBack(this.returnUrl);
			};

			//cancel button configuration for going back to the record.
			$(this.__rootNode).append("<div class='opdoc-header-container' id='" + CONSTANTS.DRAFT_DIV + "'></div>");
			var headerTitle = "<div class='opdoc-header-title' id='" + CONSTANTS.OBJECT_HEADER + "'></div>";
			$("#" + CONSTANTS.DRAFT_DIV, $(this.__rootNode)).append(headerTitle);
			var imageURL = SVMX.getClient().getApplicationParameter('objectIconURL');
			var imageDivWidth = 10;
			var colourCode = SVMX.getClient().getApplicationParameter('colorCodeForIcon');
			if(imageURL && imageURL.length > 0){
				imageDivWidth = 42;
			}
			var imageIcon = '<img src="' + imageURL + '" width="' + (imageDivWidth - 10) +'" height="' + (imageDivWidth - 10) + '" style="margin: 0 10px 10px 0; background:#' + colourCode +'">';
			var objectLabel = "<label >" + SVMX.getClient().getApplicationParameter('objectLabel') + "</label>";
			var recordName =  "<label >" + SVMX.getClient().getApplicationParameter('recordName') + "</label>";
			var titleContainer = '<table width="100%" border="0" cellpadding="0" cellspacing="0" style="table-layout:fixed">';
			titleContainer += '<tr><td rowspan="2" width="' + imageDivWidth + '" style="word-break:break-word;word-wrap:break-word">';
			titleContainer += imageIcon;
			titleContainer += '</td><td style="word-break:break-word;word-wrap:break-word;"><span>';
			titleContainer += objectLabel;
			titleContainer += '</span></td></tr><tr><td width="50%" style="word-break:break-word;word-wrap:break-word;"><h1>';
			titleContainer += recordName;
			titleContainer += '</h1></td></tr></table>';
			$("#" + CONSTANTS.OBJECT_HEADER, $(this.__rootNode)).append(titleContainer);
			//$("#" + CONSTANTS.OBJECT_HEADER, $(this.__rootNode)).append(headerLabel);
			var cancelBtn = "<input style='' type='button' id='svmx_cancelBTN' class='opdoc-btn' value='"+ cancelbtnTitle +"'>";
			$("#" + CONSTANTS.DRAFT_DIV, $(this.__rootNode)).append(cancelBtn);
			$('#' + 'svmx_cancelBTN', $(this.__rootNode) ).on("click", SVMX.proxy(this, handleCancelButtonClick));
			return "<input style='margin-left: 10px' type='button' id='svmx_draft' class='opdoc-btn opdoc-btn-brand' value='"+ saveBtnTitle +"'>";
		},

		__getTagValue : function(tagKey){
			var tagValue = null;
			if(this.__displayTags != null && this.__displayTags[tagKey] !== undefined
				&& this.__displayTags[tagKey] !== null){
					tagValue = this.__displayTags[tagKey];
				}
			return tagValue;
		},

		__parseforStyle : function(template){
			var startIndex, endIndex;
			var ret = "";
			if(!template) return ret;

			startIndex = template.indexOf("<style");
			endIndex = template.indexOf("</style>");

			if(startIndex != -1 && endIndex != -1){
				ret = template.substring(startIndex, endIndex);
			}
			if(ret !== undefined && ret !== null && ret.length > 0){
				ret = ret + "</style>";
			}
			return ret;
		},

		onSubmitDocumentComplete : function(document){

			var docId = document.DocumentId;
			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
						"SFMOPDOCDELIVERY.CREATE_PDF", this,
						{request : { context : this, returnUrl : this.returnUrl, documentId : docId, recordId : SVMX.getUrlParameter("SVMX_recordId"), processId: SVMX.getUrlParameter("SVMX_processId")}});

			this.getEventBus().triggerEvent(evt);
		},

		onCreatePDFComplete : function(pdf){

			var evt = SVMX.create("com.servicemax.client.lib.api.Event", "SFMOPDOCDELIVERY.TARGET_UPDATES", this, {
				request: {
					context : this,
					processId: SVMX.getUrlParameter("SVMX_processId"),
					recordId: SVMX.getUrlParameter("SVMX_recordId"),
					pdf: pdf
				}
			});
			this.getEventBus().triggerEvent(evt);
		},

		onTargetUpdatesComplete : function(pdf){

			var evt = SVMX.create("com.servicemax.client.lib.api.Event",
			"SFMOPDOCDELIVERY.VIEW_DOCUMENT", this, {request : { context : this, attachmentId : pdf.PDFAttachmentId, recordId : SVMX.getUrlParameter("SVMX_recordId")}});

			this.getEventBus().triggerEvent(evt);

		},

		//processing metadata
		__processMetaDataCollection : function(){
			var metadata = this.__metadata.AllObjectInfo;
			this.__processedMetadata = {};
			this.__recsInfo = {};
			this.__aliasObjectName = {};
			var sortedArray;
			var i, count = metadata.length;

			//if checklist is there then we need to add checklist Attachment Info.
			if(this.__isCheckListExistInMata(metadata)){
				var attachmentObj = this.__orgNamespace + "__SM_Checklist_Attachment__c";
				this.__addToUniqueObjects(attachmentObj);
				this.__aliasObjectName['Checklist_Attachment'] = attachmentObj;
			}
			for (i = 0; i < count; i++) {
				sortedArray = [];
				var fields = metadata[i][this.__orgNamespace + "__Fields__c"]
				if(!fields || fields.length === 0) continue;
				sortedArray = this.__sortFieldsInformation(metadata[i][this.__orgNamespace + "__Fields__c"])
				this.__processedMetadata[metadata[i][this.__orgNamespace + "__Alias__c"]] = sortedArray;
				this.__recsInfo[metadata[i][this.__orgNamespace + "__Alias__c"]] = metadata[i][this.__orgNamespace + "__Type__c"];
				this.__aliasObjectName[metadata[i][this.__orgNamespace + "__Alias__c"]] = metadata[i][this.__orgNamespace + "__Object_Name__c"]
			}
		},

		__isCheckListExistInMata : function(metadata){
			var count = metadata.length;
			for (var i = 0; i < count; i++) {
				if( metadata[i][this.__orgNamespace + "__Type__c"] === 'Detail_Object' && metadata[i][this.__orgNamespace + "__Object_Name__c"] === (this.__orgNamespace + "__Checklist__c") ) {
					this.__isCheckListProcess = true;
					break;
				}
			}
			return this.__isCheckListProcess;
		},

		//process Image metadata
		__parseForImageIds : function(){
			this.__imageIds = {};
			var templareRec = this.__metadata.TemplateRecord;
			if(templareRec != null && templareRec){
				var imageInfo = templareRec[0][this.__orgNamespace + "__Media_Resources__c"];
				if(imageInfo != null && imageInfo.length > 0){
					var imageInfoObject = SVMX.toObject(imageInfo);
					for(i = 0; i < imageInfoObject.length ; i++){
						this.__imageIds[imageInfoObject[i]["DeveloperName"]] = imageInfoObject[i]["Id"];
					}
				}
			}
			this.__jsee.setProperty(CONSTANTS.IMAGENAMEID, this.__imageIds);

		},

		//processing the data
		__processDataCollection : function() {

			if(this.__data.DocumentData === undefined) return;
			//process the data and build the required object
			var i, count = this.__data.DocumentData.length;
			var documentData = this.__data.DocumentData;
			this.__processedData = {};
			this.__specialFieldsData = {};
			for (i = 0; i < count; i++) {
				this.__processedData[this.__data.DocumentData[i]["Key"]] = this.__data.DocumentData[i]["Records"];
				this.__specialFieldsData[this.__data.DocumentData[i]["Key"]] = this.__data.DocumentData[i]["SpecialFields"];
			}
		},

		//prcessing metadata
		__processReferenceData : function(){
			var metadata = this.__processedMetadata;
			var data = this.__processedData;
			var specData = this.__specialFieldsData;
			for(var key in metadata){

				//for the current metadata alias get the data
				var Recs = data[key];
				var RecSpecData = {};
				for(var idKey in specData[key]){
					RecSpecData[specData[key][idKey].Key] = specData[key][idKey].Value;
				}
				if (Recs !== undefined && Recs !== null) {
					var fields = metadata[key];
					var descInfo = this.__aliasDescribeInfo[key] || [];
					var i, count = fields.length;
					var j, recCount = Recs.length;
					//now loop through the fields
					for (i = 0; i < count; i++) {
						//now loop the recs
						for (j = 0; j < recCount; j++) {
							//handling reference fields
							if (fields[i][CONSTANTS.REF_OBJ_NAME_2]) {
								if(Recs[j][fields[i][CONSTANTS.RLN_NAME]] !== null && Recs[j][fields[i][CONSTANTS.RLN_NAME]][fields[i][CONSTANTS.RLN_NAME_2]] !== null){

									//process each metadata field that have the refernce update the value to actual field
									Recs[j][fields[i][CONSTANTS.RLN_NAME]][fields[i][CONSTANTS.REF_FLD_NAME]]
																= Recs[j][fields[i][CONSTANTS.RLN_NAME]][fields[i][CONSTANTS.RLN_NAME_2]][fields[i][CONSTANTS.REF_FLD_NAME_2]];

								}
							}

							if (fields[i][CONSTANTS.REF_OBJ_NAME]) {

								//for second level picklist
								if((fields[i][CONSTANTS.REF_FLD_TYP] === "picklist" || fields[i][CONSTANTS.REF_FLD_TYP] === "multipicklist") && Recs[j][fields[i][CONSTANTS.RLN_NAME]] !== null){
									Recs[j][fields[i][CONSTANTS.RLN_NAME]][fields[i][CONSTANTS.REF_FLD_NAME]] = this.__processPicklistValues(this.__aliasDescribeInfo[key][fields[i][CONSTANTS.FLD_NAME]], fields[i][CONSTANTS.REF_FLD_NAME], Recs[j][fields[i][CONSTANTS.RLN_NAME]], fields[i][CONSTANTS.REF_FLD_TYP]);
								}

								var idValue = '';
								if(Recs[j][fields[i][CONSTANTS.FLD_NAME]] && Recs[j][fields[i][CONSTANTS.FLD_NAME]].Id){
									idValue = Recs[j][fields[i][CONSTANTS.FLD_NAME]].Id;
								}
								else{
									idValue = Recs[j][fields[i][CONSTANTS.FLD_NAME]];
								}
								Recs[j][fields[i][CONSTANTS.FLD_NAME]] = Recs[j][fields[i][CONSTANTS.RLN_NAME]];
								if(Recs[j][fields[i][CONSTANTS.FLD_NAME]])
									Recs[j][fields[i][CONSTANTS.FLD_NAME]].Id = idValue;



							}

							if(fields[i][CONSTANTS.FLD_TYP] === "picklist" || fields[i][CONSTANTS.FLD_TYP] === "multipicklist"){
								Recs[j][fields[i][CONSTANTS.FLD_NAME]] = this.__processPicklistValues(this.__aliasDescribeInfo[key], fields[i][CONSTANTS.FLD_NAME], Recs[j], fields[i][CONSTANTS.FLD_TYP]);
							}
						}
					}

					//now handling for special fields
					for (j = 0; j < recCount; j++) {
						Recs[j] = this.__processSpecialFields(RecSpecData, Recs[j]);
						//now process security check
						Recs[j] = this.__processFieldSecurity(Recs[j],descInfo);
						//the below statement is used in SNUMBER function
						Recs[j].aliasName = key;
					}
				}
				var context = {};
				context[key] = Recs;
				if (this.__recsInfo[key] === CONSTANTS.TYPE_HEADER) {
					context[key] = Recs[0];
				}
				this.__jsee.addContext(context, "$D");
			}

		},

		__processPicklistValues : function(descInfo, fldName, rec, type){
			// Defect 020251: Opdoc hangs
			if (!descInfo[fldName]) {
				console.warn("__processPicklistValues: Skipp field " + fldName + ", which does not exist in object description, possibly limited by security setting.")
				return;
			}
			var pickValuesObjArray = descInfo[fldName].picklistValues;
			var fldValue = (rec && rec[fldName] ? rec[fldName] : '');
			var traslatedKeyValue = {label : fldValue, value : fldValue, toString : function(){return this.value;}};//if not found.. set default to empty

			if(pickValuesObjArray !== undefined && pickValuesObjArray.length > 0)
			{
				  var multiValues = type && type === "multipicklist" ? fldValue.split(";") : [fldValue];
				  var i = 0, iLength = multiValues.length;
				  var pickedObj = "";
				  for(i = 0; i < iLength; i++){
					  var pickValue = multiValues[i];
					  if(pickedObj.length > 0) pickedObj += "; ";
					  var pickedItem = pickValuesObjArray.filter(function(item){
							return item.value === pickValue; //"Is any pick list item matching just add to the result array"
					  });
					  pickedObj += pickedItem[0] && pickedItem[0].label ? pickedItem[0].label : pickValue;
				  }
				  traslatedKeyValue.value = fldValue;
				  traslatedKeyValue.label = fldValue;
				  if(pickedObj.length > 0)
				  {
					  traslatedKeyValue.label = pickedObj;//Shoud display translated label in the UI
				  }
			}
			//(Set as object) jsel.js has a check to access label during evaluation
			return traslatedKeyValue;
		},

		__processFieldSecurity : function(record, descInfo){
			for (var fieldName in record) {
				if (typeof record[fieldName] === 'object' && descInfo[fieldName] !== undefined
					&& descInfo[fieldName].accessible === true && fieldName !== "Id" && descInfo[fieldName].dataType === 'reference') {
					this.__processFieldSecurity(record[fieldName],descInfo[fieldName]);
				}
				else if(descInfo[fieldName] != null && descInfo[fieldName].accessible === false){
					record[fieldName] = '';
				}
				else if(descInfo[fieldName] === undefined || descInfo[fieldName] === null){
					record[fieldName] = '';
				}
			}
			return record;
		},

		__processSpecialFields : function(RecSpecData, record){
			var recId = record["Id"];
			var recData = RecSpecData[recId];
			if(!recData) return record;
			for(var i = 0; i < recData.length; i++){
				var arrFlds = recData[i].Key.split(".");
				var formattedValue = recData[i].Value;
				if (recData[i].Info && recData[i].Info === 'datetime') {
					formattedValue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(recData[i].Value,this.__dateFormat + " " + this.__timeFormat)
				}
				else if (recData[i].Info && recData[i].Info === 'date') {
					formattedValue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(recData[i].Value,this.__dateFormat)
				}
				if(arrFlds.length == 2 ){
					record[arrFlds[0]][arrFlds[1]] = formattedValue;
				}
				else{
					record[recData[i].Key] = formattedValue;
				}
			}
			return record;

		},

		getProcessId : function() {
			return this.__processId;
		},

		getRecordId : function() {
			return this.__recordId;
		},

		__sortFieldsInformation : function(fields){

			var level2 = [], level1 = [], level0 = [];
			var l2_Index = 0, l1_Index = 0, l0_Index = 0;
			var allFields = SVMX.toObject(fields);
			var metadata = allFields.Metadata;
			if (metadata.length > 0) {
				for (var index in metadata) {
					if(metadata[index][CONSTANTS.REF_OBJ_NAME_2]){
						level2[l2_Index] = metadata[index];
						this.__addToUniqueObjects(metadata[index][CONSTANTS.REF_OBJ_NAME_2]);
						this.__addToUniqueObjects(metadata[index][CONSTANTS.REF_OBJ_NAME]);
						this.__addToUniqueObjects(metadata[index][CONSTANTS.OBJ_NAME]);
						l2_Index++;
					}else if(metadata[index][CONSTANTS.REF_OBJ_NAME]) {
						level1[l1_Index] = metadata[index];
						this.__addToUniqueObjects(metadata[index][CONSTANTS.REF_OBJ_NAME]);
						this.__addToUniqueObjects(metadata[index][CONSTANTS.OBJ_NAME]);
						l1_Index++;
					}else if(metadata[index][CONSTANTS.OBJ_NAME]) {
						level0[l0_Index] = metadata[index];
						this.__addToUniqueObjects(metadata[index][CONSTANTS.OBJ_NAME]);
						l0_Index++;
					}
				}
				//combining all the arrays
			}
			return level2.concat(level1, level0);
		},
		__addToUniqueObjects : function(objName){
			if(objName != undefined && objName && objName.length > 0)
				this.__uniqueObjects[objName] = objName;
		},
		__processNode : function(node, targetAttribute){
			var result = this.__jsee.evalExpression($(node).attr(targetAttribute));
			$(node, $(this.__rootNode)).html(utils.htmlEncoding(result));
		}

	}, {});

	engine.Class("AbstractNodeProcessor", com.servicemax.client.lib.api.Object, {
		__constructor : function(){},
		/**
		 *
		 * @param {Object} params
		 * {
		 * 		jsee : expression engine,
		 * 		node : htmlelement
		 *
		 */
		process : function(params){ return null; },

		_removeControlCharacters : function(value){
			return value.replace(/[\n\r\t]/g,'');
		},

		_removeSVMXCharacters : function(value){
			return value.substring(2,value.length - 2);
		},

		format : function(str, argsArray){
			var i = 0, l = argsArray.length;
			for (var i = 0; i < l; i++) {
		        var regexp = new RegExp('\\{'+ i +'\\}', 'gi');
		        str = str.replace(regexp, argsArray[i]);
		    }

		    return str;
		},

		replaceExpressions : function(expressionData, params, handleSpecialCharacters){
			var i , items = expressionData.items, l = items.length, item, result;
			for(i = 0; i < l; i++){
				item = items[i];

				// strip of the start and end delimiters
				item = item.substring(2, item.length - 2);
				item = this._removeControlCharacters(item);
				result = params.jsee.evalExpression(item, params);
				if(handleSpecialCharacters){
					if(result === undefined || result === null || result === ''){
						result = "";
					}
				}
				items[i] = result != undefined && result != null ? result : '';
			}
			return this.format(expressionData.expression, items);
		},

		parseforExpressions : function(inlineExpression){
			var ret = {expression : inlineExpression, found : false, items : []};
			var startIndex, endIndex, expression, temp, i;

			if(!inlineExpression) return ret;

			i = 0;
			while(true){
				startIndex = inlineExpression.indexOf("{{");
				endIndex = inlineExpression.indexOf("}}");

				if(startIndex != -1 && endIndex != -1){
					expression = inlineExpression.substring(startIndex, endIndex + 2);
					temp = inlineExpression.substring(0, startIndex)
									+ "{" + i + "}";

					if(endIndex + 2 < inlineExpression.length){
						temp += inlineExpression.substring(endIndex + 2);
					}

					inlineExpression = temp;

					ret.found = true;
					ret.expression = inlineExpression;
					ret.items[i] = expression;
					i++;
				}else{
					//no more expressions
					break;
				}
			}
			return ret;
		},

		parseandreplaceExpressions : function(inlineExpression, params){

			res = this.parseforExpressions(inlineExpression);
			var processData = this.replaceExpressions(res, params);
			return processData;
		}

	}, {});

	engine.Class("NodeProcessor", com.servicemax.client.runtime.api.AbstractNamedInstance, {
		__nodeTypeToProcessor : {},
		__constructor : function(){
			this.__nodeTypeToProcessor = {};
		},

		initialize: function(name, data, params){

			var i, count = data.length;
			for (i = 0; i < count; i++) {
				var d = data[i];
				var nodeTypeMap = d.data, nodeTypeMapCount = nodeTypeMap.length, j;
				for (j = 0; j < nodeTypeMapCount; j++) {
					var mapping = nodeTypeMap[j];
					this.__nodeTypeToProcessor[mapping.nodeType] = {processor : mapping.processor, inst : null};
				}
			}
		},

		process : function(params){
			var name = params.name || $(params.node)[0].nodeName;
			var processorInfo = this.__nodeTypeToProcessor[name], processor = null, ret = false;
			if(processorInfo){
				if(!processorInfo.inst){
					var cls = SVMX.getClass(processorInfo.processor);
					var clsObj = new cls();
					processorInfo.inst = clsObj;
				}
				processor = processorInfo.inst;
			}

			if(processor){
				ret = processor.process(
					{engine : params.engine, jsee : params.jsee, node : params.node, pendingNodeItems : params.pendingNodeItems});
			}

			return ret;
		}

	}, {});

	engine.Class("DivNodeProcessor", engine.AbstractNodeProcessor, {
		__constructor : function(){ this.__base(); },
		process : function(params){

			var expression = $(params.node).attr("svmx-data");
			expression = this._removeControlCharacters(expression);
			var result = this.parseandreplaceExpressions(expression, params);
			$(params.node).html(utils.htmlEncoding(result));
			return true;
		}

	}, {});

	engine.Class("TableNodeProcessor", engine.AbstractNodeProcessor, {
		__constructor : function(){ this.__base(); },
		process : function(params){
			var expression = $(params.node).attr("svmx-data");
			expression = this._removeSVMXCharacters(expression);
			var result = params.jsee.evalExpression(expression);
			if (result != null && result.length > 0) {
				var l = result.length, i;
				var tbody = $("tbody", $(params.node));

				if(tbody.length == 0){
					$(params.node).append(document.createElement('tbody'));
				}
				tbody = $("tbody", $(params.node))[0];

				var thead = $("thead", $(params.node));

				var columns = $($(thead[0]).children()[0]).children(), colCount = columns.length, j;
				for (i = 0; i < l; i++) {
					var curRowData = result[i];
					var row = tbody.insertRow(i);
					//for supporting expressions in line items
					var key = expression.substring(3);
					this.assignContext(params.jsee, key, curRowData);

					for (j = 0; j < colCount; j++) {
						var actualCellField = $(columns[j]).attr("svmx-data");
						var cellField = this._removeSVMXCharacters(actualCellField);
						var cellData = row.insertCell(j);
						var path = cellField.split("."), pathElementCount = path.length, k;
						var value = curRowData;
						for (k = 0; k < pathElementCount; k++) {
							if (value[path[k]] && typeof(value[path[k]]) === 'object'
														&& value[path[k]].Id && pathElementCount === 1)
								value = value[path[k]].Id;
							else if(value[path[k]] !== undefined && value[path[k]] !== null)
								value = value[path[k]];
							else
								value = '';
						}
						//code to support expressions
						var isNeedToEncript = true;
						if(value.length == 0){
							var childExp = this._removeControlCharacters(actualCellField);
							value = this.parseandreplaceExpressions(childExp, params);
							isNeedToEncript = false;
						}

						try {
							if(value && typeof(value) === 'object'){
								if(value.label !== undefined && value.label !== null
										&& value.value !== undefined && value.value !== null){
									value = value.value;
								}
							}
							value = value.toString();
						}catch(e){}
						if(isNeedToEncript){
							$(cellData).html(utils.htmlEncoding(value));
						} else {
							$(cellData).html(value);
						}
						cellData.align = "center";
					}
				}
				this.assignContext(params.jsee, key, result);
			}
			return true;
		},

		assignContext : function(jsee, key, rowData){

			var context = {};
			context[key] = rowData;
			jsee.addContext(context, "$D");
		}

	}, {});

	engine.Class("ImageNodeProcessor", engine.AbstractNodeProcessor, {
		__constructor : function(){ this.__base(); },
		process : function(params){

			var expression = $(params.node).attr("svmx-data");
			expression = this._removeSVMXCharacters(expression);
			var result = params.jsee.evalExpression(expression, {node : params.node, pendingNodeItems : params.pendingNodeItems});
			return true;
		}

	}, {});

	engine.Class("TdNodeProcessor", engine.AbstractNodeProcessor, {
		__constructor : function(){ this.__base(); },
		process : function(params){

			var expression = $(params.node).attr("svmx-data");
			expression = this._removeControlCharacters(expression);
			var result = this.parseandreplaceExpressions(expression, params);
			params.node.innerText = result;
			return true;
		}

	}, {});

	engine.Class("AbstractInlineNodeProcessor", engine.AbstractNodeProcessor, {
		__constructor : function(){ this.__base(); },

		processChildNodes : function(params){
			var node = params.node, children = node.childNodes, i, l = children.length, child, inlineExpression, res;
			for(i = 0; i < l; i++){
				child = children[i];
				if(child.nodeType == 3){
					// text node
					inlineExpression = child.nodeValue;
					res = this.parseforExpressions(inlineExpression);
					var processData = this.replaceExpressions(res, params, params.handleSpecialCharacters);
					var isNodeProcessed = this.processSignatureNodes(processData, child);
					if(!isNodeProcessed)
						child.nodeValue = processData;
				}
			}
		},

		processSignatureNodes : function(data, childNode){
			var textArr = [], i, l;
			var isNodeProcessed = false;
			var spanNode = $("<span></span>");
			textArr = this.processTextWithDelimiters(data, "svmx-signature-start", "svmx-signature-end", 20, 18);

			if(textArr && textArr.length > 0){
				l = textArr.length;
				//insert before node
				$(spanNode).insertBefore(childNode);
				isNodeProcessed = true;
				for(i = 0; i < l; i++){
					var currNode = $("<span></span>").html(textArr[i]);
					$(spanNode).append(currNode);
				}
				//remove existing node
				$(childNode).remove();

			}
			return isNodeProcessed;
		},

		processTextWithDelimiters : function(text, delimiterStart, delimiterEnd,
													numOfCharSkippedStart, numOfCharSkippedEnd){
			var textData = text;
			var textArr = [];
			var startIndex, endIndex;
			while(true){
				var temp = "";
				startIndex = textData.indexOf(delimiterStart);
				endIndex = textData.indexOf(delimiterEnd);
				if(startIndex != -1 && endIndex != -1){
					textArr.push(textData.substring(0, startIndex));
					textArr.push(textData.substring(startIndex + numOfCharSkippedStart, endIndex));

					if(endIndex + numOfCharSkippedEnd < textData.length){
						temp = textData.substring(endIndex + numOfCharSkippedEnd);
					}
					textData = temp;
				}else{
					//no more signatures
					break;
				}
			}
			return textArr;
		}

	}, {});

	engine.Class("InlineDivNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineStrongNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineUnderlineNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineItalicNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineParaNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlinePreNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineHeadingNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineStyleNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){
			this.processChildNodes(params);
			return true;
		},

		processChildNodes : function(params){
			if(params.engine.styleNodeValue == null) return;

			var node = params.node, children = node.childNodes, i, l = children.length, child, inlineExpression, res;
			inlineExpression = params.engine.styleNodeValue;
			res = this.parseforExpressions(inlineExpression);
			processData = this.replaceExpressions(res, params);
			params.engine.__processedStyleNodeValue = processData;

			//Defect: 030583 - Adding a <style></style> tag at the top of an output doc duplicates it when generating it.
			//Get the style content and assign in to the child node (style child node).
			if(processData && processData.length > 0) {

				var startIndex = processData.indexOf('<style'), contentStartIndex = 0;
				var endIndex = processData.indexOf('</style>'), contentEndIndex = 0;

	            if(startIndex != -1){
	                contentStartIndex = processData.indexOf('>', startIndex) + 1;
	            }

	            if(endIndex != -1){
	                contentEndIndex = endIndex;
	            }

	            if(startIndex != -1 && endIndex != -1){
	                processData = processData.substring(contentStartIndex, contentEndIndex);
	            }
			}

			if(l > 0){
				child = children[0];
				child.nodeValue = processData;
			}else{
				node.nodeValue = processData;
			}
		}

	}, {});

	engine.Class("InlineSpanNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineEMNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineStrikeNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineSubNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineSupNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineOlNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineLiNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){
			params.handleSpecialCharacters = true;
			this.processChildNodes(params);
			return true;
		}

	}, {});

	engine.Class("InlineUlNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineBoldNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineTDNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("InlineTHNodeProcessor", engine.AbstractInlineNodeProcessor, {
		__constructor : function(){ this.__base(); },

		process : function(params){

			this.processChildNodes(params);
			return true;
		}
	}, {});

	engine.Class("PendingNodeProcessCollection",  com.servicemax.client.lib.api.Object, {
		__constructor : function(){
			this.__pendingNodeItems = {};
		},
		__pendingNodeItems : {},
		addItem : function(key, value){
			this.__pendingNodeItems[key] = value;
		},

		removeItem : function(key){
			delete this.__pendingNodeItems[key];
		},

		isPending : function(){
			for(key in this.__pendingNodeItems){
				return true;
			}
			return false;
		}
	}, {});

	engine.Class("PendingSignatures",  com.servicemax.client.lib.api.Object, {
		__constructor : function(context){
			this.__parent = context;
			this.__pendingSignatures = {};
		},
		__parent: null,
		__pendingSignatures : {},
		__finBtnName : 'svmx_finalize',
		__draBtnDiv : CONSTANTS.DRAFT_DIV,
		addItem : function(key, value){
			this.__pendingSignatures[key] = value;
			$("#" + this.__finBtnName, $(this.__parent.__rootNode)).prop("disabled","true");

			if(this.__parent.changeStyleSignature)
			{
				this.__parent.changeStyleSignature.handler.apply(
							 this.__parent.changeStyleSignature.context,
						["add", this.__finBtnName, $(this.__parent.__rootNode)]
					);
			}else{
					$("#" + this.__finBtnName, $(this.__parent.__rootNode)).css({"background":"#cecece", "border": "1px solid #b1b1b1", "color" : "#a9a9a9", "text-shadow": "-1px 0px 1px #ededed", "cursor": "default", "opacity":"1" });
			}
		},

		removeItem : function(key){
			if(this.__pendingSignatures[key]){
				delete this.__pendingSignatures[key];
			}
			if(!this.isPending()){
				$("#" + this.__finBtnName, $(this.__parent.__rootNode)).removeAttr("disabled");

				if(this.__parent.changeStyleSignature)
				{
					this.__parent.changeStyleSignature.handler.apply(
							 this.__parent.changeStyleSignature.context,
						["remove", this.__finBtnName, $(this.__parent.__rootNode)]
					);
				}else{
					$("#" + this.__finBtnName, $(this.__parent.__rootNode)).css({"background":"#f16138", "border": "1px solid #db3202", "color" : "#FFFFFF", "text-shadow": "none","opacity":"1"});
				}
			}
		},

		isPending : function(){
			for(key in this.__pendingSignatures){
				return true;
			}
			return false;
		}
	}, {});

};
})();

// end of file
