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

    function clearTable() {
        /** @type {HTMLTableRowElement} */
        const theadrow = document.querySelector("#thead");
        /** @type {HTMLTableSectionElement} */
        const tbody = document.querySelector("#tbody");

        while (theadrow.firstChild) {
            theadrow.removeChild(theadrow.lastChild);
        }

        while (tbody.firstChild) {
            /** @type {HTMLTableRowElement} */
            const lastRow = tbody.lastChild;
            while (lastRow.firstChild) {
                lastRow.removeChild(lastRow.lastChild);
            }
        }
    }

    function createTableView(colunas, linhas) {
        clearTable();

        /** @type {HTMLTableRowElement} */
        const theadrow = document.querySelector("#thead");
        /** @type {HTMLTableSectionElement} */
        const tbody = document.querySelector("#tbody");

        colunas.forEach((col) => {
            const tcell = document.createElement("th");
            tcell.scope = "col";
            tcell.text = col.NAME;
            theadrow.appendChild(tcell);
        });

        linhas.forEach((linha) => {
            const trow = document.createElement("tr");
            colunas.forEach((col) => {
                const tcell = document.createElement("td");
                tcell.text = linha[col.NAME];
                trow.appendChild(tcell);
            });
            tbody.appendChild(trow);
        });
    }

    function getdata() {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        let dataObject = {
            "tbl": [{
                "col": String(htmlSelect.options[htmlSelect.selectedIndex].value)
            }]
        }

        sasjs.request("services/common/getdata", dataObject, undefined, loginRequired).then((response) => {
            let responseJson;

            try {
                responseJson = response;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                getdata();
            } else if (responseJson) {
                let colunas = responseJson.WORK.LISTA.colattrs;
                let linhas = responseJson.lista;
                createTableView(colunas, linhas);
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
