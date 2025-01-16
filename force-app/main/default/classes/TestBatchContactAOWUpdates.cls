/**
*    @author: Deep Diwakar
*    @date:   Feb-13-2024
*    @description: Test class for BatchContactAOWUpdates class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-13-2024        CMCM-4508: Test class for BatchContactAOWUpdates class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchContactAOWUpdates {

    @TestSetup
    static void dataSetup() {
        //Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.Market_Segment__c = null;
        insert objAccount;
    }

    @isTest
    static void testBatchUpdates() {
        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 100);

        insert objMarketSegment1;

        Contact testCont1 = TestDataPerson.initContact(testAcct.Id);


        // Bypassing trigger update so AOW values are not set
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
        objApexSettings.Bypass_All_Triggers__c=true;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        insert testCont1;

        // Reverting bypass
        objApexSettings.Bypass_All_Triggers__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        Test.startTest();
        Database.executeBatch(new BatchContactAOWUpdates(), 2000);
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c FROM Contact WHERE Id =: testCont1.Id];

        Assert.areEqual('Agrigenomics', resultCont.Area_Of_Work__c, 'Batch did not set AOW value correctly');

    }

    @isTest
    static void testBatchWithAOW() {
        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 100);

        insert objMarketSegment1;

        Contact testCont1 = TestDataPerson.initContact(testAcct.Id);

        // trigger will set AOW for contact
        insert testCont1;

        Test.startTest();
        Database.executeBatch(new BatchContactAOWUpdates(), 2000);
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c FROM Contact WHERE Id =: testCont1.Id];

        Assert.areEqual('Agrigenomics', resultCont.Area_Of_Work__c, 'Batch updated AOW value incorrectly');

    }

    @isTest
    static void testBatchNoAOW() {
        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        // not creating Market segment for this account so AOW value will remain empty even after trigger run
        // creating contact directly
        Contact testCont1 = TestDataPerson.initContact(testAcct.Id);

        // trigger will set AOW for contact
        insert testCont1;

        Test.startTest();
        Database.executeBatch(new BatchContactAOWUpdates(), 2000);
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c FROM Contact WHERE Id =: testCont1.Id];

        Assert.isNull(resultCont.Area_Of_Work__c, 'Batch updated AOW value incorrectly');

    }


}