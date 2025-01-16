/***************************************************************************************************************************************
 * NAME   : TestSLATermsSelector
 * DESCRIPTION  : TestClass for SLATermsSelector class.
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
public with sharing class TestSLATermsSelector {
    static SVMXC__Service_Level__c objServiceLevel = new SVMXC__Service_Level__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
          
        objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        System.assert(objServiceLevel.Id != null);
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void slaTermsSelectorTest(){
        initializeTestData();
        Test.startTest();
        System.assertEquals(1, new SLATermsSelector().selectSLATermsFromIds(new Set<Id>{objServiceLevel.Id}).size(),'Assertion Failed.');
        Test.stopTest();
    }
}