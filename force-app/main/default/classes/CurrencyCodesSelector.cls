/**
*    @author Rishab Wali
*    @date   2020-03-17
*    @description    DCP-32959 Currency Type Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Rishab Wali              17 March 2020            Currency Type Selector class
*    Himanshu                 30 March 2022            Code Scan Fixes    
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class CurrencyCodesSelector extends ilib_SObjectSelector 
{   
    /*
    *   @author Rishab Wali      
    *   @date   17 March 2022 
    *   @description  Describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return CurrencyType.sObjectType;
    }
    
    /**
    *  @author  Rishab Wali 
    *  @description Retrieve list of fields for CurrencyType sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                CurrencyType.Id,
                CurrencyType.IsoCode,
                CurrencyType.conversionRate,
                CurrencyType.DecimalPlaces,    
                CurrencyType.IsActive,
                CurrencyType.IsCorporate    
                };
                    }
    
     /**
     *  @author Rishab Wali
     *  @description fetch the Currency Type Records on basis of Iso Codes
     *  @param Set of Iso Codes
     *  @return CurrencyType List
    **/
    public List<CurrencyType> getCurrencyTypeRecordsFromIsoCodes(Set<String> setIsoCodes)
    {
        return (List<CurrencyType>) Database.query(
            newQueryFactory().selectField('Id').selectField('conversionRate')
             .setCondition('IsoCode = : setIsoCodes').toSOQL());
    }
    
    /**
     * DGP-103 : Method to fetch Currency Type records for all Currency ISO Codes.
     **/
    public List<CurrencyType> fetchCurrencyTypeRecordsForAllIsoCodes()
    {
        return (List<CurrencyType>) Database.query(
            newQueryFactory().selectField('Id').selectField('ConversionRate').selectField('IsoCode')
            .setCondition('IsActive = true').toSOQL());
    }
}