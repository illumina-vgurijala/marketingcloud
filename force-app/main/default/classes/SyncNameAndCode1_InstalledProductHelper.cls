/**
* @author Shivani Jain
* @date 17th August 2022
*
* @description DCP-50068 Helper Class for Installed product trigger to populate Product Code 1 and Name field
* Test Class - TestSyncNameAndCode1_IPHelper 
*/ 
public with sharing class SyncNameAndCode1_InstalledProductHelper {

    private static final String LOG_TITLE = 'SyncNameAndCode1_InstalledProductHelper';
   
    /*******************************************************************************************************
    * @description DCP-50068 - populates Product Code 1 and Name on Installed Product
    * @param records list of new records
    * @param oldRecords map of old records
    * @return void
    */
    public static void populateFields(SVMXC__Installed_Product__c installedProd, SVMXC__Installed_Product__c oldRec) {

        ilib_LogEvent.push(LOG_TITLE + '.populateFields()'); 
        ilib_LogEvent.info('installedProd :'+installedProd.Id);

        if(installedProd.RecordTypeId != InstalledProducts.LIMS_INSTALLED_PRODUCT && (oldRec == NULL || oldRec.SVMXC__Product__c != installedProd.SVMXC__Product__c 
                || oldRec.SVMXC__Serial_Lot_Number__c != installedProd.SVMXC__Serial_Lot_Number__c || oldRec.Product_Code1__c != installedProd.Product_Code1__c)) {
            if(installedProd.SVMXC__Serial_Lot_Number__c != NULL && (installedProd.SVMXC__Product__c != NULL || installedProd.Product_Code1__c != NULL)) {
                installedProd.Name = generateName(installedProd);
            }
        }

        if(InstalledProducts.mapProducts.containsKey(installedProd.SVMXC__Product__c) 
                && ((oldRec == NULL && String.isEmpty(installedProd.Product_Code1__c)) || (oldRec != NULL && oldRec.SVMXC__Product__c != installedProd.SVMXC__Product__c 
                    && installedProd.Product_Code1__c != InstalledProducts.mapProducts.get(installedProd.SVMXC__Product__c).ProductCode))) {
            installedProd.Product_Code1__c = InstalledProducts.mapProducts.get(installedProd.SVMXC__Product__c).ProductCode;
        }
        ilib_LogEvent.pop(); 
    }

    /*******************************************************************************************************
    * @description DCP-50068 - generate Expected Name Value
    * @param records list of new records
    * @param oldRecords map of old records
    * @return void
    */
    private static String generateName(SVMXC__Installed_Product__c installedProd) {
        String prodCode = InstalledProducts.mapProducts.get(installedProd.SVMXC__Product__c) != NULL ? InstalledProducts.mapProducts.get(installedProd.SVMXC__Product__c).ProductCode : 
                            (String.isNotBlank(installedProd.Product_Code1__c) ? installedProd.Product_Code1__c : '');
       
        return  installedProd.SVMXC__Serial_Lot_Number__c + '-' + prodCode;
    }
}