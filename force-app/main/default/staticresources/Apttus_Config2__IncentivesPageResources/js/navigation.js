var j$ = jQuery.noConflict();
var toggleNav;

function navFunctionality(options) {

    var $firstTd,
        $navContainer,
        $window = j$(window)
        collapsibleNavIsCollapsed = false,
        _toggleNav = function($navWidth) {
            if(!collapsibleNavIsCollapsed){
                $firstTd.animate({
                    'width': 0
                }, 250, function() {});

                $navContainer.animate({
                    'margin-left': -265,
                }, 250, function() {});

                $navContainer.find(".nav-toggle").find(".fa").attr('class', 'fa fa-caret-right');

                collapsibleNavIsCollapsed = true;
            } else {
                $firstTd.animate({
                    'width': 280
                }, 250, function() {});

                $navContainer.animate({
                    'margin-left': 0,
                }, 250, function() {});

                $navContainer.find(".nav-toggle").find(".fa").attr('class', 'fa fa-caret-left');

                collapsibleNavIsCollapsed = false;
            }
        };

    this.rebind = function() {
        $firstTd = j$(options.collapsibleContainer);
        $navContainer = j$(options.innerNavContainer);

        $window.unbind("scroll").bind("scroll", function () {
          $firstTd.css({"padding-top": $window.scrollTop() + "px"});
        });

        $navContainer.find(".nav-toggle").unbind("click").bind("click", function(){
            _toggleNav($navContainer.outerWidth(true));
        });
    };
    
    this.rebind();

    return this;
}

j$(document).ready(function() {

    var actionFunction = function(e){
            var actionLinkSelected = (e.target.tagName === "LI" ? j$(e.target).find("a") : null);

            if(actionLinkSelected !== null && j$(actionLinkSelected).length) {
                j$(actionLinkSelected)[0].click();
            }
        };

    j$(".nav li").on("click", actionFunction);
});