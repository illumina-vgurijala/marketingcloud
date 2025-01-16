/**
 * @author Akshay Mohan 
 * @date   12-Sep-2018
 * @description    Class to handle defaulting of Bill to and Ship to on a quote
 * Modification Log:
*  --------------------------------------------------------------------------------------------------
*   Developer                Date                Description                                                 
*   Akshay Mohan             12-Sep-2018         Original
*   Rahul Sharma             18-Sep-2018         Adding checkSoldToUCUpdate Test Method
*   Rahul Sharma             25-Sep-2018         Adding CheckDistributorUpdate Test Method
*   Rahul Sharma             23-Oct-2018         Adding assert statements for DCP-14178
*   Gopinath Reddy           31-Oct-2018         Adding commonAssetLineItemBySoldToAndUCAccount for DCP-14180
*   Rahul Sharma             27-Nov-2018         Adding data for RTP fields as part of DCP-12852
*   Rahul Sharma             30-Nov-2018         Adding data for Incoterm1 as part of DCP-7554
*   Govind Dubey             03-Dec-2018         Adding checkShipToAfterUpdatingDistributor method    
*   Satya Swain              10-Sep-2019         Adding clearOpportunityCache for INC0225110 
*   Roopal Verma             13-Nov-2019         Adding method checkDefalutCMDSet for DCP-28541
*   Roopal Verma             02-Mar-2020         Added static strings for sonar qube fix
*      KD                   29-June-2021         DCP-46226 : Payment term defaulting for Greater china.   
*   Prem Ranjan             04 May 2022          CodeScan Fix (APEX) Unused Local Variable                        
*   Bharath Varma            18-May-2022         INC0395756 - Added logic to populate Incoterm value based on Ship To's Sales Area 
*  ---------------------------------------------------------------------------------------------------         
*/
@isTest(isParallel=true)
public class TestAutomateBillToShipToService {

    public static final String COUNTRY_HK = 'Hong Kong';                      //Sonar qube fix
    public static final String INCOTERM_CFR = 'CFR: Costs and freight';
    public static final String PL_AMR_USD = '01-AMR-USD';
    public static final String PL1_AMR_USD = 'AMR-USD-US-01';
    public static final String APPROVAL_REQ = 'Approval Required';
	public static boolean boolDontRunLogic = false;
  
