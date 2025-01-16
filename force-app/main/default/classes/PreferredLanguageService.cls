/**
*    @author Rishab Wali
*    @date   24 Feb 2021
*    @description    Preferred Language related logic written in this class.
*    @Test Class - TestApttusAgreements
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                         Date                     Description
*    Rishab Wali                       24-Feb-2021              Initial Version
*    Iram Malik                        21-Jul-2022              DCP-56109: Added Spanish mapping for AMR 
*    Prem Ranjan                       24-Nov-2022              POL-49 Update picklist value from APJ to AMEA and EMEA to Europe
*/
public without sharing class PreferredLanguageService {

    public static final String STRENGLISH = 'English'; //DCP-37232 Default Preferred Language
    public static final String STRACCOUNTAPINAME = 'Apttus__Account__c'; //DCP-37232
    public static Map<String,String> regionToPreferredLanguageMap = new Map<String,String> {
        System.Label.QuoteRegionAMR => 'English,Portuguese,Spanish',  //DCP-56109
        System.Label.QuoteRegionEUR => 'English,French,German,Italian,Spanish',
        System.Label.QuoteRegionAMEA => 'English,Korean,Japanese',
        System.Label.QuoteRegionChina => 'English,Chinese,Chinese trad.'
    };
    /*
    @Author - Rishab Wali
    @Story : DCP-37232
    @Description : Set Preferred Language on Agreement.
    @Paramters - List<Apttus__APTS_Agreement__c> - Agreements List
    */
    public static void setPreferredLanguage(List<Apttus__APTS_Agreement__c> lstAgreements)
    {
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAgreements, STRACCOUNTAPINAME);
        List<Account> lstAccounts = new AccountsSelector().selectAccounts(setAccountIds);
        Map<Id,String> accountIdToLanguageMap = new Map<Id,String>();
        Map<String,String> recordTypeToLanguageMap = new Map<String,String>();

        for(Account acc : lstAccounts)
        {
            accountIdToLanguageMap.put(acc.Id,acc.Preferred_Language__c);
        }

        List<CLM_Preferred_Language_To_Template__mdt> lstPreferredLanguageToTemplate = new CLMPreferredLanguageToTemplatesSelector().selectAllRecords();

        for(CLM_Preferred_Language_To_Template__mdt objPrefToTemplate : lstPreferredLanguageToTemplate)
        {
            recordTypeToLanguageMap.put(objPrefToTemplate.Record_Type_Name__c,objPrefToTemplate.Supported_Languages__c);
        }

        for(Apttus__APTS_Agreement__c objAgg : lstAgreements)
        {
            String languageSupported = ''; //Supported Languages
            if(recordTypeToLanguageMap.containsKey(Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(objAgg.RecordTypeId).getDeveloperName()))
            {
                languageSupported = recordTypeToLanguageMap.get(Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(objAgg.RecordTypeId).getDeveloperName());
            }

            if(String.isNotBlank(objAgg.Preferred_Language__c))
            {
                Boolean isValidLanguage = languageSupported.contains(objAgg.Preferred_Language__c) ? true : false;
                if(!isValidLanguage)
                {
                    objAgg.Preferred_Language__c = STRENGLISH;
                }
            }
            else
            {
                String strAccPreferredLanguage = accountIdToLanguageMap.get(objAgg.Apttus__Account__c);
                if(String.isNotBlank(strAccPreferredLanguage) && languageSupported.contains(strAccPreferredLanguage))
                {
                    objAgg.Preferred_Language__c = strAccPreferredLanguage;
                }
                else
                {
                    objAgg.Preferred_Language__c = STRENGLISH;
                }
            }
        }
    }


    /*Method to set Preferred Language on Quote */
    public static void updatePreferredLanguageOnQuote(List<Apttus_Proposal__Proposal__c> lstProposals,Map<Id, Opportunity> mapOppIdToOpp)
    {
        for(Apttus_Proposal__Proposal__c proposal : lstProposals)
        {
            if (mapOppIdToOpp.containsKey(proposal.Apttus_Proposal__Opportunity__c))
            {
                Opportunity objOpp = mapOppIdToOpp.get(proposal.Apttus_Proposal__Opportunity__c);
                if(regionToPreferredLanguageMap.containsKey(objOpp.Territory_Region__c))
                {
                    proposal.Preferred_Language__c = regionToPreferredLanguageMap.get(objOpp.Territory_Region__c).contains(objOpp.Account.Preferred_Language__c) ? objOpp.Account.Preferred_Language__c : STRENGLISH;
                }
                else if(proposal.Preferred_Language__c != objOpp.Account.Preferred_Language__c)
                {
                    proposal.Preferred_Language__c = objOpp.Account.Preferred_Language__c ;
                }
            }
        }
    }
}