/**
*    @author Rishab Wali
*    @date   2020-08-17
*    @description  DCP-40087 Test Class for Pending Approval Requests Component Controller
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rishab Wali                 2020-08-17           Initial Version
*    Pravallika, Gundreddy        28-nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ------------------------------------------------------------------------------------                  
*/
@isTest
public class TestPendingApprovalRequestController {
    
    Public static FINAL String PRICELIST_01_AMEA_USD = '01-AMEA-USD'; //POL-57
    Public static FINAL String TEST_TXDR = 'Test TXDR';
    Public static FINAL String AUTHOR_CONTRACT = 'Author Contract';
    Public static FINAL String APPROVAL_REQUIRED = 'Approval Required';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string HK01 = 'HK01';
    public static FINAL string APTTUSAPTSAGREEMENTAPI = 'Apttus__APTS_Agreement__c';
    /*
    *@author: Rishab Wali
    *@Desc: Test method for check approval request controller
    */
    @isTest
    public static void checkApprovalRequestController()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';  
        acc2.BIllingCountryCode='HK' ;     
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        insert new List<Customer_Master_Data__c> {objCMD1};
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = PRICELIST_01_AMEA_USD; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';        
        acc1SalesArea.Sales_Organization__c=HK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
       

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Approval_Hierarchy__c objAppHierarchy = appHierarchy(UserInfo.getUserId(),UserInfo.getUserId(),UserInfo.getUserId(),UserInfo.getUserId(),UserInfo.getUserId(),UserInfo.getUserId());
        Approval_Hierarchy__c objAppHierarchy2 = appHierarchy(null,UserInfo.getUserId(),null,null,null,null);
        Approval_Hierarchy__c objAppHierarchy3 = appHierarchy(null,null,UserInfo.getUserId(),null,null,null);
        Approval_Hierarchy__c objAppHierarchy4 = appHierarchy(null,null,null,UserInfo.getUserId(),null,null);
        Approval_Hierarchy__c objAppHierarchy5 = appHierarchy(null,null,null,null,UserInfo.getUserId(),null);
        Approval_Hierarchy__c objAppHierarchy6 = appHierarchy(null,null,null,null,null,UserInfo.getUserId());
        insert new List<Approval_Hierarchy__c>{objAppHierarchy,objAppHierarchy2,objAppHierarchy3,objAppHierarchy4,objAppHierarchy5,objAppHierarchy6};

        Apttus__APTS_Agreement__c oAgreement1 = createAgreement(objAppHierarchy.Id,recTypeId,acc.Id);
        Apttus__APTS_Agreement__c oAgreement2 = createAgreement(objAppHierarchy2.Id,recTypeId,acc.Id);
        Apttus__APTS_Agreement__c oAgreement3 = createAgreement(objAppHierarchy3.Id,recTypeId,acc.Id);
        Apttus__APTS_Agreement__c oAgreement4 = createAgreement(objAppHierarchy4.Id,recTypeId,acc.Id);
        Apttus__APTS_Agreement__c oAgreement5 = createAgreement(objAppHierarchy5.Id,recTypeId,acc.Id);
        Apttus__APTS_Agreement__c oAgreement6 = createAgreement(objAppHierarchy6.Id,recTypeId,acc.Id);
        insert new List<Apttus__APTS_Agreement__c>{oAgreement1,oAgreement2,oAgreement3,oAgreement4,oAgreement5,oAgreement6};
        
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI1.Material_Number__c = VC0013519_OPA;
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Material';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 50;
        oAgreementLI1.Customer_ERP_Number__c = '123456';
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= 'USD';
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+5;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+28;
        oAgreementLI1.Apttus_Approval__Approval_Status__c = 'Approval Required';
		oAgreementLI1.Approval_Level_RO_Discount__c = 3;
        insert oAgreementLI1;
        
        Apttus_Approval__Approval_Request__c appReq = createApprovalRequest(oAgreement1.Id);
        Apttus_Approval__Approval_Request__c appReq2 = createApprovalRequest(oAgreement2.Id);
        Apttus_Approval__Approval_Request__c appReq3 = createApprovalRequest(oAgreement3.Id);
        Apttus_Approval__Approval_Request__c appReq4 = createApprovalRequest(oAgreement4.Id);
        Apttus_Approval__Approval_Request__c appReq5 = createApprovalRequest(oAgreement5.Id);
        Apttus_Approval__Approval_Request__c appReq6 = createApprovalRequest(oAgreement6.Id);
        List<Apttus_Approval__Approval_Request__c> lstAppReq = new List<Apttus_Approval__Approval_Request__c>();
        lstAppReq.addall(new List<Apttus_Approval__Approval_Request__c>{appReq,appReq2,appReq3,appReq4,appReq5,appReq6});
        insert lstAppReq;
        
