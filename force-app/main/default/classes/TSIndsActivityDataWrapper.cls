/**
 *   @author: Deep Diwakar
*    @date:   Feb-02-2024
*    @description: Wrapper class for TSIndustryActivitySyncInterface interface
*    @Test Class: TestTSIndsActivityDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-02-2024       Wrapper class for TSIndustryActivitySyncInterface interface
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class TSIndsActivityDataWrapper {

    public Integer per_id;
    public String person_name_list;
    public Integer organisation_id;
    public String organization_name;
    public String fee_disclosure_purpose;
    public String fee_disclosure_period;
    public Integer fee_disclosure_amount_in_dollars;

}