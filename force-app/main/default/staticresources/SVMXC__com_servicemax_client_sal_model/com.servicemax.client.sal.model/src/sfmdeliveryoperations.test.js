
describe("sfmdelivery.engine" ,function(){

	var engine =  {
		__page : null,
		__eventBus : null,

		getMetaModel : function() {
        	return this.__page;
    	},

    	getEventBus : function () {	
    		// this.__eventBus = SVMX.create("com.servicemax.client.sfmdelivery.impl.SFMDeliveryEngineEventBus", {});
    		// this.__eventBus.triggerEvent = function(event){
    		// 	return undefined;
    		// },
    		return this.__eventBus;
    	},

    	isFieldUpdatesEnabled : function () {
    		return false;
    	},

    	initAsync : function(options){
    		this.__eventBus = SVMX.create("com.servicemax.client.sfmdelivery.impl.SFMDeliveryEngineEventBus", {});
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
            this.__eventBus = SVMX.create("com.servicemax.client.sfmdelivery.impl.SFMDeliveryEngineEventBus", {});
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){
            	//Call other event from here.
            }, context : this, additionalParams : { eventBus : this.__eventBus }});

        }
	};
	var responseStatus = '';
	describe("#checklist default value" ,function(){
		var preOrgNamespace = SVMX.OrgNamespace;
		before(function() {
			SVMX.OrgNamespace = 'SVMXDEV';
			engine.initAsync();
			var attachmentTypeStub = sinon.stub(com.servicemax.client.sal.impl.AttachmentSoapRequest.prototype, 'callAsync').callsFake(function() {
				var data = {};
				var status = 'Success';
				var jqXhr = SVMX.toObject('{"readyState":4,"responseText":"<?xml version=\"1.0\" encoding=\"UTF-8\"?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"urn:partner.soap.sforce.com\"><soapenv:Body><createResponse><result><id>00P0G00000p6yguUAA</id><success>true</success></result></createResponse></soapenv:Body></soapenv:Envelope>","responseXML":{"location":null},"status":200,"statusText":"OK"}');
				this._callAsyncAttachmentSuccess(data, status, jqXhr);
		    });

		    var saveTargetRecord = sinon.stub(com.servicemax.client.sal.model.sfmdelivery.operations.SaveTargetAttachmentRecord.prototype, 'performAsync').callsFake(function(request, response) {
				var additionalInfo = request.additionalInfo;
				additionalInfo.eventType = 'save checklist attachment';
				var targetRecord = SVMX.create("com.servicemax.client.sfmdelivery.operationutils.SFMTargetAttachmentRecord", request, request.metadata, request.additionalInfo);
				var requestData = targetRecord.getRequest();
				responder.result('Success');
		    }); 

		    var saveTargetRecord = sinon.stub(com.servicemax.client.sal.model.impl.UploadAttachment.prototype, '__uploadChecklistAttachment').callsFake(function(response, request) {
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

				//Calling 
				var attachmentData = SVMX.create("com.servicemax.client.sal.model.sfmdelivery.operations.SaveTargetAttachmentRecord",{});
				attachmentData.performAsync(this.__data.request, this.__data.responder);
		    }); 

		    var responder = {
		    	result:function(resultData){
		    		responseStatus = resultData;
		    	}
			};

		    //AttachmentData
		    var records = SVMX.toObject('[{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000ne7MQAQ"},"Id":"a2w0G000000ne7MQAQ","SVMXDEV__SM_Checklist__c":"","SVMXDEV__SM_Question__c":"a1q0G00000NFrfvQAD","SVMXDEV__SM_Internal_Question_ID__c":"QB000438","SVMXDEV__SM_Attachment_ID__c":"","SVMXDEV__SM_Attachment_Name__c":"1503586128940__test_.rtf","SVMXDEV__SM_File_Type__c":"Document","SVMXDEV__SM_File_Size__c":6474},{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000ne7MQAQ"},"Id":"a2w0G000000ne7MQAQ","SVMXDEV__SM_Checklist__c":"a1z0G00001JTDrMQAX","SVMXDEV__SM_Question__c":"a1q0G00000NFrfvQAD","SVMXDEV__SM_Internal_Question_ID__c":"QB000438","SVMXDEV__SM_Attachment_ID__c":"00P0G00000oIXlqUAG","SVMXDEV__SM_Attachment_Name__c":"1503586128940__test_.rtf","SVMXDEV__SM_File_Type__c":"Document","SVMXDEV__SM_File_Size__c":6474},{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000ne7NQAQ"},"Id":"a2w0G000000ne7NQAQ","SVMXDEV__SM_Checklist__c":"a1z0G00001JTDrMQAX","SVMXDEV__SM_Question__c":"a1q0G00000NFrg0QAD","SVMXDEV__SM_Internal_Question_ID__c":"QB000439","SVMXDEV__SM_Attachment_ID__c":"00P0G00000oIXlvUAG","SVMXDEV__SM_Attachment_Name__c":"1503586140345_image 2.jpg","SVMXDEV__SM_File_Type__c":"Image","SVMXDEV__SM_File_Size__c":103303}]');
		    var data = {'response':{'records':records}};
		    var attachmentData = SVMX.create("com.servicemax.client.sal.model.impl.SFMAttachmentDeliveryData",data);
		    attachmentData.setAttachmentValueToPath('QB000439',{});
		    var result = '{"tagId":null,"success":true,"stringMap":[],"StringLstMap":[],"stringFieldMap":[],"sobjectMap":[],"resultIds":["a1z0G00001JTDpWQAX"],"records":[],"QuestionValidationRuleInfo":{"QuestionValidationRule":{"attributes":{"type":"SVMXDEV__ServiceMax_Processes__c"}},"questionId":null,"questionBankId":null,"lstQuestionValidationRuleDetails":[],"checklistId":null},"profileData":{"details":[{"reqtype":" ExecutionTime","name":"saveTargetInternal","description":"saveTargetInternal","endtime":"2017-08-24T08:53:59.211Z","begintime":"2017-08-24T08:53:51.799Z"}]},"msgDetails":null,"messageType":null,"messages":[],"message":null,"MapStringMap":[],"lstQuestionBank":[],"lstFieldSetWithSorting":[],"lstChecklistInfo":[],"lstChecklistBusinessProcessInfo":null,"lstBizRuleInfo":[],"logMsg":null,"fieldUpdateRuleInfoList":[],"eventType":"quick save checklist","docTemplate":null}';
		    var metadataString = '{"response":{"tagId":null,"success":true,"stringMap":[{"value1":null,"value":"CHECKLIST","key":"PROCESSTYPE","fieldsToNull":null}],"StringLstMap":[],"stringFieldMap":[],"sobjectMap":[],"resultIds":[],"records":[],"QuestionValidationRuleInfo":{"QuestionValidationRule":{"attributes":{"type":"SVMXDEV__ServiceMax_Processes__c"}},"questionId":null,"questionBankId":null,"lstQuestionValidationRuleDetails":[],"checklistId":null},"profileData":{"details":[{"reqtype":" ExecutionTime","name":"getPageLayoutInternal","description":"gets page layout data","endtime":"2017-08-16T06:51:30.215Z","begintime":"2017-08-16T06:51:29.331Z"}]},"msgDetails":null,"messageType":null,"messages":[],"message":null,"MapStringMap":[],"lstQuestionBank":[],"lstFieldSetWithSorting":[],"lstChecklistInfo":[],"lstChecklistBusinessProcessInfo":null,"lstBizRuleInfo":[],"logMsg":null,"fieldUpdateRuleInfoList":[],"eventType":null,"docTemplate":null,"sfmProcessType":"CHECKLIST"},"page":{"recordTypeList":[],"processTitle":"1SM Attachment","lstObjectMapInfo":[],"header":{"sourceRecordId":null,"sections":[{"sectionDetail":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKKUA1"},"SVMXDEV__Field_Mapping__c":null,"SVMXDEV__Show_In_iPad__c":false,"SVMXDEV__Width__c":null,"SVMXDEV__Section__r":null,"SVMXDEV__Show_In_Web__c":false,"SVMXDEV__Related_Object_Name_Field__c":null,"SVMXDEV__Context_Source_Object__c":null,"SVMXDEV__Title__c":"Checklist Section Title","SVMXDEV__IsStandard__c":false,"SVMXDEV__Sequence__c":1,"SVMXDEV__Section__c":null,"SVMXDEV__Page_Layout_Detail_Id__c":null,"SVMXDEV__Required__c":false,"SVMXDEV__Related_Object_Name__c":null,"SVMXDEV__Readonly__c":false,"SVMXDEV__Page_Layout__c":"a0Z0G00000FnpK9UAJ","SVMXDEV__Override_Related_Lookup__c":false,"SVMXDEV__Named_Search__c":null,"SVMXDEV__Named_Search__r":null,"SVMXDEV__Lookup_Query_Field__c":null,"SVMXDEV__Lookup_Context__c":null,"SVMXDEV__Field_API_Name__c":null,"SVMXDEV__Display_Row__c":null,"SVMXDEV__Display_Column__c":null,"SVMXDEV__Detail_Type__c":"Section","SVMXDEV__DataType__c":null,"Name":"0000286696","Id":"a0Y0G00000BJmKKUA1","SVMXDEV__No_Of_Columns__c":null,"SVMXDEV__Enable_Chatter__c":false,"SVMXDEV__Control_Type__c":"Standard","SVMXDEV__Maximum_Value__c":null,"SVMXDEV__Minimum_Value__c":null,"SVMXDEV__Use_For_SLA_Clock__c":false,"SVMXDEV__Question__c":null,"SVMXDEV__QuestionInfoJSON__c":null,"SVMXDEV__SM_Description__c":null,"SVMXDEV__SM_Help_URL__c":null,"SVMXDEV__SM_Checklist_Source_Field_API_Name__c":null,"SVMXDEV__ServiceMax_Processes__r":null,"SVMXDEV__Entry_Criteria__c":false},"lstSectionExitCriteria":[],"fieldsToNull":null,"fields":[{"fieldsToNull":null,"fieldEvents":[],"fieldDetail":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKMUA1"},"SVMXDEV__Field_Mapping__c":null,"SVMXDEV__Show_In_iPad__c":false,"SVMXDEV__Width__c":null,"SVMXDEV__Section__r":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKKUA1"},"SVMXDEV__No_Of_Columns__c":null},"SVMXDEV__Show_In_Web__c":false,"SVMXDEV__Related_Object_Name_Field__c":null,"SVMXDEV__Context_Source_Object__c":null,"SVMXDEV__Title__c":null,"SVMXDEV__IsStandard__c":false,"SVMXDEV__Sequence__c":1,"SVMXDEV__Section__c":"a0Y0G00000BJmKKUA1","SVMXDEV__Page_Layout_Detail_Id__c":null,"SVMXDEV__Required__c":true,"SVMXDEV__Related_Object_Name__c":null,"SVMXDEV__Readonly__c":false,"SVMXDEV__Page_Layout__c":"a0Z0G00000FnpK9UAJ","SVMXDEV__Override_Related_Lookup__c":false,"SVMXDEV__Named_Search__c":null,"SVMXDEV__Named_Search__r":null,"SVMXDEV__Lookup_Query_Field__c":null,"SVMXDEV__Lookup_Context__c":null,"SVMXDEV__Field_API_Name__c":null,"SVMXDEV__Display_Row__c":null,"SVMXDEV__Display_Column__c":null,"SVMXDEV__Detail_Type__c":"Question","SVMXDEV__DataType__c":"reference","Name":"0000286698","Id":"a0Y0G00000BJmKMUA1","SVMXDEV__No_Of_Columns__c":null,"SVMXDEV__Enable_Chatter__c":false,"SVMXDEV__Control_Type__c":"Standard","SVMXDEV__Maximum_Value__c":null,"SVMXDEV__Minimum_Value__c":null,"SVMXDEV__Use_For_SLA_Clock__c":false,"SVMXDEV__Question__c":"a1q0G00000NFsMcQAL","SVMXDEV__QuestionInfoJSON__c":"{\"questionResponses\":[{\"sequence\":1.0,\"response\":\"\",\"questionID\":\"QB000460\",\"active\":true}],\"question\":{\"ShowInSmartDoc\":true,\"shortname\":null,\"scale\":null,\"responseType\":\"Attachment\",\"questionJSON\":null,\"questionID\":\"QB000460\",\"question\":\"Question 1\",\"precision\":null,\"length\":null,\"helpURL\":null,\"descriptionRequired\":true,\"description\":null,\"captureComments\":null,\"active\":true},\"defaultChecklistRes\":null}","SVMXDEV__SM_Description__c":null,"SVMXDEV__SM_Help_URL__c":null,"SVMXDEV__SM_Checklist_Source_Field_API_Name__c":null,"SVMXDEV__ServiceMax_Processes__r":null},"bubbleinfo":{"response":{"tagId":null,"success":null,"stringMap":[],"StringLstMap":[],"stringFieldMap":[],"sobjectMap":[],"resultIds":[],"records":[],"QuestionValidationRuleInfo":{"QuestionValidationRule":{"attributes":{"type":"SVMXDEV__ServiceMax_Processes__c"}},"questionId":null,"questionBankId":null,"lstQuestionValidationRuleDetails":[],"checklistId":null},"profileData":null,"msgDetails":null,"messageType":null,"messages":[],"message":null,"MapStringMap":[],"lstQuestionBank":[],"lstFieldSetWithSorting":[],"lstChecklistInfo":[],"lstChecklistBusinessProcessInfo":null,"lstBizRuleInfo":[],"logMsg":null,"fieldUpdateRuleInfoList":[],"eventType":null,"docTemplate":null},"fieldvalue":{"value1":null,"value":null,"key":null,"fieldsToNull":null},"fieldapiname":null,"bubbleinfo":[]}}],"entryCriteriaId":null,"enableEntryCriteria":null},{"sectionDetail":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKLUA1"},"SVMXDEV__Field_Mapping__c":null,"SVMXDEV__Show_In_iPad__c":false,"SVMXDEV__Width__c":null,"SVMXDEV__Section__r":null,"SVMXDEV__Show_In_Web__c":false,"SVMXDEV__Related_Object_Name_Field__c":null,"SVMXDEV__Context_Source_Object__c":null,"SVMXDEV__Title__c":"Checklist Section Title","SVMXDEV__IsStandard__c":false,"SVMXDEV__Sequence__c":2,"SVMXDEV__Section__c":null,"SVMXDEV__Page_Layout_Detail_Id__c":null,"SVMXDEV__Required__c":false,"SVMXDEV__Related_Object_Name__c":null,"SVMXDEV__Readonly__c":false,"SVMXDEV__Page_Layout__c":"a0Z0G00000FnpK9UAJ","SVMXDEV__Override_Related_Lookup__c":false,"SVMXDEV__Named_Search__c":null,"SVMXDEV__Named_Search__r":null,"SVMXDEV__Lookup_Query_Field__c":null,"SVMXDEV__Lookup_Context__c":null,"SVMXDEV__Field_API_Name__c":null,"SVMXDEV__Display_Row__c":null,"SVMXDEV__Display_Column__c":null,"SVMXDEV__Detail_Type__c":"Section","SVMXDEV__DataType__c":null,"Name":"0000286697","Id":"a0Y0G00000BJmKLUA1","SVMXDEV__No_Of_Columns__c":null,"SVMXDEV__Enable_Chatter__c":false,"SVMXDEV__Control_Type__c":"Standard","SVMXDEV__Maximum_Value__c":null,"SVMXDEV__Minimum_Value__c":null,"SVMXDEV__Use_For_SLA_Clock__c":false,"SVMXDEV__Question__c":null,"SVMXDEV__QuestionInfoJSON__c":null,"SVMXDEV__SM_Description__c":null,"SVMXDEV__SM_Help_URL__c":null,"SVMXDEV__SM_Checklist_Source_Field_API_Name__c":null,"SVMXDEV__ServiceMax_Processes__r":null,"SVMXDEV__Entry_Criteria__c":false},"lstSectionExitCriteria":[],"fieldsToNull":null,"fields":[{"fieldsToNull":null,"fieldEvents":[],"fieldDetail":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKNUA1"},"SVMXDEV__Field_Mapping__c":null,"SVMXDEV__Show_In_iPad__c":false,"SVMXDEV__Width__c":null,"SVMXDEV__Section__r":{"attributes":{"type":"SVMXDEV__Page_Layout_Detail__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout_Detail__c/a0Y0G00000BJmKLUA1"},"SVMXDEV__No_Of_Columns__c":null},"SVMXDEV__Show_In_Web__c":false,"SVMXDEV__Related_Object_Name_Field__c":null,"SVMXDEV__Context_Source_Object__c":null,"SVMXDEV__Title__c":null,"SVMXDEV__IsStandard__c":false,"SVMXDEV__Sequence__c":1,"SVMXDEV__Section__c":"a0Y0G00000BJmKLUA1","SVMXDEV__Page_Layout_Detail_Id__c":null,"SVMXDEV__Required__c":false,"SVMXDEV__Related_Object_Name__c":null,"SVMXDEV__Readonly__c":false,"SVMXDEV__Page_Layout__c":"a0Z0G00000FnpK9UAJ","SVMXDEV__Override_Related_Lookup__c":false,"SVMXDEV__Named_Search__c":null,"SVMXDEV__Named_Search__r":null,"SVMXDEV__Lookup_Query_Field__c":null,"SVMXDEV__Lookup_Context__c":null,"SVMXDEV__Field_API_Name__c":null,"SVMXDEV__Display_Row__c":null,"SVMXDEV__Display_Column__c":null,"SVMXDEV__Detail_Type__c":"Question","SVMXDEV__DataType__c":"reference","Name":"0000286699","Id":"a0Y0G00000BJmKNUA1","SVMXDEV__No_Of_Columns__c":null,"SVMXDEV__Enable_Chatter__c":false,"SVMXDEV__Control_Type__c":"Standard","SVMXDEV__Maximum_Value__c":null,"SVMXDEV__Minimum_Value__c":null,"SVMXDEV__Use_For_SLA_Clock__c":false,"SVMXDEV__Question__c":"a1q0G00000NFsMhQAL","SVMXDEV__QuestionInfoJSON__c":"{\"questionResponses\":[{\"sequence\":1.0,\"response\":\"\",\"questionID\":\"QB000461\",\"active\":true}],\"question\":{\"ShowInSmartDoc\":true,\"shortname\":null,\"scale\":null,\"responseType\":\"Attachment\",\"questionJSON\":null,\"questionID\":\"QB000461\",\"question\":\"Question 2\",\"precision\":null,\"length\":null,\"helpURL\":null,\"descriptionRequired\":true,\"description\":null,\"captureComments\":null,\"active\":true},\"defaultChecklistRes\":null}","SVMXDEV__SM_Description__c":null,"SVMXDEV__SM_Help_URL__c":null,"SVMXDEV__SM_Checklist_Source_Field_API_Name__c":null,"SVMXDEV__ServiceMax_Processes__r":null},"bubbleinfo":{"response":{"tagId":null,"success":null,"stringMap":[],"StringLstMap":[],"stringFieldMap":[],"sobjectMap":[],"resultIds":[],"records":[],"QuestionValidationRuleInfo":{"QuestionValidationRule":{"attributes":{"type":"SVMXDEV__ServiceMax_Processes__c"}},"questionId":null,"questionBankId":null,"lstQuestionValidationRuleDetails":[],"checklistId":null},"profileData":null,"msgDetails":null,"messageType":null,"messages":[],"message":null,"MapStringMap":[],"lstQuestionBank":[],"lstFieldSetWithSorting":[],"lstChecklistInfo":[],"lstChecklistBusinessProcessInfo":null,"lstBizRuleInfo":[],"logMsg":null,"fieldUpdateRuleInfoList":[],"eventType":null,"docTemplate":null},"fieldvalue":{"value1":null,"value":null,"key":null,"fieldsToNull":null},"fieldapiname":null,"bubbleinfo":[]}}],"entryCriteriaId":null,"enableEntryCriteria":null}],"pageEvents":[],"headerLayout":{"attributes":{"type":"SVMXDEV__Page_Layout__c","url":"/services/data/v40.0/sobjects/SVMXDEV__Page_Layout__c/a0Z0G00000FnpK9UAJ"},"SVMXDEV__Type__c":"Header","SVMXDEV__Sequence__c":null,"SVMXDEV__Prompt_For_New_Event__c":false,"SVMXDEV__Enable_Attachments__c":false,"SVMXDEV__Enable_Chatter__c":false,"SVMXDEV__Show_Account_History__c":false,"SVMXDEV__Show_All_Sections_By_Default__c":false,"SVMXDEV__Show_Product_History__c":false,"SVMXDEV__Hide_Save__c":false,"SVMXDEV__Hide_Quick_Save__c":false,"SVMXDEV__Page_Layout_ID__c":"Checklist","SVMXDEV__Page_Help__c":null,"SVMXDEV__Object_Name__c":"SVMXDEV__Checklist__c","SVMXDEV__Multi_Add_Search_Object__c":null,"SVMXDEV__Multi_Add_Search_Field__c":null,"SVMXDEV__Multi_Add_Configuration__c":null,"SVMXDEV__IsStandard__c":false,"SVMXDEV__Enable_Service_Report_View__c":false,"SVMXDEV__Enable_Troubleshooting__c":false,"SVMXDEV__Enable_Service_Report_Generation__c":false,"SVMXDEV__Help_URL__c":"http://userdocs.servicemax.com:8080/ServiceMaxHelp/Summer14/en_us/svmx_redirector.htm?uid=SFM01_16","SVMXDEV__Header_Reference_Field__c":null,"SVMXDEV__Header_Page_Layout__c":null,"SVMXDEV__Action_On_Zero_Lines__c":null,"SVMXDEV__Name__c":"SM Attachment CHK","SVMXDEV__Allow_New_Lines__c":false,"SVMXDEV__Allow_Delete_Lines__c":false,"OwnerId":"005F0000007u96iIAA","Name":"0000142539","LastModifiedDate":"2017-08-16T06:48:31.000+0000","LastModifiedById":"005F0000007u96iIAA","IsDeleted":false,"Id":"a0Z0G00000FnpK9UAJ","CreatedDate":"2017-08-10T06:58:23.000+0000","CreatedById":"005F0000007u96iIAA","SVMXDEV__SM_Include_Contact__c":false,"SVMXDEV__SM_Include_Field1__c":null,"SVMXDEV__SM_Include_Field2__c":null,"SVMXDEV__SM_Include_Field3__c":null,"SVMXDEV__SM_Include_Summary__c":false,"SVMXDEV__SM_Include_Time_and_Place__c":false,"SVMXDEV__SM_Summary_Title__c":null,"SVMXDEV__SM_Title_Bar__c":null},"hdrLayoutId":"a0Z0G00000FnpK9UAJ","hdrData":null,"fieldsToNull":null,"enableAttachment":false,"buttons":[]},"fieldsToNull":null,"details":[],"businessRules":[]},"fieldsToNull":null}';
		    var metadata = {response:{sfmProcessType:'CHECKLIST'},page:{header:{hdrLayoutId:'a0Z0G00000FnpK9UAJ'}}};//SVMX.toObject(metadataString);
		    var additionalInfo = SVMX.toObject('{"sfProcessId":"a120G00000B0hrLQAR","processId":"AAA_Attachment_D","eventType":"save checklist attachment","toModelOnly":true,"targetId":"a1z0G00001JTDrMQAX","lstSobjectinfo":[],"currentIndex":0}');
		    var request = {'deliveryEngine':engine,'data':{'__attachementData':attachmentData},'additionalInfo':additionalInfo,'doSourceObjectUpdate': false, 'metadata': metadata,'sourceRecordId':'a1LF0000003CKorMAG','skipAggressiveSync':'','skipStatusMsg':''}; //request.data.__attachementData
		    var attachmentData = {'request':request, 'responder': responder, 'result': result};
			var sfmdeliveryData = SVMX.create("com.servicemax.client.sal.model.impl.UploadAttachment", attachmentData);
			sfmdeliveryData.uploadAttachments();

			
		});

		after(function() {
			SVMX.OrgNamespace = preOrgNamespace;
		});

			
		it('Status should be Success',function(done){
			var defaultValue = responseStatus;
			assert.equal(defaultValue,'Success','default value is Success');
			done();
		});


	});	
	
});