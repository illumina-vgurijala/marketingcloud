/**
*   @author Satya Swain
*   @date   2022-08-17
*   @description : TASK0799027 : This platform event trigger handler class is introduced to handle business logic execution that 
*   takes place when finalization of cart takes place and there are more than 200+ lines. Logic is separated from Queueable which 
*   fires twice when 200+ quotation line items are getting inserted. 
*   Test class for 90%+ coverage : TestApttusProposalLineItemsOpenOffer
*   Test class for 75%+ coverage : TestApttusProposalLineItemsOpenOffer
*   Modification Log:
*   ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*        Satya Swain                  2022-08-17           Initial Version
*   ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpenOfferQuotationUpdatesAsync implements ilib_AdminOperationLogicInterface {
    private static final String LOG_TITLE = 'OpenOfferQuotationUpdatesAsync';
    
    /**
     *  @author       : Satya Swain
     *  @description  : Update open offer quote fields using platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstQuotationLineItemIds) {
        ilib_LogEvent.rootTitle = LOG_TITLE;  
        ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');
        Map<Id,Id> mapLineItemIdtoQuoteId = new Map<Id,Id>();
        
        for(Apttus_Proposal__Proposal_Line_Item__c objQuotationLineItem : new ApttusProposalLineItemsSelector().fetchQuotationLineItemById(new Set<Id>(lstQuotationLineItemIds))) {
            if(!mapLineItemIdtoQuoteId.containsKey(objQuotationLineItem.Apttus_QPConfig__DerivedFromId__c)) { //DCP-53938
                mapLineItemIdtoQuoteId.put(objQuotationLineItem.Apttus_QPConfig__DerivedFromId__c,objQuotationLineItem.Apttus_Proposal__Proposal__c);
            }
        }

        // Reuse the same logic except this time it will be in platform event context
        if(!mapLineItemIdtoQuoteId.isEmpty()) {
            new OpenOfferQuotationUpdatesHelper().evaluateOpenOfferLogic(mapLineItemIdtoQuoteId);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}
