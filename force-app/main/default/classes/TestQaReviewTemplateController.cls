/***************************************************************************************************************************************
 * NAME   : TestQaReviewTemplateController
 * DESCRIPTION  : TestQaReviewTemplateController class for LWC Controller (QaReviewTemplateController)
 *    
 * @AUTHOR : Avina
 * @DATE   : 26-Aug-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Avina                   31 AUG 18           Initial Version
 */
@isTest
public with sharing class TestQaReviewTemplateController {
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string OBJECT_NAME = 'Case';
    public static final String SUCCESS_MESSAGE = 'Successfully Updated';
    public static final String LIMIT_EXCEED = 'Limit Exceed' ;
    public static final String QA_REVIEW_FIELD_IS_EMPTY = 'QA Review Field Is Empty' ;
    public static final String QA_REVIEW = 'In Progress' ;

    @testSetup static void setup() {
        List<Case> caseList = new List<Case>();
            Custom_Quick_Text__c quickText = new Custom_Quick_Text__c();
            quickText.Name = 'RUO Reportability assessment';
            quickText.Template__c = 'Product is RUO product.';
            quickText.Related_Object__c = 'Case';
            insert quickText;
        
        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = myId;
        insert csapex;
        
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.Status = 'Initiated';
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = 'Complaint';    
        objCase.Category__c = 'LIMS';
        objCase.Investigation_Summary_Comments__c = 'test';        
        objCase.QA_Review__c = QA_REVIEW;
        caseList.add(objCase);

        Case objCase1 = TestDataCase.initServiceRequestCase(con);
        objCase1.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase1.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase1.Status = 'Initiated';
        objCase1.Description = 'testDescription1';
        objCase1.Sub_Type__c = 'Complaint';    
        objCase1.Category__c = 'LIMS';
        objCase1.QA_Review__c = QA_REVIEW;
        caseList.add(objCase1);

        Case objCase2 = TestDataCase.initServiceRequestCase(con);
        objCase2.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase2.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase2.Status = 'Initiated';
        objCase2.Description = 'testDescription1';
        objCase2.Sub_Type__c = 'Complaint';    
        objCase2.Category__c = 'LIMS';
        caseList.add(objCase2);

        insert caseList;
    }
    static testmethod void updateNonEmptyInvestigationSummary() {
        Case caseData = new Case();
        Map<string,string> textMap = QaReviewTemplateController.getTemplateData(OBJECT_NAME);
        Custom_Quick_Text__c text = [select Name,Template__c from Custom_Quick_Text__c limit 1];
        system.assertEquals(textMap.get(text.Name),text.Template__c,'Please check both values are not equal');

        List<Case> caseRecord = [Select Id,Investigation_Summary_Comments__c,QA_Review__c from Case limit 3  ];
        for(case csData : caseRecord ) {
            if(csData.Investigation_Summary_Comments__c !=null  && csData.QA_Review__c == QA_REVIEW) {
                caseData.Id = csData.Id;
                caseData.Investigation_Summary_Comments__c = csData.Investigation_Summary_Comments__c;
            }
        }
        Test.startTest();
        String isUpdated = QaReviewTemplateController.upsertSummaryField(caseData.Id,text.Template__c,OBJECT_NAME);
        Test.stopTest();
        system.assertEquals(SUCCESS_MESSAGE,isUpdated,'Investigation summary field is not updated successfully');
    }

    static testmethod void updateEmptyInvestigationSummary() {
        Case caseData = new Case();
        Map<string,string> textMap = QaReviewTemplateController.getTemplateData(OBJECT_NAME);
        Custom_Quick_Text__c text = [select Name,Template__c from Custom_Quick_Text__c limit 1];
        system.assertEquals(textMap.get(text.Name),text.Template__c,'Please check both values are not equal');

        List<Case> caseRecord = [Select Id,Investigation_Summary_Comments__c,QA_Review__c from Case limit 3 ];

        for(case csData : caseRecord ) {
            if(csData.Investigation_Summary_Comments__c == null && csData.QA_Review__c == QA_REVIEW) {
                caseData.Id = csData.Id;
                caseData.Investigation_Summary_Comments__c = null;
               
            }
        }
        Test.startTest();
        String isUpdated = QaReviewTemplateController.upsertSummaryField(caseData.Id,text.Template__c,OBJECT_NAME);
        Test.stopTest();
        system.assertEquals(SUCCESS_MESSAGE,isUpdated,'Investigation summary field is not updated successfully');
    }

    static testmethod void updateEmptyISFwithQAReviewInprogress() {
        Case caseData = new Case();
        Map<string,string> textMap = QaReviewTemplateController.getTemplateData(OBJECT_NAME);
        Custom_Quick_Text__c text = [select Name,Template__c from Custom_Quick_Text__c limit 1];
        system.assertEquals(textMap.get(text.Name),text.Template__c,'Please check bothe values are not equal');

        List<Case> caseRecord = [Select Id,Investigation_Summary_Comments__c,QA_Review__c from Case limit 3 ];

        for(case csData : caseRecord ) {
            if(csData.Investigation_Summary_Comments__c == null && csData.QA_Review__c != QA_REVIEW) {
                caseData.Id = csData.Id;
                caseData.Investigation_Summary_Comments__c = null;
               
            }
        }
        Test.startTest();
        String isUpdated = QaReviewTemplateController.upsertSummaryField(caseData.Id,text.Template__c,OBJECT_NAME);
        Test.stopTest();
        system.assertEquals(QA_REVIEW_FIELD_IS_EMPTY ,isUpdated,'QA Review is progress still the Investigation summary field is updated successfully');
    }
    
}
