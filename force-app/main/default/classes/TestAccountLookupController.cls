/***************************************************************************************************************************************
 * NAME   : TestAccountLookupController
 * DESCRIPTION  : TestAccountLookupController class for LWC Controller (AccountLookupController)
 *    
 * @AUTHOR : Avina
 * @DATE   : 26-Aug-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Avina                   21 SEP 2022          Initial Version
 */
@isTest
public with sharing class TestAccountLookupController {
    public static final string OBJECT_NAME = 'Account';
    public static final string FIELD_NAME = 'Name';
    public static final string DISPLAY_TEXT = 'ERP_Customer_Id__c';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final String QA_REVIEW = 'In Progress' ;
    @testSetup static void setup() {
        
        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = myId;
        insert csapex;
        
        TestDataAccount.getNewAccount();
    }
    static testmethod void fetchAccountDetailsForLookup() {
       // List<SObJectResult> sObjectResultList = new List<SObJectResult>();
       Test.startTest();
       List<AccountLookupController.sObJectResult> accountRecord= AccountLookupController.getAccountResults(OBJECT_NAME,FIELD_NAME,'Test',DISPLAY_TEXT);
       Test.stopTest();
       system.assertEquals(1,accountRecord.size(),'More than 1 record returned');
    }
}