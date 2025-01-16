/*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopinath Reddy          22 Oct 2018                      Initial version
* Govind Dubey            06 Dec 2019                      Updated interface name IAssetLineItemCallback3 and added new validateAssetTermination
* Todd Newman             12 Feb 2020                      TASK0457622: only filter on UC match, not sold to and UC
* Adyasha                 08 Mar 2022                      Updated interface name IAssetLineItemCallback4 and added new method getAssetTerminationDate
                                                           to have the visibility of assets from multiple sold to accounts on Installed Products page
* Himanshu                31 Mar 2022                      Code Scan Fixes during Q2 2022
*/

global with sharing class ApttusAssetLineItemCallBack implements Apttus_Config2.CustomClass.IAssetLineItemCallback4 {

    private List<String> assetSearchScope = null;
    private Id idUltimateConsinee = null;
    private String assetSearchFilter = null;
    /**
     * @author Gopinath Reddy  
     * @description Callback at the beginning of the asset selection call. Use the start method to initialize state
     * @param cart the cart object or null if there is no cart context
     * @param assetSearchFilter the preset static filter used in the asset search or null if there is no preset filter
     * @param assetSearchScope the list of asset fields to match the search text or empty to use the default list of fields
     * @return void
     */
    public void start(Apttus_Config2.ProductConfiguration cart,String assetSearchFilter, List<String> assetSearchScope)
    {
        this.assetSearchScope = assetSearchScope;
        this.assetSearchFilter = assetSearchFilter;

        Apttus_Config2__ProductConfiguration__c sObjConfig = new ApttusProductConfigurationsSelector().fetchCart(cart.getConfigSO().Id);
        idUltimateConsinee = sObjConfig.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c;
    }
    /**
     * @author Gopinath Reddy  
     * @description Callback to return the filter expression for the asset query where clause this filter is used in listing installed products
     * @param params the parameters for the method
     * @return the filter expression or null to use the default filter. 
    */
    public String getFilterExpr(Apttus_Config2.CustomClass.ActionParams params)
    {
        //Id idAccount = params.AccountId;

        String whereClause = ' Apttus_Config2__IsInactive__c = false'
            + ' AND Is_Customer_Not_Renewing__c = false'
            + ' AND Apttus_Config2__PriceType__c = \'Recurring\''
            + ' AND Apttus_Config2__AssetStatus__c != \'Cancelled\''
            + ' AND Apttus_Config2__StartDate__c != null'
            + ' AND Apttus_Config2__EndDate__c != null';

        String filters = ' AND Ultimate_Consignee__c = ' + '\'' + idUltimateConsinee + '\'';
        whereClause += filters;

        System.debug('@@@@whereClause: ' + whereClause);
        return whereClause;
    }
    
    /*New method in new interface */
    public Boolean validateAssetTermination(Set<ID> assetIds, Set<ID> accountIds, Date effectiveDate)
    {
        return true;
    } 
    /**
     * @author Gopinath Reddy  
     * @description Callback to return part of SOQL filter clause
     * @param params accountId is the context account id  
     * @return string The query filter. 
    */
    public String getQueryFilter(ID accountId)
    {
        System.debug('***AssetLineItemCB: getQueryFilter()-assetSearchFilter: ' + assetSearchFilter);        
        return this.assetSearchFilter;
    }
    /**
     * @author Gopinath Reddy  
     * @description Gets the asset search scope
     * @return the asset search scope or null to use the default asset search scope
    */
    public List<String> getAssetSearchScope()
    {
        System.debug('***AssetLineItemCB: getAssetSearchScope()-returning: ' + this.assetSearchScope);
        return this.assetSearchScope; 
    }
    /**
     * @author Gopinath Reddy  
     * @description Callback after the filter is used. Use the finish method to release state
     * @param NA
     * @return NA
    */
    public void finish()
    {
        System.debug('***AssetLineItemCB: finish()');
    }

    /*DCP-52300: New method in new interface */
    global Date getAssetTerminationDate() {
        return Date.newInstance(2999,01,01);
    }

}