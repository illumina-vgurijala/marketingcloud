/**
 *   @author: Deep Diwakar
*    @date:   July-27-2023
*    @description: Marketing waterfall service class to execute waterfall logic
*    @Test Class: TestMktgWaterfallOpptyContactRoles
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       July-27-2023        DCP-60131: Initial version
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class MktgWaterfallOpptySrvc implements IMktgWaterfallOpptySrvc {

    private static final String LOG_TITLE = 'MktgWaterfallOpptySrvc';
    private static final String CODE_PARAM_CLOSED_OPPTY_STAGES = 'Mktg_Waterfall_Closed_Oppty_Stages';

    /**
     * @author: Deep Diwakar
     * @date: July-27-2023
     * @description: this method runs waterfall logic for given contact ids
     * @param: Set of contact id
     * @return: void
     */
    public void executeWaterfallOpptyLogic(Set<Id> setContactIds) {

        ilib_LogEvent.push(LOG_TITLE + '.executeWaterfallOpptyLogic');

        // creating some collection variables for storing different values 
        List<Contact> lstWaterfallUpdatedCont = new List<Contact>();
        List<Contact> lstWaterfallResetCont = new List<Contact>();
        Map<Id, Contact> mapFinalUpdates = new Map<Id, Contact>();

        try {
            // get closed oppty stages from code parameter CMT
            List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_CLOSED_OPPTY_STAGES});
            List<String> lstClosedOpptyStages = lstCodeParam[0].value__c.split(',');

            List<OpportunityContactRole> lstOcr =  new OpportunityContactRoleSelector().selectValidContactOppAssociations(setContactIds, new Set<String>(lstClosedOpptyStages));
            ilib_LogEvent.info('lstOcr: ' + lstOcr.size());

            // if no opportunity contact role returned with open opportunity then execute reset waterfall logic on all contact ids
            if (lstOcr.isEmpty()) {
                // run reset waterfall logic
                MktgWaterfallServiceHelper.resetWaterfallLogic(setContactIds);
            }

            // creating two sets, one for executing waterfall logic and second for exeucting reset waterfall logic
            Set<Id> setWaterfallContactIds = new Set<Id>();
            Set<Id> setWaterfallResetContactIds = new Set<Id>();

            // getting contact ids in sets from lstOcr
            setWaterfallContactIds = UtilsCollection.getSetOfIds(lstOcr, 'ContactId');

            // looping to get reset waterfall logic contact ids 
            for (Id contId : setContactIds) {
                if (!setWaterfallContactIds.contains(contId)) {
                    // reset waterfall logic for this contact id
                    setWaterfallResetContactIds.add(contId);
                }
            }

            if (!setWaterfallContactIds.isEmpty()) {
                // call waterfall set logic
                lstWaterfallUpdatedCont = MktgWaterfallServiceHelper.executeWaterfallLogic(setWaterfallContactIds); 
            }

            if (!setWaterfallResetContactIds.isEmpty()) {
                // call waterfall reset logic
                lstWaterfallResetCont = MktgWaterfallServiceHelper.resetWaterfallLogic(setWaterfallResetContactIds);
            }

            // creating final map to combine both waterfall set and reset contacts at one place
            // initializing with waterfall set contacts
            mapFinalUpdates = new Map<Id, Contact>(lstWaterfallUpdatedCont);

            // a contact could be added to a new opportunity and removed from another opportunity in the same transaction 
            // in bulkified manner. In that case, contact's newly set waterfall values (added opportunity) should be persisted
            for (Contact cont : lstWaterfallResetCont) {
                // ignore if same contact is there in waterfall set list
                if (!mapFinalUpdates.containsKey(cont.Id)) {
                    mapFinalUpdates.put(cont.Id, cont);
                }
            }

            ilib_LogEvent.info('mapFinalUpdates: ' + mapFinalUpdates);
            if (!mapFinalUpdates.isEmpty()) {
                MktgWaterfallServiceHelper.processDML(mapFinalUpdates.values());
            }

            ilib_LogEvent.pop();

        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE, ex, 'Marketing');
            throw ex;
        }
    }

}