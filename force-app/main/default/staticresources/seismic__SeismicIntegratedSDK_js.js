(function(window){
	var IntegratedSDK = {
        /**
         * Load embedded application using the iframe
         * 
         * @param {Dom} iframeDom
         * @param {Object} contextInfo
         * @param {Object} credentialInfo
         * @param {Object} configInfo
         * @param {String} sObjectType
         * @param {String} sObjectId
         * @param {String} sObjectName
         */
		loadEmbeddedApplication: function(iframeDom, contextInfo, credentialInfo, configInfo, sObjectType, sObjectId, sObjectName, currentTabLabel, currentPageBaseUrl){	
            var serverURL = contextInfo.ServerBaseUrl;
			var integratorContextObj = {
                SystemType: 'Salesforce',
                ApplicationVersion: contextInfo.PackageVersion,
                ContextType: sObjectType,
                ContextTypePlural: currentTabLabel,
                ContextName: sObjectName,
                ContextId: sObjectId,
				SfdcPageSupportRefreshPage: true,
                ExtraMetadata: {
                    OrganizationId: contextInfo.SFOrganizationId,
                    BaseUrl: contextInfo.SFBaseUrl,
                    SessionId: contextInfo.SessionId,
                    UserId: credentialInfo.UserId,
                    IsCommunity: contextInfo.IsCommunity,
                    CommunityId: contextInfo.CommunityId,
                    CurrentPageBaseUrl: currentPageBaseUrl
                },
                Metadata: {
                        serverURL: serverURL,
                        client_id: 'ff7d19eb-b3c8-48dd-8a42-cdecfc116e9c',
                        //options included for new OIDC auth
                        popup_redirect_uri: serverURL + '/embedded_auth.aspx',
                        redirect_uri: serverURL + '/embedded_auth.aspx',
                        silent_redirect_uri: serverURL + '/embedded_auth_silent.aspx',
                        popup_post_logout_redirect_uri: serverURL + '/embedded_auth_logout.aspx',
                        post_logout_redirect_uri: serverURL + '/X5/sfdc_logout.aspx',
                        configHideLogOut: configInfo.hideLogOutButton
                }			
			};
			
			function setupPostMessage() {
				window.addEventListener('message', function (event) {
					if (event.data == "refresh") {
						refreshSeismic();
					}
				}, false);
			}
			function refreshSeismic() {
				setTimeout(function () {
					window.location.reload();
				}, 500);
			}
			setupPostMessage();
			
	
			return new Seismic.EmbeddedPage(iframeDom, {
				clientId: credentialInfo.ClientType,
				serverBaseUrl: contextInfo.ServerBaseUrl,
				integratorContext: integratorContextObj,
				loginOptions: {
					identityToken: credentialInfo.RememberMeToken,
					disableRememberMe : credentialInfo.DisableRememberMe == '1',
					disableSSOAutoRedirection: credentialInfo.DisableSSOAutoRedirection == '1',
					ssoState: credentialInfo.SSOState,
				},
				config: configInfo
			});
		},
			
        actions:{
            showDetail: 'openDocumentDetail',
            goBack: 'goBack'
        }
	};
	
	window.Seismic = window.Seismic || {};
	window.Seismic.IntegratedSDK = IntegratedSDK;
	
})(window);