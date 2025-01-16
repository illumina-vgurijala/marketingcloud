/**
 * @author Gerardo Garcia
 * @description Trigger handler for Competitive_Complementary_Technology__c
 * @TestClasses TestTAPS_CompetitiveComplementaryTech, TestCompetitiveComplementaryTechnologies
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Gerardo Garcia                2023-10-02                      Initial Version CMCM-2893
 *    Gerardo Garcia                2023-11-15                      Publish CCT_Event__e event for refresh lwc CMCM-3960
 *    Gerardo Garcia                2024-01-30                      Add validation opportunityHasAlreadyMarkedPrimaryCTT CMCM-4485
 *    Enrique Reyes                 2024-07-01                      Convert class to without sharing
 *   ---------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class CompetitiveComplementaryTechnologies extends ilib_SObjectDomain {

    private static Boolean hasRunTaps = false;
    private static final String LOG_TITLE = 'CompetitiveComplementaryTechnologies';
    private static final String OPPORTUNITYNAME = 'Opportunity_Name__c';	//CodeScan 
    /*
    *  @Author: Gerardo Garcia
    *  @Description: Parameterized constructor to pass the parameter value to parent constructor
    *  @Param: List<Competitive_Complementary_Technology__c>
    */
    public CompetitiveComplementaryTechnologies(List<Competitive_Complementary_Technology__c> sObjectList)
    {
        super(sObjectList);
    }

    /*
    *  @Author: Gerardo Garcia
    *  @Description: Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        *  @Author: Gerardo Garcia
        *  @Description: contruct method to create a CompetitiveComplementaryTechnologies object
        *  @Param: List<SObject>
        *  @Return: ilib_SObjectDomain
        */

        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CompetitiveComplementaryTechnologies(sObjectList);
        }
    }

    /*Trigger Before Insert method - runs before record is inserted in database */
    public override void onBeforeInsert() {
        applyValidations((List<Competitive_Complementary_Technology__c>) records);
        applyDefaults((List<Competitive_Complementary_Technology__c>) records);
    }

    /*Trigger After Insert method - runs after record is saved in database */
    public override void onAfterInsert(){
        recalculateRecordSharing();
        emitEvent(records);

        // vefiry opp flag of ccts
        Map<id, List<Competitive_Complementary_Technology__c>> mapOpportunityCtts = (Map<id, List<Competitive_Complementary_Technology__c>>) UtilsCollection.getMapOfIdToSObjects(records, OPPORTUNITYNAME);

        List<Opportunity> opps = [SELECT id, Has_Competitor_Info__c FROM Opportunity WHERE id IN :mapOpportunityCtts.keySet()];

        List<Opportunity> opps2update = new List<Opportunity>();

        for(Opportunity opp: opps) {
            if(!opp.Has_Competitor_Info__c && opportunityHasCCts(mapOpportunityCtts.get(opp.id))) {
                opp.Has_Competitor_Info__c = true;
                opp.Is_Updated_By_System__c = true;
                opps2update.add(opp);
            }
        }

        update opps2update;

        
        ilib_LogEvent.emit();
    }

    /*
    *  @Author: Gerardo Garcia
    *  @Description: This method is invoked after records are deleted
    */
    public override void onAfterDelete() { 

        System.debug('On After Delete:' + records);
        Set<id> delCtts = UtilsCollection.getSetOfIds(records, OPPORTUNITYNAME);
        List<Opportunity> opps = [SELECT id, Has_Competitor_Info__c FROM Opportunity WHERE id IN :delCtts];
        
        List<Competitive_Complementary_Technology__c> nonDeletedCCTS = [SELECT id, Opportunity_Name__c FROM Competitive_Complementary_Technology__c WHERE Opportunity_Name__c IN :delCtts];
        System.debug('nonDeletedCCTS:' + JSON.serializePretty(nonDeletedCCTS));

        Map<Id, List<Competitive_Complementary_Technology__c>> mapOppCtts = (Map<Id, List<Competitive_Complementary_Technology__c>>) UtilsCollection.getMapOfIdToSObjects(nonDeletedCCTS, OPPORTUNITYNAME);

        List<Opportunity> opps2update = new List<Opportunity>();

        System.debug('mapOppCtts:' + JSON.serializePretty(mapOppCtts));
        System.debug('opps:' + JSON.serializePretty(opps));
		// Iterate through opportunities and update them if necessary
        for(Opportunity opp: opps) {
            if(opp.Has_Competitor_Info__c && !opportunityHasCCts(mapOppCtts.get(opp.id))) {
                opp.Has_Competitor_Info__c = false;
                opp.Is_Updated_By_System__c = true;
                opps2update.add(opp);
            }
        }
		// Update the modified opportunities
        update opps2update;
        System.debug('opps2update:' + JSON.serializePretty(opps2update));
    }

    private Boolean opportunityHasCCts(List<Competitive_Complementary_Technology__c> ccts) {
        if(ccts == null)
            return false;

        return ccts.size() > 0;
    }

    /*Trigger Before Update method - runs before record is updated in database */
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords) {
        applyValidations((List<Competitive_Complementary_Technology__c>) records);
        applyDefaults((List<Competitive_Complementary_Technology__c>) records);
    }

    /*Trigger After Update method - runs after record is updated in database */
    public override void onAfterUpdate(Map<Id, sObject> existingRecords) {
        onUpdateRecalculateRecordSharing(existingRecords);
        ilib_LogEvent.emit();
    }

    private void applyValidations(List<Competitive_Complementary_Technology__c> ccts) {
        Map<id, List<Competitive_Complementary_Technology__c>> mapOpportunityCtts = (Map<id, List<Competitive_Complementary_Technology__c>>) UtilsCollection.getMapOfIdToSObjects(ccts, OPPORTUNITYNAME);
        opportunityHasAlreadyMarkedPrimaryCTT(mapOpportunityCtts);
    }

    /**
     * Default methods holder
     */
    private void applyDefaults(List<Competitive_Complementary_Technology__c> ccts) {

    }

    /**
     * @description: Opportunity can only have one CCT marked as Primary Competitor
     */
    private void opportunityHasAlreadyMarkedPrimaryCTT(Map<id, List<Competitive_Complementary_Technology__c>> cctMap) {

        Set<id> opportunities = cctMap.keySet();

        Map<id, List<Competitive_Complementary_Technology__c>> hasIncomingPrimary = new Map<id, List<Competitive_Complementary_Technology__c>>();
        // Ids of coming records. Only filled onUpdate
        Set<id> ignoreList = new Set<Id>(); 

        for(id opp : opportunities) {
            List<Competitive_Complementary_Technology__c> ccts = cctMap.get(opp);
            for(Competitive_Complementary_Technology__c cct : ccts) {
                if(cct.Primary_Competitor__c) {
                    if(!hasIncomingPrimary.containsKey(opp)) {
                        hasIncomingPrimary.put(opp, new List<Competitive_Complementary_Technology__c>());
                    } 
                    List<Competitive_Complementary_Technology__c> lst = hasIncomingPrimary.get(opp);
                    lst.add(cct);

                    if(Trigger.isupdate) {
                        ignoreList.add(cct.id);
                    }
                }
            }
        }

        ilib_LogEvent.message('hasIncomingPrimary:' + JSON.serializePretty(hasIncomingPrimary));

        AggregateResult[] groupedResults = [SELECT Opportunity_Name__c, 
            Primary_Competitor__c, 
            COUNT(id) 
            FROM Competitive_Complementary_Technology__c 
            WHERE Primary_Competitor__c = true 
            AND Opportunity_Name__c = :hasIncomingPrimary.keySet()
            AND id NOT IN :ignoreList
            GROUP BY Opportunity_Name__c, Primary_Competitor__c];

        ilib_LogEvent.message('groupedResults:' + JSON.serializePretty(groupedResults));

        for (AggregateResult ar : groupedResults)  {
            ilib_LogEvent.message(JSON.serializePretty(ar));

            String oppId = (String) ar.get(OPPORTUNITYNAME);
            List<Competitive_Complementary_Technology__c> ccts = hasIncomingPrimary.get(oppId);
            for(Competitive_Complementary_Technology__c cct : ccts) {
                cct.addError(Label.CCT_Validation_Primary_Competitor);
                ilib_LogEvent.info('Validation Error opportunityHasAlreadyMarkedPrimaryCTT for cct:' + JSON.serializePretty(cct));
            }
        }
    }

    private void recalculateRecordSharing() {
        if(Feature.isOn(Feature.TAPS_CCT)) {
            ilib_LogEvent.info(LOG_TITLE + '.recalculateRecordSharing()');
            TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();
            tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());
        }
    }
	@TestVisible		//Added by SB
    private void onUpdateRecalculateRecordSharing(Map<Id, sObject> existingRecords) {
        if (canProceedRecalculateSharing()) {
            ilib_LogEvent.info(LOG_TITLE + '.onUpdateRecalculateRecordSharing()');
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId', TAPS_CompetitiveComplementaryTech.ACCOUNT_ID};
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);
            if (!idsThatNeedRecalculation?.isEmpty()) {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());
                hasRunTaps = true;
            }
        }
    }

    @TestVisible
    private static void emitEvent(List<Competitive_Complementary_Technology__c> ccts) {
        ilib_LogEvent.info( LOG_TITLE + '.emitEvent');
        String accountsIds = getAccountIds(ccts);
        if(ccts != null && String.isNotEmpty(accountsIds)) {
            Database.SaveResult result = emitEvent(accountsIds);
            if(!result.isSuccess()) {
                ApexExceptions.emitSaveErrors(new List<Database.SaveResult> {result}, LOG_TITLE);
            }
        } else {
            ilib_LogEvent.info('CCT_Event__e not launched' + JSON.serializePretty(ccts));
        }
        
    }

    @TestVisible
    private static Database.SaveResult emitEvent(String accountsIds) {
        CCT_Event__e evt = new CCT_Event__e(Account_Ids__c = accountsIds);
        ilib_LogEvent.message('evt' + JSON.serializePretty(evt));
        return EventBus.publish(evt);
    }
	@TestVisible	//Added by SB
    private Boolean canProceedRecalculateSharing() {
        return Feature.isOn(Feature.TAPS_CCT) && !hasRunTaps && !isInsertOperationForObject(getSObjectType());
    }

    private static String getAccountIds(List<Competitive_Complementary_Technology__c> ccts) {
        Set<String> accountIds = new Set<String>();
        for(Competitive_Complementary_Technology__c cct : ccts) {
            if(cct.Account__c != null) { 
                accountIds.add(cct.Account__c);
            }
        }
        return String.join(accountIds, ',');
    }

    /**
     * return the workstream
    */
    public override string getWorkstream() {
        return ilib_LogEvent.SALES;
    }
}