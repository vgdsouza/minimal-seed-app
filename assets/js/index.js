window.addEventListener("load", function () {
    /** @type {HTMLParagraphElement} */
    const currentUser = document.querySelector("#currentUser");

    /** @type {HTMLDivElement} */
    const spinner = document.querySelector("#spinner");

    /** @type {HTMLDivElement} */
    const main = document.querySelector("#main");

    /** @type {HTMLSelectElement} */
    const tableselect = document.querySelector("#tableselect");

    /** @type {HTMLInputElement} */
    const tablefile = document.querySelector("#tablefile");

    /** @type {HTMLButtonElement} */
    const tablebutton = document.querySelector("#tablebutton");

    /** @type {HTMLDivElement} */
    const tablespinner = document.querySelector("#tablespinner");

    /** @type {HTMLTableElement} */
    const mytable = document.querySelector("#mytable");

    /** @type {HTMLTableRowElement} */
    const thead = document.querySelector("#thead");

    /** @type {HTMLTableSectionElement} */
    const tbody = document.querySelector("#tbody");

    const sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
    });

    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            currentUser.innerText = res.userName;
            appinit();
        }
    });

    /* APPINIT */
    async function appinit() {
        await sasjs.request("services/common/appinit", null).then((res) => {
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

    function createSelectListas(lists) {
        lists.forEach((list) => {
            /** @type {HTMLOptionElement} */
            const option = new Option();
            option.value = list['TABLE_REFERENCE'];
            option.text = list['LIST_NAME'];
            tableselect.options.add(option);
        });

        tablefile.value = "";
        spinner.style.display = "none";
        main.style.display = "flex";
    }
    /* APPINIT END */


    /* GETDATA */
    tableselect.addEventListener("change", getdata);

    async function getdata() {
        mytable.style.display = "";  // No CSS está definido como None
        tablespinner.style.display = "flex";

        clearTable();

        const val = String(tableselect.options[tableselect.selectedIndex].value);

        if (val === "") {
            tablefile.disabled = true;
        } else {
            const dataObject = {
                [val]: [{}]
            }

            await sasjs.request("services/common/getdata", dataObject).then((res) => {
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

        tablespinner.style.display = "";  // No CSS está definido como None
        mytable.style.display = "table";
        tablefile.value = "";
        tablefile.disabled = false;
    }

    function clearTable() {
        while (thead.firstChild) {
            thead.removeChild(thead.lastChild);
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
        if (lista[0]) {
            let colunas = Object.keys(lista[0]);

            colunas.forEach((col) => {
                /** @type {HTMLTableCellElement} */
                const th = document.createElement("th");
                th.scope = "col";
                th.innerText = col;
                thead.appendChild(th);
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
    /* GETDATA END */


    /* UPDATEDATA */
    tablefile.addEventListener("change", function () {
        if (!(tablefile.value === "")) {
            tablebutton.disabled = false;
        }
    });

    tablebutton.addEventListener("click", updatedata);

    async function updatedata() {
        tablefile.disabled = true;
        tablebutton.disabled = true;
        tablebutton.click();

        /** @type {File} */
        const myfile = tablefile.files[0];

        const val = String(tableselect.options[tableselect.selectedIndex].value);

        if (myfile) {
            await sasjs.uploadFile(
                'services/common/updatedata',
                [{ "file": myfile, "fileName": myfile.name }],
                {"tableRef": val}
            ).then((res) => {
                let responseJson;

                try {
                    responseJson = res;
                } catch (e) {
                    console.error(e);
                }

                if (responseJson && responseJson.status === 449) {
                    console.error(responseJson);
                } else if (responseJson) {
                    console.log(responseJson);
                }
            });
        }
    }
    /* UPDATEDATA END */
});
