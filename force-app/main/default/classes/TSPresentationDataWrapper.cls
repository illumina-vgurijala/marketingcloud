/**
 *   @author: Deep Diwakar
*    @date:   Jan-02-2024
*    @description: Wrapper class for TSPresentationSyncInterface interface
*    @Test Class: TestTSPresentationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024       Wrapper class for TSPresentationSyncInterface interface
*         Deep Diwakar       Feb-06-2024       Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class TSPresentationDataWrapper {

    public Integer per_id;
    public String person_name_list;
    public String presentation_type;
    public Integer presentation_id;
    public String conference_name;
    public String presentation_title;
    public String presentation_author_order;
    public String conference_start;
    public String conference_url;
    public String presenters;

}