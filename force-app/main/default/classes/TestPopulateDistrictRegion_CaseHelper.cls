/**
 * @description       : To validate district and region updation on case record
 * @author            :Pooja
 * @last modified on  : 06-13-2022
**/
@isTest
public class TestPopulateDistrictRegion_CaseHelper {
    public static final string STRING_CASE_CATEGORY_ORDER = 'New Order';
    public static final string STRING_CASE_STATUS_IN_PROGRESS = 'In Progress';
    
    /**
    * @description : validate case field update based on web email
    **/
    static testmethod void populateCaseFieldsOnWebEmail(){
        Territory2 objTerritory = TestTerritoryPlanStrategyController.getTerritory();
        //Account objAcc = TestDataAccount.getNewAccount();
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        objAdminUser.email='test@gmail.com.invalid';
        update objAdminUser;
        //Create Account
        Account objAcc = TestDataAccount.getCustomerAccount();
        objAcc.BillingCountryCode = 'US';
        objAcc.Territory_Region__c = 'AMR';
        insert objAcc;
        
        System.runAs(objAdminUser)
        {
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTerritory.Id,objAcc.Id); 
            UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTerritory.Id,objAdminUser.id);
            insert objUTA;
        }

        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
        cs.Status = STRING_CASE_STATUS_IN_PROGRESS;
        cs.SuppliedEmail = 'test@gmail.com.invalid';
        cs.Closed_with_Associated_Codes__c = false;
        cs.origin=cases.STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS;
        cs.status=System.label.CaseStatusReopenedInProgress;
        cs.First_Call_Resolution__c=true;
        test.startTest();
       insert cs;
       test.stopTest();
       List<Case> lstCase=[SELECT id,Region__c,Contact.Account.Territory_Region__c FROM case LIMIT 1];
       system.assertEquals(lstCase[0].Region__c, objTerritory.Territory_Region__c, 'region updated');
        system.assertEquals(lstCase[0].ContactId,con.Id,'update contact field on case based on webEmail');
    }
}
