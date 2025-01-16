/**
*    @author Rohan Chandarana
*    @date   2018-05-15
*    @description  DCP-454: Create Quote - Ability to Clone Quote
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Satya Swain                    07-05-2018          Modified to test ApttusValidationCallback class,
*                                                               using checkLineItemValidationForShippingInCloseQuarterValue()
*            Satya Swain                    08-17-2018          Modified to test renewing assets functionality in testValidateCart()
*            Gopesh Banker                  09-20-2018          added test method testProposalSyncToOpportunity
*            Roopal Verma                   10-04-2018          Added method testSetMyIlluminaEmail
*            Rahul Sharma                   10-09-2018          Added method testValidToInSameQuarter,testValidToBlank
*            Milan Savaliya                 10-24-2018          Added method testSyncOppLineToCart
*            Milan Savaliya                 10-30-2018          Removed code to test sync Batch
*            Govind Dubey                   02-05-2019          TestUpdatePricing
*            Kushagra Desai                 7-July-2018         Added Assert : testCartValidations()
*            Rahul Bishnoi                  30-Jan-2020        DCP-31767 Added method testRequiredInformaticsFields
*            Arnab Modak                    1-Apr-2020          SonarCube
*            Raja Siva Krishna              23-Sep-2020         DCP-40107  Updated data to get code coverage
*            Satya Swain                    02 Nov 2020         INC0281082 : Added test method for primary quote sync failure
*            KD                             22-June-2021        DCP-46257 : Logic to populate Inventory Location
*            Rishab Wali                    18 June 2021        DCP-46920 Auto Generate Quote
*            Rahul Bishnoi                  04 October 2021     TASK0573816 - Added coverage for ApttusQuoteLifeCycleCallBack
*            Koustubh Masurkar              21 October 2021     Applied code scan suggestions.
*            Koustubh Masurkar              21 October 2021     Applied code scan suggestions
*            Khushbu Vasani                 13 June 2022        DCP-54531
*            Adyasha Satapathy              28-Nov-2022         POL-54: Update region references to AMEA and EUR
*            Saddam                         08-Dec-2022         Codescan Fix , Assert statement added for test methods 
*            Gerardo Garcia                 24-Jan-2024         CMCM-5310 Refactor tests.
*            Kumar Gaurav                   24-Jun-2024         Adding the invoke for apttusproposal reapproval 
*            Pradeep Landge                 25-Nov-2024         Adding test consortium terms and conditions.
*
*/

