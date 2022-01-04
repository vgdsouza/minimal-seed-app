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
            /** @type {HTMLDivElement} */
            const spinner = document.querySelector("#spinner");
            spinner.style.display = "none";
            /** @type {HTMLDivElement} */
            const main = document.querySelector("#main");
            main.style.display = "flex";
            /** @type {HTMLParagraphElement} */
            const currentUser = document.querySelector("#currentUser");
            currentUser.innerText = res.SYSUSERID;
        }
    })

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
            tbody.removeChild(tbody.lastChild);
        }
    }

    function createTableView(lista) {
        clearTable();

        /** @type {HTMLTableRowElement} */
        const theadrow = document.querySelector("#thead");
        /** @type {HTMLTableSectionElement} */
        const tbody = document.querySelector("#tbody");

        if (lista[0]) {
            let colunas = Object.keys(lista[0]);

            colunas.forEach((col) => {
                /** @type {HTMLTableCellElement} */
                const th = document.createElement("th");
                th.scope = "col";
                th.innerText = col;
                theadrow.appendChild(th);
            });

            lista.forEach((linha) => {
                /** @type {HTMLTableRowElement} */
                const tr = document.createElement("tr");
                colunas.forEach((col) => {
                    /** @type {HTMLTableCellElement} */
                    const td = document.createElement("td");
                    td.innerText = linha[col];
                    tr.appendChild(td);
                });
                tbody.appendChild(tr);
            });
        }
    }

    function getdata() {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        let val = String(htmlSelect.options[htmlSelect.selectedIndex].value);

        if (val === "vazio") {
            clearTable();
        } else {
            let dataObject = {
                "object": [{
                    "value": val
                }]
            }

            sasjs.request("services/common/getdata", dataObject).then((res) => {
                let responseJson;

                try {
                    responseJson = res;
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
    }

    function createSelectListas(listas) {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        listas.forEach((lista) => {
            /** @type {HTMLOptionElement} */
            const option = new Option();
            option.value = lista['TABLE_REFERENCE'];
            option.text = lista['LIST_NAME'];
            htmlSelect.options.add(option);
        });

        htmlSelect.addEventListener("change", getdata);
    }

    function appinit() {
        sasjs.request("services/common/appinit", null).then((res) => {
            let responseJson;

            try {
                responseJson = res;
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

    function updatedata(dataObject) {
        sasjs.request("services/common/updatedata", dataObject).then((res) => {
            let responseJson;

            try {
                responseJson = res;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                updatedata();
            } else if (responseJson && responseJson.listas) {
                console.log("Sucesso!");
            }
        });
    }

    function convertCsv() {
        /** @type {HTMLButtonElement} */
        const htmlButton = document.querySelector("#tablebutton");
        /** @type {HTMLInputElement} */
        const htmlFile = document.querySelector("#tablefile");
        /** @type {FileReader} */
        const reader = new FileReader();

        htmlButton.disabled = true;

        let dataObject = {
            "object": []
        }

        reader.addEventListener("load", function(event) {
            const str = event.target.result;
            const linhas = str.split("\n");
            const colunas = linhas[0].trim().toUpperCase().split("|");

            for (let i = 1; i < linhas.length; i++) {
                let temp = {};

                for (let j = 0; j < colunas.length; j++) {
                    temp[colunas[j]] = linhas[i].trim().split("|")[j];
                }

                dataObject["object"].push(temp);
            }
        })

        reader.readAsText(htmlFile.files[0]);

        updatedata(dataObject)
    }

    document.querySelector("#tablebutton").addEventListener("click", convertCsv);

    appinit();
})
