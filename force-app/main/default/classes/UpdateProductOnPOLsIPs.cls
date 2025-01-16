/***************************************************************************************************************************************
* NAME   : UpdateProductOnPOLsIPs
* DESCRIPTION  : Logic for updating POLs/IPs product when product synced to SFDC
*                    
* @AUTHOR : Tapas
* @DATE   : 16-Jul-2021  
* 
* MODIFICATION LOG: 
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------------------------------------------------------------------------------
* Tapas             	   16-Jul-2021          Initial Version. 
* Shivani Jain             22-Aug-2022          DCP-50068 Add a new field for handling more products for Missing products Functionality
* Priya Mukherjee          30-Apr-2024          CMCM-2846 Modify implementation related to Missing product functionality
******************************************************************************************************************************************************************/
public with sharing class UpdateProductOnPOLsIPs implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'UpdateProductOnPOLsIPs';

    /*******************************************************************************************************
    * @description Run Business Logic for updating Installed products, Missing products & POLs
    * @param lstProductIds List<Id>
    * @return void
    * Modified - CMCM-2846 - added logic to replace custom settings Missing_Products__c with custom object Missing_Product__c
    */
    public static void doBusinessLogic(List<Id> lstProductIds){
        system.debug('Inside doBusinessLogic');
        ilib_LogEvent.rootTitle = LOG_TITLE;  
        ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');
        
        try{
            Set<Id> setProdIds = new Set<Id>(lstProductIds);
            List<Product2> lstProds = new ProductsSelector().selectProducts(setProdIds);
            Map<String,Product2> prodCodeToProd = (Map<String,Product2>)UtilsCollection.getMapOfStringToSObject(lstProds,'ProductCode',Map<String, Product2>.class);
            
            List<SVMXC__RMA_Shipment_Line__c> lstPOLs = new PartsOrderLineSelector().selectPOLsFromProductExtIds(prodCodeToProd.keySet());
            List<SVMXC__Installed_Product__c> lstIPs = new InstalledProductsSelector().selectIPsFromProductExtIds(prodCodeToProd.keySet());

            system.debug('lstPOLs=='+ lstPOLs);
            system.debug('prodCodeToProd=='+ prodCodeToProd);
            system.debug('lstIPs=='+ lstIPs);
            updateRelatedRecords(lstPOLs, prodCodeToProd);
            updateRelatedRecords(lstIPs, prodCodeToProd);

            // Query and delete Matching Missing_Product__c records
            List<Missing_Product__c> missingProducts = [SELECT Id, Product_External_Id__c FROM Missing_Product__c WHERE Product_External_Id__c IN :prodCodeToProd.keySet()];
            system.debug('missingProducts=='+ missingProducts);
            delete missingProducts;

            ilib_LogEvent.message('Processed POLs and IPs updates. Missing products deleted: ' + missingProducts.size());

        } catch (Exception ee) {
            ApexExceptions.emit(LOG_TITLE, lstProductIds.get(0), ee);
        }
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    private static void updateRelatedRecords(List<SObject> records, Map<String, Product2> prodCodeToProd) {
        system.debug('Inside updateRelatedRecords');
        for (SObject record : records) {
            String productCode = (String) record.get('Product_Code1__c');
            if (record.get('SVMXC__Product__c') == null && productCode != null && prodCodeToProd.containsKey(productCode)) {
                system.debug('Inside updateRelatedRecords iF statement');
                record.put('SVMXC__Product__c', prodCodeToProd.get(productCode).Id);
            }
        }
        system.debug('records=='+ records);
        if (!records.isEmpty()) {
            update records;
        }
    }
}