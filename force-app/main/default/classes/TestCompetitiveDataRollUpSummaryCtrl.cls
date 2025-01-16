/**
*    @author: Kushagra Desai
*    @date:   03-Sept-2019
*    @description:  Test class for Controller class of  Component CompetitiveDataRollUpSummary
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                07-Feb-2022           CodeScan-Fix [Use assertEquals instead of assert].
*            Gerardo Garcia               14-Feb-2024           Add getJSONProductNames test.
*            Gerardo Garcia               01-Mar-2024           Add getObjectNameById tests CTT forms phase 1.
*    ----------------------------------------------------------------------------------------
*                    
*/
@isTest
public class TestCompetitiveDataRollUpSummaryCtrl {

    @TestSetup
    static void makeData(){
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(acc);
        TestDataCompetitiveCompTech.getNewCompetitiveCompTech(acc);
    }

    @isTest
    static void testinitRecords(){
        CompetitiveDataRollUpSummaryCtrl.MasterData lstDataWrap = CompetitiveDataRollUpSummaryCtrl.initRecords(getAccountPlan().id);
        System.assertEquals(1,lstDataWrap.CompData.size(),'List return more that 1 record');//CodeScan-Fix
        List<CompetitiveDataRollUpSummaryCtrl.RelatedDataTable> lstRelatedData = CompetitiveDataRollUpSummaryCtrl.relatedRecords(getAccountPlan().id, 0, 'GenapSys');
        System.assertEquals(1, lstRelatedData.size(), 'List dont have data');

    }

    @IsTest
    private static void getJSONProductNames() {
        Test.startTest();
        Map<String, Map<String, List<String>>> res = CompetitiveDataRollUpSummaryCtrl.getJSONProductNames();
        System.debug('res:' + JSON.serializePretty(res));
        Test.stopTest();
        Assert.isFalse(res.isEmpty(), 'It should have options Avaliable');
        Assert.isTrue(res.containsKey(CompetitiveDataRollUpSummaryCtrl.OTHER_OPTION), 'It should have "Other"');
        Assert.isTrue(res.containsKey(CompetitiveDataRollUpSummaryCtrl.OUTSOURCED_OPTION), 'It should have "Outsourced / Service Provider"');
    }

    @IsTest
    private static void getObjectNameByIdAsAccount() {
        Test.startTest();
        // Retrieve object name from ID. Account_Name is an account id.
        String objectName = CompetitiveDataRollUpSummaryCtrl.getObjectNameById(getAccountPlan().Account_Name__c);
        Test.stopTest();
        Assert.areEqual('Account', objectName);
    }

    @IsTest
    private static void getObjectNameByIdAsCCTTypeAccount() {
        Test.startTest();
        // Retrieve object name from ID. Account_Name is an account id.
        String objectName = CompetitiveDataRollUpSummaryCtrl.getObjectNameById(getCCT().id);
        Test.stopTest();
        Assert.areEqual('Account', objectName);
    }

    private static Account_Plan__c getAccountPlan() {
        return [SELECT id, Account_Name__c FROM Account_Plan__c LIMIT 1];
    }

    private static Competitive_Complementary_Technology__c getCCT(){
        return [SELECT id FROM Competitive_Complementary_Technology__c LIMIT 1];
    }
}