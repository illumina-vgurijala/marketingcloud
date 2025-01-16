/**
 *   @author: Deep Diwakar
*    @date:   Mar-04-2024
*    @description: Concreate implementation of Marketability Strategy to determine sObject record Marketability 
*    @Test Class: TestMarketabilityServiceFacade
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-04-2024        CMCM-5551: Concreate implementation of Marketability Strategy
*         Deep Diwakar       Apr-30-2024        CMCM-7707: Updated setting of date field due to Pardot issue of
*                                                          not taking null updates
*         Deep Diwakar       May-22-2024        CMCM-7994: Added Cvent opt in logic flow and refactored code for n-path complexity 
*         Deep Diwakar       May-28-2024        CMCM-7770: Added Captello opt in logic flow
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class GlobalMarketabilityStrategyV1 implements IMarketabilityStrategy {

    private static final String EXPLICIT_OPT_IN = 'Explicit_Opt_In__c';
    private static final String IMPLICIT_OPT_IN = 'Implicit_Opt_In__c';
    private static final String DOUBLE_OPT_IN = 'Double_Opt_In__c';
    private static final String EXPLICIT_OPT_IN_DATE = 'Explicit_Opt_In_Date__c';
    private static final String IMPLICIT_OPT_IN_DATE = 'Implicit_Opt_In_Date__c';
    private static final String DOUBLE_OPT_IN_DATE = 'Double_Opt_In_Date__c';
    private static final String DOUBLE_OPT_IN_EMAIL_SENT_DATE = 'Double_Opt_In_Email_Sent_Date__c';
    private static final String MARKETABLE = 'Marketable__c';
    private static final String MARKETABLE_DATE = 'Marketable_Date__c';
    private static final String YES = 'Yes';
    private static final String NO = 'No';
    private static final String PARDOT_OPTED_OUT = 'Pardot_Opted_Out__c';
    private static final String SFDC_OPTED_OUT = 'HasOptedOutOfEmail';
    private static final String OPT_IN_RULE = 'Opt_in_Rule__c';
    private static final String UNKNOWN = 'Unknown';
    private static final String LOG_TITLE = 'GlobalMarketabilityStrategyV1';

    //CMCM-7994: User fields to check current user
    private static final String STRING_CVENT_INTEGRATION_USER ='Integration Cvent';
    private static final String STRING_CURRENT_USER = UserInfo.getname();

    //CMCM-7770: User name field to check captello user
    private static final String STRING_CAPTELLO_INTEGRATION_USER ='Integration Captello';



    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    public void calculateMarketability(List<sObject> lstRecords) {

        ilib_LogEvent.push(LOG_TITLE + '.calculateMarketability()');

        //CMCM-7994: if running user is cvent user then call Cvent marketability class
        if(STRING_CURRENT_USER.equals(STRING_CVENT_INTEGRATION_USER)) { 
            ilib_LogEvent.info('Cvent user: ' + STRING_CVENT_INTEGRATION_USER);
            CventMarketability cventMarketability = new CventMarketability();
            cventMarketability.calculateCventMarketability(lstRecords);
            ilib_LogEvent.pop();
            return;
        }

        //CMCM-7770: if running user is captello user then call Captello marketability class
        if(STRING_CURRENT_USER.equals(STRING_CAPTELLO_INTEGRATION_USER)) { 
            ilib_LogEvent.info('Captello user: ' + STRING_CAPTELLO_INTEGRATION_USER);
            CaptelloMarketability captelloMarketability = new CaptelloMarketability();
            captelloMarketability.calculateCaptelloMarketability(lstRecords);
            ilib_LogEvent.pop();
            return;
        }

        for (sObject objRecord : lstRecords) {

            // get fields
            Boolean pardotOptedOut = (Boolean) objRecord.get(PARDOT_OPTED_OUT);
            Boolean sfdcOptedOut = (Boolean) objRecord.get(SFDC_OPTED_OUT);
            String optInRule = (String) objRecord.get(OPT_IN_RULE);
            Datetime marketableDate = (Datetime) objRecord.get(MARKETABLE_DATE);

            ilib_LogEvent.message('optInRule: ' + optInRule);

            // first check if prospect has opted out or not
            if (pardotOptedOut || sfdcOptedOut) {

                ilib_LogEvent.message('opting out');

                // reset marketability
                objRecord.put(MARKETABLE, NO);

                // set all opt in to No and clear corresponding dates
                updatesOnOptOut(objRecord);

                continue;
            }

            // no opt in rule then we can't determing marketability
            if (String.isBlank(optInRule) || UNKNOWN.equals(optInRule)) {
                objRecord.put(MARKETABLE, NO);
                if (marketableDate != null) {
                    objRecord.put(MARKETABLE_DATE, null);
                }
                continue;
            }

            // method to check opt in rule and run its corresponding logic
            calculateOptInFields(objRecord, optInRule);

        }

        // set opt it dates
        setOptInDates(lstRecords);

        ilib_LogEvent.pop();
        
    }

    /**
     * @author: Deep Diwakar
     * @date: May-22-2024
     * @description: This method calculates marketability for given records
     * @param: objRecord - sObject record for calculation of marketability
     * @param: optInRule - opt in rule based on record country
     * @return: void
     */
    private void calculateOptInFields(sObject objRecord, String optInRule) {

        // opt in country single
        if ('Opt In Country Single'.equals(optInRule)) {
            // set marketability
           setMarketableForOptInCountrySingle(objRecord);
           return;

       }

       // opt out country single
       if ('Opt Out Country Single'.equals(optInRule)) {
           // set marketability
           setMarketableForOptOutCountrySingle(objRecord);
           return;
       }

       // opt in country double
       if ('Opt In Country Double'.equals(optInRule)) {
           // set marketability
           setMarketableForOptInCountryDouble(objRecord);
           return;

       }

       // opt out country double
       if ('Opt Out Country Double'.equals(optInRule)) {
           // set marketability
           setMarketableForOptOutCountryDouble(objRecord);
           return;
       }

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    private void setMarketableForOptInCountrySingle(sObject objRecord) {

        // get fields
        String explicitOptIn = (String) objRecord.get(EXPLICIT_OPT_IN);

        // decide marketablitiy
        if (YES.equals(explicitOptIn)) {
            objRecord.put(MARKETABLE, YES);
        } else {
            objRecord.put(MARKETABLE, NO);
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    private void setMarketableForOptOutCountrySingle(sObject objRecord) {

        // get fields
        String explicitOptIn = (String) objRecord.get(EXPLICIT_OPT_IN);
        String implicitOptIn = (String) objRecord.get(IMPLICIT_OPT_IN);

         // set marketability
         if (YES.equals(explicitOptIn) || YES.equals(implicitOptIn)) {
            objRecord.put(MARKETABLE, YES);
        } else {
            // need this block for lead/contact direclty created in SFDC. In this case they won't have
            // any value set for explicitOptIn and HasOptedOutOfEmail
            objRecord.put(MARKETABLE, NO);
           
        }

    }


    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    @TestVisible
    private void setMarketableForOptInCountryDouble(sObject objRecord) {

        // get fields
        String explicitOptIn = (String) objRecord.get(EXPLICIT_OPT_IN);
        String doubleOptIn = (String) objRecord.get(DOUBLE_OPT_IN);
        Datetime doubleOptInEmailSendDate = (Datetime) objRecord.get(DOUBLE_OPT_IN_EMAIL_SENT_DATE);

         // set marketability
         if (YES.equals(doubleOptIn)) {
            objRecord.put(MARKETABLE, YES);
             return;
        } else {
            objRecord.put(MARKETABLE, NO);
        }

        if (YES.equals(explicitOptIn)) {
            // check if double opt is email is sent or not. If not sent or passed 7 days then set field
            // to trigger email sent from Pardot
            if (doubleOptInEmailSendDate == null || doubleOptInEmailSendDate.addDays(7) < Datetime.now()) {
                objRecord.put('SendDoubleOptinConfirmation__c', true);
                objRecord.put(DOUBLE_OPT_IN_EMAIL_SENT_DATE, Datetime.now());
            } 
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    private void setMarketableForOptOutCountryDouble(sObject objRecord) {

        // get fields
        String explicitOptIn = (String) objRecord.get(EXPLICIT_OPT_IN);
        String implicitOptIn = (String) objRecord.get(IMPLICIT_OPT_IN);
        String doubleOptIn = (String) objRecord.get(DOUBLE_OPT_IN);
        Datetime doubleOptInEmailSendDate = (Datetime) objRecord.get(DOUBLE_OPT_IN_EMAIL_SENT_DATE);

        // set marketability
        if (YES.equals(doubleOptIn)) {
            objRecord.put(MARKETABLE, YES);
            return;
        } else {
            objRecord.put(MARKETABLE, NO);
        }

        // double opt in email check
        if (YES.equals(explicitOptIn) || YES.equals(implicitOptIn)) {
            // set double opt in date
            if (doubleOptInEmailSendDate == null || doubleOptInEmailSendDate.addDays(7) < Datetime.now()) {
                objRecord.put('SendDoubleOptinConfirmation__c', true);
                //objRecord.put(DOUBLE_OPT_IN_EMAIL_SENT_DATE, Datetime.now());
                objRecord.put(DOUBLE_OPT_IN_EMAIL_SENT_DATE, Datetime.newInstance(Date.today(), Time.newInstance(0,0,0,0)));

            } 
            
        }  

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    private void setOptInDates(List<sObject> lstSobjects) {

        ilib_LogEvent.info('setting opt in dates');

        for (sObject objRecord : lstSobjects) {

            // get opt in fields
            String explicitOptIn = (String) objRecord.get(EXPLICIT_OPT_IN);
            String implicitOptIn = (String) objRecord.get(IMPLICIT_OPT_IN);
            String doubleOptIn = (String) objRecord.get(DOUBLE_OPT_IN);
            Datetime marketableDate = (Datetime) objRecord.get(MARKETABLE_DATE);
            String marketableValue = (String) objRecord.get(MARKETABLE);
            
            // CMCM-7707: Using Marketable date to set other opt it dates because Pardot doesn't take
            // null updates and overwrite new SFDC updates with its old value during sync

            // set implicit date based on below conditions
            if (YES.equals(implicitOptIn) && marketableDate == null) {
                objRecord.put(IMPLICIT_OPT_IN_DATE, Datetime.now());
            }

            // set explicit date based on below conditions
            if (YES.equals(explicitOptIn) && marketableDate == null) {
                objRecord.put(EXPLICIT_OPT_IN_DATE, Datetime.now());
            }

            // set double date based on below conditions
            if (YES.equals(doubleOptIn) && marketableDate == null) {
                objRecord.put(DOUBLE_OPT_IN_DATE, Datetime.now());
            }

            // set marketability date
            setMarketableDate(objRecord, marketableValue, marketableDate);

        }

    }

    /**
     * @author: Deep Diwakar
     * @date: May-22-2024
     * @description: This method calculates marketability date for given records
     * @param: objRecord - sObject record for calculatiion of marketability date
     * @param: marketableValue - marketable field value
     * @return: void
     */
    private void setMarketableDate(sObject objRecord, String marketableValue, Datetime marketableDate) {

        if (YES.equals(marketableValue) && marketableDate == null) {
            objRecord.put(MARKETABLE_DATE, Datetime.now());
        }

        if (NO.equals(marketableValue) && marketableDate != null) {
            objRecord.put(MARKETABLE_DATE, null);
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-05-2024
     * @description: This method calculates marketability for given records
     * @param: lstRecords - list of sObject records
     * @return: void
     */
    private void updatesOnOptOut(sObject objRecord) {
        
        // get fields
        String doubleOptIn = (String) objRecord.get(DOUBLE_OPT_IN);
        Datetime doubleOptInDate = (Datetime) objRecord.get(DOUBLE_OPT_IN_DATE);
        Datetime doubleOptInSendDate = (Datetime) objRecord.get(DOUBLE_OPT_IN_EMAIL_SENT_DATE);


        objRecord.put(EXPLICIT_OPT_IN, NO);
        objRecord.put(EXPLICIT_OPT_IN_DATE, null);

        objRecord.put(IMPLICIT_OPT_IN, NO);
        objRecord.put(IMPLICIT_OPT_IN_DATE, null);

        if (YES.equals(doubleOptIn) || doubleOptInDate != null) {
            objRecord.put(DOUBLE_OPT_IN, NO);
            objRecord.put(DOUBLE_OPT_IN_DATE, null);
        }
        
        if (doubleOptInSendDate != null) {
            objRecord.put(DOUBLE_OPT_IN_EMAIL_SENT_DATE, null);
        }


    }
}