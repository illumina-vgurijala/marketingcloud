/**
*    @author Rishab Wali
*    @date   2021-03-16
*    @description    DCP-45453: Quote Improvements (Update Is Updated By System)
*    @Test Class for 75% coverage -  TestOpportunityUpdateFromQuoteQueueable
*    @Test Class for 90% coverage -  TestOpportunityUpdateFromQuoteQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                         2021-03-16          Initial Version
*         Anshaj                         2022-09-14          CMSI-203 Instrumented Class for logging framework
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class QuotationIsUpdatedBySystemQueueable implements Queueable{
    
    private static final String LOG_TITLE = 'QuotationIsUpdatedBySystemQueueable';
    set<Id> proposalIdSet = new Set<Id>();
    public static Boolean catchException = false;


    /*Paramterised Constructor */
    public QuotationIsUpdatedBySystemQueueable(Set<Id> propIdSet) {
        this.proposalIdSet = propIdSet;
    }

/*Queueable execute method */
public void execute(QueueableContext qc) { 
    try
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
        List<Apttus_Proposal__Proposal__c> updatedprpslList = new List<Apttus_Proposal__Proposal__c>();
        ApttusProposalsSelector apttusPropSelector = new ApttusProposalsSelector();
        proposalList = apttusPropSelector.selectByQuoteId(proposalIdSet);
        if(!proposalList.isEmpty()){
            for(Apttus_Proposal__Proposal__c prpsl : proposalList)
            {
                ilib_LogEvent.message('Quote Id in for Loop : '+prpsl.Id);
                if(prpsl.Is_Updated_By_System__c)
                {
                    ilib_LogEvent.message('Inside If Loop');
                    prpsl.Is_Updated_By_System__c = false;
                    ilib_LogEvent.message('prpsl.Is_Updated_By_System__c = false');
                    updatedprpslList.add(prpsl);
                }
            }
			if(!updatedprpslList.isEmpty())
			{
                ApttusProposals.boolRecursiveCheck = true;
				update updatedprpslList;
                ilib_LogEvent.info('Updated Quotation Records Ids : '+UtilsCollection.getSetOfIds(updatedprpslList));
			}
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