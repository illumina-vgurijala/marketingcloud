/*@ author       : Gopesh Banker
* @ date         : 05 Oct 2018
* @ Description  : display action callback test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopesh Banker          05 Oct 2018                      Initial version
*/
@isTest
private class TestApttusDisplayActionCallback {

    private static final String FINALIZE = 'Finalize';
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String USA = 'USA';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';
    
    @testSetup
    static void setupData()
    {
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAccount.Id);
        objAccount.Territory_Region__c =AMR;
        objAccount.CurrencyIsoCode=USD;
        objAccount.Country_Local__c = USA;
        Update objAccount;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
      
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
        
        
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        
        TestDataProposal.initPriceListItem(objProduct, objPriceList);
        
        
        TestDataProposal.getNewCart(objProposal);
        
        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;

        List<Apttus_Config2__ConfigCustomDisplayActions__c> lstConfigDisplayActions = new List<Apttus_Config2__ConfigCustomDisplayActions__c>();
        
        Apttus_Config2__ConfigCustomDisplayActions__c objCustomSetting = new Apttus_Config2__ConfigCustomDisplayActions__c();
        objCustomSetting.Apttus_Config2__ActionLabelName__c = FINALIZE;
        objCustomSetting.Apttus_Config2__ActionName__c = FINALIZE;
        objCustomSetting.Apttus_Config2__Sequence__c = 1;
        objCustomSetting.Apttus_Config2__IsEnabled__c = false;
        objCustomSetting.Name = 'Test' + objCustomSetting.Apttus_Config2__Sequence__c + '' + System.now().millisecond();
        objCustomSetting.Apttus_Config2__DisplayType__c = 'Cart Line Item';
        lstConfigDisplayActions.add(objCustomSetting);

        insert lstConfigDisplayActions;        
    }

    /**
    *  @author Gopesh Banker
    *  @description Test method for display action callback
    **/
    @isTest
    static void testCallback()
    {
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c limit 1];
        Product2 thisProduct = [Select Id from product2 limit 1];
        
        Apttus_CPQApi.CPQ.CreateCartRequestDO createCartRequest = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        createCartRequest.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO createCartResponse = Apttus_CPQApi.CPQWebService.createCart(createCartRequest);

        

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addProductRequest.CartId = createCartResponse.CartId;
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectedProduct.ProductId = thisProduct.Id;
        selectedProduct.Quantity = 1;
        selectedProduct.SellingTerm = 12;
        addProductRequest.SelectedProducts.add(selectedProduct);

        Apttus_CPQApi.CPQWebService.addMultiProducts(addProductRequest);

        

        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id,Quote_Sub_Type__c,GT_Check_Pending_Count__c From Apttus_Config2__ProductConfiguration__c where id = :createCartResponse.CartId];

        List<Apttus_Config2__LineItem__c> lstLi = [Select Id, Global_Trade_Block__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :createCartResponse.CartId];

        lstLi.get(0).Global_Trade_Block__c = false;
        update lstLi;

        List<Apttus_Config2__ConfigCustomDisplayActions__c> lstConfigDisplayActions = [SELECT Id, Name, Apttus_Config2__ActionName__c, Apttus_Config2__ActionLabelName__c, Apttus_Config2__DisplayType__c, Apttus_Config2__ActionPage__c, Apttus_Config2__IsEnabled__c, Apttus_Config2__Sequence__c FROM Apttus_Config2__ConfigCustomDisplayActions__c ];
        List<Apttus_Config2.DisplayActionInfo> lstDisplayActions = new List<Apttus_Config2.DisplayActionInfo>();

        Apttus_Config2.DisplayActionInfo oDisplayActionInfo;

        for( Apttus_Config2__ConfigCustomDisplayActions__c oTempCustomSetting : lstConfigDisplayActions){
            oDisplayActionInfo = new Apttus_Config2.DisplayActionInfo(oTempCustomSetting);
            oDisplayActionInfo.IsEnabled = false;
            lstDisplayActions.add(oDisplayActionInfo);
        }

        Test.startTest();

        ApttusDisplayActionCallback objDisplayActionCallback = new ApttusDisplayActionCallback();
        try{
            objDisplayActionCallback.start(null, lstDisplayActions);
        } catch(Exception e){
            System.debug('Exception : '+ e);
        }

        Apttus_Config2.ProductConfiguration objCart;
        objDisplayActionCallback.objProductConfig = prodConfig;
        objDisplayActionCallback.start(objCart,lstDisplayActions);
        objDisplayActionCallback.setActionProperties(null);
        Test.stopTest();
        System.assertEquals(1,[SELECT COUNT() FROM Apttus_Config2__ConfigCustomDisplayActions__c WHERE Apttus_Config2__IsEnabled__c = false]);
    }
}