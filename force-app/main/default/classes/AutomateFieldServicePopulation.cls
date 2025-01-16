/**
*    @author        Akash Kumar 
*    @date          2018-09-30
*    @description   DCP-758: Base Class for Field Service related Fields update on Opportunity 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                     Date                   Description
*             Akash Kumar                   28 Sep 2018            Update Field Service Related Field On Opportunity
*             Chaarvi Sardana               13 Dec 2018            Added logic to populate Partner FSE and FAS for Indirect Opportunities
*             Todd Neewman                  01 Nov 2019            Refactor and simplify
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*/
public class AutomateFieldServicePopulation {

    public static final Map<String, String> SERVICE_ROLE_TO_OPPORTUNITY_FIELD = new Map<String, String> {
        AccountToFieldSupports.PRIMARY_FAS => 'Primary_Field_Application_Scientist__c',
        AccountToFieldSupports.PRIMARY_FSE => 'Primary_Field_Service_Engineer__c',
        AccountToFieldSupports.FAS_MANAGER => 'Field_Application_Manager__c',
        AccountToFieldSupports.FSE_MANAGER => 'Field_Service_Manager__c',
        AccountToFieldSupports.PARTNER_FSE => 'Partner_Primary_Field_Service_Engineer__c',
        AccountToFieldSupports.PARTNER_FAS => 'Partner_Primary_Field_App_Scientist__c'
    };

    /*
    * @author       Akash Kumar
    * @date         2018-09-28
    * @description  updated opportunites based on roles in Account To Field Support, return list of those that need an update
    */    
    public static List<Opportunity> setFieldServiceFields(Map<Id, List<Opportunity>> accountIdToOpportunities, Map<Id, List<Account_to_Field_Support__c>> accountIdToAFS)
    {
        System.debug('accountIdToOpportunities--->' + accountIdToOpportunities);
        System.debug('accountIdToAFS--->' + accountIdToAFS);

        Map<Id, Opportunity> idToChangedOpportunity = new Map<Id, Opportunity>();

        for (Id accountId : accountIdToOpportunities.keySet())
        {
            List<Account_to_Field_Support__c> accountToFieldSupports = accountIdToAFS.get(accountId);
            List<Opportunity> opportunities = accountIdToOpportunities.get(accountId);

            updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_Primary_FSE, idToChangedOpportunity);
            updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_Primary_FAS, idToChangedOpportunity);
            updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_FSM, idToChangedOpportunity);
            updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_FAM, idToChangedOpportunity);

            if (Label.AccountGroupDistributor.equals(accountToFieldSupports.get(0).Account__r.Account_Group__c))
            {
                updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_Partner_Primary_FSE, idToChangedOpportunity);
                updateUserIfChanged(accountToFieldSupports, opportunities, Label.Field_Support_User_Role_Partner_Primary_FAS, idToChangedOpportunity);
            }
        }

        for (Opportunity opp : idToChangedOpportunity.values())
        {
            if (opp.Id != null)
                opp.Is_Updated_By_System__c = true;
        }

        return idToChangedOpportunity.values();
    }

    private static void updateUserIfChanged(List<Account_to_Field_Support__c> accountToFieldSupports, List<Opportunity> opportunities, String roleName, Map<Id, Opportunity> idToChangedOpportunity)
    {
        String oppFieldName = SERVICE_ROLE_TO_OPPORTUNITY_FIELD.get(roleName);

        Account_to_Field_Support__c matchingAFS = findMatchingUser(accountToFieldSupports, roleName);

        for (Opportunity opp : opportunities)
        {
            Id correctServiceUserId = (matchingAFS == null ? null : matchingAFS.User__r.SVMXC__Salesforce_User__c);
            Id savedServiceUserId = (Id)opp.get(oppFieldName);
            if (savedServiceUserId == correctServiceUserId) continue;

            if (idToChangedOpportunity.containsKey(opp.Id))
            {
                idToChangedOpportunity.get(opp.Id).put(oppFieldName, correctServiceUserId);
                System.debug('for opp ' + opp.Id + ', setting ' + roleName + ' aka ' + oppFieldName + ' to ' + correctServiceUserId);
            }
            else
            {
                opp.put(oppFieldName, correctServiceUserId);
                idToChangedOpportunity.put(opp.Id, opp);
                System.debug('for opp ' + opp.Id + ', setting ' + roleName + ' aka ' + oppFieldName + ' to ' + correctServiceUserId);
            }
        }
    }

    private static Account_to_Field_Support__c findMatchingUser(List<Account_to_Field_Support__c> accountToFieldSupports, String roleName)
    {
        Account_to_Field_Support__c matchingAFS = null;
        for (Account_to_Field_Support__c afs : accountToFieldSupports)
        {
            if (roleName.equals(afs.User_Role__c) && afs.User__r.SVMXC__Active__c && !String.isBlank(afs.User__r.SVMXC__Salesforce_User__c))
            {
                matchingAFS = afs;
                break;
            }
        }

        return matchingAFS;
    }

}