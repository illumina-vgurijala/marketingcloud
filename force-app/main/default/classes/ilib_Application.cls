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
**/

/**
 * Class provides inner classes implementing factories for the main components
 * of the Apex Enterprise Patterns, Service, Unit Of Work, Selector and Domain.
 *   See the sample applications Application.cls file for an example
 **/
public class ilib_Application
{

    /**
     * Class implements a Unit of Work factory
     **/
    public class UnitOfWorkFactory
    {
        private List<SObjectType> mobjectTypes;

        /**
         * Constructs a Unit Of Work factory
         *
         * @param objectTypes List of SObjectTypes in dependency order
         **/
        public UnitOfWorkFactory(List<SObjectType> objectTypes)
        {
            mobjectTypes = objectTypes.clone();
        }

        /**
         * Returns a new ilib_SObjectUnitOfWork configured with the
         *   SObjectType list provided in the constructor
         **/
        public ilib_ISObjectUnitOfWork newInstance()
        {
            return new ilib_SObjectUnitOfWork(mobjectTypes);
        }

        /**
         * Returns a new ilib_SObjectUnitOfWork configured with the
         *   SObjectType list specified
         **/
        public ilib_ISObjectUnitOfWork newInstance(List<SObjectType> objectTypes)
        {
            return new ilib_SObjectUnitOfWork(objectTypes);
        }
    }

    /**
     * Simple Service Factory implementaiton
     **/
    public class ServiceFactory
    {
        private Map<Type, Type> mserviceInterfaceTypeByServiceImplType;

        /**
         * Constructs a simple Service Factory,
         *   using a Map of Apex Interfaces to Apex Classes implementing the interface
         *   Note that this will not check the Apex Classes given actually implement the interfaces
         *     as this information is not presently available via the Apex runtime
         *
         * @param serviceInterfaceTypeByServiceImplType Map ofi interfaces to classes
         **/
        public ServiceFactory(Map<Type, Type> serviceInterfaceTypeByServiceImplType)
        {
            mserviceInterfaceTypeByServiceImplType = serviceInterfaceTypeByServiceImplType;
        }

        /**
         * Returns a new instance of the Apex class associated with the given Apex interface
         *   Note that this method will not check the configured Apex class actually implements the interface
         *
         * @param serviceInterfaceType Apex interface type
         * @exception Is thrown if there is no registered Apex class for the interface type
         **/
        public Object newInstance(Type serviceInterfaceType)
        {
            // Create an instance of the type impleneting the given interface
            Type serviceImpl = mserviceInterfaceTypeByServiceImplType.get(serviceInterfaceType);
            if (serviceImpl == null)
                throw new DeveloperException('No implementation registered for service interface ' + serviceInterfaceType.getName());
            return serviceImpl.newInstance();
        }
    }

    /**
     * Class implements a Selector class factory
     **/
    public class SelectorFactory
    {
        private Map<SObjectType, Type> msObjectBySelectorType;

        /**
         * Constructs a Selector Factory linking SObjectType's with Apex Classes implement the ilib_ISObjectSelector interface
         *   Note that the factory does not chekc the given Apex Classes implement the interface
         *     currently this is not possible in Apex.
         *
         * @Param sObjectBySelectorType Map of SObjectType's to Selector Apex Classes
         **/
        public SelectorFactory(Map<SObjectType, Type> sObjectBySelectorType)
        {
            msObjectBySelectorType = sObjectBySelectorType;
        }

        /**
         * Creates a new instance of the associated Apex Class implementing ilib_ISObjectSelector
         *   for the given SObjectType
         *
         * @param sObjectType An SObjectType token, e.g. Account.SObjectType
         **/
        public ilib_ISObjectSelector newInstance(SObjectType sObjectType)
        {
            // Determine Apex class for Selector class
            Type selectorClass = msObjectBySelectorType.get(sObjectType);
            if (selectorClass == null)
                throw new DeveloperException('Selector class not found for SObjectType ' + sObjectType);

            // Construct Selector class and query by Id for the records
            return (ilib_ISObjectSelector) selectorClass.newInstance();
        }

        /**
         * Helper method to query the given SObject records
         *   Internally creates an instance of the registered Selector and calls its
         *     selectSObjectById method
         *
         * @param recordIds The SObject record Ids, must be all the same SObjectType
         * @exception Is thrown if the record Ids are not all the same or the SObjectType is not registered
         **/
        public List<SObject> selectById(Set<Id> recordIds)
        {
            // No point creating an empty Domain class, nor can we determine the SObjectType anyway
            if (recordIds == null || recordIds.size() == 0)
                throw new DeveloperException('Invalid record Id\'s set');

            // Determine SObjectType
            SObjectType domainSObjectType = new List<Id>(recordIds)[0].getSObjectType();
            for (Id recordId : recordIds)
                if (recordId.getSobjectType() != domainSObjectType)
                    throw new DeveloperException('Unable to determine SObjectType, Set contains Id\'s from different SObject types');

            // Construct Selector class and query by Id for the records
            return newInstance(domainSObjectType).selectSObjectsById(recordIds);
        }

