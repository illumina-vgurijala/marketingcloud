/*
 * @Author: Nishan Shetty
 * @Date: 24-Aug-2022
 * @Description : Interface created to remove direct binding between the TAPS_Orchestrator and the Domain Classes.
 * @Test Class with 75% coverage
 * @Test Class with 90% coverage
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                 Date                        Description
 * Nishan Shetty           24-Aug-2022                  Initial Version[DCP-44091].
 * ---------------------------------------------------------------------------------------------------------------------------------------
 */
public interface TAPS_OrchestratorInterface {

    void recalculateTerritoryChanges(Set<Id> territoryIds);
    void recalculateAccountChanges(Set<Id> accountIds);
    Boolean recalculateATFSChanges(Set<Id> accountIds);
    void recalculateAccountChangesForObject(SObjectType objectType, Set<Id> accountIds);
    void recalculateRecordChanges(Set<Id> recordIds, SObjectType objectType);
    Set<Id> updateRequiresRecalculation(List<SObject> records, Map<Id, sObject> oldRecords, List<String> parentFieldNames);
}
