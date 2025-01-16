/**
*    @author Rishab Wali
*    @date   2021-03-22
*    @description    DCP-45455: Opportunity Improvements (Update Quote Fields trigerred from Opp Updates)
*    @Test Class  -  TestUpdateQuoteFieldsFromOppQueueable
*    90% code coverage test class : TestUpdateQuoteFieldsFromOppQueueable
*    75% code coverage test class : TestUpdateQuoteFieldsFromOppQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                         2021-03-16          Initial Version
*         Biswajeet                      2022-08-23          [CMSI-201] Instrumentation of class
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class UpdateQuoteFieldsFromOppQueueable implements Queueable{
    
    private static final String EXCEPTION_LOG_TITLE = 'UpdateQuoteFieldsFromOpportunityQueueable';
    private static final String LOG_TITLE = 'UpdateQuoteFieldsFromOppQueueable';
    Set<Id> oppIdSet = new Set<Id>();
    public static Boolean catchException = false;

    /*Parameterised Constructor */
    public UpdateQuoteFieldsFromOppQueueable(Set<Id> opportunityIdSet) {
        this.oppIdSet = opportunityIdSet;
    }

    /*Queueable execute method */
    public void execute(QueueableContext qc) { 
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);      //CMSI-201
        ilib_LogEvent.push(LOG_TITLE+'.execute()');               //CMSI-201
        try
        {
            List<Apttus_Proposal__Proposal__c> lstProposals = new List<Apttus_Proposal__Proposal__c>(new ApttusProposalsSelector().selectValidQuote(oppIdSet));
            
            for(Apttus_Proposal__Proposal__c propsl : lstProposals)
            {
                propsl.Apttus_Proposal__Primary__c = false;
                propsl.Invalid_Quote__c = true;
                propsl.Apttus_Proposal__Approval_Stage__c='Denied';
            }

            update lstProposals;
            ilib_LogEvent.info('List Proposals :'+UtilsCollection.getSetOfIds(lstProposals));    //CMSI-201
            
            //covering catch block  CMSI-201
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }

            ilib_LogEvent.pop();  //CMSI-201
        }
        catch(Exception e) { 
            ApexExceptions.emit(EXCEPTION_LOG_TITLE, e,ilib_LogEvent.SALES); //CMSI-201 Added workstream
            ilib_LogEvent.pop();  //CMSI-201
            ilib_LogEvent.emit();   //CMSI-201
        }

        ilib_LogEvent.emit();   //CMSI-201
    }

}