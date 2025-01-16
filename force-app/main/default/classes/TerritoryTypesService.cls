/* Territorytype service class
* NAME         : TerritoryTypesService
* DESCRIPTION  : Service Class
*                    
* @AUTHOR : 
* @DATE   : 
*  
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                  9-Aug-2021          Added new Static Value TYPE_TERRITORY_VAD_CP and updated TYPE_TERRITORY_CP v
*                                                               value with Territory Distributor Channel Partner and also added method
*                                                               getAccountToTerritoryTypeMap to return map of Account to Territory Type Map.
*            Nishan Shetty                  2-Sep-2021          Added Label for VAD Territory Type and Corrected Label for Territory Distributor Channel Partner [CMCP-20].]
*            Aman Tyagi                     31-Mar-2022         CodeScan Fixes
*    -------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class TerritoryTypesService {

    public final static String TYPE_STREAM = 'Business_Stream';
    public final static String TYPE_TERRITORY = 'Territory';
    public final static String TYPE_TERRITORY_CP = TYPE_TERRITORY + '_Distributor_' + Territories2.CHANNEL_PARTNER_LABEL;//CMCP-23
    public final static String TYPE_TERRITORY_VAD_CP = TYPE_TERRITORY + '_Value_Added_Distributor_' + Territories2.CHANNEL_PARTNER_LABEL;//CMCP-23
    public final static String LABEL_TYPE_TERRITORY_CP = 'Territory Distributor Channel Partner';//CMCP-20
    public final static String TYPE_DISTRICT = 'District';
    public final static String TYPE_SUBREGION = 'Sub_Region';
    public final static String TYPE_BU = 'Business_Unit';
    public final static String TYPE_REGION = 'Region';
    public final static String TYPE_PARENT_GROUP = 'Parent_Group';
	public final static Set<String> ALL_SALES_TYPES = new Set<String> {TYPE_STREAM, TYPE_TERRITORY, TYPE_DISTRICT, TYPE_SUBREGION, TYPE_BU, TYPE_REGION, TYPE_PARENT_GROUP};
    public final static String TYPE_DISTRICT_CP = 'District' + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static String TYPE_SUBREGION_CP = 'Sub_Region' + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static String TYPE_BU_CP = 'Business_Unit' + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static String TYPE_REGION_CP = 'Region' + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static String TYPE_STREAM_CP = 'Business_Stream' + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static Set<String> ALL_CHANNEL_TYPES = new Set<String> {TYPE_TERRITORY_CP,TYPE_TERRITORY_VAD_CP,TYPE_DISTRICT_CP, TYPE_SUBREGION_CP, TYPE_BU_CP, TYPE_REGION_CP, TYPE_STREAM_CP};
    public final static String LABEL_TYPE_TERRITORY_VAD_CP = 'Territory Value Added Distributor Channel Partner';//CMCP-20

    private static List<Territory2Type> territoryTypes;

    /*
    * @Author: Nishan Shetty
    * @Description : method for fetching 2type id based on typename
    * @param : String typeName
    * @return : Id
    */
    public static Id pickT2TypeIdFromList(String typeName)
    {
        retrieveTypes();

        for (Territory2Type type : territoryTypes)
            if (type.DeveloperName == typeName) return type.Id;
        return null;
    }

    private static void retrieveTypes()
    {
        if (territoryTypes == null)
        {
            TerritoryTypesSelector selector = new TerritoryTypesSelector();
            territoryTypes = selector.selectKnownTypes();
        }
    }

    /*
    *  @author Nishan Shetty (CMCP-23)
    *  @description - Method to prepare map of account to territory type of Channel Partner.
    *  @PARAM : Set<Id> - set - set of Account Ids.
    *  @RETURN: Map<Id,String> - Map of Account Id to Territory Type.
    */
    public static Map<Id,String> getAccountToTerritoryTypeMap(Set<Id> setAccountIds) {
        Map<Id,String> mapAccountIdToTerritoryType =new Map<Id,String>();
        List<ObjectTerritory2Association> lstObjTerritoryAssociation = new List<ObjectTerritory2Association>(new ObjectTerritory2AssociationsSelector().selectIndirectByAccountIds(setAccountIds));

        for(ObjectTerritory2Association objOTA:lstObjTerritoryAssociation) {
            String strTerritoryType=objOTA.Territory2.Territory2Type.DeveloperName;
            if(strTerritoryType==TYPE_TERRITORY_VAD_CP) {
               mapAccountIdToTerritoryType.put(objOTA.ObjectId,objOTA.Territory2.Territory2Type.DeveloperName);
            }
        }

        return mapAccountIdToTerritoryType;
    }

}