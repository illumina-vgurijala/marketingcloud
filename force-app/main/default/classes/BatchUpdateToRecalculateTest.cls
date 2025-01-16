/**
 *  @date  24-June-2024
 *  @description  BatchUpdateApprovalReqQuoteToDraftStage,BatchUpdateToRecalculate
 **/
@isTest
public class BatchUpdateToRecalculateTest {
   
    public static final String PROMOTION_JSON = '[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
   
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        acc.ERP_Customer_Id__c = '123457';
        acc.Territory_Region__c = 'AMR';
        update acc;
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '123456';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.BillingCountryCode = 'US';
        acc4.BillingStateCode = 'AK';
        acc4.ERP_Customer_Id__c = '567891';
        acc4.Account_Group__c = 'Sold To';
       
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '6000022795';
        acc5.Account_Group__c = 'Sold To';

        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        lstAcc.add(acc4);
        lstAcc.add(acc5);
        insert lstAcc;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc2.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc3.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = 'US01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};
       
        Account_Relationship__c objSoldToPayer = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Gryffy',
                                                                            Relationship__c=Label.AccountGroupPayer,
                                                                            Account_Sales_Area__c=acc2SalesArea.Id);
        insert objSoldToPayer;
        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        List<Customer_Master_Data__c> lstCMD = new List<Customer_Master_Data__c>();
        lstCMD.add(objCMDUC);
        lstCMD.add(objCMDSoldTo);
        lstCMD.add(objCMDDist);
        insert lstCMD;
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc2.Id);
        con2.FirstName = 'test contact';
        List<Contact> lstContact = new List<Contact>{con,con2};
        insert lstContact;
       
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        opp2.Price_List__c = priceList.Name;
        opp2.Consortium__c = consortium.Id;
        opp2.Type = 'Consortium';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstopp.add(opp2);

        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc2.Id;
        opp3.Distributor__c = acc3.Id;
        opp3.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp3.Are_Products_Added_by_Channel_Partner__c = true;
        lstopp.add(opp3);

        Opportunity opp5 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp5);
        insert lstopp;

        subSetUp(priceList, con, acc, acc2, acc5, opp, opp2, opp3, opp5, objCMDUC);
    }
   
    static void subSetUp(Apttus_Config2__PriceList__c priceList, Contact con, Account acc, Account acc2, Account acc5,
                         Opportunity opp, Opportunity opp2, Opportunity opp3, Opportunity opp5, Customer_Master_Data__c objCMDUC){
        subSetUp2(con, acc, acc2, acc5, opp, opp2, opp3, opp5, objCMDUC, priceList);                    
        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.End_Of_Sale_Date__c =Date.today()-1;
        objProduct.End_Of_Service_Date__c =Date.today();
        lstProduct.add(objProduct);

        Product2 objProductTwo = TestDataMaster.createProduct(false);
        objProductTwo.Material_Class__c = Label.ProductMaterialClassServices;
        lstProduct.add(objProductTwo);

        Product2 objProductThree = TestDataMaster.createProduct(false);
        lstProduct.add(objProductThree);

        Product2 objProductFour = TestDataMaster.createProduct(false);
        objProductFour.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductFour.End_Of_Sale_Date__c =Date.today();
        objProductFour.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductFour);

        Product2 objProductFive = TestDataMaster.createProduct(false);
        objProductFive.Material_Class__c = 'Informatics Software';
        objProductFive.End_Of_Sale_Date__c =Date.today()-1;
        objProductFive.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductFive);

        Product2 objFixedBundleProduct = TestDataMaster.initProduct('Pizza','Services');
        objFixedBundleProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
        objFixedBundleProduct.Material_Class_Type__c = Label.FixedBundleMatClassType;
        lstProduct.add(objFixedBundleProduct);

        Product2 objCompProduct = TestDataMaster.initProduct('Toppings','Services');
        lstProduct.add(objCompProduct);
        insert lstProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();

        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);

        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(objProductTwo, priceList);
        priceListItemTwo.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemTwo);

        Apttus_Config2__PriceListItem__c priceListItemThree = TestDataProposal.initPriceListItem(objProductThree, priceList);
        priceListItemThree.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemThree);

        Apttus_Config2__PriceListItem__c priceListItemFour = TestDataProposal.initPriceListItem(objProductFour, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFour);

        Apttus_Config2__PriceListItem__c priceListItemFive = TestDataProposal.initPriceListItem(objProductFive, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFive);

        Apttus_Config2__PriceListItem__c priceListItemFixBundleSKU = TestDataProposal.initPriceListItem(objFixedBundleProduct, priceList);
        priceListItemFixBundleSKU.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFixBundleSKU);

        Apttus_Config2__PriceListItem__c priceListItemFixBundleComp = TestDataProposal.initPriceListItem(objCompProduct, priceList);
        priceListItemFixBundleComp.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemFixBundleComp);

        insert lstPriceList;

        Apttus_Config2__ConfigCustomClasses__c configCustomClass = TestDataProposal.getNewConfigCustomClass();
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Apttus_Config2__ValidationCallbackClass__c = 'ApttusValidationCallback';
        configCustomClass.Name = 'System Properties';
        update configCustomClass;

        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();
        Apttus_Config2__Incentive__c objIncentive=new Apttus_Config2__Incentive__c();
        objIncentive.Apttus_Config2__IncentiveCode__c='NEWBEE';
        objIncentive.Apttus_Config2__Sequence__c=1;

        insert objIncentive;
    }
   
    static void subSetUp2(Contact con, Account acc, Account acc2, Account acc5,
                         Opportunity opp, Opportunity opp2, Opportunity opp3, Opportunity opp5, Customer_Master_Data__c objCMDUC, Apttus_Config2__PriceList__c priceList){
        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Promotion_JSON__c=PROMOTION_JSON;
        Proposal.Bill_To__c = objCMDUC.id;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Approval Required';
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Promotion_JSON__c=PROMOTION_JSON;
        Proposal2.Bill_To__c = objCMDUC.id;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Approval Required';
        lstProp.add(proposal2);

        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc2.id, opp3.id, 'Test Proposal3', priceList.id, true, 'Draft', 'None');
        proposal3.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal3.Apttus_Proposal__Proposal_Name__c = 'Test Proposal3';
        proposal3.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal3.Bill_To__c = objCMDUC.id;
        proposal3.Ultimate_Consignee__c = acc.id;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Approval Required';
        lstProp.add(proposal3);

        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc5.id, opp5.id, 'Test Proposal4', priceList.id, true, 'Draft', 'None');
        proposal4.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal4.Apttus_Proposal__Proposal_Name__c = 'Test Proposal4';
        proposal4.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal4.Bill_To__c = objCMDUC.id;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Approval Required';
        lstProp.add(proposal4);

        Apttus_Proposal__Proposal__c proposal5 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal 3', priceList.id, true, 'Draft', 'None');
        proposal5.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal5.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal5.Bill_To__c = objCMDUC.id;
        Proposal5.Invalid_Quote__c = true;
        Proposal5.Generate_In_Progress__c = true;
        Proposal5.Async_Generation_Complete__c = false;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Approval Required';
         
        lstProp.add(proposal5);

        insert lstProp;
       
        MockApttusSAPConnector.strQuoteNumber = lstProp[0].name;
        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;

        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(lstProp.get(2).Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;

        cs_Apex_Settings__c cs1 = cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        cs1.Bypass_All_Validations__c = true;
        upsert cs1 cs_Apex_Settings__c.Id;

        Customer_Historical_Spend__c ch = new Customer_Historical_Spend__c();
        ch.Primary_Customer_Type__c = 'Government';
        ch.Customer_Historic_Spend__c = 120000;
        ch.Total_Instrument_Credits__c = 11;
        ch.Valid_From_Date__c = System.today() - 5;
        ch.Frequency__c = 'Last Fiscal Year';
        ch.ERP_ID__c = '123457';
        insert ch;

        cs1.Bypass_All_Validations__c = false;
        upsert cs1 cs_Apex_Settings__c.Id;
        System.assertEquals(120000,ch.Customer_Historic_Spend__c);
    }

    /**
     *  @description setupTest
     **/
    @isTest
    static void setupTest() {
       
        Discount_Guidance__c dg = new Discount_Guidance__c();
        dg.Start_Date__c = System.today() + 2;
        dg.End_Date__c = System.today() + 10;
        dg.Discount_Guidance_Level__c = 'Country';
        dg.Country__c = 'HK';
        dg.Channel__c = 'Direct';
        dg.Customer_Discount_Tier__c = '1';
        dg.Tier_Min__c = 1;
        dg.Tier_Max__c = 999999;
        dg.Median_Discount__c = 30;
        dg.Max_Discount__c = 42;
        dg.Discount_Grid_Group__c = 'iSeq Cons';
        dg.Primary_Customer_Type__c = 'Government';
        dg.Tier_Type__c = 'Spend';
        insert dg;
        Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
        proposal1.Sold_To_Distribution_Channel__c = Label.DirectDistributionChannelCode;
        update proposal1;
       
        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        product.ProductCode = 'ADCS';
        product.Discount_Grid_Group__c = 'iSeq Cons';
        insert product;
       
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal1);
        
        objApttusProductConfig.Apttus_QPConfig__Proposald__c=proposal1.id;
        update objApttusProductConfig;
        
        List<Apttus_Config2__LineItem__c> objLineItemList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__ProductConfiguration__c> objConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__LineItem__c objLineItem=new Apttus_Config2__LineItem__c();
        objLineItem.Apttus_Config2__ConfigurationId__c=objApttusProductConfig.id;
        objLineItem.Apttus_Config2__ItemSequence__c=2;
        objLineItem.Apttus_Config2__LineNumber__c=10;
        objLineItem.Beadchip_Part_Number__c = 'BeadChip1';
        objLineItem.Project_Id__c = 'Project1';
        objLineItem.Discount_Guidance__c = dg.Id;
        objLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        objLineItem.Apttus_Config2__ProductId__c =product.Id;
        objLineItem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
        objLineItemList.add(objLineItem);
        insert objLineItemList;
        
        System.debug('objLineItemList '+objLineItemList + ' '+objLineItemList.size());
        
        // Collecting all the test data IDs
        Set<Id> quoteIdSet = new Set<Id>();
        for (Apttus_Config2__ProductConfiguration__c lineItem : [SELECT ID,Apttus_QPConfig__Proposald__c,(Select Id,Customer_Historical_Discount__c,Approval_Matrix_Custom__c,Min_Discount__c,Approval_Matrix_Record_Owner__c,Material_Group_1__c,Open_Offer_Product_Category__c,Max_Discount_Guidance__c,Median_Discount_Guidance__c,Discount_Guidance__c,Product_Code__c,Discount_Grid_Group__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c From Apttus_Config2__LineItems__r) FROM Apttus_Config2__ProductConfiguration__c limit 100]) {
            quoteIdSet.add(lineItem.Apttus_QPConfig__Proposald__c);
            objConfigList.add(lineItem);
        }
        // Initialize the batch class
        BatchUpdateToRecalculate batch = new BatchUpdateToRecalculate(quoteIdSet);
        Test.startTest();
        Database.executeBatch(batch);
        Database.BatchableContext bc;
        batch.execute(bc,objConfigList);
        Test.stopTest();
        System.assertEquals('ADCS',product.ProductCode,'Code matching');

        
    }

    @isTest
    static void testBatchUpdateApprovalReqQuoteToDraftStage() {
        
        // Initialize the batch class
        BatchUpdateApprovalReqQuoteToDraftStage batch = new BatchUpdateApprovalReqQuoteToDraftStage();
        List<Apttus_Proposal__Proposal__c> quotes = [select id, Apttus_Proposal__Approval_Stage__c from  Apttus_Proposal__Proposal__c where Apttus_Proposal__Approval_Stage__c = 'Approval Required'];
        // Run the batch class
        Test.startTest();
        Database.executeBatch(batch);
        Database.BatchableContext bc;
        batch.execute(bc,quotes);
        Test.stopTest();

        // Add assertions to verify the outcome of the batch processing
        for (Apttus_Config2__LineItem__c lineItem : [SELECT Customer_Historical_Discount__c, Approval_Matrix_Custom__c FROM Apttus_Config2__LineItem__c LIMIT 100]) {
            System.assertNotEquals(null, lineItem.Customer_Historical_Discount__c, 'Customer Historical Discount should not be null.');
            System.assertNotEquals(null, lineItem.Approval_Matrix_Custom__c, 'Approval Matrix Custom should not be null.');
        }
    }

    @isTest
    static void testBatch() {
        // Collecting all the test data IDs
        Set<Id> quoteIdSet = new Set<Id>();
        for (Apttus_Config2__LineItem__c lineItem : [SELECT Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c FROM Apttus_Config2__LineItem__c LIMIT 100]) {
            quoteIdSet.add(lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c);
        }
        
        List<Apttus_Config2__ProductConfiguration__c> lineItems = [SELECT ID,(Select Id,Customer_Historical_Discount__c,Approval_Matrix_Custom__c,Min_Discount__c,Approval_Matrix_Record_Owner__c,Material_Group_1__c,Open_Offer_Product_Category__c,Max_Discount_Guidance__c,Median_Discount_Guidance__c,Discount_Guidance__c,Product_Code__c,Discount_Grid_Group__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c From Apttus_Config2__LineItems__r) FROM Apttus_Config2__ProductConfiguration__c limit 100];

        // Initialize the batch class
        BatchUpdateToRecalculate batch = new BatchUpdateToRecalculate(quoteIdSet);

        // Run the batch class
        Test.startTest();
        Database.executeBatch(batch);
        Database.BatchableContext bc;
        batch.execute(bc,lineItems);
        Test.stopTest();

        // Add assertions to verify the outcome of the batch processing
        for (Apttus_Config2__LineItem__c lineItem : [SELECT Customer_Historical_Discount__c, Approval_Matrix_Custom__c FROM Apttus_Config2__LineItem__c LIMIT 100]) {
            System.assertNotEquals(null, lineItem.Customer_Historical_Discount__c, 'Customer Historical Discount should not be null');
            System.assertNotEquals(null, lineItem.Approval_Matrix_Custom__c, 'Approval Matrix Custom should not be null');
        }
    }

    @isTest
    static void testDiscountGuidancePopulatorForCPQ() {
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, Apttus_Config2__ConfigurationId__c, Customer_Historical_Discount__c FROM Apttus_Config2__LineItem__c LIMIT 10];
       
        //DiscountGuidancePopulatorForCPQ disGuidanceObj = new DiscountGuidancePopulatorForCPQ();
       
        Test.startTest();
        //BatchUpdateToRecalculate bctr;
        //Database.BatchableContext bc;
        //bctr.execute(BC,lineItems);
        //disGuidanceObj.deriveFieldValuesForDiscountGuidance(lineItems);
        Test.stopTest();
       
        for (Apttus_Config2__LineItem__c lineItem : lineItems) {
            System.assertNotEquals(null, lineItem.Customer_Historical_Discount__c, 'Customer Historical Discount should not be null');
        }
    }
}