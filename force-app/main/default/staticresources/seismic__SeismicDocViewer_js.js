(function () {
    'use strict';

    var DeliveryOptionControllerMap = {};
    DeliveryOptionControllerMap[DeliveryOptionNameToType.Normal] = 'SeismicDocViewerDeliveryCustomDeliveryFormController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.CreateSharedLink] = 'SeismicDocViewerDeliveryCreateSharedLinkController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SendToLiveSend] = 'SeismicDocViewerDeliveryLiveSendController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SaveToPersonal] = 'SeismicDocViewerDeliveryAdd2PersonalSpaceController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SFSendByEmail] = 'SeismicDocViewerDeliveryEmailController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SFPostToChatter] = 'SeismicDocViewerDeliverySFPostToChatterController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SFSaveAttachment] = 'SeismicDocViewerDeliverySFSaveAttachmentController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SFCreateContent] = 'SeismicDocViewerDeliverySFCreateContentController';
    DeliveryOptionControllerMap[DeliveryOptionNameToType.SFCreateContentDelivery] = 'SeismicDocViewerDeliverySFCreateContentDeliveryController';


    angular
        .module('seismicDocViewer',
            [
                'ui.bootstrap',
                'ngTouch',
                'ngStorage',
                'ngRoute',
                'SeismicConnector',
                'DistributionManager',
                'ngAnimate',
                'toaster',
                'seismic.ui',
                'seismic.doccenter.contactSearcher',
                'seismic.doccenter.commonform.distributionpreview.previewreorder',
            ])
        .filter('seismicFormatToName', function () {
            return function (input) {
                return FORMATS_TO_NAME[input] || "UNKNOWN";
            };
        })
        .filter('seismicDateToLong', function () {
            return function (input) {
                return (input || '').replace(/\/Date\((-?\d+)\)\//, "$1");
            };
        })
        .constant('SeismicDocViewer_DeliveryOptionList_include_html', SeismicDocViewer_DeliveryOptionList_include_html)
        .constant('SeismicIcons', SeismicIcons)
        .constant('SeismicDeliverOptionIcon', SeismicDeliverOptionIcon)
        .factory('params', function () {
            return {};
        })
        .factory('currentDocument', function () {
            return {};
        })
        .factory('currentSObject', function () {
            return {};
        })
        .factory('currentDeliveryOption', function () {
            return {};
        })
        .factory('currentGeneratedDocument', function(){
            return {};
        })
        .factory('currentOutput', function(){
            return {};
        })
        .factory('previewReorderData', function(){
            return {
                pages: [],
                orignalPages: [],
                pagesInitialized: false,
                stack: null
            };
        })
        .factory('seismicSObjectCache', function($localStorage) {
            $localStorage.seismicSObjectCache = $localStorage.seismicSObjectCache || {};
            return $localStorage.seismicSObjectCache;
        })
        .factory('seismicDocumentDetailCache', function ($localStorage) {
            $localStorage.seismicDocumentDetailCache = $localStorage.seismicDocumentDetailCache || {};
            return $localStorage.seismicDocumentDetailCache;
        })
        .factory('sideBarStatus', function () {
            var sideBarStatus = {};
            sideBarStatus.isDisplay = isSalesforce1 ? false : true;
            sideBarStatus.mainStyle = isSalesforce1 ? { 'margin-left': '0px' } : {};
            sideBarStatus.isLightning = isLightning;
            sideBarStatus.switch = function () {
                if (!isSalesforce1) {
                    return;
                }
                sideBarStatus.isDisplay = !sideBarStatus.isDisplay;
                sideBarStatus.mainStyle = sideBarStatus.isDisplay ? {} : { 'margin-left': '0px' };
                $('body').css({ 'padding-left': sideBarStatus.isDisplay ? '10px' : '0px' });
            };
            return sideBarStatus;
        })
        .controller("SeismicDocViewerSideBarController", function($scope, $routeParams, $sce, params, seismic, distribution, currentSObject, currentDocument, sideBarStatus) {
            $scope.params = params;
            
            $scope.currentSObject = currentSObject;
            $scope.currentDocument = currentDocument;
            $scope.status = sideBarStatus;
            $scope.iconGotoCart = SeismicIcon.GOTO_CART;
        })
        .controller('SeismicDocViewerContentController', function ($scope, $route, $routeParams, $location, $rootScope, toaster, sideBarStatus) {
            $scope.$route = $route;
            $scope.$location = $location;
            $scope.$routeParams = $routeParams;
            $scope.sideBarStatus = sideBarStatus;

            $rootScope.$on('toaster', function (event, args) {
                toaster.pop(args);
            });
        })
        .controller("SeismicDocViewerStaticController", function ($scope, $rootScope, $q, $timeout, $routeParams, params, $sce, seismicSObjectCache, seismicDocumentDetailCache, currentSObject, currentDocument, currentOutput, seismic, seismicInit, distribution, sideBarStatus, SeismicDocViewer_DeliveryOptionList_include_html) {
            $scope.params = params;
            angular.extend($scope.params, $routeParams);

            $scope.seismicDocViewer_DeliveryOptionList_include_html = SeismicDocViewer_DeliveryOptionList_include_html;
            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            $scope.currentOutput = currentOutput;
            $scope.distribution = distribution;
            $scope.sideBarStatus = sideBarStatus;

            seismicInit.init($routeParams)
                .then(function () {
                    return _initializeSObject(seismic, $scope, $q, $timeout, seismicSObjectCache);
                })
                .then(function () {
                    $rootScope.isReady = true;
                    $rootScope.isSiderbarReady = true;
                    return _initializeDocument(seismic, $scope, $q, $timeout, $sce, seismicDocumentDetailCache);
                })
                .then(function (currentDocument) {
                    try {
                        _initializeDocumentThumbnails(seismic, currentDocument, $scope);
                        _initializeVideo(seismic, currentDocument, $scope, $sce);
                        _initializeExternalUrl(seismic, currentDocument, $scope, $sce);
                        _initializeExternalVideo(seismic, currentDocument, $scope, $sce);
                    } catch (e) {
                        //alert(e);
                    }
                });
        })
        .controller("SeismicDocViewerLiveDocController", function ($scope, $rootScope, $q, $timeout, $location, $routeParams, params, $sce, seismicSObjectCache, seismicDocumentDetailCache, currentSObject, currentDocument, currentOutput, seismic, seismicInit, distribution, sideBarStatus) {
            $scope.params = params;
            angular.extend($scope.params, $routeParams);
            
            $scope.currentSObject = currentSObject;
            $scope.currentDocument = currentDocument;
            $scope.currentFormApps = null;
            $scope.currentOutput = currentOutput;
            $scope.sideBarStatus = sideBarStatus;

            $scope.liveFormIconSrc = SeismicFormatIcon.FORM_PNG_URL;

            
            seismicInit.init($routeParams)
                .then(function () {
                    return _initializeSObject(seismic, $scope, $q, $timeout, seismicSObjectCache);
                })
                .then(function () {
                    $rootScope.isReady = true;
                    $rootScope.isSiderbarReady = true;
                    return _initializeDocument(seismic, $scope, $q, $timeout, $sce, seismicDocumentDetailCache);
                })
                .then(function (currentDocument) {
                    if (currentDocument.FormApps && currentDocument.FormApps.length == 1) {
                        var form = currentDocument.FormApps[0];
                        var hash = _buildFormUrl($scope, seismic, form);
                        $location.path(hash);
                        $location.replace();
                    } else {
                        $scope.currentFormApps = currentDocument.FormApps;
                    }
                });
        })
        .controller("SeismicDocViewerLiveFormController", function ($scope, $rootScope, $location, $q, $timeout, $routeParams, params, $sce, seismicSObjectCache, seismicDocumentDetailCache, currentSObject, currentDocument, currentOutput, seismic, seismicInit, distribution, sideBarStatus) {
            $scope.params = params;
            angular.extend($scope.params, $routeParams);

            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            $scope.currentOutput = currentOutput;
            $scope.sideBarStatus = sideBarStatus;

            $scope.isLiveFormReady = false;
            
            seismicInit.init($routeParams)
                .then(function () {
                    return _initializeSObject(seismic, $scope, $q, $timeout, seismicSObjectCache);
                })
                .then(function () {
                    $rootScope.isReady = true;
                    $rootScope.isSiderbarReady = true;
                    return _initializeDocument(seismic, $scope, $q, $timeout, $sce, seismicDocumentDetailCache);
                })
                .then(function (currentDocument) {
                    $scope.currentForm = _getFormFromDoc($scope);
                    return _getDirectRequestForm($scope, seismic, $q, currentDocument, $scope.currentForm, $timeout);
                })
                .then(function (data) {
                    angular.extend($scope.currentForm, data);
                    
                    var defaultOutput = $scope.currentForm.availableOutputDefinitions[0];
                    $scope.currentSelectedOutput = defaultOutput;
                    
                    angular.extend($scope.currentOutput, defaultOutput);
                    $scope.currentOutput.isReady = false;
                    
                    if ($scope.currentForm.type == DirectRequestFormType.NoInput || $scope.currentForm.type == DirectRequestFormType.SFIndexFieldOnly) {
                        seismic.RequestContent($scope.currentDocument, $scope.currentForm, $scope.currentSObject.objectId, $scope.currentForm.sfIndexField,
                        	function (response) {
                        	    var hash = _buildGeneratedUrl($scope, seismic, response.RequestId);
                        	    $rootScope.$apply(function () {
                        	        $location.path(hash);
                        	        $location.replace();
                        	    });
                        	});
                    } else {
                        $scope.currentFormPageUrl = $sce.trustAsResourceUrl(_getFormUrl(seismic, $scope));
                    }
                });

            $scope.liveFormReady = false;
            $scope.$on("$destroy", function () {
                window.removeEventListener("message", _liveFormHandler);
            });

            window.addEventListener("message", _liveFormHandler);

            function _liveFormHandler(e) {
                __liveFormReadyHandler(e, seismic, $rootScope, $scope, $location);
                __checkRequestResultFromLiveForm(e, seismic, $rootScope, $scope, $location);
            }
        })
        .controller("SeismicDocViewerGeneratedController", function($scope, $rootScope, $location, $q, $timeout, $interval, $routeParams, params, $sce, seismicSObjectCache, seismicDocumentDetailCache, currentSObject, currentDocument, currentOutput, seismic, seismicInit, distribution, sideBarStatus, SeismicDocViewer_DeliveryOptionList_include_html, SeismicDeliverOptionIcon, previewReorderData, currentGeneratedDocument) {
            currentDocument.IsLiveDoc = true;

            $scope.params = params;
            angular.extend($scope.params, $routeParams);

            $scope.seismicDocViewer_DeliveryOptionList_include_html = SeismicDocViewer_DeliveryOptionList_include_html;
            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            $scope.distribution = distribution;
            $scope.sideBarStatus = sideBarStatus;

            $scope.renderType = params.renderType;
            $scope.requestId = params.requestId;
            $scope.currentOutput = currentOutput;

            $scope.progressMessage = 'Generating, progress: 0%';

            $scope.hasError = false;
            $scope.errorMessage = '';

            $scope.canPreviewEdit = true;

            $scope.editIconUrl = SeismicDeliverOptionIcon.CDO_EDIT;
            $scope.reorderAndEditEnabled = true;
            
            if(!previewReorderData.stack) {
                previewReorderData.stack = new Undo.Stack();
            }

            $scope.reorderAndEdit = function () {
                if (!$scope.canPreviewEdit) {
                    return;
                }

                _redirectToPreviewReorder($scope, seismic, $scope.requestId, $rootScope, $location);
            }

            $scope.updateCurrentOutput = function(newSelectedOutput) {
                $scope.currentDocument.isBusy = true;
                $scope.currentDocument.busyMessage = 'Loading...';
                $scope.currentGeneratedDocument.isReady = false;

                var selectedOutput = angular.extend({}, newSelectedOutput || $scope.currentOutput);
                selectedOutput.DeliveryFormat = selectedOutput.Format.indexOf("xlsx-model") == 0 ? "XLSX" : selectedOutput.Format;
                angular.extend($scope.currentOutput, selectedOutput);
                
                seismic.updatePreviewDeliveryFormat($scope.params.requestId, selectedOutput.DeliveryFormat, selectedOutput.finalBlobId)
                    .then(function () {
                        if (selectedOutput.isReady || !$scope.pages || $scope.pages.length == 0) {
                            return;
                        }

                        var ids = $scope.pages.map(function (n) { return n.UniqeId; });
                        var basicFormat = $scope.currentDocument.BasicInfo.Type;
                        var requestFormat = null;
                        switch (selectedOutput.DeliveryFormat) {
                            case 'PPTX': requestFormat = DocumentTypes.PRESENTATION; break;
                            case 'DOCX': requestFormat = DocumentTypes.MSWORD; break;
                            case 'XLSX': requestFormat = DocumentTypes.EXCEL; break;
                            case 'PDF': requestFormat = DocumentTypes.PDF; break;
                            default: requestFormat = DocumentTypes.PDF; break;
                        }
                        var additionInfo = [];
                        if ($scope.currentForm.availableOutputDefinitions) {
                            for (var index in $scope.currentForm.availableOutputDefinitions) {
                                var outputOption = $scope.currentForm.availableOutputDefinitions[index];
                                if (outputOption.DisplayName == selectedOutput.DisplayName &&
                                    outputOption.Format == selectedOutput.Format &&
                                    outputOption.Options) {
                                    for (var optionIndex in outputOption.Options) {
                                        var option = outputOption.Options[optionIndex];
                                        if (option && option.Key && option.Value) {
                                            additionInfo.push(option);
                                        }
                                    }

                                    break;
                                }
                            }
                        }

                        return seismic.updateDocument($scope.params.requestId, selectedOutput.finalBlobId, basicFormat, requestFormat, ids, additionInfo);
                    })
                    .then(function () {
                        if (selectedOutput.finalBlobId) {
                            return;
                        }

                        return seismic.getPreviewBlobInfo($scope.params.requestId);
                    })
                    .then(function (blobIdMap) {
                        if (window.console) {
                            console.log(selectedOutput.finalBlobId, blobIdMap);
                        }
                        if (!selectedOutput.finalBlobId && blobIdMap) {
                            if (selectedOutput.Format.toUpperCase() == "PDF") {
                                selectedOutput.finalBlobId = blobIdMap.FinalPDFBlobId;
                            } else if (selectedOutput.Format == "PPTX" || selectedOutput.Format == "DOCX") {
                                selectedOutput.finalBlobId = blobIdMap.FinalDataBlobId;
                            } else {
                                selectedOutput.finalBlobId = blobIdMap.FinalExcelBlobId;
                            }
                        }

                        selectedOutput.isReady = true;
                        $scope.currentGeneratedDocument.OutputFileId = selectedOutput.finalBlobId;
                        $scope.currentGeneratedDocument.Format = selectedOutput.Format;
                        $scope.currentGeneratedDocument.isReady = true;

                        $scope.currentDocument.isBusy = false;
                    });
            };

            var _isPagesDataDirty = false;
            seismicInit.init($routeParams)
                .then(function () {
                    return _initializeSObject(seismic, $scope, $q, $timeout, seismicSObjectCache);
                })
                .then(function () {
                    $rootScope.isReady = true;
                    $rootScope.isSiderbarReady = true;
                    return _initializeDocument(seismic, $scope, $q, $timeout, $sce, seismicDocumentDetailCache);
                })
                .then(function (currentDocument) {
                    $scope.currentForm = _getFormFromDoc($scope);
                    return _getDirectRequestForm($scope, seismic, $q, currentDocument, $scope.currentForm, $timeout);
                })
                .then(function (data) {
                    if (data.availableOutputDefinitions) {
                        angular.extend($scope.currentForm, data);

                        var defaultOutput = null;
                        if ($scope.currentOutput && $scope.currentOutput.DisplayName) {
                            for (var i = 0, count = $scope.currentForm.availableOutputDefinitions.length; i < count; i++) {
                                if ($scope.currentForm.availableOutputDefinitions[i].DisplayName === $scope.currentOutput.DisplayName) {
                                    defaultOutput = $scope.currentForm.availableOutputDefinitions[i];
                                    break;
                                }
                            }
                        }
                        if (!defaultOutput) {
                            defaultOutput = $scope.currentForm.availableOutputDefinitions[0];
                        }
                        $scope.currentSelectedOutput = defaultOutput;
                        angular.extend($scope.currentOutput, defaultOutput);
                    }

                    if ($scope.renderType == "canceled") {
                        $scope.pages = previewReorderData.pages;
                        return null;
                    } else if ($scope.renderType == "saved") {
                        _isPagesDataDirty = _isDirty($scope.pages, previewReorderData.pages);
                        $scope.pages = previewReorderData.pages;
                        return null;
                    } else {
                        _setImagesHandlersForLiveDoc($scope);
                        return _checkPreviewResult($q, seismic, $scope.params.requestId, $interval);
                    }
                })
                .then(
                    function (generatedDocument) {
                        if (generatedDocument) {
                            angular.extend(currentGeneratedDocument, generatedDocument);
                            
                            var search = _getUrlSearcher()
				            var addSfActivityHistoryParams = {
					            type: 'generate',
					            currentDocument: generatedDocument.OutputFileName,
					            objectId: search.sid.substring(0, 15)
					        	};
                                
                        	seismic.AddSfActivityHistory(addSfActivityHistoryParams);
                        		
                        } else {
                            generatedDocument = currentGeneratedDocument;
                        }

                        if (window.console) {
                            console.log(generatedDocument);
                        }
                        $scope.currentGeneratedDocument = generatedDocument;

                        if ($scope.renderType == "canceled") {
                            $scope.currentOutput.isReady = true;
                            $scope.currentGeneratedDocument.isReady = true;
                            $scope.currentDocument.isBusy = false;
                            _addSlides();
                        } else if ($scope.renderType == "saved") {
                            var outputs = $scope.currentForm.availableOutputDefinitions;
                            if (_isPagesDataDirty && outputs && outputs.length > 0) {
                                for(var i = 0; i < outputs.length; i++) {
                                    outputs[i].isReady = false;
                                    outputs[i].finalBlobId = null;
                                }
                            }

                            if (window.console) {
                                console.log($scope.currentOutput)
                            }
                            $scope.updateCurrentOutput($scope.currentSelectedOutput);
                            _addSlides();
                        } else {
                            $scope.updateCurrentOutput($scope.currentSelectedOutput);
                        }

                        _deleteLoadingSlide();
                        _finishLoading();

                        function _addSlides () {
                            var documentUrls = $scope.pages.map(function (item) {
                                var url = 'https://' + seismic.Tenant + '.seismic.com/Resource/Image.ashx?'
                                    + 'tenant=' + seismic.Tenant 
                                    + '&user=' + seismic.UserName 
                                    + '&client=' + encodeURIComponent(seismic.pageInfo.PackageFullName)
                                    + '&imageid=' + item.BlobId;
                                return url;
                            })
                            _setImagesHandlers($scope, documentUrls);
                        }
                    },
                    function (requestError, previewError) {
                        if (requestError) {
                            if (window.console) {
                                console.log(requestError);
                            }

                            $scope.hasError = true;
                            $scope.errorMessage = requestError.Message;
                            alert(requestError.Message);
                        }
                        if (previewError) {
                            if (window.console) {
                                console.log(previewError);
                            }

                            $scope.hasError = true;
                            $scope.errorMessage = previewError;
                            alert(previewError);
                        }
                    },
                    function (progressData) {
                        if (window.console) {
                            console.log(progressData);
                        }

                        if (progressData.progress) {
                            $scope.progressMessage = 'Generating, progress: ' + (progressData.progress || 0) + '%';
                            _updateProcess(progressData.progress);
                        }

                        if (progressData.previewData) {
                            $scope.documentUrls = $scope.documentUrls || [];
                            $scope.pages = progressData.previewData || [];

                            $scope.pages.forEach(function (v) {
                                v.thumbnailUrl = commonApiHelper.getImageUrl(v.BlobId);
                                v.previewImageUrl = commonApiHelper.getImageUrl(v.BlobId);
                            });

                            previewReorderData.pages = $scope.pages;
                            angular.extend(previewReorderData.orignalPages, previewReorderData.pages);
                            previewReorderData.pagesInitialized = true;
                            progressData.previewData
                                .sort(function (a, b) {
                                    return a.OrignalIndex - b.OrignalIndex;
                                })
                                .forEach(function (item) {
                                    var url = 'https://' + seismic.Tenant + '.seismic.com/Resource/Image.ashx?'
                                        + 'tenant=' + seismic.Tenant
                                        + '&user=' + seismic.UserName
                                        + '&client=' + encodeURIComponent(seismic.pageInfo.PackageFullName)
                                        + '&imageid=' + item.BlobId;

                                    if ($scope.documentUrls.indexOf(url) > -1) {
                                        return;
                                    }

                                    $scope.documentUrls.push(url);

                                    _addSlide({
                                        id: item.OrignalIndex,
                                        image: url,
                                        thumb: url,
                                        title: ''
                                    });
                                });
                        }
                    });

                function _isDirty(oldArray, newArray) {
                    oldArray = oldArray || [];
                    newArray = newArray || [];
                    var _isDirty = false;

                    if (oldArray.length != newArray.length) {
                        _isDirty = true;
                    } else {
                        for (var i = 0; i < oldArray.length; i++) {
                            if (oldArray[i].UniqeId != newArray[i].UniqeId) {
                                _isDirty = true;
                                break;
                            }
                        }
                    }

                    return _isDirty;
                }
        })
        .controller('SeismicDocViewerPreviewReorderController', function($scope, $rootScope, $location, $q, $filter, $timeout, $interval, $routeParams, params, $sce, seismicSObjectCache, seismicDocumentDetailCache, currentSObject, currentDocument, currentOutput, seismic, seismicInit, distribution, sideBarStatus, SeismicDocViewer_DeliveryOptionList_include_html, SeismicDeliverOptionIcon, previewReorderData, modalService){
            currentDocument.IsLiveDoc = true;
            
            $scope.params = params;
            angular.extend($scope.params, $routeParams);
            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            $scope.currentOutput = currentOutput;
            $scope.distribution = distribution;
            $scope.sideBarStatus = sideBarStatus;

            $scope.editHistory = previewReorderData.stack;

            $scope.requestId = params.requestId;
            $scope.canRemove = false;
            $scope.canMoveToPrev = false;
            $scope.canMoveToNext = false;
            $scope.canUndo = false;
            $scope.canRedo = false;

            $scope.moveToPrev = _moveToPrev;
            $scope.moveToNext = _moveToNext;
            $scope.remove = _remove;
            $scope.undo = _undo;
            $scope.redo = _redo;
            $scope.reset = _reset;
            $scope.selectPage = _selectPage;
            $scope.cancel = _cancel;
            $scope.save = _save;

			$scope.iconUndo = SeismicIcon.Reorder.UNDO;
			$scope.iconRedo = SeismicIcon.Reorder.REDO;
			$scope.iconReset = SeismicIcon.Reorder.RESET;
			$scope.iconCancel = SeismicIcon.Reorder.CANCEL;
			$scope.iconFinish = SeismicIcon.Reorder.FINISH;
			$scope.iconDelete = SeismicIcon.Reorder.DELETE;

            var EditCommand = null;

            var _initPagesForCancel = null;
            seismicInit.init($routeParams)
                .then(function() {
                    $rootScope.isReady = true;
                    return _initializeSObject(seismic, $scope, $q, $timeout, seismicSObjectCache);
                })
                .then(function() {
                    $rootScope.isSiderbarReady = true;
                    return _initializeDocument(seismic, $scope, $q, $timeout, seismicDocumentDetailCache);
                })
                .then(function(currentDocument) {
                    $scope.currentForm = _getFormFromDoc($scope);
                    return _getDirectRequestForm($scope, seismic, $q, currentDocument, $scope.currentForm, $timeout);
                })
                .then(function(data) {
                    if(previewReorderData.pagesInitialized) {
                        return previewReorderData;
                    }
                    // return _checkPreviewResult($q, seismic, $scope.params.requestId, $interval);
                })
                .then(function() {
                    $scope.pages = previewReorderData.pages;

                    if($scope.pages) {
                        $scope.pages.activePage = $scope.pages[0];
                    }

                    _initialize();
                });
                
            function _canMoveToPrev(index) {
                return index > 0;
            };

            function _canMoveToNext(index) {
                return index > -1 && index < $scope.pages.length - 1;
            };

            function _canUndo() {
                return $scope.editHistory.canUndo();
            };

            function _canRedo() {
                return $scope.editHistory.canRedo();
            };

            function _moveToPrev() {
                if (!$scope.canMoveToPrev) return;

                var index = _getIndex();
                var oldValue = angular.copy($scope.pages);
                var item = $scope.pages[index];
                $scope.pages.splice(index, 1);
                $scope.pages.splice(index - 1, 0, item);
                $scope.editHistory.execute(new EditCommand($scope, oldValue, $scope.pages));

                _refreshStatus();
            };

            function _moveToNext() {
                if (!$scope.canMoveToNext) return;

                var index = _getIndex();
                var oldValue = angular.copy($scope.pages);
                var item = $scope.pages[index];
                $scope.pages.splice(index, 1);
                $scope.pages.splice(index + 1, 0, item);
                $scope.editHistory.execute(new EditCommand($scope, oldValue, $scope.pages));

                _refreshStatus();
            };

            function _remove(index) {
                if (!$scope.canRemove) return;

                var index = _getIndex();
                var oldValue = angular.copy($scope.pages);
                $scope.pages.splice(index, 1);
                $scope.editHistory.execute(new EditCommand($scope, oldValue, $scope.pages));

                $scope.pages.activePage = $scope.pages[index] || $scope.pages[index - 1];

                _refreshStatus();
            };

            function _undo() {
                if (!$scope.canUndo) return;
                $scope.editHistory.undo();

                _refreshStatus();
            };

            function _redo() {
                if (!$scope.canRedo) return;
                $scope.editHistory.redo();

                _refreshStatus();
            };

            /**
             * Need to clear all commond history when reset
             */
            function _reset() {
                modalService
                    .confirm('Do you want to reset all the pages?', 'Reset', 'Discard')
                    .then(function (value) {
                        __reset();
                    });
            };

            function __reset() {
                $scope.pages.length = 0;
                angular.extend($scope.pages, previewReorderData.orignalPages);

                $scope.pages.activePage = $scope.pages.activePage || $scope.pages[0];

                // clear all commond history
                $scope.editHistory.stackPosition = -1;
                $scope.editHistory.commands.length = 0;
                _refreshStatus();
            }

            function _selectPage(page) {
                $scope.pages.activePage = page;

                _refreshStatus();
            };

            function _save() {
                __onSave();
            };

            /**
             * No need to change the commond history when save
             */
            function __onSave() {
                var isDirty = _isDirty();
                $scope.editHistory.save();

                if ($scope.pages.length == 0) {
                    $scope.pages.activePage = null;

                    modalService
                        .alert('File can not be empty');
                } else {
                    _redirectToGeneratedPageDirectly($scope, seismic, $scope.requestId, $rootScope, $location, "saved");
                }
            }

            function _isDirty() {
                return $scope.editHistory.dirty();
            }

            /**
             * No need to remove the commond history changes of this time when cancel
             */
            function _cancel() {
                if ($scope.editHistory.stackPosition > $scope.editHistory.savePosition) {
                    $scope.editHistory.commands.splice($scope.editHistory.savePosition);
                    $scope.editHistory.stackPosition = $scope.editHistory.savePosition;
                } else if ($scope.editHistory.stackPosition < $scope.editHistory.savePosition) {
                    $scope.editHistory.stackPosition = $scope.editHistory.savePosition;
                }

                $scope.pages.length = 0;
                angular.extend($scope.pages, _initPagesForCancel);
                _refreshStatus();

                _redirectToGeneratedPageDirectly($scope, seismic, $scope.requestId, $rootScope, $location, "canceled");
            };

            function _initialize() {
                EditCommand = Undo.Command.extend({
                    constructor: function ($scope, oldValue, newValue) {
                        this.oldValue = angular.copy(oldValue);
                        this.newValue = angular.copy(newValue);
                    },
                    execute: function () {
                    },
                    undo: function () {
                        $scope.pages.length = 0;
                        angular.extend($scope.pages, this.oldValue);
                    },

                    redo: function () {
                        $scope.pages.length = 0;
                        angular.extend($scope.pages, this.newValue);
                    }
                });

                _initPagesForCancel = angular.copy($scope.pages);
                _refreshStatus();
            };

            function _getIndex() {
                if (!$scope.pages.activePage || !$scope.pages || $scope.pages.length == 0) {
                    return -1;
                }

                var _fnFind = $filter('filter');
                var found = _fnFind($scope.pages, function (p) {
                    return $scope.pages.activePage.UniqeId == p.UniqeId;
                });

                return found && found.length > 0 ? $scope.pages.indexOf(found[0]) : -1;
            }

            function _refreshStatus() {
                var index = _getIndex();

                $scope.canRemove = !!$scope.pages.activePage;
                $scope.canMoveToPrev = $scope.pages.activePage && _canMoveToPrev(index);
                $scope.canMoveToNext = $scope.pages.activePage && _canMoveToNext(index);
                $scope.canUndo = _canUndo();
                $scope.canRedo = _canRedo();
            }
        })
        .controller("SeismicDocViewerDeliveryEmailController", function($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, currentOutput, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', {$scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons}); 
            $scope.currentDocument = currentDocument;
            $scope.isEmailFormReady = false;
			
			var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;

            requestIdPromise.promise.then(function (requestId) {
                $scope.email = {
                    RequestId: requestId,
                    DeliveryOptionId: deliveryOptionId,
                    profileVersionId: seismic.profileInfo.ProfileVersionId,
                    Body: '',
                    RequestFormat: currentOutput.DeliveryFormat,
                    SendTo: '',
                    SendCC: '',
                    SendBCC: '',
                    salesforceObjectId: seismic.pageInfo.objectId,
                    salesforceObjectType: seismic.pageInfo.objectType,
                    salesforceObjectName: seismic.pageInfo.objectName
                };

                $scope.isEmailFormReady = true;
            });

            $scope.isSendingEmail = false;

            $scope.sendToAppender = function (appended) {
                $scope.email.SendTo += appended;
            };

            $scope.sendCCAppender = function (appended) {
                $scope.email.SendCC += appended;
            };

            $scope.sendBCCAppender = function (appended) {
                $scope.email.SendBCC += appended;
            };

            $scope.sendEmail = function() {
                $scope.isSendingEmail = true;
                seismic.sendEmail($scope.email)
                    .then(function () {
                        $scope.isSendingEmail = false;
                        
                        var addSfActivityHistoryParams = {
			            type: 'email',
			            currentDocument: currentDocument,
			            objectId: currentSObject.objectId.substring(0, 15),
			            email: $scope.email.SendTo,
			        	};
			        	
                        seismic.AddSfActivityHistory(addSfActivityHistoryParams);
	                    
                        $modalInstance.close();

                        $rootScope.$emit("toaster", {
                            type: 'success',
                            title: 'Send Email',
                            body: 'Send email success!'
                        });
                    });
            };
        })
        .controller("SeismicDocViewerDeliveryCustomDeliveryFormController", function ($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.currentDocument = currentDocument;
            $scope.deliveryFormReady = false;

            var deliveryOptionType = deliveryOption.Type;
            var deliveryOptionId = deliveryOption.DeliveryOptionId;
            
            requestIdPromise.promise.then(function (requestId) {
                $scope.deliveryFormUrl = $sce.trustAsResourceUrl(_buildDeliveryFormUrl(seismic, $scope.currentDocument, deliveryOptionId, requestId));
            });

            $scope.$on("$destroy", function () {
                window.removeEventListener("message", _commonDeliveryFormHandler);
            });

            window.addEventListener("message", _commonDeliveryFormHandler);
			
            var addSfActivityHistoryParams = {
	            type: 'field',
	            currentDocument: currentDocument,
	            objectId: currentSObject.objectId.substring(0, 15),
	            deliveryOptionName: deliveryOption.Name
	        };
	        
            function _commonDeliveryFormHandler(e) {
                __commonDeliveryFormReadyHandler(e, seismic, $rootScope, $scope, function () {
                    $scope.deliveryFormReady = true;
                    $scope.$digest();
                });

                __commonDeliveryFormCancelHandler(e, seismic, $rootScope, $scope, function () {
                    $modalInstance.close();
                });

                __commonDeliveryFormFinishHandler(e, seismic, $rootScope, $scope, function () {
	        		seismic.AddSfActivityHistory(addSfActivityHistoryParams);
                    $modalInstance.close();
                });
            }
        })
        .controller("SeismicDocViewerDeliveryLiveSendController", function ($scope, $controller, $rootScope, $location, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            $scope.livesendPageReady = false;
            
			var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;

            requestIdPromise.promise.then(function (requestId) {
                $scope.livesendPageUrl = $sce.trustAsResourceUrl(_buildLiveSendUrl(seismic, $scope.currentDocument, requestId));
            });

            $scope.$on("$destroy", function () {
                window.removeEventListener("message", _livesendHandler);
            });

            window.addEventListener("message", _livesendHandler);
		        	
            function _livesendHandler(e) {
                __livesendReadyHandler(e, seismic, $rootScope, $scope, function () {
                    $scope.livesendPageReady = true;
                    $scope.$digest();
                });

                __livesendFinishHandler(e, seismic, $rootScope, $scope, function () {
                    $modalInstance.close();
                });
            }
        })
        .controller("SeismicDocViewerDeliveryCreateSharedLinkController", function ($scope, $controller, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.modalHeader = 'Shared Link';
            $scope.currentDocument = currentDocument;
            $scope.currentSObject = currentSObject;
            
            $scope.isSharedLinkReady = false;
            
            var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;
			    	
            requestIdPromise.promise.then(function(requestId) {
                seismic
                    .deliver(deliveryOptionId, requestId, [])
                    .then(
                        function(deliveryResult){
                            if ($scope.currentDocument.SharedLinkUrl) {
                                $scope.linkUrl = $scope.currentDocument.SharedLinkUrl;
                                $scope.isSharedLinkReady = true;
            
					            var search = _getUrlSearcher()
					            var addSfActivityHistoryParams = {
						            type: 'sharedlink',
						            currentDocument: $scope.currentDocument,
						            objectId: search.sid.substring(0, 15)
						        	};
                                
                        		seismic.AddSfActivityHistory(addSfActivityHistoryParams);
                            } else {
                                seismic.createSharedLink($scope.currentDocument.BasicInfo.DocumentId).then(function (sharedlink) {
                                    if (sharedlink) {
                                        var linkId = sharedlink;
                                        $scope.linkUrl = "https://" + pageInfo.seismicTenant + ".seismic.com/c/" + linkId;
                                        $scope.isSharedLinkReady = true;
            
							            var search = _getUrlSearcher()
							            var addSfActivityHistoryParams = {
								            type: 'sharedlink',
								            currentDocument: $scope.currentDocument,
								            objectId: search.sid.substring(0, 15)
								        	};
                                
                        				seismic.AddSfActivityHistory(addSfActivityHistoryParams);
                                    }
                                });
                            }
                        },
                        function(error){
                            $scope.isSharedLinkReady = true;
                            alert('Create shared link failed!');
                        },
                        function(progressData){

                        });
            });
        })
        .controller("SeismicDocViewerDeliveryAdd2PersonalSpaceController", function ($scope, $controller, $rootScope, $location, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.currentDocument = currentDocument;
            $scope.distribution = distribution;
            $scope.persoanlSpacePageReady = false;

			var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;
			
            requestIdPromise.promise.then(function (requestId) {
                $scope.add2persoanlspacePageUrl = $sce.trustAsResourceUrl(_buildAdd2PersonalSpace(seismic, $scope.currentDocument, requestId));

                $scope.$on("$destroy", function () {
                    window.removeEventListener("message", _add2personalspaceHandler);
                });

                window.addEventListener("message", _add2personalspaceHandler);

                function _add2personalspaceHandler(e) {
                    __add2personalspaceReadyHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, function () {
                        $scope.persoanlSpacePageReady = true;
                        $scope.$digest();
                    });

                    __add2personalspaceCancelHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, function () {
                        $modalInstance.close();
                    });

                    __add2personalspaceFinishHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, function () {
                    
	                    var search = _getUrlSearcher()
			            var addSfActivityHistoryParams = {
				            type: 'addtospace',
				            currentDocument: $scope.currentDocument,
				            objectId: search.sid.substring(0, 15)
				        	};
						seismic.AddSfActivityHistory(addSfActivityHistoryParams);
                        				
                        $modalInstance.close();
                    });
                }
            });
        })
        .controller("SeismicDocViewerDeliverySFPostToChatterController", function ($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, currentOutput, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.currentObjectId = seismic.pageInfo.objectId;
            $scope.currentObjectType = seismic.pageInfo.objectType;
            $scope.currentObjectName = seismic.pageInfo.objectName;
            $scope.currentOutput = currentOutput;
            $scope.chatterGroups = [];
            $scope.postChatter = {};
            $scope.postChatter.To = '';
            $scope.postChatter.WithType = 'Link';
            $scope.postChatter.Body = '';
            $scope.postChatter.LinkName = currentDocument.BasicInfo.Name;
            $scope.postChatter.SalesforceBaseAddress = seismic.pageInfo.sfBaseUrl;
            $scope.postChatter.SalesforceSessionId = seismic.pageInfo.sfSessionId;
            
            var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;

            $scope.isPosting = true;
            requestIdPromise.promise.then(function (requestId) {
                seismic.GetChatterGroups().then(function (result) {
                    $scope.isPosting = false;
                    if (Array.isArray(result)) {
                        result.forEach(
                            function (v, k) {
                                if (window.console) {
                                    console.log(v, k);
                                }
                                $scope.chatterGroups.push(v);
                            });
                    } else {
                        alert("Chatter has not enabled in your Salesforce organization configuration.");
                        $modalInstance.close();
                    }
                })
				.then(function () {
				    $scope.postOut = function () {
				        $scope.isPosting = true;
				        var postChatter = $scope.postChatter;
				        var deliveryData = [
							{ "Name": "Channel", "Value": postChatter.To },
							{ "Name": "IsPostFile", "Value": postChatter.WithType == "File" },
							{ "Name": "Message", "Value": postChatter.Body },
							{ "Name": "Format", "Value": $scope.currentOutput.DeliveryFormat },
							{ "Name": "SFBaseAddress", "Value": postChatter.SalesforceBaseAddress },
							{ "Name": "SFSessionId", "Value": postChatter.SalesforceSessionId }
				        ];

				        if (postChatter.WithType == "Link") {
				            deliveryData.push({ "Name": "LinkName", "Value": postChatter.LinkName });
				        }
				        
				        var addSfActivityHistoryParams = {
			            type: 'chatter',
			            currentDocument: currentDocument,
			            objectId: currentSObject.objectId.substring(0, 15),
			        	};

				        seismic.deliver(deliveryOptionId, requestId, deliveryData, null, deliveryOptionType, addSfActivityHistoryParams)
	                    .then(
	                        function (deliveryResult) {
	                            $scope.isPosting = false;

	                            $rootScope.$emit("toaster", {
	                                type: 'success',
	                                title: 'Post To Chatter',
	                                body: 'Post to chatter group successfully!'
	                            });
	                            
	                            $modalInstance.close();
	                        },
	                        function (error) {
	                            $scope.isPosting = false;
	                            alert('Post to chatter group failed!');
	                        },
	                        function (progressData) {

	                        });
				    };
				});
            });
        })
        .controller("SeismicDocViewerDeliverySFSaveAttachmentController", function ($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, currentOutput, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.attachment = {};
            $scope.attachment.SalesforceBaseAddress = seismic.pageInfo.sfBaseUrl;
            $scope.attachment.SalesforceSessionId = seismic.pageInfo.sfSessionId;
            $scope.attachment.SalesforceObjectId = seismic.pageInfo.objectId;
            
            var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;

            $scope.isSaving = true;
            requestIdPromise.promise.then(function (requestId) {
                $scope.isSaving = false;
                $scope.save = function () {
                    $scope.isSaving = true;

                    var attachment = $scope.attachment;
                    var deliveryData = [
	                    { "Name": "SFBaseAddress", "Value": attachment.SalesforceBaseAddress },
	                    { "Name": "SFSessionId", "Value": attachment.SalesforceSessionId },
	                    { "Name": "SFObjectId", "Value": attachment.SalesforceObjectId }
                    ];
                    
			        var addSfActivityHistoryParams = {
		            type: 'attachment',
		            currentDocument: currentDocument,
		            objectId: currentSObject.objectId.substring(0, 15),
		        	};
			        
                    seismic.deliver(deliveryOptionId, requestId, deliveryData, null, deliveryOptionType, addSfActivityHistoryParams)
	                .then(
	                    function (deliveryResult) {
	                        $scope.isSaving = false;

	                        $rootScope.$emit("toaster", {
	                            type: 'success',
	                            title: 'Save As Attachment',
	                            body: 'Save as attachment success!'
	                        });
	                        
	                        var searcher = _getUrlSearcher();
	                        var islivedocValue = searcher.live;
	                        
	                        var contentFormat = FORMATS_TO_NAME[currentDocument.BasicInfo.Format].toLowerCase();
	                        var documentFileName = currentDocument.BasicInfo.Name + '.' + contentFormat;
	                        var contentName = getFileNameToDownload(documentFileName, contentFormat);
	                        
	                        $modalInstance.close();
	                    },
	                    function (error) {
	                        $scope.isSaving = false;
	                        alert('Save as attachment failed!');
	                    },
	                    function (progressData) {

	                    });
                };
            });
        })
        .controller("SeismicDocViewerDeliverySFCreateContentController", function ($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, SeismicIcons, currentSObject, currentDocument, currentOutput, seismic, distribution, deliveryOption, requestIdPromise) {
            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.content = {};
            $scope.content.Format = FORMATS_TO_NAME[currentDocument.BasicInfo.Format];
            $scope.content.SalesforceBaseAddress = seismic.pageInfo.sfBaseUrl;
            $scope.content.SalesforceSessionId = seismic.pageInfo.sfSessionId;
            
            var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;

            $scope.isCreating = true;
            requestIdPromise.promise.then(function (requestId) {
                $scope.isCreating = false;
                $scope.createContent = function () {
                    $scope.isCreating = true;

                    var content = $scope.content;
                    var deliveryData = [
	                    { "Name": "Format", "Value": content.Format },
	                    { "Name": "SFBaseAddress", "Value": content.SalesforceBaseAddress },
	                    { "Name": "SFSessionId", "Value": content.SalesforceSessionId }
                    ];

					var addSfActivityHistoryParams = {
			            type: 'createContent',
			            currentDocument: currentDocument,
			            objectId: currentSObject.objectId.substring(0, 15),
			         };
			        	
                    seismic.deliver(deliveryOptionId, requestId, deliveryData, null, deliveryOptionType, addSfActivityHistoryParams)
	                .then(
	                    function (deliveryResult) {
	                        $scope.isCreating = false;

	                        $rootScope.$emit("toaster", {
	                            type: 'success',
	                            title: 'Create Content',
	                            body: 'Create content success!'
	                        });
	                        
	                        $modalInstance.close();
	                    },
	                    function (error) {
	                        $scope.isCreating = false;
	                        alert('Create content failed!');
	                    },
	                    function (progressData) {
	                    });
                };
            });
        })
        .controller("SeismicDocViewerDeliverySFCreateContentDeliveryController", function ($scope, $rootScope, $location, $controller, $sce, $modalInstance, $timeout, $filter, SeismicIcons, currentSObject, currentDocument, currentOutput, seismic, distribution, deliveryOption, requestIdPromise) {
            var deliveryOptionType = deliveryOption.Type;
			var deliveryOptionId = deliveryOption.DeliveryOptionId;
			
            var _now = new Date();
            var _format = FORMATS_TO_NAME[currentDocument.BasicInfo.Format];
            function _canShowDeliveryMethod() {
                var formats = ['ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx', 'pdf'];
                for (var i = 0, count = formats.length; i < count; i++) {
                    if (_format.toLowerCase() == formats[i].toLowerCase()) {
                        return true;
                    }
                }
                return false;
            }

            $controller('SeismicDialog', { $scope: $scope, $modalInstance: $modalInstance, SeismicIcons: SeismicIcons });
            $scope.extentionName = _format;
            $scope.isDeliveryMethodVisible = _canShowDeliveryMethod();
            $scope.isDownloadPDFVisible = ($scope.extentionName.toLowerCase() != 'pdf');
            $scope.currentSObjectName = seismic.pageInfo.objectName;
            $scope.expiryDatepickerMinDate = _now;
            $scope.expiryDatepickerMaxDate = new Date(_now.getTime() + 90 * 24 * 60 * 60 * 1000);
            $scope.expiryDatepickerOptions = { formatYear: 'yy', startingDay: 1 };
            $scope.isExpiryDatepickerOpened = false;
            $scope.showRelatedObject = (!!currentSObject);
            $scope.isRelatedRecordIdChecked = $scope.showRelatedObject;
            $scope.contentDelivery = {};
            $scope.contentDelivery.Name = currentDocument.BasicInfo.Name;
            $scope.contentDelivery.OwnerId = seismic.pageInfo.sfUserId;
            $scope.contentDelivery.PreferencesAllowOriginalDownload = true;
            $scope.contentDelivery.PreferencesAllowPDFDownload = true;
            $scope.contentDelivery.PreferencesAllowViewInBrowser = true;
            $scope.contentDelivery.PreferencesExpires = true;
            $scope.contentDelivery.PreferencesLinkLatestVersion = true;
            $scope.contentDelivery.PreferencesNotifyOnVisit = true;
            $scope.contentDelivery.PreferencesNotifyRndtnComplete = false;
            $scope.contentDelivery.PreferencesPasswordRequired = false;
            $scope.contentDelivery.RelatedRecordId = currentSObject.objectId.substring(0, 15);
            $scope.contentDelivery.ExpiryDate = $filter('date')(_now, 'MM/dd/yyyy HH:mm:ss');
            $scope.contentDelivery.Format = _format;
            $scope.contentDelivery.SalesforceBaseAddress = seismic.pageInfo.sfBaseUrl;
            $scope.contentDelivery.SalesforceSessionId = seismic.pageInfo.sfSessionId;

            $scope.openExpiryDatepicker = function ($event) {
                $event.preventDefault();
                $event.stopPropagation();

                if ($scope.contentDelivery.PreferencesExpires) {
                    $scope.isExpiryDatepickerOpened = true;
                }
            };

            $scope.isCreating = true;
            requestIdPromise.promise.then(function (requestId) {
                $scope.isCreating = false;

                $scope.createContentDelivery = function () {
                    $scope.isCreating = true;

                    var contentDelivery = $scope.contentDelivery;
                    var deliveryData = [
	                    { "Name": "Name", "Value": contentDelivery.Name },
	                    { "Name": "OwnerId", "Value": contentDelivery.OwnerId },
	                    { "Name": "PreferencesAllowOriginalDownload", "Value": contentDelivery.PreferencesAllowOriginalDownload },
	                    { "Name": "PreferencesAllowPDFDownload", "Value": contentDelivery.PreferencesAllowPDFDownload },
	                    { "Name": "PreferencesAllowViewInBrowser", "Value": contentDelivery.PreferencesAllowViewInBrowser },
	                    { "Name": "PreferencesExpires", "Value": contentDelivery.PreferencesExpires },
	                    { "Name": "PreferencesLinkLatestVersion", "Value": contentDelivery.PreferencesLinkLatestVersion },
	                    { "Name": "PreferencesNotifyOnVisit", "Value": contentDelivery.PreferencesNotifyOnVisit },
	                    { "Name": "PreferencesNotifyRndtnComplete", "Value": contentDelivery.PreferencesNotifyRndtnComplete },
	                    { "Name": "PreferencesPasswordRequired", "Value": contentDelivery.PreferencesPasswordRequired },
	                    { "Name": "RelatedRecordId", "Value": $scope.isRelatedRecordIdChecked ? contentDelivery.RelatedRecordId : null },
	                    { "Name": "ExpiryDate", "Value": contentDelivery.ExpiryDate },
	                    { "Name": "Format", "Value": contentDelivery.Format },
	                    { "Name": "SFBaseAddress", "Value": contentDelivery.SalesforceBaseAddress },
	                    { "Name": "SFSessionId", "Value": contentDelivery.SalesforceSessionId }
                    ];

					var addSfActivityHistoryParams = {
			            type: 'createContentDelivery',
			            currentDocument: currentDocument,
			            objectId: currentSObject.objectId.substring(0, 15),
			        	};
			        	
                    seismic.deliver(deliveryOptionId, requestId, deliveryData, null, deliveryOptionType, addSfActivityHistoryParams)
	                .then(
	                    function (deliveryResult) {
	                        $scope.isCreating = false;

	                        $rootScope.$emit("toaster", {
	                            type: 'success',
	                            title: 'Create Content',
	                            body: 'Create content success!'
	                        });
	                        
	                        $modalInstance.close();
	                    },
	                    function (error) {
	                        $scope.isCreating = false;
	                        alert('Create content failed!');
	                    },
	                    function (progressData) {
	                    });
                };
            });
        })
    	.controller("SeismicDialog", function ($scope, $modalInstance, SeismicIcons) {
    	    $scope.okBtnVisible = false;
    	    $scope.cancelBtnVisible = false;

    	    $scope.closeIconUrl = SeismicIcons.closeIcon;

    	    $scope.dialogOk = function () {
    	        $modalInstance.close();
    	    };

    	    $scope.dialogCancel = function () {
    	        $modalInstance.dismiss('cancel');
    	    };

    	    $scope.dialogClose = function () {
    	        $modalInstance.dismiss('cancel');
    	    };
    	})
        .directive('seismicBusy', function () {
            return {
                restrict: 'E',
                transclude: true,
                scope: {
                    isBusy: "=",
                    busyMessage: "=",
                    wrapperClass: "=",
                    visibleMode: "=" // true: hide when busy, false: visible but set it out of window when busy
                },
                templateUrl: 'SeismicBusy.html'
            };
        })
        .config(function ($routeProvider, $locationProvider) {
            var search = _getUrlSearcher();
            var hash = '';
            if (window.location.search && window.location.search.length > 1) {
                if (window.location.hash || window.location.hash.length < 1) {
                    if (window.console) {
                        console.log(search.fromUrl);
                    }
                    hash += "/" + (search.live == "1" ? "LiveDoc" : "Static");
                    hash += "/" + search.stype;
                    hash += "/" + search.sid;
                    hash += "/" + search.pid;
                    hash += "/" + search.pvid;
                    hash += "/" + search.cvid;
                    //window.location.hash = hash;
                } else {
                    hash = '/error';
                }
            }

            var _prepare = {templates: _templateLoaderFactory};
            
            $routeProvider
            	/*
                .when(undefined, {
                    templateUrl: function () { debugger; return search.live == "1" ? SeismicDocViewer_LiveDoc_html : SeismicDocViewer_Static_html; },
                    controller: function () { debugger; return search.live == "1" ? 'SeismicDocViewerLiveDocController' : 'SeismicDocViewerStaticController'; }
                })
                */
                .when('/Static/:objectType/:objectId/:profileId/:profileVersionId/:documentVersionId', {
                    templateUrl: SeismicDocViewer_Static_html,
                    controller: 'SeismicDocViewerStaticController',
                    resolve: _prepare
                })
                .when('/LiveDoc/:objectType/:objectId/:profileId/:profileVersionId/:documentVersionId', {
                    templateUrl: SeismicDocViewer_LiveDoc_html,
                    controller: 'SeismicDocViewerLiveDocController',
                    resolve: _prepare
                })
                .when('/LiveForm/:objectType/:objectId/:profileId/:profileVersionId/:documentVersionId/:formVersionId', {
                    templateUrl: SeismicDocViewer_LiveForm_html,
                    controller: 'SeismicDocViewerLiveFormController',
                    resolve: _prepare
                })
                .when('/Generated/:renderType/:objectType/:objectId/:profileId/:profileVersionId/:documentVersionId/:formVersionId/:requestId', {
                    templateUrl: SeismicDocViewer_Generated_html,
                    controller: 'SeismicDocViewerGeneratedController',
                    resolve: _prepare
                })
                .when('/PreviewReorder/:objectType/:objectId/:profileId/:profileVersionId/:documentVersionId/:formVersionId/:requestId', {
                    templateUrl: SeismicDocViewer_PreviewReorder_html,
                    controller: 'SeismicDocViewerPreviewReorderController',
                    resolve: _prepare
                })
                .otherwise(hash);
        })
        .run(function (distribution, $location, $modal) {

            if (isInSFOneApp()) {
                //alert('This is running inside Salesforce1 application.');
                $('body').css({ 'padding-top': '10px' });
            }

            distribution.openDeliveryOption = function (deliveryOption, requestIdPromise) {
                var dialog = $modal.open({
                    animation: true,
                    // windowTemplateUrl : SeismicDocViewer_DeliveryOptionDialog_html,
                    templateUrl: SeismicDocViewer_DeliveryOption_htmlTemplates_map[deliveryOption.Type],
                    controller: DeliveryOptionControllerMap[deliveryOption.Type],
                    size: "lg",
                    resolve: {
                        deliveryOption: function () {
                            return deliveryOption;
                        },
                        deliveryOptionType: function () {
                            return deliveryOption.Type;
                        },
                        deliveryOptionId: function () {
                            return deliveryOption.DeliveryOptionId;
                        },
                        requestIdPromise: function () {
                            // I have to wrap requestIdPromise
                            // otherwise, it will be waiting for resolving it before showing dialog
                            return { promise: requestIdPromise };
                        }
                    }
                });
            };
        });
    
    function _getUrlSearcher() {
        var search = {};
        if (window.location.search && window.location.search.length > 1) {
            window.location.search.substring(1).split('&').forEach(function (value, index) {
                var keyValuePair = value.split('=');
                if (keyValuePair && keyValuePair.length > 0) {
                    search[keyValuePair[0]] = keyValuePair[1] ? keyValuePair[1] : '';
                }
            });
        }
        return search;
    }

    function _templateLoaderFactory ($q, $templateCache) {
        var templates = [];
        for(var i in HtmlFilesInJson) {
            var url = "https://" + pageInfo.seismicTenant + ".seismic.com/h5/apps/sfdcinline/dist/" + i + "?v=" + HtmlFilesInJson[i];

            var deferred = $q.defer();
            sforce.connection.remoteFunction({
                url: url,
                requestHeaders:{
                    Authorization: 'Bearer '+ __sfdcSessionId,
                    Accept: "application/json, */*"
                },
                onSuccess: function (data){
                    deferred.resolve(data);
                },
                onFailure: function (error) {
                    deferred.reject(error);
                }
            });

            templates.push(deferred.promise);
        }

        return $q.all(templates)
            .then(function(htmls) {
                // $(document.body).append($("<div>").hide().append(htmls));
                if (window.console) {
                    console.log($templateCache);
                }
                for(var i = 0; i < htmls.length; i++) {
                    $(htmls[i]).each(function(k, v) {
                        $templateCache.put($(v).attr("id"), $(v).html());
                    });
                }
            });
    }

    function _initializeSObject (seismic, $scope, $q, $timeout, seismicSObjectCache) {
        var deferred = $q.defer();
        
        var search = _getUrlSearcher();
        seismic.pageInfo.objectId = $scope.params.objectId;
        seismic.pageInfo.objectType = $scope.params.objectType;

        var key = $scope.params.objectId;
        var value = seismicSObjectCache[key];
        if (!$scope.currentSObject.__initialized) {
            if (value && value.Name) {
                $timeout(function () {
                    _callback(value.Name);
                });
                _serviceCall();
            } else {
                _serviceCall(
                	function (obj) {
                	    _callback(obj.Name);
                	});
            }
        } else {
            $timeout(function () {
                deferred.resolve();
            });
        }

        return deferred.promise;

        function _callback(objectName) {
            seismic.pageInfo.objectName = objectName;
            
            (function () {
                var objectUrl = "/" + $scope.params.objectId;
                var fromUrl = search.fromUrl ? decodeURIComponent(search.fromUrl) : '';
                var cartUrl = null;
                
                if (fromUrl) {
                    var doesSupportCart = fromUrl.indexOf('btnName=') > 0 || fromUrl.indexOf('sfdc.tabName=') > 0;
                    if (fromUrl.indexOf('&open_cart=1') > 0) {
                        cartUrl = fromUrl;
                        fromUrl = fromUrl.replace('&open_cart=1', '');
                    } else if (fromUrl.indexOf('&open_cart=0') > 0) {
                        cartUrl = fromUrl.replace('&open_cart=0', '&open_cart=1');
                        fromUrl = fromUrl.replace('&open_cart=0', '');
                    } else {
                        cartUrl = fromUrl + '&open_cart=1';
                    }
                    
                    if (!doesSupportCart) {
                        cartUrl = null;
                    }
                }
                
                if ($scope.params.objectType == 'tab') {
                    objectName = decodeURIComponent(search.sname);
                    // Use fromUrl to instead of salesforce object detail page 
                    objectUrl = fromUrl;
                    // Don't show 'Back to Content List' hyperlink for tab requester
                    fromUrl = null;
                }
                
                angular.extend($scope.currentSObject, {
                    objectType: $scope.params.objectType,
                    objectId: $scope.params.objectId,
                    fromUrl: fromUrl,
                    objectUrl: objectUrl,
                    objectName: objectName
                });
                
                angular.extend($scope.params, {
                    fullPathId: decodeURIComponent(search.fpid),
                    fullPathName: decodeURIComponent(search.fpname),
                    fromUrl: search.fromUrl,
                	cartUrl: cartUrl,
                	cartItemCount: 0
                });
                
                $scope.currentSObject.__initialized = true;
            })();

            deferred.resolve();
        }

        function _serviceCall(callback) {
            if (/^tab$/i.test($scope.params.objectType)) {
                if (callback) {
                    callback({ Name: decodeURIComponent(search.sname) });
                }
            } else {
                seismic.getSObjectName(function(result){
                	var obj = result;
                    
                    // Save to cache
                    seismicSObjectCache[key] = { Name: obj.Name };
                    	
                    $timeout(function() {
                    	if (callback) {
                        	callback(obj);
                        }
                    });
                });
            }
        }
    };

    function _getFormFromDoc($scope) {
        var forms = $scope.currentDocument.FormApps;
        if (forms) {
            for (var i = 0; i < forms.length; i++) {
                var form = forms[i];

                if (form.VersionId == $scope.params.formVersionId) {
                    return form;
                }
            }
        }

        return null;
    };

    function _buildFormUrl($scope, seismic, form) {
        return "/LiveForm/" + $scope.currentSObject.objectType
                             + "/" + $scope.currentSObject.objectId
                             + "/" + seismic.profileInfo.ProfileId
                             + "/" + seismic.profileInfo.ProfileVersionId
                             + "/" + $scope.currentDocument.BasicInfo.VersionId
                             + "/" + form.VersionId;
    }

    function _buildPreviewReorderUrl($scope, seismic, requestId) {
        return "/PreviewReorder/" + $scope.currentSObject.objectType
                             + "/" + $scope.currentSObject.objectId
                             + "/" + seismic.profileInfo.ProfileId
                             + "/" + seismic.profileInfo.ProfileVersionId
                             + "/" + $scope.currentDocument.BasicInfo.VersionId
                             + "/" + $scope.currentForm.VersionId
                             + "/" + requestId;
    }

    function _buildGeneratedUrl ($scope, seismic, requestId, renderType) {
        return "/Generated/" 
                             + (renderType || "default")
                             + "/" + $scope.currentSObject.objectType
                             + "/" + $scope.currentSObject.objectId
                             + "/" + seismic.profileInfo.ProfileId
                             + "/" + seismic.profileInfo.ProfileVersionId
                             + "/" + $scope.currentDocument.BasicInfo.VersionId
                             + "/" + $scope.currentForm.VersionId
                             + "/" + requestId;
    }

    function _redirectToPreviewReorder ($scope, seismic, requestId, $rootScope, $location) {
        var hash = _buildPreviewReorderUrl($scope, seismic, requestId);
        $location.path(hash);
        $location.replace();
    }

    function _redirectToGeneratedPageDirectly ($scope, seismic, requestId, $rootScope, $location, renderType) {
        var hash = _buildGeneratedUrl($scope, seismic, requestId, renderType);
        $location.path(hash);
        $location.replace();
    }

    function _redirectToGeneratedPage ($scope, seismic, requestId, $rootScope, $location, renderType) {
        var hash = _buildGeneratedUrl($scope, seismic, requestId, renderType);
        $rootScope.$apply(function () {
            $location.path(hash);
        });
    }

    function __liveFormReadyHandler(e, seismic, $rootScope, $scope, $location) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com' && e.data == 'CommonLiveFormReady') {
            $rootScope.$apply(function () {
                $scope.isLiveFormReady = true;
            });
        }
    };

    function __checkRequestResultFromLiveForm(e, seismic, $rootScope, $scope, $location) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com' && /^CommonLiveFormFinished-/.test(e.data)) {
            var requestId = /^CommonLiveFormFinished-(.*)/.exec(e.data)[1];
            _redirectToGeneratedPage($scope, seismic, requestId, $rootScope, $location);
        }
    };

    function _getFormUrl(seismic, $scope) {
        var formVersionId = $scope.params.formVersionId;

        var url = 'https://' + seismic.Tenant + '.seismic.com/HTML5/CommonForm.aspx';
        url += '?clientType=' + encodeURIComponent(seismic.pageInfo.PackageFullName);
        url += '&baseUrl=' + encodeURIComponent(seismic.pageInfo.sfBaseUrl);
        url += '&orgId=' + seismic.pageInfo.sfOrgId;
        url += '&oId=' + seismic.pageInfo.objectId;
        url += '&oType=' + encodeURIComponent(seismic.pageInfo.objectType);
        url += '&oName=' + encodeURIComponent($.base64.encode(seismic.pageInfo.objectName));
        url += '&sId=' + encodeURIComponent(seismic.pageInfo.sfSessionId);
        url += '&rmToken=' + encodeURIComponent(seismic.pageInfo.rmToken);
        url += "&pid=" + encodeURIComponent(seismic.profileInfo.ProfileId);
        url += '&pvid=' + encodeURIComponent(seismic.profileInfo.ProfileVersionId);
        url += "&fpid=" + encodeURIComponent($scope.currentDocument.BasicInfo.DocCenterFullPath);
        url += "&fpname=" + encodeURIComponent($scope.currentDocument.BasicInfo.FullPath);
        url += "&docId=" + encodeURIComponent($scope.currentDocument.BasicInfo.DocumentId);
        url += '&formId=' + formVersionId;
        url += '&previewMode=true';
        url += '&spv=' + seismic.pageInfo.PackageVersion;
        return url;
    };

    function _getDirectRequestForm($scope, seismic, $q, doc, form, $timeout) {
        var deferred = $q.defer();
        
        function _callback(type, sfIndexField, availableOutputDefinitions) {
            if (form.DeliveryOptions && form.DeliveryOptions.length > 0) {
                var finalDeliveryOptions = [];
                $.each($scope.currentDocument.DeliveryOptions,
                    function (index, item) {
                        for (var i = 0, count = form.DeliveryOptions.length; i < count; i++) {
                            if (form.DeliveryOptions[i] == item.DeliveryOptionId) {
                                finalDeliveryOptions.push(item);
                            }
                        }
                    });
                var formDeliveryOptions = seismic.BuildDeliveryOptions(finalDeliveryOptions, doc);
                $scope.currentDeliveryOptions = formDeliveryOptions;
            }
        
            deferred.resolve({
                type: type,
                sfIndexField: sfIndexField,
                availableOutputDefinitions: availableOutputDefinitions
            });
        }

        if ($scope.currentForm.availableOutputDefinitions) {
            $timeout(function () {
                _callback($scope.currentForm.type, $scope.currentForm.sfIndexField, $scope.currentForm.availableOutputDefinitions);
            }, 1);
        } else {
            seismic.getDirectRequestForm(form.VersionId)
                .then(function (result) {
                    var outputs = [];
                    if (result.AvailableOutputDefinitions && result.AvailableOutputDefinitions.length > 0) {
                        for (var i = 0; i < result.AvailableOutputDefinitions.length; i++) {
                            var o = result.AvailableOutputDefinitions[i];
                            if (o.Visible) {
                                outputs.push(o);
                            }
                        }
                    }

                    _callback(result.DirectRequestFormType, result.SFIndexField, outputs);
                },
                function (error) {
                    if (window.console) {
                        console.log(error);
                    }
                    deferred.reject(error);
                });
        }

        return deferred.promise;
    };

    function _initializeDocument(seismic, $scope, $q, $timeout, $sce, seismicDocumentDetailCache) {
        var deferred = $q.defer();

        function _callback(result, doNotRefresh) {
            result.BasicInfo.Description = result.BasicInfo.Description.replace(/\r/g, '\r\n').replace(/\r\n\n/g, '\r\n');
            //result.BasicInfo.DescriptionHtml = $sce.trustAsHtml(result.BasicInfo.Description.replace(/\r\n/g, '<br />\r\n'));
            //result.DeliveryOptions = seismic.BuildDeliveryOptions(result.DeliveryOptions, result);
            if (!doNotRefresh) {
                result.BasicInfo.Rating = _mathRound(result.BasicInfo.Rating);
                angular.extend($scope.currentDocument, result);
            }

            var formatName = FORMATS_TO_NAME[$scope.currentDocument.BasicInfo.Format];
            $scope.currentDeliveryOptions = seismic.BuildDeliveryOptions(result.DeliveryOptions, result);
            $scope.currentDocument.__initialized = true;
            $scope.currentDocument.documentFormatIcon = _getIconThumbnail(formatName);
            $scope.currentOutput.DeliveryFormat = formatName;
            $scope.deliveryIconMoreSrc = SeismicDeliverOptionIcon.CDO_MORE;
            deferred.resolve($scope.currentDocument);
        }

        function _serviceCall(callback) {
            var documentVersionId = $scope.params.documentVersionId;
            var fullPathId = $scope.params.fullPathId;
            seismic.getDocumentDetail(documentVersionId, fullPathId)
                .then(function (result) {
                    $timeout(function () {
                        callback(result);
                    });
                },
                function (error) {
                    if (window.console) {
                        console.log(error);
                    }
                    deferred.reject(error);
                });
        }

        if (!pageInfo.seismicIsLogined) {
            $timeout(function () {
                deferred.reject({});
            });
        } else if (!$scope.currentDocument.__initialized) {
            var key = $scope.params.documentVersionId;
            var value = seismicDocumentDetailCache[key];
            if (value) {
                $timeout(function () {
                    _callback(value);
                });
            }
            _serviceCall(function (obj) {
                seismicDocumentDetailCache[key] = obj;
                _callback(obj);
            });
        } else {
            $timeout(function () {
                _callback($scope.currentDocument, true);
            });
        }
        return deferred.promise;
    };

    function _initializeDocumentThumbnails(seismic, currentDocument, $scope) {
        if (currentDocument.BasicInfo.ThumbnailBlobIds && currentDocument.BasicInfo.ThumbnailBlobIds.length > 0) {
            $scope.type = 'thumbnail';
            $scope.documentUrls = [];
            currentDocument.BasicInfo.ThumbnailBlobIds.forEach(function (id) {
                var url = 'https://' + seismic.Tenant + '.seismic.com/Resource/Image.ashx?'
                    + 'tenant=' + seismic.Tenant
                    + '&user=' + seismic.UserName
                    + '&client=' + encodeURIComponent(seismic.pageInfo.PackageFullName)
                    + '&imageid=' + id;

                $scope.documentUrls.push(url);
            });

            var isImage = currentDocument.BasicInfo.Format == DocumentFormats.IMAGE
                        || currentDocument.BasicInfo.Format == DocumentFormats.GIF
                        || currentDocument.BasicInfo.Format == DocumentFormats.TIF
                        || currentDocument.BasicInfo.Format == DocumentFormats.TIFF
                        || currentDocument.BasicInfo.Format == DocumentFormats.JPG
                        || currentDocument.BasicInfo.Format == DocumentFormats.JPEG
                        || currentDocument.BasicInfo.Format == DocumentFormats.PNG;

            _setImagesHandlers($scope, $scope.documentUrls, isImage);
        }
    };

    function _initializeVideo(seismic, currentDocument, $scope, $sce) {

        var videoBlobId = '';

        if (!currentDocument.BasicInfo) {
            return;
        }

        if (currentDocument.BasicInfo.Format == DocumentFormats.MP4) {
            videoBlobId = currentDocument.SourceBlobId;
        }

        if (currentDocument.BasicInfo.MP4ProgressiveBlobId && currentDocument.BasicInfo.MP4ProgressiveBlobId.length > 0) {
            videoBlobId = currentDocument.BasicInfo.MP4ProgressiveBlobId;
        }

        if (videoBlobId && videoBlobId.length > 0) {
            $scope.type = 'vid';

            $scope.videoUrl = $sce.trustAsResourceUrl('https://' + seismic.Tenant + '.seismic.com/videohandler/playvideostreaming.aspx' +
                '?tenant=' + seismic.Tenant +
                '&clienttype=' + encodeURIComponent(seismic.pageInfo.PackageFullName) +
                '&width=640' +
                '&height=480' +
                '&videoid=' + videoBlobId +
                '&id=' + currentDocument.BasicInfo.ThumbnailBlobIds[0] +
                '&videoType=blob');

            if (window.console) {
                console.log($scope.videoUrl);
            }
        }

    };

    function _initializeExternalUrl(seismic, currentDocument, $scope, $sce) {
        if (!currentDocument || !currentDocument.BasicInfo || !currentDocument.BasicInfo.Format) {
            return;
        }
        if (currentDocument.BasicInfo.Format != DocumentFormats.URL || currentDocument.BasicInfo.UrlMode != "0") {
            return;
        }

        $scope.type = 'externalUrlDialog';
        $scope.externalUrl = $sce.trustAsResourceUrl(currentDocument.BasicInfo.Url);
        if (window.console) {
            console.log($scope.externalUrl);
        }
    };

    function _initializeExternalVideo(seismic, currentDocument, $scope, $sce) {
        if (!currentDocument.BasicInfo.Origin_Type || currentDocument.BasicInfo.Origin_Type.length == 0) {
            return;
        }

        if (currentDocument.BasicInfo.Origin_Type.toUpperCase() == "EXTERNAL|VIMEO" || currentDocument.BasicInfo.Origin_Type.toUpperCase() == "EXTERNAL|YOUTUBE") {
            $scope.type = 'embed';

            $scope.embedUrl = $sce.trustAsResourceUrl('https://' + seismic.Tenant + '.seismic.com/VideoHandler/PlayVideoStreaming.aspx' +
                '?id=' + currentDocument.BasicInfo.DocumentId +
                '&width=1280' +
                '&height=720' +
                '&tenant=' + seismic.Tenant +
                '&user=' + seismic.UserName +
                '&clientType=' + encodeURIComponent(seismic.pageInfo.PackageFullName));

            if (window.console) {
                console.log($scope.embedUrl);
            }
        }
    };

    function _findDeliveryOption(deliveryOptions, deliveryOptionId) {
        var i = deliveryOptions.length;
        while (i--) {
            if (deliveryOptions[i].DeliveryOptionId === deliveryOptionId) {
                return deliveryOptions[i];
            }
        }
    };

    function __add2personalspaceReadyHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "SaveToPersonalSpaceReady")) {
            _afterFinish();
        }
    }

    function __add2personalspaceCancelHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "SaveToPersonalSpaceCanceled")) {
            _afterFinish();
        }
    }

    function __add2personalspaceFinishHandler(e, seismic, $rootScope, $scope, deliveryOptionId, requestId, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data.indexOf("SaveToPersonalSpaceFinished-") > -1)) {

            var collectionId = e.data.replace('SaveToPersonalSpaceFinished-', '');

            if (collectionId && collectionId.length > 0) {

                if (collectionId == "cancel") {
                    _afterFinish();
                    return;
                }

                var formInputs = [{ "Name": "PersonalFolderId", "Value": collectionId }];
                seismic.deliver(deliveryOptionId, requestId, formInputs)
                    .then(function (result) {
                        $rootScope.$emit("toaster", {
                            type: 'success',
                            title: 'Save to personal space',
                            body: 'Save to personal space successfully!'
                        });

                        _afterFinish();
                    }, function (error) {
                        $rootScope.$emit("toaster", {
                            type: 'failed',
                            title: 'Save to personal space',
                            body: 'Save to personal space failed!',
                        });

                        _afterFinish();
                    });

                return;
            }

            $rootScope.$emit("toaster", {
                type: 'failed',
                title: 'Save to personal space',
                body: 'Save to personal space failed! Can not find personal folder id.',
            });

            _afterFinish();
        }
    }

    function __commonDeliveryFormReadyHandler(e, seismic, $rootScope, $scope, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "CommonDeliveryFormReady")) {
            _afterFinish();
        }
    };

    function __commonDeliveryFormCancelHandler(e, seismic, $rootScope, $scope, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "CommonFormCanceled")) {
            _afterFinish();
        }
    };

    function __commonDeliveryFormFinishHandler(e, seismic, $rootScope, $scope, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "CommonDeliveryFormFinished")) {

            $rootScope.$emit("toaster", {
                type: 'success',
                title: 'Delivery Option',
                body: 'Success!'
            });

            _afterFinish();
        }
    };

    function __livesendReadyHandler(e, seismic, $rootScope, $scope, _afterReady) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "LiveSendFormReady")) {
            _afterReady();
        }
    };

    function __livesendFinishHandler(e, seismic, $rootScope, $scope, _afterFinish) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "LiveSendFormFinished")) {

            $rootScope.$emit("toaster", {
                type: 'success',
                title: 'LiveSend',
                body: 'LiveSend success!'
            });
        }
        
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (typeof e.data == "string" && e.data.substr(0,17) == 'LiveSendFormInput')) {
            
            var liveSendInputs = e.data.split('||');
            var livenSendInputContents = liveSendInputs[1].split(';');
            var livenSendInputContentsCount = livenSendInputContents.length;
            
            var search = _getUrlSearcher()
            var addSfActivityHistoryParams = {
		            type: 'livesend',
		            currentDocument: $scope.currentDocument,
		            objectId: search.sid.substring(0, 15),
		            email: liveSendInputs[2],
		            contentCount: livenSendInputContentsCount
		        	};
		        	
			   	seismic.AddSfActivityHistory(addSfActivityHistoryParams);
			    	
            	_afterFinish();
            }
    };

    function _liveFormFinishOrCanceledHandler(e) {
        if (e.origin == 'https://' + seismic.Tenant + '.seismic.com'
            && (e.data == "CommonFormFinished"
                || e.data == "CommonFormCanceled")) {
            window.history.back();
        }
    };

    function _buildAdd2PersonalSpace(seismic) {
        var baseUrl = 'https://' + seismic.Tenant + '.seismic.com/HTML5/SfAddToPersonalSpace.aspx?clientType=' + encodeURIComponent(seismic.pageInfo.PackageFullName);

        return baseUrl;
    }

    function _buildDeliveryFormUrl(seismic, document, deliveryOptionId, requestId) {
        var baseUrl = seismic.pageInfo.sfBaseUrl;
        var orgId = seismic.pageInfo.sfOrgId;
        var oId = seismic.pageInfo.objectId;
        var oType = seismic.pageInfo.objectType;
        var oName = seismic.pageInfo.objectName;
        var sId = seismic.pageInfo.sfSessionId;
        var rmToken = seismic.pageInfo.rmToken;
        var spv = seismic.pageInfo.PackageVersion;
        
		var queryString = ([
            "clientType=" + encodeURIComponent(seismic.pageInfo.PackageFullName),
            "baseUrl=" + encodeURIComponent(baseUrl),
            "sessionId=" + encodeURIComponent(sId),
            "orgId=" + encodeURIComponent(orgId),
            "oId=" + encodeURIComponent(oId),
            "oType=" + encodeURIComponent(oType),
            "oName=" + encodeURIComponent($.base64.encode(oName)),
            "rmToken=" + encodeURIComponent(rmToken),
            "deliveryOptionId=" + encodeURIComponent(deliveryOptionId),
            "requestId=" + encodeURIComponent(requestId),
            "spv=" + encodeURIComponent(spv)
        ]).join("&");
        return 'https://' + seismic.Tenant + '.seismic.com/HTML5/CommonDeliveryForm.aspx?' + queryString;
    }

    function _buildLiveSendUrl(seismic, document, requestId) {
        var clientType = seismic.pageInfo.PackageFullName;
        var teamsiteId = seismic.profileInfo.ProfileVersionId;
        var profileId = seismic.profileInfo.ProfileId;
        var profileVersionId = seismic.profileInfo.ProfileVersionId;
        var personalSpaceRootFolderId = null; // null for now, no personal space for inline-viewer for now
        var accessKey = null;
        var userId = seismic.userInfo.UserId;
        var userName = seismic.UserName;
        var userFullName = seismic.UserName;
        var documentId = document.IsLiveDoc ? requestId : document.BasicInfo.VersionId;
        var liveSendContentType = document.IsLiveDoc ? LiveSendContentType.GENERATED_DOC : LiveSendContentType.LIBRARY;
        var documentVersionId = document.BasicInfo.VersionId;
        var tintColors = "FF000000_FFBBBBBB_FF000000_FFE0E0E0_FF000000_FF999999_FF000000_FFFFFFFF_FFFFFFFF_FF337AB7";

        var urlComponents = [
            clientType,
            teamsiteId,
            profileId,
            profileVersionId,
            personalSpaceRootFolderId,
            accessKey,
            userId,
            userName,
            userFullName,
            documentId,
            liveSendContentType,
            tintColors
        ];

        var baseUrl = 'https://' + seismic.Tenant + '.seismic.com/H5LiveSend/DeliveryCenter.aspx';
        baseUrl += '?baseUrl=' + encodeURIComponent(seismic.pageInfo.sfBaseUrl) + '&sId=' + encodeURIComponent(seismic.pageInfo.sfSessionId);
        baseUrl += '#/LiveSend';
        for (var i = 0, count = urlComponents.length; i < count; i++) {
            var component = (urlComponents[i] == undefined || urlComponents[i] == null ? "" : urlComponents[i].toString()).trim();
            var encodedComponent = encodeURIComponent(component.length == 0 ? 'null' : component);
            baseUrl += '/' + encodedComponent;
        }
        return baseUrl;
    };

    function _mathRound(input) {
        if (!isFinite(input) || isNaN(input)) {
            input = 0;
        }

        return Math.round(input);
    };

    function _checkPreviewResult($q, seismic, requestId, $interval) {
        var deferred = $q.defer();

        var lastFinishedPageCount = 0;
        var _progress = 0;
        var _requestResult = null;
        var _requestCompleted = false;
        var _requestError = false;

        function _check() {
            if (!_requestCompleted) {
                seismic.CheckRequestResult(requestId,
                    function (result) {
                        if (result) {
                            _requestResult = result;
                        }
                    });
            }

            if (_requestResult) {
                if (_requestResult.Status == 1) {
                    // Successful
                    _requestCompleted = true;
                } else if (_requestResult.Status == 2) {
                    // Failed
                    _requestCompleted = true;
                    _requestError = true;
                }

                // Error handling
                if (_requestResult.GeneralError) {
                    _requestError = true;
                    deferred.reject(_requestResult.GeneralError, null);
                }
            }

            if (_requestError) {
                return;
            }

            seismic.GetLatestDocumentGenerateState(requestId,
                function (generateState) {
                    if (_requestError) {
                        return;
                    }

                    if (!generateState || !generateState.Progress || generateState.Progress != 100) {
                        // Keep checking while error happens or still in progress.
                        setTimeout(_check, 2000);
                        return;
                    }

                    if (generateState.FinishedPageCount) {
                        lastFinishedPageCount = generateState.FinishedPageCount;
                    }

                    _progress = 100;
                    deferred.notify({ progress: 100 });

                    seismic.GetLatestDocumentPreviewData(requestId,
                        function (previewData) {
                            if (window.console) {
                                console.log(previewData);
                            }
                            deferred.notify({ previewData: previewData });

                            if (_requestCompleted) {
                                deferred.resolve(_requestResult.ChannelResults[0].OutputFiles[0]);
                            } else {
                                seismic.CheckRequestResult(requestId,
                                    function (requestResult) {
                                        deferred.resolve(requestResult.ChannelResults[0].OutputFiles[0]);
                                    });
                            }
                        });
                });
        }

        _check();

        var _timer = $interval(function () {
            if (_progress >= 95) {
                $interval.cancel(_timer);
                return;
            }

            _progress += 1;
            _progress = _progress > 100 ? 100 : _progress;
            deferred.notify({ progress: _progress });
        }, 1000);

        return deferred.promise;
    }

    function initPlayer(slides, startSlide) {
        window.player = new $.supersized({
            slideshow: 1, // Slideshow on/off
            autoplay: 0, // Slideshow starts playing automatically
            start_slide: startSlide, // Start slide (0 is random)
            stop_loop: 0, // Pauses slideshow on last slide
            random: 0, // Randomize slide order (Ignores start slide)
            slide_interval: 3000, // Length between transitions
            transition: 6, // 0-None, 1-Fade, 2-Slide Top, 3-Slide Right, 4-Slide Bottom, 5-Slide Left, 6-Carousel Right, 7-Carousel Left
            transition_speed: 1000, // Speed of transition
            new_window: 1, // Image links open in new window/tab
            pause_hover: 0, // Pause slideshow on hover
            keyboard_nav: 1, // Keyboard navigation on/off
            performance: 1, // 0-Normal, 1-Hybrid speed/quality, 2-Optimizes image quality, 3-Optimizes transition speed // (Only works for Firefox/IE, not Webkit)
            image_protect: 1, // Disables image dragging and right click with Javascript
            // Size & Position                         
            min_width: 0, // Min width allowed (in pixels)
            min_height: 0, // Min height allowed (in pixels)
            vertical_center: 1, // Vertically center background
            horizontal_center: 1, // Horizontally center background
            fit_always: 1, // Image will never exceed browser width or height (Ignores min. dimensions)
            fit_portrait: 1, // Portrait images will not exceed browser height
            fit_landscape: 1, // Landscape images will not exceed browser width
            // Components                           
            slide_links: 'blank', // Individual links for each slide (Options: false, 'num', 'name', 'blank')
            thumb_links: 1, // Individual thumb links for each slide
            thumbnail_navigation: 0, // Thumbnail navigation
            slides: slides,

            // Theme Options               
            progress_bar: 1, // Timer for each slide
            mouse_scrub: 0,
        });

        function RefreshPrevNextState() {
            if (vars.current_slide > 0) {
                $("#prevslide").show();
            } else {
                $("#prevslide").hide();
            }
            if (vars.current_slide < (slides.length - 1)) {
                $("#nextslide").show();
            } else {
                $("#nextslide").hide();
            }
        }

        var oldInit = theme._init;
        theme._init = function() {
            RefreshPrevNextState();
            oldInit();
        };

        var oldAfterAnimation = theme.afterAnimation;
        theme.afterAnimation = function() {
            RefreshPrevNextState();
            oldAfterAnimation();
        };

        if (window.oneImageMode) {
            $("#prevslide, #nextslide, #thumb-tray, #loading-process, #progress-back, #controls-wrapper").remove();
        }

        window.isPlayerLoaded = true;
    };

    function gotoSlide(slide) {
        window.player.goTo(slide);
    }

    function _updateProcess(percent) {
        percent = percent || 0;
        percent += "%";
        $("#loading-process-percent-bar").css({
            width: percent
        });

        $("#loading-process-percent-text").text(percent);
    }

    function _finishLoading() {
        $("#thumb-controllers").show();
        $("#loading-process").hide();
    }

    function _addSlide(slide) {
        if (window.player) {
            window.player.addSlide(slide);
        }
    }

    function _deleteLoadingSlide() {
        window.player.deleteLoadingSlide();
    }

    function _setImagesHandlersForLiveDoc($scope, oneImageMode, index) {
        var v = 'https://redtealtest2.seismic.com/html5/Theme/base/images/spinner48.gif';
        window.slides = [{
                image: v,
                thumb: v,
                title: '',
                isLoadingImage: true
            }];

        window.startPageIndex = index || 0;
        window.oneImageMode = oneImageMode;
        initPlayer(window.slides, 1);
    }

    function _setImagesHandlers($scope, documentUrls, isImage, index) {
        _setImages($scope, documentUrls, isImage, index);
    }

    function _setImages ($scope, documentUrls, oneImageMode, index) {
        window.slides = documentUrls.map(function(v, k, array) {
            return {
                image: v,
                thumb: v,
                title: ''
            }
        });

        window.startPageIndex = index || 0;
        window.oneImageMode = oneImageMode;
        initPlayer(window.slides, 1);
    }

    function _getIconThumbnail(format) {
        format = format || '';

        var iconThumbnail = '';
        switch (format) {
            case "PPT":
            case "PPTX":
            case "PPTXTABLE":
                iconThumbnail = SeismicFormatIcon.PPT_PNG_URL;
                break;
            case "DOC":
            case "DOCX":
            case "DOCXTABLE":
                iconThumbnail = SeismicFormatIcon.WORD_PNG_URL;
                break;
            case "PDF":
                iconThumbnail = SeismicFormatIcon.PDF_PNG_URL;
                break;
            case "IMAGE":
            case "GIF":
            case "TIF":
            case "TIFF":
            case "JPG":
            case "JPEG":
            case "PNG":
                iconThumbnail = SeismicFormatIcon.IMG_PNG_URL;
                break;
            case "BMP":
            case "AVI":
            case "MPEG4":
            case "M4V":
            case "WAV":
            case "MP4":
            case "MPG":
            case "MPA":
            case "MPE":
            case "RM":
            case "RAM":
            case "ASF":
            case "MOV":
            case "VOB":
            case "WMV":
            case "V3GP":
                iconThumbnail = SeismicFormatIcon.VIDEO_PNG_URL;
                break;
            case "ZIP":
                iconThumbnail = SeismicFormatIcon.GENERAL_PNG_URL;
                break;
            case "YOUTUBE":
                iconThumbnail = SeismicFormatIcon.YOUTUBE_PNG_URL;
                break;
            case "VIMEO":
                iconThumbnail = SeismicFormatIcon.VIMEO_PNG_URL;
                break;
            case "XLSX":
            case "XLS":
                iconThumbnail = SeismicFormatIcon.XLS_PNG_URL;
                break;
            case "URL":
                iconThumbnail = SeismicFormatIcon.URL_PNG_URL;
                break;
            default:
                iconThumbnail = SeismicFormatIcon.GENERAL_PNG_URL;
                break;
        }

        return iconThumbnail;
    };

    // we have to make this clint follow the H5 app to use $App everywhere, it may need more time, so please add once you find it need
    window.$App = {
      "loginInfo": {
        "tenant": "",
        "username": "",
        "userid": "",
        "password": "",
        "accessKey": "",
        "rememberMeToken": "",
        "isFormAuth": false,
        "clientType": "",
        "clientInfo": {},
        "pageUrl": "",
        "isSSO": false,
        "fullname": "admin"
      },
      "distributionInfo": {
        "allowDownload": true,
        "allowEmail": true
      },
      "status": {
        "isServing": true,
        "isLoggedIn": false
      },
      "timeZoneOffset": -4,
      "defaultTeamSiteId": null,
      "specialPersonalContentCollectionIds": [
      ],
      "isPersonalSpaceEnabled": true,
      "ApplicationInfo": {
        "AccountConfiguration": [
        ],
        "AppConfiguration": [],
        "BelongTeamSites": [
        ],
        "CanAccessLibrary": true,
        "ClientAppCommonSettings": {
          "DisableAskExpert": false,
          "DisableBackgroundCheckForSalesforceData": false,
          "DisabledUserGroups": [],
          "EnablePreview": false,
          "UseIndividualFiles": false
        },
        "CurrentTeamSiteId": "1",
        "CurrentTimeZoneId": "Eastern Standard Time",
        "CurrentUser": {},
        "DomainName": "seismic.com",
        "GoogleOAuthDefaultSetting": [
        ],
        "IsFullTextSearchEnabled": false,
        "IsPersonalSpaceEnabled": true,
        "IsSalesforceEnabled": true,
        "SalesforceOrganizations": [
        ],
        "SharePointAPPClientSecret": "",
        "SharePointAppClientId": "",
        "SystemDeliveryOptions": [
        ],
        "SystemUICustomization": {
          "CustomBackgroundImageBlobId": null,
          "CustomLogoBlobId": null,
          "ThemeColor": null
        },
        "Tenant": "redtealtest2",
        "TimeZoneOffset": -4,
        "UserAllTeamSitePermissionInfo": {
          "TeamSitePermissionInfoDict": []
        },
        "UserAllTeamSitePermissionInfoV2": {
          "TeamSitePermissionInfoDict": [
          ]
        },
        "UserExternalMappings": [
        ],
        "UserProfileProperty": {
          "CustomProperties": [
          ]
        }
      },
      "disableAskExpert": false,
      "personalSpaceRootFolderId": "",
      "personalCartFolderId": "",
      "isHelpCenter": false,
      "showMostPopular": true,
      "showFavorites": true,
      "showRecentlyUsed": true,
      "showActivities": true,
      "showUserName": true,
      "showUserSettings": true,
      "showHelpCenter": true,
      "showHelpCenterTicket": true,
      "canAccessLibrary": true,
      "showPersonalSpace": true,
      "showDocumentCart": true,
      "showLiveShareCenter": true,
      "showOnlineEdit": true,
      "showLiveSendTrace": true,
      "showLiveShareTrace": true,
      "orignalGlobalTint": {
        "ControlBackground": "#FFFFFFFF",
        "ControlForeground": "#FF000000",
        "DeliveryOptions": [
        ],
        "HighlightBackground": "#FFDC745B",
        "HighlightForeground": "#FFFFFFFF",
        "IconBlobId": "",
        "IsIconTint": true,
        "OfflineOption": 1,
        "PreviewOption": 1,
        "PrimaryBackground": "#FFFFFFFF",
        "PrimaryForeground": "#FF000000",
        "SecondaryBackground": "#FFFFFFFF",
        "SecondaryForeground": "#FF000000",
        "TileBackground": "#FFFFFFFF",
        "TileForeground": "#FF000000",
        "TitleBackground": "#FFFFFFFF",
        "TitleForeground": "#FF000000",
        "WidgetSize": 0
      },
      "globalTint": {
        "iconTint": "FF000000",
        "allIconPath": "https://redtealtest2.seismic.com/Resource/Image.ashx?tenant=redtealtest2&us…ntcolor=FFFFFFFF&isembeddedresource=true&v=16010101000000&v=16010101000000",
        "gridIconTint": "FF000000",
        "iconFavoriteTint": "FF000000",
        "iconFavoriteTintHover": "FFDC745B",
        "previewIconTint": "FF000000",
        "colors": {
          "iconPreviewImg": null,
          "ControlBackground": "rgba(255,255,255,1)",
          "ControlForeground": "rgba(0,0,0,1)",
          "HighlightBackground": "rgba(220,116,91,1)",
          "HighlightForeground": "rgba(255,255,255,1)",
          "PrimaryBackground": "rgba(255,255,255,1)",
          "PrimaryForeground": "rgba(0,0,0,1)",
          "SecondaryBackground": "rgba(255,255,255,1)",
          "SecondaryForeground": "rgba(0,0,0,1)",
          "TileBackground": "rgba(255,255,255,1)",
          "TileForeground": "rgba(0,0,0,1)",
          "TitleBackground": "rgba(255,255,255,1)",
          "TitleForeground": "rgba(0,0,0,1)",
          "PrimaryBackground_odd": "rgba(255,255,255,1)",
          "PrimaryBackground_hover": "rgba(255,255,255,1)",
          "PrimaryBackground_border": "rgba(255,255,255,1)",
          "SecondaryBackground_hover": "rgba(220,116,91,1)",
          "HighlightBackground_hover": "rgba(220,116,91,1)"
        },
        "paths": {
          "iconspirit": "https://redtealtest2.seismic.com/Resource/Image.ashx?tenant=redtealtest2&us…enter-5&imageid=icon-spirit.png&tintcolor=FF273C42&isembeddedresource=true"
        }
      }
    }
})();

