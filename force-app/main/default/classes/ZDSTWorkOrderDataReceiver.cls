/*
* @Author:  KD
* @Date:    31-May-2021
* @Description: DCP-38933 Auto Work Order creation/update from ZDST
* Modification Log:
* Test Coverage 75% :- TestCycleCounts,TestZDSTWorkOrderDataReceiver
* Test Coverage 90% :- TestCycleCounts,TestZDSTWorkOrderDataReceiver
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* KD                        3-June-2021        DCP-38933 : Initial Version
* Akshay Mohan              7-June-2021        DCP-46835: update opportunity to set flag for exclude from forecast
* Arya Gautam               9-June-2021        DCP-46661: Send Email Notification
* KD                        11-June-2021       Updated logic for Relocation Opps and WO type determination
* KD                        1-July-2021        DCP-48683: Update subject for serial instrument and relocation
* Arif,Dalali               16-sep-2022        CMSI-210 Instrumentation
* Sai						20-June-2023	   CMCM-41  Updated logic for Relocation boolean
* ------------------------------------------------------------------------------------
*/
@RestResource(urlMapping = '/ZDSTWorkOrderSyncInterface/*')
global with sharing class ZDSTWorkOrderDataReceiver extends ilib_RestReceiver{
    private static final String LOG_TITLE = 'ZDSTWorkOrderDataReceiver';
    private static String strProductIdentifier;
    private static ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWorkOrdersWrapper;
    private static SVMXC__Service_Order__c objWOSObject;
    //added 'Auto Create Billable Install Work Order for Purchased Installs' in setFieldServiceProductIdentifier by Dhairya Shah for CMCM - 6756
    private static Set<String> setFieldServiceProductIdentifier = new Set<String>{'Auto Create Field Service Relocation Work Order','Auto Create Field Service Preventative Maintenance Work Order','Auto Create Billable Install Work Order for Purchased Installs'};
    private static Set<String> setPrimaryFASOwnerIdentifier = new Set<String>{'Auto Create Service Support Professional Service FAS Work Order','Auto Create Service Support Clarity LIMS Work Order'};
    private static Boolean boolIsWOAutoCreateQualified = true;
    private static final String CODEPARAMETERNAME = 'Auto_WO_Creation_Failure_Email_DL';
    private static final String EMAILTEMPLATENAME = 'Work_Order_Send_Failure_Notification';
    private static Boolean isWOCreateScenario = false;
    public static Boolean boolByPassOwnerChangeOnPOUpdate = false;
    private static Integer intContactCount = 1;
    private static ZDSTWorkOrderDataReceiver instantiated;
    private static ilib_RestInterface.InterfaceDetails interfaceDetails;
    private static String strInterfaceLog;
    public static final String STRING_AUTO_GENERATED = 'Auto Generated';//DCP-47771
    public static final String STRING_WEB_MY_ILLUMINA_CS = 'Web - My Illumina - CS';//DCP-47771
    private static Id idUC;
    private static final String MY_ILLUMINA_IDENTIFIER = 'MY';
    private static final String RETURN_NULL = 'Returning Null';
    /*
    * @Author: KD
    * @Description : Method to accept POST Json from SNAP system
    */
    @HttpPost
    global static void upsertIncomingValues(){
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValues()');
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SERVICE);
        // get the (non-static context) details
        instantiated = new ZDSTWorkOrderDataReceiver();
        interfaceDetails = instantiated.interfaceDetails;

        String strRestError = null;
        Id primaryRecordId;
        String strJsonInput = (String.isNotBlank(RestContext.request.requestBody.toString()) ? RestContext.request.requestBody.toString() : null);
        ilib_LogEvent.info( 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);
        try
        {
            if (String.isBlank(strJsonInput)){
                ApexExceptions.emit(LOG_TITLE, 'Input JSON is missing',ilib_LogEvent.SERVICE);
                throwException('Input JSON is missing');
            }

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, objWorkOrdersWrapper);

            primaryRecordId = upsertIncomingValuesImpl();
            ilib_LogEvent.info( 'primaryRecordId :' + primaryRecordId);
        }
        
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        Boolean isSuccess = String.isBlank(strRestError);
        strInterfaceLog = ilib_LogInterface.finalizeLog(
            log,
            (!isSuccess ? ilib_LogInterface.RESULT_FAIL : boolIsWOAutoCreateQualified ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_REJECTED),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        ilib_LogEvent.info( 'isSuccess :' + isSuccess);

        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }
        else
        {
            
            if(isWOCreateScenario){
                sendFailureEmail(objWorkOrdersWrapper.ERP_Order_Number);
            }
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            ApexExceptions.emit(LOG_TITLE, strInterfaceLog,strRestError,ilib_logEvent.SERVICE);
        }
        ilib_LogEvent.pop();
    }
    /*
    * @Author: KD
    * @Description : Method to deserialize JSON
    */
    private static void deserializeInputs(String jsonInput){
        ilib_LogEvent.push(LOG_TITLE + '.deserializeInputs()');
        
        objWorkOrdersWrapper = (ZDSTWorkOrderDataReceiverWrapper.WorkOrders) System.JSON.deserialize(jsonInput, ZDSTWorkOrderDataReceiverWrapper.WorkOrders.class);
        ilib_LogEvent.info('WOWrapper::::'+objWorkOrdersWrapper);
    }
    /*
    * @Author: KD
    * @Description : Method to process Sobject and create Work Order
    */
    private static Id upsertIncomingValuesImpl(){
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValuesImpl()');
        if(String.isNotBlank(objWorkOrdersWrapper.WorkOrderNumber)){
            // Update existing WO to populate PO number // DCP-39784
            updatePONumber();
        }
        else{
            ilib_LogEvent.info('Create WO scenerio');
            isWOCreateScenario = true;
            objWOSObject = objWorkOrdersWrapper.getSObject();
            List<Product2> lstProduct = new List<Product2>();
            //DCP-46835: Start- Make objOpps local variable
            Id idOpp = updateContactOnWO();
            ilib_LogEvent.info('idOpp: '+idOpp);
            lstProduct = new ProductsSelector().fetchProductId(new Set<String>{objWorkOrdersWrapper.SVMXC_Product});
                if(lstProduct.isEmpty()){
                    throwException('Product '+objWorkOrdersWrapper.SVMXC_Product+' is invalid');
            }
            //DCP-46835: End- Make objOpps local variable
            if(String.isNotBlank(objWorkOrdersWrapper.SVMXC_Component)){
                createWOFromIPDetails(lstProduct);
            }
            else{
                // When no Serial is found
                createWOFromProduct(lstProduct);
            }
            if(!boolIsWOAutoCreateQualified){
                ilib_LogEvent.info(RETURN_NULL);
                ilib_LogEvent.pop();
                return null;
            }
            objWOSObject.Billing_Type_Set_Manually__c = true;
            objWOSObject.RecordTypeId = getRecordTypeId(strProductIdentifier);
            objWOSObject.SVMXC__Order_Type__c = getOrderType(strProductIdentifier);
            objWOSObject.SVMXC__Group_Member__c = getFieldSupport(objWOSObject.OwnerId);
            objWOSObject.ZDST_WO_Unique_Identifier__c = objWorkOrdersWrapper.ERP_Order_Number+'_'+objWorkOrdersWrapper.ERP_Order_Line_Number;
            objWOSObject.Standalone_Work_Order_Origin__c = String.isNotBlank(objWorkOrdersWrapper.SVMXC_Order_Type) && objWorkOrdersWrapper.SVMXC_Order_Type.contains(MY_ILLUMINA_IDENTIFIER) ? STRING_WEB_MY_ILLUMINA_CS : STRING_AUTO_GENERATED; // DCP-28889
            if(idUC != null && strProductIdentifier == Label.Product_WO_Identifier_CRLO){
                objWOSObject.Relocated_Account__c = idUC;
            }
            ilib_LogEvent.info('Work Order to be inserted ->'+objWOSObject);
            boolByPassOwnerChangeOnPOUpdate = true;
            insert objWOSObject;
            //DCP-46835: Start- Update opportunity if applicable
            if(idOpp!=null){
                ilib_LogEvent.info('Updating opp: '+idOpp);
                EventBus.publish(new Admin_Operation__e(Related_Record__c=idOpp,Name__c='UpdateOppExcludeForecast'));
            }
            //DCP-46835: End- Update opportunity if applicable
            ilib_LogEvent.info('objWOSObject.id :' +objWOSObject.id);
            ilib_LogEvent.pop();
            return objWOSObject.id;
        }
        ilib_LogEvent.info(RETURN_NULL);
        ilib_LogEvent.pop();
        return null;    
    }
    /*
    * @Author: KD
    * @Description : Method to get RT id based on Product Identifier
    */
    private static id getRecordTypeId(String strAutoCreateBillableWO){
        ilib_LogEvent.push(LOG_TITLE + '.getRecordTypeId()');
        ilib_LogEvent.info('strAutoCreateBillableWO :' +strAutoCreateBillableWO);
        if(setFieldServiceProductIdentifier.contains(strAutoCreateBillableWO)){
            return Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(Label.Field_Service).getRecordTypeId();
        }
        else{
            return Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(Label.Service_Support).getRecordTypeId();
        }
    }
    /*
    * @Author: KD
    * @Description : Method to get Owner id based on Product Identifier and Opportunity
    */
    private static id getWorkOrderOwner(String strAutoCreateBillableWO,String strERPNumber){
        ilib_LogEvent.push(LOG_TITLE + '.getWorkOrderOwner()');
        ilib_LogEvent.info('strERPNumber :' +strERPNumber);
        if(setPrimaryFASOwnerIdentifier.contains(strAutoCreateBillableWO)){
            List<Account_to_Field_Support__c> lstAFS = new AccountToFieldSupportSelector().selectAccountToFieldSupportByAccountERPAndRole(new Set<String>{strERPNumber},new Set<String>{Label.Field_Support_User_Role_Primary_FAS});
            if(lstAFS.isEmpty()){
                throwException('No Owner determined based on Account');
            }
            ilib_LogEvent.info('lstAFS[0].Salesforce_User_ID__c :' +lstAFS[0].Salesforce_User_ID__c);
            ilib_LogEvent.pop();
            return lstAFS[0].Salesforce_User_ID__c;
        } else {
            if(strAutoCreateBillableWO == Label.Product_WO_Identifier_CPBI){
                //Assign to Partner Primary FSE for Billable Install
                List<Account_to_Field_Support__c> lstAFSFSE = new AccountToFieldSupportSelector().selectAccountToFieldSupportByAccountERPAndRole(new Set<String>{strERPNumber},new Set<String>{Label.Field_Support_User_Role_Partner_Primary_FSE});
                if(lstAFSFSE!=null && !lstAFSFSE.isEmpty()){
                    return lstAFSFSE[0].Salesforce_User_ID__c;
                }
            }
            //Assign to Primary FSE
            List<Account_to_Field_Support__c> lstAFS = new AccountToFieldSupportSelector().selectAccountToFieldSupportByAccountERPAndRole(new Set<String>{strERPNumber},new Set<String>{Label.Field_Support_User_Role_Primary_FSE});
            if(lstAFS.isEmpty()){
                throwException('No Owner determined based on Account');
            }
            return lstAFS[0].Salesforce_User_ID__c;
        }
    }
    /*
    * @Author: KD
    * @Description : Method to get Field Support based on Owner Id
    */
    private static id getFieldSupport(Id idOwnerId){
        ilib_LogEvent.push(LOG_TITLE + '.getFieldSupport()');
         ilib_LogEvent.info('idOwnerId :' +idOwnerId);
        List<SVMXC__Service_Group_Members__c> lstFieldSupport = new TechniciansSelector().selectTechniciansMatchingUsers(new Set<Id>{idOwnerId});
        if(lstFieldSupport.isEmpty()){
            throwException('No Field Support found for Owner');
        }
        ilib_LogEvent.info('lstFieldSupport[0].id :' +lstFieldSupport[0].id);
        ilib_LogEvent.pop();
        return lstFieldSupport[0].id;
    }
    /*
    * @Author: KD
    * @Description : Method to get order type
    */
    private static String getOrderType(String strAutoCreateBillableWO){
        ilib_LogEvent.push(LOG_TITLE + '.getOrderType()');
        switch on strAutoCreateBillableWO{
            when 'Auto Create Field Service Relocation Work Order' {
                ilib_LogEvent.info('Label.WorkOrderTypeRelocation: ' +Label.WorkOrderTypeRelocation);
                ilib_LogEvent.pop();
                return Label.WorkOrderTypeRelocation;
            }
            when 'Auto Create Field Service Preventative Maintenance Work Order' {
                ilib_LogEvent.info('Label.WorkOrderTypePreventativeMaintenance: ' +Label.WorkOrderTypePreventativeMaintenance);
                ilib_LogEvent.pop();
                return Label.WorkOrderTypePreventativeMaintenance;
            }
            when 'Auto Create Service Support Professional Service FSE Work Order','Auto Create Service Support Professional Service FAS Work Order' {
                ilib_LogEvent.info('Label.WorkOrderTypeProfessionalServices: ' +Label.WorkOrderTypeProfessionalServices);
                ilib_LogEvent.pop();
                return Label.WorkOrderTypeProfessionalServices;
            }
            when 'Auto Create Service Support Clarity LIMS Work Order' {
                ilib_LogEvent.info('Label.WorkOrderTypeClarityLIMS: ' +Label.WorkOrderTypeClarityLIMS);
                ilib_LogEvent.pop();
                return Label.WorkOrderTypeClarityLIMS;
            }
            // added by Dhairya Shah for CMCM - 6756
            when 'Auto Create Billable Install Work Order for Purchased Installs' {
                ilib_LogEvent.info('Label.WorkOrderTypeBillableInstall: ' +Label.WorkOrderTypeBillableInstall);
                ilib_LogEvent.pop();
                return Label.WorkOrderTypeBillableInstall;
            }
        }
        ilib_LogEvent.info(RETURN_NULL);
        ilib_LogEvent.pop();
        return null;
    }
    /*
    * @Author: KD
    * @Description : Method to throw Exception
    */
    public static void throwException(String strErrorMsg){
        ilib_LogEvent.push(LOG_TITLE + '.throwException()');
        ilib_LogEvent.info('strErrorMsg :' +strErrorMsg);
        ilib_LogEvent.pop();
        ApexExceptions.emit(LOG_TITLE, strErrorMsg, ilib_LogEvent.SERVICE );
        throw new UtilsRest.InterfaceException(strErrorMsg);
    }
    /*
    * @Author: KD
    * @Description : Method to update PO number
    */
    private static Id updatePONumber(){
        ilib_LogEvent.push(LOG_TITLE + '.updatePONumber()');
        ilib_LogEvent.info('PO Number found');
        List<SVMXC__Service_Order__c> lstWorkOrder = new WorkOrdersSelector().selectWOByName(objWorkOrdersWrapper.WorkOrderNumber);
        if(lstWorkOrder.isEmpty()){
            throwException('Work Order number '+objWorkOrdersWrapper.WorkOrderNumber + ' doesn\'t exists');
        }
        SVMXC__Service_Order__c objWorkOrder = lstWorkOrder[0];
        if(String.isBlank(objWorkOrdersWrapper.TimeStamp)){
            throwException('TimeStamp Missing');
        }

        if(objWorkOrder.SVMXC__Order_Type__c != Label.WorkOrderTypeBillableInstall){
            if(String.isNotBlank(objWorkOrder.ZDST_WO_Time_Stamp__c) && Long.valueOf(objWorkOrder.ZDST_WO_Time_Stamp__c) > Long.valueOf(objWorkOrdersWrapper.TimeStamp)){
                throwException('Outdated Payload recieved');
            }
            Id idFieldServiceRecordType = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(Label.Field_Service).getRecordTypeId();
            if(objWorkOrder.RecordTypeId != idFieldServiceRecordType 
                || objWorkOrder.PO_Number__c != objWorkOrdersWrapper.PO_Number 
                    || objWorkOrder.SVMXC__Billing_Type__c != Label.WorkOrderBillingTypeBillable 
                        || objWorkOrder.SVMXC__Order_Type__c != Label.WorkOrderTypeServiceActivities){
                objWorkOrder.ZDST_WO_Time_Stamp__c = String.valueOf(objWorkOrdersWrapper.TimeStamp);
                objWorkOrder.PO_Number__c = objWorkOrdersWrapper.PO_Number;
                objWorkOrder =  updatePONumber1(objWorkOrder,idFieldServiceRecordType);// added by Dhairya Shah for CMCM 6756(this is a code scan fix )
            }
        }
        ilib_LogEvent.info('objWorkOrder.id :' +objWorkOrder.id);
        ilib_LogEvent.pop();
        return objWorkOrder.id;
    }
