/**
 * @author Akshay Mohan 
 * @date   30-Aug-2018
 * @description  Test class for Controller class for custom component which let's user select and search Ship To and Bill To
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Akshay Mohan             30-Aug-2018         Original
*   Akshay Mohan             09-Apr-2018         DCP-24588 Allow search for payers
*   Joshith K                11-Dec-2019         INC0235038 - increase coverage for Sales org Override changes.
*  Akshay Mohan              02-July-2021        DCP-46226: Add Payment Term Override logic
*   Aman Tyagi               07-Oct-2022         Codescan Fixes
*  -----------------------------------------------------------------------------------          
*/
@isTest(isparallel=true)
public class TestCustomerMasterDataSelectionCntrl {
    public static ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
                                                    new List<Schema.SObjectType> {
                                                        Account.SObjectType,
                                                        Pricebook2.SObjectType,
                                                        Opportunity.SObjectType,
                                                        Apttus_Config2__PriceList__c.SObjectType,
                                                        Apttus_Proposal__Proposal__c.SObjectType,
                                                        Customer_Master_Data__c.SObjectType,
                                                        Account_Sales_Area__c.SObjectType,
                                                        Account_Relationship__c.SObjectType
                                                });
    /**
    * @author  Akshay Mohan 
    * @description static method for set up the data
    * @param NA
    * @return NA
    **/                                          
    @testSetup
    public static void setupData(){
        Account objAccount = TestDataAccount.getAccount('Hogwarts');
        objAccount.ERP_Customer_Id__c = 'Hogy';
        uow.registerNew(objAccount);
        Account objUC = TestDataAccount.getAccount('Gryffindoor');
        objUC.ERP_Customer_Id__c = 'Gryffy';
        uow.registerNew(objUC);
        Account objDistributor = TestDataAccount.getAccount('Slytherin');
        objDistributor.ERP_Customer_Id__c = 'Slimy';
        objDistributor.Account_Group__c = Label.AccountGroupDistributor;
        uow.registerNew(objDistributor);
        
        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
            					objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
            					objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor,Country__c='HK');
        uow.registerNew(objCMDUC);
        uow.registerNew(objCMDSoldTo);
        uow.registerNew(objCMDDist);
        
        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        uow.registerRelationship(objSoldToSA, Account_Sales_Area__c.Account__c, objAccount);
        uow.registerNew(objSoldToSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDSoldTo);
        Account_Sales_Area__c objUCSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Gryffy_HK010100','div1',false);
        uow.registerNew(objUCSA, Account_Sales_Area__c.Account__c, objUC);
        uow.registerRelationship(objUCSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDUC);
        Account_Sales_Area__c objDistributorSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Slimy_HK010200','div1',false);
        uow.registerNew(objDistributorSA, Account_Sales_Area__c.Account__c, objDistributor);
        uow.registerRelationship(objDistributorSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDDist);
        
        Account_Relationship__c objBTSelf = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
            																Relationship__c=Label.AccountRelationshipBillTo);
        uow.registerNew(objBTSelf, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);
        
        Account_Relationship__c objBTOther = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Gryffy',
            																Relationship__c=Label.AccountRelationshipBillTo);
        uow.registerNew(objBTOther, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);
        
        Account_Relationship__c objShipToSelf = new Account_Relationship__c(ERP_Customer_Id__c = 'Gryffy',
                                                                          	Related_ERP_Customer_Id__c ='Gryffy',
            																Relationship__c=Label.AccountRelationshipShipTo);
        uow.registerNew(objShipToSelf, Account_Relationship__c.Account_Sales_Area__c, objUCSA);
        
        Account_Relationship__c objShipToOther = new Account_Relationship__c(ERP_Customer_Id__c = 'Gryffy',
                                                                          	Related_ERP_Customer_Id__c ='Hogy',
            																Relationship__c=Label.AccountRelationshipShipTo);
        uow.registerNew(objShipToOther, Account_Relationship__c.Account_Sales_Area__c, objUCSA);
        
        Account_Relationship__c objSoldToP = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
                                                                          ERP_Account_Relationship_Id__c='Hogy_Payer',
            															  Relationship__c=Label.AccountGroupPayer);
        uow.registerNew(objSoldToP, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);
        
        Account_Relationship__c objShipToP = new Account_Relationship__c(ERP_Customer_Id__c = 'Gryffy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
            																Relationship__c=Label.AccountGroupPayer);
        uow.registerNew(objShipToP, Account_Relationship__c.Account_Sales_Area__c, objUCSA);
        
        Account_Relationship__c objSoldToD = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Slimy',
            																Relationship__c=Label.AccountGroupDistributor);
        uow.registerNew(objSoldToD, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);
        
        
        Pricebook2 objPricebook = new Pricebook2(Name='Book of prices',IsActive=true);
        uow.registerNew(objPricebook); 
        //Indirect Opp
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        uow.registerRelationship(objOpportunity, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity, Opportunity.Ultimate_Consignee__c, objUC);
        uow.registerRelationship(objOpportunity, Opportunity.Distributor__c, objDistributor);
        objOpportunity.Name = 'Has Relationship'; 
        uow.registerNew(objOpportunity,Opportunity.AccountId,objAccount);
        //Setup for Indirect opp
        Opportunity objOpportunity2 = TestDataOpportunity.initOpportunity(objAccount);
        uow.registerRelationship(objOpportunity2, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity2, Opportunity.Ultimate_Consignee__c, objUC);
        uow.registerRelationship(objOpportunity2, Opportunity.Distributor__c, objDistributor);
        objOpportunity2.Name = 'Indirect Deal'; 
        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        objOpportunity2.RecordTypeId= rts.get(Label.OpportunityRTIndirectStandard).getRecordTypeId();
        uow.registerNew(objOpportunity2,Opportunity.AccountId,objAccount);
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        uow.registerNew(objPriceList);
        
        uow.commitWork();
        update new List<sObject>{objSoldToSA,objUCSA,objOpportunity,objDistributorSA,objOpportunity2};//do update since lookup to CMD is not populated for some reason
            
        System.debug('objAccount: '+ objAccount);
        System.debug('objUC: '+ objUC);
        System.debug('objCMDUC: '+ objCMDUC);
        System.debug('objCMDSoldTo: '+ objCMDSoldTo);
        System.debug('objSoldToSA: '+ objSoldToSA);
        System.debug('objUCSA: '+ objUCSA);
        System.debug('objBTSelf: '+ objBTSelf);
        System.debug('objBTOther: '+ objBTOther);
        System.debug('objShipToSelf: '+ objShipToSelf);
        System.debug('objShipToOther: '+ objShipToOther);
        System.debug('objSoldToP: '+ objSoldToP);
        System.debug('objShipToP: '+ objShipToP);
        System.debug('objSoldToD: '+ objSoldToD);
        System.debug('objPricebook: '+ objPricebook);
        System.debug('objOpportunity: '+ objOpportunity);
        System.debug('objPriceList: '+ objPriceList);
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 
                                                                              'Test Proposal', objPriceList.id, true, 
                                                                              'Draft', 'None');
        Apttus_Proposal__Proposal__c objProposal2 = TestDataProposal.initProposal(objAccount.id, objOpportunity2.id, 
                                                                              'Test Proposal 2', objPriceList.id, true, 
                                                                              'Draft', 'None');
        insert new List<Apttus_Proposal__Proposal__c>{objProposal,objProposal2};
        System.debug('objProposal: ' + objProposal);
    }
    /**
    * @author  
    * @description static method to check direct bill
    * @param NA
    * @return NA
    **/
    @isTest
    public static void checkDirectBillTo(){
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Apttus_Proposal__Opportunity__r.AccountId 
                                                    FROM Apttus_Proposal__Proposal__c
                                                    WHERE Apttus_Proposal__Proposal_Name__c ='Test Proposal'];
        System.debug('objProposal: '+objProposal);
        
        Set<String> setCMDERPs = new Set<String>{'Hogy','Gryffy','Slimy'};
        Customer_Master_Data__c objCMDBillTo,objCMDShipTo,objCMDDistributor;
        for(Customer_Master_Data__c objCMD: [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
			if(objCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDBillTo = objCMD;
			if(objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
            if(objCMD.ERP_Customer_Id__c == 'Slimy')
                objCMDDistributor = objCMD;
        }
        
        Test.startTest();
        String strJSON = CustomerMasterDataSelectionController.loadPage(objProposal.Id, Label.AccountRelationshipBillTo);
        
        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstIndirect,lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '), List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstDirect: '+ lstDirect);
        System.assertEquals(2, lstDirect.size(),'Incorrect number of relationships returned');
        Boolean booFoundBillTo=false,booFoundShipTo=false;
        List<String> lstERPs = new List<String>();
        for(CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objWrap : lstDirect){
            if(objWrap.strRecordId == objCMDBillTo.Id)
                booFoundBillTo=true;
            if(objWrap.strRecordId == objCMDShipTo.Id)
                booFoundShipTo=true;
            System.assert(String.isBlank(objWrap.strIcon),'Icon getting set when it shouldn\'t');
            lstERPs.add(objWrap.strRecordId);
        }
        System.assert(booFoundBillTo,'Bill To not found');
        System.assert(booFoundShipTo,'Ship To not found');
        
        Boolean booDirect = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"booDirectDeal": ', ',"booClosedOpportunity": '), 
                                                       Boolean.class);
        System.assert(booDirect,'Direct flag not set for deal');
        String strCountry = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strUCCountry": ', ',"strSalesArea": '), 
                                                       String.class);
        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), 
                                                       String.class);
        //DCP-46226
        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(objProposal.Id,lstERPs,Label.AccountRelationshipBillTo,
                                                                          booDirect,'CMD',strCountry,strSalesArea);
        Test.stopTest();
        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            			JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstIndirect: '+lstIndirect);
        System.assertEquals(0, lstIndirect.size(),'Incorrect number of search results returned');
        
    }
    /**
    * @author  
    * @description static method to check direct ship to
    * @param NA
    * @return NA
    **/
    @isTest
    public static void checkDirectShipTo(){
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c
                                                    FROM Apttus_Proposal__Proposal__c
                                                    WHERE Apttus_Proposal__Proposal_Name__c ='Test Proposal'];
        System.debug('objProposal: '+objProposal);

        Set<String> setCMDERPs = new Set<String>{'Hogy','Gryffy','Slimy'};
        Customer_Master_Data__c objCMDBillTo,objCMDShipTo,objCMDDistributor;
        for(Customer_Master_Data__c objCMD: [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
			if(objCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDBillTo = objCMD;
			if(objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
            if(objCMD.ERP_Customer_Id__c == 'Slimy')
                objCMDDistributor = objCMD;
        }

        Test.startTest();
        String strJSON = CustomerMasterDataSelectionController.loadPage(objProposal.Id, Label.AccountRelationshipShipTo);
        
        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstIndirect,lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '), List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstDirect: '+ lstDirect);
        System.assertEquals(2, lstDirect.size(),'Incorrect number of relationships returned');
        Boolean booFoundBillTo=false,booFoundShipTo=false;
        List<String> lstERPs = new List<String>();
        for(CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objWrap : lstDirect){
            if(objWrap.strRecordId == objCMDBillTo.Id)
                booFoundBillTo=true;
            if(objWrap.strRecordId == objCMDShipTo.Id)
                booFoundShipTo=true;
            System.assert(String.isNotBlank(objWrap.strIcon),'Icon not getting set when it should');
            lstERPs.add(objWrap.strRecordId);
        }
        System.assert(booFoundBillTo,'Bill To not found');
        System.assert(booFoundShipTo,'Ship To not found');
        
        Boolean booDirect = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"booDirectDeal": ', ',"booClosedOpportunity": '), 
                                                       Boolean.class);
        System.assert(booDirect,'Direct flag not set for deal');
        String strCountry = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strUCCountry": ', ',"strSalesArea": '), 
                                                       String.class);
        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), 
                                                       String.class);
        //DCP-46226
        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(objProposal.Id,lstERPs,Label.AccountRelationshipBillTo,
                                                                          booDirect,'CMD',strCountry,strSalesArea);
        Test.stopTest();

        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            			JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstIndirect: '+lstIndirect);
        System.assertEquals(0, lstIndirect.size(),'Incorrect number of search results returned');
        //
        
    }
    /**
    * @author  
    * @description static method to check indirect bill to
    * @param NA
    * @return NA
    **/
    @isTest
    public static void checkIndirectBillTo(){
        
        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Apttus_Proposal__Opportunity__r.AccountId,Apttus_Proposal__Opportunity__c 
                                                    FROM Apttus_Proposal__Proposal__c
                                                    WHERE Apttus_Proposal__Proposal_Name__c ='Test Proposal'];
        System.debug('objProposal: '+objProposal);
        Opportunity objOpp = new Opportunity(Id = objProposal.Apttus_Proposal__Opportunity__c,
                                             Is_Updated_By_System__c=true,
                                             RecordTypeId= rts.get(Label.OpportunityRTIndirectStandard).getRecordTypeId()); 
        update objOpp;
        
        Set<String> setCMDERPs = new Set<String>{'Hogy','Gryffy','Slimy'};
        Customer_Master_Data__c objCMDBillTo,objCMDShipTo,objCMDDistributor;
        for(Customer_Master_Data__c objCMD: [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
			if(objCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDBillTo = objCMD;
			if(objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
            if(objCMD.ERP_Customer_Id__c == 'Slimy')
                objCMDDistributor = objCMD;
        }

        Test.startTest();
        String strJSON = CustomerMasterDataSelectionController.loadPage(objProposal.Id, Label.AccountRelationshipBillTo);
        
        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstIndirect,lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '), List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstDirect: '+ lstDirect);
        System.assertEquals(2, lstDirect.size(),'Incorrect number of relationships returned');
        CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objBT,objST;
        List<String> lstERPs = new List<String>();
        for(CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objWrap : lstDirect){
            if(objWrap.strRecordId == objCMDBillTo.Id)
                objBT=objWrap;
            if(objWrap.strRecordId == objCMDShipTo.Id)
                objST=objWrap;
            System.assert(String.isBlank(objWrap.strIcon),'Icon getting set when it shouldn\'t');
            lstERPs.add(objWrap.strRecordId);
        }
        System.assert(objBT!=null,'Bill To not found');
        System.assert(objST!=null,'Ship To not found');
        
        Boolean booDirect = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"booDirectDeal": ', ',"booClosedOpportunity": '), 
                                                       Boolean.class);
        System.assert(!booDirect,'Indirect flag not set for deal');
        String strCountry = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strUCCountry": ', ',"strSalesArea": '), 
                                                       String.class);
        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), 
                                                       String.class);
        //DCP-46226
        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(objProposal.Id,lstERPs,Label.AccountRelationshipBillTo,
                                                                          booDirect,'CMD',strCountry,strSalesArea);
        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            			JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstIndirect: '+lstIndirect);
        System.assertEquals(1, lstIndirect.size(),'Incorrect number of search relationships returned');
        System.assertEquals(objCMDDistributor.Id, lstIndirect[0].strRecordId,'Wrong record retrieved');
        
        objProposal.Bill_To__c = objBT.strRecordId;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),JSON.serialize(objBT),null,Label.AccountRelationshipBillTo,booDirect,strSalesArea);
        System.assertEquals('Success',strJSON,'Update not happening as expected');
        objProposal = [SELECT Id,Payer__c FROM Apttus_Proposal__Proposal__c WHERE Id =:objProposal.Id ];
        System.assertEquals(objProposal.Payer__c,objCMDBillTo.Id,'Payer not setting as expected');
        objProposal.Bill_To__c = objST.strRecordId;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),JSON.serialize(objST),null,Label.AccountRelationshipBillTo,booDirect,strSalesArea);
        Test.stopTest();
        System.assertEquals('Success',strJSON,'Update not happening as expected');
        objProposal = [SELECT Id,Payer__c FROM Apttus_Proposal__Proposal__c WHERE Id =:objProposal.Id ];
        System.assertEquals(objProposal.Payer__c,objCMDBillTo.Id,'Payer not setting as expected');
    }
    /**
    * @author  
    * @description static method to check indirect ship to
    * @param NA
    * @return NA
    **/
    @isTest
    public static void checkIndirectShipTo(){
        
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c
                                                    	,Apttus_Proposal__Opportunity__r.Distributor__c,Apttus_Proposal__Opportunity__c 
                                                    FROM Apttus_Proposal__Proposal__c
                                                    WHERE Apttus_Proposal__Proposal_Name__c ='Test Proposal 2'];
        System.debug('objProposal: '+objProposal);
        
        Set<String> setCMDERPs = new Set<String>{'Hogy','Gryffy','Slimy'};
        Customer_Master_Data__c objCMDBillTo,objCMDShipTo,objCMDDistributor;
        for(Customer_Master_Data__c objCMD: [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
			if(objCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDBillTo = objCMD;
			if(objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
            if(objCMD.ERP_Customer_Id__c == 'Slimy')
                objCMDDistributor = objCMD;
        }

        Test.startTest();
        String strJSON = CustomerMasterDataSelectionController.loadPage(objProposal.Id, Label.AccountRelationshipShipTo);
        
        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstIndirect,lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '), List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstDirect: '+ lstDirect);
        System.assertEquals(2, lstDirect.size(),'Incorrect number of relationships returned');
        Boolean booFoundBillTo=false,booFoundShipTo=false;
        List<String> lstERPs = new List<String>();
        for(CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objWrap : lstDirect){
            if(objWrap.strRecordId == objCMDBillTo.Id)
                booFoundBillTo=true;
            if(objWrap.strRecordId == objCMDShipTo.Id)
                booFoundShipTo=true;
            System.assert(String.isBlank(objWrap.strIcon),'Icon getting set when it shouldn\'t');
            lstERPs.add(objWrap.strRecordId);
        }
        System.assert(booFoundBillTo,'Bill To not found');
        System.assert(booFoundShipTo,'Ship To not found');
        
        Boolean booDirect = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"booDirectDeal": ', ',"booClosedOpportunity": '), 
                                                       Boolean.class);
        System.assert(!booDirect,'Indirect flag not set for deal');
        String strCountry = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strUCCountry": ', ',"strSalesArea": '), 
                                                       String.class);
        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), 
                                                       String.class);
        //DCP-46226
        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(objProposal.Id,lstERPs,Label.AccountRelationshipShipTo,
                                                                          booDirect,'CMD',strCountry,strSalesArea);
        
        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            			JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstIndirect: '+lstIndirect);
        System.assertEquals(1, lstIndirect.size(),'Incorrect number of relationships returned');
        System.assertEquals(objCMDDistributor.Id, lstIndirect[0].strRecordId,'Wrong record retrieved');
        objProposal.Ship_To__c = lstIndirect[0].strRecordId;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),null,JSON.serialize(lstIndirect[0]),Label.AccountRelationshipShipTo,booDirect,strSalesArea);
        System.assertEquals(Label.UI_ErrorMessage_CMD_Selection_Sales_Area_Country_Missing,strJSON,'Missing country code error not coming as expected');
        objCMDDistributor.Country_Code__c='US';
        update objCMDDistributor;
        //DCP-46226
        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(objProposal.Id,lstERPs,Label.AccountRelationshipShipTo,
                                                                          booDirect,'CMD',strCountry,strSalesArea);
        
        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
                        JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        objProposal.Ship_To__c = lstIndirect[0].strRecordId;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),null,JSON.serialize(lstIndirect[0]),Label.AccountRelationshipShipTo,booDirect,strSalesArea);
        System.assertEquals(Label.UI_ErrorMessage_CMD_Selection_Indirect_Ship_To_Sales_Area,strJSON,'Missing sales area extension error not coming as expected');
        Account objacc=[select id from account where name='Slytherin' limit 1];
        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('US01','02','Hogy_HK20100','00',false);
        objSoldToSA.Account__c=objacc.id;
        insert objSoldToSA;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),null,JSON.serialize(lstIndirect[0]),Label.AccountRelationshipShipTo,booDirect,strSalesArea);
        // opportunity  sales org override
        opportunity opp=[select id ,Sales_Org_Override__c from opportunity where name='Indirect Deal' limit 1];
        opp.Sales_Org_Override__c='CN03';
        update opp;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal),null,JSON.serialize(lstIndirect[0]),Label.AccountRelationshipShipTo,booDirect,strSalesArea);
        Test.stopTest();
        
    }
    /**
    * @author  
    * @description static method to check bill to search as per DCP-24588
    * //added for DCP-24588
    * @param NA
    * @return NA
    **/
    @isTest
    public static void checkBillToSearch()
    {
        Apttus_Proposal__Proposal__c objProposal =
            [SELECT Id,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c
             FROM Apttus_Proposal__Proposal__c
             WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        System.debug('objProposal: ' + objProposal);

        Set<String> setCMDERPs = new Set<String> {'Hogy', 'Gryffy', 'Slimy'};
        Customer_Master_Data__c objCMDBillTo, objCMDShipTo, objCMDDistributor;
        for (Customer_Master_Data__c objCMD :
            [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c WHERE ERP_Customer_Id__c IN :setCMDERPs]
        ) {
			if (objCMD.ERP_Customer_Id__c == 'Hogy')   objCMDBillTo = objCMD;
			if (objCMD.ERP_Customer_Id__c == 'Gryffy') objCMDShipTo = objCMD;
            if (objCMD.ERP_Customer_Id__c == 'Slimy')  objCMDDistributor = objCMD;
        }
        objCMDDistributor.Account_Group__c = Label.AccountRelationshipBillTo;
        update objCMDDistributor;

        Account_Sales_Area__c objSlimySA =
            [SELECT Id
             FROM Account_Sales_Area__c 
             WHERE ERP_Account_Sales_Area_Id__c = 'Slimy_HK010200'];
        objSlimySA.ERP_Account_Sales_Area_Id__c = 'Slimy_HK010100';
        update objSlimySA;

        Account_Relationship__c objBillToSelf = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Slimy',
            Related_ERP_Customer_Id__c = 'Slimy',
            Relationship__c = Label.AccountRelationshipBillTo,
            Account_Sales_Area__c = objSlimySA.Id,
            IsInactive__c = false
        );
        insert objBillToSelf;
        System.debug('objBillToSelf: ' + objBillToSelf);

        String strJSON = CustomerMasterDataSelectionController.loadPage(objProposal.Id, Label.AccountRelationshipBillTo);

        Test.startTest();

        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstIndirect, lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '), List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstDirect: '+ lstDirect);
        List<String> lstERPs = new List<String>();
        for (CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper objWrap : lstDirect)
        {
            lstERPs.add(objWrap.strRecordId);
        }

        Boolean booDirect = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"booDirectDeal": ', ',"booClosedOpportunity": '), Boolean.class);
        String strCountry = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strUCCountry": ', ',"strSalesArea": '), String.class);
        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), String.class);

        strJSON = CustomerMasterDataSelectionController.searchIndirectCMD(//DCP-46226
            objProposal.Id,lstERPs, Label.AccountRelationshipBillTo, booDirect, 'Slimy', strCountry, strSalesArea
        );

        lstIndirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            			JSON.deserialize(strJSON, List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class);
        System.debug('lstIndirect: ' + lstIndirect);
        System.assertEquals(1, lstIndirect.size(), 'Incorrect number of relationships returned');
        System.assertEquals(objCMDDistributor.Id, lstIndirect[0].strRecordId, 'Wrong record retrieved');

        objProposal.Bill_To__c = objCMDDistributor.Id;
        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal), JSON.serialize(lstIndirect[0]),null, Label.AccountRelationshipBillTo, booDirect, strSalesArea);
        System.assertEquals('Success', strJSON, 'Update not happening as expected');
        Apttus_Proposal__Proposal__c objUpdate = [SELECT Id, Payer__c FROM Apttus_Proposal__Proposal__c WHERE Id = :objProposal.Id];
        System.assertEquals(objCMDBillTo.Id, objUpdate.Payer__c, 'Payer not setting as expected');

        Account_Relationship__c objGriffySelfPayer = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Slimy',
            Related_ERP_Customer_Id__c = 'Slimy',
            Relationship__c = Label.AccountGroupPayer,
            Account_Sales_Area__r = new Account_Sales_Area__c(ERP_Account_Sales_Area_Id__c = 'Slimy_HK010100')
        );
        insert objGriffySelfPayer;
        System.debug('Added relationship ' + objGriffySelfPayer);

        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objProposal), JSON.serialize(lstIndirect[0]),null, Label.AccountRelationshipBillTo, booDirect, strSalesArea);
        System.assertEquals('Success', strJSON, 'Update not happening as expected');
        objUpdate = [SELECT Id, Payer__c FROM Apttus_Proposal__Proposal__c WHERE Id = :objProposal.Id];
        System.assertEquals(objCMDDistributor.Id, objUpdate.Payer__c, 'Payer not setting as expected');
        Test.stopTest();
    }

}