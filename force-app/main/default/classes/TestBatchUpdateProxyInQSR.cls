/***************************************************************************************************************************************
 * NAME   : TestBatchUpdateProxyInQSR
 * DESCRIPTION  : TestClass for BatchUpdateProxyInQSR
 * @AUTHOR : Vignesh
 * @DATE   : 08-Jun-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vignesh             08-Jun-2020             Initial Version
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public with sharing class TestBatchUpdateProxyInQSR {

    /**
    *  @author - Vignesh
    *  @description - Test Proxy User in QSR
    **/
     public static final String PROFILE_CUSTOMER_SERVICE = 'Customer Service';
     
     static testmethod void testDelegatedUsers() {
        User proxyUser = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE);
        
        User proxyUser2 = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id} );
        
        User ownerRecord = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id});

        Qualtrics_Survey_Response__c objQSR = new Qualtrics_Survey_Response__c(NPS_Score__c=1,OSAT_Score__c=2,ownerId = OwnerRecord.Id);
        insert objQSR;
        
        test.starttest();
            OwnerRecord.out_of_office__c = true;
            OwnerRecord.DelegatedApproverId = ProxyUser.Id;
            update OwnerRecord;
        test.stoptest();
        
        Qualtrics_Survey_Response__c updatedQSR = [select id,Proxy_owner__c from Qualtrics_Survey_Response__c WHERE ID = :objQSR.Id ];
        system.assertEquals( updatedQSR.Proxy_owner__c , proxyUser.Id,'Delegated Approver Id Not Matching' );
         
        list<Qualtrics_Survey_Response__share> lstShare = [select id from Qualtrics_Survey_Response__share WHERE parentId = :objQSR.Id AND userorGroupId = :proxyUser.Id ];
        system.assert(lstShare.size() > 0, 'Share Records creation failed.');
        
        
    }
    
    /**
    *  @author - Vignesh
    *  @description - Test Proxy User in QSR
    **/
    static testMethod void testProxyUserRemoval(){
        User proxyUser = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE);
        
        User proxyUser2 = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id} );
        
        User ownerRecord = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id});
        
        User updatedOwner = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id,ownerRecord.Id});

        Qualtrics_Survey_Response__c objQSR = new Qualtrics_Survey_Response__c(NPS_Score__c=1,OSAT_Score__c=2,ownerId = OwnerRecord.Id);
        insert objQSR;
        
        test.starttest();
            OwnerRecord.out_of_office__c = true;
            OwnerRecord.DelegatedApproverId = ProxyUser.Id;
            update OwnerRecord;
        test.stoptest();
        
        Qualtrics_Survey_Response__c updatedQSR = [select id,Proxy_owner__c from Qualtrics_Survey_Response__c WHERE ID = :objQSR.Id ];
        system.assertEquals( updatedQSR.Proxy_owner__c , proxyUser.Id ,'Delegated Approver Id not Matching with proxy user' );
         
        list<Qualtrics_Survey_Response__share> lstShare = [select id from Qualtrics_Survey_Response__share WHERE parentId = :objQSR.Id AND userorGroupId = :proxyUser.Id ];
        system.assert(lstShare.size() > 0 , 'QSR Share Records creation Failed');
        
        updatedOwner.out_of_office__c = true;
        updatedOwner.DelegatedApproverId = ProxyUser2.Id;
        update updatedOwner;
        
        objQSR.OwnerId = updatedOwner.Id;
        update objQSR;
        
        Qualtrics_Survey_Response__c updatedOwnerQSR = [select id,Proxy_owner__c from Qualtrics_Survey_Response__c WHERE ID = :objQSR.Id ];
        system.assertEquals( updatedOwnerQSR.Proxy_owner__c , proxyUser2.Id ,'Owner Updated didnt update Proxy.' );
         
        list<Qualtrics_Survey_Response__share> lstUpdatedShare = [select id from Qualtrics_Survey_Response__share WHERE parentId = :objQSR.Id AND userorGroupId = :proxyUser2.Id ];
        system.assert(lstUpdatedShare.size() > 0, 'Updating Owner SHare records creation failed');
        
        list<Qualtrics_Survey_Response__share> lstRemovedShare = [select id from Qualtrics_Survey_Response__share WHERE parentId = :objQSR.Id AND userorGroupId = :proxyUser.Id ];
        system.assert(lstRemovedShare.size() == 0, 'Share records deletion failed');
    }
}