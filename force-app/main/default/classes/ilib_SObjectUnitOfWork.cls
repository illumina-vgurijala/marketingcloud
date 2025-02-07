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

/**
 * Provides an implementation of the Enterprise Application Architecture Unit Of Work, as defined by Martin Fowler
 *   http://martinfowler.com/eaaCatalog/unitOfWork.html
 *
 * "When you're pulling data in and out of a database, it's important to keep track of what you've changed; otherwise,
 *  that data won't be written back into the database. Similarly you have to insert new objects you create and
 *  remove any objects you delete."
 *
 * "You can change the database with each change to your object model, but this can lead to lots of very small database calls,
 *  which ends up being very slow. Furthermore it requires you to have a transaction open for the whole interaction, which is
 *  impractical if you have a business transaction that spans multiple requests. The situation is even worse if you need to
 *  keep track of the objects you've read so you can avoid inconsistent reads."
 *
 * "A Unit of Work keeps track of everything you do during a business transaction that can affect the database. When you're done,
 *  it figures out everything that needs to be done to alter the database as a result of your work."
 *
 * In an Apex context this pattern provides the following specific benifits
 *  - Applies bulkfication to DML operations, insert, update and delete
 *  - Manages a business transaction around the work and ensures a rollback occurs (even when exceptions are later handled by the caller)
 *  - Honours dependency rules between records and updates dependent relationships automatically during the commit
 *
 * Please refer to the testMethod's in this class for example usage
 *
 * TODO: Need to complete the 100% coverage by covering parameter exceptions in tests
 * TODO: Need to add some more test methods for more complex use cases and some unexpected (e.g. registerDirty and then registerDeleted)
 *
 **/
