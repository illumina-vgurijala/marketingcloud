/*
 * @Author:Vaibhav
 * @Date:11 Mar 2021
 * @Description: DCP-42718 - LMS-DCP Course Completion Data Sync
 * @Test Class for 75% covergae : TestLMSCertificationDataReceiver
 * @Test Class for 90% covergae : TestLMSCertificationDataReceiver
 * * Modification Log:
 * -------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *          Sagar Madkaikar                11 Aug 2021        CMCP-21 Populated more fields from LMS Request 
                                                                into Product Serviced records.
            Sagar Madkaikar                 1 Sep 2021        CMCP-219: Added conditions to check if Product Serviced record is already created for FS user.
                                                                Ans perform Insert vs Update accordingly.
 *          Anshaj Sinha                   21-Sep-2022        Cmsi-364 Instrumentation of class according to framework guidelines
 * -------------------------------------------------------------------------------------------------------------
 */
 
@RestResource(urlMapping = '/LMSCertificationSyncInterface/*')
global with sharing class LMSCertificationDataReceiver extends ilib_RestReceiver {

    private static LMSCertificationDataReceiverWrapper lstLMSCertificationWrapper;
    private static Id primaryRecordId;
    private static final String STRING_INTERNAL_EMPLOYEE = 'Internal';
    private static final String STRING_EXTERNAL_EMPLOYEE = 'External';
    private static final String CERT_STATUS_ACQUIRED = 'Acquired';
    //CMCP-219:Set will have Ids of FS users whose Certifications should be updated and not created.
    private static Set < String > setUpdatedCertification = new Set < String > ();
    private static Map < Id, SVMXC__Service_Group_Product__c > productServicedProductIdToProductServicedMap = new Map < Id, SVMXC__Service_Group_Product__c > ();
    private static Final String LOG_TITLE = 'LMSCertificationDataReceiver';
    
    /*
    * @Description: Upsert incoming values from incoming json.
    */ 
    @Httppost
    global static string upsertIncomingValues() {
        ilib_LogEvent.settitle(LOG_TITLE , ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValues()');
        // get the (non-static context) details
        LMSCertificationDataReceiver instantiated = new LMSCertificationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        LMSCertificationDataErrorResponse sfdcToLMSResponse = new LMSCertificationDataErrorResponse();
        LMSCertificationDataErrorResponse.ErrorDetail sfdcToLMSResponseErrorDetail = new LMSCertificationDataErrorResponse.ErrorDetail();
        String strRestError = null;
        String customErrorMessageForLMS;
        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        ilib_LogEvent.info('Incoming JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, lstLMSCertificationWrapper);

            customErrorMessageForLMS = upsertIncomingValuesImpl();
            ilib_LogEvent.info('customErrorMessageForLMS : ' + customErrorMessageForLMS);

            if (String.isNotBlank(customErrorMessageForLMS) && customErrorMessageForLMS.contains('Field Support')) {
                sfdcToLMSResponse.result = 'Error';
                sfdcToLMSResponseErrorDetail.code = 'SER_CERT_002';
                sfdcToLMSResponseErrorDetail.message = customErrorMessageForLMS;
                sfdcToLMSResponse.errorDetail = sfdcToLMSResponseErrorDetail;
            } else if (String.isNotBlank(customErrorMessageForLMS) && !customErrorMessageForLMS.contains('Field Support')) {
                sfdcToLMSResponse.result = 'Error';
                sfdcToLMSResponseErrorDetail.code = 'SER_CERT_001';
                sfdcToLMSResponseErrorDetail.message = customErrorMessageForLMS;
                sfdcToLMSResponse.errorDetail = sfdcToLMSResponseErrorDetail;
            } else if (String.isBlank(customErrorMessageForLMS)) {
                sfdcToLMSResponse.result = 'Success';
                sfdcToLMSResponseErrorDetail.code = '';
                sfdcToLMSResponseErrorDetail.message = '';
                sfdcToLMSResponse.errorDetail = sfdcToLMSResponseErrorDetail;
            }

        } catch (Exception e) {
            strRestError = UtilsRest.handleCustomRestError(e);
            sfdcToLMSResponse.result = 'Error';
            sfdcToLMSResponseErrorDetail.code = 'SER_CERT_004';
            sfdcToLMSResponseErrorDetail.message = 'An unknown error was encountered from Salesforce and the product serviced record cannot be created';
            sfdcToLMSResponse.errorDetail = sfdcToLMSResponseErrorDetail;
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess) {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess) {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();

        }
        ilib_LogEvent.emit();
        return JSON.serialize(sfdcToLMSResponse);
    }

    /*
    * @Description: deserializeInputs.
    */
    private static void deserializeInputs(String jsonInput) {
        ilib_LogEvent.push(LOG_TITLE + '.deserializeInputs()');
        lstLMSCertificationWrapper = LMSCertificationDataReceiverWrapper.parse(jsonInput);
        System.debug('LMSCertificationDataReceiverWrapper::::' + lstLMSCertificationWrapper);
        ilib_LogEvent.pop();
    }

    /*
    * @Description: upsertIncomingValuesImpl.
    */
    private static string upsertIncomingValuesImpl() {
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValuesImpl()');
        ilib_UpsertHelpers.ProductServicedUnitofWorkHelper productServicedWork = new ilib_UpsertHelpers.ProductServicedUnitofWorkHelper();

        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                SVMXC__Service_Group_Product__c.SObjectType
            });

        uow.registerWork(productServicedWork);

        string customErrorMessage = '';

        set < String > setProductFamiliesForCertification = new set < String > ();
        
        SVMXC__Service_Group_Members__c fieldSupportObjInContext = new SVMXC__Service_Group_Members__c();
        List < SVMXC__Service_Group_Product__c > lstProductServicedRecordToUpsert = new List < SVMXC__Service_Group_Product__c > ();
        List < User > lstSalesforceUser = new List < User > ();
        List<SVMXC__Service_Group_Members__c> lstFieldSupportRecords = new List<SVMXC__Service_Group_Members__c>();//DCP-43152
        

        string userUniqueId = lstLMSCertificationWrapper.Content.Person_Person_No; //get the field service user based on the unique id received from LMS
        string certificationId = lstLMSCertificationWrapper.Content.Certification_ID; //get the lms to certification mapping records.
        string certificationStatus = lstLMSCertificationWrapper.Content.Student_Certification_Status;
        string personDomain = lstLMSCertificationWrapper.Content.Person_Domain;//DCP-43152
        

        if (String.isNotBlank(userUniqueId) && String.isNotBlank(certificationId) && String.isNotBlank(certificationStatus)) {
            
            //DCP-43152 - Start
            String fieldSupportQuery = 'Select Id, SVMXC__Service_Group__c, (Select Id, SVMXC__Product__c, SVMXC__Group_Member__c,Certification_Name__c from SVMXC__Service_Group_Product__r) from SVMXC__Service_Group_Members__c';
            
            if(personDomain == STRING_INTERNAL_EMPLOYEE){
            lstSalesforceUser = new UsersSelector().getUniqueUsers(userUniqueId);   
            fieldSupportQuery += ' Where SVMXC__Salesforce_User__r.Unique_Id__c =: userUniqueId ';
            } else if (personDomain == STRING_EXTERNAL_EMPLOYEE){
            lstSalesforceUser = new UsersSelector().getCPUniqueUsersByFederationId(userUniqueId);   
            fieldSupportQuery += ' Where SVMXC__Salesforce_User__r.FederationIdentifier =: userUniqueId ';
            }
            lstFieldSupportRecords = Database.query(fieldSupportQuery);
            //DCP-43152 - End
            ilib_LogEvent.info('fieldSupportQuery : '+fieldSupportQuery);
            if (lstSalesforceUser.isEmpty())
                customErrorMessage = 'User ' + userUniqueId + ' not found in Salesforce. Product serviced record cannot be created.';

            Map < Id, SVMXC__Service_Group_Members__c > fieldSupportIdToFieldSupportMap = new Map < Id, SVMXC__Service_Group_Members__c > (lstFieldSupportRecords);
            if (fieldSupportIdToFieldSupportMap.isEmpty())
                customErrorMessage = String.isNotBlank(customErrorMessage) ? customErrorMessage : 'Field Support for User ' + userUniqueId + ' not found in Salesforce. Product serviced record cannot be created.';

            if (String.isBlank(customErrorMessage)) {

                //read the product family record based on the certification id received from LMS json.
                Map < Id, LMS_Certification_Mapping__c > sfdcCertificationIdToProductFamilyMap = new Map < Id, LMS_Certification_Mapping__c > (new LMSCertificationMappingSelector().selectProductFamilyByCertificationId(certificationId));

                if (sfdcCertificationIdToProductFamilyMap != null && !sfdcCertificationIdToProductFamilyMap.isEmpty()) {
                    for (Id lmsCertificationId: sfdcCertificationIdToProductFamilyMap.keyset()) {
                         //CMCP-11: Added null check for product family
                         if(sfdcCertificationIdToProductFamilyMap.get(lmsCertificationId).Product_Family__c!=null) 
                         {
                              setProductFamiliesForCertification.add(sfdcCertificationIdToProductFamilyMap.get(lmsCertificationId).Product_Family__c);
                         }
                    }
                    ilib_LogEvent.info('set of ProductFamiliesForCertification : '+setProductFamiliesForCertification);

                    //get all the products based on product families
                    Map < Id, Product2 > productIdToProductMap = new Map < Id, Product2 > (new ProductsSelector().selectProductsFromFamily(setProductFamiliesForCertification));

                    //update product serviced records for each of the product queried based on product family for that field support user.
                    if(fieldSupportIdToFieldSupportMap != null && !fieldSupportIdToFieldSupportMap.isEmpty()){
                    for (Id fieldSupportId: fieldSupportIdToFieldSupportMap.keyset()) {
                        fieldSupportObjInContext = fieldSupportIdToFieldSupportMap.get(fieldSupportId);
                        primaryRecordId = fieldSupportObjInContext.Id;
                        //CMCP-21 CodeScan Fix: Moved code to processExistingProductServicedRecords() method
                        lstProductServicedRecordToUpsert = processExistingProductServicedRecords(fieldSupportIdToFieldSupportMap,productIdToProductMap,lstLMSCertificationWrapper,lstProductServicedRecordToUpsert,fieldSupportId);                       
                    }

                }

                    //creation of product serviced records for the products which were not listed for that field support.
                    if(productIdToProductMap != null && !productIdToProductMap.isEmpty()){
                    for (Id productId: productIdToProductMap.keyset()) {
                        if (!productServicedProductIdToProductServicedMap.containsKey(productId)) {
                            //CMCP-21: ARB Review Comments: Added SVMXC__Service_Group_Product__c instance population logic in a separate method populateProductServicedInstance().
                            lstProductServicedRecordToUpsert.add(populateProductServicedInstance(certificationStatus,productId,fieldSupportObjInContext,lstLMSCertificationWrapper.Content.Certification_Name,lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On,lstLMSCertificationWrapper.Content.Student_Certification_Due_Date));
                        }

                    }
                    
                }  
                 //START:CMCP-21: Added else block. If no product family found, create one Product Service record keeping Product field empty.
                 else{
                    //CMCP-219:If setUpdatedCertification contains the certificationName of updated Product Service record, then dont create the new Product Service Record.
                    if(!setUpdatedCertification.contains(lstLMSCertificationWrapper.Content.Certification_Name))
                    {
                        //CMCP-21: ARB Review Comments: Added SVMXC__Service_Group_Product__c instance population logic in a separate method populateProductServicedInstance().
                        lstProductServicedRecordToUpsert.add(populateProductServicedInstance(certificationStatus,null,fieldSupportObjInContext,lstLMSCertificationWrapper.Content.Certification_Name,lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On,lstLMSCertificationWrapper.Content.Student_Certification_Due_Date));
                    }
                }
                //END:CMCP-21: Added else block. If no product family found, create one Product Service record keeping Product field empty. 

                    if (lstProductServicedRecordToUpsert != null && !lstProductServicedRecordToUpsert.isEmpty())
                        productServicedWork.registerUpsert(lstProductServicedRecordToUpsert);
                }
            }
            ilib_LogEvent.info('Product Service Record To Upsert Ids : '+utilsCollection.getsetOfIds(lstProductServicedRecordToUpsert));
        }
        businessRules(uow);

        uow.commitWork();
        ilib_LogEvent.info('Returning Error Message : '+customErrorMessage);
        ilib_LogEvent.pop();
        return customErrorMessage;
        
    }

    /*
    * @Description: post commit business logic.
    */
    public static void businessRules(ilib_SObjectUnitOfWork uow) {}

      /*
 * @Description: This method is triggered from Product trigger.
 */
   
    public static void createProductServicedForDCPProducts(set < Id > productIds) {
        ilib_LogEvent.push(LOG_TITLE + '.createProductServicedForDCPProducts()');
        ilib_LogEvent.info('Product Ids : '+productIds);
        set < String > setProductFamilies = new set < String > ();
        List < SVMXC__Service_Group_Product__c > lstProductServicedToInsert = new List < SVMXC__Service_Group_Product__c > ();
        Map < String, SVMXC__Service_Group_Product__c > fieldServiceIdToProductServicedMap = new Map < String, SVMXC__Service_Group_Product__c > ();
        Map < Id, LMS_Certification_Mapping__c > lmsMappingIdToProductFamiliesMap = new Map < Id, LMS_Certification_Mapping__c > (new LMSCertificationMappingSelector().selectLMSMappingRecords());
        Map < String, List < Product2 >> productFamilyToListProductMap = new Map < String, List < Product2 >> ();

        //productFamily to product list
        for (Product2 prodObj: [Select Id, Family from Product2 where Id IN: productIds]) {
            if (productFamilyToListProductMap.containsKey(prodObj.Family)) {
                productFamilyToListProductMap.get(prodObj.Family).add(prodObj);
            } else {
                productFamilyToListProductMap.put(prodObj.Family, new List < Product2 > ());
                productFamilyToListProductMap.get(prodObj.Family).add(prodObj);
            }
        }


        //only product families present in LMS mapping table needs to be processed.
        if (lmsMappingIdToProductFamiliesMap != null && !lmsMappingIdToProductFamiliesMap.isEmpty()) {
            for (Id lmsMappingObj: lmsMappingIdToProductFamiliesMap.keyset()) {
                if (productFamilyToListProductMap.containsKey(lmsMappingIdToProductFamiliesMap.get(lmsMappingObj).Product_Family__c))
                    setProductFamilies.add(lmsMappingIdToProductFamiliesMap.get(lmsMappingObj).Product_Family__c);
            }
        }
        ilib_LogEvent.info('setProductFamilies : '+setProductFamilies);

        //fetch all product serviced records for the product families received
        Map < Id, SVMXC__Service_Group_Product__c > productServicedIdToProductServiced = new Map < Id, SVMXC__Service_Group_Product__c > ([Select Id, Active_Certification__c, SVMXC__Product__c, SVMXC__Service_Group__c, SVMXC__Group_Member__c, SVMXC__Product__r.Family,Certification_Name__c,Student_Certification_Acquired_On__c,Student_Certification_Due_Date__c from SVMXC__Service_Group_Product__c Where SVMXC__Product__r.Family IN: setProductFamilies]);//CMCP-21: Added 3 more fields in SOQL query.

        //store field service of product serviced record with product serviced record.
        if (productServicedIdToProductServiced != null && !productServicedIdToProductServiced.isEmpty()) {
            for (Id productServicedObj: productServicedIdToProductServiced.keyset()) {
                fieldServiceIdToProductServicedMap.put(productServicedIdToProductServiced.get(productServicedObj).SVMXC__Group_Member__c, productServicedIdToProductServiced.get(productServicedObj));
            }
        }
        ilib_LogEvent.info('fieldServiceIdToProductServicedMap : '+fieldServiceIdToProductServicedMap);
        //create product serviced records for all those newly inserted products for DCP
        if (fieldServiceIdToProductServicedMap != null && !fieldServiceIdToProductServicedMap.isEmpty()) {
            for (string fieldSupportId: fieldServiceIdToProductServicedMap.keyset()) {
                if(productFamilyToListProductMap.containskey(fieldServiceIdToProductServicedMap.get(fieldSupportId).SVMXC__Product__r.Family)){
                for (Product2 prodObj: productFamilyToListProductMap.get(fieldServiceIdToProductServicedMap.get(fieldSupportId).SVMXC__Product__r.Family)) {
                    SVMXC__Service_Group_Product__c productServicedRec = new SVMXC__Service_Group_Product__c();
                    productServicedRec.SVMXC__Product__c = prodObj.Id;
                    productServicedRec.Active_Certification__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).Active_Certification__c;
                    productServicedRec.SVMXC__Group_Member__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).SVMXC__Group_Member__c;
                    productServicedRec.SVMXC__Service_Group__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).SVMXC__Service_Group__c;
                    //START:CMCP-21:Populated 3 more values..
                    productServicedRec.Certification_Name__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).Certification_Name__c;
                    productServicedRec.Student_Certification_Acquired_On__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).Student_Certification_Acquired_On__c;
                    productServicedRec.Student_Certification_Due_Date__c = fieldServiceIdToProductServicedMap.get(fieldSupportId).Student_Certification_Due_Date__c;
                    //END:CMCP-21:opulated 3 more values..
                    lstProductServicedToInsert.add(productServicedRec);
                }
             } 
            }
        }
        if (lstProductServicedToInsert != null && !lstProductServicedToInsert.isEmpty())
            insert lstProductServicedToInsert;
            ilib_LogEvent.info('ProductServiced Inserted Ids : '+UtilsCollection.getsetOfIds(lstProductServicedToInsert));
            ilib_LogEvent.pop();

    }
     /** populateProductServicedInstance
    * @author Sagar Madkaikar
    * @date   30-Aug-2021
    * @description: CMCP-21:ARB Review Comments:Common method to populate SVMXC__Service_Group_Product__c record instance
    * @params : 
    * @return : converted value in Date format.
    */
    private static SVMXC__Service_Group_Product__c populateProductServicedInstance(String certificationStatus, Id productId, SVMXC__Service_Group_Members__c fieldSupportObjInContext,String certificationName, String certificationAcquiredDate, String certificationDueDate){
        ilib_LogEvent.message('Product Id : '+productId);
        SVMXC__Service_Group_Product__c productServicedRec = new SVMXC__Service_Group_Product__c();
        productServicedRec.SVMXC__Product__c = productId;
        productServicedRec.Active_Certification__c = certificationStatus == CERT_STATUS_ACQUIRED ? true : false;
        productServicedRec.SVMXC__Group_Member__c = fieldSupportObjInContext.Id;
        productServicedRec.SVMXC__Service_Group__c = fieldSupportObjInContext.SVMXC__Service_Group__c;
        //START:CMCP-21:Populated more values that are coming from LMS.
        productServicedRec.Certification_Name__c = certificationName;
        productServicedRec.Student_Certification_Acquired_On__c = String.isNotBlank(certificationAcquiredDate)?UtilsObject.convertStringToDate(certificationAcquiredDate):null;
        productServicedRec.Student_Certification_Due_Date__c = String.isNotBlank(certificationDueDate)?UtilsObject.convertStringToDate(certificationDueDate):null;
        //END:CMCP-21:Populated  more values that are coming from LMS.
        ilib_LogEvent.message('Returning Record : '+productServicedRec);
        return productServicedRec;
    }

    /** processExistingProductServicedRecords
    * @author Sagar Madkaikar
    * @date   28-Oct-2021
    * @description: CMCP-21-CodeScan Fix: Taken the logic outside main method to reduce long method error. It populates the existing product serviced records with the lates LMS certification details received.
    * @params : Map < Id, SVMXC__Service_Group_Members__c > fieldSupportIdToFieldSupportMap,Map < Id, Product2 > productIdToProductMap,LMSCertificationDataReceiverWrapper lstLMSCertificationWrapper,List < SVMXC__Service_Group_Product__c > lstProductServicedRecordToUpser
    * @return : converted value in Date format.
    */
    private static List < SVMXC__Service_Group_Product__c > processExistingProductServicedRecords(Map < Id, SVMXC__Service_Group_Members__c > fieldSupportIdToFieldSupportMap,Map < Id, Product2 > productIdToProductMap,LMSCertificationDataReceiverWrapper lstLMSCertificationWrapper,List < SVMXC__Service_Group_Product__c > lstProductServicedRecordToUpsert,Id fieldSupportId)
    {


        for (SVMXC__Service_Group_Product__c productServicedObj: fieldSupportIdToFieldSupportMap.get(fieldSupportId).SVMXC__Service_Group_Product__r) {
            //if contains product id, update the certification status.
            ilib_LogEvent.fine('Record in Loop : '+productServicedObj);
            if (productIdToProductMap.containsKey(productServicedObj.SVMXC__Product__c)) {
                productServicedObj.Active_Certification__c = lstLMSCertificationWrapper.Content.Student_Certification_Status == CERT_STATUS_ACQUIRED ? true : false;
                productServicedObj.Student_Certification_Due_Date__c = String.isNotBlank(lstLMSCertificationWrapper.Content.Student_Certification_Due_Date)?UtilsObject.convertStringToDate(lstLMSCertificationWrapper.Content.Student_Certification_Due_Date):null;
                productServicedObj.Student_Certification_Acquired_On__c = String.isNotBlank(lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On)?UtilsObject.convertStringToDate(lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On):null;
                productServicedProductIdToProductServicedMap.put(productServicedObj.SVMXC__Product__c, productServicedObj);
                lstProductServicedRecordToUpsert.add(productServicedObj);
            }
            //CMCP-219: Added Else block for updating Product Serviced record for Certification without a Product Family. Earlier it was creating duplicate Product Serviced Record.
            else {
                if(productServicedObj.Certification_Name__c==lstLMSCertificationWrapper.Content.Certification_Name)
                {
                    productServicedObj.Active_Certification__c = lstLMSCertificationWrapper.Content.Student_Certification_Status == CERT_STATUS_ACQUIRED ? true : false;
                    productServicedObj.Student_Certification_Due_Date__c = String.isNotBlank(lstLMSCertificationWrapper.Content.Student_Certification_Due_Date)?UtilsObject.convertStringToDate(lstLMSCertificationWrapper.Content.Student_Certification_Due_Date):null;
                    productServicedObj.Student_Certification_Acquired_On__c = String.isNotBlank(lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On)?UtilsObject.convertStringToDate(lstLMSCertificationWrapper.Content.Student_Certification_Acquired_On):null;
                    setUpdatedCertification.add(lstLMSCertificationWrapper.Content.Certification_Name);
                    lstProductServicedRecordToUpsert.add(productServicedObj);
                }
            }
        }
        return lstProductServicedRecordToUpsert;
    }



}

/* Sample Incoming JSON */
/*

{
        "MetaData": {
            "EventCreatedDate": "2021-03-01T19:20:14.125"
        },
        "Content": {
            "Certification_Progress_Action_Date": "16-Feb-21",
            "Certification_Assignment_Created_On": "16-Feb-21",
            "Certification_Assignment_Updated_On": "16-Feb-21",
            "Person_Full_Name": "Tracy Solomon",
            "Student_Certification_Status": "Acquired",
            "Certification_Name": "DCP 4 Certification",
            "Certification_Version": "3",
            "Certification_ID": "53344",
            "Student_Certification_Assigned_On": "16-Feb-21",
            "Student_Certification_Acquired_On": "16-Feb-21",
            "Student_Certification_Due_Date": "2-Mar-21",
            "Student_Certification_Expiration_Date": "2-Mar-21",
            "Person_Username": "3187",
            "Person_Person_No": "1.03183E+18",
            "Person_SAM_Account": "tsolomon",
            "Person_Email": "tsolomon@illumina.com",
            "Person_Employee_Type": "Employee",
            "Person_Domain": "Internal"
        }
    }

*/