/*
 * Test class for ApttusProductConfigItems Class
      Developer                  Date              Description
*        
*    ------------------------------------------------------------------------------------
*      Pravallika, Gundreddy           28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*      Sai Pasumarthy                  22-Nov-2024             CMCM-11328 TI WF to apex
*      Gerardo Garcia                  02-Dec-2024             Fix 101 SOQL. Add test start/end block.
*      Sai Pasumarthy                  11-Dec-2024             CMCM-11053: TI- Line Item : Update Manual List Price
 */
@isTest
private class TestApttusProductConfigItems
{

    @testSetup
    static void setupData()
    {
        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = myId;
        insert csapex; //CMCM-11053
        
        Account a = TestDataAccount.getNewAccount();
        Account a1 = TestDataAccount.getCustomerAccount(); 
        insert a1;

        TestDataPerson.getNewContact(a.Id);
        TestDataPerson.getNewContact(a1.Id);

        Apttus_Config2__PriceList__c pl = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert pl;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = a1.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c='Test TXDR';
        acc1SalesArea.Distribution_Channel__c='01';
        
        insert acc1SalesArea;

        CLM_ProfileValidation__c setting = CLM_ProfileValidation__c.getInstance(UserInfo.getUserId());
        if(setting.Special_Programs__c == false)
        {
            setting.Special_Programs__c = true;
        }
        upsert setting;

        Apttus__APTS_Agreement__c agr = TestDataAgreement.initAgreements('testAgrSP', a1.Id);
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('Special_Programs').getRecordTypeId();
        agr.RecordTypeId = recTypeId;
        agr.Apttus__Subtype__c = 'Reagent Rental';
        agr.Apttus__Contract_End_Date__c = system.today() + 30;
        agr.Discount_Justification__c = 'DiscountJustified';
        agr.Sales_Org__c = 'HK01';
        insert agr;

        Opportunity o = TestDataOpportunity.initOpportunity(a);
        o.Ultimate_Consignee__c = a.Id;
        o.Sold_to_Distribution_Channel__c = 'Direct';
        o.Price_List__c = pl.Name;
        insert o;
        
        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'TestConsortiaBeadchip';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium; //CMCM-11053

        Opportunity o1 = TestDataOpportunity.initOpportunity(a1, 'Re_Order');
        o1.Ultimate_Consignee__c = a1.Id;
        o1.Sold_to_Distribution_Channel__c = '01';
        o1.Price_List__c = pl.Name;
        o1.Product_Interest__c = 'Consumables';
        o1.Consortium__c = consortium.Id;
        o1.Type = System.Label.OpportunityTypeConsortium;
        insert o1;

        TestDataProposal.getNewProposal(a1.Id, o1.Id, 'Test Proposal', pl.Id, true, 'Draft', 'None');
        TestDataProposal.getNewProposal(a1.Id, o1.Id, 'Test Proposal RecType Change', pl.Id, true, 'Draft', 'None');

        Product2 p1 = TestDataMaster.initProduct('Cookie');
        Product2 p2 = TestDataMaster.initProduct('Brownie');
        Product2 p3 = TestDataMaster.initProduct('Cake');
        Product2 p4 = TestDataMaster.initProduct('Pie');
        Product2 p5 = TestDataMaster.initProduct('Broccoli');
        insert new List<Product2> { p1, p2, p3, p4, p5 };
    }

    /*
     * Test Scenario to check one line
     */
    @isTest
    public static void resetGTCheckOneLine()
    {
        Apttus_Proposal__Proposal__c q = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 LIMIT 1];

        Apttus_Config2__ProductConfiguration__c cart = TestDataProposal.initCart(q);
        cart.Is_SAP_Pricing_Completed__c = true;
        insert cart;

        Apttus_Config2__LineItem__c cartLine = TestDataProposal.initLineItem(cart.Id, p2.Id, 1, 0);
        cartLine.Apttus_Config2__CopySourceNumber__c = 7;
        cartLine.Global_Trade_Block__c = true;

        Test.startTest();
            insert cartLine;
        Apttus_Config2__ProductConfiguration__c modifiedCart = [SELECT Id, Is_SAP_Pricing_Completed__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cart.Id];
        System.assert(!modifiedCart.Is_SAP_Pricing_Completed__c, 'Is SAP Pricing flag was not reset');

