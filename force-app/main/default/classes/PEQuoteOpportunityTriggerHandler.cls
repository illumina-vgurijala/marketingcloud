/**
*    @author Vinay S Reddy
*    @date   2023-12-10
*    @description    CMCM-1036 platform event trigger handler class 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Vinay S Reddy                12 Oct 2023           Apex Class to handle Platform event
   ----------------------------------------------------------------------------------- 
*                    
*/
public with sharing class PEQuoteOpportunityTriggerHandler extends ilib_SObjectDomain {

    private static final String LOG_TITLE = 'PEQuoteOpportunityTriggerHandler'; 
    private static final String COMPLETED = 'Completed';
    private static final Integer THREE = 3;
    private static final Boolean STATUSFLAGFORTEST=false;
    private static Integer i=0;
    
    /* Constructor
    */
    public PEQuoteOpportunityTriggerHandler(List<ProcessQuotesOnOpportunityClose__e> sObjectList) {
        super(sObjectList);   
        // setting workstream
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);  
    }
    /*
        * Boilerplate which is required for base class instantiation logic
        */
        public class Constructor implements ilib_SObjectDomain.IConstructable {
            /*Method Param - List<sObject> */
            public ilib_SObjectDomain construct(List<SObject> sObjectList) {
              return new PEQuoteOpportunityTriggerHandler(sObjectList);
            }
        }
    /**Method to handle the platform event
     * 
     */
    public override void onAfterInsert()
    {   ilib_LogEvent.push(LOG_TITLE + '.execute()');
        List<Apttus_Proposal__Proposal__c> quoteRecall2 = new List<Apttus_Proposal__Proposal__c>();
        List<Apttus_Proposal__Proposal__c> quoteRecall1 = new List<Apttus_Proposal__Proposal__c>();
        Integer iteration;
    
        List<ProcessQuotesOnOpportunityClose__e> evtList = (List<ProcessQuotesOnOpportunityClose__e>)Trigger.New;
        List<String> queryQuoteList=new List<String>();
        for(ProcessQuotesOnOpportunityClose__e temp5:evtList)
        {
            String localVar;
            localVar =temp5.oppId__c;
            queryQuoteList.add(localVar);
        }
            ilib_LogEvent.message('List is '+queryQuoteList);
            List<Apttus_Proposal__Proposal__c> lstquoteRecordofClosedOpp =[Select Id,Apttus_Proposal__Approval_Stage__c,Is_Updated_By_System__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Opportunity__r.StageName From Apttus_Proposal__Proposal__c Where Apttus_Proposal__Opportunity__c IN :queryQuoteList]; 
    
        for(Apttus_Proposal__Proposal__c eventCMCM:lstquoteRecordofClosedOpp){
            if(eventCMCM.Apttus_Proposal__Approval_Stage__c==Label.QuoteStageInReview){
            Apttus_Proposal__Proposal__c temp1=new Apttus_Proposal__Proposal__c() ;
            temp1.Id=eventCMCM.Id;
            temp1.Is_Updated_By_System__c = true;
            quoteRecall1.add(temp1);}
    
        }
            ilib_LogEvent.message('List of affected Quotes is '+quoteRecall1);
            update quoteRecall1; 
    
    
        for(Apttus_Proposal__Proposal__c eventCMCM:lstquoteRecordofClosedOpp){
    
             if(eventCMCM.Apttus_Proposal__Approval_Stage__c==Label.QuoteStageInReview)
             {
                    Boolean status=Apttus_Approval.ApprovalsWebService.cancelApprovalsWithComments('Apttus_Proposal__Proposal__c', eventCMCM.Id,'Recalling the Quotes because Opportunity is Closed Lost/Closed Abondoned');
                    ilib_LogEvent.message('Status of approval cancel '+status);
                    Apttus_Proposal__Proposal__c temp1=new Apttus_Proposal__Proposal__c() ;
                    temp1.Id=eventCMCM.Id;
                    temp1.Apttus_Proposal__Approval_Stage__c=Label.QuoteStageDraft;
    
             for(iteration=0;iteration<3;iteration ++){
    
                Apttus_Config2.CPQStruct.JobInfo parentJobInfo = Apttus_CPQAPI.BatchUpdateService.getBatchJobInfoForContext (eventCMCM.Id);
                boolean returnflag= methodToCheckQuotetoRecall(parentJobInfo.status,STATUSFLAGFORTEST);
    
                 if(returnflag){
                         quoteRecall2.add(temp1);
                        ilib_LogEvent.message('Break after adding proposal record into list for update');
                        break;
                 } else{
                     i=i+1;
                 }
    
            }
    
            }
    
         }
                        ilib_LogEvent.message('List of affected Quotes is '+quoteRecall2);
                        if(i==THREE){
                            ilib_LogEvent.info('Exception:Quote Record is not recalled');
                        }
                        else{
                            update quoteRecall2;
                        }    
                            ilib_LogEvent.pop();
                            ilib_LogEvent.emit(); 
    
    }
    /**Method to check job status 
     * 
     */
    public static Boolean methodToCheckQuotetoRecall(String jobStatus,Boolean testStatusFlag)
    {
       if((Test.isRunningTest() && !testStatusFlag) ||   jobStatus==COMPLETED){
            return True; 
        }
    
        else {	    
            Long startTime = DateTime.now().getTime();
            Long finishTime = DateTime.now().getTime();                
    
            while((finishTime-startTime)<3000){
                        //sleep for three seconds
                        ilib_LogEvent.message('(finishTime - startTime) : '+(finishTime-startTime));
                        finishTime = DateTime.now().getTime();
    
        }
            return False;
    }     
    
    }
    
    }