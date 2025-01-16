/***************************************************************************************************************************************
 * NAME   : TestQualtricsSurveyResponseShareSelector
 * DESCRIPTION  : TestClass for QualtricsSurveyResponseShareSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestQualtricsSurveyResponseShareSelector {
    static final String PROFILE_CUSTOMER_SERVICE = 'Customer Service';
    /**
      *  @author Prashanth
      *  @description - test the qualtricsSurveyResponseShareSelector class 
    **/
    @IsTest
    static void qualtricsSurveyResponseShareSelectorTest(){
        User proxyUser = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE);
        
        User proxyUser2 = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id} );
        
        User ownerRecord = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id});

        Qualtrics_Survey_Response__c objQSR = new Qualtrics_Survey_Response__c(NPS_Score__c=1,OSAT_Score__c=2,ownerId = OwnerRecord.Id);
        insert objQSR;
        
        Test.startTest();
        OwnerRecord.out_of_office__c = true;
        OwnerRecord.DelegatedApproverId = ProxyUser.Id;
        update OwnerRecord;
        Test.stopTest();
        List<Qualtrics_Survey_Response__share> lstShare = [select id from Qualtrics_Survey_Response__share WHERE parentId = :objQSR.Id AND userorGroupId = :proxyUser.Id ];
        system.assert(!lstShare.isEmpty(), 'Share Records creation failed.');
        new QualtricsSurveyResponseShareSelector().getShareRecordsWithParentId(new Set<Id>{objQSR.Id},new List<Id>{proxyUser.Id},'Manual');
    }
}
