/**
 *    @author Kushagra Desai
 *    @date   14-Jully-2020
 *    @description    Mock class for Lead integrations 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *       
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
global class LeadEmailVerificationMockHTTP implements HttpCalloutMock{
    public string statusType;
    
    /**Parameterized constructor */
    public LeadEmailVerificationMockHTTP(String statusType) {
        this.statusType = statusType;
    }

    /**Method - Mock response */
    global HTTPResponse respond(HTTPRequest req) {
        String strResSuccess = '{"VerifyEmailResult":{"ServiceStatus":{"StatusNbr":"200","StatusDescription":"Email Valid"},"ServiceResult":{"Reason":{"Code":"201","Description":"Mailbox Confirmed"}}}}';
        String strResSuccessWithWarnings = '{"VerifyEmailResult":{"ServiceStatus":{"StatusNbr":"300","StatusDescription":"Email Not Valid"},"ServiceResult":{"Reason":{"Code":"301","Description":"Mailbox Confirmed"}}}}';
        String strResPartialSuccess = '{"VerifyEmailResult":{"ServiceStatus":{"StatusNbr":"200","StatusDescription":"Email Valid"},"ServiceResult":{"Reason":{"Code":"203","Description":"Mailbox Confirmed"}}}}';
        String strFailure = 'System Failure';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(statusType == 'S' ? strResSuccess : (statusType == 'SP' ? strResPartialSuccess : (statusType == 'IE' ? strResSuccessWithWarnings : strFailure)));
        res.setStatusCode(statusType == 'F' ? 400 : 200);
        return res;
    }
}