/**
*    @author: Deep Diwakar
*    @date:   May-28-2024 
*    @description: Marketability logic for Captello generated/updated Lead and contact
*    @Test Class: TestMarketabilityServiceFacade
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       May-28-2024        CMCM-7770: Adding Captello opt in logic here  
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class CaptelloMarketability {

    private static final String CAPTELLO_OPT_IN = 'Captello_Opt_In__c';
    private static final String CAPTELLO_OPT_IN_CHANGE_DATE = 'Captello_Opt_In_Change_Date__c';
    private static final String CAPTELLO_CONTACT_ME = 'Captello_Contact_Me__c';
    private static final String CAPTELLO_CONTACT_ME_DATE = 'Captello_Contact_Me_Date__c';
    private static final String YES = 'Yes';
    private static final String MARKETABLE = 'Marketable__c';
    private static final String LOG_TITLE = 'CaptelloMarketability';



    /**
     * @author: Deep Diwakar
     * @date: May-28-2024 
     * @description: CMCM-7770: This method calculates opt in values for Captello generated/updated lead/contacts
     * @param: objRecord - sObject (Lead/Contact) record
     * @return: void
     */
    public void calculateCaptelloMarketability (List<sObject> lstRecords) {

        ilib_LogEvent.push(LOG_TITLE + '.calculateCaptelloMarketability()');

        if (Trigger.IsInsert) {
            ilib_LogEvent.info('captello insert scenario');
            captelloMarketabilityForNew(lstRecords);
        }

        if (Trigger.IsUpdate) {
            ilib_LogEvent.info('captello update scenario');
            captelloMarketabilityForExisting(lstRecords, Trigger.oldMap);
        }

        ilib_LogEvent.pop();

    }

    /**
     * @author: Deep Diwakar
     * @date: May-31-2024 
     * @description: CMCM-7770: This method calculates opt in values for Captello for new lead/contacts
     * @param: objRecord - sObject (Lead/Contact) record
     * @return: void
     */
    public void captelloMarketabilityForNew(List<sObject> lstRecords) {

        ilib_LogEvent.push(LOG_TITLE + '.captelloMarketabilityForNew()');
        ilib_LogEvent.info('captello maketability insert scenario');

        for (sObject objRecord : lstRecords) {
        
            // get fields
            String cventOptIn = (String) objRecord.get(CAPTELLO_OPT_IN);
            String cventContactMe = (String) objRecord.get(CAPTELLO_CONTACT_ME);

            if (String.isNotBlank(cventOptIn)) {
                objRecord.put(CAPTELLO_OPT_IN_CHANGE_DATE, Date.today());
            }
            if (YES.equalsIgnoreCase(cventContactMe)) {
                objRecord.put(CAPTELLO_CONTACT_ME_DATE, Date.today());
            }
        }

        ilib_LogEvent.pop();

    }

    /**
     * @author: Deep Diwakar
     * @date: May-31-2024 
     * @description: CMCM-7770: This method calculates opt in values for Captello for existing lead/contacts
     * @param: objRecord - sObject (Lead/Contact) record
     * @param: oldRecordMap - sObject (Lead/Contact) record map for old records
     * @return: void
     */
    public void captelloMarketabilityForExisting(List<sObject> lstRecords, Map<Id, sObject> oldRecordMap) {

        ilib_LogEvent.push(LOG_TITLE + '.captelloMarketabilityForExisting()');
        ilib_LogEvent.message('captello maketability update scenario');

        for (sObject objRecord : lstRecords) {
            
            // get fields
            String cventOptIn = (String) objRecord.get(CAPTELLO_OPT_IN);
            String cventContactMe = (String) objRecord.get(CAPTELLO_CONTACT_ME);
            sObject oldRecord = oldRecordMap.get(objRecord.Id);
            String oldCaptelloOptIn = (String) oldRecord.get(CAPTELLO_OPT_IN);
            String oldCaptelloContactMe = (String) oldRecord.get(CAPTELLO_CONTACT_ME);
            String oldMarketable = (String) oldRecord.get(MARKETABLE);

            if (String.isNotBlank(cventOptIn) && (!cventOptIn.equals(oldCaptelloOptIn) || !cventOptIn.equals(oldMarketable))) {
                objRecord.put(CAPTELLO_OPT_IN_CHANGE_DATE, Date.today());
            }

            if (String.isNotBlank(cventContactMe) && YES.equals(cventContactMe)
                    && !cventContactMe.equals(oldCaptelloContactMe)) {
                objRecord.put(CAPTELLO_CONTACT_ME_DATE, Date.today());

            }
        }

        ilib_LogEvent.pop();


    }


}