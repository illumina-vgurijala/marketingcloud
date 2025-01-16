/* @ author      :  Akash Kumar
* @ date         :  26-SEP-2024
* @ Description  :  Class for Mock SnowFlake response/request for real time test classes
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akash Kumar          17-OCT-2024             Initial version
*/
public with sharing class MockSnowFlakeConnector implements HttpCalloutMock {
	/**
	 *  @Method with mock respose data for success from SNAP
	 **/
	public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
            '{"Margin":[{"GMVersionName":"FY24 Budget V2","Region":"AMR","FsclQtrID":20241,"FsclQtrStrtDt":"2024-01-01","FsclQtrEndDt":"2024-03-31","MaterialNumber":"20024905","L04_ProductGroupCode":"0NR1","TargetMarginPercent":6.69,"Publish_Dt":"2024-11-01T09:31:00.000","Publish_Usr":"TM1"},{"GMVersionName":"FY24 Budget V2","Region":"AMR","FsclQtrID":20241,"FsclQtrStrtDt":"2024-01-01","FsclQtrEndDt":"2024-03-31","MaterialNumber":"20031371","L04_ProductGroupCode":"0FRE","TargetMarginPercent":2.17,"Publish_Dt":"2024-11-01T09:32:00.000","Publish_Usr":"TM1"},{"GMVersionName":"FY24 Budget V2","Region":"AMR","FsclQtrID":20241,"FsclQtrStrtDt":"2024-01-01","FsclQtrEndDt":"2024-03-31","MaterialNumber":"20089501","L04_ProductGroupCode":"0FFY","TargetMarginPercent":2.47,"Publish_Dt":"2024-11-01T09:32:00.000","Publish_Usr":"TM1"}],"StatusCode":"200","Status":"Success","Details":"Target Margins Returned from TM1 successfully","request":{"Sub_Region":"AMR Pacific","Region":"AMR","Product_Code":["15043761","20024905","15033418","15033419","20031371","20089501","20086666","20019983"],"OppClosedDate":"2024-01-15"}}'
        );
        res.setStatusCode(200);
        res.setStatus('Success from TM1');

        return res;
    }

	/**
	 *  @Method with mock respose with authentication error
	 **/
	/*public HTTPResponse respondAuthError(HTTPRequest req) {
		HTTPResponse res = new HTTPResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody(
			'{"Margin": [{"productCode": "123","targetMargin": "10"},{"productCode": "456","targetMargin": "20"}],"StatusCode": "200","Status": "Success","Details": "Target Margins Returned from TM1 successfully","request": {"Sub_Region": null,"Region": "AMR","Fiscal_Quarter": "Q123","productCode": ["123","456","312","459"]}}'
		);
		res.setStatus('Error');
		res.setStatusCode(403);

		return res;
	}*/
}