/***************************************************************************************************************************************
 * NAME   : TestQualtricsSurveyResponseFlow
 * DESCRIPTION  : TestClass for QualtricsSurveyFlow
 *           
 *    
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gaurav         19-10-2024           Initial Version
 
  ****************************************************************************************************************************************/ 
@IsTest
public class TestQualtricsSurveyResponseFlow {
    
   /**
    * This method sets up the test data for Qualtrics_Survey_Response__c
    * and configures cs_Apex_Settings__c to bypass all validations.
    */
    @TestSetup
    public static void setup() {
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
		cs.Bypass_All_Validations__c = true;
		upsert cs cs_Apex_Settings__c.Id;
        
        // Create test data for Qualtrics_Survey_Response__c
        Qualtrics_Survey_Response__c surveyResponse = new Qualtrics_Survey_Response__c();
        surveyResponse.Status__c = 'Closed / Case Created';
        surveyResponse.Reason_for_Reopen__c = 'Test Reason';
        insert surveyResponse;
    }

    /**
    * This method checks the Qualtrics Survey flow
    * and configures cs_Apex_Settings__c to bypass all validations.
    */
    @IsTest
    public static void testSurveyResponseFlow() {
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = UserInfo.getUserId();
        upsert csapex;

        Qualtrics_Survey_Response__c qSResponse = new Qualtrics_Survey_Response__c();
        qSResponse.Status__c = 'Initiated';
        qSResponse.Review_Comments__c = 'Test Comment';
        qSResponse.Low_Score_Flag__c = true;
        insert qSResponse;

        qSResponse.Status__c = 'Closed / No Customer Response';
        update qSResponse;

        qSResponse.Status__c = 'In Progress';
        qSResponse.Reason_for_Reopen__c ='test Reopen';
        update qSResponse;

        List<Qualtrics_Survey_Response__c> qSResponseList = [SELECT id, Status__c, Reopened_By__c,Reason_for_Reopen__c FROM Qualtrics_Survey_Response__c WHERE Id = :QSResponse.Id LIMIT 1];

        System.assertEquals(UserInfo.getUserId(), qSResponseList[0].Reopened_By__c);
    }
}
