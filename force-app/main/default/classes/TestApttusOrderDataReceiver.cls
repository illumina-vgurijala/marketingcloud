/*
* @Author : Sravan Panchangam
* @Description : DCP-13048 Sales Order Sync
* @Date : 2018-10-10
Modification Log:
*       -------------------------------------------------------------------------------------
*       Prem Ranjan         04 May 2022             CodeScan Fix (APEX) Unused Local Variable.
*       -------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class TestApttusOrderDataReceiver {
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
            cases.skipCaseTrigger = true; //Test Class fix 
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
    
   static testMethod void testOrderInsertHTTPPost(){
        
        List<ApttusOrderWrapper.OrderLineItem> lstOrderLineItems=new List<ApttusOrderWrapper.OrderLineItem>();
       
       Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='TestApttusOrderDataProposal'];
       system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        
       
        ApttusOrderWrapper.OrderLineItem orderlineItem1=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem1.Apttus_Config2_ProductId='837444';
        orderlineItem1.Actual_Ship_Date='20181016';
        orderlineItem1.Item_status='Completed';
        orderlineItem1.ERP_Line_Number_Id='789654';
        orderlineItem1.Reason_For_Rejection='Completed';
       	orderlineItem1.Registrant_Lead = 'qwertypoiulead';
        orderlineItem1.Custom_License_Flag = true;
        Apttus_Proposal__Proposal_Line_Item__c apttusQuoteLineItemNumber=[select Id,Name from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:apttusQuoteNumber.Id];
        orderlineItem1.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        ApttusOrderWrapper.OrderLineItem orderlineItem2=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem2.Apttus_Config2_ProductId='837444';
        orderlineItem2.ERP_Line_Number_Id='232425';
        orderlineItem2.Reason_For_Rejection='Cancelled';
        orderlineItem2.Registrant_Contact = 'qwertypoiucon';
        orderlineItem2.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
       
        orderlineItem2.Custom_License_Flag = true;
        ApttusOrderWrapper.OrderLineItem orderlineItem3=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem3.Apttus_Config2_ProductId='837444';
        orderlineItem3.Actual_Ship_Date='20181016';
        orderlineItem3.Item_status='Completed';
        orderlineItem3.ERP_Line_Number_Id='23242526';
       	orderlineItem3.Reason_For_Rejection='Cancelled';
           orderlineItem3.Custom_License_Flag = true;
        orderlineItem3.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        lstOrderLineItems.add(orderlineItem1);
        lstOrderLineItems.add(orderlineItem2);
        
        ApttusOrderWrapper.Order order1=new ApttusOrderWrapper.Order();
        order1.Apttus_Config2_SoldToAccountId='123456';
        order1.Ultimate_Consignee='123456';
        order1.Distributor='123456';
        order1.Apttus_Config2_OrderReferenceNumber='1741';
        order1.Bill_To='1981';
        order1.Ship_To='1981';
        order1.Payer='1981';
        order1.Order_status='partial';
        
        order1.ASOP_Number='00004';
       // order1.Sales_Order_Number_Unique=
        order1.Apttus_Config2_RelatedOpportunityId=apttusQuoteNumber.Apttus_Proposal__Opportunity__c;
        order1.Apttus_QPConfig_ProposalId=apttusQuoteNumber.Name;
        order1.orderLineItem =new List<ApttusOrderWrapper.OrderLineItem>();
        order1.orderLineItem.addAll(lstOrderLineItems);
             
        String orderJSON = JSON.serialize(order1);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = REQUEST_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(orderJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrderDataReceiver.upsertIncomingValues();
        Test.stopTest();
        System.assertequals(200,res.statuscode,'status code should be 200');
        List<Apttus_Config2__Order__c> orderRetrieve=new List<Apttus_Config2__Order__c>();
         orderRetrieve= [select Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,Bill_To__c,Ship_To__c,	Payer__c,Distributor__c,Apttus_QPConfig__ProposalId__c,Apttus_Config2__RelatedOpportunityId__c from Apttus_Config2__Order__c where Sales_Order_Number_Unique__c='1741'];
        
        Account accRetrieve =[select id from Account where ERP_Customer_Id__c='123456'];
        Customer_Master_Data__c cmdRetrieve=[select id from Customer_Master_Data__c where ERP_Customer_Id__c='1981'];
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemRetrieve=new List<Apttus_Config2__OrderLineItem__c>();
        orderLineItemRetrieve=[select Apttus_Config2__ProductId__c,Apttus_QPConfig__ProposalLineItemId__c,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Item_Status__c='Completed'];
        Apttus_Config2__OrderLineItem__c oliRetrieveCon = [SELECT Registrant_Contact__c, Registrant_Lead__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = '232425'];
        Apttus_Config2__OrderLineItem__c oliRetrieveLead = [SELECT Registrant_Contact__c, Registrant_Lead__c from Apttus_Config2__OrderLineItem__c where ERP_Line_Number_Id__c = '789654'];
        Contact con = [SELECT id from Contact limit 1];
        Lead ld = [SELECT id from Lead limit 1];
        System.assertEquals(con.Id, oliRetrieveCon.Registrant_Contact__c,'contact id should match');
        System.assertEquals(ld.Id, oliRetrieveLead.Registrant_Lead__c,'lead id should match');
        Product2 productRetrieve=[select ProductCode,Material_Number__c from Product2 where ProductCode='837444'];
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode,'status code should be 200');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Apttus_Config2__SoldToAccountId__c,'sold to id should match');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Ultimate_Consignee__c,'UC should match');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Distributor__c,'Distributor should match');
       
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Bill_To__c,'bill to should match');
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Ship_To__c,' ship to should match');
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Payer__c,' payer should match');
        
        //System.assertEquals(apttusQuoteNumber.Id,orderRetrieve[0].Apttus_QPConfig__ProposalId__c);
        System.assertEquals(productRetrieve.Id, orderLineItemRetrieve[0].Apttus_Config2__ProductId__c,'product id should match');
        System.assertEquals(apttusQuoteLineItemNumber.Id, orderLineItemRetrieve[0].Apttus_QPConfig__ProposalLineItemId__c,'proposal lineitem id should match');
        //System.assertNotEquals(null, orderLineItemRetrieve[0].Apttus_Config2__AssetLineItemId__c);
    }
	static testMethod void testOrderUpdateHTTPPost(){
                
        Apttus_Config2__Order__c ordersUpdated=new Apttus_Config2__Order__c();
        ordersUpdated.Apttus_Config2__OrderReferenceNumber__c= '1741';
        ordersUpdated.Sales_Order_Number_Unique__c='000093090';
        ordersUpdated.Apttus_Config2__Type__c= 'Standard Order';
        ordersUpdated.Order_Reason__c   =   null;   
        ordersUpdated.ERP_Quote_Number__c = '';
        ordersUpdated.Apttus_Config2__PONumber__c = '';
        ordersUpdated.Apttus_Config2__PODate__c =  null;
        ordersUpdated.Contract_Review_Status__c = '';
        ordersUpdated.Total_Price__c = 9828.00;
        ordersUpdated.Total_Price_USD__c = 9828.00;
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ship_To_ERP_Id__c = '123456' ;
        ordersUpdated.Bill_To_ERP_Id__c = '';
        ordersUpdated.Payer_ERP_Id__c = '';
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ultimate_Consignee_ERP_Id__c = '123456';
        ordersUpdated.Distributor_ERP_Id__c = '';
        ordersUpdated.PO_Type__c = '';
        ordersUpdated.Order_Status__c = '';
        ordersUpdated.Sales_Order_Number_Unique__c = '1741';
        ordersUpdated.Contact_Name__c = 'Contact person.' ;
        ordersUpdated.ASOP_Number__c = '0002398765';
        ordersUpdated.Apttus_Config2__ActivatedDate__c = System.now();
        ordersUpdated.Apttus_Config2__Status__c  = 'Activated';
        insert ordersUpdated;
        
        Apttus_Config2__OrderLineItem__c orderLinesUpdated=new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c= '789654',Apttus_Config2__StartDate__c= System.today(),Apttus_Config2__EndDate__c= System.today().addDays(140),Apttus_Config2__Quantity__c   =   null,Apttus_Config2__OrderId__c = ordersUpdated.id,Item_Status__c = null,Apttus_Config2__Status__c  = 'Activated',Custom_License_Flag__c = true);
        //orderLinesUpdated.Software_Id__c = '';
        insert orderLinesUpdated;
        
        Apttus_Config2__OrderLineItem__c orderLinesUpdated2=new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c= '789656',Apttus_Config2__StartDate__c= System.today(),Apttus_Config2__EndDate__c= System.today().addDays(140),Apttus_Config2__Quantity__c  =   null,Apttus_Config2__OrderId__c = ordersUpdated.id,Item_Status__c = 'Completed',Apttus_Config2__Status__c     = 'Activated',Custom_License_Flag__c = true);
        //orderLinesUpdated2.Software_Id__c = '';
        insert orderLinesUpdated2;
        
        
        
        List<ApttusOrderWrapper.OrderLineItem> lstOrderLineItems=new List<ApttusOrderWrapper.OrderLineItem>();
       
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='TestApttusOrderDataProposal'];
        system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        
       
        ApttusOrderWrapper.OrderLineItem orderlineItem1=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem1.Apttus_Config2_ProductId='837444';
        orderlineItem1.Actual_Ship_Date='20181016';
        orderlineItem1.ERP_Line_Number_Id='789654';
        orderlineItem1.SVMXC_Start_Date='20190116';
        orderlineItem1.SVMXC_End_Date='20190625';
        orderlineItem1.Item_Status= null;
        orderlineItem1.SVMXC_Service_Plan = 'ServicePlan';
        orderlineItem1.Custom_License_Flag = true;
        Apttus_Proposal__Proposal_Line_Item__c apttusQuoteLineItemNumber=[select Id,Name from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:apttusQuoteNumber.Id];
        orderlineItem1.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        ApttusOrderWrapper.OrderLineItem orderlineItem2=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem2.Apttus_Config2_ProductId='837444';
        orderlineItem2.Actual_Ship_Date='20181016';
        orderlineItem2.ERP_Line_Number_Id='789656';
        orderlineItem2.SVMXC_Start_Date='20190116';
        orderlineItem2.SVMXC_End_Date='20190625';
        orderlineItem2.Item_Status='Completed';
        orderlineItem2.Custom_License_Flag = true;
        orderlineItem2.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        
        
        lstOrderLineItems.add(orderlineItem1);
        lstOrderLineItems.add(orderlineItem2);
        
        ApttusOrderWrapper.Order order1=new ApttusOrderWrapper.Order();
        order1.Apttus_Config2_SoldToAccountId='123456';
        order1.Ultimate_Consignee='123456';
        order1.Distributor='123456';
        order1.Apttus_Config2_OrderReferenceNumber='1741';
        order1.Bill_To='1981';
        order1.Ship_To='1981';
        order1.Payer='1981';
        order1.Payer='1981';
        order1.Order_status='partial';
        order1.ASOP_Number='00004';
       // order1.Sales_Order_Number_Unique=
        
        order1.Apttus_QPConfig_ProposalId=apttusQuoteNumber.Name;
        order1.Apttus_Config2_RelatedOpportunityId=apttusQuoteNumber.Apttus_Proposal__Opportunity__c;
        order1.orderLineItem =new List<ApttusOrderWrapper.OrderLineItem>();
        order1.orderLineItem.addAll(lstOrderLineItems);
             
        String orderJSON = JSON.serialize(order1);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = REQUEST_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(orderJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrderDataReceiver.upsertIncomingValues();
        Test.stopTest();
        System.assertequals(200,res.statuscode,'status code should match');
        List<Apttus_Config2__Order__c> orderRetrieve=new List<Apttus_Config2__Order__c>();
         orderRetrieve= [select Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,Bill_To__c,Ship_To__c, Payer__c,Distributor__c,Apttus_QPConfig__ProposalId__c,Apttus_Config2__RelatedOpportunityId__c from Apttus_Config2__Order__c where Sales_Order_Number_Unique__c='1741'];
        
        Account accRetrieve =[select id from Account where ERP_Customer_Id__c='123456'];
        Customer_Master_Data__c cmdRetrieve=[select id from Customer_Master_Data__c where ERP_Customer_Id__c='1981'];
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemRetrieve=new List<Apttus_Config2__OrderLineItem__c>();
        orderLineItemRetrieve=[select Apttus_Config2__ProductId__c,Apttus_QPConfig__ProposalLineItemId__c,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Item_Status__c='Completed'];
        
        Product2 productRetrieve=[select ProductCode,Material_Number__c from Product2 where ProductCode='837444'];
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode,'status code should match');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Apttus_Config2__SoldToAccountId__c,'sold to should match');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Ultimate_Consignee__c,'UC should match');
        System.assertEquals(accRetrieve.Id,orderRetrieve[0].Distributor__c,' Distributor should match');
       
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Bill_To__c,'bill to should match');
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Ship_To__c,' ship to should match');
        System.assertEquals(cmdRetrieve.Id, orderRetrieve[0].Payer__c,'payer should match');
        
        //System.assertEquals(apttusQuoteNumber.Id,orderRetrieve[0].Apttus_QPConfig__ProposalId__c);
        System.assertEquals(productRetrieve.Id, orderLineItemRetrieve[0].Apttus_Config2__ProductId__c,' product id should match');
        System.assertEquals(apttusQuoteLineItemNumber.Id, orderLineItemRetrieve[0].Apttus_QPConfig__ProposalLineItemId__c,' proposal id should match');
    }
    static testMethod void testOrderUpsertHTTPPost(){
        
        Account acc =[select Id,Name from Account where ERP_Customer_Id__c='123456'];
        
        
        Apttus_Config2__Order__c ordersUpdated=new Apttus_Config2__Order__c(Order_Reason__c   =   null,Apttus_Config2__Type__c= 'Standard Order',Apttus_Config2__OrderReferenceNumber__c= '1741',Sales_Order_Number_Unique__c='000093090');
        ordersUpdated.ERP_Quote_Number__c = '';
        ordersUpdated.Apttus_Config2__PONumber__c = '';
        ordersUpdated.Apttus_Config2__PODate__c =  null;
        ordersUpdated.Contract_Review_Status__c = '';
        ordersUpdated.Total_Price__c = 9828.00;
        ordersUpdated.Total_Price_USD__c = 9828.00;
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ship_To_ERP_Id__c = '123456' ;
        ordersUpdated.Bill_To_ERP_Id__c = '';
        ordersUpdated.Payer_ERP_Id__c = '';
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ultimate_Consignee_ERP_Id__c = '123456';
        ordersUpdated.Distributor_ERP_Id__c = '';
        ordersUpdated.PO_Type__c = '';
        ordersUpdated.Order_Status__c = '';
        ordersUpdated.Sales_Order_Number_Unique__c = '1741';
        ordersUpdated.Contact_Name__c = 'Contact person.' ;
        ordersUpdated.ASOP_Number__c = '0002398765';
        ordersUpdated.Apttus_Config2__ActivatedDate__c = System.now();
        insert ordersUpdated;
        
        Apttus_Config2__OrderLineItem__c orderLinesUpdated=new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c= '789654',Apttus_Config2__StartDate__c= System.today().addDays(12),Apttus_Config2__EndDate__c= System.today().addDays(140),Apttus_Config2__Quantity__c   =   null,Custom_License_Flag__c = true,Apttus_Config2__OrderId__c = ordersUpdated.id,Item_Status__c = null,Apttus_Config2__Status__c  = 'Pending');
        insert orderLinesUpdated;
        
        List<ApttusOrderWrapper.OrderLineItem> lstOrderLineItems=new List<ApttusOrderWrapper.OrderLineItem>();
       
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='TestApttusOrderDataProposal'];
        system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        
       
        ApttusOrderWrapper.OrderLineItem orderlineItem1=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem1.Apttus_Config2_ProductId='837444';
        orderlineItem1.Actual_Ship_Date='20181016';
        orderlineItem1.ERP_Line_Number_Id='789654';
        orderlineItem1.SVMXC_Start_Date='20190120';
        orderlineItem1.SVMXC_End_Date='20190625';
        orderlineItem1.Item_Status= null;
        orderlineItem1.SVMXC_Service_Plan = 'ServicePlan';
        orderlineItem1.Custom_License_Flag = true;
        Apttus_Proposal__Proposal_Line_Item__c apttusQuoteLineItemNumber=[select Id,Name from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:apttusQuoteNumber.Id];
        orderlineItem1.Apttus_QPConfig_ProposalLineItemId=apttusQuoteLineItemNumber.Name;
        
        
        lstOrderLineItems.add(orderlineItem1);
        
        ApttusOrderWrapper.Order order1=new ApttusOrderWrapper.Order();
        order1.Apttus_Config2_SoldToAccountId='123456';
        order1.Ultimate_Consignee='123456';
        order1.Distributor='123456';
        order1.Apttus_Config2_OrderReferenceNumber='1741';
        order1.Bill_To='1981';
        order1.Ship_To='1981';
        order1.Payer='1981';
        order1.Payer='1981';
        order1.Order_status='partial';
        order1.ASOP_Number='00004';
        
        order1.Apttus_QPConfig_ProposalId=apttusQuoteNumber.Name;
        order1.Apttus_Config2_RelatedOpportunityId=apttusQuoteNumber.Apttus_Proposal__Opportunity__c;
        order1.orderLineItem =new List<ApttusOrderWrapper.OrderLineItem>();
        order1.orderLineItem.addAll(lstOrderLineItems);
             
        String orderJSON = JSON.serialize(order1);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = REQUEST_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(orderJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrderDataReceiver.upsertIncomingValues();
        Test.stopTest();
        
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode,' status code should match');
        
        List<Apttus_Config2__OrderLineItem__c> lstOLIs = new ApttusOrderLineItemsSelector().fetchLinesBySalesOrderNumber(new Set<String>{'1741'});
        System.assertEquals(1,lstOLIs.size(),'Incorrect line items');
        Apttus_Config2__OrderLineItem__c objOLI = lstOLIs[0];
        Apttus_Config2__AssetLineItem__c objAssetLine =  new Apttus_Config2__AssetLineItem__c(Apttus_Config2__AccountId__c=acc.Id);
        insert objAssetLine;
        objOLI.Apttus_Config2__AssetLineItemId__c=objAssetLine.Id;
        update objOLI;

        orderlineItem1.Equipment_Id='123Equip';
        orderJSON = JSON.serialize(order1);
        System.debug('Order JSON updated: ' + orderJSON);
        req = new RestRequest(); 
        res = new RestResponse();
        req.requestURI = REQUEST_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(orderJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrderDataReceiver.upsertIncomingValues(); //in header level activation, new orderlineitem that is added to already existing order does not get activated and asset does not get created for it. Asset has to be manually created.
        List<Apttus_Config2__OrderLineItem__c> oliToActivate = new ApttusOrderLineItemsSelector().fetchLinesWithInactiveAssetsByIds(new set<Id>{ordersUpdated.Id});
        system.debug('oliToActivate: '+oliToActivate);
        List<Apttus_Config2__Order__c> orderActivate = new ApttusOrdersSelector().fetchOrdersbySalesOrderUnique(new set<String>{'1234'});
        system.debug('orderActivate: '+orderActivate);
        try{
            Apttus_Config2__Order__c orderActivate2 = new ApttusOrdersSelector().fetchRecordForSalesOrderNumber('1234');
            system.debug('orderActivate2: '+orderActivate2);
        }catch(exception e){
            system.debug(e);
        }
        List<Apttus_Config2__Order__c> orderActivate3 = new ApttusOrdersSelector().selectOrdersBySoldToAndUC(new set<Id>{acc.Id});
        system.debug('orderActivate3: '+orderActivate3);
        List<Apttus_Config2__AssetLineItem__c> aliActivate = new ApttusAssetLineItemsSelector().selectAssetsByAccounts(new set<Id>{acc.Id});
        system.debug('aliActivate: '+aliActivate);
        List<Apttus_Config2__AssetLineItem__c> aliActivate2 = new ApttusAssetLineItemsSelector().selectAssetsByUC(new set<Id>{acc.Id});
        system.debug('aliActivate2: '+aliActivate2);
        List<Apttus_Config2__AssetLineItem__c> aliActivate3 = new ApttusAssetLineItemsSelector().selectById(new set<Id>{objAssetLine.Id});
        system.debug('aliActivate3: '+aliActivate3);

        System.assertEquals(200,res.statuscode,'Response is not successful');
    } 
    
   static testMethod void testApttusOrderInsertHTTPPostRestError(){
        // invalid JSON with quote number only
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='TestApttusOrderDataProposal']; 
        List<ApttusOrderWrapper.OrderLineItem> lstOrderLineItems=new List<ApttusOrderWrapper.OrderLineItem>();
        
        ApttusOrderWrapper.OrderLineItem orderlineItem1=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem1.Apttus_Config2_ProductId='837444';
        orderlineItem1.Actual_Ship_Date='20181016';
        
        
        ApttusOrderWrapper.OrderLineItem orderlineItem2=new ApttusOrderWrapper.OrderLineItem();
        orderlineItem2.Apttus_Config2_ProductId='837444';
        
        
        
        lstOrderLineItems.add(orderlineItem1);
        lstOrderLineItems.add(orderlineItem2);
        
        ApttusOrderWrapper.Order order1=new ApttusOrderWrapper.Order();
        order1.Apttus_Config2_SoldToAccountId='123456';
        order1.Ultimate_Consignee='123456';
        order1.Distributor='123456';
        order1.Apttus_Config2_OrderReferenceNumber='1741';
        order1.Bill_To='1981';
        order1.Ship_To='1981';
        order1.Payer='1981';
        order1.Payer='1981';
        order1.Order_status='partial';
        order1.ASOP_Number='00004';
       // order1.Sales_Order_Number_Unique=
        
        order1.Apttus_QPConfig_ProposalId=apttusQuoteNumber.Name;
        order1.Apttus_Config2_RelatedOpportunityId=apttusQuoteNumber.Apttus_Proposal__Opportunity__c;
        order1.orderLineItem =new List<ApttusOrderWrapper.OrderLineItem>();
        order1.orderLineItem.addAll(lstOrderLineItems);
        
        String orderJSON = JSON.serialize(order1);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = REQUEST_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(orderJSON);
        RestContext.request = req;
        RestContext.response= res;
        ApttusOrderDataReceiver.upsertIncomingValues();
        Test.stopTest();
		System.assert(res.statuscode != 200,'Response is successful');
        
    }
}