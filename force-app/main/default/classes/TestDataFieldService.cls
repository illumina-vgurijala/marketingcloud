/***************************************************************************************************************************************
* NAME   : TestDataFieldService
* DESCRIPTION  : For creating reusable test specific data and methods
*    
* @AUTHOR : Debalina
* @DATE   : 16-May-2018  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Debalina             16-May-2018             Initial Version
* Ritika               22-May-2018              Added methods to createcase and createworkorder
* Debalina             31-May-2018              DCP-802/DCP-803 Added createContact/createCase/ methods 
* Debalina             11-Jun-2018              DCP-804 Added createDocLink/createDocVersion/createAccount/createInstalledProduct
* Sandeep Ram Ch.      12-Jun-2018              DCP-1050 Added service team/ Technician methods and changing return type of user method
* Ritika M             18-Jun-2018              Removed createCase method
* Akshay               19-Jun-2018              Removed createAccount method
 * Soumya               09-AUG-2018              DCP-1573 Added createProduct method
 * Soumya               21-Aug-2018             DCP-842 Added createPartsOrderForInstallationWO() Method
 ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false) 
public with sharing class TestDataFieldService {  
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates createDocLink
*  @PARAM : String strDocId, String strLinkId, String strShare, String strVisbility
*  @RETURN:  ContentDocumentLink
*/
    public static ContentDocumentLink createDocLink(String strDocId, String strLinkId, String strShare, String strVisbility){
        return new ContentDocumentLink(ContentDocumentId =  strDocId,
                                       LinkedEntityId = strLinkId, 
                                       ShareType = strShare,
                                       Visibility =strVisbility);
    }
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates createDocVersion
*  @PARAM :  String strTitle, String strPathOnClient, String strVersionData, Boolean boolIsMajorVersion
*  @RETURN:  ContentVersion
*/
    public static ContentVersion createDocVersion(String strTitle, String strPathOnClient, String strVersionData, Boolean boolIsMajorVersion){
        return new ContentVersion(Title =  strTitle,
                                  PathOnClient = strPathOnClient, 
                                  VersionData = Blob.valueOf(strVersionData),
                                  IsMajorVersion = boolIsMajorVersion);
    }
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates EmailTemplate
*  @PARAM :  String strUniqeName
*  @RETURN:  objEmailTemplate
*/
    public static EmailTemplate createEmailTemplate(String strUniqeName) {
        EmailTemplate objEmailTemplate = new EmailTemplate();
        objEmailTemplate.isActive = true;
        objEmailTemplate.Name = strUniqeName;
        objEmailTemplate.DeveloperName = strUniqeName;
        objEmailTemplate.TemplateType = 'text';
        objEmailTemplate.FolderId = UserInfo.getUserId();
        
        insert objEmailTemplate;
        return objEmailTemplate;
    }
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates Installed Product
*  @PARAM :  String strName, String strCurrencyCode
*  @RETURN:  Account type object
*/
    public static SVMXC__Installed_Product__c createInstalledProduct(String strName, String strCurrencyCode, String strStatus){
        SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c(Name = strName, 
                                                                            CurrencyIsoCode = strCurrencyCode, 
                                                                            SVMXC__Status__c = strStatus);
        return objIP;
    }

     /*
*  @AUTHOR:  Ritika   
*  @DESCRIPTION:This method creates Installed Product
*  @PARAM :  String product Id
*  @RETURN:  Installed Product
*/
    public static SVMXC__Installed_Product__c createInstalledProduct(Id productId){
        SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c(SVMXC__Product__c = productId);
        return objIP;
    }

     /**
*  @author Ritika Maheshwari
*  @description - Method to create Service BOM 
* params : String product Id
* return type : ServiceBOM instance
**/
    public static Service_Bill_Of_Materials__c createServiceBOM(Id productId)
    {
        Service_Bill_Of_Materials__c serviceBOM = new Service_Bill_Of_Materials__c(Product__c = productId,
                                                                                    Active__c = TRUE,
                                                                                    ERP_Service_BoM_Number__c = '1122');
        insert serviceBOM;
        return serviceBOM;
    }

    /**
*  @author Ritika Maheshwari
*  @description - Method to create FRU List 
* params : String Service BOM ID, Product Id
* return type : FRU instance
**/
    public static FRU_List__c createToolFRU(Id serviceBOMId,Id productId)
    {
        FRU_List__c objFRU = new FRU_List__c(ERP_Product__c = productId,
                                            Service_Bill_Of_Materials__c = serviceBOMId);
        insert objFRU;
        return objFRU;
    }

    /**
*  @author Ritika Maheshwari
*  @description - Method to create FRU List 
* params : String Service BOM ID, Product Id
* return type : FRU instance
**/
    public static FRU_List__c createPartFRU(Id serviceBOMId,Id productId)
    {
        FRU_List__c objFRU = new FRU_List__c(ERP_Product__c = productId,
                                            Service_Bill_Of_Materials__c = serviceBOMId);
        insert objFRU;
        return objFRU;
    }
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates Custom Settings
*  @PARAM :  NA
*  @RETURN:  void
*/
    public static void createSettings(){
        TestDataOrg.createSettings();
    }
    
    
    /**
*  @author Ritika Maheshwari
*  @description - Method to create work order 
* params : work order record type name
* params : case id
* params : order status
* return type : Work Order instance
**/
    public static SVMXC__Service_Order__c createWorkOrder(String recordTypeName, String caseId, String orderStatus)
    {
        Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(
            RecordTypeId = woRecordTypeId,
            SVMXC__Case__c = caseId,
            SVMXC__Order_Status__c = orderStatus,
            SVMXC__Order_Type__c = 'Field Service'
        );
        return workOrder;
    }
    
    /**
*  @author Vaibhav Parashar
*  @description - Method to create work order.
* params : work order record type name
* params : recordTypeName, orderStatus, orderType
* return type : Work Order instance
**/
    public static SVMXC__Service_Order__c createWorkOrderWithoutCase(String recordTypeName,String orderStatus,String orderType)
    {
        Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(
            RecordTypeId = woRecordTypeId,
            SVMXC__Order_Type__c = orderType,
            SVMXC__Order_Status__c = orderStatus,
            Cost_Center__c = 123456
        );
        insert workOrder;
        return workOrder;
    }
    
    /**
*  @author Ritika Maheshwari
*  @description - Method to create part order instance 
* params : work order record type name
* params : case id
* params : order status
* return type : Part Order instance
**/
    public static SVMXC__RMA_Shipment_Order__c createPartOrder(String recordTypeName, String caseId, String partOrderStatus)
    {
        Id poRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        SVMXC__RMA_Shipment_Order__c partOrder = new SVMXC__RMA_Shipment_Order__c(
            RecordTypeId = poRecordTypeId,
            SVMXC__Case__c = caseId,
            SVMXC__Order_Status__c = partOrderStatus
        );
        return partOrder;
    }
    /**
*  @author Sandeep Ram Ch.
*  @description - Method to create Service Team instance 
* params : Service Team name
* params : country
* return type : Service Team instance
**/
    
    public static SVMXC__Service_Group__c createServiceTeam (String  serviceTeamName,String country){
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = serviceTeamName,
            SVMXC__Country__c = country);
        
        return serviceTeam;
        
    }
    
    /**
*  @author Sandeep Ram Ch.
*  @description - Method to create Technician instance 
* params : Technician name
* params : user id
* params : service team id
* return type : Technician instance
**/
    
    public static SVMXC__Service_Group_Members__c createTechnician (String userId,String technicianName,String serviceTeamId)
    {
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(SVMXC__Salesforce_User__c = userId,
                                                                                         Name = technicianName,SVMXC__Service_Group__c = serviceTeamId);
        
        return grpMembers;
        
    }
    
    
    /**
*  @author Sandeep Ram Ch.
*  @description - Method to create Account To FieldSupport instance 
* params : user Role
* params : Account id
* params : user Id
* return type : Account To FieldSupport instance
**/
    
    public static Account_to_Field_Support__c createAccountToFieldSupport (String accId,String userRole,String userId){
        
        
        Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
            Account__c = accId,
            User__c = userId,
            User_Role__c = userRole
        );
        return accTechRole;
    }
    
    /**
*  @author Sandeep Ram Ch.
*  @description - Method to create Loction instance 
* params : Name
* params : street
* params : country
* params : zip
* params : currency
* return type : location instance
**/
    
    public static SVMXC__Site__c createLocation (String name,String street,String country,String zip,String strCurrency){
        
        
        SVMXC__Site__c location = new SVMXC__Site__c(
            Name = name,
            SVMXC__Street__c = street,
            SVMXC__Country__c = country,
            SVMXC__Zip__c =zip,
            CurrencyIsoCode=strCurrency
        );
        return location;
    }
	
    /*
    * method to create Location record
    */	
    public static SVMXC__Site__c getNewLocation(Id accountId)
    {
        SVMXC__Site__c rec = initLocation(accountId);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Location record with Account
    */		
    public static SVMXC__Site__c initLocation(Id accountId)
    {
        SVMXC__Site__c rec = new SVMXC__Site__c(
            SVMXC__Account__c = accountId,
            Name = TestData.getRandom(),
            SVMXC__Street__c = TestData.getRandom(),
            SVMXC__Country__c = 'US',
            SVMXC__Zip__c = TestData.getRandom()
        );
        return rec;
    }

    /**
    *  @author Sandeep Ram Ch.
    *  @description - Method to create work detail instance 
    * params : Work Order id 
    * params : Installed Product Id
    * return type : Work Detail instance
    **/
    public static SVMXC__Service_Order_Line__c createWorkDetail (String  woId,String ipId){
        
        SVMXC__Service_Order_Line__c workDetail = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = woId,
            SVMXC__Serial_Number__c = ipId);
        
        return workDetail;
        
    }
    
     /**
    *  @author Ritika M
    *  @description - Method to create work detail instance for a record type and work order id
    * params : Work Order id 
    * params : Installed Product Id
    * return type : Work Detail instance
    **/
        
    public static SVMXC__Service_Order_Line__c createWorkDetailWithSpecifiedRecordType (String  woId,String recordTypeName){
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(); 
        SVMXC__Service_Order_Line__c workDetail = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = woId,
            RecordTypeId = idWorkDetailRecordTypeId);
        
        return workDetail;
        
    }
    /**
*  @author Sandeep Ram Ch.
*  @description - Method to create Location covered instance 
* params : Field Support id 
* params : Location Id
* return type : Location covered instance
**/
    
    public static SVMXC__Service_Group_Site__c createLocationCovered (String  fieldSupportId,String locationId,String serviceGroupId){
        
        SVMXC__Service_Group_Site__c locationCovered = new SVMXC__Service_Group_Site__c(
            SVMXC__Technician_Equipment__c = fieldSupportId,
            SVMXC__Site__c = locationId,
            SVMXC__Service_Group__c=serviceGroupId);
        
        return locationCovered;
        
    }
    
    /**
*  @author Veerendra
*  @description - Method to create Service Contract
* params : Account id
* return type : Service Contract instance
**/
    public static SVMXC__Service_Level__c createServiceLevel()
    {
        SVMXC__Service_Level__c objServiceLevel = new SVMXC__Service_Level__c(
            Name ='Test',
            SVMXC__Onsite_Response_Tracked_On__c='Case',
            SVMXC__Restoration_Tracked_On__c='Case',
            SVMXC__Resolution_Tracked_On__c='Case',
            SVMXC__Active__c = true
        );
        return objServiceLevel;
    } 
    
