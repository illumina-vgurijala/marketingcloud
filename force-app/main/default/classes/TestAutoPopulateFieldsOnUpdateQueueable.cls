/**
*    @author Bharath Varma
*    @date   2021-03-16
*    @description    Test Class For AutoPopulateOppFieldsOnUpdateQueueable Class
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Bharath Varma                2021-03-16          Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
*      Pravallika, Gundreddy          28-nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
**/
@isTest(isParallel=false)
public class TestAutoPopulateFieldsOnUpdateQueueable {
    
    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        opp.Proposal_Sent_On__c = null;
        insert opp;
        
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
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2, proposal3 };

        Product2 product = TestDataMaster.createProduct(false);
        Product2 productTwo = TestDataMaster.createProduct(false);
        Product2 productThree = TestDataMaster.createProduct(false);
        insert new List<Product2> { product, productTwo, productThree };

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
        Apttus_Config2__ClassificationHierarchy__c level0= TestDataProposal.initHierarchy(category, 'Level0', null, null, 0);
        lstOfLevels.add(level0);
        Apttus_Config2__ClassificationHierarchy__c level1= TestDataProposal.initHierarchy(category, 'Level1', level0, level0, 1);
        lstOfLevels.add(level1);
        Apttus_Config2__ClassificationHierarchy__c level2= TestDataProposal.initHierarchy(category, 'Level2', level0, level1, 2);
        lstOfLevels.add(level2);
        Apttus_Config2__ClassificationHierarchy__c level3= TestDataProposal.initHierarchy(category, 'Level3', level0, level2, 3);
        lstOfLevels.add(level3);
        Apttus_Config2__ClassificationHierarchy__c level4= TestDataProposal.initHierarchy(category, 'Level4', level0, level3, 4);
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

        System.assertEquals(5, lstEmailTemplateIds.size(),'All templates not inserted.');

        TestDataApprovalProcess.getApprovalProcess();

        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;

        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(proposal.Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;
    }

    /*Method to check if quote stage in review */
   @isTest
    public static void updateQuoteIsStagePresented()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id, Apttus_Proposal__Approval_Stage__c,
                                                            Apttus_Proposal__ReadyToPresent__c, Apttus_Proposal__Presented_Date__c
                                                          FROM Apttus_Proposal__Proposal__c LIMIT 10];
        test.startTest();
        lstProposal[0].Apttus_Proposal__Approval_Stage__c = System.Label.QuoteStagePresented;
        lstProposal[0].Apttus_Proposal__ReadyToPresent__c = true;
        lstProposal[0].Apttus_Proposal__Presented_Date__c = System.Today();
        Id quoteId = lstProposal[0].Id;

        update lstProposal;
        test.stopTest();

        List<Apttus_Proposal__Proposal__c> lstProposals = [SELECT Id,Apttus_Proposal__Approval_Stage__c, Apttus_Proposal__Opportunity__c,
                                                          Apttus_Proposal__Opportunity__r.Proposal_Sent_On__c
                                                          FROM Apttus_Proposal__Proposal__c WHERE Id=:quoteId LIMIT 10];

        System.assertEquals(System.Label.QuoteStagePresented, lstProposals[0].Apttus_Proposal__Approval_Stage__c);
        
    }

    /*Method to check if quote stage not in review */
    @isTest
    public static void checkOppStageNotInCreate()
    {
        List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id,Apttus_Proposal__Opportunity__c, Apttus_Proposal__Approval_Stage__c,
                                                            Apttus_Proposal__ReadyToPresent__c,
                                                          Apttus_Proposal__Opportunity__r.Proposal_Sent_On__c, Apttus_Proposal__Opportunity__r.StageName
                                                          FROM Apttus_Proposal__Proposal__c LIMIT 10];

        List<Opportunity> lstOpp = [SELECT Id, Proposal_Sent_On__c, StageName
                                    FROM Opportunity LIMIT 10];
        lstOpp[0].StageName = System.Label.OpportunityStageQualify;
        update lstOpp;

        test.startTest();
        lstProposal[0].Apttus_Proposal__Approval_Stage__c = System.Label.QuoteStagePresented;
        lstProposal[0].Apttus_Proposal__ReadyToPresent__c = false;


        update lstProposal;
        test.stopTest();
        List<Apttus_Proposal__Proposal__c> lstProposals = [SELECT Id,Apttus_Proposal__Opportunity__c,
                                                          Apttus_Proposal__Opportunity__r.Proposal_Sent_On__c, Apttus_Proposal__Opportunity__r.StageName
                                                          FROM Apttus_Proposal__Proposal__c LIMIT 10];
        System.assertEquals(System.Label.OpportunityStageQualify,lstProposals[0].Apttus_Proposal__Opportunity__r.StageName);
        
    }
}