/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__(9);


/***/ }),
/* 1 */,
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = (__webpack_require__(3))(2);

/***/ }),
/* 3 */
/***/ (function(module, exports) {

	module.exports = vendor_lib;

/***/ }),
/* 4 */,
/* 5 */,
/* 6 */,
/* 7 */,
/* 8 */,
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
	
		//Entry point for all the scss files to this application
		__webpack_require__(10);
	
		__webpack_require__(23)();
		__webpack_require__(24);
		__webpack_require__(51);
		__webpack_require__(66);
	
		module.exports = angular.module('docGen', [
				'DocGenSetting',
				'docGen.adminServices',
				'docGen.commonFilters',
				'docGenCommonDirectives',
				'docGenCommonServices',
				'ui.router',
				'ui.bootstrap',
				'ngLodash',
				'ngSanitize',
				'smart-table',
				'ngFileUpload',
				'dndLists',
				'ngMaterial'		
			])
			.config(__webpack_require__(68))
			// .service('docGenC', require('./common/directives/pageContainer/services/pageContainerService.js'))		
			.constant('docGenConstants', __webpack_require__(70));
	
	})();


/***/ }),
/* 10 */
/***/ (function(module, exports) {

	// removed by extract-text-webpack-plugin

/***/ }),
/* 11 */,
/* 12 */,
/* 13 */,
/* 14 */,
/* 15 */,
/* 16 */,
/* 17 */,
/* 18 */,
/* 19 */,
/* 20 */,
/* 21 */,
/* 22 */,
/* 23 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = (__webpack_require__(3))(1);

/***/ }),
/* 24 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
	
		module.exports = angular.module('docGenCommonDirectives', [])
	
			.directive('attachments', __webpack_require__(25))
			.directive('contenteditable', __webpack_require__(29))
			.directive('contextMenu', __webpack_require__(30))
			.directive('editableTextField', __webpack_require__(32))
			.directive('email', __webpack_require__(34))
			.directive('focusAndSelect', __webpack_require__(37))
			.directive('globalHeader', __webpack_require__(38))
			.directive('globalSubHeader', __webpack_require__(40))
			.directive('pageContainer', __webpack_require__(42))
			.directive('pageNotification', __webpack_require__(44))
			.directive('proposalsList', __webpack_require__(46))
			.directive('preview', __webpack_require__(49));
	
	})();


/***/ }),
/* 25 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
			var attachmentsController;
	
			attachmentsController = function(systemConstants,
												$scope,
												$uibModal,
												_,
												RemoteService,
												i18nService,
												ProposalsListService,
												PageContainerService,
												PageNotificationService,
												GlobalService,
												PreviewService,
	                                            UploadService,
	                                            UtilitiesService) {
				var vm = this;
				var tplDialogSize = 'lg';
				var urlDialogSize = 'md';
				var currentProposalId = GlobalService.currentProposalId;
				var notificationTimeout = 5000;
				var isFileEnabled = systemConstants.docGenCustomSettings.isFileEnabled;
	
				vm.labels = i18nService.CustomLabel;
				vm.mergeFiles = [];
				vm.attachFiles = [];
				vm.invalidFiles = [];
				vm.selectedNAFiles = [];
				vm.fileValidity = true;
				vm.collatedDocs = false;
				vm.selectionIsNotPdf = false;
				vm.noGeneratedDocYet = true;
				vm.fileUploadSupport = UtilitiesService.deviceInfo.isFileInputSupported;
				vm.isMobileIos = UtilitiesService.deviceInfo.isMobileIos;
				
				var _addAttachmentInfo = function(attachmentInfo, bucket) {
					var fileSize = attachmentInfo.BodyLength / 1000000; // MBs
					var fileType = attachmentInfo.ContentType;
	
					if (fileSize > 4 || !GlobalService.isAcceptedFileType(fileType))
					{
						PageNotificationService.hasPageNotification = true;
						PageNotificationService.alert = {
							type: 'danger',
							message: vm.labels.AcceptedDocgenFileFormats,
							timeout: undefined
						};
					}
					else {
						PreviewService.attemptToMerge = true;
						var obj = {
							RecordId: attachmentInfo.RecordId,
							Title: attachmentInfo.Title,
							isCollated: attachmentInfo.isCollated
						};
						PageContainerService.mergeFilesAttachmentInfo.push(obj);
					}
	
					if (PreviewService.selectionIsNotPdf && !PreviewService.goForPDF && (attachmentInfo.ContentType === "application/pdf" || attachmentInfo.ContentType === "PDF"))
					{
						PreviewService.goForPDF = true;
					}
	
					var object = {
						lastModified: '',
						lastModifiedDate: {},
						name: attachmentInfo.Title,
						size: attachmentInfo.BodyLength,
						type: attachmentInfo.ContentType,
						webkitRelativePath: '',
						uuid: UtilitiesService.generateUuid()
					};
	
					if (bucket == 'merge') {
						vm.mergeFiles.push(object);
					} else {
						vm.attachFiles.push(object);
					}
				};
	
				if(ProposalsListService.proposalListLength > 0) {
					vm.noGeneratedDocYet = false;
				}
	
				vm.getFileTypeIconClass = function(type) {
					if (type === 'application/pdf' || type === 'PDF') {
						return 'fa-file-pdf-o';
					} else if (type === 'application/msword' || type === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
						return 'fa-file-word-o';
					} else {
						return 'fa-file-text-o';
					}
				};
	
				vm.getFileTypeIconUrl = function(file) {
					return GlobalService.getFileTypeIconUrl(file);
				};
	
				vm.openNADialog = function() {
					PreviewService.dialogIsOpen = true;
	
					addFromQuoteDialogController.$inject = ['$scope', '$uibModalInstance'];
	
					function addFromQuoteDialogController($scope, $uibModalInstance) {
						// The following is the scope of the select template popup
						$scope.displayedCollection = [];
						$scope.labels = i18nService.CustomLabel;
						RemoteService.getAttachments(currentProposalId).then(function(response) {
							$scope.rowCollection = response;
						});
	
						$scope.getFileTypeIconClass = function(type) {
							if (type === 'application/pdf' || type === 'PDF') {
								return 'fa-file-pdf-o';
							} else if (type === 'application/msword' || type === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
								return 'fa-file-word-o';
							} else {
								return 'fa-file-text-o';
							}
						};
	
						$scope.dismiss = function() {
							$uibModalInstance.dismiss('cancel');
							PreviewService.dialogIsOpen = false;
						};
	
						$scope.addToMerge = function() {
							PreviewService.attemptToMerge = false;
	
							_.map($scope.displayedCollection, function(row) {
								if (row.isSelected) {
									if (row.ContentType === "" || !angular.isDefined(row.ContentType)) { // derive file type from file name if none found
										var re = /(?:\.([^.]+))?$/;
										var fileType = re.exec(row.Title)[1];
	
										row.ContentType = "application/" + fileType;
									}
	
									_addAttachmentInfo(row, 'merge');
								}
	
							});
	
							if (PreviewService.goForPDF) {
								PageNotificationService.hasPageNotification = true;
								PageNotificationService.alert = {
									type: 'danger',
									message: vm.labels.OutputWillBePDF,
									timeout: notificationTimeout
								};
							}
							PageContainerService.mergeFilesAttachmentInfo = _.uniq(PageContainerService.mergeFilesAttachmentInfo, 'Title');
							vm.mergeFiles = _.uniq(vm.mergeFiles, 'name');
	
							$uibModalInstance.close(true);
							PreviewService.dialogIsOpen = false;
						};
					}
	
					var dialogInstance = $uibModal.open({
						backdrop: 'static',
						animation: true,
						template: __webpack_require__(26),
						size: tplDialogSize,
						keyboard: false,
						controller: addFromQuoteDialogController
					});
	
				};
	
				vm.openUrlDialog = function() {
					PreviewService.dialogIsOpen = true;
	
					addUrlDialogCtrl.$inject = ['$scope', '$uibModalInstance', 'RemoteService'];
	
					function addUrlDialogCtrl($scope, $uibModalInstance, RemoteService) {
						// The following is the scope of the select template popup
						$scope.labels = i18nService.CustomLabel;
	
						// default to show one linked URL
						$scope.linkedUrls = [{
							addedUrl: '',
							urlTitle: ''
						}];
	
						$scope.addLinkedUrl = function() {
							$scope.linkedUrls.push({
								                       addedUrl: '',
								                       urlTitle: ''
							                       });
						};
	
						$scope.dismiss = function() {
							$uibModalInstance.dismiss('cancel');
							PreviewService.dialogIsOpen = false;
						};
	
						$scope.done = function() {
							var requestObj = {
								proposalId: currentProposalId,
								hyperlinkList: [],
								outputFormat: "PDF" // currently we only support PDF format
							};
	
							// add linked URLs to request object
							for (var i = 0; i < $scope.linkedUrls.length; i++) {
								if($scope.linkedUrls[i].addedUrl && $scope.linkedUrls[i].addedUrl !== ''){
									requestObj.hyperlinkList.push({
										                              Title: $scope.linkedUrls[i].urlTitle,
										                              URL: $scope.linkedUrls[i].addedUrl
									                              });
								}
							}
	
							RemoteService.getURLContent(requestObj).then(
								function(response) {
									// success
									PreviewService.attemptToMerge = false;
	
									for (var i = 0; i < response.length; i++) {
										var row = response[i];
	
										_addAttachmentInfo(row, 'merge');
									}
	
									if (PreviewService.goForPDF) {
										PageNotificationService.hasPageNotification = true;
										PageNotificationService.alert = {
											type: 'danger',
											message: vm.labels.OutputWillBePDF,
											timeout: notificationTimeout
										};
									}
	
									// TODO is this necessary? If attachments have same Title this does not necessarily mean it is the same document contents
									PageContainerService.mergeFilesAttachmentInfo = _.uniq(PageContainerService.mergeFilesAttachmentInfo, 'Title');
	
									$uibModalInstance.close(true);
									PreviewService.dialogIsOpen = false;
								},
								function(reason) {
									// failure
									// TODO: feed it to the page error service with appropriate error level
									console.log(reason);
									$scope.loading = false;
								}
							);
						};
	
					}
	
					var urlDialogInstance = $uibModal.open({
						backdrop: 'static',
						animation: true,
						template: __webpack_require__(27),
						size: urlDialogSize,
						keyboard: false,
						controller: addUrlDialogCtrl
					});
				};
	
				// Remove file
				vm.removeFile = function(file, idx, bucket) {
	
					if (bucket === 'mergeBucket') {
						// Remove from the view
						_.remove(vm.mergeFiles, function(obj) {
							return obj.name === file.name;
						});
	
						if(vm.mergeFiles.length == 1) {
							PreviewService.attemptToMerge = false;
						}
	
						_.remove(PageContainerService.mergeFilesAttachmentInfo, function(obj) {
							return (obj.Title === file.name);
						});
	
						// this file pending upload and others also pending completion?
						if(file.uploadStatus === "pending" && vm.filesForUpload > 0) {
							// decrement number of pending uploads
							vm.filesForUpload--;
						}
	
						// Check for a non-word file after removing any file if the generated file is a word file
						_.map(vm.mergeFiles, function(file, idx) {
							var re = /(?:\.([^.]+))?$/;
							var fileType = re.exec(file.name)[1];
							if (idx !== 0 &&
									PreviewService.selectionIsNotPdf &&
									fileType !== 'doc' &&
									fileType !== 'docx')
							{
								PreviewService.goForPDF = true;
								PageNotificationService.hasPageNotification = true;
								PageNotificationService.alert = {
									type: 'danger',
									message: vm.labels.OutputWillBePDF,
									timeout: notificationTimeout
								};
								return false;
							}
							else {
								PreviewService.goForPDF = false;
							}
						});
	
						if(vm.filesForUpload === 0) { // no more files pending upload?
							// re-enable merge button
							PreviewService.disableMerge = false;
							PageNotificationService.hasPageNotification = false;
						}
					}
				};
	
				vm.dragoverCallback = function(event, index, external, type) {
					return index > 0;
				};
	
				// Re-order files to be merged after drag and drop shuffle
				vm.reOrderFiles = function(index, bucket) {
					var dummyArr = [];
					if (bucket === 'merge') {
						vm.mergeFiles.splice(index, 1);
						_.map(vm.mergeFiles, function(file, index) {
							if (index !== 0) {
								dummyArr.push(_.find(PageContainerService.mergeFilesAttachmentInfo, _.matchesProperty('Title', file.name)));
							}
						});
						PageContainerService.mergeFilesAttachmentInfo = dummyArr;
					}
				};
	
				// Being called before the file upload happens
				vm.beforeFileUpload = function(files) {
					_.map(files, function(file) {
						var fileSize = file.size / 1000000; //MB
						var fileType = file.type;
	
						if (fileSize > 4 || !GlobalService.isAcceptedFileType(fileType))
						{
							PageNotificationService.hasPageNotification = true;
							PageNotificationService.alert = {
								type: 'danger',
								message: vm.labels.AcceptedDocgenFileFormats,
								timeout: undefined
							};
						}
	
						if (PreviewService.selectionIsNotPdf && !PreviewService.goForPDF && (fileType === 'application/pdf' || fileType === 'PDF'))
						{
							PreviewService.goForPDF = true;
						}
	
						if(!angular.isDefined(file.uuid)) {
							file.uuid = UtilitiesService.generateUuid();
						}
					});
	
					if (PreviewService.goForPDF) {
						PageNotificationService.hasPageNotification = true;
						PageNotificationService.alert = {
							type: 'danger',
							message: 'Output format will be PDF if you merge these chosen files',
							timeout: notificationTimeout
						};
					}
	
				};
	
				vm.uploadLocalFiles = function(bucket) {
					vm.filesForUpload = 0;
					vm.filesUploaded = 0;
	
					PreviewService.attemptToMerge = true;
	
					if (bucket === 'mergeBucket') {
						_.map(vm.mergeFiles, function(file, index) {
							if (index !== 0 && file instanceof File && file.uploadStatus !== "complete") {
								// disable merge button till all files uploaded
								PreviewService.disableMerge = true;
	
								vm.filesForUpload++; // increment number of files pending upload
	
								encodeAndUploadFileAttachment(vm.mergeFiles[index], bucket, index);
							}
						});
					} else {
						PreviewService.disableMerge = true;
	
						vm.filesForUpload = vm.attachFiles.length; // all files in list should be uploaded
	
						_.map(vm.attachFiles, function(file, index) {
							// if file is defined set to upload status of pending
							if (vm.attachFiles[index]) vm.attachFiles[index].uploadStatus = "pending";
	
							encodeAndUploadFileAttachment(vm.attachFiles[index]);
						});
					}
	
				};
	
				// This function will be called per file
				function encodeAndUploadFileAttachment(file, bucket, index) {
					if(file.uploadStatus == "pending") return;
	
					file.uploadStatus = "pending";
					file.percentComplete = 0;
	
						// display message indicating files being uploaded
					PageNotificationService.hasPageNotification = true;
					PageNotificationService.alert = {
						type: 'success',
						message: vm.labels.PleaseWaitWhileDocumentUploaded
					};
	
					var uploadRequest = {
						file: file,
						parentId: currentProposalId,
						onerror: function(e) {
							file.uploadStatus = "error";
	
							// unkown error occurred
							PageNotificationService.hasPageNotification = true;
							PageNotificationService.alert = {
								type: 'danger',
								message: vm.labels.GenericServiceFailureError
							};
						},
						oncomplete: function(e) {
							file.uploadStatus = "complete";
							file.percentComplete = 100;
	
							// file still in list?
							var fileExists = _.some((bucket === 'mergeBucket' ? vm.mergeFiles : vm.attachFiles), function (listFile) {
								return file.uuid === listFile.uuid;
							});
	
							if(fileExists) {
								file.uploadStatus = "complete"; // flag file as uploaded
								vm.filesUploaded++; // increment number of files uploaded
	
								if (bucket === 'mergeBucket') {
									PageContainerService.mergeFilesAttachmentInfo.push(e.result);
								} else {
									PageContainerService.attachFilesAttachmentInfo.push(e.result);
								}
							}
	
							// if files uploaded greater than or equal to pending files for upload
							// then remove notification message and re-enable merge button
							if(vm.filesUploaded >= vm.filesForUpload) {
								PageNotificationService.hasPageNotification = false;
								PreviewService.disableMerge = false;
							}
	
							// need to create simple JSON copy of File object otherwise when drag/drop occurs properties
							// from the File object are not properly copied.
							var _tmpFile = {
								name: file.name,
								uuid: file.uuid,
								lastModified: file.lastModified,
								lastModifiedDate: file.lastModifiedDate,
								size: file.size,
								type: file.type,
								uploadStatus: file.uploadStatus,
								webkitRelativePath: file.webkitRelativePath
							};
	
							vm.mergeFiles[index] = _tmpFile;
						},
						onchunkcomplete: function(e) {
							// upload file upload status
							file.percentComplete = Math.floor(e.percentComplete * 100);
	
							// in case file removed mid-upload
							if(vm.filesUploaded >= vm.filesForUpload) {
								e.stopUploading = true;
							}
						}
					};
	
					UploadService.uploadAttachment(uploadRequest);
				}
	
				function clearBuckets() {
					vm.mergeFiles = [];
					vm.attachFiles = [];
					PageContainerService.attachNAFilesAttachmentInfo = [];
				}
	
				var deRegisterWatch1 = $scope.$watch(function() {
						return GlobalService.clearAttachmentsBuckets;
					},
					function(newVal, oldVal) {
						if (newVal === true) {
							clearBuckets();
						}
					}
				);
	
				var deRegisterWatch2 = $scope.$watch(function() {
						return ProposalsListService.mergedSourceDocs;
					},
					function(newVal, oldVal) {
						if (newVal) {
							vm.mergeFiles = ProposalsListService.mergedSourceDocs;
	
							_.map(vm.mergeFiles, function(file, index) {
								if(!angular.isDefined(file.uuid)) {
									file.uuid = UtilitiesService.generateUuid();
								}
							});
						}
					}
				);
	
				var deRegisterWatch3 = $scope.$watch(function() {
						return ProposalsListService.attachments;
					},
					function(newVal, oldVal) {
						if (newVal) {
							vm.attachFiles = ProposalsListService.attachments;
	
							_.map(vm.attachFiles, function(file, index) {
								if(!angular.isDefined(file.uuid)) {
									file.uuid = UtilitiesService.generateUuid();
								}
							});
						}
					}
				);
	
				var deRegisterWatch4 = $scope.$watch(function() {
						return ProposalsListService.proposalDoc;
					},
					function(newVal, oldVal) {
						if (newVal) {
							clearBuckets();
							// make sure is valid file object before adding
							if(ProposalsListService.proposalDoc.hasOwnProperty('name')) {
								vm.mergeFiles.push(ProposalsListService.proposalDoc);
							}
						}
					}
				);
	
				var deRegisterWatch5 = $scope.$watch(function() {
						return ProposalsListService.selectionIsACollatedDoc;
					},
					function(newVal) {
						if (newVal) {
							vm.collatedDocs = true;
						}
						if (!newVal) {
							vm.collatedDocs = false;
						}
					}
				);
	
				var deRegisterWatch6 = $scope.$watch(function() {
						return PreviewService.selectionIsNotPdf;
					},
					function(newVal, oldVal) {
						vm.selectionIsNotPdf = PreviewService.selectionIsNotPdf;
					}
				);
	
				var deRegisterWatch7 = $scope.$watch(function() {
						return ProposalsListService.proposalList;
					},
					function(newVal, oldVal) {
						if (newVal && newVal.length > 0) {
								vm.noGeneratedDocYet = false;
						}
						else {
							vm.noGeneratedDocYet = true;
						}
					}
				);
	
				$scope.$on('$destroy', function() {
					deregisterWatch1();
					deRegisterWatch2();
					deRegisterWatch3();
					deRegisterWatch4();
					deRegisterWatch5();
					deRegisterWatch6();
					deRegisterWatch7();
				});
			};
	
			attachmentsController.$inject = ['systemConstants',
												'$scope',
												'$uibModal',
												'lodash',
												'RemoteService',
												'i18nService',
												'ProposalsListService',
												'PageContainerService',
												'PageNotificationService',
												'GlobalService',
												'PreviewService',
												'UploadService',
	                                            'UtilitiesService'
											];
	
			return {
				restrict: 'E',
				replace: true,
				controller: attachmentsController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(28)
			};
		}];
	})();


/***/ }),
/* 26 */
/***/ (function(module, exports) {

	module.exports = "<div class='modal-header list-na__header'>\r\n\t<h3 class='modal-title'>{{labels.QuoteAttachments}}</h3>\r\n\t<i class='fa fa-times list-na__close' ng-click='dismiss()' aria-hidden='true'></i>\r\n</div>\r\n<div class=\"modal-body list-na__body\">\r\n\t<div class='templates'>\r\n\t\t<!-- <div class='templates__search'></div> -->\r\n\t\t<div class='templates__table'>\r\n\t\t\t<div>\r\n\t\t\t\t<table st-table=\"displayedCollection\" st-safe-src='rowCollection' class='table'>\r\n\t\t\t\t\t<thead>\r\n\t\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t\t<th colspan=\"2\" class='searchable'>\r\n\t\t\t\t\t\t\t\t<div class='searchbar'>\r\n\t\t\t\t\t\t\t\t\t<i class=\"fa fa-search\"></i>\r\n\t\t\t\t\t\t\t\t\t<input st-search='' class=\"form-control\" placeholder=\"{{labels.Search}}\" type=\"text\" />\r\n\t\t\t\t\t\t\t\t</div>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t\t<th st-sort=\"Name\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.DocumentName}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t\t<th st-sort=\"Name\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.DocumentType}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t\t<th st-sort=\"BodyLength\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.SizeKB}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t</thead>\r\n\t\t\t\t\t<tbody>\r\n\t\t\t\t\t\t<tr ng-if='displayedCollection.length === 0'>\r\n\t\t\t\t\t\t\t<td>{{labels.NoAttachmentsToDisplay}}</td>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t\t<tr st-select-row=\"row\" st-select-mode=\"multi\" ng-repeat=\"row in displayedCollection\">                            \r\n\t\t\t\t\t\t\t<td>{{row.Title}}</td>\r\n\t\t\t\t\t\t\t<td>\r\n\t\t\t\t\t\t\t\t<i class='fa fileIcon' ng-class='getFileTypeIconClass(row.ContentType)'></i>\r\n\t\t\t\t\t\t\t</td>\r\n\t\t\t\t\t\t\t<td>{{row.BodyLength/1000}}</td>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t</tbody>\r\n\t\t\t\t</table>\r\n\t\t\t</div>\r\n\t\t</div>\r\n\t</div>\r\n</div>\r\n<div class=\"modal-footer list-na__footer\">\r\n\t<button class=\"btn btn-primary\" type=\"button\" ng-click=\"addToMerge()\">{{labels.AddToMergeDocs}}</button>\r\n</div>\r\n"

/***/ }),
/* 27 */
/***/ (function(module, exports) {

	module.exports = "<div class='modal-header list-na__header'>\r\n\t<h3 class='modal-title'>Add Urls</h3>\r\n\t<i class='fa fa-times list-na__close' ng-click='dismiss()' aria-hidden='true'></i>\r\n</div>\r\n<div class=\"modal-body list-na__body\">\r\n  <form class='form-horizontal'>\r\n      <div class='form-group'>\r\n\t\t\t\t<ul class=\"url-list\">\r\n\t\t\t\t\t<li ng-repeat=\"linkedUrl in linkedUrls\">\r\n\t\t\t\t\t\t<div class=\"row-cont\">\r\n\t\t\t\t\t\t\t<label for='url' class='col-sm-2 control-label'>{{labels.Url}}</label>\r\n\t\t\t\t\t\t\t<div class='col-sm-10'>\r\n\t\t\t\t\t\t\t\t<input type='text' class='form-control' id='url' ng-model='linkedUrl.addedUrl'>\r\n\t\t\t\t\t\t\t\t<span class=\"email__warning\">{{labels.AddURLWarning}}</span>\r\n\t\t\t\t\t\t\t</div>\r\n\t\t\t\t\t\t</div>\r\n\t\t\t\t\t\t<div class=\"row-cont\">\r\n\t\t\t\t\t\t\t<label for='url' class='col-sm-2 control-label'>{{labels.Title}}</label>\r\n\t\t\t\t\t\t\t<div class='col-sm-10'>\r\n\t\t\t\t\t\t\t\t<input type='text' class='form-control' id='url' ng-model='linkedUrl.urlTitle'>\r\n\t\t\t\t\t\t\t</div>\r\n\t\t\t\t\t\t</div>\r\n\t\t\t\t\t</li>\r\n\t\t\t\t</ul>\r\n\t      <div class=\"secondary-action-container\">\r\n\t\t      <label class=\"col-sm-2\">&nbsp;</label>\r\n\t\t      <div class=\"col-sm-10\"><a href title='{{labels.AddAnother}}' ng-click='addLinkedUrl()'>&#43; {{labels.AddAnother}}</a></div>\r\n\t      </div>\r\n\t      <div class=\"primary-btn-container\">\r\n\t\t      <button class='btn btn-primary'\r\n\t\t              type='submit'\r\n\t\t              title='{{labels.Done}}'\r\n\t\t              ng-click='done()'>\r\n\t\t\t      {{labels.Done}}\r\n\t\t      </button>\r\n\t      </div>\r\n      </div>\r\n    </form>\r\n</div>\r\n"

/***/ }),
/* 28 */
/***/ (function(module, exports) {

	module.exports = "<div layout='column' class='attachments__content'>\r\n\r\n\t<div layout='row' class='attachments__header'>\r\n\t\t<span class=\"title\">{{vm.labels.AdditionalDocuments}}</span>\r\n\t\t<button ng-disabled='vm.collatedDocs || vm.noGeneratedDocYet' class=\"btn btn-default btn-action\" type=\"submit\" ng-click='vm.openNADialog()'>\r\n\t\t\t<i class='fa fa-plus'></i>\r\n\t\t\t<span>{{vm.labels.AddFromQuote}}</span>\r\n\t\t</button>\r\n\t\t<button ng-disabled='vm.collatedDocs || vm.noGeneratedDocYet' class=\"btn btn-default btn-action\" type=\"submit\" ng-click='vm.openUrlDialog()'>\r\n\t\t\t<i class='fa fa-plus'></i>\r\n\t\t\t<span>{{vm.labels.AddUrl}}</span>\r\n\t\t</button>\r\n\t</div>\r\n\t<div class='mergeDoc__header'>\r\n\t\t<span class='title-with-sidelines subtitle'>{{vm.labels.DocumentsToBeMerged}}</span>\r\n\t</div>\r\n\t<!-- Merge Files Drag and Drop Container -->\r\n\t<div flex ngf-drag-over-class=\"'dragover'\" class='mergeDoc__content drop-box'\r\n\t     ngf-change=\"vm.uploadLocalFiles('mergeBucket')\"\r\n\t     ng-model='vm.mergeFiles' name='files'\r\n\t     ngf-pattern=\"'.pdf,.doc,.docx'\"\r\n\t     ngf-model-invalid=\"vm.invalidFiles\"\r\n\t     ngf-before-model-change=\"vm.beforeFileUpload($files)\"\r\n\t     ngf-drop\r\n\t     ngf-keep=\"'distinct'\"\r\n\t     ngf-drag-over-class=\"'dragover'\"\r\n\t     ngf-multiple=\"true\"\r\n\t     ngf-max-size=\"4MB\"\r\n\t     ngf-drop-disabled='vm.collatedDocs || vm.noGeneratedDocYet || !vm.fileUploadSupport || vm.isMobileIos'\r\n\t>\r\n\t\t<ul dnd-list='vm.mergeFiles'\r\n\t\t    class='filelist mergefiles-list'\r\n\t\t    ng-class=\"{'collated-list': vm.collatedDocs === true}\"\r\n\t\t    dnd-dragover='vm.dragoverCallback(event, index, external, type)'\r\n\t\t    dnd-horizontal-list='true'\r\n\t\t>\r\n\t\t\t<li ng-repeat='file in vm.mergeFiles'\r\n\t\t\t    ng-if='vm.mergeFiles.length > 0'\r\n\t\t\t    dnd-draggable='file'\r\n\t\t\t    dnd-disable-if='$index === 0 || vm.collatedDocs'\r\n\t\t\t    dnd-moved='vm.reOrderFiles($index, \"merge\")'\r\n\t\t\t    dnd-effect-allowed='move'\r\n\t\t\t>\r\n\t\t\t\t<img class=\"fileIcon\" ng-src=\"{{vm.getFileTypeIconUrl(file)}}\" />\r\n\t\t\t\t<span class='fileTitle'>\r\n\t\t\t\t\t\t\t\t{{file.name}}\r\n\t\t\t\t\t\t\t\t<md-tooltip md-direction=\"right\" md-delay='1000'>\r\n\t\t\t\t\t\t\t\t  {{file.name}}\r\n\t\t\t\t\t\t\t\t</md-tooltip>\r\n\t\t\t\t\t\t\t</span>\r\n\t\t\t\t<md-progress-linear ng-if=\"file.uploadStatus == 'pending'\" class='upload-progressBar' md-mode=\"determinate\" ng-value=\"file.percentComplete\"></md-progress-linear>\r\n\t\t\t\t<i class=\"fa fa-times-circle rm-file-btn\" aria-hidden=\"true\" ng-if='$index > 0' ng-click='vm.removeFile(file, $index, \"mergeBucket\")'></i>\r\n\t\t\t</li>\r\n\t\t</ul>\r\n\t</div>\r\n\r\n\t<div layout='column' class='browse' ng-if=\"vm.fileUploadSupport && !vm.isMobileIos\">\r\n\t\t<div>\r\n\t\t\t<span class='browse__drag-drop'>{{vm.labels.DragAndDrop}}</span>\r\n\t\t</div>\r\n\t\t<div>\r\n\t\t\t<span>Or</span>\r\n\t\t\t<button type=\"button\" class=\"btn btn-link browse__btn\"\r\n\t\t\t        ngf-select\r\n\t\t\t        ngf-change=\"vm.uploadLocalFiles('mergeBucket')\"\r\n\t\t\t        ng-model='vm.mergeFiles'\r\n\t\t\t        ngf-pattern=\"'.pdf,.doc,.docx'\"\r\n\t\t\t        ngf-before-model-change=\"vm.beforeFileUpload($files)\"\r\n\t\t\t        ngf-keep=\"'distinct'\"\r\n\t\t\t        ngf-multiple=\"true\"\r\n\t\t\t        ngf-max-size=\"4MB\"\r\n\t\t\t        ng-disabled='vm.collatedDocs || vm.noGeneratedDocYet'\r\n\t\t\t>\r\n\t\t\t\t{{vm.labels.BrowseToComputer}}\r\n\t\t\t</button>\r\n\t\t</div>\r\n\t</div>\r\n</div>"

/***/ }),
/* 29 */
/***/ (function(module, exports) {

	(function() {
		'use strict';
	
		module.exports = [function() {
			return {
				restrict: "A",
				require: "ngModel",
				link: function(scope, element, attrs, ngModel) {
	
					function read() {
						ngModel.$setViewValue(element.text());
					}
	
					ngModel.$render = function() {
						return ngModel.$viewValue || "";
					};
	
					element.bind("blur keyup change", function() {
						scope.$apply(read);
					});
				}
			};
		}];
	})();


/***/ }),
/* 30 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = ['$window',
		                  '$document',
		                  '$timeout',
		                  'systemConstants', function($window, $document, $timeout, systemConstants) {
	
			function _getElementOffset(elem) {
				var documentElement;
				var window;
				var clientRectangle;
				var document;
	
				if (!elem) {
					return;
				}
	
				clientRectangle = elem.getBoundingClientRect();
	
				// Make sure element is not hidden (display: none) or disconnected
				if (clientRectangle.width || clientRectangle.height || elem.getClientRects().length) {
					window = $window;
					document = elem.ownerDocument;
					documentElement = document.documentElement;
	
					return {
						top: clientRectangle.top + window.pageYOffset - documentElement.clientTop,
						left: clientRectangle.left + window.pageXOffset - documentElement.clientLeft,
						width: clientRectangle.width,
						height: clientRectangle.height
					};
				}
			}
	
			function _getNewMenuPosition($scope, menuEl) {
				var contextElPosition;
				var newPosition;
				var clientVpHeight;
				var calculatedTop;
				var menuOffsetHeight;
				var contextEl = $scope.settings.contextElem[0];
	
				clientVpHeight = (window.innerHeight || document.documentElement.clientHeight);
	
				contextElPosition = _getElementOffset(contextEl);
	
				// set ideal new position of menu
				newPosition = {
					yBoundReached: false
				};
	
				if($scope.settings.verticalOrientation === "TopTop") {
					newPosition.top = contextElPosition.top;
				} else {
					newPosition.top = contextElPosition.top + contextEl.offsetHeight;
				}
	
				if($scope.settings.horizontalOrientation === "LeftRight") {
					// align left side of menu to right side of context element
					newPosition.left = contextElPosition.left + contextEl.offsetWidth;
				} else if($scope.settings.horizontalOrientation === "RightRight") {
					// align right side of menu to right side of context element
					newPosition.left = (contextElPosition.left - menuEl.offsetWidth) + contextEl.offsetWidth;
				} else {
					newPosition.left = contextElPosition.left;
				}
	
				menuOffsetHeight = menuEl.offsetHeight;
				newPosition.bottom = newPosition.top + menuOffsetHeight;
	
	
				// menu goes beyond bottom bound of viewport
				if (newPosition.bottom > clientVpHeight) {
	
					if($scope.settings.verticalOrientation === "TopTop") {
						calculatedTop = (contextElPosition.top - menuOffsetHeight) + contextEl.offsetHeight;
					} else {
						calculatedTop = (contextElPosition.top - menuOffsetHeight);
					}
	
					newPosition.yBoundReached = true;
	
					// subtract difference effectively moving menu up, if goes beyond upward bound then set to 0
					newPosition.top = (calculatedTop < 0 ? 0 : calculatedTop);
				}
	
				return newPosition;
			}
	
			return {
				restrict: 'EA',
				scope: {
					settings: '='
				},
				template: __webpack_require__(31),
				link: {
					post: function($scope, elem, attr) {
						var menuUl;
						var windowChangeFn;
						var updateViewModel;
	
						$scope.settings.contextElem = elem;
	
						$scope.settings.menuPosition = {
							top: 0,
							left: 0
						};
	
						$scope.settings.boxShadow = "3px 3px 5px #999";
	
						$scope.itemClicked = function (eventMethod) {
							// hide menu
							$scope.settings.expanded = false;
	
							eventMethod();
						};
	
						menuUl = elem[0].childNodes[0];
	
						var eElement = $document[0].body;
	
						// move menu UL to body
						eElement.insertBefore(menuUl, eElement.firstChild);
	
						updateViewModel = function (newPos) {
							$scope.settings.menuPosition.top = (newPos.top > 0 ? newPos.top + "px" : 0);
							$scope.settings.menuPosition.left = (newPos.left > 0 ? newPos.left + "px" : 0);
							$scope.settings.boxShadow = "3px " + (newPos.yBoundReached ? "-3px" : "3px") + " 5px #999";
						};
	
						windowChangeFn = function () {
							if (!$scope.settings.expanded) {
								return;
							}
	
							var newPos = _getNewMenuPosition($scope,
							                                 menuUl);
	
							// call $apply to notify angular of model change
							$scope.$apply(function () { updateViewModel(newPos); });
						};
	
						angular.element($window).on('DOMContentLoaded load resize', windowChangeFn);
	
						// remove events upon destruction of directive
						$scope.$on('$destroy', function () {
							angular.element($window).off('DOMContentLoaded load resize', windowChangeFn);
						});
	
						$scope.$watch('settings.expanded', function (newVal) {
							if (newVal) {
								angular.element(menuUl).removeClass('ng-hide');
								var newPos = _getNewMenuPosition($scope, menuUl);
	
								updateViewModel(newPos);
							}
						});
	
						var _idOrClassMatch = function(element, classList) {
							// now we have done the initial checks, start gathering id's and classes
							var id = element.id;
							var classNames = element.className;
	
							// Unwrap SVGAnimatedString classes
							if (angular.isDefined(classNames) && angular.isDefined(classNames.baseVal)) {
								classNames = classNames.baseVal;
							}
	
							// if there are no class names on the element clicked, skip the check
							if (classNames || id) {
								// loop through the elements id's and classnames looking for exceptions
								for (var i = 0; i < classList.length; i++) {
									//prepare regex for class word matching
									var classIdMatchingRegexExpr = new RegExp('\\b' + classList[i] + '\\b');
	
									// check for exact matches on id's or classes, but only if they exist in the first place
									if ((angular.isDefined(id) && id === classList[i]) || (classNames && classIdMatchingRegexExpr.test(
											classNames))) {
										// now let's exit out as it is an element that has been defined as being ignored for clicking outside
										return true;
									}
								}
							}
	
							return false;
						};
	
						// postpone linking to next digest to allow for unique id generation
						$timeout(function () {
							var classList = [];
	
							// default close menu events
							var closeEventsList = ["touchstart", "click"];
	
							// unique identifiers of elements that should be ignored when clicked
							if(angular.isDefined($scope.settings.closeEventsList)) {
								closeEventsList = $scope.settings.closeEventsList;
							}
	
							// unique identifiers of elements that should be ignored when clicked
							if(angular.isDefined($scope.settings.classList)) {
								classList = $scope.settings.classList;
							}
	
							function eventHandler(e) {
								var element;
	
								// check if our element already hidden and abort if so
								if (angular.element(elem).hasClass("ng-hide")) {
									return;
								}
	
								// if there is no click target, no point going on
								if (!e || !e.target) {
									return;
								}
	
	
								if(e.type === "mouseout") {
									element = (angular.isDefined(e.relatedTarget) && e.relatedTarget !== null ? e.relatedTarget : e.toElement);
	
									if(angular.isDefined(element) && element !== null && _idOrClassMatch(element, classList)) {
										return;
									}
								} else {
									// loop through the available elements, looking for classes in the class list that might match and so will eat
									for (element = e.target; element; element = element.parentNode) {
										// check if the element is the same element the directive is attached to and exit if so (props @CosticaPuntaru)
										if (element === elem[0]) {
											return;
										}
	
										if(_idOrClassMatch(element, classList)) {
											return;
										}
									}
								}
	
	
								// use apply to make angular aware of model change
								$scope.$apply(function () {
									// wrapped this within $apply
									$scope.settings.expanded = false;
								});
							}
	
							for (var i = 0; i < closeEventsList.length; i++) {
								switch(closeEventsList[i]) {
									case "touchstart":
										// if the devices has a touchscreen, listen for this event
										if (_hasTouch()) {
											$document.on('touchstart', eventHandler);
										}
										break;
									case "mouseleave":
										// mouse leave event for context element and menu
										$scope.settings.contextElem.on('mouseleave', eventHandler);
										angular.element(menuUl).on('mouseleave', eventHandler);
										break;
									case "click":
										// still listen for the click event even if there is touch to cater for touchscreen laptops
										$document.on('click', eventHandler);
										break;
								}
							}
	
							// when the scope is destroyed, clean up the documents event handlers as we don't want it hanging around
							$scope.$on('$destroy', function () {
								for (var i = 0; i < closeEventsList.length; i++) {
									switch(closeEventsList[i]) {
										case "touchstart":
											if (_hasTouch()) {
												$document.off('touchstart', eventHandler);
											}
											break;
										case "mouseleave":
											angular.element(menuUl).off('mouseleave', eventHandler);
											break;
										case "click":
											$document.off('click', eventHandler);
											break;
									}
								}
							});
	
							/**
							 * @description Private function to attempt to figure out if we are on a touch device
							 * @private
							 **/
							function _hasTouch() {
								// works on most browsers, IE10/11 and Surface
								return 'ontouchstart' in window || navigator.maxTouchPoints;
							}
						});
					}
				}
			};
	
		}];
	})();

