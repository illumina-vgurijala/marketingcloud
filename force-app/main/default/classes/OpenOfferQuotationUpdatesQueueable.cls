/**
*    @author Nesar Mohan
*    @date   2022-06-02
*    @description  DCP-53938: Queueable class to call ApttusProposalLineItemsHelper from onAfterInsert() context of ApttusProposalLineItems.cls
*    This class is created to replace ApttusProposalLineItemsQueueable to make it Open Offer Quotation specific
*    Test class for 90%+ coverage : TestApttusProposalLineItemsOpenOffer
*    Test class for 75%+ coverage : TestApttusProposalLineItemsOpenOffer
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*        Nesar Mohan                  2022-06-02           Initial Version
*        Satya Swain                  2022-08-23           TASK0799027 : Created the class for Open offer specific activities
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpenOfferQuotationUpdatesQueueable implements Queueable {
    
    String strMethodtoExecute;
    Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>> mapQuoteIDtoInfoOO = new Map<Id,List<Apttus_Proposal__Proposal_Line_Item__c>>();
    Map<Id,Id> mapLineItemIdtoQuoteId = new Map<Id,Id>();

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Constructor to initialize the method name to invoke and the data to operate on
    *  @PARAM :         String, Map<Id,Id>
    *  @RETURN:         void
    */
    public OpenOfferQuotationUpdatesQueueable(String strMethodtoExecute , Map<Id,Id> mapLineItemIdtoQuoteId) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.mapLineItemIdtoQuoteId = mapLineItemIdtoQuoteId;
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Execute method to call the helper class method based on the invokation
    *  @PARAM :         QueueableContext qc
    *  @RETURN:         void
    */
    public void execute(QueueableContext qc) {
        if(strMethodtoExecute=='evaluateOpenOfferLogic' && !mapLineItemIdtoQuoteId.isEmpty()) {
            new OpenOfferQuotationUpdatesHelper().evaluateOpenOfferLogic(mapLineItemIdtoQuoteId);        
        }
    }
}
