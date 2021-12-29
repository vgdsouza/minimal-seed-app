window.addEventListener("load", function() {
    let sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: true,
        loginMechanism: "Redirected"
    });

    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            document.querySelector("#spinner").style.display = "none";
            document.querySelector("#main").style.display = "flex";
        }
    })

    function loginRequired() {
        window.location.replace("/SASLogon/login");
    }

    function createTableView(lista) {
        console.log(lista);
    }

    function getdata() {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        let dataObject = {
            "tbl": [{
                "col": String(htmlSelect.options[htmlSelect.selectedIndex].value)
            }]
        }

        sasjs.request("services/common/upload", dataObject, undefined, loginRequired).then((response) => {
            let responseJson;

            try {
                responseJson = response;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                getdata();
            } else if (responseJson) {
                createTableView(responseJson.lista);
            }
        });
    }

    function createSelectListas(listas) {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        listas.forEach((lista) => {
            const option = new Option();
            option.value = lista['TABLE_REFERENCE'];
            option.text = lista['LIST_NAME'];
            htmlSelect.options.add(option);
        });

        htmlSelect.addEventListener("change", getdata);
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
            } else if (responseJson && responseJson.listas) {
                createSelectListas(responseJson.listas);
            }
        });
    }

    appinit();
})
