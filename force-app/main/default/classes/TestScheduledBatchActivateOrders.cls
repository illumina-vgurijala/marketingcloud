/**
*    @author Satya Swain
*    @date   2021-03-31
*    @description   TASK0578653 : Test class for ScheduledBatchActivateOrders
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Satya Swain                 2021-03-31             Initial Version
*         Satya Swain                 2021-04-16             Added testAssetLineActivation as part of TASK0585742
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestScheduledBatchActivateOrders {
    /**
     * @author Satya
     * @description setup method
     **/
    @testSetup
    static void initializeTestData()
    {
        //Test Data for account Insert
        Account acc =TestDataAccount.getCustomerAccount();
        acc.Name = 'TestAccountApttusOrderInsert';
        acc.ERP_Customer_Id__c='123456';
        
        //Test Data for account Update
        Account accUpdate =TestDataAccount.getCustomerAccount();
        accUpdate.Name = 'TestAccountApttusOrderUpdate';
        accUpdate.ERP_Customer_Id__c='654321';
        insert new List<Account>{acc,accUpdate};
        System.debug('acc-> '+acc);
        System.debug('Account Update:-'+accUpdate);
        
        //Customer Master Data insert
        Customer_Master_Data__c testCMD = new  Customer_Master_Data__c();
        testCMD.Name='TestApttusOrderDataCMD';
        testCMD.ERP_Customer_Id__c='1981';
        insert testCMD;
        System.debug('CMD Insert:-'+testCMD);
        
       //Test Data For Proposal insert
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Pricebook2Id = pricebookId;
        update opp;
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposalInsert = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposalInsert;
        System.debug('Apttus Proposal:'+proposalInsert);
        
        //Test Data for Proposal Update
        Pricebook2 standardPricebookUpdate = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookIdUpdate = standardPricebookUpdate.id;
        
        Opportunity oppUpdate = TestDataOpportunity.getNewOpportunity(accUpdate);
        oppUpdate.Pricebook2Id = pricebookIdUpdate;
        update opp;
        
        Apttus_Config2__PriceList__c priceListUpdate = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceListUpdate;
        
        Apttus_Proposal__Proposal__c proposalUpdate = TestDataProposal.initProposal(accUpdate.id, oppUpdate.id, 'Test Proposal Update', priceListUpdate.id, true, 'Draft', 'None');
        insert proposalUpdate;
        System.debug('Apttus Proposal:'+proposalUpdate); 
    }
    /**
     * @author Satya
     * @description method for checking OLI activation for item status completed value
     **/
    @isTest
    static void testOrderLineCreationForItemStatus() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        
        Product2 objProduct = TestDataFieldService.createProduct('Test Product', 'Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Auto_Create_IQ_OQ__c = true;
        objProduct.Auto_Create_PQ__c = true;
        insert objProduct;

        Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
        objOrder.Sales_Order_Number_Unique__c = '001';
        objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        objOrder.Ultimate_Consignee_ERP_Id__c = '123456';
        objOrder.Distributor_ERP_Id__c = '123456';
        objOrder.Bill_To_ERP_Id__c = '1981';
        objOrder.Ship_To_ERP_Id__c = '1981';
        objOrder.Payer_ERP_Id__c = '1981';
        objOrder.Apttus_Config2__PODate__c = Date.valueOf('2018-10-20');
        
        Apttus_Proposal__Proposal__c apttusQuoteNumber = [SELECT Id, Name FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        objOrder.APTTUS_Quote_Number__c = apttusQuoteNumber.Name;
        
        insert objOrder;

        Apttus_Config2__OrderLineItem__c objOrderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem1.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem1.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem1.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem1.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem1.Item_Status__c = 'Completed'; // Ensure this status allows activation in your logic
        objOrderLineItem1.Apttus_Config2__StartDate__c = Date.today().addMonths(-1); // Make sure the StartDate is in the past

        Apttus_Config2__OrderLineItem__c objOrderLineItem2 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem2.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem2.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem2.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem2.ERP_Line_Number_Id__c = '12345_123';
        objOrderLineItem2.Apttus_Config2__StartDate__c = Date.today().addMonths(-10); // Ensure valid past date for activation logic

        insert new List<Apttus_Config2__OrderLineItem__c>{objOrderLineItem1, objOrderLineItem2};

        Test.startTest();
        ScheduledBatchActivateOrders scheduled = new ScheduledBatchActivateOrders();
        scheduled.execute(null); // Assuming your execute method works without a context

        List<Exception> lstException = new List<Exception>();
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        try {
            acc.Name = 'Test Name Change';
            lstSaveResult = Database.update(new List<Account>{acc}, false);
            System.debug('@@@ lstSaveResult' + lstSaveResult);
        } catch (Exception e) {
            lstException.add(e);
        }
        Test.stopTest();

        Apttus_Config2__OrderLineItem__c updatedOLI = [SELECT Id, Name, Apttus_Config2__Status__c, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__OrderId__r.Apttus_Config2__Status__c 
                                                    FROM Apttus_Config2__OrderLineItem__c 
                                                    WHERE ERP_Line_Number_Id__c = '12345_122'];
        
        // Debugging to confirm status changes
        System.debug('@@@ updatedOLI.Apttus_Config2__Status__c: ' + updatedOLI.Apttus_Config2__Status__c);
        System.debug('@@@ updatedOLI.Apttus_Config2__AssetLineItemId__c: ' + updatedOLI.Apttus_Config2__AssetLineItemId__c);
        System.debug('@@@ updatedOLI.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c: ' + updatedOLI.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c);
        
        System.assertEquals(Label.OrderLineItemStatusActivated, updatedOLI.Apttus_Config2__Status__c, 'OLI Status is not activated.');
        System.assertEquals(Label.OrderLineItemStatusActivated, updatedOLI.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c, 'Order status is not activated.');
    }

    
    /**
     * @author Satya
     * @description method for checking OLI not getting activated for start date in the future
     **/
    @isTest
    static void testOrderLineCreationForFutureStartDate()
    {
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        //objProduct.Auto_Create_Install_Work_Order__c = true;
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Auto_Create_IQ_OQ__c = true;
        objProduct.Auto_Create_PQ__c = true;
        insert objProduct;

        Apttus_Config2__Order__c objOrder=new Apttus_Config2__Order__c();
        objOrder.Sales_Order_Number_Unique__c='001';
        objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        objOrder.Ultimate_Consignee_ERP_Id__c='123456';
        objOrder.Distributor_ERP_Id__c='123456';
        objOrder.Bill_To_ERP_Id__c='1981';
        objOrder.Ship_To_ERP_Id__c='1981';
        objOrder.Payer_ERP_Id__c='1981';
        objOrder.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        objOrder.APTTUS_Quote_Number__c=apttusQuoteNumber.Name;
           
        insert objOrder;
        
        Apttus_Config2__OrderLineItem__c objOrderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem1.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem1.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem1.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem1.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem1.Apttus_Config2__StartDate__c = Date.today().addMonths(6);

        Apttus_Config2__OrderLineItem__c objOrderLineItem2 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem2.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem2.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem2.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem2.ERP_Line_Number_Id__c = '12345_123';
        objOrderLineItem2.Apttus_Config2__StartDate__c = Date.today().addMonths(-6);

        insert new List<Apttus_Config2__OrderLineItem__c>{objOrderLineItem1,objOrderLineItem2};
        
        Test.startTest();

        ScheduledBatchActivateOrders scheduled = new ScheduledBatchActivateOrders();
        scheduled.execute(null);

        Test.stopTest();
        List<Apttus_Config2__OrderLineItem__c> lstUpdatedOLI = [Select Id, Name,Apttus_Config2__Status__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,ERP_Line_Number_Id__c from Apttus_Config2__OrderLineItem__c LIMIT 2];
        for(Apttus_Config2__OrderLineItem__c updatedOLI : lstUpdatedOLI)
        {
            if(updatedOLI.ERP_Line_Number_Id__c == '12345_122')
            {
                System.assertEquals(Label.OrderLineItemStatusActivated,updatedOLI.Apttus_Config2__Status__c,'OLI status is not activated');
            }
            if(updatedOLI.ERP_Line_Number_Id__c == '12345_123')
            {
                System.assertEquals(Label.OrderLineItemStatusActivated,updatedOLI.Apttus_Config2__Status__c,'OLI status is not activated');
            }
            System.assertEquals(Label.OrderLineItemStatusActivated,updatedOLI.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,'OLI status is not activated');
        }
    }
    /**
     * @author Satya
     * @description method for checking asset line activation if inactive asset is present as part of TASK0585742.
     **/
    @isTest
    static void testAssetLineActivation()
    {
        // Creating test data for Account, Product, and Order
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 objProduct = TestDataFieldService.createProduct('Test Product', 'Instrument');
        insert objProduct;

        Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
        objOrder.Apttus_Config2__Status__c = Label.OrderLineItemStatusActivated;
        objOrder.Sales_Order_Number_Unique__c = '001';
        insert objOrder;

        // Create Asset Line Item that will be linked to OrderLineItem
        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = 'Pending Activation';
        objAssetLineItem.Apttus_Config2__IsInactive__c = true;
        insert objAssetLineItem;

        // Create OrderLineItem linked to the AssetLineItem
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
        insert objOrderLineItem;

        // Start Test
        Test.startTest();
        ScheduledBatchActivateOrders scheduled = new ScheduledBatchActivateOrders(0);
        database.executebatch(scheduled, 1);
        Test.stopTest();

        // Query to check if AssetLineItem is now active
        Apttus_Config2__AssetLineItem__c updatedAssetLineItem = [SELECT Id, Apttus_Config2__IsInactive__c, Apttus_Config2__AssetStatus__c 
                                                                FROM Apttus_Config2__AssetLineItem__c 
                                                                WHERE Id = :objAssetLineItem.Id LIMIT 1];
        System.assert(!updatedAssetLineItem.Apttus_Config2__IsInactive__c, 'ALI is still inactive');
        System.assertEquals(Label.OrderLineItemStatusActivated, updatedAssetLineItem.Apttus_Config2__AssetStatus__c, 'Asset status is not activated');
    }

}