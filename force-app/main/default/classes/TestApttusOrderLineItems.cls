/***************************************************************************************************************************************
 * NAME   : TestApttusOrderLineItems
 * DESCRIPTION  : TestClass for Apptus Order Line Items Trigger
 * @AUTHOR : Ritika
 * @DATE   : 12-Nov-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika             12-Nov-2018             Initial Version
 * Shivani            08-Sep-2021             DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
 * Shivani            28-Sep-2021             DCP-47698 : Sync Acceptance Code to Install Work Order
 * Romi               17-Nov-2021             DCP-47704 - Test method for Email when Work Order fails on creation
 * Shivani            15-Mar-2022             DCP-51484 : No CP WOs should have Associated SR case
 * Gladis             22-Jun-2022             DCP-45368 : Modified updateOrderLineItems method 
 * Nishan             10-Oct-2022             CodeScanFix [Method name should not start with Capital].
 * Sudarshan          05-Dec-2023             CMCM-1354  EOL WO Changes
 * Arquimidez Mora    09-Aug-2024             CMCM-9644 : Test Methods for delete rejected Order Line Item and update related Asset Line Item 
 * Dhairya Shah       11-Oct-2024             CMCM-5165 No changes in Test Class
 ****************************************************************************************************************************************/ 
@isTest(SeeAllData=false)
public class TestApttusOrderLineItems {
    
    static final String MATERIALGROUP5_ACCEPTANCE = 'ACD: Acceptance Upon Delivery'; //DCP-47698
    
