/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Selector class for UserTerritory2Association
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Kushagra Desai        25-July-2020                Added method "selectByUserIdsWithType"
* Anisha Bharti         20-Aug-2020                 Added method "selectOnlyDirectByUserId"
* KD                    26-Aug-2020                 Updated method "selectOnlyDirectByUserId"
* KD                    9-Sep-2020                 Add field in getRelatedFieldsQuery
* Vaibhav               10-Sep-2020                 Added updates for DCP-37827
* Rucha Dalvi           05-July-2022                Codescan Fix - Duplicate Literals
*/
public with sharing class UserTerritory2AssociationSelector extends ilib_SObjectSelector {

  //Codescan Fix - Duplicate Literals  
  public static final String STRING_ACTIVE = 'Active';
    //private static final String GLOBALTERRITORY = Label.Global_Territory_Type;
    private String strOrderByClause;
    private String strOrderByClauseForSelectByUserWebEmailAddressesMethod; //DCP-37827

    /**
    * @description Set Association Selector
    * @author  
    **/
    public UserTerritory2AssociationSelector()
    {
        super(false, false, false, false);
        //m_orderBy = '';
    }

    /**
    * @description returns a list
    * @author 
    * @return List<Schema.SObjectField> 
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            UserTerritory2Association.Id,
            UserTerritory2Association.IsActive,
            UserTerritory2Association.RoleInTerritory2,
            UserTerritory2Association.UserId,
            UserTerritory2Association.Territory2Id,
            UserTerritory2Association.LastModifiedDate
        };
    }

    
    /**
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return UserTerritory2Association.sObjectType;
    }

    /*//DCP-39966
    * @description  Related field
    *
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
                .selectField('User.Name')
                .selectField('Territory2.Name')
                .selectField('Territory2.Territory_Code__c')
                // Added as part of DCP-39107
                .selectField('Territory2.Territory_Region__c')
                //Added as a part of DCP-37827
                .selectField('User.Email')
                .selectField('User.ProfileId')
                .selectField('Territory2.District__c')
                .selectField('Territory2.Territory2Model.State');
                
    }
    

  /**
    * @description  call default orderby method and override with additional parameters
    */
    public override String getOrderBy() {
    string orderBy;

    if (String.isNotBlank(strOrderByClause)) {
      orderBy = strOrderByClause;
    } else if (String.isNotBlank(strOrderByClauseForSelectByUserWebEmailAddressesMethod)) {
      orderBy = strOrderByClauseForSelectByUserWebEmailAddressesMethod;
    } else {
      orderBy = super.getOrderBy();
    }
    return orderBy;
  }

    /**
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  get records by territory id
    * @param Set of Territory Id
    */
    public List<UserTerritory2Association> selectByTerritoryId(Set<Id> territoryIds)
    {
        return Database.query(
            getRelatedFieldsQuery()
            .setCondition('Territory2Id IN :territoryIds AND User.IsActive = true')
            .toSOQL()
        );
    }

    /**
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  get records by territory id
    * @param Set of Territory Id
    */
    public List<UserTerritory2Association> selectByTerritoryIdIncludeInactive(Set<Id> territoryIds)
    {
        return Database.query(
            newQueryFactory(true)
            .setCondition('Territory2Id IN :territoryIds')
            .toSOQL()
        );
    }

    /**
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  get records by territory id
    * @param Set of Territory Id
    * @param Set of Exclusion roles
    */
    public List<UserTerritory2Association> selectWithDisplayDetailsByTerritoryId(Set<Id> territoryIds,Set<String> setExcludeRoles)
    {
        String activeModelState = STRING_ACTIVE;

        ilib_QueryFactory qf = newQueryFactory(false);

        // remove default order by clause
        // NOTE: this is a bit of a hassle, build it into the base class
        List<ilib_QueryFactory.Ordering> orderings = qf.getOrderings();
        if (orderings.size() > 0)
            for (Integer i = orderings.size() - 1; i >= 0; i--)
                orderings.remove(i);

        // NOTE: the following 4 lines do not compile. C'mon, Salesforce!
        // .selectField(UserTerritory2Association.User.Email)
        // .selectField(UserTerritory2Association.User.Name)
        // .selectField(UserTerritory2Association.Territory2.Name)
        // .selectField(UserTerritory2Association.Territory2.Territory2Type.DeveloperName)
        ilib_QueryFactory queryWithFields = qf
            .selectField(UserTerritory2Association.LastModifiedDate)
            .selectField(UserTerritory2Association.UserId)
            .selectField('User.Email')
            .selectField('User.Name')
            .selectField(UserTerritory2Association.RoleInTerritory2)
            .selectField('Territory2.Name')
            .selectField('Territory2.Territory2Type.Priority')
            .selectField('Territory2.Territory2Type.MasterLabel');

        // since a user could be assigned at multiple levels, this query might duplicate users
        List<UserTerritory2Association> associationsWithDupes = Database.query(
            queryWithFields
            .setCondition('Territory2Id IN :territoryIds AND User.IsActive = true '
            + ' AND Territory2.Territory2Model.State = :activeModelState '
            + ' AND RoleInTerritory2 NOT IN :setExcludeRoles')
            .addOrdering('Territory2.Territory2Type.Priority', ilib_QueryFactory.SortOrder.DESCENDING, true)
            .addOrdering('User.Name', ilib_QueryFactory.SortOrder.ASCENDING, true)
            .toSOQL()
        );

        return associationsWithDupes;

//        // remove dupes
//        Set<Id> userIds = new Set<Id>();
//        List<UserTerritory2Association> uniqueAssociations = new List<UserTerritory2Association>();
//        for (UserTerritory2Association a : associationsWithDupes)
//        {
//            if (userIds.contains(a.UserId)) continue;
//            userIds.add(a.UserId);
//            uniqueAssociations.add(a);
//        }
//
//        return uniqueAssociations;
    }

    /**
    * @author Vishnu Priya Duggineni
    * @date   10-24-2018
    * @description  get records by all territory id and roles
    * @param Set of Territory Id, List of roles
    * @return List of territory associated emails and roles
    */
    public List<UserTerritory2Association> selectUsersByTerritoriesAndRoles(Set<Id> territoryIds, List<String> roles)
    {
        ilib_QueryFactory qf = newQueryFactory(false);

        // NOTE: the following lines do not compile. C'mon, Salesforce!
        // .selectField(UserTerritory2Association.User.Email)
        // .selectField(UserTerritory2Association.User.Name)
        ilib_QueryFactory queryWithFields = qf
            .selectField(UserTerritory2Association.UserId)
            .selectField(UserTerritory2Association.Territory2Id)
            .selectField(UserTerritory2Association.RoleInTerritory2)
            .selectField('Territory2.Territory_Code__c')
            .selectField('User.Email')
            .selectField('User.Name');

        // since a user could be assigned at multiple levels, this query might duplicate users
        List<UserTerritory2Association> associations = Database.query(
            queryWithFields
            .setCondition('Territory2Id IN :territoryIds AND User.IsActive = true AND RoleInTerritory2 IN :roles')
            .toSOQL()
        );

        return associations;
    }

    /**
    * @author Vishnu Priya Duggineni
    * @date   03/26/2019
    * @description  get territories associated with users
    * @param Set of Territory Id
    */
    public List<UserTerritory2Association> selectByUserIds(Set<Id> userIds)
    {
        String activeModelState = STRING_ACTIVE;
        return Database.query(
            getRelatedFieldsQuery()
            .setCondition('UserId IN :userIds AND User.IsActive = true AND Territory2.Territory2Model.State = :activeModelState')
            .toSOQL()
        );
    }
    /**
    * @author KD
    * @date   25-July-2020
    * @description  get territories associated with users and specific type
    * @param Set of Territory Id
    */
    public List<UserTerritory2Association> selectByUserIdsWithType(Set<Id> userIds,String strTerritoryType)
    {
        return Database.query(
            getRelatedFieldsQuery()
            .setCondition('UserId IN :userIds AND User.IsActive = true AND Territory2.Territory2Model.State = :STRING_ACTIVE and Territory2.Territory2Type.DeveloperName =:strTerritoryType')
            .toSOQL()
        );
    }
   
    /**
    * @author Anisha
    * @date   20-Aug-2020
    * @description  DCP-39736 get records by territory type
    * @param Set of Users
    */
    public List<UserTerritory2Association> selectOnlyDirectByUserId(Set<Id> userIds)
    {
        Set<String> setDirectTerritoryType = new Set<String>{
            TerritoryTypesService.TYPE_BU,
            TerritoryTypesService.TYPE_REGION,
            TerritoryTypesService.TYPE_SUBREGION,
            TerritoryTypesService.TYPE_STREAM,
            TerritoryTypesService.TYPE_DISTRICT,
            TerritoryTypesService.TYPE_TERRITORY
        };
        strOrderByClause = 'Territory2.Territory2Type.Priority ASC';
        return Database.query(
            getRelatedFieldsQuery()
            .setCondition('UserId IN :userIds AND User.IsActive = true AND Territory2.Territory2Model.State = :STRING_ACTIVE AND Territory2.Territory2Type.DeveloperName IN :setDirectTerritoryType')
            .toSOQL()
        );
    }
    
    /**
   * @author Vaibhav
   * @date   10-Sep-2020
   * @description  DCP-37827 - get territories associated with users by user web email
   * @param Set of user web email addresses
   */
  public List < UserTerritory2Association > selectByUserWebEmailAddresses(Set < string > setWebEmailAddresses) {
    strOrderByClauseForSelectByUserWebEmailAddressesMethod = 'Territory2.District__c ASC';
    String activeModelState = STRING_ACTIVE;
    String territoryType = 'Territory';
    return Database.query(
      getRelatedFieldsQuery()
      .setCondition('User.Email IN: setWebEmailAddresses AND User.IsActive = true AND Territory2.Territory2Model.State = :activeModelState AND Territory2.District__c != null AND Territory2.Territory2Type.MasterLabel =:territoryType')
      .toSOQL()
    );
  }
  
  /**
   * @author maruthi
   * @date   15-Sep-2021
   * @description  IP2-51 - get territories associated with Account
   */
  public List<UserTerritory2Association> selectTerrAssoForISR(List<String> terrNameList, String roleName) {
    strOrderByClause = 'Territory2.name , LastModifiedDate desc';
    return Database.query(
      getRelatedFieldsQuery()
      .setCondition('Territory2.Name =:terrNameList and RoleInTerritory2 = :roleName')
      .toSOQL()
    );
  }

  /**
   * @author Maruthi
   * @date   15-Sep-2021
   * @description  IP2-51 - get territories associated with users by TerritoryName, Role and Region
   * @param Set TerritoryName, Role and Region 
   */
  public List <UserTerritory2Association> selectTerritoryAssociationNonChina(Set<string> accountTerrNameSet, Set<string> setRoles, Set<string> setRegion) {
    //strOrderByClauseForSelectByUserWebEmailAddressesMethod = 'Territory2.District__c ASC';
    String activeModelState = STRING_ACTIVE;    
    return Database.query(
      getRelatedFieldsQuery()
      .setCondition('Territory2.Name =:accountTerrNameSet and RoleInTerritory2 =:setRoles and Territory2.Territory_Region__c =:setRegion and Territory2.Territory2Model.State =:activeModelState')
      .toSOQL()
    );
  }
}