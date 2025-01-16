/***************************************************************************************************************************************
* NAME         : ProactiveDataReceiver
* DESCRIPTION  : Proactive Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 18-Nov-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Ritika/Sarath            03/29/2021          Added Case Number and Work Order Number in the response JSON
***************************************************************************************************************************************/
@RestResource(urlMapping = '/ProactiveSyncInterface/*')
global with sharing class ProactiveDataReceiver extends ilib_RestReceiver {
    private static final String LOG_TITLE = 'ProactiveDataReceiver'; // DCP-56514

    //Object API names
    public static final String INSTALLED_PRODUCT_API = 'SVMXC__Installed_Product__c';
    public static final String CASE_API = 'Case';
    public static final String WORK_ORDER_API = 'SVMXC__Service_Order__c';
    public static final String ACCOUNT_API = 'Account';
    public static final Integer REST_SUCCESS = 200;

    private static List <ProactiveDataReceiverWrapper.Proactive> wrapProactive;

    /**
    * @description HTTP Post method
    * @author 
    **/
    @HttpPost
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        ProactiveDataReceiver instantiated = new ProactiveDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name );
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SERVICE); // DCP-56514
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);
        ilib_LogEvent.info('JSON Input:\n' + strJsonInput); // DCP-56514

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            //if there is no body found, throw an error.
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapProactive);

            primaryRecordId = upsertIncomingValuesImpl();
            ilib_LogEvent.info('primaryRecordId :' + primaryRecordId); // DCP-56514
            erpCustomerId = getRelatedErpCustomerId('Case', 'Account', primaryRecordId);
            ilib_LogEvent.info('erpCustomerId :' + erpCustomerId); // DCP-56514
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
            ilib_LogEvent.info('strRestError :' + strRestError); // DCP-56514
        }

        Boolean isSuccess = String.isBlank(strRestError);
        ilib_LogEvent.info('isSuccess :' + isSuccess); // DCP-56514
        if (isSuccess) {
            //UtilsRest.handleCustomRestSuccess();
            ilib_LogEvent.info('Success'); // DCP-56514
            handleCustomRestSuccess(primaryRecordId);
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
          
        }
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        ilib_LogEvent.push(LOG_TITLE+'.deserializeInputs()'); // DCP-56514
        wrapProactive = (List < ProactiveDataReceiverWrapper.Proactive > ) System.JSON.deserialize(jsonInput, List < ProactiveDataReceiverWrapper.Proactive > .class);
        ilib_LogEvent.pop(); // DCP-56514
    }

    private static Id upsertIncomingValuesImpl()
    {
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValuesImpl()'); // DCP-56514
        Case oneCase;

        /* REGISTER HELPERS : MANDATORY STEP */
        // Register custom helpers: This is a mandatory step.
        //Case
        ilib_UpsertHelpers.CaseUnitofWorkHelper caseWork = new ilib_UpsertHelpers.CaseUnitofWorkHelper();
        //Work Order
        ilib_UpsertHelpers.WorkOrdersUnitofWorkHelper workOrderWork = new ilib_UpsertHelpers.WorkOrdersUnitofWorkHelper();
        /* END */

        /* STORE ALL LOOKUP VARIABLES HERE */

        //Installed Product Serial/Lot Number set.
        Set < String > installedProductSerialSet = new Set < String > ();
        //Installed Prod Serial with Installed Prod Id.
        Map < String, String > installedProdSerialToInstalledProdId = new Map < String, String > ();

        //Account ERP Customer Id set.
        Set < String > accountERPCustomerIdSet = new Set < String > ();
        //Account ERP Customer Id with Account Id.
        Map < String, String > accountERPCustomerIdToAccountId = new Map < String, String > ();

        //case number set.
        Set < String > caseNumberSet = new Set < String > ();
        //case number with case Id.
        Map < String, String > caseNumberSetToCaseId = new Map < String, String > ();

        //case number with service activity Work Order Id.
        Map < String, String > caseNumberToWorkOrder = new Map < String, String > ();
        
        //List to update Installed Product
        List<SVMXC__Installed_Product__c> lstInstalledProduct = new List<SVMXC__Installed_Product__c>();
        

        /* UNIT OF WORK : GENERIC STATEMENT */
        //unit of work: This is a mandatory step.
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                Case.SObjectType,
                SVMXC__Service_Order__c.SObjectType
            });
        /* / UNIT OF WORK : GENERIC STATEMENT */

        /* REGISTER OBJECTS : GENERIC STATEMENT */
        //register your objects: This is a mandatory step.
        uow.registerWork(caseWork);
        uow.registerWork(workOrderWork);
        /* / REGISTER OBJECTS : GENERIC STATEMENT */

        //if the recieved JSON body is not null, process it.
        if (wrapProactive != null)
        {
            ilib_LogEvent.info('wrapProactive :'+wrapProactive); // DCP-56514
            /** POPULATE LOOKUP VARIABLES **/
            //iterate over the header
            for (ProactiveDataReceiverWrapper.Proactive wrapperProactive: wrapProactive)
            {
                if (String.IsNotBlank(wrapperProactive.InstrumentSerial))
                    installedProductSerialSet.add(wrapperProactive.InstrumentSerial);
                    system.debug('installedProductSerialSet ' +installedProductSerialSet);
                    ilib_LogEvent.info('installedProductSerialSet '+installedProductSerialSet); // DCP-56514

                if (String.IsNotBlank(wrapperProactive.Account))
                    accountERPCustomerIdSet.add(wrapperProactive.Account);
                    ilib_LogEvent.info('accountERPCustomerIdSet '+accountERPCustomerIdSet); // DCP-56514

                if (String.IsNotBlank(wrapperProactive.AssociatedCase))
                    caseNumberSet.add(wrapperProactive.AssociatedCase);
                    ilib_LogEvent.info('caseNumberSet '+caseNumberSet); // DCP-56514
            }

            /********************************************************** Getting Salesforce Id of lookup variables ****************************/
            //Installed Product
            for (SVMXC__Installed_Product__c installedProds: new InstalledProductsSelector().selectInstallProductsForSerialLotNumber(installedProductSerialSet)) {
                installedProdSerialToInstalledProdId.put(installedProds.SVMXC__Serial_Lot_Number__c, installedProds.id);
            }
            
            system.debug('installedProdSerialToInstalledProdId ' +installedProdSerialToInstalledProdId);
            ilib_LogEvent.info('installedProdSerialToInstalledProdId '+installedProdSerialToInstalledProdId);// DCP-56514

            //Account By ERP Customer Id
            for (Account accounts: new AccountsSelector().selectAccountsForERPCustomerIds(accountERPCustomerIdSet)) {
                accountERPCustomerIdToAccountId.put(accounts.ERP_Customer_Id__c, accounts.id);
            }

            //Case by Case Number
            for (Case cases: new CasesSelector().selectCaseForCaseNumber(caseNumberSet)) {
                caseNumberSetToCaseId.put(cases.CaseNumber, cases.id);
            }

            //Service Activities Work Order by Case Number
            for (SVMXC__Service_Order__c workOrder: new WorkOrdersSelector().selectWorkOrderIdOnCaseNumber(caseNumberSetToCaseId.KeySet())) {
                caseNumberToWorkOrder.put(workOrder.SVMXC__Case__r.CaseNumber, workOrder.id);
            }

            /********************************************************** END ****************************/

            /********************************************************** INSTANTIATE SOBEJCTS AND ITS FIELDS ****************************/
            //iterate over header
            for (ProactiveDataReceiverWrapper.Proactive wrapperProactive: wrapProactive)
            {
                //if (String.isBlank(wrapperProactive.AssociatedCase) && wrapperProactive.Severity.equalsIgnoreCase('Critical') || wrapperProactive.Severity.equalsIgnoreCase('Alert')) {
                if (!wrapperProactive.Severity.equalsIgnoreCase('Info'))
                {
                    /********************* Case **********************/
                    Case caseObj = wrapperProactive.getCaseObject();
                    oneCase = caseObj;

                    //if Associated case is not blank, update the case
                    if (String.isNotBlank(wrapperProactive.AssociatedCase)) {
                        caseObj.Id = caseNumberSetToCaseId.get(wrapperProactive.AssociatedCase);
                    }

                    //Installed product lookup
                    caseObj.SVMXC__Component__c = installedProdSerialToInstalledProdId.containsKey(wrapperProactive.InstrumentSerial) ? installedProdSerialToInstalledProdId.get(wrapperProactive.InstrumentSerial) : null;

                    //Account lookup
                    caseObj.AccountId = accountERPCustomerIdToAccountId.containsKey(wrapperProactive.Account) ? accountERPCustomerIdToAccountId.get(wrapperProactive.Account) : null;

                    //Upsert operation
                    caseWork.registerUpsert(caseObj);

                    /********************* Work Order **********************/
                    //instantiate a new WO object.
                    SVMXC__Service_Order__c workOrderObj = new SVMXC__Service_Order__c();

                    workOrderObj = wrapperProactive.getWorkOrderObject();

                    //Update the WO associated with the case when associated case is not blank.
                    if (String.isNotBlank(wrapperProactive.AssociatedCase)) {
                        workOrderObj.Id = caseNumberToWorkOrder.get(wrapperProactive.AssociatedCase);
                    }

                    //Installed product lookup on WO - INC0335810
                    workOrderObj.SVMXC__Component__c = installedProdSerialToInstalledProdId.containsKey(wrapperProactive.InstrumentSerial) ? installedProdSerialToInstalledProdId.get(wrapperProactive.InstrumentSerial) : null;

                    //Relationship made only for new records.
                    if (String.isBlank(caseObj.Id) && String.isBlank(workOrderObj.Id)) {
                        uow.registerRelationship(workOrderObj, SVMXC__Service_Order__c.SVMXC__Case__c, caseObj);
                    }

                    //Upsert Work Order
                    workOrderWork.registerUpsert(workOrderObj);
                } 
                else {
                
                //get the installed product based on the serial number and update the notes field.
                String installedProdId = installedProdSerialToInstalledProdId.containsKey(wrapperProactive.InstrumentSerial) ? installedProdSerialToInstalledProdId.get(wrapperProactive.InstrumentSerial) : null;
                ilib_LogEvent.info('Installed Product Id based on the serial Number : installedProdId  '+installedProdId); // DCP-56514
                if(String.isNotBlank(installedProdId)){
                
                SVMXC__Installed_Product__c installedPro = new SVMXC__Installed_Product__c();
                installedPro.Id = installedProdId;
                installedPro.Instrument_Notes__c = (String.isNotBlank(wrapperProactive.Component) ? 'Component Information: ' + wrapperProactive.Component : '') + (String.isNotBlank(wrapperProactive.Detail) ? ' | Detail: ' + wrapperProactive.Detail : '') + (String.isNotBlank(wrapperProactive.Severity) ? ' | Severity: ' + wrapperProactive.Severity : '');
                lstInstalledProduct.add(installedPro);
                }
                
                }
            }

            /********************************************************** END ****************************/
        }
        
        if(lstInstalledProduct != null && !lstInstalledProduct.isEmpty())
        update lstInstalledProduct;
        
        // any business logic for incoming values goes in here
        businessRules(uow);

        uow.commitWork();
        ilib_LogEvent.pop(); //DCP-56514
        return (oneCase != null ? oneCase.Id : null);
    }

    /**
    * @description 
    * @author 
    * @param uow 
    **/
    public static void businessRules(ilib_SObjectUnitOfWork uow) {
    }

    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - This method gives the mentioned fields back to Proactive based on the URL parameters.
     *  @PARAM : 
     *  @RETURN : Installed Product,Case,Work Order and Account information
     **/
    @HttpGet
    global static List < Sobject > getInfo()
    {
        ilib_LogEvent.push(LOG_TITLE + '.getInfo()'); // DCP-56514
        //Returns the RestRequest object for our Apex REST method.
        RestRequest request = RestContext.request;
        //Returns the RestResponse for our Apex REST method.  
        RestResponse response = RestContext.response;
        ilib_LogEvent.info('RestRequest requestURI Contains SVMXC__Installed_Product__c :  '+request.requestURI.contains(INSTALLED_PRODUCT_API)); //DCP-56514
        //Response back for Installed Product Object
        if (request.requestURI.contains(INSTALLED_PRODUCT_API)) {
        

            // Sample Request := /services/apexrest/ProactiveSyncInterface/SVMXC__Installed_Product__c/M99999

            //Retrieve the parameter sent in the URL  
            String installedProdSerialNumber = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
            system.debug('installedProdSerialNumber ' + installedProdSerialNumber);
            ilib_LogEvent.info('installedProdSerialNumber :  '+installedProdSerialNumber); //DCP-56514
            
            //query the installedProduct on the basis of serial number sent and return the record  
            List < SVMXC__Installed_Product__c > installedProduct = [SELECT Id, Name, SVMXC__Serial_Lot_Number__c,Operation_Status__c, SVMXC__Product__r.Product_Category__c, SVMXC__Company__r.Name, SVMXC__Company__r.ERP_Customer_Id__c,  SVMXC__Status__c, Currently_Active_Service_Contract__r.SVMX_PS_External_ID__c,
                Currently_Active_Service_Contract__r.SVMXC__Start_Date__c, Currently_Active_Service_Contract__r.SVMXC__End_Date__c, Currently_Active_Service_Contract__r.Status__c, Currently_Active_Service_Contract__r.Labor_Included__c, Currently_Active_Service_Contract__r.Parts_Included__c,
                Currently_Active_Service_Contract__r.SVMXC__All_Products_Covered__c, Currently_Active_Service_Contract__r.Consumables_Included__c, Primary_Installation_FSE__r.Name
                FROM SVMXC__Installed_Product__c WHERE SVMXC__Serial_Lot_Number__c =: installedProdSerialNumber
            ];
            system.debug('installedProduct ' + installedProduct);
            ilib_LogEvent.info('installedProduct with :  '+installedProdSerialNumber+ ' SVMXC__Serial_Lot_Number__c  :  '+installedProduct); //DCP-56514
            ilib_LogEvent.pop(); //DCP-56514
            return installedProduct;
        }
        ilib_LogEvent.info('RestRequest requestURI Contains Case :  '+request.requestURI.contains(CASE_API)); //DCP-56514
        //Response back for Case Object
        if (request.requestURI.contains(CASE_API))
        {
            // Sample Request := /services/apexrest/ProactiveSyncInterface/Case/M99999/Initiated/2005-10-08T00:00:00Z/00002190

            //Pass the URI to wrapper class which gives back url paramters.
            requestURIWrapper requestWrap = new requestURIWrapper(request.requestURI, 'Case');
            //List<Case> cases = new CasesSelector().selectCasesRequestedByProactive(requestWrap.serialNumber,'Open','NA','NA');

            //Case dynamic query
            String soql = 'Select Id, CaseNumber, Description, CreatedDate,Status,Owner.Name,Suspected_Causes_Experiments_Done__c,(Select Id,Name From SVMXC__Service_Order__r) ' + ' FROM Case Where SVMXC__Component__r.SVMXC__Serial_Lot_Number__c = \'' + String.escapeSingleQuotes(requestWrap.serialNumber) + '\'';
            ilib_LogEvent.info('request status :  '+requestWrap.status); //DCP-56514
            //append status
            if (requestWrap.status != 'NA' && String.isNotBlank(requestWrap.status)) {
                soql += ' AND Status =\'' + String.escapeSingleQuotes(requestWrap.status) + '\'  ';
            }
            ilib_LogEvent.info('request createdDate :  '+requestWrap.createdDate); //DCP-56514
            //append createdDate
            if (requestWrap.createdDate != 'NA' && String.isNotBlank(requestWrap.createdDate)) {
                soql += ' AND CreatedDate >= ' + requestWrap.createdDate;
            }
            ilib_LogEvent.info('request svmxNumber :  '+requestWrap.svmxNumber); //DCP-56514
            //append caseNumber
            if (requestWrap.svmxNumber != 'NA' && String.isNotBlank(requestWrap.svmxNumber)) {
                soql += ' AND CaseNumber =\'' + String.escapeSingleQuotes(requestWrap.svmxNumber) + '\'  ';
            }

            system.debug('soql ' + soql);
            ilib_LogEvent.info('soql ' + soql); //DCP-56514
            //Query result
            system.debug('Database.query(soql) ' + Database.query(soql));
            ilib_LogEvent.info('Database.query(soql) ' + Database.query(soql)); //DCP-56514
            ilib_LogEvent.pop(); //DCP-56514
            return Database.query(soql);
        }
        ilib_LogEvent.info('RestRequest requestURI Contains SVMXC__Service_Order__c :  '+request.requestURI.contains(WORK_ORDER_API)); //DCP-56514
        //Response back for Work Order Object
        if (request.requestURI.contains(WORK_ORDER_API))
        {
            // Sample Request := /services/apexrest/ProactiveSyncInterface/SVMXC__Service_Order__c/M99999/Initiated/2005-10-08T00:00:00Z/WO-00001246

            //Pass the URI to wrapper class which gives back url paramters.
            requestURIWrapper requestWrap = new requestURIWrapper(request.requestURI, 'SVMXC__Service_Order__c');

            //WO dynamic query
            String soql = 'Select Id, Name, SVMX_PS_Subject__c, SVMXC__Problem_Description__c, CreatedDate, Owner.Name, SVMXC__Product__r.Name, Material_Number__c, SVMXC__Order_Status__c ' + ' FROM SVMXC__Service_Order__c Where SVMXC__Component__r.SVMXC__Serial_Lot_Number__c = \'' + String.escapeSingleQuotes(requestWrap.serialNumber) + '\'';
            ilib_LogEvent.info('request status :  '+requestWrap.status); //DCP-56514
            //append status    
            if (requestWrap.status != 'NA' && String.isNotBlank(requestWrap.status)) {
                soql += ' AND SVMXC__Order_Status__c =\'' + String.escapeSingleQuotes(requestWrap.status) + '\'  ';
            }
            ilib_LogEvent.info('request createdDate :  '+requestWrap.createdDate); //DCP-56514
            //append createdDate
            if (requestWrap.createdDate != 'NA' && String.isNotBlank(requestWrap.createdDate)) {
                soql += ' AND CreatedDate >= ' + requestWrap.createdDate;
            }
            ilib_LogEvent.info('request svmxNumber :  '+requestWrap.svmxNumber); //DCP-56514
            //append WO Number
            if (requestWrap.svmxNumber != 'NA' && String.isNotBlank(requestWrap.svmxNumber)) {
                soql += ' AND Name =\'' + String.escapeSingleQuotes(requestWrap.svmxNumber) + '\'  ';
            }
 
            system.debug('soql ' + soql);
            ilib_LogEvent.info('soql ' + soql); //DCP-56514
            //Query result
            system.debug('Database.query(soql) ' + Database.query(soql));
            ilib_LogEvent.info('Database.query(soql) ' + Database.query(soql)); //DCP-56514
            ilib_LogEvent.pop(); //DCP-56514
            return Database.query(soql);

        }
        ilib_LogEvent.info('RestRequest requestURI Contains Account :  '+request.requestURI.contains(ACCOUNT_API)); //DCP-56514
        if (request.requestURI.contains(ACCOUNT_API))
        {
            // Sample Request := /services/apexrest/ProactiveSyncInterface/Account/Test Account/6000020002

            //remove initial part of the url
            String shorterURI = request.requestURI.substringAfterLast(ACCOUNT_API + '/');

            //get Account ERP Customer Id from the URL
            String accountId = shorterURI.substringAfterLast('/');

            //get Account Name from the URL
            String accountName = shorterURI.substringBeforeLast('/');
            system.debug('accountName ' +accountName);
            ilib_LogEvent.info('requestURI accountId :  '+accountId); //DCP-56514
            ilib_LogEvent.info('requestURI accountName :  '+accountName); //DCP-56514

            //repace all automaticall added + by the url with a space.
            if(accountName.contains('+')){
            accountName = accountName.replaceAll('\\+', ' ');
            }
            if(accountName.contains('%20')){
             accountName = accountName.replaceAll('\\%20', ' ');
            system.debug('accountName replace ' +accountName);
            }

            //Account dynamic query
            String soql = ' Select Id, Name,Territory_Region__c,District__c,(Select User_Role__c,User__r.Name from  Account_Field_Support_Roles__r Where User_Role__c = \'' + String.escapeSingleQuotes('Primary Field Service Engineer') + '\' OR User_Role__c = \'' + String.escapeSingleQuotes('Primary Field Application Scientists') + '\'),(Select SVMXC__Serial_Lot_Number__c from R00N70000001hzZ0EAI) ' + ' FROM Account Where Name = \'' + String.escapeSingleQuotes(accountName) + '\'';

            //append account id if not null
            if (accountId != 'NA' && String.isNotBlank(accountId)) {
                soql += ' AND ERP_Customer_Id__c =\'' + String.escapeSingleQuotes(accountId) + '\'  ';
            }

            system.debug('soql ' + soql);
            ilib_LogEvent.info('soql ' + soql); //DCP-56514
            system.debug('Database.query(soql) ' + Database.query(soql));
            ilib_LogEvent.info('Database.query(soql) ' + Database.query(soql)); //DCP-56514
            ilib_LogEvent.pop(); //DCP-56514
            return Database.query(soql);
        }
        ilib_LogEvent.pop(); //DCP-56514
        return null;
    }


    //Wrapper class to read request URI and return back parameters.
	
   /*
    * @Description- Wrapper Object
    */ 	
    public class requestURIWrapper {

        public String serialNumber;
        public String status;
        public String createdDate;
        public String svmxNumber;
        public String requestURI;
        public String objectAPI;
        Public String afterObjectApi;
        Public String middlePart;

   /*
    * @Description- Wrapper Object
    */ 
        public requestURIWrapper(String requestURI, String objectAPI)
        {
            this.requestURI = requestURI;
            this.objectAPI = objectAPI;
            this.afterObjectApi = requestURI.substringAfter(objectAPI + '/');
            this.serialNumber = afterObjectApi.substringBefore('/');
            this.svmxNumber = afterObjectApi.substringAfterLast('/');
            this.middlePart = afterObjectApi.substringBetween(serialNumber + '/', '/' + svmxNumber);
            this.status = middlePart.substringBefore('/');
            this.createdDate = middlePart.substringAfter('/');
        }

    }

    /*
     *  @author      Ritika/Sarath
     *  @description Handle the success scenario for proactive data sync. Adds Case Number and WO Number in response JSON.
     *  @param       primaryRecordId - ID of the case created.
     *  @return      void
    */
    public static void handleCustomRestSuccess(Id primaryRecordId)
    {
        ilib_LogEvent.push(LOG_TITLE + '.handleCustomRestSuccess()'); // DCP-56514
        List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrderIdOnCase(new Set<Id>{primaryRecordId});
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Success');
        gen.writeStringField('ErrorDetail', '');
        if(lstWorkOrders != null && !lstWorkOrders.isEmpty())
        {
            gen.writeStringField('CaseNumber', lstWorkOrders[0].SVMXC__Case__r.CaseNumber);
            gen.writeStringField('WorkOrderNumber', lstWorkOrders[0].Name);
        }
        RestContext.response.statusCode = REST_SUCCESS;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
        ilib_LogEvent.push( ' Success scenario responseBody : '+RestContext.response.responseBody); // DCP-56514
        ilib_LogEvent.pop(); //DCP-56514
    }
}

/*
SAMPLE INPUT RECIEVED

[{
 "InstrumentSerial":"M99999",
 "Account":"6000020002",
 "Component":"Component Description Updated",
 "Summary":"Test Summary Update",
 "SWErrorCode":"",
 "Detail":"Test Detail Updated",
 "Severity":"Critical",
 "AssociatedCase":"00002190"
}]

*/