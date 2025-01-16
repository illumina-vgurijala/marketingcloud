/*
 * @Author: Sravan Panchangam
 * @Description: DCP-9865,14870 Test class for ApttusOrders
*/
@isTest(SeeAllData=false)
public class TestApttusOrders {
    
    @testSetup
    static void initializeTestData()
    {
        //Test Data for account Insert
        Account acc =TestDataAccount.getAccount('TestAccountApttusOrderInsert');
        acc.ERP_Customer_Id__c='123456';
        insert acc;
        System.debug('Account Insert:-'+acc);
        
        //Test Data for account Update
        Account accUpdate =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        accUpdate.ERP_Customer_Id__c='654321';
        insert accUpdate;
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
        //System.assertNotEquals(null, pricebookId);
        
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
        //System.assertNotEquals(null, pricebookId);
        
        Opportunity oppUpdate = TestDataOpportunity.getNewOpportunity(accUpdate);
        oppUpdate.Pricebook2Id = pricebookIdUpdate;
        update opp;
        
        Apttus_Config2__PriceList__c priceListUpdate = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceListUpdate;
        
        Apttus_Proposal__Proposal__c proposalUpdate = TestDataProposal.initProposal(accUpdate.id, oppUpdate.id, 'Test Proposal Update', priceListUpdate.id, true, 'Draft', 'None');
        insert proposalUpdate;
        System.debug('Apttus Proposal:'+proposalUpdate);
    }

   static testMethod void insertApttusOrder(){
        
        List<Apttus_Config2__Order__c> lstOrders = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
       // orders.ASOP_Number__c='0001';
        orders.Sales_Order_Number_Unique__c='001';
        orders.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        orders.Ultimate_Consignee_ERP_Id__c='123456';
        orders.Distributor_ERP_Id__c='123456';
        orders.Bill_To_ERP_Id__c='1981';
        orders.Ship_To_ERP_Id__c='1981';
        orders.Payer_ERP_Id__c='1981';
        orders.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        orders.APTTUS_Quote_Number__c=apttusQuoteNumber.Name;
        lstOrders.add(orders);
        Test.startTest();
        insert orders;
        Test.stopTest();
        Apttus_Config2__Order__c orderRetrieve= [select Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,Apttus_QPConfig__ProposalId__c from Apttus_Config2__Order__c LIMIT 1];
        Account accRetrieve =[select id from Account where ERP_Customer_Id__c='123456'];
        System.debug('Account Id:'+accRetrieve.id+'Ultimate Consignee :'+orderRetrieve.Ultimate_Consignee__c+'Sold TO :'+orderRetrieve.Apttus_Config2__SoldToAccountId__c);
        System.assertEquals(accRetrieve.id, orderRetrieve.Ultimate_Consignee__c);
        System.assertEquals(accRetrieve.id, orderRetrieve.Apttus_Config2__SoldToAccountId__c);
       System.assertEquals(apttusQuoteNumber.Id,orderRetrieve.Apttus_QPConfig__ProposalId__c);
    }

    static testMethod void insertMultipleApttusOrder(){
        
        List<Apttus_Config2__Order__c> lstOrders = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
       // orders.ASOP_Number__c='0001';
        orders.Sales_Order_Number_Unique__c='001';
        orders.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        orders.Ultimate_Consignee_ERP_Id__c='123456';
        orders.Distributor_ERP_Id__c='123456';
        orders.Bill_To_ERP_Id__c='1981';
        orders.Ship_To_ERP_Id__c='1981';
        orders.Payer_ERP_Id__c='1981';
        orders.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        system.debug('From Proposal: Id:-'+apttusQuoteNumber.Id+'Quotation:-'+apttusQuoteNumber.Name);
        orders.APTTUS_Quote_Number__c=apttusQuoteNumber.Name;

        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
       // orders.ASOP_Number__c='0001';
        orders1.Sales_Order_Number_Unique__c='002';
        orders1.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        orders1.Ultimate_Consignee_ERP_Id__c='123456';
        orders1.Distributor_ERP_Id__c='123456';
        orders1.Bill_To_ERP_Id__c='1981';
        orders1.Ship_To_ERP_Id__c='1981';
        orders1.Payer_ERP_Id__c='1981';
        orders1.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        orders1.APTTUS_Quote_Number__c=apttusQuoteNumber.Name;

        lstOrders.add(orders);
        lstOrders.add(orders1);
        Test.startTest();
        insert lstOrders;
        Test.stopTest();
        Apttus_Config2__Order__c orderRetrieve= [select Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,Apttus_QPConfig__ProposalId__c from Apttus_Config2__Order__c LIMIT 1];
        Account accRetrieve =[select id from Account where ERP_Customer_Id__c='123456'];
        System.debug('Account Id:'+accRetrieve.id+'Ultimate Consignee :'+orderRetrieve.Ultimate_Consignee__c+'Sold TO :'+orderRetrieve.Apttus_Config2__SoldToAccountId__c);
        System.assertEquals(accRetrieve.id, orderRetrieve.Ultimate_Consignee__c);
        System.assertEquals(accRetrieve.id, orderRetrieve.Apttus_Config2__SoldToAccountId__c);
       System.assertEquals(apttusQuoteNumber.Id,orderRetrieve.Apttus_QPConfig__ProposalId__c);
    }
    
