/**
 *    @author Gopesh Banker
 *    @date   26-09-2018
 *    @description   class to get asset line item records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Gopesh Banker                 26-SEP-2018         Initial Version
 *      Rahul Sharma                  03-Jul-2019         DCP-25384 Added selectAssetsByAccounts
 *      KD                            8-May-2021          DCP-45742 getRelatedFieldsQuery
 *      Himanshu                      31-March-2022       Code Scan Fixes
 *      Rishi Sharma                  2022-09-09          TASK0730598: Used header level asset activation
 *      Arquimidez Mora               10-Aug-2024         CMCM-9644 Added new method selectAssetLineItem 
 *    ------------------------------------------------------------------------------------
 *
 */
public with sharing class ApttusAssetLineItemsSelector extends ilib_SObjectSelector 
{
    private final String LOG_TITLE = 'ApttusAssetLineItemsSelector';
    private static final string QUERY_LOGS_SALES = 'SalesQueryLogs';

    /*
    *   @author Gopesh Banker      
    *   @date  26-09-2018
    *   @description  Describe the object
    */
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Config2__AssetLineItem__c.sObjectType;
    }
    /*
    *   @author Gopesh Banker      
    *   @date  26-09-2018
    *   @description  Describe the object
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Config2__AssetLineItem__c.id,
            Apttus_Config2__AssetLineItem__c.Name,
            Apttus_Config2__AssetLineItem__c.Apttus_Config2__AssetStatus__c,
            Apttus_Config2__AssetLineItem__c.Days_After_Expiry__c,
            Apttus_Config2__AssetLineItem__c.Apttus_Config2__AccountId__c,
            Apttus_Config2__AssetLineItem__c.Ultimate_Consignee__c,
            Apttus_Config2__AssetLineItem__c.Status__c,
            //Added by Sravan Panchangam for DCP-18876
            Apttus_Config2__AssetLineItem__c.Apttus_Config2__StartDate__c,
            Apttus_Config2__AssetLineItem__c.Apttus_Config2__EndDate__c,
            Apttus_Config2__AssetLineItem__c.Serial_Number__c
        };
    }
    /*  
    * @description  Related select field
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Apttus_Config2__ProductId__r.Name')
            .selectField('Apttus_Config2__ProductId__r.Apttus_Config2__ProductType__c')
            .selectField('Apttus_Config2__ProductId__r.SVMXC__Product_Type__c')
            .selectField('Apttus_Config2__ProductId__r.ProductCode');
    }
    /**
     * @Author: Sravan Panchangam
     * @Description: get the list of asset line items with records based on the Id
     * @param Set<ID> idSet
     * @return List<Apttus_Config2__AssetLineItem__c>
    **/
    public List<Apttus_Config2__AssetLineItem__c> selectById(Set<ID> idSet) 
    {
        return (List<Apttus_Config2__AssetLineItem__c>) selectSObjectsById(idSet);
    }

    /**
     * @Name :selectByAssetId
     * @Author: Sravan Panchangam
     * @Description: get the list of asset line items with records based on the Id
     * @Date:10 Jan 2019
     **/
    public List<Apttus_Config2__AssetLineItem__c> selectByAssetId(Set<ID> ids)
    {
        return (List<Apttus_Config2__AssetLineItem__c>) Database.query(
            newQueryFactory().setCondition('ID IN :ids').toSOQL()
        );
    }

    /**
     *  @Name           : selectAssetsByAccounts 
     *  @Author         : Rahul Sharma
     *  @Description    : DCP-25384 get the list of asset line items by Sold To and UC Account
     *  @Since          : 03 Jul 2019
     **/
     public List<Apttus_Config2__AssetLineItem__c> selectAssetsByAccounts(Set<Id> setAccountId) 
     {
          String strQuery = newQueryFactory().setCondition('Apttus_Config2__AccountId__c IN :setAccountId OR Ultimate_Consignee__c IN :setAccountId').toSOQL();
          return (List<Apttus_Config2__AssetLineItem__c>) Database.query(strQuery);
     }

    /**
     *  @Name           : selectAssetsByUC
     *  @Since          : 18 Feb 2020
     **/
    public List<Apttus_Config2__AssetLineItem__c> selectAssetsByUC(Set<Id> setUCId) 
    {
         return (List<Apttus_Config2__AssetLineItem__c>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Ultimate_Consignee__c IN :setUCId')
            .toSOQL());
    }

    /**
     *  @Name           : selectAssetsByContractNumber 
     *  @Author         : Rishi Sharma
     *  @Description    : TASK0730598: Used header level asset activation
     *  @Since          : 09 Sept 2022
     **/
    public List<Apttus_Config2__AssetLineItem__c> selectAssetsByContractNumber(String strSalesOrderNo) 
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectAssetsByContractNumber',
            strSalesOrderNo
        );

         List<Apttus_Config2__AssetLineItem__c> res = (List<Apttus_Config2__AssetLineItem__c>) Database.query(
            newQueryFactory()
            .selectField('id')
            .setCondition('Contract_Number__c =: strSalesOrderNo')
            .toSOQL()
         );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /**
     *  @Author         : Arquimidez Mora
     *  @Description    : Get Asset Line item query with any field
     **/
    public List<Apttus_Config2__AssetLineItem__c> selectAssetLineItem(Set<Id> setAssetLineItemIds, List<String> lstFields)
    {
        ilib_QueryFactory objQueryFactor = newQueryFactory(); 
        for(String strField : lstFields){
            objQueryFactor.selectField(strField);
        }

        List<Apttus_Config2__AssetLineItem__c> res = (List<Apttus_Config2__AssetLineItem__c>) Database.query(
            objQueryFactor
            .setCondition('Id IN :setAssetLineItemIds')
            .toSOQL()
        );

        return res;
    }

}