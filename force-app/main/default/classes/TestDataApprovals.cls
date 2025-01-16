/**
*    @author Satya Swain
*    @date   2021-08-19
*    @description    DCP-48131: Factory class for Approvals
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-19           Initial Version
*         Bharath Varma               2021-12-07           Added data for CLM Approvals
*         Pravallika, Gundreddy       28-nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestDataApprovals {
    public static Map<String, Schema.RecordTypeInfo> nameToRecordType;
    public static final String APPROVAL_HIERARCHY_TYPE_ALL = 'Record Owner;Custom';
    public static final String MATERIAL_GROUP_AIP = 'AIP';
    public static final String RECORD_TYPE_CPQ_MATERIAL_NUMBER = 'CPQ Material Number';
    public static final String RECORD_TYPE_CPQ_MATERIAL_GROUP_1 = 'CPQ Material Group 1';
    public static final String RECORD_TYPE_CPQ_DISCOUNT = 'CPQ Discount';
    public static final String RECORD_TYPE_PROMOTION = 'Promotion';
    public static final String PRICE_LIST = 'AMR-USD-US-01';
    public static final String TEST_PROPOSAL = 'Test Proposal';
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 1;
    public static final String PROMOTION_NAME_BOGO = 'BOGO';
    public static final string AMEA_USD = '01-AMEA-USD'; //POL-57
    public static final string SGD_USD = '06-SGD-USD';

    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string SV_111_3001 = 'SV-111-3001';
    public static FINAL string PERDISCOUNT = '% Discount';
    public static FINAL string MATERIALGROUP = 'Material Group 1';
    public static FINAL string PRICEGROUP = 'Price Group - Material';
    public static FINAL string FIXEDDISCOUNT = 'Fixed Price';
    public static FINAL string DEBUG_SOQLCHECK = 'Total Number of SOQL Queries allowed in this apex code context: ';
    public static FINAL string DEBUG_SOQLIMIT = 'Number of Queries used in this apex code so far:';
    public static FINAL string DISCAMT = 'Discount Amount';
    public static FINAL string MATGRPAIP = 'AIP';
    //Code scan fixes
    public static FINAL string TXDR = 'TXDR';


    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method creates all support data required in Approvals. This method is to be called in all approvals test classes in setup method
    *  @PARAM :         none
    *  @RETURN:         void
    */
    public static void getSupportDataForApprovals() {
        
       // TestDataOpportunity.getStandardPriceBook();

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert priceList;

        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        objAccount.CurrencyIsoCode = 'USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.OwnerId = UserInfo.getUserId();
        insert objAccount;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = priceList.Name;
        objOpportunity.Type = System.Label.OpportunityTypeConsortium;
        insert objOpportunity;

        Apttus_Proposal__Proposal__c quote = TestDataProposal.initProposal(objAccount.Id, objOpportunity.Id, TEST_PROPOSAL, priceList.Id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        quote.Apttus_Proposal__Account__c = objAccount.Id;
        insert quote;

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProduct.Product_Specific_Terms__c = 'Test Specific Term'; // Added for 29812
        objProduct.Material_Group_1_Code__c = MATERIAL_GROUP_AIP;
        insert objProduct;

        TestDataProposal.initPriceListItem(objProduct, priceList);
        
        List<Approval_Hierarchy__c> lstHierarchy = initApprovalHierarchies(objAccount.OwnerId, false);
        insert lstHierarchy;

        Id customHierarchyId = null;
        for (Approval_Hierarchy__c hierarchy : lstHierarchy) {
            if (hierarchy.Approval_Hierarchy_Type__c == 'CPQ_Custom_Hierarchy') {
                customHierarchyId = hierarchy.Id;
                break;
            }
        }

        List<Custom_Approval_Matrix__c> lstMatrix = fetchCustomApprovalMatrices(customHierarchyId);
        insert lstMatrix;
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method creates all types of Custom Approval Matrix records
    *  @PARAM :         none
    *  @RETURN:         void
    */
    public static List<Custom_Approval_Matrix__c> fetchCustomApprovalMatrices(Id approvalHierarchyId) {
        
        List<Custom_Approval_Matrix__c> allMatrices = new List<Custom_Approval_Matrix__c>();

        Custom_Approval_Matrix__c materialNumberMatrixWithoutMinDiscount = initApprovalMatrix(RECORD_TYPE_CPQ_MATERIAL_NUMBER,Label.QuoteRegionAMR,null,null,approvalHierarchyId);
        
        Custom_Approval_Matrix__c materialNumberMatrixWithMinDiscount = initApprovalMatrix(RECORD_TYPE_CPQ_MATERIAL_NUMBER,Label.QuoteRegionAMR,null,null,approvalHierarchyId);
        materialNumberMatrixWithMinDiscount.Min_Discount__c = 2;
        materialNumberMatrixWithMinDiscount.Min_Discount_Amount__c = 100;

        Custom_Approval_Matrix__c materialGroupMatrix = initMaterialGroupMatrix(approvalHierarchyId, MATERIAL_GROUP_AIP);
        Custom_Approval_Matrix__c discountMatrix = initApprovalMatrix(RECORD_TYPE_CPQ_DISCOUNT, Label.QuoteRegionAMR,null,null,approvalHierarchyId);
        
        //TODO: Add promotion matrix
        Custom_Approval_Matrix__c promotionMatrix = initPromotionMatrix(PROMOTION_NAME_BOGO, approvalHierarchyId);

        allMatrices.add(materialNumberMatrixWithoutMinDiscount);
        allMatrices.add(materialNumberMatrixWithMinDiscount);
        allMatrices.add(materialGroupMatrix);
        allMatrices.add(discountMatrix);
        allMatrices.add(promotionMatrix);
        //NOTE: in case of future matrices creation please add all matrices here

        return allMatrices;
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method returns Custom Approval Matrix record
    *  @PARAM :         String recordTypeName, String strRegion, String strCurrency, String strDistributionChannel,Id hierarchyId
    *  @RETURN:         Custom_Approval_Matrix__c type object
    */
    public static Custom_Approval_Matrix__c initApprovalMatrix(String recordTypeName, String strRegion, String strCurrency, String strDistributionChannel, Id hierarchyId) {

        Id recordTypeId = getMatrixNameToRecordType().get(recordTypeName).getRecordTypeId();
        return new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recordTypeId,
            Region__c = strRegion,
            Currency__c = strCurrency,
            Distribution_Channel__c = strDistributionChannel,
            Discount_Level_1__c = 5,
            Discount_Amount_Level_1__c = 5000,
            Discount_Level_2__c=10,
            Discount_Amount_Level_2__c = 10000,
            Discount_Level_3__c=15,
            Discount_Amount_Level_3__c = 15000,
            Discount_Level_4__c=20,
            Discount_Amount_Level_4__c = 20000,
            Discount_Level_5__c=25,
            Discount_Amount_Level_5__c = 25000,
            Discount_Level_6__c=30,
            Discount_Amount_Level_6__c = 30000,
            Approval_Hierarchy__c = hierarchyId,
            Approval_Hierarchy_Type__c = APPROVAL_HIERARCHY_TYPE_ALL
        );        
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method returns Material Group Custom Approval Matrix record
    *  @PARAM :         Id approvalHierarchyId, String strMaterialGroup
    *  @RETURN:         Custom_Approval_Matrix__c type object
    */
    public static Custom_Approval_Matrix__c initMaterialGroupMatrix(Id approvalHierarchyId, String strMaterialGroup) {
        
        Custom_Approval_Matrix__c materialGroupMatrix = initApprovalMatrix(RECORD_TYPE_CPQ_MATERIAL_GROUP_1,Label.QuoteRegionAMR,null,null,approvalHierarchyId);
        materialGroupMatrix.Material_Group_1__c = strMaterialGroup;
        return materialGroupMatrix;
    
    }

    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method returns Promotion Custom Approval Matrix record
    *  @PARAM :         String strPromoCode,Id approvalHierarchyId
    *  @RETURN:         Custom_Approval_Matrix__c type object
    */
    public static Custom_Approval_Matrix__c initPromotionMatrix(String strPromoCode,Id approvalHierarchyId) {
        return initApprovalMatrix(RECORD_TYPE_PROMOTION,null,null,null,approvalHierarchyId);
    }

    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method returns various approval hierarchy records
    *  @PARAM :         Id ownerIdForLevel1
    *  @RETURN:         List<Approval_Hierarchy__c>
    */
    public static List<Approval_Hierarchy__c> initApprovalHierarchies(Id ownerIdForLevel1, Boolean isAgreement) {
        
        List<Approval_Hierarchy__c> allHierarchies = new List<Approval_Hierarchy__c>();

        if(isAgreement)
        {
            Approval_Hierarchy__c objRecordOwnerApprovalHierarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Sales_Hierarchy', ownerIdForLevel1);
            allHierarchies.add(objRecordOwnerApprovalHierarchy);
            Approval_Hierarchy__c objCustomApprovalHierarchy = TestDataAgreement.initApprovalHierarchy('CLM_Custom_Hierarchy');
            allHierarchies.add(objCustomApprovalHierarchy);

            return allHierarchies;
        }

        Approval_Hierarchy__c recordOwnerHierarchy = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        recordOwnerHierarchy.Approver_Level_1__c = ownerIdForLevel1;
        Approval_Hierarchy__c customFlowHierarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        
        allHierarchies.add(recordOwnerHierarchy);
        allHierarchies.add(customFlowHierarchy);

        return allHierarchies;

    }

    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method creates a cart and line items based on products supplied
    *  @PARAM :         Id quoteId, List<Product2> products
    *  @RETURN:         void
    */
    public static Id createCartAndLineItems(Id quoteId, List<Product2> products) {
        
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = quoteId;
        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        for(Product2 objProduct : products) {
            Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
            selectProduct.ProductId = objProduct.Id;
            selectProduct.Quantity = 1;
            selectProduct.SellingTerm = 12;
            selectProduct.StartDate = Date.today();
            selectProduct.EndDate = Date.today() + 365;
            selectedProducts.add(selectProduct);
        }

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.CartId;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        //Apttus_CPQApi.CPQ.AddMultiProductResponseDO addMultiProductResponse = Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        
        return objProductConfig.CartId;
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method validates the cart 
    *  @PARAM :         Id cartId
    *  @RETURN:         void
    */
    public static void validateCart(Id cartId) {
        Apttus_Config2.CPQWebService.validateCart(cartId);
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method finalizes the cart 
    *  @PARAM :         Id cartId
    *  @RETURN:         void
    */
    public static void finalizeCart(Id cartId) {
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        requestFinalize.CartId = cartId;
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method returns a static map of Matrix Record Type Name To Record Type Info
    *  @PARAM :         none
    *  @RETURN:         Map<String, Schema.RecordTypeInfo>
    */
    public static Map<String, Schema.RecordTypeInfo> getMatrixNameToRecordType() {
        if (nameToRecordType == null) { 
            nameToRecordType = Custom_Approval_Matrix__c.sObjectType.getDescribe().getRecordTypeInfosByName(); 
        } 
        return nameToRecordType;
    }

    /*
    *  @AUTHOR:         Bharath Varma
    *  @DESCRIPTION:    This method creates all support data required in Agreement Approvals. This method is to be called in all approvals test classes in setup method
    *  @PARAM :         none
    *  @RETURN:         void
    */
    public static void getSupportDataForAgreementApprovals() {

        Account acc = TestDataAccount.initAccount();
        acc.Country_Local__c ='Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';

        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';

        insert new List<Account> { acc, acc2 };

        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);

        insert new List<Contact> { con, con2 }; 
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';

        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = '11234187';

        insert new List<Product2> { product };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;

        List<Account_Sales_Area__c> lstAccountSalesArea = initAccountSalesArea(new List<Id>{acc.Id, acc2.Id});
        insert lstAccountSalesArea;

        System.debug(DEBUG_SOQLCHECK +' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc2.id);
        oAgreement2.RecordTypeId = recTypeId;

        insert new List<Apttus__APTS_Agreement__c>{oAgreement2};

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());
        
        List<Approval_Hierarchy__c> lstApprovalHierarchy = initApprovalHierarchies(acc.OwnerId, true);
        insert lstApprovalHierarchy;


        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        initPriceListAndPriceListItem(new List<Product2> { product });

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        //Custom Approval Matrix Data
        initApprovalMatrices(lstApprovalHierarchy, new List<Product2> { product });

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

    }

    /*
    *  @AUTHOR:         Bharath Varma
    *  @DESCRIPTION:    This method inserts the Approval Matrices
    *  @RETURN:         void
    */
    public static void initApprovalMatrices(List<Approval_Hierarchy__c> lstApprovalHierarchy, List<Product2> products)
    {
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();  // 40115
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,lstApprovalHierarchy[1].id);
        lstMatrix.add(standingDiscountApprovalMatrix);
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix1 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,lstApprovalHierarchy[1].id);
        lstMatrix.add(standingDiscountApprovalMatrix1);

        Custom_Approval_Matrix__c standingMaterialGroupApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Group 1', 10 , MATGRPAIP, null, lstApprovalHierarchy[1].id);
        lstMatrix.add(standingMaterialGroupApprovalMatrix);
        Custom_Approval_Matrix__c standingMaterialGroupApprovalMatrix2 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Group 1', 10 , MATGRPAIP, null, lstApprovalHierarchy[1].id);
        lstMatrix.add(standingMaterialGroupApprovalMatrix2);

        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Number', 10 , null, products[0].id,lstApprovalHierarchy[1].id);
        lstMatrix.add(standingMaterialNumberApprovalMatrix);
        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix3 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Number', 20 , null, products[0].id,lstApprovalHierarchy[1].id);
        standingMaterialNumberApprovalMatrix3.Min_Discount__c = 4;
        lstMatrix.add(standingMaterialNumberApprovalMatrix3);

        insert lstMatrix;
    }

    /*
    *  @AUTHOR:         Bharath Varma
    *  @DESCRIPTION:    This method inserts the Account Sales Area
    *  @RETURN:         void
    */
    public static List<Account_Sales_Area__c> initAccountSalesArea(List<Id> accountIds)
    {

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = accountIds[0];
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = SGD_USD;
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = TXDR;

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = accountIds[1];
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        
		Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '178', '00', false);
        acc3SalesArea.Account__c = accountIds[1];
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = SGD_USD;
        acc3SalesArea.Contract_Number__c = '123456_HK010200';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010200';
        acc3SalesArea.Price_Group__c = TXDR;

        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '178', '00', false);
        acc4SalesArea.Account__c = accountIds[1];
        acc4SalesArea.Price_List_Type__c = '06';
        acc4SalesArea.CurrencyIsoCode = 'USD';
        acc4SalesArea.Price_List__c = SGD_USD;
        acc4SalesArea.Contract_Number__c = '234567_HK010200';
        acc4SalesArea.ERP_Account_Sales_Area_Id__c = '234567_HK010200';
        acc4SalesArea.Price_Group__c = TXDR;
        

        return new List<Account_Sales_Area__c>{acc1SalesArea, acc2SalesArea, acc3SalesArea, acc4SalesArea};

    }

    /*
    *  @AUTHOR:         Bharath Varma
    *  @DESCRIPTION:    This method inserts the Price list and price list items
    *  @RETURN:         void
    */
    public static void initPriceListAndPriceListItem(List<Product2> products)
    {
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(AMEA_USD); //POL-57
        Apttus_Config2__PriceList__c objPriceList2 = TestDataAgreement.initPriceList(SGD_USD);
        insert new List<Apttus_Config2__PriceList__c>{objPriceList, objPriceList2};
        
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(products[0], objPriceList);
        Apttus_Config2__PriceListItem__c objPriceListItem2 = TestDataAgreement.initPriceListItem(products[0], objPriceList2);

        insert new List<Apttus_Config2__PriceListItem__c>{objPriceListItem, objPriceListItem2};
    }
    
}