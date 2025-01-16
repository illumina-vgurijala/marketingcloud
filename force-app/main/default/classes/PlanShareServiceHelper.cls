/**
 *    @author KD
 *    @date   9-Sept-2020
 *    @description : Queueable Service Handler class  to share plan records
 * 
 *    90% Code Coverage : TestPlanShareServiceHelper.
 *    75% Code Coverage : TestPlanShareServiceHelper.
 * 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Adyasha                   06-December-2021      Added recalculateObjectiveOpportunityAssociationSharing
 *    Sibin P Kuriakose               19-Sep-2022        [CMSI-213] Instrumentation of the class.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PlanShareServiceHelper implements Queueable{
    public Set<Id> setPlanId = new  Set<Id>();
    public List<Plan__c> lstPlanToShare = new List<Plan__c>();
    public static Boolean catchException = false;
    public static final String LOG_TITLE = 'PlanShareServiceHelper'; //CMSI-213
    /**
     * @author KD
     * @date   6-Spt-2020
     * @description  Constructor
     * @param List of plan records to re-share
     */
    public PlanShareServiceHelper(List<Plan__c> lstPlans){
        this.lstPlanToShare = lstPlans;
        this.setPlanId = UtilsCollection.getSetOfIds(lstPlans,'Id');
    }
    /**
     * @author KD
     * @date   6-Spt-2020
     * @description  Execute method of Queueable
     * @param QueueableContext
     */
    public void execute(QueueableContext context){
      ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES); //CMSI-213
      ilib_LogEvent.push(LOG_TITLE+'.execute()'); //CMSI-213
      try{
        List<Plan__share> lstPlanShare =new PlanShareSelector().getShareRecordsWithParentId(setPlanId,Schema.Plan__Share.RowCause.Manual);
        PlanShareService.deleteExistingSharing(lstPlanShare);
        ilib_LogEvent.info('lstPlanShare :' + lstPlanShare); //CMSI-213
        reCalculateSharing(lstPlanToShare);
        //Added as part of DCP-50392
        ilib_LogEvent.info('Plan Ids :' + setPlanId); //CMSI-213
        recalculateObjectiveOpportunityAssociationSharing(setPlanId);
        // End of DCP-50392
         //code coverage for catch block
        if(catchException == true){
          throw new AuraHandledException('throwing custom exceptions');
        }
      }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('PlanShareServiceHelper', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
      ilib_LogEvent.pop(); //CMSI-213
      ilib_LogEvent.emit(); //CMSI-213
    }
    /**
     * @author KD
     * @date   6-Spt-2020
     * @description  DCP-39107 Recalculatr sharing
     * @param List of plan records to re-share
     */
    public static void reCalculateSharing(List<Plan__c> lstPlans){
        ilib_LogEvent.push(LOG_TITLE+'reCalculateSharing()'); //CMSI-213
        PlanShareService.sharePlanRecords(lstPlans);
        ilib_LogEvent.pop(); //CMSI-213
    }

    /**
     * @author Adyasha
     * @date   06-Dec-2021
     * @description  DCP-50392 : Recalculate objective opportunity association sharing
     * @param List of plan records to re-share
     */
    public static void recalculateObjectiveOpportunityAssociationSharing(Set<Id> setPlanId) {
        ilib_LogEvent.push(LOG_TITLE+'recalculateObjectiveOpportunityAssociationSharing()'); //CMSI-213
        List<Objective_Opportunity_Relationship__Share> lstRelationshipShare = new ObjectiveOppRelationshipShareSelector().getShareRecordsWithParentPlanId(setPlanId,Schema.Objective_Opportunity_Relationship__Share.RowCause.Manual);
        Set<Id> relationshare = UtilsCollection.getSetOfIds(lstRelationshipShare, 'Plan__c'); //CMSI-213
        ilib_LogEvent.info('list of relationship shared: '+relationshare); //CMSI-213
        ObjectiveOppRelationshipShareService.deleteObjectiveOpportunityRelationshipShares(lstRelationshipShare);
        
        List<Objective_Opportunity_Relationship__c> relationship = new ObjectiveOpportunityRelationshipSelector().selectAssociationByPlanIds(setPlanId,true);
        
        ilib_LogEvent.info('PlanIds: '+ UtilsCollection.getSetOfIds(relationship, 'Plan__c')); //CMSI-213
        ObjectiveOppRelationshipShareService.sharePlanObjectiveOppRecords(UtilsCollection.getMapOfIdToSObjects(relationship,'Plan__c'));
        ilib_LogEvent.pop(); //CMSI-213
    }    
}
