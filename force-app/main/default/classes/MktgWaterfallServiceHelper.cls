/**
 *   @author: Deep Diwakar
*    @date:   July-28-2023
*    @description: Marketing waterfall service helper class. It contains method that can resused for running waterfall logic. 
*    @Test Class: TestMktgWaterfallOpptyContactRoles, TestLeads
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       July-28-2023        DCP-60131: Initial version
*         Deep Diwakar       Sep-22-2023         CMCM-3604: Fix for contact records which have both Marketing qualified and non-qualified oppty
*         Deep Diwakar       June-10-2024        CMCM-6457: Added Waterfall logic for merged Lead/Contacts
*         Deep Diwakar       June-26-2024        CMCM-6457: Added Waterfall logic for lead conversion
*         Deep Diwakar       Sept-03-2024        CMCM-9949: Added logic to handle empty waterfall stage for lead conversion scenario
*         Deep Diwakar       Dec-18-2024         CMCM-12362: Updated class to add new disposition code value
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class MktgWaterfallServiceHelper {

    private static final String OPPORTUNITY = 'Opportunity';
    private static final String OPEN_OPPORTUNITY = 'Open Opportunity';
    private static final String RECYCLED = 'Recycled';
    private static final String DISPOSITION_CODE = 'No need';
    private static final String FUNNEL_MARKETING = 'Funnel Marketing';
    private static final String CODE_PARAM_OPPTY_TYPE_SKIP = 'Mktg_Waterfall_Oppty_Type_Skip';
    private static final String CODE_PARAM_OPEN_OPPTY_STAGES = 'Mktg_Waterfall_Open_Oppty_Stages';
    private static final String STRING_OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    

    private static final String LOG_TITLE = 'MktgWaterfallServiceHelper';
    private static Set<String> setClosedOpptyStages = new Set<String> {'Closed Won', 'Closed Lost', 'Closed Abandoned'};

    // CMCM-6457: Added following string values for this story
    private static final String WATERFALL_STAGE = 'Waterfall_Stage__c';
    private static final String WATERFALL_ENGAGED_DATE = 'Waterfall_Engaged_Date__c';
    private static final String WATERFALL_QUALIFIED_DATE = 'Waterfall_Qualified_Date__c';
    private static final String WATERFALL_SALES_ACCEPTED_DATE = 'Waterfall_Sales_Accepted_Date__c';
    private static final String WATERFALL_OPPORTUNITY_DATE = 'Waterfall_Opportunity_Date__c';
    private static final String WATERFALL_CLOSED_WON_DATE = 'Waterfall_Closed_Won_Date__c';
    private static final String LAST_RESPONDED_CAMPAIGN_DATE = 'Last_Responded_Campaign_Date__c';
    private static final String LAST_RESPONDED_CAMPAIGN = 'Last_Responded_Campaign__c';


    /**
     * @author: Deep Diwakar
     * @date: July-28-2023 
     * @description: this method runs waterfall logic to set waterfall fields
     * @param: Set of contact ids
     * @return: List of updated contact records
     */
    public static List<Contact> executeWaterfallLogic(Set<Id> setContactIds) {

        ilib_LogEvent.push(LOG_TITLE + '.executeWaterfallLogic');

        Map<Id, Contact> mapContactUpdates = new Map<Id, Contact>();
        Map<Id, Contact> mapResetWaterfallStage = new Map<Id, Contact>();

        // get closed oppty stages from code parameter CMT
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_OPEN_OPPTY_STAGES});
        List<String> lstOpenOpptyStages = lstCodeParam[0].value__c.split(',');

        // get valid list of OCR object with required fields
        List<OpportunityContactRole> lstOcr =  new OpportunityContactRoleSelector().selectOpenOpptyContRoleByContactId(setContactIds,new Set<String>(lstOpenOpptyStages));

        ilib_LogEvent.info('lstOcr size: ' + lstOcr.size());
        if (lstOcr.isEmpty()) {
            // return empty list
            return new List<Contact>();
        }

        // find OCRs where oppty qualifies to be marketing waterfall opportunity
        Set<OpportunityContactRole> waterfallQualifiedOcr = findWaterfallQualifiedContactRoles(lstOcr);

        // set contact object fields for waterfall
        mapContactUpdates = setContactFieldsForWaterfall(waterfallQualifiedOcr);

        ilib_LogEvent.info('waterfallQualifiedOcr - mapContactUpdates: ' + mapContactUpdates);

        // handle scenario where waterfall stage is incorrectly set on contact e.g. changing lead source on from Funnel Marketing 
        // to something else. In this case, contact's waterfall stage should be cleared.
        mapResetWaterfallStage = clearIncorrectWaterfallStage(waterfallQualifiedOcr, lstOcr);

        ilib_LogEvent.info('mapResetWaterfallStage: ' + mapResetWaterfallStage);

        if (mapResetWaterfallStage.isEmpty()) {
            return mapContactUpdates.values();
        }

        // combine both maps
        for (Id contId : mapResetWaterfallStage.keySet()) {
            // if contact is getting set above then do not reset
            if (!mapContactUpdates.containsKey(contId)) {
                mapContactUpdates.put(contId, mapResetWaterfallStage.get(contId));
            }

        }

        ilib_LogEvent.info('mapContactUpdates: ' + mapContactUpdates);

        ilib_LogEvent.pop();

        return mapContactUpdates.values();
    }


    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method runs reset waterfall logic
     * @param: Set of contact ids
     * @return: List of updated contact records
     */
    public static List<Contact> resetWaterfallLogic(Set<Id> setContactIds) {

        ilib_LogEvent.push(LOG_TITLE + '.resetWaterfallLogic');

        List<Contact> lstResetContacts = new List<Contact>();

        // checking if this contact id has any other open opportunity attached to it
        for(OpportunityContactRole objOpportunityContactRole: new OpportunityContactRoleSelector().selectValidContactOppAssociations(setContactIds,setClosedOpptyStages)) {
            setContactIds.remove(objOpportunityContactRole.ContactId);       
        }
        
        for(Id contId : setContactIds) {

            Contact objCon = new Contact(Id=contId);

            // reset Marketing contact staus. Resetting contact status will reset waterfall stage through trigger.
            objCon.Marketing_Contact_Status__c=RECYCLED;
            objCon.Disposition_Code__c=DISPOSITION_CODE;
            objCon.Is_Recycled__c=true;

            lstResetContacts.add(objCon);

        }

        ilib_LogEvent.pop();

        return lstResetContacts;
    }


    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method finds Marketing qualified waterfall opportunity contact roles in given list of roles
     * @param: List of opportunity contat role records
     * @return: Set of Marketing qualified opportunity contat role records
     */
    public static Set<OpportunityContactRole> findWaterfallQualifiedContactRoles(List<OpportunityContactRole>  ocrList) {

        Set<OpportunityContactRole> setFilteredOcr = new Set<OpportunityContactRole>();

        // Set variables for collecting renewal oppty types from Code Parameter CMT
        Set<String> setRenewalOpportunityTypes = new Set<String>();

        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_OPPTY_TYPE_SKIP});
        setRenewalOpportunityTypes.addAll(lstCodeParam[0].value__c.split(','));

        for (OpportunityContactRole ocr: ocrList) {

            Boolean isRenewalOppty = setRenewalOpportunityTypes.contains(ocr.Opportunity.Type);
            Boolean isFunnelOppty = FUNNEL_MARKETING.equals(ocr.Opportunity.LeadSource);
            ilib_LogEvent.message('ocr.Opportunity.LeadSource: ' + ocr.Opportunity.LeadSource);

            // collect marketing qualified opportunity related contact roles
            if (!isRenewalOppty && (isFunnelOppty || (ocr.Contact.Last_Responded_Campaign_Date__c != null && ocr.Contact.Last_Responded_Campaign_Date__c > System.now()-365)
                || (String.isNotBlank(ocr.Contact.waterfall_stage__c) && !OPPORTUNITY.equalsIgnoreCase(ocr.Contact.waterfall_stage__c)))) {

                    setFilteredOcr.add(ocr);
            } 
        }

        return setFilteredOcr;

    }

    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method clears waterfall stage from those contacts which doesn't qualify for waterfall anymore
     * @param: waterfallQualifiedOcr-  Set of waterfall qualified opportunity contat role records
     * @param: waterfallQualifiedOcr-  List of all opportunity contat role records for a given transaction
     */
    public static Map<Id, Contact> clearIncorrectWaterfallStage(Set<OpportunityContactRole> waterfallQualifiedOcr, List<OpportunityContactRole> allOcr) {
        Map<Id, Contact> mapWaterfallReset = new Map<Id, Contact>();

        //CMCM-3604:Fix for contact records which have both Marketing qualified and non-qualified oppty
        Set<Id> setWaterfallQualContId = new Set<Id>();

        if (!waterfallQualifiedOcr.isEmpty()) {
            setWaterfallQualContId = UtilsCollection.getSetOfIds(new List<OpportunityContactRole>(waterfallQualifiedOcr), 'ContactId');
        }

        for (OpportunityContactRole ocr : allOcr) {
            if (!setWaterfallQualContId.contains(ocr.ContactId) && OPPORTUNITY.equals(ocr.Contact.Waterfall_Stage__c)) {
                
                Contact updateContact = new Contact(Id = ocr.ContactId);
                // clear waterfall stage
                updateContact.Waterfall_Stage__c = '';
                
                mapWaterfallReset.put(ocr.ContactId, updateContact);
            }
                 
        }

        return mapWaterfallReset;

    }

    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method performs DML for contact updates
     * @param: List of contact records
     * @return: void
     */
    public static void processDML(List<Contact> lstContactForUpdate) {

        if (lstContactForUpdate.isEmpty()) {
            return;
        }

        // bypassing validaiton as this is a backend update, not user context. Restoring it back after update
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
        objApexSettings.Bypass_All_Validations__c=true;
        if (Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
            upsert objApexSettings cs_Apex_Settings__c.Id;
            List<Database.SaveResult> results = Database.update(lstContactForUpdate, false);
            ApexExceptions.emitSaveErrors(results, 'MktgWaterfallServiceHelper');
            objApexSettings.Bypass_All_Validations__c=false;
            upsert objApexSettings cs_Apex_Settings__c.Id;
        } else {
            ilib_LogEvent.info('User does not have create and update permission on custom setting - Apex Settings');
        }

    }


    /**
     * @author: Deep Diwakar
     * @date: July-31-2023
     * @description: This method publishes platform event to execute waterfall logic
     * @param: objectType - Name of the object e.g. contact, opportunity etc. whose ids are getting passed
     * @param: setObjectIds - Set of object ids
     * @return: void
     */
    public static void publishWaterfallOpptyEvent(String objectType, Set<Id> setObjectIds) {
        List<ProcessContactForWaterfallOppty__e> lstWaterfallContactUpdate = new List<ProcessContactForWaterfallOppty__e>();

        for (Id objectId : setObjectIds) {
            ProcessContactForWaterfallOppty__e event = new ProcessContactForWaterfallOppty__e();
            event.Object_Id__c = objectId;
            event.Object_Type__c = objectType;
            lstWaterfallContactUpdate.add(event);

        }

        ilib_LogEvent.info('lstWaterfallContactUpdate size: ' + lstWaterfallContactUpdate.size());
        ilib_LogEvent.info('lstWaterfallContactUpdate: ' + lstWaterfallContactUpdate);
        if (!lstWaterfallContactUpdate.isEmpty()) {

            EventBus.publish(lstWaterfallContactUpdate);
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method sets contact status and waterfall fields for contacts
     * @param: Set of opportunity contat role records for which we have to set waterfall fields
     * @return: Map of id and updated contacts
     */
    public static Map<Id, Contact> setContactFieldsForWaterfall(Set<OpportunityContactRole> setOcr) {

        Map<Id, Contact> mapContactUpdates = new Map<Id, Contact>();

        // setting contact fields related waterfall
        mapContactUpdates = setContactWaterfallFields(setOcr);

        // setting contact status if not set already
        for (Contact cont : mapContactUpdates.values()) {

            if (!OPEN_OPPORTUNITY.equals(cont.Marketing_Contact_Status__c)) {
                cont.Marketing_Contact_Status__c = OPEN_OPPORTUNITY; 
                cont.Is_Recycled__c = false;
            }

        }

        return mapContactUpdates;

    }

    /**
     * @author: Deep Diwakar
     * @date: July-28-2023
     * @description: This method sets waterfall fields for contacts
     * @param: Set of opportunity contat role records for which we have to set waterfall fields
     * @return: Map of id and updated contacts
     */
    public static Map<Id, Contact> setContactWaterfallFields(Set<OpportunityContactRole> setOcr) {

        Map<Id, Contact> mapContactUpdates = new Map<Id, Contact>();

        for (OpportunityContactRole ocr : setOcr) {

            // reset waterfall date fields when waterfall stage is empty because contact is entering new waterfall cycle here
            if(String.isBlank(ocr.Contact.Waterfall_Stage__c)) {
                ilib_LogEvent.message('clearing old waterfall dates as contact is entering new waterfall');
                ocr.Contact.Waterfall_Closed_Won_Date__c=null;
                ocr.Contact.Waterfall_Opportunity_Date__c=null;
                ocr.Contact.Waterfall_Sales_Accepted_Date__c=null;
                ocr.Contact.Waterfall_Qualified_Date__c=null;
                ocr.Contact.Waterfall_Engaged_Date__c=null;
            
            } 

            // set waterfall values
            if (!OPPORTUNITY.equals(ocr.Contact.Waterfall_Stage__c) && !STRING_OPPORTUNITY_STAGE_CLOSED_WON.equals(ocr.Contact.Waterfall_Stage__c)) {
                ocr.Contact.Waterfall_Stage__c = OPPORTUNITY;
            }
            
            if (ocr.Contact.Waterfall_Engaged_Date__c == null) {
                ocr.Contact.Waterfall_Engaged_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Qualified_Date__c == null) {
                ocr.Contact.Waterfall_Qualified_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Sales_Accepted_Date__c == null) {
                ocr.Contact.Waterfall_Sales_Accepted_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Opportunity_Date__c == null) {
                ocr.Contact.Waterfall_Opportunity_Date__c = Datetime.Now();
            }

            mapContactUpdates.put(ocr.ContactId, ocr.Contact);

        }

        return mapContactUpdates;


    }

    /**
     * @author: Deep Diwakar
     * @date: Sep-28-2023
     * @description: This method re-evaluate waterfall stage for incoming contacts
     * @param: Set of contact id
     * @return: List of contacts after revaluation
     */
    public static List<Contact> revaluateWaterfallStage(Set<Id> setContactIds) {

        ilib_LogEvent.push(LOG_TITLE + '.revaluateWaterfallStage');

        Map<Id, Contact> mapResetUpdate = new Map<Id, Contact>();

        // get open oppty stages from code parameter CMT
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_OPEN_OPPTY_STAGES});
        List<String> lstOpenOpptyStages = new List<String>();
        lstOpenOpptyStages.addAll(lstCodeParam[0].value__c.split(','));

        // get valid list of OCR object with required fields
        List<OpportunityContactRole> lstOcr =  new OpportunityContactRoleSelector().selectOpenOpptyContRoleByContactId(setContactIds,new Set<String>(lstOpenOpptyStages));

        Set<OpportunityContactRole> setFilteredOcr = findWaterfallQualifiedContactRoles(lstOcr);

        ilib_LogEvent.info('setFilteredOcr size:' + setFilteredOcr);

        mapResetUpdate.putAll(clearIncorrectWaterfallStage(setFilteredOcr, lstOcr));

        ilib_LogEvent.info('mapResetUpdate: ' + mapResetUpdate);

        ilib_LogEvent.pop();

        return mapResetUpdate.values();

    }

     /**
     * @author: Deep Diwakar
     * @date: June-13-2024
     * @description: This method runs waterfall logic when records are merged
     * @param: maplooserIdToWinnerObj - map to hold looser record id and winner record object
     * @return: void
     */
    public static void mergeWaterfallLogic(Map<Id, sObject> maplooserIdToWinnerObj) {

        ilib_LogEvent.push(LOG_TITLE + '.mergeWaterfallValues');

        List<sObject> winnerObjectList = maplooserIdToWinnerObj.values();

        String objectName = '';
        if (winnerObjectList.getSObjectType() == Lead.sObjectType) {
            objectName = 'Lead';
        } else if (winnerObjectList.getSObjectType() == Contact.sObjectType) {
            objectName = 'Contact';
        }

        ilib_LogEvent.info('objectName: ' + objectName);

        if (String.isBlank(objectName)) {
            ilib_LogEvent.info('objectName is empty');
            ilib_LogEvent.pop();
            return;
        }

        // get deleted record id
        Set<Id> deletedObjId = maplooserIdToWinnerObj.keySet();

        // using dynamic soql
        String queryString = 'SELECT Id, Waterfall_Stage__c, Waterfall_Engaged_Date__c, Waterfall_Qualified_Date__c, Waterfall_Sales_Accepted_Date__c, '
                                + 'Waterfall_Opportunity_Date__c, Waterfall_Closed_Won_Date__c, Last_Responded_Campaign_Date__c, '
                                + 'Last_Responded_Campaign__c FROM '
                                + objectName + ' WHERE IsDeleted = true AND Id IN: deletedObjId ALL ROWS';
    

        ilib_LogEvent.info('queryString: ' + queryString);

        // query to get deleted record waterfall values
        List<sObject> deletedRecords = Database.query(queryString);

        ilib_LogEvent.info('deletedRecords: ' + deletedRecords);

        for (sObject delObj : deletedRecords) {

            sObject winnerObj = maplooserIdToWinnerObj.get((Id) delObj.Id);

            mergeWaterfallFields(winnerObj, delObj);
            mergeWaterfallLastCampaignFields(winnerObj, delObj);
           
        }

        ilib_LogEvent.pop();

    }

    /**
     * @author: Deep Diwakar
     * @date: June-13-2024
     * @description: This method calculates waterfall field values in merge scenario
     * @param: winnerObj - winner object record
     * @param: delObj - looser object record
     * @return: void
     */
    private static void mergeWaterfallFields(sObject winnerObj, sObject delObj) {
        String winObjWatarfallStage = (String) winnerObj.get(WATERFALL_STAGE);
        String delObjWaterfallStage = (String) delObj.get(WATERFALL_STAGE);

        ilib_LogEvent.message('winObjWatarfallStage: ' + winObjWatarfallStage);

        ilib_LogEvent.message('delObjWaterfallStage: ' + delObjWaterfallStage);

        // Rank map. Higher the rank means higher the priority in waterfall flow
        Map<String, Integer> mapWafallStageToRank = new Map<String, Integer> {
                                                            'Engaged' => 1,
                                                            'Qualified' => 2,
                                                            'Sales Accepted' => 3,
                                                            'Opportunity' => 4,
                                                            'Closed Won' => 5
                                                        };

        Integer winnerObjRank = String.isNotBlank(winObjWatarfallStage) ? mapWafallStageToRank.get(winObjWatarfallStage) : 0;
        Integer delObjRank = String.isNotBlank(delObjWaterfallStage) ? mapWafallStageToRank.get(delObjWaterfallStage) : 0;

        ilib_LogEvent.message('winnerObjRank: ' + winnerObjRank);
        ilib_LogEvent.message('delObjRank: ' + delObjRank);

        if (String.isNotBlank(delObjWaterfallStage) && (String.isBlank(winObjWatarfallStage) || winnerObjRank < delObjRank)) {
            ilib_LogEvent.message('moving waterfall fields from looser record to winner record');
            // set waterfall field values on new records
            winnerObj.put(WATERFALL_STAGE, (String) delObj.get(WATERFALL_STAGE));
            winnerObj.put(WATERFALL_ENGAGED_DATE, (Datetime) delObj.get(WATERFALL_ENGAGED_DATE));
            winnerObj.put(WATERFALL_QUALIFIED_DATE, (Datetime) delObj.get(WATERFALL_QUALIFIED_DATE));
            winnerObj.put(WATERFALL_SALES_ACCEPTED_DATE, (Datetime) delObj.get(WATERFALL_SALES_ACCEPTED_DATE));
            winnerObj.put(WATERFALL_OPPORTUNITY_DATE, (Datetime) delObj.get(WATERFALL_OPPORTUNITY_DATE));
            winnerObj.put(WATERFALL_CLOSED_WON_DATE, (Datetime) delObj.get(WATERFALL_CLOSED_WON_DATE));
        }
           
    }

    /**
     * @author: Deep Diwakar
     * @date: June-13-2024
     * @description: This method calculates last campaign field values in merge scenario
     * @param: winnerObj - winner object record
     * @param: delObj - looser object record
     * @return: void
     */
    private static void mergeWaterfallLastCampaignFields(sObject winnerObj, sObject delObj) {
        // check and update last responded campaign date and value
        Datetime delLastRespCmpgnDate = (Datetime) delObj.get(LAST_RESPONDED_CAMPAIGN_DATE);
        Datetime winLastRespCmpgnDate = (Datetime) winnerObj.get(LAST_RESPONDED_CAMPAIGN_DATE);

        ilib_LogEvent.message('delLastRespCmpgnDate: ' + delLastRespCmpgnDate);
        ilib_LogEvent.message('winLastRespCmpgnDate: ' + winLastRespCmpgnDate);

        if (delLastRespCmpgnDate != null && (winLastRespCmpgnDate == null || delLastRespCmpgnDate > winLastRespCmpgnDate)) {
            ilib_LogEvent.message('updating last campaing id and date with deleted record info');
            winnerObj.put(LAST_RESPONDED_CAMPAIGN_DATE, delLastRespCmpgnDate);
            winnerObj.put(LAST_RESPONDED_CAMPAIGN, delObj.get(LAST_RESPONDED_CAMPAIGN));
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: June-26-2024
     * @description: This method calculates last campaign field values in merge scenario
     * @param: mapConvertedLeadIdToContactId - map of converted lead id to contact id
     * @param: lstContacts - list of contact object to which lead is converted
     * @return: void
     */
    public static void waterfallForLeadConversion(Map<Id, Id> mapConvertedLeadIdToContactId, List<Contact> lstContacts, List<Id> lstContIdsEmptyWaterfall) {
        ilib_LogEvent.push(LOG_TITLE + '.waterfallForLeadConversion');

        ilib_LogEvent.info(LOG_TITLE +  '- lstContIdsEmptyWaterfall: ' + lstContIdsEmptyWaterfall);

        // get lead object with waterfall fields
        Set<Id> setConvertedLeadIds = mapConvertedLeadIdToContactId.keySet();
        List<Lead> lstConvertedLeads = new List<Lead>();
        lstConvertedLeads = new LeadsSelector().selectConvertedLeadsWithWaterfall(setConvertedLeadIds);

        Map<Id, Lead> mapConvertedContIdToLead = new Map<Id, Lead>();
        for (Lead convLead : lstConvertedLeads) {
            mapConvertedContIdToLead.put(convLead.ConvertedContactId, convLead);
        }
        ilib_LogEvent.info('mapConvertedContIdToLead: ' + mapConvertedContIdToLead);


        // get contact object with waterfall fields
        Map<Id, Contact> mapIdToContactWithWaterfall = new Map<Id, Contact>();
        List<Id> lstContactIds =  mapConvertedLeadIdToContactId.values();
        mapIdToContactWithWaterfall = new Map<Id, Contact> (new ContactsSelector().selectContactsWithWaterfall(new Set<Id>(lstContactIds)));

        ilib_LogEvent.info('mapIdToContactWithWaterfall: ' + mapIdToContactWithWaterfall);
        // loop original contacts 
        for (Contact cont : lstContacts) {
            // get lead object with waterfall fields using converted contact id of this contact
            Lead convertedLead = mapConvertedContIdToLead.get(cont.Id);

            // get contact object with waterfall fields using this contact id
            Contact winnerCont = mapIdToContactWithWaterfall.get(cont.Id);


            //CMCM-9949: check if winning contact had empty waterfall stage earlier. If so, then reset it to its original state
            if (lstContIdsEmptyWaterfall.contains(cont.Id)) {
                ilib_LogEvent.message('found contact with previous waterfall stage as empty');
                winnerCont.Waterfall_Stage__c = '';
            }

            // call merge waterfall field method
            mergeWaterfallFields(winnerCont, convertedLead);

            // call merge last campaing responded date method
            mergeWaterfallLastCampaignFields(winnerCont, convertedLead);

            ilib_LogEvent.message('copying winner values to original contact');

            cont.Waterfall_Stage__c = winnerCont.Waterfall_Stage__c;
            cont.Waterfall_Engaged_Date__c = winnerCont.Waterfall_Engaged_Date__c;
            cont.Waterfall_Qualified_Date__c = winnerCont.Waterfall_Qualified_Date__c;
            cont.Waterfall_Sales_Accepted_Date__c = winnerCont.Waterfall_Sales_Accepted_Date__c;
            cont.Waterfall_Opportunity_Date__c = winnerCont.Waterfall_Opportunity_Date__c;
            cont.Waterfall_Closed_Won_Date__c = winnerCont.Waterfall_Closed_Won_Date__c;
            cont.Last_Responded_Campaign_Date__c = winnerCont.Last_Responded_Campaign_Date__c;
            cont.Last_Responded_Campaign__c = winnerCont.Last_Responded_Campaign__c;

            ilib_LogEvent.message('cont.Waterfall_Stage__c: ' + cont.Waterfall_Stage__c);

        }

        ilib_LogEvent.pop();

    }

}