/**
 *   @author: Deep Diwakar
*    @date:   Dec-03-2023
*    @description: Decorator class for calculating area of work for contacts
*    @Test Class: TestAreaOfWorkContactDecorator
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Dec-03-2023        CMCM-4856: Initial version
*         Deep Diwakar       Dec-08-2023        CMCM-4856: Adjusted overridden methods
*         Deep Diwakar       Dec-12-2023        CMCM-4509: Updated to handle lead conversion scenario
*         Deep Diwakar       Jan-04-2024        CMCM-4697: Added recursion check
*         Deep Diwakar       Jan-12-2023        CMCM-4509: Lead converstion bug fixes
*         Deep Diwakar       Mar-18-2023        CMCM-5683: Updated to handle contact's primary account change
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class AreaOfWorkContactDecorator extends ilib_SObjectDecorator {

    private static final String LOG_TITLE = 'AreaOfWorkContactDecorator';
    private static final String CODE_PARAM_MKTG_SEGMENT_SKIP = 'Mktg_Contact_Market_Segment_Skipped';
    // recursion check flag
    private static Boolean isDecoratorExecuted = false;

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: Constructor
     * @param: List of lead records
     */
    public AreaOfWorkContactDecorator(List<SObject> lstSObjectRecords) {
        super(lstSObjectRecords);
    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: Overriding method to calculate Area of Work in Insert scenario
     * @param: none
     * @return: void
     */
    public override void decorate() { 
        ilib_LogEvent.push(LOG_TITLE + '.decorate');

        //CMCM-4697: recursion check
        if (isDecoratorExecuted && !Test.isRunningTest()) {
            ilib_LogEvent.info('Decorator already executed: ' + isDecoratorExecuted);
            return;
        }

        this.determineAreaOfWork();

        // set recursion flag
        isDecoratorExecuted = true;
        ilib_LogEvent.pop();

    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: Overriding method to calculate Area of Work in Update scenario
     * @param: Map of old sobject values
     * @return: void
     */
    public override void decorate(Map<Id, sObject> mapOfOldRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.decorate with map param');
        
        //CMCM-4697: recursion check
        if (isDecoratorExecuted && !Test.isRunningTest()) {
            ilib_LogEvent.info('Decorator already executed: ' + isDecoratorExecuted);
            return;
        }

        this.updateAreaOfWork(mapOfOldRecords);
        // set recursion flag
        isDecoratorExecuted = true;
        ilib_LogEvent.pop();
     }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: This method determines market segment value in update scenario
     * @param: none
     * @return: void
     */
     private void updateAreaOfWork(Map<Id, sObject> mapOfOldRecords) {

        List<Contact> lstContact = (List<Contact>) lstRecords;
        List<Contact> lstAowChangedContact = new List<Contact>();
        List<Contact> lstContactsAccountChange = new List<Contact>();

        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_MKTG_SEGMENT_SKIP});
        List<String> lstSkippedAoWValues = lstCodeParam[0].value__c.split(',');

        ilib_LogEvent.info('lstSkippedAoWValues: ' + lstSkippedAoWValues);

        for (Contact cont : lstContact) {
            Contact oldObj = (Contact) mapOfOldRecords.get(cont.Id);
            ilib_LogEvent.message('new area of work: ' + cont.Area_Of_Work__c);
            ilib_LogEvent.message('old area of work: ' + oldObj.Area_Of_Work__c);

            if (!String.isBlank(cont.Area_Of_Work__c) && !cont.Area_Of_Work__c.equalsIgnoreCase(oldObj.Area_Of_Work__c)) {
                lstAowChangedContact.add(cont);
            }

            //CMCM-5683: path for account change is different than direct AOW value change
            if (String.isNotBlank(cont.AccountId) && cont.AccountId != oldObj.AccountId) {
                ilib_LogEvent.message('primary account id changed for this contact: ' + cont.Id);
                // clear old AOW value
                cont.Area_Of_Work__c = '';
                lstContactsAccountChange.add(cont);

            }
        }


        ilib_LogEvent.info('lstAowChangedContact: ' + lstAowChangedContact);
        ilib_LogEvent.info('lstContactsAccountChange: ' + lstContactsAccountChange);

        //CMCM-5683: if primary account is changed then calculate new AOW
        if (!lstContactsAccountChange.isEmpty()) {
            ilib_LogEvent.info('recalculating AOW due to primary account change');
            lstRecords = lstContactsAccountChange;
            determineAreaOfWork();
        }

        // return if no change in area of work field
        if (lstAowChangedContact.isEmpty()) {
            return;
        }

         //create list of contact id
         Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAowChangedContact, 'AccountId');

         // create map for AccountId - list of market segment, to group them by account id
         Map<Id, List<Market_Segment__c>> mapAccountIdMarketSegment = new Map<Id, List<Market_Segment__c>>();
         mapAccountIdMarketSegment = getMarketSegmentByAccountId(setAccountIds);

         ilib_LogEvent.info('mapAccountIdMarketSegment: ' + mapAccountIdMarketSegment);

         for (Contact cont : lstAowChangedContact) {

            Contact oldObj = (Contact) mapOfOldRecords.get(cont.Id);

            List<Market_Segment__c> lstAcctMktgSegmentObj = new List<Market_Segment__c>();
            lstAcctMktgSegmentObj = mapAccountIdMarketSegment.get(cont.AccountId);

            ilib_LogEvent.message('lstAcctMktgSegmentObj: ' + lstAcctMktgSegmentObj); 

            if (lstAcctMktgSegmentObj != null && !lstAcctMktgSegmentObj.isEmpty()) {
                setAowForUpdate(cont, oldObj, lstAcctMktgSegmentObj, lstSkippedAoWValues);
            }

         }

     }

    /**
     * @author: Deep Diwakar
     * @date: Jan-12-2023 
     * @description: This method figures sets AOW value based on given inputs
     * @param: newRec -  new state of contact record
     * @param: oldRec -  old state of contact record
     * @param: lstAcctMkSegment - list of market segment for a given account
     * @param: lstSkippedAoWValues - list of skipped aow value
     * @return: void
     */
    private void setAowForUpdate(Contact newRec, Contact oldRec, List<Market_Segment__c> lstAcctMkSegment, List<String> lstSkippedAoWValues) {

        Set<String> setAcctMktgSegment = new Set<String>();

        setAcctMktgSegment = UtilsCollection.getSetOfStrings(lstAcctMkSegment, 'Market_Segment__c');

        ilib_LogEvent.message('setAcctMktgSegment: ' + setAcctMktgSegment);

        String incomingMktgSegment = newRec.Area_Of_Work__c;
        ilib_LogEvent.message('incomingMktgSegment: ' + incomingMktgSegment);

        if (lstSkippedAoWValues.contains(incomingMktgSegment) || (!setAcctMktgSegment.isEmpty() && 
                !setAcctMktgSegment.contains(incomingMktgSegment))) {

            ilib_LogEvent.message('persist old value');
            ilib_LogEvent.message('aow old value: ' + oldRec.Area_Of_Work__c);

            if (String.isBlank(oldRec.Area_Of_Work__c)) {
                // calculate aow using account market segment values
                setAowFromMarketSegmentList(newRec, lstAcctMkSegment, lstSkippedAoWValues);
                return;
            }

            newRec.Area_Of_Work__c = oldRec.Area_Of_Work__c;
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-12-2023 
     * @description: This method figures sets AOW value based on given inputs
     * @param: cont -  contact record
     * @param: lstAcctMkSegment - list of market segment for a given account
     * @param: lstSkippedAoWValues - list of skipped aow value
     * @return: void
     */
    private void setAowFromMarketSegmentList(Contact cont, List<Market_Segment__c> lstAcctMkSegment, List<String> lstSkippedAoWValues) {

        ilib_LogEvent.message('setting Aow using market segment list: ' + lstAcctMkSegment);

        // if only one market segment attached and it's not among the skipped values, then use that
        if (lstAcctMkSegment.size() == 1 && !lstSkippedAoWValues.contains(lstAcctMkSegment.get(0).Market_Segment__c)) {
            cont.Area_Of_Work__c = lstAcctMkSegment.get(0).Market_Segment__c;
            ilib_LogEvent.message('single market segment value: ' + lstAcctMkSegment.get(0).Market_Segment__c);
            return;
        }

        // initialing settign variable to NULL
        Market_Segment__c highestAllocationSegment = new Market_Segment__c();
        highestAllocationSegment = findHighestAllocationMarketSegment(lstAcctMkSegment, lstSkippedAoWValues);

        ilib_LogEvent.message('highestAllocationSegment: ' + highestAllocationSegment);

        // setting AoW for multiple segments
        if (highestAllocationSegment != null) {
            cont.Area_Of_Work__c = highestAllocationSegment.Market_Segment__c;
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: This method figuere out market segment value in insert scenario
     * @param: none
     * @return: void
     */
    private void determineAreaOfWork() {

        ilib_LogEvent.info(LOG_TITLE +'.determineAreaOfWork ');

        List<Contact> lstContact = (List<Contact>) lstRecords;

        // get closed oppty stages from code parameter CMT
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_MKTG_SEGMENT_SKIP});
        List<String> lstSkippedAoWValues = lstCodeParam[0].value__c.split(',');

        ilib_LogEvent.info('lstSkippedAoWValues: ' + lstSkippedAoWValues);

        //create list of contact id
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstContact, 'AccountId');

        // create map for AccountId - list of market segment, to group them by account id
        Map<Id, List<Market_Segment__c>> mapAccountIdMarketSegment = new Map<Id, List<Market_Segment__c>>();
        mapAccountIdMarketSegment = getMarketSegmentByAccountId(setAccountIds);

        ilib_LogEvent.info('mapAccountIdMarketSegment: ' + mapAccountIdMarketSegment);

        for (Contact cont : lstContact) {
            if (String.isBlank(cont.AccountId)) {
                ilib_LogEvent.message('contact->accountid is blank'); 
                continue;
            }
            List<Market_Segment__c> lstAcctMkSegment = new List<Market_Segment__c>();

            // get all account market segments for a given contact->account
            lstAcctMkSegment = mapAccountIdMarketSegment.get(cont.AccountId);

            // no market segment on this account
            if (lstAcctMkSegment == null || lstAcctMkSegment.isEmpty()) {
                ilib_LogEvent.message('no market segment found'); 
                continue;
            }

            //CMCM-4509: changes for lead conversion
            // check if incoming value is among the related account market segment. If so, then use that.
            String incomingMktgSegment = cont.Area_Of_Work__c;
            ilib_LogEvent.message('incomingMktgSegment: ' + incomingMktgSegment); 

            Set<String> setAcctMktgSegment = new Set<String>();
            setAcctMktgSegment = UtilsCollection.getSetOfStrings(lstAcctMkSegment, 'Market_Segment__c');

            if (!String.isBlank(incomingMktgSegment) && setAcctMktgSegment.contains(incomingMktgSegment)
                    && !lstSkippedAoWValues.contains(incomingMktgSegment)) {
                continue;
            }
            // CMCM-4509: Changes end here

            // calculate aow using market segment list
            setAowFromMarketSegmentList(cont, lstAcctMkSegment, lstSkippedAoWValues);
            
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: This method finds out highest allocation in given market segments
     * @param: List of market segments, List of skipped market segment values
     * @return: Highest allocation market segment
     */
    private Market_Segment__c findHighestAllocationMarketSegment(List<Market_Segment__c> lstAcctMkSegment, List<String> lstSkippedAoWValues) {

        // initialing settign variable to NULL
        Market_Segment__c highestAllocationSegment = null;

        // find highest percentage allocation
        for (Market_Segment__c acctMkSegment: lstAcctMkSegment) {

            // market segment shouldn't be from the skipped values
            if (lstSkippedAoWValues.contains(acctMkSegment.Market_Segment__c)) {
                continue;
            }

            // first entry
            if (highestAllocationSegment == null) {
                highestAllocationSegment = acctMkSegment;
                continue;
            }

            // pick highest allocation. If there is tie between two high allocation then randomly pick
            if (acctMkSegment.Percent_Allocation__c > highestAllocationSegment.Percent_Allocation__c) {
                highestAllocationSegment = acctMkSegment;
            }
        }

        return highestAllocationSegment;

    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-03-2023 
     * @description: This method finds all market segment for given account ids
     * @param: Set of Account Ids
     * @return: Map of Account Id to list of market segments
     */
    private Map<Id, List<Market_Segment__c>> getMarketSegmentByAccountId(Set<Id> setAccountIds) {

        // query market segment object using contact account id
        List<Market_Segment__c> lstMarketSegment = new MarketSegmentSelector().getMarketSegmentByAccountIds(setAccountIds);

        // create map for AccountId - list of market segment, to group them by account id
        Map<Id, List<Market_Segment__c>> mapAccountIdMarketSegment = new Map<Id, List<Market_Segment__c>>();

        for (Market_Segment__c mkSegment : lstMarketSegment) {
            if (mapAccountIdMarketSegment.containsKey(mkSegment.Account__c)) {
                List<Market_Segment__c> lstMkSegment = mapAccountIdMarketSegment.get(mkSegment.Account__c);
                lstMkSegment.add(mkSegment);

            } else {
                List<Market_Segment__c> lstMkSegment = new List<Market_Segment__c>();
                lstMkSegment.add(mkSegment);
                mapAccountIdMarketSegment.put(mkSegment.Account__c, lstMkSegment);

            }
        }

        return mapAccountIdMarketSegment;

    }

}