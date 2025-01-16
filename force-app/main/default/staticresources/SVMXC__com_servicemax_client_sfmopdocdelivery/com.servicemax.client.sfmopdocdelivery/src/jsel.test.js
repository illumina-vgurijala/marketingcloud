describe("sfmdelivery.OPDoc" ,function(){
	describe("#checklist OPDoc" ,function(){
		var preOrgNamespace = SVMX.OrgNamespace;
		var numberOfSectionAfterFilterCalculation;
		before(function() {
			SVMX.OrgNamespace = 'SVMXDEV';
			var responseJson = "{\"QB000401\":11,\"QB000403\":\"2017-07-10\",\"QB000404\":\"\",\"QB000405\":\"TRAIN\"}";
			var mataJson = "{\"response\": {}, \"page\":{\"header\":{\"sections\":[{\"fields\":[{\"fieldDetail\":{\"SVMXDEV__QuestionInfoJSON__c\":\"\"}}]},{\"fields\":[{\"fieldDetail\":{\"SVMXDEV__QuestionInfoJSON__c\":\"\"}}]},{\"fields\":[{\"fieldDetail\":{\"SVMXDEV__QuestionInfoJSON__c\":\"\"}}]}]}}, \"fieldsToNull\":{}}";
			var QuestionObject1 = "{\"question\":{\"questionID\":\"QB000401\"}}";
			var QuestionObject2 = "{\"question\":{\"questionID\":\"QB000406\"}}";
			var QuestionObject3 = "{\"question\":{\"questionID\":\"QB000403\"}}";
			var mataObject = SVMX.toObject(mataJson);
			var data = {__interceptors:null ,__de:null, __rootNode: null};
			mataObject.page.header.sections[0].fields[0].fieldDetail.SVMXDEV__QuestionInfoJSON__c = QuestionObject1;
			mataObject.page.header.sections[1].fields[0].fieldDetail.SVMXDEV__QuestionInfoJSON__c = QuestionObject2;
			mataObject.page.header.sections[2].fields[0].fieldDetail.SVMXDEV__QuestionInfoJSON__c = QuestionObject3;
			var mataData;
			var jsee = SVMX.create("com.servicemax.client.sfmopdocdelivery.jsel.JSExpressionEngine", data);
			var params = {};
			params.contextRoots = ["$D","$M"];
			jsee.initialize(params);
			mataObject = jsee.filterSkippedSection(responseJson,SVMX.toJSON(mataObject));
			numberOfSectionAfterFilterCalculation = mataObject.page.header.sections.length;
		});

		after(function() {
			SVMX.OrgNamespace = preOrgNamespace;
		});
		it('should not have skipped section after filter',function(done){
			assert.equal(numberOfSectionAfterFilterCalculation,2,'default value is not null');
			done();
		});

	});	

	describe("#checklist OPDoc Attachment" ,function(){
		var preOrgNamespace = SVMX.OrgNamespace;
		var attachmentID;
		before(function() {
			SVMX.OrgNamespace = 'SVMXDEV';
			var attachmentList = '{"a1z0G00001JT5NgQAL":[{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000nBR7QAM"},"Id":"a2w0G000000nBR7QAM","SVMXDEV__SM_Checklist__c":"a1z0G00001JT5NgQAL","SVMXDEV__SM_Question__c":"a1q0G00000NFqawQAD","SVMXDEV__SM_Internal_Question_ID__c":"QB000363","SVMXDEV__SM_Attachment_ID__c":"00P0G00000nJRvL","SVMXDEV__SM_Attachment_Name__c":"TestImage","SVMXDEV__SM_File_Type__c":"Image","SVMXDEV__SM_File_Size__c":null},{"attributes":{"type":"SVMXDEV__SM_Checklist_Attachment__c","url":"/services/data/v40.0/sobjects/SVMXDEV__SM_Checklist_Attachment__c/a2w0G000000nBRCQA2"},"Id":"a2w0G000000nBRCQA2","SVMXDEV__SM_Checklist__c":"a1z0G00001JT5NgQAL","SVMXDEV__SM_Question__c":"a1q0G00000NFqbQQAT","SVMXDEV__SM_Internal_Question_ID__c":"QB000369","SVMXDEV__SM_Attachment_ID__c":"00P0G00000nJRvL","SVMXDEV__SM_Attachment_Name__c":"TestImage1","SVMXDEV__SM_File_Type__c":"Image","SVMXDEV__SM_File_Size__c":null}]}';
			var data = {__interceptors:null ,__de:null, __rootNode: null};
			var jsee = SVMX.create("com.servicemax.client.sfmopdocdelivery.jsel.JSExpressionEngine", data);
			var params = {};
			params.contextRoots = ["$D","$M"];
			jsee.initialize(params);
			jsee.setProperty('allChecklistAttachment',SVMX.toObject(attachmentList));
			var attachmentObject = jsee.getAttachmentIDFromQuestionID('QB000363','a1z0G00001JT5NgQAL');
			attachmentID =  attachmentObject.SVMXDEV__SM_Attachment_ID__c;
		});

		after(function() {
			SVMX.OrgNamespace = preOrgNamespace;
		});
		it('should have attachmentID',function(done){
			assert.equal(attachmentID,'00P0G00000nJRvL','default value is not null');
			done();
		});
	});	
});