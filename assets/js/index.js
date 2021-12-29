window.addEventListener("load", function() {
    function scrollbarWidth() {
        let htmlRoot = document.querySelector(":root");
        let scrollbar = window.innerWidth - htmlRoot.offsetWidth;
        htmlRoot.style.setProperty("--scrollbar", scrollbar + "px");
    }

    scrollbarWidth();

    let sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
    });
})
