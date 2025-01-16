/**
*    @author Satya Swain
*    @date   17 Feb 2020
*    @description Domain class to store Profiles information
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 17 Feb 2020            INC0220493 - Initial Version
*             KD                          11-May-2020             DCP-37793 : Added QA profile
*             Roopal Verma                23 July 2020           DCP-37254 - Updated Release Admin ID
*             KD                          1-June-2021            DCP-38933 : Added Sevice Snap
*             Jitesh Lakhwani            02-Sept-2022           INC0419938
*    ------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class Profiles extends ilib_SObjectDomain {

    private static final Id SYSTEM_ADMIN = '00e1N000001uZ18';
    private static final Id GIS_ADMIN = '00e1N0000016ew1';
    private static final Id RELEASE_ADMIN = '00e3l000001RBGy';
    private static final String COMMERCIAL_OPS_QUOTING_USER_ID = '00e1N0000016eU9';
    private static final String COMMERCIAL_AND_REVENUE_OPERATIONS_ID = '00e1N0000016eU4';

    private final static Id SNAP_SALES = '00e1N0000016eYp';
    private final static Id SAP_SALES = '00e1N0000016eYn';

    private static final Id SALES_CONTRACTS = '00e1N0000016eYv';
    private static final Id SALES_READ_ONLY = '00e1N0000016f6m';
    private static final Id SALES_USER = '00e1N0000016eTz';
    private static final Id CUSTOMER_SERVICE = '00e1N0000016eYX';

    public static final String CHANNEL_PARTNER_SERVICE_PROFILE = 'Channel Partner Service';
    public static final String CHANNEL_PARTNER_SALES_SERVICE_PROFILE = 'Channel Partner Sales and Service';
    public static final String INTEGRATION_RPA_PROFILE = 'Integration RPA Profile';
    public static final String INTEGRATION_MYILLUMINA_P2P_SERVICE_PROFILE = 'Integration MyIllumina P2P Service';
    public static final String INTEGRATION_IDENTITY_MANAGEMENT_PROFILE = 'Integration Identity Management';
    public final static String PERMSET_APTTUS_READONLY = 'SL_Apttus_Read_Only';
    public final static String PERMSET_SS_SERVICE_OBJECTS = 'SS_Service_Objects';
    public static Set<String> setSuperUserProfile = new Set<String>{System.label.Profile_Release_Manager,System.label.Profile_GIS_Non_Admin,System.label.ProfileSystemAdmin};
    public static Set<String> setQAProfileName = new Set<String>{System.label.Profile_Quality_Assurance};
    public static Set<String> setSystemAdminProfileName = new Set<String>{System.label.ProfileSystemAdmin};
    public static Set<String> setSalesIntegrationProfileName = new Set<String>{System.label.Integration_Sales_SNAP_Profile,System.label.Integration_SAP_Sales};
    public static Set<String> setAllSalesProfileName = new Set<String>{System.label.Profile_Commercial_and_Revenue_Operations,System.label.SalesRepProfileName,System.label.Profile_Commercial_Ops_Quoting_User};
    public static Set<String> setCommercialRevenueOperationsProfileName = new Set<String>{System.label.Profile_Commercial_and_Revenue_Operations};
    public static Set<String> setCommercialOpsQuotingUserProfileName = new Set<String>{System.label.Profile_Commercial_Ops_Quoting_User};
    public static Set<String> setCustomerServiceProfileName = new Set<String>{System.Label.ProfileCustomerService};
    public static Set<String> setMarketingLeadQualificationProfileName = new Set<String>{System.Label.Marketing_Lead_Qualification}; //INC0419938
    public static Set<String> setChannelPartnerProfiles = new Set<String>{CHANNEL_PARTNER_SERVICE_PROFILE, CHANNEL_PARTNER_SALES_SERVICE_PROFILE};
    public static Set<String> setFieldServiceProfileName = new Set<String>{System.Label.ProfileFieldService}; //CMCM-10597
    public static Set<String> setFieldServiceThirdPartyProfileName = new Set<String>{System.Label.Field_Service_Third_Party}; //CMCM-10597
    public static Set<String> setOtherIntegrationProfileName = new Set<String>{INTEGRATION_RPA_PROFILE, INTEGRATION_MYILLUMINA_P2P_SERVICE_PROFILE, INTEGRATION_IDENTITY_MANAGEMENT_PROFILE}; //CMCM-10597

    // DCP-38933
    public static Set<String> setServiceIntegrationProfileName = new Set<String>{System.Label.Integration_SAP_Service,System.Label.Integration_Service_SNAP_Profile};
    /****************************/
    //Deepika
    public static Set<String> setLogisticsProfileName = new Set<String>{System.Label.Profile_Service_Logistics};
    /*****************************/
    public static Map<String,Profile> mapNameToProfile = new Map<String,Profile>();
    /**
    * 
    *
    * @description: Profiles constructor  [CodeScan Fix]
    */
    
    public Profiles(List<Profile> sObjectList) {
        super(sObjectList);
    }

    /**
    * 
    *
    * @description: Constructor  [CodeScan Fix]
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * 
        *
        * @description: Construct  [CodeScan Fix]
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Profiles(sObjectList);
        }
    }


    // sys admin and admin-esque profiles

    /**
    * 
    *
    * @description: getAdminProfileId  [CodeScan Fix]
    */
    public static Set<Id> getAdminProfileId() {
        return new Set<Id> {SYSTEM_ADMIN};
    }

    /**
    * 
    *
    * @description: getAllAdminProfileIds  [CodeScan Fix]
    */
    public static Set<Id> getAllAdminProfileIds() {
        return new Set<Id> {SYSTEM_ADMIN, GIS_ADMIN, RELEASE_ADMIN};
    }

    // integration profiles
    /**
    * 
    *
    * @description: getSalesIntegrationProfileIds  [CodeScan Fix]
    */
    public static Set<Id> getSalesIntegrationProfileIds() {
        return new Set<Id> {SNAP_SALES, SAP_SALES};
    }
    // sales profiles
    /**
    * 
    *
    * @description: getAllSalesProfileIds  [CodeScan Fix]
    */
    public static Set<Id> getAllSalesProfileIds() {
        return new Set<Id> {SALES_CONTRACTS, COMMERCIAL_AND_REVENUE_OPERATIONS_ID, SALES_READ_ONLY, COMMERCIAL_OPS_QUOTING_USER_ID, SALES_USER};
    }
    /**
    * 
    *
    * @description: getCommercialRevenueOperationsProfileId  [CodeScan Fix]
    */
    public static Set<Id> getCommercialRevenueOperationsProfileId() {
        return new Set<Id> {COMMERCIAL_AND_REVENUE_OPERATIONS_ID};
    }
    /**
    * 
    *
    * @description: getCommercialOpsQiuotingUserProfileId  [CodeScan Fix]
    */
    public static Set<Id> getCommercialOpsQuotingUserProfileId() {
        return new Set<Id> {COMMERCIAL_OPS_QUOTING_USER_ID};
    }
    /**
    * 
    *
    * @description: getCustomerServiceUserProfileId  [CodeScan Fix]
    */
    public static Set<Id> getCustomerServiceUserProfileId() {
        return new Set<Id> {CUSTOMER_SERVICE};
    }
    /**
     * @actor illumina
     * @description :- DCP-37793 Fetch QA Profile Id set.
     */
    
    public static Set<Id> getQualityAssuranceProfileId() {
        return getProfileIdSet(setQAProfileName);
    }
     /**
     * @actor illumina
     * @description :-//Deepika DCP-43515
     */
    public static Set<Id> getFieldServicelogisticsProfileId() {
        return getProfileIdSet(setLogisticsProfileName);
    }
    /**
     * @actor illumina
     * @description :-DCP-37793 Fetch SuperUser Profile Id set.
     */
    public static Set<Id> getSuperUserProfileId() {
        return getProfileIdSet(setSuperUserProfile);
    }

    /** @description: This will fetch the Profile Id for the 'Marketing Lead Qualification' Profile
    *  @return Set<Id>
    * INC0419938
    */
    public static Set<Id> getMarketingLeadQualificationProfileId() {
        return getProfileIdSet(setMarketingLeadQualificationProfileName);
    }

    //DCP-37793
    /* @Description : Method to query profile based on set of profile name created.
    */
    public static Map<String,Profile> getMapProfile(){
        if(mapNameToProfile.isEmpty()){
            Set<String> setProfileName = new Set<String>();
            setProfileName.addAll(setSuperUserProfile);
            setProfileName.addAll(setQAProfileName);
            setProfileName.addAll(setSystemAdminProfileName);
            setProfileName.addAll(setSalesIntegrationProfileName);
            setProfileName.addAll(setAllSalesProfileName);
            setProfileName.addAll(setCommercialRevenueOperationsProfileName);
            setProfileName.addAll(setCommercialOpsQuotingUserProfileName);
            setProfileName.addAll(setCustomerServiceProfileName);
            setProfileName.addAll(setServiceIntegrationProfileName);
            setProfileName.addAll(setLogisticsProfileName);
            setProfileName.addAll(setMarketingLeadQualificationProfileName); //INC0419938
            setProfileName.addAll(setChannelPartnerProfiles);
            setProfileName.addAll(setFieldServiceProfileName);
            setProfileName.addAll(setFieldServiceThirdPartyProfileName);
            setProfileName.addAll(setOtherIntegrationProfileName);

            List<Profile> lstProfiles = new ProfilesSelector().getProfileByName(setProfileName);
            for(Profile p : lstProfiles)
                mapNameToProfile.put(p.Name,p);
        }
        return mapNameToProfile;
    }
    /*
    *DCP-37793
    *Description : Method to return set of profile id corresponding to strProfileName set.
    */
    public static Set<Id> getProfileIdSet(Set<String> strProfileName){
        Set<Id> setProfileId = new Set<Id>();
        for(Profile objPro : getMapProfile().values()){
            if(strProfileName.contains(objPro.Name))
                setProfileId.add(objPro.id);
        }
        return setProfileId;
    }
}