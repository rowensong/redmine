$(document).ready(function () {
  const scrSize = window.matchMedia("(min-width: 900px)");
  if (scrSize.matches) {
    // Top menu setup
    $("#top-menu").after('<div id="topmenu-nav"></div>');
    $("#topmenu-nav").append($("#top-menu").html());
    $("#top-menu").empty();
    $("#topmenu-nav").appendTo("#top-menu");

    $("#topmenu-nav").prepend($("#header h1"));

    $("#quick-search").appendTo("#topmenu-nav");
    $("#quick-search #project-jump").appendTo($("#topmenu-nav h1"));

    const ele = $("#quick-search label a");
    $("#quick-search label").empty();
    $(ele).appendTo("#quick-search label");
    const srch = "<div class = expandSearch ></div>";
    $("#quick-search #q").before(srch).prependTo(".expandSearch");
    $("#project-jump .drdn-trigger").prop("title", "Jump to project");
    $("#userprofile").prop("title", "User profile");
    $("#loggedas").prependTo("#account");
    $("#account").appendTo("#topmenu-nav");

    //Add header after topmenu nav

    // For user profile Setup
    if ($("#loggedas").length > 0) {
      var loggedasEle = $.parseHTML($("#loggedas").html());
    }
    // Get current user avatar if available
    var userAvatar = "";
    if ($("#loggedas").length > 0) {
      // Try to get avatar from the page if it exists
      var avatarImg = $("img.gravatar").first();
      console.log(avatarImg);
      if (avatarImg.length > 0) {
        // Clone the avatar image and adjust size for profile icon
        var clonedAvatar = avatarImg.clone();
        clonedAvatar.css({
          width: "32px",
          height: "32px",
          "border-radius": "50%",
          "object-fit": "cover",
        });
        userAvatar = clonedAvatar.prop("outerHTML");
      }
    }

    var account = '<div id="userprofile">';
    if (userAvatar) {
      account += '<div class="profileicon account">' + userAvatar + "</div>";
    } else {
      account += '<div class="profileicon account"></div>';
    }
    account += '<div id="profilemenu" style="display: none;"></div></div>';
    $("#quick-search").append(account);
    $("#account ul").prop("id", "profilelist").appendTo("#profilemenu");
    $("#account").remove();
    $("#userprofile").appendTo("#quick-search");

    // For user profile popup setup
    $(".account").click(function () {
      var X = this.id;
      if (X == 1) {
        $("#profilemenu").hide();
        $(this).prop("id", "0");
      } else {
        $("#profilemenu").show();
        $(this).prop("id", "1");
      }
    });
    $("#profilemenu, .account").mouseup(function () {
      return false;
    });
    $(document).mouseup(function () {
      $("#profilemenu").hide();
      $(".account").prop("id", "");
    });
  }
});
