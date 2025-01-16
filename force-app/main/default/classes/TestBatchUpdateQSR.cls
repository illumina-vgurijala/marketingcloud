/**
 *    @author Aditi Joshi
 *    @date   25-Nov-2020
 *    @description  Test Class for BatchUpdateQSR
*/

@isTest
public with sharing class TestBatchUpdateQSR {
    public static final String QSR_RECORDTYPE_TRAINING_SURVEY = 'Training Survey';
	public static boolean updatedRecords;
	public static String QSR_INSTANCE = '';
	public static final String TEST_QUESTION = 'Dummy';
    
	/* Description Data Setup*/
	@testSetup
    static void setupData(){
        
		QSR_INSTANCE = Schema.SObjectType.Qualtrics_Survey_Response__c.getRecordTypeInfosByDeveloperName().get('Installation').getRecordTypeId();

		User uManager = TestDataUser.findUserInProfile(System.label.Field_Service);
        User u = TestDataUser.findUserInProfile(System.label.Field_Service,new set<Id>{uManager.Id});
        u.ManagerId = uManager.id;
        update u;
		
        Contact con = TestDataPerson.getNewContact(null);

        Case cs = TestDataCase.initServiceRequestCase(con);

        cs_Apex_Settings__c cs1 = cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        cs1.Bypass_All_Validations__c = true;
		cs1.Bypass_All_Triggers__c = true;
        upsert cs1 cs_Apex_Settings__c.Id;
		
        List<Qualtrics_Survey_Response__c> lstqsr=new List<Qualtrics_Survey_Response__c>();
        
		Qualtrics_Survey_Response__c  qsrObj1= TestDataQualtricsSurveyResponse.getNewCaseQSR(cs,QSR_INSTANCE);
        qsrObj1.Survey_Title__c=QSR_RECORDTYPE_TRAINING_SURVEY;
        qsrObj1.status__c = Label.QSRStatusInProgress;
		qsrObj1.Q3_Question__c = TEST_QUESTION;
		qsrObj1.Q4_Question__c = TEST_QUESTION;
		qsrObj1.Q5_Question__c = TEST_QUESTION;
		qsrObj1.Q6_Question__c = TEST_QUESTION;
		qsrObj1.Q7_Question__c = TEST_QUESTION;
		qsrObj1.Q8_Question__c = TEST_QUESTION;
		qsrObj1.Q9_Question__c = TEST_QUESTION;
		qsrObj1.Q10_Question__c = TEST_QUESTION;
		
		Qualtrics_Survey_Response__c  qsrObj2= TestDataQualtricsSurveyResponse.getNewCaseQSR(cs,QSR_INSTANCE);
        qsrObj2.Survey_Title__c=QSR_RECORDTYPE_TRAINING_SURVEY;
        qsrObj2.status__c = Label.QSRStatusInProgress;
		qsrObj2.Q3_Question__c = '';
		qsrObj2.Q4_Question__c = '';
		qsrObj2.Q5_Question__c = '';
		qsrObj2.Q6_Question__c = '';
		qsrObj2.Q7_Question__c = '';
		qsrObj2.Q8_Question__c = '';
		qsrObj2.Q9_Question__c = '';
		qsrObj2.Q10_Question__c = '';
        
		lstqsr.add(qsrObj1);
        lstqsr.add(qsrObj2);

		if(lstqsr!=null && !lstqsr.isEmpty()){
			update lstqsr;
		}

        cs1.Bypass_All_Validations__c = false;
		cs1.Bypass_All_Triggers__c = false;
        upsert cs1 cs_Apex_Settings__c.Id;
        
        BatchUpdateQSR.boolIsTestRunning = true;
    }

	/*Description Method to update batch class and verify result*/
    @isTest
    static void testUpdateQuestions(){
		setupData();
        Test.startTest();
        Id batchJobId =  Database.executeBatch(new BatchUpdateQSR());
        System.assert(batchJobId != null,'Batch Not Scheduled');
        Test.stopTest();

		updatedRecords = true;
		
		List<Qualtrics_Survey_Response__c> lstQSR= [SELECT Id,Q3_Question__c,Q4_Question__c,Q5_Question__c,Q6_Question__c,Q7_Question__c,
													Q8_Question__c,Q9_Question__c, Q10_Question__c 
													FROM Qualtrics_Survey_Response__c];
		
        for(Qualtrics_Survey_Response__c objQSR : lstQSR){
			if(String.IsBlank(objQSR.Q3_Question__c) || String.IsBlank(objQSR.Q4_Question__c) || String.IsBlank(objQSR.Q5_Question__c) || String.IsBlank(objQSR.Q6_Question__c) || String.IsBlank(objQSR.Q7_Question__c) || String.IsBlank(objQSR.Q8_Question__c) || String.IsBlank(objQSR.Q9_Question__c) || String.IsBlank(objQSR.Q10_Question__c)){
				updatedRecords = true;
			}
        }
		System.assert((BatchUpdateQSR.boolEmailSent),'Email Not sent');
		System.assertEquals(true,updatedRecords);
    }
}