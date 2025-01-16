/*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Saddam                22-Feb-2022           Initial Version PM-33 
* Maruthi				14-Mar-2022           Created TestupdateRQContactCompliantUpdate to cover afterupdate method PM-54
*  Saddam                22-Feb-2022           Initial Version PM-33 
*  Maruthi               09-Mar-2022           PM-54 
 ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestAccountContactRelationship {

     /**
     * @author Saddam
     * @description : PM-33 and PM-430, Method for accountcontactrelationship class
     **/
    @istest
    public static void testupdateRQContactCompliant() {
      
            //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount;

        Account objAccount2 = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount2;

        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.is_active__c=true;
        
        List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, Roles, IsActive FROM AccountContactRelation limit 3];        
        listAccConRel[0].Roles = 'Bioinformatics';
        test.startTest();
        update listAccConRel;   
        system.assertNotEquals(Null,listAccConRel.size(),'Not Contains ACR Records');
        test.stopTest();
    }

     /**
    * @author Maruthi
    * @date   14-Mar-2022
    * @description PM-54:To cover 
    */
    @istest
    public static void testupdateRQContactCompliantUpdate() {
      
        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount;

        Account objAccount2 = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount2;

        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.is_active__c=true;
        
        List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, Roles, IsActive FROM AccountContactRelation Limit 3];        
        listAccConRel[0].Roles = 'Finance';	 
        test.startTest();
            update listAccConRel;
            List<Object_History__c> hisObj = [Select id from Object_History__c where Source_Object_Record_ID__c =: listAccConRel[0].Id];
            System.assertEquals(1,hisObj.Size(),'AccountContactRelationships');  
        test.stopTest();
    }

}