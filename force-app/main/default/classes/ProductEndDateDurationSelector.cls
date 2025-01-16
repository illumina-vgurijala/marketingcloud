/**
*    @author Prem Ranjan
*    @date   29 June 2021
*    @description    DCP-48133 Class to get the Custom Metadata records to update End Date as per its Duration 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Prem Ranjan                    29 June 2021               Initial Version
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class ProductEndDateDurationSelector extends ilib_SObjectSelector{
    /* getSObjectType method*/
    public Schema.SObjectType getSObjectType()
    {
        return Product_End_Date_Setting__mdt.sObjectType;
    } 

/**
*  @author - Prem Ranjan
*  @description - Retrieve list of fields for Product End Date Setting Metadata type 
*  @return - sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Product_End_Date_Setting__mdt.DeveloperName,
            Product_End_Date_Setting__mdt.Product_Code__c,
            Product_End_Date_Setting__mdt.Terms_Months__c
        };
    }

/**
*  @author Prem Ranjan
*  @description Fetch Product and End Date Durations records
*  @return list of CLM Preferred Language to Template records
**/
    public List<Product_End_Date_Setting__mdt> selectAllRecords(){
        return (List<Product_End_Date_Setting__mdt>) Database.query(
            newQueryFactory().toSOQL()
        );
    }
}