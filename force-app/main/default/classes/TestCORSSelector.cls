/***************************************************************************************************************************************
 * NAME   : TestCORSSelector
 * DESCRIPTION  : TestClass for LMSCertificationMappingSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 30-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             30-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData=false)
public with sharing class TestCORSSelector {
    /**
      *  @author Prashanth
      *  @description - test the LMSCertificationMappingSelector class.
    **/
    @IsTest
    static void corsSelectorTest(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);

        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
        orders1.ASOP_Number__c = '0001';
        orders1.Ultimate_Consignee__c = acc.Id;
        orders1.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders1.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders1;

        Contract_Order_Routing_Sheet__c objCORS = new Contract_Order_Routing_Sheet__c();
        objCORS.Opportunity__c = opp.Id;
        objCORS.Order__c = orders1.Id;
        objCORS.Additional_Notes__c = 'test notes';
        objCORS.Rev_Rec_Code__c = 'ACD: Acceptance Upon Delivery';
        objCORS.Account__c = acc.Id;
        insert objCORS;
        
        Test.startTest();
        CORSSelector selector = new CORSSelector();
        System.assertEquals(1, selector.selectCORSForOrders(new Set<Id>{orders1.Id}).size(), 'Assertion failed.');
        System.assertEquals(1, selector.selectCORSForOrders(new List<Id>{orders1.Id}).size(),'Assertion failed');
        Test.stopTest();
        
    }
}
