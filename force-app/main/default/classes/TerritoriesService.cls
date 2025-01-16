/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Service class for the Territory2 Object
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Aman Tyagi            31-mar-2022                CodeScan Fixes
* 
*/
global with sharing class TerritoriesService {

    /*
    * @Author:Akshay Mohan
    * @Description : this method has logic for fetching the user id who are able to access leaf based on id
    * @param : Set<Id> leafTerritoryIds
    */
    public static Map<Id, Set<Id>> getAllUserIdsWhoCanAccessLeaf(Set<Id> leafTerritoryIds)
    {
        Map<Id, Set<Id>> territoryIdToTreeUserIds = new Map<Id, Set<Id>>();
        if (leafTerritoryIds == null || leafTerritoryIds.size() == 0) return territoryIdToTreeUserIds;

        // get parents of leaf territories 
        Map<Id, Set<Id>> leafIdToParentIds = new TerritoriesSelector().selectTerritoriesInHierarchy(leafTerritoryIds);

        // add all IDs up so that we can query all users
        Set<Id> allTerritoryIds = new Set<Id>();
        for (Id i : leafIdToParentIds.keySet())
        {
            allTerritoryIds.add(i);
            if (leafIdToParentIds.get(i) != null)
                allTerritoryIds.addAll(leafIdToParentIds.get(i));
        }

        // get the users associated with all territories
        List<UserTerritory2Association> allUserAssociations = new UserTerritory2AssociationSelector().selectByTerritoryId(allTerritoryIds);
        Map<Id, Set<Id>> territoryIdToUserIds = UtilsCollection.getMapOfIdToIds(allUserAssociations, 'Territory2Id', 'UserId');

        // combine the users from anywhere in the tree into which leaf they are associated with
        for (Id leafId : leafIdToParentIds.keySet())
        {
            Set<Id> combinedUserIds = new Set<Id>();

            if (territoryIdToUserIds.get(leafId) != null)
                combinedUserIds.addAll(territoryIdToUserIds.get(leafId));
            for (Id parentT2 : leafIdToParentIds.get(leafId))
            {
                if (territoryIdToUserIds.get(parentT2) != null)
                    combinedUserIds.addAll(territoryIdToUserIds.get(parentT2));
            }

            if (combinedUserIds.size() > 0)
                territoryIdToTreeUserIds.put(leafId, combinedUserIds);
        }

        return territoryIdToTreeUserIds;
    }

}