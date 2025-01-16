/************************************************************************************************************************************************************************************
* NAME         : ServiceBOMDataReceiver
* DESCRIPTION  : Service BOM Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 14-Sep-2018  
* TestClass coverage for 90%: TestServiceBOMDataReceiver
* TestClass coverage for 75%: TestServiceBOMDataReceiver
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Nitin                   22-08-2022           CMSI-221: Instrumentation 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@RestResource(urlMapping = '/ServiceBOMSyncInterface/*')
global with sharing class ServiceBOMDataReceiver extends ilib_RestReceiver {

    private static List <ServiceBOMDataReceiverWrapper.ServiceBOM> wrapServiceBOM;
    private static final String LOG_TITLE = 'ServiceBOMDataReceiver';
    @HttpPost
	
		/*
         * description - upsertIncomingValues method
		 * return - void
         */ 	
    global static void upsertIncomingValues()
    {
        
        ServiceBOMDataReceiver instantiated = new ServiceBOMDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE+'.upsertIncomingValues()');
        String strRestError = null;
        Id primaryRecordId;
        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);
        ilib_LogEvent.info('strJsonInput : '+strJsonInput);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            // if there is no body found, throw an error.
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapServiceBOM);

            primaryRecordId = upsertIncomingValuesImpl();
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        ilib_LogEvent.info('isSuccess : '+isSuccess);
        if (isSuccess) {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError),
                primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

		/*
         * description - deserializeInputs method
		 * return - void
         */ 
    private static void deserializeInputs(String jsonInput)
    {
        wrapServiceBOM = (List < ServiceBOMDataReceiverWrapper.ServiceBOM > ) System.JSON.deserialize(jsonInput, List < ServiceBOMDataReceiverWrapper.ServiceBOM > .class);
        ilib_LogEvent.info('wrapServiceBOM : '+wrapServiceBOM);
    }

		/*
         * description - upsertIncomingValuesImpl method
		 * return - Id
         */ 
    private static Id upsertIncomingValuesImpl()
    {

        Service_Bill_Of_Materials__c oneBom;

        /* REGISTER HELPERS : MANDATORY STEP */
        // Register custom helpers: This is a mandatory step.
        ilib_UpsertHelpers.ServiceBOMUnitofWorkHelper serviceBOMWork = new ilib_UpsertHelpers.ServiceBOMUnitofWorkHelper();
        ilib_UpsertHelpers.FruListUnitOfWorkHelper fruListWork = new ilib_UpsertHelpers.FruListUnitOfWorkHelper();
        /* END */
        ilib_LogEvent.push(LOG_TITLE+'.upsertIncomingValuesImpl()');
        ilib_LogEvent.info('serviceBOMWork : '+serviceBOMWork);
        ilib_LogEvent.info('fruListWork : '+fruListWork);
        /* STORE ALL LOOKUP VARIABLES HERE */
        //Product lookup based on Material Number of Product.
        Set < String > productExtIdSet = new Set < String > ();
        //Map ProductMaterialId to PrdId
        Map < String, String > productMaterialIdToPrdId = new Map < String, String > ();

        //Parent Product lookup based on Material Number of Product.
        Set < String > parentProductExtIdSet = new Set < String > ();
        //Map ParentProductMaterialId to PrdId
        Map < String, String > parentProductMaterialIdToPrdId = new Map < String, String > ();
		
		//DCP-21788
        //Delete existing FRUList Records
        Set < String > serviceBomExtIdSet = new Set < String > ();
        List < FRU_List__c > oldLstFRUList = new List < FRU_List__c > ();
		
		 //Service BOM - Name change
        Map < String, String > productMaterialIdToProductDescription = new Map < String, String > ();


       /* UNIT OF WORK : GENERIC STATEMENT */
        //unit of work: This is a mandatory step.
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                Service_Bill_Of_Materials__c.SObjectType,
                FRU_List__c.SObjectType
            });
        /* / UNIT OF WORK : GENERIC STATEMENT */

        /* REGISTER OBJECTS : GENERIC STATEMENT */
        //register your objects: This is a mandatory step.
        uow.registerWork(serviceBOMWork);
        uow.registerWork(fruListWork);
        /* / REGISTER OBJECTS : GENERIC STATEMENT */

        //if the recieved JSON body is not null, process it.
        if (wrapServiceBOM != null)
        {
            /** POPULATE LOOKUP VARIABLES **/
            //iterate over the Service BOM record (header)
            for (ServiceBOMDataReceiverWrapper.ServiceBOM wrapperServiceBOM: wrapServiceBOM)
            {
				 //DCP-21788
                serviceBomExtIdSet.add(wrapperServiceBOM.ERP_Service_BOM_Number);    
                /*ITERATE OVER CHILD RECORDS*/
                for (ServiceBOMDataReceiverWrapper.FRUList wrapperFruList: wrapperServiceBOM.FRUList)
                {
					//GetProductExtId
                    if (String.isNotBlank(wrapperFruList.Parent_Product))
                        parentProductExtIdSet.add(wrapperFruList.Parent_Product);

                    /*ITERATE OVER CHILD SUB ARRAY RECORDS*/
                    for (ServiceBOMDataReceiverWrapper.Product_Group wrapperFruListProductGroup: wrapperFruList.Product_Group)
                    {
                        //GetProductExtId
                        if (String.isNotBlank(wrapperFruListProductGroup.Product))
                            productExtIdSet.add(wrapperFruListProductGroup.Product);
                    }
                }    
            }
            ilib_LogEvent.info('serviceBomExtIdSet : '+serviceBomExtIdSet);
            ilib_LogEvent.info('productExtIdSet : '+productExtIdSet);
            ilib_LogEvent.info('parentProductExtIdSet : '+parentProductExtIdSet);
            /********************************************************** Getting Salesforce Id of lookup variables ****************************/
            //Map ProductMaterialId to PrdId  r.Material_Number__c productExtIdSet
            for (Product2 prdM: new ProductsSelector().selectProductsForMaterialNumber(productExtIdSet)) {
                productMaterialIdToPrdId.put(prdM.Material_Number__c, prdM.id);
            }
            ilib_LogEvent.info('productMaterialIdToPrdId : '+productMaterialIdToPrdId);
            //Map ParentProductMaterialId to PrdId  r.Material_Number__c parentProductExtIdSet
            for (Product2 parentProductId: new ProductsSelector().selectProductsForMaterialNumber(parentProductExtIdSet)) {
                parentProductMaterialIdToPrdId.put(parentProductId.Material_Number__c, parentProductId.id);
            }
			ilib_LogEvent.info('parentProductMaterialIdToPrdId : '+parentProductMaterialIdToPrdId);
			 //Service BOM - Name change
            for (Product2 prdM: new ProductsSelector().selectProductsForMaterialNumber(serviceBomExtIdSet)) {
                productMaterialIdToProductDescription.put(prdM.Material_Number__c, prdM.Name);
            }
			ilib_LogEvent.info('productMaterialIdToProductDescription : '+productMaterialIdToProductDescription);
			 //DCP-21788               
             for (FRU_List__c fruListRecords: new FRUListSelector().selectFRUListForServiceBOMNumber(serviceBomExtIdSet)) {
             oldLstFRUList.add(fruListRecords);   
            }
            /********************************************************** END ****************************/

            /********************************************************** INSTANTIATE SOBEJCTS AND ITS FIELDS ****************************/
            //iterate over the Service BOM record (header)
            for (ServiceBOMDataReceiverWrapper.ServiceBOM wrapperServiceBOM: wrapServiceBOM)
            {
                //get the object details from the method created in ServiceBOMDataReceiverWrapper.
                //It has all the fields information which will be updated.
                Service_Bill_Of_Materials__c serviceBOMObj = wrapperServiceBOM.getSObject();
                ilib_LogEvent.message('serviceBOMObj : '+serviceBOMObj);
                //Service BOM - Name change
                serviceBOMObj.Name = String.isNotBlank(wrapperServiceBOM.Name) ? wrapperServiceBOM.Name : productMaterialIdToProductDescription.containsKey(wrapperServiceBOM.ERP_Service_BOM_Number) ? productMaterialIdToProductDescription.get(wrapperServiceBOM.ERP_Service_BOM_Number) : null;
                oneBom = serviceBOMObj;
                serviceBOMWork.registerUpsert(serviceBOMObj);

                /* ITERATE OVER CHILD RECORDS */
                //Iterate over the child records. 
                for (ServiceBOMDataReceiverWrapper.FRUList wrapperFruList: wrapperServiceBOM.FRUList)
                {
                    for (ServiceBOMDataReceiverWrapper.Product_Group wrapperFruListProductGroup: wrapperFruList.Product_Group)
                    {
                        //get the object details from the method created in ServiceBOMDataReceiverWrapper.
                        //It has all the fields information which will be updated.
                        FRU_List__c fruListObj = wrapperFruList.getSObject();

                        fruListObj.SVMX_PS_External_ID__c = wrapperServiceBOM.ERP_Service_BOM_Number+wrapperFruList.Parent_Product+wrapperFruListProductGroup.Product;
                        fruListObj.ERP_Product__c = productMaterialIdToPrdId.containsKey(wrapperFruListProductGroup.Product) ? productMaterialIdToPrdId.get(wrapperFruListProductGroup.Product) : null;
                        fruListObj.ERP_Parent_Product__c = parentProductMaterialIdToPrdId.containsKey(wrapperFruList.Parent_Product) ? parentProductMaterialIdToPrdId.get(wrapperFruList.Parent_Product) : null;
                        uow.registerRelationship(fruListObj,FRU_List__c.Service_Bill_Of_Materials__c, serviceBOMObj);
                        fruListWork.registerUpsert(fruListObj);
						//delete existing fru list records.
                        //DCP-21788
                        fruListWork.registerDelete(oldLstFRUList);
                        
                    }
                }
            }
            /********************************************************** END ****************************/
        }

        // any business logic for incoming values goes in here
        businessRules(uow);

        uow.commitWork();
        ilib_LogEvent.pop();
        return (oneBom != null ? oneBom.Id : null);
    }

		/*
         * description - businessRules method
		 * return - void
         */ 
    public static void businessRules(ilib_SObjectUnitOfWork uow) {
    }

}

/*
SAMPLE INPUT RECIEVED

[{
    "Name": "FRU LIST, BASESPACE HT",
    "ERP_Service_BOM_Number": "20005785",
    "Active": true,
    "FRUList": [{
        "Parent_Product": "20001266",
        "Product_Group": [{
            "Product": "20028300"
        }, {
            "Product": "20022240"
        }]
    }, {
        "Parent_Product": "",
        "Product_Group": [{
            "Product": "20002063"
        }]
    }]
}]

*/