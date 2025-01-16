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


@IsTest
private class ilib_ApplicationTest
{

    @IsTest
    private static void callingDomainFactoryShouldGiveRegisteredImplsAndMocks()
    {
        // Registered Accounts domain class by SObject List
        Account a = TestDataAccount.getNewAccount();
        ilib_ISObjectDomain domainObjectAcct = DOMAIN.newInstance(new List<Account> { a });
        System.assert(domainObjectAcct instanceof AccountsDomain);
        System.assertEquals(a.Id, domainObjectAcct.getRecords()[0].Id);

        // Registered Accounts domain class by SObject List
        domainObjectAcct = DOMAIN.newInstance(new List<SObject>{ a }, Account.SObjectType);
        System.assert(domainObjectAcct instanceof AccountsDomain);
        System.assertEquals(a.Id, domainObjectAcct.getRecords()[0].Id);
    }

    @IsTest
    private static void callingDomainFactoryWithIdsShouldGiveRegisteredImpls()
    {
        // Given
        Account a = TestDataAccount.getNewAccount();

        // When
        ilib_ISObjectDomain domainObjectAcc = DOMAIN.newInstance(new Set<Id> { a.Id });

        // Then
        List<Account> assertAccounts = (List<Account>) domainObjectAcc.getRecords();
        System.assert(domainObjectAcc instanceof AccountsDomain);
        System.assertEquals(a.Id, domainObjectAcc.getRecords()[0].Id);
        System.assertEquals(1, assertAccounts.size());
        System.assertEquals(a.Id, assertAccounts[0].Id);
        System.assertEquals(a.Name, assertAccounts[0].Name);
    }

    @IsTest
    private static void callingDomainFactoryWithGenericListShouldGiveException()
    {
        try {
            DOMAIN.newInstance(new List<SObject>());
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Unable to determine SObjectType', e.getMessage());
        }
    }

    @IsTest
    private static void callingDomainFactoryWithNoSObjectTypeShouldGiveException()
    {
        try {
            DOMAIN.newInstance(new List<SObject>(), null);
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Must specify sObjectType', e.getMessage());
        }
    }

    @IsTest
    private static void callingDomainFactoryWithInAccessableConstructorShouldGiveException()
    {
        try {
            DOMAIN.newInstance(new List<Product2>{ new Product2(Name = 'Test Product') });
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Domain constructor class not found for SObjectType Product2', e.getMessage());
        }

        try {
            DOMAIN.newInstance(new List<SObject>{ new Product2(Name = 'Test Product') }, Product2.SObjectType);
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Domain constructor class not found for SObjectType Product2', e.getMessage());
        }
    }

    @IsTest
    private static void callingDomainFactoryWithContructorClassThatDoesNotSupportIConstructableShouldGiveException()
    {
        try {
            DOMAIN.newInstance(new List<Contact>{ new Contact(LastName = 'TestContactLName') });
            System.assert(false, 'Expected exception');
        } catch (System.TypeException e) {
            System.assert(Pattern.Matches('Invalid conversion from runtime type \\w*\\.?ilib_ApplicationTest\\.ContactsConstructor to \\w*\\.?ilib_SObjectDomain\\.IConstructable',
                e.getMessage()), 'Exception message did not match the expected pattern: ' + e.getMessage());
        }

        try {
            DOMAIN.newInstance(new List<SObject>{ new Contact(LastName = 'TestContactLName') }, Contact.SObjectType);
            System.assert(false, 'Expected exception');
        } catch (System.TypeException e) {
            System.assert(Pattern.Matches('Invalid conversion from runtime type \\w*\\.?ilib_ApplicationTest\\.ContactsConstructor to \\w*\\.?ilib_SObjectDomain\\.IConstructable2',
                e.getMessage()), 'Exception message did not match the expected pattern: ' + e.getMessage());
        }
    }

    @IsTest
    private static void callingUnitOfWorkFactoryShouldGivenStandardImplsAndMockImpls()
    {
        System.assert(UNITOFWORK.newInstance() instanceof ilib_SObjectUnitOfWork);
        System.assert(UNITOFWORK.newInstance(new List<SObjectType> { Account.SObjectType, Opportunity.SObjectType}) instanceof ilib_SObjectUnitOfWork);
    }