/***/ }),
/* 31 */
/***/ (function(module, exports) {

	module.exports = "<ul class=\"context-menu-container\" ng-show=\"settings.expanded\"\r\n    ng-style=\"{left:settings.menuPosition.left,\r\n               top:settings.menuPosition.top,\r\n               boxShadow:settings.boxShadow}\">\r\n\t<li ng-repeat=\"menuItem in settings.menuItems\" ng-click=\"itemClicked(menuItem.onClick);$event.stopPropagation();\">{{menuItem.displayLabel}}</li>\r\n</ul>"

/***/ }),
/* 32 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
			return {
				restrict: 'E',
				scope: {
					settings: "=",
					value: "=",
					maxLength: "@",
					maxLengthErrorMsg: "@"
				},
				template: __webpack_require__(33),
				link: function(scope) {
					var originalValue = scope.value;
	
					var _userAction = function(currentValue, action) {
						// if validation error exists and user clicks accept trigger no action
						if(action === "accept" && scope.hasValidationError()) return;
	
						// reset value to original
						if(action == "cancel") {
							currentValue = originalValue;
							scope.value = originalValue;
						}
	
						var userEditEventInfo = {
							valueChanged: (currentValue !== originalValue),
							newValue: currentValue,
							origValue: originalValue,
							action: action
						};
	
						// if value changed update original
						if(action == "accept" && currentValue !== originalValue) {
							originalValue = currentValue;
						}
	
						return userEditEventInfo;
					};
	
					scope.maxLength = -1;
	
					if(angular.isDefined(scope.maxLength)) {
						scope.maxLength = parseInt(scope.maxLength);
					}
	
					scope.onAccept = function() {
						scope.settings.onUserAction(_userAction(scope.value, "accept"));
					};
	
					scope.onCancel = function() {
						scope.settings.onUserAction(_userAction(scope.value, "cancel"));
	
						// stop editing value
						scope.settings.editMode = false;
					};
	
					scope.hasValidationError = function() {
						if (angular.isDefined(scope.maxLength) && angular.isDefined(scope.value) && scope.maxLength > -1 && scope.value.length > scope.maxLength) {
							return true;
						}
	
						return false;
					};
				}
			};
	
		}];
	})();

/***/ }),
/* 33 */
/***/ (function(module, exports) {

	module.exports = "<span class=\"editable-text-field\">\r\n\t<span ng-show=\"!settings.editMode\">\r\n      {{value}}\r\n      <md-tooltip md-direction=\"right\" md-delay='1000'>\r\n        {{value}}\r\n      </md-tooltip>\r\n  </span>\r\n\t<div class=\"edit-view\" ng-show=\"settings.editMode\" ng-class=\"{'txt-input-error': hasValidationError()}\">\r\n\t\t<input type=\"text\"\r\n\t\t       ng-model=\"value\"\r\n\t\t       ng-keyup=\"$event.keyCode == 13 && onAccept()\"\r\n\t\t       focus-and-select=\"settings.editMode\" />\r\n\t\t<i class=\"fa fa-check\" aria-hidden=\"true\" ng-click=\"onAccept()\"></i>\r\n\t\t<i class=\"fa fa-times\" aria-hidden=\"true\" ng-click=\"onCancel()\"></i>\r\n\t</div>\r\n\t<span class=\"validation-error-msg\" ng-if=\"maxLength > -1 && value.length > maxLength\">{{maxLengthErrorMsg}}</span>\r\n</span>"

/***/ }),
/* 34 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		module.exports = [function() {
			var proposalsListController;
			emailController = function($scope,
				$uibModal,
				_,
				RemoteService,
				i18nService,
				systemConstants,
				EmailService,
				PageContainerService,
				ProposalsListService,
				PageNotificationService,
				GlobalService,
				PreviewService,
				UtilitiesService
			) {
				var vm = this;
				var tplDialogSize = 'lg';
				vm.wantToEmail = false;
				vm.showDialog = false;
	
				vm.openDialog = function() {
					PreviewService.dialogIsOpen = true;
	
					emailDialogCtrl.$inject = ['$q', '$scope', '$sce', '$uibModalInstance'];
	
					function emailDialogCtrl($q, $scope, $sce, $uibModalInstance) {
	
						$scope.emailTo = '';
						$scope.emailCC = '';
						$scope.emailBcc = '';
						$scope.subject = '';
						$scope.emailBody = '';
						$scope.mergedDocuments = [];
	
						if(EmailService.mergedDocInfo.length > 0) {
							$scope.mergedDocuments = [ EmailService.mergedDocInfo[0] ];
						}
	
						for(var i = 0; i < EmailService.mergedSourceDocsAttachInfo.length; i++) {
							$scope.mergedDocuments.push(EmailService.mergedSourceDocsAttachInfo[i]);
						}
						$scope.extraAttachments = [];
						$scope.noRecipient__added = false;
						$scope.emailTemplates = [];
						$scope.selectedEmailTpl = {TemplateType : 'text'}; // Default template type
						$scope.emailFolderList = [];
						$scope.selectedEmailFolder = {};
						$scope.isTemplateMerged = false;
						$scope.labels = i18nService.CustomLabel;
						$scope.displayedCollection = [];
						$scope.fileIsFromQA = false;
						$scope.proposalAlreadyPresented = false;
						$scope.approvalStatus = true;
						$scope.fileUploadSupport = UtilitiesService.deviceInfo.isFileInputSupported;
						$scope.isMobileIos = UtilitiesService.deviceInfo.isMobileIos;
						$scope.isProposalEmailEditingEnabled = systemConstants.docGenCustomSettings.IsProposalEmailEditingEnabled;
						$scope.origEmailSubject = '';
						$scope.origEmailBody = '';
						$scope.isActionInProgress = false;
	
						var emailSentNotificationTimeout = 5000;
						var currentProposalId = GlobalService.currentProposalId;
						var emailAttachmentsArr = EmailService.mergedDocInfo.length ?
							EmailService.mergedDocInfo :
							EmailService.mergedSourceDocsAttachInfo;
						var quoteDialogInstance = {};
						var attachExtraAttachments = [];
						var allEmailTemplates = [];
						var folderIdToEmailTemplatesMap = {};
						var emailTemplateMap = {};
						var defaultEmailTemplate = GlobalService.defaultEmailTemplate;
						$scope.proposalAlreadyPresented = GlobalService.proposalInfo.Approval_Stage__c === $scope.labels.PresentedApprovalStage;
						RemoteService.getEmailFolders().then(function(response) {
							$scope.emailFolderList = response;
							if (defaultEmailTemplate) {
								let defaultFolder = _.find(response, {Id : defaultEmailTemplate.FolderId});
								$scope.selectedEmailFolder = defaultFolder;
								_selectFolder(defaultFolder);
							}
						});
	
						// Get the attachments for the currently selected document
						RemoteService.getAttachments(currentProposalId).then(function(response) {
							$scope.rowCollection = response;
						});
	
						$scope.addToMerge = function () {
							$scope.fileIsFromQA = true;
							_.map($scope.rowCollection, function(row) {
								if (row.isSelected) {
									delete row.isSelected;
									if(angular.isDefined(attachExtraAttachments)) attachExtraAttachments.push(angular.fromJson(angular.toJson(row)));
									var object = {
										lastModified: '',
										lastModifiedDate: {},
										name: row.Title,
										size: row.BodyLength,
										type: row.ContentType,
										webkitRelativePath: ''
									};
									if(angular.isDefined($scope.extraAttachments)) $scope.extraAttachments.push(object);
								}
							});
							$scope.dismissQuoteDialog();
						};
	
						var _selectDefaultEmailTemplate = function() {
							$scope.selectedEmailTpl = $scope.emailTemplates[0];
							// pre-select default email template if available
							if (defaultEmailTemplate) {
								const existingTemplate = _.find($scope.emailTemplates, {Id : defaultEmailTemplate.Id});
								if (existingTemplate) {
									$scope.selectedEmailTpl = existingTemplate;
									$scope.emailTemplates.unshift(existingTemplate);
								}
							}
							_selectTemplate($scope.selectedEmailTpl);
							$scope.emailTemplates = _.uniq($scope.emailTemplates);
						}
	
						var _serviceFailure = function(reason) {
							// unkown error occurred
							PageNotificationService.hasPageNotification = true;
							PageNotificationService.alert = {
								type: 'danger',
								message: vm.labels.GenericServiceFailureError
							};
						};
	
						function getEmailTemplates(folderId) {
							if (folderIdToEmailTemplatesMap[folderId]) {
								return $q.when(folderIdToEmailTemplatesMap[folderId]);
							} 
							return RemoteService.getEmailTemplates(folderId);
						}
	
						function getEmailTemplate(templateId) {
							if (emailTemplateMap[templateId]) {
								return $q.when(emailTemplateMap[templateId]);
							} 
							return RemoteService.getEmailTemplate(templateId);
						}
	
						var _selectFolder = function(folder) {
							// clear selection
							$scope.selectedEmailTpl = {TemplateType : 'text'};
							$scope.emailBody = '';
							$scope.subject = '';
							$scope.emailTemplates = [];
							$scope.isActionInProgress = true;
							getEmailTemplates(folder.Id).then(function(emailTemplates) {
								if (!_.isEmpty(emailTemplates)) {
									$scope.emailTemplates = emailTemplates;
									_selectDefaultEmailTemplate();
								}
								if(!_.has(folderIdToEmailTemplatesMap, folder.Id)) {
									folderIdToEmailTemplatesMap[folder.Id] = emailTemplates;
								}
								$scope.isActionInProgress = false;
							});
						};
	
						var _selectTemplate = function(template) {
							$scope.isActionInProgress = true;
							getEmailTemplate(template.Id).then(function(emailTemplate) {
								$scope.emailBody = (angular.isDefined(emailTemplate.Body)) ? emailTemplate.Body : "";
	
								$scope.subject = (angular.isDefined(emailTemplate.Subject)) ? emailTemplate.Subject : "";
	
								// store original subject and body to detect change
								$scope.origEmailSubject = $scope.subject;
								$scope.origEmailBody = $scope.emailBody;
								$scope.isTemplateMerged = false;
								$scope.isHtmlTemplate = (emailTemplate.TemplateType.toUpperCase() !== 'TEXT');
								$scope.isActionInProgress = false;
								if(!_.has(emailTemplateMap, emailTemplate.Id)) {
									emailTemplateMap[emailTemplate.Id] = emailTemplate;
								}
							});
						};
	
						$scope.uploadExtraAttachments = function() {
							$scope.fileIsFromQA = false;
							_.map($scope.extraAttachments, function(file) {
								angular.fromJson(angular.toJson(file)); // Strip the angular internal props i.e. $$hashKey
								encodeAndUploadFileAttachment(file);
							});
						};
	
						// This function will be called per file
						function encodeAndUploadFileAttachment(file) {
							var attachmentBody;
							var reqObj = {};
							$scope.fileUploaded = false;
	
							if(angular.isUndefined(file.type))
							{
								return; // No need to upload files from Quote Attachments
							}
	
							if (file) {
								var fileReader = new FileReader();
	
								fileReader.onloadend = function(e) {
									attachmentBody = this.result.match(/,(.*)$/)[1];
									reqObj = {
										'parentId': currentProposalId,
										'attachmentName': file.name,
										'attachmentBody': attachmentBody
									};
	
									RemoteService.uploadAttachment(reqObj).then(function(response) {
										attachExtraAttachments.push(response);
										$scope.fileUploaded = true;
									});
								};
	
								fileReader.onerror = function(e) {
									// vm.filesValid = false;
									console.log('file is not valid');
								};
								fileReader.onabort = function(e) {
									console.log('file is not valid');
									// vm.filesValid = false;
								};
	
								fileReader.readAsDataURL(file); //Read the body of the file
							}
	
						}
	
						$scope.selectedTpl = function(value) {
							_selectTemplate(value);
	
						};
	
						$scope.selectedFldr = function(value) {
							_selectFolder(value);
						};
	
						$scope.emailTemplateIsSelected = function() {
							return (angular.isDefined($scope.selectedEmailTpl) && angular.isDefined($scope.selectedEmailTpl.Id) && !($scope.isTemplateMerged));
						};
	
						$scope.formHasInvalidEmail = false;
	
						var _validEmail = function(value) {
							if(!angular.isDefined(value)) return;
	
							var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
	
							var emailList = [];
	
							// remove spaces
							value = value.split(' ').join('');
	
							if(value.indexOf(";") !== -1) {
								emailList = value.split(';');
							} else {
								emailList.push(value);
							}
	
							for (var i = 0; i < emailList.length; i++) {
								var emailAddr = emailList[i];
								if(!re.test(emailAddr)) {
									return false;
								}
							}
	
							return true;
						};
	
						var _validateEmailField = function(value) {
							$scope.formHasInvalidEmail = false;
	
							if(value === "") return;
	
							$scope.formHasInvalidEmail =  !_validEmail(value);
	
						};
	
						// returns temporary template id in case of text templates
						function getEmailTemplateId(emailObj) {
							if (angular.isDefined(emailObj.emailTemplateId) 
									&& emailObj.emailTemplateFormat.toUpperCase() == 'TEXT'
									&& isEmailSubOrBodyChanged()) {							
								return RemoteService.createTempEmailTemplate(emailObj);
							}
	
							return $q.when(emailObj.emailTemplateId);
						}
						
						function isEmailSubOrBodyChanged() {
							return ($scope.emailBody != $scope.origEmailBody || $scope.subject != $scope.origEmailSubject);
						}
	
						$scope.emailToOnChange = function() {
							if($scope.emailTo === "") {
								$scope.noRecipient__added = true;
								return;
							}
	
							_validateEmailField($scope.emailTo);
						};
	
						$scope.emailCcOnChange = function() {
							_validateEmailField($scope.emailCC);
						};
	
						$scope.emailBccOnChange = function() {
							_validateEmailField($scope.emailBcc);
						};
	
						RemoteService.getDefaultContact(currentProposalId).then
						(
							function(response) {
								if (response && response.Email) {
									$scope.emailTo += response.Email;
								}
							},
							function(reason) {
								console.log(reason);
							}
						);
	
						if(emailAttachmentsArr.length) {
							_.map(emailAttachmentsArr, function(obj, index) {
								emailAttachmentsArr[index] = angular.fromJson(angular.toJson(obj)); // Strip the angular internal props i.e. $$hashKey
							});
						}
	
						$scope.getFileTypeIconUrl = function(type) {
							return GlobalService.getFileTypeIconUrl({ type: type });
						};
	
						$scope.sendEmail = function() {
							// validate all email values
							_validateEmailField($scope.emailTo);
							if($scope.formHasInvalidEmail) return;
	
							_validateEmailField($scope.emailCC);
							if($scope.formHasInvalidEmail) return;
	
							_validateEmailField($scope.emailBcc);
							if($scope.formHasInvalidEmail) return;
	
							if($scope.emailTo === '') {
								$scope.noRecipient__added = true;
								return;
							}
	
							var emailTo = $scope.emailTo.split(';');
							var emailCC = $scope.emailCC !== '' ? $scope.emailCC.split(';') : [];
							var emailBcc = $scope.emailBcc !== '' ? $scope.emailBcc.split(';') : [];
							if(attachExtraAttachments.length) {
								_.map(attachExtraAttachments, function (file) {
									emailAttachmentsArr.push(file);
								});
							}
	
							var attachments = [];
							if(emailAttachmentsArr.length) {
								_.map(emailAttachmentsArr, function (file) {
									var newInst = file;
	
									// remove these objects as they will not be recognized by server.
									delete newInst.contextMenu;
									delete newInst.editableFieldSettings;
	
									attachments.push(newInst);
								});
							}
	
							var emailObj = {
								'emailTo': emailTo,
								'emailCc': emailCC,
								'emailBcc': emailBcc,
								'emailSubject': $scope.subject,
								'emailTemplateId': null,
								'attachmentInfoList': attachments,
								'proposalId': currentProposalId,
								'makePresented': $scope.approvalStatus
							};
	
							emailObj.emailBody = ($scope.isTemplateMerged && $scope.selectedEmailTpl.TemplateType !== 'text')
												 ? $sce.getTrustedHtml($scope.emailBody) : $scope.emailBody;
	
							if(angular.isDefined($scope.selectedEmailTpl.TemplateType)) {
								emailObj.emailTemplateFormat = $scope.selectedEmailTpl.TemplateType.toUpperCase();
							}
	
							if (!$scope.isTemplateMerged) {
								emailObj.emailTemplateId = $scope.selectedEmailTpl.Id;
							}
							
							emailObj.emailSubject = $scope.subject;
							$scope.isActionInProgress = true;
							const dataPromise = getEmailTemplateId(emailObj);
	
							dataPromise.then((emailTemplateId) => {
								emailObj.emailTemplateId = emailTemplateId;
								RemoteService.sendEmail(emailObj).then(
									function(response) {
										if(response) {
											attachExtraAttachments = [];
											PageNotificationService.hasPageNotification = true;
											PageNotificationService.alert = {
												type: 'success',
												message: $scope.labels.EmailSentNotification,
												timeout: emailSentNotificationTimeout
											};
										} else {
											// unkown error occurred
											PageNotificationService.hasPageNotification = true;
											PageNotificationService.alert = {
												type: 'danger',
												message: $scope.labels.GenericServiceFailureError
											};
										}
										deleteEmailTemplate(emailTemplateId);
										$scope.isActionInProgress = false;
									},
									function(reason) {
										console.log('reason: ' + reason);
										$scope.isActionInProgress = false;
									}								
								);
							});
							$scope.close();
						};
	
						$scope.populateEmailContent = function() {
	
							var emailObj = {
								'emailTemplateId': $scope.selectedEmailTpl.Id,
								'emailTemplateFormat': $scope.selectedEmailTpl.TemplateType,
								'proposalId': currentProposalId,
								'emailBody' : $scope.emailBody,
								'emailSubject' : $scope.subject
							};
							$scope.isActionInProgress = true;
							const dataPromise = getEmailTemplateId(emailObj);						
							dataPromise.then((emailTemplateId) => {
								emailObj.emailTemplateId = emailTemplateId;
								RemoteService.populateEmailContent(emailObj).then(
									function(response) {
										if(!angular.isDefined(response.emailBody) && !angular.isDefined(response.emailSubject)) {
											// user chose no email template
											$scope.emailBody = "";
											$scope.subject = "";
										} else {
											$scope.isTemplateMerged = true;
											$scope.emailBody = ($scope.selectedEmailTpl.TemplateType == 'HTML')
																? $sce.trustAsHtml(response.emailBody)
																: response.emailBody;
											$scope.subject = response.emailSubject;										
										}
										$scope.origEmailSubject = $scope.subject;
										$scope.origEmailBody = $scope.emailBody;
										deleteEmailTemplate(emailTemplateId);
										$scope.isActionInProgress = false;
									},
									function(reason) {
										console.log('reason: ' + reason);
										$scope.isActionInProgress = false;
									}
								);
							});
						};
	
						function deleteEmailTemplate(emailTemplateId) {
							// only delete temporary email template
							if (emailTemplateId && emailTemplateId != $scope.selectedEmailTpl.Id) {
								RemoteService.deleteEmailTemplate(emailTemplateId);
							}
						}
	
						// Remove file
						$scope.removeFile = function(file, idx) {
							// Remove from the view
							_.remove($scope.extraAttachments, function(obj) {
								return obj.name === file.name;
							});
							_.remove(attachExtraAttachments, function(obj) {
								return obj.Title === file.name;
							});
						};
	
						// The following is the scope of the select template popup
						$scope.dismiss = function() {
							EmailService.wantToEmail = false;
							PreviewService.dialogIsOpen = false;
							$uibModalInstance.dismiss('cancel');
						};
	
						// Dismiss the sub-dialog of quote attachments
						$scope.dismissQuoteDialog = function () {
							quoteDialogInstance.dismiss('dismiss');
						};
	
						$scope.close = function() {
							EmailService.wantToEmail = false;
							PreviewService.dialogIsOpen = false;
							$uibModalInstance.dismiss('cancel');
						};
	
						$scope.openQuoteDialog = function() {
							$scope.displayedCollection = [];
							RemoteService.getAttachments(currentProposalId).then(function(response) {
								$scope.rowCollection = response;
							});
						};
	
	
						$scope.openNADialog = function() {
	
							quoteDialogInstance = $uibModal.open({
								                                     backdrop: 'static',
								                                     animation: true,
								                                     template: __webpack_require__(35),
								                                     size: tplDialogSize,
								                                     keyboard: false,
								                                     scope: $scope
							                                     });
						};
					}
	
					var dialogInstance = $uibModal.open({
						backdrop: 'static',
						animation: $scope.animationsEnabled,
						size: tplDialogSize,
						template: __webpack_require__(36),
						keyboard: false,
						controllerAs: 'parentDialog',
						bindToController: true,
						controller: emailDialogCtrl
					});
	
				};
	
				var deregisterWatch1 = $scope.$watch(function() {
						return EmailService.wantToEmail;
					},
					function(newVal, oldVal) {
						if (newVal === true) {
							vm.wantToEmail = newVal;
							vm.openDialog();
						}
					}
				);
	
				$scope.$on('$destroy', function() {
					deregisterWatch1();
				});
	
			};
	
			emailController.$inject = ['$scope',
				'$uibModal',
				'lodash',
				'RemoteService',
				'i18nService',
				'systemConstants',
				'EmailService',
				'PageContainerService',
				'ProposalsListService',
				'PageNotificationService',
				'GlobalService',
				'PreviewService',
				'UtilitiesService'
			];
	
			return {
				restrict: 'E',
				controller: emailController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: '<div></div>'
			};
		}];
	})();


/***/ }),
/* 35 */
/***/ (function(module, exports) {

	module.exports = "<div class='modal-header list-na__header'>\r\n\t<h3 class='modal-title'>{{labels.QuoteAttachments}}</h3>\r\n\t<i class='fa fa-times list-na__close' ng-click='dismissQuoteDialog()' aria-hidden='true'></i>\r\n</div>\r\n<div class=\"modal-body list-na__body\">\r\n\t<div class='templates'>\r\n\t\t<!-- <div class='templates__search'></div> -->\r\n\t\t<div class='templates__table'>\r\n\t\t\t<div>\r\n\t\t\t\t<table st-table=\"displayedCollection\" st-safe-src='rowCollection' class='table'>\r\n\t\t\t\t\t<thead>\r\n\t\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t\t<th colspan=\"2\" class='searchable'>\r\n\t\t\t\t\t\t\t\t<div class='searchbar'>\r\n\t\t\t\t\t\t\t\t\t<i class=\"fa fa-search\"></i>\r\n\t\t\t\t\t\t\t\t\t<input st-search='' class=\"form-control\" placeholder=\"{{labels.Search}}\" type=\"text\" />\r\n\t\t\t\t\t\t\t\t</div>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t\t<th st-sort=\"Name\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.DocumentName}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t\t<th st-sort=\"Name\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.DocumentType}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t\t<th st-sort=\"BodyLength\" class='sortable'>\r\n\t\t\t\t\t\t\t\t<span>{{labels.SizeKB}}</span>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t\t<i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n\t\t\t\t\t\t\t</th>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t</thead>\r\n\t\t\t\t\t<tbody>\r\n\t\t\t\t\t\t<tr ng-if='displayedCollection.length === 0'>\r\n\t\t\t\t\t\t\t<td>{{labels.NoAttachmentsToDisplay}}</td>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t\t<tr st-select-row=\"row\" st-select-mode=\"multi\" ng-repeat=\"row in displayedCollection\">\r\n\t\t\t\t\t\t\t<td>{{row.Title}}</td>\r\n\t\t\t\t\t\t\t<td>\r\n\t\t\t\t\t\t\t\t<i class='fa fileIcon' ng-class='getFileTypeIconClass(row.ContentType)'></i>\r\n\t\t\t\t\t\t\t</td>\r\n\t\t\t\t\t\t\t<td>{{row.BodyLength/1000}}</td>\r\n\t\t\t\t\t\t</tr>\r\n\t\t\t\t\t</tbody>\r\n\t\t\t\t</table>\r\n\t\t\t</div>\r\n\t\t</div>\r\n\t</div>\r\n</div>\r\n<div class=\"modal-footer list-na__footer\">\r\n\t<button class=\"btn btn-primary\" type=\"button\" ng-click=\"addToMerge()\">{{labels.AttachToEmail}}</button>\r\n</div>\r\n"

/***/ }),
/* 36 */
/***/ (function(module, exports) {

	module.exports = "<div class='modal-header dialog-header'>\r\n    <h3 class='modal-title'>{{labels.SendEmail}}</h3>\r\n    <i class='fa fa-times modal-dismiss-btn' ng-click='dismiss()' aria-hidden='true'></i>\r\n</div>\r\n<div class='modal-body dialog-body'>\r\n    <!-- Email To, From, cc, Bcc, Subject goes here -->\r\n    <div class='email__header'>\r\n        <!-- Search and list the available templates -->\r\n        <form class='form-horizontal'>\r\n            <div class='form-group'>\r\n                <label for='toAddress' class='col-sm-4 control-label'>{{labels.To}}</label>\r\n                <div class='col-sm-7'>\r\n                    <input type='text' class='form-control' id='toAddress' ng-model='emailTo' ng-change=\"emailToOnChange()\">\r\n                </div>\r\n                <div class='col-sm-2'>\r\n                    <a class='links' ng-click='isCCDivOpen = !isCCDivOpen'>{{labels.CC}}</a>\r\n                    <a class='links' ng-click='isBCCDivOpen = !isBCCDivOpen'>{{labels.BCC}}</a>\r\n                    <span ng-show=\"fileUploadSupport && !isMobileIos\">\r\n                        <i class=\"fa fa-paperclip attachMoreFiles\"\r\n                           ng-model='extraAttachments'\r\n                           ngf-change=\"uploadExtraAttachments()\"\r\n                           ngf-select\r\n                           ngf-multiple=\"true\"\r\n                           ngf-max-size=\"4MB\"\r\n                           ngf-keep=\"'distinct'\"\r\n                           aria-hidden=\"true\"\r\n                           title='{{labels.BrowseToComputer}}'>\r\n                        </i>\r\n                    </span>\r\n\r\n                    <button class='btn btn-link'\r\n                        title='{{labels.AddFromQuote}}'\r\n                        ng-click='openNADialog()'>\r\n                        {{labels.AddFromQuote}}\r\n                    </button>\r\n                </div>\r\n            </div>\r\n            <form class='form-horizontal'>\r\n                <div class='form-group'>\r\n                    <label for='sel1' class='col-sm-4 control-label'>{{labels.SelectEmailFolder}}</label>\r\n                    <div class='col-sm-7'>\r\n                        <select class='form-control'\r\n                            id='sel1'\r\n                            ng-model='selectedEmailFolder'\r\n                            ng-options='folder.Name for folder in emailFolderList'\r\n                            ng-change=\"selectedFldr(selectedEmailFolder)\"\r\n                            ng-disabled=\"isActionInProgress\"\r\n                        >\r\n                        </select>\r\n                    </div>\r\n                </div>\r\n\r\n                <form class='form-horizontal'>\r\n                    <div class='form-group'>\r\n                        <label for='sel2' class='col-sm-4 control-label'>{{labels.SelectEmailTemplate}}</label>\r\n                        <div class='col-sm-7'>\r\n                            <select class='form-control'\r\n                                id='sel2'\r\n                                ng-model='selectedEmailTpl'\r\n                                ng-options='emailTemplate.Name for emailTemplate in emailTemplates'\r\n                                ng-change=\"selectedTpl(selectedEmailTpl)\"\r\n                                ng-disabled=\"isActionInProgress\"\r\n                            >\r\n                            </select>\r\n                        </div>\r\n                    </div>\r\n                <div ng-if='selectedEmailTpl.TemplateType != \"text\"' class='form-group'>\r\n                    <label for='subjectLine' class='col-sm-4 control-label'>&nbsp;</label>\r\n                    <div class='col-sm-7'>\r\n                        <span class=\"email__warning\">{{labels.SubjectLineAndEmailBodyDisabledSelectedTemplate}}</span>\r\n                    </div>\r\n                </div>\r\n                <div class='form-group'>\r\n                    <label for='subjectLine' class='col-sm-4 control-label'>{{labels.Subject}}</label>\r\n                    <div class='col-sm-7'>\r\n                        <input type='text' ng-disabled='selectedEmailTpl.TemplateType != \"text\"' class='form-control' id='subjectLine' ng-model='subject'>\r\n                    </div>\r\n                </div>\r\n                <div class='form-group' ng-show='isCCDivOpen'>\r\n                    <label for='ccAddress' class='col-sm-4 control-label'>{{labels.CC}}</label>\r\n                    <div class='col-sm-7'>\r\n                        <input type='text' class='form-control' id='ccAddress' ng-model='emailCC' ng-change=\"emailCcOnChange()\">\r\n                    </div>\r\n                </div>\r\n                <div class='form-group' ng-show='isBCCDivOpen'>\r\n                    <label for='bccAddress' class='col-sm-4 control-label'>{{labels.BCC}}</label>\r\n                    <div class='col-sm-7'>\r\n                        <input type=\"text\" class='form-control' id='bccAddress' ng-model='emailBcc' ng-change=\"emailBccOnChange()\">\r\n                    </div>\r\n                </div>\r\n                <div class='form-group'>\r\n                    <label for='approval-status' class='col-sm-4 control-label'>{{labels.MarkProposalAsPresented}}</label>\r\n                    <div class='col-sm-7'>\r\n                        <input type='checkbox' ng-disabled='proposalAlreadyPresented' class='form-control check-control' id='approval-status' ng-model='approvalStatus' aria-label='Mark Proposal as presented'>\r\n                    </div>\r\n                </div>\r\n            </form>\r\n        </form>\r\n    </div>\r\n    <div class='email__body'>\r\n        <div ng-if='noRecipient__added' class='email__error'>{{labels.EmailRecipientError}}</div>\r\n        <div ng-show='formHasInvalidEmail' class='email__error'>{{labels.InvalidEmail}}</div>\r\n        <div class=\"form-group\">\r\n            <div id='emailBody'>\r\n                <textarea ng-if=\"!isHtmlTemplate\"\r\n                    class='email__text'\r\n                    ng-disabled='selectedEmailTpl.TemplateType != \"text\"'\r\n                    ng-model='$parent.emailBody'>\r\n                </textarea>\r\n                <div class='email__text' \r\n                    ng-if=\"isHtmlTemplate\"\r\n                    ng-bind-html='emailBody'>\r\n                </div>                      \r\n            </div>  \r\n            <div class='modal-footer sel-tpl__footer'>\r\n                <button ng-hide='customURL' class='btn btn-primary' type='button' ng-disabled=\"isActionInProgress\" ng-click='populateEmailContent();'>{{labels.MergeFields}}</button>\r\n            </div>\r\n            <div class='attachments email__attachments' ng-if='mergedDocuments.length > 0'>\r\n                <div class='heading'>{{labels.Attachments}}</div>\r\n                <div class='body'>\r\n                    <ul class='list'>\r\n                        <li ng-repeat='file in mergedDocuments track by $index'>\r\n                            <img class=\"fileIcon\" ng-src=\"{{getFileTypeIconUrl(file.ContentType)}}\" />\r\n                            <span class='fileTitle'>{{file.Title}}</span>\r\n                        </li>\r\n                    </ul>\r\n                </div>\r\n            </div>\r\n            <div class='attachments email__extraFiles' ng-if='extraAttachments.length > 0'>\r\n                <div class='heading'>{{labels.AdditionalDocuments}}</div>\r\n                <div class='body'>\r\n                    <ul class='list extraList'>\r\n                        <li ng-repeat='file in extraAttachments'>\r\n                            <img class=\"fileIcon\" ng-src=\"{{getFileTypeIconUrl(file.type)}}\" />\r\n                            <span class='fileTitle'>{{file.name}}</span>\r\n                            <md-progress-linear ng-if='!fileUploaded && !fileIsFromQA' class='upload-progressBar' md-mode=\"indeterminate\" value=\"10\"></md-progress-linear>\r\n                            <i class=\"fa fa-times-circle rm-file-btn\" aria-hidden=\"true\" ng-if='fileUploaded || fileIsFromQA' ng-click='removeFile(file, $index)'></i>\r\n                        </li>\r\n                    </ul>\r\n                </div>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n<div class='modal-footer sel-tpl__footer'>\r\n    <button ng-hide='customURL' class='btn btn-primary' ng-disabled=\"isActionInProgress\" type='button' ng-click='sendEmail();'>{{labels.Send}}</button>\r\n</div>\r\n"

/***/ }),
/* 37 */
/***/ (function(module, exports) {

	(function() {
		'use strict';
		module.exports = ['$window',
		                  '$timeout', function($window, $timeout) {
				return {
					restrict: 'A',
					scope: {
						trigger: "=focusAndSelect"
					},
					link: function(scope, element) {
						scope.$watch('trigger', function(value) {
							if (value) {
								$timeout(function() {
									// set focus to the element
									var elem = element[0];
									elem.focus();
	
									// highlight/select text
									if (!$window.getSelection().toString()) {
										// Required for mobile Safari
										elem.setSelectionRange(0, elem.value.length);
									}
								});
							}
						});
					}
				};
	
			}];
	})();

/***/ }),
/* 38 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
	
			var globalHeaderController;
	
			globalHeaderController = function(i18nService, GlobalService, RemoteService) {
				//Extracts only menu related infos from all modules config
				var vm = this;
				var currentProposalInfo = {};
				var currentProposalId = GlobalService.currentProposalId;
				var nsPrefix = GlobalService.nameSpacePrefix;
				vm.labels = i18nService.CustomLabel;
	
				RemoteService.getProposalInfo(currentProposalId).then(function(response) {
					currentProposalInfo = response;
					var proposalFieldName = currentProposalInfo[nsPrefix + 'Proposal_Name__c'] || '';
					vm.currentProposalName = vm.labels.ProposalTitle + ' ' +  proposalFieldName;
					GlobalService.proposalInfo = response;	
				});
				if (GlobalService.defaultTemplateName) {
					RemoteService.getDefaultEmailTemplate().then(function(response) {
						GlobalService.defaultEmailTemplate = response;
					});
				}			
			};
	
			globalHeaderController.$inject = ['i18nService' ,'GlobalService', 'RemoteService'];
	
			return {
				restrict: 'E',
				replace: true,
				controller: globalHeaderController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(39)
			};
	
		}];
	})();

/***/ }),
/* 39 */
/***/ (function(module, exports) {

	module.exports = "<div class=\"global-header-container layout-row\">\r\n    <div class='global-header-container__left-block'>\r\n    \t<div class='global-header-container__proposal'>\r\n    \t\t<span class='container__proposal-name'>{{vm.currentProposalName}}</span>\r\n    \t</div>\r\n    </div>    \r\n</div>\r\n"

/***/ }),
/* 40 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
	
			var globalSubHeaderController;
	
			globalSubHeaderController = function(i18nService, systemConstants, GlobalService) {
				//Extracts only menu related infos from all modules config
				var vm = this;
				var currentContext = GlobalService.currentContext;
				var cartStatus = '';
				var configRequestId = '';
				var productConfigId = '';
				var flow = '';
				var launchState = '';
				var cartBaseUrl = '';
				var prefixOrigin = GlobalService.baseSFurl.replace('apttus-proposal', 'apttus-config2');
				var isCommunitiesUser = systemConstants.docGenCustomSettings.IsCommunitiesUser;
				var proposalRecordUrl = (isCommunitiesUser)
											? window.location.pathname.split('apex')[0] + GlobalService.currentProposalId // get the community name in the URL.
											: '/' + GlobalService.currentProposalId;
				
	
				vm.labels = i18nService.CustomLabel;
				vm.redirectTo = redirectTo;
	
				if(currentContext.toLowerCase() === 'cart') {
					cartStatus = systemConstants.cartStatusParam;
					configRequestId = systemConstants.configRequestParam;
					productConfigId = systemConstants.productConfigParam;
					flow = systemConstants.cartFlowParam;
					launchState = systemConstants.launchStateParam;
					cartBaseUrl = prefixOrigin + '/apex/Cart' + '?cartStatus=' + cartStatus + '&configRequestId=' + configRequestId + '&id=' + productConfigId + '&flow=' + flow + '&launchState=' + launchState;
				}
	
				var fromQuotePageLinks = [
					{
						url: proposalRecordUrl,
						text: vm.labels.GoToProposal
					}
				];
	
				var fromCartPageLinks = [
					{
						url: cartBaseUrl + '#/cart',
						text: vm.labels.GoToPricing
					},
					{
						url: cartBaseUrl + '#!/catalog',
						text: vm.labels.AddMoreProducts
					},
					{
						url: proposalRecordUrl,
						text: vm.labels.GoToProposal
					}
				];
	
				if(currentContext !== 'proposal' && systemConstants.docGenCustomSettings.IsAssetEnabled) {
					fromCartPageLinks.splice(2,
											0,
											{
												url: cartBaseUrl + '#!/assetsgrid',
												text: vm.labels.InstalledProducts
											});
				}
	
				vm.actionBtns = (currentContext === 'proposal') ? fromQuotePageLinks : fromCartPageLinks;
	
				/**
				 * @param url
				 */
				function redirectTo(url) {
					if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
						sforce.one.navigateToURL(url);
					} else {
						window.location.href = url;
					}
				}
			};
	
			globalSubHeaderController.$inject = ['i18nService', 'systemConstants', 'GlobalService'];
	
			return {
				restrict: 'E',
				replace: true,
				controller: globalSubHeaderController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(41)
			};
	
		}];
	})();


