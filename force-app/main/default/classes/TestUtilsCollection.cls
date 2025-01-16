/*
* @Author:  Illumina
* @Date:    
* @Description: 
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam               08-Dec-2022                   Codescan Fix , Assert statement added for test methods 
*/
@isTest(SeeAllData = false)

public with sharing class TestUtilsCollection {

    static testMethod void setExtraction()
    {
        Account a1 = TestDataAccount.getAccount('Test Acc 1', 'USD');
        Account a2 = TestDataAccount.getAccount('Test Acc 2', 'USD');
        Account a3 = TestDataAccount.getAccount('Test Acc 3', 'USD');
        Account a4 = TestDataAccount.getAccount('Test Acc 4', 'USD');
        List<Account> accounts = new List<Account> {a1, a2, a3, a4};
        insert accounts;

        List<Account> queriedAccounts = [SELECT Id, OwnerId FROM Account];

        Set<Id> ids1 = UtilsCollection.getSetOfIds(accounts);
        System.assertEquals(4, ids1.size());
        System.assert(ids1.contains(a1.Id));

        Set<Id> ids2 = UtilsCollection.getSetOfIds(queriedAccounts, 'OwnerId');
        System.assertEquals(1, ids2.size());
        System.assert(ids2.contains(UserInfo.getUserId()));

        Set<String> names = UtilsCollection.getSetOfStrings(accounts, 'Name');
        System.assertEquals(4, names.size());
        System.assert(names.contains(a1.Name));
    }

    static testMethod void scalarMapExtraction()
    {
        Account a1 = TestDataAccount.getAccount('Test Acc 1', 'USD');
        Account a2 = TestDataAccount.getAccount('Test Acc 2', 'USD');
        Account a3 = TestDataAccount.getAccount('Test Acc 3', 'USD');
        Account a4 = TestDataAccount.getAccount('Test Acc 4', 'USD');
        List<Account> accounts = new List<Account> {a1, a2, a3, a4};
        insert accounts;

        List<Account> queriedAccounts = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Username FROM Account];

        Map<Id, Id> idToOwnerId = UtilsCollection.getMapOfIdToId(queriedAccounts, 'Id', 'OwnerId');
        System.assertEquals(4, idToOwnerId.size());
        System.assert(idToOwnerId.containsKey(a1.Id));
        System.assertEquals(UserInfo.getUserId(), idToOwnerId.get(a1.Id));

        Map<Id, Set<Id>> idToOwnerIds = UtilsCollection.getMapOfIdToIds(queriedAccounts, 'Id', 'OwnerId');
        System.assertEquals(4, idToOwnerIds.size());
        System.assert(idToOwnerIds.containsKey(a1.Id));
        System.assertEquals(1, idToOwnerIds.get(a1.Id).size());

        Map<String, String> fieldNameToValue = UtilsCollection.getMapOfAPInameToValue(a1, new List<String> {'Name', 'Id'});
        System.assertEquals(a1.Name, fieldNameToValue.get('Name'));

        Map<String, String> ownerNameToUsername = UtilsCollection.getMapOfStringToString(queriedAccounts, 'Owner.Username', 'Owner.Name');
        System.assertEquals(1, ownerNameToUsername.size());
        System.assert(ownerNameToUsername.containsKey(UserInfo.getUserName()));

        Id id1 = queriedAccounts.get(0).Id;
        Id id2 = queriedAccounts.get(1).Id;
        Id id3 = queriedAccounts.get(2).Id;
        Map<Id, Set<Id>> map1 = new Map<Id, Set<Id>> {
            id1 => new Set<Id> {id2},
            id2 => new Set<Id> {id1}
        };
        Map<Id, Set<Id>> map2 = new Map<Id, Set<Id>> {
            id1 => new Set<Id> {id3},
            id3 => new Set<Id> {id1}
        };
        Map<Id, Set<Id>> mergedMap = UtilsCollection.getMergeMap(map1, map2);
        System.assertEquals(2, mergedMap.get(id1).size());
        System.assertEquals(1, mergedMap.get(id2).size());
        System.assertEquals(1, mergedMap.get(id3).size());

        Set<Id> flattenedIds = UtilsCollection.flattenMapValueSets(mergedMap);
        System.assertEquals(3, flattenedIds.size());

        Id oneId = UtilsCollection.getFirstIdFromSet(flattenedIds);
        System.assert(flattenedIds.contains(oneId));
    }

    static testMethod void objectMapExtraction()
    {
        Account a1 = TestDataAccount.getAccount('Test Acc 1', 'USD');
        Account a2 = TestDataAccount.getAccount('Test Acc 2', 'USD');
        Account a3 = TestDataAccount.getAccount('Test Acc 3', 'USD');
        Account a4 = TestDataAccount.getAccount('Test Acc 4', 'USD');
        List<Account> accounts = new List<Account> {a1, a2, a3, a4};
        insert accounts;

        List<Account> queriedAccounts = [SELECT Id, Name, OwnerId, Owner.Id, Owner.Name, Owner.Username FROM Account];

        Map<Id, List<SObject>> idToOwner = UtilsCollection.getMapOfIdToSObjects(queriedAccounts, 'OwnerId', 'Owner');
        User valueRecord = (User)idToOwner.get(UserInfo.getUserId()).get(0);
        System.assertEquals(1, idToOwner.size());
        System.assert(idToOwner.containsKey(UserInfo.getUserId()));
        System.assertEquals(UserInfo.getUserName(), valueRecord.Username);

        Map<Id, List<SObject>> ownerIdToRecs = UtilsCollection.getMapOfIdToSObjects(queriedAccounts, 'OwnerId');
        System.assertEquals(1, ownerIdToRecs.size());
        System.assertEquals(4, ownerIdToRecs.get(UserInfo.getUserId()).size());

        Map<String, List<SObject>> nameToRecs = UtilsCollection.getMapOfStringToSObjects(queriedAccounts, 'Name');
        System.assertEquals(4, nameToRecs.size());
        System.assert(nameToRecs.containsKey(a3.Name));
    }

    static testMethod void scalaInspiredMethods()
    {
        Integer setSize = 100;
        List<User> users = [SELECT Id, Username FROM User LIMIT :setSize];
        Set<Id> ids = UtilsCollection.getSetOfIds(users);
        Set<String> namesSet = UtilsCollection.getSetOfStrings(users, 'Username');
        List<String> names = new List<String>(namesSet);

        Integer chunkSize = 8;
        List<Set<Id>> chunkedIds = UtilsCollection.sliding(ids, chunkSize);
        Integer expectedSize = setSize / chunkSize
            + (Math.mod(setSize, chunkSize) > 0 ? 1 : 0); // remainder
        System.assertEquals(expectedSize, chunkedIds.size());

        Set<Id> firstChunkIds = UtilsCollection.take(ids, chunkSize);
        List<Id> lstIds = new List<Id>(ids); // as the method does
        System.assertEquals(chunkSize, firstChunkIds.size());
        System.assert(firstChunkIds.contains(lstIds.get(0)));

        Set<Id> lastChunkIds = UtilsCollection.takeRight(ids, chunkSize);
        System.assertEquals(chunkSize, lastChunkIds.size());
        System.assert(lastChunkIds.contains(lstIds.get(setSize - 1)));

        List<String> firstChunkStrings = UtilsCollection.take(names, chunkSize);
        List<String> lstStrings = new List<String>(names); // as the method does
        System.assertEquals(chunkSize, firstChunkStrings.size());
        System.assert(firstChunkStrings.contains(lstStrings.get(0)));

        List<String> lastChunkStrings = UtilsCollection.takeRight(names, chunkSize);
        System.assertEquals(chunkSize, lastChunkStrings.size());
        System.assert(lastChunkStrings.contains(lstStrings.get(setSize - 1)));
    }

    static testMethod void serialization()
    {
        Integer setSize = 5;
        List<User> users = [SELECT Id, Username FROM User LIMIT :setSize];
        Set<Id> ids = UtilsCollection.getSetOfIds(users);
        Set<String> namesSet = UtilsCollection.getSetOfStrings(users, 'Username');

        String idsSerialized = UtilsCollection.serializeIds(ids);
        Id singleId = UtilsCollection.getFirstIdFromSet(ids);
        System.assert(idsSerialized.contains(singleId));

        String stringsSerialized = UtilsCollection.serializeIds(namesSet);
        String singleString = users.get(1).Username;
        System.assert(stringsSerialized.contains(singleString));
    }

    static testMethod void dmlResults()
    {
        Account a1 = TestDataAccount.getAccount('Test Acc 1', 'USD');
        Account a2 = TestDataAccount.getAccount('Test Acc 2', 'USD');
        Account a3 = TestDataAccount.getAccount('Test Acc 3', 'USD');
        Account a4 = TestDataAccount.getAccount('Test Acc 4', 'USD');
        List<Account> accounts = new List<Account> {a1, a2, a3, a4};
        insert accounts;

        a1.Name = 'New Value';
        a2.Name = 'New Value';
        a3.Name = 'New Value';
        a4.Name = 'New Value';
        List<Database.SaveResult> results = Database.update(accounts);

        UtilsCollection.processSaveResults(results, 'Test Method');

        System.assert(!results.isEmpty(),'Results are empty');

    }

    @isTest static void testConcatenations() {
        List<User> users = [SELECT Id, Username FROM User LIMIT 5];
        Set<Id> setIds = UtilsCollection.getSetOfIds(users);

        String concatenatedString1 = UtilsCollection.concatenateToStringWithDelimiter(setIds, ';');
        String concatenatedString2 = UtilsCollection.concatenateToStringWithDelimiter(users, 'Id', ';');
        String singleString = users.get(1).Id;
        System.assert(concatenatedString1.contains(singleString), 'Concatenated string does not contain the added value as expected');
        System.assert(concatenatedString2.contains(singleString), 'Concatenated string does not contain the added value as expected');
    }

    @isTest static void testAddErrors() {
        Set<String> setKnownErrors = UtilsCollection.addKnownErrors('Complete Error Message', new Set<String>{'Error Message'});
        Set<String> setUnknownErrors = UtilsCollection.addUnknownErrors('Complete Error Message', new Set<String>{'Exception Message'});
        System.assertEquals(1, setKnownErrors.size(), 'Known errors not added as expected');
        System.assertEquals(1, setUnknownErrors.size(), 'Unknown errors not added as expected');
    }

}