    @IsTest
    private static void callingServiceFactoryShouldGiveRegisteredImplsAndMockImpls()
    {
        // Standard behaviour
        System.assert(SERVICE.newInstance(IAccountService.class) instanceof AccountsServiceImpl);
        System.assert(SERVICE.newInstance(IOpportunitiesService.class) instanceof OpportunitiesServiceImpl);
        try {
            SERVICE.newInstance(IContactService.class);
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('No implementation registered for service interface ' + IContactService.class.getName(), e.getMessage());
        }
    }

    @IsTest
    private static void callingSelectorFactoryShouldGiveRegisteredImpls()
    {
        // Standard behaviour
        System.assert(SELECTOR.newInstance(Account.SObjectType) instanceof AccountsSelector);
        System.assert(SELECTOR.newInstance(Opportunity.SObjectType) instanceof OpportuntiesSelector);
        try {
            SELECTOR.newInstance(User.SObjectType);
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Selector class not found for SObjectType User', e.getMessage());
        }
    }

    @IsTest
    private static void callingSelectorFactorySelectByIdWithEmptyListShouldGiveException()
    {
        try {
            SELECTOR.selectById(null);
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Invalid record Id\'s set', e.getMessage());
        }
        try {
            SELECTOR.selectById(new Set<Id>());
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Invalid record Id\'s set', e.getMessage());
        }
    }

    @IsTest
    private static void callingSelectorFactorySelectByIdWithMixedIdTypeListShouldGiveException()
    {
        Account a = TestDataAccount.getNewAccount();
        Opportunity o = TestDataOpportunity.getNewOpportunity(a);

        try {
            SELECTOR.selectById(new Set<Id> { a.Id, o.Id });
            System.assert(false, 'Expected exception');
        } catch (ilib_Application.DeveloperException e) {
            System.assertEquals('Unable to determine SObjectType, Set contains Id\'s from different SObject types', e.getMessage());
        }
    }

    @IsTest
    private static void callingSelectoryFactorySelectByIdShouldReturnResults()
    {
        // Given
        List<Account> accounts = new List<Account> { TestDataAccount.getNewAccount() };
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        // When
        List<Account> assertAccounts = SELECTOR.selectById(accountIds);

        // Then
        System.assertEquals(1, assertAccounts.size());
        System.assertEquals(accounts.get(0).Id, assertAccounts[0].Id);
        System.assertEquals(accounts.get(0).Name, assertAccounts[0].Name);
        System.assert(SELECTOR.newInstance(Opportunity.SObjectType) instanceof OpportuntiesSelector);
    }

    @IsTest
    private static void callingSelectoryFactorySselectByRelationshipPassRelatedIds()
    {
        // Given
        Account a = TestDataAccount.getNewAccount();
        Opportunity o = TestDataOpportunity.getNewOpportunity(a);
        //List<Account> accounts = new List<Account>{ a };

        // When
        List<Opportunity> opportunties = new List<Opportunity> { o };
        List<Account> assertAccounts = SELECTOR.selectByRelationship(opportunties, Opportunity.AccountId);

        // Then
        System.assertEquals(1, assertAccounts.size());
        System.assertEquals(a.Id, assertAccounts[0].Id);
        System.assertEquals(a.Name, assertAccounts[0].Name);
        System.assert(SELECTOR.newInstance(Opportunity.SObjectType) instanceof OpportuntiesSelector);
    }

    // Configure and create the ServiceFactory for this Application
    public static final ilib_Application.ServiceFactory SERVICE =
        new ilib_Application.ServiceFactory(
            new Map<Type, Type> {
                    IOpportunitiesService.class => OpportunitiesServiceImpl.class,
                    IAccountService.class => AccountsServiceImpl.class });

    // Configure and create the UnitOfWorkFactory for this Application
    public static final ilib_Application.UnitOfWorkFactory UNITOFWORK =
        new ilib_Application.UnitOfWorkFactory(
                new List<SObjectType> {
                    Account.SObjectType,
                    Opportunity.SObjectType,
                    OpportunityLineItem.SObjectType });

    // Configure and create the SelectorFactory for this Application
    public static final ilib_Application.SelectorFactory SELECTOR =
        new ilib_Application.SelectorFactory(
            new Map<SObjectType, Type> {
                    Account.SObjectType => AccountsSelector.class,
                    Opportunity.SObjectType => OpportuntiesSelector.class });

    // Configure and create the DomainFactory for this Application
    public static final ilib_Application.DomainFactory DOMAIN =
        new ilib_Application.DomainFactory(
            ilib_ApplicationTest.SELECTOR,
            new Map<SObjectType, Type> {
                    Account.SObjectType => AccountsConstructor.class,
                    Opportunity.SObjectType => OpportuntiesConstructor.class,
                    Contact.SObjectType => ContactsConstructor.class });

    /**
     * @author illumina
     * @description 
     */
    public class AccountsDomain extends ilib_SObjectDomain
    {
         /**
         * @author illumina
         * @description 
         */
        public AccountsDomain(List<Account> sObjectList)
        {
            super(sObjectList);
        }
         /**
        * @author illumina
        * @description 
        */
        public AccountsDomain(List<SObject> sObjectList, SObjectType sObjectType)
        {
            super(sObjectList, sObjectType);
        }
    }
     /**
     * @author illumina
     * @description 
     */
    public class AccountsConstructor implements ilib_SObjectDomain.IConstructable2
    {
         /**
        * @author illumina
        * @description 
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AccountsDomain(sObjectList);
        }
         /**
        * @author illumina
        * @description 
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType)
        {
            return new AccountsDomain(sObjectList, sObjectType);
        }
    }
     /**
     * @author illumina
     * @description 
     */
    public class OpportuntiesDomain extends ilib_SObjectDomain
    {
         /**
        * @author illumina
        * @description 
        */
        public OpportuntiesDomain(List<Opportunity> sObjectList)
        {
            super(sObjectList);
        }
         /**
        * @author illumina
        * @description 
        */
        public OpportuntiesDomain(List<SObject> sObjectList, SObjectType sObjectType)
        {
            super(sObjectList, sObjectType);
        }
    }
     /**
     * @author illumina
     * @description 
     */
    public class OpportuntiesConstructor implements ilib_SObjectDomain.IConstructable2
    {
         /**
        * @author illumina
        * @description 
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new OpportuntiesDomain(sObjectList);
        }
         /**
        * @author illumina
        * @description 
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType)
        {
            return new OpportuntiesDomain(sObjectList, sObjectType);
        }
    }
 
    /**
    * @author illumina
    * @description Intentionally does not support IConstructable or IConstructable2 interfaces in order to support testing
    */
    public class ContactsConstructor { }

    /**
    * @author illumina
    * @description 
    */
    class OpportuntiesSelector extends ilib_SObjectSelector
    {
        /**
        * @author illumina
        * @description 
        */
        public List<Schema.SObjectField> getSObjectFieldList()
        {
            return new List<Schema.SObjectField> {
                Opportunity.Name,
                Opportunity.Id
            };
        }
        /**
        * @author illumina
        * @description 
        */
        public Schema.SObjectType getSObjectType()
        {
            return Opportunity.sObjectType;
        }
    }
    /**
    * @author illumina
    * @description 
    */
    class AccountsSelector extends ilib_SObjectSelector
    {
        /**
        * @author illumina
        * @description 
        */
        public List<Schema.SObjectField> getSObjectFieldList()
        {
            return new List<Schema.SObjectField> {
                Account.Name,
                Account.Id,
                Account.AccountNumber,
                Account.AnnualRevenue
            };
        }
        /**
        * @author illumina
        * @description 
        */
        public Schema.SObjectType getSObjectType()
        {
            return Account.sObjectType;
        }
    }
    /**
    * @author illumina
    * @description 
    */
    public interface IContactService { }
    /**
    * @author illumina
    * @description 
    */
    public interface IOpportunitiesService { }
    /**
    * @author illumina
    * @description 
    */
    public interface IAccountService { }
    /**
    * @author illumina
    * @description 
    */
    public class OpportunitiesServiceImpl implements IOpportunitiesService { }
    /**
    * @author illumina
    * @description 
    */
    public class AccountsServiceImpl implements IAccountService { }

}