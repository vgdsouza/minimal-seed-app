document.querySelector("#body").addEventListener("load", function() {
    function setScrollbarWidth() {
        var element = document.querySelector(':root');
        var width = window.innerWidth - element.offsetWidth;
        element.style.setProperty('--scrollbar-width', width + 'px');
    }

    setScrollbarWidth();

    let sasjs = new SASjs.default({
        appLoc: '/Public/app/ICL',
        serverType: 'SASVIYA',
        serverUrl: '',
        debug: false,
        loginMechanism: 'Redirected'
    });

    console.log("Foo");
})
 console.log("Blah");
