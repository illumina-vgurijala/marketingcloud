/***************************************************************************************************************************************
 * NAME   : TestBatchUpdateIsUpdatedBySystemFlag
 * DESCRIPTION  : Test Class for BatchUpdateIsUpdatedBySystemFlag.
 *    
 * @AUTHOR : Nishan Shetty
 * @DATE   : 02-Sept-2022
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Nishan Shetty          02-Sept-2022          Initial
 * --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/ 
@isTest
public class TestBatchUpdateIsUpdatedBySystemFlag {
   
    @testSetup static void initializeTestData() {

        //Creating Account
        Account objAcc = TestDataAccount.getCustomerAccount();
        insert objAcc;

        //Creating Opportunity
        Opportunity objOpp = TestDataOpportunity.initOpportunity(objAcc);
        objOpp.Name='BatchUpdateOppIsUpdatedBySystemFlagOpp';
        insert objOpp;
    }
   
    /**
    *    @author Nishan Shetty
    *    @date   02-Sept-2022
    *    @description    Testing whether IsUpdatedBySystem Flag on Opportunity is set to false.
    */
    @isTest
    static void testIsUpdatedBySystemFlag() {
       Opportunity opp =[Select Id,Is_Updated_By_System__c from Opportunity where Name='BatchUpdateOppIsUpdatedBySystemFlagOpp' LIMIT 1];
       Test.startTest();
       opp.Is_Updated_By_System__c=true;
       update opp;
       BatchUpdateIsUpdatedBySystemFlag batInstance = new BatchUpdateIsUpdatedBySystemFlag();
       batInstance.finish(null);
       BatchUpdateIsUpdatedBySystemFlag batchInstance = new BatchUpdateIsUpdatedBySystemFlag(BatchUpdateIsUpdatedBySystemFlag.STRING_OPPORTUNITY,200);
       batchInstance.execute(null,new List<SObject>{(SObject)opp});
       String serializedString = batchInstance.serializeInputs();
       batchInstance.restoreInputs(serializedString);
       batchInstance.getDefaultBatchSize();
       Database.executeBatch(batchInstance,200);
       Test.stopTest();
       opp = [Select Id,Is_Updated_By_System__c from Opportunity where Name='BatchUpdateOppIsUpdatedBySystemFlagOpp' LIMIT 1];
       System.assert(!opp.Is_Updated_By_System__c,'IsUpdatedBySystem Flag on Opportunity is not set correctly via batch update......');
    }
}
