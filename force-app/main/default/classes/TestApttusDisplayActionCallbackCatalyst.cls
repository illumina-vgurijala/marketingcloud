/*@ author       : Rahul Sharma
* @ date         : 20 April 2019
* @ Description  : Display action callback Catalyst test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rahul Sharma         20 Apr 2019                     Initial version
* Nishan Shetty        05-Jan-2023                     CodeScan Fix for Unused Local Variable.
*/
@isTest(isParallel=false)
private class TestApttusDisplayActionCallbackCatalyst {

    
    private static final String SUGGESTED_SALES = 'Apply_Remove';
    private static final String PRICELIST = '01-AMR-USD';
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';
    
    @testSetup
    static void setupData()
    {
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Territory_Region__c =AMR;
        objAccount.CurrencyIsoCode=USD;
        Update objAccount;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
        
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
                
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        TestDataMaster.createProduct(true);//CodeScan Fix For Unused Local Variable.

        Apttus_Config2__ProductConfiguration__c newCart = TestDataProposal.getNewCart(objProposal);
                
        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
          

        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;
    
        List<Apttus_Config2__ConfigCustomDisplayActions__c> lstConfigDisplayActions = new List<Apttus_Config2__ConfigCustomDisplayActions__c>();
        
        Apttus_Config2__ConfigCustomDisplayActions__c objCustomSetting = new Apttus_Config2__ConfigCustomDisplayActions__c();
        objCustomSetting.Apttus_Config2__ActionLabelName__c = SUGGESTED_SALES;
        objCustomSetting.Apttus_Config2__ActionName__c = SUGGESTED_SALES;
        objCustomSetting.Apttus_Config2__Sequence__c = 1;
        objCustomSetting.Apttus_Config2__IsEnabled__c = false;
        objCustomSetting.Name = 'Test' + objCustomSetting.Apttus_Config2__Sequence__c + '' + System.now().millisecond();
        objCustomSetting.Apttus_Config2__DisplayType__c = 'Cart Line Item';
        lstConfigDisplayActions.add(objCustomSetting);

        insert lstConfigDisplayActions;  
    }

    /**
    *  @author Rahul  Sharma
    *  @description Test method for display action callback Catalyst
    **/
   
    
    @isTest
    static void testCallbackCatalyst()
    {   
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
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa; 

        String strSysAdmin = 'System Administrator';
        Set<Id> setUserId = UtilsCollection.getSetOfIds([SELECT AssigneeId FROM PermissionSetAssignment 
                                                         WHERE Assignee.Profile.Name= :strSysAdmin
                                                            AND PermissionSet.Name='Test_DisplayAction_Catalyst']
                                                        ,'AssigneeId');
        
        User objUser = TestDataUser.findUserInProfile(strSysAdmin,setUserId,true);

        //System.runAs(new User(Id = UserInfo.getUserId())){  
        System.runAs(objUser){
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c limit 1];
        Product2 thisProduct = [Select Id from product2 limit 1];

        Apttus_CPQApi.CPQ.CreateCartRequestDO createCartRequest = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        createCartRequest.QuoteId = proposal.Id;

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id,Quote_Sub_Type__c,GT_Check_Pending_Count__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];  

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addProductRequest.CartId = objProductConfig.Id;
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectedProduct.ProductId = thisProduct.Id;
        selectedProduct.Quantity = 1;
        selectedProduct.SellingTerm = 12;
        addProductRequest.SelectedProducts.add(selectedProduct);

        Apttus_CPQApi.CPQWebService.addMultiProducts(addProductRequest);

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
        objDisplayActionCallback.objProductConfig = objProductConfig;
        objDisplayActionCallback.start(objCart,lstDisplayActions);
        objDisplayActionCallback.setActionProperties(null);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Apttus_Config2__ConfigCustomDisplayActions__c WHERE Apttus_Config2__IsEnabled__c = false]);
    }
}
    
}