function _retrieveTabInfo(oncomplete, onerror, oninfo) {
  var CUSTOME_TAB_ID_LENGTH = 15;
  function asyncErrorHandler(error){
    if("sf:INSUFFICIENT_ACCESS" == error.faultcode){
      var infoMessage = $Label.messageInsufficientAccess;
      oninfo(infoMessage);
    } else {
      var errorMessage = format($Label.messageUnknownIssue, error.faultstring);
      onerror(errorMessage);
    }
  }
  function waitForDone(callback) {
    function getResult(id) {
      sforce.metadata.checkRetrieveStatus(id, {
        onSuccess: callback,
        onFailure: asyncErrorHandler
      });
    }
    function check(results) {
      var done = results[0].getBoolean("done");
      if (!done) {
        sforce.metadata.checkStatus([results[0].id], {
          onSuccess: check,
          onFailure: asyncErrorHandler
        });
      } else {
        getResult(results[0].id);
      }
    }
    return function (result) {
      check([result]);
    };
  }
  var req, result;
  req = new sforce.RetrieveRequest();
  req.apiVersion = "27.0";
  req.singlePackage = false;
  req.unpackaged = {
    types: [{name: "CustomTab", members:["*"]}]
  };
  
  sforce.metadata.retrieve(req, {
    onSuccess: waitForDone(function (result) {
      var zip = new JSZip(result.zipFile, {base64:true});

      if (window.console) {
          console.log('PARSING THE RESPONSE: ', zip);
      }
      parseZip(zip);
    }),
    onFailure: asyncErrorHandler
  });

  function parseZip(zip){
    var zipFileNames = [];
    for(var zipfileName in zip.files) {
      zipFileNames.push(zipfileName);    
    }
    var fileMapping = {};
    while(true)
    {
      var fileName = zipFileNames.pop();
      if(fileName == null) break;
      var file = zip.files[fileName];
      if(file.data!=null && file.data.length>0){
        fileMapping[fileName] = file.data;
      }
    }
    var displayNameMapping = {};
    for(var key in fileMapping){
      var $doc = jQuery(jQuery.parseXML(fileMapping[key]));
      var $label = jQuery($doc.children()[0]).children().filter("label");
      try{
        var $page = jQuery($doc.children()[0]).children().filter("page");
        if($page && $page.text() && 
          ($page.text().toLowerCase() == 'seismicrequester' || $page.text().toLowerCase() == 'seismic__seismicrequester' || $page.text().toLowerCase() == 'seismic_dev__seismicrequester')) {
          displayNameMapping[key] = $label.text();
        }
      }catch(e){}
    }
    
    sforce.metadata.listMetadata(
      {queries: [{type: 'CustomTab'}], asOfVersion: 27},
      {
        onSuccess: function (results) {
          var fileProperties = {};
          for(var i = 0; i < results.length; i++){
            fileProperties['unpackaged/' + results[i].fileName] = results[i].id;
          }
          var customTabList = [];
          for(var key in displayNameMapping){
            var id = fileProperties[key];
            var label = displayNameMapping[key];
            if(id && label){
              customTabList.push(new CustomTab(id, label));
            }
          }
          customTabList.sort(function(a, b){
            var ta = a.label;
            var tb = b.label;
            return ta > tb ? -1 : (tb > ta ? 1 : 0);
          });

          oncomplete(customTabList);
        },
        onFailure: asyncErrorHandler
      }
    );
    function CustomTab(id, label){
      if(id != null){
        id = id.substring(0, CUSTOME_TAB_ID_LENGTH);
      }
      this.id = id;
      this.label = label;
    }
  }
}