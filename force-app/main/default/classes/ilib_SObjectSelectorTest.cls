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
private with sharing class ilib_SObjectSelectorTest {

	/* 
	 *  @description : Method to setup test data
	*/
    @testSetup
    static void setupData() {
        // Inserting in reverse order so that we can test the order by of select
        List<Account> accountList = new List<Account> {
                TestDataAccount.getAccount('TestAccount2'),
                TestDataAccount.getAccount('TestAccount1')
        };
        accountList[0].AccountNumber = 'A2';
        accountList[0].AnnualRevenue = 12345.67;
        accountList[1].AccountNumber = 'A1';
        accountList[1].AnnualRevenue = 76543.21;
        insert accountList;
    }

	/* 
	 *  @description : Method to test the query parameters in the selector class
	*/
	@isTest static void testBasics() {
        Testilib_BasicSelector selector = new Testilib_BasicSelector();
		System.assertEquals(null, selector.getSObjectFieldSetList());
        System.assertEquals(false, selector.isIncludeFieldSetFields());
        System.assertEquals(false, selector.isEnforcingFLS());
        System.assertEquals(false, selector.isEnforcingCRUD());
        System.assertEquals('Account', selector.getSObjectName());
        System.assertEquals(Account.SObjectType, selector.sObjectType());
        System.assertEquals('Name', selector.getOrderBy());
	}

	/* 
	 *  @description : Method to test the query results from selector 
	*/
    @isTest static void testSelectSObjectsById() {
		//retrieve what was set up in test setup method
		List<Account> accountList = [SELECT Name,AccountNumber, AnnualRevenue FROM Account LIMIT 1000];
		Set<Id> idSet = new Set<Id>();
		for (Account item : accountList)
			idSet.add(item.Id);

		Test.startTest();
		Testilib_SObjectSelector selector = new Testilib_SObjectSelector();
		List<Account> result = (List<Account>) selector.selectSObjectsById(idSet);
		Test.stopTest();

		System.assertEquals(2,result.size());
		System.assertEquals('TestAccount2',result[0].Name);
		System.assertEquals('A2',result[0].AccountNumber);
		System.assertEquals(12345.67,result[0].AnnualRevenue);
		System.assertEquals('TestAccount1',result[1].Name);
		System.assertEquals('A1',result[1].AccountNumber);
		System.assertEquals(76543.21,result[1].AnnualRevenue);
	}

	/* 
	 *  @description : Method to test the query results from querylocator
	*/
    @isTest static void testQueryLocatorById() {
		//retrieve what was set up in test setup method
		List<Account> accountList = [SELECT Name,AccountNumber, AnnualRevenue FROM Account LIMIT 1000];
		Set<Id> idSet = new Set<Id>();
		for (Account item : accountList)
			idSet.add(item.Id);

		Test.startTest();
		Testilib_SObjectSelector selector = new Testilib_SObjectSelector();
		Database.QueryLocator result = selector.queryLocatorById(idSet);
		System.Iterator<SObject> iteratorResult = result.iterator();
		Test.stopTest();

		System.assert(true, iteratorResult.hasNext());
		Account account = (Account) iteratorResult.next();
		System.assertEquals('TestAccount2',account.Name);
		System.assertEquals('A2',account.AccountNumber);
		System.assertEquals(12345.67,account.AnnualRevenue);
		System.assert(true, iteratorResult.hasNext());
		account = (Account) iteratorResult.next();
		System.assertEquals('TestAccount1',account.Name);
		System.assertEquals('A1',account.AccountNumber);
		System.assertEquals(76543.21,account.AnnualRevenue);
		System.assertEquals(false, iteratorResult.hasNext());
	}

	/* 
	 *  @description : Method to test the assert permissions for user
	*/
    @isTest static void testAssertIsAccessible() {
		//retrieve what was set up in test setup method
		List<Account> accountList = [SELECT Name, AccountNumber, AnnualRevenue FROM Account LIMIT 1000];
		Set<Id> idSet = new Set<Id>();
		for (Account item : accountList)
			idSet.add(item.Id);

		// Create a user which will not have access to the test object type
		User testUser = createChatterExternalUser();
		if (testUser == null)
			return; // Abort the test if unable to create a user with low enough acess
		System.runAs(testUser)
		{
			Testilib_SObjectSelector selector = new Testilib_SObjectSelector();
			try
			{
				List<Account> result = (List<Account>) selector.selectSObjectsById(idSet);
				System.assert(false,'Expected exception was not thrown');
			}
			catch (ilib_SObjectDomain.DomainException e)
			{
				System.assertEquals('Permission to access an Account denied.',e.getMessage());
			}
		}
	}

	/* 
	 *  @description : Method to test the CRUD permissions for the user
	*/
    @isTest static void testCRUDOff() {
		//retrieve what was set up in test setup method
		List<Account> accountList = [SELECT Name,AccountNumber, AnnualRevenue FROM Account LIMIT 1000];
		Set<Id> idSet = new Set<Id>();
		for (Account item : accountList)
			idSet.add(item.Id);

		// Create a user which will not have access to the test object type
		User testUser = createChatterExternalUser();
		if (testUser == null)
			return; // Abort the test if unable to create a user with low enough acess
		System.runAs(testUser)
		{
			Testilib_SObjectSelector selector = new Testilib_SObjectSelector(false, false, false, true);

			try
			{
				selector.selectSObjectsById(idSet);
			}
			catch (ilib_SObjectDomain.DomainException e)
			{
				System.assert(false, 'Did not expect an exception to be thrown');
			}
		}
	}

	/* 
	 *  @description : Method to test the generated SOQL query
	*/
    @isTest static void testSOQL(){
		Testilib_SObjectSelector selector = new Testilib_SObjectSelector();
		String soql = selector.newQueryFactory().toSOQL();
		Pattern p = Pattern.compile('SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ');
		Matcher m = p.matcher(soql);
		System.assert(m.matches(), 'Generated SOQL does not match expected pattern. Here is the generated SOQL: ' + soql);
		System.assertEquals(1, m.groupCount(), 'Unexpected number of groups captured.');
		String fieldListString = m.group(1);
		assertFieldListString(fieldListString, null);
	}

	private static void assertFieldListString(String fieldListString, String prefix) {
		String prefixString = (!String.isBlank(prefix)) ? prefix + '.' : '';
		List<String> fieldList = fieldListString.split(',{1}\\s?');
		System.assertEquals(UserInfo.isMultiCurrencyOrganization() ? 5 : 4, fieldList.size());
		Set<String> fieldSet = new Set<String>();
		fieldSet.addAll(fieldList);
		String expected = prefixString + 'AccountNumber';
		System.assert(fieldSet.contains(expected), expected + ' missing from field list string: ' + fieldListString);
		expected = prefixString + 'AnnualRevenue';
		System.assert(fieldSet.contains(expected), expected + ' missing from field list string: ' + fieldListString);
		expected = prefixString + 'Id';
		System.assert(fieldSet.contains(expected), expected + ' missing from field list string: ' + fieldListString);
		expected = prefixString + 'Name';
		System.assert(fieldSet.contains(expected), expected + ' missing from field list string: ' + fieldListString);
		if (UserInfo.isMultiCurrencyOrganization()) {
			expected = prefixString + 'CurrencyIsoCode';
			System.assert(fieldSet.contains(expected), expected + ' missing from field list string: ' + fieldListString);
		}
	}

	/* 
	 *  @description : Method to test the sorting pattern in SOQL
	*/
	@isTest static void testWithoutSorting() {
		//Given
		Testilib_SObjectSelector selector = new Testilib_SObjectSelector(false, false, false, false);
		ilib_QueryFactory qf = selector.newQueryFactory(true);

		Set<String> expectedSelectFields = new Set<String>{ 'Name', 'Id', 'AccountNumber', 'AnnualRevenue' };
		if (UserInfo.isMultiCurrencyOrganization()) {
			expectedSelectFields.add('CurrencyIsoCode');
		}

		//When
		String soql = qf.toSOQL();

		//Then
		Pattern soqlPattern = Pattern.compile('SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ');
		Matcher soqlMatcher = soqlPattern.matcher(soql);
		soqlMatcher.matches();

		List<String> actualSelectFields = soqlMatcher.group(1).deleteWhiteSpace().split(',');
		System.assertEquals(expectedSelectFields, new Set<String>(actualSelectFields));
	}

	/* 
	 *  @description : Method to test subqueries in the SOQL from selector class
	*/
    @isTest static void testAddSubselectToQuery() {
        Testilib_BasicSelector accountSelector = new Testilib_BasicSelector();
        Testilib_OpportunitySelector opptSelector = new Testilib_OpportunitySelector();

        ilib_QueryFactory opptQueryFactory =
                opptSelector.addQueryFactorySubselect(accountSelector.newQueryFactory());
        String soql = opptQueryFactory.toSOQL();
        System.assert(soql.contains('FROM Opportunities'));
    }

	/* 
	 *  @description : Method to test name prefixes in the SOQL query from selector
	*/
    @isTest static void testNamePrefix() {
        ilib_QueryFactory opportunitiesQueryFactory = new Testilib_OpportunitySelector().newQueryFactory();

        ilib_QueryFactory lineItemsQueryFactory =
                new Testilib_OpportunityLinesSelector().
                        addQueryFactorySubselect(opportunitiesQueryFactory);

        new Testilib_ProductsSelector().
                configureQueryFactoryFields(lineItemsQueryFactory, 'PricebookEntry.Product2');

        String soql = opportunitiesQueryFactory.toSOQL();
        System.assert(soql.contains('PricebookEntry.Product2.'));
        // SELECT Name, Id, StageName, CloseDate, CurrencyIsoCode,  (SELECT Id, OpportunityId, Product2Id, CurrencyIsoCode, PricebookEntry.Product2.Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.CurrencyIsoCode FROM OpportunityLineItems ORDER BY Name ASC NULLS FIRST ) FROM Opportunity ORDER BY Name ASC NULLS FIRST
    }

	/*
	 *  @author: Illumina
	 *  @description: Private inner class to implement selector for Account object
	*/
    private class Testilib_SObjectSelector extends ilib_SObjectSelector {
		
		/**
		 *  @description: Call to the constructor from the parent class 
		*/
		public Testilib_SObjectSelector() {
			super();
		}

		/* 
		 *  @author: Illumina
		 *  @description : Call to the parameterized constructor from the parent class
		 *  @param Boolean includeFieldSetFields Set to true if the Selector queries are to include Fieldset fields as well
		 *  @param Boolean enforceCRUD Enforce CRUD security
		 *  @param Boolean enforeFLS Enforce Field Level Security
		 *  @param Boolean sortSelectFields Set to false if selecting many columns to skip sorting select fields and improve performance
		 *  @return: NA
		*/
		public Testilib_SObjectSelector(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields) {
			super(includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields);
		}

		/* 
		 *  @author: Illumina
		 *  @description : Returns list of fields from Account object
		 *  @param       : NA
		 *  @return      : List<Schema.SObjectField>
		*/
		public List<Schema.SObjectField> getSObjectFieldList() {
			return new List<Schema.SObjectField> {
				Account.Name,
				Account.Id,
				Account.AccountNumber,
				Account.AnnualRevenue
			};
		}

		/* 
		 *  @author: Illumina
		 *  @description : Returns type for Account object
		 *  @param       : NA
		 *  @return      : Schema.SObjectType 
		*/
		public Schema.SObjectType getSObjectType() {
			return Account.sObjectType;
		}

		/* 
		 *  @author: Illumina
		 *  @description : To set the order by parameter in the SOQL query
		 *  @param       : NA
		 *  @return      : NA
		*/
		public override String getOrderBy() {
			return 'Name DESC, AnnualRevenue ASC';
		}
	}

	/*
	 *  @author: Illumina
	 *  @description: Private inner class to implement the basic selector for Account object
	*/
    private class Testilib_BasicSelector extends ilib_SObjectSelector {

		/* 
		 *  @author: Illumina
		 *  @description : Constructor to set the includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields parameters to false
		*/
        public Testilib_BasicSelector() {
            super(false, false, false, false);
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns list of fields from Account object
		 *  @param       : NA
		 *  @return      : List<Schema.SObjectField>
		*/
        public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField> {
                    Account.Name,
                    Account.Id,
                    Account.AccountNumber,
                    Account.AnnualRevenue
            };
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns type for Account object
		 *  @param       : NA
		 *  @return      : Schema.SObjectType
		*/
        public Schema.SObjectType getSObjectType() {
            return Account.sObjectType;
        }
    }

	/*
	 *  @author: Illumina
	 *  @description: Private inner class to implement selector for Opportunity object
	*/
    private class Testilib_OpportunitySelector extends ilib_SObjectSelector {

		/* 
		 *  @author: Illumina
		 *  @description : Constructor to set the includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields parameters to false
		*/
        public Testilib_OpportunitySelector() {
            super(false, false, false, false);
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns list of fields from Opportunity object
		 *  @param       : NA
		 *  @return      : List<Schema.SObjectField>
		*/
        public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField> {
                    Opportunity.Name,
                    Opportunity.Id,
                    Opportunity.StageName,
                    Opportunity.CloseDate
            };
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns type for Opportunity object
		 *  @param       : NA
		 *  @return      : Schema.SObjectType
		*/
        public Schema.SObjectType getSObjectType() {
            return Opportunity.sObjectType;
        }
    }

	/*
	 *  @author: Illumina
	 *  @description: Private inner class to implement selector for OpportunityLineItem object
	*/
    private class Testilib_OpportunityLinesSelector extends ilib_SObjectSelector {

		/* 
		 *  @author: Illumina
		 *  @description : Constructor to set the includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields parameters to false
		*/
        public Testilib_OpportunityLinesSelector() {
            super(false, false, false, false);
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns list of fields from OpportunityLineItem object
		 *  @param       : NA
		 *  @return      : List<Schema.SObjectField>
		*/
        public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField> {
                    OpportunityLineItem.Id,
                    OpportunityLineItem.OpportunityId,
                    OpportunityLineItem.Product2Id
            };
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns type for OpportunityLineItem object
		 *  @param       : NA
		 *  @return      : Schema.SObjectType
		*/
        public Schema.SObjectType getSObjectType() {
            return OpportunityLineItem.sObjectType;
        }
    }

	/*
	 *  @author: Illumina
	 *  @description: Private inner class to implement selector for Product2 object
	*/
    private class Testilib_ProductsSelector extends ilib_SObjectSelector {

		/* 
		 *  @author: Illumina
		 *  @description : Constructor to set the includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields parameters to false
		*/
        public Testilib_ProductsSelector() {
            super(false, false, false, false);
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns list of fields from Product2 object
		 *  @param       : NA
		 *  @return      : List<Schema.SObjectField>
		*/
        public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField> {
                    Product2.Id,
                    Product2.Name,
                    Product2.ProductCode
            };
        }

		/* 
		 *  @author: Illumina
		 *  @description : Returns type for Product2 object
		 *  @param       : NA
		 *  @return      : Schema.SObjectType
		*/
        public Schema.SObjectType getSObjectType() {
            return Product2.sObjectType;
        }
    }

    /**
     * @description : Create test user
     **/
	private static User createChatterExternalUser() {
		// Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
		List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name='Chatter External' limit 1];
		if (testProfiles.size() != 1)
			return null;

		// Can only proceed with test if we can successfully insert a test user
		String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
		User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
		try {
			insert testUser;
		}
		catch (Exception e) {
			return null;
		}
		return testUser;
	}

}