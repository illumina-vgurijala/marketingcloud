/**
*    @author Kumar Gaurav
*    @date  21-Jun-2024
*    @description   Test Class for reapproval reference trigger Handler class 
*    Modification Log: 
*    ------------------------------------------------------------------------------------
*      Developer                      Date                 Description
*      Kumar Gaurav                 21-Jun-2024            Initial Commit 
*      Kumar Gaurav                 4-Jul-2024             Defect fix
*/
@isTest(SeeAllData=false isParallel=false)
public class TestReapprovalReference {
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final String ACCOUNT_NAME_1 = 'Test Account 1';
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    public static final String OPPORTUNITY_LOSS_REASON_PRICE = 'Price';
    public static Boolean runAutoGenerateLogic = false; 	
    private static final String INFORMATIC_PRODUCT = 'Info product';
    private static final String ADD_ON_PRODUCT = 'Add On product';

        /**
     *  @author Kumar Gaurav
     *  @description [DgP-31] Test data setup
     **/
    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
        acc.Name = ACCOUNT_NAME_1;
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc,'Create',Date.today() + 30,10000,Opportunities.RECORD_TYPE_MAP.get(Opportunities.RT_STANDARD_DIRECT).getRecordTypeId(),10,'Clinical','Description Test','Applied Lab','Forensics','Consumables','Standard Sale','$10,000 - $25,000','Internal Budget: In Process','Poor Data Quality','0-3 Months',false);
        opp2.Pricebook2Id = standardPricebook.Id;
        opp2.Price_List__c = '01-AMR-USD';
        insert new List<Opportunity>{ opp, opp2 };

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strDraft = 'Draft';
        String strNone = 'None';
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, strDraft, strNone);
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Proposal 1', priceList.id, true, strDraft, strNone);
        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal', priceList.id, true, strDraft, strNone);
        proposal2.Is_Updated_By_System__c = false;
        proposal2.Apttus_Proposal__ExpectedEndDate__c = System.today();
        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal2', priceList.id, true, strDraft, strNone);
        proposal3.Apttus_Proposal__ExpectedEndDate__c = System.today();
        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test AutoGenerateDoc Proposal', priceList.id, true, strDraft, strNone);
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2, proposal3, proposal4 };

        Product2 product = TestDataMaster.createProduct(false);
        Product2 productTwo = TestDataMaster.createProduct(false);
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Name = ADD_ON_PRODUCT;
        productThree.Informatics_SKU_Type__c = ApttusProposalLineItems.ADD_ON;
        Product2 informaticProduct = TestDataMaster.createProduct(false);
        informaticProduct.Name = INFORMATIC_PRODUCT;
        informaticProduct.Informatics_Family__c = 'BASESPACE_SEQUENCE_HUB';

        insert new List<Product2> { product, productTwo, productThree, informaticProduct };

        Restricted_Product__c restrictedProduct = TestDataProposal.initRestrictedProduct(acc2, productThree);
        insert restrictedProduct;

        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(product, priceList);
        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(productTwo, priceList);
        Apttus_Config2__PriceListItem__c priceListItemThree = TestDataProposal.initPriceListItem(productThree, priceList);
        insert new List<Apttus_Config2__PriceListItem__c> { priceListItem, priceListItemTwo, priceListItemThree };


    }
        /**
     *  @author Kumar Gaurav

     **/
    @istest
    static void onBeforeInsertTest()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c limit 1];
        test.startTest();
        Reapproval_Reference__c rr = new Reapproval_Reference__c();
        rr.Quote_Proposal_Id__c =lstProposal[0].id;
        insert rr;
        String isApproved = rr.id;
        
        test.stopTest();
        Assert.isNotNull(isApproved, 'myString should not be null');
    }
}