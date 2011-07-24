// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require_tree .

var openNotifications = []
var timeout = null;
var interval = null;

$(document).ready(function() {

    $("input[id=movie_adder]").autocomplete({
        source: "/movielist.json" + $("input[id=movie_adder]").val(),
        minLength: 2,
        open: function() {
            console.debug($(this).val())
        }
    });

    $('a.download_torrent').click(function(e) {
        e.preventDefault()
        console.debug(this, $(this), $(this).attr('id'), this.id)
        $.ajax({
            url: "movie/" + this.id + "/download",
            success: function(data) {
                console.debug("Downloading the torrent:", data)
            }
        })
    })

    $("#movie_list").hide()

    $('input[id="rtfetch"]').click(function(e) {
        e.preventDefault();
        select = $('select[name="movie[name]"]')
        input = $('input[name="movie[search_term]"]')
        query = input.val()
        spinner = $('#ajax_loader')

        spinner.fadeIn()

        $("#movie_list").slideDown()

        $.ajax({
            url: "/movielist.json?q=" + query,
            success: function(data) {
                spinner.fadeOut()
                select.children().remove()
                selects = ""
                $.each(data, function(index, element) {
                    selects += "<option value=\"" + element + "\">" + element + "</option>"
                })
                console.debug(selects)
                select.html(selects)
                select.removeAttr("disabled")
            },
            error: function(data) {
                console.debug("You failed.", data)
                createNotificationDiv(1, "Could not communicate with Rotten Tomatoes. Are you connected to the internet?", false)
            }

        });
    })

    $('.add_movie').fancybox({
        type: 'iframe',
        width: 450,
        height: 250,
        autoScale: false
    })


    $('.movies.index').ready(function() {
//        startRefreshTimer()
    })

    function startRefreshTimer() {
        timeout = setTimeout(function() {
            window.location.reload(false)
        }, 60 * 1000)
    }

    $('.movie_info').each(function() {
        $(this).qtip({
            content: {
                text: '<img src="/assets/ajax-loader.gif" alt="Loading..." />',
                ajax: {
                    url: '/movies/' + $(this).attr('data-id')
                },
                title: {
                    text: $(this).attr('data-title')
                }
            },
            show: {
                event: 'mouseover',
                solo: true // Only show one tooltip at a time
            },
            hide: {
                event: 'mouseleave',
                fixed: true
            },
            style: {
                classes: 'ui-tooltip-dark ui-tooltip-shadow',
                width: "500px"
            },
            position: {
                at: 'top left',
                viewport: $(window)
            }

        })
    })


    $('input[name="tor_fetch"]').click(function(e) {
        e.preventDefault();
        select = $('select[name="torrent_list"]')
        input = $('input[name="movie[search_term]"]')
        query = input.val()
        form_action_with_id = $(this).parent().siblings('form').attr('action').match(/\d+/)
        if (form_action_with_id == null) {
            createNotificationDiv(0, "You must save the movie first before getting torrents.", false)
            return false
        } else {
            movie_id = form_action_with_id[0]
        }


        $.ajax({
            url: "/torrent_list.json",
            data: {
                q: query,
                m_id: movie_id
            },
            method: 'get',
            success: function(data) {
                console.debug("Data:", data)
                select.children().remove()
                selects = ""
                $.each(data, function(index, element) {
                    selects += "<option value=\"" + element + "\">" + element + "</option>"
                })
                console.debug(selects)
                select.html(selects)
                select.removeAttr("disabled")
            },
            error: function(data) {
                console.debug("You failed.", data)
                createNotificationDiv(1, "Could not communicate with Rotten Tomatoes. Are you connected to the internet?", false)
            }

        });
    })
})

function noop() {
    return false;
}

function createNotificationDiv(id, text, sticky) {
    notification_holder = $("#notice")
    notification = $("<div>")
    notification.addClass("notification")
    notification.attr({
        display: 'none',
        id: id
    })
    notification.html(text)

    hide_link = $("<a>")
    hide_link.attr({
        href: "javascript:noop()"
    })
    hide_link.html("[X]")
    hide_link.click(function(e) {
        console.debug("Posting to notification/read")
        e.preventDefault()
        $.ajax({
            url: "/notifications/" + id + "/read",
            success: function(data) {
                console.debug("Successfully posted to notification/read")
                $('.notification#' + id).fadeOut()
            }
        })
    })

    notification.append(hide_link)
    notification_holder.append(notification)
    notification.fadeIn()
    openNotifications.push(id)
    console.debug("Updated openNotifications", openNotifications)

    if (!sticky) {
        setTimeout(function() {
            notification_holder.find("div#" + id).fadeOut()
        }, 5000);
    }

}

function queryNotifications() {
    $.ajax({
        url: "/notifications/poll",
        success: function(data) {
            if (data.length > 0) {
                $.each(data, function(index, notification) {
                    if (openNotifications.indexOf(notification.id) < 0) {
                        createNotificationDiv(notification.id, notification.notification, notification.sticky)
                    }
                })
            }

        }
    })
}