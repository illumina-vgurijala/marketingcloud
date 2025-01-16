/**
*    @author Roopal Verma
*    @date   2018-09-11
*    @description    DCP-9717: Prevent deletion on Consortium Account related to Consortium Opportunity
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ---------------------------------------------------------------------------------------------------------------------
*
*/
@isTest(isParallel=true)
public class TestConsortiumAccounts {
    static testMethod void consortiumAccountWithOppDelete()
    { 
        String strErrorMessage;
        Consortium__c con = TestDataConsortium.initConsortium('Open');
        insert con;
        
        Consortium__c con1 = TestDataConsortium.initConsortium('Open');
        insert con1;

        Account acc = TestDataAccount.getNewAccount();

        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Consortium__c = con.Id;
        opp.Type = 'Consortium';
        opp.Product_Interest__c = 'Consumables';
        update opp;

        Consortium_Account__c conAcc = TestDataConsortiumAccount.initConsortiumAccount(con,acc,false);
        insert conAcc;
        
        Consortium_Account__c conAcc1 = TestDataConsortiumAccount.initConsortiumAccount(con1,acc,false);
        insert conAcc1;

        Test.startTest();
        try {
            delete conAcc;
        } catch(Exception e) {
            System.debug('--Error--'+e.getMessage());
            strErrorMessage = e.getMessage();
        }

        System.assert(strErrorMessage.contains('Consortium Account cannot be deleted as Consortium is related to an opportunity'), 'Validation rule is not fired as expected.');
        
        delete conAcc1;        
        
        List<Consortium_Account__c> lstConAcc = [Select Id From Consortium_Account__c where Id = :conAcc1.Id];
        
        System.assert(lstConAcc.isEmpty(),'Consortium Account is not deleted');
        
        Test.stopTest();
    }

}