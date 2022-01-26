window.addEventListener("load", function () {
    let sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: true,
        loginMechanism: "Redirected"
    });

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

    async function getdata() {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");
        /** @type {HTMLInputElement} */
        const htmlFile = document.querySelector("#tablefile");
        /** @type {HTMLButtonElement} */
        const htmlButton = document.querySelector("#tablebutton");

        clearTable();

        const val = String(htmlSelect.options[htmlSelect.selectedIndex].value);

        if (val === "") {
            htmlButton.disabled = true;
            htmlFile.disabled = true;
            htmlFile.value = "";
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

            htmlButton.disabled = false;
            htmlFile.disabled = false;
            htmlFile.value = "";
        }
    }

    function createSelectListas(listas, usuario) {
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");
        /** @type {HTMLDivElement} */
        const spinner = document.querySelector("#spinner");
        /** @type {HTMLDivElement} */
        const main = document.querySelector("#main");
        /** @type {HTMLParagraphElement} */
        const currentUser = document.querySelector("#currentUser");
        /** @type {HTMLInputElement} */
        const htmlFile = document.querySelector("#tablefile");

        listas.forEach((lista) => {
            /** @type {HTMLOptionElement} */
            const option = new Option();
            option.value = lista['TABLE_REFERENCE'];
            option.text = lista['LIST_NAME'];
            htmlSelect.options.add(option);
        });

        currentUser.innerText = usuario;
        htmlFile.value = "";
        spinner.style.display = "none";
        main.style.display = "flex";

        htmlSelect.addEventListener("change", getdata);
    }

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
                createSelectListas(responseJson.listas, responseJson.SYSUSERID);
            }
        });
    }

    function filePromise(file) {
        const reader = new FileReader();

        return new Promise((resolve) => {
            reader.onload = () => {
                resolve(reader.result);
            };

            reader.readAsText(file);
        });
    }

    async function updatedata() {
        /** @type {HTMLInputElement} */
        const htmlFile = document.querySelector("#tablefile");
        /** @type {HTMLSelectElement} */
        const htmlSelect = document.querySelector("#tableselect");

        /** @type {String} */
        const str = await filePromise(htmlFile.files[0]);

        /** @type {Array} */
        const linhas = str.split("\n");
        /** @type {Array} */
        const colunas = linhas[0].trim().split("|");

        let dataObject = {
            "fromjs": []
        };

        let temp;
        let linha;

        for (let i = 1; i < linhas.length; i++) {
            temp = {};
            linha = linhas[i].trim().split("|");
            for (let j = 0; j < colunas.length; j++) {
                temp[colunas[j]] = linha[j];
            }
            dataObject["fromjs"].push(temp);
        }

        await sasjs.request("services/common/updatedata", dataObject).then((res) => {
            let responseJson;

            try {
                responseJson = res;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                updatedata();
            } else if (responseJson) {
                console.log("Sucesso");
            }
        });
    }

    document.querySelector("#tablebutton").addEventListener("click", updatedata);

    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            appinit();
        }
    });
});
