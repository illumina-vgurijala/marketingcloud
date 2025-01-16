/**
*    @author Bharath Kumar
*    @date   15 Oct 2018
*    @description  Test class for CasesSelector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Bharath Kumar          15 Oct 2018          DCP-25279 : Test class for CasesSelector class
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData = false)  
public with sharing class TestCasesSelector {

    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_EVALUATION_ANSWER_NO = 'No';
    public static final string STRING_EVALUATION_ANSWER_YES = 'YES';
    public static final string STRING_EVALUATION_ANSWER_PENDING='Pending';
    public static final string STRING_CASE_SUB_TYPE = 'Complaint';
    public static final string STRING_CASE_CATEGORY = 'Install';
    public static final string STRING_CASE_STATUS_CLOSED = 'Closed';
    public static final string STRING_CASE_RECORDTYPENAME_INQUIRY = 'Inquiry';

/**
    *  @author Bharath Kumar
    *  @description - DCP-25279 test the part order status update when updated by Non-CS User containing instrument type part order lines
    **/
    static testMethod void testmethodCaseSelector(){
        Account objAccount = TestDataAccount.getAccount('Test Account 1', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        objAccount.Clinical_Type__c = 'Clinical';
        insert objAccount;
        Test.startTest();
        Contact con = TestDataContact.getNewContact(objAccount);
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert objServiceContract;
        
        //SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: objServiceContract.Id];

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;

        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);

        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);

        List<Case> csList = new List<Case>();
        Case objCase = TestDataCase.initServiceRequestCase(con);
        csList.add(objCase);

        Case objRecallCase = TestDataCase.initServiceRequestCase(con);
        objRecallCase.Recall__c = true;
        csList.add(objRecallCase);
        insert csList;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service',objCase.id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;

        set<Id> workOrderIdSet = new set<Id>();
        workOrderIdSet.add(workOrder.id);
        set<Id> caseIdSet = new set<Id>();
        caseIdSet.add(objCase.id);
        set<string> caseNumberSet = new set<string>();
        caseNumberSet.add(objCase.casenumber);
        CasesSelector cse= new CasesSelector();
        cse.selectOpenCases(caseIdSet);
        cse.selectCases(caseIdSet);
        cse.selectCasesWithAdditionalProduct(caseIdSet);
        cse.selectCaseForCaseNumber(caseNumberSet);
        cse.selectCasesFromSetIds(caseIdSet);
        cse.selectCasesWithServiceBOM(caseIdSet);
        cse.selectCasesWithRegion(caseIdSet);
       /* DCP-51725 start */
          Set<String> setFields = new Set<String>(); 
          setFields.add('Id') ;
          cse.selectCasesWithDynamicFieldsAndCondition(null,null,setFields,null,'Id!=null',null,null); 
         /* DCP-51725 End */
        //DCP-25229
        List<Case> lstBICase = cse.selectCasesByRecordType(new Set<Id>{objCase.Id}, 'Business Issue');
        //list will be empty since, we have inserted case with different record type.
        System.assertEquals(0,lstBICase.size());
                      
        //test selectCasesRelatedtoIP
        List<Case> lstBICase2 = cse.selectCasesRelatedtoIP(caseIdSet);
        system.assertEquals(0,lstBICase2.size());
        
        //test selectCaseByCaseId 
        Case lstBICase3 = cse.selectCaseByCaseId(objCase.id);
        System.assertNotEquals(null,lstBICase3.id);
        
        //test selectCasesByCaseIdSet
        List<Case> lstBICase4 = cse.selectCasesByCaseIdSet(caseIdSet);
        system.assertEquals(0,lstBICase4.size());
        
        //test selectCasesByCaseIdSetForQualtrics
        List<Case> lstBICase5 = cse.selectCasesByCaseIdSetForQualtrics(caseIdSet);
        system.assertEquals(1,lstBICase5.size());

        //test selectCasesByCaseId 
        List<Case> lstBICase6 = cse.selectCasesByCaseId(objCase.id);
        System.assertNotEquals(0,lstBICase6.size());
        
        //test selectAccountByCaseId 
        List<Case> lstBICase7 = cse.selectAccountByCaseId(objCase.id);
        System.assertNotEquals(0,lstBICase7.size());
        
        //test fetchCaseWithNullIPIds
        List<Case> caseList = cse.fetchCaseWithNullIPIds(new Set<Id>{objCase.id});
        System.assertNotEquals(0,caseList.size());

        //test selectCasesByCaseIdSetForQualtrics
        List<Case> lstCase = cse.selectCasesWithCaseID(caseIdSet);
        system.assertEquals(1,lstCase.size());

        //test selectCasesForRecall
        //List<Case> lstRecallCase = cse.selectCasesForRecall(new Set<Id>{objRecallCase.Id});
        //system.assertEquals(1,lstRecallCase.size());

        //test selectRecallCasesByAccountId
        //List<Case> lstRecallByAccountCase = cse.selectRecallCasesByAccountId(objAccount.Id);
        //system.assertEquals(1,lstRecallByAccountCase.size());
        
        Test.stopTest(); 
    }
}