    @testSetup
    static void initializeData(){
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
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
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
    
    static testMethod void testCreateWoObj(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.VAD_Channel_Partner_Territory__c = 'test';
        insert acc;
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('testip', 'USD', 'New');
        insert ip1;

        Apttus_Proposal__Proposal__c quote = TestDataProposal.initProposal(acc.id, opp.id, 'testOpp1', priceList.id, true, 'Draft', 'None');
        insert quote;

        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
        orders1.ASOP_Number__c = '0001';
        orders1.Ultimate_Consignee__c = acc.Id;
		
        orders1.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders1.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders1;

        Trade_In_Product__c tip = new Trade_In_Product__c(
            Account__c = acc.id,
            Installed_Product__c = ip1.id,
            Quote_Proposal__c = quote.id
        );
        insert tip;

        SVMXC__Service_Order__c wo = ApttusOrderLineItems.createWoObj(orders1, tip, new Map<Id,Map<String,Account_to_Field_Support__c>> ());
        System.assertNotEquals(null, wo,'Wo Object returned is null');
    }

    static testMethod void insertOrderLineItems(){
        //initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.VAD_Channel_Partner_Territory__c = 'test';
        insert acc;
        
        Contact con = TestDataContact.getNewContact(acc);
        con.Email = 'test123@illumina.com';
        update con;
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Auto_Create_IQ_OQ__c = true;
        objProduct.Auto_Create_PQ__c = true;
        insert objProduct;
        
        SVMXC__Service_Group_Members__c grpMembers = [Select Id from SVMXC__Service_Group_Members__c limit 1];
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        insert accTechRole1;
        SVMXC__Service_Group__c serviceTeam = [Select Id from SVMXC__Service_Group__c limit 1];
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        
        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
        orders1.ASOP_Number__c = '0001';
        orders1.Ultimate_Consignee__c = acc.Id;
		
        orders1.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders1.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders1;
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
		orders.Apttus_Config2__SoldToAccountId__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        orders.ASOP_Number_Link__c = orders1.Id;
        orders.Contact_Email__c = 'test123@illumina.com';
        insert orders;
        
        Contract_Order_Routing_Sheet__c objCORS = new Contract_Order_Routing_Sheet__c();
        objCORS.Opportunity__c = opp.Id;
        objCORS.Order__c = orders1.Id;
        objCORS.Additional_Notes__c = 'test notes';
        objCORS.Rev_Rec_Code__c = 'ACD: Acceptance Upon Delivery';
        objCORS.Account__c = acc.Id;
        insert objCORS;
        system.debug('## objProduct ' + objProduct);
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        Test.startTest();
        insert objOrderLineItem;
		Test.stopTest();
        List<SVMXC__Service_Order__c> lstWOInserted = [Select Id from SVMXC__Service_Order__c];
        system.assertEquals(2, lstWOInserted.size(),'WO Insertion issue');
        //Test.stopTest();
    }

    static testMethod void insertOrderLineItemsWithEol(){
        //initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        Contact con = TestDataContact.getNewContact(acc);
        con.Email = 'test123@illumina.com';
        update con;
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Auto_Create_IQ_OQ__c = true;
        objProduct.Auto_Create_PQ__c = true;
        insert objProduct;
        
        SVMXC__Service_Group_Members__c grpMembers = [Select Id from SVMXC__Service_Group_Members__c limit 1];
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        insert accTechRole1;
        SVMXC__Service_Group__c serviceTeam = [Select Id from SVMXC__Service_Group__c limit 1];
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        
        Apttus_Config2__Order__c orders1=new Apttus_Config2__Order__c();
        orders1.ASOP_Number__c = '0001';
        orders1.Ultimate_Consignee__c = acc.Id;
		
        orders1.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders1.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders1;
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
		orders.Apttus_Config2__SoldToAccountId__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        orders.ASOP_Number_Link__c = orders1.Id;
        orders.Contact_Email__c = 'test123@illumina.com';
        insert orders;
        
        Contract_Order_Routing_Sheet__c objCORS = new Contract_Order_Routing_Sheet__c();
        objCORS.Opportunity__c = opp.Id;
        objCORS.Order__c = orders1.Id;
        objCORS.Additional_Notes__c = 'test notes';
        objCORS.Rev_Rec_Code__c = 'ACD: Acceptance Upon Delivery';
        objCORS.Account__c = acc.Id;
        insert objCORS;
        system.debug('## objProduct ' + objProduct);
        Apttus_Config2__OrderLineItem__c objOrderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem1.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem1.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem1.Trade_In_Indicator__c = 'C';
        objOrderLineItem1.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem1.ERP_Line_Number_Id__c = '12345_122';
        Test.startTest();
        insert objOrderLineItem1;
        Apttus_Config2__OrderLineItem__c objOrderLineItem2 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem2.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem2.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem2.Trade_In_Indicator__c = 'A';
        objOrderLineItem2.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem2.ERP_Line_Number_Id__c = '12345_999'; 
        insert objOrderLineItem2;
		Test.stopTest(); 
        System.assertNotEquals(null, objOrderLineItem2.Id,'Order Line Item is null'); 
        //Test.stopTest();
    }
    
    static testMethod void updateOrderLineItems(){
        //initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
        insert acc;
        
        //DCP-45368 starts
        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = myId;
        insert csapex;

        Contact con = TestDataPerson.getNewContact(acc.Id);
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.ERP_Equipment_ID__c='123456';
        insert objInstalledProduct;    
        Case objCase  = new Case();  
        objCase.Status = 'Initiated';
        objCase.Subject = 'test' ;
        objCase.Description= 'test';
        objCase.Origin = 'Phone-CP';
        objCase.Date_of_Issue_Awareness__c=System.today() -2;
        objCase.ContactId = con.Id;
        objCase.AccountId = acc.Id;
        objCase.RecordTypeId = idCaseRecordTypeId;
        objCase.SVMXC__Component__c = null;
        objCase.Next_Steps__c='Case AutoGenerated by Install WO Process.';
        insert objCase;
        //DCP-45368 ends

        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        //START DCP-47686
        objProduct.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA; 
        //END DCP-47686
        insert objProduct;
        
        SVMXC__Service_Group_Members__c grpMembers = [Select Id from SVMXC__Service_Group_Members__c limit 1];
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        insert accTechRole1;
        SVMXC__Service_Group__c serviceTeam = [Select Id from SVMXC__Service_Group__c limit 1];
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
       
        insert objExpertise;
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders;
         Test.startTest();
        //Test.startTest();
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem.Equipment_Id__c = '123';//DCP-45368
        objOrderLineItem.Case_Id__c = objCase.id;
        insert objOrderLineItem;
        objOrderLineItem.Apttus_Config2__Quantity__c = 3;  
        objOrderLineItem.Equipment_Id__c = '123456';//DCP-45368   
        update objOrderLineItem;
        //DCP-47698
        objOrderLineItem.Material_Group_5__c = MATERIALGROUP5_ACCEPTANCE;  
        update objOrderLineItem;

        //DCP-45368 starts
        List<Case> lstCases = [Select Id, SVMXC__Component__c from Case where Id =: objCase.id];
        System.assertEquals(null, lstCases[0].SVMXC__Component__c, 'Case not updated');
        //DCP-45368 ends
		Test.stopTest();
        //Modified DCP-47686
        List<SVMXC__Service_Order__c> lstWOInserted = [Select Id, Qualification_Requirements__c from SVMXC__Service_Order__c limit 10];
        system.assertEquals(3, lstWOInserted.size(), 'WO Insertion issue');
        Boolean qrValuesPresent = lstWOInserted[0].Qualification_Requirements__c.contains(ApttusOrderLineItems.STRING_QUAL_REQ_IQ_OQ) 
                                &&  lstWOInserted[0].Qualification_Requirements__c.contains(ApttusOrderLineItems.STRING_QUAL_REQ_PQ);
        System.assert(qrValuesPresent, 'Qualifcation Requirements field not populated!');

        //DCP-47698
        List<SVMXC__Service_Order__c> lstWOUpdated = [Select Id, Acceptance_Code__c from SVMXC__Service_Order__c LIMIT 10];
        System.assertEquals(MATERIALGROUP5_ACCEPTANCE, lstWOUpdated[0].Acceptance_Code__c, 'Acceptance Code not populated succesfully!');
    }
    
    static testMethod void deleteOrderLineItems(){
        Test.startTest();
        //initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
        insert acc;
        //Create dummy Contact to be used as target on Email Template
        TestDataContact.getNewContact(acc);
       
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Serial_Number_Profile__c = 'IL02';
        insert objProduct;
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        
        
        insert orders;
        
        SVMXC__Service_Group_Members__c grpMembers = [Select Id from SVMXC__Service_Group_Members__c limit 1];
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        insert accTechRole1;
        
        //Test.startTest();
        SVMXC__Service_Group__c serviceTeam = [Select Id from SVMXC__Service_Group__c limit 1];
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        insert objOrderLineItem;
		
		
		Test.stopTest();
        delete objOrderLineItem;
        List<SVMXC__Service_Order__c> lstWOCanceled = [Select Id from SVMXC__Service_Order__c where SVMXC__Order_Status__c = 'Canceled'];
        system.assertEquals(2, lstWOCanceled.size(),'WO Cancellation failure');
        
    }
    /*
     *@description - To test email notification
     */
	
	static testMethod void wFMOrderLineItems(){//CodeScan Issue Fix
        //initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders;
        
        Test.startTest();
        Product2 objProduct1=TestDataFieldService.createProduct('VeriSeq™ NIPT Solution Enablement','Services');
        objProduct1.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct1.Service_Product_Type__c = 'Core';
        objProduct1.ProductCode = '15076162';
        insert objProduct1;
        
        Product2 wfmProd=TestDataFieldService.createProduct('WFM 2.3.1 USB Kit','Instrument');
        wfmProd.ProductCode = '20041804';
        insert wfmProd;
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Serial_Number_Profile__c = 'IL02';
        insert objProduct;
        
        SVMXC__Installed_Product__c ipObj = new SVMXC__Installed_Product__c();
        ipObj.SVMXC__Product__c = objProduct.Id;
        ipObj.name = 'WFMyy-15076162';
        ipObj.SVMXC__Status__c = 'Shipped';
        insert ipObj;
        
        Apttus_Config2__OrderLineItem__c objOrderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem1.Apttus_Config2__ProductId__c = objProduct1.id;
        objOrderLineItem1.Apttus_Config2__OrderId__c = orders.id;
        objOrderLineItem1.Apttus_Config2__Quantity__c = 2;
        insert objOrderLineItem1;
        
        Apttus_Config2__OrderLineItem__c objOrderLineItem2 = [SELECT id FROM Apttus_Config2__OrderLineItem__c WHERE id =:objOrderLineItem1.id ];
        objOrderLineItem2.Apttus_Config2__Quantity__c = 3;
        update objOrderLineItem2;
        Test.stopTest(); 
        system.assertEquals(3, objOrderLineItem2.Apttus_Config2__Quantity__c,'Order line items insertion failure' );
       
    }
	 /*
     * @Description- An email notification is sent when Work Order fails to be created for new instrument orders. DCP-47704
     */
    static testMethod void sendEmailWhenWOFailsQuantity(){
       // initializeData();
       Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
       insert acc;
       System.assertNotEquals(null, acc.Id,'Account insertion failure');
      
       Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
       
       Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
       objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
       objProduct.Service_Product_Type__c = 'Instrument';
       objProduct.Serial_Number_Profile__c = 'IL02';
       insert objProduct;
       System.assertNotEquals(null, objProduct.Id,'Production insertion failed');
 
       SVMXC__Service_Group_Members__c grpMembers = [Select Id from SVMXC__Service_Group_Members__c limit 1];
       Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
           Account__c = acc.Id,
           User__c = grpMembers.Id,
           User_Role__c = 'Primary Field Service Engineer'
       );
       insert accTechRole1;
       System.assertNotEquals(null, accTechRole1.Id,'Account role insertion failed');
       SVMXC__Service_Group__c serviceTeam = [Select Id from SVMXC__Service_Group__c limit 1];
       SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                       SVMXC__Group_Member__c = grpMembers.Id,
                                                                                       SVMXC__Service_Group__c = serviceTeam.Id);
      
