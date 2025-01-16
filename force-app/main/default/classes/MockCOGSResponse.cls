/* @ author      :  Pradeep Landge
* @ date         :  23-OCT-2024  
* @ Description  :  Class for Mock COGS response/request for real time test classes
*
* Modification Log:
* -----------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* -----------------------------------------------------------------------------------------------------------------------------------
* Pradeep Landge          23-OCT-2024             Initial version
*/
public with sharing class MockCOGSResponse implements HttpCalloutMock {
	/**
	 *  @Method with mock respose data for success from SNAP
	 **/
	public HTTPResponse respond(HTTPRequest req) {
		HTTPResponse res = new HTTPResponse();
		res.setHeader('Content-Type', 'application/json');
        res.setBody('{"d":{"Vbeln":"4613783","DocType":"","SalesOrg":"","DistrChan":"","Division":"","QtValidT":"","QtValidF":"","ZzsvmxOrderType":"","PriceList":"","HCurr":"","PriceDate":"","PoMethod":"","ZzapQuot":"","Zzoppid":"","Incoterms1":"","Incoterms2":"","ZzmyilmnEmail":"","Zstatus":"","Pmnttrms":"","OrdReason":"","UsageInd":"","ZzpromoCode1":"","ZzpromoCode2":"","ZzpromoCode3":"","ZzpromoChannel1":"","ZzpromoChannel2":"","ZzpromoChannel3":"","Cstcndgrp2":"","CustGrp2":"","RefDocL":"","ZdName":"","ZdTelephone":"","ZdEmail":"","PguidPurch":"","FileContent":"","EvSalesDocument":"","CostCenter":"","NAVHDRTOCND":{"results":[]},"NAVHDRTOITM":{"__deferred":{}},"NAVHDRTOPRT":{"__deferred":{}},"NAVHDRTORET":{"results":[{"__metadata":{},"Type":"E","Message":"Order/QuoteNumberisinvalid"}]},"NAVHDRTOTXT":{"__deferred":{}},"NAVHDRTOINP":{"__deferred":{}},"NAVHDRTOCFGSBLOB":{"__deferred":{}},"NAVHDRTOCFGSINST":{"__deferred":{}},"NAVHDRTOCFGSPARTOF":{"__deferred":{}},"NAVHDRTOCFGSREF":{"__deferred":{}},"NAVHDRTOCFGSREFINST":{"__deferred":{}},"NAVHDRTOCFGSVAL":{"__deferred":{}},"NAVHDRTOCFGSVK":{"__deferred":{}},"NAVHDRTOKEYS":{"__deferred":{}},"NAVHDRTOLOGSWT":{"__deferred":{}},"NAVHDRTOSENDER":{"__deferred":{}},"NAVHDRTOPARADD":{"__deferred":{}},"NAVHDRTOPARCNG":{"__deferred":{}},"NAVHDRTOGTSLOGS":{"__deferred":{}},"NAVHDRTOITEMCOND":{"results":[{"__metadata":{"type":"ZQ2C_INT_QUOTE_CONV_SRV.SALES_ITEM_COND"},"ItmNumber":"000050","ZzapPosnr":"LI-0001383428","KonvKschl":"VPRS","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"1,049.89","KonvKrech":"C","KonvKwert":"6,562.55","Krate":"1,312.51"},{"__metadata":{"type":"ZQ2C_INT_QUOTE_CONV_SRV.SALES_ITEM_COND"},"ItmNumber":"000060","ZzapPosnr":"LI-0001384222","KonvKschl":"VPRS","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"1,049.89","KonvKrech":"C","KonvKwert":"1,312.51","Krate":"1,312.51"},{"__metadata":{"type":"ZQ2C_INT_QUOTE_CONV_SRV.SALES_ITEM_COND"},"ItmNumber":"000070","ZzapPosnr":"LI-0001384223","KonvKschl":"ZNSC","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"35.00","KonvKrech":"A","KonvKwert":"875.00","Krate":"175.00"},{"__metadata":{"type":"ZQ2C_INT_QUOTE_CONV_SRV.SALES_ITEM_COND"},"ItmNumber":"000080","ZzapPosnr":"LI-0001384224","KonvKschl":"ZNSC","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"35.00","KonvKrech":"A","KonvKwert":"175.00","Krate":"175.00"}]},"NAVHDRTOEXP":{"__deferred":{}},"NAVHDRTOFAPIAO":{"__deferred":{}},"NAVITMTOTXT":{"__deferred":{}}}}');
		res.setStatusCode(200);
		return res;
	}
}
