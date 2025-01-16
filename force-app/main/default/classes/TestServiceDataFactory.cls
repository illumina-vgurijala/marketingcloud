/***************************************************************************************************************************************
 * NAME   : TestServiceDataFactory
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
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false) 
public with sharing class TestServiceDataFactory {

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
    *  @DESCRIPTION:This method creates Account
    *  @PARAM :  String strName, String strCurrencyCode
    *  @RETURN:  Account type object
    */
    public static Account createAccount(String strName, String strCurrencyCode){
        Account objAccount = TestDataAccount.initPartnerAccount('TestAcc');
        objAccount.CurrencyIsoCode = strCurrencyCode;
        objAccount.BillingState = '';
        objAccount.BillingCountry = '';
        objAccount.Account_Group__c = 'Internal';
        insert objAccount;
        return objAccount;
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
        insert objIP;
        return objIP;
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
                            SVMXC__Order_Status__c = orderStatus
                                            );
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
    
    public static SVMXC__Service_Group_Members__c createTechnician (String userId,String technicianName,String serviceTeamId){
    
       SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(SVMXC__Salesforce_User__c = userId,
            Name = technicianName,SVMXC__Service_Group__c = serviceTeamId);
            
            return grpMembers;
    
    }

     /**
    *  @author Veerendra
    *  @description - Method to create Service Contract
    * params : Account id
    * return type : Service Contract instance
    **/
    public static SVMXC__Service_Contract__c createServiceContract(String accountId)
    {
        SVMXC__Service_Contract__c serviceContract = new SVMXC__Service_Contract__c(
                                            SVMXC__Company__c = accountId
                                            );
        return serviceContract;
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
                                            SVMXC__Installed_Product__c = installedProductId
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
}