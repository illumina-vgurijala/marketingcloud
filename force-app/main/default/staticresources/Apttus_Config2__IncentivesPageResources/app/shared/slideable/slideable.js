;(function() {
var _defaultMaxHeight = '2000px';

angular.module('sharedWidgetsApp')
    .directive('slideable', slideableDirective);

    function slideableDirective() {
        return {
            restrict:'C',
            scope: {
              expanded: '='
            },
            controller: function($scope) { },
            compile: function (element, attr) {
                // wrap tag
                var contents = element.html();
                element.html('<div class="slideable_content" style="margin:0 !important; padding:0 !important" >' + contents + '</div>');

                return function postLink(scope, element, attrs) {
                    if(attrs.maxHeight) _defaultMaxHeight = attrs.maxHeight;

                    // default properties
                    attrs.duration = (!attrs.duration) ? '1s' : attrs.duration;
                    attrs.easing = (!attrs.easing) ? 'ease-in-out' : attrs.easing;
                    element.css({
                        'overflow': 'hidden',
                        'transitionProperty': 'max-height',
                        'max-height': (scope.expanded ? _defaultMaxHeight : '0px'),
                        'transitionDuration': attrs.duration,
                        'transitionTimingFunction': attrs.easing
                    });
                };
            }
        };
    }

    angular.module('sharedWidgetsApp').directive('slideToggle', slideToggleDirective);

    function slideToggleDirective() {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                var target,
                    content,
                    expanded = (attrs.expanded == 'true' ? true : false);

                element.bind('click', function() {
                    if (!target) target = document.querySelector(attrs.slideToggle);
                    if (!content) content = target.querySelector('.slideable_content');

                    if(!expanded) {
                        target.style.maxHeight = _defaultMaxHeight;
                    } else {
                        target.style.maxHeight = '0px';
                    }

                    expanded = !expanded;
                });
            }
        }
    }
})();