/**
 *   @author: Deep Diwakar
*    @date:   Jan-31-2024
*    @description: Wrapper class for TSTrialSyncInterface interface
*    @Test Class: TestTSTrialDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-31-2024       Wrapper class for TSTrialSyncInterface interface
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class TSTrialDataWrapper {

    public Integer per_id;
    public String person_name_list;
    public String trial_registry_id;
    public String study_type;
    public Integer trial_id;
    public String trial_name;
    public String therapy_treatment;
    public String trial_purpose;
    public String state;
    public String primary_outcomes;
    public String trial_participant_gender_restriction;
    public String study_start;
    public String study_end;
    public String trial_url;
    public String sponsors;
    public String phase;
    public Double enrollment;
    public Double minimum_age;
    public Double maximum_age;
    public Integer number_of_sites;

}