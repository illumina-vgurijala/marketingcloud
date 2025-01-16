/**
*    Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rahul Bishnoi          10 March 2021                  Added afterClone 	 
* Koustubh Masurkar      21 October 2021                Applied code scan suggestions
* Ashwin Kumar           15-Nov-2021                    INC0350488: Call Reprice webservice in queueable and update Quote when Config is empty
**/

global with sharing class ApttusQuoteLifeCycleCallBack implements Apttus_Proposal.CustomClass.IQuoteLifecycleCallback2{
    //private Apttus_Config2.ProductConfiguration cart=null; //Koustubh Masurkar      21 October 2021        Applied code scan suggestions
    public static Boolean isCloned = false;
     /**
     * Owner: Rahul Bishnoi
     * Callback invoked after a quote/proposal is cloned
     * @param originalSO the original quote sobject 
     * @param cloneSO the clone quote sobject
     */
    global void afterClone(Apttus_Proposal__Proposal__c originalSO, Apttus_Proposal__Proposal__c cloneSO) {
    }

    /**
     * Callback invoked after a quote/proposal is created from an account
     * @param quoteSO the new quote sobject 
     */
    global void afterCreateFromAccount(Apttus_Proposal__Proposal__c quoteSO) {
    }

     /**
     * Callback invoked after a quote/proposal is created from an opportunity
     * @param quoteSO the new quote sobject 
     */
    global void afterCreateFromOpportunity(Apttus_Proposal__Proposal__c quoteSO) {
    }

    /**
     * Callback invoked after an agreement is created from a quote/proposal
     * @param quoteSO the quote sobject 
     * @param agreementSO the new agreement sobject 
     */
    global void afterCreateAgreement(Apttus_Proposal__Proposal__c quoteSO, Apttus__APTS_Agreement__c agreementSO) {
    }

    /**
     * Callback invoked before a quote/proposal is cloned
     * @param originalSO the original quote sobject 
     * @param cloneSO the clone quote sobject
     */
    global void beforeClone(Apttus_Proposal__Proposal__c originalSO, Apttus_Proposal__Proposal__c cloneSO) {
    }
    
    /**
     * Callback invoked after the completion of a lifecycle action
     * @param quoteSO the quote sobject 
     * @PARAM actionType the lifecycle action type
     */
    global void afterComplete(Apttus_Proposal__Proposal__c quoteSO, Apttus_Proposal.CustomClass.ActionType actionType) {
        System.debug('Action Type -->> ' + actionType + ' isCLoned -->> ' + isCloned);
        if(actionType == Apttus_Proposal.CustomClass.ActionType.ACTION_CLONE){
            List<Apttus_Config2__ProductConfiguration__c> prodConfig = new ApttusProductConfigurationsSelector().selectProductConfigurationByQuotIds(new Set<ID> {quoteSO.id});
            if(prodConfig.isEmpty()) {
                quoteSO.Is_Reprice_Completed__c = true;
                update quoteSO;     //INC0350488
                return; 
            }
            System.debug('-->>config found: ' + prodConfig[0].id );
            
            List<Apttus_Config2__LineItem__c> lstLineItems =  new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<ID> {prodConfig[0].id});
            for(Apttus_Config2__LineItem__c lineItems: lstLineItems){
                lineItems.Apttus_Config2__ListPrice__c = null;
                lineItems.Apttus_Config2__NetPrice__c = null;
                lineItems.List_Price__c = null;
                lineItems.Apttus_Config2__BasePrice__c = null;
                lineItems.Apttus_Config2__BasePriceMethod__c = null;
                lineItems.Apttus_Config2__AdjustedPrice__c	 = null;
                lineItems.Apttus_Config2__NetUnitPrice__c	 = null;
                lineItems.Apttus_Config2__BasePriceOverride__c = null;
                lineItems.Apttus_Config2__ExtendedPrice__c = null;
                lineItems.Apttus_Config2__AdjustmentAmount__c = null;
                lineItems.Apttus_Config2__DeltaPrice__c = null;
                lineItems.Discounted_Price_Per_Unit__c = null;
                lineitems.Apttus_Config2__PricingStatus__c = 'Pending';
                lineitems.Apttus_Config2__AdjustmentType__c = null;
            }
            if(!lstLineItems.isEmpty()){
                update lstLineItems;
            }
            UtilsCart.doReprice(prodConfig[0].id);  //INC0350488
        }
   }
    
    /**
     * Callback invoked after the completion of a lifecycle action
     * @param agreementSO the agreement sobject 
     * @PARAM actionType the lifecycle action type
     */
    global void afterComplete(Apttus__APTS_Agreement__c agreementSO, Apttus_Proposal.CustomClass.ActionType actionType) {
    }
 }