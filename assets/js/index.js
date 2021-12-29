window.addEventListener("load", function() {
    let sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
    });

    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            document.querySelector("#notLoggedIn").style.display = "none";
            document.querySelector("#loggedIn").style.display = "flex";
        }
    })

    function createSelectListas(listas) {
        const htmlSelect = document.querySelector("#tableselect");
        listas.forEach((lista) => {
            const option = new Option();
            option.value = lista['table_reference'];
            option.text = lista['list_name'];
            htmlSelect.options.add(option);
        });
    }

    function appinit() {
        sasjs.request("services/common/appinit", null, undefined, loginRequired).then((response) => {
            let responseJson;

            try {
                responseJson = response;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                appinit();
            } else if (responseJson && responseJson.areas) {
                createSelectListas(responseJson.areas);
            }
        });
    }

    appinit();
})
