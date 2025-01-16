/*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Saddam                28-Mar-2022           Initial Version PM-33,pm-430, Test class for AccountContactRelationshipsService class.
 ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestAccountContactRelationshipsService {

    /**
    * @author Saddam
    * @date    28-Mar-2022
    * @description  To cover 
    */
    @istest
    public static void testUpdateRQContactCompliant() {
      
            //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount;

        Account objAccount2 = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount2;

        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.is_active__c=true;
        
        List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, Roles, IsActive FROM AccountContactRelation Limit 3];        
        listAccConRel[0].Roles = 'Bioinformatics';
        test.startTest();
        update listAccConRel;
        AccountContactRelationshipsService.updateRQContactCompliant(listAccConRel);   
        system.assertNotEquals(Null,listAccConRel.size(),'Not Contains ACR Records');
        test.stopTest();
    }

     /**
    * @author Saddam
    * @date    19-Mar-2022
    * @description  To cover 
    */
    @isTest
    static void testAsyncUpdateAccountCompliance() {

        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        objAccount.R_Q_Contact_Eligible__c=false;
        objAccount.R_Q_Contact_Compliant__c='Not Applicable';
        
        List<Account> accList =[SELECT id,name FROM ACCOUNT WHERE id =: objAccount.Id];     
        test.startTest(); 
        update accList;
        AccountContactRelationshipsService.asyncUpdateAccountCompliance(accList);   
        system.assertNotEquals(Null,accList.size(),'Account not updated');
        test.stopTest();
    }

}