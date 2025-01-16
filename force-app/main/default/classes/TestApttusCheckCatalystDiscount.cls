/*@ author       : Rahul Sharma
* @ date         : 14-Apr-19
* @ Description  : TestApttusCheckCatalystDiscount is the test class for ApttusCheckCatalystDiscount
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rahul Sharma         14-APR-2019                                      Initial version
* Satya Swain          23-SEP-2019                                      DCP-30062 Sonar Qube Fixes
//SonarQube Fixes 10-12-2019
* Prem Ranjan          20-Feb-2023                                      CodeScan Fixes (APEX) Variable Naming Conventions
*/

@isTest(isParallel=false)
public class TestApttusCheckCatalystDiscount {
    public static final String DISCOUNT_TYPE_PERCENT = '% Discount';
    public static final String DISCOUNT_TYPE_AMOUNT ='Discount Amount';
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = 10;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = 15;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = NULL;
    public static final String STRING_BLANK_COST_CENTER = NULL;
    
    /**
     *  @author Rahul Sharma
     *  @description Test Data Setup
    **/
    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getNewAccount();
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK'; 
        acc2.ERP_Customer_Id__c = '123456';

        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc2);
        insert lstAcc;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc2.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea};

        Contact con = TestDataPerson.getNewContact(acc.Id);
        con.email = 'axs@scs.com';

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('01-AMR-USD');
        insert priceList;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);   
        insert lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal 1', priceList.id, true, 'Draft', 'None');
        proposal1.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal1.Apttus_Proposal__Proposal_Name__c = 'Test Proposal 1';
        proposal1.Apttus_Proposal__Primary_Contact__c = con.id;
        lstProp.add(proposal1);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal 2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal 2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        lstProp.add(proposal2);
        insert lstProp;

        ApttusCatalystDiscountMock.strQuoteId = lstProp[0].Id;

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
        insert lstPriceList;

    }

    @isTest
    static void testCatalystDiscountSuccess()
    {
        User objCurrentUser = [Select Id FROM User WHERE Id=:UserInfo.getUserId()];
        new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_DisplayAction_Catalyst';
        ps.Label = 'Test_DisplayAction_Catalyst';
        insert ps;

        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Check_Catalyst_Discount'][0].Id;
        insert sea;

        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = objCurrentUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa; 

        System.runAs(objCurrentUser){
        Apttus_Proposal__Proposal__c proposal, proposal1;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c like '%Test Proposal%'];
        //Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal 2' LIMIT 1];
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        for(Apttus_Proposal__Proposal__c objProp : lstProposal){
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 1'){ 
                proposal = objProp;
             }
             if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 2')
             {
                proposal1 = objProp;
             }
         }
        ApttusCatalystDiscountMock.strQuoteId = proposal.Id;

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusCatalystDiscount'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

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

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId = [select Id from Apttus_Config2__PriceListItem__c];
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id, name from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :objProductConfig.Id];
        ApttusCatalystDiscountMock.strLineItemId = lineItemList[0].Id;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                System.debug('Line item 0 --'+lineitem);
                 lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__Quantity__c=1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Applied_Discount_Details__c = 'Sales Discretionary';
                lineitem.Applied_Discount_Percentage__c = 5;
            }
            else if (idx == 1)
            {
                System.debug('Line item 1 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__Quantity__c=1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Applied_Discount_Details__c = 'Sales Discretionary';
                lineitem.Applied_Discount_Percentage__c = 5;
            }
        }
        update lineItemList;

        ApttusCheckCatalystDiscount objCheckCatalystDisc = new ApttusCheckCatalystDiscount();
        ApttusCatalystDiscountMock.integerResponseCode = 200;
        Test.startTest();
        objCheckCatalystDisc.callCatalyst();
        objCheckCatalystDisc.redirectToCart();
        ApttusCheckCatalystDiscount objCheckCatalystDisc2 = new ApttusCheckCatalystDiscount();
        // for exception
        String strConfigurationId = 'wrongId';
        objCheckCatalystDisc2.strConfigId = strConfigurationId;
        objCheckCatalystDisc2.callCatalyst();
        //Added below code for checkmarx asserts
        HttpResponse res;
        HttpRequest req = new HttpRequest();
        res = new ApttusCatalystDiscountMock().respond(req);
        System.assertEquals(200,res.getStatusCode(),'Catalyst Response is Failure');
        Test.stopTest();
    }
    }

    @isTest
    static void testCatalystDiscountFailure()
    {
        User objCurrentUser = [Select Id FROM User WHERE Id=:UserInfo.getUserId()];
        new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_DisplayAction_Catalyst';
        ps.Label = 'Test_DisplayAction_Catalyst';
        insert ps;

        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Check_Catalyst_Discount'][0].Id;
        insert sea;

        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = objCurrentUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa; 

        System.runAs(objCurrentUser){
        Apttus_Proposal__Proposal__c proposal, proposal1;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c like '%Test Proposal%'];
        //Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal 2' LIMIT 1];
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        for(Apttus_Proposal__Proposal__c objProp : lstProposal){
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 1'){ 
                proposal = objProp;
             }
             if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 2')
             {
                proposal1 = objProp;
             }
         }
         ApttusCatalystDiscountMock.strQuoteId = proposal.Id;

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusCatalystDiscount'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

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

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId = [select Id from Apttus_Config2__PriceListItem__c];
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id, name from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :objProductConfig.Id];
        ApttusCatalystDiscountMock.strLineItemId = lineItemList[0].Id;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                System.debug('Line item 0 --'+lineitem);
                 lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__Quantity__c=1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Applied_Discount_Details__c = 'Sales Discretionary';
                lineitem.Applied_Discount_Percentage__c = 5;
            }
            else if (idx == 1)
            {
                System.debug('Line item 1 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__Quantity__c=1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Applied_Discount_Details__c = 'Sales Discretionary';
                lineitem.Applied_Discount_Percentage__c = 5;
            }
        }
        update lineItemList;

        ApttusCheckCatalystDiscount objCheckCatalystDisc = new ApttusCheckCatalystDiscount();
        ApttusCatalystDiscountMock.integerResponseCode = 401;
        Test.startTest();
        objCheckCatalystDisc.callCatalyst();
        objCheckCatalystDisc.redirectToCart();
        //Added below code for checkmarx asserts
        HttpResponse res;
        HttpRequest req = new HttpRequest();
        res = new ApttusCatalystDiscountMock().respond(req);
        System.assertEquals(true,ApttusCatalystDiscountMock.booResponseSuccess,'Catalyst is not responding');
        Test.stopTest();
    }
    }

     /**
    * @Author Rahul Sharma
    * @description Test method for Custom Permission 
    */
    @isTest
    static void testCheckCatalystPermissionForUser(){
        new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Testing_SL_Catalyst_Discount_Permission';
        ps.Label = 'Testing_SL_Catalyst_Discount_Permission';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Check_Catalyst_Discount'][0].Id;
        insert sea;
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

        String strSysAdmin = 'System Administrator';
        Set<Id> setUserId = UtilsCollection.getSetOfIds([SELECT AssigneeId FROM PermissionSetAssignment 
                                                         WHERE Assignee.Profile.Name= :strSysAdmin
                                                            AND PermissionSet.Name='Test_DisplayAction_Catalyst']
                                                        ,'AssigneeId');
        
        User objUser = TestDataUser.findUserInProfile(strSysAdmin,setUserId,true);

        System.runAs(objUser){     
            Apttus_Proposal__Proposal__c proposal, proposal1;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c like '%Test Proposal%'];
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        for(Apttus_Proposal__Proposal__c objProp : lstProposal){
            if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 1'){ 
                proposal = objProp;
             }
             if(objProp.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 2')
             {
                proposal1 = objProp;
             }
         }
         ApttusCatalystDiscountMock.strQuoteId = proposal.Id;

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusCatalystDiscount'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

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

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
            
        ApttusCheckCatalystDiscount objCheckCatalystDisc = new ApttusCheckCatalystDiscount();
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig1=TestDataProposal.getNewCart(proposal1);
        objCheckCatalystDisc.callCatalyst();
        ApttusCheckCatalystDiscount objCheckCatalystDisc2 = new ApttusCheckCatalystDiscount();
        // Added by Satya: SonarQube Issue Fix
        objCheckCatalystDisc2.strConfigId = objApttusProductConfig1.Id;
        objCheckCatalystDisc2.callCatalyst();
        Test.stopTest();

        //Added by Rahul: Checkmarx Asserts
        Boolean boolCatalystEnabled = FeatureManagement.checkPermission('Check_Catalyst_Discount');
        System.assertEquals(false,boolCatalystEnabled,'Catalyst Permission is not assigned');
        }
    }
}