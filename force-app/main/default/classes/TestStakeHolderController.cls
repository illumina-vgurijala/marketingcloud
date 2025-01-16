/**
*    @author: Vaibhav Sirohi
*    @date:   30-AUg-2019
*    @description:  Test class for Controller class of StakeHolderController Component
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*            Satya Swain                  09 Dec 2022         Added Codescan fix for Variable Naming Convention           
*/
@isTest
public class TestStakeHolderController {
    /**
*  @author Vaibhav Sirohi
*  @description  
**/
    @isTest
    static void testGetStakeHolderData(){
        List<Key_Stakeholder_Analysis__c> lstStakeholder = new List<Key_Stakeholder_Analysis__c>();     
        Account acc = TestDataAccount.getNewAccount();
        Account acc1 = TestDataAccount.getNewAccount();
        acc1.ParentId = acc.Id;
        update acc1;
        
        Contact c= TestDataContact.getNewContact(acc);
        system.debug('contact -->'+c);
        Contact c1= TestDataContact.getNewContact(acc1);
        system.debug('contact -->'+c);
        AccountContactRelation acctcr = new AccountContactRelation(
            AccountId = acc1.id, 
            ContactId = c.id,
            Roles = 'Administrative: Other'
        );
        
        insert acctcr;
        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(acc1);
        TestDataAccountPlan.getNewAccountPlan(acc);
        // joshith to increase coverage
        Contact con=[select name from contact where id=:c.id];
        Key_Stakeholder_Analysis__c stakeholder = TestDataStakeholder.getNewStakehoder(acc1, ap, c1);
        lstStakeholder.add(stakeholder);
        update lstStakeholder;
        
        Test.startTest();
        StakeHolderController.getResults( ap.Id , '',0);
        System.assertEquals(false,StakeHolderController.getResults( ap.Id , '',0).isempty());
        //StakeHolderController.getAllContact(ap.Id, '');
        StakeHolderController.getAllContact(con.name,ap.Id,0);
         System.assertEquals(true,StakeHolderController.getAllContact(ap.Id,'',0).isempty());
        StakeHolderController.getAllStakeholderRecord(ap.Id);
          System.assertEquals(1,StakeHolderController.getAllStakeholderRecord(ap.Id).size());
       //StakeHolderController.removeStakeholerRecord(lstStakeholder);
        StakeHolderController.updateStakeholer(lstStakeholder);
        System.assertEquals(true,StakeHolderController.updateStakeholer(lstStakeholder));
        Test.stopTest();
        
    }
}