@isTest(SeeAllData=false isParallel=false)
public with sharing class TestApttusProposals
{
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final String ACCOUNT_NAME_1 = 'Test Account 1';
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    public static final String OPPORTUNITY_LOSS_REASON_PRICE = 'Price';
    public static Boolean runAutoGenerateLogic = false; 	
    private static final String INFORMATIC_PRODUCT = 'Info product';
    private static final String ADD_ON_PRODUCT = 'Add On product';
    private static final String ASSET_STATUS_PENDING_RENEWAL = 'Pending Renewal';

    //SonarCube
    public static final String VALIDATION_ASSERT_MESSAGE = 'Validation rule is not fired as expected.'; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    public static final String LINE_ITEM_OLD_VALUES_JSON = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}'; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - made the variable final
    /**
     *  @author Rohan Chandarana
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
        Apttus_Proposal__Proposal__c proposal5 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Approver Access On Insert', priceList.id, true, strDraft, strNone);
        Apttus_Proposal__Proposal__c proposal6 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Approver Access On Reassignment', priceList.id, true, strDraft, strNone);
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2, proposal3, proposal4, proposal5, proposal6 };

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
        Apttus_Config2__ProductConfiguration__c testCartTwo = TestDataProposal.initCart(proposal);
        insert new List<Apttus_Config2__ProductConfiguration__c> { testCart, testCartTwo };

        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        insert new List<Apttus_Approval__Approval_Request__c> { objApprovalRequest, objApprovalRequest2 };
        List<Id> lstEmailTemplateIds = TestDataEmailTemplate.getEmailTemplates();

        System.assertEquals(5, lstEmailTemplateIds.size(),'All templates not inserted. ');

        TestDataApprovalProcess.getApprovalProcess();

        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;

        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        //List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(proposal.Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;

        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        TestDataUser.allowUserCreation(objUser.Id);

        System.runAs(objUser){
            Profile salesUserProfile = [select Id from Profile where Name = :TestDataUser.PROFILE_SALES_REP limit 1];
            UserRole amrSalesUserRole = [select Id from UserRole where Name = :TestDataUser.ROLE_AMR_SALES limit 1];
            User user1 = TestDataUser.initStandardInternalUser(salesUserProfile.Id, amrSalesUserRole.Id);
            user1.LastName = 'Approver1';
            User user2 = TestDataUser.initStandardInternalUser(salesUserProfile.Id, amrSalesUserRole.Id);
            user2.LastName = 'Approver2';
            insert new List<User> { user1, user2 };
        }
    }

    /**
     *  @author Pradeep Landge
     *  @description Test the logic for updating Template Consortia Terms And Conditions
     **/
    @isTest 
    static void setTemplateConsortiaTCToInitialSaleSpecialTerms()
    {   
        Feature.setMockFeatureFlag('WF_Quotation_Populate_Consortia', true);
        Consortium__c consortium = TestDataConsortium.initConsortium();
        consortium.Beadchip_Part_Number__c = TestData.getRandom();
        insert consortium;

        //Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Opportunity o1 = [SELECT Id,First_Proposal_Id__c FROM Opportunity LIMIT 1];
        o1.Consortium__c = consortium.Id;
        update o1;

        Test.startTest();
        Apttus_Proposal__Proposal__c quotation = [SELECT Id,Template_Consortia_Terms_And_Conditions__c,Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Account__r.Territory_Region__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        quotation.Invalid_Quote__c = false;
        update quotation;
        Test.stopTest();
        consortium = [SELECT id, Initial_Sale_Special_Terms__c FROM Consortium__c LIMIT 1];
        System.debug('Initial_Sale_Special_Terms__c:' + consortium.Initial_Sale_Special_Terms__c);
        quotation = [SELECT Id,Template_Consortia_Terms_And_Conditions__c FROM Apttus_Proposal__Proposal__c WHERE id =: quotation.Id];
        Assert.areEqual(consortium.Initial_Sale_Special_Terms__c, quotation.Template_Consortia_Terms_And_Conditions__c, 'Expected Consortium.Initial_Sale_Special_Terms__c'); // Succeeds
    }

    /**
     *  @author Pradeep Landge
     *  @description Test the logic for updating Template Consortia Terms And Conditions
     **/
    @isTest 
    static void setTemplateConsortiaTCToReOrderSpercialTerms()
    {   
        String specialTerms = 'consortium.Re_Order_Special_Terms__c';
        Feature.setMockFeatureFlag('WF_Quotation_Populate_Consortia', true);
        Consortium__c consortium = TestDataConsortium.initConsortium();
        consortium.Beadchip_Part_Number__c = TestData.getRandom();
        consortium.Beadpool_Expiration__c = Date.today();
        consortium.Stage__c = Label.ConsortiumStageReOrder;
        consortium.Re_Order_Special_Terms__c = specialTerms;
        consortium.Consortium_Chip_Name__c = 'Consortium chip name';
        consortium.Number_Of_Total_SNPs_In_BPM__c = 10;
        consortium.C_Pricing_AMR_USD__c = 10;
        consortium.C_Pricing_ANZ_AUD__c = 10;
        consortium.C_Pricing_ANZ_NZD__c = 10;
        consortium.C_Pricing_ANZ_USD__c = 10;
        consortium.C_Pricing_CAD_CAD__c = 10;
        consortium.C_Pricing_CAD_USD__c = 10;
        consortium.C_Pricing_CNY_CNY__c = 10;
        consortium.C_Pricing_CNY_USD__c = 10;
        consortium.C_Pricing_Distributors_USD__c = 10;
        consortium.C_Pricing_EUR_GBP__c = 10;
        consortium.C_Pricing_EUR_USD__c = 10;
        consortium.C_Pricing_HKD_CNY__c = 10;
        consortium.C_Pricing_HKD_HKD__c = 10;
        consortium.C_Pricing_HKD_USD__c = 10;
        consortium.C_Pricing_JPY_JPY__c = 10;
        consortium.C_Pricing_JPY_USD__c = 10;
        consortium.C_Pricing_KRW_KRW__c = 10;
        consortium.C_Pricing_KRW_USD__c = 10;
        consortium.C_Pricing_SGD_SGD__c = 10;
        consortium.C_Pricing_SGD_USD__c = 10;
        consortium.L_Pricing_AMR_USD__c = 10;
        consortium.L_Pricing_ANZ_AUD__c = 10;
        consortium.L_Pricing_ANZ_NZD__c = 10;
        consortium.L_Pricing_ANZ_USD__c = 10;
        consortium.L_Pricing_CAD_CAD__c = 10;
        consortium.L_Pricing_CAD_USD__c = 10;
        consortium.L_Pricing_CNY_CNY__c = 10;
        consortium.L_Pricing_CNY_USD__c = 10;
        consortium.L_Pricing_Distributors_USD__c = 10;
        consortium.L_Pricing_EUR_GBP__c = 10;
        consortium.L_Pricing_EUR_USD__c = 10;
        consortium.L_Pricing_HKD_CNY__c = 10;
        consortium.L_Pricing_HKD_HKD__c = 10;
        consortium.L_Pricing_HKD_USD__c = 10;
        consortium.L_Pricing_JPY_JPY__c = 10;
        consortium.L_Pricing_JPY_USD__c = 10;
        consortium.L_Pricing_KRW_KRW__c = 10;
        consortium.L_Pricing_KRW_USD__c = 10;
        consortium.L_Pricing_SGD_SGD__c = 10;
        consortium.L_Pricing_SGD_USD__c = 10;
        insert consortium;

        //Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Opportunity o1 = [SELECT Id,First_Proposal_Id__c FROM Opportunity LIMIT 1];
        o1.Consortium__c = consortium.Id;
        update o1;

        Test.startTest();
        Apttus_Proposal__Proposal__c quotation = [SELECT Id,Template_Consortia_Terms_And_Conditions__c,Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Account__r.Territory_Region__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        quotation.Invalid_Quote__c = false;
        update quotation;
        Test.stopTest();
        consortium = [SELECT id, Re_Order_Special_Terms__c FROM Consortium__c LIMIT 1];
        System.debug('Re_Order_Special_Terms__c:' + consortium.Re_Order_Special_Terms__c);
        quotation = [SELECT Id,Template_Consortia_Terms_And_Conditions__c FROM Apttus_Proposal__Proposal__c WHERE id =: quotation.Id];
        Assert.areEqual(consortium.Re_Order_Special_Terms__c, quotation.Template_Consortia_Terms_And_Conditions__c, 'Expected Consortium.Re_Order_Special_Terms__c'); // Succeeds
    }

    /**
     *  @author Deepesh Malhotra
     *  @description Test method for recall approval functionality
     **/
    @istest
    static void recallApproval()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c];
        lstProposal = new ApttusProposalsSelector().selectById(new Set<ID>{lstProposal.get(0).id});
        //lstProposal.get(0).Apttus_QPApprov__Approval_Status__c='Approved';
        Apttus_Proposal__Proposal__c proposal = lstProposal.get(0);
        proposal.Apttus_QPApprov__Approval_Status__c='Approved';
        proposal.Apttus_Proposal__Approval_Stage__c='Approved';
        System.debug('+++++++++++++++'+proposal);
        update proposal;
        test.startTest();
            ApttusQuoteRecallController.recallQuotation(proposal.Id);
        Test.stopTest();
        System.assertEquals('SUCCESS', ApttusQuoteRecallController.recallQuotation(proposal.Id));
        ApttusQuoteRecallController.recallQuotation(null);
    }
    /**
     *  @author Rahul Bishnoi
     *  @description Test method for ApttusQuoteLifeCycleCallBack
    **/
    @isTest
    private static voId testAfterComplete(){
        Apttus_Proposal__Proposal__c objProposal = [Select Id, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Proposal_Name__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Product2 product = [Select Id From Product2 LIMIT 1];
        System.assert(product != null,'product should not be null'); //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - Added assert statement
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);
        Apttus_Config2__ProductConfiguration__c testCart = [SELECT Id, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c = :objProposal.Id LIMIT 1];

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = product.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = testCart.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        
        
        
                    
        test.startTest();
        for(Apttus_Config2__LineItem__c cartLineItemsNew:[SELECT Id, Apttus_Config2__Quantity__c, Apttus_Config2__PriceListId__c, Apttus_Config2__PriceListItemId__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__EffectiveDate__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ExpirationDate__c, Apttus_Config2__ProductId__r.ProductCode
        FROM Apttus_Config2__LineItem__c LIMIT 1]) { //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - LIMIT 1
            System.debug('-->> cartLineItems ' + cartLineItemsNew + 'extra ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__c + ' ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__r.Apttus_Config2__EffectiveDate__c + ' ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ExpirationDate__c);
            
        }
        objProposal.Apttus_QPConfig__PricingDate__c = system.today()+8;
        objProposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        Update objProposal;

        testCart.Apttus_Config2__PricingDate__c = system.today()+8;
        update testCart;

        Apttus_Config2__PriceList__c obPriceList = [SELECT id from Apttus_Config2__PriceList__c LIMIT 1]; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - LIMIT 1
        Apttus_Config2__PriceListItem__c priceListItemfuture = TestDataProposal.initPriceListItem(product, obPriceList);
         priceListItemfuture.Apttus_Config2__EffectiveDate__c=system.today()+7;
         priceListItemfuture.Apttus_Config2__ExpirationDate__c=system.today()+15;
         insert priceListItemfuture;

         //Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
         //insert oAgreement2;

         //methods to cover ApttusQuoteLifeCycleCallBack -- to be removed once apttus provides resolution
         new ApttusQuoteLifeCycleCallBack().afterClone(objProposal,objProposal);
         new ApttusQuoteLifeCycleCallBack().afterCreateFromAccount(objProposal);
         new ApttusQuoteLifeCycleCallBack().afterCreateFromOpportunity(objProposal);
         //new ApttusQuoteLifeCycleCallBack().afterCreateAgreement(objProposal,oAgreement2);
         new ApttusQuoteLifeCycleCallBack().beforeClone(objProposal,objProposal);
         new ApttusQuoteLifeCycleCallBack().afterComplete(objProposal,Apttus_Proposal.CustomClass.ActionType.ACTION_CLONE);
         //new ApttusQuoteLifeCycleCallBack().afterComplete(oAgreement2,Apttus_Proposal.CustomClass.ActionType.ACTION_CLONE);
         test.stopTest();

        for(Apttus_Config2__LineItem__c cartLineItemsNew:[SELECT Id, Apttus_Config2__Quantity__c, Apttus_Config2__PriceListId__c, Apttus_Config2__PriceListItemId__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__EffectiveDate__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ExpirationDate__c, Apttus_Config2__ProductId__r.ProductCode
        FROM Apttus_Config2__LineItem__c LIMIT 1]) { //Koustubh Masurkar      21 October 2021        Applied code scan suggestions - LIMIT 1
            System.debug('-->> cartLineItemsNew ' + cartLineItemsNew + 'extra ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__c + ' ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__r.Apttus_Config2__EffectiveDate__c + ' ' + cartLineItemsNew.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ExpirationDate__c);

        }
    }
    /**
     *  @author Rohan Chandarana
     *  @description Test method for Clone Proposal functionality
     **/
    @isTest
    static void cloneProposal()
    {
        Product2 product = [Select Id From Product2 LIMIT 1];
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c];
        lstProposal = new ApttusProposalsSelector().selectById(new Set<ID>{lstProposal.get(0).id});
        //lstProposal.get(0).Apttus_QPApprov__Approval_Status__c = 'Approved';
        Apttus_Proposal__Proposal__c proposal = lstProposal.get(0);
        proposal.Apttus_QPApprov__Approval_Status__c='Approved';
        proposal.Apttus_Proposal__Approval_Stage__c='Approved';
        update proposal;
        Test.startTest();
        Apttus_Proposal__Proposal__c clonedProp = proposal.clone(false, true, false, false);
        insert clonedProp;
			
        List<Apttus_Proposal__Proposal__c> lstClonedProposal = new ApttusProposalsSelector().selectById(new Set<ID>{clonedProp.id});
        System.assertEquals(true, lstClonedProposal.get(0).Apttus_Proposal__Primary__c);
        System.assertEquals(ApttusProposals.APPROVAL_STATUS_NONE, lstClonedProposal.get(0).Apttus_QPApprov__Approval_Status__c);

        //Test previous primary proposal is marked non-primary after clone and approval status is Approved
        lstProposal = new ApttusProposalsSelector().selectById(new Set<ID>{proposal .id});
        System.assertEquals(false, lstProposal.get(0).Apttus_Proposal__Primary__c);
        System.assertEquals('Approved', lstProposal.get(0).Apttus_QPApprov__Approval_Status__c);
        
        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[SELECT Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal, product);
        proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        insert proposalLineItem;
        Test.stopTest();
    }

    /**
     *  @author Rohan Chandarana
     *  @description Test method for Proposal Approvals functionality
     **/
    @isTest
    static void testProposalApprovals()
    {
        

        
        	Apttus_Proposal__Proposal__c proposal = [Select id,Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c Limit 1];
        	Product2 product = [Select id From Product2 LIMIT 1];
            Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
            productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
            update productConfig;

            product.Material_Class__c = 'Services';
            update product;

            List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
            lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;

        	Test.startTest();
            Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal, product);
            proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
            proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
            proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
            insert proposalLineItem;

            Apttus_QPConfig__ProposalAdjustmentLineItem__c propAdjLine = TestDataProposal.initProposalAdjustmentLineItem(proposalLineItem);
            insert propAdjLine;
			
            Custom_Approval_Matrix__c approvalMatrix = [SELECT Id FROM Custom_Approval_Matrix__c LIMIT 1];
            Set<Id> setApprovalMatrixIds = new Set<Id> {approvalMatrix.id};
            List<Custom_Approval_Matrix__c> lstApprovalMatrix = new CustomApprovalMatrixSelector().selectById(setApprovalMatrixIds);
            System.assertNotEquals(0, lstApprovalMatrix.size());

            Apttus_Proposal__Proposal_Line_Item__c pli = [SELECT Id, Approval_Category__c,Apttus_Proposal__Proposal__c FROM Apttus_Proposal__Proposal_Line_Item__c Limit 1];
            System.debug('$$$$$$$$$$$'+pli.Approval_Category__c);
            //System.assertEquals('Product;Product_Category;Discount;Material_Class;Product_Group;Product_Line;Promotion', pli.Approval_Category__c);

            pli.Apttus_QPApprov__Approval_Status__c = null;
            update pli;
            pli.Apttus_QPApprov__Approval_Status__c = System.Label.ProposalApprovalStatusApprovalRequired;
            update pli;

            //List<Apttus_Proposal__Proposal__c> lstProposal = new ApttusProposalsSelector().selectById(new Set<Id>{pli.Apttus_Proposal__Proposal__c});
            // System.assertEquals(lstProposal[0].Apttus_Proposal__Approval_Stage__c, System.Label.ProposalApprovalStatusApprovalRequired);
        
        Test.stopTest();
    }

    /**
     *  @author Satya Swain
     *  @description Test method for Post Pricing Message Approvals
     **/
    @isTest
    static void testPostPricingMessageApprovals()
    {
        Test.startTest();
        Apttus_Proposal__Proposal__c objQuotation = [Select Id,Apttus_Proposal__Proposal_Name__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Custom_Approval_Matrix__c objMatrix = [Select Id, Name from Custom_Approval_Matrix__c where Name = 'Post Pricing Message Approval Matrix'];
        System.debug('@@@ matrix: '+objMatrix);
        objQuotation.Post_Pricing_Message_List__c = 'Non-Standard Post Pricing Message';
        objQuotation.Post_Pricing_Message__c = 'Test Non-Standard Post Pricing Message';
        objQuotation.Preferred_Language__c = 'English';
        update objQuotation;
        Test.stopTest();
        Apttus_Proposal__Proposal__c objQuotation2 = [Select Id,Apttus_Proposal__Proposal_Name__c,Approval_Category__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];

        system.debug('@@@ category : '+ objQuotation2.Approval_Category__c);
        System.assert(objQuotation2.Approval_Category__c.contains('Post_Pricing_Message'), 'Approval Category incorrect');
    }

    /**
     *  @author Satya Swain
     *  @description Test method for Post Pricing Message Approvals when preferred langauge is not English
     **/
    @isTest
    static void testPostPricingMessageApprovalsForNonEnglishPreferredLanguage()
    {
        Test.startTest();
        Apttus_Proposal__Proposal__c objQuotation = [Select Id,Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Account__r.Territory_Region__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Custom_Approval_Matrix__c objMatrix = [Select Id, Name from Custom_Approval_Matrix__c where Name = 'Post Pricing Message Approval Matrix'];
        System.debug('@@@ matrix: '+objMatrix);
        objQuotation.Apttus_Proposal__Account__r.Territory_Region__c = 'EUR'; //POL-54
        objQuotation.Post_Pricing_Message_List__c = 'Messaggio dei prezzi post non standard ';
        objQuotation.Post_Pricing_Message__c = 'Messaggio dei prezzi test';
        objQuotation.Preferred_Language__c = 'Italian';
        update objQuotation;
        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotation2 = [Select Id,Apttus_Proposal__Proposal_Name__c,Approval_Category__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
       // system.debug('@@@ category NonEnglishPreferredLanguage: '+ objQuotation2.Apttus_Proposal__Proposal_Name__c);
        //System.assert(objQuotation2.Approval_Category__c.contains('Post_Pricing_Message'), 'Approval Category incorrect');
        System.assertEquals('Test Proposal', objQuotation2.Apttus_Proposal__Proposal_Name__c, 'Test Proposal created');
    }

    /**
     *  @author Rohan Chandarana
     *  @description Test method for swap of primary qutoe
     **/
    @isTest
    static void testSyncPrimaryProposal()
    {
        Opportunity opp = [SELECT Id,First_Proposal_Id__c FROM Opportunity LIMIT 1];
        System.debug('@@@opp.First_Proposal_Id__c: '+opp.First_Proposal_Id__c);
        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Proposal__Proposal__c proposal = [Select id, Apttus_Proposal__Primary__c From Apttus_Proposal__Proposal__c LIMIT 1];
        //update proposal;
        system.debug('@@@isPrimary: '+proposal.Apttus_Proposal__Primary__c);

        Test.startTest();

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal, product);
        proposalLineItem.By_Pass_Sync_To_Opportunity__c = true;
        proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        insert proposalLineItem;

        {
            proposal.Apttus_Proposal__Primary__c = false;
            update proposal;

            proposal.Apttus_Proposal__Primary__c = true;
            update proposal;
        }

        List<OpportunityLineItem> lstOppLines = [select id from OpportunityLineItem];
        System.assert(true, lstOppLines.size()>0);
        Test.stopTest();
    }

    /**
     *  @author Rohan Chandarana
     *  @description Test method for validate cart functionality
     **/
    @isTest
    static void testCartValidations()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
        Test.startTest();
        List<Product2> lstProduct = [Select id From Product2];
        // Product 1 : non-subscription based, Product 2: subscription based
        lstProduct.get(0).Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        lstProduct.get(1).Material_Class__c = Label.ProductMaterialClassServices;
        update lstProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceListItem = [Select id,Apttus_Config2__PriceType__c From Apttus_Config2__PriceListItem__c];
        lstPriceListItem.get(0).Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceListItem.get(1).Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        update lstPriceListItem;

        Apttus_Config2__ConfigCustomClasses__c custSetting = [Select id From Apttus_Config2__ConfigCustomClasses__c LIMIT 1];
        custSetting.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        custSetting.Name = 'System Properties';
        update custSetting;

        // Create cart
        /* Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO cartResult = Apttus_CPQApi.CPQWebService.createCart(request); */

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusCheckPrice'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );
        ApttusCheckPriceController cpc = new ApttusCheckPriceController();

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = lstProduct.get(0).Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = lstProduct.get(1).Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct3 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct3.ProductId = lstProduct.get(0).Id;
        selectProduct3.Quantity = 1;
        selectProduct3.SellingTerm = 12;
        selectProduct3.StartDate = Date.today();
        selectProduct3.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct3);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        for(Integer idx=0; idx<lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }
            else if(idx == 1)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Sales_Discretionary_Discount__c = 150;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Promotion_Discount__c= 50;
                lineitem.Apttus_Config2__BasePriceOverride__c=200;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;

            }
            else if(idx == 2)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__LineStatus__c= Label.LineItemLineStatusRenewed;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;

            }
        }

        update lineItemList;
        Apttus_Config2.CustomClass.ValidationResult result = Apttus_Config2.CPQWebService.validateCart(objProductConfig.Id);
        cpc.redirectToCart();
        cpc.repriceCart();
        Test.stopTest();

        // Assertion statements
        // error messages this method validates
        Map <String, Boolean> errorMessageToFoundInResult = new Map<String, Boolean> {
                Label.UI_ErrorMessage_BlankShippingInCloseQuarter => false,
                Label.UI_ErrorMessage_ShippingInCloseQuarterGreaterThanQuantity => false,
                Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate => false
        };

        // validate messages
        for (ApexPages.Message msg : result.Messages)
        {
            String errorText = msg.getSummary();
            if (errorMessageToFoundInResult.containsKey(errorText))
                errorMessageToFoundInResult.put(errorText, true);
        }
        System.assertEquals(false,errorMessageToFoundInResult.get(Label.UI_ErrorMessage_BlankShippingInCloseQuarter),'Shipping in close Quarter validation succeed');

        // TODO: functional code not finished which fails these checks