    static testMethod void wrongERPidOrder(){
        Apttus_Proposal__Proposal__c apttusQuoteNumber=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
       // orders.ASOP_Number__c='0001';
        orders1.Sales_Order_Number_Unique__c='002';
        orders1.Apttus_Config2_SoldToAccountId_ERP_Id__c='1234569';
        orders1.Ultimate_Consignee_ERP_Id__c='1234569';
        orders1.Distributor_ERP_Id__c='1234569';
        orders1.Bill_To_ERP_Id__c='1981';
        orders1.Ship_To_ERP_Id__c='1981';
        orders1.Payer_ERP_Id__c='1981';
        orders1.Apttus_Config2__PODate__c=Date.valueOf('2017-10-20');
        orders1.APTTUS_Quote_Number__c=apttusQuoteNumber.Name;
        Test.startTest();
        insert orders1;
        Test.stopTest();
        System.assertEquals(apttusQuoteNumber.Name,orders1.APTTUS_Quote_Number__c, 'Quote Number copied incorrectly');
    }
    
    static testMethod void updateApttusOrder(){
       //Inserting a new Order 
        Apttus_Config2__Order__c ordersUpdated=new Apttus_Config2__Order__c();
       // ordersUpdated.ASOP_Number__c='0002';
        ordersUpdated.Sales_Order_Number_Unique__c='0002';
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        ordersUpdated.Ultimate_Consignee_ERP_Id__c='123456';
        ordersUpdated.Apttus_Config2__PODate__c=Date.valueOf('2018-10-30');
        ordersUpdated.Apttus_Config2__PONumber__c='76543';
        insert ordersUpdated;
        
        
        Apttus_Config2__Order__c orderRetrieveUpdate= [select Apttus_Config2_SoldToAccountId_ERP_Id__c,Ultimate_Consignee_ERP_Id__c,Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,ERP_Quote_Number__c,Apttus_QPConfig__ProposalId__c,ASOP_Number__c,APTTUS_Quote_Number__c from Apttus_Config2__Order__c where Sales_Order_Number_Unique__c='0002'];
        
        System.debug('Previous Order Ultimate ERP :-'+orderRetrieveUpdate.Ultimate_Consignee_ERP_Id__c+'Soldto:-'+orderRetrieveUpdate.Apttus_Config2_SoldToAccountId_ERP_Id__c+'erp Quote Number:-'+orderRetrieveUpdate.APTTUS_Quote_Number__c+'ProposalId:-'+orderRetrieveUpdate.Apttus_QPConfig__ProposalId__c);
        //Retrieving and updating the earlier order with new Ultimate_Consignee_ERP_Id__c ,Apttus_Config2_SoldToAccountId_ERP_Id__c ,ERP_Quote_Number__c
        orderRetrieveUpdate.Ultimate_Consignee_ERP_Id__c='654321';
        orderRetrieveUpdate.Apttus_Config2_SoldToAccountId_ERP_Id__c='654321'; 
        Apttus_Proposal__Proposal__c apttusQuoteNumberUpdate=[select Id,Name from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c='Test Proposal Update'];
        orderRetrieveUpdate.APTTUS_Quote_Number__c=apttusQuoteNumberUpdate.Name;
       	Test.startTest();
        update orderRetrieveUpdate;
        Test.stopTest();
        
        Account accRetrieveUpdate =[select id from Account where ERP_Customer_Id__c='654321'];
        Apttus_Config2__Order__c orderUpdated= [select Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c,Apttus_Config2_SoldToAccountId_ERP_Id__c,Ultimate_Consignee_ERP_Id__c,Apttus_QPConfig__ProposalId__c,APTTUS_Quote_Number__c from Apttus_Config2__Order__c where Sales_Order_Number_Unique__c='0002'];
       
        System.debug('From Update after update: ultimate consignee: '+orderUpdated.Ultimate_Consignee_ERP_Id__c+'SoldTOAccountId :'+orderUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c+'ERPQuoteNumber:'+orderUpdated.APTTUS_Quote_Number__c+'ProposalId:-'+orderUpdated.Apttus_QPConfig__ProposalId__c);
        System.debug('Account Id:'+accRetrieveUpdate.Id+'Ultimate Consignee :'+orderUpdated.Ultimate_Consignee__c+'Sold TO :'+orderUpdated.Apttus_Config2__SoldToAccountId__c);
        System.debug('After Update ERPQuoteNumber'+apttusQuoteNumberUpdate.Id+'ProposalId'+orderUpdated.Apttus_QPConfig__ProposalId__c);
        System.assertEquals(accRetrieveUpdate.Id, orderUpdated.Apttus_Config2__SoldToAccountId__c);
        System.assertEquals(accRetrieveUpdate.Id, orderUpdated.Ultimate_Consignee__c);
        System.assertEquals(apttusQuoteNumberUpdate.Id, orderUpdated.Apttus_QPConfig__ProposalId__c);
        orderUpdated.Ultimate_Consignee__c = null;
        update orderUpdated;        

    }

