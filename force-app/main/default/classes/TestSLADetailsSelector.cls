/***************************************************************************************************************************************
 * NAME   : TestSLADetailsSelector
 * DESCRIPTION  : TestClass for SLADetailsSelector class.
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
public with sharing class TestSLADetailsSelector {
    static SVMXC__SLA_Detail__c objServiceDetail = new SVMXC__SLA_Detail__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        objServiceDetail = TestDataFieldService.createServiceDetail(objServiceLevel.Id);
        insert objServiceDetail;
        System.assert(objServiceDetail.Id != null);
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void slaDetailsSelectorTest(){
        initializeTestData();
        
        Set<Id> setSLATermIds = new Set<Id>{objServiceDetail.Id};
            
        Test.startTest();
        SLADetailsSelector selector = new SLADetailsSelector();
        selector.selectSLADetailsFromSLATermIds(setSLATermIds);
        System.assertNotEquals(null,setSLATermIds.size());
        Test.stopTest();
    }
}