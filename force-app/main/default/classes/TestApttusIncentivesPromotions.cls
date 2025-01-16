/**
* @author Vishnu Priya Duggineni
* @date   2018-10-28
* @description    Test class for IncentivesPromotions
* Modification Log:
* ----------------------------------------------------------------------------------------------------------------------------------------
* Developer                   Date                       Description
* Vishnu Priya Duggineni      28 October 2018            IncentivesPromotions test class
* Kushagra Desai              7-July-2018                Added Assert : testApttusIncentivesPromotions()
* ----------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class TestApttusIncentivesPromotions {
    @testSetup
    static void setupData()
    {
         insert new LIST<Apttus_Config2__Incentive__c> {
                 TestDataIncentives.initIncentive(),
                 TestDataIncentives.initIncentive(),
                 TestDataIncentives.initIncentive()
         };
    }

    static testMethod void testApttusIncentivesPromotions() 
    {
        List<ApttusIncentivesPromotions.PromotionsResult> lstPromotions;
        Test.startTest();
        {
            lstPromotions = ApttusIncentivesPromotions.getPromotions();
        }
        Test.stopTest();
        system.assertEquals(false, lstPromotions.isEmpty(),'No record returned');
         
    }

}