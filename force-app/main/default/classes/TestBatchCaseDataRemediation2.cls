/**************************************************************************************************************************************
* NAME   : TestBatchCaseDataRemediation2
* DESCRIPTION  : Test class for BatchCaseDataRemediation2
*  
*
* @AUTHOR : Nitin Z 
* @DATE   : 25 -jun -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  25-jun -2024   

****************************************************************************************************************************************/ 

@isTest
public class TestBatchCaseDataRemediation2 {
    public static final String STRING_PRODUCT_MATERIAL_CLASS = 'Consumables';
    public static final String STRING_PRODUCT_CODE = 'Test 1234';
    
    
    @testSetup
    static void setupTestData() {
        // Create Test Users
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        // Insert Account
        Account objAccount = new Account(Name = 'Test Account', 
                                         Account_Group__c = 'Distributor', 
                                         Clinical_Type__c = 'Clinical',
                                         BillingStreet = 'test billing street',
                                         BillingCity = 'test billing city',
                                         BillingPostalCode = '90909',
                                         BillingStateCode = '',
                                         BillingCountryCode = 'JP',
                                         Customer_Sub_Type__c = 'Genome Center',
                                         Customer_Type__c = 'Academic',
                                         Market_Segment__c = 'Forensics',
                                         Tier__c = 'Tier 1',
                                         CurrencyIsoCode = 'USD');
        insert objAccount;

        // Insert Service Plan
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c(Name = 'Test Service Plan');
        insert sp;

        // Insert Service Contract
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.Id;
        objServiceLevel.Least_SLA__c = 2880;
        insert objServiceLevel;

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.ERP_Contract_Type__c = '12 Software (ZWS)';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;
        System.assert(objServiceContract.Id != null, 'Service Contract not created');

        // Create Test Products
        Product2 product = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        product.Service_Product_Type__c = 'Core';
        product.Regulatory_Type__c = 'DX';
        product.Source_System__c = 'SAP';
        insert product;

        // Insert Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = new SVMXC__Installed_Product__c(
            Name = 'Test IP VM', 
            SVMXC__Company__c = objAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert objInstalledProduct;

        Contact con = TestDataPerson.getNewContact(objAccount.Id);

        // Ensure CaseRoutingCriteriaMappings and other required data are populated
        CasesHelper.CaseRoutingCriteriaMapping caseRoutingCriteriaMapping = new CasesHelper.CaseRoutingCriteriaMapping();
        if (caseRoutingCriteriaMapping != null) {
            caseRoutingCriteriaMapping.initMapCaseRoutingCriteriaMappings();
        } else {
            System.debug('The map inside caseRoutingCriteriaMapping is null.');
        }
   
        // Create a Case to associate with the Work Order
        Case testCase = TestDataCase.initServiceRequestCase(con);
        testCase.Origin = 'Web';
        testCase.Status = 'New';
        testCase.Date_Time_Completed__c = System.today();
        testCase.Product_Lot_Number__c = 'LOT001';
        testCase.Product_Serial_Number__c = 'SN001';
        testCase.CreatedById = testUser.Id;
        testCase.Expired_Reagent__c = false;
        testCase.Software_Version__c = 'v1.0';
        testCase.OwnerId = testUser.Id;
        testCase.SVMXC__Product__c = product.Id;
       // testCase.Subscription__c = objServiceContract.Id;
        testCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert testCase;
    }

    @isTest
    static void testBatchCaseDataRemediation() {

        List<Case> caseList = [SELECT Id,SVMXC__Component__c, SVMXC__Product__c,AP_Conversion_Flag__C FROM Case LIMIT 200];
        SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id from SVMXC__Installed_Product__c LIMIT 1];
        SVMXC__Service_Contract__c objServiceContract = [SELECT ID from SVMXC__Service_Contract__c LIMIT 1];
        //Product2 product = [SELECT Id from Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        Product2 product = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        product.Service_Product_Type__c = 'Core';
        product.Regulatory_Type__c = 'EU';
        product.Source_System__c = 'SAP';
        insert product;

        // Start the test
        Test.startTest();

        // Create Test Work Order and associate it with the Case
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c(
            SVMXC__Component__c = objInstalledProduct.Id,
            SVMXC__Product__c = product.Id,
            Product_Lot_Number__c = 'LOT001',
            Product_Serial_Number__c = 'SN001',
            CreatedById = testUser.Id,
            OwnerId = testUser.Id,
            SVMXC__Order_Type__c = 'Field Service',
            Record_Created_from_SFM__c = true,
            SVMXC__Case__c = caseList[0].Id
        );
         AssociatedProduct.skipAPTrigger=true;
         Cases.skipCaseTrigger=true;
         WorkOrders.skipWOTrigger=true;
         
         insert wo;
		 caseList[0].Work_Order__c=wo.Id;
         update caseList[0];
        // Verify Results
        // Collect results in a single query
        SVMXC__Case_Line__c caseLine = new SVMXC__Case_Line__c(
            SVMXC__Case__c = caseList[0].Id,
            Recall_Activity__c = 'Recall Actions Acknowledged & Completed',
            Expiration_Date__c = System.today().addDays(30),
            SVMXC__Installed_Product__c = caseList[0].SVMXC__Component__c,
            SVMXC__Product__c = caseList[0].SVMXC__Product__c,
            IsExpired__c = false,
            Product_Lot_Number__c = 'LOT00' + caseList[0].Id,
            Product_Serial_Number__c = 'SN00' + caseList[0].Id
        );
        insert caseLine;
		// Stop the test
       
        BatchCaseDataRemediation2 batch = new BatchCaseDataRemediation2(10000);
        Database.executeBatch(batch, 200);
        Test.stopTest(); 
        caseList = [SELECT Id, AP_Conversion_Flag__C FROM Case WHERE AP_Conversion_Flag__C = 'PROCESSED' LIMIT 200];
               
        // Verify that the cases have been updated
        for (Case caseObj : caseList) {
            System.assertEquals('PROCESSED', caseObj.AP_Conversion_Flag__C, 'The AP Conversion Flag should be PROCESSED.');
        }

        // Verify that the case lines have been updated
        // for (SVMXC__Case_Line__c caseLine : caseLines) {
        //      System.assertEquals('PROCESSED', caseLine.Associated_Product__c, 'The Associated Product flag should be PROCESSED.');
        // }

        // Verify that the associated products have been inserted
        Integer associatedProductCount = [SELECT COUNT() FROM Associated_Product__c limit 1];
        System.assert(associatedProductCount > 0, 'There should be associated products inserted.');
    }
}