/***/ }),
/* 41 */
/***/ (function(module, exports) {

	module.exports = "<div class=\"global-sub-header-container layout-row\">\r\n\t<div class='global-sub-header-container__left-block'>\r\n\t\t<div class='global-sub-header-container__buttons'>\r\n\t\t\t<button class=\"btn btn-default btn-action global-sub-header-container__buttons-btn\" ng-repeat='btnName in vm.actionBtns' ng-click='vm.redirectTo(btnName.url)'>{{btnName.text}}</button>\r\n\t\t</div>\r\n\t</div>\r\n</div>"

/***/ }),
/* 42 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
	
			var pageContainerController;
	
			pageContainerController = function($scope) {
				//And the code goes like this			
			};
	
			pageContainerController.$inject = ['$scope'];
	
			return {
				restrict: 'E',
				replace: true,
				controller: pageContainerController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(43)
			};
	
		}];
	})();

/***/ }),
/* 43 */
/***/ (function(module, exports) {

	module.exports = "<div class=\"page-container\" layout='row' flex layout-margin layout-fill>\r\n    <proposals-list class=\"proposals-list\" flex='30'></proposals-list>\r\n    <div layout='row' flex='70' class='page-container__doc'>\r\n        <attachments flex='40'></attachments>\r\n        <preview flex='60'></preview>\r\n    </div>\r\n</div>"

/***/ }),
/* 44 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = [function() {
	
			var pageNotificationController;
	
			pageNotificationController = function($scope,
												  GlobalService,
												  PageNotificationService,
												  i18nService,
												  $window) {
				var vm = this;
				var isCommunitiesUser = systemConstants.docGenCustomSettings.IsCommunitiesUser;
				var proposalRecordUrl = (isCommunitiesUser) ? window.location.pathname.split('apex')[0] + GlobalService.currentProposalId : '/' + GlobalService.currentProposalId;
				vm.labels = i18nService.CustomLabel;
				vm.alert = PageNotificationService.alert;
	
				vm.closeAlert = function() {
					vm.hasNotification = false;
					PageNotificationService.hasPageNotification = false;
					PageNotificationService.alert = {};
				};
	
				/**
				 * @param url
				 */
				vm.redirectTo = function() {
					if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
						sforce.one.navigateToURL(proposalRecordUrl);
					} else {
						$window.location.href = proposalRecordUrl;
					}
				};
	
				var deregisterWatch1 = $scope.$watch(function() {
						return PageNotificationService.hasPageNotification;
					},
					function(newVal, oldVal) {
						if (newVal === true) {
							vm.hasNotification = newVal;
							vm.alert = PageNotificationService.alert;
						}
						else if (newVal === false) {
							vm.closeAlert();
						}
					}
				);
	
				$scope.$on('$destroy', function() {
					deregisterWatch1();
				});
			};
	
			pageNotificationController.$inject = ['$scope',
												  'GlobalService',
												  'PageNotificationService',
												  'i18nService',
												  '$window'
												 ];
	
			return {
				restrict: 'E',
				controller: pageNotificationController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(45)
			};
	
		}];
	})();


