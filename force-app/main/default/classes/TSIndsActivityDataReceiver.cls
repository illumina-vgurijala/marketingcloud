/**
 *   @author: Deep Diwakar
*    @date:   Feb-02-2024
*    @description: Custom rest api for inserting Tascan Industry Activity records
*    @Test Class: TestTSIndsActivityDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-02-2024        Custom rest api for inserting Tascan Industry Activity records
*    --------------------------------------------------------------------------------------------------
*/

@RestResource(urlMapping = '/TSIndustryActivitySyncInterface/*')
global with sharing class TSIndsActivityDataReceiver extends ilib_RestReceiver {
    private static List<TSIndsActivityDataWrapper> lstIndsActivityWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Feb-02-2024
     * @description: Post method for upserting Tascan Industry Activity records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSIndsActivityDataReceiver instantiated = new TSIndsActivityDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name, ilib_LogEvent.MARKETING);

        String strRestError = null;

        String strJsonInput = String.isNotBlank(RestContext.request.requestBody.toString()) ? RestContext.request.requestBody.toString() : null;
       
        ilib_LogEvent.info('JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try {
            if (String.isBlank(strJsonInput)) {
                throw new UtilsRest.InterfaceException('Input JSON is missing');
            } 

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, lstIndsActivityWrapper);

            // method to do perform logic
            upsertIncomingValuesImpl();

        } catch(Exception e) {
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess) {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError)
        );
 
        if (!isSuccess) {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, null, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }

        ilib_LogEvent.emit();
    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-02-2024
     * @description: Deserialize input to wrapper
     * @param: json input string
     * @return: void
     */
    global static void deserializeInputs(String jsonInput) {
        lstIndsActivityWrapper = (List<TSIndsActivityDataWrapper>) System.JSON.deserialize(jsonInput, List<TSIndsActivityDataWrapper>.class);
    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-02-2024
     * @description: This method runs logic for selecting data for insert
     * @param: json input string
     * @return: void
     */
    private static void upsertIncomingValuesImpl() {
        Set<String> setContTascanId = new Set<String>();
        Set<String> setIndsActivityTascanId = new Set<String>();
        List<openq__OPENQ_Industry_Activity__c> indsActToInsert = new List<openq__OPENQ_Industry_Activity__c>();
 
        for (TSIndsActivityDataWrapper wrapper : lstIndsActivityWrapper) {
            setContTascanId.add(String.valueOf(wrapper.per_id));
            setIndsActivityTascanId.add(String.valueOf(wrapper.organisation_id));
        }

        ilib_LogEvent.info('incoming setContTascanId: ' + setContTascanId);
        ilib_LogEvent.info('incoming setIndsActivityTascanId: ' + setIndsActivityTascanId);

        List<Contact> lstContacts = new List<Contact>();
        lstContacts = [SELECT Id, openq__TaScanID__c, (SELECT Id, openq__IndustryActivity_Tascan_ID__c,
                                                        openq__Exp_Date__c, openq__Amount__c
                                                        FROM openq__Industry_Activities__r)
                        FROM Contact WHERE  openq__TaScanID__c IN : setContTascanId];
        
        ilib_LogEvent.info('lstContacts size: ' + lstContacts.size());  

        if (lstContacts.isEmpty()) {
            return;
        }

        Map<String, Sobject> mapTascanIdToContact = new Map<String, Contact>();
        mapTascanIdToContact = UtilsCollection.getMapOfStringToSObject(lstContacts, 'openq__TaScanID__c', Map<String, Contact>.class);

        // loop over incoming wrapper list to check and insert industry activity records
        for (TSIndsActivityDataWrapper wrapper : lstIndsActivityWrapper) {
            if (mapTascanIdToContact.containsKey(String.valueOf(wrapper.per_id))) {

                // get existing contact
                Contact extCont = (Contact) mapTascanIdToContact.get(String.valueOf(wrapper.per_id));

                // get existing industry activity records for that contact
                List<openq__OPENQ_Industry_Activity__c> lstExtIndsAct = extCont.openq__Industry_Activities__r;

                // check if incoming industry activity already exist with right contact or not. If it doesn't
                // exist then prepare for insertion
                if (!checkExtIndsActForIncomingContact(wrapper, lstExtIndsAct)) {
                    addNewIndsActRecord(wrapper, indsActToInsert);
                }
            }

        }

        // insert all records here
        ilib_LogEvent.info('indsActToInsert size: ' + indsActToInsert.size());
        ilib_LogEvent.message('indsActToInsert: ' + indsActToInsert);
        if (!indsActToInsert.isEmpty()) {
            Database.SaveResult[] resultList = Database.insert(indsActToInsert, false);
            ApexExceptions.emitSaveErrors(resultList, 'TSIndsActivityDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-02-2024
     * @description: This method check if contact already has incoming industry activity record
     * @param: wrapper - TSIndsActivityDataWrapper wrapper object 
     * @param: lstExtIndsAct - list of existing industry activity records
     * @return: void
     */
    private static Boolean checkExtIndsActForIncomingContact(TSIndsActivityDataWrapper wrapper, List<openq__OPENQ_Industry_Activity__c> lstExtIndsAct) {
        ilib_LogEvent.message('method - checkExtIndsActForIncomingContact: ');
        Boolean isIndsActExistForIncomingCont = false;
        for (openq__OPENQ_Industry_Activity__c indsAct : lstExtIndsAct) {
            String extIndsActTascanId = indsAct.openq__IndustryActivity_Tascan_ID__c;
            String extIndsActExpDate = indsAct.openq__Exp_Date__c;
            String extIndsActAmount = indsAct.openq__Amount__c;

            ilib_LogEvent.message('extIndsActTascanId: ' + extIndsActTascanId);
            ilib_LogEvent.message('extIndsActAmount: ' + extIndsActAmount);
            ilib_LogEvent.message('extIndsActExpDate: ' + extIndsActExpDate);
            ilib_LogEvent.message('wrapper.organisation_id: ' + wrapper.organisation_id);
            ilib_LogEvent.message('wrapper.fee_disclosure_amount_in_dollars: ' + wrapper.fee_disclosure_amount_in_dollars);
            ilib_LogEvent.message('wrapper.fee_disclosure_period: ' + wrapper.fee_disclosure_period);

            if (Integer.valueOf(extIndsActTascanId) == wrapper.organisation_id 
                    && Integer.valueOf(extIndsActAmount) == wrapper.fee_disclosure_amount_in_dollars
                    && String.isNotBlank(extIndsActExpDate)
                    && extIndsActExpDate.equals(wrapper.fee_disclosure_period)) {
                        ilib_LogEvent.message('match found');
                        isIndsActExistForIncomingCont = true;
                        break;
            }

        }

        ilib_LogEvent.message('isIndsActExistForIncomingCont: ' + isIndsActExistForIncomingCont);
        return isIndsActExistForIncomingCont;

    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-02-2024
     * @description: This method adds new industry activity record to insert list
     * @param: wrapper - TSIndsActivityDataWrapper wrapper object 
     * @param: lstExtIndsAct - list of industry activity records that are going to be inserted
     * @return: void
     */
    private static void addNewIndsActRecord(TSIndsActivityDataWrapper wrapper, List<openq__OPENQ_Industry_Activity__c> indsActToInsert) {
        ilib_LogEvent.message('method - addNewIndsActRecord');
        ilib_LogEvent.message('wrapper: ' + wrapper);
        // create new record object
        openq__OPENQ_Industry_Activity__c indsActNew = new openq__OPENQ_Industry_Activity__c();
        indsActNew.openq__Description__c = wrapper.organization_name;
        indsActNew.openq__Amount__c = String.valueOf(wrapper.fee_disclosure_amount_in_dollars);
        indsActNew.openq__Exp_Date__c = wrapper.fee_disclosure_period;
        indsActNew.openq__IndustryActivity_Tascan_ID__c = String.valueOf(wrapper.organisation_id);
        indsActNew.openq__Experience_Type__c = wrapper.fee_disclosure_purpose;
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(wrapper.per_id));
        indsActNew.openq__Contact_Name__r = parentContact;

        // add for insertion
        indsActToInsert.add(indsActNew);

    }
}