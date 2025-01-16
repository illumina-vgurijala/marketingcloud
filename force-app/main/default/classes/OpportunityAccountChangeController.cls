/**
* @author Akash Kumar
* @date :   2018-08-22
* @description :   US-9539: Controller class for the VisualForce Email Template Component
* TEST CLASS  for 75% coverage : TestUpdateQuoteFieldsFromOppQueueable  
* TEST CLASS  for 90% coverage : TestUpdateQuoteFieldsFromOppQueueable 
* Modification Log:
* ------------------------------------------------------------------------------------ 
*       Akash Kumar         2018-10-07            Original Version
*       Jitesh Lakhwani     6-July-2022           Code Scan fixes of Comments
* ------------------------------------------------------------------------------------    
*/
public with sharing class OpportunityAccountChangeController {
    
    
    public String strOppId{get;set;}
    
    /**
    * @description: This will return the list of quotes which are in denied state/status
    * @param : None
    * @return : List<Apttus_Proposal__Proposal__c> : List of Proposals
    **/
    public List<Apttus_Proposal__Proposal__c> getlstDeniedQuotes(){

        System.debug('strOppId--->' +strOppId);

        Set<String> setDeniedToStages = new Set<String>{Label.QuotationApprovalStatusApproved,
                                                    Label.QuoteStageGenerated,
                                                    Label.QuoteStagePresented};

        List<Apttus_Proposal__Proposal__c> lstDeniedQuote = new List<Apttus_Proposal__Proposal__c>();

        for(Apttus_Proposal__Proposal__c objProposal : new ApttusProposalsSelector().selectValidQuote(new Set<Id>{strOppId})){
            if(setDeniedToStages.contains(objProposal.Apttus_Proposal__Approval_Stage__c))
                lstDeniedQuote.add(objProposal);
        }
     return lstDeniedQuote;
     }

    /**
    *  @description: This will return the list of quotes which are in draft state/status
    * @param : None
    * @return : List<Apttus_Proposal__Proposal__c> : List of Proposals
    **/
     public List<Apttus_Proposal__Proposal__c> getlstDraftQuotes(){

        System.debug('strOppId--->' +strOppId);

        Set<String> setDraftToStages = new Set<String>{Label.QuoteStageApprovalRequired,
                                                    Label.QuoteStageDraft};
                                                    

        List<Apttus_Proposal__Proposal__c> lstDraftQuote = new List<Apttus_Proposal__Proposal__c>();

        for(Apttus_Proposal__Proposal__c objProposal : new ApttusProposalsSelector().selectValidQuote(new Set<Id>{strOppId})){
            if(setDraftToStages.contains(objProposal.Apttus_Proposal__Approval_Stage__c))
                lstDraftQuote.add(objProposal);
        }
     return lstDraftQuote;
     }
}