/***/ }),
/* 45 */
/***/ (function(module, exports) {

	module.exports = "<div uib-alert type='{{vm.alert.type}}' class='alert' ng-if='vm.hasNotification' dismiss-on-timeout='{{vm.alert.timeout}}' close='vm.closeAlert()'>{{vm.alert.message}}\r\n\t<a href=\"\" ng-if='vm.hasNotification && vm.alert.message == vm.labels.PreviewNotAvailableForFiles' ng-click='vm.redirectTo()'>{{vm.labels.GoToProposal}}</a>\r\n</div>"

/***/ }),
/* 46 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		module.exports = [function() {
			var proposalsListController;
			proposalsListController = function($scope,
			                                   $timeout,
												$sce,
												$filter,
												$uibModal,
												_,
												RemoteService,
												i18nService,
	                                            systemConstants,
												ProposalsListService,
												PreviewService,
												EmailService,
												PageNotificationService,
												PageContainerService,
												GlobalService) {
				var vm = this;
				var currentProposalId = GlobalService.currentProposalId;
				var proposalType = 'proposal';
				var tplDialogSize = 'lg';
				var nsPrefix = GlobalService.nameSpacePrefix || '';
	
				vm.labels = i18nService.CustomLabel;
				vm.currentProposalList = {};
				vm.selectedProposalDocIndex = {};
				vm.selectedTemplateId = '';
				vm.proposalListTitles = [];
				vm.listedResultsLimit = 1;
	
				// setup maximum length error message
				vm.MaximumCharacterLengthMessage = vm.labels.MaximumNumberOfCharacters.replace("{0}", 80);
				vm.defaultTemplateSpinnerText = vm.labels.DocumentGenerationInProgress;
	
				var customSettings = systemConstants.docGenCustomSettings;
				var mergeTimeout = customSettings.MergeCallTimeoutMillis || 5000;
				var submitDocGenTimeout = 5000;
	
				var _serviceFailure = function(reason) {
					// unkown error occurred
					PageNotificationService.hasPageNotification = true;
					PageNotificationService.alert = {
						type: 'danger',
						message: vm.labels.GenericServiceFailureError
					};
				};
	
				RemoteService.getFastDocGenDetails(currentProposalId).then(function(response) {
					if(response.isFastDocGen) {
						// flag to disable Create New Proposal button
						vm.isFastDocGen = true;
	
						var docGenerationSpecs = {
							selectedTemplateId: response.defaultTemplateId,
							currentProposalId: currentProposalId,
							selectedOPFormat: response.outputFormat,
							watermark: response.hasWatermark
						};
	
						_generateDoc(docGenerationSpecs, mergeTimeout).then(function(response, state){
							if(state === "success" || state === "failure") {
								vm.isFastDocGen = false;
							}
						});
					} else if(GlobalService.currentContext === 'cart') {
						vm.openDialog();
					}
				});
	
				var _generateDoc = function(obj, timeout) {
					var timeInMs = 0,
						timeoutFlag = true;
	
					timeout = (angular.isDefined(timeout) ? timeout : 5000); // default to 3s
	
					return {
						then: function(callback) {
							RemoteService.createDocumentCollateInfo().then(function(documentCollateInfoId) {
								var generateDocReq = {
									'templateId': obj.selectedTemplateId,
									'proposalId': obj.currentProposalId,
									'pLevel': 'Full access',
									'docFormat': obj.selectedOPFormat,
									'isDraft': obj.watermark,
									'documentCollateInfoId': documentCollateInfoId
								};
	
								// Timeout the loading circle and close the dialog
								var countUp = function() {
									timeInMs += 500;
	
									// if document goes over timeout setting display message to user that the document is being
									// generated and will be available shortly
									if(timeInMs >= timeout) {
										if(timeoutFlag !== true) {
											return;
										}
										// perform timout action (display messsage etc)
										PageNotificationService.hasPageNotification = true;
										PageNotificationService.alert = {
											type: 'success',
											message: vm.labels.MergeCallTimeout
										};
										callback(null, "timeout");
									}
									else {
										$timeout(countUp, 500);
									}
								};
	
								$timeout(countUp, 500);
	
								RemoteService.generateDoc(generateDocReq).then(
									function(response) {
										ProposalsListService.populateProposalList();
										timeoutFlag = false;
										if (PageNotificationService.hasPageNotification) {
											PageNotificationService.hasPageNotification = false;
										}
	
										// document successfully generated
										callback(response, "success");
									},
									function(reason) {
										// unkown error occurred
										PageNotificationService.hasPageNotification = true;
										PageNotificationService.alert = {
											type: 'warning',
											message: reason.message
										};
										callback(reason, "failure");
									}
								);
	
							});
						}
					};
	
				};
	
				vm.openDialog = function() {
					PreviewService.dialogIsOpen = true;
	
					proposalPopupDialogCtrl.$inject = ['$scope', '$timeout', '$uibModalInstance', 'i18nService'];
	
					function proposalPopupDialogCtrl($scope, $timeout, $uibModalInstance, i18nService) {
	
						// The following is the scope of the select template popup
						$scope.loading = false;
						$scope.spinnerText = '';
						$scope.outputFormats = ['DOCX','DOC','PDF'];
						$scope.displayCollection = [];
						$scope.customURL = '';
						$scope.tplSelected = false;
						$scope.IsSubmitCallEnabled = customSettings.IsSubmitCallEnabled;
						$scope.labels = i18nService.CustomLabel;
						$scope.selectedOPFormat = '';
	
						var tplDO = {
							'proposalId': currentProposalId,
							'proposalType': proposalType
						};
	
						if (!customSettings.CustomDocGenURL) {
							RemoteService.getAvailableTemplates(tplDO).then(function(response) {
								//params.availableTemplates = response;
								$scope.rowCollection = response;
								$scope.displayCollection = [].concat($scope.rowCollection);
							});
						} else {
							var builtUrl = customSettings.CustomDocGenURL + '?' + 'context=' +
								GlobalService.currentContext + '&name=' +
								GlobalService.currentProposalName + '&id=' +
								GlobalService.currentProposalId;
	
							$scope.customURL = $sce.trustAsResourceUrl(builtUrl);
						}
	
						RemoteService.getDefaultOutputFormat(currentProposalId).then(function(response) {
							if (response) {
								var defaultFormat = response[nsPrefix + 'Output_Format__c'];
								$scope.watermark = response[nsPrefix + 'IncludeWatermark__c'];
								$scope.allowedOverRideWmark = response[nsPrefix + 'AllowOverrideWatermark__c'];
								$scope.allowOverRideFormat = response[nsPrefix + 'Allow_Override__c'];
								if(angular.isDefined(defaultFormat)) {
									$scope.outputFormats.unshift(defaultFormat);
								}
								$scope.outputFormats = _.uniq($scope.outputFormats);
								$scope.selectedOPFormat = $scope.outputFormats[0];
							} else {
								$scope.selectedOPFormat = ProposalsListService.defaultOutputFormat;
								$scope.allowOverRideFormat = true;
								$scope.watermark = false;
							}
						});
	
						$scope.getters = {
							templateName: function(value) {
								//this will sort by the length of the first name string
								return value.Name;
							}
						};
	
						$scope.selectedFormat = function(value) {
							$scope.selectedOPFormat = value;
						};
	
						$scope.isDraft = function(bool) {
							$scope.watermark = bool;
						};
	
						$scope.dismiss = function() {
							$uibModalInstance.dismiss('cancel');
							PreviewService.dialogIsOpen = false;
						};
	
						$scope.closeWithCustomTpl = function() {
							$uibModalInstance.close(ProposalsListService.populateProposalList());
							PreviewService.dialogIsOpen = false;
						};
	
						$scope.trustSrc = function(src) {
							return $sce.trustAsResourceUrl(src);
						};
	
						$scope.generateDoc = function() {
							$scope.rowCollection.filter(function(row) {
								if (row.isSelected) {
									vm.selectedTemplateId = row.Id;
								}
							});
	
							var docGenerationSpecs = {
								selectedTemplateId: vm.selectedTemplateId,
								currentProposalId: currentProposalId,
								selectedOPFormat: $scope.selectedOPFormat,
								watermark: $scope.watermark
							};
	
							$scope.loading = true;
							$scope.spinnerText = vm.labels.DocumentGenerationInProgress;
	
							_generateDoc(docGenerationSpecs, mergeTimeout).then(function(response, state){
								if(state === "success") {
									$scope.attachmentInfo = response;
									$scope.dismiss();
									$scope.loading = false;
								} else if(state === "timeout") {
									// perform timout action (display messsage etc)
									$scope.loading = false;
									$scope.dismiss();
								} else if(state === "failure") {
									$scope.loading = false;
								}
							});
						};
	
						$scope.submitGenerateDoc = function() {
							$scope.rowCollection.filter(function(row) {
								if (row.isSelected) {
									vm.selectedTemplateId = row.Id;
								}
							});
	
							var docGenerationSpecs = {
								templateId: vm.selectedTemplateId,
								proposalSO: GlobalService.proposalInfo,
								outputFormat: $scope.selectedOPFormat,
								includeWatermark: $scope.watermark
							};
	
							$scope.loading = true;
	
							RemoteService.submitGenerateDoc(docGenerationSpecs).then(
								function(response) {
									// action successfully submitted
									$scope.dismiss();
									$scope.loading = false;
									PageNotificationService.hasPageNotification = true;
									PageNotificationService.alert = {
										type: 'success',
										message: $scope.labels.SubmitDocAsyncMessage,
										timeout: submitDocGenTimeout
									};
								},
								function(reason) {
									// unkown error occurred
									PageNotificationService.hasPageNotification = true;
									PageNotificationService.alert = {
										type: 'warning',
										message: reason.message
									};
									$scope.dismiss();
									$scope.loading = false;
								}
							);
						};
	
						$scope.$watch('displayCollection', function(templates) {
							var hasSelectedItem = false;
							// get selected row
							if(templates) {
								templates.filter(function(r) {
									if (r.isSelected) {
										$scope.tplSelected = true;
										hasSelectedItem = true;
									}
								});
	
								if(!hasSelectedItem) $scope.tplSelected = false;
							}
						}, true);
	
					}
	
					var dialogInstance = $uibModal.open({
						backdrop: 'static',
						animation: true,
						template: __webpack_require__(47),
						size: tplDialogSize,
						bindToController: true,
						windowClass: 'templates-dialog',
						controller: proposalPopupDialogCtrl
					});
				};
	
				vm.selectProposal = function(value, index, forceSelection) {
					// only perform actions if proposal is not already selected
					if(!forceSelection && GlobalService.currentSelectedProposalInfo.RecordId === value.RecordId) return;
	
					// Initialize the followings on every selection
					GlobalService.clearAttachmentsBuckets = false;
					GlobalService.currentSelectedProposalInfo = value;
					PreviewService.attemptToMerge = false;
					ProposalsListService.selectionIsACollatedDoc = false;
					ProposalsListService.proposalDoc = {};
					PreviewService.selectionIsNotPdf = false;
					EmailService.mergedSourceDocsAttachInfo = [];
					EmailService.mergedDocInfo = [];
					PageContainerService.mergeFilesAttachmentInfo = [];
					vm.selectedProposalDocIndex = index;
	
					if(value && (value.ContentType !== 'application/pdf' && value.ContentType !== 'PDF')) {
						PreviewService.selectionIsNotPdf = true;
					}
	
					if (value && value.isCollated === true) {
						ProposalsListService.selectionIsACollatedDoc = true;
						EmailService.mergedDocInfo.push(value);
						RemoteService.getGeneratedDocumentInfo(value.ParentId).then(function(response) {
							var sourceDocs = [];
							var attachments = [];
	
							EmailService.mergedSourceDocsAttachInfo = response.sourceDocuments;
	
							// add collated parent document
							sourceDocs.push({
								                name: value.Title,
								                size: value.BodyLength,
								                type: value.ContentType,
								                parentId: value.ParentId,
								                recordId: value.RecordId,
								                isCollated: value.isCollated
							                });
	
							_.map(response.sourceDocuments, function(obj) {
								var fileObj = {
									lastModified: '',
									lastModifiedDate: {},
									name: obj.Title,
									size: obj.BodyLength,
									type: obj.ContentType,
									parentId: obj.ParentId,
									recordId: obj.RecordId,
									isCollated: obj.isCollated,
									webkitRelativePath: ''
								};
								sourceDocs.push(fileObj);
							});
	
							_.map(response.attachments, function(obj) {
								var fileObj = {
									lastModified: '',
									lastModifiedDate: {},
									name: obj.Title,
									size: obj.BodyLength,
									type: obj.ContentType,
									parentId: obj.ParentId,
									recordId: obj.RecordId,
									isCollated: obj.isCollated,
									webkitRelativePath: ''
								};
								attachments.push(fileObj);
							});
	
							ProposalsListService.mergedSourceDocs = sourceDocs;
							ProposalsListService.attachments = attachments;
						});
					} else if(value && (!angular.isDefined(value.isCollated) || !value.isCollated)) {
						var fileObj = {
							lastModified: '',
							lastModifiedDate: {},
							name: value.Title,
							size: value.BodyLength,
							type: value.ContentType,
							webkitRelativePath: ''
						};
						var proposalDocAttachmentInfo = angular.fromJson(angular.toJson(value)); //strip the internal angular props i.e. $$hashKey
						EmailService.mergedSourceDocsAttachInfo.push(proposalDocAttachmentInfo);
						ProposalsListService.proposalDoc = fileObj;
						GlobalService.clearAttachmentsBuckets = true; // Empty the current attachments buckets
						// ProposalsListService.selectionIsATpl = true; // TODO: Remove later
						ProposalsListService.selectionIsACollatedDoc = false;
					}
					if(value) {
						PreviewService.previewPDF(value);
					}
				};
	
				vm.selectNewProposal = function() {
					vm.selectProposal(vm.proposalList[0], 0, true);
				};
	
				vm.toggleProposalListLimit = function() {
					if(vm.listedResultsLimit === 1) {
						vm.listedResultsLimit = undefined;
					} else {
						vm.listedResultsLimit = 1;
					}
	
				};
	
				vm.expandContextMenu = function (event, item, proposalList) {
					event.stopPropagation();
					_.forEach(proposalList, function (value) {
						if (value.contextMenu.expanded) {
						value.contextMenu.expanded = false;
						}
					});
					item.contextMenu.expanded = true;
				}
	
				function activate() {
					vm.proposalList = ProposalsListService.proposalList;
	
					ProposalsListService.populateProposalList();
				}
	
				activate();
	
				var deregisterWatch2 = $scope.$watch(function() {
						return ProposalsListService.proposalList;
					},
					function(newVal, oldVal) {
						if (newVal !== oldVal) {
							var renameMethod = function(RecordId) {
								return function() {
									var index = _.findIndex(vm.proposalList, function(proposal) { return proposal.RecordId == RecordId; });
									vm.proposalList[index].editableFieldSettings.editMode = true;
								};
							};
	
							var onUserRename = function(proposal) {
								return function(editEvent) {
									if(editEvent.action === "accept") {
										// no need to make service call if name unchanged
										if(!editEvent.valueChanged) return;
	
										var renameRequest = {
											recordId: proposal.RecordId,
											name: proposal.Title
										};
	
										// clear any previous error before making service call
										PageNotificationService.hasPageNotification = false;
	
										RemoteService.setDocumentName(renameRequest).then(function(response) {
											if(response === proposal.Title) {
												// rename successful
												proposal.editableFieldSettings.editMode = false;
	
												// re-select proposal to display renamed doc
												vm.selectProposal(proposal, i, true);
											} else {
												_serviceFailure();
											}
										}, _serviceFailure);
									}
								};
							};
	
							var onUserDeleteProposal = function(proposal) {
								return function() {
									// clear any previous error before making service call
									PageNotificationService.hasPageNotification = false;
	
									var deleteRequest = {
										recordId: proposal.RecordId,
										proposalId: currentProposalId,
										isCollated: (angular.isDefined(proposal.isCollated) ? proposal.isCollated : false)
									};
	
									RemoteService.deleteAttachment(deleteRequest).then(function(deletedAttachmentId) {
										if(deletedAttachmentId === null) {
											// unknown error occurred
											_serviceFailure();
										} else {
											// successfully delete, remove from list
											_.remove(vm.proposalList, {
												RecordId: deletedAttachmentId
											});
	
											if(vm.proposalList.length > 0) {
												vm.selectProposal(vm.proposalList[0], 0, true);
											}
	
										}
									}, _serviceFailure);
								};
							};
							
							for (var i = 0; i < ProposalsListService.proposalList.length; i++) {
								var proposal = ProposalsListService.proposalList[i];							
	
								// configure editable/rename component
								proposal.editableFieldSettings = {
									editMode: false,
									onUserAction: onUserRename(proposal)
								};
	
								// controller code to setup menu settings/data-model
								proposal.contextMenu = {
									closeEventsList: ["touchstart", "click"],
									classList: ["context-menu-container", "context-menu-switch"],
									verticalOrientation: "TopTop",
									horizontalOrientation: "LeftRight",
									expanded: false,
									menuItems: [{ // array of menu items to appear when context menu is toggled
											name: "proposal-menu-item-rename" + i,
											displayLabel: "Rename",
											onClick: renameMethod(proposal.RecordId)
										},
										{ // array of menu items to appear when context menu is toggled
											name: "proposal-menu-item-delete" + i,
											displayLabel: "Delete",
											onClick: onUserDeleteProposal(proposal)
										}]
								};
	
							}
	
							vm.proposalList = ProposalsListService.proposalList;
							_.map(vm.proposalList, function(obj) {
								if(angular.isDefined(obj.Title)) {
									obj.Title = obj.Title.replace(/\.[^/.]+$/, "");
								}
							});
							vm.selectNewProposal();
						}
					}
				);
	
				$scope.$on('$destroy', function() {
					deregisterWatch2();
				});
	
			};
	
			proposalsListController.$inject = ['$scope',
			                                   '$timeout',
												'$sce',
												'$filter',
												'$uibModal',
												'lodash',
												'RemoteService',
												'i18nService',
												'systemConstants',
												'ProposalsListService',
												'PreviewService',
												'EmailService',
												'PageNotificationService',
												'PageContainerService',
												'GlobalService'
											];
	
			return {
				restrict: 'E',
				controller: proposalsListController,
				controllerAs: 'vm',
				scope: {},
				bindToController: {},
				template: __webpack_require__(48)
			};
		}];
	})();


/***/ }),
/* 47 */
/***/ (function(module, exports) {

	module.exports = "<div ng-show=\"loading\" class=\"slds-spinner_container\">\r\n    <div class=\"slds-spinner slds-spinner_medium slds-spinner_brand minicart-pricing-spinner\">\r\n        <div class=\"slds-spinner__dot-a\"></div>\r\n        <div class=\"slds-spinner__dot-b\"></div>\r\n    </div>\r\n    <span class=\"spinner-text\">{{spinnerText}}</span>\r\n</div>\r\n<div class='modal-header sel-tpl__header'>\r\n    <h3 class='modal-title'>{{labels.ChooseTemplateTitle}}</h3>\r\n    <i class='fa fa-times sel-tpl__close' ng-click='dismiss()' aria-hidden='true'></i>\r\n</div>\r\n<div class='modal-body sel-tpl__body'>\r\n    <div ng-if='customURL'>\r\n        <iframe ng-src=\"{{customURL}}\" class='custompage-content-iframe' height='500px' width=\"100%\"></iframe>\r\n    </div>\r\n    <div ng-if='!customURL'>\r\n        <!-- Output format and draft selection -->\r\n        <div class='output'>\r\n            <div class='output__format'>\r\n                <div class='form-group'>\r\n                    <label for='sel1'>{{labels.SelectOutputFormat}}</label>\r\n                    <select class='form-control'\r\n                            id='sel1'\r\n                            ng-model='selectedOPFormat'\r\n                            ng-options='format for format in outputFormats'\r\n                            ng-disabled= '!allowOverRideFormat'\r\n                            ng-change=\"selectedFormat(selectedOPFormat)\"\r\n                    >                       \r\n                    </select>\r\n                </div>\r\n            </div>\r\n            <div class='output__wmark'>\r\n                <div class=\"checkbox\">\r\n                    <label>\r\n                        <input ng-checked='watermark' ng-model='watermark' ng-disabled='!allowedOverRideWmark' ng-change='isDraft(watermark)' type=\"checkbox\" value=\"\" >\r\n                        {{labels.IncludeWatermark}}\r\n                    </label>\r\n                </div>\r\n            </div>\r\n        </div>\r\n        <!-- Search and list the available templates -->\r\n        <div class='templates'>\r\n            <!-- <div class='templates__search'></div> -->\r\n            <div class='templates__table'>\r\n                <div>\r\n                    <table st-table=\"displayCollection\" st-safe-src='rowCollection' class='table'>\r\n                        <thead>\r\n                            <tr>\r\n                                <th colspan=\"2\" class='searchable'>\r\n                                    <div class='searchbar'>\r\n                                        <i class=\"fa fa-search\"></i>\r\n                                        <input st-search='' class=\"form-control\" placeholder=\"{{labels.Search}}\" type=\"text\" />\r\n                                    </div>\r\n                                </th>\r\n                            </tr>\r\n                            <tr>\r\n                                <th st-sort=\"Name\" class='sortable'>\r\n                                    <span>{{labels.TemplateNameColumn}}</span>\r\n                                    <i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n                                    <i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n                                </th>\r\n                                <th st-sort=\"description\" class='sortable'>\r\n                                    <span>{{labels.Description}}</span>\r\n                                    <i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n                                    <i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n                                </th>\r\n                                <th st-sort=\"category\" class='sortable'>\r\n                                    <span>{{labels.Category}}</span>\r\n                                    <i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n                                    <i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n                                </th>\r\n                                <th st-sort=\"subcategory\" class='sortable'>\r\n                                    <span>{{labels.SubCategory}}</span>\r\n                                    <i class=\"fa fa-caret-down\" aria-hidden=\"true\"></i>\r\n                                    <i class=\"fa fa-caret-up\" aria-hidden=\"true\"></i>\r\n                                </th>\r\n                            </tr>\r\n                        </thead>\r\n                        <tbody>\r\n                            <tr st-select-row=\"row\" st-select-mode=\"single\" ng-repeat=\"row in displayCollection\">\r\n                                <td>{{row.Name}}</td>\r\n                                <td>{{row.Apttus__Description__c}}</td>\r\n                                <td>{{row.Apttus__Category__c}}</td>\r\n                                <td>{{row.Apttus__Subcategory__c}}</td>\r\n                            </tr>\r\n                        </tbody>\r\n                    </table>\r\n                </div>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n<div class='modal-footer sel-tpl__footer'>\r\n    <button ng-disabled='!tplSelected' ng-hide='!IsSubmitCallEnabled || customURL' class='btn btn-primary' type='button' ng-click='submitGenerateDoc()'>{{labels.SubmitForGenerate}}</button>\r\n    <button ng-disabled='!tplSelected' ng-hide='customURL' class='btn btn-primary' type='button' ng-click='generateDoc()'>{{labels.Generate}}</button>    \r\n    <button ng-show='customURL' class='btn btn-primary' type='button' ng-click='closeWithCustomTpl()'>{{labels.Apply}}</button>\r\n</div>\r\n"

/***/ }),
/* 48 */
/***/ (function(module, exports) {

	module.exports = "<!-- <div class='col-md-3 proposals-list__container'> -->\r\n<div ng-show=\"vm.isFastDocGen\" class=\"slds-spinner_container\">\r\n    <div class=\"slds-spinner slds-spinner_large slds-spinner_brand minicart-pricing-spinner\">\r\n        <div class=\"slds-spinner__dot-a\"></div>\r\n        <div class=\"slds-spinner__dot-b\"></div>\r\n    </div>\r\n    <span class=\"spinner-text\">{{vm.defaultTemplateSpinnerText}}</span>\r\n</div>\r\n<div flex class='proposals-list__container'>\r\n    <div class='proposals-list__header'>\r\n        <span class='title proposals-list__title'>{{vm.labels.ProposalsTitle}}</span>\r\n        <button class='btn btn-primary' ng-disabled=\"vm.isFastDocGen\" ng-click='vm.openDialog()'>{{vm.labels.CreateNewProposal}}</button>\r\n    </div>\r\n    <div class='proposals-list__searchbar'>\r\n        <i id=\"filter\" class=\"fa fa-search\"></i>\r\n        <input id='' type=\"text\" placeholder=\"{{vm.labels.SearchProposals}}\" ng-model=\"searchText.Title\" />\r\n    </div>\r\n    <div class='proposals-list__list'>\r\n        <ul>\r\n            <li id=\"{{item.RecordId}}\" ng-repeat='item in vm.proposalList | filter:searchText | limitTo:vm.listedResultsLimit' ng-click='vm.selectProposal(item, $index)' ng-class=\"{'sel': $index == vm.selectedProposalDocIndex}\">\r\n                <editable-text-field settings=\"item.editableFieldSettings\"\r\n                                     value=\"item.Title\"\r\n                                     max-length=\"80\"\r\n                                     max-length-error-msg=\"{{vm.MaximumCharacterLengthMessage}}\"></editable-text-field>\r\n                <i context-menu\r\n                   ng-show=\"!item.editableFieldSettings.editMode\"\r\n                   class=\"fa fa-ellipsis-v context-menu-switch\"\r\n                   aria-hidden='true'\r\n                   settings=\"item.contextMenu\"\r\n                   ng-click=\"vm.expandContextMenu($event, item, vm.proposalList)\"></i>\r\n            </li>\r\n        </ul>\r\n        <span class=\"msg\" ng-if=\"vm.proposalList.length === 0\">{{vm.labels.NoProposalDocumentCreated}}</span>\r\n        <button ng-if=\"vm.proposalList.length > 0\" type=\"button\"\r\n                class=\"btn btn-link proposal-list-toggle\" ng-click=\"vm.toggleProposalListLimit()\">\r\n            {{vm.listedResultsLimit === 1 ? vm.labels.ShowRecentProposals : vm.labels.HideRecentProposals}}\r\n        </button>\r\n    </div>\r\n</div>\r\n"

/***/ }),
/* 49 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		var previewController = function($http,
		                                 $sce,
		                                 $compile,
		                                 _,
		                                 RemoteService,
		                                 i18nService,
		                                 ProposalsListService,
		                                 PreviewService,
		                                 PageContainerService,
		                                 PageNotificationService,
		                                 GlobalService,
		                                 EmailService,
		                                 UtilitiesService) {
	
	
			return {
				restrict: 'E',
				scope: {},
				template: __webpack_require__(50),
				link: function($scope, element, attrs) {
					var vm = $scope;
	
					vm.loading = false;
					vm.attemptToMerge = false;
					vm.selectionIsNotPdf = false;
					vm.labels = i18nService.CustomLabel;
					vm.title = GlobalService.currentSelectedProposalInfo.Title;
					vm.isMobileIos = UtilitiesService.deviceInfo.isMobileIos;
					vm.isIE = (UtilitiesService.deviceInfo.browser === "IE");
	
					var h = screen.height;
					var w = screen.width;
	
					vm.openPdfInNewWindow = function() {
						if(vm.isMobileIos) {
							window.open(vm.url, 'newwindow', 'toolbar=no,location=0,status=no,' +
							            'titlebar=no,menubar=no,width=' + h + ', height=' + w);
						}
					};
	
					vm.mergeDocs = function() {
						vm.loading = true;
						var currentProposalInfo = GlobalService.currentSelectedProposalInfo;
						var currentProposalInfoList = [];
	
						currentProposalInfo = {
							'RecordId': currentProposalInfo.RecordId,
							'Title': currentProposalInfo.Title,
							'isCollated': currentProposalInfo.isCollated
						};
	
						currentProposalInfoList.push(currentProposalInfo);
	
						var sourceDocsList = _.union(
							currentProposalInfoList,
							PageContainerService.mergeFilesAttachmentInfo
						);
	
						var attachmentsList = _.union(
							PageContainerService.attachFilesAttachmentInfo,
							PageContainerService.attachNAFilesAttachmentInfo
						);
	
						RemoteService.createDocumentCollateInfo().then(function(newParentId) {
							var proposalId = newParentId;
							var reqObj = {
								'addAutoFooter': false,
								'addWatermark': false,
								'sourceDocuments': sourceDocsList,
								'attachments': attachmentsList,
								'docFileName': 'Q-' + GlobalService.currentProposalId + 'PDFPackage.pdf',
								'externalLinks': [],
								'footerText': '',
								'headerText': '',
								'parentId': proposalId,
								'proposalId': GlobalService.currentProposalId,
								'protectionLevel': '',
								'removeWatermark': false,
								'sessionId': '',
								'sessionUrl': ''
							};
	
							if (PreviewService.selectionIsNotPdf && !PreviewService.goForPDF) {
								RemoteService.createWordPackage(reqObj).then(
									function() {
										ProposalsListService.populateProposalList();
										GlobalService.packageHasCreated = true;
										vm.loading = false;
										vm.attemptToMerge = false;
										PreviewService.goForPDF = false;
										// Empty up all the buckets on a merge doc action
										PageContainerService.mergeFilesAttachmentInfo = [];
										PageContainerService.mergeNAFilesAttachmentInfo = [];
										PageContainerService.attachFilesAttachmentInfo = [];
										PageContainerService.attachNAFilesAttachmentInfo = [];
									},
									function(reason) {
										// TODO: feed it to the page error service with appropriate error level
										console.log(reason);
										vm.loading = false;
									}
								);
							}
							else {
								RemoteService.createPDFPackage(reqObj).then(
									function() {
										ProposalsListService.populateProposalList();
										GlobalService.packageHasCreated = true;
										vm.loading = false;
										vm.attemptToMerge = false;
										PreviewService.goForPDF = false;
										// Empty up all the buckets on a merge doc action
										PageContainerService.mergeFilesAttachmentInfo = [];
										PageContainerService.mergeNAFilesAttachmentInfo = [];
										PageContainerService.attachFilesAttachmentInfo = [];
										PageContainerService.attachNAFilesAttachmentInfo = [];
									},
									function(reason) {
										// TODO: feed it to the page error service with appropriate error level
										console.log(reason);
										vm.loading = false;
									}
								);
							}
	
						});
					};
	
					vm.embedPdfPreview = function() {
						return !vm.selectionIsNotPdf && !vm.attemptToMerge && !vm.isMobileIos;
					};
	
					vm.sendEmail = function() {
						EmailService.wantToEmail = true;
					};
	
					var deRegisterWatch1 = $scope.$watch(function() {
						                                     return PreviewService.selectedDocUrl;
					                                     },
					                                     function(newVal, oldVal) {
						                                     if (newVal !== oldVal) {
							                                     $sce.trustAsResourceUrl(PreviewService.selectedDocUrl);
																 vm.url = PreviewService.selectedDocUrl;
							                                     if(vm.isMobileIos) {
	
								                                     // to stay as language agnostic as possible replace token with anchor markup
								                                     var htmlContent = vm.labels.PreviewNotSupportedOnDevice.replace("{0}", "<a target='_blank' href='" +
								                                                                                                     (vm.isMobileIos ? "#" : vm.url) +
								                                                                                                     "' ng-click='openPdfInNewWindow()'>" +
								                                                                                                     vm.labels.Here + "</a>");
	
								                                     // compile the provided template against the current scope
								                                     var elmnt = $compile( "<span>" + htmlContent + "</span>" )( $scope );
	
								                                     // get message container element reference
								                                     var messageContainerEl = angular.element(element[0].querySelector('.isMobileIos'));
								                                     angular.element(document.querySelector('.isMobileIos'));
	
								                                     messageContainerEl.html(""); // "clear"
	
								                                     messageContainerEl.append( elmnt );
							                                     }
						                                     }
					                                     }
					);
	
					var deRegisterWatch2 = $scope.$watch(function() {
						                                     return PreviewService.attemptToMerge;
					                                     },
					                                     function(newVal, oldVal) {
						                                     vm.attemptToMerge = PreviewService.attemptToMerge;
					                                     }
					);
	
					var deRegisterWatch3 = $scope.$watch(function() {
						                                     return PreviewService.selectionIsNotPdf;
					                                     },
					                                     function(newVal, oldVal) {
						                                     vm.selectionIsNotPdf = PreviewService.selectionIsNotPdf;
					                                     }
					);
	
					var deRegisterWatch4 = $scope.$watch(function() {
						                                     return PreviewService.dialogIsOpen;
					                                     },
					                                     function(newVal, oldVal) {
						                                     vm.dialogIsOpen = PreviewService.dialogIsOpen;
					                                     }
					);
	
					var deRegisterWatch5 = $scope.$watch(function() {
						                                     return PreviewService.disableMerge;
					                                     },
					                                     function(newVal, oldVal) {
						                                     vm.disableMerge = PreviewService.disableMerge;
					                                     }
					);
	
					var deRegisterWatch6 = $scope.$watch(function() {
															return PreviewService.selectedDocPreviewUrl;
														},
														function(newVal, oldVal) {
															if (newVal !== oldVal) {
																$sce.trustAsResourceUrl(PreviewService.selectedDocPreviewUrl);
																vm.previewUrl = PreviewService.selectedDocPreviewUrl;
															}
														}
					);
	
					$scope.$on('$destroy', function() {
						deregisterWatch1();
						deregisterWatch2();
						deRegisterWatch3();
						deRegisterWatch4();
						deRegisterWatch5();
						deRegisterWatch6();
					});
	
					if(UtilitiesService.deviceInfo.isMobileIos) {
						var downloadLnk = element[0].querySelector('.download');
	
						// remove download attribute so iPad browser will not attempt to
						// download the file
						downloadLnk.removeAttribute("download");
					}
				}
			};
		};
	
		module.exports = ['$http',
		                  '$sce',
		                  '$compile',
		                  'lodash',
		                  'RemoteService',
		                  'i18nService',
		                  'ProposalsListService',
		                  'PreviewService',
		                  'PageContainerService',
		                  'PageNotificationService',
		                  'GlobalService',
		                  'EmailService',
		                  'UtilitiesService', previewController];
	})();


/***/ }),
/* 50 */
/***/ (function(module, exports) {

	module.exports = "<div layout='column' class='preview__container'>\r\n    <div layout='row' class='preview__header'>\r\n        <div flex class='title preview__title'>\r\n            <span>{{labels.Preview}}</span>\r\n            <span>{{title}}</span>\r\n        </div>\r\n        <div class='preview__action-container'>\r\n            <button class='btn btn-default btn-action' type='submit' ng-click='sendEmail();'>\r\n                <i class='fa fa-envelope-o'></i>\r\n                <span>{{labels.Email}}</span>\r\n            </button>\r\n            <a class='btn btn-default btn-action download'\r\n               target='{{isIE ? \"_blank\" : \"_self\" }}'\r\n               href='{{ isMobileIos ? \"#\" : url }}'\r\n               download='foo.pdf'\r\n               ng-click=\"openPdfInNewWindow()\">\r\n                <i class='fa fa-download'></i>\r\n                <span>{{isMobileIos ? labels.View : labels.Download}}</span>\r\n            </a>\r\n        </div>\r\n    </div>\r\n    <iframe ng-if='embedPdfPreview()'\r\n            ng-hide='dialogIsOpen'\r\n            ng-src='{{previewUrl}}'\r\n            layout='column' flex class='preview__content'\r\n            frameborder='0'\r\n            scrolling='no' allowfullscreen=\"true\">\r\n        <p>{{labels.PreviewBrowserNotSupported}}<a href='{{previewUrl}}'>{{labels.Here}}</a></p>\r\n    </iframe>\r\n    <div ng-if='!embedPdfPreview()' layout='column' flex class='preview__content'>\r\n        <div ng-if='selectionIsNotPdf && !isMobileIos' class='preview__nosupport'>\r\n            {{labels.PreviewNotSupported}} {{labels.PleaseClick}} <a href='{{url}}'>{{labels.Here}}</a> {{labels.ToDownloadIt}}\r\n        </div>\r\n        <!-- Merge Documents Button Container -->\r\n        <div ng-show='attemptToMerge' class='merge-btn-wrapper'>\r\n            <button ng-disabled=\"disableMerge\" class='btn btn-primary btn-lg merge-btn' ng-click='mergeDocs()'>{{labels.MergeDocuments}}</button>\r\n        </div>\r\n        <div ng-if='!selectionIsNotPdf && isMobileIos' class='preview__nosupport isMobileIos'>\r\n        </div>\r\n        <div ng-if='selectionIsNotPdf && isMobileIos' class='preview__nosupport'>\r\n            {{labels.PreviewNotSupported}}\r\n        </div>\r\n    </div>\r\n\r\n    <md-progress-circular class='spinner' ng-show='loading' md-mode=\"indeterminate\"></md-progress-circular>\r\n</div>\r\n"

/***/ }),
/* 51 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
	    'use strict';
	    __webpack_require__(2);
	    module.exports = angular.module('docGenCommonServices', [])
	        .service('GlobalService', __webpack_require__(52))
	        .service('UploadService', __webpack_require__(59))
	        .service('UtilitiesService', __webpack_require__(60))
	        .service('PageContainerService', __webpack_require__(61))
	        .service('ProposalsListService', __webpack_require__(62))
	        .service('PreviewService', __webpack_require__(63))
	        .service('EmailService', __webpack_require__(64))
	        .service('PageNotificationService', __webpack_require__(65));
	
	})();


/***/ }),
/* 52 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
	    'use strict';
	
	    var globalService = function(systemConstants, RemoteService) {
	
	        var baseSFurl = '';
	        var currentProposalId = '';
	        var currentContext = '';
	        var clearAttachmentsBuckets = false;
	        var currentSelectedProposalInfo = {};
	        var nameSpacePrefix = systemConstants.nameSpacePrefix;
	
	        __webpack_require__(53);
	        __webpack_require__(54);
	        __webpack_require__(55);
	        __webpack_require__(56);
	        __webpack_require__(57);
	        __webpack_require__(58);
	
		    var isAcceptedFileType = function(fileType) {
			    return (fileType == 'application/pdf' ||
			    		fileType == 'PDF' ||
	                fileType == 'application/doc' ||
	                fileType == 'application/docx' ||
	                fileType == 'application/msword' ||
	                fileType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
		    };
	
	        var getFileTypeIconUrl = function(file) {
	            var imgPath = "";
	            var mergedPrefix = (file.isCollated ? "merged-": "");
	
	            if (file.type === 'application/pdf' || file.type === 'PDF') {
	                imgPath = "pdf.png";
	            } else if (file.type === 'application/msword' || file.type === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
	                imgPath = "doc.png";
	            } else {
	                imgPath = "misc-info.png";
	            }
	
	            return systemConstants.imagesFolderPath + mergedPrefix + imgPath;
	        };
	
	        function getCurrentContext() {
	            baseSFurl = window.location.origin;
	            currentContext = systemConstants.contextParam;
	            currentProposalId = systemConstants.proposalIdParam || getQueryVariable('id');            
	        }        
	
	        function getQueryVariable(variable) {
	            var query = window.location.search.substring(1);
	            var vars = query.split("&");
	            for (var i = 0; i < vars.length; i++) {
	                var pair = vars[i].split("=");  
	                if (pair[0] == variable) {
	                    return pair[1];
	                }
	            }
	            return (false);
	        }
	
	        function activate() {
	            getCurrentContext();
	        }
	
	        activate();
	
	        var service = {
	            currentProposalId: currentProposalId,
	            currentContext: currentContext,
	            clearAttachmentsBuckets: clearAttachmentsBuckets,
	            currentSelectedProposalInfo: currentSelectedProposalInfo,
	            baseSFurl: baseSFurl,
	            nameSpacePrefix: nameSpacePrefix,
	            getFileTypeIconUrl: getFileTypeIconUrl,
	            isAcceptedFileType: isAcceptedFileType,
	            defaultTemplateName: systemConstants.docGenCustomSettings.EmailTemplateForPresentingProposals
	        };
	
	        return service;
	    };
	
	    globalService.$inject = ['systemConstants', 'RemoteService'];
	
	    module.exports = globalService;
	})();


/***/ }),
/* 53 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/doc.png";

/***/ }),
/* 54 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/merged-doc.png";

/***/ }),
/* 55 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/merged-pdf.png";

/***/ }),
/* 56 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/pdf.png";

/***/ }),
/* 57 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/xls.png";

/***/ }),
/* 58 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__.p + "app/common/assets/images/misc-info.png";

/***/ }),
/* 59 */
/***/ (function(module, exports) {

	(function() {
		'use strict';
	
		var maxStringSize = 6000000;    //Maximum String size is 6,000,000 characters
		var maxFileSize = 4350000;      //After Base64 Encoding, this is the max file size
		var chunkSize = 125000;         //Maximum Javascript Remoting message size is 1,000,000 characters
	
		var uploadService = function(RemoteService) {
			var uploadAttachment = function(uploadRequest) {
				uploadRequest.onerror = (angular.isDefined(uploadRequest.onerror) ? uploadRequest.onerror : function() {} );
				uploadRequest.request = {
					proposalId: uploadRequest.parentId,
					attachmentName: uploadRequest.file.name,
				    contentType: uploadRequest.file.type
				};
	
				var fileReader = new FileReader();
	
				fileReader.onloadend = function(e) {
					uploadRequest.positionIndex = 0;
					uploadRequest.attachment = this.result.match(/,(.*)$/)[1];
	
					if(uploadRequest.attachment.length <= maxFileSize) {
						uploadRequest.doneUploading = false;
	
						if(uploadRequest.attachment.length < maxStringSize) {
							uploadFile(uploadRequest);
						} else {
							uploadRequest.onerror({
								                      errorCode: -1,
								                      additionalInfo: {}
							                      });
						}
	
					} else {
						uploadRequest.onerror({
							                      errorCode: -2,
							                      additionalInfo: {}
						                      });
					}
				};
	
				fileReader.onerror = function(e) {
					uploadRequest.onerror({
						                      errorCode: -3,
						                      additionalInfo: e
					                      });
				};
	
				fileReader.onabort = function(e) {
					uploadRequest.onerror({
						                      errorCode: -4,
						                      additionalInfo: e
					                      });
				};
	
				fileReader.readAsDataURL(uploadRequest.file); // read the body of the file
			};
	
			// Method to send a file to be attached to the Account bound to the page by the standardController
			// Sends parameters: Account Id, Attachment (body), Attachment Name, and the Id of the Attachment if it exists
			// to the controller
			function uploadFile(uploadRequest) {
				var attachmentBody = "";
	
				if(uploadRequest.attachment.length <= uploadRequest.positionIndex + chunkSize) {
					attachmentBody = uploadRequest.attachment.substring(uploadRequest.positionIndex);
					uploadRequest.doneUploading = true;
				} else {
					attachmentBody = uploadRequest.attachment.substring(uploadRequest.positionIndex,
					                                                    uploadRequest.positionIndex + chunkSize);
				}
	
				uploadRequest.request.attachmentBody = attachmentBody;
	
				RemoteService.doUploadAttachment(uploadRequest.request).then(function(result) {
					if(uploadRequest.doneUploading === true) {
						uploadRequest.oncomplete({
							result: result
						});
					} else {
						uploadRequest.request.attachmentId = result.RecordId;
						uploadRequest.positionIndex += chunkSize;
						var eventDetails = {
							percentComplete: uploadRequest.positionIndex / uploadRequest.attachment.length,
							result: result
						};
	
						uploadRequest.onchunkcomplete(eventDetails);
	
						if(eventDetails.stopUploading) return;
	
						uploadFile(uploadRequest);
					}
				});
			}
	
			return {
				uploadAttachment: uploadAttachment
			};
		};
	
		uploadService.$inject = ['RemoteService'];
	
		module.exports = uploadService;
	})();


/***/ }),
/* 60 */
/***/ (function(module, exports) {

	(function() {
		'use strict';
	
		var utilitiesService = function() {
			var _browser;
	
			var generateUuid = function() {
				function s4() {
					return Math.floor((1 + Math.random()) * 0x10000)
					           .toString(16)
					           .substring(1);
				}
				return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
					s4() + '-' + s4() + s4() + s4();
			};
	
			var _isInternetExplorer = function() {
				var rv = false;
				var ua;
				var re;
	
				if (navigator.appName == 'Microsoft Internet Explorer') {
					ua = navigator.userAgent;
					re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
					rv = re.test(ua);
				}
				else if (navigator.appName == 'Netscape') {
					ua = navigator.userAgent;
					re = new RegExp("Trident/.*rv:([0-9]{1,}[\.0-9]{0,})");
					rv = re.test(ua);
				}
				return rv;
			};
	
			if(_isInternetExplorer()) {
				_browser = "IE";
			}
	
			var isSf1 = false;
	
			// salesforce specific detection if is salesforce1
			if((typeof sforce != 'undefined') && (sforce !== null)) { // SF1 mobile
				isSf1 = true;
			}
	
			var _isMobileIos = (function() {
				var iDevices = [
					'iPad Simulator',
					'iPhone Simulator',
					'iPod Simulator',
					'iPad',
					'iPhone',
					'iPod'
				];
	
				if (!!navigator.platform) {
					while (iDevices.length) {
						if (navigator.platform === iDevices.pop()){ return true; }
					}
				}
	
				return false;
			})();
	
			// Detect file input support
			var _isFileInputSupported = (function () {
				// Handle devices which falsely report support
				if (navigator.userAgent.match(/(Android (1.0|1.1|1.5|1.6|2.0|2.1))|(Windows Phone (OS 7|8.0))|(XBLWP)|(ZuneWP)|(w(eb)?OSBrowser)|(webOS)|(Kindle\/(1.0|2.0|2.5|3.0))/)) {
					return false;
				}
				// Create test element
				var el = document.createElement("input");
				el.type = "file";
				return !el.disabled;
			})();
	
			var service = {
				generateUuid: generateUuid,
				deviceInfo: {
					browser: _browser,
					isMobileIos: _isMobileIos,
					isFileInputSupported: _isFileInputSupported
				},
				isSf1: isSf1
			};
	
			return service;
		};
	
		module.exports = utilitiesService;
	})();


/***/ }),
/* 61 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	
	    var pageContainerService = function($q) {
	
	        var mergeFilesAttachmentInfo = [];
	        var attachFilesAttachmentInfo = [];
	        var mergeNAFilesAttachmentInfo = [];
	        var attachNAFilesAttachmentInfo = [];
	        var generatedDocAttachmentInfo = [];
	        var currentWaterMarkNeeded = false;
	        var currentOutputFormat = '';
	
	        var service = {
	            generatedDocAttachmentInfo: generatedDocAttachmentInfo,
	            mergeFilesAttachmentInfo: mergeFilesAttachmentInfo,
	            attachFilesAttachmentInfo: attachFilesAttachmentInfo,
	            mergeNAFilesAttachmentInfo: mergeNAFilesAttachmentInfo,
	            attachNAFilesAttachmentInfo: attachNAFilesAttachmentInfo,
	            currentWaterMarkNeeded: currentWaterMarkNeeded,
	            currentOutputFormat: currentOutputFormat
	        };
	
	        return service;
	    };
	
	    pageContainerService.$inject = ['$q'];
	
	    module.exports = pageContainerService;
	})();


/***/ }),
/* 62 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	
	    var proposalListService = function($q, $filter, _, RemoteService, GlobalService) {
		    var service;
	        var proposalList = [];
	        var currentProposalId = GlobalService.currentProposalId;
	        var mergedSourceDocs = [];
	        var attachments = [];
	        var selectionIsATpl = false;
	        var selectionIsACollatedDoc = false;
	        var proposalDoc = {};
	
	        function populateProposalList() {
	            RemoteService.getCollatedDocuments(currentProposalId).then(function(response) {
		            service.proposalList = $filter('reverse')(response);
	            });
	        }
	
	        service = {
	            proposalList: proposalList,
	            populateProposalList: populateProposalList,
	            mergedSourceDocs: mergedSourceDocs,
	            attachments: attachments,
	            selectionIsATpl: selectionIsATpl,
	            selectionIsACollatedDoc: selectionIsACollatedDoc,
	            proposalDoc: proposalDoc,
	            defaultOutputFormat: systemConstants.docGenCustomSettings.DefaultOutputFormat
	        };
	
	        return service;
	    };
	
	    proposalListService.$inject = ['$q', '$filter', 'lodash', 'RemoteService', 'GlobalService'];
	
	    module.exports = proposalListService;
	})();


/***/ }),
/* 63 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	
	    var previewService = function($q, $filter, _, RemoteService, GlobalService) {
	
	        this.selectedDocUrl = '';
	        this.selectedDocPreviewUrl = '';
	        var service;
	        var attemptToMerge = false;
	        var selectionIsNotPdf = false;
	        var dialogIsOpen = false;
	        var goForPDF = false;
		    var disableMerge = false;
	
	        function previewPDF(documentObj) {
	            RemoteService.getAttachmentURL(documentObj.RecordId).then(function(response) {
		            service.selectedDocUrl = response;
	            });
	            RemoteService.getAttachmentPreviewURL(documentObj.RecordId).then(function(response) {
		            service.selectedDocPreviewUrl = response;
	            });
	        }
	
	        service = {
	            previewPDF: previewPDF,
	            selectedDocUrl: this.selectedDocUrl,
	            selectedDocPreviewUrl: this.selectedDocPreviewUrl,
	            attemptToMerge: attemptToMerge,
	            selectionIsNotPdf: selectionIsNotPdf,
	            dialogIsOpen: dialogIsOpen,
	            goForPDF: goForPDF,
		        disableMerge: disableMerge
	        };
	
	        return service;
	    };
	
	    previewService.$inject = ['$q', '$filter', 'lodash', 'RemoteService', 'GlobalService'];
	
	    module.exports = previewService;
	})();


/***/ }),
/* 64 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	
	    var emailService = function($q, _, RemoteService) {
	
	        var wantToEmail = false;
	        var mergedSourceDocsAttachInfo = [];
	        var mergedDocInfo = [];
	
	        var service = {
	            wantToEmail: wantToEmail,
	            mergedSourceDocsAttachInfo : mergedSourceDocsAttachInfo,
	            mergedDocInfo: mergedDocInfo
	        };
	
	        return service;
	    };
	
	    emailService.$inject = ['$q', 'lodash', 'RemoteService'];
	
	    module.exports = emailService;
	})();


/***/ }),
/* 65 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	
	    var pageNotificationService = function() {
	
	        var hasPageNotification = false;
	        var alert = {
	            type: 'warning',
	            message: ''
	        };
	
	        var service = {
	            hasPageNotification: hasPageNotification,
	            alert: alert
	        };
	
	        return service;
	    };
	
	    pageNotificationService.$inject = [];
	
	    module.exports = pageNotificationService;
	})();


/***/ }),
/* 66 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
	
		module.exports = angular.module('docGen.commonFilters', [])
			.filter('reverse', __webpack_require__(67));
	
	})();

/***/ }),
/* 67 */
/***/ (function(module, exports) {

	(function() {
	    'use strict';
	    module.exports = [function() {
	
	        function reverse (items) {
	            return items.slice().reverse();
	        }
	        return reverse;
	    }];
	
	})();


/***/ }),
/* 68 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
		'use strict';
		module.exports = ['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {
			// Defaults to product listing page with selected view
			$urlRouterProvider.otherwise('/app/list');
	
			$stateProvider.state('app', {
					url: '/app',
					abstract: true
				})
				.state('404', {
					url: '/file-not-found',
					template: __webpack_require__(69)
				});
	
			/* 5 mins timeout*/
			/*IdleProvider.idle(300);
	
			IdleProvider.timeout(5);
	
			KeepaliveProvider.interval(10);*/
		}];
	})();

