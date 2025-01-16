/***************************************************************************************************************************************
 * NAME   : TestServicePlanSelector
 * DESCRIPTION  : TestClass for ServicePlanSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestServicePlanSelector {
    static SVMXC__Service_Plan__c testServicePlan = new SVMXC__Service_Plan__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        testServicePlan = new SVMXC__Service_Plan__c();
        testServicePlan.Name = 'Test Service Plan';
        testServicePlan.SVMXC__Active__c = true;
        testServicePlan.OQ_Required__c = true;
        testServicePlan.Item_Number__c = '01234';
        insert TestServicePlan;
        System.assert(testServicePlan.Id != null);
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void servicePlanSelectorTest(){
        Test.startTest();
        System.assertEquals(1, new ServicePlanSelector().selectServicePlanForItemNumber(new Set<String>{'01234'}).size(),'Assertion Failed');
        Test.stopTest();
    }
}
