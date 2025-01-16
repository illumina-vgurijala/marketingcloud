/**
*    @author Gopinath Reddy
*    @date   2018-09-17
*    @description  Test class for ApttusProposalLineItems and ApttusProposals
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Gopinath Reddy                   17-09-2018              Original method 
*       Saswati Prusty                   25-06-2019              Consortium Opportunity to Cover Approval Category as part Of DCP - 25456  
*       Roopal Verma                     25-06-2019              DCP-25456 Inco Terms approval
        Roopal Verma                     07-05-2019              DCP-25340, Promotion Approvals, Moved testIndirectProposalTransRegionAndPaymentTerm to a new class - TestApprovalTransRegionAndPaymentTerm 
        Roopa Verma                      12-08-2019              DCP-28526, Modified Inco Term approval methods with region   
        Roopal Verma                     30-08-2019              DCP-26583, Added condition for End of Sale
*       Prakhar Kumar                    26-11-2019              DCP-30368, Quote Line Item - Create Custom Component to capture      Informatics product fields
        Rahul Bishnoi                    17-01-2020              DCP-32794 - Removed Software_Product_Check__c
        Roopal Verma                     14-05-2020              DCP-29812, Added product specific term for product data
        Roopal Verma                     24 Nov, 2020            DCP-43262 - Error handling for approvals
        Prem Ranjan                      04 May 2022             CodeScan Fix (APEX) Unused Local Variable
        Nishan                           10-Oct-2022             CodeScanFix [Method name should not start with Capital].
*       Adyasha Satapathy                28-Nov-2022             POL-54: Update region references to AMEA and EUR 
*       Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention.
*       Satya Swain                      21-Feb-2022             Codescan fix : Unused Variables 
*       Rajbabu Boopalan                 06-Nov-2023             CMCM-4516CPU Timeout error on submit for approval (ApttusProposalSubmitForApproval) 
*       Gerardo Garcia                   24-Jan-2024             CMCM-5310 Refactor tests.
*    -----------------------------------------------------------------------------------------------------------------------------------
*/


@isTest
public class TestApttusApprovals {
     private static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
     private static final String PRICE_LIST = 'AMR-USD-US-01';
     private static final String DEBUG_NO_OF_SOQL = 'Total Number of SOQL Queries allowed in this apex code context: ';
     private static final String DEBUG_NO_OF_SOQL_SO_FAR = 'Number of Queries used in this apex code so far: ';
     private static final String TEST_PROPOSAL = 'Test Proposal';
     private static final String BOGO_PROMO_SAVINGS = 'BOGO Promo Savings';
     private static final String BOGO_CODE = 'BOGO';
     private static final String SALES_DISCRETIONARY = 'Sales Discretionary';
     private static final String MATERIAL_GROUP_AIP = 'AIP';
     private static final String PRODUCT_AIM = 'AIM';
     private static final String PRODUCT_INFORMATIC = 'INFORMATIC';
     private static final String PRODUCT_AIP = 'AIP';

     
    @testSetup
    static void setupData()
    {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Case',
        Bypass_Triggers_By_Object_2__c = 'Account',
        Bypass_Triggers_By_Object_3__c = 'Contact',
        Bypass_Triggers_By_Object_4__c = 'Opportunity'
        );
        insert apexSettings;  

        User accOwner = TestDataFieldService.createUser('Field Service', true);

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Territory_Region__c ='AMR';
        objAccount.CurrencyIsoCode='USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.Owner = accOwner;
        update objAccount;

        printLimits('objAccount &&' + objAccount.Owner.id);
 
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        objOpportunity.Type = System.Label.OpportunityTypeConsortium;
        update objOpportunity;

