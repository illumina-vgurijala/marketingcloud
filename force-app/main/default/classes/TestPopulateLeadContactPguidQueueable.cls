/*
* @Author : Koustubh M.
* @Description : TASK0730598.
* @Date : 26th May 2022.
*/
@isTest(SeeAllData=false)
public class TestPopulateLeadContactPguidQueueable {
    public static final String REQUEST_URI = '/services/apexrest/SalesOrderSyncInterface';
    @testSetup
    static void initializeTestData()
    {
        //Test Data for account Insert
        Account acc =TestDataAccount.getAccount('TestApttusOrderDataReceiverInsert');
        acc.ERP_Customer_Id__c='123456';
        insert acc;
        System.debug('Account Insert:-'+acc);
       	Contact con = TestDataPerson.initContact(acc.Id);
        con.PGUID__c = 'qwertypoiucon';
        insert con;
        Lead ld = TestDataPerson.initLead();
        ld.PGUID__c = 'qwertypoiulead';
        insert ld;
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.Sales_Order_Number_Unique__c='00004';
        insert orders;
        System.debug('Order Insert :'+orders);
        
        Customer_Master_Data__c testCMD = new  Customer_Master_Data__c();
        testCMD.Name='TestApttusOrderDataCMD';
        testCMD.ERP_Customer_Id__c='1981';
        insert testCMD;
        System.debug('CMD Insert:-'+testCMD);
        List<Product2> lstProduct = new List<Product2>();
        
        Product2  testProduct=new Product2();
        testProduct.ProductCode='837444';
        testProduct.Material_Number__c = '837444';
        testProduct.Name='TestApttusOrderDataProduct';
        testProduct.Source_System__c='SAP';
        lstProduct.add(testProduct);
        
        insert lstProduct;
        System.debug('Product Insert:-'+lstProduct);
        
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;
        //System.assertNotEquals(null, pricebookId);
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Pricebook2Id = pricebookId;
        update opp;
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposalInsert = TestDataProposal.initProposal(acc.id, opp.id, 'TestApttusOrderDataProposal', priceList.id, true, 'Draft', 'None');
        insert proposalInsert;
        System.debug('Apttus Proposal:'+proposalInsert);
        
       Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposalInsert, testProduct);
        proposalLineItem.ERP_Line_Number_Id__c='12345123421';
        insert proposalLineItem;
        System.debug('Apttus Proposal Line Item:'+proposalLineItem);
    }

    /*
    * @Author : Gopinath Reddy
    * @Description : DCP-32166 Case Creation logic
    * @Date : 2020-12-02
    */
    static testMethod void testOrderInsertHTTPPostforCaseCreation(){
        
        List<Product2> lstProduct = new List<Product2>();
        
        Product2  testProduct=new Product2(ProductCode='8374445',Material_Number__c = '8374445',Name='TestApttusOrderDataProduct',Informatics_Family__c = 'DRAGEN',Informatics_SKU_Type__c='Subscription',Source_System__c='SAP');
        lstProduct.add(testProduct); 
        
        testProduct=new Product2(ProductCode='83744456',Material_Number__c = '83744456',Name='TestApttusOrderDataProduct',Informatics_Family__c = 'BASESPACE_CLARITY_LIMS',Informatics_SKU_Type__c='Subscription',Source_System__c='SAP');
        lstProduct.add(testProduct); 
        
        testProduct=new Product2(ProductCode='83744457',Material_Number__c = '83744457',Name='TestApttusOrderDataProduct',Informatics_Family__c = 'BASESPACE_CLARITY_LIMS',Informatics_SKU_Type__c='ADD-ON',Source_System__c='SAP');
        lstProduct.add(testProduct); 
        
        insert lstProduct;
        
        List<ApttusOrderWrapper.OrderLineItem> lstOrderLineItems=new List<ApttusOrderWrapper.OrderLineItem>();
        
       Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='TestApttusOrderDataProposal'];
       system.debug('From Proposal1: Id:-'+apttusQuoteNumber.Id+'Quotation1:-'+apttusQuoteNumber.Name);
       Apttus_Proposal__Proposal_Line_Item__c apttusQuoteLineItemNumber=[select Id,Name,ERP_Line_Number_Id__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:apttusQuoteNumber.Id];
        System.debug('My QLI -->'+apttusQuoteLineItemNumber);
       
        ApttusOrderWrapper.OrderLineItem orderlineItem1=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem1.Apttus_Config2_ProductId='8374445';
        orderlineItem1.Actual_Ship_Date='20181016';
        orderlineItem1.Item_status='Completed';
        orderlineItem1.Reason_For_Rejection='Completed';
       	orderlineItem1.Registrant_Lead = 'qwertypoiulead';
        orderlineItem1.ERP_Line_Number_Id='789654';
        orderlineItem1.Custom_License_Flag = false;
        orderlineItem1.Dragen_Connectivity='Offline';
        //orderlineItem1.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        ApttusOrderWrapper.OrderLineItem orderlineItem2=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem2.Apttus_Config2_ProductId='8374445';
        orderlineItem2.Actual_Ship_Date='20181016';
        orderlineItem2.Item_status='Completed';
        orderlineItem2.Reason_For_Rejection='Completed';
        orderlineItem2.Registrant_Lead = 'qwertypoiulead';
        orderlineItem2.ERP_Line_Number_Id='232425';
        orderLineItem2.Custom_License_Flag = true;
        orderlineItem2.Registrant_Contact = 'qwertypoiucon';
       // orderlineItem2.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;

        ApttusOrderWrapper.OrderLineItem orderlineItem3=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem3.Apttus_Config2_ProductId='83744456';
        orderlineItem3.Actual_Ship_Date='20181016';
        orderlineItem3.Item_status='Completed';
        orderlineItem3.Reason_For_Rejection='Completed';
        orderlineItem3.Registrant_Lead = 'qwertypoiulead';
        orderlineItem3.ERP_Line_Number_Id='12345123421';
        orderLineItem3.Custom_License_Flag = true;
        //orderlineItem3.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        ApttusOrderWrapper.OrderLineItem orderlineItem4=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem4.Apttus_Config2_ProductId='83744457';
        orderlineItem4.Actual_Ship_Date='20181016';
        orderlineItem4.Item_status='Completed';
        orderlineItem4.Reason_For_Rejection='Completed';
        orderlineItem4.Registrant_Lead = 'qwertypoiulead';
        orderlineItem4.ERP_Line_Number_Id='232425267';
        orderLineItem4.Custom_License_Flag = true;
        //orderlineItem4.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        lstOrderLineItems.add(orderlineItem1);
        lstOrderLineItems.add(orderlineItem2);
        lstOrderLineItems.add(orderlineItem3);
        lstOrderLineItems.add(orderlineItem4);

        ApttusOrderWrapper.Order order2=new ApttusOrderWrapper.Order();
        order2.Apttus_Config2_SoldToAccountId='123456';
        order2.Ultimate_Consignee='123456';
        order2.Distributor='123456';
        order2.Apttus_Config2_OrderReferenceNumber='1741';
        order2.Bill_To='1981';
        order2.Ship_To='1981';
        order2.Payer='1981';
        order2.Order_status='partial';
        
        order2.ASOP_Number='00005';
        //order2.Apttus_Config2_RelatedOpportunityId=apttusQuoteNumber.Apttus_Proposal__Opportunity__c;
        //order2.Apttus_QPConfig_ProposalId=apttusQuoteNumber.Name;
        order2.orderLineItem =new List<ApttusOrderWrapper.OrderLineItem>();
        order2.orderLineItem.addAll(lstOrderLineItems);
        
        String orderJSON = JSON.serialize(order2);
         
        system.debug('My JNON Value -->'+orderJSON);

        User integrationSnapSalesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_INTEGRATION_SNAP_SALES);

        
        System.runAs(integrationSnapSalesUser){
            Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/SalesOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(orderJSON);
            RestContext.request = req;
            RestContext.response= res;
            ApttusOrderDataReceiver.upsertIncomingValues();
            Test.stopTest();
        }
        
        Apttus_Config2__OrderLineItem__c olic1 = [SELECT Case_Id__c,Renewal_Subscription__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = :orderlineItem1.ERP_Line_Number_Id];
        Apttus_Config2__OrderLineItem__c olic2 = [SELECT Case_Id__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = :orderlineItem2.ERP_Line_Number_Id];
        Apttus_Config2__OrderLineItem__c olic3 = [SELECT Case_Id__c,Renewal_Subscription__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = :orderlineItem3.ERP_Line_Number_Id];
        Apttus_Config2__OrderLineItem__c olic4 = [SELECT Case_Id__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = :orderlineItem4.ERP_Line_Number_Id];
        System.debug('My OLI 3-->'+olic3);
        System.debug('My OLI 4-->'+olic4);

        System.assert(String.IsNotBlank(olic1.Case_Id__c),'OLI 1 Case id is not populating' );
        System.assert(String.IsNotBlank(olic2.Case_Id__c),'OLI 2 Case id is not populating' );
        System.assert(String.IsNotBlank(olic3.Case_Id__c),'OLI 3 Case id is not populating' );
        System.assert(String.IsNotBlank(olic4.Case_Id__c),'OLI 4 Case id is not populating' );
        
        
        Case case1 = [SELECT Next_Steps__c FROM Case WHERE id = :olic1.Case_Id__c];
        Case case2 = [SELECT Next_Steps__c FROM Case WHERE id = :olic2.Case_Id__c];
        Case case3 = [SELECT Description FROM Case WHERE id = :olic3.Case_Id__c];
        Case case4 = [SELECT Description FROM Case WHERE id = :olic4.Case_Id__c];
        System.debug('case1 ---> ' + case1);
        System.debug('case2 ---> ' + case2);
        System.debug('case3 ---> ' + case3);
        System.debug('case4 ---> ' + case4);
        System.assert(case1.Next_Steps__c.contains('Server Connectivity'), 'Case 1 is not getting created or doesnt have required values');
        System.assert(case2.Next_Steps__c.contains('Please review custom software license setup request'),'Case 2 is not getting created or doesnt have required values');
        System.assert(case3.Description.contains('Instances to be provisioned:'), 'Case 3 is not getting created or doesnt have required values');
        System.assert(case4.Description.contains('Add-On Quantity'), 'Case 4 is not getting created or doesnt have required values');
    }
}