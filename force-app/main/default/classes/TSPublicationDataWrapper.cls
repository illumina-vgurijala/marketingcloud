/**
 *   @author: Deep Diwakar
*    @date:   Jan-25-2024
*    @description: Wrapper class for TSPublicationSyncInterface interface
*    @Test Class: TestTSPublicationDataReceiver
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-25-2024       Wrapper class for TSPublicationSyncInterface interface
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class TSPublicationDataWrapper {

    public Integer per_id;
    public String person_name_list;
    public Integer publication_id;
    public Integer medline_id;
    public String journal_name;
    public String publication_title;
    public String author_order;
    public String publication_date;
    public String publication_url;
    public String authors;
    public String publication_about_trial_tag;

}