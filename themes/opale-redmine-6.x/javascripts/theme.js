$(document).ready(function () {
  const scrSize = window.matchMedia("(min-width: 900px)");
  if (scrSize.matches) {
    // Top menu setup
    $("#top-menu").after('<div id="topmenu-nav"></div>');
    $("#topmenu-nav").append($("#top-menu").html());
    $("#top-menu").empty();

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

    // Get current user avatar if available (BEFORE removing #loggedas)
    var userAvatar = "";
    if ($("#loggedas").length > 0) {
      // Try to get avatar from the page if it exists
      var avatarImg = $("img.gravatar").first();
      console.log("=== Gravatar Debug Info ===");
      console.log("Found gravatar images:", $("img.gravatar").length);
      console.log("Gravatar src:", avatarImg.attr("src"));

      if (avatarImg.length > 0) {
        console.log("Gravatar found - processing...");
        // Clone the avatar image and adjust size for profile icon
        var clonedAvatar = avatarImg.clone();
        clonedAvatar.css({
          width: "32px",
          height: "32px",
          "border-radius": "50%",
          "object-fit": "cover",
        });
        userAvatar = clonedAvatar.prop("outerHTML");
        console.log("Processed userAvatar:", userAvatar);
      } else {
        console.log("No gravatar image found on page");
      }
    }

    // For user profile Setup (AFTER getting avatar)
    if ($("#loggedas").length > 0) {
      var loggedasEle = $.parseHTML($("#loggedas").html());
      $("#loggedas").remove();
      $("#account ul").prepend("<li></li>");
      $("#account ul li").first().html(loggedasEle[1]);
    }

    var account = '<div id="userprofile">';
    if (userAvatar) {
      account += '<div class="profileicon account"></div>';
      console.log("Profile icon created with avatar");
    } else {
      account += '<div class="profileicon account"></div>';
      console.log("Profile icon created without avatar");
    }
    account += '<div id="profilemenu" style="display: none;"></div></div>';
    $("#quick-search").append(account);
    $("#account ul").prop("id", "profilelist").appendTo("#profilemenu");
    $("#account").remove();
    $("#topmenu-nav > ul").appendTo($("#quick-search"));
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

    if ($('label[for="settings_app_title"]').length > 0) {
      $('label[for="settings_app_title"]').parent().hide();
    } else {
      return;
    }

    if ($('label[for="settings_ui_theme"]').length > 0) {
      $('label[for="settings_ui_theme"]').parent().hide();
    } else {
      return;
    }
  }
});
