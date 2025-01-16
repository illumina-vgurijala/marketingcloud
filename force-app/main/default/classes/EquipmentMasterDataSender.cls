/**
 * @author 
 * @date   
 * @description    DCP-905: Equipment Creation from SFDC to SAP 
 * Modification Log:    
 */
public class EquipmentMasterDataSender extends ilib_RestSender {

	/*
    * @description: Class to send data to external system
    */

    private class CalloutData extends ilib_CalloutData
    {
        SVMXC__Installed_Product__c installProductId;

		/*
        * @description Constructor: to intantiate installed product data 
        * @param installProductId SVMXC__Installed_Product__c
        */	
        public CalloutData(SVMXC__Installed_Product__c installProductId)
        {
            this.installProductId = installProductId;           
        }
    }
    
    private CalloutData data {
        get { return (CalloutData)idata; }
    }
    
    // this class uses selectors to populate CalloutData	
		/*
         * this class uses selectors to populate CalloutData
         */
    protected override ilib_CalloutData retrieveCalloutData()
    {
        InstalledProductsSelector instaProdSelector = new InstalledProductsSelector();
        SVMXC__Installed_Product__c installProductId = instaProdSelector.selectRelatedInstalledProducts(new Set<Id>{ recordId })[0];
        System.debug('retrieveCalloutData Interface:::');

        CalloutData data = new CalloutData(installProductId);
        return data;
    }

    /**
     *  @author  Mandeep Singh
     *  @description   this method is the last line of defense to make sure we don't send garbage to
     *      the target system.  Some validation will occur before the interface is called
     *      but we may allow retriggers by admins so we need these sanity checks here
     *      it builds a list of errors which are thrown to the caller
     */
    protected override void validateFields() { }

    /**
     *  @author  Mandeep Singh
     *  @description    US-4885: This Method will return String body in JSON format which will be used in HTTP request method.
     */
    protected override String createJSON()
    {
        EquipmentMasterWrapper eqw = new EquipmentMasterWrapper();
        Set<Id> setInstalledProductsIds = new Set<Id> { data.installProductId.Id };

        Map<Id,SVMXC__Installed_Product__c> mapIdToInstalledProduct = new Map<Id,SVMXC__Installed_Product__c>(new InstalledProductsSelector().selectInstalledProductsFromIds(setInstalledProductsIds));
        System.debug('mapIdToInstalledProduct ==> ' +mapIdToInstalledProduct );
        
        //Holds Id and EquipmentWrapper data type records.  
        Map<Id,EquipmentMasterWrapper.InstalledProduct> instPrdIdTOInstPrdHeader = new Map<Id,EquipmentMasterWrapper.InstalledProduct>();
     
        for (Id instPrdId : mapIdToInstalledProduct.keyset())
        {
            if (!instPrdIdTOInstPrdHeader.keyset().contains(instPrdId))
            {
                EquipmentMasterWrapper.InstalledProduct objINWListInstProduct = new EquipmentMasterWrapper.InstalledProduct(mapIdToInstalledProduct.get(instPrdId));
                instPrdIdTOInstPrdHeader.put(instPrdId,objINWListInstProduct);
            }
        }
        eqw.InstalledProduct = instPrdIdTOInstPrdHeader.values();

        String strJson = JSON.serializePretty(eqw);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
        
    }
    /*
    * @description: Overrided method definition for handleResult
    * @param res HTTPResponse
    * @return void
    */	                       
    protected override void handleResult(HTTPResponse res)
    {
        System.debug('res: '+res);
    }

}