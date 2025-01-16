/***************************************************************************************************************************************
* NAME   : TestACRHistoryTrackingRelatedListCtrl
* DESCRIPTION  : TestClass for ACRHistoryTrackingRelatedListController 
* @AUTHOR : Maruthi
* @DATE   : 17-Mar-2022
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Maruthi                22-Feb-2022           Initial Version PM-54 
 ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestACRHistoryTrackingRelatedListCtrl {
    
    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This Method PM-54 to ACRHistoryTrackingRelatedListCtrl  
    */
    @istest
    public static void testACRHisTrackRelListController() {
      
        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount;

        Account objAccount2 = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount2;

        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.is_active__c=true;
        
        //Create Non related Contact
        Contact objContact2 = TestDataContact.getNewContact(objAccount);
        objContact2.is_active__c=true;

        List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, Roles, IsActive FROM AccountContactRelation limit 100];        

        //Create Object History
        Object_History__c objHis = new Object_History__c();
        objHis.Original_Value__c = 'Original';
        objHis.New_Value__c = 'Original';
        objHis.Source_Object__c = 'AccountContactRelation';
        objHis.Source_Object_Record_ID__c = listAccConRel[0].Id;

        insert objHis;
        

        test.startTest();
        ACRHistoryTrackingRelatedListController.getObjectHistoryData(listAccConRel[0].Id);
        system.assertEquals(listAccConRel[0].Id,objHis.Source_Object_Record_ID__c,'TestACRHistoryTrackingRelatedListCtrl' );
        test.stopTest();
    }
}