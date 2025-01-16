function isInSFOneApp() {
    var searches = (window.location.search || "").replace(/^\?/, "").split("&");
    for(var i = 0; i < searches.length; i++){
        if(/^isdtp\=/.test(searches[i])) {
            return true;
        }
    }

    return false;
}


var Seismic = angular.module('SeismicConnector', ['ngStorage']);

Seismic.factory('seismic', function($rootScope, $q, $localStorage, $timeout) {
    $localStorage.seismicSObjectCache = $localStorage.seismicSObjectCache || {};
    var seismicSObjectCache = $localStorage.seismicSObjectCache;
    
    if ($localStorage.seismicTenantCache != pageInfo.seismicTenant) {
    	$localStorage.seismicTenantCache = pageInfo.seismicTenant;
    	$localStorage.seismicInitInfoCache = {};
    	$localStorage.seismicProfileMappingCache = {};
    	$localStorage.seismicDocumentListCache = {};
    	$localStorage.seismicRecursiveDocumentListCache = {};
    	$localStorage.seismicDocumentDetailCache = {};
    }
    
    $localStorage.seismicProfileMappingCache = $localStorage.seismicProfileMappingCache || {};
    var seismicProfileMappingCache = $localStorage.seismicProfileMappingCache;
    
    $localStorage.seismicDocumentListCache = $localStorage.seismicDocumentListCache || {};
    var seismicDocumentListCache = $localStorage.seismicDocumentListCache;
    
    $localStorage.seismicRecursiveDocumentListCache = $localStorage.seismicRecursiveDocumentListCache || {};
    var seismicRecursiveDocumentListCache = $localStorage.seismicRecursiveDocumentListCache;

    var seismic = {};

    seismic.pageInfo = pageInfo;
    seismic.Tenant = '';
    seismic.UserName = '';
    seismic.errorState = {};
    seismic.securityCredentials = {};
    seismic.userInfo = {};
    seismic.documents = {};

	seismic._isInited = false;
    seismic.detailsExpanded = false;
    seismic.deliveryOptionsExpanded = false;

    seismic.seismicSessionId = '';
    seismic.salesforceSessionId = '';

    seismic.remoteFunction = '';
    seismic.setupCarousel = function() {};

    /************************************************************************************************
    * A generic function that will package the data and invoke the remote action in the controller.
    * That remote action will route the request into SeismicConnector, which will actually contact
    * Seismic.
    *
    * @param method    The method that should be invoked in the remote action
    * @param params    An object containing all the correct params pertaining to the method
    * @param callback  A function to call after the remote action completes
    *************************************************************************************************/
    seismic.RemoteCall = function(method, params, callback) {

        //assemble the request body
        var reqBody = {
            'Method': method,
            'Data': params
        };

		if (window.console) {
        	console.log(method + ' request: ', reqBody);
    	}

        //JS Remoting call to try out the username/pasword
        Visualforce.remoting.Manager.invokeAction(
            //specify the remote function
            seismic.pageInfo.remoteFunction,

            //pass in the req body
            JSON.stringify(reqBody),

            //the callback
            function(result, event) {

                //parse the response
                var response = null;

                try{
                    response = $.parseJSON(result);
                } catch(e) {
                    if (window.console) {
                    	console.error("cannot parse json: ", result, "\nRequest:", reqBody)
                	}
                }

                if (!response) {
                    if (event && event.message) {
                        seismic.errorState = true;
                        if (window.console) {
                        	console.error(method + ' event error: ', event.type + '' + event.message);
                    	}
                    }
                    response = {};
                } else if (response.Error) {
                    seismic.errorState = true;
                    if (window.console) {
                    	console.error(method + ' response error: ', response);
                	}
                    response = {};
                } else {
                    if (window.console) {
                    	console.log(method + ' response: ', response);
                	}
                    //invoke their callback, passing in the endpoints response
                }

                callback(response);
            },
            //prevent the returned JSON from being corrupted with escaped characters
            {
                escape: false,
                timeout: 120000
            }
        );
    };
    
    seismic.getCachedSObject = function() {
        var cachedSObject = seismicSObjectCache[pageInfo.objectId];
        return cachedSObject ? cachedSObject : null;
    };
    
    seismic.cacheSObject = function() {
        var cacheValue = { Type: pageInfo.objectType, SystemModstamp: pageInfo.objectSystemModstamp };
        seismicSObjectCache[pageInfo.objectId] = cacheValue;
    }

    seismic.getProfileMapping = function(callback) {
        var params = {
            objectType: pageInfo.objectType,
            objectId: pageInfo.objectId,
            buttonName: pageInfo.buttonName
        };
        
        seismic.RemoteCall('GetProfileMapping', params, function(response) {
            if (response.Error == null) {
            	var mappings = response.ServiceResult.ProfileVersionMappings;
            	if (mappings) {
                    var key = seismic.getCacheKeyProfileMapping();
                    var cacheValue = new Object();
                	cacheValue[pageInfo.mappingVersion] = mappings;
                    seismicProfileMappingCache[key] = cacheValue;
                }
                $timeout(function() {
                    callback(mappings);
                });
            } else {
                seismic.HandleError(response.Error, seismic.getProfileMapping, null);
            }
        });
    };
    
    seismic.getCacheKeyProfileMapping = function () {
        return pageInfo.seismicTenant + '-' + pageInfo.objectType + '@' + pageInfo.objectId + '#' + pageInfo.buttonName;
    };
    
    seismic.getCachedProfileMapping = function () {
        var key = seismic.getCacheKeyProfileMapping();
        var value = seismicProfileMappingCache[key];
        if (value && value[pageInfo.mappingVersion]) {
            return value[pageInfo.mappingVersion];
        }
        return null;
    };
    
    seismic.getProfileMappingFilterValues = function() {
        if (seismic.profileInfo.FilterValueString) {
            return seismic.profileInfo.FilterValueString;
        } else {
            var result = '';
            if (seismic.profileInfo && seismic.profileInfo.FilterMappings && seismic.profileInfo.FilterMappings[0]) {
                var filters = seismic.profileInfo.FilterMappings;
                for (var i = 0, count = filters.length; i < count; i++) {
                    var mapping = filters[i];
                    if (mapping && mapping.Values && mapping.Values[0]) {
                        for (var j = 0, countValues = mapping.Values.length; j < countValues; j++) {
                            result += mapping.Values[j] + '|';
                        }
                    }
                }
            }
            
            seismic.profileInfo.FilterValueString = result;
            return result;
        }
    };
    
    seismic.pushDocuments = function(documentList, isFromCache) {
        seismic.documents = [];
        if(documentList && documentList.length > 0) {
            for(var i = 0, count = documentList.length; i < count; i++) {
                var doc = documentList[i];

                //if(doc.IsDynamic && doc.Format == DocumentFormats.DOCX) {
                //    continue;
                //}
                //if(doc.Format == DocumentFormats.URL) {
                //    continue;
                //}

                seismic.documents.push(doc);
            }
        }

        seismic.setupCarousel(isFromCache);
    }

    /* 
     * if there is a cached data, return directly, and then check service to refresh cache.
     * so, it will apply next time
     */
    /* No logic to manage cache for now */
    seismic.GetDocumentsWithFilter = function() {
        if (!seismic.userInfo || !seismic.profileInfo) {
    		seismic.pushDocuments(null);
    	} else {
            var params = {
                profileVersionId: seismic.profileInfo.ProfileVersionId,
                path: seismic.profileInfo.FolderIdPath,
                filters: JSON.stringify(seismic.profileInfo.FilterMappings)
            };
            seismic.RemoteCall('GetDocumentsWithFilter', params, 
                function(response) {
                    if (response.Error == null) {
                        var docs = response.ServiceResult[response.ServiceResult.length - 1].Documents;
                        if (docs) {
                            var key = seismic.GetCacheKeyDocumentsWithFilter();
                            seismicDocumentListCache[key] = docs;
                        }
                        seismic.pushDocuments(docs);
                    } else {
                        seismic.HandleError(response.Error, seismic.GetDocumentsWithFilter, null);
                    }
                });
        }
    };
    
    seismic.GetCacheKeyDocumentsWithFilter = function () {
        return seismic.pageInfo.seismicTenant + '@' + seismic.userInfo.UserName 
             + '-' + seismic.profileInfo.ProfileVersionId + '@' + seismic.profileInfo.FolderFullPath + '#' + seismic.getProfileMappingFilterValues();
    };
    
    seismic.GetCachedDocumentsWithFilter = function () {
        var key = seismic.GetCacheKeyDocumentsWithFilter();
        var value = seismicDocumentListCache[key];
        return value;
    };

    /* 
     * if there is a cached data, return directly, and then check service to refresh cache.
     * so, it will apply next time
     */
    /* No logic to manage cache for now */
    seismic.GetRecursiveDocumentsWithFilter = function() {
    	if (!seismic.userInfo || !seismic.profileInfo) {
            seismic.pushDocuments(null);
    	} else {
            var params = {
                profileVersionId: seismic.profileInfo.ProfileVersionId,
                path: seismic.profileInfo.FolderIdPath,
                filters: JSON.stringify(seismic.profileInfo.FilterMappings)
            };
            seismic.RemoteCall('GetRecursiveDocumentsWithFilter', params,
                function(response) {
                    if (response.Error == null) {
                        var docs = response.ServiceResult[response.ServiceResult.length - 1].Documents;
                        if (docs) {
                            var key = seismic.GetCacheKeyRecursiveDocumentsWithFilter();
                            seismicRecursiveDocumentListCache[key] = docs;
                        }
                        $timeout(function() {
                            seismic.pushDocuments(docs);
                        });
                    } else {
                        seismic.HandleError(response.Error, seismic.GetRecursiveDocumentsWithFilter, null);
                    }
                });
        }
    }
    
    seismic.GetCacheKeyRecursiveDocumentsWithFilter = function(profileMapping) {
    	return seismic.pageInfo.seismicTenant + '@' + seismic.userInfo.UserName + '-' 
             + seismic.profileInfo.ProfileVersionId + '@' + seismic.profileInfo.FolderFullPath + '#' + seismic.getProfileMappingFilterValues();
    }
    
    seismic.GetCachedRecursiveDocumentsWithFilter = function(profileMapping) {
        var key = seismic.GetCacheKeyRecursiveDocumentsWithFilter();
        var value = seismicRecursiveDocumentListCache[key];
        return value;
    };

    /************************************************************************************************
    * Gets all specific details of a document that are not included in the documents with
    * with filter call. Includes information about distribution options
    *
    * @return    On succeeding, this will update the document passed into it
                 with additonal information
    *************************************************************************************************/
    seismic.GetDocumentDetails = function(document, successCallback) {
        document.isBusy = true;

        var params = {
            profileVersionId: seismic.profileInfo.ProfileVersionId,
            versionId: document.VersionId
        };

        seismic.RemoteCall('GetDocumentDetails', params, function(response) {
            //if the response contains the -1004 error, log in again
            if (response.Error == null) {
                $rootScope.$apply(function() {


                    seismic.errorState = null;

                    //currently, the source blob comes back as null from the details endpoint.
                    //so, preserve it and replace it after updating the doc
                    var sourceBlob = document.SourceBlobId;
                    $.extend(document, response.ServiceResult.BasicInfo);
                    document.SourceBlobId = sourceBlob;

                    document.deliveryOptions = _buildDeliveryOptions(response.ServiceResult.DeliveryOptions);
                    document.formApps = response.ServiceResult.FormApps;
                    document.basicInfo = response.ServiceResult.BasicInfo;

                    //indicate that the details have now been downloaded, no need to do it again
                    document.isBusy = false;

                    if (!!successCallback) {
                        successCallback();
                    }
                });
            } else {
                seismic.HandleError(response.Error, seismic.GetDocumentDetails, arguments);
            }
        });
    };

    seismic.getFormDefinition = function(fvId) {
        var deferred = $q.defer();

        var params = {
            formVersionId: fvId
        };

        seismic.RemoteCall('GetFormDefinition', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.getFormDefinition, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };

    seismic.sendEmail = function(params) {
        var deferred = $q.defer();
        seismic.RemoteCall('SendEmail', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.sendEmail, arguments);
                deferred.reject(response.Error);
            }
        });
        return deferred.promise;
    };

    seismic.getDocumentDetail = function(documentVersionId, fullPathId) {
        var deferred = $q.defer();

        var params = {
            profileVersionId: seismic.profileInfo.ProfileVersionId,
            versionId: documentVersionId,
            fullPathId: fullPathId
        };

        seismic.RemoteCall('GetDocumentDetails', params, function(response) {
            //if the response contains the -1004 error, log in again
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.getDocumentDetail, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };
    
    seismic.BuildDeliveryOptions = function (deliveryOptions, documentDetails) {
    	return _buildDeliveryOptions(deliveryOptions, documentDetails);
    };

    function _buildDeliveryOptions (deliveryOptions, docDetail) {
        var filteredDeliveryOptions = _filterDeliveryOptions(deliveryOptions, docDetail);
        var sortedDeliveryOptions = _sortDeliveryOptions(filteredDeliveryOptions);
        var decoratedDeliveryOptions = _decorateDeliveryOptions(sortedDeliveryOptions);
        return decoratedDeliveryOptions;
    }

    function _filterDeliveryOptions (deliveryOptions, docDetail) {
        var profileDeliveryOptionIds = docDetail.BasicInfo.DeliveryOptions;
        deliveryOptions = deliveryOptions || [];
        
        var result = [];
        deliveryOptions.forEach(function (item) {
            if (profileDeliveryOptionIds && profileDeliveryOptionIds.length > 0) {
                if ($.inArray(item.DeliveryOptionId, profileDeliveryOptionIds) < 0) {
                    return;
                }
            }
            
            // TODO, canEmail, canDownload
            switch (item.Type) {
                case DeliveryOptionNameToType.SendByEmail: 
                case DeliveryOptionNameToType.SendToSalesforce: 
                case DeliveryOptionNameToType.SendToSharePoint:
                case DeliveryOptionNameToType.AddPersonalCollection: 
                case DeliveryOptionNameToType.RemovePersonalContent: 
                case DeliveryOptionNameToType.MovePersonalContent: 
                case DeliveryOptionNameToType.ChangePersonalContentName: 
                case DeliveryOptionNameToType.EditPersonalContent: 
                case DeliveryOptionNameToType.Unknown:
                    {
                        return;
                    } break;
                case DeliveryOptionNameToType.Download:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowDownload) {
                            return;
                        }
                        if (isInSFOneApp()) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SFSendByEmail:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowEmail) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SFPostToChatter:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowPostToChatter) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SFSaveAttachment:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowSaveAttachment) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SFCreateContent:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowCreateContent) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SFCreateContentDelivery:
                    {
                        if ($App.salesforceOrganization && !$App.salesforceOrganization.AllowCreateContentDelivery) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SendToLiveSend:
                    {
                        if (!_canLiveSend(docDetail.BasicInfo.Format)) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SendToLiveShare:
                    {
                        if (!_canLiveShare(docDetail.BasicInfo.Format)) {
                            return;
                        }
                    } break;
                case DeliveryOptionNameToType.SendToCart:
                case DeliveryOptionNameToType.SaveToPersonal:
                    {
                        if (_isYoutebeOrVimeo(docDetail.BasicInfo.Format)) {
                            return;
                        }
                    } break;
            }
            result.push(item);
        });

        return result;
    }

    function _isYoutebeOrVimeo(format) {
        var _toUpper = String.prototype.toUpperCase;
        return _toUpper.call(FORMATS_TO_NAME[format] || "") == "YOUTUBE"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "VIMEO";
    }

    function _canLiveSend(format) {
        var _toUpper = String.prototype.toUpperCase;
        return _toUpper.call(FORMATS_TO_NAME[format] || "") == "PPTX"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "DOCX"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "PDF"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "URL";
    }
    
    function _canLiveShare(format) {
        var _toUpper = String.prototype.toUpperCase;
        return _toUpper.call(FORMATS_TO_NAME[format] || "") == "PPTX"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "DOCX"
            || _toUpper.call(FORMATS_TO_NAME[format] || "") == "PDF";
    }

    function _decorateDeliveryOptions (deliveryOptions) {
        deliveryOptions = deliveryOptions || [];
        $.each(deliveryOptions,
            function (index, item) {
                var forMenuList = deliveryOptions.length > 4 && index > 2;
                item.iconSrc = _getDeliveryOptionIconUrl(item, forMenuList);
            });
        return deliveryOptions;
    }

    function _getDeliveryOptionIconUrl(deliveryOption, forMenuList) {
        var key;
	    switch (deliveryOption.Type) {
	        case DeliveryOptionNameToType.SendToLiveSend:
	        case DeliveryOptionNameToType.SendToLiveShare:
	            {
	                key = DeliveryOptionIconNames[deliveryOption.Type];
	            } break;
	        case DeliveryOptionNameToType.SendByEmail:
	        case DeliveryOptionNameToType.SFSendByEmail:
	            {
	                key = "DO_EMAIL";
	            } break;
	        default:
	            {
	                key = DeliveryOptionIconNames[deliveryOption.Type] || DeliveryOptionIconNames[DeliveryOptionNameToType.Unknown];
	            } break;
	    }
        return SeismicDeliverOptionIcon[(forMenuList ? '' : 'C') + key];
    }

    var personalCartFolderId = null; // TODO
    function _sortDeliveryOptions(array, isForTheNavigationBar) {
        var result = [];
        for (var i = 0; i < array.length; i++) {
            var item = array[i];
            switch (item.Type) {
                case DeliveryOptionNameToType.RemovePersonalContent:
                    if (personalCartFolderId == item.ParentId) {
                        item.index = "10500" + item.Name;
                    } else {
                        item.index = "20050" + item.Name;
                    }

                    break;
                case DeliveryOptionNameToType.SendToCart:
                    item.index = "11000" + item.Name;
                    break;
                case DeliveryOptionNameToType.Download:
                    item.index = "12000" + item.Name;
                    break;
                case DeliveryOptionNameToType.SendByEmail:
                case DeliveryOptionNameToType.SFSendByEmail:
                    item.index = "13000" + item.Name;
                    break;
                case DeliveryOptionNameToType.CreateSharedLink:
                    item.index = "13100" + item.Name;
                    break;
                case DeliveryOptionNameToType.SendToLiveShare:
                    item.index = "14000" + item.Name;
                    break;
                case DeliveryOptionNameToType.SendToLiveSend:
                    item.index = "15000" + item.Name;
                    break;
                case DeliveryOptionNameToType.SaveToPersonal:
                    if (personalCartFolderId == item.Id) {
                        item.index = "11500" + item.Name;
                    } else {
                        item.index = "16000" + item.Name;
                    }

                    break;
                case DeliveryOptionNameToType.AddPersonalCollection:
                    if (isForTheNavigationBar) {
                        item.index = "10300" + item.Name;
                    } else {
                        item.index = "17000" + item.Name;
                    }

                    break;
                case DeliveryOptionNameToType.EditPersonalContent:
                    if (personalCartFolderId == item.ParentId) {
                        item.index = "18000" + item.Name;
                    } else {
                        item.index = "11100" + item.Name;
                    }

                    break;
                case DeliveryOptionNameToType.ChangePersonalContentName:
                    item.index = "19000" + item.Name;
                    break;
                case DeliveryOptionNameToType.MovePersonalContent:
                    item.index = "20000" + item.Name;
                    break;
                case DeliveryOptionNameToType.SFPostToChatter:
                    item.index = "20100" + item.Name;
                    break;
                case DeliveryOptionNameToType.SFSaveAttachment:
                    item.index = "20200" + item.Name;
                    break;
                case DeliveryOptionNameToType.SFCreateContent:
                    item.index = "20300" + item.Name;
                    break;
                case DeliveryOptionNameToType.SFCreateContentDelivery:
                    item.index = "20400" + item.Name;
                    break;
                case DeliveryOptionNameToType.SendToSalesforce:
                    item.index = "21000" + item.Name;
                    break;
                case DeliveryOptionNameToType.SendToSharePoint:
                    item.index = "22000" + item.Name;
                    break;
                case DeliveryOptionNameToType.Normal:
                    item.index = "23000" + item.Name;
                    break;
                case DeliveryOptionNameToType.Unknown:
                default:
                    item.index = "99999" + item.Name;
                    break;
            }

            result.push(item);
        }

        result.sort(function (a, b) {
            return a.index > b.index ? 1 : (a.index == b.index ? 0 : -1);
        });

        return result;
    }

    seismic.GetLatestDocumentPreviewData = function(requestId, successCallback) {
        var params = {
            profileVersionId: seismic.profileInfo.ProfileVersionId,
            requestId: requestId
        };

        seismic.RemoteCall('GetLatestDocumentPreviewData', params, function(response) {
            //if the response contains the -1004 error, log in again
            if (response.Error == null) {
                successCallback(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.GetDocumentDetails, arguments);
            }
        });
    };

    seismic.GetLatestDocumentGenerateState = function(requestId, successCallback) {
        var params = {
            profileVersionId: seismic.profileInfo.ProfileVersionId,
            requestId: requestId
        };

        seismic.RemoteCall('GetLatestDocumentGenerateState', params, function(response) {
            //if the response contains the -1004 error, log in again
            if (response.Error == null) {
                successCallback(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.GetDocumentDetails, arguments);
            }
        });
    };

    /************************************************************************************************
    * Registers a distribution with the seismic system
    *
    * @param    doc  the document the work with
    * @param    success  a callback for if the delivery succeeds
    * @return   Calls the success callback when it completes, if it was successful
    *************************************************************************************************/
    seismic.RequestContentAsync = function(doc, success) {
		var options = {};
		
        //build the request body
        var reqBody = {
            'ClientInfo': {
                "ClientBaseAddress": null,
                "ClientSessionKey": null,
                "ClientType": seismic.pageInfo.PackageFullName
            },
            'RequestData': {
                'RequestDocuments': [{
                    'ContentProfileId': seismic.profileInfo.ProfileId,
                    'ContentProfileVersionId': seismic.profileInfo.ProfileVersionId,
                    'DocumentId': doc.BasicInfo.DocumentId,
                    'FullPathId': doc.BasicInfo.DocCenterFullPath,
                    'FullPathName': doc.BasicInfo.FullPath,
                    'Name': doc.BasicInfo.Name,
                    'VersionId': doc.BasicInfo.VersionId,
                    'MajorVersion': doc.BasicInfo.MajorVersion,
                    'MinorVersion': doc.BasicInfo.MinorVersion
                }]
            },
            'DistributionDefinition': {
                "CustomFileName": doc.BasicInfo.Name,
                "Channels": [{
                    "DataArchiveMethod": null,
                    "DownloadMethod": {
                
                    },
                    "EmailMethod": null,
                    "Name": "Download",
                    "OutputDefinition": {
                        "IsBindDocuments": false,
                        "BindDocumentFormat": doc.BasicInfo.Format,
                        "BindDocumentOutputName": doc.BasicInfo.Name,
                        "IndividualDocumentOutputFormats": [{
                            "DocumentName": doc.BasicInfo.Name,
                            "IsDocumantNameAlias": false,
                            "OriginalDocumentName": doc.BasicInfo.Name,
                            "Format": doc.BasicInfo.Format,
                            "Options": options
                        }]
                    }
                }]
            }
        };

        var params = {
            requestBody: JSON.stringify(reqBody),
            profileVersionId: seismic.profileInfo.ProfileVersionId
        };

        seismic.RemoteCall('RequestContentAsync', params, function(response) {
            success(response.ServiceResult);
        });
    };

    seismic.RequestContent = function (doc, form, objectId, sFIndexField, callback) {
        var documentName = doc.BasicInfo.Name;
        var formName = form.Name;
        var documentVersionId = doc.BasicInfo.VersionId;
        var formVersionId = form.VersionId;
        // TODO, fake customFileName, format and options
        var customFileName = doc.BasicInfo.CustomFileName || doc.BasicInfo.Name;
        var formatStr = FORMATS_TO_NAME[doc.BasicInfo.Format];

        var dataInput = null;
        if (sFIndexField) {
            dataInput = {
                VariableListData: [{
                    VariableListName: sFIndexField.BindVariableListName,
                    VariableData: [{
                        Name: sFIndexField.BindVariableFullName,
                        Value: objectId,
                        IsTable: false,
                        ChildVariableData: null
                    }]
                }]
            };
        }        

        var options = [
                        {
                            "Key": "DPI",
                            "Value": "200"
                        },
                        {
                            "Key": "PreviewMode",
                            "Value": ""
                        }
                    ];
                    
        var requestInput = {
            RequestData: {
                RequestDocuments: [{
                    ContentProfileId: seismic.profileInfo.ProfileId,
                    ContentProfileVersionId: seismic.profileInfo.ProfileVersionId,
                    DocumentId: doc.BasicInfo.DocumentId,
                    FullPathId: doc.BasicInfo.DocCenterFullPath,
                    FullPathName: doc.BasicInfo.FullPath,
                    Name: customFileName,
                    VersionId: documentVersionId,
                    MajorVersion: 0,
                    MinorVersion: 0,
                    Alias: "",
                    FormVersionId: formVersionId,
                    FormName: formName,
                    MiniFormRecords: [],
                    DataInput: dataInput
                }]
            },
            DistributionDefinition: {
                CustomFileName: customFileName,
                Channels: [{
                    Name: "Download",
                    OutputDefinition: {
                        IsBindDocuments: false,
                        BindDocumentFormat: formatStr,
                        BindDocumentOutputName: documentName,
                        IndividualDocumentOutputFormats: [{
                            DocumentName: documentName,
                            IsDocumantNameAlias: false,
                            OriginalDocumentName: documentName,
                            Format: formatStr,
                            Options: options
                        }]
                    }
                }]
            }
        };

        seismic.RequestDocumentAsync(requestInput, callback);
    }

    seismic.deliver = function(deliveryOptionId, reqId, formInputs, collectionId) {
        var deferred = $q.defer();

        var params = {
            salesforceObjectId: seismic.pageInfo.objectId,
            salesforceObjectType: seismic.pageInfo.objectType,
            salesforceObjectName: seismic.pageInfo.objectName,
            requestId: reqId,
            distributionOptionId: deliveryOptionId,
            profileVersionId: seismic.profileInfo.ProfileVersionId,
            formInputs: formInputs
        };

        if (collectionId) {
            params.collectionId = collectionId;
        }
        
        
        function _callback(result) {
            if (result) {
                if (result.StatusType === 90) {
                    deferred.reject(result);
                    return;
                }
                if (result.StatusType === 100) {
                    deferred.resolve(result);
                    return;
                }
            }
            
            setTimeout(function () {
                seismic.RemoteCall('DeliveryResult', {
                        deliveryRequestId: result.DeliveryRequestId,
                        profileVersionId: seismic.profileInfo.ProfileVersionId
                    },
                    function(resp) {
                        _callback(resp.ServiceResult);
                    });
                }, 1000);
        }
        
        
        seismic.RemoteCall('Deliver', params,
            function(response) {
                _callback(response ? response.ServiceResult : null);
            });

        return deferred.promise;
    };

    seismic.createSharedLink = function (contentId) {
        var deferred = $q.defer();

        var params = {
            contentId: contentId,
            profileVersionId: seismic.profileInfo.ProfileVersionId
        };

        seismic.RemoteCall('CreateSharedLink', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.getDirectRequestForm, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    }

    /************************************************************************************************
    * This will ask the server is this form has no inputs
    *
    * @param    fvId    The form version from the document details
    * @return   Requests the document to be generated
    *************************************************************************************************/
    seismic.GetDirectRequestForm = function(formVersionId, callback) {

        var params = {
            formVersionId: formVersionId
        };

        seismic.RemoteCall('GetDirectRequestForm', params, function(response) {
            callback(response);
        });
    };

    seismic.getDirectRequestForm = function(formVersionId) {
        var deferred = $q.defer();

        var params = {
            formVersionId: formVersionId
        };

        seismic.RemoteCall('GetDirectRequestForm', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.getDirectRequestForm, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };

    seismic.updatePreviewDeliveryFormat = function(requestId, format, finalBlobId) {
        var deferred = $q.defer();

        var params = {
            requestid: requestId,
            format: format,
            finalblobid: finalBlobId
        };

        seismic.RemoteCall('UpdatePreviewDeliveryFormat', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.updatePreviewDeliveryFormat, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };

    seismic.getPreviewBlobInfo = function(requestId) {
        var deferred = $q.defer();

        var params = {
            requestid: requestId
        };

        seismic.RemoteCall('GetPreviewBlobInfo', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.getPreviewBlobInfo, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };

    seismic.updateDocument = function(requestId, finalBlobId, basicFormat, requestFormat, uniqIds, additionInfo) {
        var deferred = $q.defer();
		
		var requestInputs = {"BasicDocumentType": basicFormat, "RequestDocumentType": requestFormat, "FinalImageUniquedIds": uniqIds, "AdditionInfo": additionInfo};
        var params = {
            requestid: requestId,
            finalblobid: finalBlobId,
            requestBody: JSON.stringify(requestInputs)
        };

        seismic.RemoteCall('UpdateDocument', params, function(response) {
            if (response.Error == null) {
                deferred.resolve(response.ServiceResult);
            } else {
                seismic.HandleError(response.Error, seismic.updateDocument, arguments);
                deferred.reject(response.Error);
            }
        });

        return deferred.promise;
    };

    /************************************************************************************************
    * This will get the definition for the form
    *
    * @param    fvId    The form version from the document details
    * @return   Requests the document to be generated
    *************************************************************************************************/
    seismic.GetFormDefinition = function(doc, fvId) {

        var params = {
            formVersionId: fvId
        };

        seismic.RemoteCall('GetFormDefinition', params, function(response) {

            //request the document by spoofing the type they want
            seismic.RequestDocument(doc, fvId);
        });
    };

    seismic.RequestDocumentAsync = function(data, callback) {
        seismic.RemoteCall('RequestDocument', {reqBody:JSON.stringify(data)}, function(response) {
            callback(response);
        });
    };


    /************************************************************************************************
    * This will continually check on the status of a document, until it receives a success
    * or failure status
    *
    * @param    requestId    The form version from the document details
    * @return   Opens the document viewer
    *************************************************************************************************/
    seismic.CheckRequestResult = function(reqId, callback) {
        var params = { requestId: reqId };
        seismic.RemoteCall('CheckRequestResult', params,
        	function(response) {
                if (angular.isFunction(callback)) {
                    callback(response);
                }
            });
    }


    seismic.GetChatterGroups = function() {
        var deferred = $q.defer();

        var params = {};

        seismic.RemoteCall('GetChatterGroups', params, function(response) {
            deferred.resolve(response);
        });

        return deferred.promise;
    };

    /************************************************************************************************
    * If an endpoint returns an error object, this function will determine the response
    *
    * @param    error        The error object returned from the endpoint
    * @param    callback     The function that should be called when the error is handled
    * @param    arguments    The arguments that should be passed to the callback
    *************************************************************************************************/
    seismic.HandleError = function(error, callback, arguments) {
        //if this is error code -1004, the session has expired. Log in again and then
        //retry the function that failed
        if (error.ErrorCode === -1004) {

            seismic.RemoteCall('LogInWithIdentityToken', null, function(response) {
                $rootScope.$apply(function() {
                    //update the credentials and the error state
                    seismic.errorState = response.Error;
                    seismic.securityCredentials = response.ServiceResult;
                });

                //after validating, update the session cookie
                if (response.Error == null) {
                    //store the session credentials
                    localStorage.setItem('credentials', JSON.stringify(response.ServiceResult));

                    seismic.UpdateSessionCookie(false);

                    callback.apply(this, arguments);
                } else {
                    $rootScope.$apply(function() {
                        $rootScope.formState = 'login';
                    });
                }
            });
        } else if (error.ErrorCode === -1002 || error.ErrorCode === -1) {
            $rootScope.formState = 'login';
        }
    };

    return seismic;
});

Seismic.factory('seismicInit', function(seismic, $q, $timeout, $localStorage) {
    
    $localStorage.seismicInitInfoCache = $localStorage.seismicInitInfoCache || {};
    var seismicInitInfoCache = $localStorage.seismicInitInfoCache;

    var seismicInit = {};
    var _isInited = false;
    var _needOrganization = true;

    function _syncSession(seismicSessionId, onSyncFinihsed, deferred) {
        //submit the form to get the cookie
        var sessionForm = document.getElementById("autoSubmitForm");
        if (sessionForm != null) {
            var inputSeismicSeissionId = document.getElementById("SeismicSessionId");
        	inputSeismicSeissionId.setAttribute("value", seismicSessionId);
        	
        	var iframe = document.getElementById("iframeUnitedLogin");
            iframe.onload = function () {
            	seismic.RemoteCall('SessionSynchronized', { },
            		function (response) {
		                if (onSyncFinihsed) {
		                	onSyncFinihsed(deferred);
		                }
            		});
            }

            sessionForm.submit();
        }
    };

    function _onSyncFinihsed(deferred) {
        var pageLoadingPanel = document.getElementById("pageloading-panel");
        pageLoadingPanel.setAttribute("style", "display: none;");
        
        if (pageInfo.seismicIsLogined) {
        	_initialUserInfo(deferred);
        } else {
        	deferred.reject('NoLoggedIn');
        	if (window.console) {
        		console.log("not logged in, waiting for input username/password or SSO!");
    		}
        	
        	if (pageInfo.seismicSingleSignOnEnabled) {
        		var singleSignOnPanel = document.getElementById("singlesignon-panel");
        		singleSignOnPanel.setAttribute("style", "min-height: 200px;");
        		
        		if (pageInfo.EnableSingleSignOnAutoRedirection) {
        			// Show loading
        			pageLoadingPanel.setAttribute("style", "");
        			
			    	var linkSSO = document.getElementById("LinkToSeismicSSO");
			    	if (linkSSO != null) {
			    		var ssoUrl = linkSSO.getAttribute('href');
						window.top.location = ssoUrl;
			    	}
			    }
        	} else {
        		var loginPanel = document.getElementById("login-panel");
        		loginPanel.setAttribute("style", "min-height: 200px;");
        	}
        }
    }
    
    function _initialUserInfo(deferred) {
        var key = 'userInfo';
        var value = seismicInitInfoCache[key];
        if (value) {
            $timeout(function() {
                _callback(value, true);
            });
        }
        _serviceCall();
        return;

        function _callback(userInfo, isFromCache) {
            if (userInfo) {
                seismic.userInfo = userInfo;
                seismic.UserName = userInfo.UserName;
                
                if (!$App.loginInfo) {
                	$App.loginInfo = {};
                }
                $App.loginInfo.tenant = seismic.Tenant;
                $App.loginInfo.username = seismic.UserName;
                $App.loginInfo.clientType = encodeURIComponent(seismic.pageInfo.PackageFullName);
                
                deferred.notify(isFromCache);
                if (!isFromCache) {
                	if (_needOrganization) {
                	    _initialOrganization(deferred);
                	} else {
                        deferred.resolve();
                	}
                }
            }
        }

        function _serviceCall(callback) {
            seismic.RemoteCall('GetUserInfo', null, function(response) {
                if (response) {
                    if (response.ServiceResult) {
                    	var result = response.ServiceResult;
                        seismicInitInfoCache[key] = result;
                        _callback(result, false);
                    } else {
                        deferred.reject(response.Error);
                    }
                } else {
                    deferred.reject();
                }
            });
        }
    };
    
    function _initialOrganization(deferred) {
        seismic.RemoteCall('GetOrganizationSettings', null, function(response) {
            if (response) {
                if (response.ServiceResult) {
                    var result = response.ServiceResult;
                    var appSettings = result.AppSettings;
                    $App.salesforceOrganization = appSettings;
                    deferred.resolve();
                } else {
                    deferred.reject(response.Error);
                }
            } else {
                deferred.reject();
            }
        });
    };

    seismicInit.init = function (params) {
        var deferred = $q.defer();

        if (_isInited) {
            $timeout(function() {
                deferred.resolve(seismic.userInfo);
            });
            return deferred.promise;
        } else {
        	_isInited = true;
    	}

        seismic.Tenant = pageInfo.seismicTenant;
        
        if (params) {
            seismic.profileInfo = {
                ProfileId: params.profileId,
                ProfileVersionId: params.profileVersionId
            };
            
            if (params.skipOrganization) {
            	_needOrganization = false;
        	}
        }
        
        /*
        if (window.console) {
	        try {
	        	console.debug("Window Top Url: " + window.top.location.href);
	        } catch (e) {
	            console.debug(e);
	        } finally {
	            console.debug("PageInfo Top Url: " + pageInfo.TopPageUrl);
	            //alert(pageInfo.seismicRequireTurnOnCookie + '|' + pageInfo.seismicRequireSessionSynchronicity + ' -- ' + navigator.userAgent);
	        }
        }
        */
        
        seismic.RemoteCall('Authorize', { PageUrl: window.location.href, UserAgent: window.navigator.userAgent },
        	function (response) {
        		if (response) {
        			pageInfo.seismicRequireTurnOnCookie = response.RequireTurnOnCookie;
        			pageInfo.seismicRequireSessionSynchronicity = response.RequireSessionSynchronicity;
        			pageInfo.seismicIsLogined = response.IsLogined;
        			pageInfo.seismicSingleSignOnEnabled = response.SingleSignOnEnabled;
        			pageInfo.EnableSingleSignOnAutoRedirection = response.EnableSingleSignOnAutoRedirection;
    			}
        	
		        if (response.RequireTurnOnCookie) {
			        var currentTopPageUrl = pageInfo.TopPageUrl;
			        var gotoUrl = 'https://'+ pageInfo.seismicTenant + '.seismic.com/HTML5/PrepareCookieForIframe.aspx?redirectUrl=' + escape(currentTopPageUrl);
			        window.top.location = gotoUrl;
		        } else if (response.RequireSessionSynchronicity) {
		            _syncSession(response.SeismicSessionId, _onSyncFinihsed, deferred);
		        } else {
		            _onSyncFinihsed(deferred);
		        }
        	});

        return deferred.promise;
    };
    
    return seismicInit;
});