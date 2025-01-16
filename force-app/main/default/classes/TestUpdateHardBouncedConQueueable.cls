/*@ author       : Gopi
* @ date         : 10-06-2023
* @ Description  : CMCM-704:  R/Q Contact Notifications: Account Engagement Hard Bounced
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopi               	10-06-2023                 CMCM-704
* Bala               	23-06-2023                 CMCM-933
 ****/

@isTest
public class TestUpdateHardBouncedConQueueable {
	 /*
    *  @AUTHOR:  Gopi
    *  @DESCRIPTION: Method to test UpdateHardBouncedConQueueable  
    */ 
    @isTest 
    static void checkQueueable() {
        //creation of accounts
        Account account1 = TestDataAccount.getCustomerAccount();
        Account account2 = TestDataAccount.getCustomerAccount();
        insert new List<Account> {account1, account2};
        System.assert(account1.Id != null,'Account not created');
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert new List<Contact> {con1};
        System.assert(con1.Id != null,'Contact not created'); 
        // Setting up mock response for Resignation Form Handler.
        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        //start test
        Test.startTest();
        con1.AccountId = account2.Id;
        con1.Email = 'pr@test123.com';
        update con1;
        List<AccountContactRelation> lstACR = [Select Id,AccountId,ContactId,Roles,Product_Notifications_Categories__c from AccountContactRelation where contactId =:con1.Id];
        System.assertEquals(2,lstACR.size(),'Account Contact Relation List size is not as expected');
        lstACR[0].Product_Notifications_Categories__c = 'Default (All)';
        lstACR[0].Roles = 'Regulatory/Quality;Hard Copy letter to Sales;Hard Copy letter to Service';
        update lstACR[0];
        con1.pi__pardot_hard_bounced__c = TRUE;
        con1.Resigned_R_Q__c = TRUE;
        update con1;
        Test.stopTest();
        List<AccountContactRelation> lstACR1 = [Select Id,AccountId,ContactId,Roles,Product_Notifications_Categories__c from AccountContactRelation where contactId =:con1.Id];
        System.assert(String.isBlank(lstACR1[1].Roles),'AccountContactRelation Roles not removed.');
        System.assert(String.isBlank(lstACR1[1].Product_Notifications_Categories__c),'AccountContactRelation Product_Notifications_Categories__c not removed.');
    }
}