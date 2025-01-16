/**
*    @author Adyasha Satapathy
*    @date   2021-04-27
*    @description    DCP-38809, DCP-39763: Auto Create Quotation, Cart and Line Items from Work Order
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-04-27            Initial Version
*         KD                           2021-05-10            DCP-46472 : Error handling 
*         Akshay                       2021-05-17            DCP-46579 Added Discount_Reason__c
*         Adyasha                      2021-07-26            DCP-49455: Updated Selector Query to fetch only Estimate WD
*         Ashwin Kumar                 15-Nov-2021           INC0350488: Update Quote when reprice is completed or reprice is not required
*         Bharath Varma                11-Mar-2022           INC0379209: Refreshed stale data before updating the quotation
*    ---------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class CreateQuoteAutomation implements IOpportunityQuoteAutomation
{
    public static final String QUOTE_NAME = 'Quote';
    public static final String QUOTE_RECORD_TYPE_PROPOSAL = 'Proposal';
    public static final String CONFIGURATION_STATUS_SAVED = 'Saved';
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_CREATING;
    public static final String INITIATE_QUOTING_BLANKET = 'Blanket Purchase Order Quote';
    public static final String CODE_PARAMETER_BLANKET_QUOTE_PRODUCTS = 'Billable_Blanket_Purchase_Quote_Material';
    private static final String LOG_TITLE = 'CreateQuoteAutomation';
    private static final String STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE ='Estimate';

    private static String strErrorMessage;
    private Id opportunityId;
    private Id quotationId;
    private Id proposalId;
    Opportunity objOpportunity;
    private String strBlanketPOMaterial;
    List<SVMXC__Service_Order_Line__c> lstWDs;
    Map<String,String> mapMaterialNumberToProductId;
    private Boolean boolHasDiscount=false;

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
	*	@param NA
	*	@return Id of quote
	**/
    public Id getRecordId()
    {
        return quotationId;
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
	*	@param Opportunity Id
	*	@return void
	**/
    public void setRecordId(String parentRecordId)
    {
        this.opportunityId = parentRecordId;    
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
	*	@param NA
	*	@return OpportunityQuoteAutomationQueueable.EmailWrapper
	**/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.getErrorDetails()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails= new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.idRecord = (status == OpportunityQuoteAutomationQueueable.STATUS.QUOTE_CREATING) ? opportunityId : proposalId;
        wrapDetails.setEmail(objOpportunity.Work_Order__r.OwnerId);
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = getFailureReason();
        wrapDetails.idProposal=proposalId;
        wrapDetails.idSourceWorkOrder=objOpportunity.Work_Order__c;
        wrapDetails.strQuoteName = '';
        if(status != OpportunityQuoteAutomationQueueable.STATUS.QUOTE_CREATING){
            wrapDetails.strQuoteName = new ApttusProposalsSelector().selectById(new Set<Id>{proposalId})[0].Name;
        }
        wrapDetails.strWOName=objOpportunity.Work_Order__r.Name;
        wrapDetails.strRegion=objOpportunity.Work_Order__r.Account_Region__c;
        ilib_LogEvent.pop();
        return wrapDetails;
    }

    /**
    *   DCP-46472
	*	@author Akshay Mohan
	*	@param NA
	*	@return String
	**/
    private String getFailureReason(){
        String strFailureMessage='';
        switch on status{
            when QUOTE_CREATING{ strFailureMessage=Label.OpportunityQuoteAutomation_QUOTE_CREATING;}
            when CART_LINE_CREATING{ strFailureMessage=Label.OpportunityQuoteAutomation_CART_CREATING;}
            when QUOTE_DISCOUNT_NEEDED{ strFailureMessage=Label.OpportunityQuoteAutomation_QUOTE_DISCOUNT_NEEDED;}
            when else{ strFailureMessage=Label.OpportunityQuoteAutomation_OTHER;}
        }
        return strFailureMessage;
    }
    
    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext context)
    {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try
        {
            ApttusProposals.booIsRepriceRequired = true;    //INC0350488
            proposalId = createProposal();
            //DCP-38808: Start - declare platform event list
            Admin_Operation__e objQuoteAmountUpdates = new Admin_Operation__e(Related_Record__c=proposalId,Name__c='UpdateQuoteAmountOnWO');
            EventBus.publish(objQuoteAmountUpdates);
            //DCP-38808: End - declare platform event list
            Id cartId = createCart(proposalId);
            createCartLineItems(cartId, lstWDs, proposalId);    //INC0350488 - Added proposalId param
            if(boolHasDiscount){
                status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_DISCOUNT_NEEDED;
            }else{
                quotationId = proposalId;
            }
        }
        catch(Exception e)
        {
            strErrorMessage = e.getMessage();
            ilib_LogEvent.message('Exception occured in: CreateQuoteAutomation ' +e);
            quotationId = null;
            ApexExceptions.emit(LOG_TITLE,String.isNotBlank(proposalId)?proposalId:opportunityId, e);
        }
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
    *   @description Create Quote
	*	@param NA
	*	@return Id of quote
	**/
    public Id createProposal()
    {
        ilib_LogEvent.push(LOG_TITLE + '.createProposal()');
        objOpportunity = new OpportunitySelector().selectOpportunities(new Set<Id>{opportunityId})[0];
        Apttus_Proposal__Proposal__c objProposal = new Apttus_Proposal__Proposal__c();
        ID proposalRecordTypeID = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByDeveloperName().get(QUOTE_RECORD_TYPE_PROPOSAL).getRecordTypeId();
        objProposal = Apttus_Proposal.ProposalWebService.createProposalFromOpportunity(opportunityId, proposalRecordTypeID);
        objProposal.Apttus_Proposal__Proposal_Name__c = objOpportunity.Work_Order__r.Name + ' - ' + QUOTE_NAME;
        objProposal.Prepared_by__c = UserInfo.getUserId();
        objProposal.Work_Order__c = objOpportunity.Work_Order__c;
        objProposal.Apttus_Proposal__ExpectedEndDate__c = System.today().addDays(30);
        objProposal.MyIllumina_User_Email__c = objOpportunity.Primary_Contact__r.Email;
        
        //DCP-46579: Start- Get work details to populate discount reason
        objProposal.Work_Order_Discount_Request__c='';
        lstWDs = new WorkDetailsSelector().selectWorkDetailsByWorkOrderIdWithRecordType(new set<Id>{objOpportunity.Work_Order__c},STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE);//49455
        for(SVMXC__Service_Order_Line__c workdetail : lstWDs){   
            if(String.isNotBlank(workdetail.Discount_Reason__c)){
                String strReasonConcat=  workdetail.SVMXC__Product__r.ProductCode+' - '+workdetail.Discount_Reason__c;
                ilib_LogEvent.message('strReasonConcat' + strReasonConcat);
                objProposal.Work_Order_Discount_Request__c+= String.isBlank(objProposal.Work_Order_Discount_Request__c)? strReasonConcat : ','+strReasonConcat;
                boolHasDiscount=true;
            }
        }
        objProposal.Work_Order_Discount_Request__c= String.isBlank(objProposal.Work_Order_Discount_Request__c)? null : objProposal.Work_Order_Discount_Request__c.abbreviate(32760);//keep buffer
        ilib_LogEvent.message('Final Work_Order_Discount_Request__c' + objProposal.Work_Order_Discount_Request__c);
        //DCP-46579: End- Get work details to populate discount reason
        
        insert objProposal;

        //INC0379209 - Added this to refresh stale data where the primary field was getting overwritten in the update statement below
        objProposal = new Apttus_Proposal__Proposal__c(Id = objProposal.Id);

        //DCP - 47291
        if(String.isNotBlank(objOpportunity.Work_Order__r.SVMXC__Site__c))
        {
            List<Customer_Master_Data__c> lstCMD = new CustomerMasterDataSelector().selectByAccountERPId(new Set<String> {objOpportunity.Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c});
            if(!lstCMD.isEmpty())
            {
                objProposal.Ship_To__c = lstCMD[0].Id;
                update objProposal;
            }
        }

        status=OpportunityQuoteAutomationQueueable.STATUS.CART_CREATING;
        ilib_LogEvent.pop();
        return objProposal.Id;
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
    *   @description Create Cart
	*	@param Id of Quote
	*	@return Id of cart
	**/
    public Id createCart(Id quoteId)
    {
        if(String.isBlank(quoteId)){ return null;}
        ilib_LogEvent.push(LOG_TITLE + '.createCart()');
        ilib_LogEvent.message('inside CreateQuoteAutomation.createCart, value of quoteId: '+quoteId);
        Id cartId = UtilsCart.createCartForQuote(quoteId);
        status=OpportunityQuoteAutomationQueueable.STATUS.CART_LINE_CREATING;
        ilib_LogEvent.pop();
        return cartId;
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
    *   @description Create Cart Lines
	*	@param Id of cart
	*	@return NA
	**/
    public void createCartLineItems(Id cartLevelId,List<SVMXC__Service_Order_Line__c> lstWorkDetail, Id proposalId)
    {
        if(String.isBlank(cartLevelId) || lstWorkDetail == NULL){ 
            ApttusProposals.updateRepriceFlagOnQuote(proposalId);     //INC0350488
            return;
        }
        ilib_LogEvent.push(LOG_TITLE + '.createCartLineItems()');

        List<UtilsCart.LineItemWrapper> lstLineItemWrappers = new List<UtilsCart.LineItemWrapper>();
        mapMaterialNumberToProductId = new Map<String,String>();

        Code_Parameter__mdt objCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAMETER_BLANKET_QUOTE_PRODUCTS})[0];
        strBlanketPOMaterial = objCodeParam.Value__c;
        Boolean isBlanketPOQuote = objOpportunity.Work_Order__r.Initiate_Quoting__c == INITIATE_QUOTING_BLANKET;
        if(isBlanketPOQuote)
        {
            Set<String> setMaterialNumbers = new Set<String>{strBlanketPOMaterial};
            Product2 objProduct = new ProductsSelector().selectProductsForMaterialNumber(setMaterialNumbers)[0];
            mapMaterialNumberToProductId.put(objProduct.Material_Number__c, objProduct.Id);
        }

        lstLineItemWrappers = getListOfLineItemWrappers(lstWorkDetail,isBlanketPOQuote);
        if(!lstLineItemWrappers.isEmpty())
        {
            UtilsCart.addMultiProducts(cartLevelId,lstLineItemWrappers);
            UtilsCart.doReprice(cartLevelId);

            Apttus_Config2__ProductConfiguration__c objProductConfiguration = new Apttus_Config2__ProductConfiguration__c(Id = cartLevelId,Apttus_Config2__Status__c = CONFIGURATION_STATUS_SAVED,Work_Order__c = objOpportunity.Work_Order__c);
            updateCartLineItemValues(objProductConfiguration,lstWorkDetail);
        }else{
            ApttusProposals.updateRepriceFlagOnQuote(proposalId);     //INC0350488
        }  
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
    *   @description Get list of Work Details to be inserted based on Itemized or Blanket Order Quote
	*	@param WorkDetails List, Boolean value for Blanket Purchase Order Quote
	*	@return Line Items List Wrapper
	**/    
    public List<UtilsCart.LineItemWrapper> getListOfLineItemWrappers(List<SVMXC__Service_Order_Line__c> lstWorkDetail,Boolean isBlanketPOQuote)
    {
        List<UtilsCart.LineItemWrapper> lstLineItemWrapper = new List<UtilsCart.LineItemWrapper>();
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetail)
        {
            UtilsCart.LineItemWrapper liWrapper = getLineItemWrapperInstance(objWorkDetail,isBlanketPOQuote);
            if(liWrapper != NULL){ lstLineItemWrapper.add(liWrapper);}
            if(isBlanketPOQuote){ break;}
        }
        return lstLineItemWrapper;
    }
    
    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
    *   @description Set Values for Cart Line Items
	*	@param WorkDetails List, Boolean value for Blanket Purchase Order Quote
	*	@return Line Items List wrapper
	**/
    public UtilsCart.LineItemWrapper getLineItemWrapperInstance(SVMXC__Service_Order_Line__c objWorkDetail,Boolean isBlanketPOQuote)
    {
        if(objWorkDetail.SVMXC__Product__c == NULL){ return NULL;}
        UtilsCart.LineItemWrapper liWrapper = new UtilsCart.LineItemWrapper(objWorkDetail);
        if(isBlanketPOQuote)
        {
            liWrapper.productId = mapMaterialNumberToProductId.get(strBlanketPOMaterial);
            liWrapper.quantity = 1;
            liWrapper.shippingInCloseQuarter = 1;
        }
        return liWrapper;
    }

    /*Populate Serial Number and Work Detail on Cart Lines from Opportunity Line Items*/
    public void updateCartLineItemValues(Apttus_Config2__ProductConfiguration__c objProductConfiguration,List<SVMXC__Service_Order_Line__c> lstWorkDetail)
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateCartLineItemValues()');
        List<Apttus_Config2__LineItem__c> lstUpdateLineItems = new List<Apttus_Config2__LineItem__c>();
        Integer count = 0;
        for (Apttus_Config2__LineItem__c li : new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id>{objProductConfiguration.id})){
            SVMXC__Service_Order_Line__c objWorkDetail = lstWorkDetail.get(count);
            li.Work_Detail_Line__c = objWorkDetail.Id;
            li.Serial_Number__c = objWorkDetail.SVMXC__Service_Order__r.Installed_Product_Serial_Number__c;
            lstUpdateLineItems.add(li);  
            count = count + 1;
        }
        if(!lstUpdateLineItems.isEmpty())
        {
            update lstUpdateLineItems;
            update objProductConfiguration;
            status = OpportunityQuoteAutomationQueueable.STATUS.CART_LINE_CREATED; 
        }
        ilib_LogEvent.pop();
    }
}