/**
 *    @author Ritika Maheshwari
 *    @date   26-05-2018
 *    @description    Class to get the Parts Order records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer              Date                    Description
 *    Ritika                 26-May-2018             Initial Version
 *    Soumya                 21-Aug-2018             Added query fields in selectPartsOrdersExcludingOrderType Method
 *    Joshith K              15-Nov -2018            Method to query part order with owner email id using set of Parts order names
 *    Adyasha                08-Mar-2021             Added query fields in selectPartsOrders method
 *    Sarath Pullanikkatt    29-Jun-2021             DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *    Shivani Jain           29 Nov 2021             DCP-42926 Parts Order Lines Optimization
 *    Shivani Jain           05 Sep 2022             DCP-43629 Parts Orders Sold To Population Logic [added field in selectPartsOrders method]
 *    Preetha                29-Mar-2022             QACM-770 Added selectPartsOrderByCaseId method
 *    ------------------------------------------------------------------------------------ 
 */
public with sharing class PartsOrdersSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'PartsOrdersSelector';
    private static final String STRING_SERVICE_QUERY_LOGS = 'servicequerylogs';

    /**
     *  @author Ritika Maheshwari 
     *  @description  
     *  @return SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__RMA_Shipment_Order__c.sObjectType;
    }
    
    /**
     *  @author  Ritika Maheshwari 
     *  @description Retrieve list of fields for Parts Order sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
            SVMXC__RMA_Shipment_Order__c.id,
            SVMXC__RMA_Shipment_Order__c.SVMXC__Order_Status__c,
            SVMXC__RMA_Shipment_Order__c.SVMXC__Case__c,
            SVMXC__RMA_Shipment_Order__c.SVMXC__Service_Order__c,
            SVMXC__RMA_Shipment_Order__c.SVMXC__Order_Type__c,
            SVMXC__RMA_Shipment_Order__c.SVMXC__Sales_Order_Number__c,
            SVMXC__RMA_Shipment_Order__c.Submit_to_SAP__c,
            SVMXC__RMA_Shipment_Order__c.Open_Parts_Orders_Lines__c,
            SVMXC__RMA_Shipment_Order__c.Name,
            SVMXC__RMA_Shipment_Order__c.Ownerid
        };
    }
    
    /**
     *  @author Ritika Maheshwari
     *  @description Fetch parts orders associated with case which are not delivered
     *  @param Parts order ids : part order ids to be excluded
     *          Case ids : cases for which parts order are to be fetched
     *          strExcludePOStatus : status to be exculded in parts order selection
     *  @param case ids
     *  @return part orders which are not in the status passed as paramater 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersForAppropriateStatusonCase(Set<Id> setPartsOrderIds, Set<Id> setCaseIds, 
                                                                                    String strExcludePOStatus) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersForAppropriateStatusonCase', UtilsCollection.serializeIds(setPartsOrderIds)
                                                                                                   + '|' + UtilsCollection.serializeIds(setCaseIds) + '|' + strExcludePOStatus);

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .setCondition('ID NOT IN : setPartsOrderIds ' + 
                          ' AND SVMXC__Case__c IN : setCaseIds ' + 
                          ' AND SVMXC__Order_Status__c != :strExcludePOStatus')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /*
     *  @description - Fetch Parts Orders Ids with Work Order Ids
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersForAppropriateStatusonWO(Set<Id> setPartsOrderIds, Set<Id> setWorkOrderIds, 
                                                                                    Set<String> listExcludePOStatus) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersForAppropriateStatusonWO', UtilsCollection.serializeIds(setPartsOrderIds)
                                                                                                 + '|' + UtilsCollection.serializeIds(setWorkOrderIds) + '|' + listExcludePOStatus);

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .setCondition('ID NOT IN : setPartsOrderIds ' + 
                         ' AND SVMXC__Service_Order__c IN : setWorkOrderIds ' + 
                         ' AND SVMXC__Order_Status__c != :listExcludePOStatus')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch Parts Orders
     *  @param Parts Order ids
     *  @Date 3 Aug 2018
     *  @return List of Parts Orders
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrders(Set<Id> setPartsOrderIds)
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrders', UtilsCollection.serializeIds(setPartsOrderIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__r.Service_Bill_Of_Materials__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c')
            .selectField('SVMXC__Case__r.SVMXC__Component__c')
            .selectField('SVMXC__Case__r.SVMXC__Product__c')
            .selectField('SVMXC__Case__r.SVMXC__Component__r.Service_Bill_Of_Materials__c')
            .selectField('SVMXC__Case__r.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c')
            .selectField('Warning_Message__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__r.Regulatory_Type__c')
            .selectField('SVMXC__Case__r.SVMXC__Product__r.Regulatory_Type__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__r.Installed_Product_Upgrade_Type__c')
            .selectField('SVMXC__Case__r.SVMXC__Component__r.Installed_Product_Upgrade_Type__c')
            .selectField('SVMXC__Destination_Location__c')
            .selectField('SVMXC__Source_Location__c')
            .selectField('Submit_for_Approval_CP__c')
            .selectField('SVMXC__Order_Status__c')
            .selectField('SVMXC__Company__r.Clinical_Type__c')
            .selectField('SVMXC__Company__r.Customer_Type__c')
            .selectField('SVMXC__Company__r.Territory_Region__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__r.ProductCode')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__r.Name')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__r.SVMXC__Serial_Lot_Number__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__r.Name')
            .selectField('SVMXC__Service_Order__r.SVMXC__Company__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Site__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Contact__c')
            .selectField('SVMXC__Service_Order__r.Contact_Name__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Group_Member__c') //DCP-42926
            //START - DCP-43629
            .selectField('Shipping_Location__c') 
            .selectField('Shipping_Location__r.SVMXC__Country__c') 
            .selectField('Shipping_Country__c') 
            .selectField('Sold_To__c') 
            .selectField('Sold_To__r.ERP_Customer_Id__c') 
            .selectField('SVMXC__Company__r.ERP_Customer_Id__c') 
            .selectField('SVMXC__Service_Order__r.Partner_Work_Order__c') 
            .selectField('SVMXC__Service_Order__r.Sold_To_Account__c') 
            //END - DCP-43629
            .setCondition('ID IN : setPartsOrderIds ')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Nitin Sood
     *  @description Fetch Parts Orders excluding the specified Order Type
     *  @param Parts order ids : part order ids 
     *          strExcludePOType : type to be exculded in parts order selection
     *  @param case ids
     *  @return part orders which are not of type passed as paramater 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersExcludingOrderType(Set<Id> setPartsOrderIds,  
                                                                                    String strExcludePOType) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersExcludingOrderType', UtilsCollection.serializeIds(setPartsOrderIds) + '|' + strExcludePOType);

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Group_Member__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Order_Type__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Component__c')
            .selectField('SVMXC__Service_Order__r.SVMXC__Product__c')
            .selectField('SVMXC__Case__r.SVMXC__Component__c')
            .selectField('SVMXC__Case__r.SVMXC__Product__c')
            .setCondition('ID IN : setPartsOrderIds ' + 
                          ' AND SVMXC__Order_Type__c != :strExcludePOType')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 

    /**
     *  @author Nitin Sood
     *  @description Fetch Parts Orders excluding the specified Order Type
     *  @param Parts order ids : part order ids 
     *  @return part orders with Technitians 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersAndFieldService(List<Id> setPartsOrderIds) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersAndFieldService', UtilsCollection.serializeIds(new Set<Id>(setPartsOrderIds)));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Service_Order__r.SVMXC__Group_Member__c')
            .setCondition('ID IN : setPartsOrderIds AND SVMXC__Service_Order__c != null AND SVMXC__Service_Order__r.SVMXC__Group_Member__c != null' )
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch Parts Orders on WOs
     *  @param Work order ids : setWOIds 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersOnWorkOrders(set<Id> setWOIds) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersOnWorkOrders', UtilsCollection.serializeIds(setWOIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Service_Order__c  IN : setWOIds AND SVMXC__Order_Status__c != \'Canceled\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }

    /**
     *  @author Joshith K
     *  @description Fetch Parts Orders with owner email id
     *  @param setOrderName Set Of Part Order Names 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersWithName(set<string> setOrderName) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersWithName', UtilsCollection.serializeIds(setOrderName));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('owner.email')
            .selectField('owner.name')
            .selectField('ERP_Sales_Order_Number__c')
            .selectField('createdby.UserType')
            .selectField('SVMXC__Company__c')
            .selectField('SVMXC__Order_Type__c') // CMCM-91
            .selectField('SVMXC__Destination_Location__c')
            .selectField('SVMXC__Destination_Location__r.ERP_Customer_ID__c')
            .selectField('Warning_Message__c')
            .setCondition('ERP_Sales_Order_Number__c  IN : setOrderName')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Debanka Chakraborty
     *  @description Fetch Parts Orders of Work Order excluding selected status
     *  @param setWorkOrderIds,String strExcludePOStatus
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersofWOForAppropriateStatus(Set<Id> lstWorkOrders,String strExcludePOStatus) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersofWOForAppropriateStatus', UtilsCollection.serializeIds(lstWorkOrders) + '|' + strExcludePOStatus);

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Service_Order__c In : lstWorkOrders ' + 
                          ' AND SVMXC__Order_Status__c = :strExcludePOStatus')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch Parts Orders on WOs where ERP Submitted = Not Requested And Status != Canceled
     *  @param Work order ids : setWOIds 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectERPSubmittedPartsOrdersOnWorkOrders(set<Id> setWOIds) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectERPSubmittedPartsOrdersOnWorkOrders', UtilsCollection.serializeIds(setWOIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('ERP_Submitted__c')
            .setCondition('SVMXC__Service_Order__c  IN : setWOIds AND ERP_Submitted__c = \'Not Requested\' AND SVMXC__Order_Status__c != \'Canceled\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author Vaibhav
     *  @description DCP-29080 - Return all non return type parts orders which are not submitted to SAP.
     *  @param Work order ids : setWOIds 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectERPSubmittedNonReturnPartsOrders(set<Id> setWOIds) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectERPSubmittedNonReturnPartsOrders', UtilsCollection.serializeIds(setWOIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('ERP_Submitted__c')
            .setCondition('SVMXC__Service_Order__c  IN : setWOIds AND ERP_Submitted__c = \'Not Requested\'  AND SVMXC__Order_Type__c != \'Return\' AND SVMXC__Order_Status__c != \'Canceled\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author Sravan
     *  @description DCP-33467 : Fetch Parts Orders of Retrun/Stock Transfer which are create from Location
     *  @param Parts Order ids : setPOIds 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectReturnOrStockTransferPOsByIds(set<Id> setPOIds) 
    {    
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectReturnOrStockTransferPOsByIds', UtilsCollection.serializeIds(setPOIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .setCondition('Id IN : setPOIds AND SVMXC__Service_Order__c =null')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @author Vaibhav
     *  @description Fetch Parts Orders on WOs where Parts Order != Cancelled / Closed/Duplicates - DCP-8444 - New changes
     *  @param Work order ids : setWOIds 
     *  @return part orders 
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectNonCancelledPartsOrdersOnWorkOrders(set<Id> setWOIds) 
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNonCancelledPartsOrdersOnWorkOrders', UtilsCollection.serializeIds(setWOIds));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('ERP_Submitted__c')
            .setCondition('SVMXC__Service_Order__c  IN : setWOIds AND SVMXC__Order_Status__c != \'Canceled\' AND SVMXC__Order_Status__c != \'Closed\'')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * Method: selectPartsOrderWithPOL
     * Description: Fetch parts orders along with its parts order lines.
     * params: set of parts order Ids
     * return: list of parts orders
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrderWithPOL(Set<Id> setPartsOrderId)
    {
        ilib_QueryFactory partsOrderQuery = newQueryFactory();
        partsOrderQuery.selectField('Request_All_Part_Order_Lines_CS_Override__c');
        ilib_QueryFactory polSubQuery = new PartsOrderLineSelector().addQueryFactorySubselect(partsOrderQuery,'SVMXC__RMA_Shipment_Line__r');
        polSubQuery.selectField('SVMXC__RMA_Shipment_Order__c');
        
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderWithPOL', UtilsCollection.serializeIds(setPartsOrderId));

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>)Database.query(
            partsOrderQuery
            .setCondition('Id in:setPartsOrderId')
            .toSOQL());

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }  
    /*
    *  @author      : Preetha QACM-770
    *  @description : Fetch Parts Order Id based on Case ID
    *  @return      : Parts Order
    */

    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrderByCaseId(id caseId) {
        ilib_LogQuery logger=null;
            if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderByCaseId', caseId);        
        String strQuery = newQueryFactory()
            .selectField('Id')
            .selectField('SVMXC__Order_Type__c')
            .selectField('SVMXC__Case__c')
            .setCondition('SVMXC__Case__c = : caseId AND Id IN (Select Parts_Order__c from Quality_Notification__c) AND SVMXC__Order_Type__c = \'Return\'')
            .toSOQL();
            List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(strQuery);
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
     /**
     *  @author Avina
     *  @description QACM-175 Fetch Parts Orders with caseIds
     *  @param String caseId
     *  @Date 06-Oct-2022
     *  @return List of Parts Orders
     */
    public List<SVMXC__RMA_Shipment_Order__c> selectPartsOrdersWithCase(String caseId)
    {
        ilib_LogQuery logger = NULL;
        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersWithCase',caseId);

        List<SVMXC__RMA_Shipment_Order__c> res = (List<SVMXC__RMA_Shipment_Order__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Name')
            .selectField('SVMXC__Company__r.Name')
            .selectField('SVMXC__Order_Status__c')
            .selectField('SVMXC__Source_Location__r.Name')
            .selectField('SVMXC__Destination_Location__r.Name')
            .setCondition('SVMXC__Case__c = : caseId ')
            .toSOQL()
        );

        if(Feature.isOn(STRING_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
}