public virtual class ilib_SObjectUnitOfWork implements ilib_ISObjectUnitOfWork
{
    private List<Schema.SObjectType> mSObjectTypes = new List<Schema.SObjectType>();

    public static final String SALES_EXCEPTIONMESSAGE = 'SObject type {0} is not supported by this unit of work';

    // records to DML by type
    private Map<String, List<SObject>> mNewListByType = new Map<String, List<SObject>>();
    private Map<String, Map<Id, SObject>> mDirtyMapByType = new Map<String, Map<Id, SObject>>();
    private Map<String, Map<Id, SObject>> mDeletedMapByType = new Map<String, Map<Id, SObject>>();

    // which fields relate records - used for cascading inserts
    private Map<String, Relationships> mRelationships = new Map<String, Relationships>();

    private List<IDoWork> mWorkList = new List<IDoWork>();

    //private SendEmailWork m_emailWork = new SendEmailWork();

    private IDML mDml;

    /**
     * Interface describes work to be performed during the commitWork method
     **/
    public interface IDoWork
    {
        void doWork();
    }
    /**
     * @author Illumina
     * @description Interface
     */
    public interface IDML
    {
        void dmlInsert(List<SObject> objList);
        void dmlUpdate(List<SObject> objList);
        void dmlDelete(List<SObject> objList);
    }
    /**
     * @author Illumina
     * @description 
     */
    public class SimpleDML implements IDML
    {
        /**
        * @author Illumina
        * @description 
        */
        public void dmlInsert(List<SObject> objList) { insert objList; }
        /**
        * @author Illumina
        * @description 
        */
        public void dmlUpdate(List<SObject> objList) { update objList; }
        /**
        * @author Illumina
        * @description 
        */
        public void dmlDelete(List<SObject> objList) { delete objList; }
    }

    /**
     * Constructs a new UnitOfWork to support work against the given object list
     *
     * @param sObjectList A list of objects given in dependency order (least dependent first)
     */
    public ilib_SObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes)
    {
        this(sObjectTypes, new SimpleDML());
    }
    /**
    * @author Illumina
    * @description 
    */
    public ilib_SObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes, IDML dml)
    {
        mSObjectTypes = sObjectTypes.clone();

        for (Schema.SObjectType sObjectType : mSObjectTypes)
            // register the type
            handleRegisterType(sObjectType);

       // mWorkList.add(m_emailWork);

        mDml = dml;
    }

    // default implementations for commitWork events
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onRegisterType(Schema.SObjectType sObjectType) { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onCommitWorkStarting() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onDMLStarting() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onDMLFinished() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onDoWorkStarting() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onDoWorkFinished() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onCommitWorkFinishing() { }
    /**
    * @author Illumina
    * @description 
    */
    public virtual void onCommitWorkFinished(Boolean wasSuccessful) { }

    /**
     * Registers the type to be used for DML operations
     *
     * @param sObjectType - The type to register
     *
     */
    private void handleRegisterType(Schema.SObjectType sObjectType)
    {
        // add type to dml operation tracking
        mNewListByType.put(sObjectType.getDescribe().getName(), new List<SObject>());
        mDirtyMapByType.put(sObjectType.getDescribe().getName(), new Map<Id, SObject>());
        mDeletedMapByType.put(sObjectType.getDescribe().getName(), new Map<Id, SObject>());
        mRelationships.put(sObjectType.getDescribe().getName(), new Relationships());

        // give derived class opportunity to register the type
        onRegisterType(sObjectType);
    }

    /**
     * Register a generic peace of work to be invoked during the commitWork phase
     **/
    public void registerWork(IDoWork work)
    {
        mWorkList.add(work);
    }

    /**
     * Registers the given email to be sent during the commitWork
     **/
    public void registerEmail(Messaging.Email email)
    {
        //m_emailWork.registerEmail(email);
    }

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called
     *
     * @param record A newly created SObject instance to be inserted during commitWork
     **/
    public void registerNew(SObject record)
    {
        registerNew(record, null, null);
    }

    /**
     * Register a list of newly created SObject instances to be inserted when commitWork is called
     *
     * @param records A list of newly created SObject instances to be inserted during commitWork
     **/
    public void registerNew(List<SObject> records)
    {
        for (SObject record : records)
            registerNew(record, null, null);
    }

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called,
     *   you may also provide a reference to the parent record instance (should also be registered as new separatly)
     *
     * @param record A newly created SObject instance to be inserted during commitWork
     * @param relatedToParentField A SObjectField reference to the child field that associates the child record with its parent
     * @param relatedToParentRecord A SObject instance of the parent record (should also be registered as new separatly)
     **/
    public void registerNew(SObject record, Schema.sObjectField relatedToParentField, SObject relatedToParentRecord)
    {
        if (record.Id != null)
            throw new UnitOfWorkException('Only new records can be registered as new');

        String sObjectType = record.getSObjectType().getDescribe().getName();
        if (!mNewListByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format(SALES_EXCEPTIONMESSAGE, new String[] { sObjectType }));

            mNewListByType.get(sObjectType).add(record);
        if (relatedToParentRecord!=null && relatedToParentField!=null)
            registerRelationship(record, relatedToParentField, relatedToParentRecord);
    }

    /**
     * Register a relationship between two records that have yet to be inserted to the database. This information will be
     *  used during the commitWork phase to make the references only when related records have been inserted to the database.
     *
     * @param record An existing or newly created record
     * @param relatedToField A SObjectField referene to the lookup field that relates the two records together
     * @param relatedTo A SOBject instance (yet to be commited to the database)
     */
    public void registerRelationship(SObject record, Schema.sObjectField relatedToField, SObject relatedTo)
    {
        system.debug('Inside registerRelationship...');
        system.debug('record...' +record);
        system.debug('relatedToField...' +relatedToField);
        system.debug('relatedTo...' +relatedTo);
        String sObjectType = record.getSObjectType().getDescribe().getName();
        if (!mNewListByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format(SALES_EXCEPTIONMESSAGE, new String[] { sObjectType }));

        mRelationships.get(sObjectType).add(record, relatedToField, relatedTo);
    }

    /**
     * Register an existing record to be updated during the commitWork method
     *
     * @param record An existing record
     **/
    public void registerDirty(SObject record)
    {
        if (record.Id == null)
            throw new UnitOfWorkException('New records cannot be registered as dirty');

        String sObjectType = record.getSObjectType().getDescribe().getName();
        if (!mDirtyMapByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format(SALES_EXCEPTIONMESSAGE, new String[] { sObjectType }));

            mDirtyMapByType.get(sObjectType).put(record.Id, record);
    }

    /**
     * Register a list of existing records to be updated during the commitWork method
     *
     * @param records A list of existing records
     **/
    public void registerDirty(List<SObject> records)
    {
        for (SObject record : records)
            this.registerDirty(record);
    }

    /**
     * Register an existing record to be deleted during the commitWork method
     *
     * @param record An existing record
     **/
    public void registerDeleted(SObject record)
    {
        if (record.Id == null)
            throw new UnitOfWorkException('New records cannot be registered for deletion');

        String sObjectType = record.getSObjectType().getDescribe().getName();
        if (!mDeletedMapByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format(SALES_EXCEPTIONMESSAGE, new String[] { sObjectType }));

        mDeletedMapByType.get(sObjectType).put(record.Id, record);
    }

    /**
     * Register a list of existing records to be deleted during the commitWork method
     *
     * @param records A list of existing records
     **/
    public void registerDeleted(List<SObject> records)
    {
        for (SObject record : records)
            this.registerDeleted(record);
    }

    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the database
     **/
    public void commitWork()
    {
        // notify we're starting the commit work
        onCommitWorkStarting();

        // Wrap the work in its own transaction
        Savepoint sp = Database.setSavePoint();
        Boolean wasSuccessful = false;
        try
        {
            // notify we're starting the DML operations
            onDMLStarting();

            // Insert by type
            for (Schema.SObjectType sObjectType : mSObjectTypes)
            {
                mRelationships.get(sObjectType.getDescribe().getName()).resolve();
                mDml.dmlInsert(mNewListByType.get(sObjectType.getDescribe().getName()));
            }

            // Update by type
            for (Schema.SObjectType sObjectType : mSObjectTypes)
            {
                mDml.dmlUpdate(mDirtyMapByType.get(sObjectType.getDescribe().getName()).values());
            }

            // Delete by type (in reverse dependency order)
            Integer objectIdx = mSObjectTypes.size() - 1;
            while (objectIdx >= 0)
            {
                mDml.dmlDelete(mDeletedMapByType.get(mSObjectTypes[objectIdx--].getDescribe().getName()).values());
            }

            // notify we're done with DML
            onDMLFinished();

            // notify we're starting to process registered work
            onDoWorkStarting();

            // Generic work
            for (IDoWork work : mWorkList)
            {
                // This is not so efficient
                // dropped in here because upsert isn't really supported
                // but it will need relationship resolution
                for (Schema.SObjectType sObjectType : mSObjectTypes)
                    mRelationships.get(sObjectType.getDescribe().getName()).resolve();

                work.doWork();
            }

            // notify we've completed processing registered work
            onDoWorkFinished();

            // notify we've completed all steps and are in the final stage of completing
            onCommitWorkFinishing();

            // mark tracker to indicate success
            wasSuccessful = true;
        }
        catch (Exception e)
        {
            // Rollback
            Database.rollback(sp);
            // Throw exception on to caller
            throw e;
        }
        finally
        {
            // notify we're done with commit work
            onCommitWorkFinished(wasSuccessful);
        }
    }
    /**
    * @author Illumina
    * @description 
    */
    private class Relationships
    {
        private List<Relationship> mRelationships = new List<Relationship>();
        /**
        * @author Illumina
        * @description 
        */
        public void resolve()
        {
            // Resolve relationships
            for (Relationship relationship : mRelationships)
            {
                // PricebookEntry.Product2Id, once set, can't be edited, even to the same value
                // Incidentally: this is because of a bug that Illumina reported to Salesforce
                if (relationship.record.getSObjectType() == PricebookEntry.SObjectType
                        && relationship.relatedToField == PricebookEntry.Product2Id
                        && relationship.record.get(relationship.relatedToField) != null)
                {
                    continue;
                }

                // also OpportunityLineItem:PricebookEntryId and OpportunityLineItem:OpportunityId
                // let's just not allow any lookups to change on OpportunityLineItem
                if (relationship.record.getSObjectType() == OpportunityLineItem.SObjectType
                        && relationship.record.get(relationship.relatedToField) != null)
                {
                    continue;
                }
                
                 // also SVMXC__Service_Contract_Products__c
                if (relationship.record.getSObjectType() == SVMXC__Service_Contract_Products__c.SObjectType
                        && relationship.record.get(relationship.relatedToField) != null)
                {
                    continue;
                }
                
                // also SVMXC__Service_Contract_Sites__c 
                if (relationship.record.getSObjectType() == SVMXC__Service_Contract_Sites__c.SObjectType
                        && relationship.record.get(relationship.relatedToField) != null)
                {
                    continue;
                }
                
                // also SVMXC__RMA_Shipment_Line__c 
                if (relationship.record.getSObjectType() == SVMXC__RMA_Shipment_Line__c.SObjectType
                        && relationship.record.get(relationship.relatedToField) != null)
                {
                    continue;
                }

                relationship.record.put(relationship.relatedToField, relationship.relatedTo.Id);
            }
        }
        /**
        * @author Illumina
        * @description 
        */
        public void add(SObject record, Schema.sObjectField relatedToField, SObject relatedTo)
        {
            // Relationship to resolve
            Relationship relationship = new Relationship();
            relationship.record = record;
            relationship.relatedToField = relatedToField;
            relationship.relatedTo = relatedTo;
            mRelationships.add(relationship);
        }
    }
    /**
    * @author Illumina
    * @description 
    */
    private class Relationship
    {
        public SObject record;
        public Schema.sObjectField relatedToField;
        public SObject relatedTo;
    }

    /**
     * UnitOfWork Exception
     **/
    public class UnitOfWorkException extends Exception { }

    /**
     * Internal implementation of Messaging.sendEmail, see outer class registerEmail method
     **/
   /* private class SendEmailWork implements IDoWork
    {
        private List<Messaging.Email> emails;

        public SendEmailWork()
        {
            this.emails = new List<Messaging.Email>();
        }

        public void registerEmail(Messaging.Email email)
        {
            this.emails.add(email);
        }

        public void doWork()
        {
            if (emails.size() > 0)
            Messaging.sendEmail(emails);
        }
    }*/

}