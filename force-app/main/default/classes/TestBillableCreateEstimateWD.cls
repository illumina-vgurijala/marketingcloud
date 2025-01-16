/**
*    @authorKD
*    @date  
*    @description    DCP-45928: Test class for BillableCreateEstimateWD
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestBillableCreateEstimateWD {
    public static final String STRING_WORK_ORDER_RECORD_TYPE_ESTIMATES = 'Estimates';
    public static final String PRICE_LIST_TYPE = '01';
    public static final String PRICE_LIST_CURRENCY = 'USD';
    public static final string PRICE_LIST = '01-AMR-USD';
    public static final string COMPANY_CODE = 'US01';
    /**
    *   DCP-45928
	*	@author KD	
	**/
    @TestSetup
    static void setupData()
    {
        // Add Labor and Travel Product
        Product2 objTravelProduct = TestDataMaster.initProduct('IL-SER-TRAVEL-Z1');
        Product2 objLaborProduct1 = TestDataMaster.initProduct('15013864');
        Product2 objLaborProduct2 = TestDataMaster.initProduct('15013863');
        

        insert new List<Product2>{objTravelProduct,objLaborProduct1,objLaborProduct2};
    }
    /**
    *   DCP-45928
    *   @author KD  
    **/
    @isTest
    public static void testWDCreation(){
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(profile.Id);
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = false;
        upsert cs cs_Apex_Settings__c.Id;
        //Create WorkOrder
        Test.startTest();
        TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_ESTIMATES,TestPartsOrderLines.STRING_WORK_ORDER_STATUS_INITIATED,'Service Activities');
        Test.getEventBus().deliver();
        Test.stopTest();
        List<SVMXC__Service_Order_Line__c> lstWD = [Select id from SVMXC__Service_Order_Line__c where RecordType.Name = 'Estimate'];
        System.assertEquals(2,lstWD.size(), 'WorkDetail Not created');
    }
}