/***************************************************************************************************************************************
* NAME   : OrderLineItemService 
* DESCRIPTION  : Service class for ApptusOrderLineItem object.
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 08-08-2024  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Arquimidez Mora         08-Aug-2024         CMCM-9644: Methods to delete Order Line Items and update related Asset Line Items
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class OrderLineItemService {
    private static final String LOG_TITLE = 'OrderLineItemService';
    public static final String STRING_ORDER_LINE_ITEM_STATUS_REJECTED = 'Rejected'; //CMCM-9644
    public static final String STRING_ORDER_LINE_ITEM_STATUS_ACTIVATED = 'Actived'; //CMCM-9644
    public static final String STRING_STATUS_CANCELLED = 'Cancelled';
    public static final String STRING_LINE_STATUS_RENEWED = 'Renewed';
    public static final String STRING_ASSET_LINE_STATUS_PENDING_ACCEPTANCE = 'Pending Acceptance';
    public static final String STRING_ASSET_LINE_STATUS_PENDING_ACTIVATION = 'Pending Activation';

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9644 method update order line item status to rejected and delete rejected recods.
    **/
    public static void updateStatusToRejectedAndDeleteRejectedRecords (List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems, Map<Id, sObject> mapOldRecords){
        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToDelete = new List<Apttus_Config2__OrderLineItem__c>();

        for(Apttus_Config2__OrderLineItem__c objOrderLineItem : lstOrderLineItems){
            Apttus_Config2__OrderLineItem__c objOldOrderLineItem = (Apttus_Config2__OrderLineItem__c)mapOldRecords.get(objOrderLineItem.Id);
            Apttus_Config2__OrderLineItem__c objOrderLineToUpdateDelete = new Apttus_Config2__OrderLineItem__c();
            objOrderLineToUpdateDelete.Id = objOrderLineItem.Id;

            if(
                (objOrderLineItem.Reason_For_Rejection__c != objOldOrderLineItem.Reason_For_Rejection__c) && 
                objOrderLineItem.Reason_For_Rejection__c != null && objOrderLineItem.Item_Status__c != STRING_ORDER_LINE_ITEM_STATUS_REJECTED
            ){
                objOrderLineToUpdateDelete.Item_Status__c = STRING_ORDER_LINE_ITEM_STATUS_REJECTED;
                lstOrderLineItemsToUpdate.add(objOrderLineToUpdateDelete);
                lstOrderLineItemsToDelete.add(objOrderLineToUpdateDelete);
            }
            if(
                ((objOrderLineItem.Item_Status__c != objOldOrderLineItem.Item_Status__c) && 
                objOrderLineItem.Item_Status__c == STRING_ORDER_LINE_ITEM_STATUS_REJECTED)
            ){
                lstOrderLineItemsToDelete.add(objOrderLineToUpdateDelete);
            }
        }

        updateOrderLineItem(lstOrderLineItemsToUpdate);
        deleteOrderLineItem(lstOrderLineItemsToDelete);
    }

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9644 method that update status and asset status fields from Asset Line Item related record.
    **/
    public static void updateStatusAndAssetLineItemLineStatus(List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems, Map<Id, sObject> mapOldRecords){
        Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItems = new Map<Id, Apttus_Config2__AssetLineItem__c>(); 
        List<Apttus_Config2__AssetLineItem__c> lstAssetLineItemsToUpdate = new List<Apttus_Config2__AssetLineItem__c>();
        List<String> lstOrderLineItemQueryFields = new List<String>{
            'Apttus_Config2__Status__c','Apttus_Config2__LineStatus__c',
            'Apttus_Config2__AssetLineItemId__c'
        };
        List<String> lstAssetLineItemQueryFields = new List<String>{'Status__c','Apttus_Config2__AssetStatus__c','Days_After_Expiry__c'};
        Set<Id> setOrderLineItemsIds = new Set<Id>();
        Set<Id> setAssetLineItemsIds = new Set<Id>();
        
        for(Apttus_Config2__OrderLineItem__c objOrderLineItem : lstOrderLineItems){
            setOrderLineItemsIds.add(objOrderLineItem.Id);
            setAssetLineItemsIds.add(objOrderLineItem.Apttus_Config2__AssetLineItemId__c);
        }

        List<Apttus_Config2__OrderLineItem__c> lstQueryOrderLineItems = new ApttusOrderLineItemsSelector().selectOrderLineItem(setOrderLineItemsIds, lstOrderLineItemQueryFields);
        List<Apttus_Config2__AssetLineItem__c> lstQueryAssetLineItems = new ApttusAssetLineItemsSelector().selectAssetLineItem(setAssetLineItemsIds, lstAssetLineItemQueryFields);
        for(Apttus_Config2__AssetLineItem__c objAssetLineItem : lstQueryAssetLineItems){
            mapAssetLineItems.put(objAssetLineItem.Id, objAssetLineItem);
        }

        for(Apttus_Config2__OrderLineItem__c objQueryOrderLineItem : lstQueryOrderLineItems){
            Apttus_Config2__OrderLineItem__c objOldOrderLineItem = (Apttus_Config2__OrderLineItem__c)mapOldRecords.get(objQueryOrderLineItem.Id);
            Apttus_Config2__AssetLineItem__c objAssetLineItem = (mapAssetLineItems.containsKey(objQueryOrderLineItem.Apttus_Config2__AssetLineItemId__c)) ? mapAssetLineItems.get(objQueryOrderLineItem.Apttus_Config2__AssetLineItemId__c) : null;
            if(
                objQueryOrderLineItem.Apttus_Config2__Status__c != objOldOrderLineItem.Apttus_Config2__Status__c && 
                objQueryOrderLineItem.Apttus_Config2__Status__c != STRING_ORDER_LINE_ITEM_STATUS_ACTIVATED && objQueryOrderLineItem.Apttus_Config2__Status__c != STRING_STATUS_CANCELLED && 
                objQueryOrderLineItem.Apttus_Config2__LineStatus__c == STRING_LINE_STATUS_RENEWED &&  objQueryOrderLineItem.Apttus_Config2__AssetLineItemId__c != null && 
                (objAssetLineItem != null && objAssetLineItem.Days_After_Expiry__c != null)
            ){
                if(objAssetLineItem.Days_After_Expiry__c < 0){
                    objAssetLineItem.Status__c = STRING_ASSET_LINE_STATUS_PENDING_ACCEPTANCE;
                }
                if(objAssetLineItem.Days_After_Expiry__c >= 0){
                    objAssetLineItem.Status__c = STRING_ASSET_LINE_STATUS_PENDING_ACTIVATION;
                }
                lstAssetLineItemsToUpdate.add(objAssetLineItem);
            }else{
                if(
                    objQueryOrderLineItem.Apttus_Config2__Status__c != objOldOrderLineItem.Apttus_Config2__Status__c && 
                    objQueryOrderLineItem.Apttus_Config2__Status__c == STRING_STATUS_CANCELLED && objQueryOrderLineItem.Apttus_Config2__LineStatus__c == STRING_LINE_STATUS_RENEWED && 
                    objQueryOrderLineItem.Apttus_Config2__AssetLineItemId__c != null
                ){
                    objAssetLineItem.Status__c = STRING_STATUS_CANCELLED;
                    objAssetLineItem.Apttus_Config2__AssetStatus__c = STRING_STATUS_CANCELLED;
                    lstAssetLineItemsToUpdate.add(objAssetLineItem);
                }
            }
        }

        updateAssetLineItemRelated(lstAssetLineItemsToUpdate);
    }

    /**
     *  @author Arquimidez Mora
     *  @description CMCM-9644 Method to update Order Line Item list.
     *  @return void
    **/
    public static void updateOrderLineItem(List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToUpdate){
        List<Database.SaveResult> lstSaveErrors = Database.update(lstOrderLineItemsToUpdate, false);
        ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
    }

    /**
     *  @author Arquimidez Mora
     *  @description CMCM-9644 Method to delete rejected Order Line items.
     *  @return void
    **/
    public static void deleteOrderLineItem(List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToDelete){
        List<Database.DeleteResult> lstOrderLineItemsDeleted = Database.delete(lstOrderLineItemsToDelete, false);
        ApexExceptions.emitDeleteErrors(lstOrderLineItemsDeleted,LOG_TITLE);
    }

    /**
     *  @author Arquimidez Mora
     *  @description CMCM-9644 Method to delete rejected Order Line items related to Work Orders.
     *  @return void
    **/
    public static void deleteWorkOrderRelatedOrderLineItems(Set<Id> setWorkOrderIds){
        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToDelete = getWorkOrderRelatedOrderLineItemsToDelete(setWorkOrderIds);
        if(lstOrderLineItemsToDelete.size() > 0){
            deleteOrderLineItem(lstOrderLineItemsToDelete);
        }
    }

    /**
     *  @author Arquimidez Mora
     *  @description CMCM-9644 Method to get a list of Order Line items by Work Order.
     *  @return Order Line Items List
    **/
    private static List<Apttus_Config2__OrderLineItem__c> getWorkOrderRelatedOrderLineItemsToDelete (Set<Id> setWorkOrderIds){
        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItemsToDelete = new List<Apttus_Config2__OrderLineItem__c>();
        Set<Id> setOpportunityIds = new Set<Id>();
        Set<Id> setOrderIds = new Set<Id>();
        try {
            List<Opportunity> lstOpportunities = new OpportunitySelector().fetchOpportunityRelatedToWorkOrders(setWorkOrderIds); 
            for(Opportunity objOpportunity : lstOpportunities){
                setOpportunityIds.add(objOpportunity.Id);
            }
            List<Apttus_Config2__Order__c> lstOrders = new ApttusOrdersSelector().fetchOrderByRelatedOpportunity(setOpportunityIds); 
            for(Apttus_Config2__Order__c objOrder : lstOrders){
                setOrderIds.add(objOrder.Id);
            }
            lstOrderLineItemsToDelete = new ApttusOrderLineItemsSelector().fetchOrderLineItemsByOrder(setOrderIds);
        } catch (Exception ex) {
            ilib_LogEvent.info('## Exception : ' + ex.getStackTraceString());
            ilib_LogEvent.info('## Exception Message : ' + ex.getMessage());
        }
        return lstOrderLineItemsToDelete;
    }

    /**
     *  @author Arquimidez Mora
     *  @description CMCM-9644 Method to update Asset Line Item list related to the Order Line Item records triggered.
     *  @return void
    **/
    public static void updateAssetLineItemRelated(List<Apttus_Config2__AssetLineItem__c> lstAssetLineItemsToUpdate){
        List<Database.SaveResult> lstSaveErrors = Database.update(lstAssetLineItemsToUpdate, false);
        ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
    }
}