/**
 *   @author: Deep Diwakar
*    @date:   Jan-17-2024
*    @description: Custom rest api for inserting Tascan Affiliation records
*    @Test Class: TestTSAffiliationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024        Custom rest api for inserting Tascan Affiliation records
*         Deep Diwakar       Feb-07-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
 */

@RestResource(urlMapping = '/TSAffiliationSyncInterface/*')
global with sharing class TSAffiliationDataReceiver extends ilib_RestReceiver {
    private static List<TSAffiliationDataWrapper> lstAffiliationWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: Post method for upserting Tascan Affiliation records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSAffiliationDataReceiver instantiated = new TSAffiliationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;

        String strJsonInput = String.isNotBlank(RestContext.request.requestBody.toString()) ? RestContext.request.requestBody.toString() : null;
       
        ilib_LogEvent.info('JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try {
            if (String.isBlank(strJsonInput)) {
                throw new UtilsRest.InterfaceException('Input JSON is missing');
            } 

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, lstAffiliationWrapper);

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
     * @date: Jan-17-2024
     * @description: Deserialize input to wrapper
     * @param: json input string
     * @return: void
     */
    global static void deserializeInputs(String jsonInput) {
        lstAffiliationWrapper = (List<TSAffiliationDataWrapper>) System.JSON.deserialize(jsonInput, List<TSAffiliationDataWrapper>.class);
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: This method runs logic for selecting data for insert
     * @param: json input string
     * @return: void
     */
    private static void upsertIncomingValuesImpl() {
        Set<String> setContTascanId = new Set<String>();
        Set<String> setAffiliationTascanId = new Set<String>();
        List<openq__OPENQ_Affiliation__c> lstAffiliationToInsert = new List<openq__OPENQ_Affiliation__c>();
 
        for (TSAffiliationDataWrapper wrapper : lstAffiliationWrapper) {
            setContTascanId.add(String.valueOf(wrapper.per_id));
            setAffiliationTascanId.add(String.valueOf(wrapper.organisation_id));
        }

        ilib_LogEvent.info('incoming setContTascanId: ' + setContTascanId);
        ilib_LogEvent.info('incoming setAffiliationTascanId: ' + setAffiliationTascanId);

        List<openq__OPENQ_Affiliation__c> lstExistingAffiliations = new List<openq__OPENQ_Affiliation__c>();
        lstExistingAffiliations = [Select Id, openq__Affiliation_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                    FROM  openq__OPENQ_Affiliation__c
                                    WHERE openq__Affiliation_Tascan_ID__c IN : setAffiliationTascanId LIMIT 10000];
        
        ilib_LogEvent.info('lstExistingAffiliations: ' + lstExistingAffiliations);   

        Map<String, List<openq__OPENQ_Affiliation__c>> mapTascanIdToPrst = new Map<String, List<openq__OPENQ_Affiliation__c>>();
    
        mapTascanIdToPrst = UtilsCollection.getMapOfStringToSObjects(lstExistingAffiliations, 'openq__Affiliation_Tascan_ID__c');
        
        for (TSAffiliationDataWrapper wrapper : lstAffiliationWrapper) {
            if (mapTascanIdToPrst.containsKey(String.valueOf(wrapper.organisation_id))) {
                // if affiliation record exist then check if incoming contact has that affiliation record already linked or not
                if (!checkExtAflnForIncomingContact(wrapper, mapTascanIdToPrst.get(String.valueOf(wrapper.organisation_id)))) {
                    addNewAffiliationRecord(wrapper, lstAffiliationToInsert);
                }
            } else {
                // add new affiliation record in insert list
                addNewAffiliationRecord(wrapper, lstAffiliationToInsert);
            }

        }

        // insert all records here
        ilib_LogEvent.info('lstAffiliationToInsert: ' + lstAffiliationToInsert);
        if (!lstAffiliationToInsert.isEmpty()) {
            Database.SaveResult[] resultList = Database.insert(lstAffiliationToInsert, false);
            ApexExceptions.emitSaveErrors(resultList, 'TSAffiliationDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: This method check if contact already has incoming presentation record
     * @param: wrapper - TSAffiliationDataWrapper wrapper object 
     * @param: lstExtAffiliation - list of existing affiliation records
     * @return: void
     */
    private static Boolean checkExtAflnForIncomingContact(TSAffiliationDataWrapper wrapper, List<openq__OPENQ_Affiliation__c> lstExtAffiliation) {
        ilib_LogEvent.message('method - checkExtPrstForIncomingContact: ');
        Boolean isAflnExistForIncomingCont = false;
        for (openq__OPENQ_Affiliation__c affiliation : lstExtAffiliation) {
            String extAflnTascanId = affiliation.openq__Contact_Name__r.openq__TaScanID__c;

            ilib_LogEvent.message('extAflnTascanId: ' + extAflnTascanId);
            ilib_LogEvent.message('wrapper.per_id: ' + wrapper.per_id);

            if (String.isBlank(extAflnTascanId)) {
                continue;
            }

            if (extAflnTascanId.equals(String.valueOf(wrapper.per_id))) {
                ilib_LogEvent.message('method-checkExtAflnForIncomingContact : extAflnTascanId- ' + extAflnTascanId);
                isAflnExistForIncomingCont = true;
                break;
            }

        }

        ilib_LogEvent.message('isAflnExistForIncomingCont: ' + isAflnExistForIncomingCont);
        return isAflnExistForIncomingCont;

    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: This method adds new presentation record to insert list
     * @param: wrapper - TSAffiliationDataWrapper wrapper object 
     * @param: lstAffiliationToInsert - list of presentation records that are going to be inserted
     * @return: void
     */
    private static void addNewAffiliationRecord(TSAffiliationDataWrapper wrapper, List<openq__OPENQ_Affiliation__c> lstAffiliationToInsert) {
        ilib_LogEvent.message('method - addNewAffiliationRecord');
        ilib_LogEvent.message('lstAffiliationToInsert: ' + lstAffiliationToInsert);

        // create new record object
        openq__OPENQ_Affiliation__c aflnNew = new openq__OPENQ_Affiliation__c();
        aflnNew.Name = wrapper.known_associated_organization_name;
        aflnNew.openq__Website__c = String.valueOf(wrapper.organization_url);
        aflnNew.openq__First_Year__c = String.valueOf(wrapper.first_year_at_known_associated_organization);
        aflnNew.openq__Last_Year__c = String.valueOf(wrapper.last_year_at_known_associated_organization);
        aflnNew.openq__Affiliation_Tascan_ID__c = String.valueOf(wrapper.organisation_id);
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(wrapper.per_id));
        aflnNew.openq__Contact_Name__r = parentContact;

        // add for insertion
        lstAffiliationToInsert.add(aflnNew);

    }

}