/**
*  @author Nancy Kalach
*  @description - Method to create Service Plan
* params : Name
* return type : Service Contract instance
**/
public static SVMXC__Service_Plan__c createServicePlan(String name) {
        
    SVMXC__Service_Plan__c svcPlan = new SVMXC__Service_Plan__c();
    svcPlan.Name = name;
    svcPlan.SVMXC__Active__c = true;

    insert svcPlan;
    return svcPlan;
}

	/*
    * method to create Service Contract record
    */	
    public static SVMXC__Service_Contract__c createServiceContract(String accountId)
    {
        SVMXC__Service_Contract__c serviceContract = new SVMXC__Service_Contract__c(
            Name = 'Test Contract',
            Status__c = 'Active',
            SVMXC__Company__c = accountId,
            SVMXC__Start_Date__c = date.Today(),
            SVMXC__End_Date__c = date.Today()+1
        );
        return serviceContract;
    } 
    
    
    /**
    *  @author Mandeep
    *  @description - Method to create Service Detail
    * params : Service Level id
    * return type : Service Detail instance
    **/
    public static SVMXC__SLA_Detail__c createServiceDetail(Id objServiceLevel)
    {
        SVMXC__SLA_Detail__c objServiceDetail = new SVMXC__SLA_Detail__c(
        SVMXC__Commitment_Type__c = 'InitialResponse',
        SVMXC__Customer_Commitment__c = 10,
        SVMXC__SLA_Terms__c = objServiceLevel
        );
        
        return objServiceDetail;
    } 
    
    
    /**
    *  @author Veerendra
    *  @description - Method to create Covered Product
    * params : Installed Product id
    * return type : Covered Product instance
    **/
    public static SVMXC__Service_Contract_Products__c createCoveredProduct(String installedProductId)
    {
        SVMXC__Service_Contract_Products__c coveredProduct = new SVMXC__Service_Contract_Products__c(
            SVMXC__Installed_Product__c = installedProductId,
            SVMXC__Start_Date__c = system.today().addDays(-10),
            SVMXC__End_Date__c = system.today().addDays(10)
        );
        return coveredProduct;
    }
    
    /**
    *  @author Veerendra
    *  @description - Method to create Covered Location
    * params : Location id
    * return type : Covered Location instance
    **/
    public static SVMXC__Service_Contract_Sites__c createCoveredLocation(String locationId)
    {
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = locationId
        );
        return coveredLocation;
    } 
    
    /**
    *  @author Veerendra
    *  @description - Method to create Parts Order
    * params : Case id
    * return type : Parts Order instance
    **/
    public static SVMXC__RMA_Shipment_Order__c createPartsOrder(String caseId)
    {
        SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(
            SVMXC__Case__c = caseId
        );
        return partsOrder;
    }

    /**
    *  @author Soumya
    *  @description - Method to create Parts Order with installation work order
    * params : Work Order id
    * return type : Parts Order instance
    **/
    public static SVMXC__RMA_Shipment_Order__c createPartsOrderForInstallationWO(String workOrderId)
    {
        SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(
            SVMXC__Service_Order__c = workOrderId
        );
        return partsOrder;
    }

	/*
    * method to create Parts Order record
    */	
    public static SVMXC__RMA_Shipment_Order__c getNewPartsOrder(Id workOrderId, Id siteId)
    {
        SVMXC__RMA_Shipment_Order__c rec = initPartsOrder(workOrderId, siteId);
        insert rec;
        return rec;
    }

    /*
    * method to create Parts Order record with service order
    */
    public static SVMXC__RMA_Shipment_Order__c initPartsOrder(Id workOrderId, Id siteId)
    {
        SVMXC__RMA_Shipment_Order__c rec = new SVMXC__RMA_Shipment_Order__c(
            SVMXC__Service_Order__c = workOrderId,
            Shipping_Location__c  = siteId,
            SVMXC__Order_Type__c = 'Shipment',
            Contact_Name__c = TestData.getRandom(),
            Contact_Phone__c = TestData.getRandomNumeric()
        );
        return rec;
    }

    /**
    *  @author Veerendra
    *  @description - Method to create Parts Order Line
    * params : Parts Order id
    * return type : Parts Order Line instance
    **/
    public static SVMXC__RMA_Shipment_Line__c createPartsOrderLines(String partsOrderId)
    {
        SVMXC__RMA_Shipment_Line__c partsOrderLine = new SVMXC__RMA_Shipment_Line__c(
            SVMXC__RMA_Shipment_Order__c = partsOrderId
        );
        return partsOrderLine;
    }
    
	/*
    * method to create entitlement record
    */	
    public static Applied_Contract__c createEntitlement(String caseId, String workOrderId, String contractId)
    {
        Applied_Contract__c entitlement = new Applied_Contract__c(
            Case_Number__c = caseId,
            Work_Order__c = workOrderId,
            Service_Contract__c = contractId
        );
        return entitlement;
    }

    /**
    *  @author Soumya
    *  @description - Method to create Product
    * params : Product Name, Material Class
    * return type : Product instance
    **/
    public static Product2 createProduct(String strProductName, String strMaterialClass)
    {
        Product2 objProduct = new Product2(
            Name = strProductName, 
            Material_Class__c = strMaterialClass,
            Source_System__c='SAP');
        return objProduct;
    }

    /**
    *  @author Soumya
    *  @description - Method to create Work Detail of Type Tools
    * params : Work Order ID, Product ID
    * return type : Work Detail instance
    **/
    public static SVMXC__Service_Order_Line__c createToolTypeWorkDetail (String  strWorkOrderId,String strProductId){
        
        SVMXC__Service_Order_Line__c objWorkDetail= new SVMXC__Service_Order_Line__c(RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId(),
                                                                                     SVMXC__Line_Type__c='Tools',
                                                                                     SVMXC__Service_Order__c= strWorkOrderId, 
                                                                                     SVMXC__Product__c=strProductId);
        
        return objWorkDetail;
        
    }

    /**
    *  @author Ritika
    *  @description - Method to create Work Detail of Type Parts
    * params : Work Order ID, Product ID
    * return type : Work Detail instance
    **/
    public static SVMXC__Service_Order_Line__c createPartTypeWorkDetail (String  strWorkOrderId,String strProductId, String installedProductId){
        
        SVMXC__Service_Order_Line__c objWorkDetail= new SVMXC__Service_Order_Line__c(RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId(),
                                                                                     SVMXC__Line_Type__c='Parts',
                                                                                     SVMXC__Service_Order__c= strWorkOrderId, 
                                                                                     SVMXC__Product__c=strProductId,
                                                                                     SVMX_PS_VS_Return_Installed_Product__c= installedProductId);
        
        return objWorkDetail;
        
    }
    /**
    *  @author Soumya
    *  @description - Method to create FRU List
    * params : Product ID
    * return type : FRUList instance
    **/
    public static FRU_List__c createFRUList(Id productId)
    {
        FRU_List__c objFRUList = new FRU_List__c(ERP_Product__c = productId);
        return objFRUList;
    }

    /**
    *  @author Debanka
    *  @description - Method to create Field Action & Notification of Record Type Notification
    * params : RecordTypeName
    * return type : Field Action Notification instance
    **/
    public static Field_Action_Notification__c createFAN (String  strRecordTypeName){
        
        Field_Action_Notification__c objFAN= new Field_Action_Notification__c(RecordTypeId = Schema.SObjectType.Field_Action_Notification__c.getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId(),
                                                                              Subject__c='Testing Notification',
                                                                              Notification_Type__c= 'PCN');                                                                             
        return objFAN;
        
    }
   
    /**
    *  @author Debanka
    *  @description - Method to create Field Action Item 
    * params : caseId and fANId
    * return type : Field Action Item instance
    **/
    public static Field_Action_Item__c createFAI (Id caseId, Id fANId){
        
        Field_Action_Item__c objFAI= new Field_Action_Item__c(Case__c=caseId,Field_Action_Notification__c = fANId);
        return objFAI;
        
    }

    /**
    *  @author Soumya
    *  @description - Method to create Attachment 
    * params : ParentId and Attachment Name
    * return type : Attachment instance
    **/
    public static Attachment createAttachment (Id idParentId, string strAttachmentName){
        
        Attachment objAttachment= new Attachment(ParentId=idParentId,Name = strAttachmentName, Body=Blob.ValueOf('Test'));
        return objAttachment;
        
    }

   /*  @author Soumya
    *  @description - Method to create Agreement instance 
    * params : Agreement Name, status, work order Id
    * params : case id
    * params : order status
    * return type : Part Order instance
    **/
    public static echosign_dev1__SIGN_Agreement__c createAgreement(String strName, String strStatus, Id idWorkOrderId)
    {
        
        echosign_dev1__SIGN_Agreement__c objAgreement = new echosign_dev1__SIGN_Agreement__c(
            Name = strName,
            Work_Order__c = idWorkOrderId,
            echosign_dev1__Status__c = strStatus
        );
        return objAgreement;
    }
	
	/*
    * method to create Work Order record
    */
    public static SVMXC__Service_Order__c getNewWorkOrder(Id accountId)
    {
        SVMXC__Service_Order__c rec = initWorkOrder(accountId);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Work Order record  with Account
    */	
    public static SVMXC__Service_Order__c initWorkOrder(Id accountId)
    {
        Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
        SVMXC__Service_Order__c rec = new SVMXC__Service_Order__c(
                RecordTypeId = woRecordTypeId,
                SVMXC__Company__c = accountId,
                SVMXC__Order_Status__c = 'Initiated',
                SVMXC__Order_Type__c = 'Field Service'
        );

        return rec;
    }
	
	/*
    * method to create Comment record
    */	
    public static Comment__c getNewComment(Id workOrderId)
    {
        Comment__c rec = initComment(workOrderId);
        insert rec;
        return rec;
    }

	/*
    * method to create Comment record with Work Order
    */		
    public static Comment__c initComment(Id workOrderId)
    {
        Comment__c rec = new Comment__c(
                Work_Order__c = workOrderId,
                Comment__c = TestData.getRandom()
        );
        return rec;
    }


    /*  @author Dipika
    *  @description - Method to create Agreement instance 
    * params : Profie Name
    * return type : User
    **/
    public static User createUser(String profileName, boolean isInsert){
        List<Profile> testProfiles = [Select Id From Profile where Name=: profileName limit 1];
        String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
        User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', 
                                LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                                ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
        
        
        if(isInsert){
           insert testUser;
        }
        return testUser;
        
    }

    /**
    *  @author Dipika
    *  @description - Method to create contact
    * params : FirstName 
    * params : LastName
    * params : emailId
    * return type : Contact Instance
    **/
    public static Contact createContact(string fName,String lName,String emailId){
        Contact con=new Contact(FirstName = fName, LastName = lName,email=emailId);
        insert con;
        return con;
    }
    
    /**
    *  @author Soumya
    *  @description - Method to create code library record
    * params : CodeTitle 
    * params : CodeType
    * params : ServiceProductType
    * return type :Code Library Instance
    **/
    public static Code_Library__c createCodeLibrary(string strCodeTitle,String strCodeType,String strServiceProductType){
        Code_Library__c objCodeLibrary = new Code_Library__c(Name=strCodeTitle,Code_Type__c=strCodeType,
            Service_Product_Type__c=strServiceProductType,Logistics_Supply_Chain_code__c = true);
        return objCodeLibrary;
    }

    /**
    *  @author Soumya
    *  @description - Method to create Associated code record
    * params : caseId
    * params : WorkOrderId
    * params : CodeLibraryId
    * return type :Associated Code Instance
    **/
    public static Associated_Codes__c createAssociatedCode(id idCase,id idWorkOrder, id idCodeLibrary ){
        Associated_Codes__c objAssociatedCode = new Associated_Codes__c(Code_Title__c=idCodeLibrary,Case__c=idCase,
            Work_Order__c=idWorkOrder);
        return objAssociatedCode;
    }

    /**
    *  @author Debanka
    *  @description - Method to create Work Detail of Type Materials Consumed
    * params : Work Order ID, Product ID
    * return type : Work Detail instance
    **/
    public static SVMXC__Service_Order_Line__c createMaterialsConsumedTypeWorkDetail (String  strWorkOrderId,String strProductId){
        
        SVMXC__Service_Order_Line__c objWorkDetail= new SVMXC__Service_Order_Line__c(RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId(),
                                                                                     SVMXC__Line_Type__c='Material Consumed',
                                                                                     SVMXC__Service_Order__c= strWorkOrderId, 
                                                                                     SVMXC__Product__c=strProductId);
        
        return objWorkDetail;
        
    }

	/*
    * method to create Parts Request record
    */
    public static SVMXC__Parts_Request__c getNewPartsRequest(Id workOrderId, Id supplierId, Id locationId)
    {
        SVMXC__Parts_Request__c rec = initPartsRequest(workOrderId, supplierId, locationId);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Parts Request record with Work Order
    */		
    public static SVMXC__Parts_Request__c initPartsRequest(Id workOrderId, Id supplierId, Id locationId)
    {
        SVMXC__Parts_Request__c rec = new SVMXC__Parts_Request__c(
            SVMX_PS_Work_Order__c = workOrderId,
            SVMXC__Company__c = supplierId,
            SVMXC__Requested_From__c = locationId
        );
        return rec;
    }

	/*
    * method to create Service Group record
    */
    public static SVMXC__Service_Group__c getNewServiceTeam(String country)
    {
        SVMXC__Service_Group__c rec = initServiceTeam(country);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Service Group record with random name
    */		
    public static SVMXC__Service_Group__c initServiceTeam(String country)
    {
        return new SVMXC__Service_Group__c (
            Name = TestData.getRandom(),
            SVMXC__Country__c = country
        );
    }

	/*
    * method to create Service Group Member record
    */
    public static SVMXC__Service_Group_Members__c getNewFieldSupport(Id userId, String technicianName, Id serviceTeamId)
    {
        SVMXC__Service_Group_Members__c rec = initFieldSupport(userId, technicianName, serviceTeamId);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Service Group Member record 
    */
    public static SVMXC__Service_Group_Members__c initFieldSupport(Id userId, String technicianName, Id serviceTeamId)
    {
        return new SVMXC__Service_Group_Members__c(
            SVMXC__Salesforce_User__c = userId,
            Name = technicianName,
            SVMXC__Service_Group__c = serviceTeamId
        );
    }

	/*
    * method to create Account To Field Support record 
    */	
    public static Account_to_Field_Support__c getNewAccountToFieldSupport(Id accountId, String userRole, Id userId)
    {
        Account_to_Field_Support__c rec = initAccountToFieldSupport(accountId, userRole, userId);
        insert rec;
        return rec;
    }
	
	/*
    * method to create Account To Field Support record with Account
    */
    public static Account_to_Field_Support__c initAccountToFieldSupport(Id accountId, String userRole, Id userId)
    {
        return new Account_to_Field_Support__c(
            Account__c = accountId,
            User__c = userId,
            User_Role__c = userRole
        );
    }

	/*
    * method to create Serialized Product record 
    */
    public static Product2 getNewSerializedProduct()
    {
        Product2 rec = initSerializedProduct();
        insert rec;
        return rec;
    }
	
	/*
    * method to initialize Serialized Product record 
    */		
    public static Product2 initSerializedProduct()
    {
        return new Product2(
                Name = TestData.getRandom(),
                IsActive = true,
                SVMXC__Tracking__c = 'Serialized',
                SVMXC__Stockable__c = true,
                SVMXC__Enable_Serialized_Tracking__c = true
        );
    }

	/*
    * method to create Product AStock record 
    */	
    public static SVMXC__Product_Stock__c getNewProductStock(Id locationId, Id productId)
    {
        SVMXC__Product_Stock__c rec = initProductStock(locationId, productId);
        insert rec;
        return rec;
    }
	
	/*
    * method to insitialize Product AStock record 
    */		
    public static SVMXC__Product_Stock__c initProductStock(Id locationId, Id productId)
    {
        return new SVMXC__Product_Stock__c(
            SVMXC__Location__c = locationId,
            SVMXC__Product__c = productId,
            SVMXC__Status__c = 'Available',
            SVMXC__Quantity2__c = Decimal.valueOf(TestData.getRandomNumeric(2)),
            SVMX_PS_External_ID__c = TestData.getRandom()
        );
    }

      /**
    *  @author Soumya
    *  @description - Method to create work order with location.
    * params : work order record type name,LocationId
    * params : recordTypeName, orderStatus, orderType
    * return type : Work Order instance
    **/
    public static SVMXC__Service_Order__c createWorkOrderWithLocation(String recordTypeName,id idLocation,String orderStatus,String orderType)
    {
        Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(
            RecordTypeId = woRecordTypeId,
            SVMXC__Order_Type__c = orderType,
            SVMXC__Order_Status__c = orderStatus,
            SVMXC__Site__c = idLocation
        );
        return workOrder;
    }

    /**
    *  @author Soumya
    *  @description - Method to create Cycle Count from work order
    * params : work orderId,status
    * return type : Cycle Count instance
    **/
    public static Cycle_Count__c createCycleCountFromWO(id idWorkOrder, String status)
    {
            Cycle_Count__c objCycleCount = new Cycle_Count__c(            
            Work_Order__c = idWorkOrder,
            Status__c = status
        );
        return objCycleCount;
    }
	
	/*
    * method to create IB Technical Attribute For IP
    */		
	public static SVMXC__SM_IB_Technical_Attributes__c  createIBTechAttributeForIP(id idIP, String attributeName , String attributeValue)
    {
           SVMXC__SM_IB_Technical_Attributes__c objIBTechAttr = new SVMXC__SM_IB_Technical_Attributes__c(            
            SVMXC__SM_Installed_Product_id__c = idIP,
            SVMXC__SM_IsActive__c = true,
            SVMXC__SM_Attr_Name__c=attributeName,
            SVMXC__SM_Attr_Value__c=attributeValue
        );
        return objIBTechAttr;
    }

    /*******************************************************************************************************
    * @description DCP-42926
    * @param partsOrderId Parts Order Id
    * @param objLocationRecId Location Id
    * @param recTypeId Record Type Id
    * @param status Line status
    * @param installProdId Install Product Id
    * @param prodId Product Id
    * @return SVMXC__RMA_Shipment_Line__c
    */
    public static SVMXC__RMA_Shipment_Line__c createPartsOrderLineRecord(String partsOrderId, Id objLocationRecId, Id recTypeId, 
                                                                String status, Id installProdId, Id prodId) {
        SVMXC__RMA_Shipment_Line__c partsOrderLine = new SVMXC__RMA_Shipment_Line__c(
            SVMXC__RMA_Shipment_Order__c = partsOrderId,
            From_Location__c = objLocationRecId,
            RecordTypeId = recTypeId,
            SVMXC__Line_Status__c = status,
            SVMXC__Serial_Number__c = installProdId,
            SVMXC__Product__c = prodId
        );
        return partsOrderLine;
    }

    /*******************************************************************************************************
    * @description DCP-42926
    * @param orderType Parts Order Type
    * @param status Order status
    * @param salesONo ERP Sales Order Number
    * @param cName Contact Name
    * @param cPhone Contact Phone
    * @param locationId Shipping Location Id
    * @return SVMXC__RMA_Shipment_Order__c
    */
    public static SVMXC__RMA_Shipment_Order__c createPartsOrderRecord(String orderType, String status, String salesONo, 
                                                                String cName, String cPhone, Id locationId) {
            SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(
                SVMXC__Order_Type__c = orderType,
                SVMXC__Order_Status__c = status,
                ERP_Sales_Order_Number__c = salesONo,
                Contact_Name__c = cName,
                Contact_Phone__c = cPhone,
                Shipping_Location__c = locationId
        );
        return partsOrder;
    }

    /*  @author Dhairya Shah
    *  @description - Method to create Associated Product
    * params : workorderId, CaseID
    * US -CMCM-7542
    **/	
    public static Associated_Product__c createAssociatedProductonCase(Id caseId, Id workOrderId, Id productId,
                                                                        Id installedproductId, Id accountId)
    {
        Associated_Product__c apc2 = new Associated_Product__c(
            Case__c =caseId,
            Work_Order__c = workOrderId,
            Product_Serial_Number__c = 'TS12345678',
            Product__c = productId,
            Installed_Product__c = installedproductId,
            Account__c =accountId
        );
        return apc2;
    }

        /*
    *  @AUTHOR:  Dhairya shah   
    *  @DESCRIPTION:This method creates Installed Product
    *  @PARAM :  String strName, String strCurrencyCode
    *  US - CMCM - 7910
    */
    public static SVMXC__Installed_Product__c createInstalledProductforLotNumber(String strName, String strStatus, String serialLotNumber){
        SVMXC__Installed_Product__c objLotNum = new SVMXC__Installed_Product__c(Name = strName,
                                                                            SVMXC__Status__c = strStatus,
                                                                            SVMXC__Serial_Lot_Number__c=serialLotNumber );
        return objLotNum;
    }

   /*
    *  @AUTHOR:  Dhairya Shah   
    *  @DESCRIPTION:This method creates Knowledge_kuv
    *  @PARAM :  String strName, String strCurrencyCode
    *  US - CMCM - 7910
    */
    public static Knowledge__kav createKnowledgekav(String prvName, String revStatus){
        Knowledge__kav know = new Knowledge__kav(Primary_Workflow__c = prvName, Secondary_Workflow__c = prvName,
        Review_Status__c = revStatus);
        return know;
    }
  
   /*
    *  @AUTHOR:  Dhairya Shah   
    *  @DESCRIPTION:This method creates Field_Action_Notification
    *  @PARAM :  String  strRecordTypeName, String strSubject, String strStatus
    */
    public static Field_Action_Notification__c createFANForTE (String  strRecordTypeName, String strSubject, String strStatus){

        Field_Action_Notification__c objFANForTE= new Field_Action_Notification__c(RecordTypeId = Schema.SObjectType.Field_Action_Notification__c.getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId(),
                                                                              Subject__c=strSubject, Status__c = strStatus);                                                                             
        return objFANForTE;
    }
  
    /*
    *  @AUTHOR:  Dhairya Shah   
    *  @DESCRIPTION:This method creates Code_Library
    *  @PARAM :  String  strName, String strCodeType
    */
    public static Code_Library__c createCodeLibraryRec (String  strName, String strCodeType){
        
        Code_Library__c objCodeLib= new Code_Library__c(Name = strName, Code_Type__c = strCodeType);                                                                             
        return objCodeLib;
    }
}