/*
 * Created By : Mukul Pandey
 * Date : 10/15/2023
 * Description : Covers AddAssociatedCodeController
 * CMCM-105
*/
@isTest(SeeAllData = false)
public class TestAddAssociatedCodes {
	public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_PRODUCT_INSTRUMENT = 'Instrument';
    public static final string CASE_ORIGIN_PHONECP  = 'Phone-CP';
    public static final string PRODUCT_REGULATORYTYPE_IUO = 'IUO';
    public static final string PRODUCT_SERIALNUMBER = 'IL02';
    public static final string CASE_SUBTYPE_ORDER = 'Order';
    
    /*
     * Method to validated the main controller class.
     */
    static testmethod void validateCode(){
        User usr1 = TestDataFieldService.createUser(System.label.Profile_Quality_Assurance,false);
        usr1.alias = 'TestUser';
        usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
        usr1.FederationIdentifier = 'Test234';
        insert new list<User> {usr1};
        List<Code_Library__c> lstCodeLib = new List<Code_Library__c>();
        Code_Library__c objCLParent = new Code_Library__c(Name='Test Hazard Code Parent',
        Code_type__c = 'Hazard', Case_Type__c = STRING_CASE_RECORDTYPENAME);
        insert objCLParent;
        Code_Library__c objCL = new Code_Library__c(Name='Test Hazard Code',
        Code_type__c = 'Hazard', Case_Type__c = STRING_CASE_RECORDTYPENAME,Parent_Code__c =objCLParent.id );
        lstCodeLib.add(objCL);
        Code_Library__c objCL1 = new Code_Library__c(Name='Additional Code',
        Code_type__c = 'Hazard', Case_Type__c =STRING_CASE_RECORDTYPENAME);
        lstCodeLib.add(objCL1);
        insert lstCodeLib;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        cs.Date_of_Issue_Awareness__c = Date.Today();
        cs.Hazard_Codes__c = 'Test Hazard Code';
        cs.status = Label.CaseStatusInitiated;
        insert cs;
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = objCL.Id;
        ac2.Case__c = cs.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        insert ac2;
        Case cs2 = TestDataCase.initServiceRequestCase(con);
        cs2.Status = 'In Progress';
        insert cs2;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs2.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        List<Case> caseRec = [SELECT Id from Case where Id=:cs.Id];
        system.assert(!caseRec.isEmpty(),'case created');
        AddAssociatedCodeController.getAssociatedCodesLwc(cs.Id,'Case');
        AddAssociatedCodeController.getAssociatedCodesLwc(workOrder.Id,'SVMXC__Service_Order__c');
        AddAssociatedCodeController.getCodeLibrary(ac2.Case_Type__c);
    }

    // Method to test getUserAndCodeLibraryTypeInfo
    static testmethod void testgetUserAndCodeLibraryTypeInfo(){ 
        Feature.setMockFeatureFlag('IVD_Workflow', true);
        String jsonOutput = AddAssociatedCodeController.getUserAndCodeLibraryTypeInfo(); 
        AddAssociatedCodeController.getIVDWorkflow();
        system.assertNotEquals('',jsonOutput,'Json returned must not be blank'); 
    } 
}