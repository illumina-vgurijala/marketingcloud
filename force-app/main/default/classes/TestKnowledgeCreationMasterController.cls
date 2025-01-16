/* @ author      : Adyasha Satapathy
* @ date         : 04-12-2020
* @ Description  : TestKnowledgeCreationMasterController is the test class for the Controller KnowledgeCreationMasterController of knowledgeCreationMasterComponent LWC.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       04-12-2020                  DCP-43374          Initial version
* Abhinav Gupta           18-May-2022                 DCP-49920          Knowledge Creation prepopulation from Case
*/

@isTest(isParallel = false)
public with sharing class TestKnowledgeCreationMasterController {
    
    public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_MAP = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName();
    public static final String EVALUATION_AID_RECORD_TYPE = 'Evaluation_Aid';
    public static final String OBJECT_API_NAME = 'Knowledge__kav';
    public static final String INVALID_OBJECT_API_NAME = 'Knowledge__c';
    public static final String EXCEPTION_MESSAGE = 'Script-thrown exception';
    public static final String DATA_CATEGORY_IS = 'Evaluation_Aid';
    public static final String DATA_CATEGORY_CS = 'FAQ';
    public static final String DATA_CATEGORY_GROUP_WF = 'Service_and_Support';
    //Start DCP-49920
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_CASES_MATCHED = 'Cases length matched';
    //End DCP-49920

    /**
     *  @author      : Adyasha Satapathy
     *  @description : Setup method to create Knowledge article
     **/
    @TestSetup
    static void initializeTestData()
    {
        String newArticleKnowledgeId = createNewArticleAsADraft();
        publishArticle(newArticleKnowledgeId);
    }
    /**
     *  @author      : Adyasha Satapathy
     *  @description : utility method to create Knowledge article
     **/
    public static String createNewArticleAsADraft()
    {
        Knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,TestKAFeedbackController.KA_PRIMARY_WORKFLOW,TestKAFeedbackController.KA_SECONDARY_WORKFLOW);
        insert newArticle;
        return [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id =: newArticle.Id].KnowledgeArticleId;
    }
    /**
     *  @author      : Adyasha Satapathy
     *  @description : utility method to publish Knowledge article
     **/
    public static void publishArticle(String recordId) 
    { 
        KbManagement.PublishingService.publishArticle(recordId, true);
    }

    /**
     *  @author      : Adyasha Satapathy
     *  @description : test method to test positive scenarios of KnowledgeCreationMasterController methods.
     **/
    @isTest
    public static void testKnowledgeMasterController()
    {
        Knowledge__kav objKnowledge = [Select Id,Title,KnowledgeArticleId FROM Knowledge__kav LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMockHTTP());
        String recTypeID = RECORD_TYPE_MAP.get(EVALUATION_AID_RECORD_TYPE).getRecordTypeId();
        String strJSON = KnowledgeCreationMasterController.loadPage(recTypeID);
        KnowledgeCreationMasterController.getRecordTypeData(OBJECT_API_NAME);
        KnowledgeCreationMasterController.fetchRecordTypeID(objKnowledge.Id);
        Test.stopTest();
        System.assert(strJSON.length() > 0,'Page Layout not fetched');
    }

    /**
     *  @author      : Adyasha Satapathy
     *  @description : test method to trigger Load Page method failure
     **/
    @isTest
    public static void testloadPageFailure()
    {
        String strExceptionMessage='';
        Test.startTest();
        try{
            String recTypeID = RECORD_TYPE_MAP.get(EVALUATION_AID_RECORD_TYPE).getRecordTypeId();
            KnowledgeCreationMasterController.loadPage(recTypeID);
        }
        catch(Exception e){
            strExceptionMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, strExceptionMessage.contains(EXCEPTION_MESSAGE));
    }
    /**
     *  @author      : Adyasha Satapathy
     *  @description : test method to trigger failure scenario of fetchRecordTypeID
     **/
    @isTest
    public static void testfetchRecordTypeIDFailure()
    {
        String strExceptionMessage='';
        Knowledge__kav objKnowledge = [Select Id,Title,KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        Test.startTest();
        try{
            KnowledgeCreationMasterController.fetchRecordTypeID(objKnowledge.KnowledgeArticleId);
        }
        catch(Exception e){
            strExceptionMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, strExceptionMessage.contains(EXCEPTION_MESSAGE));
    }
    /**
     *  @author      : Adyasha Satapathy
     *  @description : test method to trigger failure scenario of getRecordTypeData
     **/
    @isTest
    public static void testGetRecordTypeDataFailure()
    {
        String strExceptionMessage='';
        Test.startTest();
        try{
            KnowledgeCreationMasterController.getRecordTypeData(INVALID_OBJECT_API_NAME);
        }
        catch(Exception e){
            strExceptionMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, strExceptionMessage.contains(EXCEPTION_MESSAGE));
    }
    /**
     *  @author      : Abhinav Gupta
     *  @description : test method to cover getCaseValues DCP-49920
     *  Created Date : 18 May 2022
     **/
    @isTest
    public static void testGetCasesList(){
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        insert objCase;
        List<Case> casesList = new List<Case>();
        Test.startTest();
        casesList = KnowledgeCreationMasterController.getCaseValues(objCase.Id);
        Test.stopTest();
        System.assertEquals(1, casesList.size(),STRING_CASES_MATCHED);
    }
}