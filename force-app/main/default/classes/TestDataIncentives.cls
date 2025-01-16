/**
* @author Vishnu Priya Duggineni
* @date   2018-10-28
* @description    Test data for TestApttusIncentivesPromotions
* Modification Log:
* ----------------------------------------------------------------------------------------------------------------------------------------
* Developer                   Date                       Description
* Vishnu Priya Duggineni      28 October 2018            Test Data Incentives
* ----------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TestDataIncentives {
    /**
    * 
    *
    * @desc initIncentive [CodeScan Fix]
    */
     public static Apttus_Config2__Incentive__c initIncentive() {
        Apttus_Config2__Incentive__c aIncentive = new Apttus_Config2__Incentive__c(
            Name = 'TestIncentive ' + TestData.getRandom(),
            Apttus_Config2__IncentiveCode__c  = '123456',
            Apttus_Config2__ExpirationDate__c  = system.Today(),
            Promotion_Redemption_Method__c = 'TestMethod',
            Apttus_Config2__Description__c  = 'TestDescription',
            Promo_Channel__c = 'Test Promo',
            Apttus_Config2__Sequence__c = 1,
			Apttus_Config2__Active__c = true
        );
        return aIncentive;
    }
}