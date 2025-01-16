/**
*    @author Rahul Sharma
*    @date   2018-08-23
*    @description    DCP-10312: PriceList Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*     Developer                    Date                Description
*     Rahul Sharma              23 Aug 2018            PriceList Selector Class
*     Aman Tyagi                31 March 2022          Codescan fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PriceListSelector extends ilib_SObjectSelector {

    /*
    * @Author: Rahul Sharma   
    * @Description : parameterized constructor of class PriceListSelector 
    * @param :null
    */ 
    public PriceListSelector()
    {
        super(false, false, false, false);
        
    }

    /*
    * @Author: Rahul Sharma   
    * @Description : method to get the sObject type
    * @param :null
    */
    public Schema.SObjectType getSObjectType()
    {
        return Price_List__mdt.sObjectType;
    }
    
    /*
    * @author Rahul Sharma
    * @date   2018-08-23
    * @description  set select fields
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Price_List__mdt.MasterLabel,
            Price_List__mdt.DeveloperName,
            Price_List__mdt.Price_List_Type__c,
            Price_List__mdt.Region__c,
            Price_List__mdt.Currency__c,
            Price_List__mdt.Price_List__c
        };
    }
    
    /*
    * @author Rahul Sharma
    * @date   2018-08-25
    * @description Fetch Related PriceList for account sales area price list type and currency unique combination
    * @param lstTypeCurrency List of Price List Type and Currency
    *
    */
    public List<Price_List__mdt> selectPriceList(List<String> lstTypeCurrency) 
    {
        return (List<Price_List__mdt>) Database.query(
        newQueryFactory().setCondition(' MasterLabel IN :lstTypeCurrency').toSOQL());
    }   
    
    
}