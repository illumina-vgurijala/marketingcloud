/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to process Service loaner INstrument POLs 
*/ 
public class ProcessServiceLoanerInstrument_POLHelper implements Queueable {

    Set<Id> setPartsOrderLineId = new Set<Id>();
    List<ContentDocumentLink> lstCDLToInsert = new List<ContentDocumentLink>();
    Map<Id, SVMXC__Installed_Product__c> mapIpToUpdate = new Map<Id, SVMXC__Installed_Product__c>();
    public static Boolean catchException = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param nonReturnPartsOrderLineIds Set of Part Order Line Ids
    */
    public ProcessServiceLoanerInstrument_POLHelper(Set<Id> setPartsOrderLineId) {
        this.setPartsOrderLineId = setPartsOrderLineId;
    }

    /*******************************************************************************************************
    * @description execute Method
    * @param qc QueueableContext
    * @return void
    */
    public void execute(QueueableContext qc) {
       try{
        updateIPInsertCDL(setPartsOrderLineId);
         //code coverage for catch block
         if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
       }catch(Exception e){
            //catch the exception 
            ApexExceptions.emit('ProcessServiceLoanerInstrument_POLHelper', e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
       }
    }

    /*******************************************************************************************************
    * @description DCP-41581 - To copy the file from Parts Order Line to Installed Product when Line is 
    *                           updated to Shipped.
    * @param setPartsOrderLineId Set<Id>
    * @return
    */
    public void updateIPInsertCDL(Set<Id> setPartsOrderLineId) {
        Set<Id> setInstalledProductId = new set<Id>();
        Map<Id, SVMXC__RMA_Shipment_Line__c> mapCDIdToPOL =  new Map<Id, SVMXC__RMA_Shipment_Line__c>();
        
        Map<Id, SVMXC__RMA_Shipment_Line__c> mapCurrentPartsOrderLines = new Map<Id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineRecords(setPartsOrderLineId));


        Map<Id,ContentDocumentLink> mapPOLtoCDL = new Map<Id,ContentDocumentLink>();
        if(!setPartsOrderLineId.isEmpty()){
            for(ContentDocumentLink objCDL : new ContentDocumentLinksSelector().selectContentDocumentLinks(setPartsOrderLineId)){
                if(!mapPOLtoCDL.containsKey(objCDL.LinkedEntityId)) {
                    mapPOLtoCDL.put(objCDL.LinkedEntityId, objCDL);
                }
            }
        }

        for(Id poId : setPartsOrderLineId) {
            if(mapPOLtoCDL.containskey(poId) && mapCurrentPartsOrderLines != NULL 
                    && mapCurrentPartsOrderLines.containsKey(poId)) {

                SVMXC__RMA_Shipment_Line__c objPOL = mapCurrentPartsOrderLines.get(poId);
                ContentDocumentLink cdl = mapPOLtoCDL.get(poId);
                if(String.isNotBlank(objPOL.SVMXC__Serial_Number__c) && objPOL.Service_Product_Type__c == 'Instrument' 
                        && objPOL.SVMXC__Product__r.Condition_Type__c == 'LOANER') {
                    ContentDocumentLink objCDForInstalledProd =  new ContentDocumentLink(LinkedEntityId = objPOL.SVMXC__Serial_Number__c,
                                        ContentDocumentId = cdl.ContentDocumentId);
                    objCDForInstalledProd.ShareType = 'V';
                    objCDForInstalledProd.Visibility = 'AllUsers';
                    lstCDLToInsert.add(objCDForInstalledProd);
                    setInstalledProductId.add(objPOL.SVMXC__Serial_Number__c);
                    mapCDIdToPOL.put(cdl.ContentDocumentId, objPOL);
               }
           }
        }
        
        if(!mapCDIdToPOL.isEmpty()) {
            List<Id> lstCDId=new List<Id>(mapCDIdToPOL.keySet());
            Map<Integer,String> monthNameMap=new Map<Integer, String>{1 =>'Jan', 2=>'Feb', 3=>'March', 4=>'Apr', 5=>'May',6=>'Jun', 7=>'Jul', 8=>'Aug', 9=>'Sept',10=>'Oct',11=>'Nov', 12=>'Dec'}; 
            for(ContentDocument cdObj : new ContentDocumentSelector().selectById(lstCDId)) {
                Date dt = date.newinstance(cdObj.CreatedDate.year(), cdObj.CreatedDate.month(), cdObj.CreatedDate.day());
                Id installedProdId = mapCDIdToPOL.get(cdObj.Id).SVMXC__Serial_Number__c;
                if(!mapIpToUpdate.containskey(installedProdId)) {
                    mapIpToUpdate.put(installedProdId, new SVMXC__Installed_Product__c(Id= installedProdId));
                }
                mapIpToUpdate.get(installedProdId).Latest_Loaner_Agreement_Signature_Date__c = dt.day() + '-' +  monthNameMap.get(dt.month())  
                                                                                                + '-' + dt.year();
            }
        }
        performDmls();
    }

    /*******************************************************************************************************
    * @description Update Installed Product and insert Content Document 
    */
    public void performDmls() {
        if(!lstCDLToInsert.isEmpty()){
            insert lstCDLToInsert;
        }
        if(!mapIpToUpdate.isEmpty()){
            update mapIpToUpdate.values();
        }
    }
}
