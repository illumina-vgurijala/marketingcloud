/**
 *    @author Anisha Bharti
 *    @date   13-Jul-2020
 *    @description : Selector class for Plan__c object.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    KD                            7-Aug-2020           
 *    Anisha Bharti                 10-Aug-2020
 *    KD                            21-Aug                  DCP-39768 : added method to query active plan in territory  
 *    KD                            31-Aug-2020             DCP-40334  : Updated getPlanbyTerritoryCode to getPlanbyTerritoryCodeStatus method 
 *    KD                            4-Sept-2020             Added Plan_Owner_Name__c field  
 *    KD                            9-Sept-2020             DCP-39107 : Added getAllPlanbyOwnerandRecordId method 
 *    KD                            17-Sept                 DCP-39967 : Plan CLone  
 *    KD                            24-Sept-2020            DCP-39951 : Admin layout
 *    Prem Ranjan                   19/11/2021              DCP-50569 : Added getPlanWithoutAttachment
 *    Ashwin                        1-July-2022             TASK0769726 : Removed Reviewed_by_Sales_Leader__c
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public with sharing class PlanSelector extends ilib_SObjectSelector {

    public static final String STATUSACTIVE = Label.PlanStatusActive;
    public static final String STATUSDRAFT = Label.PlanStatusDraft;
    public static Id idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Overlay_Plan').getRecordTypeId();
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Plan__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Plan__c.id,
            Plan__c.Name,
            Plan__c.Territory_Name__c,
            Plan__c.Territory_Id__c,
            Plan__c.LastModifiedById,
            Plan__c.Status__c,
            Plan__c.Channel_Partner__c,
            Plan__c.Territory_Code__c,
            Plan__c.OwnerId,
            Plan__c.Plan_Target__c,
            Plan__c.Start_Date__c,
            Plan__c.Plan_Owner_Name__c,
            // DCP-39967 : Plan CLone
            Plan__c.RecordTypeId,
            Plan__c.Opportunities__c,
            Plan__c.Reviewed_by_PAM__c,
            Plan__c.Strengths__c,
            Plan__c.Threats__c,
            Plan__c.Weaknesses__c,
            Plan__c.Regional_Strategic_Summary__c,
            Plan__c.End_Date__c,
            Plan__c.Channel_Partner_Territory_Code__c,
            Plan__c.Gap_Analysis__c,
            Plan__c.Core_Consumables__c,
            Plan__c.Library_Prep__c,
            Plan__c.NovaSeq_System__c,
            Plan__c.NextSeq_System__c,
            Plan__c.MiSeq_System__c,
            Plan__c.Mini_iSeq__c,
            Plan__c.Software_Informatics__c,
            Plan__c.Professional_Services_Service_Contract__c,
            Plan__c.Other__c,
            Plan__c.Percent_of_Upside__c,
            Plan__c.Percent_of_Not_Forecasted__c,
            Plan__c.Percent_of_Create__c,
            Plan__c.Est_Run_Rate__c
        }; 
    }
    /*  
    * @description  Related select field
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Owner.Name')
            .selectField('Channel_Partner__r.Name')
            .selectField('RecordType.Name')
            .selectField('RecordType.DeveloperName');
    }

    private Boolean removeDefaultOrderBy=false;
    /*  
    * @description  Override Default ordering 
    */
    public override String getOrderBy()
    {
        if(removeDefaultOrderBy)
            return 'Status__c DESC, LastModifiedDate DESC';  
        else 
            return super.getOrderBy(); 
    }
    /**
     * @author 
     * @date  
     * @description  get plan records using territory Plan Id
     * @param 
     */
    public List<Plan__c> getTerritoryPlanbyId(String strTerritoryPlanId) {
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('id = :strTerritoryPlanId ')
            .toSOQL());
    }
    /**
     * @author KD
     * @date   6-Aug-2020
     * @description  DCP-39561 get plan records using territory code
     * @param Account Id
     */
    public List<Plan__c> getPlanbyTerritoryCodeStatus(String strTerritoryCode,String strStatus) {
        removeDefaultOrderBy = TRUE;
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Territory_Code__c =:strTerritoryCode AND Status__c = :strStatus')
            .toSOQL()
        );
    }
    /**
     * @author Anisha Bharti
     * @date   10-Aug-2020
     * @description  DCP-39713 get plan records using territory Code and channel partner
     * @param set of Territory Codes, set of Channnel Pertners
     */
    public List<Plan__c> getActiveIndirectPlanbyTerritoryCode(set<String> strTerritoryCode, set<id> idchannelpartner, Id idRecordTypeId) {
        Set<String> setStatus = new Set<String>{STATUSACTIVE};
        removeDefaultOrderBy = TRUE;
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Territory_Code__c IN:strTerritoryCode AND Status__c IN :setStatus AND RecordTypeId =:idRecordTypeId AND Channel_Partner__c IN:idchannelpartner ')
            .toSOQL()
        );
    }
    /**
    * @author Anisha Bharti
     * @date   10-Aug-2020
     * @description  DCP-39713 get plan records using territory Code
     * @param set of Territory Codes
     */
    public List<Plan__c> getActiveDirectPlanbyTerritoryCode(set<String> strTerritoryCode, Id idRecordTypeId) {
        Set<String> setStatus = new Set<String>{STATUSACTIVE};
        removeDefaultOrderBy = TRUE;
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Territory_Code__c IN:strTerritoryCode AND Status__c IN :setStatus AND RecordTypeId =:idRecordTypeId')
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   6-Aug-2020
     * @description  DCP-39119 get Overlay plan records using territory Code
     * @param set of owner id and Record type id to include
     */
    public List<Plan__c> getPlanbyOwnerandRecordId(Set<Id> setOwnerId,Id idRecordTypeId) {
        Set<String> setStatus = new Set<String>{STATUSACTIVE,STATUSDRAFT};
        removeDefaultOrderBy = TRUE;
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('OwnerId IN :setOwnerId and RecordTypeId =:idRecordTypeId AND Status__c IN :setStatus')
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   21-Aug-2020
     * @description  DCP-39768 get active Territory plan records using territory code except current record
     * @param Territory Code and record id of exception plan
     */
    public List<Plan__c> getPlanByTerritoryCodeExceptRecordId(String strTerritoryCode,String strPlanId) {
        Set<String> setStatus = new Set<String>{STATUSACTIVE};
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Id != :strPlanId and  Territory_Code__c=:strTerritoryCode AND Status__c IN :setStatus and RecordTypeId !=:idOverlayRecordType')
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   26-Aug-2020
     * @description  DCP-39437 get active Territory plan records using territory code
     * @param Set of Territory Code
     */
    public List<Plan__c> getActivePlanByTerritoryCode(Set<String> setTerritoryCode) {
        Set<String> setStatus = new Set<String>{STATUSACTIVE};
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Territory_Code__c IN :setTerritoryCode AND Status__c IN :setStatus and RecordTypeId !=:idOverlayRecordType')
            .addOrdering('Start_Date__c',ilib_QueryFactory.SortOrder.DESCENDING)
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   9-Sept-2020
     * @description  DCP-39107 get Overlay plan records using owner
     * @param set of owner id and Record type id to include
     */
    public List<Plan__c> getAllPlanbyOwnerandRecordId(Set<Id> setOwnerId,Id idRecordTypeId) {
        removeDefaultOrderBy = TRUE;
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('OwnerId IN :setOwnerId and RecordTypeId =:idRecordTypeId')
            .toSOQL()
        );
    }
    /**
     * @author 
     * @date  
     * @description  get plan records using territory Plan Id
     * @param Set of plan Id
     * DCP-39951
     */
    public List<Plan__c> getPlanbyIds(Set<Id> setPlanId) {
        return (List<Plan__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('id IN :setPlanId ')
            .toSOQL());
    }
    /**
     * @author Prem Ranjan
     * @date  
     * @description  DCP-50569 get plan records using Plan Id
     * @param Set of plan Id
     */
    public List<Plan__c> getPlanWithoutAttachment(Set<Id> setPlanId) {
        return (List<Plan__c>) Database.query(newQueryFactory().selectField('Is_file_attached__c')
                                                            .setCondition('ID IN :setPlanId AND Is_file_attached__c = False').toSOQL());

    }
}