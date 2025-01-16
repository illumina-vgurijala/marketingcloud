/**
* @ author       : Indra Ganesan
* @ date         : 10 JAN 2019
* @ Description  : DCP -12936 Product Search Call back to filter producs shown in the cart based on profile and product level indicator
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Indra Ganesan        06-DEC-2018                  Initial version
* Indra Ganesan        10-JAN-2019                  Modified as part of DCP-18879
* Satya Swain          03-MAY-2019                  Modified as part of TASK0370801
*/
global with sharing class ApttusProductSearchFilterCallback implements Apttus_Config2.CustomClass.IProductFilterCallback {

    /**
    * @owner Satya Swain
    * @description Callback to return part of SOQL filter clause.This filter is used in listing catalog products
    * @param none
    * @return String
    */
    public String getProductFilterExpr(Apttus_Config2.CustomClass.ActionParams params)
    {
        return buildWhereClause('Product_Level_Indicator__c', getProductIndicatorValuesForUser());
    }

    /**
    * @owner Satya Swain 
    * @description Callback to return part of SOQLfilter clause.This filter is used in listing option products.
    * @param none
    * @return String
    */
    public String getOptionFilterExpr(Apttus_Config2.CustomClass.ActionParams params)
    {
        return buildWhereClause('ComponentProductId__r.Product_Level_Indicator__c', getProductIndicatorValuesForUser());
    }

    private String buildWhereClause(String strCriteriaField, String strProductIndicatorValue)
    {
        if (String.isBlank(strProductIndicatorValue)) return '';

        String strWhereClause = ' ' + strCriteriaField + ' IN (' + strProductIndicatorValue + ')';

        System.debug('@@@ ApttusProductSearchFilterCallback -> filter clause is ' + strWhereClause);
        return strWhereClause;
    }

    private String getProductIndicatorValuesForUser()
    {
        Product_Level_Indicator__c objProductLevelIndicator = Product_Level_Indicator__c.getInstance();

        if (objProductLevelIndicator == null) return null;
        if (String.isBlank(objProductLevelIndicator.Values__c)) return null;

        return objProductLevelIndicator.Values__c;
    }

}