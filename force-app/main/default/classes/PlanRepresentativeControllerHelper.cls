/**
 *    @author Anisha
 *    @date   01-Sep-2020
 *    @description : Helper class for PlanRepresentativeController
 *    @Test Class for 90% Code Coverage
 *    @Test Class for 75% Code Coverage
 *    TestPlanRepresentativeController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Nishan Shetty                 13-Sept-2022         CodeScan Fix DCP-56402.               
 */
public without sharing class PlanRepresentativeControllerHelper {
    
    public static Set<String> setAllChannelPartnerName = new Set<String>{
        Label.Profile_Channel_Partner_Sales,
        Label.Profile_Channel_Partner_Sales_and_Read_Only_Service, 
        Label.Profile_Channel_Partner_Sales_and_Read_Only_Service_Login,
        Label.Profile_Channel_Partner_Sales_and_Service,
        Label.Profile_Channel_Partner_Sales_Login};    
    /** DCP-39621
    *  @author Anisha
    *  @description check if channel partner user
    *  @return boolean
    **/
    public static boolean isChannelPartnerProfile() {//DCP-56402 CodeScan Fix.
        Id userId = userinfo.getUserId();
        boolean isChannelPartnerProfile = false;
        // Direct query is used as community user can't query in with sharing.
        User objUsr = [Select id,ProfileId,Profile.Name from User where Id =:userId];
        if(setAllChannelPartnerName.contains(objUsr.Profile.Name)) { //DCP-56402 CodeScan Fix.
            isChannelPartnerProfile = true;
        }
        return isChannelPartnerProfile;  
    }
}