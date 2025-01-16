/**
 *   @author: Deep Diwakar
*    @date:   Jan-31-2024
*    @description: Custom rest api for upserting Tascan Trial records
*    @Test Class: TestTSTrialDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-31-2024        Custom rest api for upserting Tascan Trial records
*         Deep Diwakar       Feb-12-2024        Corrected mapping and fixed null pointer exception
*         Deep Diwakar       Feb-12-2024        Fixed UAT issue - duplicate records in list update
*    --------------------------------------------------------------------------------------------------
 */

@RestResource(urlMapping = '/TSTrialSyncInterface/*')
global with sharing class TSTrialDataReceiver extends ilib_RestReceiver {
    private static List<TSTrialDataWrapper> lstTrialWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Jan-31-2024
     * @description: Post method for upserting Tascan Trial records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSTrialDataReceiver instantiated = new TSTrialDataReceiver();
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
            instantiated.addFriendlyJsonToLog(log, lstTrialWrapper);

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
     * @date: Jan-31-2024
     * @description: Deserialize input to wrapper
     * @param: json input string
     * @return: void
     */
    global static void deserializeInputs(String jsonInput) {
        lstTrialWrapper = (List<TSTrialDataWrapper>) System.JSON.deserialize(jsonInput, List<TSTrialDataWrapper>.class);
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-31-2024
     * @description: This method runs logic for selecting data for upsert
     * @param: json input string
     * @return: void
     */
    private static void upsertIncomingValuesImpl() {
        Set<String> setContTascanId = new Set<String>();
        Set<String> setTrialTascanId = new Set<String>();
        List<openq__OPENQ_Trial__c> trialToUpsert = new List<openq__OPENQ_Trial__c>();
 
        for (TSTrialDataWrapper wrapper : lstTrialWrapper) {
            setContTascanId.add(String.valueOf(wrapper.per_id));
            setTrialTascanId.add(String.valueOf(wrapper.trial_id));
        }

        ilib_LogEvent.info('incoming setContTascanId: ' + setContTascanId);
        ilib_LogEvent.info('incoming setTrialTascanId: ' + setTrialTascanId);

        List<openq__OPENQ_Trial__c> lstExistingTrials = new List<openq__OPENQ_Trial__c>();
        lstExistingTrials = [Select Id, openq__Trial_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                    FROM  openq__OPENQ_Trial__c
                                    WHERE openq__Trial_Tascan_ID__c IN : setTrialTascanId LIMIT 1000];
        
        ilib_LogEvent.info('lstExistingTrials: ' + lstExistingTrials);   

        Map<String, List<openq__OPENQ_Trial__c>> mapTascanIdToTrial = new Map<String, List<openq__OPENQ_Trial__c>>();
    
        mapTascanIdToTrial = UtilsCollection.getMapOfStringToSObjects(lstExistingTrials, 'openq__Trial_Tascan_ID__c');
        
        for (TSTrialDataWrapper wrapper : lstTrialWrapper) {
            if (mapTascanIdToTrial.containsKey(String.valueOf(wrapper.trial_id))) {
                // if trial record exist then check if incoming contact has that trial record already linked or not
                if (!checkExtTrialForIncomingContact(wrapper, mapTascanIdToTrial.get(String.valueOf(wrapper.trial_id)), trialToUpsert)) {
                    addNewTrialRecord(wrapper, trialToUpsert);
                } 
            } else {
                // add new trial record in upsert list
                addNewTrialRecord(wrapper, trialToUpsert);
            }

        }

        // upsert all records here
        ilib_LogEvent.info('trialToUpsert: ' + trialToUpsert);
        if (!trialToUpsert.isEmpty()) {
            Database.UpsertResult[] resultList = Database.upsert(trialToUpsert, false);
            ApexExceptions.emitUpsertErrors(resultList, 'TSTrialDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-31-2024
     * @description: This method check if contact already has incoming trial record
     * @param: wrapper - TSTrialDataWrapper wrapper object 
     * @param: lstExtTrial - list of existing trial records
     * @return: void
     */
    private static Boolean checkExtTrialForIncomingContact(TSTrialDataWrapper wrapper, List<openq__OPENQ_Trial__c> lstExtTrial, List<openq__OPENQ_Trial__c> trialToUpsert) {
        ilib_LogEvent.message('method - checkExtTrialForIncomingContact: ');
        Boolean isTrialExistForIncomingCont = false;
        for (openq__OPENQ_Trial__c trial : lstExtTrial) {
            String extTrialTascanId = trial.openq__Contact_Name__r.openq__TaScanID__c;

            ilib_LogEvent.message('extTrialTascanId: ' + extTrialTascanId);
            ilib_LogEvent.message('wrapper.per_id: ' + wrapper.per_id);

            if (String.isBlank(extTrialTascanId)) {
                continue;
            }

            if (extTrialTascanId.equals(String.valueOf(wrapper.per_id))) {
                ilib_LogEvent.message('method-checkExtTrialForIncomingContact : extTrialTascanId- ' + extTrialTascanId);
                
                // Update existing record with new trial values
                updateTrialRecord(wrapper, trial, trialToUpsert);
                isTrialExistForIncomingCont = true;
                break;
            }

        }

        ilib_LogEvent.message('isTrialExistForIncomingCont: ' + isTrialExistForIncomingCont);
        return isTrialExistForIncomingCont;

    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-31-2024
     * @description: This method adds new trial record to upsert list
     * @param: wrapper - TSTrialDataWrapper wrapper object 
     * @param: trialToUpsert - list of trial records that are going to be inserted
     * @return: void
     */
    private static void addNewTrialRecord(TSTrialDataWrapper wrapper, List<openq__OPENQ_Trial__c> trialToUpsert) {
        ilib_LogEvent.message('method - addNewTrialRecord');
        ilib_LogEvent.message('trialToUpsert: ' + trialToUpsert);

        // create new record object
        openq__OPENQ_Trial__c trialNew = new openq__OPENQ_Trial__c();
        trialNew.openq__Trial_Sponsors__c = wrapper.sponsors;
        trialNew.openq__Trial_URL__c = wrapper.trial_url;
        trialNew.openq__TrialID_Number__c = wrapper.trial_registry_id;
        trialNew.openq__Trial_Tascan_ID__c = String.valueOf(wrapper.trial_id);
        trialNew.openq__Full_Trial_Name__c = wrapper.trial_name;
        trialNew.openq__Trial_Sites__c = wrapper.number_of_sites;
        trialNew.openq__Trial_Type__c = wrapper.study_type;
        trialNew.openq__Therapy__c = wrapper.therapy_treatment;
        trialNew.openq__Trial_Description__c = wrapper.trial_purpose;
        trialNew.openq__Status__c = wrapper.state;
        trialNew.openq__Primary_Outcome__c = wrapper.primary_outcomes;
        trialNew.openq__Phase__c = wrapper.phase;
        trialNew.openq__Enrollment__c = wrapper.enrollment;
        trialNew.openq__Gender__c = wrapper.trial_participant_gender_restriction;
        trialNew.openq__Start_Date__c = wrapper.study_start?.substringBefore('T');
        trialNew.openq__End_Date__c = wrapper.study_end?.substringBefore('T');
        trialNew.openq__Maximum_Age__c = wrapper.maximum_age;
        trialNew.openq__Minimum_Age__c = wrapper.minimum_age;
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(wrapper.per_id));
        trialNew.openq__Contact_Name__r = parentContact;

        // add for upsert
        trialToUpsert.add(trialNew);

    }

        /**
     * @author: Deep Diwakar
     * @date: Jan-31-2024
     * @description: This method adds trial records for update
     * @param: wrapper - TSTrialDataWrapper wrapper object 
     * @param: extTrial - existing trial record
     * @param: trialToUpsert - list of trial records that are going to be upserted
     * @return: void
     */
    private static void updateTrialRecord(TSTrialDataWrapper wrapper, openq__OPENQ_Trial__c extTrial, List<openq__OPENQ_Trial__c> trialToUpsert) {
        ilib_LogEvent.message('method - updateTrialRecord: ');

        openq__OPENQ_Trial__c trialUpdate = new openq__OPENQ_Trial__c();
        trialUpdate.Id = extTrial.Id;
        trialUpdate.openq__End_Date__c = wrapper.study_end?.substringBefore('T');
        trialUpdate.openq__Enrollment__c = wrapper.enrollment;
        trialUpdate.openq__Phase__c = wrapper.phase;
        trialUpdate.openq__Primary_Outcome__c = wrapper.primary_outcomes;
        trialUpdate.openq__Status__c = wrapper.state;
        trialUpdate.openq__Trial_Sites__c = wrapper.number_of_sites;

        // add for update
        trialToUpsert.add(trialUpdate);

    }

}