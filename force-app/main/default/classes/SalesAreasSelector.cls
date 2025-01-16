/**
*    @author Akshay Mohan
*    @date   2018-07-17
*    @description    DCP-358: SalesArea Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*     Developer                      Date                Description
*     Akshay Mohan              17 Jul 2018            SalesArea Selector Class
*     Rahul Sharma              11 Oct 2018            Changing Params in selectSalesArea
*     Aman Tyagi                31 Mar 2022            CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class SalesAreasSelector extends ilib_SObjectSelector {

    /*
    * @Author: Rahul Sharma
    * @Description : constructor of class SalesAreasSelector
    * @param : null
    */
    public SalesAreasSelector()
    {
        super(false, false, false, false);
        //m_orderBy = '';
    }

     /*
    * @author Akshay Mohan
    * @date   2018-07-17
    * @description  set select fields
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Sales_Area__mdt.Company_Code__c,
            Sales_Area__mdt.Country_Code__c,
            Sales_Area__mdt.Distribution_Channel__c,
            Sales_Area__mdt.Division__c,
            Sales_Area__mdt.Price_List_Type__c,
            Sales_Area__mdt.Sales_Organization__c,
            Sales_Area__mdt.Term_Of_Payment__c,
            Sales_Area__mdt.DeveloperName,
            Sales_Area__mdt.MasterLabel,
            Sales_Area__mdt.Transportation_Zone__c
        };
    }

    /*
    * @author Akshay Mohan
    * @date   2018-07-17
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Sales_Area__mdt.sObjectType;
    }
    
    /*
    * @author Akshay Mohan
    * @date   2018-07-17
    * @description Fetch Related SalesAreas for the Accounts CountryCode
    * @param strCountryCode String of Account CountryCode
    *
    */
    public List<Sales_Area__mdt> selectSalesAreas(String strCountryCode) 
    {
        return (List<Sales_Area__mdt>) Database.query(
        newQueryFactory().setCondition('Country_Code__c = : strCountryCode').toSOQL());
    }   

    /*
    * @author Rahul Sharma
    * @date   2018-08-03
    * @description Fetch Related SalesArea for the Accounts CountryCode
    * @param lstCountryCode List of Account CountryCode
    *
    */
    public List<Sales_Area__mdt> selectSalesArea(Set<String> setCountryCode) 
    {
        return (List<Sales_Area__mdt>) Database.query(
        newQueryFactory().setCondition(' Country_Code__c IN :setCountryCode').toSOQL());
    }   
    
}