        Apttus_Config2__LineItem__c modifiedLine = [SELECT Id, Apttus_Config2__CopySourceNumber__c, Global_Trade_Block__c FROM Apttus_Config2__LineItem__c WHERE Id = :cartLine.Id];
        Test.stopTest();
        System.assert(!modifiedLine.Global_Trade_Block__c, 'Global Trade Block flag was not reset');
        System.assertEquals(null, modifiedLine.Apttus_Config2__CopySourceNumber__c, 'Source number is not null');
        system.debug('Global Trade Block Flag'+!modifiedLine.Global_Trade_Block__c);
    }

    /*
     * Test scenario to check twenty lines
     */
    @isTest
    public static void resetGTCheckTwentyLines()
    {
        Integer lineCount = 20;

        Apttus_Proposal__Proposal__c q = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 5];

        Apttus_Config2__ProductConfiguration__c cart = TestDataProposal.initCart(q);
        cart.Is_SAP_Pricing_Completed__c = true;
        insert cart;

        List<Apttus_Config2__LineItem__c> cartLines = new List<Apttus_Config2__LineItem__c>();
        Integer productIndex = 0;
        for (Integer i = 0; i < lineCount; i++)
        {
            if (productIndex >= products.size()) {
                productIndex = 0;
            }

            Apttus_Config2__LineItem__c cartLine = TestDataProposal.initLineItem(cart.Id, products.get(productIndex).Id, 1, 0);
            productIndex = productIndex + 1;

            cartLine.Apttus_Config2__CopySourceNumber__c = 7;
            cartLine.Global_Trade_Block__c = true;
            cartLines.add(cartLine);
        }

        Test.startTest();
            insert cartLines;
        

        Apttus_Config2__ProductConfiguration__c modifiedCart = [SELECT Id, Is_SAP_Pricing_Completed__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cart.Id LIMIT 1];
        System.assert(!modifiedCart.Is_SAP_Pricing_Completed__c, 'Is SAP Pricing flag was not reset');

        List<Apttus_Config2__LineItem__c> modifiedLines = [SELECT Id, Apttus_Config2__CopySourceNumber__c, Global_Trade_Block__c FROM Apttus_Config2__LineItem__c LIMIT 20];
        Test.stopTest();
        for (Apttus_Config2__LineItem__c modifiedLine : modifiedLines)
        {
            System.assert(!modifiedLine.Global_Trade_Block__c, 'Global Trade Block flag was not reset');
            System.assertEquals(null, modifiedLine.Apttus_Config2__CopySourceNumber__c, 'Copy Source Number is null');
        }
    }
    
    /*
    @Author : Vijay Masne
    @Story : TI-11056
    @Description : TI- Line Item:Update Erp Number
    @Paramters : List of Line Item
    */
    @isTest
    public static void testUpdateERPNumber() {
    Feature.setMockFeatureFlag('WF_FF_APTS_Set_ERPNo', true);
    Test.startTest();
    Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
    Product2 product = [SELECT Id FROM Product2 LIMIT 1];

    Apttus_Config2__ProductConfiguration__c cart = TestDataProposal.initCart(proposal);
    insert cart;

    Apttus_Config2__LineItem__c lineItem = TestDataProposal.initLineItem(cart.Id, product.Id, 1, 0);
    lineItem.ERP_Line_Number__c = '12345';
    insert lineItem;

    lineItem.ERP_Line_Number__c = '67890';

    Apttus_Config2__LineItem__c clonedLineItem = lineItem.clone();
    clonedLineItem.Apttus_Config2__CopySourceNumber__c = 100; // Simulate clone with CopySourceNumber
    clonedLineItem.ERP_Line_Number__c = '56789';

    Assert.areEqual(true, clonedLineItem.isClone(), 'The cloned line item should be recognized as a clone before saving.');

    insert clonedLineItem;
    Test.stopTest();
    Assert.areEqual(true, clonedLineItem.isClone(), 'The cloned line item should still be recognized as a clone after saving.');

    Apttus_Config2__LineItem__c updatedLineItemWithFlag = [
        SELECT Id, ERP_Line_Number__c 
        FROM Apttus_Config2__LineItem__c 
        WHERE Id = :lineItem.Id
    ];
    Assert.isTrue(updatedLineItemWithFlag.ERP_Line_Number__c == '' || updatedLineItemWithFlag.ERP_Line_Number__c == null,
        'ERP_Line_Number__c should be set to blank or null for non-clone records when feature flag is enabled.');

        Apttus_Config2__LineItem__c updatedClonedLineItem = [
        SELECT Id, ERP_Line_Number__c 
        FROM Apttus_Config2__LineItem__c 
        WHERE Id = :clonedLineItem.Id
    ];
    Assert.isTrue(updatedClonedLineItem.ERP_Line_Number__c == '' || updatedClonedLineItem.ERP_Line_Number__c == null,
        'ERP_Line_Number__c should be set to blank or null for cloned records when feature flag is enabled.');
    } 

    /*
    @Author : Sai Pasumarthy
    @Story : CMCM-11328
    @Description : TI- Quotation: Lock Record Based On Quote Stage
    @Paramters : 
    */
    @isTest
    public static void testQuoteRecTypeChange() {
        Test.startTest();
        Feature.setMockFeatureFlag('WF_Quotation_Lock_Record_Stage', true);
        Apttus_Proposal__Proposal__c proposal = [SELECT Id, Apttus_Proposal__Approval_Stage__c, RecordType.DeveloperName FROM Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal RecType Change' LIMIT 1];
        proposal.Apttus_Proposal__Approval_Stage__c = 'Denied';
        update proposal;
        Test.stopTest();

        Apttus_Proposal__Proposal__c proposal1 = [SELECT Id, Apttus_Proposal__Approval_Stage__c, RecordType.DeveloperName FROM Apttus_Proposal__Proposal__c where Id =: proposal.Id];
        Assert.areEqual('Proposal_Read_Only',proposal1.RecordType.DeveloperName, 'Record Type Changed to Proposal_Read_Only');
    }
    
    /*
    @Author : Sai Pasumarthy
    @Story : CMCM-11053
    @Description : TI- Quotation: Lock Record Based On Quote Stage
    @Paramters : 
    */
    @isTest
    public static void testUpdateManualListPrice()
    {
        Feature.setMockFeatureFlag('WF_FF_Update_Manual_List_Price', true);
        Test.startTest();
        Apttus_Proposal__Proposal__c q = [SELECT Id, Apttus_Proposal__Approval_Stage__c, RecordType.DeveloperName FROM Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal RecType Change' LIMIT 1];
        Product2 objProduct1 = TestDataMaster.createProduct(false);
        objProduct1.Material_Group_1__c = null;
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Group_1__c = null;
        List<Product2> products = new List<Product2>{objProduct1,objProduct2};
        insert products;        
        Id cartId = TestDataApprovals.createCartAndLineItems(q.Id, products);        
        Consortium__c con = [SELECT Id, Beadchip_Part_Number__c FROM Consortium__c LIMIT 1];
        Apttus_Config2__LineItem__c lineitem = [SELECT Id FROM Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :cartId LIMIT 1];
        {
            lineitem.Shipping_In_Close_Quarter__c = TestDataApprovals.INTEGER_SHIPPING_IN_CLOSE_QUARTER;
            lineitem.Apttus_Config2__ListPrice__c = 3000;
            lineitem.Apttus_Config2__StartDate__c = null;
            lineitem.Apttus_Config2__EndDate__c = null;
            lineitem.Apttus_Config2__Quantity__c = 6;
            lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
            lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
            update lineitem;
        }
        Apttus_Config2__LineItem__c modifiedLine = [SELECT 
        Id, List_Price__c, Apttus_Config2__ListPrice__c,Beadchip_Part_Number__c
        FROM Apttus_Config2__LineItem__c WHERE Id = :lineitem.Id];
        Test.stopTest();
        Assert.areEqual(modifiedLine.Apttus_Config2__ListPrice__c, modifiedLine.List_Price__c, 'List Price should not be null');
        Assert.areEqual(con.Beadchip_Part_Number__c, modifiedLine.Beadchip_Part_Number__c, 'Beadchip Part Number should not be null');
    }
   
/*
    @Author : Vijay Masne
    @Story : TI-11056
    @Description : TI- Line Item:Update Erp Number
    @Paramters : List of Line Item
    */
    @isTest
    public static void testUpdateERPNumber2() {
     
        Test.startTest();
        Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Feature.setMockFeatureFlag('WF_FF_APTS_Set_ERPNo', false);

        Apttus_Config2__ProductConfiguration__c cart = TestDataProposal.initCart(proposal);
        insert cart;
 
        Apttus_Config2__LineItem__c lineItem = TestDataProposal.initLineItem(cart.Id, product.Id, 1, 0);
        lineItem.ERP_Line_Number__c = '12345';
        insert lineItem;
        Test.stopTest();

        Apttus_Config2__LineItem__c updatedLineItemWithFlag = [
            SELECT Id, ERP_Line_Number__c
            FROM Apttus_Config2__LineItem__c
            WHERE Id = :lineItem.Id
        ];

        Assert.areEqual(updatedLineItemWithFlag.ERP_Line_Number__c, '12345', 'ERP number is not null');
  }
}