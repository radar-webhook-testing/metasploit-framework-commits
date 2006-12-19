/*
 * Copyright (c) 2006, L.M.H. <lmh@info-pull.com>
 * All Rights Reserved.
 * -- Part of 'msfweb', the web interface for the Metasploit Framework.
 */

/*
 * Global variables
 */

var web_windows_theme = "metasploit";

/*
 * Window Management code and Dialogs
 */

var winIndex = 0;

/* Returns a unique Window identifier */
function obtainWindowId() {
	return (winIndex++);
}

/*
 * Show the About information dialog
 */
function openAboutDialog() {
    var aboutWindow = new Window("about-window"+obtainWindowId(),
        { className: web_windows_theme,
        width:450,
        height:160,
        zIndex: 100,
        resizable: true,
        title: "About msfweb v.3",
        showEffect:Effect.BlindDown,
        hideEffect: Effect.SwitchOff,
        draggable:true
        })
        
    var about_content = "<div style='padding:5px'>The new <strong>Metasploit Framework Web Console</strong> (v.3)" +
                        " has been developed by L.M.H &lt;lmh@info-pull.com&gt;.<br />Copyright &copy; 2006 L.M.H " +
                        "&lt;lmh@info-pull.com&gt;. All Rights Reserved. <br /><br />" +
                        "Thanks to H.D.M for the functionality suggestions and general help. Also thanks to" +
                        " the Metasploit team (hdm, skape, etc) and contributors for developing a ground-breaking" +
                        " project: <strong>Metasploit.</strong><br /><br />Standards compliant: Valid XHTML Strict " +
                        "and CSS code.</div>"
                        
    aboutWindow.getContent().innerHTML= about_content;
    aboutWindow.showCenter();
}


/*
 * Functions for opening modules lists and views
 */

function openExploitsWindow() {
    var exploitList = create_window_ajax("/exploits/list", "exploits-list", "Available Exploits", 600, 300);
    exploitList.setDestroyOnClose();
    exploitList.showCenter();
}

function openAuxiliariesWindow() {
    var auxList = create_window_ajax("/auxiliaries/list", "auxiliaries-list", "Auxiliary Modules", 600, 300);
    auxList.setDestroyOnClose();
    auxList.showCenter();
}

function openPayloadsWindow() {
    var payloadList = create_window_ajax("/payloads/list", "payloads-list", "Available Payloads", 600, 300);
    payloadList.setDestroyOnClose();
    payloadList.showCenter();
}

function openEncodersWindow() {
    var encoderList = create_window_ajax("/encoders/list", "encoders-list", "Available Encoders", 600, 300);
    encoderList.setDestroyOnClose();
    encoderList.showCenter();
}

function openNopsWindow() {
    var nopList = create_window_ajax("/nops/list", "nops-list", "Available No-Op Generators", 600, 300);
    nopList.setDestroyOnClose();
    nopList.showCenter();
}

function openSessionsWindow() {
    var sessionList = create_window_ajax("/sessions/list", "sessions-list", "Metasploit Sessions", 600, 300);
    sessionList.setDestroyOnClose();
    sessionList.showCenter();
}

function openJobsWindow() {
    var jobList = create_window_ajax("/jobs/list", "jobs-list", "Running Jobs", 600, 300);
    jobList.setDestroyOnClose();
    jobList.showCenter();
}

function openIDEWindow() {
    window.open('/ide/start');
}

/*
 * Task and helper functions
 */

/*
 * Live search helper: sets an observer on text field with id (observer_id)
 * for (module_type) modules (ex. exploits) and the id of the spinner container
 * to show loading progress/indicator.
 * Last argument gives a clean list with no formatting. (ul-li)
 */
function generic_live_search(observer_id, module_type, load_spinner_id, clean_list) {
    new Form.Element.Observer(observer_id, 1, 
      function(element, value) {
        /* Set an AJAX updater for the observer of the text field */
        new Ajax.Updater(
            'search_results',
            '/msf/search',
            {
                asynchronous:true,
                evalScripts:true, 
                onComplete:function(request)
                {
                    Element.hide(load_spinner_id)
                }, 
                onLoading:function(request)
                {
                    Element.show(load_spinner_id)
                },
                method:'post',
                parameters:'module_type=' + module_type + '&clean_list=' + clean_list + '&terms=' + value
            })
      });
    /* Initializes the contents with all available modules by
     * doing a blank search 
     */
    $(observer_id).value = ' ';
}

/*
 * Create and AJAX based window from extenal content
 */
function create_window_ajax(target_url, wid, wtitle, wwidth, wheight) {
    var new_mwindow = new Window(wid+'-'+obtainWindowId(),
        { className: web_windows_theme,
          title: wtitle,
          top:70,
          left:100,
          width:wwidth,
          height:wheight,
          resizable: true,
          draggable: true,
          url: target_url,
          showEffect: Element.show,
          hideEffect: Element.hide
          });
    return new_mwindow;
}

/*
 * Open a window for the module of type (mtype) by id (refname) with tile (wtitle).
 * Height and width are fixed, should be working values in all cases.
 */
function openModuleWindow(mtype, refname, wtitle) {
    var mWin = create_window_ajax("/" + mtype + "/view?refname=" + refname, mtype + "-view-" + obtainWindowId(), wtitle, 500, 500);
    mWin.setDestroyOnClose();
    mWin.showCenter();
}

function run_tasks() {
    // ...
}
