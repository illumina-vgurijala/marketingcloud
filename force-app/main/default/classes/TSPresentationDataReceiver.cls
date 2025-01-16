/**
 *   @author: Deep Diwakar
*    @date:   Jan-17-2024
*    @description: Custom rest api for inserting Tascan Presentation records
*    @Test Class: TestTSPresentationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024        Custom rest api for inserting Tascan Presentation records
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
 */

@RestResource(urlMapping = '/TSPresentationSyncInterface/*')
global with sharing class TSPresentationDataReceiver extends ilib_RestReceiver {

    private static List<TSPresentationDataWrapper> lstPresentationWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: Post method for upserting Tascan Presentation records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSPresentationDataReceiver instantiated = new TSPresentationDataReceiver();
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
            instantiated.addFriendlyJsonToLog(log, lstPresentationWrapper);

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
        lstPresentationWrapper = (List<TSPresentationDataWrapper>) System.JSON.deserialize(jsonInput, List<TSPresentationDataWrapper>.class);
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
        Set<String> setPresentationTascanId = new Set<String>();
        List<openq__OPENQ_Presentation__c> prstToInsert = new List<openq__OPENQ_Presentation__c>();
 
        for (TSPresentationDataWrapper wrapper : lstPresentationWrapper) {
            setContTascanId.add(String.valueOf(wrapper.per_id));
            setPresentationTascanId.add(String.valueOf(wrapper.presentation_id));
        }

        ilib_LogEvent.info('incoming setContTascanId: ' + setContTascanId);
        ilib_LogEvent.info('incoming setPresentationTascanId: ' + setPresentationTascanId);

        List<openq__OPENQ_Presentation__c> lstExistingPresentations = new List<openq__OPENQ_Presentation__c>();
        lstExistingPresentations = [Select Id, openq__Presentation_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                    FROM  openq__OPENQ_Presentation__c
                                    WHERE openq__Presentation_Tascan_ID__c IN : setPresentationTascanId LIMIT 10000];
        
        ilib_LogEvent.info('lstExistingPresentations: ' + lstExistingPresentations);   

        Map<String, List<openq__OPENQ_Presentation__c>> mapTascanIdToPrst = new Map<String, List<openq__OPENQ_Presentation__c>>();
    
        mapTascanIdToPrst = UtilsCollection.getMapOfStringToSObjects(lstExistingPresentations, 'openq__Presentation_Tascan_ID__c');
        
        for (TSPresentationDataWrapper wrapper : lstPresentationWrapper) {
            if (mapTascanIdToPrst.containsKey(String.valueOf(wrapper.presentation_id))) {
                // if presentation record exist then check if incoming contact has that presentation record already linked or not
                if (!checkExtPrstForIncomingContact(wrapper, mapTascanIdToPrst.get(String.valueOf(wrapper.presentation_id)))) {
                    addNewPrstRecord(wrapper, prstToInsert);
                }
            } else {
                // add new presentation record in insert list
                addNewPrstRecord(wrapper, prstToInsert);
            }

        }

        // insert all records here
        ilib_LogEvent.info('prstToInsert: ' + prstToInsert);
        if (!prstToInsert.isEmpty()) {
            Database.SaveResult[] resultList = Database.insert(prstToInsert, false);
            ApexExceptions.emitSaveErrors(resultList, 'TSPresentationDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: This method check if contact already has incoming presentation record
     * @param: wrapper - TSPresentationDataWrapper wrapper object 
     * @param: lstExtPrst - list of existing presentation records
     * @return: void
     */
    private static Boolean checkExtPrstForIncomingContact(TSPresentationDataWrapper wrapper, List<openq__OPENQ_Presentation__c> lstExtPrst) {
        ilib_LogEvent.message('method - checkExtPrstForIncomingContact: ');
        Boolean isPrstExistForIncomingCont = false;
        for (openq__OPENQ_Presentation__c prst : lstExtPrst) {
            String extPrstTascanId = prst.openq__Contact_Name__r.openq__TaScanID__c;

            ilib_LogEvent.message('extPrstTascanId: ' + extPrstTascanId);
            ilib_LogEvent.message('wrapper.per_id: ' + wrapper.per_id);

            if (String.isBlank(extPrstTascanId)) {
                continue;
            }

            if (extPrstTascanId.equals(String.valueOf(wrapper.per_id))) {
                ilib_LogEvent.message('method-checkExtPrstForIncomingContact : extPrstTascanId- ' + extPrstTascanId);
                isPrstExistForIncomingCont = true;
                break;
            }

        }

        ilib_LogEvent.message('isPrstExistForIncomingCont: ' + isPrstExistForIncomingCont);
        return isPrstExistForIncomingCont;

    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-17-2024
     * @description: This method adds new presentation record to insert list
     * @param: wrapper - TSPresentationDataWrapper wrapper object 
     * @param: lstExtPrst - list of presentation records that are going to be inserted
     * @return: void
     */
    private static void addNewPrstRecord(TSPresentationDataWrapper wrapper, List<openq__OPENQ_Presentation__c> prstToInsert) {
        ilib_LogEvent.message('method - addNewPrstRecord');
        ilib_LogEvent.message('prstToInsert: ' + prstToInsert);

        // create new record object
        openq__OPENQ_Presentation__c prstNew = new openq__OPENQ_Presentation__c();
        prstNew.openq__Presenters__c = wrapper.presenters;
        prstNew.openq__Meeting_URL__c = wrapper.conference_url;
        prstNew.openq__Meeting_Name__c = wrapper.conference_name;
        prstNew.openq__Presentation_Type__c = wrapper.presentation_type;
        prstNew.openq__Presentation_Tascan_ID__c = String.valueOf(wrapper.presentation_id);
        prstNew.openq__Presentation_Title__c = wrapper.presentation_title;
        prstNew.openq__Position__c = wrapper.presentation_author_order;
        String confDate = wrapper.conference_start;
        prstNew.openq__Date__c = confDate.substringBefore('T');
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(wrapper.per_id));
        prstNew.openq__Contact_Name__r = parentContact;

        // add for insertion
        prstToInsert.add(prstNew);

    }

}