    public static ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> {
            Account.SObjectType,
            Pricebook2.SObjectType,
            Opportunity.SObjectType,
            Apttus_Config2__PriceList__c.SObjectType,
            Apttus_Proposal__Proposal__c.SObjectType,
            Account_Sales_Area__c.SObjectType,
            Customer_Master_Data__c.SObjectType,
            Account_Relationship__c.SObjectType
    });

    /**
    * 
    *
    * @desc setupData [CodeScan Fix]
    */
    @testSetup
    public static void setupData()
    {
        Account objAccount = TestDataAccount.getAccount('Hogwarts');
        objAccount.ERP_Customer_Id__c = 'Hogy';
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        objAccount.RecordTypeId = recordtypeid;
        uow.registerNew(objAccount);
        Account objUC = TestDataAccount.getAccount('Gryffindoor');
        objUC.ERP_Customer_Id__c = 'Gryffy';
        objUC.RecordTypeId = recordtypeid;
        uow.registerNew(objUC);
        Account objDistributor = TestDataAccount.getAccount('Slytherin');
        objDistributor.ERP_Customer_Id__c = 'Slimy';
        objDistributor.Account_Group__c = Label.AccountGroupDistributor;
        objDistributor.RecordTypeId = recordtypeid;
        uow.registerNew(objDistributor);
        Account objDistributor2 = TestDataAccount.getAccount('James');
        objDistributor2.ERP_Customer_Id__c = 'Thomas';
        objDistributor2.Account_Group__c = Label.AccountGroupDistributor;
        objDistributor2.RecordTypeId = recordtypeid;
        uow.registerNew(objDistributor2);
        //Added for DCP-28541
    Account objDefaultCMD = TestDataAccount.getAccount('Lily');
        objDefaultCMD.ERP_Customer_Id__c = 'Buckbeak';
        objDefaultCMD.RecordTypeId = recordtypeid;
        uow.registerNew(objDefaultCMD);

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name = 'GCMD', Country__c = COUNTRY_HK, Country_Code__c = 'HK'),
                                objCMDSoldTo = new Customer_Master_Data__c(Name = 'HCMD', Country__c = COUNTRY_HK, Country_Code__c = 'HK'),
                                objCMDDefault = new Customer_Master_Data__c(Name = 'BCMD', Country__c = COUNTRY_HK, Country_Code__c = 'HK'); //Added for DCP-28541
        objCMDUC.ERP_Customer_Id__c = 'Gryffy';
        objCMDSoldTo.ERP_Customer_Id__c = 'Hogy';
        objCMDDefault.ERP_Customer_Id__c = 'Buckbeak';
        uow.registerNew(objCMDUC);
        uow.registerNew(objCMDSoldTo);
        uow.registerNew(objCMDDefault);

        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        uow.registerRelationship(objSoldToSA, Account_Sales_Area__c.Account__c, objAccount);
        objSoldToSA.Inco_Term_1__c = INCOTERM_CFR;
        //DCP-46226
        objSoldToSA.Term_Of_Payment__c = AutomateBillToShipToService.PAYMENT_TERM_PP00;
        uow.registerNew(objSoldToSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDSoldTo);
        Account_Sales_Area__c objUCSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Gryffy_HK010100','div1',false);
        uow.registerNew(objUCSA, Account_Sales_Area__c.Account__c, objUC);
        objUCSA.Inco_Term_1__c = INCOTERM_CFR;
        uow.registerRelationship(objUCSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDUC);

        //Added data for DCP-14178
        Account_Sales_Area__c objDistributorSA = TestDataAccountSalesArea.getAccountSalesArea('HK01','02','Thoma_HK010200','00',false);
        objDistributorSA.Contract_Number__c = 'Thomas_HK010200';
        //Added Data for DCP-11696
        objDistributorSA.Company_Code__c = 'US01';
        objDistributorSA.Price_List__c = PL_AMR_USD;
        objDistributorSA.Inco_Term_1__c = INCOTERM_CFR;
        uow.registerRelationship(objDistributorSA, Account_Sales_Area__c.Account__c, objDistributor2);
        uow.registerNew(objDistributorSA);

    Account_Sales_Area__c objDefaultASA = TestDataAccountSalesArea.getAccountSalesArea('HK01','01','Buckbeak_HK010100','00',false); //Added for DCP-28541
        objDefaultASA.Company_Code__c = 'US01';
        objDefaultASA.Price_List__c = PL_AMR_USD;
        uow.registerNew(objDefaultASA, Account_Sales_Area__c.Account__c, objDefaultCMD);
        objDefaultASA.Inco_Term_1__c = INCOTERM_CFR;
        uow.registerRelationship(objDefaultASA, Account_Sales_Area__c.Customer_Master_Data__c, objCMDDefault);

        Account_Relationship__c objSoldToBT = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Hogy',
            Related_ERP_Customer_Id__c = 'Gryffy',
            Relationship__c = Label.AccountRelationshipBillTo
        );
        uow.registerNew(objSoldToBT, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);

        Account_Relationship__c objUCST = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Gryffy',
            Related_ERP_Customer_Id__c = 'Gryffy',
            Relationship__c = Label.AccountRelationshipShipTo
        );
        uow.registerNew(objUCST, Account_Relationship__c.Account_Sales_Area__c, objUCSA);

        Account_Relationship__c objSoldToP = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Hogy',
            Related_ERP_Customer_Id__c = 'Hogy',
            Relationship__c = Label.AccountGroupPayer
        );
        uow.registerNew(objSoldToP, Account_Relationship__c.Account_Sales_Area__c, objSoldToSA);

        Account_Relationship__c objShipToP = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Gryffy',
            Related_ERP_Customer_Id__c = 'Hogy',
            Relationship__c = Label.AccountGroupPayer
        );
        uow.registerNew(objShipToP, Account_Relationship__c.Account_Sales_Area__c, objUCSA);

        Account_Relationship__c objDefBT = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Buckbeak', //Added for DCP-28541
            Related_ERP_Customer_Id__c = 'Buckbeak',
            Default_Partner__c = true,
            Relationship__c = Label.AccountRelationshipBillTo
        );
        uow.registerNew(objDefBT, Account_Relationship__c.Account_Sales_Area__c, objDefaultASA);

        Account_Relationship__c objDefBT2 = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Buckbeak',
            Related_ERP_Customer_Id__c = 'Hogy',
            Relationship__c = Label.AccountRelationshipBillTo
        );
        uow.registerNew(objDefBT2, Account_Relationship__c.Account_Sales_Area__c, objDefaultASA);

        Account_Relationship__c objDefSP = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Buckbeak',
            Related_ERP_Customer_Id__c = 'Buckbeak',
            Default_Partner__c = true,                                                                  
            Relationship__c = Label.AccountRelationshipShipTo
        );
        uow.registerNew(objDefSP, Account_Relationship__c.Account_Sales_Area__c, objDefaultASA);

        Account_Relationship__c objDefSP2 = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Buckbeak',
            Related_ERP_Customer_Id__c = 'Hogy',
            Relationship__c = Label.AccountRelationshipShipTo
        );
        uow.registerNew(objDefSP2, Account_Relationship__c.Account_Sales_Area__c, objDefaultASA);

        Pricebook2 objPricebook = new Pricebook2(Name='Book of prices', IsActive=true);
        uow.registerNew(objPricebook); 
        id idRecordTypeId = Opportunities.RECORD_TYPE_MAP.get(Label.OpportunityRTDirectFieldServices).getRecordTypeId();
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        uow.registerRelationship(objOpportunity, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity, Opportunity.Ultimate_Consignee__c, objUC);
        uow.registerRelationship(objOpportunity, Opportunity.Distributor__c, objDistributor2);
        objOpportunity.Name = 'Has Relationship';
        //DCP-46226
        objOpportunity.Product_Interest__c = Label.OpportunityProductInterestRelocation;
        objOpportunity.Type = Label.OpportunityTypeBillableService;
        objOpportunity.recordTypeId =idRecordTypeId;
        uow.registerNew(objOpportunity,Opportunity.AccountId,objAccount);

        Opportunity objOpportunity2 = TestDataOpportunity.initOpportunity(objUC);
        uow.registerRelationship(objOpportunity2, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity2, Opportunity.Ultimate_Consignee__c, objAccount);
        uow.registerRelationship(objOpportunity2, Opportunity.Distributor__c, objDistributor);
        objOpportunity2.Name = 'No Relationship';
        uow.registerNew(objOpportunity2,Opportunity.AccountId,objUC);

        Opportunity objOpportunity3 = TestDataOpportunity.initOpportunity(objAccount,'Indirect_Standard');
        uow.registerRelationship(objOpportunity3, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity3, Opportunity.Ultimate_Consignee__c, objUC);
        uow.registerRelationship(objOpportunity3, Opportunity.Distributor__c, objDistributor);
        objOpportunity3.Name = 'With Relationship'; 
        uow.registerNew(objOpportunity3,Opportunity.AccountId,objAccount);

        Opportunity objOpportunity4 = TestDataOpportunity.initOpportunity(objAccount,'Standard');
        uow.registerRelationship(objOpportunity4, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunity4, Opportunity.Ultimate_Consignee__c, objUC);
        uow.registerRelationship(objOpportunity4, Opportunity.Distributor__c, objDistributor);
        objOpportunity4.Name = 'RenewalOpportunity'; 
        objOpportunity4.Type = 'Upsell with Service Contract Renewal';
        objOpportunity4.Product_Interest__c = 'Instrument';
        uow.registerNew(objOpportunity4,Opportunity.AccountId,objAccount);

    Opportunity objOpportunityDef = TestDataOpportunity.initOpportunity(objDefaultCMD); //Added for DCP-28541
        uow.registerRelationship(objOpportunityDef, Opportunity.Pricebook2Id, objPricebook);
        uow.registerRelationship(objOpportunityDef, Opportunity.Ultimate_Consignee__c, objDefaultCMD);
        objOpportunityDef.Name = 'Default CMD';
        uow.registerNew(objOpportunityDef,Opportunity.AccountId,objDefaultCMD);

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PL1_AMR_USD);
        uow.registerNew(objPriceList);

        Apttus_Config2__PriceList__c objPriceList2 = TestDataProposal.initPriceList(PL_AMR_USD);
        uow.registerNew(objPriceList2);

        uow.commitWork();

        // create asset line for use by renewal opportunity / quote
        Product2 objProduct = TestDataMaster.initProduct('Cookie');
        objProduct.Material_Class__c = 'Instrument';
        insert objProduct;
        TestDataApttusAsset.getNewExpiredAssetLineItem(objAccount.Id, objUC.Id, objProduct.Id);
        
        //do update since lookup to CMD is not populated for some reason
        objSoldToSA.Customer_Master_Data__c = objCMDSoldTo.Id;
        objUCSA.Customer_Master_Data__c = objCMDUC.Id;
        objDefaultASA.Customer_Master_Data__c = objCMDDefault.Id;
        objOpportunity2.Price_List__c = PL1_AMR_USD;
    objOpportunityDef.Price_List__c = PL1_AMR_USD; //Added for DCP-28541
        update new List<sObject> { objSoldToSA, objUCSA, objOpportunity, objOpportunity2, objOpportunityDef, objOpportunity3, objOpportunity4, objDistributorSA, objDefaultASA };

        System.debug('objAccount: '+ objAccount);
        System.debug('objUC: '+ objUC);
        System.debug('objCMDUC: '+ objCMDUC);
        System.debug('objCMDSoldTo: '+ objCMDSoldTo);
        System.debug('objSoldToSA: '+ objSoldToSA);
        System.debug('objUCSA: '+ objUCSA);
        System.debug('objSoldToBT: '+ objSoldToBT);
        System.debug('objUCST: '+ objUCST);
        System.debug('objSoldToP: '+ objSoldToP);
        System.debug('objShipToP: '+ objShipToP);
        System.debug('objPricebook: '+ objPricebook);
        System.debug('objOpportunity: '+ objOpportunity);
        System.debug('objOpportunity2: '+ objOpportunity2);
        System.debug('objPriceList: '+ objPriceList);
    }

    /**
    * 
    *
    * @desc commonAssetLineItemBySoldToAndUCAccount [CodeScan Fix]
    */
    @isTest
    public static void commonAssetLineItemBySoldToAndUCAccount()
    {
        Test.startTest();
        Account accSoldTo = [SELECT Id FROM Account WHERE Name = 'Hogwarts'];
        Account accUC = [SELECT Id FROM Account WHERE Name = 'Gryffindoor'];

        Apttus_Config2__PriceList__c objPriceList = [SELECT Id, Name FROM Apttus_Config2__PriceList__c WHERE Name = 'AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);

        Opportunity objOpp = [SELECT Id, Ultimate_Consignee__c, AccountId FROM Opportunity WHERE Name = 'RenewalOpportunity'];
        System.debug('objOpp: ' + objOpp);

        Opportunity objOpp1 =[SELECT Id, Ultimate_Consignee__c, AccountId FROM Opportunity WHERE Name = 'With Relationship'];
        System.debug('objOpp1 : ' + objOpp1);

        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 1', objPriceList.id, true, 'Draft', 'None'
        );
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 2', objPriceList.id, true, 'Draft', 'None'
        );

        insert new List<Apttus_Proposal__Proposal__c> { objProp1, objProp2 };
        System.debug('objProp1: ' + objProp1);
        System.debug('objProp2: ' + objProp2);

        Apttus_Config2__AssetLineItem__c objAssetLineItem = [SELECT Id, Apttus_Config2__AccountId__c FROM Apttus_Config2__AssetLineItem__c];

        System.assertEquals(objAssetLineItem.Apttus_Config2__AccountId__c, accSoldTo.Id);
        System.assertNotEquals(objAssetLineItem.Apttus_Config2__AccountId__c, accUC.Id);
        Test.stopTest();
    }

    /**
    * 
    *
    * @desc checkSoldToDefault [CodeScan Fix]
    */
    @isTest
    public static void checkSoldToDefault()
    { 
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name='AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);
        Opportunity objOpp = [SELECT Id,Ultimate_Consignee__c, AccountId FROM Opportunity WHERE Name='No Relationship'];
        System.debug('objOpp: ' + objOpp);
        
        Set<String> setCMDERPs = new Set<String>{'Hogy','Gryffy'};
        Customer_Master_Data__c objCMDBillTo,objCMDShipTo;
        Account_Sales_Area__c objASA;
        for(Customer_Master_Data__c objCMD: [SELECT ID, ERP_Customer_Id__c,(SELECT Inco_Term_1__c FROM Account_Sales_Area__r ) FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
      if(objCMD.ERP_Customer_Id__c == 'Hogy'){
                objCMDBillTo = objCMD;
                objASA = objCMD.Account_Sales_Area__r[0];
            }
                
      if(objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
        }
        System.debug('objCMDBillTo: ' + objCMDBillTo);
        System.debug('objCMDShipTo: ' + objCMDShipTo);
        
        Test.startTest();
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(objOpp.AccountId, objOpp.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp1.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(objOpp.AccountId, objOpp.id, 'Test Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp2.Is_Updated_By_System__c= false;
        
        insert new List<Apttus_Proposal__Proposal__c>{objProp1,objProp2};
        System.debug('objProp1: ' + objProp1);
        System.debug('objProp2: ' + objProp2);

        for(Apttus_Proposal__Proposal__c objProp : [SELECT ID,Name,Bill_To__c,Payer__c,Ship_To__c,Opportunity_Record_Type__c,Inco_Term_1__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c like'Test%']){
            System.debug('objProp: '+objProp);
      System.assertEquals(objCMDShipTo.Id, objProp.Bill_To__c,'Bill To not defaulting');
      System.assertEquals(objCMDBillTo.Id, objProp.Ship_To__c,'Ship To not defaulting');                                                        
      System.assertEquals(objCMDBillTo.Id, objProp.Payer__c,'Payer not defaulting');  
            System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c,'Incoterm1 not defaulting');                                                      
        } 
        String strUC = objOpp.Ultimate_Consignee__c, strSoldTo=objOpp.AccountId;
        objOpp.Ultimate_Consignee__c = strSoldTo;
        objOpp.AccountId = strUC;
        System.debug('Opportunity update');
        // opportunity was created in this transaction, clear query cache for update
        OpportunitySelector.clearOpportunityCache();
        update objOpp;
        Test.stopTest();
        for(Apttus_Proposal__Proposal__c objProp : [SELECT ID,Name,Bill_To__c,Payer__c,Ship_To__c,Opportunity_Record_Type__c,Inco_Term_1__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c like'Test%']){
            System.debug('objProp: '+objProp);
      System.assertEquals(objCMDShipTo.Id, objProp.Bill_To__c,'Bill To changing post Opp change');
      System.assertEquals(objCMDShipTo.Id, objProp.Ship_To__c,'Ship To not changing post Opp change');                                                        
      System.assertEquals(objCMDBillTo.Id, objProp.Payer__c,'Payer changing post Opp change'); 
            System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c,'Incoterm1 not changing post Opp Change');                                                        
        } 
    }

    /**
    * 
    *
    * @desc checkBillToSet [CodeScan Fix]
    */
    @isTest
    public static void checkBillToSet()
    {
        Opportunity objOppHas, objOppNo; 
        for (Opportunity o :
            [SELECT Id, Name, Ultimate_Consignee__c, AccountId, RecordType.DeveloperName
             FROM Opportunity 
             WHERE Name IN ('Has Relationship', 'No Relationship')]
        ) {
      if (o.Name == 'Has Relationship'){
                objOppHas = o;
                objOppHas.Current_Ultimate_Consignee__c = o.AccountId; //DCP-46226
      }
      if (o.Name == 'No Relationship')
                objOppNo = o;
    }

        objOppHas.Price_List__c = PL1_AMR_USD;
        objOppNo.Price_List__c = PL1_AMR_USD;
        update new List<Opportunity> { objOppHas, objOppNo };
        System.debug('objOppHas: ' + objOppHas);
        System.debug('objOppNo: ' + objOppNo);

        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);

        Account_Sales_Area__c objASA = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c = 'Gryffy_HK010100'];

        Set<String> setCMDERPs = new Set<String> { 'Hogy', 'Gryffy' };
        Customer_Master_Data__c objCMDBillTo, objCMDShipTo; 
        for (Customer_Master_Data__c objCMD :
            [SELECT ID, ERP_Customer_Id__c
             FROM Customer_Master_Data__c 
             WHERE ERP_Customer_Id__c IN :setCMDERPs]
        ) {
      if (objCMD.ERP_Customer_Id__c == 'Hogy') 
                objCMDBillTo = objCMD;
      if (objCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDShipTo = objCMD;
        }
    System.debug('objCMDBillTo: ' + objCMDBillTo);
        System.debug('objCMDShipTo: ' + objCMDShipTo);
        
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(
            objOppHas.AccountId, objOppHas.id, 'Test Proposal 1', objPriceList.id, true, 'Draft', 'None'
        );
        objProp1.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(
            objOppHas.AccountId, objOppHas.id, 'Test Proposal 2', objPriceList.id, true, 'Draft', 'None'
        );
        objProp2.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(
            objOppNo.AccountId, objOppNo.id, 'Test Proposal 3', objPriceList.id, true, 'Draft', 'None'
        );
        objProp3.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp4 = TestDataProposal.initProposal(
            objOppNo.AccountId, objOppNo.id, 'Test Proposal 4', objPriceList.id, true, 'Draft', 'None'
        );
        objProp4.Is_Updated_By_System__c = false;

        Test.startTest();
        {
            insert new List<Apttus_Proposal__Proposal__c> { objProp1, objProp2, objProp3, objProp4 };
            System.debug('objProp1: ' + objProp1);
            System.debug('objProp2: ' + objProp2);
            System.debug('objProp3: ' + objProp3);
            System.debug('objProp4: ' + objProp4);

            Account_Sales_Area__c objASA2 = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c = 'Hogy_HK010100'];

            for (Apttus_Proposal__Proposal__c objProp :
                [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Apttus_Proposal__Proposal_Name__c, Inco_Term_1__c, Opportunity_Record_Type__c,
                Apttus_Proposal__Payment_Term__c //DCP-46226
                FROM Apttus_Proposal__Proposal__c 
                WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Test%']
            ) {
                System.debug('objProp: '+objProp);
                if (objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 1'
                    || objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 2'
                ) {
                    System.assertEquals(objCMDShipTo.Id, objProp.Bill_To__c, 'Bill To not set via relationship');
                    System.assertEquals(objCMDShipTo.Id, objProp.Ship_To__c, 'Ship To not set via relationship');
                    System.assertEquals(objCMDBillTo.Id, objProp.Payer__c, 'Payer not set via relationship');
                    System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c, 'Incoterm1 not set via relationship');
                    //DCP-46226
                    System.assertEquals(AutomateBillToShipToService.PAYMENT_TERM_NT00, objProp.Apttus_Proposal__Payment_Term__c, 'Incoterm1 not set via relationship');
                }

                if (objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 3'
                    || objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 4'
                ) {
                    System.assertEquals(objCMDShipTo.Id, objProp.Bill_To__c, 'Bill To not set via relationship');
                    System.assertEquals(objCMDBillTo.Id, objProp.Ship_To__c, 'Ship To not set via relationship');
                    System.assertEquals(objCMDBillTo.Id, objProp.Payer__c, 'Payer not set via relationship');
                    System.assertEquals(objASA2.Inco_Term_1__c, objProp.Inco_Term_1__c, 'Incoterm1 not set via relationship');
                }
            }
        }
        Test.stopTest();
    }

    /**
    * 
    *
    * @desc checkBillToBlank [CodeScan Fix]
    */
    @isTest
    public static void checkBillToBlank()
    {
        Set<String> setERPIds = new Set<String>{'Hogy', 'Gryffy'};

        Account_Sales_Area__c objSoldToSA, objUCSA;  
        for (Account_Sales_Area__c asa : [SELECT Id, Name, Account__r.ERP_Customer_Id__c
                                          FROM Account_Sales_Area__c
                                          WHERE Account__r.ERP_Customer_Id__c IN :setERPIds])
        {
      if (asa.Account__r.ERP_Customer_Id__c == 'Hogy')
                objSoldToSA = asa;
      if (asa.Account__r.ERP_Customer_Id__c == 'Gryffy')
                objUCSA =asa;
    }
        System.debug('objSoldToSA: ' + objSoldToSA);
        System.debug('objUCSA: ' + objUCSA);

        Account_Relationship__c objSoldToBT = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
                                            Relationship__c = Label.AccountRelationshipBillTo,
                                                                          Account_Sales_Area__c = objSoldToSA.Id);

        Account_Relationship__c objUCST = new Account_Relationship__c(ERP_Customer_Id__c = 'Gryffy',
                                                                      Related_ERP_Customer_Id__c ='Gryffy',
                                          Relationship__c = Label.AccountRelationshipShipTo,
                                                                      Account_Sales_Area__c = objUCSA.Id);
        insert new List<Account_Relationship__c> { objSoldToBT, objUCST };

        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);
        Opportunity objOpp = [SELECT Id,Ultimate_Consignee__c, AccountId, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Price_List__c
                                FROM Opportunity WHERE Name = 'Has Relationship'];
        objOpp.Price_List__c = PL1_AMR_USD;
        objOpp.Current_Ultimate_Consignee__c = objOpp.AccountId;  // DCP-46226
        update objOpp;
        System.debug('objOpp: ' + objOpp + '__'+objOpp.Price_List__c );

    Test.startTest();
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(objOpp.AccountId, objOpp.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp1.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(objOpp.AccountId, objOpp.id, 'Test Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp2.Is_Updated_By_System__c= false;
        insert new List<Apttus_Proposal__Proposal__c> { objProp1, objProp2 };
        Test.stopTest();
        System.debug('objProp1: ' + objProp1);
        System.debug('objProp2: ' + objProp2);

        for (Apttus_Proposal__Proposal__c objProp : [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c,Inco_Term_1__c
                                                     FROM Apttus_Proposal__Proposal__c
                                                     WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Test%'])
        {
            System.debug('objProp: ' + objProp);
      System.assert(String.isBlank(objProp.Bill_To__c), 'Bill To not blanking out');
      System.assert(String.isBlank(objProp.Ship_To__c), 'Ship To not blanking out');
      System.assert(String.isBlank(objProp.Payer__c), 'Payer not blanking out');
            System.assert(String.isBlank(objProp.Inco_Term_1__c), 'Incoterm1 not blanking out');
        }
    }

    /**
    * 
    *
    * @desc checkShipToDistributorDefault [CodeScan Fix]
    */
    @isTest
    public static void checkShipToDistributorDefault()
    {
        Set<String> setAccountERPs = new Set<String>{'Thomas','Hogy'};
        Account objAccNotSetup, objSoldto;
        for (Account objAccount :
            [SELECT Id, Name, ERP_Customer_Id__c
             FROM Account 
             WHERE ERP_Customer_Id__c IN :setAccountERPs]
        ) {
            if (objAccount.ERP_Customer_Id__c == 'Hogy')
                objSoldto = objAccount;
      if (objAccount.ERP_Customer_Id__c == 'Thomas')
                objAccNotSetup =objAccount;
        }
        System.debug('objSoldto: ' + objSoldto);
        objSoldto.Account_Group__c = Label.AccountGroupDistributor;
        update objSoldto;
        System.debug('objAccNotSetup: ' + objAccNotSetup);

        Customer_Master_Data__c objCMDShipTo = new Customer_Master_Data__c(
            Name = 'SCMD', Account_Group__c = Label.AccountGroupSoldTo, ERP_Customer_Id__c = 'Slimy'
        );
        uow.registerNew(objCMDShipTo);
        Customer_Master_Data__c objCMD = new Customer_Master_Data__c(
            Name = 'TCMD', Account_Group__c = Label.AccountGroupDistributor, ERP_Customer_Id__c = 'Thomas');
        uow.registerNew(objCMD);

        Account_Sales_Area__c objSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Thomas_HK010200','div1',false);
        objSA.Account__c = objAccNotSetup.Id;
        objSA.Inco_Term_1__c = INCOTERM_CFR;
        uow.registerNew(objSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMD);

        Account_Sales_Area__c objSA2 = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Thomas_HK010100','div1',false);
        objSA2.Account__c = objAccNotSetup.Id;
        uow.registerNew(objSA2, Account_Sales_Area__c.Customer_Master_Data__c, objCMD);

        Account_Relationship__c objBillTo = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Thomas', Related_ERP_Customer_Id__c = 'Thomas', Relationship__c = Label.AccountRelationshipBillTo
        );
        uow.registerNew(objBillTo, Account_Relationship__c.Account_Sales_Area__c, objSA2);

        Account_Relationship__c objShipTo = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Thomas', Related_ERP_Customer_Id__c = 'Thomas', Relationship__c = Label.AccountRelationshipShipTo
        );
        uow.registerNew(objShipTo, Account_Relationship__c.Account_Sales_Area__c, objSA);

        Account_Relationship__c objPayer = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Thomas', Related_ERP_Customer_Id__c = 'Thomas', Relationship__c = Label.AccountGroupPayer
        );
        uow.registerNew(objPayer, Account_Relationship__c.Account_Sales_Area__c, objSA2);

        uow.commitWork();

        objSA.Customer_Master_Data__c = objCMD.Id;
        objSA2.Customer_Master_Data__c = objCMD.Id;
        update new List<sObject> { objSA, objBillTo, objShipTo, objPayer, objSA2 };
        System.debug('objCMD: ' + objCMD);
        System.debug('objSA: ' + objSA);
        System.debug('objSA2: ' + objSA2);
        System.debug('objBillTo: ' + objBillTo);
        System.debug('objShipTo: ' + objShipTo);
        System.debug('objPayer: ' + objPayer);
        
        Opportunity objOpp = [SELECT Id, RecordType.DeveloperName, Ultimate_Consignee__c, AccountId,Distributor__c, Direct_Sale_to_Ultimate_Consignee__c
            FROM Opportunity WHERE Name = 'With Relationship'];
        objOpp.Direct_Sale_to_Ultimate_Consignee__c = false;
        objOpp.Price_List__c = PL_AMR_USD;
        update objOpp;
        System.debug('objOpp: ' + JSON.serialize(objOpp));

        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);

        Set<String> setCMDERPs = new Set<String> { 'Gryffy', 'Hogy' };
        Customer_Master_Data__c objCMDBillTo, objCMDPayer;
        for (Customer_Master_Data__c oCMD :
            [SELECT Id, ERP_Customer_Id__c
             FROM Customer_Master_Data__c 
             WHERE ERP_Customer_Id__c IN :setCMDERPs]
        ) {
      if (oCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDBillTo = oCMD;
            if (oCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDPayer = oCMD;
        }
        System.debug('objCMDBillTo: ' + objCMDBillTo);
        System.debug('objCMDShipTo: ' + objCMDShipTo);
        System.debug('objCMDPayer: ' + objCMDPayer);

        Test.startTest();
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 1', objPriceList.id, true, 'Draft', 'None'
        );
        objProp1.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 2', objPriceList.id, true, 'Draft', 'None'
        );
        objProp2.Is_Updated_By_System__c= false;
        insert new List<Apttus_Proposal__Proposal__c> { objProp1, objProp2 };
        System.debug('objProp1: ' + objProp1);
        System.debug('objProp2: ' + objProp2);

        Account_Sales_Area__c objASA = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c = 'Thomas_HK010100'];

        for (Apttus_Proposal__Proposal__c objProp :
            [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Inco_Term_1__c
             FROM Apttus_Proposal__Proposal__c 
             WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Test%']
        ) {
            System.debug('objProp: '+objProp);
      System.assertEquals(objCMDBillTo.Id, objProp.Bill_To__c,'Bill To not defaulting');
      System.assertEquals(objCMDShipTo.Id, objProp.Ship_To__c,'Ship To not defaulting');
      System.assertEquals(objCMDPayer.Id, objProp.Payer__c,'Payer not defaulting');
            System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c,'Incoterm1 not defaulting');
        } 

        objOpp.AccountId = objAccNotSetup.Id;
        objOpp.Distributor__c = objAccNotSetup.Id;
        System.debug('Updating Opp');
        // opportunity was already updated in this transaction, clear query cache for new update
        OpportunitySelector.clearOpportunityCache();
        update objOpp;
        Test.stopTest();

        objOpp = new OpportunitySelector().selectOpportunities(new Set<Id>{objOpp.Id}).get(0);
        System.debug('objOpp: '+JSON.serialize(objOpp));

        Account_Sales_Area__c objASA2 = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c = 'Thomas_HK010200'];

        for (Apttus_Proposal__Proposal__c objProp :
            [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Inco_Term_1__c
             FROM Apttus_Proposal__Proposal__c 
             WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Test%']
        ) {
            System.debug('objProp: '+objProp);
      System.assertEquals(objCMD.Id, objProp.Ship_To__c,'Ship To not defaulting');  
            System.assertEquals(objASA2.Inco_Term_1__c, objProp.Inco_Term_1__c,'Incoterm1 not defaulting');                                                      
        } 

    }

    /**
    * 
    *
    * @desc checkShipToDistributorOnUpdate [CodeScan Fix]
    */
    @isTest
    public static void checkShipToDistributorOnUpdate()
    {
        Set<String> setAccountERPs = new Set<String>{'Thomas','Hogy','Slimy'};
        Account objAccNotSetup, objSoldto, objUC, objDistributor; 
        for(Account objAccount: [SELECT Id,Name,ERP_Customer_Id__c FROM Account 
                                WHERE ERP_Customer_Id__c IN :setAccountERPs]) {
            if(objAccount.ERP_Customer_Id__c=='Hogy')
                objSoldto = objAccount;
            if(objAccount.ERP_Customer_Id__c=='Thomas')
                objAccNotSetup =objAccount;
            if(objAccount.ERP_Customer_Id__c=='Slimy')
                objDistributor = objAccount;
        }
        System.debug('objSoldto: ' + objSoldto);
        objSoldto.Account_Group__c =Label.AccountGroupDistributor;
        update objSoldto;
        System.debug('objAccNotSetup: ' + objAccNotSetup);
        System.debug('objAccNotSetup: ' + objUC);
        Customer_Master_Data__c objCMDofUC = [SELECT Id FROM Customer_Master_Data__c WHERE Name='GCMD'];
        Customer_Master_Data__c objCMDShipTo = new Customer_Master_Data__c(Name='SCMD'
                                                                    ,Account_Group__c=Label.AccountGroupSoldTo);
        objCMDShipTo.ERP_Customer_Id__c = 'Slimy';
        uow.registerNew(objCMDShipTo);
        Customer_Master_Data__c objCMD = new Customer_Master_Data__c(Name='TCMD'
                                                                    ,Account_Group__c=Label.AccountGroupDistributor);
        objCMD.ERP_Customer_Id__c = 'Thomas';
        uow.registerNew(objCMD);

        Account_Sales_Area__c objDistribSA = TestDataAccountSalesArea.getAccountSalesArea('HK01','01','Slimy_HK010100','00',false);
        uow.registerNew(objDistribSA, Account_Sales_Area__c.Account__c, objDistributor);

        Account_Sales_Area__c objSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Thomas_HK010200','div1',false);
        objSA.Account__c = objAccNotSetup.Id;
        uow.registerNew(objSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMD);

        Account_Sales_Area__c objSA2 = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Thomas_HK010100','div1',false);
        objSA2.Account__c = objAccNotSetup.Id;
        uow.registerNew(objSA2, Account_Sales_Area__c.Customer_Master_Data__c, objCMD);
        
        Account_Relationship__c objBillTo = new Account_Relationship__c(ERP_Customer_Id__c = 'Thomas',
                                                                          Related_ERP_Customer_Id__c ='Thomas',
                                                                            Relationship__c=Label.AccountRelationshipBillTo);
        uow.registerNew(objBillTo, Account_Relationship__c.Account_Sales_Area__c, objSA2);
        
        Account_Relationship__c objShipTo = new Account_Relationship__c(ERP_Customer_Id__c = 'Thomas',
                                                                          Related_ERP_Customer_Id__c ='Thomas',
                                                                            Relationship__c=Label.AccountRelationshipShipTo);
        uow.registerNew(objShipTo, Account_Relationship__c.Account_Sales_Area__c, objSA);
        
        Account_Relationship__c objPayer = new Account_Relationship__c(ERP_Customer_Id__c = 'Thomas',
                                                                          Related_ERP_Customer_Id__c ='Thomas',
                                                                            Relationship__c=Label.AccountGroupPayer);
        uow.registerNew(objPayer, Account_Relationship__c.Account_Sales_Area__c, objSA2);

        uow.commitWork();
        update new List<sObject>{objSA,objBillTo,objShipTo,objPayer,objSA2,objDistribSA};
        objDistribSA.Customer_Master_Data__c = objCMDShipTo.Id;
        update objDistribSA;
        System.debug('objCMD: ' + objCMD);
        System.debug('objSA: ' + objSA);
        System.debug('objSA2: ' + objSA2);
        System.debug('objBillTo: ' + objBillTo);
        System.debug('objShipTo: ' + objShipTo);
        System.debug('objPayer: ' + objPayer);
        System.debug('objDistribSA: ' + objDistribSA);
        Opportunity objOpp = [SELECT Id,RecordType.DeveloperName,Ultimate_Consignee__c, Ultimate_Consignee__r.ERP_Customer_Id__c, AccountId,Distributor__c, Direct_Sale_to_Ultimate_Consignee__c
                                FROM Opportunity WHERE Name='With Relationship'];     
        objOpp.Price_List__c = PL_AMR_USD;
        update objOpp;              
        System.debug('objOpp: ' + JSON.serialize(objOpp));
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name='AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);
        Set<String> setCMDERPs = new Set<String>{'Gryffy','Hogy','Slimy'};
        Customer_Master_Data__c objCMDBillTo, objCMDPayer;
        for(Customer_Master_Data__c oCMD: [SELECT ID, ERP_Customer_Id__c FROM Customer_Master_Data__c 
                                             WHERE ERP_Customer_Id__c IN :setCMDERPs]){
            if(oCMD.ERP_Customer_Id__c == 'Gryffy')
                objCMDBillTo = oCMD;
            if(oCMD.ERP_Customer_Id__c == 'Hogy')
                objCMDPayer = oCMD;
            if(oCMD.ERP_Customer_Id__c == 'Slimy')
                objCMDShipTo = oCMD;
        }
        System.debug('objCMDBillTo: ' + objCMDBillTo);
        System.debug('objCMDShipTo: ' + objCMDShipTo);
        System.debug('objCMDPayer: ' + objCMDPayer);
        
        Test.startTest();
        
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(objOpp.AccountId, objOpp.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp1.Is_Updated_By_System__c= false;
        
        insert new List<Apttus_Proposal__Proposal__c>{objProp1};
        
        Account_Sales_Area__c objASA = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c='Gryffy_HK010100'];

        for(Apttus_Proposal__Proposal__c objProp : [SELECT ID,Name,Bill_To__c,Payer__c,Ship_To__c,Inco_Term_1__c,Opportunity_Record_Type__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c like'Test%']){
            System.debug('objProp: '+objProp);
            System.assertEquals(objCMDBillTo.Id, objProp.Bill_To__c,'Bill To not defaulting');
            System.assertEquals(objCMDofUC.Id, objProp.Ship_To__c,'Ship To not defaulting');                                                        
            System.assertEquals(objCMDPayer.Id, objProp.Payer__c,'Payer not defaulting'); 
            System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c,'Incoterm1 not defaulting');                                                        
        } 

        objDistributor = TestDataAccount.getAccount('Test Dist');
        objDistributor.ERP_Customer_Id__c = 'Test';
        objDistributor.Account_Group__c = Label.AccountGroupDistributor;
        insert objDistributor;
        objOpp.Distributor__c = objDistributor.Id;
        // opportunity was already updated in this transaction, clear query cache for new update
        OpportunitySelector.clearOpportunityCache();
        update objOpp;

        Account objUltimateCons = TestDataAccount.getAccount('Test Cons');
        objUltimateCons.ERP_Customer_Id__c = 'TestCons';
        insert objUltimateCons;
        objOpp.Ultimate_Consignee__c = objUltimateCons.Id;
        // opportunity was already updated in this transaction, clear query cache for new update
        OpportunitySelector.clearOpportunityCache();
        update objOpp;
        for (Apttus_Proposal__Proposal__c objProp :
            [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Inco_Term_1__c
             FROM Apttus_Proposal__Proposal__c
             WHERE Apttus_Proposal__Proposal_Name__c like'Test%']
        ) {
            System.debug('objProp: '+objProp);
            System.assertEquals(null,objProp.Ship_To__c,'Ship To not changed to null');   
            System.assertEquals(null,objProp.Inco_Term_1__c,'Incoterm1 not changed to null');                                                      
        } 
        Test.stopTest();
    }

    /**
    * 
    *
    * @desc checkIncompleteSetup [CodeScan Fix]
    */
    @isTest
    public static void checkIncompleteSetup()
    {
        Account objAccNotSetup = [SELECT Id, Name, ERP_Customer_Id__c FROM Account WHERE ERP_Customer_Id__c = 'Slimy'];
        System.debug('objAccNotSetup: ' + objAccNotSetup);
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);

        Opportunity objOpp = [SELECT Id,Ultimate_Consignee__c, AccountId FROM Opportunity WHERE Name = 'Has Relationship'];
        objOpp.Ultimate_Consignee__c = objAccNotSetup.Id;
        objOpp.AccountId = objAccNotSetup.Id;
        objOpp.Current_Ultimate_Consignee__c = objAccNotSetup.Id; //DCP-46226
        update objOpp;
        objOpp.Price_List__c = PL1_AMR_USD;
        update objOpp;
        System.debug('objOpp: ' + objOpp);

        Customer_Master_Data__c objShipToCMD =
            [SELECT Id, ERP_Customer_Id__c
             FROM Customer_Master_Data__c 
             WHERE ERP_Customer_Id__c = 'Hogy'];

        Test.startTest();
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 1', objPriceList.id, true, 'Draft', 'None'
        );
        objProp1.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 2', objPriceList.id, true, 'Draft', 'None'
        );
        objProp2.Is_Updated_By_System__c = false;
        insert new List<Apttus_Proposal__Proposal__c> { objProp1, objProp2 };

        for (Apttus_Proposal__Proposal__c objProp :
            [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Inco_Term_1__c
             FROM Apttus_Proposal__Proposal__c
             WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Test%']
        ) {
            System.debug('objProp: '+objProp);
      System.assert(String.isBlank(objProp.Bill_To__c), 'Bill To not blanking out');
      System.assert(String.isBlank(objProp.Ship_To__c), 'Ship To not blanking out');  
            System.assert(String.isBlank(objProp.Inco_Term_1__c), 'Incoterm1 not blanking out');                                                       
      System.assert(String.isBlank(objProp.Payer__c), 'Payer not blanking out');                                                        
        }

        Customer_Master_Data__c objCMD = new Customer_Master_Data__c(
            Name = 'SCMD', Country__c = COUNTRY_HK, Country_Code__c = 'HK', Account_Group__c = Label.AccountGroupSoldTo
        );
        objCMD.ERP_Customer_Id__c = 'Slimy';
        uow.registerNew(objCMD);

        Account_Sales_Area__c objSA = TestDataAccountSalesArea.getAccountSalesArea('org1', 'ch1', 'Slimy_HK010100', '00', false);
        objSA.Account__c = objAccNotSetup.Id;
        objSA.Inco_Term_1__c = INCOTERM_CFR;
        uow.registerNew(objSA, Account_Sales_Area__c.Customer_Master_Data__c, objCMD);

        Account_Relationship__c objBillTo = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Slimy', Related_ERP_Customer_Id__c = 'Slimy', Relationship__c = Label.AccountRelationshipBillTo
        );
        uow.registerNew(objBillTo, Account_Relationship__c.Account_Sales_Area__c, objSA);

        Account_Relationship__c objShipTo = new Account_Relationship__c(
            ERP_Customer_Id__c = 'Slimy', Related_ERP_Customer_Id__c = 'Hogy', Relationship__c = Label.AccountRelationshipShipTo
        );
        uow.registerNew(objShipTo, Account_Relationship__c.Account_Sales_Area__c, objSA);

        uow.commitWork();

        objSA.Customer_Master_Data__c = objCMD.Id;
        update new List<sObject> { objSA, objBillTo, objShipTo };
        System.debug('Setup done');
        System.debug('objCMD: ' + objCMD);
        System.debug('objSA: ' + objSA);
        System.debug('objBillTo: ' + objBillTo);
        System.debug('objShipTo: ' + objShipTo);

        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 3', objPriceList.Id, true, 'Draft', 'None'
        );
        objProp3.Is_Updated_By_System__c = false;
        Apttus_Proposal__Proposal__c objProp4 = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 4', objPriceList.Id, true, 'Draft', 'None'
        );
        objProp4.Is_Updated_By_System__c = false;
        insert new List<Apttus_Proposal__Proposal__c> { objProp3, objProp4 };

        // INC0395756 - Updated ERP_Account_Sales_Area_Id__c based on the related ERP ID of SHip to account relationship record
        Account_Sales_Area__c objASA = [SELECT Inco_Term_1__c FROM Account_Sales_Area__c WHERE ERP_Account_Sales_Area_Id__c = 'Hogy_HK010100'];

        for (Apttus_Proposal__Proposal__c objProp :
            [SELECT Id, Name, Bill_To__c, Payer__c, Ship_To__c, Inco_Term_1__c
             FROM Apttus_Proposal__Proposal__c
             WHERE Apttus_Proposal__Proposal_Name__c IN ('Test Proposal 3','Test Proposal 4')]
        ) {
            System.debug('objProp: ' + objProp);
            System.debug('Incomplete Setup');
      System.assertEquals(objCMD.Id, objProp.Bill_To__c, 'Bill To not setting');
      System.assertEquals(objShipToCMD.Id, objProp.Ship_To__c, 'Ship To not setting');                                                        
      System.assertEquals(objCMD.Id, objProp.Payer__c, 'Payer not setting'); 
            // INC0395756 - Added logic to populate Incoterm value based on Ship To's Sales Area 
            System.assertEquals(objASA.Inco_Term_1__c, objProp.Inco_Term_1__c, 'Incoterm1 not setting');                                                         
        }
        Test.stopTest();
    }

    /**
    * 
    *
    * @desc checkSoldToUSUpdate [CodeScan Fix]
    */
    @isTest
    public static void checkSoldToUCUpdate()
    {
        //Added below account sales area for DCP-14178
        Account objUC = [SELECT Id,Name FROM Account WHERE Name='Gryffindoor' LIMIT 1];
        Account_Sales_Area__c objUCSA2 = TestDataAccountSalesArea.getAccountSalesArea('HK01','01','Gryff_HK010100','00',false);
        objUCSA2.Contract_Number__c = 'Gryffy_HK010100';
        objUCSA2.Price_List__c = PL_AMR_USD;
        objUCSA2.Account__c = objUC.Id;   
        insert objUCSA2;

        Opportunity objOppHas, objOppNo;
        for(Opportunity o: [SELECT Id,Name,Ultimate_Consignee__c, AccountId,RecordType.DeveloperName FROM Opportunity 
                            WHERE Name IN ('Has Relationship','No Relationship')]){
            if(o.Name == 'Has Relationship'){
                objOppHas =o; 
                objOppHas.Current_Ultimate_Consignee__c = o.AccountId; //DCP-46226
            }
            if(o.Name == 'No Relationship')
                objOppNo =o;
        }
        objOppHas.Price_List__c = PL1_AMR_USD;
        objOppNo.Price_List__c = PL1_AMR_USD;
        update new List<Opportunity>{objOppHas,objOppNo};
        System.debug('objOppHas: ' + objOppHas);
        System.debug('objOppNo: ' + objOppNo);

        
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name='AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);
       
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(objOppHas.AccountId, objOppHas.id, 'Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp1.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(objOppHas.AccountId, objOppHas.id, 'Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp2.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(objOppHas.AccountId, objOppHas.id, 'Proposal 3', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp3.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp4 = TestDataProposal.initProposal(objOppNo.AccountId, objOppNo.id, 'Proposal 4', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp4.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp5 = TestDataProposal.initProposal(objOppNo.AccountId, objOppNo.id, 'Proposal 5', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp5.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp6 = TestDataProposal.initProposal(objOppNo.AccountId, objOppNo.id, 'Proposal 6', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objProp6.Is_Updated_By_System__c= false;
                                                                                 
        insert new List<Apttus_Proposal__Proposal__c>{objProp1,objProp2,objProp3,objProp4,objProp5,objProp6};
        Test.startTest();
        objProp2.Apttus_Proposal__Approval_Stage__c =APPROVAL_REQ;
        objProp3.Apttus_Proposal__Approval_Stage__c ='Approved';
        objProp5.Apttus_Proposal__Approval_Stage__c =APPROVAL_REQ;
        objProp6.Apttus_Proposal__Approval_Stage__c ='Approved';
        update new List<Apttus_Proposal__Proposal__c>{objProp2,objProp3,objProp5,objProp6};

        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        String strUC = objOppHas.Ultimate_Consignee__c,strSoldTo=objOppNo.AccountId;
        objOppHas.AccountId = strSoldTo;
        objOppNo.Ultimate_Consignee__c = strUC;
        Id recordTypeID = rts.get('Direct Standard').getRecordTypeId();
        objOppNo.RecordTypeId = recordTypeID;

        // opportunity was already updated in this transaction, clear query cache for new update
        OpportunitySelector.clearOpportunityCache();
        
        update new List<Opportunity>{objOppHas,objOppNo};
        List<Apttus_Proposal__Proposal__c> lstProps = [SELECT Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Approval_Stage__c,
                                                    Apttus_QPApprov__Approval_Status__c,Id,Ultimate_Consignee__c,Apttus_Proposal__Account__c,
                                                    Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,Contract_Numbers__c,
                                                    Apttus_Proposal__Opportunity__r.Contract_Number__c,Apttus_QPConfig__PriceListId__c,
                                                    Apttus_Proposal__Opportunity__r.Price_List__c,Apttus_QPConfig__PriceListId__r.Name,
                                                    Sold_To_Sales_Organization__c,Sold_To_Distribution_Channel__c,Sold_To_Division__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Division__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c like'Proposal%'];
        System.debug('lstProps: ' + lstProps);
        Test.stopTest(); 
        for(Apttus_Proposal__Proposal__c objProp : lstProps){
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 1'){ 
                System.assertEquals(objProp.Apttus_Proposal__Account__c,objOppHas.AccountId,'Sold To not changing post Opp Change');  
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');

            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 2'){ 
                System.assertEquals(objProp.Apttus_Proposal__Account__c,objOppHas.AccountId,'Sold To not changing post Opp change');  
                System.assertEquals('Draft',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp Change');  
                System.assertEquals('None',objProp.Apttus_QPApprov__Approval_Status__c,'Approval Status not changing post Opp change');
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');  
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 3'){ 
                System.assertEquals('Denied',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp change');  
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 4'){ 
                System.assertEquals(objProp.Ultimate_Consignee__c,objOppNo.Ultimate_Consignee__c,'UC not changing post Opp change');
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');  
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 5'){ 
                System.assertEquals(objProp.Ultimate_Consignee__c,objOppNo.Ultimate_Consignee__c,'UC not changing post Opp change');
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');
                if(objProp.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName == 'Direct Standard'){
                    System.assertEquals('Draft',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp Change');  
                    System.assertEquals('None',objProp.Apttus_QPApprov__Approval_Status__c,'Approval Status not changing post Opp change');   
                }
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 6'){ 
                System.assertEquals('Denied',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp change');  
            }
                              
        }
          
    }

    /**
    * 
    *
    * @desc checkDistributorUpdate [CodeScan Fix]
    */
    @isTest
    public static void checkDistributorUpdate() {

        Opportunity objOppHas, objOppWith;
        for(Opportunity o: [SELECT Id,Name,Ultimate_Consignee__c, AccountId,RecordType.DeveloperName,Distributor__c FROM Opportunity 
                            WHERE Name IN ('Has Relationship','With Relationship')]){
            if(o.Name == 'Has Relationship')
                objOppHas =o; 
            if(o.Name == 'With Relationship')
                objOppWith =o;
        }

        
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name='AMR-USD-US-01'];
        System.debug('objPriceList: ' + objPriceList);
        
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(objOppWith.AccountId, objOppWith.id, 'Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        //objProp1.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(objOppWith.AccountId, objOppWith.id, 'Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        //objProp2.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(objOppWith.AccountId, objOppWith.id, 'Proposal 3', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        //objProp3.Is_Updated_By_System__c= false;
                                                                                 
        insert new List<Apttus_Proposal__Proposal__c>{objProp1,objProp2,objProp3};

        objProp2.Apttus_Proposal__Approval_Stage__c =APPROVAL_REQ;
        objProp3.Apttus_Proposal__Approval_Stage__c ='Approved';
        update new List<Apttus_Proposal__Proposal__c>{objProp2,objProp3};

        String strDistributor = objOppHas.Distributor__c;
        objOppWith.Distributor__c = strDistributor;

        Test.startTest();
		boolDontRunLogic = true;
        update new List<Opportunity>{objOppWith};

        List<Apttus_Proposal__Proposal__c> lstProps = [SELECT Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Approval_Stage__c,
                                                    Apttus_QPApprov__Approval_Status__c,Id,Ultimate_Consignee__c,Apttus_Proposal__Account__c, 
                                                    Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,Distributor__c,Contract_Numbers__c,
                                                    Apttus_Proposal__Opportunity__r.Contract_Number__c,Apttus_QPConfig__PriceListId__c,
                                                    Apttus_Proposal__Opportunity__r.Price_List__c,Apttus_QPConfig__PriceListId__r.Name,
                                                    Sold_To_Sales_Organization__c,Sold_To_Distribution_Channel__c,Sold_To_Division__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,
                                                    Apttus_Proposal__Opportunity__r.Sold_to_Division__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c like'Proposal%'];

        for(Apttus_Proposal__Proposal__c objProp : lstProps){
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 1'){ 
                System.assertEquals(objProp.Distributor__c,objOppHas.Distributor__c,'Distributor not changing post Opp Change');  
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 2'){ 
                System.assertEquals(objProp.Distributor__c,objOppHas.Distributor__c,'Distributor not changing post Opp change');
                System.assertEquals(objProp.Contract_Numbers__c,objProp.Apttus_Proposal__Opportunity__r.Contract_Number__c,'Contract Number not changing post Opp Change');  
                System.assertEquals('Draft',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp Change');  
                System.assertEquals('None',objProp.Apttus_QPApprov__Approval_Status__c,'Approval Status not changing post Opp change');  
                System.assertEquals(objProp.Apttus_QPConfig__PriceListId__r.Name,objProp.Apttus_Proposal__Opportunity__r.Price_List__c,'Price List not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Sales_Organization__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Sales_Organization__c,'Sold To Sales Org not changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Distribution_Channel__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel changing post Opp Change');
                System.assertEquals(objProp.Sold_To_Division__c,objProp.Apttus_Proposal__Opportunity__r.Sold_to_Division__c,'Sold To Division not changing post Opp Change');
            }
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Proposal 3'){ 
                System.assertEquals('Denied',objProp.Apttus_Proposal__Approval_Stage__c,'Quote Stage not changing post Opp change');  
            }
                              
        }
        Test.stopTest();   
    }
  
    /**
    * 
    *
    * @desc checkDefalutCMDSet [CodeScan Fix]
    */
  @isTest
    public static void checkDefalutCMDSet(){

        Opportunity defOpp = [SELECT Id,Name,Account.Name,Ultimate_Consignee__r.Name,Price_List__c,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c From Opportunity WHERE Name = 'Default CMD' LIMIT 1 ];
        System.debug('defOpp: '+defOpp);

        Apttus_Config2__PriceList__c objPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name='AMR-USD-US-01'];

        Customer_Master_Data__c objCMD = [SELECT Id, NAme FROM Customer_Master_Data__c WHERE NAme = 'BCMD'];
        System.debug('objCMD: '+objCMD);

        Test.startTest();
        Apttus_Proposal__Proposal__c objPropdef = TestDataProposal.initProposal(defOpp.AccountId, defOpp.id, 'Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objPropdef.Is_Updated_By_System__c= false;
        Apttus_Proposal__Proposal__c objPropdef2 = TestDataProposal.initProposal(defOpp.AccountId, defOpp.id, 'Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        objPropdef2.Is_Updated_By_System__c= false;
        insert new List<Apttus_Proposal__Proposal__c>{objPropdef,objPropdef2};

        Apttus_Proposal__Proposal__c objPropUpdated = [SELECT ID,Name,Bill_To__c,Ship_To__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c = 'Proposal 1'];
        Apttus_Proposal__Proposal__c objPropUpdated2 = [SELECT ID,Name,Bill_To__c,Ship_To__c FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c = 'Proposal 2'];

        System.debug('objPropUpdated: '+objPropUpdated);
        System.assertEquals(objCMD.Id,objPropUpdated.Bill_To__c,'Bill To not defaulting');
        System.assertEquals(objCMD.Id,objPropUpdated.Ship_To__c,'Ship To not defaulting');
        System.assertEquals(objCMD.Id,objPropUpdated2.Bill_To__c,'Bill To not defaulting');
        System.assertEquals(objCMD.Id,objPropUpdated2.Ship_To__c,'Ship To not defaulting');
        Test.stopTest();                                                        
    }

}