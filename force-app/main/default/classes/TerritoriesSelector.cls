/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Service class for the Territory2 Object
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Roopal Verma          05-02-2018                 Commented methods selectById and selectParentsInHierarchy as no references found.
* KD                    12-Aug-2020                 Added getTerritoryCodeIncludingParents
* Akshay                19-Aug-2020                 Added common relationship field logic
* KD                    26-Aug-2020                 DCP-39437 : Added selectLeafTerritoriesByTerritoryId
* KD                    9-Sep-2020                 DCP-39107 Fetch all territory By Id
* Prabhsimran Singh     9-Sep-2020                 DCP-39733 refactor static queries to dynamic
* Akshay Mohan          21-Sep-2020                 DCP-41644: Change query for leaf nodes
* Ashwin Kumar          16-Apr-2021                 INC0316527 - Added condition Territory2Model.State = Active in selectChildrenByTerritoryId()
* Jitesh Lakhwani       6-July-2022                 Code Scan fixes of Comments
*/
public with sharing class TerritoriesSelector extends ilib_SObjectSelector {

	private final static String MODEL_STATE_ACTIVE = Territories2.MODEL_STATE_ACTIVE;
	private final static String PARENT_TERRITORY2_KEYWORD = 'ParentTerritory2.';
	
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  constructor to call base class
    *  
    */
    public TerritoriesSelector()
    {
        super(false, false, false, false);
        //m_orderBy = '';
    }
    
    /**
    * @description: Method to retrieve the SObjectType of Territory2
    * @param : None
    * @return: Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Territory2.sObjectType;
    }

    /**
    * @description: Method to retrieve the list of Territory2 for the set of id's passed as paramerter
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: List<Territory2>
    */
    public List<Territory2> selectById(Set<Id> idSet)
    {
        return (List<Territory2>)selectSObjectsById(idSet);
    }

    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  select fields
    *  
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Territory2.Id,
            Territory2.ParentTerritory2Id,
            Territory2.Name,
            Territory2.Territory2TypeId,
            Territory2.District__c,
            Territory2.Subregion__c,
            Territory2.Business_Unit__c,
            Territory2.Territory_Region__c,
            Territory2.Territory_Code__c,
            Territory2.OpportunityAccessLevel,
            Territory2.CaseAccessLevel
        };
    }
	
	/*
    * @author Prabhsimran Singh
    * @date   09-09-2020
    * @description  DCP-39733 method to generate dynamic fields
    *  
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        ilib_QueryFactory factory = newQueryFactory(true);
        for (Integer i = 0; i < Territories2.MAX_TERRITORY_DEPTH; i++)
        {
            String columnPrefix = '';
            for (Integer j = 1; j < i+1; j++)
            {
                columnPrefix += PARENT_TERRITORY2_KEYWORD;
            }
            factory = factory.selectField(columnPrefix + 'ParentTerritory2Id');         
        }
        return factory;
    }

    /**
    * @description: Method to retrieve the set of Territory2 including parent territories for the set of id's passed as paramerter
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: Set<Id>
    */
    public Set<Id> getTerritoryIdsIncludingParents(Set<Id> idSet)
    {        

        List<Territory2> leafNodes = (List<Territory2>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Id IN :idSet AND Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );

        Set<Id> territoryIdsIncludingParents = new Set<Id>();
        for (Territory2 t : leafNodes)
        {
            territoryIdsIncludingParents.add(t.Id);
			String parentTerritoryField = 'ParentTerritory2Id';
            while(TerritoriesSelector.getValue(t,parentTerritoryField) != null){
                territoryIdsIncludingParents.add((Id)TerritoriesSelector.getValue(t,parentTerritoryField));
                parentTerritoryField = PARENT_TERRITORY2_KEYWORD+parentTerritoryField;
            }
		}
        return territoryIdsIncludingParents;
    }

    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  select records with hierarchy
    *  
    */
    public Map<Id, Set<Id>> selectTerritoriesInHierarchy(Set<Id> idSet)
    {        

        List<Territory2> leafNodes = (List<Territory2>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Id IN :idSet AND Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );

        Map<Id, Set<Id>> leafIdToParentIds = new Map<Id, Set<Id>>();
        for (Territory2 t : leafNodes)
        {
            leafIdToParentIds.put(t.Id, new Set<Id>());
            //Added Dynamic loop for parent territory Ids
            String parentTerritoryField = 'ParentTerritory2Id';
            while(TerritoriesSelector.getValue(t,parentTerritoryField) != null){
                leafIdToParentIds.get(t.Id).add((Id)TerritoriesSelector.getValue(t,parentTerritoryField));
                parentTerritoryField = PARENT_TERRITORY2_KEYWORD+parentTerritoryField;
            }
        }

        return leafIdToParentIds;
    }

    /**
    * @description: Method receives modified node, return everything below it (up to 4 levels), assumption is highest we could modify is Region
                    so return BUs, subregions, districts and territories, the client will be responsible to add the source territories to this list if desired
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: Set<Id>
    */
    public List<Territory2> selectChildrenByTerritoryId(Set<Id> territoryIds)
    {
		String fieldCondition = '';
        for (Integer i = 0; i < Territories2.MAX_TERRITORY_DEPTH; i++)
        {
            String columnPrefix = '';
            for (Integer j = 1; j < i+1; j++)
            {
                columnPrefix += PARENT_TERRITORY2_KEYWORD;
            }
            fieldCondition += columnPrefix + 'ParentTerritory2Id IN :territoryIds OR ';         
        }
        fieldCondition = fieldCondition.removeEnd('OR ');
        
        //INC0316527 - Added condition Territory2Model.State = Active
        fieldCondition = String.isNotBlank(fieldCondition) ? 
                                '('+ fieldCondition + ')' + ' AND Territory2Model.State = :MODEL_STATE_ACTIVE' : 'Territory2Model.State = :MODEL_STATE_ACTIVE';
        ilib_LogEvent.message('TerritoriesSelector.selectChildrenByTerritoryId Query: '+newQueryFactory(true)
                                                                                    .setCondition(fieldCondition)
                                                                                    .toSOQL());
        return Database.query(
            newQueryFactory(true)
            .setCondition(fieldCondition)
            .toSOQL()
        );
    }

    /**
    * @description: Method to retrieve the list of Territory2 to understand what is the type of the territory for the set of id's passed as paramerter
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: List<Territory2>
    */
    public List<Territory2> getTerritoryTypes(Set<Id> idSet)
    {
        List<Territory2> recordDetails = (List<Territory2>)Database.query(
            newQueryFactory(false)
                .selectField(Territory2.Id)
                .selectField(Territory2.Name)
                .selectField('Territory2Type.MasterLabel')
                .setCondition('Id IN :idSet')
                .toSOQL()
        );

        return recordDetails;
    }

    /**
    * @description: Method to retrieve the list of direct territories for the set of id's passed as paramerter.
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: List<Territory2>
    */
    public List<Territory2> keepDirectTerritories(Set<Id> territoryIds)
    {
        String channelPartnerLikeValue = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';

        return Database.query(
            newQueryFactory(true)
            .setCondition('Id IN :territoryIds AND (NOT Territory2Type.MasterLabel LIKE :channelPartnerLikeValue )')
            .toSOQL()
        );
    }
     
    /**
    * @description: Method to retrieve the list of Indirect territories for the set of id's passed as paramerter.
    * @param : Set<Id> idSet - set of Territory2 id's
    * @return: List<Territory2>
    */
    public List<Territory2> keepIndirectTerritories(Set<Id> territoryIds)
    {
        String channelPartnerLikeValue = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';

        return Database.query(
            newQueryFactory(true)
            .setCondition('Id IN :territoryIds AND Territory2Type.MasterLabel like :channelPartnerLikeValue')
            .toSOQL()
        );
    }
    
    /**
     * @author KD
     * @date   6-Aug-2020
     * @description  DCP-39119 Fetch all parent territory in hierarchy
     * @param Set Territory Code
     */
    public Set<Id> getTerritoryCodeIncludingParents(Set<String> setTerritoryCode)
    {
        List<Territory2> leafNodes = getByTerritoryCode(setTerritoryCode);

        Set<Id> territoryIdsIncludingParents = new Set<Id>();
        for (Territory2 t : leafNodes)
        {
            territoryIdsIncludingParents.add(t.Id);
            if (String.isNotBlank(t.ParentTerritory2Id))
                territoryIdsIncludingParents.add(t.ParentTerritory2Id);
            if (String.isNotBlank(t.ParentTerritory2.ParentTerritory2Id))
                territoryIdsIncludingParents.add(t.ParentTerritory2.ParentTerritory2Id);
            if (String.isNotBlank(t.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                territoryIdsIncludingParents.add(t.ParentTerritory2.ParentTerritory2.ParentTerritory2Id);
            if (String.isNotBlank(t.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                territoryIdsIncludingParents.add(t.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id);
        }

        return territoryIdsIncludingParents;
    }

    /**
     * @author Akshay
     * @date   19-Aug-2020
     * @description  DCP-39119 Fetch all parent territory in hierarchy
     * @param Set Territory Code
     */
    public List<Territory2> getByTerritoryCode(Set<String> setTerritoryCode){

        return (List<Territory2>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Territory_Code__c IN :setTerritoryCode AND Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );
    }
     /*
    * @author Kushagra Desai
    * @date   10-08-2019
    * @description  DCP-39437 : get the all territory in leaf node
    *  
    */
    public List<Territory2> selectLeafTerritoriesByTerritoryId(Set<Id> territoryId)
    {
        String strTerritoryType = TerritoryTypesService.TYPE_TERRITORY;
        String activeState = MODEL_STATE_ACTIVE;
        return Database.query(
            getRelatedFieldsQuery()
            .setCondition(
                    '( id IN : territoryId '+
                    'OR ParentTerritory2Id IN :territoryId ' +
                    'OR ParentTerritory2.ParentTerritory2Id IN :territoryId ' +
                    'OR ParentTerritory2.ParentTerritory2.ParentTerritory2Id IN :territoryId ' +
                    'OR ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id  IN :territoryId) ' +
                    'AND Territory2Model.State = :activeState ' +
                    'AND Territory2Type.MasterLabel =:strTerritoryType'
            )
            .toSOQL()
        );
    }
    /**
     * @author KD
     * @date   9-Sept-2020
     * @description  DCP-39107 Fetch all territory By Id
     * @param Set Territory Code
     */
    public List<Territory2> getByTerritoryId(Set<Id> setTerritoryId){
        return (List<Territory2>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Id IN :setTerritoryId AND Territory2Model.State = :MODEL_STATE_ACTIVE')
            .toSOQL()
        );
	}
	
	/**
     * @author Prabhsimran Singh
     * @date   10-Sept-2020
     * @description  Method to return the value of parent lookup fields of dynamic soql
     * @param sObject record and field api name
     */
    public static Object getValue(SObject record, String fieldApi) {
        try {
            SObject tempRecord = record;
            String[] parts = fieldApi.split('\\.');            
            while(parts.size() > 1) {                
                tempRecord = tempRecord.getSObject(parts.remove(0));                
            }            
            return tempRecord.get(parts[0]);
        } catch(Exception e) {
            return null;
        }
    }
	

}