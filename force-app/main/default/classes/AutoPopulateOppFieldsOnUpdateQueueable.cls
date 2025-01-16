/**
*    @author Bharath
*    @date   2021-03-16
*    @description    DCP-43259: Quote Improvements (Update Opportunity trigerred from Quote Updates)
*    @Test Class  -  TestAutoPopulateFieldsOnUpdateQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Bharath                        2021-03-16          Initial Version
*         Rishab                         2021-05-28          DCP-46204 Quote Optimization [Populate Proposal Sent On field on Generate]
*         Todd/Ashwin                    2021-11-30          INC0360847 - Break logics smaller and avoid cached Opportunity record update & update values tracked only in this class.
*         Avina                          2022-07-04          CMSI-91 Added Instrumentation
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AutoPopulateOppFieldsOnUpdateQueueable implements Queueable {
    
    private static final String LOG_TITLE = 'AutoPopulateOppFieldsOnUpdateQueueable';//CMSI-91
    private static final String EXCEPTION_LOG_TITLE = 'AutoPopulateOppFieldsOnUpdateQueueable';
    List<Apttus_Proposal__Proposal__c> lstProposals;
    public Map<Id, Opportunity> idToStaleOpportunity;
    public boolean boolIsInsert;

    /*Paramterised constructor */
    public AutoPopulateOppFieldsOnUpdateQueueable(Map<Id, Opportunity> idToStaleOpportunity, Map<Id, Apttus_Proposal__Proposal__c> idToProposal, Boolean boolIsInsert)
    {
        this.idToStaleOpportunity = idToStaleOpportunity;
        this.lstProposals = idToProposal.values(); // this class doesn't need the map, just the values
        this.boolIsInsert = boolIsInsert;
    }

    /*Queueable execute method */
    public void execute(QueueableContext qc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);//CMSI-91
        ilib_LogEvent.push(LOG_TITLE + '.execute()');//CMSI-91
        try {
            updateOpportunities();
        } catch(Exception e) {
            ApexExceptions.emit(EXCEPTION_LOG_TITLE, e);
        }
        ilib_LogEvent.pop();//CMSI-91
        ilib_LogEvent.emit();//CMSI-91
    }

    /* execute logic, all inside try/catch */
    private void updateOpportunities()
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateRQContactCompliant()');//CMSI-91
        Map<Id, Opportunity> idToUpdatedOpportunity = new Map<Id, Opportunity>();

        for (Apttus_Proposal__Proposal__c prpsl : lstProposals)
        {
            if (!idToStaleOpportunity.containsKey(prpsl.Apttus_Proposal__Opportunity__c)) {
                continue;
            }

            Opportunity staleOpportunity = idToStaleOpportunity.get(prpsl.Apttus_Proposal__Opportunity__c);

            Opportunity updatedOpportunity = idToUpdatedOpportunity.get(staleOpportunity.Id);
            if (updatedOpportunity == null) {
                updatedOpportunity = new Opportunity(Id = staleOpportunity.Id);  //INC0360847
            }

            // stamp first proposal ID if has not been done before
            if (boolIsInsert && staleOpportunity.First_Proposal_Id__c == null) {
                updatedOpportunity.First_Proposal_Id__c = prpsl.Id;
            }

            // stamp proposal sent date if the user sent the generated doc
            if (!boolIsInsert && isQuotePresented(prpsl)) {
                updatedOpportunity.ByPass_LockSentProposalDate__c = true;
                updatedOpportunity.Proposal_Sent_On__c = prpsl.Apttus_Proposal__Presented_Date__c;
            }

            // stamp proposal sent date if the system auto-generated and emailed the doc
            if (!boolIsInsert && isQuoteAutoEmailed(staleOpportunity, prpsl)) { //DCP-46204
                updatedOpportunity.ByPass_LockSentProposalDate__c = true;
                updatedOpportunity.Proposal_Sent_On__c =  System.Today();
            }

            idToUpdatedOpportunity.put(updatedOpportunity.Id, updatedOpportunity);
        }
        ilib_LogEvent.info('idToUpdatedOpportunity-->: '+idToUpdatedOpportunity);//CMSI-91
        updateOppValues(idToUpdatedOpportunity.values());
        ilib_LogEvent.pop();//CMSI-91
    }

    /* if sales user manually sent doc from Salesforce which stamps the proposal date */
    private Boolean isQuotePresented(Apttus_Proposal__Proposal__c prpsl)
    {
        ilib_LogEvent.message('prpsl-->: '+prpsl);//CMSI-91
        return prpsl.Apttus_Proposal__ReadyToPresent__c
            && prpsl.Apttus_Proposal__Presented_Date__c != null 
            && prpsl.Apttus_Proposal__Approval_Stage__c == ApttusProposals.QUOTE_STAGE_PRESENTED;
    }

    /* if after approval the doc was auto-generated and emailed to the sales user */
    private Boolean isQuoteAutoEmailed(Opportunity opp, Apttus_Proposal__Proposal__c prpsl)
    {
        ilib_LogEvent.message('opp-->: '+opp);//CMSI-91
        ilib_LogEvent.message('prpsl-->: '+prpsl);//CMSI-91
        return (prpsl.Apttus_Proposal__Approval_Stage__c == ApttusProposals.QUOTE_STAGE_GENERATED
            || (
                prpsl.Apttus_Proposal__Approval_Stage__c == ApttusProposals.QUOTE_STAGE_PRESENTED 
                && opp.Proposal_Sent_On__c == null 
                && opp.StageName != ApttusProposals.OPPORTUNITY_STAGE_CREATE
            )
        );
    }

    /* Update Opportunity Values */
    private void updateOppValues(List<Opportunity> updatedOpportunities) {
        ilib_LogEvent.push(LOG_TITLE + '.updateOppValues()');//CMSI-91
        ilib_LogEvent.info('updatedOpportunities-->: '+UtilsCollection.getSetOfIds(updatedOpportunities));//CMSI-91
        
        if(!updatedOpportunities.isEmpty()) {
            update updatedOpportunities;
        }
        ilib_LogEvent.pop();//CMSI-91
    }

}