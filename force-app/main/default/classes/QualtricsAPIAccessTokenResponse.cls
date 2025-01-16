/**
 *    @author Vaibhav
 *    @date   2 May 2021
 *    @description   DCP-46141 - QualtricsAPIAccessTokenResponse
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Vaibhav                       2 May 2021              Initial Version - DCP-46141 : Qualtrics Integration.
 * ---------------------------------------------------------------------------------------
 */
public class QualtricsAPIAccessTokenResponse {

    public String access_token;
    public String token_type;
    public Integer expires_in;
    public String scope;

    /** @DESCRIPTION - prase json response **/
    public static QualtricsAPIAccessTokenResponse parse(String json) {
        return (QualtricsAPIAccessTokenResponse) System.JSON.deserialize(json, QualtricsAPIAccessTokenResponse.class);
    }
    
}