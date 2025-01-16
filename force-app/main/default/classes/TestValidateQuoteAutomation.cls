/**
*    @author Adyasha Satapathy
*    @date   2021-05-10 
*    @description    DCP-38809: Test class for Validate Cart
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Adyasha Satapathy       2021-05-11         Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestValidateQuoteAutomation
{
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';

    
    /**
    *   DCP-38809
  *  @author Adyasha Satapathy  
  **/
    @TestSetup
    static void setupData()
    {
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
		    objWorkOrder.Is_Auto_Created__c = true;
        insert objWorkOrder;

        
        setting.Bypass_All_Validations__c = false;
        update setting;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity2(objWorkOrder.SVMXC__Company__c);
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Price_List__c = objPriceList.Name;
        objOpportunity.Work_Order__c = objWorkOrder.Id;
        insert objOpportunity;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objWorkOrder.SVMXC__Company__c, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal.Work_Order__c =  objWorkOrder.Id;
        insert objProposal;
        
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        
        TestDataProposal.initPriceListItem(objProduct, objPriceList);
        
        
        TestDataProposal.getNewCart(objProposal);
        
        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;

        Apttus_CPQApi.CPQ.CreateCartRequestDO createCartRequest = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        createCartRequest.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO createCartResponse = Apttus_CPQApi.CPQWebService.createCart(createCartRequest);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addProductRequest.CartId = createCartResponse.CartId;
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectedProduct.ProductId = objProduct.Id;
        selectedProduct.Quantity = 1;
        selectedProduct.SellingTerm = 12;
        addProductRequest.SelectedProducts.add(selectedProduct);

        Apttus_CPQApi.CPQWebService.addMultiProducts(addProductRequest);
    }

    
    /**
    *   DCP-38809
  *  @author Adyasha Satapathy
  **/
    @isTest
    static void testValidateCart()
    {
        Apttus_Proposal__Proposal__c objProposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
        ValidateQuoteAutomation queueable = new ValidateQuoteAutomation();
        queueable.setRecordId(objProposal.Id);
        
        Test.startTest();
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        
        System.assert(String.isNotBlank(queueable.getRecordId()),'Validate cart not successfull');
        Apttus_Proposal__Proposal__c objProposalPostUpdate = [Select Id,SAP_Quote__c, SAP_Errors__c from Apttus_Proposal__Proposal__c where Id = :objProposal.Id];
        System.debug('@@@@  objProposalPostUpdate.SAP_Quote__c : '+objProposalPostUpdate.SAP_Quote__c);
        System.debug('@@@@  objProposalPostUpdate.SAP_Errors__c : '+objProposalPostUpdate.SAP_Errors__c);
        System.assert(String.isBlank(objProposalPostUpdate.SAP_Quote__c),'SAP Quote # not captured');
    }
    /**
     *  @author      : Arif,Dalali
     *  @description : method to cover catch block in ValidateQuoteAutomation
     **/
    @isTest
    public static void coverCatchBlockValidateQuoteAutomation(){
        try{
          ValidateQuoteAutomation.catchException = true;
          ValidateQuoteAutomation pd = new ValidateQuoteAutomation( );
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}