        /**
         * Helper method to query related records to those provided, for example
         *   if passed a list of Opportunity records and the Account Id field will
         *   construct internally a list of Account Ids and call the registered
         *   Account selector to query the related Account records, e.g.
         *
         *     List<Account> accounts =
         *        (List<Account>) Applicaiton.Selector.selectByRelationship(myOpps, Opportunity.AccountId);
         *
         * @param relatedRecords used to extract the related record Ids, e.g. Opportunty records
         * @param relationshipField field in the passed records that contains the relationship records to query, e.g. Opportunity.AccountId
         **/
        public List<SObject> selectByRelationship(List<SObject> relatedRecords, SObjectField relationshipField)
        {
            Set<Id> relatedIds = new Set<Id>();
            for (SObject relatedRecord : relatedRecords)
            {
                Id relatedId = (Id) relatedRecord.get(relationshipField);
                if(relatedId != null)
                    relatedIds.add(relatedId);
            }
            return selectById(relatedIds);
        }
    }

    /**
     * Class implements a Domain class factory
     **/
    public class DomainFactory
    {
        private ilib_Application.SelectorFactory mselectorFactory;

        private Map<SObjectType, Type> msObjectByDomainConstructorType;

        /**
         * Consturcts a Domain factory, using an instance of the Selector Factory
         *   and a map of Apex classes implementing ilib_ISObjectDomain by SObjectType
         *   Note this will not check the Apex classes provided actually implement the interfaces
         *     since this is not possible in the Apex runtime at present
         *
         * @param selectorFactory, e.g. Application.Selector
         * @param sObjectByDomainConstructorType Map of Apex classes by SObjectType
         **/
        public DomainFactory(ilib_Application.SelectorFactory selectorFactory,
            Map<SObjectType, Type> sObjectByDomainConstructorType)
        {
            mselectorFactory = selectorFactory;
            msObjectByDomainConstructorType = sObjectByDomainConstructorType;
        }

        /**
         * Dynamically constructs an instance of a Domain class for the given record Ids
         *   Internally uses the Selector Factory to query the records before passing to a
         *   dynamically constructed instance of the application Apex Domain class
         *
         * @param recordIds A list of Id's of the same type
         * @exception Throws an exception via the Selector Factory if the Ids are not all of the same SObjectType
         **/
        public ilib_ISObjectDomain newInstance(Set<Id> recordIds)
        {
            return newInstance(mselectorFactory.selectById(recordIds));

        }

        /**
         * Dynamically constructs an instace of the Domain class for the given records
         *
         * @param records A concreate list (e.g. List<Account> vs List<SObject>) of records
         * @exception Throws an exception if the SObjectType cannot be determined from the list
         *              or the constructor for Domain class was not registered for the SOBjectType
         **/
        public ilib_ISObjectDomain newInstance(List<SObject> records)
        {
            SObjectType domainSObjectType = records.getSObjectType();
            if (domainSObjectType == null)
                throw new DeveloperException('Unable to determine SObjectType');

            // Determine SObjectType and Apex classes for Domain class
            Type domainConstructorClass = msObjectByDomainConstructorType.get(domainSObjectType);
            if (domainConstructorClass == null)
                throw new DeveloperException('Domain constructor class not found for SObjectType ' + domainSObjectType);

            // Construct Domain class passing in the queried records
            ilib_SObjectDomain.IConstructable domainConstructor =
                (ilib_SObjectDomain.IConstructable) domainConstructorClass.newInstance();
            return (ilib_ISObjectDomain) domainConstructor.construct(records);
        }

        /**
         * Dynamically constructs an instace of the Domain class for the given records and SObjectType
         *
         * @param records A list records
         * @param domainSObjectType SObjectType for list of records
         * @exception Throws an exception if the SObjectType is not specified or if constructor for Domain class was not registered for the SObjectType
         *
         * @remark Will support List<SObject> but all records in the list will be assumed to be of
         *         the type specified in sObjectType
         **/
        public ilib_ISObjectDomain newInstance(List<SObject> records, SObjectType domainSObjectType)
        {
            if (domainSObjectType == null)
                throw new DeveloperException('Must specify sObjectType');

            // Determine SObjectType and Apex classes for Domain class
            Type domainConstructorClass = msObjectByDomainConstructorType.get(domainSObjectType);
            if (domainConstructorClass == null)
                throw new DeveloperException('Domain constructor class not found for SObjectType ' + domainSObjectType);

            // Construct Domain class passing in the queried records
            ilib_SObjectDomain.IConstructable2 domainConstructor =
                (ilib_SObjectDomain.IConstructable2) domainConstructorClass.newInstance();
            return (ilib_ISObjectDomain) domainConstructor.construct(records, domainSObjectType);
        }
    }
    /**
     * @author Illumina
     * @description 
     */
    public class ApplicationException extends Exception { }

    /**
     * Exception representing a developer coding error, not intended for end user eyes
     **/
    public class DeveloperException extends Exception { }

}