/*
* @Author
* @Date
* @Description  test class  ilib_ScheduleAndBatchTest
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Aman Tyagi            7th Oct 2022               Codescan Fixes
* Prem Ranjan           11th Jan 2023              Codescan Fixes
---------------------------------------------------------------------------------------------------------------------------------------                                                 
*/
@isTest private class ilib_ScheduleAndBatchTest {

    private final static String ACCOUNT_INITIAL_NAME = 'Mystery, Inc.';
    private final static String ACCOUNT_SCHEDULED_NAME = 'Mystery, Inc - scheduled';
    private final static String ACCOUNT_BATCHED_NAME = 'Mystery, Inc - batched';

    @TestSetup
    static void createSampleAccount()
    {
        Account a = TestDataAccount.getAccount(ACCOUNT_INITIAL_NAME);
        a.ERP_Customer_Id__c = '';
        insert a;
    }

    @IsTest
    static void scheduledUpdate()
    {
        SchedulableContext sc = null;
        Database.BatchableContext bc = null;
        JustSchedule scheduleOnlyClass = new JustSchedule();

        Test.startTest();
        scheduleOnlyClass.execute(sc);
        Test.stopTest();

        List<Account> afterJob = [SELECT Id, Name FROM Account LIMIT 1000];
        System.assertEquals(ACCOUNT_SCHEDULED_NAME, afterJob[0].Name);

        try
        {
            scheduleOnlyClass.start(bc);
            System.assert(false, 'Batchable start should be unsupported');
        }
        catch (Exception e)
        {
            ilib_LogEvent.message('Exception: ' + e.getMessage());
        }

        try
        {
            scheduleOnlyClass.execute(bc, null);
            System.assert(false, 'Batchable execute should be unsupported');
        }
        catch (Exception e)
        {
            ilib_LogEvent.message('Exception: ' + e.getMessage());
        }

        try
        {
            scheduleOnlyClass.finish(bc);
            System.assert(false, 'Batchable finish should be unsupported');
        }
        catch (Exception e)
        {
            ilib_LogEvent.message('Exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void batchedUpdate()
    {
        SchedulableContext sc = null;
        Database.BatchableContext bc = null;
        JustBatch batchOnlyClass = new JustBatch();

        Test.startTest();
        batchOnlyClass.start(bc);
        batchOnlyClass.execute(bc, [SELECT Id, Name FROM Account LIMIT 1000]);
        batchOnlyClass.finish(bc);
        Test.stopTest();

        List<Account> afterJob = [SELECT Id, Name FROM Account LIMIT 1000];
        System.assertEquals(ACCOUNT_BATCHED_NAME, afterJob[0].Name);

        try
        {
            batchOnlyClass.execute(sc);
            System.assert(false, 'Schedulable execute should be unsupported');
        }
        catch (Exception e)
        {
            ilib_LogEvent.message('Exception: ' + e.getMessage());
        }
    }

    /**
     * @author   
     * @description schedule class which is extending ilib_ScheduleAndBatch
     **/
    public class JustSchedule extends ilib_ScheduleAndBatch
    {
        /**
        * @author   
        * @description overriding the execute method of ilib_ScheduleAndBatch
        * @param SchedulableContext ctx
        * @return NA
        **/
        public override void execute(SchedulableContext ctx)
        {
            Account a = [SELECT Id, Name FROM Account WHERE Name = :ACCOUNT_INITIAL_NAME];
            a.Name = ACCOUNT_SCHEDULED_NAME;
            update a;
        }
    }

    /**
     * @author   
     * @description batch class which is extending ilib_ScheduleAndBatch
     **/
    public class JustBatch extends ilib_ScheduleAndBatch
    {
        // query all objects (accounts) tied to the current territory
        /**
        * @author   
        * @description overriding the start method of ilib_ScheduleAndBatch
        * @param Database.BatchableContext bc
        * @return Database.QueryLocator
        **/
        public override Database.QueryLocator start(Database.BatchableContext bc)
        {
            String soql = 'SELECT Id, Name FROM Account WHERE Name = :ACCOUNT_INITIAL_NAME';
            return Database.getQueryLocator(soql);
        }
        /**
        * @author   
        * @description overriding the execute method of ilib_ScheduleAndBatch
        * @param Database.BatchableContext bc, List<sObject> accountList
        * @return  NA
        **/
        public override void execute(Database.BatchableContext bc, List<sObject> accountList)
        {
            Account a = (Account)accountList[0];
            a.Name = ACCOUNT_BATCHED_NAME;
            update a;
        }

        /**
        * @author   
        * @description overriding the finish method of batch class ilib_ScheduleAndBatch
        * @param NA
        * @return  NA
        **/
        public override void finish(Database.BatchableContext bc) { }
    }

}