/**
 * @author Gerardo Garcia
 * @description Sharing handler for Competitive_Complementary_Technology__c
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Gerardo Garcia                2023-10-02                      Initial Version CMCM-2893
 *   ---------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class TAPS_CompetitiveComplementaryTech extends TAPS_ComposedBase implements TAPS_IObjectsDirect {
    public static final String ACCOUNT_ID = 'Account__c';

    /**
     * @description the object being shared
     * @return SObjectType
     */
    public override SObjectType getObjectType()
    {
        return Competitive_Complementary_Technology__c.SObjectType;
    }

    /**
     * @description Get name of the field linked with the parent account
     * @return String field name
     */
    public override String getLookupFieldName()
    {
        return ACCOUNT_ID;
    }

    /**
     * @description Retrieves the sObject Type of Competitive_Complementary_Technology__Share
     * @param       none
     * @return      SObjectType sharing type
     */
    public override SObjectType getShareObjectType()
    {
        return Competitive_Complementary_Technology__Share.SObjectType;
    }

    /**
     * @description : Creates Sharing entry for CCT(recordId) and userId
     * @params      : recordId, userId
     * @return      : SObject sharing record
     */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Competitive_Complementary_Technology__Share share = new Competitive_Complementary_Technology__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Competitive_Complementary_Technology__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    /*
     *  @Description : Method to filter by role in "direct" territory to only include certain 
     *               from custom Medatada TAPS_Sales_Roles
     *  @Param       : three parameters of type Map<Id, Set<Id>> 
     *  @Return      : Map<Id, Set<Id>>
     */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }
}