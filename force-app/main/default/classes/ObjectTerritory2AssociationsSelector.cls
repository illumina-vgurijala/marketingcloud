/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Selector class for UserTerritory2Association
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Kushagra Desai        15-Nov-2019           selectByAccountIdsNonGlobal()
* Joshith K             17-Dec-2019           INC0242945-added selectDirectByAccountIds()
* KD                    6-Aug-2020             DCP-39561 Added new method selectOnlyDirectByAccountId
* KD                    3-Sept-2020             DCP-39735 : added select field in selectIndirectByAccountIds
* Prabhsimran Singh     9-Sept-2020             DCP-39733 : refactor static queries to dynamic	
*    KD                21-Sept-2020            DCP-41752 : Updated method 'getByTerritoryName' to 'getByTerritoryCode'
* KD                   25-Sept-2020            DCP-41767 : Added related field.
* Ashwin Kumar         16-Apr-2021             INC0316527 - Added condition Territory2.Territory2Model.State = Active in selectByTerritoryId()
* Nishan Shetty        11-Aug-2021             CMCP-23- Added Territory Type Developername in selectIndirectByAccountIds and query instrumentation.
* Ashwin Kumar         24-Aug-2021             TASK0587523 : Updated ObjectTerritory2AssociationsSelector.selectOnlyDirectByAccountId method to accept List param
*/
public with sharing class ObjectTerritory2AssociationsSelector extends ilib_SObjectSelector {

    private final static String GLOBALTERRITORY = Label.Global_Territory_Type;
	private final static String MODEL_STATE_ACTIVE = Territories2.MODEL_STATE_ACTIVE;
    private static final String LOG_TITLE = 'ObjectTerritory2AssociationsSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';

    /**
     * @author Akshay Mohan
     * @date   07-06-2018
     * @description  constructor to call the base class
     */
    public ObjectTerritory2AssociationsSelector()
    {
        super(false, false, false, false);
        //m_orderBy = '';
    }

    /**
     * @author Akshay Mohan
     * @date   07-06-2018
     * @description  set select fields
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            ObjectTerritory2Association.Id,
            ObjectTerritory2Association.AssociationCause,
            ObjectTerritory2Association.ObjectId,
            ObjectTerritory2Association.Territory2Id
        };
    }

    /**
     * @author Akshay Mohan
     * @date   07-06-2018
     * @description  describe the object
     */
    public Schema.SObjectType getSObjectType()
    {
        // Does not work, rediculous!!
        //return ObjectTerritory2Association.sObjectType;
        return Schema.getGlobalDescribe().get('ObjectTerritory2Association');
    }

    /**
     *  Not needed now may need in future
     * @author Akshay Mohan
     * @date   07-06-2018
     * @description  get records by territory id
     * @param Set of Territory Id
     */
    public List<ObjectTerritory2Association> selectByTerritoryId(Set<Id> territoryIds)
    {
        //INC0316527 - Added condition Territory2.Territory2Model.State = Active
        return Database.query(
            newQueryFactory(true)
            .selectField('Territory2.Territory_Code__c')
            .selectField('ObjectId')
            .setCondition('Territory2Id IN :territoryIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE')
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
    public List<ObjectTerritory2Association> selectByAccountIds(Set<Id> accountIds)
    {
        return Database.query(            
            getSelectByAccountIdQueryFactory()
            .setCondition('ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );
    }
    /**
     * @author Kushagra
     * @date   15-Nov-2019
     * @description  get records by territory id for non global territory.
     * @param Set of Territory Id
     * @param Set of Exclusion roles
     */
    public List<ObjectTerritory2Association> selectByAccountIdsNonGlobal(Set<Id> accountIds)
    {
        // excluding global territory	
        Set<String> salesAndChannelTypes = new Set<String>();	
        salesAndChannelTypes.addAll(TerritorytypesService.ALL_SALES_TYPES);	
        salesAndChannelTypes.addAll(TerritorytypesService.ALL_CHANNEL_TYPES);
        return Database.query(
            getSelectByAccountIdQueryFactory()
            .selectField('Territory2.Territory2Type.Developername')
            .setCondition('ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND Territory2.Territory2Type.DeveloperName in :salesAndChannelTypes')
            .toSOQL()
        );
    }

	//Method to create fields for query dynamically.
    private ilib_QueryFactory getSelectByAccountIdQueryFactory()
    {
        ilib_QueryFactory factory = newQueryFactory(true);
        for (Integer i = 0; i < Territories2.MAX_TERRITORY_DEPTH -1; i++)
        {
            String columnPrefix = 'Territory2.';
            for (Integer j = 1; j < i+1; j++)
            {
                columnPrefix += 'ParentTerritory2.';
            }
            factory = factory.selectField(columnPrefix + 'Name')
            .selectField(columnPrefix + 'ParentTerritory2Id');
        }
        return factory;
    }
	
    /**
     * @author Vishnu Priya Duggineni
     * @date   12-10-2018
     * @description  get records by territory id for channel partners
     * @param Set of Territory Id
     */
    public List<ObjectTerritory2Association> selectIndirectByAccountIds(Set<Id> accountIds)
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE + '.selectIndirectByAccountIds', UtilsCollection.serializeIds(accountIds));
        }
         
        String cp = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';
        List<ObjectTerritory2Association> res = (List<ObjectTerritory2Association>) Database.query(
            newQueryFactory(true)
            .selectField('Territory2.Territory_Code__c')
            .selectField('Territory2.Territory2Type.DeveloperName')//CMCP-23
            // DCP-41767
            .selectField('Object.Name')
            .setCondition('ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND Territory2.Territory2Type.MasterLabel like :cp')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger.stop(res == null ? 0 : 1);
        }

        return res;
       
    }

    /**
     * @author Joshith K
     * @date   12-10-2018
     * @description  get records by Account  id for Direct Terittories.
     * @param Set of Account Id
     */
    public List<ObjectTerritory2Association> selectDirectByAccountIds(Set<Id> accountIds)
    {
        String cp = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';
        return Database.query(
            newQueryFactory(true)
            .setCondition('ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND ( NOT Territory2.Territory2Type.MasterLabel like :cp)')
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   06-26-2020
     * @description  DCP-39108 o get Territory Association with Territory Code. 
     * @param Set - Territory Code
     // DCP-41752 : Updated method to pass territory Code.
     */
    public List<ObjectTerritory2Association> getByTerritoryCode(Set<String> setTerritoryCode){
        return Database.query(
            newQueryFactory(true)
            .selectField('Object.Name')
            .setCondition('Territory2.Territory_Code__c IN :setTerritoryCode AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   6-Aug-2020
     * @description  DCP-39561 get records by Account  id for ILMN Sales Terittories.
     * @param Account Id
     */
    public List<ObjectTerritory2Association> selectOnlyDirectByAccountId(List<String> lstAccountIds)    //TASK0587523
    {
        String cp = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';
        return Database.query(
            newQueryFactory(true)
            .selectField('Territory2.Name')
            .selectField('Territory2.Territory_Code__c')
            .setCondition('ObjectId IN :lstAccountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND Territory2.Territory2Type.MasterLabel !=:GLOBALTERRITORY AND ( NOT Territory2.Territory2Type.MasterLabel like :cp)')
            .toSOQL()
        );
    }
    /**
     * @author Juned
     * @date   13-Sep-2021
     * @description  DCP-48251 get records by Account id and Territory Type.
     * @param AccountId , MasterLabel 
     */
    public List<ObjectTerritory2Association> indirectTerritoryPlanByMasterLabel(String  strAccountId, List<String> lstMasterLabel)
    {
        return Database.query(
            newQueryFactory(true)
            .selectField('ObjectId')
            .setCondition('ObjectId =: strAccountId AND Territory2.Territory2Type.MasterLabel IN: lstMasterLabel AND Territory2.Territory2Model.State =: MODEL_STATE_ACTIVE')
            .toSOQL()
        );
    }
}