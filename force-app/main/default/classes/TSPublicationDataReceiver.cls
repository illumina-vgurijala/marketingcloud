/**
 *   @author: Deep Diwakar
*    @date:   Jan-25-2024
*    @description: Custom rest api for inserting Tascan Publication records
*    @Test Class: TestTSPublicationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-25-2024        Custom rest api for inserting Tascan Publication records
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
 */

 @RestResource(urlMapping = '/TSPublicationSyncInterface/*')
global with sharing class TSPublicationDataReceiver extends ilib_RestReceiver {
    private static List<TSPublicationDataWrapper> lstPublicationWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Jan-25-2024
     * @description: Post method for upserting Tascan Publication records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSPublicationDataReceiver instantiated = new TSPublicationDataReceiver();
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
            instantiated.addFriendlyJsonToLog(log, lstPublicationWrapper);

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
     * @date: Jan-25-2024
     * @description: Deserialize input to wrapper
     * @param: json input string
     * @return: void
     */
    global static void deserializeInputs(String jsonInput) {
        lstPublicationWrapper = (List<TSPublicationDataWrapper>) System.JSON.deserialize(jsonInput, List<TSPublicationDataWrapper>.class);
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-25-2024
     * @description: This method runs logic for selecting data for insert
     * @param: json input string
     * @return: void
     */
    private static void upsertIncomingValuesImpl() {
        Set<String> setContTascanId = new Set<String>();
        Set<String> setPublicationTascanId = new Set<String>();
        List<openq__OPENQ_Publication__c> pubToInsert = new List<openq__OPENQ_Publication__c>();
 
        for (TSPublicationDataWrapper wrapper : lstPublicationWrapper) {
            setContTascanId.add(String.valueOf(wrapper.per_id));
            setPublicationTascanId.add(String.valueOf(wrapper.publication_id));
        }

        ilib_LogEvent.info('incoming setContTascanId: ' + setContTascanId);
        ilib_LogEvent.info('incoming setPublicationTascanId: ' + setPublicationTascanId);

        List<openq__OPENQ_Publication__c> lstExistingPublications = new List<openq__OPENQ_Publication__c>();
        lstExistingPublications = [Select Id, openq__Publication_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                    FROM  openq__OPENQ_Publication__c
                                    WHERE openq__Publication_Tascan_ID__c IN : setPublicationTascanId LIMIT 1000];
        
        ilib_LogEvent.info('lstExistingPublications: ' + lstExistingPublications);   

        Map<String, List<openq__OPENQ_Publication__c>> mapTascanIdToPub = new Map<String, List<openq__OPENQ_Publication__c>>();
    
        mapTascanIdToPub = UtilsCollection.getMapOfStringToSObjects(lstExistingPublications, 'openq__Publication_Tascan_ID__c');
        
        for (TSPublicationDataWrapper wrapper : lstPublicationWrapper) {
            if (mapTascanIdToPub.containsKey(String.valueOf(wrapper.publication_id))) {
                // if publication record exist then check if incoming contact has that publication record already linked or not
                if (!checkExtPubForIncomingContact(wrapper, mapTascanIdToPub.get(String.valueOf(wrapper.publication_id)))) {
                    addNewPubRecord(wrapper, pubToInsert);
                }
            } else {
                // add new publication record in insert list
                addNewPubRecord(wrapper, pubToInsert);
            }

        }

        // insert all records here
        ilib_LogEvent.info('pubToInsert: ' + pubToInsert);
        if (!pubToInsert.isEmpty()) {
            Database.SaveResult[] resultList = Database.insert(pubToInsert, false);
            ApexExceptions.emitSaveErrors(resultList, 'TSPublicationDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-25-2024
     * @description: This method check if contact already has incoming publication record
     * @param: wrapper - TSPublicationDataWrapper wrapper object 
     * @param: lstExtPub - list of existing publication records
     * @return: void
     */
    private static Boolean checkExtPubForIncomingContact(TSPublicationDataWrapper wrapper, List<openq__OPENQ_Publication__c> lstExtPub) {
        ilib_LogEvent.message('method - checkExtPubForIncomingContact: ');
        Boolean isPubExistForIncomingCont = false;
        for (openq__OPENQ_Publication__c pub : lstExtPub) {
            String extPubTascanId = pub.openq__Contact_Name__r.openq__TaScanID__c;

            ilib_LogEvent.message('extPubTascanId: ' + extPubTascanId);
            ilib_LogEvent.message('wrapper.per_id: ' + wrapper.per_id);

            if (String.isBlank(extPubTascanId)) {
                continue;
            }

            if (extPubTascanId.equals(String.valueOf(wrapper.per_id))) {
                ilib_LogEvent.message('method-checkExtPubForIncomingContact : extPubTascanId- ' + extPubTascanId);
                isPubExistForIncomingCont = true;
                break;
            }

        }

        ilib_LogEvent.message('isPubExistForIncomingCont: ' + isPubExistForIncomingCont);
        return isPubExistForIncomingCont;

    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-25-2024
     * @description: This method adds new publication record to insert list
     * @param: wrapper - TSPublicationDataWrapper wrapper object 
     * @param: lstExtPub - list of publication records that are going to be inserted
     * @return: void
     */
    private static void addNewPubRecord(TSPublicationDataWrapper wrapper, List<openq__OPENQ_Publication__c> pubToInsert) {
        ilib_LogEvent.message('method - addNewPubRecord');
        ilib_LogEvent.message('pubToInsert: ' + pubToInsert);

        // create new record object
        openq__OPENQ_Publication__c pubNew = new openq__OPENQ_Publication__c();
        pubNew.openq__Author__c = wrapper.authors;
        pubNew.openq__Publication_URL__c = wrapper.publication_url;
        pubNew.openq__Journal__c = wrapper.journal_name;
        pubNew.openq__Publication_Tascan_ID__c = String.valueOf(wrapper.publication_id);
        pubNew.openq__Publication_Title__c = wrapper.publication_title;
        pubNew.openq__Author_Position__c = wrapper.author_order;
        String pubDate = wrapper.publication_date;
        pubNew.openq__Publication_Date__c = pubDate?.substring(0,4);
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(wrapper.per_id));
        pubNew.openq__Contact_Name__r = parentContact;

        // add for insertion
        pubToInsert.add(pubNew);

    }

}