/**
*    @author Prakhar Kumar
*    @date   2019-11-19
*    @description  Test class for InformaticsProductQuestionnaireCntrl
*                                      Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Prakhar Kumar                    25-11-2019              Original method 
*       Rahul Bishnoi                    17-01-2020              DCP-32794 - Removed Software_Product_Check__c
*       Khushbu Vasani                   12-09-2022              Test class error fix
*       Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*       Prem Ranjan                      2023-01-09              Code scan fix((APEX) Comment is required)
*       Gerardo Garcia                   05-28-2024              Fix test Too many SOQL queries: 101. Refactor.
*/

@isTest
public class TestInformaticsProductQuestionnaireCntrl{
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final String ACCOUNT_NAME =  'My Account 102-120';
    public static final String QUOTE_NAME =  'Test Proposal';
    public static final String PRODUCT_COMMON =  'Common Product';
    public static final String PRODUCT_INFORMATIC =  'Informatic Product';

    @TestSetup
    static void makeData(){
        //Creating Price List
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;

        //Creating Account 
        Account objAccount = TestDataAccount.initAccount();
        objAccount.Territory_Region__c ='AMR';
        objAccount.CurrencyIsoCode='USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.Name = ACCOUNT_NAME;
        insert objAccount;

        //Create Contact
        Contact objContact = TestDataContact.initContact(objAccount);
        insert objContact;

        //Creating Opportunity
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.Price_List__c = objPriceList.Name;
        insert objOpportunity;

        //Fetch metadata with Required Product Family
        //Creating Product
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        objProduct2.Informatics_Family__c ='BASESPACE_CLARITY_LIMS';
        objProduct2.Informatics_SKU_Type__c = 'SUBSCRIPTION';
        objProduct2.Subscription_Tier__c = 'Enterprise';
        objProduct2.Name = PRODUCT_INFORMATIC;
        insert  objProduct2;

        // --Creating cart
        Product2 objProduct1 = TestDataMaster.createProduct(false);
        objProduct1.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        objProduct1.Name = PRODUCT_COMMON;
        insert new List<Product2> {objProduct1};

        List<Apttus_Config2__PriceListItem__c> listPli = new List<Apttus_Config2__PriceListItem__c>();
        listPli.add(TestDataProposal.initPriceListItem(objProduct1, objPriceList));
        listpli.add(TestDataProposal.initPriceListItem(objProduct2, objPriceList));
        insert listPli;

        //Creating Quote
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, QUOTE_NAME, objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
    }

    private static Product2 getProduct(String name) {
        return [SELECT id FROM Product2 WHERE Name = :name LIMIT 1];
    }

    private static Apttus_Proposal__Proposal__c getQuotation() {
        return [SELECT id, Sales_Discretionary_Approval_Error__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = :QUOTE_NAME LIMIT 1];
    }

    private static Contact getContact() {
        return [SELECT Id FROM Contact WHERE Account.Name = :ACCOUNT_NAME];
    }

    /*
    * author: 
    * Test method to cover ApttusLineItemsSelector,ApttusProductConfigLineTrigger,ApttusProductConfigTrigger,ApttusProductConfigurationsSelector,ApttusProposalLineItemsSelector,ApttusTempObjectTrigger,ConditionalEditFormController,DragenProductsSelector,InformaticProductsService,InformaticsProductQuestionnaireCntrl
    */
    @isTest
    public static void checkRequiredFields(){

        Apttus_Proposal__Proposal__c  objProposal = getQuotation();
        Product2 commonProd = getProduct(PRODUCT_COMMON);
        Product2 infoProd = getProduct(PRODUCT_INFORMATIC);
        Contact objContact = getContact();

        Test.startTest();

        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;

        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct1 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct1.ProductId = commonProd.Id;
        selectProduct1.Quantity = 1;
        selectProduct1.SellingTerm = 12;
        selectProduct1.StartDate = Date.today();
        selectProduct1.EndDate = Date.today() + 364;
        selectedProducts.add(selectProduct1); 

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = infoProd.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.CartId;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c = :objProductConfig.CartId];

        for(Integer idx = 0; idx < lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0){
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 3000;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 6;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Applied_Discount_Percentage__c = 5 ;
                lineitem.Applied_Discount_Amount__c = 3600;
                lineitem.Applied_Discount_Details__c ='BOGO Promo Savings';
                lineitem.Promotion_Code__c = 'BOGO';
                lineitem.Promotion_Discount__c= 10;
            }

            if(idx == 1){
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 3000;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 6;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Applied_Discount_Percentage__c = 5 ;
                lineitem.Applied_Discount_Amount__c = 3600 ;
                lineitem.Applied_Discount_Details__c ='Sales Discretionary';
            }   
        }
        update lineItemList;

        Apttus_Config2.CPQWebService.validateCart(objProductConfig.CartId);
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        // add request parameters
        requestFinalize.CartId = objProductConfig.CartId;
        // finalize the cart
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);

        Test.stopTest();

        //DCP-32794 - Removed Software_Product_Check__c
        Apttus_Proposal__Proposal__c objProposal1 = getQuotation();
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id,Approval_Category__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :objProposal.id];
        Assert.isTrue(lstPLI.size() > 0, 'PLI not inserted.');

        System.debug('lineItemList [0]===>'+lineItemList);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal1, infoProd);
        proposalLineItem.Apttus_QPConfig__DerivedFromId__c = lineItemList[0].Id;

        System.debug('proposalLineItem  ID===>'+proposalLineItem.Id);

        proposalLineItem.Registrant_Contact__c = objContact.id;
        proposalLineItem.Apttus_QPConfig__StartDate__c = Date.today();
        proposalLineItem.Apttus_QPConfig__EndDate__c = Date.today()+364;
        proposalLineItem.Subscription_Duration__c = '6';
        proposalLineItem.ERP_Line_Number_Id__c = '245242_1920';
        insert proposalLineItem;

        String strResult = InformaticsProductQuestionnaireCntrl.fetchFields('Apttus_Proposal__Proposal_Line_Item__c',proposalLineItem.Id);
        ConditionalEditFormController.getDragenCustomMetaData(proposalLineItem.Id);

        System.debug('JSON1 :'+strResult);
        String strJSON = UtilsObject.getJSONPart(strResult, ', "Required_Fields" : ', ', "Read_Only_Fields" : ');
        System.debug('JSON :'+strJSON);
        String strRequiredFields = (String)JSON.deserialize(strJSON, String.class);
        System.debug('strRequiredFields :'+strRequiredFields);
        Assert.isTrue(strRequiredFields.contains('Registrant_Contact__c'), 'Required field Registrant_Contact__c not returned.');
    }

    /*
    * author: Bharath Varma
    * Test method to cover ApttusTempObjects class
    */
    @isTest
    public static void testRecalculateRecordChanges(){
        Apttus_Proposal__Proposal__c  proposal = getQuotation();

        Test.startTest();

        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;

        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        User sysAdmin = new UsersSelector().usersInProfile(System.label.ProfileSystemAdmin, new Set<Id> {}, true)[0];

        Apttus_Config2__TempObject__c tempObj = TestDataProposal.getNewTemp(objProductConfig.CartId);
        tempObj.OwnerId = sysAdmin.Id; 
        update tempObj;

        Test.stopTest();
        Apttus_Config2__TempObject__c res = [SELECT id, OwnerId FROM Apttus_Config2__TempObject__c WHERE id = :tempObj.id LIMIT 1];
        Assert.areEqual(sysAdmin.id, res.OwnerId);
    }
 }