/**
* @author Shivani Jain
* @date 28 Sep 2021
* @description DCP-47698 Test Class for ApttusOrderLineItemQueueable
*/
@isTest
private class TestApttusOrderLineItemQueueable {

    static SVMXC__Service_Group_Members__c grpMembers;
    static SVMXC__Service_Group__c serviceTeam;
    static final String MATERIALGROUP5_ACCEPTANCE = 'ACD: Acceptance Upon Delivery';
    
    /*******************************************************************************************************
    * @description Setup method for test class
    */
    @testSetup
    static void setupData() {
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
    }

    /*******************************************************************************************************
    * @description Setup method for ApttusOrderLineItemQueueable execute method
    */
    @isTest
    private static void testExecute() {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assert(acc.Id != null, 'Account not inserted successully');
       
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        System.assert(opp.Id != null, 'Opportunity not inserted successully');
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA;
        objProduct.Source_System__c='SAP'; 
        insert objProduct;
        System.assert(objProduct.Id != null, 'Product not inserted successully');
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders;
        System.assert(orders.Id != null, 'Order not inserted successully');

        Test.startTest();
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        insert objOrderLineItem;
        System.assert(objOrderLineItem.Id != null, 'Order Line Item not inserted successully');
        
        objOrderLineItem.Apttus_Config2__Quantity__c = 3;  
        objOrderLineItem.Material_Group_5__c = MATERIALGROUP5_ACCEPTANCE; 
        update objOrderLineItem; 
		Test.stopTest();
        List<SVMXC__Service_Order__c> lstWOInserted = [Select Id from SVMXC__Service_Order__c LIMIT 10];
        system.assertEquals(3, lstWOInserted.size(), 'Work Order Insertion Automation failed');

        List<SVMXC__Service_Order__c> lstWOUpdated = [Select Id, Acceptance_Code__c from SVMXC__Service_Order__c LIMIT 10];
        System.assertEquals(MATERIALGROUP5_ACCEPTANCE, lstWOUpdated[0].Acceptance_Code__c, 'Acceptance Code not populated succesfully!');
    }
    @isTest
    private static void testExecuteBillabeCheck() {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assert(acc.Id != null, 'Account not inserted successully');
       
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        System.assert(opp.Id != null, 'Opportunity not inserted successully');
        
        Product2 objProduct=TestDataFieldService.createProduct('Test ProductA','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL04';
        objProduct.ProductCode = '20102513'; 
        insert objProduct;
        System.assert(objProduct.Id != null, 'Product not inserted successully');
        
        Product2 objMaterial =TestDataFieldService.createProduct('Test ProductM','Instrument');
        objMaterial.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objMaterial.Service_Product_Type__c = 'Instrument';
        objMaterial.Serial_Number_Profile__c = 'IL05';
        objMaterial.ProductCode = '20132562'; 
        insert objMaterial;
        System.assert(objMaterial.Id != null, 'Product not inserted successully');
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-LS-06');
        insert priceList;
        Apttus_Proposal__Proposal__c quotation = TestDataProposal.initProposal(acc.Id, opp.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quotation;
        System.assert(quotation.Id != null, 'Quotation not inserted successully');
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0003';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1238';
        orders.Apttus_QPConfig__ProposalId__c = quotation.Id;
        insert orders;
        System.assert(orders.Id != null, 'Order not inserted successully');
        
        Apttus_Proposal__Proposal_Line_Item__c quotationLine = new Apttus_Proposal__Proposal_Line_Item__c();
        quotationLine.Apttus_Proposal__Proposal__c = quotation.Id;
        quotationLine.Apttus_Proposal__Product__c = objMaterial.Id;
        quotationLine.Apttus_QPConfig__Quantity2__c= 10;
        insert quotationLine;
        System.assert(quotationLine.Id != null, 'Quotation not inserted successully');
        
        Test.startTest();
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_123';
        insert objOrderLineItem;
        System.assert(objOrderLineItem.Id != null, 'Order Line Item not inserted successully');
        
        objOrderLineItem.Apttus_Config2__Quantity__c = 3;  
        objOrderLineItem.Material_Group_5__c = MATERIALGROUP5_ACCEPTANCE; 
        update objOrderLineItem; 
		Test.stopTest();
    }
}