/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Queueable Class for Parts Order Line Trigger to swap process on reords 
*/ 
public class SwapProcessOnLineItems_POLHelper implements Queueable {
    List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines = new List<SVMXC__RMA_Shipment_Line__c>();
    Map<Id, sObject> mapPartsOrderLineIdToOldPartsOrderLines = new Map<Id, sObject>();
	public static Boolean catchException = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param lstCurrentPartsOrderLines List of Part Order Lines
    * @param mapPartsOrderLineIdToOldPartsOrderLines Map<Id, sObject>
    */
    public SwapProcessOnLineItems_POLHelper(List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines,  
                                            Map<Id, sObject> mapPartsOrderLineIdToOldPartsOrderLines) {
        this.lstCurrentPartsOrderLines = lstCurrentPartsOrderLines;
        this.mapPartsOrderLineIdToOldPartsOrderLines = mapPartsOrderLineIdToOldPartsOrderLines;
    }

    /*******************************************************************************************************
    * @description execute Method
    * @param qc QueueableContext
    * @modification CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions with Workstream.
    * @return void
    */
    public void execute(QueueableContext qc) {
        try{
        Set<Id> setShippedPartsOrderLines = new Set<Id>();
        Map<Id, Id> mapLineToLinkedReturn = new Map<Id, Id>();
        Set<Id> setIP = new Set <Id>();
        Set<Id> setInstalledProductIds = new Set<Id>();
        Set<Id> setPOLIds = new Set<Id>();
        Map<Id, Id> mapInstalledProductToAccount = new Map<Id,Id>();
        Map <Id, SVMXC__RMA_Shipment_Line__c> mapPOL = new Map<Id, SVMXC__RMA_Shipment_Line__c>();
        Map<ID, List<SVMXC__Service_Contract_Products__c>> mapIPToCoveredProd = new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
       

        for (SVMXC__RMA_Shipment_Line__c objPartOrderLine: lstCurrentPartsOrderLines) {
            SVMXC__RMA_Shipment_Line__c objOldPartsOrderLine = (SVMXC__RMA_Shipment_Line__c) mapPartsOrderLineIdToOldPartsOrderLines.get(objPartOrderLine.Id);
            if (objPartOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PART_ORDER_TYPE_ADVANCEEXCHANGE &&
                    objOldPartsOrderLine.SVMXC__Line_Status__c != objPartOrderLine.SVMXC__Line_Status__c &&
                    objPartOrderLine.SVMXC__Line_Status__c == PartsOrderLines.STRING_PART_ORDER_LINE_STATUS_SHIPPED) {
                mapLineToLinkedReturn.put(objPartOrderLine.SVMXC__Serial_Number__c, objPartOrderLine.SVMXC__Master_Order_Line__c);
                setInstalledProductIds.add(objPartOrderLine.SVMXC__Serial_Number__c);
                setShippedPartsOrderLines.add(objPartOrderLine.id);
            }
        }
        if (!setShippedPartsOrderLines.isEmpty()) {

            setPOLIds.addAll(setShippedPartsOrderLines);
            if (!mapLineToLinkedReturn.isEmpty()) {
                setPOLIds.addAll(mapLineToLinkedReturn.values());
            }
            for(SVMXC__RMA_Shipment_Line__c pol: new PartsOrderLineSelector().selectPartsOrderLineById(setPOLIds)) {
                setIP.add(pol.SVMXC__Serial_Number__c);
                setInstalledProductIds.add(pol.SVMXC__Serial_Number__c);
                if (pol.SVMXC__Serial_Number__r.SVMXC__Company__c != null) {
                    mapInstalledProductToAccount.put(pol.SVMXC__Serial_Number__c, pol.SVMXC__Serial_Number__r.SVMXC__Company__c);
                }
                mapPOL.put(pol.Id, pol);
            }
            
            for (SVMXC__Service_Contract_Products__c coveredProduct: new CoveredProductSelector().selectOrderedCoveredProductsForInstalledProduct(setInstalledProductIds)) {
                if (!mapIPToCoveredProd.containsKey(coveredProduct.SVMXC__Installed_Product__c)) {
                    mapIPToCoveredProd.put(coveredProduct.SVMXC__Installed_Product__c, new list < SVMXC__Service_Contract_Products__c > ());
                }
                mapIPToCoveredProd.get(coveredProduct.SVMXC__Installed_Product__c).add(coveredProduct);
            }

            populateProductsListAndUpdate(mapPOL, setShippedPartsOrderLines, mapIPToCoveredProd, lstCurrentPartsOrderLines);
        }
		 if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
			}
        }catch(Exception e){
            //CMSI-38 Emitting exception to ApexExceptions with Workstream.
            ApexExceptions.emit('SwapProcessOnLineItems_POLHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }

    }

    /*******************************************************************************************************
    * @description update Covered & Installed Products
    * @param mapPOL Map<Id, SVMXC__RMA_Shipment_Line__c>
    * @param setShippedPartsOrderLines Set<id>
    * @param mapIPToCoveredProd Map<ID, List<SVMXC__Service_Contract_Products__c>>
    * @param lstCurrentPartsOrderLines List<SVMXC__Service_Contract_Products__c>
    * @return void
    */
    private static void populateProductsListAndUpdate(Map<Id, SVMXC__RMA_Shipment_Line__c> mapPOL, Set<id> setShippedPartsOrderLines, 
                                                        Map<ID, List<SVMXC__Service_Contract_Products__c>> mapIPToCoveredProd,
                                                        List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines) {
        List<SVMXC__Service_Contract_Products__c> lstUpdateCoveredProduct = new List<SVMXC__Service_Contract_Products__c>();
        List<SVMXC__Installed_Product__c> lstInstalledProduct = new List <SVMXC__Installed_Product__c>();
        Id installedProductId;
        Id linkedPartOrderLine;
        Id linkedInstalledProductId;

        for (SVMXC__RMA_Shipment_Line__c objPartOrderLine: lstCurrentPartsOrderLines) {
            if (setShippedPartsOrderLines.contains(objPartOrderLine.Id) && mapPOL.containsKey(objPartOrderLine.Id)
                    && mapPOL.get(objPartOrderLine.Id).SVMXC__Master_Order_Line__c != NULL
                    && mapPOL.containsKey(mapPOL.get(objPartOrderLine.Id).SVMXC__Master_Order_Line__c)) {
                objPartOrderLine = mapPOL.get(objPartOrderLine.Id);
                installedProductId = objPartOrderLine.SVMXC__Serial_Number__c;
                linkedPartOrderLine = mapPOL.get(objPartOrderLine.Id).SVMXC__Master_Order_Line__c;
                SVMXC__RMA_Shipment_Line__c linkedPOL = mapPOL.get(linkedPartOrderLine);
                linkedInstalledProductId = linkedPOL.SVMXC__Serial_Number__c;
                lstUpdateCoveredProduct = populateLstUpdateCoveredProduct(installedProductId, linkedInstalledProductId, mapIPToCoveredProd );
                SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c(Id = objPartOrderLine.SVMXC__Serial_Number__c);
                SVMXC__Installed_Product__c oldObjIP = new SVMXC__Installed_Product__c(Id = linkedPOL.SVMXC__Serial_Number__c);
                lstInstalledProduct = populateLstInstalledProduct(objIP, oldObjIP, linkedPOL, objPartOrderLine);
            }
        }

        if (!lstInstalledProduct.isEmpty()) {
            update lstInstalledProduct;
        }
        if (!lstUpdateCoveredProduct.isEmpty()) {
            update lstUpdateCoveredProduct;
        }
    }

    /*******************************************************************************************************
    * @description populate LstUpdateCoveredProduct
    * @param installedProductId Id
    * @param linkedInstalledProductId Id
    * @param mapIPToCoveredProd Map<ID, List<SVMXC__Service_Contract_Products__c>>
    * @return List<SVMXC__Service_Contract_Products__c>
    */
    private static List<SVMXC__Service_Contract_Products__c> populateLstUpdateCoveredProduct(Id installedProductId, Id linkedInstalledProductId, 
                                                                Map<ID, List<SVMXC__Service_Contract_Products__c>> mapIPToCoveredProd) {
        List<SVMXC__Service_Contract_Products__c> lstUpdateCoveredProduct = new List<SVMXC__Service_Contract_Products__c>();
        if (installedProductId != null && linkedInstalledProductId != null) {
            if (mapIPToCoveredProd.containsKey(installedProductId)) {
                for (SVMXC__Service_Contract_Products__c covProd: mapIPToCoveredProd.get(installedProductId)) {
                    covProd.SVMXC__Installed_Product__c = linkedInstalledProductId;
                    lstUpdateCoveredProduct.add(covProd);
                }
            }
            if (mapIPToCoveredProd.containsKey(linkedInstalledProductId)) {
                for (SVMXC__Service_Contract_Products__c covProd: mapIPToCoveredProd.get(linkedInstalledProductId)) {
                    covProd.SVMXC__Installed_Product__c = installedProductId;
                    lstUpdateCoveredProduct.add(covProd);
                }
            }
        }
        return lstUpdateCoveredProduct;
    }

    /*******************************************************************************************************
    * @description populate LstInstalledProduct
    * @param objIP SVMXC__Installed_Product__c
    * @param oldObjIP SVMXC__Installed_Product__c
    * @param linkedPOL SVMXC__RMA_Shipment_Line__c
    * @param objPartOrderLine SVMXC__RMA_Shipment_Line__c
    * @return List<SVMXC__Installed_Product__c>
    */
    private static List<SVMXC__Installed_Product__c> populateLstInstalledProduct(SVMXC__Installed_Product__c objIP, SVMXC__Installed_Product__c oldObjIP, 
            SVMXC__RMA_Shipment_Line__c linkedPOL, SVMXC__RMA_Shipment_Line__c objPartOrderLine) {
        List<SVMXC__Installed_Product__c> lstInstalledProduct = new List <SVMXC__Installed_Product__c>();
        Boolean boolIsAddIP = false;
        Boolean boolIsAddLinkedIP = false;

        if (objIP.Id != null && oldObjIP.Id != null) {
            if (linkedPOL.SVMXC__Serial_Number__r.SVMXC__Site__c !=
                objPartOrderLine.SVMXC__Serial_Number__r.SVMXC__Site__c) {
                objIP.SVMXC__Site__c = linkedPOL.SVMXC__Serial_Number__r.SVMXC__Site__c;
                boolIsAddIP = true;
            }
            if (objPartOrderLine.SVMXC__Serial_Number__r.SVMXC__Company__c !=
                linkedPOL.SVMXC__Serial_Number__r.SVMXC__Company__c) {
                Id ipAccountId = objPartOrderLine.SVMXC__Serial_Number__r.SVMXC__Company__c;
                objIP.SVMXC__Company__c = linkedPOL.SVMXC__Serial_Number__r.SVMXC__Company__c;
                oldObjIP.SVMXC__Company__c = ipAccountId;
                boolIsAddLinkedIP = true;
                boolIsAddIP = true;
            }
            if (linkedPOL.SVMXC__Serial_Number__r.SVMXC__Site__c !=
                linkedPOL.SVMXC__RMA_Shipment_Order__r.Shipping_Location__c) {
                oldObjIP.SVMXC__Site__c = linkedPOL.SVMXC__RMA_Shipment_Order__r.Shipping_Location__c;
                boolIsAddLinkedIP = true;

            }
            if (boolIsAddIP) {
                lstInstalledProduct.add(objIP);

            }
            if (boolIsAddLinkedIP) {
                lstInstalledProduct.add(oldObjIP);

            }
        }
        return lstInstalledProduct;
    }
}
