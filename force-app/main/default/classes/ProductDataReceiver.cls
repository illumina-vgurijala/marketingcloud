/**
 * @author Sravan Panchangam
 * @date  11-09-2018
 * @description    US-11857-Material Synchronization 
 * 
 * Test class for 75% coverage: TestProductDataReceiver
 * Test class for 90% coverage: TestProductDataReceiver
 * 
 * Modification Log:
 * --------------------------------------------------------
 * Sravan Panchangam        11-09-2018   : initial version 
 * Aman Tyagi               31/03/2022   : Codescan fixes
 * -----------------------------------------------------------
 */
@RestResource(urlMapping='/ProductMaterialSyncInterface/')
global with sharing class ProductDataReceiver extends ilib_RestReceiver {
    
    private static List<ProductWrapper.Product> lstProductWrapper;

    @Httppost

    /*
    * @Author: Sravan Panchangam
    * @Description : this method has logic for upsert the incoming values
    * @param : null
    * @return: void 
    */ 
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        ProductDataReceiver instantiated = new ProductDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;
        Id primaryRecordId;
        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        ilib_LogEvent.message('JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, lstProductWrapper);

            primaryRecordId = upsertIncomingValuesImpl();
        }
        
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
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
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        lstProductWrapper = (List<ProductWrapper.Product>) System.JSON.deserialize(jsonInput, List<ProductWrapper.Product>.class);
        ilib_LogEvent.message('productWrapper::::'+lstProductWrapper);
    }

    private static Id upsertIncomingValuesImpl()
    {
        Product2 oneProduct;  // assuming one product coming in

        Map<String, List<Product2>> managerToProducts = new Map<String, List<Product2>>();

        // prepare unit of work
        ilib_SObjectUnitOfWork objUnitOfWork = new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> {Product2.SObjectType, Product_Sales_Area__c.SObjectType, Product_Localization__c.SObjectType});

        ilib_UpsertHelpers.ProductUnitOfWorkHelper objProductWork = new ilib_UpsertHelpers.ProductUnitOfWorkHelper();
        ilib_UpsertHelpers.ProductSalesAreaUnitOfWorkHelper objProductSalesAreaWork = new ilib_UpsertHelpers.ProductSalesAreaUnitOfWorkHelper();
        ilib_UpsertHelpers.ProductLocalizationUnitOfWorkHelper objProductLocalizationWork = new ilib_UpsertHelpers.ProductLocalizationUnitOfWorkHelper();
        objUnitOfWork.registerWork(objProductWork);
        objUnitOfWork.registerWork(objProductSalesAreaWork);
        objUnitOfWork.registerWork(objProductLocalizationWork);

        for (ProductWrapper.Product objProductWrapper : lstProductWrapper)
        {
            Product2 productSObject = objProductWrapper.getSObject();
            oneProduct = productSObject;

            // prepare business rules data
            mapManagerToProducts(managerToProducts, objProductWrapper, productSObject);

            objProductWork.registerUpsert(productSObject);

            // prepare sales area work
            for (ProductWrapper.ProductSalesArea productSalesArea : objProductWrapper.productSalesArea)
            {
                Product_Sales_Area__c productSalesAreaSObject = productSalesArea.getSObject();
                objUnitOfWork.registerRelationship(productSalesAreaSObject, Product_Sales_Area__c.Product__c, productSObject);
                objProductSalesAreaWork.registerUpsert(productSalesAreaSObject);
            }

            // prepare localization work
            if (objProductWrapper.productLocalization != null)
            {
                for (ProductWrapper.ProductLocalization localization : objProductWrapper.productLocalization)
                {
                    Product_Localization__c objLocalization = localization.getSObject();
                    objUnitOfWork.registerRelationship(objLocalization, Product_Localization__c.Product__c, productSObject);
                    objProductLocalizationWork.registerUpsert(objLocalization);
                }
            }
        }

        businessRules(objUnitOfWork, managerToProducts);

        objUnitOfWork.commitWork();

        return (oneProduct != null ? oneProduct.Id : null);
    }

    /*
    * @Author: Sravan Panchangam
    * @Description : 
    * @param : ilib_SObjectUnitOfWork uow, Map<String, List<Product2>> managerToProducts
    * @return: void 
    */
    public static void businessRules(ilib_SObjectUnitOfWork uow, Map<String, List<Product2>> managerToProducts)
    {
        linkProductsToProductManagers(uow, managerToProducts);
    }


    private static void mapManagerToProducts(Map<String, List<Product2>> managerToProducts, ProductWrapper.Product objProductWrapper, Product2 productSObject)
    {
        if (managerToProducts.containsKey(objProductWrapper.Product_Manager)) {
            managerToProducts.get(objProductWrapper.Product_Manager).add(productSObject);
        } else {
            if (objProductWrapper.Product_Manager != null) {
                managerToProducts.put(objProductWrapper.Product_Manager, new List<Product2> {productSObject});
            }
        }
    }

    private static void linkProductsToProductManagers(ilib_SObjectUnitOfWork uow, Map<String, List<Product2>> managerToProducts)
    {
        // manager from managerToProducts = User.EmployeeNumber, query the users
        List<User> activeUsers = new UsersSelector().getUsersByEmpId(managerToProducts.keySet());
        ilib_LogEvent.message('Active Users:' + activeUsers);

        // Iterating over the activeuser to fetch the list of products and there by assigning the Id from user to Product Manager
        for (User u : activeUsers)
        {
            if (u.EmployeeNumber == null) continue;

            for (Product2 prd : managerToProducts.get(u.EmployeeNumber))
            {
                prd.Product_Manager__c = u.Id;
            }
            ilib_LogEvent.message('ProductManager:' + u.EmployeeNumber + 'Values:' + managerToProducts.get(u.EmployeeNumber));
        }
    }

}