        PendingApprovalRequestController.DataWrapper dwrapApprove = new PendingApprovalRequestController.DataWrapper();
        dwrapApprove.comments = 'Test Comment Approve';
        dwrapApprove.appReqId = appReq.Id;
        String dataWrapApprove = JSON.serialize(new List<PendingApprovalRequestController.DataWrapper> {dwrapApprove});

        PendingApprovalRequestController.DataWrapper dwrapReject = new PendingApprovalRequestController.DataWrapper();
        dwrapReject.comments = 'Test Comment Reject';
        dwrapReject.appReqId = appReq2.Id;
        String dataWrapReject = JSON.serialize(new List<PendingApprovalRequestController.DataWrapper> {dwrapReject});

        Map<Id,String> idToNameMap = new Map<Id,String>();
        idToNameMap.put(oAgreement1.Id,'Rishab Wali');
        test.startTest();
        PendingApprovalRequestController.getPendingApprovals(APTTUSAPTSAGREEMENTAPI);
        PendingApprovalRequestController.createWrapper(lstAppReq,idToNameMap);
        PendingApprovalRequestController.getRequestForApproveReject(dataWrapApprove,'approve');
        PendingApprovalRequestController.getRequestForApproveReject(dataWrapReject,'reject');
        test.stopTest();
        System.assertEquals('1',appReq.Apttus_Approval__Sequence__c);
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method to check no approval requests
    */
    @isTest
    public static void checkNoApprovalRequests()
    {
        test.startTest();
        PendingApprovalRequestController.getPendingApprovals(APTTUSAPTSAGREEMENTAPI);
        test.stopTest();
        System.assertEquals(null,PendingApprovalRequestController.getPendingApprovals(APTTUSAPTSAGREEMENTAPI));
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method to check for thrown exception
    */
    @isTest
    public static void checkThrowException()
    {
        test.startTest();
        PendingApprovalRequestController.getPendingApprovals(null);
        test.stopTest();
        System.assertEquals(null,PendingApprovalRequestController.getPendingApprovals(APTTUSAPTSAGREEMENTAPI));
    }
    
    private static Apttus__APTS_Agreement__c createAgreement(Id objAppHierarchyId,Id recTypeId,Id accId)
    {
        Apttus__APTS_Agreement__c objAgreement = TestDataAgreement.initAgreements('Test Agreement - One', accId);
        objAgreement.Sales_Org__c ='HK01';
        objAgreement.RecordTypeId = recTypeId;
        objAgreement.Apttus__Auto_Renewal__c=True;
        objAgreement.Apttus__Status_Category__c ='Pending Approval';
        objAgreement.Apttus__Status__c = AUTHOR_CONTRACT;
        objAgreement.Apttus_Approval__Approval_Status__c =APPROVAL_REQUIRED;
        objAgreement.Validation_Status__c ='None';
        objAgreement.Approval_Hierarchy_Discount__c = objAppHierarchyId;
        return objAgreement;
    }
    
    private static Approval_Hierarchy__c appHierarchy(String level1,String level2,String level3,String level4,String level5,String level6)
    {
        Approval_Hierarchy__c objApprovalHeirarchy = new Approval_Hierarchy__c(Name = 'Test Hierarchy',
                                                                               Approver_Level_1__c = Level1,
                                                                               Approver_Level_2__c = Level2,
                                                                               Approver_Level_3__c = Level3,
                                                                               Approver_Level_4__c = Level4,
                                                                               Approver_Level_5__c = Level5,
                                                                               Approver_Level_6__c = Level6,
                                                                               Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy');
        return objApprovalHeirarchy;
    }
    
    private static Apttus_Approval__Approval_Request__c createApprovalRequest(Id objAgreementId)
    {
        Apttus_Approval__Approval_Request__c objApprovalRequest = new Apttus_Approval__Approval_Request__c();
        objApprovalRequest.Apttus_Approval__Sequence__c = '1';
        objApprovalRequest.Apttus_Approval__Assigned_To_Id__c = UserInfo.getUserId();
        objApprovalRequest.Apttus_Approval__Step_Name__c = 'test';
        objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = UserInfo.getUserName();
        objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        objApprovalRequest.Apttus_Approval__Assigned_To_Type__c = 'User';
        objApprovalRequest.Apttus_Approval__Related_Agreement__c = objAgreementId;
        objApprovalRequest.Apttus_Approval__Object_Type__c = APTTUSAPTSAGREEMENTAPI;
        objApprovalRequest.Apttus_Approval__StepSequence__c = 1.1;
        return objApprovalRequest;
    }
}