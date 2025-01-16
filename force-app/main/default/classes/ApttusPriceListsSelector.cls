/**
 *    @author Rohan Chandarana
 *    @date   2018-05-28
 *    @description    DCP-454: Create Quote - Ability to Clone Quote 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *             Developer                      Date                Description
 *             Milan Savaliya              2018-10-23             Added selectActive(Set<String> )
 *             Kushagra Desai              12-12-2018             added selectByID(set<id>)
 *             Jitesh Lakhwani             6-July-2022            Code Scan fixes of Comments

 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ApttusPriceListsSelector extends ilib_SObjectSelector
{
   /**
    *  @author Rohan Chandarana 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Price List
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Apttus_Config2__PriceList__c.sObjectType;
   }
    
    /**
     *  @author  Rohan Chandarana 
     *  @description Retrieve list of fields for Price List sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Apttus_Config2__PriceList__c.id,
           Apttus_Config2__PriceList__c.Apttus_Config2__Active__c, 
           Apttus_Config2__PriceList__c.Name,
           Apttus_Config2__PriceList__c.Apttus_Config2__ContractNumber__c,
           Apttus_Config2__PriceList__c.Apttus_Config2__EffectiveDate__c,
           Apttus_Config2__PriceList__c.Apttus_Config2__ExpirationDate__c
       };
    }
    
    /**
     *  @author Milan Savaliya 
     *  @description Fetch all active Price Lists with selected names
     *  @return Map of price list name to price list
     **/
    public Map<String, Apttus_Config2__PriceList__c> selectActive(Set<String> setPriceListName) 
    {
        Map<String, Apttus_Config2__PriceList__c> mpNameToPriceListWrappers = new Map<String, Apttus_Config2__PriceList__c>();
        for(Apttus_Config2__PriceList__c p : Database.query(
                newQueryFactory(false).
                selectField(Apttus_Config2__PriceList__c.Id).selectField(Apttus_Config2__PriceList__c.Name).
                setCondition('Apttus_Config2__Active__c = true AND Name IN :setPriceListName').
                toSOQL())
        )
        {
           if(!mpNameToPriceListWrappers.containsKey(p.Name)){
               mpNameToPriceListWrappers.put(p.Name, p);
           }
        }
        return mpNameToPriceListWrappers;
    }

    /**
     *  @author Todd Newman
     *  @description Select by contract number
     **/
     /*
    public List<Apttus_Config2__PriceList__c> selectByContract(Set<String> contractNumbers)
    {
        return (List<Apttus_Config2__PriceList__c>) Database.query(
                newQueryFactory().setCondition(' Apttus_Config2__ContractNumber__c IN :contractNumbers').toSOQL());
    }*/

    /**
     *  @author Rohan Chandarana 
     *  @description Order By Price List records using Effective Date and Expiration Date
     *  @return String order
     **/
    public override String getOrderBy() 
    {
        return 'Apttus_Config2__EffectiveDate__c DESC, Apttus_Config2__ExpirationDate__c DESC';
    }

    /**
     *  @author Illumina 
     *  @description : This method will return all the price list where the products has price list items.
     *  @param : Set<ID> setProductIds : set of product Id's to search price list for
     *  @return List<Apttus_Config2__PriceList__c>
     **/
    public List<Apttus_Config2__PriceList__c> selectByID(Set<ID> setProductIds)
    {
        return (List<Apttus_Config2__PriceList__c>) Database.query(
                newQueryFactory().setCondition('id IN :setProductIds').toSOQL());
    }

}