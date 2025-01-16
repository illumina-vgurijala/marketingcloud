/**
*  @date   2024-06-14
*  @description    Reapproval handler for Quotation
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
   Test class for ApttusProposalReapprovalHandler
*  Modification Log: 
*  ------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Kumar Gaurav       14-Jun-2024   Initial Developments 
*      Kumar Gaurav       22-Jul-2024   Defect fix 
*
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
    /**
     *  @author Kumar Gaurav
     *  @description Test class for apttusProposalReapprovalhandler
     **/
public class TestApttusProposalReapproval {
public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final String ACCOUNT_NAME_1 = 'Test Account 1';
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    public static final String OPPORTUNITY_LOSS_REASON_PRICE = 'Price';
    public static Boolean runAutoGenerateLogic = false; 	
    private static final String INFORMATIC_PRODUCT = 'Info product';
    private static final String ADD_ON_PRODUCT = 'Add On product';
    //private static final String ASSET_STATUS_PENDING_RENEWAL = 'Pending Renewal';

    //SonarCube
    public static final String VALIDATION_ASSERT_MESSAGE = 'Validation rule is not fired as expected.'; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    public static final String LINE_ITEM_OLD_VALUES_JSON = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}'; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    /**
     *  @author Kumar Gaurav
     *  @description Test Data Setup for clone proposal functionality
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

        Apttus_Config2__ClassificationName__c category = TestDataProposal.initCategory('Test Category');
        insert category;


        Approval_Hierarchy__c objPPMApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Post_Pricing_Message');
        Approval_Hierarchy__c objPromotionApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Promotion');
        insert new List<Approval_Hierarchy__c> {objPPMApprovalHeirarchy, objPromotionApprovalHeirarchy };

        List<Apttus_Config2__ClassificationHierarchy__c> lstOfLevels = new List<Apttus_Config2__ClassificationHierarchy__c>();
        Apttus_Config2__ClassificationHierarchy__c level0= TestDataProposal.initHierarchy(category, 'Level_0', null, null, 0);
        lstOfLevels.add(level0);
        Apttus_Config2__ClassificationHierarchy__c level1= TestDataProposal.initHierarchy(category, 'Level_1', level0, level0, 1);
        lstOfLevels.add(level1);
        Apttus_Config2__ClassificationHierarchy__c level2= TestDataProposal.initHierarchy(category, 'Level_2', level0, level1, 2);
        lstOfLevels.add(level2);
        Apttus_Config2__ClassificationHierarchy__c level3= TestDataProposal.initHierarchy(category, 'Level_3', level0, level2, 3);
        lstOfLevels.add(level3);
        Apttus_Config2__ClassificationHierarchy__c level4= TestDataProposal.initHierarchy(category, 'Level_4', level0, level3, 4);
        lstOfLevels.add(level4);
        insert lstOfLevels;

        List<Custom_Approval_Matrix__c> lstOfMatrices = new List<Custom_Approval_Matrix__c>();

        Custom_Approval_Matrix__c promoApprovalMatrix = TestDataProposal.initApprovalMatrixForPromotion('Promotion', 'BOGO', '2',objPromotionApprovalHeirarchy);
        lstOfMatrices.add(promoApprovalMatrix);

        Custom_Approval_Matrix__c ppmApprovalMatrix = TestDataProposal.initApprovalPostPricingMatrix('Post Pricing Message', 'Contract Admin Queue');
        lstOfMatrices.add(ppmApprovalMatrix);

        Apttus_Config2__ProductClassification__c prodClassification = TestDataProposal.initProductClassification(level4, product);
        insert prodClassification;
        insert lstOfMatrices;

        TestDataProposal.getNewConfigCustomClass();
        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();

        // Create new cart
        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        insert new List<Apttus_Config2__ProductConfiguration__c> { testCart};
        List <Apttus_Config2__ProductConfiguration__c> prodconfigList = new List <Apttus_Config2__ProductConfiguration__c>();
        for (Apttus_Config2__ProductConfiguration__c prodconfig: [Select id, Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c limit 2])
        {
            prodconfig.Apttus_Config2__Status__c = 'Finalized';
            prodconfigList.add(prodconfig);
        }
        Update prodconfigList;
        Apttus_Config2__LineItem__c cartLine = TestDataProposal.initLineItem(testCart.Id, product.Id, 1, 0);
        insert cartline;
        system.debug('>>>>>>>>>>>>>>>>>>>>>'+cartline);
        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        insert new List<Apttus_Approval__Approval_Request__c> { objApprovalRequest, objApprovalRequest2 };
    }
    @istest
    static void reapprovalEvaluationFirstCycle()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id,Apttus_QPConfig__ConfigurationFinalizedDate__c FROM Apttus_Proposal__Proposal__c limit 5];
        test.startTest();
        Date finalizedDate = date.newinstance(2024, 6, 10);
        lstProposal[0].Apttus_QPConfig__ConfigurationFinalizedDate__c = finalizedDate;
        Assert.isTrue(lstProposal.size() > 0,'Proposal found');
        update lstProposal;
        test.stopTest();
    }
    @istest
    static void reapprovalEvaluationNextCycle()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id,Apttus_QPConfig__ConfigurationFinalizedDate__c FROM Apttus_Proposal__Proposal__c limit 5];
        test.startTest();
        Reapproval_Reference__c rr= new Reapproval_Reference__c ();
        rr.Quote_Proposal_Id__c = lstProposal[0].id;
        rr.Current_Line_Data__c = '[{"totalDiscount":128520.00000,"terms":1,"quantity":2100.00000,"lineItem":"LI-0001379638","key":"20019168_3"},{"totalDiscount":388260.00000,"terms":1,"quantity":100.00000,"lineItem":"LI-0001379640","key":"15033418_4"}]';
        rr.Level_1_Line_Data__c = '[{"totalDiscount":128520.00000,"terms":1,"quantity":2100.00000,"lineItem":"LI-0001379638","key":"20019168_3"},{"totalDiscount":388260.00000,"terms":1,"quantity":100.00000,"lineItem":"LI-0001379640","key":"15033418_4"}]';
        rr.Level_2_Line_Data__c = '[{"totalDiscount":128520.00000,"terms":1,"quantity":2100.00000,"lineItem":"LI-0001379638","key":"20019168_3"},{"totalDiscount":388260.00000,"terms":1,"quantity":100.00000,"lineItem":"LI-0001379640","key":"15033418_4"}]';
        insert rr;
        Date oldfinalizedDate = date.newinstance(2024, 6, 10);
        lstProposal[0].Apttus_QPConfig__ConfigurationFinalizedDate__c = oldfinalizedDate;
        update lstProposal;
        Date finalizedDate = date.newinstance(2024, 6, 1);
        lstProposal[0].Apttus_QPConfig__ConfigurationFinalizedDate__c = finalizedDate;
        update lstProposal;
        Assert.isTrue(lstProposal.size() > 0,'Proposal Found');
        test.stopTest();
    }
    
}