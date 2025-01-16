describe("specificChecklist.OPDoc" ,function(){
	describe("#checklist OPDoc" ,function(){
		var preOrgNamespace = SVMX.OrgNamespace;
		var numberOfSectionAfterFilterCalculation;
		var CONSTANTS = com.servicemax.client.sfmopdocdelivery.constants.Constants;
		//var PlatformSpecifics = require('com.servicemax.client.sal.model').PlatformSpecifics;
		before(function() {

			var metaData = "{\"TemplateRecord\":[],\"outputDocConfigurationObject\":{\"processOutputDoc\":{},\"lstSelectedChecklistProcess\":[{\"checklistProcessSFId\":\"a120G00000AzUyaQAF\",\"businessRules\":{\"ruleInfo\":{\"bizRuleDetails\":[{\"attributes\":{\"type\":\"SVMXDEV__ServiceMax_Config_Data__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__ServiceMax_Config_Data__c/a100G000007pGKwQAM\"},\"Id\":\"a100G000007pGKwQAM\",\"SVMXDEV__Sequence__c\":null,\"SVMXDEV__Field_Name__c\":\"QB000363\",\"SVMXDEV__Expression_Rule__c\":\"a120G00000B0K7wQAF\",\"SVMXDEV__Display_Type__c\":\"DATE\",\"SVMXDEV__Parameter_Type__c\":\"Value\",\"SVMXDEV__Operand__c\":\"07/12/2017\",\"SVMXDEV__Operator__c\":\"gt\",\"SVMXDEV__Action_Type__c\":\"Set Value\",\"SVMXDEV__Expression_Type__c\":null}],\"bizRule\":{\"attributes\":{\"type\":\"SVMXDEV__ServiceMax_Processes__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__ServiceMax_Processes__c/a120G00000B0K7wQAF\"},\"Id\":\"a120G00000B0K7wQAF\",\"SVMXDEV__Source_Object_Name__c\":\"SVMXDEV__Checklist__c\",\"SVMXDEV__Question_Bank__c\":\"a1q0G00000NFqawQAD\",\"SVMXDEV__Rule_Type__c\":\"Checklist Criteria in Output Doc\"}}}}]},\"AllObjectInfo\":[]}";
			var data = "{\"Status\":true,\"Message\":\"\",\"DocumentData\":[{\"SpecialFields\":[],\"relatedRecords\":[],\"Records\":[{\"attributes\":{\"type\":\"SVMXDEV__Service_Order__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__Service_Order__c/a1LF0000003CKorMAG\"},\"Id\":\"a1LF0000003CKorMAG\",\"Name\":\"WO-00146625\"}],\"Key\":\"Work_Order\"},[]]}";
			SVMX.OrgNamespace = 'SVMXDEV';
			var opDocEngine = SVMX.create("com.servicemax.client.sfmopdocdelivery.engine.DeliveryEngineImpl", {});
			var metaObject = SVMX.toObject(metaData);
			var dataObject = SVMX.toObject(data);
			var checklist1 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-07\",\"QB000353\":\"2017-07-06 13:22:00\",\"QB000363\":\"2017-07-06\",\"QB000364\":\"2017-07-05 18:30:00\",\"QB000365\":\"2017-07-07\",\"QB000366\":\"2017-07-06 18:30:00\",\"QB000367\":\"2017-07-05\",\"QB000368\":\"2017-07-04 18:30:00\",\"QB000369\":\"2017-07-06 13:22:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist2 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:22:00\",\"QB000363\":\"2017-07-13\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:22:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist3 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:23:00\",\"QB000363\":\"2017-07-13\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:23:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist4 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:30:00\",\"QB000363\":\"2017-07-20\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:30:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist5 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:30:00\",\"QB000363\":\"2017-07-07\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:30:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist6 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:32:00\",\"QB000363\":\"2017-07-12\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:32:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist7 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:34:00\",\"QB000363\":\"2017-07-03\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:34:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";

		    var platformSpecificsConfirmSinon = sinon.stub(com.servicemax.client.sfmopdocdelivery.model.impl.PlatformSpecifics.prototype, 'confirm').callsFake(function(message) {
		    	debugger;
		    	
				return true;	   
		    });

		    var platformSpecificsAlertSinon = sinon.stub(com.servicemax.client.sfmopdocdelivery.model.impl.PlatformSpecifics.prototype, 'alert').callsFake(function(message) {
		    	debugger;

				return true;	   
		    });

			dataObject.DocumentData[1].Records = [{SVMXDEV__ChecklistJSON__c:checklist1,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist2,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist3,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist4,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist5,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist6,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist7,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"}];
			dataObject.DocumentData[1].Key = "Checklist__Work_Order_";
			opDocEngine.__data = dataObject;
			opDocEngine.__metadata = metaObject;
			opDocEngine.__isLightning = true;
			opDocEngine.__getTagValue = function(){
				return 'test 2';
			}
			opDocEngine.__createFinalizeButton();
			opDocEngine.__createDraftButton();
			opDocEngine.__makeLightningComponents();
			opDocEngine.__evaluateBusinessRule();
			numberOfSectionAfterFilterCalculation = dataObject.DocumentData[1].Records.length
			var params = {};
			platformSpecificsConfirmSinon.restore();
			platformSpecificsAlertSinon.restore();	
		});

		after(function() {
			SVMX.OrgNamespace = preOrgNamespace;
		});

		it('Records Should filter based on configuration',function(done){
			assert.equal(numberOfSectionAfterFilterCalculation,3,'default value is not null');
			done();
		});

	});	

	describe("#Number of Attachment for this record OPDoc" ,function(){
		var preOrgNamespace = SVMX.OrgNamespace;
		var numberOfAttachments;
		before(function() {

			var metaData = "{\"TemplateRecord\":[],\"outputDocConfigurationObject\":{\"processOutputDoc\":{\"SVMXDEV__SM_Include_Skipped_Sections__c\":false},\"lstSelectedChecklistProcess\":[{\"checklistProcessSFId\":\"a120G00000AzUyaQAF\",\"businessRules\":{\"ruleInfo\":{\"bizRuleDetails\":[{\"attributes\":{\"type\":\"SVMXDEV__ServiceMax_Config_Data__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__ServiceMax_Config_Data__c/a100G000007pGKwQAM\"},\"Id\":\"a100G000007pGKwQAM\",\"SVMXDEV__Sequence__c\":null,\"SVMXDEV__Field_Name__c\":\"QB000363\",\"SVMXDEV__Expression_Rule__c\":\"a120G00000B0K7wQAF\",\"SVMXDEV__Display_Type__c\":\"DATE\",\"SVMXDEV__Parameter_Type__c\":\"Value\",\"SVMXDEV__Operand__c\":\"07/12/2017\",\"SVMXDEV__Operator__c\":\"gt\",\"SVMXDEV__Action_Type__c\":\"Set Value\",\"SVMXDEV__Expression_Type__c\":null}],\"bizRule\":{\"attributes\":{\"type\":\"SVMXDEV__ServiceMax_Processes__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__ServiceMax_Processes__c/a120G00000B0K7wQAF\"},\"Id\":\"a120G00000B0K7wQAF\",\"SVMXDEV__Source_Object_Name__c\":\"SVMXDEV__Checklist__c\",\"SVMXDEV__Question_Bank__c\":\"a1q0G00000NFqawQAD\",\"SVMXDEV__Rule_Type__c\":\"Checklist Criteria in Output Doc\"}}}}]},\"AllObjectInfo\":[]}";
			var data = "{\"Status\":true,\"Message\":\"\",\"DocumentData\":[{\"SpecialFields\":[],\"relatedRecords\":[],\"Records\":[{\"attributes\":{\"type\":\"SVMXDEV__Service_Order__c\",\"url\":\"/services/data/v40.0/sobjects/SVMXDEV__Service_Order__c/a1LF0000003CKorMAG\"},\"Id\":\"a1LF0000003CKorMAG\",\"Name\":\"WO-00146625\"}],\"Key\":\"Work_Order\"},[]]}";
			SVMX.OrgNamespace = 'SVMXDEV';
			var opDocEngine = SVMX.create("com.servicemax.client.sfmopdocdelivery.engine.DeliveryEngineImpl", {});
			opDocEngine.__orgNamespace = "SVMXDEV";
			var metaObject = SVMX.toObject(metaData);
			var dataObject = SVMX.toObject(data);
			var data = {__interceptors:null ,__de:null, __rootNode: null};
			var recordID = 'a1z0G00001JT5NgQAL';
			var relatedRecords= '[{"records":[{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000nBR7QAM"},"Id":"a2w0G000000nBR7QAM","SVMXDEV__SM_Checklist__c":"a1z0G00001JT5NgQAL","SVMXDEV__SM_Question__c":"a1q0G00000NFqawQAD","SVMXDEV__SM_Internal_Question_ID__c":"QB000363","SVMXDEV__SM_Attachment_ID__c":"00P0G00000nJRvL","SVMXDEV__SM_Attachment_Name__c":"TestImage","SVMXDEV__SM_File_Type__c":"Image","SVMXDEV__SM_File_Size__c":null},{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000nBRCQA2"},"Id":"a2w0G000000nBRCQA2","SVMXDEV__SM_Checklist__c":"a1z0G00001JT5NgQAL","SVMXDEV__SM_Question__c":"a1q0G00000NFqbQQAT","SVMXDEV__SM_Internal_Question_ID__c":"QB000369","SVMXDEV__SM_Attachment_ID__c":"00P0G00000nJRvL","SVMXDEV__SM_Attachment_Name__c":"TestImage1","SVMXDEV__SM_File_Type__c":"Image","SVMXDEV__SM_File_Size__c":null}],"headerRecordId":"a1z0G00001JT5NgQAL"}]';
			opDocEngine.__jsee = SVMX.create("com.servicemax.client.sfmopdocdelivery.jsel.JSExpressionEngine", data);
			var aliasDescribeInfo = {'Checklist_Attachment':{'SVMXDEV__SM_Internal_Question_ID__c':{'accessible':true},'SVMXDEV__SM_Attachment_ID__c':{'accessible':true},'SVMXDEV__SM_Attachment_Name__c':{'accessible':true},'SVMXDEV__SM_Checklist__c':{'accessible':true}}};
			var checklist1 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-07\",\"QB000353\":\"2017-07-06 13:22:00\",\"QB000363\":\"2017-07-06\",\"QB000364\":\"2017-07-05 18:30:00\",\"QB000365\":\"2017-07-07\",\"QB000366\":\"2017-07-06 18:30:00\",\"QB000367\":\"2017-07-05\",\"QB000368\":\"2017-07-04 18:30:00\",\"QB000369\":\"2017-07-06 13:22:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist2 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:22:00\",\"QB000363\":\"2017-07-13\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:22:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist3 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:23:00\",\"QB000363\":\"2017-07-13\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:23:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist4 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 10:30:00\",\"QB000363\":\"2017-07-20\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 10:30:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist5 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:30:00\",\"QB000363\":\"2017-07-07\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:30:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist6 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:32:00\",\"QB000363\":\"2017-07-12\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:32:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			var checklist7 = "{\"QB000344\":\"2017-07-05\",\"QB000345\":5,\"QB000352\":\"2017-07-14\",\"QB000353\":\"2017-07-13 11:34:00\",\"QB000363\":\"2017-07-03\",\"QB000364\":\"2017-07-12 18:30:00\",\"QB000365\":\"2017-07-14\",\"QB000366\":\"2017-07-13 18:30:00\",\"QB000367\":\"2017-07-12\",\"QB000368\":\"2017-07-11 18:30:00\",\"QB000369\":\"2017-07-13 11:34:00\",\"QB000354\":\"2017-04-22 04:30:00\",\"QB000355\":\"2017-07-04 18:30:00\",\"QB000356\":\"2017-04-22 04:30:00\",\"QB000370\":\"\",\"QB000371\":\"\"}";
			dataObject.DocumentData[1].Records = [{SVMXDEV__ChecklistJSON__c:checklist1,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist2,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist3,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist4,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist5,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist6,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"},{SVMXDEV__ChecklistJSON__c:checklist7,SVMXDEV__ChecklistProcessID__c:"a120G00000AzUyaQAF"}];
			dataObject.DocumentData[1].relatedRecords = SVMX.toObject(relatedRecords);
			dataObject.DocumentData[1].Key = "Checklist__Work_Order_";
			var params = {};
			params.contextRoots = ["$D","$M"];
			opDocEngine.__jsee.initialize(params);
			opDocEngine.__data = dataObject;
			opDocEngine.__metadata = metaObject;
			opDocEngine.__aliasDescribeInfo = aliasDescribeInfo;
			opDocEngine.__isCheckListProcess = true;
			opDocEngine.__processChecklist();
			var attachmentList = opDocEngine.__jsee.getProperty("allChecklistAttachment")[recordID];
			numberOfAttachments = attachmentList.length;
		});

		after(function() {
			SVMX.OrgNamespace = preOrgNamespace;
		});

		it('send me number of attachment list',function(done){
			assert.equal(numberOfAttachments,2,'default value is not null');
			done();
		});

	});	
	
});