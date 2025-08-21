$(document).ready(function () {
  const scrSize = window.matchMedia("(min-width: 900px)");
  if (scrSize.matches) {
    // Top menu setup
    $("#top-menu").after('<div id="topmenu-nav"></div>');
    $("#topmenu-nav").append($("#top-menu").html());
    $("#top-menu").empty();
    $("#topmenu-nav").appendTo("#top-menu");

    $("#topmenu-nav").after($("#header"));

    $("#quick-search").appendTo("#top-menu");
    const ele = $("#quick-search label a");
    $("#quick-search label").empty();
    $(ele).appendTo("#quick-search label");
    const srch = "<div class = expandSearch ></div>";
    $("#quick-search #q").before(srch).prependTo(".expandSearch");
    $("#project-jump .drdn-trigger").prop("title", "Jump to project");
    $("#userprofile").prop("title", "User profile");
    $("#loggedas").prependTo("#account");
    $("#account").appendTo("#top-menu");
    $("#project-jump .drdn-trigger").html(projIcon);

    //Add header after topmenu nav

    // For user profile Setup
    if ($("#loggedas").length > 0) {
      var loggedasEle = $.parseHTML($("#loggedas").html());
      $("#loggedas").remove();
      $("#account ul").prepend("<li></li>");
      $("#account ul li").first().html(loggedasEle[1]);
    }
    var account =
      ' <div id="userprofile"><div class="profileicon account"></div>';
    account += '<div id="profilemenu" style="display: none;"></div></div>';
    $("#quick-search").append(account);
    $("#account ul").prop("id", "profilelist").appendTo("#profilemenu");
    $("#account").remove();
    $("#userprofile").appendTo("#quick-search");
  }
});
