/**
 *    @author Shashank Singhal
 *    @date   2018-08-24
 *    @description  DCP-844: Apttus Order line item Selector 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Shashank                        2018-08-24         Initial Version
 *    Gopesh Banker                   2018-10-01         adding method getOrderLinesByAssetId, adding field Apttus_Config2__AssetLineItemId__c and Apttus_Config2__LineStatus__c in getSObjectFieldList
 *    Rahul Bishnoi                   2020-29-01         DCP-31767 Fetching Order Line items Based on set of Quote Line item Id's
 *    Gopinath Reddy                  2020-01-28         Selection OLI based on Contract Number
 *    Akshay Mohan                    2020-04-21         Get creation date
 *    Bharath Varma                   2020-11-20         Added fields for DCP-31776
 *    Gladis                          22-Jun-2022        DCP-45368 Added new method fetchCasebyOrderLineItemId 
 *    Koustubh                        2022-04-12         TASK0730598 - header level activation- modified fetchLinesBySalesOrderNumber(), added query logging instrumentation
 *    Sudarshan                       05-Dec-2023        CMCM-1354  EOL WO Changes
 *    Arquimidez Mora                 10-Aug-2024        CMCM-9644 Added new methods selectOrderLineItem and fetchOrderLineItemsByOrder
 *    Sandeep Singh                   15-Nov-2024        CMCM-10562 Ensure only 1 installation work order is created
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ApttusOrderLineItemsSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'ApttusOrderLineItemsSelector';//DCP-45368
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';//DCP-45368
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs';
    
    /**
    *  @author Shashank Singhal 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Order line item
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Apttus_Config2__OrderLineItem__c.sObjectType;
   }
    
    /**
     *  @author  Shashank Singhal
     *  @description Retrieve list of fields for Order sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Apttus_Config2__OrderLineItem__c.id, 
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__ProductId__c, 
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__Quantity__c,
                Apttus_Config2__OrderLineItem__c.ERP_Order_Number_Id__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__OrderId__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__AssetLineItemId__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__LineStatus__c,
                Apttus_Config2__OrderLineItem__c.Item_Status__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__Status__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__ActivatedDate__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__StartDate__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__AssetLineItemId__c,
                Apttus_Config2__OrderLineItem__c.Apttus_Config2__EndDate__c,
                Apttus_Config2__OrderLineItem__c.ERP_Line_Number_Id__c,
                Apttus_Config2__OrderLineItem__c.Apttus_QPConfig__ProposalLineItemId__c,
                Apttus_Config2__OrderLineItem__c.Serial_Number__c,
                Apttus_Config2__OrderLineItem__c.Case_Id__c,
                Apttus_Config2__OrderLineItem__c.Domain_URL__c,
                //INC0266068
                Apttus_Config2__OrderLineItem__c.CreatedDate,
                // DCP-31776
                Apttus_Config2__OrderLineItem__c.Zuora_Subscription_ID__c,
                Apttus_Config2__OrderLineItem__c.Registrant_Contact__c
                
        };
    }
    
    /**
     *  @author Shashank Singhal 
     *  @description Fetch Order line items for related orders and products
     *  @param setOrderIds Set of order Ids, setProductIds Set of Product Ids
     *  @return order line item List
     **/
    /*public List<Apttus_Config2__OrderLineItem__c> selectOrderLineitemsForOrders(Set<Id> setOrderIds, set<Id> setProductIds) 
    {
        return (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            newQueryFactory().setCondition('Apttus_Config2__OrderId__c IN :setOrderIds AND Apttus_Config2__ProductId__c IN :setProductIds').toSOQL()
        );
    }*/

    /**
     *  @author Gopesh Banker 
     *  @description Fetch Order line items by Asset Line Item Ids
     *  @param setAssetLineItems set of asset line item ids
     *  @return order line item List
     **/
    public List<Apttus_Config2__OrderLineItem__c> getOrderLinesByAssetId(Set<Id> setAssetLineItems) 
    {
        return (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            newQueryFactory().setCondition('Apttus_Config2__AssetLineItemId__c IN :setAssetLineItems').toSOQL()
        );
    }
    /*
     * @Author: Sravan Panchangam
     * @Description : Fetch orders records by the ASOP
     * @Param set ASOP NUmber
     * @returns list of apttus orders with the apttus order line items
    */
    public List<Apttus_Config2__OrderLineItem__c> fetchLinesBySalesOrderNumber(Set<String> salesOrderNumbers){
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchLinesBySalesOrderNumber',
            UtilsCollection.serializeIds(salesOrderNumbers)
        );
        String strQuery = newQueryFactory()
        .selectField('Apttus_Config2__OrderId__r.Sales_Order_Number_Unique__c')
        .selectField('Apttus_Config2__OrderId__c')
        .selectField('Apttus_Config2__OrderId__r.Apttus_Config2__Status__c')
        .selectField('Apttus_Config2__AssetLineItemId__c')
        .selectField('Apttus_Config2__AssetLineItemId__r.Apttus_Config2__IsInactive__c')
        .selectField('Apttus_Config2__ActivatedDate__c')
        .selectField('Apttus_Config2__Status__c')
        .selectField('ERP_Line_Number_Id__c')
        .setCondition('Apttus_Config2__OrderId__r.Sales_Order_Number_Unique__c IN :salesOrderNumbers').toSOQL();
        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(strQuery);
        if (Feature.isOn(SALES_QUERY_LOGS)) 
            logger.stop(res.size());
        return res;
    }

    /*
     * @Author: Koustubh M
     * @Description : Fetch orderlineitems where assets are inacive
     * @Param set<Id>
     * @returns list of order lineitems
    */
    public List<Apttus_Config2__OrderLineItem__c> fetchLinesWithInactiveAssetsByIds(set<ID> orderIds){
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchLinesWithInactiveAssetsByIds',
            UtilsCollection.serializeIds(orderIds)
        );
        String strQuery = newQueryFactory()
        .selectField('Apttus_Config2__Status__c')
        .selectField('Apttus_Config2__AssetLineItemId__c')
        .setCondition('Apttus_Config2__OrderId__c in: orderIds and ( Apttus_Config2__AssetLineItemId__r.Apttus_Config2__IsInactive__c = true or Apttus_Config2__Status__c = \''+Label.OrderLineItemStatusFulfilled+'\' or Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c != \''+Label.OrderLineItemStatusActivated+'\')').toSOQL();
        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(strQuery);
        if (Feature.isOn(SALES_QUERY_LOGS)) 
            logger.stop(res.size());
        return res;
    }

    /*
     * @Author: Sravan Panchangam
     * @Description: Fethcing the Order Line items
     * @Param set<ID>
     * @returns list of order lineitems
     */
    public List<Apttus_Config2__OrderLineItem__c> fetchLinesByIds(set<ID> setofIds){
        return (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            newQueryFactory().setCondition('Id IN :setofIds').toSOQL()
        );
    }
    /*

     * @Author : Rahul Bishnoi
     * @Description : DCP-31767 Fetch Orders For Set of Quote Line Items
   */
    public List<Apttus_Config2__OrderLineItem__c> fetchbyQuoteLineItemId(Set<Id> setProposalLineItemIds){
      return (List<Apttus_Config2__OrderLineItem__c>) Database.query(newQueryFactory().setCondition('Apttus_QPConfig__ProposalLineItemId__c IN : setProposalLineItemIds').toSOQL());
      }

    /*
     * @Author: Gopinath Reddy
     * @Description: Fethcing the Order Line items - DCP-32166
     * @Param Set<String>
     * @returns list of order lineitems
     */
    public List<Apttus_Config2__OrderLineItem__c> selectOLIbyERPHeaderContract(Set<String> setERPLineNumber){
      
        return (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            newQueryFactory()
            .selectField('Registrant_Contact__c')
            .selectField('Renewal_Subscription__c')
            .selectField('Registrant_Contact__r.Phone')
            .selectField('Registrant_Contact__r.Email')
            .selectField('Ultimate_Consignee__c')
            .selectField('Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c')
            .selectField('Domain_ID__c')
            .selectField('Apttus_Config2__ProductId__c')
            .selectField('Apttus_Config2__ProductId__r.Informatics_Family__c')
            .selectField('Apttus_Config2__ProductId__r.Informatics_SKU_Type__c')
            .selectField('Apttus_Config2__ProductId__r.Number_of_Instances__c')
            .selectField('Instance_Region__c')
            .selectField('ERP_Line_Number_Id__c')
            .selectField('Custom_License_Flag__c')
            .selectField('Apttus_Config2__StartDate__c')
            .selectField('Apttus_Config2__EndDate__c')
            .selectField('Apttus_Config2__ProductId__r.DRAGEN_Throughput_Gb__c')
            .selectField('Apttus_Config2__ProductId__r.Number_of_Users__c')
            .selectField('Dragen_Connectivity__c')
            .selectField('Order__c')
            .selectField('Contract_Number__c')
            .selectField('Name')
            .selectField('Order_Line_Number__c')
            .selectField('Apttus_Config2__OrderId__r.Apttus_Config2_SoldToAccountId_ERP_Id__c')
            .selectField('Apttus_Config2__OrderId__r.Ultimate_Consignee_ERP_Id__c')
            .selectField('Equipment_Id__c')//DCP-45368
            .setCondition('ERP_Line_Number_Id__c IN : setERPLineNumber')
            .toSOQL()
        );
    }

    /**
     *  @author Gladis
     *  @description DCP-45368 Fetch Case Ids For Set of Order Line Items
     *  @return  List<Apttus_Config2__OrderLineItem__c>
     **/
    public List<Apttus_Config2__OrderLineItem__c> fetchCasebyOrderLineItemId(set<Id> setOLIIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.fetchCasebyOrderLineItemId', UtilsCollection.serializeIds(setOLIIds));
        } 
        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(
             newQueryFactory()
            .selectField('Id')
            .selectField('Equipment_Id__c')
            .selectField('Case_Id__c')
            .selectField('ERP_Line_Number_Id__c')
            .selectField('Apttus_Config2__ProductId__c')
            .setCondition('Id IN :setOLIIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*
     * @Author : Sudarshan Kataria
     * @Decription : CMCM-1354 Fetch order line items that has Trade-in indicator as 'A' OR 'C'
     * @Param Set of Order Ids
     * @return  Order Line Items List
     */
    public List<Apttus_Config2__OrderLineItem__c> selectTradeInOrderLines(set<Id> setOrderIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectTradeInOrderLines', UtilsCollection.serializeIds(setOrderIds));
        } 
        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(
             newQueryFactory()
            .selectField('Id')
            .selectField('Trade_In_Indicator__c')
            .selectField('Apttus_Config2__OrderId__c')
            .setCondition('(Trade_In_Indicator__c = \'A\' OR Trade_In_Indicator__c = \'C\') AND Apttus_Config2__OrderId__c IN: setOrderIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*
     * @Author : Arquimidez Mora
     * @Decription : Get query with any field on the parameter
     * @return  Order Line Items List
     */
    public List<Apttus_Config2__OrderLineItem__c> selectOrderLineItem(Set<Id> setOrderLineItemIds, List<String> lstFields)
    {
        ilib_QueryFactory objQueryFactor = newQueryFactory(); 
        for(String strField : lstFields){
            objQueryFactor.selectField(strField);
        }

        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            objQueryFactor
            .setCondition('Id IN :setOrderLineItemIds')
            .toSOQL()
        );

        return res;
    }

    /*
     * @Author : Arquimidez Mora
     * @Decription : Get Order Line Items related to Orders
     * @return  Order Line List
     */
    public List<Apttus_Config2__OrderLineItem__c> fetchOrderLineItemsByOrder(Set<Id> setOrderIds)
    {
        List<Apttus_Config2__OrderLineItem__c> res = (List<Apttus_Config2__OrderLineItem__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Apttus_Config2__OrderId__c')
            .selectField('Product_Code__c')
            .selectField('Apttus_Config2__Quantity__c')
            .setCondition('Apttus_Config2__OrderId__c IN :setOrderIds')
            .toSOQL()
        );

        return res;
    }
 
}