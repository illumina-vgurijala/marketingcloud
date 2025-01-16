/**
 *   @author: Deep Diwakar
*    @date:   Feb-05-2024
*    @description: Custom rest api for upserting Tascan Contact records
*    @Test Class: TestTSContactDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-05-2024        Custom rest api for upserting Tascan Contact records
*         Deep Diwakar       Feb-12-2024        Corrected mapping, record type and updated instrumentation
*    --------------------------------------------------------------------------------------------------
*/

@RestResource(urlMapping = '/TSContactSyncInterface/*')
global with sharing class TSContactDataReceiver extends ilib_RestReceiver {
    private static List<TSContactDataWrapper> lstContactWrapper; 

    /**
     * @author: Deep Diwakar
     * @date: Feb-05-2024
     * @description: Post method for upserting Tascan Contact records
     * @param: NA
     * @return: void
     */
    @HttpPost
    global static void upsertIncomingValues() {
        // get the (non-static context) details
        TSContactDataReceiver instantiated = new TSContactDataReceiver();
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
            instantiated.addFriendlyJsonToLog(log, lstContactWrapper);

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
     * @date: Feb-05-2024
     * @description: Deserialize input to wrapper
     * @param: json input string
     * @return: void
     */
    global static void deserializeInputs(String jsonInput) {
        lstContactWrapper = (List<TSContactDataWrapper>) System.JSON.deserialize(jsonInput, List<TSContactDataWrapper>.class);
    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-05-2024
     * @description: This method runs logic for selecting data for upsert
     * @param: json input string
     * @return: void
     */
    private static void upsertIncomingValuesImpl() {
        Set<String> setContactTascanId = new Set<String>();
        List<Contact> lstContactToUpsert = new List<Contact>();
 
        for (TSContactDataWrapper wrapper : lstContactWrapper) {
            setContactTascanId.add(String.valueOf(wrapper.per_id));
        }

        ilib_LogEvent.info('incoming setContactTascanId: ' + setContactTascanId);

        List<Contact> lstExistingContacts = new List<Contact>();
        lstExistingContacts = [Select Id, openq__TaScanID__c FROM  Contact
                                    WHERE openq__TaScanID__c IN : setContactTascanId LIMIT 1000];
        
        ilib_LogEvent.info('lstExistingContacts size: ' + lstExistingContacts.size());  
        ilib_LogEvent.message('lstExistingContacts: ' + lstExistingContacts);

        Map<String, List<Contact>> mapTascanIdToContact = new Map<String, List<Contact>>();
    
        mapTascanIdToContact = UtilsCollection.getMapOfStringToSObjects(lstExistingContacts, 'openq__TaScanID__c');
        
        for (TSContactDataWrapper wrapper : lstContactWrapper) {
            if (mapTascanIdToContact.containsKey(String.valueOf(wrapper.per_id))) {
                // update existing contact with new info
                updateContactRecord(wrapper, mapTascanIdToContact.get(String.valueOf(wrapper.per_id)), lstContactToUpsert);
            } else {
                // add new contact record in insert list
                addNewContactRecord(wrapper, lstContactToUpsert);
            }

        }

        // upsert all records here
        ilib_LogEvent.info('lstContactToUpsert size: ' + lstContactToUpsert.size());
        ilib_LogEvent.message('lstContactToUpsert: ' + lstContactToUpsert);
        if (!lstContactToUpsert.isEmpty()) {
            Database.UpsertResult[] resultList = Database.upsert(lstContactToUpsert, false);
            ApexExceptions.emitUpsertErrors(resultList, 'TSContactDataReceiver');
        }
        
    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-05-2024
     * @description: This method adds new contact record to upsert list
     * @param: wrapper - TSContactDataWrapper wrapper object 
     * @param: lstContactToUpsert - list of contact records that are going to be inserted
     * @return: void
     */
    private static void addNewContactRecord(TSContactDataWrapper wrapper, List<Contact> lstContactToUpsert) {
        ilib_LogEvent.message('method - addNewContactRecord');
        ilib_LogEvent.message('wrapper: ' + wrapper);

        // create new record object
        Contact contactNew = new Contact();
        contactNew.FirstName = wrapper.person_first_name;
        contactNew.LastName = wrapper.person_name;
        contactNew.openq__Physician_Address_Line_1__c = wrapper.private_address_nice_name;
        contactNew.openq__Physician_Address_City__c = wrapper.location_name;
        contactNew.openq__Physician_Address_State__c = wrapper.private_address_region;
        contactNew.openq__TaScanID__c = String.valueOf(wrapper.per_id);
        contactNew.openq__Physician_Address_Postal_Code__c = wrapper.postcode;
        contactNew.openq__Physician_Address_Country__c = wrapper.private_address_country;
        contactNew.Phone = wrapper.telephone;
        contactNew.Email = wrapper.email;
        contactNew.Credentials__c = wrapper.person_title;
        contactNew.openq__OPENQ_Specialty1__c = wrapper.person_speciality;
        contactNew.openq__OPENQ_NPI_Number__c = wrapper.person_npi;
        contactNew.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('KOL').getRecordTypeId();

        // add for upsert
        lstContactToUpsert.add(contactNew);

    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-05-2024
     * @description: This method adds contact records for update
     * @param: wrapper - TSContactDataWrapper wrapper object 
     * @param: lstExtContact - list of existing contact records
     * @param: lstContactToUpsert - list of contact records that are going to be upserted
     * @return: void
     */
    private static void updateContactRecord(TSContactDataWrapper wrapper, List<Contact> lstExtContact, List<Contact> lstContactToUpsert) {
        ilib_LogEvent.message('method - updateContactRecord: ');

        for (Contact contUpdate : lstExtContact) {
            contUpdate.openq__Physician_Address_Line_1__c = wrapper.private_address_nice_name;
            contUpdate.openq__Physician_Address_City__c = wrapper.location_name;
            contUpdate.openq__Physician_Address_State__c = wrapper.private_address_region;
            contUpdate.openq__TaScanID__c = String.valueOf(wrapper.per_id);
            contUpdate.openq__Physician_Address_Postal_Code__c = wrapper.postcode;
            contUpdate.openq__Physician_Address_Country__c = wrapper.private_address_country;
            contUpdate.Phone = wrapper.telephone;
            contUpdate.Email = wrapper.email;
            contUpdate.Credentials__c = wrapper.person_title;
            contUpdate.openq__OPENQ_Specialty1__c = wrapper.person_speciality;
            contUpdate.openq__OPENQ_NPI_Number__c = wrapper.person_npi;

            // add for update
            lstContactToUpsert.add(contUpdate);
        }

    }

}