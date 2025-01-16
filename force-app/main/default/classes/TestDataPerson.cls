/**
 * Lead, contact, partner records
 **/
 @isTest

    public with sharing class TestDataPerson {

    private static final String LEAD_STATUS_MQL = 'Marketing Qualified Lead (MQL)';

    /**Method - Creates and returns new lead */
    public static Lead getNewLead()
    {
        Lead rec = initLead();
        insert rec;
        return rec;
    }

    /**Method - returns new lead */
    public static Lead initLead()
    {
        String rand = TestData.getRandom();
        String rand2 = TestData.getRandom();

        Lead rec = new Lead(
            FirstName = 'Test',
            LastName = 'Lead' + rand,
            Company = rand2,
            Email = rand + '@' + rand2 + '.com',
            Phone = TestData.getRandomNumeric(),
            Status = LEAD_STATUS_MQL,
            CountryCode = 'CA'
        );
        return rec;
    }

    /**Method - creates and inserts new contact */
    public static Contact getNewContact(Id accountId)
    {
        Contact c = initContact(accountId);
        insert c;
        return c;
    }

    /**Method - returns a new contact */
    public static Contact initContact(Id accountId)
    {
        String rand1 = TestData.getRandom();
        String rand2 = TestData.getRandom();
        Contact c = new Contact(
            FirstName = rand1,
            LastName = rand2,
            AccountId = accountId,
            Email = rand1 + '@illumina.com',
            Phone = TestData.getRandomNumeric(),
            MailingCountryCode = 'US'
        );
        return c;
    }

}