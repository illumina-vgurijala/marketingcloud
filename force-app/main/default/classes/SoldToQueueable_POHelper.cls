/**
* @author Shivani Jain
* @date 31st August 2022
*
* @description DCP-43629 Queueable Class to Update SOld To Field on Parts Order 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani Jain            20-02-2023          DCP-59060 - Add Check for Sold To Account Status to Parts Order Sold To Population Logic
*/ 
public with sharing class SoldToQueueable_POHelper implements Queueable {

    Set<Id> setPOIds = new Set<Id>();
    Map<Id, Boolean> poIdToChangeMap = new Map<Id, Boolean>();
    private static final String LOG_TITLE = 'SoldToQueueable_POHelper';
    private static final String OPEN_SQ_BRACKET = '[';
    private static final Set<String> SET_EXCLUDE_ACCOUNT_STATUS = new Set<String> {'Suspended', 'Obsolete', 'Cancelled', 'Rejected', 'Unverified', 'Pending Obsolete'}; //DCP-59060
    public static Boolean ranOnce = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param setPOIds Set<Id>
    * @param poIdToChangeMap Map<Id, Boolean> 
    * @return
    */
    public SoldToQueueable_POHelper(Set<Id> setPOIds, Map<Id, Boolean> poIdToChangeMap) {
        this.setPOIds = setPOIds;
        this.poIdToChangeMap = poIdToChangeMap;
    }
    
    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE+'.execute()');
        try {
            ranOnce = true;
            updateSoldToOnPO(setPOIds, poIdToChangeMap);
            ilib_LogEvent.pop();
        } catch(Exception ex) {
            ApexExceptions.emit('SoldToQueueable_POHelper.'+ 'updateSoldToOnPO', ex);
            throw ex;
        }
        ilib_LogEvent.emit(); 

    }

    /*******************************************************************************************************
    * @descriptionMethod to update SOld To on Parts Order
    * @param listSoldToUpdate List<SVMXC__RMA_Shipment_Order__c>
    * @param poIdToChangeMap Map<Id, Boolean>
    * @return void
    */
    public static void updateSoldToOnPO(Set<Id> setPOIds, Map<Id, Boolean> poIdToChangeMap) {
        ilib_LogEvent.push(LOG_TITLE+'.updateSoldToOnPO()');
        ilib_LogEvent.info('setPOIds :'+ setPOIds);
        ilib_LogEvent.info('poIdToChangeMap :'+ poIdToChangeMap);


        Map<String, String> countryToAccountERPIdMap = getDefaultSoldToMapping();
        List<SVMXC__RMA_Shipment_Order__c> recsToUpdate = new List<SVMXC__RMA_Shipment_Order__c>();
        List<SVMXC__RMA_Shipment_Order__c> recsToProcessForSoldTo = new List<SVMXC__RMA_Shipment_Order__c>();
        Map<Id,Id> poIdToAccId = new Map<Id, Id>();
        Map<Id,Id> poIdToSoldAccId = new Map<Id, Id>();

        //START - DCP-59060
        Set<String> accIdsMetadata = new Set<String>();
        List<SVMXC__RMA_Shipment_Order__c> tempRecsToUpdate = new List<SVMXC__RMA_Shipment_Order__c>();
        //END - DCP-59060

        for(SVMXC__RMA_Shipment_Order__c partsOrder : new PartsOrdersSelector().selectPartsOrders(setPOIds)) {
            String shippingLocation = getShippingCountry(partsOrder);

            if(String.isNotEmpty(shippingLocation) && countryToAccountERPIdMap.containsKey(shippingLocation)) {
                String erpCustomerId = countryToAccountERPIdMap.get(shippingLocation);

                if(partsOrder.Sold_To__r?.ERP_Customer_Id__c != erpCustomerId) {
                    Account accRec = new Account(ERP_Customer_Id__c = erpCustomerId);
                    SVMXC__RMA_Shipment_Order__c poRec = new SVMXC__RMA_Shipment_Order__c(Id = partsOrder.Id, Sold_To__r = accRec);
                    //START - DCP-59060
                    accIdsMetadata.add(erpCustomerId);
                    tempRecsToUpdate.add(poRec);
                    //END - DCP- 59060
                }

            } else if (partsOrder.SVMXC__Service_Order__c != NULL && !partsOrder.SVMXC__Service_Order__r.Partner_Work_Order__c && partsOrder.SVMXC__Company__c != NULL
                    && ((poIdToChangeMap == NULL && partsOrder.SVMXC__Company__c != partsOrder.SVMXC__Service_Order__r.SVMXC__Company__c) 
                        || (poIdToChangeMap != NULL && poIdToChangeMap.containsKey(partsOrder.Id) && poIdToChangeMap.get(partsOrder.Id)))) {
                poIdToAccId.put(partsOrder.id, partsOrder.SVMXC__Company__c);
                poIdToSoldAccId.put(partsOrder.id, null);
                recsToProcessForSoldTo.add(partsOrder);
            } else if(partsOrder.SVMXC__Service_Order__c != NULL && partsOrder.SVMXC__Service_Order__r.Partner_Work_Order__c 
                    && poIdToChangeMap == NULL && partsOrder.Sold_To__c == partsOrder.SVMXC__Service_Order__r.Sold_To_Account__c) {
                SVMXC__RMA_Shipment_Order__c poRec = new SVMXC__RMA_Shipment_Order__c(Id = partsOrder.Id, Sold_To__c = NULL);
                recsToUpdate.add(poRec);    
            }
                
        }

        if(!poIdToAccId.isEmpty()) {
            List<SVMXC__RMA_Shipment_Order__c> recsToUpdateHierarchy = getSoldToFromHierarchy(poIdToAccId, poIdToSoldAccId, recsToProcessForSoldTo);
            if(!recsToUpdateHierarchy.isEmpty()) {
                recsToUpdate.addAll(recsToUpdateHierarchy);
            }
        }

        //DCP-59060
        excludeAccountStatusBasedLogic(accIdsMetadata, tempRecsToUpdate, recsToUpdate);

        if(!recsToUpdate.isEmpty()) {
            PartsOrders.bypassPartsOrderStatusUpdate = true;
            update recsToUpdate;
        }
        PartsOrders.bypassPartsOrderStatusUpdate = false;

        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  DCP-43629 return Shipping Country
    * @param partsOrder Parts Order record
    * @return String
    */
    private static String getShippingCountry(SVMXC__RMA_Shipment_Order__c partsOrder) {
        String shippingLocation = partsOrder.Shipping_Location__c != NULL ? partsOrder.Shipping_Location__r.SVMXC__Country__c : (partsOrder.Shipping_Country__c != NULL ? partsOrder.Shipping_Country__c : '');
        if(String.isNotEmpty(shippingLocation) && shippingLocation.contains(OPEN_SQ_BRACKET)) {
            shippingLocation = shippingLocation.substringBefore(OPEN_SQ_BRACKET).trim();
        }

        return shippingLocation;
    }

    
    /*******************************************************************************************************
    * @description  DCP-43629 Parts Orders Sold To Population Logic
    * @param records Parts Order Lines List
    * @return void
    */
    private static Map<String, String> getDefaultSoldToMapping() {
        ilib_LogEvent.push(LOG_TITLE+'.getDefaultSoldToMapping()');

        Map<String, String> countryToAccountERPIdMap = new Map<String, String>();
        for(Default_PO_Sold_To_Party__mdt soldToMapping : Default_PO_Sold_To_Party__mdt.getAll().values()) {
            countryToAccountERPIdMap.put(soldToMapping.Shipping_Country__c, soldToMapping.Account_ERP_Customer_ID__c);
        }

        ilib_LogEvent.pop();
        return countryToAccountERPIdMap;
    }

    /*******************************************************************************************************
    * @description  DCP-43629 Parts Orders Sold To Population Logic
    * @param records Parts Order Lines List
    * @return void
    */
    public static List<SVMXC__RMA_Shipment_Order__c> getSoldToFromHierarchy(Map<Id,Id> poIdToAccId, Map<Id,Id> poIdToSoldAccId, List<SVMXC__RMA_Shipment_Order__c> recsToProcessForSoldTo) {
        ilib_LogEvent.push(LOG_TITLE+'.getSoldToFromHierarchy()');

        List<SVMXC__RMA_Shipment_Order__c> lstPOToUpdatedSoldTo = new List<SVMXC__RMA_Shipment_Order__c>();

        Map<Id, Id> poIdToSoldAccountId = ServiceUtility.getSoldToAccFromAccHierarchy(poIdToAccId, poIdToSoldAccId);

        if(!poIdToSoldAccountId.isEmpty()) {
           for(SVMXC__RMA_Shipment_Order__c objPO : recsToProcessForSoldTo) {
                if(poIdToSoldAccountId.containskey(objPO.id) && objPO.Sold_To__c != poIdToSoldAccountId.get(objPO.id)) {
                    SVMXC__RMA_Shipment_Order__c poRec = new SVMXC__RMA_Shipment_Order__c(Id = objPO.Id, Sold_To__c = poIdToSoldAccountId.get(objPO.id));
                    lstPOToUpdatedSoldTo.add(poRec);
                }
            }
        }
        
        ilib_LogEvent.pop();
        if(!lstPOToUpdatedSoldTo.isEmpty()) {
            return lstPOToUpdatedSoldTo;
        }

        return new List<SVMXC__RMA_Shipment_Order__c>();
    }

    /*******************************************************************************************************
    * @description  DCP-59060 - To exclude update of Parts Order where identified Sold To from metadata 
    *               is one among SET_EXCLUDE_ACCOUNT_STATUS
    * @param records Parts Order Lines List
    * @return void
    */
    private static void excludeAccountStatusBasedLogic(Set<String> accIdsMetadata, List<SVMXC__RMA_Shipment_Order__c> tempRecsToUpdate, 
                                                                                                            List<SVMXC__RMA_Shipment_Order__c> recsToUpdate) {
        ilib_LogEvent.push(LOG_TITLE+'.excludeAccountStatusBasedLogic()');
        ilib_LogEvent.info('accIdsMetadata :'+ accIdsMetadata);

        if(!accIdsMetadata.isEmpty()) {
            Map<String, Account> accountsMap = new Map<String, Account>();

            for(Account accRec : new AccountsSelector().selectAccountsForERPCustomerIds(accIdsMetadata)) {
                if(SET_EXCLUDE_ACCOUNT_STATUS.contains(accRec.Account_Status__c)) {
                    accountsMap.put(accRec.ERP_Customer_Id__c , accRec);
                }
            } 
            if(accountsMap.isEmpty()) {
                recsToUpdate.addAll(tempRecsToUpdate);
            } else {
                for(SVMXC__RMA_Shipment_Order__c rec : tempRecsToUpdate) {
                    String accERP = rec.Sold_To__r.ERP_Customer_Id__c;
                    if(!accountsMap.containsKey(accERP)) {
                        recsToUpdate.add(rec);
                    } else {
                        rec.Sold_To__r = NULL;
                        rec.Sold_To__c = NULL;
                        recsToUpdate.add(rec);
                    }
                }
            }
        }
        ilib_LogEvent.pop();
    }


}