       insert objExpertise;
       System.assertNotEquals(null, objExpertise.Id,'Service group insert issue');
       
       Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
       orders.ASOP_Number__c = '0001';
       orders.Ultimate_Consignee__c = acc.Id;
       orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
       orders.Apttus_Config2__OrderReferenceNumber__c = '1234qwertyuiufds';
       insert orders;
       System.assertNotEquals(null, orders.Id,'Order insertion issue');
       
       Test.startTest();
       Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
       objOrderLineItem.Apttus_Config2__OrderId__c = orders.Id;
       objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
       objOrderLineItem.Apttus_Config2__Quantity__c = 2;
       objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
       insert objOrderLineItem;
       System.assertNotEquals(null, objOrderLineItem.Id,'Order line item is null');
       
       Integer invocations = Limits.getEmailInvocations();
       system.assertEquals(0,invocations,'no Email invocations');
       Test.stopTest();


   }
	/*
     * @Description-Test if delete Order Line Items when a item status is rejected and reason of rejected changes. CMCM-9644 
    */
    static testMethod void updateItemStatusToRejectedAndDeleteRejectedRecods(){
        //initializeData();
        Account objAccount =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        objAccount.ERP_Customer_Id__c='654321';
        insert objAccount;

        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.Email = 'test123@illumina.com';
        update objContact;
        
        Pricebook2 objPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
        objOpportunity.Pricebook2Id = objPricebook.Id;
        update objOpportunity;
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal Update', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Apttus_Config2__Order__c order =new Apttus_Config2__Order__c();
        order.Sales_Order_Number_Unique__c='001';
        order.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        order.Ultimate_Consignee_ERP_Id__c='123456';
        order.Distributor_ERP_Id__c='123456';
        order.Bill_To_ERP_Id__c='1981';
        order.Ship_To_ERP_Id__c='1981';
        order.Payer_ERP_Id__c='1981';
        order.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        order.APTTUS_Quote_Number__c=objProposal.Name;
        insert order;

        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        Case objCase  = new Case();  
        objCase.Status = 'Initiated';
        objCase.Subject = 'test' ;
        objCase.Description= 'test';
        objCase.Origin = 'Phone-CP';
        objCase.Date_of_Issue_Awareness__c=System.today() -2;
        objCase.ContactId = objContact.Id;
        objCase.AccountId = objAccount.Id;
        objCase.RecordTypeId = idCaseRecordTypeId;
        objCase.SVMXC__Component__c = null;
        objCase.Next_Steps__c='Case AutoGenerated by Install WO Process.';
        insert objCase;

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA; 
        insert objProduct;

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = objAccount.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = objProposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = System.today();
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

        Test.startTest();
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = order.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem.Equipment_Id__c = '123';
        objOrderLineItem.Case_Id__c = objCase.id;
        insert objOrderLineItem;
        objOrderLineItem.Reason_For_Rejection__c = 'Test Delete'; 
        objOrderLineItem.Item_Status__c = 'Rejected'; 
        update objOrderLineItem;
        Test.stopTest();

        system.assertEquals(0, [SELECT COUNT() FROM Apttus_Config2__OrderLineItem__c WHERE Id = :objOrderLineItem.Id] ,'Order line items should be deleted' );
    }

    /*
     * @Description- Test if update Asset Line Items related when a item status changes and not equal to active or cancelled
     *  and the asset line item id is not null. CMCM-9644 
    */
    static testMethod void updateStatusFromAssetLineItemRelated(){
        Set<Id> setAssetIds = new Set<Id>();
        //initializeData();
        Account objAccount =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        objAccount.ERP_Customer_Id__c='654321';
        insert objAccount;
        
        Account objAccount2 =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        objAccount2.ERP_Customer_Id__c='654322';
        insert objAccount2;

        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        Opportunity objOpp1 = TestDataOpportunity.getNewOpportunity(objAccount);
        Opportunity objOpp2 = TestDataOpportunity.getNewOpportunity(objAccount);
        
        List<Apttus_Config2__PriceList__c> lstPriceList = new List<Apttus_Config2__PriceList__c>();
        Apttus_Config2__PriceList__c objPriceList1 = TestDataProposal.initPriceList('AMR-USD-US-01');
        Apttus_Config2__PriceList__c objPriceList2 = TestDataProposal.initPriceList('AMR-USD-US-01');
        lstPriceList.add(objPriceList1);
        lstPriceList.add(objPriceList2);
        insert lstPriceList;
        
        List<Apttus_Proposal__Proposal__c> lstProposals = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount.id, objOpp1.id, 'Test Proposal 1', objPriceList1.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProposal2 = TestDataProposal.initProposal(objAccount.id, objOpp2.id, 'Test Proposal 2', objPriceList2.id, true, 'Draft', 'None');
        lstProposals.add(objProposal1);
        lstProposals.add(objProposal2);
        insert lstProposals;

        Case objCase1 = TestDataCase.getNewComplaintCase(objContact);
        Case objCase2 = TestDataCase.getNewComplaintCase(objContact);

        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct1 = TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct1.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct1.Service_Product_Type__c = 'Instrument';
        objProduct1.Serial_Number_Profile__c = 'IL02';
        objProduct1.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA; 
        Product2 objProduct2 = TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct2.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct2.Service_Product_Type__c = 'Instrument';
        objProduct2.Serial_Number_Profile__c = 'IL03';
        objProduct2.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA; 

        lstProducts.add(objProduct1);
        lstProducts.add(objProduct2);
        insert lstProducts;

        List<Apttus_Config2__Order__c> lstOrders = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c objOrder1 = TestDataOrder.initOrder(objAccount.Id);
        objOrder1.Apttus_Config2__PODate__c=Date.valueOf('2018-11-20');
        objOrder1.APTTUS_Quote_Number__c=objProposal1.Name;
        Apttus_Config2__Order__c objOrder2 = TestDataOrder.initOrder(objAccount2.Id);
        objOrder2.Apttus_Config2__PODate__c=Date.valueOf('2018-11-20');
        objOrder2.APTTUS_Quote_Number__c=objProposal2.Name;

        lstOrders.add(objOrder1);
        lstOrders.add(objOrder2);
        insert lstOrders;

        Apttus_Config2__AssetLineItem__c objAssetLine1 = TestDataProposal.getNewAssetLineItem(objAccount.Id, objProduct1.Id, objProposal1.Id);
        Apttus_Config2__AssetLineItem__c objAssetLine2 = TestDataProposal.getNewAssetLineItem(objAccount.Id, objProduct2.Id, objProposal2.Id);
        setAssetIds.add(objAssetLine1.Id);
        setAssetIds.add(objAssetLine2.Id);

        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems = new List<Apttus_Config2__OrderLineItem__c>();
        Apttus_Config2__OrderLineItem__c objOrderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem1.Apttus_Config2__OrderId__c = objOrder1.Id;
        objOrderLineItem1.Apttus_Config2__ProductId__c = objProduct1.Id;
        objOrderLineItem1.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem1.ERP_Line_Number_Id__c = '12345_121';
        objOrderLineItem1.Equipment_Id__c = '121';
        objOrderLineItem1.Case_Id__c = objCase1.id;
        objOrderLineItem1.Apttus_Config2__AssetLineItemId__c = objAssetLine1.id;
        objOrderLineItem1.Apttus_Config2__Status__c = 'Activated';
        objOrderLineItem1.Apttus_Config2__LineStatus__c = 'Renewed';

        Apttus_Config2__OrderLineItem__c objOrderLineItem2 = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem2.Apttus_Config2__OrderId__c = objOrder2.Id;
        objOrderLineItem2.Apttus_Config2__ProductId__c = objProduct2.Id;
        objOrderLineItem2.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem2.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem2.Equipment_Id__c = '122';
        objOrderLineItem2.Case_Id__c = objCase2.id;
        objOrderLineItem2.Apttus_Config2__AssetLineItemId__c = objAssetLine2.id;
        objOrderLineItem2.Apttus_Config2__Status__c = 'Activated';
        objOrderLineItem2.Apttus_Config2__LineStatus__c = 'Renewed';

        lstOrderLineItems.add(objOrderLineItem1);
        lstOrderLineItems.add(objOrderLineItem2);
        
        Test.startTest();
        insert lstOrderLineItems;
        lstOrderLineItems[0].Apttus_Config2__Status__c = 'Processing'; 
        lstOrderLineItems[1].Apttus_Config2__Status__c = 'Cancelled';
        update lstOrderLineItems;
        Test.stopTest();

        List<Apttus_Config2__AssetLineItem__c> lstAssetLineItemResult = [SELECT id, Status__c FROM Apttus_Config2__AssetLineItem__c WHERE id IN :setAssetIds ];
        system.assertEquals('Pending Acceptance', lstAssetLineItemResult[0].Status__c ,'Asset line items update failure' );
        system.assertEquals('Cancelled', lstAssetLineItemResult[1].Status__c ,'Asset line items update failure' );
    }
}