/***/ }),
/* 69 */
/***/ (function(module, exports) {

	module.exports = "<div class=\"error-container\">\r\n    <div class=\"error-body\">\r\n        <p class=\"error-tagline\"> OOPS! COULD NOT FIND IT</p>\r\n        <div class=\"error-code\">\r\n            <span>4</span>\r\n            <span class=\"green\">0</span>\r\n            <span>4</span>\r\n        </div>\r\n        <br>\r\n        <div class=\"redirection\">\r\n            <a ui-sref=\"app.\" class=\"btn btn-primary\">Back to List</a>\r\n        </div>\r\n    </div>\r\n</div>\r\n"

/***/ }),
/* 70 */
/***/ (function(module, exports) {

	(function() {
		'use strict';
	
		var constants = {
			/*
			 * This object contains application wide constants.
			 * - Capitalized data type names
			 */
	
			/* Data types */
			'boolean': 'BOOLEAN',
			'string': 'STRING',
			'datetime': 'DATETIME',
			'date': 'DATE',
			'double': 'DOUBLE',
			'percent': 'PERCENT',
			'currency': 'CURRENCY',
			'picklist': 'PICKLIST',
			'multipicklist': 'MULTIPICKLIST',
			'textarea': 'TEXTAREA',
			'url': 'URL',
	
			/* Sorting */
			'ascending': 'ASC',
			'descending': 'DESC'
	
		};
	
		module.exports = constants;
	
	})();

/***/ })
/******/ ]);
//# sourceMappingURL=app.js.map