/*
* @Author: Dhairya Shah
* @Description : Method to update PO number 
*/
    private static SVMXC__Service_Order__c updatePONumber1(SVMXC__Service_Order__c objWorkOrder,Id idFieldServiceRecordType){

        if(String.isNotBlank(objWorkOrder.Opportunity__c) && objWorkOrder.Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix)){
            if(String.isBlank(objWorkOrder.SVMXC__Billing_Type__c)){
                objWorkOrder.Billing_Type_Set_Manually__c = true;
                objWorkOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable;
            }
            objWorkOrder.RecordTypeId = idFieldServiceRecordType;
            objWorkOrder.SVMXC__Order_Status__c	= Label.WorkOrderStatusInitiated;
            objWorkOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeServiceActivities;
            objWorkOrder.ZDST_WO_Unique_Identifier__c = objWorkOrdersWrapper.ERP_Order_Number+'_'+ objWorkOrdersWrapper.ERP_Order_Line_Number;
            objWorkOrder.ERP_Order_Number__c = objWorkOrdersWrapper.ERP_Order_Number;
            if(String.isNotBlank(objWorkOrder.Opportunity__c) && !objWorkOrder.Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix)){
                objWorkOrder.ERP_Order_Line_Number__c = objWorkOrdersWrapper.ERP_Order_Line_Number; //Do not populate if Break Fix
            }
            ilib_LogEvent.info('Work Order to be updated ->'+objWorkOrder);
            update objWorkOrder;
        }
        return objWorkOrder;
    }
    /*
    * @Author: KD
    * @Description : Method to add contact
    */
    private static Id updateContactOnWO(){
        ilib_LogEvent.push(LOG_TITLE + '.updateContactOnWO()');
        if(String.isNotBlank(objWorkOrdersWrapper.Opportunity)){
            List<Opportunity> lstOpp = new OpportunitySelector().selectOpportunities(new Set<Id>{objWorkOrdersWrapper.Opportunity});
            if(lstOpp.isEmpty()){
                throwException('Opportunity Id is invalid');
            }
            //DCP-46835: Start- Make objOpps local variable
            Opportunity objOpps = lstOpp[0];
            //DCP-46835: End- Make objOpps local variable
            objWOSObject.SVMXC__Contact__c = objOpps.Primary_Contact__c;
            objWOSObject.SVMX_PS_Contact_Email__c = objOpps.Primary_Contact__r.Email;
            objWOSObject.SVMX_PS_Contact_Phone__c = objOpps.Primary_Contact__r.Phone;
            idUC = objOpps.Ultimate_Consignee__c;
            if(!objOpps.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix)){
                objWOSObject.ERP_Order_Line_Number__c = objWorkOrdersWrapper.ERP_Order_Line_Number;
            }
            
 			//Updated the below boolean assignment for CMCM-41 START
            // Boolean isRelocation = objOpps.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation);
            List<Product2> lstProduct = new List<Product2>();
            lstProduct = new ProductsSelector().fetchProductId(new Set<String>{objWorkOrdersWrapper.SVMXC_Product});
            Product2 objJSONProduct = lstProduct[0];
            Boolean isRelocation = objOpps.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation) &&
                (objJSONProduct.Auto_Create_Billable_Work_Order__c == 'Auto Create Field Service Relocation Work Order' || String.isBlank(objJSONProduct.Auto_Create_Billable_Work_Order__c) );           
            //Updated the below boolean assignment for CMCM-41 END          
            
              if(isRelocation){
                strProductIdentifier = Label.Product_WO_Identifier_CRLO;
            }
            //DCP-46835: Start- return opportunity only in case of update criteria met
            if(!objOpps.Exclude_from_Forecast__c && isRelocation ||
                    objOpps.Product_Interest__c.contains(Label.OpportunityProductInterestOtherServices)){
                ilib_LogEvent.info('Setting opportunity Exclude_from_Forecast__c flag');
                ilib_LogEvent.pop();
                return objOpps.Id;
            }
            //DCP-46835: End- return opportunity only in case of update criteria met
        }
        else if(String.isNotBlank(objWorkOrdersWrapper.Contact_Email)){
            // Else for Contact populate
            List<Contact> lstContacts = new ContactsSelector().selectContactsByEmail(new Set<String>{objWorkOrdersWrapper.Contact_Email});
            if(lstContacts.size() == intContactCount){
                Contact objContact = lstContacts[0];
                objWOSObject.SVMXC__Contact__c = objContact.id;
                objWOSObject.SVMX_PS_Contact_Email__c = objContact.Email;
                objWOSObject.SVMX_PS_Contact_Phone__c = objContact.Phone;
            }
        }
        //DCP-46835: Start- return null for non opp scenarios
        ilib_LogEvent.info(RETURN_NULL);
        ilib_LogEvent.pop();
        
        return null;
        //DCP-46835: End- return null for non opp scenarios
    }
    /*
    * @Author: KD
    * @Description : Method to Create WO with IP
    */
    public static Id createWOFromIPDetails(List<Product2> lstProduct){
        // Fetch Account, location, Product details from IP
        ilib_LogEvent.push(LOG_TITLE + '.createWOFromIPDetails()');
        ilib_LogEvent.info('Inside IP found');
        List<SVMXC__Installed_Product__c> lstIP = new InstalledProductsSelector().selectInstallProductsForEquipmentIds(new Set<String>{objWorkOrdersWrapper.SVMXC_Component});
        if(lstIP.isEmpty()){
            throwException('Equipment '+objWorkOrdersWrapper.SVMXC_Component+' is invalid');
        }
        Product2 objJSONProduct = lstProduct[0];
        SVMXC__Installed_Product__c objIP = lstIP[0];
        strProductIdentifier = String.isBlank(strProductIdentifier) ? objJSONProduct.Auto_Create_Billable_Work_Order__c : strProductIdentifier;
        if(String.isBlank(strProductIdentifier)){
            ilib_LogEvent.info('No Product Identifier found for WO Creation.');
            boolIsWOAutoCreateQualified = false;
            ilib_LogEvent.info(RETURN_NULL);
            ilib_LogEvent.pop();
            return null;
        }
        objWOSObject.SVMXC__Component__c = objIP.id;
        objWOSObject.SVMXC__Company__c = objIP.SVMXC__Company__c;
        objWOSObject.SVMXC__Product__c = objIP.SVMXC__Product__c;
        objWOSObject.OwnerId = getWorkOrderOwner(strProductIdentifier,objIP.SVMXC__Company__r.ERP_Customer_Id__c);
        objWOSObject.SVMXC__Site__c = objIP.SVMXC__Site__c;
        String strProductNameForSubject;
        //DCP-48683 : SSubject updatte for WO with Serial number
        // added one OR condition below by Dhairya Shah for CMCM - 6756(strProductIdentifier == Label.Product_WO_Identifier_CPBI)
        if(strProductIdentifier == Label.Product_WO_Identifier_CPSS || strProductIdentifier == Label.Product_WO_Identifier_CPSE || strProductIdentifier == Label.Product_WO_Identifier_CPMO || strProductIdentifier == Label.Product_WO_Identifier_CPBI){
            strProductNameForSubject = objJSONProduct.Name;
        }
        else if(strProductIdentifier == Label.Product_WO_Identifier_CRLO){
            strProductNameForSubject = 'Instrument Relocation';
        }
        else{
            strProductNameForSubject = objIP.SVMXC__Product__r.Name;
        }
        objWOSObject.SVMX_PS_Subject__c = 'Billable '+strProductNameForSubject+' '+ objWorkOrdersWrapper.ERP_Order_Number;
        ilib_LogEvent.pop();
        return objWOSObject.id;
    }
    /*
    * @Author: KD
    * @Description : Method to Create WO with product
    */
    public static Id createWOFromProduct(List<Product2> lstProduct){
        ilib_LogEvent.push(LOG_TITLE + '.createWOFromProduct()');
        ilib_LogEvent.info('lstProduct :' +lstProduct);
        ilib_LogEvent.info('Inside No IP');
        Product2 objJSONProduct = lstProduct[0];
        strProductIdentifier = String.isBlank(strProductIdentifier) ? objJSONProduct.Auto_Create_Billable_Work_Order__c : strProductIdentifier;
        if(String.isBlank(strProductIdentifier)){
            ilib_LogEvent.info('No Product Identifier found for WO Creation.');
            boolIsWOAutoCreateQualified = false;
            ilib_LogEvent.info(RETURN_NULL);
            ilib_LogEvent.pop();
           
            return null;
        }
        Account objCompanyRef = new Account(ERP_Customer_Id__c = objWorkOrdersWrapper.SVMXC_Company);
        objWOSObject.SVMXC__Company__r = objCompanyRef;
        objWOSObject.SVMXC__Product__c = objJSONProduct.id;
        objWOSObject.OwnerId = getWorkOrderOwner(strProductIdentifier,objWorkOrdersWrapper.SVMXC_Company);
        objWOSObject.SVMXC__Site__r = new SVMXC__Site__c(ERP_Customer_ID__c = objWorkOrdersWrapper.SVMXC_Site);
        objWOSObject.SVMX_PS_Subject__c = 'Billable '+objJSONProduct.Name+' '+ objWorkOrdersWrapper.ERP_Order_Number;
        ilib_LogEvent.pop();
        return objWOSObject.id;
    }

    /*
    * @Author: Gautam
    * @Description : Method to send email for auto creation wo failure
    */
    public static void sendFailureEmail(String strZDSTOrderNumber){

        // Write logic to send mail here.
        ilib_LogEvent.push(LOG_TITLE + '.sendFailureEmail');
        ilib_LogEvent.info('strZDSTOrderNumber :' +strZDSTOrderNumber);
        List<Code_Parameter__mdt> objCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> strEmailId = new List<String>();
        if(!Test.isRunningTest()){
            strEmailId.addAll(objCodeParam[0].Value__c.split(';'));
        }
        else{
            strEmailId.add('sfdc_service_account@illumina.com');
        }
        
        List<EmailTemplate> lstEmailTemp = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAILTEMPLATENAME});
        try{
            if(!lstEmailTemp.isEmpty()){
                String htmlBody = lstEmailTemp[0].HtmlValue.replace('{!SVMXC__Service_Order__c.Name}', strZDSTOrderNumber);
                ilib_LogEvent.info('htmlBody :' +htmlBody);
                email.setHtmlBody(htmlBody);
                email.setToAddresses(strEmailId);
                email.setSubject(lstEmailTemp[0].Subject);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
		} 
        catch (Exception e) {
            ilib_LogEvent.info('Email Sending failed with error: ' + e.getMessage());
        
		}
        ilib_LogEvent.pop();
    }
}