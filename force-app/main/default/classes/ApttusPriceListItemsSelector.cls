/**
 * Created by tnewman on 11/1/18.
 */

public with sharing class ApttusPriceListItemsSelector extends ilib_SObjectSelector {

    /**
     *  @author Todd Newman
     *  @return SObjectType The Schema.SObjectType of the Price List Item
     **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Config2__PriceListItem__c.sObjectType;
    }

    /**
     *  @author Todd Newman
     *  @return list of fields to query
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
    return new List<Schema.SObjectField> {
            Apttus_Config2__PriceListItem__c.Id,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__Active__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceListId__c,
            Apttus_Config2__PriceListItem__c.PLI_Key__c,
            Apttus_Config2__PriceListItem__c.CurrencyIsoCode,
            Apttus_Config2__PriceListItem__c.Customer_Specific_Price__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__ListPrice__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__ProductId__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__DefaultQuantity__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceUom__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__EffectiveDate__c,
            Apttus_Config2__PriceListItem__c.Apttus_Config2__ExpirationDate__c
        };
    }


    /**
     *  @author Todd Newman
     *  @description Fetch all active Price Lists by name - Use recent price list if duplicate price list found.
     *  @parameter contractsWithCurrencies =
     *  @return PLIs that match
     **/
    public List<Apttus_Config2__PriceListItem__c> selectByContractsWithCurrencies(Set<String> pliKeys)
    {
        return (List<Apttus_Config2__PriceListItem__c>) Database.query(
                newQueryFactory().setCondition('Apttus_Config2__Active__c = true AND PLI_Key__c IN :pliKeys').toSOQL());
    }

}