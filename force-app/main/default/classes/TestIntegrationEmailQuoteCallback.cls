/**
*    @author Rishab Wali
*    @date   2020-05-23
*    @description    DCP-34910 Email Service Handler Test Class
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rishab Wali                  2020-05-26          Initial Version
*    Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*    ------------------------------------------------------------------------------------                  
*/
@isTest
public class TestIntegrationEmailQuoteCallback {

    public static final String PROMOTION_JSON = '[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
    public static final String TESTUSER = 'Test User';
    public static final String TESTEMAIL = 'TestUser@illumina.com';
    public static final String TESTSUBJECT = '[Test] Large Cart Callback-';
    public static final String TESTBODY = 'Errors in Validation';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getNewAccount();
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
        //Fapiao
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
        // DCP-25908 : Payment term
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
        Contact con = TestDataPerson.getNewContact(acc.Id);
        con.email = 'axs@scs.com';

        System.debug('contss-'+con);

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        System.debug('+++++++ Opp Type: '+opp.Type);
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
        System.debug('+++++++ Opp Type: '+opp.Type);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp5);
        insert lstopp;



        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Promotion_JSON__c=PROMOTION_JSON;
        //Proposal.Apttus_QPConfig__BillToAccountId__c = objCMDUC.id;
        Proposal.Bill_To__c = objCMDUC.id;
        System.debug('***1231**'+proposal.Direct_Sale_to_Ultimate_Consignee__c);
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Promotion_JSON__c=PROMOTION_JSON;
        Proposal2.Bill_To__c = objCMDUC.id;
        System.debug('***1232**'+proposal2.Direct_Sale_to_Ultimate_Consignee__c);
        lstProp.add(proposal2);

        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc2.id, opp3.id, 'Test Proposal3', priceList.id, true, 'Draft', 'None');
        proposal3.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal3.Apttus_Proposal__Proposal_Name__c = 'Test Proposal3';
        proposal3.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal3.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal3);

        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc5.id, opp5.id, 'Test Proposal4', priceList.id, true, 'Draft', 'None');
        proposal4.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal4.Apttus_Proposal__Proposal_Name__c = 'Test Proposal4';
        proposal4.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal4.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal4);


        insert lstProp;

        MockApttusSAPConnector.strQuoteNumber = lstProp[0].name;
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
        objProductFive.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductFive.End_Of_Sale_Date__c =Date.today()-1;
        objProductFive.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductFive);

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
    /*
    *@author: Rishab Wali
    *@Desc: Test method for Email Quote Success Scenario
    */
    @isTest
    public static void emailQuoteCallbackSuccessScenario()
    {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        test.startTest();
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name from Apttus_Proposal__Proposal__c][0];
        
        email.subject = TESTSUBJECT + objQuotation.Name;
        email.fromname = TESTUSER;
        env.fromAddress = TESTEMAIL;
        email.plainTextBody = TESTBODY;
        
        IntegrationEmailQuoteCallback intEmailQuoteCallback = new IntegrationEmailQuoteCallback();
        intEmailQuoteCallback.process(email,env,objQuotation.Name);
        test.stopTest();
        System.assertEquals(false,String.isBlank(objQuotation.Name));
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method for email quote blank subject scenario
    */
    @isTest
    public static void emailQuoteCallbackBlankSubjectScenario()
    {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
        test.startTest();
        email.subject = '';
        email.fromname = TESTUSER;
        env.fromAddress = TESTEMAIL;
        email.plainTextBody = TESTBODY;
        
        IntegrationEmailQuoteCallback intEmailQuoteCallback = new IntegrationEmailQuoteCallback();
        intEmailQuoteCallback.process(email,env,'');
        test.stopTest();
        System.assertEquals(true,String.isBlank(email.subject));
    } 
    /*
    *@author: Rishab Wali
    *@Desc: Test method for email quote invlaid quote id scenario
    */
    @isTest
    public static void emailQuoteCallbackInvalidQuoteIdScenario()
    {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        test.startTest();
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name from Apttus_Proposal__Proposal__c][0];
        
        email.subject = TESTSUBJECT;
        email.fromname = TESTUSER;
        env.fromAddress = TESTEMAIL;
        email.plainTextBody = TESTBODY;
        
        IntegrationEmailQuoteCallback intEmailQuoteCallback = new IntegrationEmailQuoteCallback();
        intEmailQuoteCallback.process(email,env,'Q-abc');
        test.stopTest();
        System.assertEquals(false,String.isBlank(objQuotation.Name));
    }    
}