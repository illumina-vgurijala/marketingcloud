/**
*    @author Rajbabu Boopalan
*    @date   2023-10-20
*    @description  Test class for AnnualPricingScheduleHelper
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Rajbabu Boopalan                07-05-2018          Initial version
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestAnnualPricingScheduleHelper {
    /**
     *  @author Rajbabu Boopalan
     *  @description Test Data Setup for clone proposal functionality
     **/
    @testSetup
    static void setupData() {
    }

    /**
     *  @author Rajbabu Boopalan
     *  @description Test method for getAnnualPriceChangeDatebyProposal method
     **/
    @istest
    static void testgetAnnualPriceChangeDatebyProposal()
    {
        DateTime sampleDate = Datetime.newInstance(2024, 04, 23);
        AnnualPricingScheduleHelper.AnnualPricingScheduleWrapper mockPrice1 = new AnnualPricingScheduleHelper.AnnualPricingScheduleWrapper();
        mockPrice1.label = '05-JPY';
        mockPrice1.priceChangeDate = sampleDate + 60;
        mockPrice1.priceListType = '05';

        AnnualPricingScheduleHelper.AnnualPricingScheduleWrapper mockPrice2 = new AnnualPricingScheduleHelper.AnnualPricingScheduleWrapper();
        mockPrice2.label = '15-INR';
        mockPrice2.priceChangeDate = sampleDate + 60;
        mockPrice2.priceListType = '15';

        AnnualPricingScheduleHelper.mockEnable = true;
        AnnualPricingScheduleHelper.testDateTime = sampleDate;
        AnnualPricingScheduleHelper.testAnnualPricingSchedules = new List<AnnualPricingScheduleHelper.AnnualPricingScheduleWrapper> {
            mockPrice1,
            mockPrice2
        };

        Integer num = 1;
        String result = String.valueOf(num++);
        String fakeOpptyId1 = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        Opportunity oppty = new Opportunity(id = fakeOpptyId1, Price_List_Type__c='05');
        Map<id,Opportunity> testMap = new Map<id,Opportunity>();
        testMap.put(fakeOpptyId1,oppty);
        
        result = String.valueOf(num++);
        String fakeOpptyId2 = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        Opportunity oppty2 = new Opportunity(id = fakeOpptyId2, Price_List_Type__c='15');
        testMap.put(fakeOpptyId2,oppty2);

        system.debug('testMap '+testMap);

        result = String.valueOf(num++);
        List<Apttus_Proposal__Proposal__c> lstProposals = new List<Apttus_Proposal__Proposal__c>();
        String fakeid1 = Apttus_Proposal__Proposal__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        lstProposals.add(new Apttus_Proposal__Proposal__c(id = fakeid1, Apttus_QPConfig__PricingDate__c = sampleDate + 15,
            Apttus_Proposal__Opportunity__c=fakeOpptyId1));
        
        result = String.valueOf(num++);
        String fakeid2 = Apttus_Proposal__Proposal__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        lstProposals.add(new Apttus_Proposal__Proposal__c(id = fakeid2, Apttus_QPConfig__PricingDate__c = sampleDate + 30,
            Apttus_Proposal__Opportunity__c=fakeOpptyId2));

        System.debug(lstProposals);

        Test.startTest();
        Map<Id,Datetime> finalMap = new AnnualPricingScheduleHelper().getAnnualPriceChangeDatebyProposal(lstProposals, testMap);
        Test.stopTest();

        System.debug('finalMap '+finalMap);
        Assert.areEqual(2, finalMap.size());
    }
}