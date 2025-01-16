/*@ author       : Rahul Sharma
* @ date         : 15-04-19
* @ Description  : ApttusCheckCatalystDiscount Apex Controller Outbound mock for catlayst discount
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rahul Sharma         14-04-2019                 PCP-4              Initial version
* Jitesh Lakhwani      6-July-2022                                   Code Scan fixes of Comments
* Prem Ranjan          20-Feb-2023                                   CodeScan Fixes (APEX) Variable Naming Conventions
*/
public class ApttusCatalystDiscountMock implements HttpCalloutMock {
    public static Boolean booResponseSuccess = false;
    public static String strQuoteId ='';
    public static String strLineItemId ='';
    public static Integer integerResponseCode;
                        
    /**
    *  @author Rahul Sharma
    *  @description Mock 'respond' method for Apttus Catlayst Discount
    *  @param :  HTTPRequest req
    *  @return : None
    **/
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"is_success": true, "response": {"requested_by_system_name": "Apttus", "requested_by": "rsharmas@deloitte.com", "request_id": "a3sc00000002gpVAAQ_2019-04-15 14:33:39", "request_date": "04-15-2019", "quote_details": [{"quote_line_item_id": "'+strLineItemId+'", "item_details": [{"value": "15014173", "key": "Material Number"}, {"value": null, "key": "Service Start Date"}, {"value": null, "key": "Service End Date"}], "discount_percentage": 17.359226890000002}], "quotation_id": "'+strQuoteId+'", "customer_details": [{"value": "6000020822", "key": "UC Number"}]}, "error_message": null, "error_code": null}');
        res.setStatusCode(integerResponseCode);
        booResponseSuccess = true;
        return res;
    }
}