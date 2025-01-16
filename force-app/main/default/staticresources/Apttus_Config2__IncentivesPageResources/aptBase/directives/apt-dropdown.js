/* 
	Simple dropdown directive
	Inspired by angular-ui-bootstrap
*/
(function () {
/**
 * This module includes three directives:
 * 	1) apt-dropdown
 * 	2) apt-dropdown-toggle
 * 	3) apt-dropdown-menu
 * which make use of a shared controller and service:
 * 	- aptDropdownService
 * 	- aptDropdownCtrl
 *
 * Together, these directives handle the addition and removal of an element
 * on the dom to provide a "dropdown" or "tooltip" effect, where the menu 
 * element can contain any kind of valid angular html and the toggle element
 * can be anything that accepts a click or hover.
 *
 * These directives accept a string of settings which affect how the elements
 * are shown and positioned. For example:
 *
 * <div apt-dropdown>
 * 	<button apt-dropdown-toggle="onClick:false onHover:true">More</button>
 * 	<div apt-dropdown-menu="alignWith:dropdown">
 * 		<p ng-repeat="paragraph in text">{{paragraph}}</p>
 * 	</div>
 * </div>
 *
 * apt-dropdown-toggle:
 * 	"onClick" - 'true' if clicking the toggle should cause menu to appear,
 * 							'false' if not. Default is 'true'.
 * 	"onHover" - 'true' if placing the pointer over the toggle should cause
 * 							menu to appear, 'false' if not. Default is 'false'.
 * 	"onDocumentClick" - 'true' if clicking the document should cause the menu
 * 							to collapse, 'false' if not. Default is 'true'.
 *
 * apt-dropdown-menu:
 * 	"appendTo" - which element to attach the menu to when it is expanded.
 * 							'body' will be the body of the document;
 * 							'toggle' will be the toggle element;
 * 							'dropdown' will be the dropdown container.
 * 							Default is 'body'.
 * 	"alignWith" - which element the menu should use to calculate its position.
 * 							'toggle' wil be the toggle element;
 * 							'dropdown' will be the dropdown container.
 */
angular.module('aptBase.dropdown', [])
/**
 * The service is used for helper functions.
 */
.service('aptDropdownService', ['$document', '$window', '$log',
	function dropdownService($document, $window, $log) {
		var service = this,
				body;
		/**
		 * Handle the addition or removal the element from the DOM
		 */
		service.detach = function(child) {
			return child.detach();
		};
		service.attach = function(child, parent, align) {
			parent = parent || service.getBody();
			align = align || parent;
			var alignOffset = service.calculateOffset(align);
			parent.append(child);
			service.setChildPosition(child, alignOffset);
			return child;
		};
		service.getBody = function() {
			if (!body) {
				body = $document.find('body');
			}
			return body;
		};
		/**
		 * Calculate the position of a dropdown for a parent element.
		 * Window measurements taken from https://github.com/angular-ui/bootstrap/blob/master/src/position/position.js#L191
		 * @param  {jQlite} element
		 * @return {Object} collection of position values
		 */
		service.calculateOffset = function(element) {
			var boundingClientRect = element[0].getBoundingClientRect(),
					width = boundingClientRect.width || element.prop('offsetWidth'),
					height = boundingClientRect.height || element.prop('offsetHeight'),
					top = boundingClientRect.top + ($window.pageYOffset || $document[0].documentElement.scrollTop),
					left = boundingClientRect.left + ($window.pageXOffset || $document[0].documentElement.scrollLeft);
			return {
				width: width,
				height: height,
				top: top,
				left: left
			};
		};
		/**
		 * Set the position of child element to fit relative to its parent.
		 * @param {jQlite} element       
		 * @param {Object} parentPosition
		 */
		service.setChildPosition = function(element, parentPosition) {
			var elStyle = element[0].style,
					bottom = $document[0].documentElement.clientHeight,
					right = $document[0].documentElement.clientWidth,
					elPosition;

			elStyle.position = 'absolute';
			elPosition = service.calculateOffset(element);
			if (parentPosition.left + elPosition.width < right) {
				elStyle.left = parentPosition.left + 'px';
			} else {
				elStyle.left = parentPosition.left + parentPosition.width - elPosition.width + 'px';
			}
			if (parentPosition.top + parentPosition.height + elPosition.height < bottom) {
				elStyle.top = parentPosition.top + parentPosition.height + 'px';
			} else {
				elStyle.top = parentPosition.top - elPosition.height + 'px';
			}
		};
		/**
		 * Determine whether the target of a click event is contained withinan element. 
		 * Note: will always return false if element is the body of the document.
		 * @param  {MouseEvent}  event
		 * @param  {jQlite}  element - Element that may contain the click event.
		 * @return {Boolean} True if target is within element, else false.
		 */
		service.isTarget = function(event, element) {
			var bodyElement = service.getBody()[0];
			if (!event || !event.target || !element) {
				return false;
			}
			while(element[0] && element[0] != event.target && element[0] != bodyElement) {
				element = element.parent();
			}
			return element[0] != bodyElement;
		};
		service.extendAttrs = function(attrStr, existingAttrs) {
			var attrMap = {},
					attrArr;
			if (!attrStr) {
				return attrMap;
			}
			attrArr = attrStr.split(/\s+/);
			for (var foundKey = false, attrIndex = 0; attrIndex < attrArr.length; attrIndex++) {
				var nextAttr = attrArr[attrIndex],
						attrKey,
						attrVal;
				if (foundKey) {
					foundKey = false;
					attrKey = attrArr[attrIndex - 1];
					attrVal = nextAttr;

				} else if (nextAttr.length < 1 || !/:$/.test(nextAttr)) {
					attrKey = nextAttr;
					attrVal = true;
					if (/\w+:\w+/.test(nextAttr)) {
						var attrPair = nextAttr.split(':');
						attrKey = attrPair[0];
						attrVal = attrPair[1];
					}

				} else {
					var truncated = nextAttr.slice(0, -1);
					attrArr[attrIndex] = truncated;
					foundKey = true;

				}
				if (attrKey && attrVal) {
					if (/^true$/i.test(attrVal)) {
						attrVal = true;
					
					} else if (/^false$/i.test(attrVal)) {
						attrVal = false;

					}
					attrMap[attrKey] = attrVal;
				}

			}
			return angular.extend(existingAttrs, attrMap);

		}
		service.getDefaultSettings = function() {
			var settings = {
				dropdown: {},
				toggle: {
					onClick: true,
					onHover: false,
					onDocumentClick: true
				},
				menu: {
					appendTo: 'body',
					alignWith: 'toggle'
				}
			};
			return settings;
		};
	}
])
.controller('aptDropdownCtrl', ['$log', '$element', '$document', '$timeout', 'aptDropdownService', 
	function dropdownCtrl($log, $element, $document, $timeout, dropdownService) {
		var ctrl = this,
				settings = dropdownService.getDefaultSettings(),
				attached = true,
				menuOver = false,
				togglePromise,
				appendTo,
				alignWith;

		ctrl.init = function(attrs) {
			$element.addClass('apt-dropdown-container');
			ctrl.dropdownAttrs = attrs;
			dropdownService.extendAttrs(attrs, settings.dropdown);
			updateBinding();
		};
		ctrl.initMenu = function(menuElement, menuAttrs) {
			ctrl.menuElement = menuElement;
			ctrl.menuAttrs = menuAttrs;
			dropdownService.extendAttrs(menuAttrs, settings.menu);
			menuElement.addClass('apt-dropdown-menu');
			updateBinding();
		};
		ctrl.initToggle = function(toggleElement, toggleAttrs) {
			ctrl.toggleElement = toggleElement;
			ctrl.toggleAttrs = toggleAttrs;
			dropdownService.extendAttrs(toggleAttrs, settings.toggle);
			toggleElement.addClass('apt-dropdown-toggle');
			updateBinding();
		}
		ctrl.destroy = function() {
			dropdownService.attach(ctrl.menuElement, $element);
			$timeout.cancel(togglePromise);
			$document.off('click', toggleOff);
			ctrl.toggleElement.off('click', clickHandler);
			ctrl.toggleElement.off('mouseover', togggleOverHandler);
			ctrl.toggleElement.off('mouseleave', toggleOutHandler);
			ctrl.menuElement.off('mouseover', menuOverHandler);
			ctrl.menuElement.off('mouseleave', menuOutHandler);
			ctrl.menuElement = null;
			ctrl.toggleElement = null;
			togglePromise = null;
			appendTo = null;
			alignWith = null;
		};
		ctrl.toggleDropdown = function() {
			if (!ctrl.menuElement) {
				return;
			}
			if (attached) {
				$element.removeClass('is--open');
				dropdownService.detach(ctrl.menuElement);
			} else {
				$element.addClass('is--open');
				dropdownService.attach(ctrl.menuElement, appendTo, alignWith);
			}
			attached = !attached;
		};
		function updateBinding() {
			if (!(ctrl.dropdownAttrs && ctrl.toggleAttrs && ctrl.menuAttrs)) {
				return;
			}
			var appendToStr = settings.menu.appendTo;
			if (appendToStr === 'dropdown') {
				appendTo = $element;
			} else if (appendToStr === 'toggle') {
				appendTo = ctrl.toggleElement;
			}
			alignWith = settings.menu.alignWith == 'dropdown' || !ctrl.toggleElement ? $element : ctrl.toggleElement;
			// Establish click & hover handling
			if (settings.toggle.onClick) {
				ctrl.toggleElement.on('click', clickHandler);
			}
			if (settings.toggle.onHover) {
				ctrl.toggleElement.on('mouseover', togggleOverHandler);
				ctrl.toggleElement.on('mouseleave', toggleOutHandler);
				ctrl.menuElement.on('mouseover', menuOverHandler);
				ctrl.menuElement.on('mouseleave', menuOutHandler);
			}
			if (settings.toggle.onDocumentClick) {
				$document.on('click', toggleOff);
			}
			toggleOff();
		}
		function clickHandler() {
			$timeout.cancel(togglePromise);
			ctrl.toggleDropdown();
		}
		function togggleOverHandler(event) {
			if (attached) {
				return;
			}
			ctrl.toggleDropdown();
		}
		function toggleOutHandler(event) {
			if (togglePromise) {
				return;
			}
			togglePromise = $timeout(function () {
				if (menuOver) {
					return;
				}
				toggleOff();
			}, 500);
			togglePromise.finally(function () {
				togglePromise = null;				
			});
		}
		function menuOverHandler(event) {
			menuOver = true;
		}
		function menuOutHandler(event) {
			menuOver = false;
			toggleOutHandler();
		}
		function toggleOff(event) {
			if (!attached
					|| event
					&& dropdownService.isTarget(event, ctrl.menuElement)
					|| dropdownService.isTarget(event, ctrl.toggleElement)) {
				return;
			}
			dropdownService.detach(ctrl.menuElement);
			$element.removeClass('is--open');
			attached = false;  
		}
	}
])
.directive('aptDropdown', function () {
	return {
		restrict: 'A',
		controller: 'aptDropdownCtrl',
		scope: {},
		link: function dropdownLink(scope, el, attrs, ctrl) {
			ctrl.init(attrs.aptDropdown);
			scope.$on('$destroy', function () {
				ctrl.destroy();
			});
		}
	};
})
.directive('aptDropdownToggle', function () {
	return {
		restrict: 'A',
		require: '^^aptDropdown',
		link: function toggleLink(scope, el, attrs, ctrl) {
			ctrl.initToggle(el, attrs.aptDropdownToggle);
		}
	};
})
.directive('aptDropdownMenu', function () {
	return {
		restrict: 'A',
		require: '^^aptDropdown',
		link: function menuLink(scope, el, attrs, ctrl) {
			ctrl.initMenu(el, attrs.aptDropdownMenu);
		}
	};
});

})();