/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

@IsTest
private with sharing class ilib_SObjectUnitOfWorkTest
{
    // SObjects (in order of dependency) used by UnitOfWork in tests bellow
    private final static List<Schema.SObjectType> MY_SOBJECTS =
            new Schema.SObjectType[] {
                    Product2.SObjectType,
                    PricebookEntry.SObjectType,
                    Opportunity.SObjectType,
                    OpportunityLineItem.SObjectType };

    private static Integer testOpportunityCount = 5; // TODO: was 10
    /**
     * @actor illumina
     * @description :-
     */
    @testSetup
    /**
    * 
    *
    * @desc loadProducts [codescan fix]
    */
    public static void loadProducts(){
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(MY_SOBJECTS);
        Product2 product = TestDataMaster.initProduct('COOKIE');
        uow.registerNew(new List<SObject>{product});
        PricebookEntry pbe = TestDataMaster.initStandardPrice(null, 10, '');
        uow.registerNew(pbe, PricebookEntry.Product2Id, product);
        product = TestDataMaster.initProduct('BROWNIE');
        uow.registerNew(new List<SObject>{product});
        pbe = TestDataMaster.initStandardPrice(null, 10, '');
        uow.registerNew(pbe, PricebookEntry.Product2Id, product);
        uow.commitWork();
    }

    @isTest
    private static void registerEmail()
    {
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(MY_SOBJECTS);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String> {'Jay.Flatley@illumina.com'} );
        mail.setReplyTo('donotreply@illumina.com');
        mail.setSenderDisplayName('Unit Test');
        mail.setSubject('Test Email');
        mail.setBccSender(false);
        mail.setPlainTextBody('Your Email has been sent');

        uow.registerEmail(mail);
    }

    @isTest
    private static void testUnitOfWorkNewDirtyDelete()
    {
        Account a = TestDataAccount.getNewPartnerAccount(Accounts.GROUP_SOLD_TO); // restore
        PricebookEntry pbeCookie,pbeBrownie;
        for(PricebookEntry pbe : [SELECT ID,Name,Product2.Name FROM PricebookEntry LIMIT 1000])
            if('COOKIE'.equals(pbe.Product2.Name))
                pbeCookie = pbe;
            else if('BROWNIE'.equals(pbe.Product2.Name))
                pbeBrownie = pbe;    
        System.debug('pbeCookie: ' + pbeCookie);
        System.debug('pbeBrownie: ' + pbeBrownie);
        // Insert Opporunities with UnitOfWork
        {
            ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(MY_SOBJECTS);
            for (Integer o = 0; o < testOpportunityCount; o++)
            {
                Opportunity opp = TestDataOpportunity.initOpportunity(a);
                opp.Name = 'UoW Test Name ' + o;
                opp.CloseDate = System.today();
                uow.registerNew(new List<SObject>{opp});

                for (Integer i = 0; i< o + 1 ; i++)
                {
                    OpportunityLineItem oppLineItem = TestDataOpportunity.initOpportunityLineItem(null, null, 1, 10);
                    uow.registerRelationship(oppLineItem, OpportunityLineItem.PricebookEntryId, pbeCookie);
                    uow.registerNew(oppLineItem, OpportunityLineItem.OpportunityId, opp);
                }
            }
            uow.commitWork();
        }
		
		Test.StartTest();

        // Assert Results
        assertResults('UoW');
        // TODO: Need to re-instate this check with a better approach, as it is not possible when
        //       product triggers contribute to DML (e.g. in sample app Opportunity trigger)
        // System.assertEquals(5 /* Oddly a setSavePoint consumes a DML */, Limits.getDmlStatements());

        // Records to update
        List<Opportunity> opps = [select Id, Name, (Select Id,PricebookEntry.Product2.Name from OpportunityLineItems)
        from Opportunity where Name like 'UoW Test Name %' order by Name];

        // Update some records with UnitOfWork
        {
            ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(MY_SOBJECTS);
            Opportunity opp = opps[0];
            opp.Name = opp.Name + ' Changed';
            uow.registerDirty(new List<SObject>{opp});
            OpportunityLineItem newOppLineItem = TestDataOpportunity.initOpportunityLineItem(null, null, 1, 10);
            uow.registerRelationship(newOppLineItem, OpportunityLineItem.PricebookEntryId, pbeBrownie);
            uow.registerNew(newOppLineItem, OpportunityLineItem.OpportunityId, opp);
            OpportunityLineItem existingOppLine = opp.OpportunityLineItems[0];
            System.debug('existingOppLine: ' + existingOppLine);
            // Test that operations on the same object can be daisy chained, and the same object registered as dirty more than once
            // This verifies that using a Map to back the dirty records collection prevents duplicate registration.
            existingOppLine.Quantity = 2;
            uow.registerDirty(new List<SObject>{existingOppLine});
            existingOppLine.TotalPrice = 20;
            uow.registerDirty(new List<SObject>{existingOppLine});
            uow.commitWork();
        }

        // Assert Results
        // TODO: Need to re-instate this check with a better approach, as it is not possible when
        //       product triggers contribute to DML (e.g. in sample app Opportunity trigger)
        // System.assertEquals(11, Limits.getDmlStatements());
        opps = [select Id, Name, (Select Id, PricebookEntry.Product2.Name, Quantity, TotalPrice
        from OpportunityLineItems Order By PricebookEntry.Product2.Name)
        from Opportunity where Name like 'UoW Test Name %' order by Name ];
        System.assertEquals(testOpportunityCount, opps.size());
        System.assertEquals('UoW Test Name 0 Changed', opps[0].Name);
        System.assertEquals(2, opps[0].OpportunityLineItems.size());
        // Verify that both fields were updated properly
        System.assertEquals('COOKIE', opps[0].OpportunityLineItems[1].PricebookEntry.Product2.Name);
        System.assertEquals(2, opps[0].OpportunityLineItems[1].Quantity);
        System.assertEquals(20, opps[0].OpportunityLineItems[1].TotalPrice);
        System.assertEquals('BROWNIE', opps[0].OpportunityLineItems[0].PricebookEntry.Product2.Name);

        // Delete some records with the UnitOfWork
        {
            ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(MY_SOBJECTS);
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0].PricebookEntry.Product2}); // Delete PricebookEntry Product
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0].PricebookEntry}); // Delete PricebookEntry
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0]}); // Delete OpportunityLine Item
            // Register the same deletions more than once.
            // This verifies that using a Map to back the deleted records collection prevents duplicate registration.
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0].PricebookEntry.Product2}); // Delete PricebookEntry Product
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0].PricebookEntry}); // Delete PricebookEntry
            uow.registerDeleted(new List<SObject>{opps[0].OpportunityLineItems[0]}); // Delete OpportunityLine Item
            uow.commitWork();
        }
        // Assert Results
        // TODO: Need to re-instate this check with a better approach, as it is not possible when
        //       product triggers contribute to DML (e.g. in sample app Opportunity trigger)
        // System.assertEquals(15, Limits.getDmlStatements());
        opps = [select Id, Name, (Select Id, PricebookEntry.Product2.Name, Quantity from OpportunityLineItems Order By PricebookEntry.Product2.Name) from Opportunity where Name like 'UoW Test Name %' order by Name];
        List<Product2> prods = [Select Id from Product2 where Name = 'BROWNIE'];
        System.assertEquals(testOpportunityCount, opps.size());
        System.assertEquals('UoW Test Name 0 Changed', opps[0].Name);
        System.assertEquals(1, opps[0].OpportunityLineItems.size()); // Should have deleted OpportunityLineItem added above
        System.assertEquals(0, prods.size()); // Should have deleted Product added above
    }

    private static void assertResults(String prefix)
    {
        // Standard Assertions on tests data inserted by tests
        String filter = prefix + ' Test Name %';
        List<Opportunity> opps = [select Id, Name, (Select Id from OpportunityLineItems) from Opportunity where Name like :filter order by Name];
        System.assertEquals(testOpportunityCount, opps.size());

        for (Integer i = 0; i< testOpportunityCount; i++)
            System.assertEquals(i + 1, opps[i].OpportunityLineItems.size());
    }

    /**
     * Create uow with new records and commit
     *
     *  Testing:
     *
     *      - Correct events are fired when commitWork completes successfully
     *
     */
    @isTest
    private static void testDerivedUnitOfWorkCommitSuccess()
    {
        Account a = TestDataAccount.getNewPartnerAccount(Accounts.GROUP_SOLD_TO); // restore

        // Insert Opportunities with UnitOfWork
        DerivedUnitOfWork uow = new DerivedUnitOfWork(MY_SOBJECTS);

        for (Integer o = 0; o < testOpportunityCount; o++)
        {
            Opportunity opp = TestDataOpportunity.initOpportunity(a);
            opp.Name = 'UoW Test Name ' + o;
            opp.CloseDate = System.today();
            uow.registerNew(opp);

            for (Integer i=0; i<o+1; i++)
            {
                Product2 product = TestDataMaster.initProduct('COOKIE' + o + '-' + i);
                uow.registerNew(new List<SObject>{product});
                PricebookEntry pbe = TestDataMaster.initStandardPrice(null, 10, '');
                uow.registerNew(pbe, PricebookEntry.Product2Id, product);
                OpportunityLineItem oppLineItem = TestDataOpportunity.initOpportunityLineItem(null, null, 1, 10);
                uow.registerRelationship(oppLineItem, OpportunityLineItem.PricebookEntryId, pbe);
                uow.registerNew(oppLineItem, OpportunityLineItem.OpportunityId, opp);
            }
        }
        uow.commitWork();

        String filter = 'UoW Test Name %';
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity WHERE Name LIKE :filter];
        System.assertEquals(5, opps.size(), '5 Opportunities should be created');

        // Assert Results
        assertResults('UoW');

        assertEvents(new List<String> {
                'onCommitWorkStarting'
                , 'onDMLStarting'
                , 'onDMLFinished'
                , 'onDoWorkStarting'
                , 'onDoWorkFinished'
                , 'onCommitWorkFinishing'
                , 'onCommitWorkFinished - true'
        }
                , uow.getCommitWorkEventsFired(), new Set<Schema.SObjectType>(MY_SOBJECTS), uow.getRegisteredTypes());
        
    }

    /**
     * Create uow with data that results in DML Exception
     *
     *  Testing:
     *
     *      - Correct events are fired when commitWork fails during DML processing
     *
     */
    @isTest
    private static void testDerivedUnitOfWorkCommitDMLFail()
    {
        // Insert Opporunities with UnitOfWork forcing a failure on DML by not setting 'Name' field
        DerivedUnitOfWork uow = new DerivedUnitOfWork(MY_SOBJECTS);
        Account a = TestDataAccount.getNewPartnerAccount(Accounts.GROUP_SOLD_TO); // restore
        Opportunity opp = TestDataOpportunity.initOpportunity(a);
        opp.Name = '';
        uow.registerNew(new List<SObject>{opp});
        Boolean didFail = false;
        System.DmlException caughtEx = null;

        try {
            uow.commitWork();
        }
        catch (System.DmlException dmlex) {
            didFail = true;
            caughtEx = dmlex;
        }

        // Assert Results
        System.assertEquals(true, didFail, 'didFail');
        System.assert(caughtEx.getMessage().contains('REQUIRED_FIELD_MISSING'), String.format('Exception message was ', new List<String> { caughtEx.getMessage() }));

        assertEvents(new List<String> {
                'onCommitWorkStarting'
                , 'onDMLStarting'
                , 'onCommitWorkFinished - false'
        }
                , uow.getCommitWorkEventsFired(), new Set<Schema.SObjectType>(MY_SOBJECTS), uow.getRegisteredTypes());
    }

    /**
     * Create uow with work that fails
     *
     *  Testing:
     *
     *      - Correct events are fired when commitWork fails during DoWork processing
     *
     */
    @isTest
    private static void testDerivedUnitOfWorkCommitDoWorkFail()
    {
        // Insert Opporunities with UnitOfWork
        DerivedUnitOfWork uow = new DerivedUnitOfWork(MY_SOBJECTS);
        Account a = TestDataAccount.getNewPartnerAccount(Accounts.GROUP_SOLD_TO); // restore
        Opportunity opp = TestDataOpportunity.initOpportunity(a);
        opp.Name = 'UoW Test Name 1';
        opp.CloseDate = System.today();
        uow.registerNew(new List<SObject>{opp});

        // register work that will fail during processing
        FailDoingWork fdw = new FailDoingWork();
        uow.registerWork(fdw);

        Boolean didFail = false;
        FailDoingWorkException caughtEx = null;

        try {
            uow.commitWork();
        }
        catch (FailDoingWorkException fdwe) {
            didFail = true;
            caughtEx = fdwe;
        }

        // Assert Results
        System.assert(didFail, 'Insert Failed OR not ?');
        System.assert(caughtEx.getMessage().contains('Work failed.'), String.format('Exception message was ', new List<String> { caughtEx.getMessage() }));

        assertEvents(new List<String> {
                'onCommitWorkStarting'
                , 'onDMLStarting'
                , 'onDMLFinished'
                , 'onDoWorkStarting'
                , 'onCommitWorkFinished - false'
        }
                , uow.getCommitWorkEventsFired(), new Set<Schema.SObjectType>(MY_SOBJECTS), uow.getRegisteredTypes());
    }

    /**
     * Assert that actual events exactly match expected events (size, order and name)
     * and types match expected types
     */
    private static void assertEvents(List<String> expectedEvents, List<String> actualEvents, Set<Schema.SObjectType> expectedTypes, Set<Schema.SObjectType> actualTypes)
    {
        // assert that events match
        System.assertEquals(expectedEvents.size(), actualEvents.size(), 'events size');
        for (Integer i = 0; i < expectedEvents.size(); i++)
        {
            System.assertEquals(expectedEvents[i], actualEvents[i], String.format('Event {0} was not fired in order expected.', new List<String> { expectedEvents[i] }));
        }

        // assert that types match
        System.assertEquals(expectedTypes.size(), actualTypes.size(), 'types size');
        for (Schema.SObjectType sObjectType :expectedTypes)
        {
            System.assertEquals(true, actualTypes.contains(sObjectType), String.format('Type {0} was not registered.', new List<String> { sObjectType.getDescribe().getName() }));
        }
    }

    /**
     * DoWork implementation that throws exception during processing
     */
    private class FailDoingWork implements ilib_SObjectUnitOfWork.IDoWork
    {
        /**
     * @actor illumina
     * @description :-
     */
        public void doWork()
        {
            throw new FailDoingWorkException('Work failed.');
        }
    }

    /**
     * Derived unit of work that tracks event notifications and handle registration of type
     */
    private class DerivedUnitOfWork extends ilib_SObjectUnitOfWork
    {
        private List<String> mcommitWorkEventsFired = new List<String>();
        private Set<Schema.SObjectType> mregisteredTypes = new Set<Schema.SObjectType>();
       /**
     * @actor illumina
     * @description :-
     */ 
        public List<String> getCommitWorkEventsFired()
        {
            return mcommitWorkEventsFired.clone();
        }
        /**
     * @actor illumina
     * @description :-
     */
        public Set<Schema.SObjectType> getRegisteredTypes()
        {
            return mregisteredTypes.clone();
        }
        /**
     * @actor illumina
     * @description :-
     */
        public DerivedUnitOfWork(List<Schema.SObjectType> sObjectTypes)
        {
            super(sObjectTypes);
        }
        /**
     * @actor illumina
     * @description :-
     */
        public DerivedUnitOfWork(List<Schema.SObjectType> sObjectTypes, IDML dml)
        {
            super(sObjectTypes, dml);
        }

        private void addEvent(String event)
        {
            // events should only be fired one time
            // ensure that this event has not been fired already
            for (String eventName :mcommitWorkEventsFired)
            {
                if (event == eventName)
                {
                    throw new DerivedUnitOfWorkException(String.format('Event {0} has already been fired.', new List<String> { event }));
                }
            }
            mcommitWorkEventsFired.add(event);
        }
        /**
     * @actor illumina
     * @description :-
     */
        public override void onRegisterType(Schema.SObjectType sObjectType)
        {
            if (mregisteredTypes.contains(sObjectType))
            {
                throw new DerivedUnitOfWorkException(String.format('Type {0} has already been registered.', new List<String> { sObjectType.getDescribe().getName() }));
            }
            mregisteredTypes.add(sObjectType);
        }
        /**
     * @actor illumina
     * @description :-
     */
        public override void onCommitWorkStarting()
        {
            addEvent('onCommitWorkStarting');
        }
        /**
     * @actor illumina
     * @description :-
     */
        public override void onDMLStarting()
        {
            addEvent('onDMLStarting');
        }
    /**
     * @actor illumina
     * @description :-
     */
        public override void onDMLFinished()
        {
            addEvent('onDMLFinished');
        }
        /**
     * @actor illumina
     * @description :-
     */
        public override void onDoWorkStarting()
        {
            addEvent('onDoWorkStarting');
        }
        /**
     * @actor illumina
     * @description :-
     */
        public override void onDoWorkFinished()
        {
            addEvent('onDoWorkFinished');
        }
    /**
     * @actor illumina
     * @description :-
     */
        public override void onCommitWorkFinishing()
        {
            addEvent('onCommitWorkFinishing');
        }
    /**
     * @actor illumina
     * @description :-
     */
        public override void onCommitWorkFinished(Boolean wasSuccessful)
        {
            addEvent('onCommitWorkFinished - ' + wasSuccessful);
        }
    }
    /**
     * @actor illumina
     * @description :-
     */
    public class DerivedUnitOfWorkException extends Exception {}
    /**
     * @actor illumina
     * @description :-
     */
    public class FailDoingWorkException extends Exception {}

}