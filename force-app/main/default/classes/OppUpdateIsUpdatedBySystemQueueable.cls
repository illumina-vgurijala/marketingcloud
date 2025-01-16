/**
*    @author Rishab Wali
*    @date   2021-03-31
*    @description    DCP-45454: Opportunity Improvements (Update Field Reason for backward movement and is updated by system)
*    @90% Test Classes  -  TestOppUpdateIsUpdatedBySystemQueueable,TestApttusOrderLineItems, TestAutoPopulateFieldsOnUpdateQueueable, TestCustomerMasterDataSelectionCntrl,TestOpportunityUpdatesFromQuoteQueueable, TestSubmitForApprovalEmail
*    @75% Test Classes  -  TestApttusOrderLineItems, TestAutoPopulateFieldsOnUpdateQueueable, TestCustomerMasterDataSelectionCntrl,TestOpportunityUpdatesFromQuoteQueueable, TestSubmitForApprovalEmail,TestOppUpdateIsUpdatedBySystemQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                         2021-03-31          Initial Version
*         Biswajeet                      2022-08-22          [CMSI-200] : Instrumentation of the class
*         Nishan Shetty                  02-Sept-2022        DCP-53823 Added Null Check for opportunityOldMap  and Exception Handling with Related Records.
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OppUpdateIsUpdatedBySystemQueueable implements Queueable{
    
    private static final String EXCEPTION_LOG_TITLE = 'OppUpdateIsUpdatedBySystemQueueable';
    List<Opportunity> oppList = new List<Opportunity>();
    Map<Id,Opportunity> opportunityOldMap = new Map<Id,Opportunity>();
    Map<Id,Opportunity> opportunityNewMap = new Map<Id,Opportunity>();
    public static final string OPPSTAGECLOSEDWON  = 'Closed Won';
    public static final string OPPSTAGECLOSEDLOST  = 'Closed Lost';
    public static final string OPPSTAGECLOSEDABANDONED  = 'Closed Abandoned';
    public static final string OPPSTAGEFINALISE = 'Finalize';
    public static final string OPPSTAGECREATE = 'Create';
    public static final string OPPSTAGENEGOTIATE = 'Negotiate & Resolve';
    public static final string OPPSTAGEPROVE = 'Prove';
    public static final string OPPSTAGEDEVELOP= 'Develop';
    public static final string OPPSTAGEQUALIFY= 'Qualify';
    private static Map<Id, Schema.RecordTypeInfo> idToRecordType;
    public static Boolean catchException = false;  //CMSI-200 catch block coverage

    /* Method to get recordId map*/ 
    public static Map<Id, Schema.RecordTypeInfo> getIdToRecordType()
    {
        if (idToRecordType == null) {idToRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();}
        return idToRecordType;
    }

    
    /*Parameterised Constructor */
    public OppUpdateIsUpdatedBySystemQueueable(List<Opportunity> lstOpportunity, Map<Id,Opportunity> oldMap , Map<Id,Opportunity> newMap) {
        this.oppList = lstOpportunity;
        this.opportunityOldMap = oldMap;
        this.opportunityNewMap = newMap;
    }
    
    /*Queueable execute method */
    public void execute(QueueableContext qc) { 
        ilib_LogEvent.setTitle(EXCEPTION_LOG_TITLE, ilib_LogEvent.SALES); //CMSI-200
        ilib_LogEvent.push(EXCEPTION_LOG_TITLE+'.execute()'); //CMSI-200
        List<Opportunity> opportunityList = new List<opportunity>();
        try
        {
           
            for(Opportunity opp : oppList)
            {
                Opportunity updateOpp = new Opportunity(Id = opp.Id);
                if(opp.Is_Updated_By_System__c)
                {
                    updateOpp.Is_Updated_By_System__c = false;
                }
                if(opportunityOldMap!=null && opportunityOldMap.containsKey(opp.Id) && opportunityNewMap.containsKey(opp.Id) && //DCP-53823
                  blankOutReasonForMovingBackward(opportunityOldMap.get(opp.Id),opportunityNewMap.get(opp.Id)))
                {
                    updateOpp.Reason_for_Moving_Backwards__c = '';
                }
				if(opp.ByPass_LockSentProposalDate__c)
                {
                    updateOpp.ByPass_LockSentProposalDate__c = false;
                }
                if(opp.ByPass_Change_Record_Type_To_Standard__c)
                {
                    updateOpp.ByPass_Change_Record_Type_To_Standard__c = false;
                }
                opportunityList.add(updateOpp);
            }

            if(!opportunityList.isEmpty())
            {
                ilib_LogEvent.info('List of opportunities :'+opportunityList); //CMSI-200
                update opportunityList;
            }
            //code coverage for catch block CMSI-200
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }
            ilib_LogEvent.pop(); //CMSI-200
        }
        catch(Exception e) { 
            ApexExceptions.emit(e,EXCEPTION_LOG_TITLE,(List<SObject>)opportunityList,ilib_LogEvent.SALES); //DCP-53823
        }
        ilib_LogEvent.emit(); //CMSI-200
    }
    
    /* Method to blank out reason for moving backward*/
    public static boolean blankOutReasonForMovingBackward(Opportunity oldOpp , Opportunity newOpp)
    {
        if(newOpp.StageName == OPPSTAGECLOSEDWON || newOpp.StageName == OPPSTAGECLOSEDLOST || newOpp.StageName == OPPSTAGECLOSEDABANDONED 
          || String.isBlank(newOpp.Reason_for_Moving_Backwards__c) || newOpp.StageName == oldOpp.StageName)
        {
            return false;
        }

        if(checkStandardRT(oldOpp, newOpp))
        {
            return true;
        }

        if(getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectReOrder 
        || getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.IndirectReOrder
        || getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.FieldServices 
        || getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.IndirectFieldServices )
        {
            if(oldOpp.StageName == OPPSTAGEFINALISE || (oldOpp.StageName == OPPSTAGEDEVELOP && newOpp.StageName != OPPSTAGEFINALISE))
            {
                return true;
            }
        }
        return false;
    }

    /* method to check standard RT*/
    private static boolean checkStandardRT(Opportunity oldOpp, Opportunity newOpp) 
    {
        Boolean retValue = false;
        if(getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectStandard 
          || getIdToRecordType().get(newOpp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTIndirectStandard)
          {
              if((oldOpp.StageName == OPPSTAGEFINALISE || (oldOpp.stageName == OPPSTAGENEGOTIATE && newOpp.stageName != OPPSTAGEFINALISE) 
              || (oldOpp.StageName == OPPSTAGEPROVE && newOpp.stageName != OPPSTAGENEGOTIATE && newOpp.stageName != OPPSTAGEFINALISE)
              || (oldOpp.StageName == OPPSTAGEDEVELOP && newOpp.stageName != OPPSTAGEPROVE && newOpp.stageName != OPPSTAGENEGOTIATE 
                  && newOpp.stageName != OPPSTAGEFINALISE)
              || (oldOpp.StageName == OPPSTAGEQUALIFY && newOpp.StageName != OPPSTAGEDEVELOP && newOpp.stageName != OPPSTAGEPROVE && newOpp.stageName != OPPSTAGENEGOTIATE 
              && newOpp.stageName != OPPSTAGEFINALISE)) && newOpp.StageName != OPPSTAGECREATE)
            {
                retValue = true;
            }
          }
          ilib_LogEvent.info('ret Value :'+retValue); //CMSI-200
          return retValue;
    }

}