 /**
* @ author       : Saddam  
* @ date         : 25-Feb-2022
* @ Description  : PM-33 Data correction test class for BatchForAccountRQCompliant 
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description 
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam              23-March-2022                 Initial version 
*/

@istest
public with sharing class TestBatchForAccountRQCompliant  {
    
     /**
    * @author Saddam  
    * @date  23-March-2022 
    * @description  This method to cover BatchForAccountRQCompliant batch
     */

    @isTest
    public static void accountRQContactCompliant() {
      
        //Create Account
     Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
     Insert objAccount;

     Account objAccount2 = TestDataAccount.getAccount('Test Acc2354', 'USD');
     Insert objAccount2;

     //Create Contact
     Contact objContact = TestDataContact.initContact(objAccount);
     objContact.is_active__c=true;
     objContact.Email = 'Test1@gaiml.com';
     insert objContact;
     
     //Create Non related Contact
     Contact objContact2 = TestDataContact.initContact(objAccount);
     objContact2.is_active__c=true;
     objContact2.Email = 'Test2@gaiml.com';
     insert objContact2;

     List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, Roles, IsActive, Account.R_Q_Contact_Compliant__c FROM AccountContactRelation Limit 3];        
     List<AccountContactRelation> listAcrObj = new List<AccountContactRelation>();
     for(AccountContactRelation acrObj : listAccConRel){
     	acrObj.Product_Notifications_Categories__c = 'Default (All)';
        acrObj.Roles = 'Regulatory/Quality';
        listAcrObj.add(acrObj);
     }     
      update listAcrObj;     
         Test.startTest();        
         BatchForAccountRQCompliant batchObj = new BatchForAccountRQCompliant();      
         batchObj.execute(Null);  
         Database.executeBatch(batchObj);
         System.assertEquals('Not Applicable',listAcrObj[0].Account.R_Q_Contact_Compliant__c,'BatchAccountSetRQContactCompliant');  
      Test.stopTest();
    }
}