    static testMethod void populateContactOpportunityAndPOData(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'Contact',
        Bypass_Triggers_By_Object_3__c = 'Opportunity'
        );
        insert apexSettings;  

        Account objAccount =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        objAccount.ERP_Customer_Id__c='7654321';
        insert objAccount;

        Contact objContact = TestDataContact.getNewContact(objAccount);

        Opportunity objOpp2 = TestDataOpportunity.getNewOpportunity(objAccount);
        objOpp2.StageName = 'Closed Won';
        objOpp2.ForecastCategoryName = 'Closed';
        objOpp2.Opportunity_Forecast_Category__c = 'Closed';
        update objOpp2;

        List<Apttus_Proposal__Proposal__c> lstProposal=[select 
                Id,Name, Apttus_Proposal__Primary_Contact__c, 
                Apttus_Proposal__Primary__c, Apttus_Proposal__Opportunity__c
                from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c LIKE '%Test Proposal%'];
        Apttus_Proposal__Proposal__c objProposal1 = lstProposal[0]; 
        Apttus_Proposal__Proposal__c objProposal2 = lstProposal[1]; 
        objProposal2.Apttus_Proposal__Primary_Contact__c = objContact.Id;
        objProposal2.Apttus_Proposal__Primary__c = true;
        update objProposal2;
        
        Test.startTest();

        List<Apttus_Config2__Order__c> lstOrders = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c objOrder1 =new Apttus_Config2__Order__c();
        objOrder1.Sales_Order_Number_Unique__c='001';
        objOrder1.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        objOrder1.Ultimate_Consignee_ERP_Id__c='123456';
        objOrder1.Distributor_ERP_Id__c='123456';
        objOrder1.Bill_To_ERP_Id__c='1981';
        objOrder1.Ship_To_ERP_Id__c='1981';
        objOrder1.Payer_ERP_Id__c='1981';
        objOrder1.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        objOrder1.Apttus_QPConfig__ProposalId__c = objProposal1.Id;
        lstOrders.add(objOrder1);

        Apttus_Config2__Order__c objOrder2 =new Apttus_Config2__Order__c();
        objOrder2.Sales_Order_Number_Unique__c='002';
        objOrder2.Apttus_Config2_SoldToAccountId_ERP_Id__c='123457';
        objOrder2.Ultimate_Consignee_ERP_Id__c='123457';
        objOrder2.Distributor_ERP_Id__c='123457';
        objOrder2.Bill_To_ERP_Id__c='1982';
        objOrder2.Ship_To_ERP_Id__c='1982';
        objOrder2.Payer_ERP_Id__c='1982';
        objOrder2.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        objOrder2.APTTUS_Quote_Number__c = 'TestProposalName';
        objOrder2.Apttus_QPConfig__ProposalId__c = objProposal2.Id;
        objOrder2.Apttus_Config2__Type__c = 'Illmna Base Warranty';
        objOrder2.Apttus_Config2__OrderReferenceNumber__c = '11223345';
        objOrder2.Apttus_Config2__RelatedOpportunityId__c = objOpp2.Id;
        lstOrders.add(objOrder2);
        
        insert lstOrders;

        Test.stopTest();

        Apttus_Config2__Order__c objOrderResult = [SELECT id,Apttus_Config2__RelatedOpportunityId__c FROM Apttus_Config2__Order__c WHERE id  =:objOrder1.Id ];
        Opportunity objOppResult = [SELECT id,First_Syncd_Order_ID__c FROM Opportunity WHERE id  =:objOpp2.Id ];
        Apttus_Proposal__Proposal__c objProposalResult1 = [SELECT id,Apttus_Proposal__Approval_Stage__c FROM Apttus_Proposal__Proposal__c WHERE id  =:objProposal2.Id ];
        system.assertEquals(objProposal1.Apttus_Proposal__Opportunity__c, objOrderResult.Apttus_Config2__RelatedOpportunityId__c ,'Order update failure' );
        system.assertEquals(objOrder2.Id, objOppResult.First_Syncd_Order_ID__c ,'Opportunity update failure' );
        system.assertEquals('Denied', objProposalResult1.Apttus_Proposal__Approval_Stage__c ,'Order update failure' );
    }
}