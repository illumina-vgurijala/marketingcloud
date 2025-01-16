/**
 *    @author Unknown
 *    @date   Not available
 *    @description  An apex page controller that takes the user to the right start page based on credentials or lack thereof
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Jitesh Lakhwani                6-July-2022         Code Scan fixes of Comments
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CommunitiesLandingController {
    
    /**
    * @description: This will load the home page based on the credentials of the user. Code we will invoke on page load.
    * @param : None
    * @return: None
    */
    public PageReference forwardToStartPage() {
        return Network.communitiesLanding();
    }
    
    /**
    * @description: CommunitiesLandingController class Constructor
    * @param : None
    * @return: None
    */
    public CommunitiesLandingController() {}
}