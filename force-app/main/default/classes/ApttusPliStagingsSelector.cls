/**
 * Created by tnewman on 11/1/18.
 */

public with sharing class ApttusPliStagingsSelector extends ilib_SObjectSelector {

    /**
     *  @author Todd Newman
     *  @return SObjectType The SObjectType for this selector
     **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_PLI_Staging__c.sObjectType;
    }

    /**
     *  @author Todd Newman
     *  @return list of fields to query
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                Apttus_PLI_Staging__c.Id,
                Apttus_PLI_Staging__c.CreatedDate,
                Apttus_PLI_Staging__c.Contract_Number__c,
                Apttus_PLI_Staging__c.PLI_Key__c,
                Apttus_PLI_Staging__c.CurrencyIsoCode,
                Apttus_PLI_Staging__c.CustomerId__c,
                Apttus_PLI_Staging__c.CustomerPrice__c,
                Apttus_PLI_Staging__c.ListPrice__c,
                Apttus_PLI_Staging__c.MaterialId__c,
                Apttus_PLI_Staging__c.Processed_Date__c,
                Apttus_PLI_Staging__c.Quantity__c,
                Apttus_PLI_Staging__c.UOM__c,
                Apttus_PLI_Staging__c.ValidFrom__c,
                Apttus_PLI_Staging__c.ValidTo__c
        };
    }

    /**
     *  @author Todd Newman
     *  @description Fetch all staged PLIs with the given contract/currency formula values
     *  @parameter contractsWithCurrencies = a set of formula values combining contract number and currency
     *  @parameter idsToExclude = a set of IDs of rows which are already retrieved and therefore shouldn't be in this list
     *  @return staged PLIs that match the parameter values
     **/
    public List<Apttus_PLI_Staging__c> selectByContractsWithCurrencies(Set<String> pliKeys, Set<Id> idsToExclude)
    {
        return (List<Apttus_PLI_Staging__c>) Database.query(
                newQueryFactory().setCondition('PLI_Key__c IN :pliKeys AND Processed_Date__c = null AND Id NOT IN :idsToExclude').toSOQL());
    }

}