/**
 *   @author: Deep Diwakar
*    @date:   Mar-04-2024
*    @description: Facade class for determining Marketability for given sObjects
*    @Test Class: TestMarketabilityServiceFacade
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-04-2024        CMCM-5551: Facade class for determining Marketability for given sObjects
*         Deep Diwakar       Mar-04-2024        CMCM-5552: Added bypass for certain test context scenarios
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class MarketabilityServiceFacade {

    private final Map<String,CountryRegionMapping__mdt> mapCountryCodesToCountryRegionMapping;
    private final Map<String,CountryRegionMapping__mdt> mapCountryNameToCountryRegionMapping;
    private static final String LOG_TITLE = 'MarketabilityServiceFacade';

    @TestVisible
    private static Boolean testContextSkipRun = false;


     /**
     * @author: Deep Diwakar
     * @date: Mar-04-2024
     * @description: constructor
     * @param: None
     * @return: NA
     */
    public MarketabilityServiceFacade() {
        mapCountryCodesToCountryRegionMapping = new Map<String,CountryRegionMapping__mdt>();
        mapCountryNameToCountryRegionMapping = new Map<String,CountryRegionMapping__mdt>();

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-04-2024
     * @description: Client facing method to determing marketability of given sObject records
     * @param: lstNewRecords - list of sObject records
     * @param: currentStrategy - name of the strategy (CMT: Marketability_Strategy__mdt) to be used to determing marketability
     * @return: void
     */
    public List<sObject> determineMarketability(List<sObject> lstNewRecords, String currentStrategy) {

        ilib_LogEvent.push(LOG_TITLE + '.determineMarketability()');

        ilib_LogEvent.info('currentStrategy: ' + currentStrategy);

        // skip ruuning marketability logic in test context for certain scenarios i.e. setting up data before testing
        if (Test.isRunningTest() && testContextSkipRun) {
            ilib_LogEvent.info('running in test context and skipping further run');
            return lstNewRecords;
        }

        // get all CMT records
        getCountryRegionMappingInfo();

        ilib_LogEvent.info('lstNewRecords.getSObjectType: ' + lstNewRecords.getSObjectType());

        if (lstNewRecords.getSObjectType() == Lead.sObjectType) {
            // set opt-in value for leads
            setOptInRuleforLeads(lstNewRecords);

        } else if (lstNewRecords.getSObjectType() == Contact.sObjectType) {
            // set opt-in value for contacts
            setOptInRuleforContacts(lstNewRecords);

        } 

        // using strategy pattern here to identify current strategy and the determining marketability based on that
        IMarketabilityStrategy marketabilityStrategy = (IMarketabilityStrategy) MarketabilityStrategyInjector.getMarketabilityStrategy(currentStrategy);
        marketabilityStrategy.calculateMarketability(lstNewRecords);

        ilib_LogEvent.pop();

        return lstNewRecords;

    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-04-2024
     * @description: This method sets opt in rule for lead based on lead country and CMT- CountryRegionMapping
     * @param: lstLeads - list of lead records
     * @return: void
     */
    private void setOptInRuleforLeads(List<Lead> lstLeads) {

        for (Lead leadRecord : lstLeads) {
            CountryRegionMapping__mdt cmtRecord = null;

            if (String.isNotBlank(leadRecord.Country) && mapCountryNameToCountryRegionMapping.containsKey(leadRecord.Country)) {
                cmtRecord = mapCountryNameToCountryRegionMapping.get(leadRecord.Country);
            } else if (String.isNotBlank(leadRecord.CountryCode) && mapCountryCodesToCountryRegionMapping.containsKey(leadRecord.CountryCode)) {
                cmtRecord = mapCountryCodesToCountryRegionMapping.get(leadRecord.CountryCode);
            }

            if (cmtRecord != null) {
                leadRecord.Opt_in_Rule__c = cmtRecord.Opt_in_Rule__c;

            } else {
                leadRecord.Opt_in_Rule__c = 'Unknown';
            }

        }

    }


    /**
     * @author: Deep Diwakar
     * @date: Mar-04-2024
     * @description: This method sets opt in rule for contacts based on mailing country and CMT- CountryRegionMapping
     * @param: lstContacts - list of contact records
     * @return: void
     */
    private void setOptInRuleforContacts(List<Contact> lstContacts) {

        for (Contact contactRecord : lstContacts) {
            CountryRegionMapping__mdt cmtRecord = null;

            if (String.isNotBlank(contactRecord.MailingCountry)
                 && mapCountryNameToCountryRegionMapping.containsKey(contactRecord.MailingCountry)) {

                    cmtRecord = mapCountryNameToCountryRegionMapping.get(contactRecord.MailingCountry);
                    
            } else if (String.isNotBlank(contactRecord.MailingCountryCode)
                && mapCountryCodesToCountryRegionMapping.containsKey(contactRecord.MailingCountryCode)) {

                    cmtRecord = mapCountryCodesToCountryRegionMapping.get(contactRecord.MailingCountryCode);

            } else if (String.isNotBlank(contactRecord.AccountBillingCountryCode__c) 
                && mapCountryNameToCountryRegionMapping.containsKey(contactRecord.AccountBillingCountryCode__c)) {

                    cmtRecord = mapCountryNameToCountryRegionMapping.get(contactRecord.AccountBillingCountryCode__c);

            }

            if (cmtRecord != null) {
                contactRecord.Opt_in_Rule__c = cmtRecord.Opt_in_Rule__c;

            } else {
                contactRecord.Opt_in_Rule__c = 'Unknown';
            }

        }


    }

    /**
     * @author: Deep Diwakar
     * @date: Mar-04-2024
     * @description: Get country - opt in rule mapping from CMT and store it in maps
     * @param: None
     * @return: void
     */
    private void getCountryRegionMappingInfo() {

        for (CountryRegionMapping__mdt objCountryRegionMapping : new CountryRegionMappingMetaDataSelector().selectCountryRegionMappingMetaRecords()) {
            mapCountryCodesToCountryRegionMapping.put(objCountryRegionMapping.Label,objCountryRegionMapping);
            mapCountryNameToCountryRegionMapping.put(objCountryRegionMapping.CountryCode__c,objCountryRegionMapping);
        }

    }
}