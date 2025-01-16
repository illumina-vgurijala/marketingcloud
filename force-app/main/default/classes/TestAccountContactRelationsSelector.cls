/**
 *    @author Prashanth
 *    @date   10-Sep-2020
 *    @description: Test class for AccountContactRelationsSelector   
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Prashanth Kumar              10-Sep-2020          Original version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
@istest 
public class TestAccountContactRelationsSelector {
    /**
    *  @description Test class for AccountContactRelationsSelector methods.
    * 
    **/
   @istest
   static void testAll(){
        Account account1 = TestDataAccount.getCustomerAccount();
        insert account1;
        System.assert(account1.Id != null);
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert con1;
        System.assert(con1.Id != null);
        con1 = [Select Id,Name from Contact where id=:con1.Id];
        Test.startTest();
        new AccountContactRelationsSelector().getAcountContactRelationOfAccount('test1','test2',con1.Name, new Set<Id>{con1.Id},0);
        new AccountContactRelationsSelector().getAcountContactRelationOfAccount(null,'test2',con1.Name, new Set<Id>{con1.Id},0);
        new AccountContactRelationsSelector().getAccountContactRelationByAccount(new Set<Id>{account1.Id});
        new AccountContactRelationsSelector().getDirectAccConRelationByContact(new Set<Id>{con1.Id});
        List<AccountContactRelation> lstACR= new AccountContactRelationsSelector().getAccConRelationByContact(new Set<Id>{con1.Id});
        System.assert(lstACR != null);
        List<AccountContactRelation> lstACRCON = new AccountContactRelationsSelector().getAccountContactRelationByContactId(new Set<Id>{con1.id});
        System.assert(lstACRCON!= null);
        Test.stopTest();
   }
   
   @IsTest
    static void testGetAccountContactRelactionByAccountIdAndContactId() {
          //creation of account
          Account account1 = TestDataAccount.getCustomerAccount();
          insert account1;
          //creation of contacts
          Contact con1 =TestDataPerson.initContact(account1.Id);
          insert con1;
          con1 = [Select Id,Name from Contact where id=:con1.Id];
          Test.startTest();
          List<AccountContactRelation> acr = new AccountContactRelationsSelector().getAccountContactRelactionByAccountIdAndContactId(new Set<Id>{account1.Id}, new List<Id>{con1.Id});
          Test.stopTest();
          System.assertEquals(1, acr.size(), 'Should return one AccountContactRelation record');
          for (AccountContactRelation relation : acr) {
               System.assertEquals(true, relation.IsActive, 'IsActive should be true');
               System.assertNotEquals(null, relation.AccountId, 'AccountId should not be null');
               System.assertNotEquals(null, relation.ContactId, 'ContactId should not be null');
          }
    }
}