/**
 * Controller of vf page :CharketDataPrivacyConsent
 * The page is used for Data Privacy Consent
 *   Modification Log:
 *   ------------------------------------------------------------------------------------ 
 *   Developer                      Date                  Description
 *   Charket                       13-Oct-2023          Added query selector  
 *   Charket                       13-Oct-2023          Added Instrumentation 
 *   ------------------------------------------------------------------------------------ 
 *   
 */
global without sharing class CharketDataPrivacyConsentController {
    public String dataPrivacyPolicy { get; set; }
    public Boolean isWeChatBrowser { get; set; }
    public String qRCodeImageName { get; set; }
    private static final String LOG_TITLE = 'CharketServiceRequestController';

    /**
     *  @author  Charket Team
     *  @description CharketDataPrivacyConsentController constructor
     **/
    public CharketDataPrivacyConsentController() {
        ilib_LogEvent.push(LOG_TITLE + 'constructor');
        isWeChatBrowser = false;
        String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
        isWeChatBrowser =
            String.isNotBlank(userAgent) && userAgent.containsIgnoreCase('MicroMessenger');
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String wechatAccountId = params.get('wechatAccountId');
        if (String.isNotBlank(wechatAccountId) && wechatAccountId instanceof Id) {
            List<Charket__WeChatAccount__c> wechatAccounts = new CharketSelector().selectWeChatAccountsById(wechatAccountId);
            if (wechatAccounts.size() > 0) {
                dataPrivacyPolicy = wechatAccounts[0].DataPrivacyPolicy__c;
                CharketSettings__mdt thisCharketSettings = CharketCustomUtil.getCharketSetting(
                    wechatAccounts[0].Id
                );

                qRCodeImageName= (thisCharketSettings != null) ? thisCharketSettings.qRCodeImageName__c : null;
               
            }
        }
        ilib_LogEvent.pop();
    }
}