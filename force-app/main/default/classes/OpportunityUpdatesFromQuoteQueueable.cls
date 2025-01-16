/**
*    @author Rishab Wali
*    @date   2021-03-16
*    @description    DCP-43259: Quote Improvements (Update Opportunity trigerred from Quote Updates)
*    @Test Class for 75% coverage -  TestOpportunityUpdateFromQuoteQueueable
*    @Test Class for 90% coverage -  TestOpportunityUpdateFromQuoteQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                         2021-03-16          Initial Version
*         Anshaj                         2022-09-14          CMSI-203 Instrumented Class for logging framework
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpportunityUpdatesFromQuoteQueueable implements Queueable{

private static final String LOG_TITLE = 'OpportunityUpdatesFromQuoteQueueable';
Map<Id,Apttus_Proposal__Proposal__c> newData = new Map<Id,Apttus_Proposal__Proposal__c>();
Map<Id,Apttus_Proposal__Proposal__c> oldData = new Map<Id,Apttus_Proposal__Proposal__c>();
public static Boolean catchException = false;

/*Paramterised Constructor */
public OpportunityUpdatesFromQuoteQueueable(Map<Id,Apttus_Proposal__Proposal__c> newMap , Map<Id,Apttus_Proposal__Proposal__c> oldMap) 
{
    this.newData = newMap;
    this.oldData = oldMap;
}

/*Queueable execute method */
public void execute(QueueableContext qc) { 
    try
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(newData.values() , 'Apttus_Proposal__Opportunity__c');
        //Map to store Related Opportunity
        Map<Id, Opportunity> idToOpportunity =  new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOpportunityIds));
        List<Opportunity> lstOppToUpdate = new List<Opportunity>();

        List<Apttus_Proposal__Proposal__c> allProposalsOfOpps = new List<Apttus_Proposal__Proposal__c>();
        ApttusProposalsSelector apttusPropSelector = new ApttusProposalsSelector();
        allProposalsOfOpps = apttusPropSelector.selectValidQuote(setOpportunityIds);
        Map<Id,Boolean> oppToIsStageInReviewMap = new Map<Id,Boolean>();

        for(Apttus_Proposal__Proposal__c prop : allProposalsOfOpps)
        {
            ilib_LogEvent.message('Quote Id in first for loop : '+prop.Id);
            if(prop.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageInReview)
            {
                oppToIsStageInReviewMap.put(prop.Apttus_Proposal__Opportunity__c,true);
            }
        }
        ilib_LogEvent.info('oppToIsStageInReviewMap : '+oppToIsStageInReviewMap);
        for(Apttus_Proposal__Proposal__c prop : newData.values())
        {
            ilib_LogEvent.message('Quote Id in second for loop : '+prop.Id);
            if(idToOpportunity.containsKey(prop.Apttus_Proposal__Opportunity__c)){
            Opportunity opp = idToOpportunity.get(prop.Apttus_Proposal__Opportunity__c);

            if(prop.Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageInReview 
                && oldData.get(prop.Id).Apttus_Proposal__Approval_Stage__c != System.Label.QuoteStageInReview)
            {
                if(opp.Is_Quote_Stage_In_Review__c == false && opp.Is_Updated_By_System__c == false)
                {
                    opp.Is_Quote_Stage_In_Review__c = true;
                    opp.Is_Updated_By_System__c = true;
                    lstOppToUpdate.add(opp);
                }
            }
            else if(prop.Apttus_Proposal__Approval_Stage__c != System.Label.QuoteStageInReview 
                    && oldData.get(prop.Id).Apttus_Proposal__Approval_Stage__c == System.Label.QuoteStageInReview 
                    && opp.Is_Quote_Stage_In_Review__c == true && !oppToIsStageInReviewMap.containsKey(opp.Id))
                    {
                        opp.Is_Quote_Stage_In_Review__c = false;
                        opp.Is_Updated_By_System__c = true;
                        lstOppToUpdate.add(opp);
                    }
        }
        }
        ilib_LogEvent.info('Opportunity Ids to be updated : '+UtilsCollection.getSetOfIds(lstOppToUpdate));
        if(!lstOppToUpdate.isEmpty())
        {
            update lstOppToUpdate;
            ilib_LogEvent.info('Updated Opportunity Records');
        }
        if(catchException == true){
            throw new AuraHandledException('throwing custom exception');
        }
    }
    catch(Exception e) { ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SALES); }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
}
}