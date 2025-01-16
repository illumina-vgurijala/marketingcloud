/**
*    @author: Pankaj 
*    @date:   04-Dec-2019
*    @description:  Test Class for DMPSegmentationDataRefresh
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        04-Dec-2019        Initial Development

     
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class DMPSegmentationDataRefreshTest{
    /*
    * @author Pankaj Singla
    * @date   04-Dec-2019 
    * @description: Test method to for updateMetadata method
    * @params :None
    * @return:None
    * 
    */
    static testmethod void updateMetadatatest(){
        Test.setMock(HttpCalloutMock.class, new DMPSegmentReceiverHTTPMock());
            Test.startTest();
            DMPSegmentationDataRefresh.updateMetadata();
            Test.stopTest(); 
        List<DMP_Priority_Segment__mdt> lst=[select id from DMP_Priority_Segment__mdt ];
        system.assertNotEquals(0, lst.size());
        
    }
    
    /*
    * @author Pankaj Singla
    * @date   04-Dec-2019 
    * @description: Test method to for handleResult method
    * @params :None
    * @return:None
    * 
    */
    
    static testmethod void testhandleresult(){
        Metadata.DeployCallback callback = new DMPSegmentationDataRefresh ();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        callback.handleResult(result, context);
        List<DMP_Priority_Segment__mdt> lst=[select id from DMP_Priority_Segment__mdt ];
        system.assertNotEquals(0, lst.size());
    }

}