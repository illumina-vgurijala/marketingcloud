/**
 * Territory (ETM) records
 **/
  @isTest
public with sharing class TestDataTerritory {

    private final static String ASSOCIATION_MANUAL = 'Territory2Manual';
    public final static String TERRITORY_ROLE_TAM = 'Territory Account Manager';
    public final static String TERRITORY_ROLE_FIELD_MARKETING = 'Field Marketing Manager';
    /**
      * @actor illumina
      * @description
      */
    public static ObjectTerritory2Association getNewAccountTerritoryLink(Account a, Territory2 t)
    {   
        ObjectTerritory2Association assoc =initAccountTerritoryLink(a,t);
        insert assoc;
        return assoc;
     }
     
     //Added by Rahul DCP-25384
    /**
    * 
    *
    * @desc initAccountTerritoryLink [CodeScan Fix]
    */
     public static ObjectTerritory2Association initAccountTerritoryLink(Account a, Territory2 t)
    {

         ObjectTerritory2Association assoc = new ObjectTerritory2Association(
         ObjectId = a.Id,
         Territory2Id = t.Id,
         AssociationCause = ASSOCIATION_MANUAL
         );

         return assoc;
     }
    /**
    * 
    *
    * @desc getNewUserTerritoryLink [CodeScan Fix]
    */
     public static UserTerritory2Association getNewUserTerritoryLink(Id userId, Id territoryId)
     {
         UserTerritory2Association assoc = initUserTerritoryLink(userId, territoryId);
         insert assoc;
         return assoc;
     }
    /**
    * 
    *
    * @desc initUserTerritoryLink [CodeScan Fix]
    */
     public static UserTerritory2Association initUserTerritoryLink(Id userId, Id territoryId)
     {
         UserTerritory2Association assoc = new UserTerritory2Association(
             UserId = userId,
             Territory2Id = territoryId,
             RoleInTerritory2 = TERRITORY_ROLE_TAM
         );
         return assoc;
     }
    /**
    * 
    *
    * @desc initUserTerritoryLinkRole [CodeScan Fix]
    */
     public static UserTerritory2Association initUserTerritoryLinkRole(Id userId, Id territoryId, String territoryRole)
     {
         UserTerritory2Association assoc = new UserTerritory2Association(
                 UserId = userId,
                 Territory2Id = territoryId,
                 RoleInTerritory2 = territoryRole
         );
         return assoc;
     }


    /**
    * 
    *
    * @desc getNewTerritory [CodeScan Fix]
    */
     public static Territory2 getNewTerritory(Id modelId, String name, Id territoryTypeId)
     {
        return getNewTerritory(modelId, name, territoryTypeId, '');
     }
    /**
    * 
    *
    * @desc initTerritory [CodeScan Fix]
    */
     public static Territory2 initTerritory(Id modelId, String name, Id territoryTypeId)
     {
        return initTerritory(modelId, name, territoryTypeId, '');
     }
    /**
    * 
    *
    * @desc getNewTerritory [CodeScan Fix]
    */
     public static Territory2 getNewTerritory(Id modelId, String name, Id territoryTypeId, Id parentId)
     {
         return getNewTerritory(modelId, name, territoryTypeId, parentId, '');
     }
    /**
    * 
    *
    * @desc initTerritory [CodeScan Fix]
    */
     public static Territory2 initTerritory(Id modelId, String name, Id territoryTypeId, Id parentId)
     {
         return initTerritory(modelId, name, territoryTypeId, parentId, '');
     }
     /**
    * 
    *
    * @desc getNewTerritory [CodeScan Fix]
    */
     public static Territory2 getNewTerritory(Id modelId, String name, Id territoryTypeId, String accountPriority)
     {
         Territory2 t = initTerritory(modelId, name, territoryTypeId, accountPriority);
         insert t;
         return t;
     }
     /**
    * 
    *
    * @desc initTerritory [CodeScan Fix]
    */
     public static Territory2 initTerritory(Id modelId, String name, Id territoryTypeId, String accountPriority)
     {
         return initTerritory(modelId, name, territoryTypeId, null, accountPriority);
     }
     
    /**
    * 
    *
    * @desc getNewTerritory [CodeScan Fix]
    */
     public static Territory2 getNewTerritory(Id modelId, String name, Id territoryTypeId, Id parentId, String accountPriority)
     {
         Territory2 t = initTerritory(modelId, name, territoryTypeId, parentId, accountPriority);
         insert t;
         return t;
     }
     /**
    * 
    *
    * @desc initTerritory [CodeScan Fix]
    */
     public static Territory2 initTerritory(Id modelId, String name, Id territoryTypeId, Id parentId, String accountPriority)
     {
         Territory2 t = new Territory2(
             DeveloperName = name,
             Name = name,
             Territory2TypeId = territoryTypeId,
             Territory2ModelId = modelId,
             ParentTerritory2Id = parentId,
             Account_Owner_Priority__c = accountPriority
         );
         return t;
     }

    //         // rule
    //         ObjectTerritory2AssignmentRule rule = new ObjectTerritory2AssignmentRule(
    //             Territory2ModelId = modelId,
    //             DeveloperName = 'TestRule_Ohio',
    //             MasterLabel = 'TestRule - Ohio',
    //             ObjectType = 'Account',
    //             IsActive = true
    //         );
    //         insert rule;

    //         // rule item
    //         ObjectTerritory2AssignmentRuleItem ruleItem = new ObjectTerritory2AssignmentRuleItem(
    //             RuleId = rule.Id,
    //             Field = 'Account.BillingStateCode',
    //             Operation = 'contains',
    //             SortOrder = 1,
    //             Value = 'OH'
    //         );
    //         insert ruleItem;

    //         rule.BooleanFilter = '1';
    //         update rule;

    //         // t2-rule
    //         RuleTerritory2Association assoc = new RuleTerritory2Association(
    //             Territory2Id = territory1.Id,
    //             RuleId = rule.Id,
    //             IsInherited = false
    //         );
    //         insert assoc;

}