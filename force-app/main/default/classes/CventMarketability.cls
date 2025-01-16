/**
*    @author: Deep Diwakar
*    @date:   May-22-2024 
*    @description: Marketability logic for Cvent generated/updated Lead and contact
*    @Test Class: TestMarketabilityServiceFacade
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       May-22-2024        CMCM-7994: Adding Cvent opt in logic here  
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class CventMarketability {

    private static final String CVENT_OPT_IN = 'Cvent_Opt_In__c';
    private static final String CVENT_OPT_IN_CHANGE_DATE = 'Cvent_Opt_In_Change_Date__c';
    private static final String CVENT_CONTACT_ME = 'Cvent_Contact_Me__c';
    private static final String CVENT_CONTACT_ME_DATE = 'Cvent_Contact_Me_Date__c';
    private static final String YES = 'Yes';
    private static final String MARKETABLE = 'Marketable__c';
    private static final String LOG_TITLE = 'CventMarketability';



    /**
     * @author: Deep Diwakar
     * @date: May-22-2024 
     * @description: CMCM-7994: This method calculates opt in values for Cvent generated/updated lead/contacts
     * @param: objRecord - sObject (Lead/Contact) record
     * @return: void
     */
    public void calculateCventMarketability (List<sObject> lstRecords) {

        ilib_LogEvent.push(LOG_TITLE + '.calculateCventMarketability()');

        for (sObject objRecord : lstRecords) {
        
            // get fields
            String cventOptIn = (String) objRecord.get(CVENT_OPT_IN);
            String cventContactMe = (String) objRecord.get(CVENT_CONTACT_ME);
            Id recordId = (Id) objRecord.get('Id');

            if (Trigger.IsInsert) {
                ilib_LogEvent.message('cvent insert scenario');
                if (String.isNotBlank(cventOptIn)) {
                    objRecord.put(CVENT_OPT_IN_CHANGE_DATE, Date.today());
                }
                if (YES.equalsIgnoreCase(cventContactMe)) {
                    objRecord.put(CVENT_CONTACT_ME_DATE, Date.today());
                }

            } else if (Trigger.IsUpdate) {
                ilib_LogEvent.message('cvent update scenario');
                sObject oldRecord = Trigger.oldMap.get(recordId);
                String oldCventOptIn = (String) oldRecord.get(CVENT_OPT_IN);
                String oldCventContactMe = (String) oldRecord.get(CVENT_CONTACT_ME);
                String oldMarketable = (String) oldRecord.get(MARKETABLE);

                if (String.isNotBlank(cventOptIn) && (!cventOptIn.equals(oldCventOptIn) || !cventOptIn.equals(oldMarketable))) {
                    objRecord.put(CVENT_OPT_IN_CHANGE_DATE, Date.today());
                }

                if (String.isNotBlank(cventContactMe) && YES.equals(cventContactMe)
                        && !cventContactMe.equals(oldCventContactMe)) {
                    objRecord.put(CVENT_CONTACT_ME_DATE, Date.today());

                }

            }

        }

        ilib_LogEvent.pop();

    }

}