        printLimits(null);

        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, TEST_PROPOSAL, objPriceList.id, true, 'Draft', 'None');
        objProposal.Apttus_Proposal__Account__c = objAccount.id;
        insert objProposal;
        System.debug('Apttus_Proposal__Account__c:' + objProposal.Apttus_Proposal__Account__c);

        System.debug('OwnerAccount:' + objProposal.Apttus_Proposal__Account__r.OwnerId + 
            '_' + objProposal.Apttus_Proposal__Account__c);

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Name = PRODUCT_AIM;
        objProduct.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProduct.Product_Specific_Terms__c = 'Test Specific Term'; // Added for 29812
        objProduct.Material_Group_1_Code__c = 'AIM';
        objProduct.Material_Group_1_Code__c = 'MaterialNo';

        Product2 informaticProduct = TestDataMaster.createProduct(false);
        informaticProduct.Name = PRODUCT_INFORMATIC;
        informaticProduct.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;

        Product2 aipProduct = TestDataMaster.createProduct(false);
        aipProduct.Name = PRODUCT_AIP;
        aipProduct.Material_Group_1__c = MATERIAL_GROUP_AIP;
        aipProduct.Material_Number__c = 'MaterialNo1';

        insert new List<Product2> {objProduct, informaticProduct, aipProduct};

        TestDataProposal.getNewCart(objProposal);

        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();

        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        objDiscountApprovalHeirarchy.Approver_Level_1__c = objAccount.Owner.id;
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);
        System.debug('objDiscountApprovalHeirarchy:' + objDiscountApprovalHeirarchy);

        Approval_Hierarchy__c objCustomApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        lstApprovalHierarchy.add(objCustomApprovalHeirarchy);

        Approval_Hierarchy__c objPPMApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Post_Pricing_Message');
        lstApprovalHierarchy.add(objPPMApprovalHeirarchy);
        
        Approval_Hierarchy__c objPromotionApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Promotion');
        lstApprovalHierarchy.add(objPromotionApprovalHeirarchy);

        insert lstApprovalHierarchy;
        // Added by Saswati : Incentives
        TestDataProposal.initIncentives('Test Incentive','Test Incentive Code');

        printLimits('Test Incentive Code');

        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;

        List<Apttus_Config2__ClassificationHierarchy__c> listClassification = new List<Apttus_Config2__ClassificationHierarchy__c>();
        Apttus_Config2__ClassificationHierarchy__c level1= TestDataProposal.initHierarchy(objCategory, 'Level_1', null, null, 0);
        listClassification.add(level1);
        
        Apttus_Config2__ClassificationHierarchy__c level2= TestDataProposal.initHierarchy(objCategory, 'Level_2', level1, level1, 1);
        listClassification.add(level2);
        
        Apttus_Config2__ClassificationHierarchy__c level3= TestDataProposal.initHierarchy(objCategory, 'Level_3', level1, level2, 2);
        listClassification.add(level3);
        
        Apttus_Config2__ClassificationHierarchy__c level4= TestDataProposal.initHierarchy(objCategory, 'Level_4', level1, level3, 3);
        listClassification.add(level4);
        
        insert listClassification;

        printLimits(null);

        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();

        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Discount',null,20, 2000, null, '2',null,objCustomApprovalHeirarchy);
        discountApprovalMatrix.Distribution_Channel__c = null;
        lstMatrix.add(discountApprovalMatrix);
        
        Custom_Approval_Matrix__c promoApprovalMatrix = TestDataProposal.initApprovalMatrixForPromotion('Promotion', 'BOGO', '2',objPromotionApprovalHeirarchy);
        lstMatrix.add(promoApprovalMatrix);
        
        Custom_Approval_Matrix__c initApprovalPostPricingMatrix = TestDataProposal.initApprovalPostPricingMatrix('Post Pricing Message', 'services');
        lstMatrix.add(initApprovalPostPricingMatrix);
        
        Custom_Approval_Matrix__c initApprovalPaymentTermMatrix = TestDataProposal.initApprovalPaymentTermMatrix('Payment Term', 'AMRQueue');
        lstMatrix.add(initApprovalPaymentTermMatrix);

        Custom_Approval_Matrix__c incoTermAMRApprovalMatrix = TestDataProposal.initApprovalIncoTermMatrix('Inco Terms', 'AMR Incoterms Approval Queue','AMR'); //Added for DCP-28526
        lstMatrix.add(incoTermAMRApprovalMatrix);

        Custom_Approval_Matrix__c incoTermNoRegionApprovalMatrix = TestDataProposal.initApprovalIncoTermMatrix('Inco Terms', 'Incoterms Approval Queue',''); // Added for DCP-28526
        lstMatrix.add(incoTermNoRegionApprovalMatrix);

        Custom_Approval_Matrix__c matNumApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Number',null,20, 20000, null, '2',null,objCustomApprovalHeirarchy);
        matNumApprovalMatrix.Distribution_Channel__c = null;
        lstMatrix.add(matNumApprovalMatrix);

        Custom_Approval_Matrix__c matGrpApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Group 1',null,20, 20000, null, '2',null,objCustomApprovalHeirarchy);
        matGrpApprovalMatrix.Distribution_Channel__c = null;
        matGrpApprovalMatrix.Material_Group_1__c = MATERIAL_GROUP_AIP; 
        lstMatrix.add(matGrpApprovalMatrix);

        insert lstMatrix;

        printLimits(null);

        Apttus_Config2__ProductClassification__c prodClassification = TestDataProposal.initProductClassification(level4, objProduct);
        insert prodClassification;        

        printLimits(null);
    }

    /**
    * @Author Gopinath Reddy
    * @description Test method for Approvals
    **/
    @isTest
    static void testCheckForApprovals(){

        // --Creating cart
        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);

        Id cartId = createCart(proposal.Id, lstProduct);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        fillConfigLineItems(lineItemList, false);
        System.debug('lines to update:' + JSON.serializePretty(lineItemList));
        update lineItemList;

        Apttus_Config2.CPQWebService.validateCart(cartId);

        Test.startTest();

        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);

        //Test.stopTest();

        //DCP-32794 - remove Software_Product_Check__c
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c 
            FROM Apttus_Proposal__Proposal_Line_Item__c 
            WHERE Apttus_Proposal__Proposal__c = :proposal.id];
        System.debug('quotation line items:' + JSON.serializePretty(lstPLI));

        Assert.isTrue(lstPLI.size() > 0,'PLI not inserted.');
        //System.assertEquals('Promotion',lstPLI.get(0).Approval_Category__c,'Promotion approvals did not fire.');
        Test.stopTest();
    }

    /**
    * DCP - 25340
    * @Author Saswti Prusty
    * @description Test method for Promotion Approvals
    **/
    @isTest
    static void testPromotionApprovals(){
        
        //Test.startTest();
        
        // --Creating cart
        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);

        Id cartId = createCart(proposal.Id, lstProduct);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id 
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        fillConfigLineItems(lineItemList, false);
        System.debug('lines to update:' + JSON.serializePretty(lineItemList));
        update lineItemList;

        Apttus_Config2.CPQWebService.validateCart(cartId);

        Test.startTest();

        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);

        //Test.stopTest();

        //DCP-32794 - remove Software_Product_Check__c
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c,Promotion_1__c,Promotion_2__c,Promotion_3__c,Promotion_4__c,Promotion_5__c 
            FROM Apttus_Proposal__Proposal_Line_Item__c 
            WHERE Apttus_Proposal__Proposal__c = :proposal.id];

        System.debug('@@@@ Saswati -- Promotion on Proposal Line Item Promotions  =' +  lstPLI[0].Promotion_1__c + lstPLI[0].Promotion_2__c + lstPLI[0].Promotion_3__c + lstPLI[0].Promotion_4__c + lstPLI[0].Promotion_5__c     );
        System.debug('@@@@ Saswati -- Approval Category on Proposal Line Item   =' +  lstPLI[0].Approval_Category__c);

        Assert.isTrue(lstPLI.size() > 0,'PLI not inserted.');
        Test.stopTest();
    }

    /**
    * @Author Govind Dubey
    * @description Test method for Approvals
    **/
    @isTest
    static void testCheckSalesOrgForApprovals(){

        // --Creating cart
        Apttus_Proposal__Proposal__c proposal = [SELECT id,Sold_to_Sales_Organization__c 
            FROM Apttus_Proposal__Proposal__c LIMIT 1];
        proposal.Sold_to_Sales_Organization__c = 'US01';
        update proposal;
        
        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);
        
        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrixForDiscount('CPQ Discount', 
        2000, 20, '2');
        discountApprovalMatrix.Sales_Organization__c = 'US01';
        
        insert discountApprovalMatrix;

        Id cartId = createCart(proposal.Id, lstProduct);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id 
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        fillConfigLineItems(lineItemList, false);
        System.debug('lines to update:' + JSON.serializePretty(lineItemList));
        update lineItemList;

        Test.startTest();
        Apttus_Config2.CPQWebService.validateCart(cartId);

        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);

        Test.stopTest();

        //DCP-32794 - remove Software_Product_Check__c
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c 
            FROM Apttus_Proposal__Proposal_Line_Item__c 
            WHERE Apttus_Proposal__Proposal__c = :proposal.id];
        System.debug('quotation line items:' + JSON.serializePretty(lstPLI));

        Assert.isTrue(lstPLI.size() > 0,'PLI not inserted.');
        //system.assertEquals('Promotion',lstPLI.get(0).Approval_Category__c,'Promotion approvals did not fire.');
    }

    /**
    * @Author Govind Dubey
    * @description Test method for Approvals
    **/
    @isTest
    static void testCheckSalesOrgCountryForApprovals(){
        
        // --Creating cart
        
        Account acc = [SELECT id, BillingCountryCode FROM Account LIMIT 1];
        acc.BillingCountryCode = 'JP';
        update acc;
        
        Apttus_Proposal__Proposal__c proposal = [SELECT id,Sold_to_Sales_Organization__c 
        FROM Apttus_Proposal__Proposal__c LIMIT 1];
        proposal.Sold_to_Sales_Organization__c = 'US01';
        update proposal;
        
        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrixForDiscount('CPQ Discount', 2000, 20, '2');
        discountApprovalMatrix.Sales_Organization__c = 'US01';
        discountApprovalMatrix.Country__c = 'JP';
        insert discountApprovalMatrix;
        
        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);
        
        Id cartId = createCart(proposal.Id, lstProduct);
        
        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id 
        FROM Apttus_Config2__LineItem__c 
        WHERE Apttus_Config2__ConfigurationId__c = :cartId];
        
        fillConfigLineItems(lineItemList, false);
        System.debug('lines to update:' + JSON.serializePretty(lineItemList));
        update lineItemList;
        
        //System.assertNotEquals(0, lineItemList.size(), 'Line items created ');
        
        Test.startTest();
        Apttus_Config2.CPQWebService.validateCart(cartId);
        
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);

        Test.stopTest();

        //DCP-32794 - remove Software_Product_Check__c
        System.debug('*** Before assert');
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c 
            FROM Apttus_Proposal__Proposal_Line_Item__c 
            WHERE Apttus_Proposal__Proposal__c = :proposal.id];
        Assert.isTrue(lstPLI.size() > 0,'PLI not inserted.');
        //system.assertEquals('Promotion',lstPLI.get(0).Approval_Category__c,'Promotion approvals did not fire.');
    }

   ///**
   // * @Author Gopinath Reddy
   // * @description Test method for Trans Region and Payment Term Approvals
   // **/
   @isTest
   static void testProposalTransRegionAndPaymentTerm(){

        Account objAccount1 = [SELECT id, Territory_Region__c,CurrencyIsoCode FROM Account LIMIT 1];

        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        objSoldToSA.Account__c = objAccount1.Id;

        Account_Sales_Area__c objPayerSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Gryffy_HK010100','div1',false);
        objPayerSA.Account__c = objAccount1.Id;
        objPayerSA.Term_Of_Payment__c = '1MEM';

        insert  new List<Account_Sales_Area__c>{objSoldToSA, objPayerSA};

        Account_Relationship__c objSoldToPayer = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                        Related_ERP_Customer_Id__c = 'Gryffy',
                                                        Relationship__c = Label.AccountGroupPayer,
                                                        Account_Sales_Area__c = objSoldToSA.Id);
        insert objSoldToPayer;

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        insert new List<Customer_Master_Data__c> {objCMDUC, objCMDSoldTo, objCMDDist};

        Account ucAccount = TestDataAccount.getAccount('Test UC Account');
        ucAccount.Territory_Region__c ='AMEA'; //POL-54
        ucAccount.CurrencyIsoCode='JPY';
        ucAccount.Is_Updated_By_System__c = true;
        insert ucAccount;

        Apttus_Config2__PriceList__c objPriceList1 = [SELECT Id,Name FROM Apttus_Config2__PriceList__c LIMIT 1];

        printLimits('Inside method : testProposalTransRegionAndPaymentTerm 1');

        Opportunity objOpportunity1 = [Select Id,Ultimate_Consignee__c,Sales_Area_Sold_To__c,Transborder_Flag__c FROM Opportunity LIMIT 1] ;
        objOpportunity1.Ultimate_Consignee__c = ucAccount.Id;
        objOpportunity1.Sales_Area_Sold_To__c = 'Opp_HK010100';
        objOpportunity1.Transborder_Flag__c = true;

        update objOpportunity1;

        printLimits('Inside method : testProposalTransRegionAndPaymentTerm 2');

        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount1.id, objOpportunity1.id, 'Test Proposal', objPriceList1.id, true, 'Draft', 'None');
        objProposal1.Ultimate_Consignee__c = ucAccount.Id;
        objProposal1.Apttus_Proposal__Account__c = objAccount1.Id;
        objProposal1.Apttus_Proposal__Payment_Term__c = 'Test';
        objProposal1.Bill_To__c = objCMDSoldTo.Id;
        objProposal1.Payer__c = objCMDSoldTo.Id;
        insert objProposal1;
        
        printLimits('Inside method : testProposalTransRegionAndPaymentTerm 3');
        
        Test.startTest();
        objProposal1.Apttus_Proposal__Payment_Term__c = 'NT30';
        update objProposal1;

        printLimits('Inside method : testProposalTransRegionAndPaymentTerm 4');
        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposalFinal = [SELECT Id, Approval_Category__c, Transregion_Flag__c, Apttus_Proposal__Account__r.Territory_Region__c, Ultimate_Consignee__r.Territory_Region__c
            FROM Apttus_Proposal__Proposal__c 
            WHERE Id = :objProposal1.Id];

        Assert.isTrue(objProposalFinal.Approval_Category__c.contains('Region'), 'Trans region approvals did not fire.');
        Assert.isTrue(objProposalFinal.Approval_Category__c.contains('Terms_of_Payment'), 'Payment Terms approvals did not fire.');
   }

    /**
    * @Author Gopinath Reddy
    * @description Test method for Indirect Transregion Approval Required
    **/
    @isTest
    static void testIndirectProposalTransRegionAndPaymentTerm(){
        
        Account objAccount1 = [SELECT id, Territory_Region__c,CurrencyIsoCode 
            FROM Account LIMIT 1];

        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        objSoldToSA.Account__c = objAccount1.Id;
        insert objSoldToSA;

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        insert new List<Customer_Master_Data__c> {objCMDUC, objCMDSoldTo, objCMDDist};

        List<Account> lstAccount = new List<Account>();
        Account ucAccount = TestDataAccount.getAccount('Test UC Account');
        ucAccount.Territory_Region__c ='AMEA'; //POL-54
        ucAccount.CurrencyIsoCode='JPY';
        ucAccount.Is_Updated_By_System__c = true;
        lstAccount.add(ucAccount);

        Account distAccount = TestDataAccount.getAccount('Test Distributor Account');
        distAccount.Territory_Region__c ='EUR'; //POL-54
        distAccount.CurrencyIsoCode='EUR';
        distAccount.Is_Updated_By_System__c = true;
        lstAccount.add(distAccount);
        insert lstAccount;

        printLimits('Inside method : testIndirectProposalTransRegionAndPaymentTerm 1');

        Apttus_Config2__PriceList__c objPriceList1 =[SELECT Id,Name FROM Apttus_Config2__PriceList__c LIMIT 1];
        printLimits('Inside method : testIndirectProposalTransRegionAndPaymentTerm 1.2');

        Test.startTest();

        Opportunity objOpportunity1 = [SELECT Id, Name, RecordTypeName__c, Sold_to_Distribution_Channel__c, Transborder_Flag__c, AccountId, Ultimate_Consignee__c, Price_List__c, Sales_Area_Sold_To__c 
            FROM Opportunity LIMIT 1];
        objOpportunity1.RecordTypeName__c = 'Indirect_Field_Services';
        objOpportunity1.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity1.Transborder_Flag__c = true;
        objOpportunity1.AccountId = objAccount1.Id;
        objOpportunity1.Ultimate_Consignee__c =ucAccount.Id;
        objOpportunity1.Price_List__c = objPriceList1.Name;
        objOpportunity1.Sales_Area_Sold_To__c = 'Opp_HK010100';
        update objOpportunity1;

        printLimits('Inside method : testIndirectProposalTransRegionAndPaymentTerm 2');

        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount1.id, objOpportunity1.id, 'Test Proposal', objPriceList1.id, true, 'Draft', 'None');
        objProposal1.Ultimate_Consignee__c = objAccount1.Id;//siva changed
        objProposal1.Apttus_Proposal__Account__c = objAccount1.Id;
        objProposal1.Apttus_Proposal__Payment_Term__c = 'Test';
        objProposal1.Bill_To__c = objCMDSoldTo.Id;
        insert objProposal1;

        printLimits('Inside method : testIndirectProposalTransRegionAndPaymentTerm 3');

        objProposal1.Ultimate_Consignee__c = ucAccount.Id;//Siva added
        objProposal1.Apttus_Proposal__Payment_Term__c = 'NT30';
        objProposal1.Distributor__c =distAccount.Id;
        update objProposal1;

        printLimits('Inside method : testIndirectProposalTransRegionAndPaymentTerm 4');

        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposalFinal = [SELECT Id, Approval_Category__c,Transregion_Flag__c,Apttus_Proposal__Account__r.Territory_Region__c,Ultimate_Consignee__r.Territory_Region__c ,Distributor__r.Territory_Region__c 
            FROM Apttus_Proposal__Proposal__c 
            WHERE Id = :objProposal1.Id];
        Assert.isTrue(objProposalFinal.Approval_Category__c.contains('Region'),'Indirect Trans region approvals did not fire.');
        Assert.isTrue(objProposalFinal.Approval_Category__c.contains('Terms_of_Payment'),'Payment Terms approvals did not fire.');
       
    }
    /**
    * @Author Roopal Verma
    * @description Test method for direct Inco Terms Approvals
    **/

    @isTest
    static void testDirectIncoTermApprovals(){
        Account objAccount1 = TestDataAccount.initAccount(); // Changed for DCP-28526
        objAccount1.Territory_Region__c = 'AMR';
        insert objAccount1;

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo);
        insert objCMDUC;

        Account_Sales_Area__c objUCSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        objUCSA.Account__c = objAccount1.Id;
        objUCSA.Customer_Master_Data__c = objCMDUC.Id;
        objUCSA.Price_List__c = PRICE_LIST;
        objUCSA.Inco_Term_1__c = 'DAP: Delivered At Place';
        insert objUCSA;

        Apttus_Config2__PriceList__c objPriceList1 = TestDataProposal.initPriceList(PRICE_LIST);
        insert objPriceList1;

        Opportunity objOpportunity1 = TestDataOpportunity.getNewOpportunity(objAccount1);
        objOpportunity1.RecordTypeName__c = 'Direct';
        objOpportunity1.AccountId = objAccount1.Id;
        objOpportunity1.Ultimate_Consignee__c =objAccount1.Id;
        objOpportunity1.Price_List__c = objPriceList1.Name;
        objOpportunity1.Sales_Area_Sold_To__c = 'Hogy_HK010100';
        objOpportunity1.Sales_Area_Ultimate_Consignee__c = 'Hogy_HK010100';
        update objOpportunity1;

        printLimits('Inside method : testIncoTermApprovals 1');

        Test.startTest();
        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount1.id, objOpportunity1.id, TEST_PROPOSAL, objPriceList1.id, true, 'Draft', 'None');
        objProposal1.Ultimate_Consignee__c = objAccount1.Id;
        objProposal1.Apttus_Proposal__Account__c = objAccount1.Id; 
        objProposal1.Ship_To__c = objCMDUC.Id;
        insert objProposal1;

        objProposal1.Inco_Term_1__c = 'CFR: Costs and freight';
        update objProposal1;
        printLimits('Inside method : testIncoTermApprovals 2');

        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposalFinal = [SELECT Id, Approval_Category__c 
            FROM Apttus_Proposal__Proposal__c 
            WHERE Id = :objProposal1.Id];
        System.assert(objProposalFinal.Approval_Category__c.contains('Inco_Terms'),'Inco Terms approvals did not fire.');

    }

    /**
    * @Author Roopal Verma
    * @description Test method for Indirect Inco Terms Approvals
    **/

     @isTest
    static void testIndirectIncoTermApprovals(){
        Account objAccount1 = TestDataAccount.initAccount();
        objAccount1.Account_Group__c = 'Distributor';
        objAccount1.Territory_Region__c = 'AMR'; //Added for DCP-28526
        insert objAccount1;

        Customer_Master_Data__c objCMDDist = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo);
        insert objCMDDist;

        Account_Sales_Area__c objDistSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        objDistSA.Account__c = objAccount1.Id;
        objDistSA.Customer_Master_Data__c = objCMDDist.Id;
        objDistSA.Price_List__c = PRICE_LIST;
        objDistSA.Inco_Term_1__c = 'DAP: Delivered At Place';
        insert objDistSA;

        Apttus_Config2__PriceList__c objPriceList1 = TestDataProposal.initPriceList(PRICE_LIST);
        insert objPriceList1;

        Opportunity objOpportunity1 = TestDataOpportunity.initOpportunity(objAccount1,Label.OpportunityRTIndirectStandard);
        insert objOpportunity1;
        objOpportunity1.AccountId = objAccount1.Id;
        objOpportunity1.Ultimate_Consignee__c =objAccount1.Id;
        objOpportunity1.Distributor__c = objAccount1.Id;
        objOpportunity1.Direct_Sale_to_Ultimate_Consignee__c = false;
        objOpportunity1.Price_List__c = objPriceList1.Name;
        objOpportunity1.Sales_Area_Sold_To__c = 'Hogy_HK010100';
        objOpportunity1.Sales_Area_Ultimate_Consignee__c = 'Hogy_HK010100';
        objOpportunity1.Sales_Area_Distributor__c = 'Hogy_HK010100';
        update objOpportunity1;

        printLimits('Inside method : testIndirectIncoTermApprovals 1');

        Test.startTest();
        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount1.id, objOpportunity1.id, TEST_PROPOSAL, objPriceList1.id, true, 'Draft', 'None');
        objProposal1.Ultimate_Consignee__c = objAccount1.Id;
        objProposal1.Apttus_Proposal__Account__c = objAccount1.Id;
        objProposal1.Distributor__c = objAccount1.Id;
        objProposal1.Ship_To__c = objCMDDist.Id;
        insert objProposal1;
     
        objProposal1.Inco_Term_1__c = 'CFR: Costs and freight';
        update objProposal1;

        printLimits('Inside method : testIndirectIncoTermApprovals 2');

        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposalFinal = [Select Id, Approval_Category__c FROM Apttus_Proposal__Proposal__c WHERE Id = :objProposal1.Id];
        System.assert(objProposalFinal.Approval_Category__c.contains('Inco_Terms'),'Inco Terms approvals did not fire.');

    }

    /**
    * @Author Gopinath Reddy
    * @description Test method for No Approval Required
    **/

    @isTest
    static void testNoApprovals(){

        Test.startTest();
        //Creating Account ,Opportunity ,Proposal ,Cart
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Territory_Region__c ='AMR';
        objAccount.CurrencyIsoCode='USD';
        objAccount.Country_Local__c = 'USA';
       
        update objAccount;
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert objPriceList;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, TEST_PROPOSAL, objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;
        System.assertNotEquals(null, objProductConfig.Id != null, 'Cart is created');
       
        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        List<Product2> lstProduct1 = [Select id From Product2 LIMIT 1];
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct1 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct1.ProductId = lstProduct1.get(0).Id;
        selectProduct1.Quantity = 1;
        selectProduct1.SellingTerm = 12;
        selectProduct1.StartDate = Date.today();
        selectProduct1.EndDate = Date.today() + 364;
        selectedProducts.add(selectProduct1); 
        
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        for(Integer idx=0; idx<lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0){
               lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 1;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
            }
        }

        Product2 objProduct2 = TestDataMaster.createProduct(true);
        objProduct2.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        update objProduct2; 

        /**
        * @Author Prakhar Kumar
        * @description Code for DCP-30368 Quote Line Item - Create Custom Component to capture Informatics product fields
        **/    
        Apttus_Config2.CPQWebService.validateCart(objProductConfig.Id);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal,lstProduct1[0]);
        insert proposalLineItem;
        //system.assertEquals(null,proposalLineItem.Approval_Category__c,'Approvals Fired.');
        Test.stopTest();
    }

    @isTest
    static void testSOQL(){ //CodeScan Issue Fix.

        Account objAccount1 = [SELECT id, Territory_Region__c,CurrencyIsoCode FROM Account LIMIT 1];

        Apttus_Config2__PriceList__c objPriceList1 = [SELECT Id,Name FROM Apttus_Config2__PriceList__c LIMIT 1];

        Account ucAccount = TestDataAccount.getAccount('Test UC Account');
        ucAccount.Territory_Region__c ='AMEA'; //POL-54
        ucAccount.CurrencyIsoCode='JPY';
        ucAccount.Is_Updated_By_System__c = true;

        Account distAccount = TestDataAccount.getAccount('Test Distributor Account');
        distAccount.Territory_Region__c ='EUR'; //POL-54
        distAccount.CurrencyIsoCode='EUR';
        distAccount.Is_Updated_By_System__c = true;
        insert new List<Account> {ucAccount, distAccount};

        Test.startTest();
        
        Opportunity objOpportunity1 = TestDataOpportunity.getNewOpportunity(objAccount1); 
        objOpportunity1.RecordTypeName__c = 'Indirect_Field_Services';
        objOpportunity1.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity1.Transborder_Flag__c = true;
        objOpportunity1.AccountId = objAccount1.Id;
        objOpportunity1.Ultimate_Consignee__c = ucAccount.Id;
        objOpportunity1.Price_List__c = objPriceList1.Name;
        objOpportunity1.Sales_Area_Sold_To__c = 'Opp_HK010100';
        update objOpportunity1;

        printLimits('Inside method : TestSOQL');

        Test.stopTest();

        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 'This will verify number of executed queries are less then the actual available');
    }
	@isTest
    static void testbeforeDelete(){//DGP-491
        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal,lstProduct[0]);
        insert proposalLineItem;
        Test.startTest();
        Delete proposalLineItem;
        //Create Proposal line Items
        List <Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItems1 = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = TestDataProposal.initProposalLineItem(proposal,lstProduct[0]);
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(proposal,lstProduct[1]);
        listProposalLineItems1.add(proposalLineItem1);
        listProposalLineItems1.add(proposalLineItem2);
        insert listProposalLineItems1;

        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = new list <Apttus_Proposal__Proposal_Line_Item__c>([SELECT Id FROM Apttus_Proposal__Proposal_Line_Item__c limit 10]);
       
        Delete proposalLineItem1;
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem3 = TestDataProposal.initProposalLineItem(proposal,lstProduct[0]);
        system.debug(proposalLineItem3);
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem4 = TestDataProposal.initProposalLineItem(proposal,lstProduct[1]);
        system.debug(proposalLineItem4);
        Test.stopTest();
        Assert.isTrue(lstPLI.size() > 0, 'Two Price List Item are needed to be re-approved');
    }

    @isTest
    static void testAfterInsert(){
        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = getProducts(PRODUCT_AIM, PRODUCT_INFORMATIC);
        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal,lstProduct[0]);
        insert proposalLineItem;
        Delete proposalLineItem;
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 =TestDataProposal.initProposalLineItem(proposal,lstProduct[0]);
        insert proposalLineItem1;
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = new List <Apttus_Proposal__Proposal_Line_Item__c>([SELECT Id FROM Apttus_Proposal__Proposal_Line_Item__c limit 10]);
        
        Test.stopTest();
        Assert.isTrue(lstPLI.size()>0,'No Price List Item needs re-approval');
    }
    //<----------DGP-491 End----------->
    @isTest
    static void testCPQApprovals(){//CodeScan Issue Fix.
        User objRepUser = TestDataUser.findUserInProfile('Sales User');

        Account acc = [SELECT Id, OwnerId FROM Account LIMIT 1];
        acc.OwnerId = objRepUser.Id;
        update acc;

        Approval_Hierarchy__c objCustomApprovalHeirarchy = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Custom_Hierarchy'];

        Approval_Hierarchy__c objSalesApprovalHeirarchy = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Sales_Hierarchy'];
        objSalesApprovalHeirarchy.Approver_Level_1__c = objRepUser.id;
        update objSalesApprovalHeirarchy;

        List<Product2> products = getProducts(PRODUCT_AIM, PRODUCT_AIP);

        Custom_Approval_Matrix__c matNumApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Number',null,20, 20000, null, '2',null,objCustomApprovalHeirarchy);
        matNumApprovalMatrix.Distribution_Channel__c = null;

        Custom_Approval_Matrix__c matGrpApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Group 1',null,20, 20000, null, '2',null,objCustomApprovalHeirarchy);
        matGrpApprovalMatrix.Distribution_Channel__c = null;
        matGrpApprovalMatrix.Material_Group_1__c = MATERIAL_GROUP_AIP;

        insert new List<Custom_Approval_Matrix__c> {matNumApprovalMatrix, matGrpApprovalMatrix};

        Custom_Approval_Matrix_Products__c campRecord = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = matNumApprovalMatrix.id,
            Product__c = products.get(0).id
        );
        Custom_Approval_Matrix_Products__c campRecord1 = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = matNumApprovalMatrix.id,
            Product__c = products.get(1).id
        );

        insert new List<Custom_Approval_Matrix_Products__c> {campRecord, campRecord1};

        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        Id cartId = createCart(proposal.Id, products);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id 
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        fillConfigLineItems(lineItemList, false);
        System.debug('lines to update:' + JSON.serializePretty(lineItemList));
        update lineItemList;

        Apttus_Config2.CPQWebService.validateCart(cartId);

        Test.startTest();

        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
        //Test.stopTest();
        
        Assert.areNotEqual(0, lineItemList.size(), 'Line items should be created');
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :proposal.id];
        System.debug('lstPLI &&'+ lstPLI);
        Assert.isTrue(lstPLI.size() > 0, 'PLI not inserted.');
        Test.stopTest();
    }

    @isTest
    static void testRODiscountApproval(){
        User objRepUser = TestDataUser.findUserInProfile('Sales User');

        Account acc = [SELECT Id, OwnerId FROM Account LIMIT 1];
        acc.OwnerId = objRepUser.Id;
        update acc;

        Approval_Hierarchy__c objSalesApprovalHeirarchy = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Sales_Hierarchy'];
        objSalesApprovalHeirarchy.Approver_Level_1__c = objRepUser.id;
        update objSalesApprovalHeirarchy;

        Product2 product = [SELECT id FROM Product2 WHERE Name = :PRODUCT_AIM LIMIT 1];

        Apttus_Proposal__Proposal__c proposal = [SELECT id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        Id cartId = createCart(proposal.Id, new List<Product2> {product, product});

        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id 
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        for(Integer idx=0; idx<lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0){
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                 lineitem.Apttus_Config2__ListPrice__c = 3000;
                 lineitem.Apttus_Config2__StartDate__c = null;
                 lineitem.Apttus_Config2__EndDate__c = null;
                 lineitem.Apttus_Config2__Quantity__c = 6;
                 lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                 lineitem.Applied_Discount_Percentage__c = 5 ;
                 lineitem.Applied_Discount_Amount__c = 3600 ;
                 lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
             }
        }
        Test.startTest();
        update lineItemList;

        Apttus_Config2.CPQWebService.validateCart(cartId);
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = cartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
        Test.stopTest(); 

        List<Apttus_Proposal__Proposal_Line_Item__c> lineItems = [SELECT Id,Approval_Category__c 
            FROM Apttus_Proposal__Proposal_Line_Item__c 
            WHERE Apttus_Proposal__Proposal__c = :proposal.id];

        System.debug('lineItems:' + JSON.serializePretty(lineItems));

        Assert.isNotNull(lineItems.get(0).Approval_Category__c, 'Approvals did not fire');
    }

    private static void fillConfigLineItems(List<Apttus_Config2__LineItem__c> lineItemList, 
        Boolean hasIncentives) 
    {
        Apttus_Config2__Incentive__c objIncentive = !hasIncentives ? null 
            : [SELECT id FROM Apttus_Config2__Incentive__c LIMIT 1];

        for(Integer idx=0; idx<lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);

            lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
            lineitem.Apttus_Config2__ListPrice__c = 3000;
            lineitem.Apttus_Config2__StartDate__c = null;
            lineitem.Apttus_Config2__EndDate__c = null;
            lineitem.Apttus_Config2__Quantity__c = 6;
            lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
            lineitem.Applied_Discount_Percentage__c = 5 ;
            lineitem.Applied_Discount_Amount__c = 3600;

            lineitem.Promotion_1__c = objIncentive?.id;
            lineitem.Promotion_2__c = objIncentive?.id;
            lineitem.Promotion_3__c = objIncentive?.id;
            lineitem.Promotion_4__c = objIncentive?.id;
            lineitem.Promotion_5__c = objIncentive?.id; 

            if(idx == 0){
                lineitem.Applied_Discount_Details__c = BOGO_PROMO_SAVINGS;
                lineitem.Promotion_Code__c = BOGO_CODE;
                lineitem.Promotion_Discount__c = 10;
            }

            if(idx == 1){
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
            }
        }
    }

    private static Id createCart(Id proposalId, List<Product2> products) {
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposalId;
        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        for(Product2 product : products) {
            Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = getProductDO(product.Id, 365);
            selectedProducts.add(selectProduct);
        }

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.CartId;
        addMultiProductRequest.SelectedProducts = selectedProducts;
		system.debug('@@@testId'+ addMultiProductRequest.CartId);
        system.debug('@@@testId1'+ selectedProducts);
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        return objProductConfig.CartId;
    }

    private static Apttus_CPQApi.CPQ.SelectedProductDO getProductDO(Id productId, Integer endDate) {
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = productId;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + endDate;

        return selectProduct;
    }

    private static void printLimits(String message) {
        if(String.isNotBlank(message)) {
            System.debug(message);
        }
        System.debug(DEBUG_NO_OF_SOQL + Limits.getLimitQueries());
        System.debug(DEBUG_NO_OF_SOQL_SO_FAR + Limits.getQueries());
    }

    private static List<Product2> getProducts(String productName1, String productName2) {
        List<String> values = new List<String> {productName1, productName2};
        return [SELECT id FROM Product2 WHERE Name IN :values];
    }  
}