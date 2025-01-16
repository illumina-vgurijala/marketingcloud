var Distribution = angular.module('DistributionManager', ['SeismicConnector']);

Distribution.factory('distribution', function($rootScope, $location, $modal, $q, $timeout, seismic) {
    // openDeliveryOption: need to be set outside, it means when it needs open dialog
    var dist = {openDeliveryOption: angular.noop};

    // Only export one API, this one.
    dist.deliver = function(currentSObject, deliveryOption, currentDocument, generatedDocument, requestId) {
        if (window.console) {
        	console.log(deliveryOption, currentDocument);
    	}

        switch(deliveryOption.Type) {
            case DeliveryOptionNameToType.Normal:
                {
	                if (deliveryOption.HasForm) {
	                    _openDistributionDialog();
	                } else {
	                    _deliver(currentDocument, deliveryOption, requestId, 'Delivering...');
	                }
                } break;
            case DeliveryOptionNameToType.Download:
                _downloadFile(currentSObject, currentDocument, generatedDocument, requestId);
                break;
            case DeliveryOptionNameToType.SendToLiveShare:
                _deliver(currentDocument, deliveryOption, requestId, 'Sending to LiveShare...');
                _openLiveShare();
                break;
            case DeliveryOptionNameToType.SendToGmail:
                _deliver(currentDocument, deliveryOption, requestId, 'Sending to Gmail...');
                break;
            case DeliveryOptionNameToType.SendToCart:
                _deliver(currentDocument, deliveryOption, requestId, 'Sending to cart...', 'Successfully added to cart.');
                break;
            case DeliveryOptionNameToType.SendByEmail:
            case DeliveryOptionNameToType.CreateSharedLink:
            case DeliveryOptionNameToType.SaveToPersonal:
            case DeliveryOptionNameToType.SendToLiveSend:
            case DeliveryOptionNameToType.SFSendByEmail:
            case DeliveryOptionNameToType.SFPostToChatter:
            case DeliveryOptionNameToType.SFSaveAttachment:
            case DeliveryOptionNameToType.SFCreateContent:
            case DeliveryOptionNameToType.SFCreateContentDelivery:
                _openDistributionDialog();
                break;
            case DeliveryOptionNameToType.AddPersonalCollection:
            case DeliveryOptionNameToType.RemovePersonalContent:
            case DeliveryOptionNameToType.MovePersonalContent:
            case DeliveryOptionNameToType.ChangePersonalContentName:
            case DeliveryOptionNameToType.EditPersonalContent:
            case DeliveryOptionNameToType.SendToSalesforce:
            case DeliveryOptionNameToType.SendToSharePoint:
            default:
            	{
            		
            	} break;
        }

        function _openDistributionDialog() {
        	var deliveryPromise = _prepareToDeliver(currentDocument, deliveryOption.Type, requestId); 
            _openDistDialog(deliveryOption.Type, deliveryOption.DeliveryOptionId, deliveryPromise);
        }
    };

    function _openDistDialog(deliveryOptionType, deliveryOptionId, requestIdPromise) {
        dist.openDeliveryOption(deliveryOptionType, deliveryOptionId, requestIdPromise);
    };
    
    function _prepareToDeliver(currentDocument, deliveryOptionType, requestId) {
        return $q(function(resolve, reject) {
            if (!!requestId) {
                resolve(requestId);
            } else {
                seismic.RequestContentAsync(currentDocument, function (result) {
                    resolve(result.RequestId);
                }); // TODO reject
            }
        });
    }

    function _openLiveShare() {
        var url = 'https://' + seismic.Tenant + '.seismic.com/HTML5/LiveShare.aspx?fromClientType=' + encodeURIComponent(seismic.pageInfo.PackageFullName) + '#requesterHome';
        window.open(url, '_blank');
    };

    function _deliver(currentDocument, deliveryOption, requestId, busyMessage, succeedMessage) {
		if (currentDocument) {
            currentDocument.isBusy = true;
            currentDocument.busyMessage = busyMessage;
        }

        return _prepareToDeliver(currentDocument, deliveryOption.Type, requestId)
                    .then(function(requestId) {
                        return seismic.deliver(deliveryOption.DeliveryOptionId, requestId);
                    })
                    .then(function() {
                    	if (succeedMessage) {
                    		currentDocument.busyMessage = succeedMessage;
                    		currentDocument.busyIconHidden = true;
                    		$timeout(function () {
					        	currentDocument.busyIconHidden = false;
								currentDocument.isBusy = false;
							}, 3000);
                    	} else {
                        	currentDocument.isBusy = false;
                    	}
                    },
                    function(error) {
                    	currentDocument.isBusy = false;
                    	
                    	alert('Deliver content failed!\n' + error.ErrorMessage);
                    });
    }

    function _downloadFile(currentSObject, currentDocument, generatedDocument, requestId) {
        var busyMessage = 'Delivering...';
        if (currentDocument) {
            currentDocument.isBusy = true;
            currentDocument.busyMessage = busyMessage;
        }

        __downloadFile(currentSObject, currentDocument, generatedDocument, requestId)
            .then(function(url) {
                window.open(url, '_blank');
                return;
            })
            .then(function() {
                var deliveryOption = _findDeliveryOption(currentDocument, DeliveryOptionNameToType.Download);
                _deliver(currentDocument, deliveryOption, requestId, busyMessage);
            });
    };

    function __downloadFile(currentSObject, currentDocument, generatedDocument, requestId) {
        var params = {};
        if (generatedDocument && requestId) {
        	var formatName = (generatedDocument.Format || "");
        	formatName = (formatName.indexOf("xlsx-model") == 0) ? "XLSX" : formatName.toUpperCase();
            params = {
                fileId: generatedDocument.OutputFileId,
                fileName: generatedDocument.DocumentName,
                fileFormat: DocumentFormats[formatName],
                isPersonal: false
            };
        }else {
            params = {
                fileId: currentDocument.SourceBlobId,
                fileName: currentDocument.BasicInfo.Name,
                fileFormat: currentDocument.BasicInfo.Format,
                contentType: currentDocument.BasicInfo.Type,
                isPersonal: false
            };
        }

        return $q(function(resolve, reject) {
            seismic.RemoteCall('GetFileDownloadUrl', params, function(response) {
                resolve(response.FileUrl);
            });
        });
    }

    function _initDocument (docId) {
        var i = seismic.documents.length;
        while(i--) {
            if(seismic.documents[i].VersionId === docId) {
                $scope.currentDocument = seismic.documents[i];
                break;
            }
        }
    }

    function _findDeliveryOption (currentDocument, optionType) {
        var i = currentDocument.DeliveryOptions.length;
        while (i--) {
            if (currentDocument.DeliveryOptions[i].Type === optionType) {
                return currentDocument.DeliveryOptions[i];
            }
        }
    }

/*
    dist.LookupContacts = function(frag, contactList) {

        //only call the server if they are beyond three characters
        if (+frag.length < 2) {
            contactList = [];
            return;
        }

        var params = {
            'lookup': frag
        };

        seismic.RemoteCall('LookupContact', params, function(response) {

            //set the list of contact options to appear
            $rootScope.$apply(function() {
                contactList = response;
            });
        });
    };
*/


    return dist;
});