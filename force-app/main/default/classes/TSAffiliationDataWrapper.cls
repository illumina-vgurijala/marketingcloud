/**
 *   @author: Deep Diwakar
*    @date:   Jan-02-2024
*    @description: Wrapper class for TSAffiliationSyncInterface interface
*    @Test Class: TestTSAffiliationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024       Wrapper class for TSAffiliationSyncInterface interface
*         Deep Diwakar       Feb-07-2024       Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class TSAffiliationDataWrapper {
    public Integer per_id;
    public String person_name_list;
    public Integer organisation_id;
    public String known_associated_organization_name;
    public String organization_url;
    public Integer first_year_at_known_associated_organization;
    public Integer last_year_at_known_associated_organization;

}