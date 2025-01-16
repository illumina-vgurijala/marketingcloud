/**
 *    @author Shashank Singhal
 *    @date   03-08-2018
 *    @description    Class to get the SVMXC__RMA_Shipment_Line__c records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                 Description
 *      Shashank Singhal               03-08-2018           Changes for DCP-874
 *      KD                             3-March-2021
 *      Adyasha Satapathy              03-08-2021           Added fields for DCP-41580
 *      Sarath Pullanikkatt            29-Jun-2021          DCP-47421 - PS Log Query Instrumentation for Service Selectors
 *      Shivani Jain                  29 Nov 2021           DCP-42926 Parts Order Lines Optimization
 *      Preetha                       22-Aug-2022           QACM-770 Added fields in selectPartsOrderLineRecords
 *    ------------------------------------------------------------------------------------                     
 */
public with sharing class PartsOrderLineSelector extends ilib_SObjectSelector
{
    //Added for DCP-38817
    private Boolean removeDefaultOrderBy=false;
    private static final String LOG_TITLE = 'PartsOrderLineSelector';
	private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	private static final String STRING_DECONTAMINATION_REQUIRED = 'Decontamination_Required__c';
	private static final String STRING_IS_DCIR_FILLED = 'Is_DCIR_Filled__c';
	private static final String STRING_LOANER_AGREEMENT_SIGNED = 'Loaner_Agreement_Signed__c';
	private static final String STRING_PARTS_ORDER_TYPE = 'Parts_Order_Type__c';
	private static final String STRING_BATCH_NUMBER = 'Batch_Number__c';
	private static final String STRING_PARTS_ORDER_SERVICE_ORDER = 'SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c';
	private static final String STRING_REASON_C = 'Reason__c';
	private static final String STRING_IS_BILLABLE = 'Is_Billable__c';
	private static final String STRING_SERVICE_PRODUCT_TYPE = 'Service_Product_Type__c';
	private static final String STRING_SVMXC_PRODUCT = 'SVMXC__Product__c';
	private static final String STRING_SVMXC_ACTUAL_QUANTITY = 'SVMXC__Actual_Quantity2__c';
	private static final String STRING_COD_UPLOAD = 'COD_Uploaded__c';
	private static final String STRING_PRODUCT_SERIAL_NUMBER_PROFILE = 'SVMXC__Product__r.Serial_Number_Profile__c';
	private static final String STRING_PRODUCT_CONDITION_TYPE = 'SVMXC__Product__r.Condition_Type__c';
	private static final String STRING_PRODUCT_CUSTOM_PRODUCT = 'SVMXC__Product__r.Custom_Product__c';
	private static final String STRING_RETURN_REASON = 'Return_Reason__c';
	private static final String STRING_TO_LOCATION = 'To_Location__c';
	private static final String STRING_RMA_REQUIRED = 'RMA_Required__c';
	private static final String STRING_PRODUCT_CODE = 'Product_Code__c';
    private static final String STRING_ITEM_DESTROYED = 'Item_Destroyed__c';
	private static final String STRING_COFD_FILLED = 'Is_CofD_Filled__c';
    private static final String STRING_LINE_STATUS = 'SVMXC__Line_Status__c';
    private static final String STRING_PARTS_ORDER = 'SVMXC__RMA_Shipment_Order__c';

	
    /**
     *  @author Shashank
     *  @description Retrieve list of fields for SVMXC__RMA_Shipment_Line__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__RMA_Shipment_Line__c.sObjectType;
    }

    /**
     *  @author Vaibhav
     *  @description Override default orderBy
     *  @return string
     */
    public override String getOrderBy()
    {
        if(removeDefaultOrderBy)
        {
            return 'LastModifiedDate DESC';
        }
        else
        {
            return super.getOrderBy();
        }
    }
    
    /**
     *  @author Shashank
     *  @description Retrieve list of fields for SVMXC__RMA_Shipment_Line__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            SVMXC__RMA_Shipment_Line__c.id,
            SVMXC__RMA_Shipment_Line__c.Name,
            SVMXC__RMA_Shipment_Line__c.SVMXC__RMA_Shipment_Order__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Line_Status__c,
            SVMXC__RMA_Shipment_Line__c.ERP_Sales_Order_Item__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Master_Order_Line__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Serial_Number__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Product__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__RMA_Shipment_Order__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Product__c,
            SVMXC__RMA_Shipment_Line__c.Is_Under_Service_Contract__c,
            SVMXC__RMA_Shipment_Line__c.Shipped_Qty__c,
            SVMXC__RMA_Shipment_Line__c.SVMXC__Actual_Quantity2__c
        };
    }
    
    /**
     *  @author Shashank
     *  @description Fetch the list of parts order lines associated to cases
     *  @param case ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLinesOnPartsOrders(Set<Id> setPartsOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLinesOnPartsOrders', UtilsCollection.serializeIds(setPartsOrderIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_DECONTAMINATION_REQUIRED)
            .selectField(STRING_IS_DCIR_FILLED)
            .selectField(STRING_LOANER_AGREEMENT_SIGNED)
            .selectField(STRING_PARTS_ORDER_TYPE)
            .selectField(STRING_PRODUCT_CODE)
            .selectField('SVMXC__Product__r.Name')
            .selectField(STRING_RMA_REQUIRED)
            .selectField(STRING_TO_LOCATION)
            .selectField(STRING_RETURN_REASON)
            .selectField(STRING_PRODUCT_CUSTOM_PRODUCT)
            .selectField(STRING_PRODUCT_CONDITION_TYPE)
            .selectField(STRING_PRODUCT_SERIAL_NUMBER_PROFILE)
            .selectField(STRING_COD_UPLOAD)
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Case__r.Logged_In_User_Profile__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Status__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.Integration_Error_Message__c')
            .selectField('Requested_Delivery_Date__c')
            .setCondition('SVMXC__RMA_Shipment_Order__c IN : setPartsOrderIds')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
	/**
     *  @author Shruti
     *  @description Fetch the list of parts order lines associated to cases
     *  @param case ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectShipmentPartsOrderLinesOnPartsOrders(Set<Id> setPartsOrderIds, String strPartsOrderType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectShipmentPartsOrderLinesOnPartsOrders', UtilsCollection.serializeIds(setPartsOrderIds) + '|' + strPartsOrderType);

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_DECONTAMINATION_REQUIRED)
            .selectField(STRING_IS_DCIR_FILLED)
            .selectField(STRING_RMA_REQUIRED)
            .selectField(STRING_TO_LOCATION)
            .selectField(STRING_RETURN_REASON)
            .selectField(STRING_PRODUCT_CUSTOM_PRODUCT)
            .selectField(STRING_COD_UPLOAD)
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Case__r.Logged_In_User_Profile__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Status__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.Integration_Error_Message__c')
            .selectField('Requested_Delivery_Date__c')
            .setCondition('SVMXC__RMA_Shipment_Order__c IN : setPartsOrderIds AND SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c =: strPartsOrderType')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author  Mandeep Singh
     *  @description Retrieve list of fields for SVMXC__RMA_Shipment_Line__c sObject 
     *  @param Parts Order Line ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectLinkedPartsOrderLine(Set<Id> setPartsOrderLineIds)
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLinkedPartsOrderLine', UtilsCollection.serializeIds(setPartsOrderLineIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__Master_Order_Line__c IN : setPartsOrderLineIds')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
      
    /**
     *  @author  Dipika
     *  @description Retrieve list of fields for Parts Order Line sObject 
     *  @param Parts Order Line ids
     *  @return List of Parts Order Lines
     **/
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLineById(Set<ID> setPOLIds)
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLineById', UtilsCollection.serializeIds(setPOLIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Serial_Number__c')
            .selectField(STRING_LINE_STATUS)
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField(STRING_PRODUCT_CONDITION_TYPE)
            .selectField('SVMXC__Serial_Number__r.SVMXC__Company__c')
            .selectField('SVMXC__Serial_Number__r.SVMXC__Site__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.Shipping_Location__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Company__c')
            .selectField('SVMXC__Master_Order_Line__c')
            .setCondition('ID  IN : setPOLIds')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
     
    /**
     *  @author  Mandeep
     *  @description Retrieve list of fields for Parts Order Line sObject 
     *  @param Parts Order Line ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLineRecords(Set<ID> setPatrsOrderLineIds)
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLineRecords', UtilsCollection.serializeIds(setPatrsOrderLineIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c')
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField(STRING_PRODUCT_CODE)
            .selectField(STRING_IS_BILLABLE)
            .selectField(STRING_REASON_C)
            .selectField('SVMXC__Serial_Number__c')
            .selectField('SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMXC__Product__r.SVMXC__Tracking__c')
            .selectField(STRING_PARTS_ORDER_SERVICE_ORDER)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Order_Status__c')
            .selectField(STRING_BATCH_NUMBER)
            .selectField('ERP_Contract_Number__c')
            .selectField('ERP_Contract_Line_Number__c')
            .selectField(STRING_PRODUCT_CONDITION_TYPE) 	
            .selectField(STRING_PRODUCT_SERIAL_NUMBER_PROFILE) 
            .selectField('SVMXC__Serial_Number_List__c')
            .selectField('SVMXC__Serial_Number__r.SVMXC__Product__c')
            .selectField(STRING_PARTS_ORDER_TYPE)
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField('SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.Requested_By__c')//DCP-42926 
            .selectField('SVMXC__Service_Order__c')//QACM-770
            .selectField('SVMXC__Product__r.Name')//QACM-770
            .setCondition('ID  IN : setPatrsOrderLineIds')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author  Vaibhav
     *  @description Retrieve list of Parts Order Line records by ERP Sales Order Number 
     *  @param Parts Order ERP Sales Order Number
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLineByPartsOrderExtId(Set<String> setPartsOrderExtId)
    {
        ilib_QueryFactory partsOrderQuery = newQueryFactory();
        partsOrderQuery.selectField(STRING_PARTS_ORDER);
     	partsOrderQuery.selectField('SVMXC__RMA_Shipment_Order__r.ERP_Sales_Order_Number__c');
     	partsOrderQuery.selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c');	
        partsOrderQuery.selectField('PO_Number__c');
        partsOrderQuery.selectField(STRING_COD_UPLOAD);
        partsOrderQuery.selectField('RMA__c');
        partsOrderQuery.selectField(STRING_RETURN_REASON);
        partsOrderQuery.selectField('No_Substitute_Parts__c');
        partsOrderQuery.selectField(STRING_IS_BILLABLE);
        partsOrderQuery.selectField('Linked_Line_Item__c');
        partsOrderQuery.selectField('External_ID__c');
        partsOrderQuery.selectField(STRING_REASON_C);
        partsOrderQuery.selectField('Tracking_Number__c');
        partsOrderQuery.selectField(STRING_LOANER_AGREEMENT_SIGNED);
     	
        ilib_QueryFactory filesSubQuery = new ContentDocumentLinksSelector().addQueryFactorySubselect(partsOrderQuery,'ContentDocumentLinks');
        filesSubQuery.selectField('Id');
     	filesSubQuery.selectField('ContentDocumentId');
     	filesSubQuery.selectField('LinkedEntityId');
     	
        ilib_QueryFactory agreementsSubQuery = new AgreementsSelector().addQueryFactorySubselect(partsOrderQuery,'Agreements__r');     	
        agreementsSubQuery.selectField('Id');
     	agreementsSubQuery.selectField('Parts_Order_Line__c');
     	
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLineByPartsOrderExtId', UtilsCollection.serializeIds(setPartsOrderExtId));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            partsOrderQuery
            .setCondition('SVMXC__RMA_Shipment_Order__r.ERP_Sales_Order_Number__c IN : setPartsOrderExtId')  
            .toSOQL());  
            
            if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author  Ritika
     *  @description Retrieve list of fields for Parts Order Line sObject  
     *  @param Parts Order Line ids
     *  @return List of Parts Order Lines 
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLineForProductType(Set<ID> setPatrsOrderLineIds, String strProductType)
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLineForProductType', UtilsCollection.serializeIds(setPatrsOrderLineIds) + '|' + strProductType);

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c')
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField('SVMXC__Product__r.Service_Product_Type__c')
            .selectField('SVMXC__Serial_Number__c')
            .selectField('SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__r.SVMXC__Stocking_Location__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c')
            .selectField(STRING_PRODUCT_CODE)
            .selectField('SVMXC__RMA_Shipment_Order__c.SVMXC__Order_Type__c')
            .selectField(STRING_BATCH_NUMBER)
            .selectField('Batch_Lookup__r.Name')
            .selectField('Batch_Expiration__c')
            .selectField('Stocked_Serial__c')
            .selectField('Stocked_Serial__r')
            .setCondition('ID  IN : setPatrsOrderLineIds AND SVMXC__Product__r.Service_Product_Type__c =:strProductType')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch Parts Orders lines on pol ids
     *  @param parts order line ids : setPOLIds 
     *  @return part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesOnIds(set<Id> setPOLIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesOnIds', UtilsCollection.serializeIds(setPOLIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_PARTS_ORDER_SERVICE_ORDER)
            .setCondition('ID  IN : setPOLIds')
            .toSOQL()                
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Soumya Ranjan Sahu
     *  @description Fetch Parts Orders lines based on Parts Order Line Status
     *  @param parts order line ids : setPOLIds, setPOLStatuses
     *  @return List part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesByStatus(set<Id> setPOLIds, set<string> setPOLStatuses) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesByStatus', UtilsCollection.serializeIds(setPOLIds) + '|' + UtilsCollection.serializeIds(setPOLStatuses));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField('PO_Number__c')
            .selectField(STRING_IS_BILLABLE)
            .setCondition('SVMXC__RMA_Shipment_Order__c IN : setPOLIds AND SVMXC__Line_Status__c IN :setPOLStatuses')
            .toSOQL()                  
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Soumya Ranjan Sahu
     *  @description Fetch Parts Orders lines based on Parts Order Line Status
     *  @param parts order line ids : setPOLIds, setPOLStatuses
     *  @return List part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesNotInStatus(set<Id> setPOLIds, set<string> setPOLStatuses) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesNotInStatus', UtilsCollection.serializeIds(setPOLIds) + '|' + UtilsCollection.serializeIds(setPOLStatuses));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__RMA_Shipment_Order__c IN : setPOLIds AND SVMXC__Line_Status__c  NOT IN :setPOLStatuses')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author Vaibhav
     *  @description DCP-31054 - Get the POL's for Location.
     *  @param Location Ids. 
     *  @return List part orders Lines
     */
    public List < SVMXC__RMA_Shipment_Line__c > selectAllPartsOrdersLinesForLocation(Set<Id> setLocationIds, set<Id> setPartsOrderLinesId)
    {
        string statusShipped = 'Shipped';
        string blankBatchNumber;
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAllPartsOrdersLinesForLocation', UtilsCollection.serializeIds(setLocationIds) + '|' + UtilsCollection.serializeIds(setPartsOrderLinesId));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('Consumed_QTY__c')
            .selectField(STRING_TO_LOCATION)
            .setCondition('To_Location__c IN :setLocationIds AND ID NOT IN :setPartsOrderLinesId AND Batch_Number__c != :blankBatchNumber AND SVMXC__Line_Status__c =: statusShipped')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        
        return res;
    }

    /**
     *  @author Ritika
     *  @description DCP-33467: Fetch Shipped Parts Orders lines based on To Location
     *  @param location external ids : setFromLocationId
     *  @return List part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesByLocation(set<String> setFromLocationId)
    {
        string statusShipped = 'Shipped';
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesByLocation', UtilsCollection.serializeIds(setFromLocationId));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('Consumed_QTY__c')
            .selectField(STRING_TO_LOCATION)
			.selectField(STRING_BATCH_NUMBER)
            .setCondition('To_Location__r.SVMX_PS_External_ID__c IN :setFromLocationId AND Batch_Number__c != NULL AND SVMXC__Line_Status__c =: statusShipped')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author: prashanth
     *  @description: get the list of Parts order lines for the given set of work order Ids and POL statuses.
     *  @param : Set of work order ids and set of parts order line statuses
     *  @return: List of POL
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectBlankContractPOLsByWorkOrderId(Set<Id> setWOId, Set<String> setStatuses)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectBlankContractPOLsByWorkOrderId', UtilsCollection.serializeIds(setWOId) + '|' + UtilsCollection.serializeIds(setStatuses));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField(STRING_PARTS_ORDER)
            .selectField('ERP_Contract_Number__c')
            .selectField('ERP_Contract_Line_Number__c')
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c')
            .selectField(STRING_PARTS_ORDER_SERVICE_ORDER)
            .setCondition('SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c IN :setWOId AND ERP_Contract_Line_Number__c = NULL AND ERP_Contract_Number__c = NULL AND SVMXC__Line_Status__c IN:setStatuses')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	/**
     *  @author Sravan
     *  @description DCP-33467: Fetch Shipped Parts Orders lines based on Batch Number and To Location
     *  @param parts order line ids : setPOLIds, setPOLStatuses
     *  @return List part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesByLocationAndBatchNumber(set<Id> setFromLocationId, set<String> setBatchNumber)
    {
        string statusShipped = 'Shipped';
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesByLocationAndBatchNumber', UtilsCollection.serializeIds(setFromLocationId) + '|' + UtilsCollection.serializeIds(setBatchNumber));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('Consumed_QTY__c')
            .selectField(STRING_TO_LOCATION)
			.selectField(STRING_BATCH_NUMBER)
            .setCondition('To_Location__c IN :setFromLocationId AND Batch_Number__c IN :setBatchNumber AND SVMXC__Line_Status__c =: statusShipped')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description DCP-38817 - Fetch Non Billable Parts Order Lines
     *  @return List of Parts Order Lines
     */
    public List < SVMXC__RMA_Shipment_Line__c > selectNonBillablePartsOrderLinesById(Set < Id > setNonBillablePartsOrderLinesId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNonBillablePartsOrderLinesById', UtilsCollection.serializeIds(setNonBillablePartsOrderLinesId));

        List<SVMXC__RMA_Shipment_Line__c> res = (List < SVMXC__RMA_Shipment_Line__c > ) Database.query(
            newQueryFactory()
            .selectField(STRING_PARTS_ORDER)
            .selectField('SVMXC__RMA_Shipment_Order__r.Requested_By__c')
            .selectField(STRING_REASON_C)
            .setCondition(' Id IN:setNonBillablePartsOrderLinesId ')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description DCP-38817 - Fetch the list of parts order lines associated to cases
     *  @param case ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLinesWithReasonOnPartsOrders(Set<Id> setPartsOrderIds) 
    {
        removeDefaultOrderBy = true;
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLinesWithReasonOnPartsOrders', UtilsCollection.serializeIds(setPartsOrderIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField('CreatedBy.Name')
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField('Name')
            .selectField('LastModifiedDate') 
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField('SVMXC__Product__r.Name')
            .selectField(STRING_PARTS_ORDER_TYPE)
            .selectField(STRING_REASON_C)
            .selectField(STRING_LINE_STATUS) 
            .selectField('SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c')//dcp-43634
            .setCondition('SVMXC__RMA_Shipment_Order__c IN : setPartsOrderIds AND Reason__c != NULL AND Reason__c != \'Consumable Warranty\' AND SVMXC__Line_Status__c != \'Canceled\' ')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @description Fetch Parts Orders lines based on Parts Order Line Status
     *  @param parts order line ids : setPOLIds, setPOLStatuses
     *  @return List part orders Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrdersLinesOfProductTypeByStatus(set<Id> setWOIds, String partsOrderType, String destinationLocationType,
                                                                                         set<string> setPOLStatuses, String serviceProductType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrdersLinesOfProductTypeByStatus', UtilsCollection.serializeIds(setWOIds) + '|' + partsOrderType + '|' + destinationLocationType
                                                                                                   + '|' + UtilsCollection.serializeIds(setPOLStatuses) + '|' + serviceProductType);

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_PARTS_ORDER_SERVICE_ORDER)
            .setCondition('SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c IN : setWOIds AND '+
                          'SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c =: partsOrderType AND '+
                          'SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__r.Type__c !=: destinationLocationType AND '+
                          'SVMXC__Line_Status__c IN :setPOLStatuses AND Service_Product_Type__c =: serviceProductType')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author KD
     *  @description - Fetch the list of parts order lines associated to Installed Product
     *  @param case ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLinesByWONotInStatues(Set<Id> setWOIds,Set<String> setPOLStatuses,Set<String> setPOStatues,Set<String> setPOType)
    {
        ilib_QueryFactory query = newQueryFactory();
        String strQueryCondition = 'SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c IN : setWOIds';
        if(setPOLStatuses != null && !setPOLStatuses.isEmpty())
            strQueryCondition = strQueryCondition + ' AND SVMXC__Line_Status__c NOT IN :setPOLStatuses';
        if(setPOStatues != null && !setPOStatues.isEmpty())
            strQueryCondition = strQueryCondition + ' AND SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Status__c NOT IN :setPOStatues';
        if(setPOType != null && !setPOType.isEmpty())
            strQueryCondition = strQueryCondition + ' AND SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c IN: setPOType';
        query.setCondition(strQueryCondition);
        String strQuery = query.selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Status__c')
            .selectField(STRING_PARTS_ORDER_SERVICE_ORDER)
            .selectField(STRING_DECONTAMINATION_REQUIRED)
            .selectField(STRING_IS_DCIR_FILLED)
            .selectField(STRING_LOANER_AGREEMENT_SIGNED)
            .selectField(STRING_PARTS_ORDER_TYPE)
            .selectField(STRING_PRODUCT_CODE)//DCP-37399
            .selectField('SVMXC__Product__r.Name')//DCP-37399
            .selectField(STRING_RMA_REQUIRED)
            .selectField(STRING_TO_LOCATION)
            .selectField(STRING_RETURN_REASON)
            .selectField(STRING_PRODUCT_CUSTOM_PRODUCT)
            .selectField(STRING_PRODUCT_CONDITION_TYPE)
            .selectField(STRING_PRODUCT_SERIAL_NUMBER_PROFILE)
            .selectField(STRING_COD_UPLOAD)
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField(STRING_IS_BILLABLE)
            .selectField(STRING_REASON_C)
            .selectField('Billable_AutoUpdated__c')   //added for UpdatePOLQueueable_WOHelper.updateIsBillabeOnPartsOrderLines
            .setCondition('SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c IN : setWOIds')
            .toSOQL();
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLinesByWONotInStatues', UtilsCollection.serializeIds(setWOIds) + '|' + UtilsCollection.serializeIds(setPOLStatuses) +
                                                                                             + '|' + UtilsCollection.serializeIds(setPOStatues) + '|' + UtilsCollection.serializeIds(setPOType));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query( strQuery );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
    /**
     *  @author Sravan
     *  @description - Fetch the list of parts order lines associated to parts orders
     *  @param PO ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPOLsFromPOIds(Set<Id> setPOIds){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPOLsFromPOIds', UtilsCollection.serializeIds(setPOIds));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
            .selectField(STRING_PRODUCT_CUSTOM_PRODUCT)
            .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c')
            .selectField(STRING_SERVICE_PRODUCT_TYPE)
            .selectField(STRING_DECONTAMINATION_REQUIRED)
            .selectField(STRING_IS_DCIR_FILLED)
            .selectField(STRING_SVMXC_PRODUCT)
            .selectField(STRING_SVMXC_ACTUAL_QUANTITY)
            .selectField(STRING_PRODUCT_SERIAL_NUMBER_PROFILE)
            .selectField(STRING_PRODUCT_CONDITION_TYPE)
            .selectField(STRING_LOANER_AGREEMENT_SIGNED)
            .selectField(STRING_RMA_REQUIRED)
            .selectField(STRING_TO_LOCATION)
            .selectField(STRING_RETURN_REASON)
            .selectField(STRING_COD_UPLOAD)
            //51199 start
            .selectField(STRING_ITEM_DESTROYED)
            .selectField(STRING_COFD_FILLED)
            //51199 end
            .selectField('Requested_Delivery_Date__c')
            .setCondition('SVMXC__RMA_Shipment_Order__c IN :setPOIds')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

/*
*  @description - Fetch the list of parts order lines associated to Products
*  @param ProductCodes
*  @return List of Parts Order Lines
*/
    public List<SVMXC__RMA_Shipment_Line__c> selectPOLsFromProductExtIds(Set<String> setPRoductCodes){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPOLsFromProductExtIds', UtilsCollection.serializeIds(setPRoductCodes));

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
             newQueryFactory()
            .selectField('Product_Code1__c')
            .setCondition('Product_Code1__c IN :setPRoductCodes AND SVMXC__Line_Status__c != \'Canceled\' ')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Nancy
     *  @description - Fetch the list of parts order lines associated to Return parts orders and filtering by Product Type
     *  @param PO ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLinesOnPOExcludeProductType(Set<Id> setPartsOrderId, String strProductType, String orderType){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsOrderLinesOnPOExcludeProductType', UtilsCollection.serializeIds(setPartsOrderId)  + '|' + strProductType + '|' + orderType);

        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
                newQueryFactory()
                .selectField(STRING_PARTS_ORDER)
                .selectField('SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c')
                .selectField('SVMXC__Product__r.Service_Product_Type__c')
                .selectField(STRING_LINE_STATUS)
                .setCondition('SVMXC__RMA_Shipment_Order__c IN :setPartsOrderId AND SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c = :orderType AND SVMXC__Product__r.Service_Product_Type__c != :strProductType' )
                .toSOQL()
        );
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Kumar Gaurav
     *  @description - Fetch the list of parts order lines with shipped and delivered Status for CMCM-9516
     *  @param PO ids
     *  @return List of Parts Order Lines
     */
    public List<SVMXC__RMA_Shipment_Line__c> selectPartsOrderLineforShippedandDelivedStatus(Set<Id> shipmentOrderIdSet) {
        List<SVMXC__RMA_Shipment_Line__c> res = (List<SVMXC__RMA_Shipment_Line__c>) Database.query(
            newQueryFactory()
                .selectField('Id')
                .selectField(STRING_LINE_STATUS)
                .selectField(STRING_PARTS_ORDER)
                // Corrected double quotes to single quotes
                .setCondition('SVMXC__RMA_Shipment_Order__c IN :shipmentOrderIdSet AND (SVMXC__Line_Status__c != \'Shipped\' AND SVMXC__Line_Status__c != \'Delivered\') ' +
                              'AND (SVMXC__Line_Status__c = \'Open\' OR SVMXC__Line_Status__c = \'On Hold\' OR SVMXC__Line_Status__c = \'Requested\')')
                .toSOQL()
        );
        return res;
    }
}