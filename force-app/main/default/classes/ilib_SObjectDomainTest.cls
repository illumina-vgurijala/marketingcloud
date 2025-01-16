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
private with sharing class ilib_SObjectDomainTest
{

    @IsTest
    private static void runTriggerByObject()
    {
        // NOTE: have to jump into real functionality with this test
        // I couldn't figure out how to access the static context where bypass is calculated
        // the other tests in this class skip that and call methods directly on an instantiated trigger handler

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Lead',
            Bypass_Triggers_By_Object_3__c = 'Account'
        );
        insert apexSettings;

        Set<String> objectsToBypass = (new ilib_SObjectDomain.TriggerEvent()).getObjectsToBypass(apexSettings);
        System.debug('TTN objectsToBypass ' + objectsToBypass);
        System.assert(!objectsToBypass.contains('Opportunity'), 'Opportunity trigger configured to bypass');

        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

        Account a = TestDataAccount.initAccount();
        a.Account_Group__c = Label.AccountGroupDistributor;
        a.Channel_Partner_Type__c = 'Aggregator';
        insert a;

        Opportunity o = TestDataOpportunity.initOpportunity(a);
        o.RecordTypeId = rts.get(Label.OpportunityRTIndirectStandard).getRecordTypeId();
        insert o;

        Opportunity affectedRecord = [SELECT Id, Distributor__c FROM Opportunity WHERE Id = :o.Id];
        System.debug('TTN ' + affectedRecord);
        System.assertEquals(a.Id, affectedRecord.Distributor__c);
    }

    @IsTest
    private static void bypassTriggerByObject()
    {
        // NOTE: have to jump into real functionality with this test
        // I couldn't figure out how to access the static context where bypass is calculated
        // the other tests in this class skip that and call methods directly on an instantiated trigger handler

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_2__c = 'Opportunity,Lead',
            Bypass_Triggers_By_Object_5__c = 'Account'
        );
        insert apexSettings;

        Set<String> objectsToBypass = (new ilib_SObjectDomain.TriggerEvent()).getObjectsToBypass(apexSettings);
        System.debug('TTN objectsToBypass ' + objectsToBypass);
        System.assert(objectsToBypass.contains('Opportunity'), 'Opportunity trigger not configured to bypass');

        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

        Account a = TestDataAccount.initAccount();
        a.Account_Group__c = Label.AccountGroupDistributor;
        a.Channel_Partner_Type__c = 'Aggregator';
        insert a;

        Opportunity o = TestDataOpportunity.initOpportunity(a);
        o.RecordTypeId = rts.get(Label.OpportunityRTIndirectStandard).getRecordTypeId();
        insert o;

        Opportunity affectedRecord = [SELECT Id, Distributor__c FROM Opportunity WHERE Id = :o.Id];
        System.debug('TTN ' + affectedRecord);
        System.assertEquals(null,affectedRecord.Distributor__c,'Trigger logic was not bypassed');
    }

    @IsTest
    private static void testObjectSecurity()
    {
        // Create a user which will not have access to the test object type
        User testUser = createChatterExternalUser();
        if (testUser == null)
            return; // Abort the test if unable to create a user with low enough acess

        System.runAs(testUser)
        {
            // Test Create object security
            Opportunity opp = new Opportunity(Name = 'Test', Type = 'Existing Account');
            ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { opp } );
            try
            {
                ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
                System.assert(false, 'Expected access denied exception');
            }
            catch (Exception e)
            {
                System.assertEquals('Permission to create an Opportunity denied.', e.getMessage());
            }

            // Test Update object security
            Opportunity existingOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
            existingOpp.Name = 'Test';
            existingOpp.Type = 'Existing Account';
            ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { opp }, new Map<Id, Opportunity> { opp.Id => opp } );
            try
            {
                ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
                System.assert(false, 'Expected access denied exception');
            }
            catch (Exception e)
            {
                System.assertEquals('Permission to udpate an Opportunity denied.', e.getMessage());
            }

            // Test Delete object security
            ilib_SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { opp.Id => opp });
            try
            {
                ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
                System.assert(false, 'Expected access denied exception');
            }
            catch (Exception e)
            {
                System.assertEquals('Permission to delete an Opportunity denied.', e.getMessage());
            }
        }
    }

    @IsTest
    private static void testValidationWithoutDML()
    {
        ilib_SObjectDomain.TestSObjectDomain opps = new ilib_SObjectDomain.TestSObjectDomain(new List<Opportunity> { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) } );
        opps.onValidate();
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((ilib_SObjectDomain.FieldError)ilib_SObjectDomain.errors.getAll()[0]).field);

        opps = new ilib_SObjectDomain.TestSObjectDomain(new List<SObject> { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) }, Opportunity.SObjectType );
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((ilib_SObjectDomain.FieldError)ilib_SObjectDomain.errors.getAll()[0]).field);
    }

    @IsTest
    private static void testInsertValidationFailedWithoutDML()
    {
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        System.assertEquals(false, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { opp } );
        System.assertEquals(true, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('You must provide an Account for Opportunities for existing Customers.', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals(Opportunity.AccountId, ((ilib_SObjectDomain.FieldError)ilib_SObjectDomain.errors.getAll()[0]).field);
    }

    @IsTest
    private static void testUpdateValidationFailedWithoutDML()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test';
        newOpp.Type = 'New Account';
        System.assertEquals(false, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        System.assertEquals(true, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('You cannot change the Opportunity type once it has been created.', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals(Opportunity.Type, ((ilib_SObjectDomain.FieldError)ilib_SObjectDomain.errors.getAll()[0]).field);
    }

    @IsTest
    private static void testOnBeforeDeleteWithoutDML()
    {
        Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        opp.Name = 'Test';
        opp.Type = 'Existing Account';
        System.assertEquals(false, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.test.database.onDelete(new Map<ID, Opportunity> { opp.Id => opp } );
        System.assertEquals(true, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('You cannot delete this Opportunity.', ilib_SObjectDomain.errors.getAll()[0].message);
    }

    @IsTest
    private static void testOnAfterUndeleteWithoutDML()
    {
        Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        opp.Name = 'Test';
        opp.Type = 'Existing Account';
        System.assertEquals(false, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.test.database.onUndelete(new list<Opportunity> { opp } );
        System.assertEquals(true, ilib_SObjectDomain.test.database.hasRecords());
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDomainConstructors.class);
    }

    @IsTest
    private static void testErrorLogging()
    {
        // Test static helpers for raise none domain object instance errors
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        ilib_SObjectDomain.errors.error('Error', opp);
        ilib_SObjectDomain.errors.error('Error', opp, Opportunity.Type);
        System.assertEquals(2, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('Error', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals('Error', ilib_SObjectDomain.errors.getAll()[1].message);
        System.assertEquals(Opportunity.Type, ((ilib_SObjectDomain.FieldError)ilib_SObjectDomain.errors.getAll()[1]).field);
        ilib_SObjectDomain.errors.clearAll();
        System.assertEquals(0, ilib_SObjectDomain.errors.getAll().size());
    }

    @IsTest
    private static void testTriggerState()
    {
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { opp } );
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectStatefulDomainConstructors.class);
        System.assertEquals(1, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('Error on Record Test', ilib_SObjectDomain.errors.getAll()[0].message);
    }

    @IsTest
    private static void testRecursiveTriggerState()
    {
        Opportunity opp = new Opportunity ( Name = 'Test Recursive 1', Type = 'Existing Account' );
        ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { opp } );
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectStatefulDomainConstructors.class);
        System.assertEquals(2, ilib_SObjectDomain.errors.getAll().size());
        System.assertEquals('Error on Record Test Recursive 2', ilib_SObjectDomain.errors.getAll()[0].message);
        System.assertEquals('Error on Record Test Recursive 1', ilib_SObjectDomain.errors.getAll()[1].message);
    }

    @IsTest
    private static void testOnValidateBehaviorDefault()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test Default Behaviour';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test Default Behaviour';
        newOpp.Type = 'New Account';
        ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectOnValidateBehaviourConstructors.class);
        System.assert(oldOpp.Name!=null, 'Old Opportunity name is null');
    }

    @IsTest
    private static void testOnValidateBehaviorOld()
    {
        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test Enable Old Behaviour';
        oldOpp.Type = 'Existing Account';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test Enable Old Behaviour';
        newOpp.Type = 'New Account';
        ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
        try
        {
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectOnValidateBehaviourConstructors.class);
            System.assert(false, 'Expected exception');
        }
        catch (Exception e)
        {
            System.assertEquals('onValidate called', e.getMessage());
        }
    }

    /**
     *    The following tests that the ability to enable/disable all trigger events works as required
     **/
    @IsTest
    private static void testDisableTriggerEventsBehaviour()
    {
        Boolean bError = false;
        String  sErrorMessage = '';

        Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        oldOpp.Name = 'Test';
        oldOpp.Type = 'Existing';
        Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
        newOpp.Name = 'Test';
        newOpp.Type = 'New';

        // these will be called multiple times making sure the correct error message comes back out
        // so... there are alot of tests to do here sadly and remember everything is reversed and you need to run backwards!
        // 1 - all disabled
        try
        {
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).disableAll();
            ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { newOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            bError = true;
        }

        System.assertEquals(false, bError, 'Error - Trigger events have been fired when they are disabled');

        ////////////////////////////
        // Insert!
        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableAfterInsert();
            ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { newOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
            System.Debug('Exception Fired :' + e.getMEssage());
        }

        System.AssertEquals('onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run');

        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableBeforeInsert();
            ilib_SObjectDomain.test.database.onInsert(new List<Opportunity> { newOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run');

        ////////////////////////////
        // Update!
        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableAfterUpdate();
            ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run');

        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableBeforeUpdate();
            ilib_SObjectDomain.test.database.onUpdate(new List<Opportunity> { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run');

        ////////////////////////////
        // Delete!
        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableAfterDelete();
            ilib_SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run');

        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableBeforeDelete();
            ilib_SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp } );
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run');

        ////////////////////////////
        // Undelete!
        try
        {
            // now lets go after insert and then before
            ilib_SObjectDomain.getTriggerEvent(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class).enableAfterUndelete();
            ilib_SObjectDomain.test.database.onUndelete(new List<Opportunity> { newOpp });
            ilib_SObjectDomain.triggerHandler(ilib_SObjectDomain.TestSObjectDisableBehaviourConstructors.class);
        }
        catch (Exception e)
        {
            sErrorMessage = e.getMessage();
        }

        System.AssertEquals('onAfterUndelete called', sErrorMessage, 'Error - After Undelete Event is enabled but did not run');
    }


    /**
     * Create test user
     **/
    private static User createChatterExternalUser()
    {
        // Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
        List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name='Chatter External' limit 1];
        if (testProfiles.size() != 1)
            return null;

        // Can only proceed with test if we can successfully insert a test user
        String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
        User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
        try
        {
            insert testUser;
        }
        catch (Exception e)
        {
            return null;
        }
        return testUser;
    }

}