/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Mock class for CLM integrations 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Kushagra Desai                                     Initial Version
 *    Nesar Mohan                   01-Apr-2022          Codescan Fix
 *    Saddam                        08-Dec-2022     Codescan Fix , Varaible naming convention.    
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
@isTest
global class ApttusCLMMockHTTP implements HttpCalloutMock{
    string strAgreementNumber;
    String strLineItemNumber;
    string statusType;
    /*
    *  @author      : Kushagra Desai
    *  @description : Parameterized Constructor for ApttusCLMMockHTTP
    *  @param       : Three parameters of type String
    */
    public ApttusCLMMockHTTP(String statusType,String strAgreementNumber,String strLineItemNumber) {
        this.statusType = statusType;
        this.strLineItemNumber = strLineItemNumber;
        this.strAgreementNumber = strAgreementNumber;
    }
    /*
    *  @author      : Kushagra Desai
    *  @description : Method to send the request and return the response
    *  @param       : HTTPRequest
    *  @return      : HTTPResponse
    */
    
    global HTTPResponse respond(HTTPRequest req) {
        String strResBody = 'REST API service endpoint returned error';
        String strResJSON = '{"AgreeStartDate": "", "Status": "E", "AgreeEndDate": "","AgreementNum": "'+strAgreementNumber+'", "Action": "Validate","EX_ReturnSet": {"results": [{"Type": "E","MsgId": "VK","MsgNumber": "009","Message": "Material  15043762 is marked for deletion","LineItemId": "'+strLineItemNumber+'"}]},"im_itemSet": {"results": [{"CalType": "A","FutUse": "","Customer": "4000003831","Curr": "USD","ProdGroup": "qwdr","Lob": "","SalesOrg": "CA01","DistChnl": "01","ProdCategory": "asdfg","PriceGroup": "","ProdLine": "qwer","CondTable": "A305","UltCons": "","PartnerRole": "qs","Material": "15043762","CondType": "ZFXP","Rate": "12500.000","RateUnit": "","LineItemId": "LI-123456","MaterialGroup": "","StartDate": "","EndDate": "" }]}}';
        String strPricingOutputJSON = '{"values":[{"attributes":null,"label":"Chinese","validFor":[],"value":"Chinese"}]}';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strAgreementNumber == null ? strPricingOutputJSON : (statusType == 'SuccessPartial' ? strResBody : strResJSON));
        res.setStatusCode(statusType == 'Success' || statusType == 'SuccessPartial' ? 200 : 401 );
        return res;
    }
}