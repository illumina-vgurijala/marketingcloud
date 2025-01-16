/**
 * Copyright (c) 2014, FinancialForce.com, inc
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
 * @ author       : 
*  @ date         : 
*  @ Description  : ilib_QueryFactoryTest Test class
*
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Developer                Date                   Modification ID      Description
*  ---------------------------------------------------------------------------------------------------------------------------------------
*  Parthasarathy D          10-Oct-2022                                 Codescan Fix- Added method level comments.
*  Prem Ranjan              10-Jan-2023                                 Codescan Fix- Comment is Required.
*/

@isTest
private class ilib_QueryFactoryTest {

    @isTest
    static void fieldSelections()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('firstName');
        qf.selectField(Schema.Contact.SObjectType.fields.lastName);
        qf.selectFields(new Set<String> {'acCounTId', 'account.name'} );
        qf.selectFields(new List<String> {'homePhonE','fAX'} );
        qf.selectFields(new List<Schema.SObjectField> { Contact.Email, Contact.Title } );
    }

    @isTest
    static void simpleFieldSelection()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('NAMe').selectFields(new Set<String>{'naMe', 'email'});
        String query = qf.toSOQL();
        System.assert( Pattern.matches('SELECT.*Name.*FROM.*',query), 'Expected Name field in query, got '+query);
        System.assert( Pattern.matches('SELECT.*Email.*FROM.*',query), 'Expected Name field in query, got '+query);
        qf.setLimit(100);
        System.assertEquals(100,qf.getLimit());
        System.assert( qf.toSOQL().endsWithIgnoreCase('LIMIT '+qf.getLimit()), 'Failed to respect limit clause:'+qf.toSOQL() );
    }

    @isTest
    static void simpleFieldCondition()
    {
        String whereClause = 'name = \'test\'';
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        qf.selectField('email');
        qf.setCondition( whereClause );
        System.assertEquals(whereClause,qf.getCondition());
        String query = qf.toSOQL();
        System.assert(query.endsWith('WHERE name = \'test\''),'Query should have ended with a filter on name, got: '+query);
    }

    @isTest
    static void duplicateFieldSelection()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('NAMe').selectFields(new Set<String> {'naMe', 'email'});
        String query = qf.toSOQL();
        System.assertEquals(1, query.countMatches('Name'), 'Expected one name field in query: '+query );
    }

    @isTest
    static void equalityCheck()
    {
        ilib_QueryFactory qf1 = new ilib_QueryFactory(Contact.SObjectType);
        ilib_QueryFactory qf2 = new ilib_QueryFactory(Contact.SObjectType);
        System.assertEquals(qf1,qf2);
        qf1.selectField('name');
        System.assertNotEquals(qf1,qf2);
        qf2.selectField('NAmE');
        System.assertEquals(qf1,qf2);
        qf1.selectField('name').selectFields(new Set<String>{ 'NAME', 'name' }).selectFields(new Set<Schema.SObjectField>{ Contact.Name, Contact.Name} );
        System.assertEquals(qf1,qf2);
    }

    @isTest
    static void nonReferenceField()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        ilib_QueryFactory.NonReferenceFieldException e;
        try
        {
            qf.selectField('name.title');
        }
        catch (ilib_QueryFactory.NonReferenceFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e,'Cross-object notation on a non-reference field should throw NonReferenceFieldException.');
    }

    @isTest
    static void invalidCrossObjectField()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        ilib_QueryFactory.InvalidFieldException e;
        try {
            qf.selectField('account.NOT_A_REAL_FIELD');
        }
        catch (ilib_QueryFactory.InvalidFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e,'Cross-object notation on a non-reference field should throw NonReferenceFieldException.');
    }

    @isTest
    static void invalidFieldTests()
    {
        List<ilib_QueryFactory.InvalidFieldException> exceptions = new List<ilib_QueryFactory.InvalidFieldException>();
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        try {
            qf.selectField('Not_a_field');
        }
        catch (ilib_QueryFactory.InvalidFieldException e)
        {
            exceptions.add(e);
        }

        try
        {
            qf.selectFields(new Set<String>{ 'Not_a_field','alsoNotreal'});
        }
        catch (ilib_QueryFactory.InvalidFieldException e)
        {
            exceptions.add(e);
        }

        try
        {
            qf.selectFields(new Set<Schema.SObjectField>{ null });
        }
        catch (ilib_QueryFactory.InvalidFieldException e)
        {
            exceptions.add(e);
        }

        try
        {
            qf.selectFields(new List<Schema.SObjectField>{ null, Contact.title });
        }
        catch (ilib_QueryFactory.InvalidFieldException e)
        {
            exceptions.add(e);
        }
        System.assertEquals(4,exceptions.size());
    }

    @isTest
    static void ordering()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        qf.selectField('email');
        qf.setCondition('name = \'test\'');
        qf.addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) ).addOrdering(new ilib_QueryFactory.Ordering('Contact','CreatedDATE',ilib_QueryFactory.SortOrder.DESCENDING) );
        String query = qf.toSOQL();

        System.assertEquals(2,qf.getOrderings().size());
        System.assertEquals(Contact.name,qf.getOrderings()[0].getField() );
        System.assertEquals(ilib_QueryFactory.SortOrder.DESCENDING,qf.getOrderings()[1].getDirection() );

        System.assert( Pattern.matches('SELECT.*Name.*FROM.*',query), 'Expected Name field in query, got '+query);
        System.assert( Pattern.matches('SELECT.*Email.*FROM.*',query), 'Expected Name field in query, got '+query);
    }

    @isTest
    static void invalidFieldString()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        Exception e;
        try
        {
            qf.selectField('not_a__field');
        }
        catch (ilib_QueryFactory.InvalidFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldsString()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        Exception e;
        try
        {
            qf.selectFields(new List<String>{'not_a__field'} );
        }
        catch (ilib_QueryFactory.InvalidFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldNullToken()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        Exception e;
        Schema.SObjectField token = null;
        try
        {
            qf.selectField( token );
        }
        catch (ilib_QueryFactory.InvalidFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldsNullToken()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        Exception e;
        List<Schema.SObjectField> token = new List<Schema.SObjectField> { null };
        try
        {
            qf.selectFields( token );
        }
        catch (ilib_QueryFactory.InvalidFieldException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldsNoQueryFields()
    {
        Exception e;
        List<Schema.SObjectField> sObjectFields = new List<Schema.SObjectField>();
        try
        {
            ilib_QueryFactory.QueryField qfld = new ilib_QueryFactory.QueryField(sObjectFields);
        }
        catch (Exception ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldsNoQueryField()
    {
        Exception e;
        Schema.SObjectField sObjectField;
        try
        {
            ilib_QueryFactory.QueryField qfld = new ilib_QueryFactory.QueryField(sObjectField);
        }
        catch (Exception ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void invalidFieldsqueryFieldsNotEquals()
    {
        //Exception e;
        //Schema.SObjectField sObjectField;
        ilib_QueryFactory.QueryField qfld = new ilib_QueryFactory.QueryField(Contact.Name);
        ilib_QueryFactory.QueryField qfld2 = new ilib_QueryFactory.QueryField(Contact.LastName);
        System.assert(!qfld.equals(qfld2));
    }

    @isTest
    static void queryIdFieldNotEquals()
    {
        //this is the equivalent of calling setField('account.name'), where table = Contact
        ilib_QueryFactory.QueryField qfld = new ilib_QueryFactory.QueryField(new List<Schema.SObjectField>{
            Schema.Contact.SObjectType.fields.AccountId,
            Schema.Account.SObjectType.fields.name
        });

        String fldString = qfld.toString();
        System.assert(fldString != null, 'String should not be null');

        //String fldString = qfld.toString();
    }

    @isTest
    static void queryIdFieldNotEqualsWrongObjType()
    {
        ilib_QueryFactory.QueryField qfld = new ilib_QueryFactory.QueryField(new List<Schema.SObjectField> { Schema.Contact.SObjectType.fields.AccountId });
        System.assert(!qfld.equals(new Contact()));
    }

    @isTest
    static void addChildQueriesWithChildRelationshipSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact();
        cont.FirstName = 'test';
        cont.LastName = 'test';
        // ILLUMINA RULE - contacts must have phone or email value (also added to contacts created in a single-line below)
        cont.Phone = '12345';
        cont.AccountId = acct.Id;
        insert cont;
        Task tsk = new Task();
        tsk.WhoId = cont.Id;
        tsk.Subject = 'test';
        tsk.ActivityDate = System.today();
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
        Contact.SObjectType.getDescribe();
        //explicitly assert object accessibility when creating the subselect
        qf.subselectQuery('Tasks', true).selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        List<Contact> contacts = Database.query(qf.toSOQL());
        System.assert(contacts != null && contacts.size() == 1);
        System.assertEquals(1,contacts[0].Tasks.size());
        System.assertEquals('test',contacts[0].Tasks[0].Subject);
    }

    @isTest
    static void addChildQueriesWithChildRelationshipNoAccessibleCheckSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
        //explicitly assert object accessibility when creating the subselect
        qf.subselectQuery('Tasks').selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        List<Contact> contacts = Database.query(qf.toSOQL());
        System.assert(contacts != null && contacts.size() == 1);
        System.assertEquals(1,contacts[0].Tasks.size());
        System.assertEquals('test',contacts[0].Tasks[0].Subject);
    }

    @isTest
    static void addChildQueriesWithChildRelationshipObjCheckIsAccessibleSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        Schema.ChildRelationship relationship;
        for (Schema.ChildRelationship childRow : descResult.getChildRelationships())
        {
            //occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
            //if there is no relationship name, we cannot query on it, so throw an exception.
            if (childRow.getRelationshipName() == 'Tasks')
                relationship = childRow;
        }
        //explicitly assert object accessibility when creating the subselect
        qf.subselectQuery(relationship, true).selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        List<Contact> contacts = Database.query(qf.toSOQL());
        System.assert(contacts != null && contacts.size() == 1);
        System.assertEquals(1,contacts[0].Tasks.size());
        System.assertEquals('test',contacts[0].Tasks[0].Subject);
    }

    @isTest
    static void addChildQueriesWithChildRelationshipObjSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        Schema.ChildRelationship relationship;
        for (Schema.ChildRelationship childRow : descResult.getChildRelationships())
        {
            //occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
            //if there is no relationship name, we cannot query on it, so throw an exception.
            if (childRow.getRelationshipName() == 'Tasks')
                relationship = childRow;
        }
        //explicitly assert object accessibility when creating the subselect
        qf.subselectQuery(relationship).selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        List<Contact> contacts = Database.query(qf.toSOQL());
        System.assert(contacts != null && contacts.size() == 1);
        System.assertEquals(1,contacts[0].Tasks.size());
        System.assertEquals('test',contacts[0].Tasks[0].Subject);
    }

    @isTest
    static void addChildQueriesWithChildRelationshipNoAccessibleCheckFail()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
         Contact.SObjectType.getDescribe();
        //explicitly assert object accessibility when creating the subselect
        //
        Exception e;
        try
        {
            qf.subselectQuery('Tas').selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        }
        catch (ilib_QueryFactory.InvalidSubqueryRelationshipException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void addChildQueriesSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name').selectField('Id').setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING, true);
        Contact.SObjectType.getDescribe();
        //explicitly assert object accessibility when creating the subselect
        qf.subselectQuery(Task.SObjectType, true).selectField('Id').selectField('Subject').setCondition(' IsDeleted = false ');
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        List<Contact> contacts = Database.query(qf.toSOQL());
        System.assert(contacts != null && contacts.size() == 1);
        System.assertEquals(1,contacts[0].Tasks.size());
        System.assertEquals('test',contacts[0].Tasks[0].Subject);
    }

    @isTest
    static void addChildQuerySameRelationshipAgainSuccess()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;
        Task tsk = new Task(WhoId = cont.Id, Subject = 'test', ActivityDate = System.today());
        insert tsk;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        qf.selectField('Id');
        qf.setCondition('name like \'%test%\'');
        qf.addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) ).addOrdering('CreatedBy.Name',ilib_QueryFactory.SortOrder.DESCENDING);
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        ChildRelationship relationship;
        for (Schema.ChildRelationship childRow : descResult.getChildRelationships())
            if (childRow.getRelationshipName() == 'Tasks')
                relationship = childRow;
        System.assertEquals(null,qf.getSubselectQueries());

        ilib_QueryFactory childQf = qf.subselectQuery(Task.SObjectType);
        childQf.assertIsAccessible();
        childQf.setEnforceFLS(true);
        childQf.selectField('Id');
        qf.subselectQuery(Task.SObjectType);
        List<ilib_QueryFactory> queries = qf.getSubselectQueries();
        System.assert(queries != null);
        System.assertEquals(1,queries.size());
    }

    @isTest
    static void addChildQueriesInvalidChildRelationship()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        qf.selectField('email');
        qf.setCondition('name like \'%test%\'');
        qf.addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) ).addOrdering( 'CreatedDATE',ilib_QueryFactory.SortOrder.DESCENDING);
         Account.SObjectType.getDescribe();
        Exception e;
        try
        {
            ilib_QueryFactory childQf = qf.subselectQuery(Contact.SObjectType);
            childQf.selectField('Id');
        }
        catch (ilib_QueryFactory.InvalidSubqueryRelationshipException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void addChildQueriesInvalidChildRelationshipTooDeep()
    {
        Account acct = TestDataAccount.getAccount('testchildqueriesacct');
        insert acct;
        Contact cont = new Contact(FirstName = 'test', LastName = 'test', Phone = '12345', AccountId = acct.Id);
        insert cont;

        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.selectField('name');
        qf.selectField('email');
        qf.setCondition('name like \'%test%\'');
        qf.addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) ).addOrdering('CreatedDATE',ilib_QueryFactory.SortOrder.DESCENDING);
        Contact.SObjectType.getDescribe();

        ilib_QueryFactory childQf = qf.subselectQuery(Task.SObjectType);
        childQf.selectField('Id');
        childQf.selectField('Subject');
        Exception e;
        try
        {
            childQf.subselectQuery(Task.SObjectType);
        }
        catch (ilib_QueryFactory.InvalidSubqueryRelationshipException ex)
        {
            e = ex;
        }
        System.assertNotEquals(null,e);
    }

    @isTest
    static void checkFieldObjectReadSortSuccess()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.assertIsAccessible()
            .setEnforceFLS(true)
            .selectField('createdby.name')
            .selectField(Contact.LastModifiedById)
            .selectFields(new List<SObjectField>{Contact.LastModifiedDate})
            .setEnforceFLS(false)
            .selectField(Contact.LastName)
            .selectFields(new List<SObjectField>{Contact.Id})
            .setCondition( 'name like \'%test%\'' )
            .setEnforceFLS(true)
            .selectFields(new Set<SObjectField>{Contact.FirstName})
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) )
            .addOrdering(Contact.LastModifiedDate,ilib_QueryFactory.SortOrder.DESCENDING)
            .addOrdering(Contact.CreatedDate,ilib_QueryFactory.SortOrder.DESCENDING, true);

        Set<ilib_QueryFactory.QueryField> fields = qf.getSelectedFields();
        ilib_QueryFactory.Ordering ordering = new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING);
        ordering.getFields();
        for (ilib_QueryFactory.QueryField qfRow : fields)
        {
            qfRow.getBaseField();
            qfRow.getFieldPath();
            break;
        }

        System.assert(qf.toSOQL().containsIgnoreCase('NULLS LAST'));
    }

    @isTest
    static void checkObjectReadFail()
    {
        User usr = createTestUserNoAccess();
        if (usr != null)
        {
            System.runAs(usr)
            {
                //create a query factory object for Account.
                ilib_QueryFactory qf = new ilib_QueryFactory(Account.SObjectType);
                Boolean excThrown = false;
                try
                {
                    //check to see if this record is accessible, it isn't.
                    qf.assertIsAccessible();
                }
                catch (ilib_SecurityUtils.CrudException e)
                {
                    excThrown = true;
                }
                System.assert(excThrown);
            }
        }
    }

    @isTest
    static void checkFieldReadFail()
    {
        User usr = createTestUserNoAccess();
        if (usr != null)
        {
            System.runAs(usr)
            {
                //create a query factory object for Account.
                ilib_QueryFactory qf = new ilib_QueryFactory(Account.SObjectType);
                Boolean excThrown = false;
                try
                {
                    //set field to enforce FLS, then try to add a field.
                    qf.setEnforceFLS(true);
                    qf.selectField('Name');
                }
                catch (ilib_SecurityUtils.FlsException e)
                {
                    excThrown = true;
                }
                System.assert(excThrown);
            }
        }
    }

    @isTest
    static void queryWithNoFields()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType);
        qf.assertIsAccessible().setEnforceFLS(true).setCondition( 'name like \'%test%\'' ).addOrdering('CreatedDate',ilib_QueryFactory.SortOrder.DESCENDING);
        String query = qf.toSOQL();
        System.assert(query.containsIgnoreCase('Id FROM'));
    }

    @isTest
    static void queryFieldCompareTo()
    {
        String otherType = 'bob';
        ilib_QueryFactory.QueryField qf = new ilib_QueryFactory.QueryField(Contact.SObjectType.fields.Name);
        ilib_QueryFactory.QueryField joinQf = new ilib_QueryFactory.QueryField(new List<Schema.SObjectField>{
            Contact.SObjectType.fields.LastModifiedById,
            Account.SObjectType.fields.OwnerId,
            User.SObjectType.fields.Name
        });
        ilib_QueryFactory.QueryField otherJoinQf = new ilib_QueryFactory.QueryField(new List<Schema.SObjectField>{
            Contact.SObjectType.fields.AccountId,
            Account.SObjectType.fields.CreatedById,
            User.SObjectType.fields.Name
        });
        System.assertEquals(-2, qf.compareTo(otherType));
        System.assertEquals(-2, qf.compareTo(null));
        System.assertEquals(0, qf.compareTo(qf));
        System.assertEquals(
            0,
            qf.compareTo(new ilib_QueryFactory.QueryField(Contact.SObjectType.fields.Name)),
            'An equal but non-identical instance should return 0'
        );
        System.assertEquals(-1 , qf.compareTo(joinQf));
        System.assertEquals(1, joinQf.compareTo(qf));
        System.assert(joinQf.compareTo(otherJoinQf) > 0);
        System.assert(otherJoinQf.compareTo(joinQf) < 0);
    }

    @isTest
    static void deterministicToSOQL()
    {
        ilib_QueryFactory qf1 = new ilib_QueryFactory(User.SObjectType);
        ilib_QueryFactory qf2 = new ilib_QueryFactory(User.SObjectType);
        for (ilib_QueryFactory qf:new Set<ilib_QueryFactory>{qf1,qf2})
        {
            qf.selectFields(new List<String>{
                'Id',
                'FirstName',
                'LastName',
                'CreatedBy.Name',
                'CreatedBy.Manager',
                'LastModifiedBy.Email'
            });
        }
        String expectedQuery =
            'SELECT '
            +'FirstName, Id, LastName, ' //less joins come first, alphabetically
            +'CreatedBy.ManagerId, CreatedBy.Name, LastModifiedBy.Email ' //alphabetical on the same number of joinrs'
            +'FROM User';
        System.assertEquals(qf1.toSOQL(), qf2.toSOQL());
        System.assertEquals(expectedQuery, qf1.toSOQL());
        System.assertEquals(expectedQuery, qf2.toSOQL());
    }

    @isTest
    static void deepCloneBasicNoChanges()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType)
            .setLimit(10)
            .setCondition('id=12345')
            .selectField('Description')
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) )
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','CreatedDATE',ilib_QueryFactory.SortOrder.DESCENDING))
            .setEnforceFLS(true);

        ilib_QueryFactory qf2 = qf.deepClone();

        System.assertEquals(qf2, qf);

        System.assertEquals(qf.getLimit(), qf2.getLimit());
        System.assertEquals(qf.getCondition(), qf2.getCondition());
        System.assertEquals(qf.toSOQL(), qf2.toSOQL());
        System.assertEquals(qf.getOrderings(), qf2.getOrderings());
    }

    @isTest
    static void deepCloneSubqueryNoChanges()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Account.SObjectType)
            .setLimit(10)
            .setCondition('id=12345')
            .selectField('Description')
            .addOrdering(new ilib_QueryFactory.Ordering('Account','Name',ilib_QueryFactory.SortOrder.ASCENDING) )
            .addOrdering(new ilib_QueryFactory.Ordering('Account','Description',ilib_QueryFactory.SortOrder.DESCENDING))
            .setEnforceFLS(true);

        qf.subselectQuery('Contacts', true);

        ilib_QueryFactory qf2 = qf.deepClone();

        System.assertEquals(qf, qf2);

        System.assertEquals(qf.getLimit(), qf2.getLimit());
        System.assertEquals(qf.getCondition(), qf2.getCondition());
        System.assertEquals(qf.toSOQL(), qf2.toSOQL());
        System.assertEquals(qf.getOrderings(), qf2.getOrderings());
        System.assertEquals(qf.getSubselectQueries(), qf2.getSubselectQueries());
    }

    @isTest
    static void deepCloneBasic()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Contact.SObjectType)
            .setLimit(10)
            .setCondition('id=12345')
            .selectField('Description')
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','name',ilib_QueryFactory.SortOrder.ASCENDING) )
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','CreatedDATE',ilib_QueryFactory.SortOrder.DESCENDING))
            .setEnforceFLS(true);

        ilib_QueryFactory qf2 = qf.deepClone()
            .setLimit(200)
            .setCondition('id=54321')
            .selectField('Fax')
            .addOrdering(new ilib_QueryFactory.Ordering('Contact','Fax',ilib_QueryFactory.SortOrder.ASCENDING))
            .setEnforceFLS(false);

        qf2.getOrderings().remove(0);

        System.assertEquals(10, qf.getLimit());
        System.assertEquals(200, qf2.getLimit());

        System.assertEquals('id=12345', qf.getCondition());
        System.assertEquals('id=54321', qf2.getCondition());

        String query = qf.toSOQL();
        String query2 = qf2.toSOQL();

        System.assertEquals(false,query.containsIgnoreCase('Fax'));
        System.assert(query.containsIgnoreCase('Description'));
        System.assert(query2.containsIgnoreCase('Description'));
        System.assert(query2.containsIgnoreCase('Fax'));

        System.assertEquals(2, qf.getOrderings().size());
        System.assertEquals(Contact.name, qf.getOrderings()[0].getField() );
        System.assertEquals(ilib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[1].getDirection());

        System.assertEquals(2, qf2.getOrderings().size());
        System.assertEquals(Contact.Fax, qf2.getOrderings()[1].getField());
        System.assertEquals(ilib_QueryFactory.SortOrder.ASCENDING, qf2.getOrderings()[1].getDirection());

    }

    @isTest
    static void deepCloneSubquery()
    {
        ilib_QueryFactory qf = new ilib_QueryFactory(Account.SObjectType);
        qf.subselectQuery('Contacts', true);

        ilib_QueryFactory qf2 = qf.deepClone();
        qf2.subselectQuery('Opportunities', true);

        List<ilib_QueryFactory> subqueries = qf.getSubselectQueries();
        List<ilib_QueryFactory> subqueries2 = qf2.getSubselectQueries();

        ilib_QueryFactory subquery20 = subqueries2.get(0);

        subquery20.addOrdering(new ilib_QueryFactory.Ordering('Contact','Name',ilib_QueryFactory.SortOrder.ASCENDING));

        System.assertEquals(1,subqueries.size());
        System.assertEquals(2,subqueries2.size());

        System.assertEquals(0,qf.getSubselectQueries().get(0).getOrderings().size());
        System.assertEquals(1,qf2.getSubselectQueries().get(0).getOrderings().size());
    }

    @isTest
    static void testSoqlUnsortedSelectFields()
    {
        //Given
        ilib_QueryFactory qf = new ilib_QueryFactory(User.SObjectType);
        qf.selectFields(new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'CreatedBy.Name',
            'CreatedBy.Manager',
            'LastModifiedBy.Email'
        });

        qf.setSortSelectFields(false);

        String orderedQuery =
            'SELECT '
            +'FirstName, Id, LastName, ' //less joins come first, alphabetically
            +'CreatedBy.ManagerId, CreatedBy.Name, LastModifiedBy.Email ' //alphabetical on the same number of joins'
            +'FROM User';

        //When
        String actualSoql = qf.toSOQL();

        //Then
        System.assertNotEquals(orderedQuery, actualSoql);
    }

    /**
    * @author  
    * @description create test user with no access
    * @param NA
    * @return user
    **/
    public static User createTestUserNoAccess()
    {
        User usr;
        try
        {
            //look for a profile that does not have access to the Account object
            PermissionSet ps =
            [SELECT Profile.Id, profile.name
                FROM PermissionSet
                WHERE IsOwnedByProfile = true
                AND Profile.UserType = 'Standard'
                AND Id NOT IN (SELECT ParentId
                            FROM ObjectPermissions
                            WHERE SObjectType = 'Account'
                            AND PermissionsRead = true)
                LIMIT 1];

            if (ps != null)
            {
                //create a user with the profile found that doesn't have access to the Account object
                usr = new User(
                    firstName = 'testUsrF',
                    LastName = 'testUsrL',
                    Alias = 'tstUsr',
                    Email = 'testy.test@test.com',
                    UserName='test'+ Math.random().format()+'user99@test.com',
                    EmailEncodingKey = 'ISO-8859-1',
                    LanguageLocaleKey = 'en_US',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    ProfileId = ps.Profile.Id,
                    IsActive=true
                    );
                insert usr;
            }
        }
        catch (Exception e)
        {
            //do nothing, just return null User because this test case won't work in this org.
            return null;
        }
        return usr;
    }

}