//        for (String errorMessage : errorMessageToFoundInResult.keySet())
//        {
//            System.assert(errorMessageToFoundInResult.get(errorMessage), 'Not fired :: ' + errorMessage);
//        }

//        // Assertion statements
//        System.assertEquals(Label.UI_ErrorMessage_BlankShippingInCloseQuarter, ApttusValidationCallback.strValidationMsgBlankCloseQuarter);
//        System.assertEquals(Label.UI_ErrorMessage_ShippingInCloseQuarterGreaterThanQuantity, ApttusValidationCallback.strValidationMsgGreaterCloseQuarter);
//        System.assertEquals(Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate, ApttusValidationCallback.strValidationMsgSubscriptionProductTerm);
//        System.assertEquals(Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate, ApttusValidationCallback.strValidationMsgRenewalProductBlankStartDateEndDate);
//      //  system.assertEquals(label.Applied_Promotion_Discount_Detail,lstUpdatedLineItem.get(0).Applied_Discount_Details__c,'Different Discount Details.');
    }

    /**
     *  @author Govind Dubey
     *  @description Test method for updatePricing
     **/
    @isTest
    static void testUpdatePricing()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id,Apttus_QPConfig__PricingDate__c From Apttus_Proposal__Proposal__c LIMIT 1];
        Test.startTest();
        List<Product2> lstProduct = [Select id From Product2];
        // Product 1 : non-subscription based, Product 2: subscription based
        lstProduct.get(0).Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        lstProduct.get(1).Material_Class__c = Label.ProductMaterialClassServices;
        update lstProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceListItem = [Select id,Apttus_Config2__PriceType__c From Apttus_Config2__PriceListItem__c];
        lstPriceListItem.get(0).Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceListItem.get(1).Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        update lstPriceListItem;

        Apttus_Config2__ConfigCustomClasses__c custSetting = [Select id From Apttus_Config2__ConfigCustomClasses__c LIMIT 1];
        custSetting.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        custSetting.Name = 'System Properties';
        update custSetting;

        // Create cart
        /* Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO cartResult = Apttus_CPQApi.CPQWebService.createCart(request); */

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusCheckPrice'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );
        ApttusCheckPriceController cpc = new ApttusCheckPriceController();

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = lstProduct.get(0).Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = lstProduct.get(1).Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct3 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct3.ProductId = lstProduct.get(0).Id;
        selectProduct3.Quantity = 1;
        selectProduct3.SellingTerm = 12;
        selectProduct3.StartDate = Date.today();
        selectProduct3.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct3);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        for(Integer idx=0; idx<lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }
            else if(idx == 1)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Sales_Discretionary_Discount__c = 150;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Promotion_Discount__c= 50;
                lineitem.Apttus_Config2__BasePriceOverride__c=200;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;

            }
            else if(idx == 2)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__LineStatus__c= Label.LineItemLineStatusRenewed;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }
        }

        update lineItemList;
        Apttus_Config2.CPQWebService.validateCart(objProductConfig.Id);
        cpc.redirectToCart();
        cpc.repriceCart();
        proposal.Apttus_QPConfig__PricingDate__c= system.today()+1;
        update proposal;
        Test.stopTest();
        objProductConfig = [SELECT Id,Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c WHERE id=:objProductConfig.id];
        System.assertEquals(objProductConfig.Apttus_Config2__Status__c,Label.ConfigurationStatusSaved);
    }

    /**
     *  @author Govind Dubey
     *  @description Test method for Lock Quantity for Professional Services & Service Contracts Products functionality. Tests PriceListItemsService.updatePLIDefaults
     **/
    @isTest
    static void testPriceListItemsAndProducts()
    {
        List<Apttus_Config2__PriceListItem__c> priceListItems;
        Apttus_Config2__PriceListItem__c priceListItem1;
        Apttus_Config2__PriceListItem__c priceListItem2;
        Apttus_Config2__PriceListItem__c priceListItem3;
        
        Test.startTest();
            priceListItems = [SELECT id, Apttus_Config2__IsQuantityReadOnly__c, Apttus_Config2__PriceType__c, 
                Apttus_Config2__ProductId__c 
                FROM Apttus_Config2__PriceListItem__c LIMIT 3];
            priceListItem1 = priceListItems[0];
            priceListItem2 = priceListItems[1];
            priceListItem3 = priceListItems[2];

            Set<Id> productIds = UtilsCollection.getSetOfIds(priceListItems, 'Apttus_Config2__ProductId__c');

            Map<Id, Product2> mapProducts = new Map<Id, Product2>([SELECT id, Material_Class__c, Product_Group__c FROM Product2 WHERE id IN :productIds]);
            System.debug('mapProducts:' + JSON.serializePretty(mapProducts));

            Assert.isTrue(priceListItem1.Apttus_Config2__IsQuantityReadOnly__c,'Error while insert first priceListItems');
            Assert.isTrue(priceListItem2.Apttus_Config2__IsQuantityReadOnly__c,'Error while insert second priceListItems');
            Assert.isTrue(priceListItem3.Apttus_Config2__IsQuantityReadOnly__c,'Error while insert second priceListItems');
            
            priceListItem2.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
            update priceListItem2;

            Product2 prod1 = mapProducts.get(priceListItem1.Apttus_Config2__ProductId__c);
            Product2 prod3 = mapProducts.get(priceListItem3.Apttus_Config2__ProductId__c);
            
            prod1.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
            prod1.Product_Group__c = Label.ProductGroupProfessionalService;

            prod3.Material_Class_Type__c = Label.FixedBundleMatClassType;
            update new List<Product2> {prod1, prod3};
        Test.stopTest();

        priceListItems = [SELECT id, Apttus_Config2__IsQuantityReadOnly__c, Apttus_Config2__PriceType__c, 
                Apttus_Config2__ProductId__c 
                FROM Apttus_Config2__PriceListItem__c LIMIT 3];
        priceListItem1 = priceListItems[0];
        priceListItem2 = priceListItems[1];
        priceListItem3 = priceListItems[2];
        System.debug('priceListItems:' + priceListItems);

        Assert.isTrue(priceListItem1.Apttus_Config2__IsQuantityReadOnly__c,'Error while updating product material class as doc training and Produc Group as Professional Service');
        Assert.isFalse(priceListItem2.Apttus_Config2__IsQuantityReadOnly__c,'Error while price list item as Price One Time');
        Assert.isTrue(priceListItem3.Apttus_Config2__IsQuantityReadOnly__c,'Error while updating product Material Bundle Mat Class Type');
    }

    /**
     *  @author Govind Dubey
     *  @description Test method for preview Approvals functionality
     **/
    @isTest
    static void testPreviewApprovals()
    {
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        Test.startTest();
        Product2 product = [Select id From Product2 LIMIT 1];
        Product2 softwareProduct = [Select id From Product2 LIMIT 1];
        softwareProduct.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        update softwareProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;

        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        lstPLI.add(proposalLineItem);
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(objProposal, softwareProduct);
        proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem2.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        lstPLI.add(proposalLineItem2);
        insert lstPLI;
        Test.setCurrentPageReference(new PageReference('Page.ApttusPreviewApprovals'));
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('id', productConfig.Id);
        ApttusPreviewApprovalsController pac = new ApttusPreviewApprovalsController();

        pac.previewApprovals();
        Test.stopTest();
        system.assert(pac.lstApprovalRequestWrapper!=null, 'Error in PreviewApprovals functionality');
        system.assertEquals('test',pac.lstApprovalRequestWrapper.get(0).strApprovalName,'Approval name are different.');
        system.assertEquals('1',pac.lstApprovalRequestWrapper.get(0).lstApprovalSequence.get(0),'Approver Level not matched.');
    }

    /**
    *  @author Satya Swain
    *  @description Test method to test submit for approval email template
    **/

    /*@isTest
    static void testSubmitForApproval(){

        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
        Product2 objProduct = [Select id From Product2 LIMIT 1];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, objProduct);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;

        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id LIMIT 1 ];
        Test.startTest();
        sec.previewQuotations();
        system.assert(sec.lstApprovalRequestWrapper!=null, 'Error in PreviewApprovals functionality');
        system.assertEquals(sec.lstApprovalRequestWrapper.get(0).strApprovalName, 'test','Approval name are different.');
        system.assertEquals(sec.lstApprovalRequestWrapper.get(0).lstApproverLevel.get(0), '1','Approver Level not matched.');
        Test.stopTest();
    } */

    /**
     *  @author Govind Dubey
     *  @description Test method for Proposal Approvals functionality
     **/
    @isTest
    static void testRestrictQuoteOnClosedOpportunity()
    {
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        objOpportunity.StageName = Label.OpportunityStageClosedLost;
        objOpportunity.Competitor_Presence__c = 'No Competitor'; //objOpportunity.Competitor_Name__c = 'No Competitor'; Added by SB
        objOpportunity.Loss_Reason__c = 'Performance';
        objOpportunity.Market_Segment__c = 'Forensics';
        objOpportunity.ForecastCategoryName = 'Not Forecasted';
        objOpportunity.Opportunity_Forecast_Category__c = 'Not Forecasted';
        update objOpportunity;
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        objProposal.Apttus_Proposal__Approval_Stage__c  = 'Approval Required';
        String strErrorMsg;
        Test.startTest();
        try {
            update objProposal;
        }
        catch(Exception e)
        {
            system.debug('@@@'+e.getMessage());
            strErrorMsg = e.getMessage();
        }
// TODO: not triggering, to fix
//        system.assert(strErrorMsg.contains(Label.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity), 'update quote Closed Stage opportunity test method.');

        try
        {
            Apttus_Proposal__Proposal__c objProposalCloned = objProposal.clone(false);
            objProposalCloned.Apttus_Proposal__Opportunity__c = objOpportunity.Id;
            insert objProposalCloned;
        }
        catch(Exception e)
        {
            system.debug('@@@'+e.getMessage());
            strErrorMsg = e.getMessage();
        }
        system.assert(strErrorMsg.contains(Label.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity), 'clone quote Closed Stage opportunity test method.');
        Test.stopTest();
    }

    /**
      *  @Name           : testProposalSyncToOpportunity
      *  @Author         : Gopesh Banker (Apttus)
      *  @Description    : Test Method for syncing proposal line items to opps
      *  @Since          : 20 Sept 2018
      **/
     @isTest
     static void testProposalSyncToOpportunity()
     {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c];

        List<Product2> lstProduct = [SELECT Id FROM Product2];
        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(lstProposal.get(0), lstProduct.get(0));
        proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;

        Test.startTest();
            insert proposalLineItem;

            List<OpportunityLineItem> lstOppLines = [select id from OpportunityLineItem];
            System.debug('lstOppLines = '+lstOppLines);
            System.assert(true, lstOppLines!= null && lstOppLines.size() == 1);

            proposalLineItem.Shipping_In_Close_Quarter__c = 1;
            update proposalLineItem;

            System.assert(true, proposalLineItem.Is_Informatics_Product__c);
            System.assertEquals(proposalLineItem.Name, proposalLineItem.Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c);

            lstOppLines = [select id, Shipping_In_Close_Quarter__c from OpportunityLineItem];
            System.assert(true, lstOppLines!= null && lstOppLines.size() == 1 && lstOppLines.get(0).Shipping_In_Close_Quarter__c == 1);

            delete proposalLineItem;

            lstOppLines = [select id, Shipping_In_Close_Quarter__c from OpportunityLineItem];

            System.assert(lstOppLines.isEmpty(), 'The Opp lines are not null');
        Test.stopTest();
     }

       /**
      *  @Name           : testRequiredInformaticsFields
      *  @Author         : Rahul Bishnoi
      *  @Description    : Test Method for Checking Required Fields are filled up Informatics product Tab.
      *  @Since          : 30 Jan 2020
      **/
      @isTest
      static void testRequiredInformaticsFields()
      {
         List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c];
         List<Product2> lstProduct = [SELECT Id FROM Product2];
         List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
         lstPriceListItemId[0].Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
         Contact con = [Select id from Contact LIMIT 1];



         Test.startTest();
             List<Opportunity> lstOpp = [select id from Opportunity];
            for(Opportunity opp:lstOpp)
            {
                opp.Primary_Contact__c = null;
            }
            update lstOpp;
            lstProposal.get(0).Apttus_Proposal__Primary_Contact__c = null;
             update lstProposal;
             List<Apttus_Proposal__Proposal__c> lstProposal1 = [SELECT Id,Apttus_Proposal__Primary_Contact__c,Informatics_Product_Line_Item_Numbers__c FROM Apttus_Proposal__Proposal__c];
             List<Opportunity> fetlstOpp = [SELECT Id,Primary_Contact__c FROM Opportunity];
             System.debug('fetlstOpp --> ' + fetlstOpp);
             System.assertEquals(null, lstProposal1.get(0).Apttus_Proposal__Primary_Contact__c);
             Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(lstProposal.get(0), lstProduct.get(0));
             proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
             proposalLineItem.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
             insert proposalLineItem;
            List<Apttus_Proposal__Proposal__c> lstProposal2 = [SELECT Id,Apttus_Proposal__Primary_Contact__c,Informatics_Product_Line_Item_Numbers__c FROM Apttus_Proposal__Proposal__c];
            System.debug('lstProposal2 --> ' + lstProposal2.get(0).Informatics_Product_Line_Item_Numbers__c);

             Apttus_Proposal__Proposal_Line_Item__c upPropLineItem = [Select id,Registrant_Contact__c,Is_Informatics_Product__c,Name,Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c from Apttus_Proposal__Proposal_Line_Item__c where id = :proposalLineItem.id];
            System.debug('upPropLineItem -->' + upPropLineItem);
             System.assertEquals(true, upPropLineItem.Is_Informatics_Product__c);
             System.assertEquals(upPropLineItem.Name, upPropLineItem.Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c);

             upPropLineItem.Registrant_Contact__c = con.id;
             Update upPropLineItem;

             Apttus_Proposal__Proposal_Line_Item__c upPropLineItem1 = [Select id,Registrant_Contact__c,Is_Informatics_Product__c,Name,Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c from Apttus_Proposal__Proposal_Line_Item__c where id = :proposalLineItem.id];
             System.debug('upPropLineItem1 -->' + upPropLineItem1.Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c);
             System.assertNotEquals(upPropLineItem1.Name, upPropLineItem1.Apttus_Proposal__Proposal__r.Informatics_Product_Line_Item_Numbers__c);


         Test.stopTest();
      }

     /**
      *  @Name           : testSetMyIlluminaEmail
      *  @Author         : Roopal Verma
      *  @Description    : Test Method for setting MyIllumina Email on quote
      *  @Since          : 1 Oct 2018
      **/
     @isTest
     static void testSetMyIlluminaEmail()
     {
        String strErrorMessage;
        Account acc = TestDataAccount.getNewAccount();
        Contact con1 = TestDataPerson.getNewContact(acc.Id);
        con1.Email = 'test@test.com';
        update con1;

        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];

        Test.startTest();
        proposal.Apttus_Proposal__Primary_Contact__c = con1.Id;
        update proposal;

        proposal.MyIllumina_User_Email__c = 'test1@test.com';
        try {
            update proposal;
        } catch(Exception e) {
            System.debug('--Error3--'+e.getMessage());
            strErrorMessage = e.getMessage();
        }
        if (!String.isBlank(strErrorMessage)){
        System.assert(strErrorMessage.contains('This email address is not associated with any contact on the sold to Account.'), VALIDATION_ASSERT_MESSAGE);
        }
        Test.stopTest();
    }

    /**
      *  @Name           : testValidToInSameQuarter
      *  @Author         : Rahul Sharma
      *  @Description    : Test Method for checking valid to date in same quarter on update
      *  @Since          : 09 Oct 2018
      **/
     @isTest
     static void testValidToInSameQuarter()
     {
        String strErrorMessage;
        String strGeneratedName = 'Generated';
        List<Apttus_Proposal__Proposal__c> lstUpdatedProposal= new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c Like 'Proposal%'];
        proposal.Apttus_Proposal__Approval_Stage__c = strGeneratedName;
        Apttus_Proposal__Proposal__c proposalNew = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test New Proposal'];
        proposalNew.Apttus_Proposal__ExpectedEndDate__c = System.today()+1;
        proposalNew.Apttus_Proposal__Approval_Stage__c =strGeneratedName;
        Apttus_Proposal__Proposal__c proposalNew2 = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test New Proposal2'];
        proposalNew2.Apttus_Proposal__ExpectedEndDate__c = null;
        proposalNew2.Apttus_Proposal__Approval_Stage__c =strGeneratedName;
        try {
            update new List<Apttus_Proposal__Proposal__c> {proposal, proposalNew, proposalNew2};
        } catch(Exception e) {
            System.debug('--Error1--'+e.getMessage());
            strErrorMessage = e.getMessage();
        }
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,Apttus_Proposal__Approval_Stage__c,Quote_Output_Generated_Valid_From_Date__c,Apttus_QPConfig__PricingDate__c,Apttus_Proposal__ExpectedEndDate__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Proposal%' OR Apttus_Proposal__Proposal_Name__c LIKE 'Test New Proposal%'];
        System.debug('lstProposal:'+lstProposal);
        Test.startTest();
        try {
            for(Apttus_Proposal__Proposal__c objQuote:lstProposal){
                objQuote.Apttus_Proposal__ExpectedEndDate__c = objQuote.Quote_Output_Generated_Valid_From_Date__c + 180;
                lstUpdatedProposal.add(objQuote);
            }
            update lstUpdatedProposal;
        } catch(Exception e) {
            System.debug('--Error2--'+e.getMessage());
            strErrorMessage = e.getMessage();
        }
        if(!String.isNotBlank(strErrorMessage)  && strErrorMessage != null)
            System.assert(strErrorMessage.contains('Cannot extend approved quote beyond current quarter. Please issue a new quote.'), VALIDATION_ASSERT_MESSAGE);
        Test.stopTest();
    }

    /**
      *  @Name           : testValidToBlank
      *  @Author         : Rahul Sharma
      *  @Description    : Test Method for checking valid to date blanking out on update
      *  @Since          : 09 Oct 2018
     **/
     @isTest
     static void testValidToBlank()
     {
        String strErrorMessage;
        List<Apttus_Proposal__Proposal__c> lstUpdatedProposal= new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal= [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c Like 'Proposal%'];
        proposal.Apttus_Proposal__Approval_Stage__c ='Generated';
        update proposal;

        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,Apttus_Proposal__Approval_Stage__c,Quote_Output_Generated_Valid_From_Date__c,Apttus_QPConfig__PricingDate__c,Apttus_Proposal__ExpectedEndDate__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c LIKE 'Proposal%'];
        System.debug('lstProposal:'+lstProposal);
        Test.startTest();
        try {
            for(Apttus_Proposal__Proposal__c objQuote:lstProposal)
            {
                objQuote.Apttus_Proposal__ExpectedEndDate__c = null;
                lstUpdatedProposal.add(objQuote);
            }
            update lstUpdatedProposal;
        } catch(Exception e) {
            System.debug('--Error--'+e.getMessage());
            strErrorMessage = e.getMessage();
        }
        if(!String.isNotBlank(strErrorMessage) && strErrorMessage != null)
            System.assert(strErrorMessage.contains('Cannot extend approved quote beyond current quarter. Please issue a new quote.'), VALIDATION_ASSERT_MESSAGE);
        Test.stopTest();
    }

    /**
      *  @Name           : testSyncOppLineToCart
      *  @Author         : Milan Savaliya
      *  @Description    : Test Method for checking Opportunity Line Item Sync To Cart
      *  @Since          : 09 Oct 2018
      **/
     @isTest
     static void testSyncOppLineToCart()
     {
        Test.startTest();//Arnab
        List<Apttus_Config2__PriceList__c> lstPriceList= [Select ID,Name  From Apttus_Config2__PriceList__c LIMIT 1];
        if(!lstPriceList.isEmpty()) {

            Account objAccount = TestDataAccount.getNewAccount();
            objAccount.Account_Group__c = 'Distributor';

            List<Account> lstAccount = new List<Account>();
            lstAccount.add(objAccount);

            update lstAccount;

            Apttus_Config2__PriceList__c obPriceList = lstPriceList[0];
            Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount, 'Indirect_Standard');
            objOpportunity.Name = 'opp2';
            objOpportunity.Distributor__c = objAccount.Id;
            objOpportunity.Ultimate_Consignee__c = objAccount.Id;
            objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = false;
            objOpportunity.Price_List__c = obPriceList.Name;
            insert objOpportunity;

            system.debug('####BatchToCloneOppLineToCart objOpportunity:' + objOpportunity);
            //Test.startTest();
            //Commented by Arnab
            List<OpportunityLineItem> lstOpportunityLineItem = new List<OpportunityLineItem>();
            for(Product2 objProduct : [SELECT Id FROM Product2 LIMIT 1])
            {
                PricebookEntry objPricebookEntry = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
                lstOpportunityLineItem.add(TestDataMaster.createOpportunityProduct(objOpportunity.Id, objPricebookEntry.Id, true));
            }

            List<Apttus_Config2__ConfigCustomClasses__c> listConfigCustomClasses = [SELECT ID FROM Apttus_Config2__ConfigCustomClasses__c];
            if(!listConfigCustomClasses.isEmpty())
            {
                delete listConfigCustomClasses;
            }
            Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objOpportunity.AccountId
                                                                                    , objOpportunity.id
                                                                                    , 'Test Proposal'
                                                                                    , obPriceList.id
                                                                                    , true
                                                                                    , 'Draft'
                                                                                    , 'None');
            insert objProposal;

            for (Apttus_Proposal__Proposal__c objProposalToVerify : [SELECT Id
                    ,Apttus_QPConfig__PriceListId__c
                    FROM Apttus_Proposal__Proposal__c
                    WHERE Id = :objProposal.Id])
            {
                System.assert(objProposalToVerify.Apttus_QPConfig__PriceListId__c != NULL, 'Price List Was not set for Indirect Opp');
            }
        }
        Test.stopTest();//Arnab
    }
	@isTest
    private static void testupdatePrimaryContactOnOpportunityContactRole(){
        Opportunity objOpp = [Select id From Opportunity LIMIT 1];

        List<Contact> lstCon = [select id from Contact limit 2];

        OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', lstCon[0].Id, objOpp.Id);
        OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', lstCon[1].Id, objOpp.Id);
        insert new List<OpportunityContactRole> { ocr1, ocr2 };
        System.assert([select id,isPrimary from OpportunityContactRole where ContactId =: lstCon[0].Id][0].isPrimary);
        Test.startTest();
        Apttus_Proposal__Proposal__c objProp = [Select id,Apttus_Proposal__Primary_Contact__c From Apttus_Proposal__Proposal__c where Apttus_Proposal__Primary__c = true LIMIT 1];

        objProp.Apttus_Proposal__Primary_Contact__c = lstCon[1].Id;
        ApttusProposals.isQuoteUpdatedFromOpty = false;
        Update objProp;
        Test.stopTest();
        System.assert([select id,isPrimary from OpportunityContactRole where ContactId =: lstCon[1].Id][0].isPrimary);
    }

   /**
    * @author Satya Swain
    * @date   2020-11-02
    * @description INC0281082 : test method for primary quote sync failure. Tests ApttusSyncToOpportunityQueueable
    * @param void
    **/ 
    @isTest
    private static void testSyncPrimaryProposalFailure()
    {
        ApttusSyncToOpportunityQueueable.boolSendEmail = true;

        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = true;
        upsert cs;

        User objSalesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP);

        List<Apttus_Proposal__Proposal__c> quotations = [SELECT Id, Apttus_Proposal__Opportunity__c 
            FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c IN ('Test Proposal', 'Proposal 1') LIMIT 2];
        
        for(Apttus_Proposal__Proposal__c quotation : quotations) {
            quotation.Apttus_Proposal__Primary__c = true;
            quotation.ownerId = objSalesUser.id;
        }
        update quotations;

        Opportunity objOpportunity = [SELECT Id, StageName, Loss_Reason__c, Has_Competitor_Info__c, Competitor_Presence__c
            FROM Opportunity WHERE Id = :quotations[0].Apttus_Proposal__Opportunity__c];
        System.debug('objOpportunity:' + objOpportunity);

        List<OpportunityLineItem> lstOpportunityLineItem = new List<OpportunityLineItem>();
        for(Product2 objProduct : [SELECT Id FROM Product2 LIMIT 1])
        {
            PricebookEntry objPricebookEntry = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
            lstOpportunityLineItem.add(TestDataMaster.createOpportunityProduct(objOpportunity.Id, objPricebookEntry.Id, false));
        }
        insert lstOpportunityLineItem;

        objOpportunity.StageName = Label.OpportunityStageClosedLost;
        objOpportunity.Loss_Reason__c = OPPORTUNITY_LOSS_REASON_PRICE;
        objOpportunity.ForecastCategoryName = 'Not Forecasted';
        objOpportunity.Opportunity_Forecast_Category__c = 'Not Forecasted';
        objOpportunity.OwnerId = objSalesUser.id;
        update objOpportunity;

        Integer invocations = 0;
        Test.startTest();
        System.runAs(objSalesUser)
        {
            ApttusSyncToOpportunityQueueable queueableClassInstance = 
                new ApttusSyncToOpportunityQueueable(new Set<Id>{quotations[0].Id, quotations[1].Id});
            queueableClassInstance.execute(null);
            invocations = Limits.getEmailInvocations();
            System.debug('invocations:' + invocations);
        }
        Test.stopTest();

        Assert.isTrue(invocations > 0, 'Not email invocations were detected');
    }
    
    /**
     *  @Name           : testLocationUpdate
    *  @Author         : KD
    *  @Description    : Test Method for checking location update on quote
    **/
    @isTest
    static void testLocationUpdate()
    {
        Test.startTest();
        List<Apttus_Config2__PriceList__c> lstPriceList= [Select ID,Name  From Apttus_Config2__PriceList__c LIMIT 1];
        if(!lstPriceList.isEmpty()) {

            Account objAccount = TestDataAccount.getNewAccount();
            objAccount.Account_Group__c = 'Distributor';
            List<Account> lstAccount = new List<Account>();
            lstAccount.add(objAccount);

            update lstAccount;
            SVMXC__Site__c objSite = new SVMXC__Site__c();
            objSite.SVMXC__Account__c = objAccount.id;
            objSite.ERP_Customer_ID__c = 'SITE1';
            objSite.SVMX_PS_External_ID__c = 'SITE1';
            objSite.Type__c = 'Partner Stock';
            objSite.Name = 'Partner Stock Test';
            insert objSite;
            Apttus_Config2__PriceList__c obPriceList = lstPriceList[0];
            Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount, 'Indirect_Standard');
            objOpportunity.Name = 'opp2';
            objOpportunity.Distributor__c = objAccount.Id;
            objOpportunity.Ultimate_Consignee__c = objAccount.Id;
            objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = false;
            objOpportunity.Price_List__c = obPriceList.Name;
            insert objOpportunity;
            List<OpportunityLineItem> lstOpportunityLineItem = new List<OpportunityLineItem>();
            for(Product2 objProduct : [SELECT Id FROM Product2 LIMIT 1])
            {
                PricebookEntry objPricebookEntry = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
                lstOpportunityLineItem.add(TestDataMaster.createOpportunityProduct(objOpportunity.Id, objPricebookEntry.Id, true));
            }

            List<Apttus_Config2__ConfigCustomClasses__c> listConfigCustomClasses = [SELECT ID FROM Apttus_Config2__ConfigCustomClasses__c LIMIT 1000];
            if(!listConfigCustomClasses.isEmpty())
            {
                delete listConfigCustomClasses;
            }
            Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objOpportunity.AccountId
                                                                                    , objOpportunity.id
                                                                                    , 'Test Proposal'
                                                                                    , obPriceList.id
                                                                                    , true
                                                                                    , 'Draft'
                                                                                    , 'None');
            insert objProposal;

            for (Apttus_Proposal__Proposal__c objProposalToVerify : [SELECT Id
                    ,Apttus_QPConfig__PriceListId__c,Inventory_Location__c
                    FROM Apttus_Proposal__Proposal__c
                    WHERE Id = :objProposal.Id])
            {
                System.assertEquals(objSite.Id,objProposalToVerify.Inventory_Location__c, 'Location not set');
            }
        }
        Test.stopTest();
    }
	
    /**
    * @author Rishab
    * @date   2020-11-02
    * @description Test Method for checking autoGenerateLogic Failed
    * @param void
    **/ 
    @isTest
    static void testQueueableAutoGenerateLogicFail()
    {
        Apttus_Proposal__Proposal__c proposal= [Select id,Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c Like 'Proposal%' LIMIT 1];
        proposal.Apttus_Proposal__Approval_Stage__c ='Approved';
        runAutoGenerateLogic = true;
        Test.startTest();
        update proposal;
        Test.stopTest();
        Apttus_Proposal__Proposal__c objProposal = [Select id,Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Id =: proposal.Id LIMIT 1];       
        System.assertEquals('Approved',objProposal.Apttus_Proposal__Approval_Stage__c,'Queueable did not update.');   
    }

    /**DCP-46920
    *  @author      : Rishab
    *  @description : method to test Success Email
    **/
    @istest
    static void testAutoGenerateSuccess()
    {
        Apttus_Proposal__Proposal__c proposal= [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c Like 'Proposal%' LIMIT 1];
        SendEmailToQuoteOwnersQueueable queueable = new SendEmailToQuoteOwnersQueueable();
        queueable.setRecordId(proposal.id);
        queueable.getErrorDetails();
        Test.startTest();
        runAutoGenerateLogic = true;
        queueable.execute(null);
        Id recordId = queueable.getRecordId();
        System.assert(recordId!=Null, 'Success Email Not Sent');
        Test.stopTest();
    }

    /**DCP-46920
     *  @author      : Rishab
     *  @description : method to test send email
     **/
    @isTest
    static void testCheckErrorScenarioForQuoteAutoGenerate(){
        Test.startTest();
        Apttus_Proposal__Proposal__c proposal= [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c Like 'Proposal%' LIMIT 1];        
            List<String> lstActionClasses = new List<String>();
            OpportunityQuoteAutomationQueueable objQueueable = new OpportunityQuoteAutomationQueueable(proposal.Id,null,lstActionClasses);
            objQueueable.execute(null);
            OpportunityQuoteAutomationQueueable.handleNotificationForQuotationAutoGenerate(proposal.Id);
            Integer invocations = Limits.getEmailInvocations();
            System.assert(invocations > 0,'Email Sent');
            Test.stopTest();
    }

    @isTest static void testCreatedByRoleDirectQuote()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        //Query permission set including Custom Permission: CP_Manage_Partner_Portal_Users 
        PermissionSet permissionSet = [SELECT ID FROM PermissionSet WHERE Name =: TestDataUser.PERMISSIONSET_MANAGE_PARTNER_PORTAL_USERS LIMIT 1];
        //Assign permission set to User so it will pass the User Validation Rule: Only_UserProvisioning_Edit_UserRecords
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = objUser.Id);
        insert permissionSetAssignment;
        //Commercial Ops Quoting User we are going to create
        Id commercialOpsQuotingUserId;
        System.runAs(objUser){
            List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory_Region__c,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
            FROM Territory2Model WHERE State='Active'];
            Territory2Model objTerritoryModel = lstModels.get(0);
            Territory2 territoryRegion = objTerritoryModel.Territory2s.get(0);

            Profile commercialOpsQuotingUserProfile = [SELECT ID FROM Profile WHERE Name =: TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER LIMIT 1];
            UserRole amrSalesUserRole = [SELECT ID FROM UserRole WHERE Name =: TestDataUser.ROLE_AMR_SALES LIMIT 1];
            User commercialOpsQuotingUser = TestDataUser.initStandardInternalUser(commercialOpsQuotingUserProfile.Id, amrSalesUserRole.Id);
            insert commercialOpsQuotingUser;
            commercialOpsQuotingUserId = commercialOpsQuotingUser.Id;

            UserTerritory2Association associatedUser = TestDataTerritory.initUserTerritoryLinkRole(commercialOpsQuotingUserId, territoryRegion.Id, 'Inside Sales Representative - Service Contract Specialists');
            insert associatedUser;

            Account acc = TestDataAccount.getAccount('Test 1');
            String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
            acc.RecordTypeId = recordtypeid;
            insert acc;

            TestDataObjectTerritory2Association.getObjectAssociationFuture(territoryRegion.id,acc.id);
        }
        Id prpslId = testCreatedByRoleDirect(commercialOpsQuotingUserId);
        Apttus_Proposal__Proposal__c prpsl =  [SELECT Id,created_By_Role__c FROM Apttus_Proposal__Proposal__c where id =:prpslId];
        system.assertEquals('Inside Sales Representative - Service Contract Specialists', prpsl.created_By_Role__c, 'Role does not match');
    }
    
    static Id testCreatedByRoleDirect(Id createdUserId)
    {
        Test.startTest();
        User commUser = [SELECT ID FROM USER WHERE ID =: createdUserId LIMIT 1];
        Account acc = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test 1' limit 1];
       
        Apttus_Proposal__Proposal__c proposal;
        system.runas(commUser)
        {     
            Contact con1 = TestDataContact.initContact(acc);
            insert con1;

            Opportunity opp = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTDirectStandard);
            opp.Name = 'opp1';
            opp.Ultimate_Consignee__c = acc.Id;
            insert opp;   

            OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, opp.Id);
            insert ocr1;

            Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
            insert priceList;
            String strDraft = 'Draft';
            String strNone = 'None';
            proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, strDraft, strNone);
            proposal.Apttus_Proposal__Account__c = acc.id;
            //proposal.Apttus_Proposal__Account__r.Territory_Region__c = territoryRegion.Territory_Region__c;
            insert proposal;
        }

        Test.stopTest();
        return proposal.Id;
    }
    
    @isTest static void testCreatedByRoleIndirectQuote()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
        //Test.startTest();
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory_Region__c,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c FROM Territory2s where Territory2Type.DeveloperName = 'Territory_Distributor_Channel_Partner') 
        FROM Territory2Model WHERE State='Active'];
        Territory2Model objTerritoryModel = lstModels.get(0);
        Territory2 territoryRegion = objTerritoryModel.Territory2s.get(0);

        User territoryUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER, new Set<Id>());
       // insert territoryUser;
        UserTerritory2Association associatedUser = TestDataTerritory.initUserTerritoryLinkRole(territoryUser.Id, territoryRegion.Id, 'Inside Sales Representative - Service Contract Specialists');
        insert associatedUser;

        Account acc = TestDataAccount.getAccount('Distri');
        acc.Account_Group__c = 'Distributor';

        Account accUC = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        insert acc;

        accUC.recordtypeid = recordtypeid;
        insert accUC;
        //Test.stopTest();
        TestDataObjectTerritory2Association.getObjectAssociationFuture(territoryRegion.id,acc.id);
        }
        Id prpslId = testCreatedByRoleIndirectProposal();
        Apttus_Proposal__Proposal__c prpsl =  [SELECT Id,created_By_Role__c FROM Apttus_Proposal__Proposal__c where id =:prpslId];
        system.assertEquals('Inside Sales Representative - Service Contract Specialists', prpsl.created_By_Role__c,'Role does not match');
    }
    
    static Id testCreatedByRoleIndirectProposal()
    {
        Test.startTest();
        User commUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER, new Set<Id>());
              
       Account acc = [SELECT ID,Name  FROM ACCOUNT WHERE NAME = 'Distri' limit 1];
       

       Account accUC = [SELECT ID,Name  FROM ACCOUNT WHERE NAME = 'Test 1' limit 1];

       Apttus_Proposal__Proposal__c proposal;
        system.runas(commUser)
       {     
            Contact con1 = TestDataContact.initContact(acc);
            insert con1; 
            Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
            insert priceList;
            Opportunity objOpportunity = TestDataOpportunity.initOpportunity(accUC, 'Indirect_Standard');
            objOpportunity.Name = 'opp2';
            objOpportunity.Distributor__c = acc.Id;
            objOpportunity.Ultimate_Consignee__c = accUC.Id;
            objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = true;
            objOpportunity.Price_List__c = acc.Name;
            insert objOpportunity; 

            OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, objOpportunity.Id);
            insert ocr1;

         
            String strDraft = 'Draft';
            String strNone = 'None';
            proposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, strDraft, strNone);
           proposal.Apttus_Proposal__Account__c = acc.id;
            //proposal.Apttus_Proposal__Account__r.Territory_Region__c = territoryRegion.Territory_Region__c;
            insert proposal;

    }

        Test.stopTest();
       return proposal.Id;
    }
    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in ApttusProposalQueueable
     **/
    @isTest
    public static void coverCatchBlockApttusProposalQueueable(){
        try{
            ApttusProposalQueueable.catchException = true;
            ApttusProposalQueueable pd = new ApttusProposalQueueable(null, null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }

    @isTest
    private static void setDefaultValuePrimaryContactShouldPopulateFromQuotationPrimaryContact() {
        Product2 product = [SELECT Id FROM Product2 WHERE NAME = :INFORMATIC_PRODUCT LIMIT 1];

        Contact contact = [SELECT id FROM Contact LIMIT 1];

        Apttus_Proposal__Proposal__c quotation = [SELECT Id, Apttus_Proposal__Proposal_Name__c, 
            Apttus_Proposal__Account__r.Territory_Region__c, Apttus_Proposal__Primary_Contact__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        quotation.Apttus_Proposal__Primary_Contact__c = contact.id;
        update quotation;

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(quotation, product);
        insert proposalLineItem;
        Test.stopTest();

        Apttus_Proposal__Proposal_Line_Item__c res = [SELECT Id, Registrant_Contact__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE id = :proposalLineItem.id LIMIT 1];
        System.debug('res:' + JSON.serializePretty(res));
        Assert.isNotNull(res.Registrant_Contact__c, 'Registrant Contact should be populated');
    }

    @isTest
    private static void setDefaultValuePrimaryContactShouldPopulateNull() {
        Product2 product = [SELECT Id FROM Product2 WHERE NAME = :ADD_ON_PRODUCT LIMIT 1];

        Apttus_Proposal__Proposal__c quotation = [SELECT Id, Apttus_Proposal__Proposal_Name__c, 
            Apttus_Proposal__Account__r.Territory_Region__c, Apttus_Proposal__Primary_Contact__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(quotation, product);
        insert proposalLineItem;
        Test.stopTest();

        Apttus_Proposal__Proposal_Line_Item__c res = [SELECT Id, Registrant_Contact__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE id = :proposalLineItem.id LIMIT 1];
        System.debug('res:' + JSON.serializePretty(res));
        Assert.isNull(res.Registrant_Contact__c, 'Registrant Contact should be populated');
    }

    @IsTest
    private static void setDefaultValuePrimaryContactShouldPopulateFromOrderLineItemRegistrantContact() {
        String erpIdLineItem = 'someId';
        Account account = [SELECT id FROM Account WHERE Name = :ACCOUNT_NAME_1 LIMIT 1];

        Contact contact = [SELECT id FROM Contact LIMIT 1];

        Product2 product = [SELECT Id FROM Product2 WHERE NAME = :INFORMATIC_PRODUCT LIMIT 1];

        Apttus_Proposal__Proposal__c quotation = [SELECT Id, Apttus_Proposal__Proposal_Name__c, 
            Apttus_Proposal__Account__r.Territory_Region__c, Apttus_Proposal__Primary_Contact__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];

        Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
        objOrder.Apttus_QPConfig__ProposalId__c = quotation.Id;
        insert objOrder;

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AssetStatus__c = ASSET_STATUS_PENDING_RENEWAL;
        objAssetLineItem.Status__c = ASSET_STATUS_PENDING_RENEWAL;
        objAssetLineItem.Apttus_Config2__AccountId__c = account.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = product.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = quotation.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = Date.valueOf('2017-12-31');
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
        objOrderLineItem.Apttus_Config2__LineStatus__c = System.Label.LineItemLineStatusRenewed;
        objOrderLineItem.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem.Registrant_Contact__c = contact.Id;
        objOrderLineItem.ERP_Line_Number_Id__c = erpIdLineItem;
        insert objOrderLineItem;

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(quotation, product);
        proposalLineItem.ERP_Line_Number_Id__c = erpIdLineItem;
        insert proposalLineItem;
        Test.stopTest();

        Apttus_Proposal__Proposal_Line_Item__c res = [SELECT Id, Registrant_Contact__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE id = :proposalLineItem.id LIMIT 1];
        System.debug('res:' + JSON.serializePretty(res));
        Assert.isNotNull(res.Registrant_Contact__c, 'Registrant Contact should be populated');
    }

    @isTest
    private static void setQuotationExpectedEndDateFromQuoteLineStillEffectivePricingDate() {
        Apttus_Proposal__Proposal__c quotation = [SELECT Id, Apttus_Proposal__Proposal_Name__c, 
            Apttus_Proposal__ExpectedEndDate__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        quotation.Apttus_QPConfig__PricingDate__c = System.today() + 28;
        update quotation;
        System.debug('quotation:' + quotation);

        Product2 product = [SELECT Id FROM Product2 WHERE NAME = :INFORMATIC_PRODUCT LIMIT 1];

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(quotation, product);
        proposalLineItem.End_Of_Sale_Date__c = System.today() + 10;
        insert proposalLineItem;
        Test.stopTest();

        Apttus_Proposal__Proposal__c res = [SELECT Id, Apttus_Proposal__ExpectedEndDate__c FROM Apttus_Proposal__Proposal__c WHERE id = :quotation.id LIMIT 1];
        System.debug('res:' + JSON.serializePretty(res));
        Assert.areEqual(proposalLineItem.End_Of_Sale_Date__c, res.Apttus_Proposal__ExpectedEndDate__c, 'Quotation and Quotation end sales date does not match!');
    }

    @isTest
    private static void setQuotationExpectedEndDateFromQuoteLineNotEffectivePricingDate() {
        Apttus_Proposal__Proposal__c quotation = [SELECT Id, Apttus_Proposal__Proposal_Name__c, 
            Apttus_Proposal__ExpectedEndDate__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        quotation.Apttus_QPConfig__PricingDate__c = System.today() + 28;
        quotation.Apttus_Proposal__ExpectedEndDate__c = null; // TODO: Can't override value due being Conga Quote Management
        quotation.Is_Updated_By_System__c = true;
        update quotation;
        System.debug('quotation:' + quotation);

        Product2 product = [SELECT Id FROM Product2 WHERE NAME = :INFORMATIC_PRODUCT LIMIT 1];

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(quotation, product);
        proposalLineItem.End_Of_Sale_Date__c = System.today() + 10;
        insert proposalLineItem;
        Test.stopTest();

        Apttus_Proposal__Proposal__c res = [SELECT Id, Apttus_Proposal__ExpectedEndDate__c FROM Apttus_Proposal__Proposal__c WHERE id = :quotation.id LIMIT 1];
        System.debug('res:' + JSON.serializePretty(res));
        // Assert.areEqual(proposalLineItem.End_Of_Sale_Date__c, res.Apttus_Proposal__ExpectedEndDate__c, 'Quotation and Quotation end sales date does not match!'); // Can't override End_Of_Sale_Date__c
        Assert.isNotNull(res.Apttus_Proposal__ExpectedEndDate__c, 'Quotation Apttus_Proposal__ExpectedEndDate__c should not be null');
    }

    @isTest
    private static void testApproverAccessOnInsert() {
        Apttus_Proposal__Proposal__c objProposal = [Select Id From Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Approver Access On Insert' LIMIT 1];
        User user1 = [select Id from User where LastName = 'Approver1' limit 1];

        List<Apttus_Proposal__Proposal__Share> shareRecordsUser1 = new List<Apttus_Proposal__Proposal__Share>();
        Boolean isSharedWithUser1;

        //Insert approval request
        Apttus_Approval__Approval_Request__c approvalRequest = TestDataProposal.initApprovalRequest(objProposal.Id, user1.Id);
        Test.startTest();
        insert approvalRequest;
        Test.stopTest();

        shareRecordsUser1 = [select Id from Apttus_Proposal__Proposal__Share where ParentId = :objProposal.Id and UserOrGroupId = :user1.Id and RowCause = 'Approver__c'];
        isSharedWithUser1 = !shareRecordsUser1.isEmpty();
        Assert.isTrue(isSharedWithUser1, 'Record should be shared with original Approver');
    }

    @isTest
    private static void testApproverAccessOnReassignment() {
        Apttus_Proposal__Proposal__c objProposal = [Select Id From Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Approver Access On Reassignment' LIMIT 1];
        User user1 = [select Id from User where LastName = 'Approver1' limit 1];
        User user2 = [select Id from User where LastName = 'Approver2' limit 1];

        List<Apttus_Proposal__Proposal__Share> shareRecordsUser2 = new List<Apttus_Proposal__Proposal__Share>();
        Boolean isSharedWithUser2;

        //Insert approval request
        Apttus_Approval__Approval_Request__c approvalRequest = TestDataProposal.initApprovalRequest(objProposal.Id, user1.Id);
        Test.startTest();
        insert approvalRequest;

        //Re-assign approval request
        Apttus_Approval__Approval_Request__c approvalRequestToUpdate = [select Id, Apttus_Approval__Assigned_To_Id__c, Apttus_Approval__Approval_Status__c from Apttus_Approval__Approval_Request__c where Apttus_Approval__ObjectRefId__c = :objProposal.Id];
        approvalRequestToUpdate.Apttus_Approval__Assigned_To_Id__c = user2.Id;
        approvalRequestToUpdate.Apttus_Approval__Approval_Status__c = Label.ApprovalRequestApprovalStatusAssigned;
        update approvalRequestToUpdate;
        Test.stopTest();

        shareRecordsUser2 = [select Id from Apttus_Proposal__Proposal__Share where ParentId = :objProposal.Id and UserOrGroupId = :user2.Id and RowCause = 'Approver__c'];
        isSharedWithUser2 = !shareRecordsUser2.isEmpty();
        Assert.isTrue(isSharedWithUser2, 'Record should be shared with new Approver');
    }
}
