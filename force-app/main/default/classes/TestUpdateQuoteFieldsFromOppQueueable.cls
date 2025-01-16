/**
*    @author Rishab Wali
*    @date   2021-03-22
*    @description    DCP-45455: Opportunity Improvements (Update Quote Fields trigerred from Opp Updates)
*    @Test Class  -  Covers class - UpdateQuoteFieldsFromOppQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                         2021-03-16          Initial Version
*         Akshay Mohan                   2021-06-07          DCP-46835: Add logic for checking Exclude from forecast
*         Pravallika, Gundreddy          28-nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*         Atit Kar                       13-March-2023       INC0419938 - Removed checkupdateManualQuoteNumber method  
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class TestUpdateQuoteFieldsFromOppQueueable {

    @testSetup
    static void initializeTestData()
    {
        User userWithPermission = [SELECT Id,Name FROM User WHERE Id =: UserInfo.getUserId()];
        new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_Custom_Perm';
        ps.Label = 'Test_Custom_Perm';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Sales_Integration_User'][0].Id;
        insert sea;

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userWithPermission.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        
        System.runAs(userWithPermission){
        Account acc = TestDataAccount.initAccount();
        Account acc2 = TestDataAccount.initAccount();
        acc2.BillingCountry = 'USA';
        acc2.BillingState = 'Pennsylvania';
        acc2.Billingstatecode = 'PA';
        acc2.CurrencyIsoCode = 'USD';
        acc2.BillingCountryCode='US';
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
        opp.name = 'Test Opp 1';
        opp.Ultimate_Consignee__c = acc.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        opp2.Pricebook2Id = standardPricebook.Id;
        opp2.Price_List__c = '01-AMR-USD';
        opp2.Proposal_Sent_On__c = null;
        opp2.name = 'Test Opp 2';
        opp2.Type = 'Custom Product (First Buy)';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Are_Products_Added__c = false;
        insert new List<Opportunity>{opp,opp2};
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strDraft = 'Draft'; 
        String strNone = 'None'; 
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, strDraft, strNone); 
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Proposal 1', priceList.id, true, strDraft, strNone); 
        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal', priceList.id, true, strDraft, strNone);
        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test New Proposal', priceList.id, true, strDraft, strNone);  
        proposal2.Is_Updated_By_System__c = true;
        proposal4.Is_Updated_By_System__c = true;
        proposal.Is_Updated_By_System__c = true;
        proposal1.Is_Updated_By_System__c = true;
        proposal2.Apttus_Proposal__ExpectedEndDate__c = System.today();
        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal2', priceList.id, true, strDraft, strNone); 
        proposal3.Apttus_Proposal__ExpectedEndDate__c = System.today();
        proposal3.Is_Updated_By_System__c = true;
        proposal4.SAP_Quote__c = '1111111';
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2, proposal3 , proposal4 };

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
            
    }
    
    static testMethod void checkUpdatedQuoteFromOppTransborderFalse()
    {
        test.startTest();
        List<account> accList = [SELECT Id,Name,BillingCountry FROM Account LIMIT 10];
        Opportunity opp = [SELECT Id,Name FROM Opportunity WHERE name = 'Test Opp 1'];
        opp.Ultimate_Consignee__c = accList[1].Id;
        opp.AccountId = accList[1].Id;
        opp.Transborder_Flag__c = true;
        update opp;
        test.stopTest();
        //DCP-46835: Start- Check Exclude_from_Forecast__c
        Test.getEventBus().deliver();
        Opportunity oppObj = [SELECT Id,Transborder_Flag__c,Exclude_from_Forecast__c FROM Opportunity WHERE id = : opp.Id];
		System.assert(!oppObj.Transborder_Flag__c,'Transborder flag set');
        System.assert(!oppObj.Exclude_from_Forecast__c,'Exclude_from_Forecast__c flag set');
        //DCP-46835: End- Check Exclude_from_Forecast__c
    }
    
    static testMethod void checkUpdatedQuoteFromOppTransborderTrue()
    {
        test.startTest();
        List<account> accList = [SELECT Id,Name,BillingCountry,BillingState FROM Account WHERE BillingCountry='USA'];
        Opportunity opp = [SELECT Id,Ultimate_Consignee__r.BillingCountry,Account.BillingCountry,Name FROM Opportunity WHERE name = 'Test Opp 1'];
        opp.Ultimate_Consignee__c = accList[0].Id;
        opp.Transborder_Flag__c = false;
        update opp;
        test.stopTest();
        //DCP-46835: Start- Check Exclude_from_Forecast__c
        Test.getEventBus().deliver();
        Opportunity oppObj = [SELECT Id,Transborder_Flag__c, Exclude_from_Forecast__c
                                FROM Opportunity WHERE id = : opp.Id];
		System.assert(oppObj.Transborder_Flag__c,'Transborder flag not set');
        System.assert(!oppObj.Exclude_from_Forecast__c,'Exclude_from_Forecast__c flag set');
        //DCP-46835: End- Check Exclude_from_Forecast__c
    }
    

    /**
     *  @author      : Biswajeet [CMSI-201]
     *  @description : method to cover catch block in UpdateQuoteFieldsFromOppQueueable
     **/
    @isTest
    public static void coverCatchBlockUpdateQuoteFieldsFromOppQueueable(){
        try{
            UpdateQuoteFieldsFromOppQueueable.catchException = true;
            UpdateQuoteFieldsFromOppQueueable pd = new UpdateQuoteFieldsFromOppQueueable(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }
}