/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Queueable Class for Parts Order Line Trigger to create Covered Product
 Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Nitin                          7 june 2022         CMSI-36 try catch in execute method 
 *    ------------------------------------------------------------------------------------  
*/ 
public class CreateCoveredProduct_POLHelper implements Queueable {

    Map<Id, Id> mapPOLIdToInstalledProductId = new Map<Id, Id>();
    public static Boolean catchException = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param mapPOLIdToInstalledProductId Map<Id, Id>
    * @return
    */
    public CreateCoveredProduct_POLHelper(Map<Id, Id> mapPOLIdToInstalledProductId) {
        this.mapPOLIdToInstalledProductId = mapPOLIdToInstalledProductId;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) {
        try{ 
        Map<Id,Id> mapPOLIdToWorkOrderId = new Map<Id,Id>();
        Map<Id,List<Applied_Contract__c>> mapWorkOrderIdToServiceContractId = new Map<Id,List<Applied_Contract__c>>();
        Set<Id> setWorkOrderId = new Set<Id>();
        List<SVMXC__Service_Contract_Products__c> lstCoveredProduct = new List<SVMXC__Service_Contract_Products__c>();

        List<SVMXC__Installed_Product__c> lstLoanerInstalledProduct = new InstalledProductsSelector().selectLoanerInstalledProductById(mapPOLIdToInstalledProductId.values());
        
        for (SVMXC__RMA_Shipment_Line__c objPartsOrderLine: new PartsOrderLineSelector().selectPartsOrderLineRecords(mapPOLIdToInstalledProductId.keyset())) {
            if(objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c != NULL) {
                mapPOLIdToWorkOrderId.put(objPartsOrderLine.id, objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c);
            }
        }
        Set<Id> setLoanerInstalledProductIds = UtilsCollection.getSetOfIds(lstLoanerInstalledProduct);
        if(!mapPOLIdToWorkOrderId.isEmpty()) {
            setWorkOrderId = new Set<Id>(mapPOLIdToWorkOrderId.values());
            for(Applied_Contract__c objEntitlement : new AppliedContractsSelector().selectWorkOrderEntitlements(setWorkOrderId)){
                if(!mapWorkOrderIdToServiceContractId.containsKey(objEntitlement.Work_order__c))
                    mapWorkOrderIdToServiceContractId.put(objEntitlement.Work_order__c,new List<Applied_Contract__c>());
                mapWorkOrderIdToServiceContractId.get(objEntitlement.Work_order__c).add(objEntitlement);
            }
        }
        if(!mapWorkOrderIdToServiceContractId.isEmpty()) {
            for(Id idPOL : mapPOLIdToInstalledProductId.keySet()){
                if(setLoanerInstalledProductIds.contains(mapPOLIdToInstalledProductId.get(idPOL)) && mapWorkOrderIdToServiceContractId.containsKey(mapPOLIdToWorkOrderId.get(idPOL))){
                    for(Applied_Contract__c objAppliedContract : mapWorkOrderIdToServiceContractId.get(mapPOLIdToWorkOrderId.get(idPOL))) {
                        lstCoveredProduct.add(new SVMXC__Service_Contract_Products__c(
                            SVMXC__Installed_Product__c = mapPOLIdToInstalledProductId.get(idPOL),
                            SVMXC__Service_Contract__c  = objAppliedContract.Service_Contract__c,
                            SVMXC__Start_Date__c = objAppliedContract.Contract_Start_Date__c,
                            SVMXC__End_Date__c = objAppliedContract.Contract_End_Date__c
                        ));
                    }
                }
            }
        }
        if(!lstCoveredProduct.isEmpty()) {
            insert lstCoveredProduct;
        }
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
    }
    catch(Exception e){
        ApexExceptions.emit('CreateCoveredProduct_POLHelper',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }   
    }
}